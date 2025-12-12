import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.Modals.FileBrowser
import qs.Services
import qs.Widgets

DarkModal {
    id: root

    Component.onCompleted: {
        console.log("[VpnAddModal] Component created")
    }

    Component.onDestruction: {
        console.log("[VpnAddModal] Component destroyed")
    }

    property int selectedVpnType: 0
    property var vpnTypes: ["OpenVPN", "WireGuard", "IKEv2", "L2TP/IPsec", "PPTP", "StrongSwan", "Cisco AnyConnect"]
    
    property string connectionName: ""
    property string openvpnServer: ""
    property string openvpnPort: "1194"
    property string openvpnProtocol: "udp"
    property string openvpnUsername: ""
    property string openvpnPassword: ""
    property string openvpnConfigFile: ""
    
    property string wireguardPrivateKey: ""
    property string wireguardPublicKey: ""
    property string wireguardEndpoint: ""
    property string wireguardAllowedIPs: "0.0.0.0/0"
    property string wireguardAddress: ""
    property string wireguardPresharedKey: ""
    property string wireguardMTU: ""
    property string wireguardDNS: ""
    property string wireguardPersistentKeepalive: ""
    
    property string ikev2Address: ""
    property string ikev2Username: ""
    property string ikev2Password: ""
    
    property string l2tpAddress: ""
    property string l2tpUsername: ""
    property string l2tpPassword: ""
    property string l2tpPsk: ""
    
    property string pptpAddress: ""
    property string pptpUsername: ""
    property string pptpPassword: ""
    
    property string strongswanAddress: ""
    property string strongswanCertificate: ""
    property string strongswanMethod: "eap"
    property string strongswanUsername: ""
    property string strongswanPassword: ""
    
    property string ciscoAddress: ""
    property string ciscoUsername: ""
    property string ciscoPassword: ""
    property string ciscoGroup: ""
    
    property bool importingFile: false
    property bool generatingKeys: false
    property string errorMessage: ""

    onVisibleChanged: {
        console.log("[VpnAddModal] visible changed to:", visible)
    }

    onShouldBeVisibleChanged: {
        console.log("[VpnAddModal] shouldBeVisible changed to:", shouldBeVisible)
    }

    function show() {
        console.log("[VpnAddModal] show() called")
        try {
            reset()
            console.log("[VpnAddModal] reset() completed, calling open()")
            open()
            console.log("[VpnAddModal] open() completed")
        } catch (error) {
            console.error("[VpnAddModal] Error in show():", error, error.stack)
        }
    }

    function reset() {
        console.log("[VpnAddModal] reset() called")
        try {
            selectedVpnType = 0
            connectionName = ""
            openvpnServer = ""
            openvpnPort = "1194"
            openvpnProtocol = "udp"
            openvpnUsername = ""
            openvpnPassword = ""
            openvpnConfigFile = ""
            wireguardPrivateKey = ""
            wireguardPublicKey = ""
            wireguardEndpoint = ""
            wireguardAllowedIPs = "0.0.0.0/0"
            wireguardAddress = ""
            wireguardPresharedKey = ""
            wireguardMTU = ""
            wireguardDNS = ""
            wireguardPersistentKeepalive = ""
        ikev2Address = ""
        ikev2Username = ""
        ikev2Password = ""
        l2tpAddress = ""
        l2tpUsername = ""
        l2tpPassword = ""
        l2tpPsk = ""
        pptpAddress = ""
        pptpUsername = ""
        pptpPassword = ""
        strongswanAddress = ""
        strongswanCertificate = ""
        strongswanMethod = "eap"
        strongswanUsername = ""
        strongswanPassword = ""
        ciscoAddress = ""
        ciscoUsername = ""
        ciscoPassword = ""
        ciscoGroup = ""
        importingFile = false
        generatingKeys = false
        errorMessage = ""
            console.log("[VpnAddModal] reset() completed")
        } catch (error) {
            console.error("[VpnAddModal] Error in reset():", error, error.stack)
        }
    }

    function importOvpnFile(filePath) {
        console.log("[VpnAddModal] importOvpnFile() called with path:", filePath)
        try {
            importingFile = true
            errorMessage = ""
            importProcess.command = ["nmcli", "connection", "import", "type", "openvpn", "file", filePath]
            console.log("[VpnAddModal] Starting import process with command:", importProcess.command)
            importProcess.running = true
        } catch (error) {
            console.error("[VpnAddModal] Error in importOvpnFile():", error, error.stack)
            importingFile = false
            errorMessage = "Error importing file: " + error.toString()
        }
    }

    function importWireGuardConf(filePath) {
        console.log("[VpnAddModal] importWireGuardConf() called with path:", filePath)
        try {
            importingFile = true
            errorMessage = ""
            
            importProcess.command = ["nmcli", "connection", "import", "type", "wireguard", "file", filePath]
            console.log("[VpnAddModal] Starting WireGuard import process with command:", importProcess.command)
            importProcess.running = true
        } catch (error) {
            console.error("[VpnAddModal] Error in importWireGuardConf():", error, error.stack)
            importingFile = false
            errorMessage = "Error importing file: " + error.toString()
        }
    }

    function generateWireGuardKeys() {
        console.log("[VpnAddModal] generateWireGuardKeys() called")
        try {
            generatingKeys = true
            errorMessage = ""
            generateKeysProcess.running = true
            console.log("[VpnAddModal] WireGuard key generation process started")
        } catch (error) {
            console.error("[VpnAddModal] Error in generateWireGuardKeys():", error, error.stack)
            generatingKeys = false
            errorMessage = "Error generating keys: " + error.toString()
        }
    }

    function addOpenVPNConnection() {
        console.log("[VpnAddModal] addOpenVPNConnection() called")
        try {
            if (!connectionName.trim()) {
                console.warn("[VpnAddModal] Connection name is missing")
                errorMessage = "Connection name is required"
                return
            }
            if (!openvpnServer.trim()) {
                console.warn("[VpnAddModal] Server address is missing")
                errorMessage = "Server address is required"
                return
            }

            errorMessage = ""
            const vpnData = `remote=${openvpnServer},port=${openvpnPort},proto=${openvpnProtocol}`
            const vpnDataWithUser = openvpnUsername.trim() ? `${vpnData},username=${openvpnUsername}` : vpnData
            const vpnSecrets = openvpnPassword.trim() ? `password=${openvpnPassword}` : ""

            let cmd = ["nmcli", "connection", "add", "type", "vpn", "vpn-type", "openvpn", "con-name", connectionName.trim()]
            
            if (vpnDataWithUser) {
                cmd.push("vpn.data", vpnDataWithUser)
            }
            if (vpnSecrets) {
                cmd.push("vpn.secrets", vpnSecrets)
            }
            cmd.push("ipv4.method", "auto")

            console.log("[VpnAddModal] OpenVPN command:", cmd)
            addConnectionProcess.command = cmd
            addConnectionProcess.running = true
        } catch (error) {
            console.error("[VpnAddModal] Error in addOpenVPNConnection():", error, error.stack)
            errorMessage = "Error creating OpenVPN connection: " + error.toString()
        }
    }

    function addWireGuardConnection() {
        console.log("[VpnAddModal] addWireGuardConnection() called")
        try {
            if (!connectionName.trim()) {
                console.warn("[VpnAddModal] Connection name is missing")
                errorMessage = "Connection name is required"
                return
            }
            if (!wireguardPrivateKey.trim()) {
                console.warn("[VpnAddModal] Private key is missing")
                errorMessage = "Private key is required"
                return
            }
            if (!wireguardEndpoint.trim()) {
                console.warn("[VpnAddModal] Endpoint is missing")
                errorMessage = "Endpoint is required"
                return
            }
            if (!wireguardPublicKey.trim()) {
                console.warn("[VpnAddModal] Server public key is missing")
                errorMessage = "Server public key is required"
                return
            }

            errorMessage = ""
            const peerConfig = {
                "public-key": wireguardPublicKey.trim(),
                "endpoint": wireguardEndpoint.trim(),
                "allowed-ips": wireguardAllowedIPs.trim() || "0.0.0.0/0"
            }
            if (wireguardPresharedKey.trim()) {
                peerConfig["preshared-key"] = wireguardPresharedKey.trim()
            }
            if (wireguardPersistentKeepalive.trim()) {
                peerConfig["persistent-keepalive"] = parseInt(wireguardPersistentKeepalive.trim()) || 0
            }

            function isIPv6(address) {
                return address.includes(':')
            }

            function splitAddresses(addressString) {
                const addresses = addressString.split(',').map(addr => addr.trim()).filter(addr => addr)
                const ipv4 = []
                const ipv6 = []
                for (const addr of addresses) {
                    if (isIPv6(addr)) {
                        ipv6.push(addr)
                    } else {
                        ipv4.push(addr)
                    }
                }
                return { ipv4: ipv4.join(','), ipv6: ipv6.join(',') }
            }

            function splitDNS(dnsString) {
                const dnsServers = dnsString.split(',').map(dns => dns.trim()).filter(dns => dns)
                const ipv4 = []
                const ipv6 = []
                for (const dns of dnsServers) {
                    if (isIPv6(dns)) {
                        ipv6.push(dns)
                    } else {
                        ipv4.push(dns)
                    }
                }
                return { ipv4: ipv4.join(','), ipv6: ipv6.join(',') }
            }

            let cmd = ["nmcli", "connection", "add", "type", "wireguard", "con-name", connectionName.trim()]
            cmd.push("wireguard.private-key", wireguardPrivateKey.trim())
            cmd.push("wireguard.peers", JSON.stringify([peerConfig]))
            
            if (wireguardAddress.trim()) {
                const addresses = splitAddresses(wireguardAddress.trim())
                if (addresses.ipv4) {
                    cmd.push("ipv4.addresses", addresses.ipv4)
                    cmd.push("ipv4.method", "manual")
                } else {
                    cmd.push("ipv4.method", "auto")
                }
                if (addresses.ipv6) {
                    cmd.push("ipv6.addresses", addresses.ipv6)
                    cmd.push("ipv6.method", "manual")
                } else {
                    cmd.push("ipv6.method", "auto")
                }
            } else {
                cmd.push("ipv4.method", "auto")
                cmd.push("ipv6.method", "auto")
            }
            
            if (wireguardMTU.trim()) {
                cmd.push("wireguard.mtu", wireguardMTU.trim())
            }
            
            if (wireguardDNS.trim()) {
                const dns = splitDNS(wireguardDNS.trim())
                if (dns.ipv4) {
                    cmd.push("ipv4.dns", dns.ipv4)
                }
                if (dns.ipv6) {
                    cmd.push("ipv6.dns", dns.ipv6)
                }
            }

            console.log("[VpnAddModal] WireGuard command:", cmd)
            addConnectionProcess.command = cmd
            addConnectionProcess.running = true
        } catch (error) {
            console.error("[VpnAddModal] Error in addWireGuardConnection():", error, error.stack)
            errorMessage = "Error creating WireGuard connection: " + error.toString()
        }
    }

    function addIKEv2Connection() {
        console.log("[VpnAddModal] addIKEv2Connection() called")
        try {
            if (!connectionName.trim()) {
                console.warn("[VpnAddModal] Connection name is missing")
                errorMessage = "Connection name is required"
                return
            }
            if (!ikev2Address.trim()) {
                console.warn("[VpnAddModal] Server address is missing")
                errorMessage = "Server address is required"
                return
            }

            errorMessage = ""
            const vpnData = `address=${ikev2Address.trim()}`
            const vpnSecrets = ikev2Password.trim() ? `password=${ikev2Password}` : ""

            let cmd = ["nmcli", "connection", "add", "type", "vpn", "vpn-type", "ikev2", "con-name", connectionName.trim()]
            cmd.push("vpn.data", vpnData)
            if (ikev2Username.trim()) {
                cmd.push("vpn.data", `${vpnData},user=${ikev2Username.trim()}`)
            }
            if (vpnSecrets) {
                cmd.push("vpn.secrets", vpnSecrets)
            }
            cmd.push("ipv4.method", "auto")

            console.log("[VpnAddModal] IKEv2 command:", cmd)
            addConnectionProcess.command = cmd
            addConnectionProcess.running = true
        } catch (error) {
            console.error("[VpnAddModal] Error in addIKEv2Connection():", error, error.stack)
            errorMessage = "Error creating IKEv2 connection: " + error.toString()
        }
    }

    function addL2TPConnection() {
        console.log("[VpnAddModal] addL2TPConnection() called")
        try {
            if (!connectionName.trim()) {
                console.warn("[VpnAddModal] Connection name is missing")
                errorMessage = "Connection name is required"
                return
            }
            if (!l2tpAddress.trim()) {
                console.warn("[VpnAddModal] Server address is missing")
                errorMessage = "Server address is required"
                return
            }

            errorMessage = ""
            const vpnData = `gateway=${l2tpAddress.trim()}`
            const vpnSecrets = []
            if (l2tpUsername.trim()) {
                vpnSecrets.push(`user=${l2tpUsername.trim()}`)
            }
            if (l2tpPassword.trim()) {
                vpnSecrets.push(`password=${l2tpPassword.trim()}`)
            }
            if (l2tpPsk.trim()) {
                vpnSecrets.push(`ipsec-psk=${l2tpPsk.trim()}`)
            }

            let cmd = ["nmcli", "connection", "add", "type", "vpn", "vpn-type", "l2tp", "con-name", connectionName.trim()]
            cmd.push("vpn.data", vpnData)
            if (vpnSecrets.length > 0) {
                cmd.push("vpn.secrets", vpnSecrets.join(","))
            }
            cmd.push("ipv4.method", "auto")

            console.log("[VpnAddModal] L2TP command:", cmd)
            addConnectionProcess.command = cmd
            addConnectionProcess.running = true
        } catch (error) {
            console.error("[VpnAddModal] Error in addL2TPConnection():", error, error.stack)
            errorMessage = "Error creating L2TP connection: " + error.toString()
        }
    }

    function addPPTPConnection() {
        console.log("[VpnAddModal] addPPTPConnection() called")
        try {
            if (!connectionName.trim()) {
                console.warn("[VpnAddModal] Connection name is missing")
                errorMessage = "Connection name is required"
                return
            }
            if (!pptpAddress.trim()) {
                console.warn("[VpnAddModal] Server address is missing")
                errorMessage = "Server address is required"
                return
            }

            errorMessage = ""
            const vpnData = `gateway=${pptpAddress.trim()}`
            const vpnSecrets = []
            if (pptpUsername.trim()) {
                vpnSecrets.push(`user=${pptpUsername.trim()}`)
            }
            if (pptpPassword.trim()) {
                vpnSecrets.push(`password=${pptpPassword.trim()}`)
            }

            let cmd = ["nmcli", "connection", "add", "type", "vpn", "vpn-type", "pptp", "con-name", connectionName.trim()]
            cmd.push("vpn.data", vpnData)
            if (vpnSecrets.length > 0) {
                cmd.push("vpn.secrets", vpnSecrets.join(","))
            }
            cmd.push("ipv4.method", "auto")

            console.log("[VpnAddModal] PPTP command:", cmd)
            addConnectionProcess.command = cmd
            addConnectionProcess.running = true
        } catch (error) {
            console.error("[VpnAddModal] Error in addPPTPConnection():", error, error.stack)
            errorMessage = "Error creating PPTP connection: " + error.toString()
        }
    }

    function addStrongSwanConnection() {
        console.log("[VpnAddModal] addStrongSwanConnection() called")
        try {
            if (!connectionName.trim()) {
                console.warn("[VpnAddModal] Connection name is missing")
                errorMessage = "Connection name is required"
                return
            }
            if (!strongswanAddress.trim()) {
                console.warn("[VpnAddModal] Server address is missing")
                errorMessage = "Server address is required"
                return
            }

            errorMessage = ""
            let vpnData = `address=${strongswanAddress.trim()},method=${strongswanMethod}`
            if (strongswanCertificate.trim()) {
                vpnData += `,certificate=${strongswanCertificate.trim()}`
            }
            const vpnSecrets = []
            if (strongswanUsername.trim()) {
                vpnSecrets.push(`user=${strongswanUsername.trim()}`)
            }
            if (strongswanPassword.trim()) {
                vpnSecrets.push(`password=${strongswanPassword.trim()}`)
            }

            let cmd = ["nmcli", "connection", "add", "type", "vpn", "vpn-type", "strongswan", "con-name", connectionName.trim()]
            cmd.push("vpn.data", vpnData)
            if (vpnSecrets.length > 0) {
                cmd.push("vpn.secrets", vpnSecrets.join(","))
            }
            cmd.push("ipv4.method", "auto")

            console.log("[VpnAddModal] StrongSwan command:", cmd)
            addConnectionProcess.command = cmd
            addConnectionProcess.running = true
        } catch (error) {
            console.error("[VpnAddModal] Error in addStrongSwanConnection():", error, error.stack)
            errorMessage = "Error creating StrongSwan connection: " + error.toString()
        }
    }

    function addCiscoConnection() {
        console.log("[VpnAddModal] addCiscoConnection() called")
        try {
            if (!connectionName.trim()) {
                console.warn("[VpnAddModal] Connection name is missing")
                errorMessage = "Connection name is required"
                return
            }
            if (!ciscoAddress.trim()) {
                console.warn("[VpnAddModal] Server address is missing")
                errorMessage = "Server address is required"
                return
            }

            errorMessage = ""
            const vpnData = `gateway=${ciscoAddress.trim()}`
            if (ciscoGroup.trim()) {
                vpnData += `,group=${ciscoGroup.trim()}`
            }
            const vpnSecrets = []
            if (ciscoUsername.trim()) {
                vpnSecrets.push(`user=${ciscoUsername.trim()}`)
            }
            if (ciscoPassword.trim()) {
                vpnSecrets.push(`password=${ciscoPassword.trim()}`)
            }

            let cmd = ["nmcli", "connection", "add", "type", "vpn", "vpn-type", "openconnect", "con-name", connectionName.trim()]
            cmd.push("vpn.data", vpnData)
            if (vpnSecrets.length > 0) {
                cmd.push("vpn.secrets", vpnSecrets.join(","))
            }
            cmd.push("ipv4.method", "auto")

            console.log("[VpnAddModal] Cisco AnyConnect command:", cmd)
            addConnectionProcess.command = cmd
            addConnectionProcess.running = true
        } catch (error) {
            console.error("[VpnAddModal] Error in addCiscoConnection():", error, error.stack)
            errorMessage = "Error creating Cisco AnyConnect connection: " + error.toString()
        }
    }

    function saveConnection() {
        console.log("[VpnAddModal] saveConnection() called, selectedVpnType:", selectedVpnType)
        try {
            errorMessage = ""
            if (selectedVpnType === 0) {
                addOpenVPNConnection()
            } else if (selectedVpnType === 1) {
                addWireGuardConnection()
            } else if (selectedVpnType === 2) {
                addIKEv2Connection()
            } else if (selectedVpnType === 3) {
                addL2TPConnection()
            } else if (selectedVpnType === 4) {
                addPPTPConnection()
            } else if (selectedVpnType === 5) {
                addStrongSwanConnection()
            } else if (selectedVpnType === 6) {
                addCiscoConnection()
            } else {
                console.error("[VpnAddModal] Unknown VPN type:", selectedVpnType)
                errorMessage = "Unknown VPN type selected"
            }
        } catch (error) {
            console.error("[VpnAddModal] Error in saveConnection():", error, error.stack)
            errorMessage = "Error saving connection: " + error.toString()
        }
    }

    shouldBeVisible: false
    width: 900
    height: 800
    positioning: "center"
    enableShadow: true
    allowStacking: true

    onOpened: {
        console.log("[VpnAddModal] Modal opened signal")
    }

    onDialogClosed: {
        console.log("[VpnAddModal] Modal closed signal")
    }

    Connections {
        function onCloseAllModalsExcept(excludedModal) {
            console.log("[VpnAddModal] closeAllModalsExcept called, excludedModal:", excludedModal, "root:", root, "allowStacking:", allowStacking)
            if (excludedModal !== root && !allowStacking && shouldBeVisible) {
                console.log("[VpnAddModal] Closing due to another modal opening")
                root.close()
            }
        }
        target: ModalManager
    }
    
    onBackgroundClicked: () => {
        console.log("[VpnAddModal] Background clicked")
        close()
    }

    content: Component {
        FocusScope {
            id: contentScope
            anchors.fill: parent
            focus: true

            Component.onCompleted: {
                console.log("[VpnAddModal] Content component created")
                console.log("[VpnAddModal] Content scope focus:", focus)
                console.log("[VpnAddModal] Parent modal visible:", root.visible)
                console.log("[VpnAddModal] Parent modal shouldBeVisible:", root.shouldBeVisible)
            }

            Component.onDestruction: {
                console.log("[VpnAddModal] Content component destroyed")
                console.log("[VpnAddModal] Destruction stack trace:", new Error().stack)
            }

            onActiveFocusChanged: {
                console.log("[VpnAddModal] Content scope activeFocus changed to:", activeFocus)
            }
            
            Keys.onEscapePressed: event => {
                console.log("[VpnAddModal] Escape key pressed")
                root.close()
                event.accepted = true
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM
                clip: true

                RowLayout {
                    width: parent.width
                    spacing: Theme.spacingM

                    DarkIcon {
                        name: "vpn_key"
                        size: Theme.iconSize
                        color: Theme.primary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Column {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Add VPN Connection"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: "Configure a new VPN connection"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }

                    Item { Layout.fillWidth: true }

                    DarkActionButton {
                        iconName: "close"
                        iconSize: Theme.iconSize - 4
                        iconColor: Theme.surfaceText
                        onClicked: () => {
                            console.log("[VpnAddModal] Close button clicked")
                            root.close()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.5
                }

                StyledText {
                    text: "VPN Type"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.vpnTypes

                        Rectangle {
                            property bool isSelected: root.selectedVpnType === index
                            
                            TextMetrics {
                                id: vpnTypeTextMetrics
                                font.pixelSize: Theme.fontSizeSmall
                                text: modelData
                            }
                            
                            implicitWidth: vpnTypeTextMetrics.width + Theme.spacingS * 2
                            implicitHeight: 32
                            width: implicitWidth
                            height: implicitHeight
                            radius: Theme.cornerRadius * 0.5
                            color: isSelected ? Theme.primary : Theme.surfaceContainer

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: Theme.fontSizeSmall
                                color: isSelected ? Theme.onPrimary : Theme.surfaceText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedVpnType = index
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.5
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: root.selectedVpnType === 0

                    StyledText {
                        text: "OpenVPN Configuration"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Connection Name"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: openvpnNameField
                            width: parent.width
                            height: 40
                            placeholderText: "My OpenVPN Connection"
                            text: root.connectionName
                            onTextChanged: root.connectionName = text
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Server Address"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: openvpnServerField
                                width: parent.width
                                height: 40
                                placeholderText: "vpn.example.com"
                                text: root.openvpnServer
                                onTextChanged: root.openvpnServer = text
                            }
                        }

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Port"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: openvpnPortField
                                width: parent.width
                                height: 40
                                placeholderText: "1194"
                                text: root.openvpnPort
                                onTextChanged: root.openvpnPort = text
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Protocol"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            Rectangle {
                                width: parent.width
                                height: 40
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Theme.outlineVariant

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingS

                                    Repeater {
                                        model: ["udp", "tcp"]

                                        Rectangle {
                                            property bool isSelected: root.openvpnProtocol === modelData
                                            
                                            width: 60
                                            height: 28
                                            radius: Theme.cornerRadius * 0.5
                                            color: isSelected ? Theme.primary : "transparent"

                                            StyledText {
                                                anchors.centerIn: parent
                                                text: modelData.toUpperCase()
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: isSelected ? Theme.onPrimary : Theme.surfaceText
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.openvpnProtocol = modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { width: (parent.width - Theme.spacingM) / 2; height: 1 }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Username (optional)"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: openvpnUsernameField
                                width: parent.width
                                height: 40
                                placeholderText: "username"
                                text: root.openvpnUsername
                                onTextChanged: root.openvpnUsername = text
                            }
                        }

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Password (optional)"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: openvpnPasswordField
                                width: parent.width
                                height: 40
                                placeholderText: "password"
                                echoMode: TextInput.Password
                                text: root.openvpnPassword
                                onTextChanged: root.openvpnPassword = text
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: Theme.cornerRadius * 0.5
                        color: importFileMouseArea.containsMouse ? Theme.primaryContainer : Theme.primary
                        visible: !root.importingFile

                        StyledText {
                            anchors.centerIn: parent
                            text: "Import .ovpn File"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.onPrimary
                        }

                        MouseArea {
                            id: importFileMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.openFileBrowser()
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 40
                        visible: root.importingFile

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingM

                            DarkIcon {
                                name: "sync"
                                size: 20
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter

                                RotationAnimation on rotation {
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                    running: root.importingFile
                                }
                            }

                            StyledText {
                                text: "Importing..."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: root.selectedVpnType === 1

                    StyledText {
                        text: "WireGuard Configuration"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Connection Name"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: wireguardNameField
                            width: parent.width
                            height: 40
                            placeholderText: "My WireGuard Connection"
                            text: root.connectionName
                            onTextChanged: root.connectionName = text
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Private Key"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            DarkTextField {
                                id: wireguardPrivateKeyField
                                width: parent.width - generateKeysButton.width - Theme.spacingS
                                height: 40
                                placeholderText: "Generate or paste private key"
                                echoMode: TextInput.Password
                                text: root.wireguardPrivateKey
                                onTextChanged: root.wireguardPrivateKey = text
                            }

                            Rectangle {
                                id: generateKeysButton
                                width: 120
                                height: 40
                                radius: Theme.cornerRadius * 0.5
                                color: generateKeysMouseArea.containsMouse ? Theme.primaryContainer : Theme.primary
                                visible: !root.generatingKeys

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "Generate"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.onPrimary
                                }

                                MouseArea {
                                    id: generateKeysMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.generateWireGuardKeys()
                                }
                            }

                            Item {
                                width: 120
                                height: 40
                                visible: root.generatingKeys

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    DarkIcon {
                                        name: "sync"
                                        size: 16
                                        color: Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter

                                        RotationAnimation on rotation {
                                            from: 0
                                            to: 360
                                            duration: 1000
                                            loops: Animation.Infinite
                                            running: root.generatingKeys
                                        }
                                    }

                                    StyledText {
                                        text: "Generating..."
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Server Public Key"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: wireguardPublicKeyField
                            width: parent.width
                            height: 40
                            placeholderText: "Server's public key"
                            text: root.wireguardPublicKey
                            onTextChanged: root.wireguardPublicKey = text
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Endpoint"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: wireguardEndpointField
                                width: parent.width
                                height: 40
                                placeholderText: "server.example.com:51820"
                                text: root.wireguardEndpoint
                                onTextChanged: root.wireguardEndpoint = text
                            }
                        }

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Allowed IPs"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: wireguardAllowedIPsField
                                width: parent.width
                                height: 40
                                placeholderText: "0.0.0.0/0"
                                text: root.wireguardAllowedIPs
                                onTextChanged: root.wireguardAllowedIPs = text
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Client IP Address (optional)"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: wireguardAddressField
                            width: parent.width
                            height: 40
                            placeholderText: "10.0.0.2/24"
                            text: root.wireguardAddress
                            onTextChanged: root.wireguardAddress = text
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: Theme.cornerRadius * 0.5
                        color: importWireGuardMouseArea.containsMouse ? Theme.primaryContainer : Theme.surfaceContainer
                        border.width: 1
                        border.color: Theme.outlineVariant

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DarkIcon {
                                name: "file_upload"
                                size: 18
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "Import .conf file"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: importWireGuardMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[VpnAddModal] Import WireGuard conf button clicked")
                                root.openWireGuardFileBrowser()
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 40
                        visible: root.importingFile && root.selectedVpnType === 1

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingM

                            DarkIcon {
                                name: "sync"
                                size: 20
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter

                                RotationAnimation on rotation {
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                    running: root.importingFile && root.selectedVpnType === 1
                                }
                            }

                            StyledText {
                                text: "Importing..."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: root.selectedVpnType === 2

                    StyledText {
                        text: "IKEv2 Configuration"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Connection Name"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: ikev2NameField
                            width: parent.width
                            height: 40
                            placeholderText: "My IKEv2 Connection"
                            text: root.connectionName
                            onTextChanged: root.connectionName = text
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Server Address"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: ikev2AddressField
                            width: parent.width
                            height: 40
                            placeholderText: "vpn.example.com"
                            text: root.ikev2Address
                            onTextChanged: root.ikev2Address = text
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Username"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: ikev2UsernameField
                                width: parent.width
                                height: 40
                                placeholderText: "username"
                                text: root.ikev2Username
                                onTextChanged: root.ikev2Username = text
                            }
                        }

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Password"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: ikev2PasswordField
                                width: parent.width
                                height: 40
                                placeholderText: "password"
                                echoMode: TextInput.Password
                                text: root.ikev2Password
                                onTextChanged: root.ikev2Password = text
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: root.selectedVpnType === 3

                    StyledText {
                        text: "L2TP/IPsec Configuration"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Connection Name"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: l2tpNameField
                            width: parent.width
                            height: 40
                            placeholderText: "My L2TP Connection"
                            text: root.connectionName
                            onTextChanged: root.connectionName = text
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Server Address"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: l2tpAddressField
                            width: parent.width
                            height: 40
                            placeholderText: "vpn.example.com"
                            text: root.l2tpAddress
                            onTextChanged: root.l2tpAddress = text
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Username"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: l2tpUsernameField
                                width: parent.width
                                height: 40
                                placeholderText: "username"
                                text: root.l2tpUsername
                                onTextChanged: root.l2tpUsername = text
                            }
                        }

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Password"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: l2tpPasswordField
                                width: parent.width
                                height: 40
                                placeholderText: "password"
                                echoMode: TextInput.Password
                                text: root.l2tpPassword
                                onTextChanged: root.l2tpPassword = text
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Pre-shared Key (PSK)"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: l2tpPskField
                            width: parent.width
                            height: 40
                            placeholderText: "IPsec pre-shared key"
                            echoMode: TextInput.Password
                            text: root.l2tpPsk
                            onTextChanged: root.l2tpPsk = text
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: root.selectedVpnType === 4

                    StyledText {
                        text: "PPTP Configuration"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Warning: PPTP is deprecated and insecure. Use only if necessary."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.error
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Connection Name"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: pptpNameField
                            width: parent.width
                            height: 40
                            placeholderText: "My PPTP Connection"
                            text: root.connectionName
                            onTextChanged: root.connectionName = text
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Server Address"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: pptpAddressField
                            width: parent.width
                            height: 40
                            placeholderText: "vpn.example.com"
                            text: root.pptpAddress
                            onTextChanged: root.pptpAddress = text
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Username"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: pptpUsernameField
                                width: parent.width
                                height: 40
                                placeholderText: "username"
                                text: root.pptpUsername
                                onTextChanged: root.pptpUsername = text
                            }
                        }

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Password"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: pptpPasswordField
                                width: parent.width
                                height: 40
                                placeholderText: "password"
                                echoMode: TextInput.Password
                                text: root.pptpPassword
                                onTextChanged: root.pptpPassword = text
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: root.selectedVpnType === 5

                    StyledText {
                        text: "StrongSwan Configuration"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Connection Name"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: strongswanNameField
                            width: parent.width
                            height: 40
                            placeholderText: "My StrongSwan Connection"
                            text: root.connectionName
                            onTextChanged: root.connectionName = text
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Server Address"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: strongswanAddressField
                            width: parent.width
                            height: 40
                            placeholderText: "vpn.example.com"
                            text: root.strongswanAddress
                            onTextChanged: root.strongswanAddress = text
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Authentication Method"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        Rectangle {
                            width: parent.width
                            height: 40
                            radius: Theme.cornerRadius * 0.5
                            color: Theme.surfaceContainer
                            border.width: 1
                            border.color: Theme.outlineVariant

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingS

                                Repeater {
                                    model: ["eap", "psk", "cert"]

                                    Rectangle {
                                        property bool isSelected: root.strongswanMethod === modelData
                                        
                                        width: 80
                                        height: 28
                                        radius: Theme.cornerRadius * 0.5
                                        color: isSelected ? Theme.primary : "transparent"

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: modelData.toUpperCase()
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: isSelected ? Theme.onPrimary : Theme.surfaceText
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.strongswanMethod = modelData
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Username"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: strongswanUsernameField
                                width: parent.width
                                height: 40
                                placeholderText: "username"
                                text: root.strongswanUsername
                                onTextChanged: root.strongswanUsername = text
                            }
                        }

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Password"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: strongswanPasswordField
                                width: parent.width
                                height: 40
                                placeholderText: "password"
                                echoMode: TextInput.Password
                                text: root.strongswanPassword
                                onTextChanged: root.strongswanPassword = text
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Certificate Path (optional)"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: strongswanCertificateField
                            width: parent.width
                            height: 40
                            placeholderText: "/path/to/certificate.pem"
                            text: root.strongswanCertificate
                            onTextChanged: root.strongswanCertificate = text
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: root.selectedVpnType === 6

                    StyledText {
                        text: "Cisco AnyConnect Configuration"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Connection Name"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: ciscoNameField
                            width: parent.width
                            height: 40
                            placeholderText: "My Cisco AnyConnect Connection"
                            text: root.connectionName
                            onTextChanged: root.connectionName = text
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Server Address"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: ciscoAddressField
                            width: parent.width
                            height: 40
                            placeholderText: "vpn.example.com"
                            text: root.ciscoAddress
                            onTextChanged: root.ciscoAddress = text
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Username"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: ciscoUsernameField
                                width: parent.width
                                height: 40
                                placeholderText: "username"
                                text: root.ciscoUsername
                                onTextChanged: root.ciscoUsername = text
                            }
                        }

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Password"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            DarkTextField {
                                id: ciscoPasswordField
                                width: parent.width
                                height: 40
                                placeholderText: "password"
                                echoMode: TextInput.Password
                                text: root.ciscoPassword
                                onTextChanged: root.ciscoPassword = text
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Group (optional)"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        DarkTextField {
                            id: ciscoGroupField
                            width: parent.width
                            height: 40
                            placeholderText: "VPN group name"
                            text: root.ciscoGroup
                            onTextChanged: root.ciscoGroup = text
                        }
                    }
                }

                Item { width: 1; height: Theme.spacingM }

                StyledText {
                    text: root.errorMessage
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.error
                    visible: root.errorMessage !== ""
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    Item { width: 1; height: 1 }

                    Rectangle {
                        width: 100
                        height: 36
                        radius: Theme.cornerRadius * 0.5
                        color: cancelMouseArea.containsMouse ? Theme.surfaceContainer : Theme.surfaceVariant

                        StyledText {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: cancelMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[VpnAddModal] Cancel button clicked")
                                root.close()
                            }
                        }
                    }

                    Rectangle {
                        width: 100
                        height: 36
                        radius: Theme.cornerRadius * 0.5
                        color: saveMouseArea.containsMouse ? Theme.primaryContainer : Theme.primary

                        StyledText {
                            anchors.centerIn: parent
                            text: "Add"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.onPrimary
                        }

                        MouseArea {
                            id: saveMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: saveConnection()
                        }
                    }
                }
            }
        }
    }

    property bool pendingFileBrowserOpen: false

    Loader {
        id: fileBrowserLoader
        active: false
        asynchronous: true
        
        onStatusChanged: {
            console.log("[VpnAddModal] fileBrowserLoader status changed to:", status)
            if (status === Loader.Ready) {
                console.log("[VpnAddModal] fileBrowserLoader is ready, item:", item)
                if (pendingFileBrowserOpen && item && typeof item.open === 'function') {
                    console.log("[VpnAddModal] Opening FileBrowserModal now that it's ready")
                    Qt.callLater(() => {
                        if (item && typeof item.open === 'function') {
                            item.open()
                            pendingFileBrowserOpen = false
                        }
                    })
                }
            } else if (status === Loader.Error) {
                console.error("[VpnAddModal] fileBrowserLoader error:", sourceComponent)
                pendingFileBrowserOpen = false
            }
        }
        
        onItemChanged: {
            console.log("[VpnAddModal] fileBrowserLoader item changed:", item)
            if (item && fileBrowserLoader.status === Loader.Ready && pendingFileBrowserOpen) {
                console.log("[VpnAddModal] FileBrowserLoader item is ready, opening now")
                Qt.callLater(() => {
                    if (item && typeof item.open === 'function') {
                        item.open()
                        pendingFileBrowserOpen = false
                    }
                })
            }
        }
        
        sourceComponent: Component {
            FileBrowserModal {
                Component.onCompleted: {
                    console.log("[VpnAddModal] FileBrowserModal component created")
                }
                
                browserTitle: root.selectedVpnType === 1 ? "Select WireGuard Configuration File" : "Select OpenVPN Configuration File"
                browserIcon: "vpn_key"
                browserType: "generic"
                fileExtensions: root.selectedVpnType === 1 ? ["*.conf"] : ["*.ovpn"]
                showHiddenFiles: true
                allowStacking: true

                onFileSelected: path => {
                    console.log("[VpnAddModal] File selected:", path, "for VPN type:", root.selectedVpnType)
                    try {
                        const cleanPath = path.replace(/^file:\/\//, '')
                        console.log("[VpnAddModal] Cleaned path:", cleanPath)
                        if (root.selectedVpnType === 1) {
                            root.importWireGuardConf(cleanPath)
                        } else {
                            root.importOvpnFile(cleanPath)
                        }
                        if (fileBrowserLoader.item) {
                            fileBrowserLoader.item.close()
                        }
                    } catch (error) {
                        console.error("[VpnAddModal] Error in onFileSelected:", error, error.stack)
                    }
                }
            }
        }
    }

    function openFileBrowser() {
        console.log("[VpnAddModal] openFileBrowser() called")
        try {
            pendingFileBrowserOpen = true
            
            if (!fileBrowserLoader.active) {
                console.log("[VpnAddModal] Activating fileBrowserLoader")
                fileBrowserLoader.active = true
            }
            
            if (fileBrowserLoader.status === Loader.Ready && fileBrowserLoader.item) {
                console.log("[VpnAddModal] FileBrowserLoader already ready, opening immediately")
                Qt.callLater(() => {
                    if (fileBrowserLoader.item && typeof fileBrowserLoader.item.open === 'function') {
                        fileBrowserLoader.item.open()
                        pendingFileBrowserOpen = false
                    }
                })
            } else {
                console.log("[VpnAddModal] Waiting for FileBrowserLoader to be ready, status:", fileBrowserLoader.status)
            }
        } catch (error) {
            console.error("[VpnAddModal] Error in openFileBrowser():", error, error.stack)
            pendingFileBrowserOpen = false
        }
    }

    function openWireGuardFileBrowser() {
        console.log("[VpnAddModal] openWireGuardFileBrowser() called")
        openFileBrowser()
    }

    FileView {
        id: wireguardConfFileView
        blockWrites: true
        blockLoading: false
        atomicWrites: true
        printErrors: true
        
        onLoadFailed: (error) => {
            console.error("[VpnAddModal] Failed to load WireGuard conf file:", error)
            root.importingFile = false
            root.errorMessage = "Failed to read configuration file: " + (error || "Unknown error")
        }
    }

    Process {
        id: importProcess
        running: false
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[VpnAddModal] Import process stdout:", text)
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                console.log("[VpnAddModal] Import process stderr:", text)
            }
        }

        onStarted: {
            console.log("[VpnAddModal] Import process started with command:", command)
        }

        onExited: exitCode => {
            console.log("[VpnAddModal] Import process exited with code:", exitCode)
            root.importingFile = false
            if (exitCode === 0) {
                console.log("[VpnAddModal] Import successful")
                try {
                    ToastService.showInfo("VPN connection imported successfully")
                    if (VpnService) {
                        VpnService.refreshAll()
                    }
                    root.close()
                } catch (error) {
                    console.error("[VpnAddModal] Error after successful import:", error, error.stack)
                }
            } else {
                console.error("[VpnAddModal] Import failed with exit code:", exitCode)
                root.importingFile = false
                const errorMsg = stderr.text || "Failed to import configuration file"
                root.errorMessage = errorMsg
            }
        }
    }

    Process {
        id: generateKeysProcess
        running: false
        command: ["wg", "genkey"]

        onStarted: {
            console.log("[VpnAddModal] Generate keys process started")
        }

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[VpnAddModal] Private key generated, length:", text.trim().length)
                try {
                    root.wireguardPrivateKey = text.trim()
                    generatePubkeyProcess.command = ["sh", "-c", "echo '" + root.wireguardPrivateKey + "' | wg pubkey"]
                    console.log("[VpnAddModal] Starting public key generation")
                    generatePubkeyProcess.running = true
                } catch (error) {
                    console.error("[VpnAddModal] Error processing private key:", error, error.stack)
                    root.generatingKeys = false
                    root.errorMessage = "Error processing keys: " + error.toString()
                }
            }
        }
        onExited: exitCode => {
            console.log("[VpnAddModal] Generate keys process exited with code:", exitCode)
            if (exitCode !== 0) {
                root.generatingKeys = false
                root.errorMessage = "Failed to generate keys. Is WireGuard installed?"
            }
        }
    }

    Process {
        id: generatePubkeyProcess
        running: false
        command: []

        onStarted: {
            console.log("[VpnAddModal] Generate public key process started")
        }

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[VpnAddModal] Public key generated, length:", text.trim().length)
                try {
                    root.wireguardPublicKey = text.trim()
                    root.generatingKeys = false
                    console.log("[VpnAddModal] Key generation completed successfully")
                } catch (error) {
                    console.error("[VpnAddModal] Error processing public key:", error, error.stack)
                    root.generatingKeys = false
                    root.errorMessage = "Error processing public key: " + error.toString()
                }
            }
        }
        onExited: exitCode => {
            console.log("[VpnAddModal] Generate public key process exited with code:", exitCode)
            root.generatingKeys = false
            if (exitCode !== 0) {
                root.errorMessage = "Failed to generate public key"
            }
        }
    }

    Process {
        id: addConnectionProcess
        running: false
        command: []

        onStarted: {
            console.log("[VpnAddModal] Add connection process started with command:", command)
        }

        onExited: exitCode => {
            console.log("[VpnAddModal] Add connection process exited with code:", exitCode)
            if (exitCode === 0) {
                console.log("[VpnAddModal] Connection added successfully")
                try {
                    ToastService.showInfo("VPN connection added successfully")
                    if (VpnService) {
                        VpnService.refreshAll()
                    }
                    root.close()
                } catch (error) {
                    console.error("[VpnAddModal] Error after successful connection add:", error, error.stack)
                }
            } else {
                console.error("[VpnAddModal] Connection add failed with exit code:", exitCode)
                root.errorMessage = "Failed to add VPN connection. Check your configuration."
            }
        }
    }
}

