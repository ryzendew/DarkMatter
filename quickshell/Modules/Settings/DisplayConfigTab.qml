import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Settings

Item {
    id: displayConfigTab

    property var monitors: []
    property var monitorCapabilities: ({})
    property var rawMonitorData: []
    property bool loading: true
    property bool hasUnsavedChanges: false
    property string originalContent: ""
    property string selectedMonitor: ""
    readonly property string monitorsConfPath: (Quickshell.env("HOME") || Paths.stringify(StandardPaths.writableLocation(StandardPaths.HomeLocation))) + "/.config/hypr/monitors.conf"
    readonly property string capabilitiesCachePath: Paths.stringify(`${StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)}/DarkMaterialShell/monitor-capabilities.json`)
    
    signal tabActivated()
    
    function getFilteredMonitors() {
        if (selectedMonitor === "") {
            return monitors
        }
        return monitors.filter(function(m) { return m.name === selectedMonitor })
    }

    function parseMonitorsConf(content) {
        var monitors = []
        var lines = content.split('\n')
        var currentMonitor = null
        var inMonitorV2Block = false
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === '' || line.startsWith('#')) continue
            
            if (line.startsWith('monitorv2') && line.includes('{')) {
                inMonitorV2Block = true
                if (currentMonitor) {
                    monitors.push(currentMonitor)
                }
                currentMonitor = {
                    name: "",
                    resolution: "",
                    position: "",
                    scale: "1",
                    refreshRate: "",
                    transform: "",
                    disabled: false,
                    bitdepth: "",
                    cm: "",
                    sdrbrightness: 1.0,
                    sdrsaturation: 1.0,
                    sdr_eotf: 0,
                    vrr: "",
                    mirror: "",
                    supports_wide_color: false,
                    supports_hdr: false,
                    sdr_min_luminance: 0.0,
                    sdr_max_luminance: 200,
                    min_luminance: 0.0,
                    max_luminance: 0,
                    max_avg_luminance: 0,
                    isV2: true
                }
                continue
            }
            
            if (inMonitorV2Block) {
                if (line === '}') {
                    inMonitorV2Block = false
                    if (currentMonitor) {
                        monitors.push(currentMonitor)
                        currentMonitor = null
                    }
                    continue
                }
                
                var keyValue = line.split('=')
                if (keyValue.length === 2) {
                    var key = keyValue[0].trim()
                    var value = keyValue[1].trim().replace(/^["']|["']$/g, '')
                    
                    if (key === 'output') {
                        currentMonitor.name = value
                    } else if (key === 'mode') {
                        if (value.includes('@')) {
                            var parts = value.split('@')
                            currentMonitor.resolution = parts[0].trim()
                            currentMonitor.refreshRate = parts[1].trim()
                        } else {
                            currentMonitor.resolution = value
                        }
                    } else if (key === 'position') {
                        currentMonitor.position = value
                    } else if (key === 'scale') {
                        currentMonitor.scale = value
                    } else if (key === 'transform') {
                        currentMonitor.transform = value
                    } else if (key === 'disabled') {
                        currentMonitor.disabled = value === 'true' || value === '1'
                    } else if (key === 'bitdepth') {
                        currentMonitor.bitdepth = value
                    } else if (key === 'cm') {
                        currentMonitor.cm = value
                    } else if (key === 'sdrbrightness') {
                        currentMonitor.sdrbrightness = parseFloat(value) || 1.0
                    } else if (key === 'sdrsaturation') {
                        currentMonitor.sdrsaturation = parseFloat(value) || 1.0
                    } else if (key === 'sdr_eotf') {
                        currentMonitor.sdr_eotf = parseInt(value) || 0
                    } else if (key === 'vrr') {
                        currentMonitor.vrr = value
                    } else if (key === 'mirror') {
                        currentMonitor.mirror = value
                    } else if (key === 'supports_wide_color') {
                        currentMonitor.supports_wide_color = value === 'true' || value === '1'
                    } else if (key === 'supports_hdr') {
                        currentMonitor.supports_hdr = value === 'true' || value === '1'
                    } else if (key === 'sdr_min_luminance') {
                        currentMonitor.sdr_min_luminance = parseFloat(value) || 0.0
                    } else if (key === 'sdr_max_luminance') {
                        currentMonitor.sdr_max_luminance = parseInt(value) || 200
                    } else if (key === 'min_luminance') {
                        currentMonitor.min_luminance = parseFloat(value) || 0.0
                    } else if (key === 'max_luminance') {
                        currentMonitor.max_luminance = parseInt(value) || 0
                    } else if (key === 'max_avg_luminance') {
                        currentMonitor.max_avg_luminance = parseInt(value) || 0
                    }
                }
                continue
            }
            
            if (line.startsWith('monitor=')) {
                if (currentMonitor) {
                    monitors.push(currentMonitor)
                }
                currentMonitor = {
                    name: "",
                    resolution: "",
                    position: "",
                    scale: "1",
                    refreshRate: "",
                    transform: "",
                    disabled: false,
                    bitdepth: "",
                    cm: "",
                    sdrbrightness: 1.0,
                    sdrsaturation: 1.0,
                    sdr_eotf: 0,
                    vrr: "",
                    mirror: "",
                    supports_wide_color: false,
                    supports_hdr: false,
                    sdr_min_luminance: 0.0,
                    sdr_max_luminance: 200,
                    min_luminance: 0.0,
                    max_luminance: 0,
                    max_avg_luminance: 0,
                    isV2: false
                }
                
                var monitorValue = line.substring(9).trim()
                if (monitorValue.startsWith('"') && monitorValue.endsWith('"')) {
                    monitorValue = monitorValue.slice(1, -1)
                }
                
                if (monitorValue === 'disable') {
                    currentMonitor.disabled = true
                    continue
                }
                
                var parts = monitorValue.split(',')
                if (parts.length > 0) {
                    var namePart = parts[0].trim()
                    if (namePart.startsWith('"') && namePart.endsWith('"')) {
                        namePart = namePart.slice(1, -1)
                    }
                    currentMonitor.name = namePart
                    
                    if (parts.length > 1) {
                        var resolutionPart = parts[1].trim()
                        if (resolutionPart.includes('@')) {
                            var resParts = resolutionPart.split('@')
                            currentMonitor.resolution = resParts[0].trim()
                            if (resParts.length > 1) {
                                currentMonitor.refreshRate = resParts[1].trim()
                            }
                        } else {
                            currentMonitor.resolution = resolutionPart
                        }
                    }
                    if (parts.length > 2) {
                        currentMonitor.position = parts[2].trim()
                    }
                    if (parts.length > 3) {
                        currentMonitor.scale = parts[3].trim()
                    }
                    if (parts.length > 4 && !currentMonitor.refreshRate) {
                        currentMonitor.refreshRate = parts[4].trim()
                    }
                    if (parts.length > 5) {
                        currentMonitor.transform = parts[5].trim()
                    }
                    
                    for (var j = 6; j < parts.length; j += 2) {
                        if (j + 1 < parts.length) {
                            var argName = parts[j].trim()
                            var argValue = parts[j + 1].trim()
                            if (argName === 'bitdepth') {
                                currentMonitor.bitdepth = argValue
                            } else if (argName === 'cm') {
                                currentMonitor.cm = argValue
                            } else if (argName === 'sdrbrightness') {
                                currentMonitor.sdrbrightness = parseFloat(argValue) || 1.0
                            } else if (argName === 'sdrsaturation') {
                                currentMonitor.sdrsaturation = parseFloat(argValue) || 1.0
                            } else if (argName === 'sdr_eotf') {
                                currentMonitor.sdr_eotf = parseInt(argValue) || 0
                            } else if (argName === 'vrr') {
                                currentMonitor.vrr = argValue
                            } else if (argName === 'mirror') {
                                currentMonitor.mirror = argValue
                            } else if (argName === 'transform') {
                                currentMonitor.transform = argValue
                            }
                        }
                    }
                }
            } 
            else if (currentMonitor && line.startsWith('monitor:')) {
                var keyValue = line.substring(8).trim().split('=')
                if (keyValue.length === 2) {
                    var key = keyValue[0].trim()
                    var value = keyValue[1].trim()
                    if (key === 'hdr') {
                        currentMonitor.supports_hdr = value === '1' || value === 'true'
                    } else if (key === 'sdrBrightness') {
                        currentMonitor.sdrbrightness = parseFloat(value) || 1.0
                    } else if (key === 'colorManagement') {
                        currentMonitor.cm = value
                    }
                }
            }
        }
        
        if (currentMonitor) {
            monitors.push(currentMonitor)
        }
        
        return monitors
    }

    function loadMonitorsConf() {
        loading = true
        monitorsFile.path = ""
        monitorsFile.path = monitorsConfPath
    }

    function loadMonitorCapabilities() {
        loadCapabilitiesProcess.running = true
        checkEdidHdrSupport()
    }
    
    function checkEdidHdrSupport() {
        for (var i = 0; i < monitors.length; i++) {
            var monitor = monitors[i]
            if (!monitor || monitor.disabled) continue
            
            var caps = displayConfigTab.monitorCapabilities[monitor.name]
            if (caps && caps.hdr === true) {
                continue
            }
            
            checkEdidForMonitor(monitor.name, i)
        }
    }
    
    function checkEdidForMonitor(monitorName, index) {
        edidCheckProcess.command = ["sh", "-c", "for card in /sys/class/drm/card*/" + monitorName + "/edid; do if [ -r \"$card\" ] 2>/dev/null; then output=$(cat \"$card\" 2>/dev/null | edid-decode 2>&1); echo \"$output\" | grep -qiE '(hdr.*static.*metadata|hdr.*metadata.*block|hdr.*static|bt\\.2020|rec\\.2020)' && echo 'HDR' && break; fi; done"]
        edidCheckProcess.monitorName = monitorName
        edidCheckProcess.monitorIndex = index
        edidCheckProcess.running = true
    }

    function saveMonitorsConf() {
        var lines = []
        var content = originalContent || ""
        var contentLines = content ? content.split('\n') : []
        
        var i = 0
        while (i < contentLines.length) {
            var line = contentLines[i]
            var trimmed = line.trim()
            
            if (trimmed.startsWith('monitor=') || trimmed.startsWith('monitorv2')) {
                if (trimmed.startsWith('monitor=')) {
                    i++
                    while (i < contentLines.length && contentLines[i].trim().startsWith('monitor:')) {
                        i++
                    }
                    continue
                }
                if (trimmed.startsWith('monitorv2')) {
                    i++
                    var braceCount = 1
                    while (i < contentLines.length && braceCount > 0) {
                        var currentLine = contentLines[i]
                        if (currentLine.includes('{')) braceCount++
                        if (currentLine.includes('}')) braceCount--
                        i++
                    }
                    continue
                }
            }
            
            lines.push(line)
            i++
        }
        
        for (var j = 0; j < monitors.length; j++) {
            var monitor = monitors[j]
            monitor.isV2 = true
            
            lines.push("monitorv2 {")
                lines.push("  output = " + (monitor.name.includes(" ") ? '"' + monitor.name + '"' : monitor.name))
                
                if (monitor.disabled) {
                    lines.push("  disabled = true")
                } else {
                    if (monitor.resolution) {
                        var mode = monitor.resolution
                        if (monitor.refreshRate) {
                            mode += "@" + monitor.refreshRate
                        }
                        lines.push("  mode = " + mode)
                    }
                    if (monitor.position) {
                        lines.push("  position = " + monitor.position)
                    }
                    if (monitor.scale && monitor.scale !== "1") {
                        lines.push("  scale = " + monitor.scale)
                    }
                    if (monitor.transform && monitor.transform !== "0") {
                        lines.push("  transform = " + monitor.transform)
                    }
                    if (monitor.bitdepth) {
                        lines.push("  bitdepth = " + monitor.bitdepth)
                    }
                    if (monitor.cm) {
                        lines.push("  cm = " + monitor.cm)
                    }
                    if (monitor.sdrbrightness && monitor.sdrbrightness !== "1.0" && monitor.sdrbrightness !== 1.0) {
                        lines.push("  sdrbrightness = " + monitor.sdrbrightness)
                    }
                    if (monitor.sdrsaturation && monitor.sdrsaturation !== "1.0" && monitor.sdrsaturation !== 1.0) {
                        lines.push("  sdrsaturation = " + monitor.sdrsaturation)
                    }
                    if (monitor.sdr_eotf && monitor.sdr_eotf !== "0" && monitor.sdr_eotf !== 0) {
                        lines.push("  sdr_eotf = " + monitor.sdr_eotf)
                    }
                    if (monitor.vrr !== undefined && monitor.vrr !== null && monitor.vrr !== "") {
                        lines.push("  vrr = " + monitor.vrr)
                    }
                    if (monitor.mirror) {
                        lines.push("  mirror = " + monitor.mirror)
                    }
                    if (monitor.supports_wide_color) {
                        lines.push("  supports_wide_color = 1")
                    }
                    if (monitor.supports_hdr) {
                        lines.push("  supports_hdr = 1")
                    }
                    if (monitor.sdr_min_luminance && monitor.sdr_min_luminance !== 0) {
                        lines.push("  sdr_min_luminance = " + monitor.sdr_min_luminance)
                    }
                    if (monitor.sdr_max_luminance && monitor.sdr_max_luminance !== 200) {
                        lines.push("  sdr_max_luminance = " + monitor.sdr_max_luminance)
                    }
                    if (monitor.min_luminance && monitor.min_luminance !== 0) {
                        lines.push("  min_luminance = " + monitor.min_luminance)
                    }
                    if (monitor.max_luminance && monitor.max_luminance !== 0) {
                        lines.push("  max_luminance = " + monitor.max_luminance)
                    }
                    if (monitor.max_avg_luminance && monitor.max_avg_luminance !== 0) {
                        lines.push("  max_avg_luminance = " + monitor.max_avg_luminance)
                    }
                }
                lines.push("}")
            lines.push("")
        }
        
        while (lines.length > 0 && lines[lines.length - 1].trim().length === 0) {
            lines.pop()
        }
        
        var newContent = lines.join('\n')
        
        var dirPath = monitorsConfPath.substring(0, monitorsConfPath.lastIndexOf('/'))
        ensureDirProcess.command = ["mkdir", "-p", dirPath]
        ensureDirProcess.running = true
        pendingSaveContent = newContent
    }
    
    property string pendingSaveContent: ""

    function applyMonitorSetting(monitorName, setting, value) {
        var monitor = monitors.find(function(m) { return m.name === monitorName })
        if (!monitor) return
        
        monitor[setting] = value
        hasUnsavedChanges = true
        
        saveMonitorsConf()
    }
    
    function updateMonitorResolution(monitorName, resolution) {
        applyMonitorSetting(monitorName, "resolution", resolution)
    }
    
    function updateMonitorRefreshRate(monitorName, refreshRate) {
        applyMonitorSetting(monitorName, "refreshRate", refreshRate)
    }

    Component.onCompleted: {
        loadMonitorsConf()
        loadMonitorCapabilitiesFromCache()
        Qt.callLater(() => {
            loadMonitorCapabilities()
        })
    }
    
    onTabActivated: {
        loadMonitorCapabilities()
    }
    
    function loadMonitorCapabilitiesFromCache() {
        capabilitiesCacheFile.path = ""
        capabilitiesCacheFile.path = capabilitiesCachePath
    }
    
    function saveMonitorCapabilitiesToCache() {
        var cacheData = {
            rawData: rawMonitorData,
            processedData: monitorCapabilities,
            timestamp: new Date().toISOString()
        }
        var capabilitiesJson = JSON.stringify(cacheData, null, 2)
        var dirPath = capabilitiesCachePath.substring(0, capabilitiesCachePath.lastIndexOf('/'))
        ensureCapabilitiesDirProcess.command = ["mkdir", "-p", dirPath]
        ensureCapabilitiesDirProcess.running = true
        pendingCapabilitiesContent = capabilitiesJson
    }
    
    property string pendingCapabilitiesContent: ""

    FileView {
        id: monitorsFile
        path: displayConfigTab.monitorsConfPath
        blockWrites: true
        blockLoading: false
        atomicWrites: true
        printErrors: true
        
        onLoaded: {
            var content = text()
            displayConfigTab.originalContent = content
            var parsedMonitors = displayConfigTab.parseMonitorsConf(content)
            if (parsedMonitors.length === 0) {
                loadMonitorsFromHyprctl()
            } else {
                displayConfigTab.monitors = parsedMonitors
                displayConfigTab.loading = false
                displayConfigTab.hasUnsavedChanges = false
                if (Object.keys(displayConfigTab.monitorCapabilities).length === 0) {
                    Qt.callLater(() => {
                        loadMonitorCapabilities()
                    })
                }
            }
        }
        
        onLoadFailed: {
            loadMonitorsFromHyprctl()
        }
    }

    function loadMonitorsFromHyprctl() {
        loadMonitorsFromHyprctlProcess.running = true
    }

    Process {
        id: loadMonitorsFromHyprctlProcess
        command: ["hyprctl", "-j", "monitors"]
        running: false
        stdout: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    var json = JSON.parse(stdout.text)
                    var monitors = []
                    for (var i = 0; i < json.length; i++) {
                        var monitor = json[i]
                        var monitorObj = {
                            name: monitor.name || "Unknown",
                            resolution: monitor.width + "x" + monitor.height,
                            position: (monitor.x !== undefined && monitor.y !== undefined) ? (monitor.x + "x" + monitor.y) : "",
                            scale: monitor.scale ? monitor.scale.toString() : "1",
                            refreshRate: monitor.refresh ? monitor.refresh.toString() : "",
                            transform: "",
                            disabled: false,
                            bitdepth: "",
                            cm: "",
                            sdrbrightness: 1.0,
                            sdrsaturation: 1.0,
                            sdr_eotf: 0,
                            vrr: "",
                            mirror: "",
                            supports_wide_color: false,
                            supports_hdr: monitor.hdr || false,
                            sdr_min_luminance: 0.0,
                            sdr_max_luminance: 200,
                            min_luminance: 0.0,
                            max_luminance: 0,
                            max_avg_luminance: 0,
                            isV2: true
                        }
                        monitors.push(monitorObj)
                    }
                    displayConfigTab.monitors = monitors
                    displayConfigTab.originalContent = ""
                    displayConfigTab.loading = false
                    displayConfigTab.hasUnsavedChanges = false
                } catch(e) {
                    displayConfigTab.monitors = []
                }
            } else {
                displayConfigTab.monitors = []
            }
            displayConfigTab.loading = false
        }
    }

    Process {
        id: loadCapabilitiesProcess
        command: ["hyprctl", "-j", "monitors"]
        running: false
        stdout: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    var json = JSON.parse(stdout.text)
                    displayConfigTab.rawMonitorData = json
                    
                    var caps = {}
                    for (var i = 0; i < json.length; i++) {
                        var monitor = json[i]
                        var refreshRates = []
                        var resolutions = []
                        var resolutionRefreshMap = {}
                        
                        if (monitor.availableModes && Array.isArray(monitor.availableModes)) {
                            for (var j = 0; j < monitor.availableModes.length; j++) {
                                var modeStr = monitor.availableModes[j]
                                var match = modeStr.match(/^(\d+)x(\d+)@([\d.]+)Hz$/)
                                if (match) {
                                    var width = parseInt(match[1])
                                    var height = parseInt(match[2])
                                    var refresh = parseFloat(match[3])
                                    var res = width + "x" + height
                                    
                                    if (!refreshRates.includes(refresh)) {
                                        refreshRates.push(refresh)
                                    }
                                    
                                    if (!resolutions.includes(res)) {
                                        resolutions.push(res)
                                    }
                                    
                                    if (!resolutionRefreshMap[res]) {
                                        resolutionRefreshMap[res] = []
                                    }
                                    if (!resolutionRefreshMap[res].includes(refresh)) {
                                        resolutionRefreshMap[res].push(refresh)
                                    }
                                }
                            }
                        }
                        
                        refreshRates = refreshRates.filter(function(value, index, self) {
                            return self.indexOf(value) === index
                        }).sort(function(a, b) { return b - a })
                        
                        resolutions = resolutions.filter(function(value, index, self) {
                            return self.indexOf(value) === index
                        }).sort(function(a, b) {
                            var aParts = a.split('x')
                            var bParts = b.split('x')
                            var aPixels = parseInt(aParts[0]) * parseInt(aParts[1])
                            var bPixels = parseInt(bParts[0]) * parseInt(bParts[1])
                            return bPixels - aPixels
                        })
                        
                        for (var res in resolutionRefreshMap) {
                            resolutionRefreshMap[res].sort(function(a, b) { return b - a })
                        }
                        
                        var hdrFromHyprctl = monitor.hdr === true
                        var hdrFromConfig = false
                        for (var k = 0; k < displayConfigTab.monitors.length; k++) {
                            var configMonitor = displayConfigTab.monitors[k]
                            if (configMonitor.name === monitor.name) {
                                var cm = (configMonitor.cm || "").toLowerCase()
                                hdrFromConfig = (cm === "hdr" || cm === "hdredid") || configMonitor.supports_hdr === true
                                break
                            }
                        }
                        
                        caps[monitor.name] = {
                            refreshRates: refreshRates,
                            resolutions: resolutions,
                            resolutionRefreshMap: resolutionRefreshMap,
                            availableModes: monitor.availableModes || [],
                            vrr: monitor.vrr !== undefined ? monitor.vrr : false,
                            hdr: hdrFromHyprctl || hdrFromConfig,
                            hdrFromEdid: false,
                            currentMode: monitor.activeWorkspace ? monitor.activeWorkspace : null,
                            width: monitor.width || 0,
                            height: monitor.height || 0,
                            refresh: monitor.refreshRate || monitor.refresh || 0,
                            scale: monitor.scale || 1.0,
                            description: monitor.description || "",
                            make: monitor.make || "",
                            model: monitor.model || "",
                            transform: monitor.transform || 0,
                            disabled: monitor.disabled || false,
                            currentFormat: monitor.currentFormat || "",
                            mirrorOf: monitor.mirrorOf || "none",
                            colorManagementPreset: monitor.colorManagementPreset || "",
                            sdrBrightness: monitor.sdrBrightness || 1.0,
                            sdrSaturation: monitor.sdrSaturation || 1.0,
                            sdrMinLuminance: monitor.sdrMinLuminance || 0.0,
                            sdrMaxLuminance: monitor.sdrMaxLuminance || 0.0,
                            dpmsStatus: monitor.dpmsStatus !== undefined ? monitor.dpmsStatus : true,
                            focused: monitor.focused !== undefined ? monitor.focused : false
                        }
                    }
                    displayConfigTab.monitorCapabilities = caps
                    saveMonitorCapabilitiesToCache()
                    Qt.callLater(() => {
                        checkEdidHdrSupport()
                    })
                } catch(e) {
                    displayConfigTab.monitorCapabilities = {}
                    displayConfigTab.rawMonitorData = []
                }
            } else {
                displayConfigTab.monitorCapabilities = {}
                displayConfigTab.rawMonitorData = []
            }
        }
    }
    
    Process {
        id: edidCheckProcess
        property string monitorName: ""
        property int monitorIndex: -1
        running: false
        stdout: StdioCollector {}
        onExited: function(exitCode) {
            if (!monitorName) return
            
            var output = stdout.text.trim().toUpperCase()
            if (output.includes("HDR")) {
                var caps = Object.assign({}, displayConfigTab.monitorCapabilities)
                if (caps[monitorName]) {
                    caps[monitorName].hdr = true
                    caps[monitorName].hdrFromEdid = true
                    displayConfigTab.monitorCapabilities = caps
                    Qt.callLater(() => {
                        saveMonitorCapabilitiesToCache()
                    })
                } else {
                    caps[monitorName] = {
                        hdr: true,
                        hdrFromEdid: true,
                        refreshRates: [],
                        resolutions: [],
                        resolutionRefreshMap: {},
                        vrr: false
                    }
                    displayConfigTab.monitorCapabilities = caps
                    Qt.callLater(() => {
                        saveMonitorCapabilitiesToCache()
                    })
                }
            }
        }
    }
    
    FileView {
        id: capabilitiesCacheFile
        path: displayConfigTab.capabilitiesCachePath
        blockWrites: true
        blockLoading: false
        atomicWrites: true
        printErrors: false
        
        onLoaded: {
            try {
                var cached = JSON.parse(text())
                if (cached && typeof cached === 'object') {
                    if (cached.rawData) {
                        displayConfigTab.rawMonitorData = cached.rawData
                    }
                    if (cached.processedData) {
                        displayConfigTab.monitorCapabilities = cached.processedData
                    } else if (cached.refreshRates || cached.resolutions) {
                        displayConfigTab.monitorCapabilities = cached
                    }
                }
            } catch(e) {
                displayConfigTab.monitorCapabilities = {}
                displayConfigTab.rawMonitorData = []
            }
        }
        
        onLoadFailed: {
            displayConfigTab.monitorCapabilities = {}
            displayConfigTab.rawMonitorData = []
        }
    }
    
    Process {
        id: ensureCapabilitiesDirProcess
        command: ["mkdir", "-p"]
        running: false
        
        onExited: exitCode => {
            if (pendingCapabilitiesContent !== "") {
                touchCapabilitiesFileProcess.command = ["touch", capabilitiesCachePath]
                touchCapabilitiesFileProcess.running = true
            }
        }
    }
    
    Process {
        id: touchCapabilitiesFileProcess
        command: ["touch"]
        running: false
        
        onExited: exitCode => {
            if (pendingCapabilitiesContent !== "") {
                saveCapabilitiesCacheFile.path = ""
                Qt.callLater(() => {
                    saveCapabilitiesCacheFile.path = capabilitiesCachePath
                    Qt.callLater(() => {
                        saveCapabilitiesCacheFile.setText(pendingCapabilitiesContent)
                    })
                })
            }
        }
    }
    
    FileView {
        id: saveCapabilitiesCacheFile
        blockWrites: false
        blockLoading: true
        atomicWrites: true
        printErrors: true
        
        onSaved: {
            pendingCapabilitiesContent = ""
        }
        
        onSaveFailed: (error) => {
            pendingCapabilitiesContent = ""
        }
    }

    Process {
        id: ensureDirProcess
        command: ["mkdir", "-p"]
        running: false
        
        onExited: exitCode => {
            if (pendingSaveContent !== "") {
                touchFileProcess.command = ["touch", monitorsConfPath]
                touchFileProcess.running = true
            }
        }
    }
    
    Process {
        id: touchFileProcess
        command: ["touch"]
        running: false
        
        onExited: exitCode => {
            if (pendingSaveContent !== "") {
                saveMonitorsFile.path = ""
                Qt.callLater(() => {
                    saveMonitorsFile.path = monitorsConfPath
                    Qt.callLater(() => {
                        saveMonitorsFile.setText(pendingSaveContent)
                    })
                })
            }
        }
    }
    
    FileView {
        id: saveMonitorsFile
        blockWrites: false
        blockLoading: true
        atomicWrites: true
        printErrors: true
        
        onSaved: {
            hasUnsavedChanges = false
            if (typeof ToastService !== "undefined") {
                ToastService.showInfo("Monitor configuration saved successfully")
            }
            Qt.callLater(() => {
                monitorsFile.reload()
            })
            reloadHyprlandProcess.running = true
            pendingSaveContent = ""
        }
        
        onSaveFailed: (error) => {
            if (typeof ToastService !== "undefined") {
                ToastService.showError("Failed to save monitor configuration: " + (error || "Unknown error"))
            }
            pendingSaveContent = ""
        }
    }
    
    Process {
        id: reloadHyprlandProcess
        command: ["hyprctl", "reload"]
        running: false
        
        onExited: exitCode => {
            if (exitCode === 0) {
                if (typeof ToastService !== "undefined") {
                    ToastService.showInfo("Hyprland configuration reloaded")
                }
                loadMonitorCapabilities()
            } else {
                if (typeof ToastService !== "undefined") {
                    ToastService.showError("Failed to reload Hyprland configuration")
                }
            }
        }
    }

    DarkFlickable {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingM
        anchors.bottomMargin: Theme.spacingS
        clip: true
        contentHeight: mainColumn.height
        contentWidth: width

        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.spacingM

            MonitorArrangementWidget {
                id: arrangementWidget
                width: parent.width
                monitors: displayConfigTab.monitors
                monitorCapabilities: displayConfigTab.monitorCapabilities
                selectedMonitor: displayConfigTab.selectedMonitor
                visible: displayConfigTab.monitors.length > 0 && !displayConfigTab.loading
                onMonitorSelected: function(monitorName) {
                    displayConfigTab.selectedMonitor = monitorName
                }
                onPositionChanged: function(monitorName, newPosition) {
                    displayConfigTab.applyMonitorSetting(monitorName, "position", newPosition)
                }
            }

            StyledText {
                text: "Loading monitors..."
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
                visible: displayConfigTab.loading
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            StyledText {
                text: displayConfigTab.monitors.length === 0 && !displayConfigTab.loading ? "No monitors found. Make sure Hyprland is running and monitors are configured." : ""
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
                visible: displayConfigTab.monitors.length === 0 && !displayConfigTab.loading
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM
                visible: displayConfigTab.monitors.length > 0 && !displayConfigTab.loading && displayConfigTab.selectedMonitor !== ""
                
                StyledRect {
                    height: 40
                    width: showAllButtonText.implicitWidth + Theme.spacingL * 2
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                    border.color: Theme.primary
                    border.width: 1
                    
                    StyledText {
                        id: showAllButtonText
                        anchors.centerIn: parent
                        text: "Show All Monitors"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.primary
                    }
                    
                    StateLayer {
                        stateColor: Theme.primary
                        cornerRadius: parent.radius
                        onClicked: {
                            displayConfigTab.selectedMonitor = ""
                        }
                    }
                }
            }

            Repeater {
                model: displayConfigTab.getFilteredMonitors()

                delegate: MonitorConfigWidget {
                    width: parent.width
                    monitorData: modelData
                    monitorCapabilities: displayConfigTab.monitorCapabilities[modelData.name] || {}
                    onSettingChanged: function(setting, value) {
                        displayConfigTab.applyMonitorSetting(modelData.name, setting, value)
                    }
                }
            }

            StyledText {
                text: "VRR Settings"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.primary
                visible: displayConfigTab.monitors.length > 0 && !displayConfigTab.loading
                width: parent.width
            }

            StyledRect {
                width: parent.width
                height: vrrSettingsColumn.implicitHeight + Theme.spacingM * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.20)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                border.width: 1
                visible: displayConfigTab.monitors.length > 0 && !displayConfigTab.loading

                Column {
                    id: vrrSettingsColumn
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "VRR Settings"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        visible: false
                    }

                    Repeater {
                        model: displayConfigTab.getFilteredMonitors()

                        delegate: DarkDropdown {
                            width: parent.width
                            text: modelData.name + " - VRR"
                            description: {
                                var vrrValue = modelData ? (modelData.vrr || "0") : "0"
                                if (vrrValue === "0" || vrrValue === 0) return "VRR disabled. Monitor runs at fixed refresh rate."
                                if (vrrValue === "1" || vrrValue === 1) return "VRR enabled globally. Matches monitor refresh rate to application frame rate."
                                if (vrrValue === "2" || vrrValue === 2) return "VRR enabled only for fullscreen applications. Prevents flickering in windowed mode."
                                return "Variable refresh rate (G-Sync/FreeSync)"
                            }
                            options: ["Disabled (0)", "Enabled Globally (1)", "Fullscreen Only (2)"]
                            currentValue: {
                                if (!modelData) return "Disabled (0)"
                                var vrrValue = modelData.vrr
                                if (vrrValue === "0" || vrrValue === 0 || vrrValue === false) return "Disabled (0)"
                                if (vrrValue === "1" || vrrValue === 1 || vrrValue === true) return "Enabled Globally (1)"
                                if (vrrValue === "2" || vrrValue === 2) return "Fullscreen Only (2)"
                                return "Disabled (0)"
                            }
                            visible: {
                                var caps = displayConfigTab.monitorCapabilities[modelData.name] || {}
                                return (!modelData || !modelData.disabled) && (caps.vrr !== undefined && caps.vrr !== null)
                            }
                            onValueChanged: (value) => {
                                if (!modelData) return
                                var newValue = "0"
                                if (value === "Enabled Globally (1)") newValue = "1"
                                else if (value === "Fullscreen Only (2)") newValue = "2"
                                
                                modelData.vrr = newValue
                                displayConfigTab.applyMonitorSetting(modelData.name, "vrr", newValue)
                            }
                        }
                    }
                }
            }
        }
    }
    
}

