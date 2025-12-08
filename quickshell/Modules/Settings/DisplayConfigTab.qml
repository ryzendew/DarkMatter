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
    property var rawMonitorData: [] // Store complete JSON from hyprctl
    property bool loading: true
    property bool hasUnsavedChanges: false
    property string originalContent: ""
    readonly property string monitorsConfPath: (Quickshell.env("HOME") || StandardPaths.writableLocation(StandardPaths.HomeLocation)) + "/.config/hypr/monitors.conf"
    readonly property string capabilitiesCachePath: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/DarkMaterialShell/monitor-capabilities.json"
    
    signal tabActivated()

    function parseMonitorsConf(content) {
        var monitors = []
        var lines = content.split('\n')
        var currentMonitor = null
        var inMonitorV2Block = false
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === '' || line.startsWith('#')) continue
            
            // Parse monitorv2 block
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
                
                // Parse monitorv2 key = value pairs
                var keyValue = line.split('=')
                if (keyValue.length === 2) {
                    var key = keyValue[0].trim()
                    var value = keyValue[1].trim().replace(/^["']|["']$/g, '') // Remove quotes
                    
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
            
            // Parse old monitor= syntax
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
                
                // Check for disable
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
                    
                    // Parse extra args
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
            // Parse monitor: lines for additional settings (old syntax)
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
    }

    function saveMonitorsConf() {
        var lines = []
        var content = originalContent
        var contentLines = content.split('\n')
        
        // Rebuild the file, replacing monitor entries
        var i = 0
        while (i < contentLines.length) {
            var line = contentLines[i]
            var trimmed = line.trim()
            
            // Skip existing monitor= or monitorv2 blocks - we'll add them back
            if (trimmed.startsWith('monitor=') || trimmed.startsWith('monitorv2')) {
                // Skip monitor= line
                if (trimmed.startsWith('monitor=')) {
                    i++
                    // Skip any following monitor: lines
                    while (i < contentLines.length && contentLines[i].trim().startsWith('monitor:')) {
                        i++
                    }
                    continue
                }
                // Skip monitorv2 block
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
            
            // Keep comments, blank lines, and other content
            lines.push(line)
            i++
        }
        
        // Add all monitors back
        for (var j = 0; j < monitors.length; j++) {
            var monitor = monitors[j]
            
            if (monitor.isV2) {
                // Write monitorv2 block
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
                    // Always write VRR value (0, 1, or 2)
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
            } else {
                // Write old monitor= syntax
                var monitorLine = "monitor="
                if (monitor.disabled) {
                    monitorLine += monitor.name + ",disable"
                } else {
                    if (monitor.name.includes(",") || monitor.name.includes(" ")) {
                        monitorLine += '"' + monitor.name + '"'
                    } else {
                        monitorLine += monitor.name
                    }
                    
                    if (monitor.resolution) {
                        if (monitor.refreshRate) {
                            monitorLine += "," + monitor.resolution + "@" + monitor.refreshRate
                        } else {
                            monitorLine += "," + monitor.resolution
                        }
                    }
                    if (monitor.position) monitorLine += "," + monitor.position
                    if (monitor.scale && monitor.scale !== "1") monitorLine += "," + monitor.scale
                    if (monitor.transform && monitor.transform !== "0") monitorLine += ",transform," + monitor.transform
                    if (monitor.bitdepth) monitorLine += ",bitdepth," + monitor.bitdepth
                    if (monitor.cm) monitorLine += ",cm," + monitor.cm
                    if (monitor.sdrbrightness && monitor.sdrbrightness !== "1.0" && monitor.sdrbrightness !== 1.0) monitorLine += ",sdrbrightness," + monitor.sdrbrightness
                    if (monitor.sdrsaturation && monitor.sdrsaturation !== "1.0" && monitor.sdrsaturation !== 1.0) monitorLine += ",sdrsaturation," + monitor.sdrsaturation
                    if (monitor.sdr_eotf && monitor.sdr_eotf !== "0" && monitor.sdr_eotf !== 0) monitorLine += ",sdr_eotf," + monitor.sdr_eotf
                    // Always write VRR value (0, 1, or 2) if it's set
                    if (monitor.vrr !== undefined && monitor.vrr !== null && monitor.vrr !== "") {
                        monitorLine += ",vrr," + monitor.vrr
                    }
                    if (monitor.mirror) monitorLine += ",mirror," + monitor.mirror
                }
                lines.push(monitorLine)
            }
            lines.push("") // Add blank line between monitors
        }
        
        // Remove trailing blank lines
        while (lines.length > 0 && lines[lines.length - 1].trim().length === 0) {
            lines.pop()
        }
        
        var newContent = lines.join('\n')
        
        // Ensure directory exists
        var dirPath = monitorsConfPath.substring(0, monitorsConfPath.lastIndexOf('/'))
        ensureDirProcess.command = ["mkdir", "-p", dirPath]
        ensureDirProcess.running = true
        pendingSaveContent = newContent
    }
    
    property string pendingSaveContent: ""

    function applyMonitorSetting(monitorName, setting, value) {
        var monitor = monitors.find(function(m) { return m.name === monitorName })
        if (!monitor) return
        
        // Update the monitor object
        monitor[setting] = value
        hasUnsavedChanges = true
        
        // Save to file instead of using hyprctl
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
        loadMonitorCapabilities()
    }
    
    onTabActivated: {
        // Refresh capabilities when tab is activated
        loadMonitorCapabilities()
    }
    
    function loadMonitorCapabilitiesFromCache() {
        capabilitiesCacheFile.path = ""
        capabilitiesCacheFile.path = capabilitiesCachePath
    }
    
    function saveMonitorCapabilitiesToCache() {
        // Store the complete raw JSON data from hyprctl
        var cacheData = {
            rawData: rawMonitorData, // Complete JSON from hyprctl -j monitors
            processedData: monitorCapabilities, // Processed data for UI
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
                // If no monitors found in config, try to get them from hyprctl
                loadMonitorsFromHyprctl()
            } else {
                displayConfigTab.monitors = parsedMonitors
                displayConfigTab.loading = false
                displayConfigTab.hasUnsavedChanges = false
            }
        }
        
        onLoadFailed: {
            // File doesn't exist or can't be read, try hyprctl
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
                            position: "",
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
                            isV2: false
                        }
                        monitors.push(monitorObj)
                    }
                    displayConfigTab.monitors = monitors
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
                    // Store the complete raw data
                    displayConfigTab.rawMonitorData = json
                    
                    // Process for UI use
                    var caps = {}
                    for (var i = 0; i < json.length; i++) {
                        var monitor = json[i]
                        var refreshRates = []
                        var resolutions = []
                        var resolutionRefreshMap = {} // Map resolution to available refresh rates
                        
                        // Gather all available modes with their refresh rates and resolutions
                        // availableModes is an array of strings like "1920x1080@60.10Hz"
                        if (monitor.availableModes && Array.isArray(monitor.availableModes)) {
                            for (var j = 0; j < monitor.availableModes.length; j++) {
                                var modeStr = monitor.availableModes[j]
                                // Parse string like "1920x1080@60.10Hz"
                                var match = modeStr.match(/^(\d+)x(\d+)@([\d.]+)Hz$/)
                                if (match) {
                                    var width = parseInt(match[1])
                                    var height = parseInt(match[2])
                                    var refresh = parseFloat(match[3])
                                    var res = width + "x" + height
                                    
                                    // Add to refresh rates list
                                    if (!refreshRates.includes(refresh)) {
                                        refreshRates.push(refresh)
                                    }
                                    
                                    // Add to resolutions list
                                    if (!resolutions.includes(res)) {
                                        resolutions.push(res)
                                    }
                                    
                                    // Map resolution to its available refresh rates
                                    if (!resolutionRefreshMap[res]) {
                                        resolutionRefreshMap[res] = []
                                    }
                                    if (!resolutionRefreshMap[res].includes(refresh)) {
                                        resolutionRefreshMap[res].push(refresh)
                                    }
                                }
                            }
                        }
                        
                        // Remove duplicates and sort
                        refreshRates = refreshRates.filter(function(value, index, self) {
                            return self.indexOf(value) === index
                        }).sort(function(a, b) { return b - a })
                        
                        resolutions = resolutions.filter(function(value, index, self) {
                            return self.indexOf(value) === index
                        }).sort(function(a, b) {
                            // Sort by total pixels (width * height), descending
                            var aParts = a.split('x')
                            var bParts = b.split('x')
                            var aPixels = parseInt(aParts[0]) * parseInt(aParts[1])
                            var bPixels = parseInt(bParts[0]) * parseInt(bParts[1])
                            return bPixels - aPixels
                        })
                        
                        // Sort refresh rates for each resolution
                        for (var res in resolutionRefreshMap) {
                            resolutionRefreshMap[res].sort(function(a, b) { return b - a })
                        }
                        
                        // Store processed data for UI - include all important fields
                        caps[monitor.name] = {
                            refreshRates: refreshRates,
                            resolutions: resolutions,
                            resolutionRefreshMap: resolutionRefreshMap, // Map of resolution -> [refresh rates]
                            availableModes: monitor.availableModes || [], // Store original availableModes array
                            vrr: monitor.vrr !== undefined ? monitor.vrr : false,
                            hdr: monitor.hdr || false,
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
                    // Save complete raw data to cache
                    saveMonitorCapabilitiesToCache()
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
                    // Load raw data if available
                    if (cached.rawData) {
                        displayConfigTab.rawMonitorData = cached.rawData
                    }
                    // Load processed data for UI
                    if (cached.processedData) {
                        displayConfigTab.monitorCapabilities = cached.processedData
                    } else if (cached.refreshRates || cached.resolutions) {
                        // Legacy format - single monitor object
                        displayConfigTab.monitorCapabilities = cached
                    }
                }
            } catch(e) {
                // Cache invalid or empty, will be refreshed from hyprctl
                displayConfigTab.monitorCapabilities = {}
                displayConfigTab.rawMonitorData = []
            }
        }
        
        onLoadFailed: {
            // Cache doesn't exist yet, will be created after hyprctl loads
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
                // Ensure file exists first
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
                // Use FileView for saving
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
                ToastService.showSuccess("Monitor configuration saved successfully")
            }
            // Reload the file to reflect changes
            Qt.callLater(() => {
                monitorsFile.reload()
            })
            // Reload Hyprland configuration to apply changes
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
                    ToastService.showSuccess("Hyprland configuration reloaded")
                }
                // Reload monitor capabilities after reload
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
        anchors.topMargin: Theme.spacingL
        anchors.bottomMargin: Theme.spacingS
        clip: true
        contentHeight: mainColumn.height
        contentWidth: width

        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.spacingL

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

            Repeater {
                model: displayConfigTab.monitors

                delegate: MonitorConfigWidget {
                    width: parent.width
                    monitorData: modelData
                    monitorCapabilities: displayConfigTab.monitorCapabilities[modelData.name] || {}
                    onSettingChanged: function(setting, value) {
                        displayConfigTab.applyMonitorSetting(modelData.name, setting, value)
                    }
                }
            }

            // Global VRR Settings
            StyledRect {
                width: parent.width
                height: vrrSettingsColumn.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.20)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                border.width: 1

                Column {
                    id: vrrSettingsColumn
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    StyledText {
                        text: "VRR Settings"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    // Per-Monitor VRR Settings
                    Repeater {
                        model: displayConfigTab.monitors

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
                                var newValue = "0" // Default to disabled
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

