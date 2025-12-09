import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Widgets

StyledRect {
    id: monitorWidget

    property var monitorData: null
    property var monitorCapabilities: ({})
    signal settingChanged(string setting, var value)
    
    // Check if monitor supports HDR and VRR
    // HDR support can come from:
    // 1. hyprctl detection (monitorCapabilities.hdr === true)
    // 2. EDID detection (monitorCapabilities.hdrFromEdid === true)
    // 3. Config file (monitorData.cm === "hdr" or "hdredid", or monitorData.supports_hdr === true)
    // 4. Monitor capabilities description/model (known HDR-capable monitors)
    readonly property bool supportsHDR: {
        // Check capabilities first (from hyprctl or EDID)
        if (monitorCapabilities && monitorCapabilities.hdr === true) {
            return true
        }
        // Check config file for HDR settings
        if (monitorData) {
            var cm = (monitorData.cm || "").toLowerCase()
            if (cm === "hdr" || cm === "hdredid") {
                return true
            }
            if (monitorData.supports_hdr === true || monitorData.supports_hdr === "1") {
                return true
            }
        }
        // Check if monitor description/model suggests HDR capability
        // Some monitors like KTC H27S17 are known to support HDR
        if (monitorCapabilities) {
            var desc = (monitorCapabilities.description || "").toLowerCase()
            var model = (monitorCapabilities.model || "").toLowerCase()
            // Check for known HDR-capable monitor models/descriptions
            if (desc.includes("h27s17") || model.includes("h27s17")) {
                return true
            }
        }
        return false
    }
    readonly property bool supportsVRR: monitorCapabilities && monitorCapabilities.vrr !== undefined && monitorCapabilities.vrr !== null

    height: contentColumn.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadius
    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.20)
    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
    border.width: 1

    Column {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingXS

        Row {
            width: parent.width
            spacing: Theme.spacingM

            DarkIcon {
                name: "monitor"
                size: Theme.iconSize - 2
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                width: parent.width - Theme.iconSize - Theme.spacingM
                spacing: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    text: monitorData ? monitorData.name : "Unknown Monitor"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                StyledText {
                    text: {
                        if (!monitorData) return ""
                        var text = monitorData.resolution || "No resolution set"
                        if (monitorData.refreshRate) {
                            text += " @ " + monitorData.refreshRate + " Hz"
                        }
                        if (monitorData.disabled) {
                            text += " (Disabled)"
                        }
                        return text
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }

        GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: Theme.spacingM
            rowSpacing: Theme.spacingXS

            StyledText {
                text: "Disabled"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            DarkToggle {
                Layout.fillWidth: true
                text: "Disabled"
                description: "Disable this monitor"
                checked: monitorData ? monitorData.disabled : false
                onToggled: (checked) => {
                    if (monitorData) {
                        monitorData.disabled = checked
                        settingChanged("disabled", checked ? "true" : "false")
                    }
                }
            }

            StyledText {
                text: "Resolution"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            DarkDropdown {
                id: resolutionDropdown
                Layout.fillWidth: true
                text: "Resolution"
                options: {
                    if (!monitorCapabilities || !monitorCapabilities.resolutions || monitorCapabilities.resolutions.length === 0) {
                        // Fallback: show current resolution if available
                        if (monitorData && monitorData.resolution) {
                            return [monitorData.resolution]
                        }
                        return ["No resolutions available"]
                    }
                    return monitorCapabilities.resolutions
                }
                currentValue: monitorData ? (monitorData.resolution || "") : ""
                onValueChanged: (value) => {
                    if (monitorData && value && value !== "No resolutions available") {
                        monitorData.resolution = value
                        settingChanged("resolution", value)
                        // Update refresh rate dropdown to show rates for this resolution
                        if (refreshRateDropdown) {
                            refreshRateDropdown.selectedResolution = value
                            refreshRateDropdown.forceUpdate = !refreshRateDropdown.forceUpdate
                        }
                    }
                }
            }

            StyledText {
                text: "Refresh Rate"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            DarkDropdown {
                id: refreshRateDropdown
                Layout.fillWidth: true
                text: "Refresh Rate"
                
                property string selectedResolution: monitorData ? (monitorData.resolution || "") : ""
                property bool forceUpdate: false
                
                function updateOptionsForResolution(resolution) {
                    selectedResolution = resolution
                    // Force update by toggling property
                    forceUpdate = !forceUpdate
                }
                
                options: {
                    // Access forceUpdate to trigger recalculation
                    var _ = forceUpdate
                    
                    if (!monitorCapabilities) {
                        if (monitorData && monitorData.refreshRate) {
                            return [monitorData.refreshRate.toString() + " Hz"]
                        }
                        return ["No refresh rates available"]
                    }
                    
                    var currentRes = selectedResolution || (monitorData ? monitorData.resolution : "")
                    
                    // If we have a resolution-to-refresh-rate map, use it
                    if (monitorCapabilities.resolutionRefreshMap && currentRes && monitorCapabilities.resolutionRefreshMap[currentRes]) {
                        var rates = monitorCapabilities.resolutionRefreshMap[currentRes]
                        return rates.map(function(rate) {
                            return rate.toString() + " Hz"
                        })
                    }
                    
                    // Fallback to all available refresh rates
                    if (monitorCapabilities.refreshRates && monitorCapabilities.refreshRates.length > 0) {
                        return monitorCapabilities.refreshRates.map(function(rate) {
                            return rate.toString() + " Hz"
                        })
                    }
                    
                    // Final fallback
                    if (monitorData && monitorData.refreshRate) {
                        return [monitorData.refreshRate.toString() + " Hz"]
                    }
                    return ["No refresh rates available"]
                }
                currentValue: {
                    if (!monitorData || !monitorData.refreshRate) return ""
                    var rate = parseFloat(monitorData.refreshRate)
                    var currentRes = selectedResolution || (monitorData ? monitorData.resolution : "")
                    
                    // Try to find in resolution-specific rates first
                    if (monitorCapabilities && monitorCapabilities.resolutionRefreshMap && currentRes && monitorCapabilities.resolutionRefreshMap[currentRes]) {
                        var rates = monitorCapabilities.resolutionRefreshMap[currentRes]
                        var exactMatch = rates.find(function(r) {
                            return Math.abs(r - rate) < 0.01
                        })
                        if (exactMatch !== undefined) {
                            return exactMatch.toString() + " Hz"
                        }
                        // Find closest in resolution-specific rates
                        var closest = rates[0]
                        var minDiff = Math.abs(closest - rate)
                        for (var i = 1; i < rates.length; i++) {
                            var diff = Math.abs(rates[i] - rate)
                            if (diff < minDiff) {
                                minDiff = diff
                                closest = rates[i]
                            }
                        }
                        return closest.toString() + " Hz"
                    }
                    
                    // Fallback to all refresh rates
                    if (monitorCapabilities && monitorCapabilities.refreshRates && monitorCapabilities.refreshRates.length > 0) {
                        // Find exact match first
                        var exactMatch = monitorCapabilities.refreshRates.find(function(r) {
                            return Math.abs(r - rate) < 0.01
                        })
                        if (exactMatch !== undefined) {
                            return exactMatch.toString() + " Hz"
                        }
                        // Otherwise find closest
                        var closest = monitorCapabilities.refreshRates[0]
                        var minDiff = Math.abs(closest - rate)
                        for (var i = 1; i < monitorCapabilities.refreshRates.length; i++) {
                            var diff = Math.abs(monitorCapabilities.refreshRates[i] - rate)
                            if (diff < minDiff) {
                                minDiff = diff
                                closest = monitorCapabilities.refreshRates[i]
                            }
                        }
                        return closest.toString() + " Hz"
                    }
                    return rate.toString() + " Hz"
                }
                onValueChanged: (value) => {
                    if (monitorData && value && value !== "No refresh rates available") {
                        var rate = parseFloat(value.replace(" Hz", ""))
                        monitorData.refreshRate = rate.toString()
                        settingChanged("refreshRate", rate.toString())
                    }
                }
            }

            StyledText {
                text: "Scale"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            Row {
                Layout.fillWidth: true
                spacing: Theme.spacingS

                DarkSlider {
                    id: scaleSlider
                    width: parent.width - scaleValueText.width - parent.spacing
                    minimum: 10
                    maximum: 20
                    value: {
                        if (!monitorData) return 10
                        var scale = parseFloat(monitorData.scale) || 1.0
                        scale = Math.max(1.0, Math.min(2.0, scale))
                        return Math.round(scale * 10)
                    }
                    onSliderDragFinished: (finalValue) => {
                        if (monitorData) {
                            var scale = (finalValue / 10.0).toFixed(1)
                            monitorData.scale = scale
                            settingChanged("scale", scale)
                        }
                    }
                }

                StyledText {
                    id: scaleValueText
                    text: {
                        if (!monitorData) return "1.0x"
                        var scale = parseFloat(monitorData.scale) || 1.0
                        scale = Math.max(1.0, Math.min(2.0, scale))
                        return scale.toFixed(1) + "x"
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: "Transform"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            DarkDropdown {
                Layout.fillWidth: true
                text: "Transform"
                options: ["Normal (0°)", "90°", "180°", "270°", "Flipped", "Flipped + 90°", "Flipped + 180°", "Flipped + 270°"]
                currentValue: {
                    if (!monitorData) return "Normal (0°)"
                    var transform = parseInt(monitorData.transform) || 0
                    var options = ["Normal (0°)", "90°", "180°", "270°", "Flipped", "Flipped + 90°", "Flipped + 180°", "Flipped + 270°"]
                    return options[transform] || "Normal (0°)"
                }
                onValueChanged: (value) => {
                    if (monitorData) {
                        var options = ["Normal (0°)", "90°", "180°", "270°", "Flipped", "Flipped + 90°", "Flipped + 180°", "Flipped + 270°"]
                        var index = options.indexOf(value)
                        if (index >= 0) {
                            monitorData.transform = index.toString()
                            settingChanged("transform", index.toString())
                        }
                    }
                }
            }

            StyledText {
                text: "Bit Depth"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            DarkDropdown {
                Layout.fillWidth: true
                text: "Bit Depth"
                options: ["Default (8-bit)", "10-bit"]
                currentValue: {
                    if (!monitorData || !monitorData.bitdepth || monitorData.bitdepth === "") return "Default (8-bit)"
                    return monitorData.bitdepth === "10" ? "10-bit" : "Default (8-bit)"
                }
                onValueChanged: (value) => {
                    if (monitorData) {
                        var bitdepth = value === "10-bit" ? "10" : ""
                        monitorData.bitdepth = bitdepth
                        settingChanged("bitdepth", bitdepth)
                    }
                }
            }
        }

        StyledText {
            text: "Color Settings"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.primary
            visible: !monitorData || !monitorData.disabled
            width: parent.width
        }

        Column {
            width: parent.width
            spacing: Theme.spacingXS
            visible: !monitorData || !monitorData.disabled

            StyledText {
                text: "Color Management"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            DarkDropdown {
                width: parent.width
                text: "Color Management"
                options: {
                    var baseOptions = ["Auto", "sRGB", "DCI P3", "Apple P3", "Adobe RGB", "Wide (BT2020)", "EDID"]
                    if (supportsHDR) {
                        baseOptions.push("HDR", "HDR EDID")
                    }
                    return baseOptions
                }
                currentValue: {
                    if (!monitorData) return "Auto"
                    var cm = monitorData.cm || ""
                    var map = {
                        "auto": "Auto",
                        "srgb": "sRGB",
                        "dcip3": "DCI P3",
                        "dp3": "Apple P3",
                        "adobe": "Adobe RGB",
                        "wide": "Wide (BT2020)",
                        "edid": "EDID",
                        "hdr": "HDR",
                        "hdredid": "HDR EDID"
                    }
                    var value = map[cm.toLowerCase()] || "Auto"
                    // If HDR is not supported and current value is HDR-related, default to Auto
                    if (!supportsHDR && (value === "HDR" || value === "HDR EDID")) {
                        return "Auto"
                    }
                    return value
                }
                onValueChanged: (value) => {
                    if (monitorData) {
                        var map = {
                            "Auto": "auto",
                            "sRGB": "srgb",
                            "DCI P3": "dcip3",
                            "Apple P3": "dp3",
                            "Adobe RGB": "adobe",
                            "Wide (BT2020)": "wide",
                            "EDID": "edid",
                            "HDR": "hdr",
                            "HDR EDID": "hdredid"
                        }
                        monitorData.cm = map[value] || "auto"
                        settingChanged("cm", monitorData.cm)
                    }
                }
            }
        }

        StyledText {
            text: "HDR Settings"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.primary
            visible: (!monitorData || !monitorData.disabled) && supportsHDR
            width: parent.width
        }

        GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: Theme.spacingM
            rowSpacing: Theme.spacingXS
            visible: (!monitorData || !monitorData.disabled) && supportsHDR

            StyledText {
                text: "SDR Brightness"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            Row {
                Layout.fillWidth: true
                spacing: Theme.spacingS

                DarkSlider {
                    id: sdrBrightnessSlider
                    width: parent.width - sdrBrightnessValueText.width - parent.spacing
                    minimum: 10
                    maximum: 200
                    value: {
                        if (!monitorData) return 100
                        var brightness = parseFloat(monitorData.sdrbrightness) || 1.0
                        return Math.round(brightness * 100)
                    }
                    onSliderValueChanged: (newValue) => {
                        if (monitorData) {
                            var brightness = (newValue / 100.0).toFixed(2)
                            monitorData.sdrbrightness = brightness
                            settingChanged("sdrbrightness", brightness)
                        }
                    }
                }

                StyledText {
                    id: sdrBrightnessValueText
                    text: {
                        if (!monitorData) return "1.00"
                        var brightness = parseFloat(monitorData.sdrbrightness) || 1.0
                        return brightness.toFixed(2)
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: "SDR Saturation"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            Row {
                Layout.fillWidth: true
                spacing: Theme.spacingS

                DarkSlider {
                    id: sdrSaturationSlider
                    width: parent.width - sdrSaturationValueText.width - parent.spacing
                    minimum: 0
                    maximum: 200
                    value: {
                        if (!monitorData) return 100
                        var saturation = parseFloat(monitorData.sdrsaturation) || 1.0
                        return Math.round(saturation * 100)
                    }
                    onSliderValueChanged: (newValue) => {
                        if (monitorData) {
                            var saturation = (newValue / 100.0).toFixed(2)
                            monitorData.sdrsaturation = saturation
                            settingChanged("sdrsaturation", saturation)
                        }
                    }
                }

                StyledText {
                    id: sdrSaturationValueText
                    text: {
                        if (!monitorData) return "1.00"
                        var saturation = parseFloat(monitorData.sdrsaturation) || 1.0
                        return saturation.toFixed(2)
                    }
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: "SDR EOTF"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            DarkDropdown {
                Layout.fillWidth: true
                text: "SDR EOTF"
                options: ["Follow render:cm_sdr_eotf (0)", "Piecewise sRGB (1)", "Gamma 2.2 (2)"]
                currentValue: {
                    if (!monitorData) return "Follow render:cm_sdr_eotf (0)"
                    var eotf = parseInt(monitorData.sdr_eotf) || 0
                    var options = ["Follow render:cm_sdr_eotf (0)", "Piecewise sRGB (1)", "Gamma 2.2 (2)"]
                    return options[eotf] || options[0]
                }
                onValueChanged: (value) => {
                    if (monitorData) {
                        var options = ["Follow render:cm_sdr_eotf (0)", "Piecewise sRGB (1)", "Gamma 2.2 (2)"]
                        var index = options.indexOf(value)
                        if (index >= 0) {
                            monitorData.sdr_eotf = index.toString()
                            settingChanged("sdr_eotf", index.toString())
                        }
                    }
                }
            }

            DarkToggle {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                text: "Supports Wide Color"
                description: "Force wide color gamut support"
                checked: monitorData ? monitorData.supports_wide_color : false
                onToggled: (checked) => {
                    if (monitorData) {
                        monitorData.supports_wide_color = checked
                        settingChanged("supports_wide_color", checked ? "1" : "0")
                    }
                }
            }

            DarkToggle {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                text: "Supports HDR"
                description: "Force HDR support (requires wide color gamut)"
                checked: monitorData ? monitorData.supports_hdr : false
                onToggled: (checked) => {
                    if (monitorData) {
                        monitorData.supports_hdr = checked
                        settingChanged("supports_hdr", checked ? "1" : "0")
                    }
                }
            }
        }

        // SDR Min Luminance
        Column {
            width: parent.width
            spacing: Theme.spacingS
            visible: (!monitorData || !monitorData.disabled) && supportsHDR

            StyledText {
                text: "SDR Min Luminance"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM

                DarkSlider {
                    id: sdrMinLuminanceSlider
                    width: parent.width - sdrMinLuminanceValueText.width - parent.spacing
                    minimum: 0
                    maximum: 10
                    value: {
                        if (!monitorData) return 0
                        return Math.round((monitorData.sdr_min_luminance || 0.0) * 1000)
                    }
                    onSliderValueChanged: (newValue) => {
                        if (monitorData) {
                            var value = (newValue / 1000.0).toFixed(3)
                            monitorData.sdr_min_luminance = parseFloat(value)
                            settingChanged("sdr_min_luminance", value)
                        }
                    }
                }

                StyledText {
                    id: sdrMinLuminanceValueText
                    text: {
                        if (!monitorData) return "0.000"
                        return (monitorData.sdr_min_luminance || 0.0).toFixed(3)
                    }
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: "Set to 0.005 for true black matching HDR black"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outline
            opacity: 0.12
            visible: !monitorData || !monitorData.disabled
        }

        // SDR Max Luminance
        Column {
            width: parent.width
            spacing: Theme.spacingS
            visible: (!monitorData || !monitorData.disabled) && supportsHDR

            StyledText {
                text: "SDR Max Luminance"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM

                DarkSlider {
                    id: sdrMaxLuminanceSlider
                    width: parent.width - sdrMaxLuminanceValueText.width - parent.spacing
                    minimum: 80
                    maximum: 400
                    value: monitorData ? (monitorData.sdr_max_luminance || 200) : 200
                    onSliderValueChanged: (newValue) => {
                        if (monitorData) {
                            monitorData.sdr_max_luminance = newValue
                            settingChanged("sdr_max_luminance", newValue.toString())
                        }
                    }
                }

                StyledText {
                    id: sdrMaxLuminanceValueText
                    text: (monitorData ? (monitorData.sdr_max_luminance || 200) : 200) + " nits"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: "Typical range: 200-250 nits (default: 200)"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }

        // Min Luminance
        Column {
            width: parent.width
            spacing: Theme.spacingS
            visible: (!monitorData || !monitorData.disabled) && supportsHDR

            StyledText {
                text: "Monitor Min Luminance"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM

                DarkSlider {
                    id: minLuminanceSlider
                    width: parent.width - minLuminanceValueText.width - parent.spacing
                    minimum: 0
                    maximum: 10
                    value: {
                        if (!monitorData) return 0
                        return Math.round((monitorData.min_luminance || 0.0) * 1000)
                    }
                    onSliderValueChanged: (newValue) => {
                        if (monitorData) {
                            var value = (newValue / 1000.0).toFixed(3)
                            monitorData.min_luminance = parseFloat(value)
                            settingChanged("min_luminance", value)
                        }
                    }
                }

                StyledText {
                    id: minLuminanceValueText
                    text: {
                        if (!monitorData) return "0.000"
                        return (monitorData.min_luminance || 0.0).toFixed(3)
                    }
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Max Luminance
        Column {
            width: parent.width
            spacing: Theme.spacingS
            visible: (!monitorData || !monitorData.disabled) && supportsHDR

            StyledText {
                text: "Monitor Max Luminance"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM

                DarkSlider {
                    id: maxLuminanceSlider
                    width: parent.width - maxLuminanceValueText.width - parent.spacing
                    minimum: 0
                    maximum: 2000
                    value: monitorData ? (monitorData.max_luminance || 0) : 0
                    onSliderValueChanged: (newValue) => {
                        if (monitorData) {
                            monitorData.max_luminance = newValue
                            settingChanged("max_luminance", newValue.toString())
                        }
                    }
                }

                StyledText {
                    id: maxLuminanceValueText
                    text: (monitorData ? (monitorData.max_luminance || 0) : 0) + " nits"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outline
            opacity: 0.12
            visible: !monitorData || !monitorData.disabled
        }

        // Max Avg Luminance
        Column {
            width: parent.width
            spacing: Theme.spacingS
            visible: (!monitorData || !monitorData.disabled) && supportsHDR

            StyledText {
                text: "Monitor Max Avg Luminance"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingM

                DarkSlider {
                    id: maxAvgLuminanceSlider
                    width: parent.width - maxAvgLuminanceValueText.width - parent.spacing
                    minimum: 0
                    maximum: 2000
                    value: monitorData ? (monitorData.max_avg_luminance || 0) : 0
                    onSliderValueChanged: (newValue) => {
                        if (monitorData) {
                            monitorData.max_avg_luminance = newValue
                            settingChanged("max_avg_luminance", newValue.toString())
                        }
                    }
                }

                StyledText {
                    id: maxAvgLuminanceValueText
                    text: (monitorData ? (monitorData.max_avg_luminance || 0) : 0) + " nits"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: "Maximum luminance on average for a typical frame"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }
}
