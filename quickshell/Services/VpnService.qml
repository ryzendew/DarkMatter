pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: true
    property bool isBusy: false
    property string errorMessage: ""

    property var profiles: []

    property bool singleActive: false

    property var activeConnections: [] // [{ name, uuid, device, state, timestamp }]
    property var activeUuids: []
    property var activeNames: []
    property string activeUuid: activeUuids.length > 0 ? activeUuids[0] : ""
    property string activeName: activeNames.length > 0 ? activeNames[0] : ""
    property string activeDevice: activeConnections.length > 0 ? (activeConnections[0].device || "") : ""
    property string activeState: activeConnections.length > 0 ? (activeConnections[0].state || "") : ""
    property bool connected: activeUuids.length > 0

    property var connectionDetails: ({}) // { uuid: { ipv4, ipv6, dns, gateway, timestamp } }
    
    signal connectionInfoUpdated()


    Component.onCompleted: initialize()

    Component.onDestruction: {
        nmMonitor.running = false
    }

    function initialize() {
        nmMonitor.running = true
        refreshAll()
    }

    function refreshAll() {
        listProfiles()
        refreshActive()
    }

    Process {
        id: nmMonitor
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.NetworkManager"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (line.includes("ActiveConnection") || line.includes("PropertiesChanged") || line.includes("StateChanged")) {
                    refreshAll()
                }
            }
        }
    }

    function listProfiles() {
        getProfiles.running = true
    }

    Process {
        id: getProfiles
        command: ["bash", "-lc", "nmcli -t -f NAME,UUID,TYPE connection show | while IFS=: read -r name uuid type; do case \"$type\" in vpn) svc=$(nmcli -g vpn.service-type connection show uuid \"$uuid\" 2>/dev/null || nmcli -g vpn.data connection show uuid \"$uuid\" 2>/dev/null | grep -o 'vpn-type=[^,]*' | cut -d= -f2 || echo ''); echo \"$name:$uuid:$type:$svc\" ;; wireguard) echo \"$name:$uuid:$type:\" ;; *) : ;; esac; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().length ? text.trim().split('\n') : []
                const out = []
                for (const line of lines) {
                    const parts = line.split(':')
                    if (parts.length >= 3 && (parts[2] === "vpn" || parts[2] === "wireguard")) {
                        const svc = parts.length >= 4 ? parts[3] : ""
                        out.push({ name: parts[0], uuid: parts[1], type: parts[2], serviceType: svc })
                    }
                }
                root.profiles = out
            }
        }
    }

    function refreshActive() {
        getActive.running = true
    }

    function getConnectionDetails(uuid) {
        return root.connectionDetails[uuid] || {}
    }

    function getConnectionDuration(uuid) {
        const details = root.connectionDetails[uuid]
        if (!details || !details.timestamp) return ""
        const now = Date.now()
        const elapsed = now - details.timestamp
        const seconds = Math.floor(elapsed / 1000)
        const minutes = Math.floor(seconds / 60)
        const hours = Math.floor(minutes / 60)
        const days = Math.floor(hours / 24)
        
        if (days > 0) return days + "d " + (hours % 24) + "h"
        if (hours > 0) return hours + "h " + (minutes % 60) + "m"
        if (minutes > 0) return minutes + "m " + (seconds % 60) + "s"
        return seconds + "s"
    }

    function formatBytes(bytes) {
        if (!bytes || bytes === 0) return "0 B"
        const k = 1024
        const sizes = ["B", "KB", "MB", "GB"]
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + " " + sizes[i]
    }

    Process {
        id: getActive
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE,STATE", "connection", "show", "--active"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().length ? text.trim().split('\n') : []
                let act = []
                const now = Date.now()
                for (const line of lines) {
                    const parts = line.split(':')
                    if (parts.length >= 5 && (parts[2] === "vpn" || parts[2] === "wireguard")) {
                        const uuid = parts[1]
                        const existing = root.activeConnections.find(c => c.uuid === uuid)
                        const timestamp = existing && existing.timestamp ? existing.timestamp : now
                        act.push({ 
                            name: parts[0], 
                            uuid: uuid, 
                            device: parts[3], 
                            state: parts[4],
                            timestamp: timestamp
                        })
                        if (!existing || !existing.timestamp) {
                            Qt.callLater(() => {
                                getConnectionInfo.uuid = uuid
                                getConnectionInfo.running = true
                            })
                        }
                    }
                }
                root.activeConnections = act
                root.activeUuids = act.map(a => a.uuid).filter(u => !!u)
                root.activeNames = act.map(a => a.name).filter(n => !!n)
            }
        }
    }

    Timer {
        id: durationUpdateTimer
        interval: 1000
        running: root.connected
        repeat: true
        onTriggered: {
            root.connectionInfoUpdated()
        }
    }

    Process {
        id: getConnectionInfo
        property string uuid: ""
        running: false
        command: []
        onUuidChanged: {
            if (uuid) {
                command = ["nmcli", "-t", "connection", "show", "uuid", uuid]
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (!getConnectionInfo.uuid) return
                const lines = text.trim().split('\n')
                let ipv4 = ""
                let ipv6 = ""
                let dns = ""
                let gateway = ""
                
                for (const line of lines) {
                    const parts = line.split(':')
                    if (parts.length >= 2) {
                        const key = parts[0].trim()
                        const value = parts.slice(1).join(':').trim()
                        if (key.startsWith("IP4.ADDRESS[1]")) {
                            ipv4 = value
                        } else if (key.startsWith("IP6.ADDRESS[1]")) {
                            ipv6 = value
                        } else if (key.startsWith("IP4.DNS[1]")) {
                            dns = value
                        } else if (key === "IP4.GATEWAY") {
                            gateway = value
                        }
                    }
                }
                
                const existing = root.connectionDetails[getConnectionInfo.uuid] || {}
                const details = Object.assign({}, root.connectionDetails)
                details[getConnectionInfo.uuid] = {
                    ipv4: ipv4,
                    ipv6: ipv6,
                    dns: dns,
                    gateway: gateway,
                    timestamp: existing.timestamp || Date.now()
                }
                root.connectionDetails = details
                root.connectionInfoUpdated()
            }
        }
    }

    function isActiveUuid(uuid) {
        return root.activeUuids && root.activeUuids.indexOf(uuid) !== -1
    }

    function _looksLikeUuid(s) {
        return s && s.indexOf('-') !== -1 && s.length >= 8
    }

    function connect(uuidOrName) {
        if (root.isBusy) return
        root.isBusy = true
        root.errorMessage = ""
        if (root.singleActive) {
            const isUuid = _looksLikeUuid(uuidOrName)
            const escaped = ('' + uuidOrName).replace(/'/g, "'\\''")
            const upCmd = isUuid ? `nmcli connection up uuid '${escaped}'` : `nmcli connection up id '${escaped}'`
            const script = `set -e\n` +
                           `nmcli -t -f UUID,TYPE connection show --active | awk -F: '$2 ~ /^(vpn|wireguard)$/ {print $1}' | while read u; do [ -n \"$u\" ] && nmcli connection down uuid \"$u\" || true; done\n` +
                           upCmd + `\n`
            vpnSwitch.command = ["bash", "-lc", script]
            vpnSwitch.running = true
        } else {
            if (_looksLikeUuid(uuidOrName)) {
                vpnUp.command = ["nmcli", "connection", "up", "uuid", uuidOrName]
            } else {
                vpnUp.command = ["nmcli", "connection", "up", "id", uuidOrName]
            }
            vpnUp.running = true
        }
    }

    function disconnect(uuidOrName) {
        if (root.isBusy) return
        root.isBusy = true
        root.errorMessage = ""
        if (_looksLikeUuid(uuidOrName)) {
            vpnDown.command = ["nmcli", "connection", "down", "uuid", uuidOrName]
        } else {
            vpnDown.command = ["nmcli", "connection", "down", "id", uuidOrName]
        }
        vpnDown.running = true
    }

    function toggle(uuid) {
        if (uuid) {
            if (isActiveUuid(uuid)) disconnect(uuid)
            else connect(uuid)
            return
        }
        if (root.profiles.length > 0) {
            connect(root.profiles[0].uuid)
        }
    }

    Process {
        id: vpnUp
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.isBusy = false
                if (!text.toLowerCase().includes("successfully")) {
                    root.errorMessage = text.trim()
                }
                refreshAll()
            }
        }
        onExited: exitCode => {
            root.isBusy = false
            if (exitCode !== 0 && root.errorMessage === "") {
                root.errorMessage = "Failed to connect VPN"
            }
        }
    }

    Process {
        id: vpnDown
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.isBusy = false
                if (!text.toLowerCase().includes("deactivated") && !text.toLowerCase().includes("successfully")) {
                    root.errorMessage = text.trim()
                }
                refreshAll()
            }
        }
        onExited: exitCode => {
            root.isBusy = false
            if (exitCode !== 0 && root.errorMessage === "") {
                root.errorMessage = "Failed to disconnect VPN"
            }
        }
    }

    function disconnectAllActive() {
        if (root.isBusy) return
        root.isBusy = true
        const script = `nmcli -t -f UUID,TYPE connection show --active | awk -F: '$2 ~ /^(vpn|wireguard)$/ {print $1}' | while read u; do [ -n \"$u\" ] && nmcli connection down uuid \"$u\" || true; done`
        vpnSwitch.command = ["bash", "-lc", script]
        vpnSwitch.running = true
    }

    Process {
        id: vpnSwitch
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.isBusy = false
                refreshAll()
            }
        }
        onExited: exitCode => {
            root.isBusy = false
            if (exitCode !== 0 && root.errorMessage === "") {
                root.errorMessage = "Failed to switch VPN"
            }
        }
    }
}
