import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals
import qs.Modals.FileBrowser
import qs.Modules.Settings
import qs.Services
import qs.Widgets

Item {
    id: themeColorsTab

    property var parentModal: null
    property var cachedFontFamilies: []
    property var cachedMonoFamilies: []
    property bool fontsEnumerated: false
    property bool forceUpdate: false
    property int currentTabIndex: 0

    function enumerateFonts() {
        var fonts = ["Default"]
        var availableFonts = Qt.fontFamilies()
        var rootFamilies = []
        var seenFamilies = new Set()
        for (var i = 0; i < availableFonts.length; i++) {
            var fontName = availableFonts[i]
            if (fontName.startsWith("."))
                continue

            if (fontName === SettingsData.defaultFontFamily)
                continue

            var rootName = fontName.replace(
                        / (Thin|Extra Light|Light|Regular|Medium|Semi Bold|Demi Bold|Bold|Extra Bold|Black|Heavy)$/i,
                        "").replace(
                        / (Italic|Oblique|Condensed|Extended|Narrow|Wide)$/i,
                        "").replace(/ (UI|Display|Text|Mono|Sans|Serif)$/i,
                                    function (match, suffix) {
                                        return match
                                    }).trim()
            if (!seenFamilies.has(rootName) && rootName !== "") {
                seenFamilies.add(rootName)
                rootFamilies.push(rootName)
            }
        }
        cachedFontFamilies = fonts.concat(rootFamilies.sort())
        var monoFonts = ["Default"]
        var monoFamilies = []
        var seenMonoFamilies = new Set()
        for (var j = 0; j < availableFonts.length; j++) {
            var fontName2 = availableFonts[j]
            if (fontName2.startsWith("."))
                continue

            if (fontName2 === SettingsData.defaultMonoFontFamily)
                continue

            var lowerName = fontName2.toLowerCase()
            if (lowerName.includes("mono") || lowerName.includes(
                        "code") || lowerName.includes(
                        "console") || lowerName.includes(
                        "terminal") || lowerName.includes(
                        "courier") || lowerName.includes(
                        "dejavu sans mono") || lowerName.includes(
                        "jetbrains") || lowerName.includes(
                        "fira") || lowerName.includes(
                        "hack") || lowerName.includes(
                        "source code") || lowerName.includes(
                        "ubuntu mono") || lowerName.includes("cascadia")) {
                var rootName2 = fontName2.replace(
                            / (Thin|Extra Light|Light|Regular|Medium|Semi Bold|Demi Bold|Bold|Extra Bold|Black|Heavy)$/i,
                            "").replace(
                            / (Italic|Oblique|Condensed|Extended|Narrow|Wide)$/i,
                            "").trim()
                if (!seenMonoFamilies.has(rootName2) && rootName2 !== "") {
                    seenMonoFamilies.add(rootName2)
                    monoFamilies.push(rootName2)
                }
            }
        }
        cachedMonoFamilies = monoFonts.concat(monoFamilies.sort())
    }

    Component.onCompleted: {
        if (!fontsEnumerated) {
            enumerateFonts()
            fontsEnumerated = true
        }

        if (typeof ColorPaletteService !== 'undefined') {

            ColorPaletteService.customThemeCreated.connect(function(themeData) {
                if (typeof Theme !== 'undefined') {
                    Theme.customThemeData = themeData

                    Theme.switchTheme("custom", true, false) // Save prefs, no transition

                    Theme.generateSystemThemesFromCurrentTheme()
                } else {
                }
            })

            ColorPaletteService.colorsExtracted.connect(function() {
                themeColorsTab.forceUpdate = !themeColorsTab.forceUpdate
            })

            ColorPaletteService.themesUpdated.connect(function() {
                themeColorsTab.forceUpdate = !themeColorsTab.forceUpdate
            })
        }
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingL
        spacing: Theme.spacingM

        DarkTabBar {
            id: tabBar
            width: parent.width
            currentIndex: themeColorsTab.currentTabIndex
            spacing: Theme.spacingS
            equalWidthTabs: true

            model: [
                { icon: "palette", text: "Theme & Colors" },
                { icon: "wallpaper", text: "Wallpaper" },
                { icon: "monitor", text: "Displays" }
            ]

            onTabClicked: function(index) {
                themeColorsTab.currentTabIndex = index
            }
        }

        StackLayout {
            id: tabStack
            width: parent.width
            height: parent.height - tabBar.height - Theme.spacingM
            currentIndex: themeColorsTab.currentTabIndex

            DarkFlickable {
                id: themeColorsFlickable
                clip: true
                contentHeight: mainColumn.height
                contentWidth: width

                Column {
                    id: mainColumn
                    width: parent.width
                    spacing: Theme.spacingXL


            StyledRect {
                width: parent.width
                height: themeSection.implicitHeight + Theme.spacingXL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g,
                               Theme.surfaceContainer.b, 0.6)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.12)
                border.width: 1

                Column {
                    id: themeSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingXL
                    spacing: Theme.spacingXL

                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "palette"
                            size: Theme.iconSize
                            color: Theme.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Column {
                            spacing: 4
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            StyledText {
                                text: "Theme Color"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: {
                                    if (Theme.currentTheme === Theme.dynamic) {
                                        return "Material colors generated from wallpaper"
                                    }
                                    if (Theme.currentThemeCategory === "catppuccin") {
                                        return "Soothing pastel theme based on Catppuccin"
                                    }
                                    if (Theme.currentTheme === Theme.custom) {
                                        return "Custom theme loaded from JSON file"
                                    }
                                    return "Material Design inspired color themes"
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.parent.width - Theme.iconSize - Theme.spacingM
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: {
                                if (Theme.currentTheme === Theme.dynamic) {
                                    return "Dynamic"
                                } else if (Theme.currentThemeCategory === "catppuccin") {
                                    return "Catppuccin " + Theme.getThemeColors(Theme.currentThemeName).name
                                } else {
                                    return Theme.getThemeColors(Theme.currentThemeName).name
                                }
                            }
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.primary
                            font.weight: Font.Medium
                        }
                    }

                    Column {
                        spacing: Theme.spacingL
                        width: parent.width

                        DarkButtonGroup {
                            property int currentThemeIndex: {
                                if (Theme.currentTheme === Theme.dynamic) return 2
                                if (Theme.currentThemeName === "custom") return 3
                                if (Theme.currentThemeCategory === "catppuccin") return 1
                                return 0
                            }

                            model: ["Generic", "Catppuccin", "Auto", "Custom"]
                            currentIndex: currentThemeIndex
                            selectionMode: "single"
                            onSelectionChanged: (index, selected) => {
                                if (!selected) return
                                switch (index) {
                                    case 0: Theme.switchThemeCategory("generic", "blue"); break
                                    case 1: Theme.switchThemeCategory("catppuccin", "cat-mauve"); break
                                    case 2:
                                        if (ToastService.wallpaperErrorStatus === "matugen_missing")
                                            ToastService.showError("matugen not found - install matugen package for dynamic theming")
                                        else if (ToastService.wallpaperErrorStatus === "error")
                                            ToastService.showError("Wallpaper processing failed - check wallpaper path")
                                        else
                                            Theme.switchTheme(Theme.dynamic, true, false)
                                        break
                                    case 3:
                                        if (Theme.currentThemeName !== "custom") {
                                            Theme.switchTheme("custom", true, false)
                                        }
                                        break
                                }
                            }
                        }

                        Column {
                            spacing: Theme.spacingL
                            width: parent.width
                            visible: Theme.currentThemeCategory === "generic" && Theme.currentTheme !== Theme.dynamic && Theme.currentThemeName !== "custom"

                            Rectangle {
                                id: extractButton
                                property bool isEnabled: !ColorPaletteService.isExtracting && Theme.wallpaperPath
                                property bool isHovered: extractMouseArea.containsMouse
                                property bool isPressed: extractMouseArea.pressed

                                width: 180
                                height: 44
                                radius: Theme.cornerRadius
                                color: isEnabled ? (isPressed ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : (isHovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1))) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.3)
                                opacity: isEnabled ? 1.0 : 0.5
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, isEnabled ? (isHovered ? 0.2 : 0.15) : 0.1)
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }

                                Rectangle {
                                    id: extractStateLayer
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Theme.surfaceTint
                                    opacity: extractButton.isEnabled && extractButton.isHovered ? 0.08 : 0
                                    visible: opacity > 0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Theme.shortDuration
                                            easing.type: Theme.standardEasing
                                        }
                                    }
                                }

                                Item {
                                    anchors.centerIn: parent
                                    width: extractContentRow.implicitWidth
                                    height: extractContentRow.implicitHeight

                                    Row {
                                        id: extractContentRow
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingS

                                        DarkIcon {
                                            name: ColorPaletteService.isExtracting ? "hourglass_empty" : "palette"
                                            size: 20
                                            color: extractButton.isEnabled ? Theme.primary : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: true
                                        }

                                        StyledText {
                                            text: ColorPaletteService.isExtracting ? "Extracting..." : "Extract Colors"
                                            color: extractButton.isEnabled ? Theme.primary : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                                            anchors.verticalCenter: parent.verticalCenter
                                            font.pixelSize: Theme.fontSizeMedium
                                            font.weight: Font.Medium
                                        }
                                    }
                                }

                                MouseArea {
                                    id: extractMouseArea
                                    anchors.fill: parent
                                    enabled: extractButton.isEnabled
                                    hoverEnabled: true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (Theme.wallpaperPath && typeof ColorPaletteService !== 'undefined') {
                                            ColorPaletteService.extractColorsFromWallpaper(Theme.wallpaperPath)
                                        }
                                    }
                                }
                            }

                            Column {
                                spacing: Theme.spacingM
                                width: parent.width
                                visible: true // Always show, even when empty

                                StyledText {
                                    text: "Saved Color Themes"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }

                                Row {
                                    spacing: Theme.spacingM

                                    Rectangle {
                                        width: 220
                                        height: 40
                                        radius: Theme.cornerRadius
                                        color: Theme.contentBackground()
                                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                        border.width: 1

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Theme.shortDuration
                                                easing.type: Theme.standardEasing
                                            }
                                        }

                                        Row {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: Theme.spacingL
                                            anchors.rightMargin: Theme.spacingL
                                            spacing: Theme.spacingM

                                            StyledText {
                                                id: selectedThemeText
                                                text: {
                                                    if (SettingsData.currentColorTheme) {
                                                        return `#${SettingsData.currentColorTheme.toUpperCase()}`
                                                    } else if (ColorPaletteService.availableThemes.length > 0) {
                                                        return "Select Theme"
                                                    } else {
                                                        return "No themes saved"
                                                    }
                                                }
                                                color: Theme.surfaceText
                                                anchors.verticalCenter: parent.verticalCenter
                                                font.pixelSize: Theme.fontSizeMedium
                                            }

                                            DarkIcon {
                                                name: "keyboard_arrow_down"
                                                size: 20
                                                color: Theme.surfaceText
                                                anchors.verticalCenter: parent.verticalCenter
                                                opacity: 0.7
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (themeDropdown.visible) {
                                                    themeDropdown.visible = false
                                                } else {
                                                    themeDropdown.visible = true
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: Theme.cornerRadius
                                        color: Theme.error || "#f44336"
                                        visible: SettingsData.currentColorTheme !== ""
                                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                        border.width: 1

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Theme.shortDuration
                                                easing.type: Theme.standardEasing
                                            }
                                        }

                                        DarkIcon {
                                            name: "delete"
                                            size: 18
                                            color: Theme.errorText || "#ffffff"
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (SettingsData.currentColorTheme) {
                                                    ColorPaletteService.deleteTheme(SettingsData.currentColorTheme)
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: themeDropdown
                                    width: 220
                                    height: Math.min(240, ColorPaletteService.availableThemes.length * 40 + 8)
                                    radius: Theme.cornerRadius
                                    color: Theme.surfaceContainer
                                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                    border.width: 1
                                    visible: false
                                    layer.enabled: true
                                    layer.smooth: true

                                    ListView {
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingXS
                                        model: ColorPaletteService.availableThemes
                                        clip: true
                                        spacing: 2

                                        delegate: Rectangle {
                                            width: ListView.view.width - Theme.spacingXS * 2
                                            height: 40
                                            color: mouseArea.containsMouse ? Theme.primaryHoverLight : "transparent"
                                            radius: Theme.cornerRadius
                                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                            border.width: 1

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Theme.shorterDuration
                                                    easing.type: Theme.standardEasing
                                                }
                                            }

                                            Row {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: Theme.spacingL
                                                spacing: Theme.spacingM

                                                Rectangle {
                                                    width: 20
                                                    height: 20
                                                    radius: 10
                                                    color: modelData.primaryColor
                                                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                                    border.width: 1
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                StyledText {
                                                    text: modelData.displayName
                                                    color: Theme.surfaceText
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }

                                            MouseArea {
                                                id: mouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    ColorPaletteService.loadThemeByName(modelData.name)
                                                    themeDropdown.visible = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Column {
                                spacing: Theme.spacingL
                                width: parent.width

                                StyledText {
                                    text: ColorPaletteService.extractedColors.length > 0 ? "Extracted Colors" : "Theme Colors"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    visible: {
                                        if (ColorPaletteService.extractedColors.length > 0) {
                                            return ColorPaletteService.extractedColors.length > 0
                                        }
                                        return ["blue", "purple", "green", "orange", "red", "cyan", "pink", "amber", "coral", "monochrome"].length > 0
                                    }
                                }

                                Grid {
                                    id: colorGrid
                                    columns: {
                                        var colors = ColorPaletteService.extractedColors.length > 0 ?
                                                    ColorPaletteService.extractedColors :
                                                    ["blue", "purple", "green", "orange", "red", "cyan", "pink", "amber", "coral", "monochrome"]
                                        var count = colors.length
                                        if (count <= 4) return count
                                        if (count <= 8) return 4
                                        if (count <= 12) return 4
                                        return 4
                                    }
                                    rowSpacing: Theme.spacingM
                                    columnSpacing: Theme.spacingM

                                    Repeater {
                                        model: {
                                            forceUpdate // Trigger update when this changes
                                            return ColorPaletteService.extractedColors.length > 0 ?
                                                   ColorPaletteService.extractedColors : // Show all extracted colors
                                                   ["blue", "purple", "green", "orange", "red", "cyan", "pink", "amber", "coral", "monochrome"] // Fallback to original colors
                                        }

                                        Rectangle {
                                            property string colorValue: modelData
                                            property bool isExtractedColor: ColorPaletteService.extractedColors.length > 0
                                            property bool isSelected: isExtractedColor && ColorPaletteService.selectedColors.includes(colorValue)
                                            property string textColor: {
                                                if (isExtractedColor && typeof SettingsData !== 'undefined') {

                                                    const hexR = Math.max(0, Math.min(255, SettingsData.extractedColorTextR)).toString(16).padStart(2, '0')
                                                    const hexG = Math.max(0, Math.min(255, SettingsData.extractedColorTextG)).toString(16).padStart(2, '0')
                                                    const hexB = Math.max(0, Math.min(255, SettingsData.extractedColorTextB)).toString(16).padStart(2, '0')
                                                    return "#" + hexR + hexG + hexB
                                                }
                                                return Theme.primary
                                            }
                                            width: 40
                                            height: 40
                                            radius: 20
                                            color: isExtractedColor ? colorValue : Theme.getThemeColors(colorValue).primary
                                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                            border.width: isSelected ? 3 : 1
                                            scale: isSelected ? 1.1 : 1

                                            DarkIcon {
                                                name: "check"
                                                size: 20
                                                color: parent.textColor
                                                anchors.centerIn: parent
                                                visible: isSelected
                                                opacity: isSelected ? 1 : 0

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: Theme.shortDuration
                                                        easing.type: Theme.standardEasing
                                                    }
                                                }

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Theme.shortDuration
                                                        easing.type: Theme.standardEasing
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                width: nameText.contentWidth + Theme.spacingL
                                                height: nameText.contentHeight + Theme.spacingS
                                                color: Theme.surfaceContainer
                                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                                border.width: 1
                                                radius: Theme.cornerRadius
                                                anchors.bottom: parent.top
                                                anchors.bottomMargin: Theme.spacingS
                                                visible: mouseArea.containsMouse
                                                layer.enabled: true
                                                layer.smooth: true

                                                StyledText {
                                                    id: nameText
                                                    property string textColorValue: {
                                                        if (isExtractedColor && typeof SettingsData !== 'undefined') {

                                                            const hexR = Math.max(0, Math.min(255, SettingsData.extractedColorTextR)).toString(16).padStart(2, '0')
                                                            const hexG = Math.max(0, Math.min(255, SettingsData.extractedColorTextG)).toString(16).padStart(2, '0')
                                                            const hexB = Math.max(0, Math.min(255, SettingsData.extractedColorTextB)).toString(16).padStart(2, '0')
                                                            return "#" + hexR + hexG + hexB
                                                        }
                                                        return Theme.surfaceText
                                                    }
                                                    text: isExtractedColor ? colorValue : Theme.getThemeColors(colorValue).name
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    font.weight: Font.Medium
                                                    color: textColorValue
                                                    anchors.centerIn: parent

                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: Theme.shortDuration
                                                            easing.type: Theme.standardEasing
                                                        }
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                id: mouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (isExtractedColor) {
                                                        ColorPaletteService.clearSelection()
                                                        ColorPaletteService.selectColor(colorValue, true)
                                                        ColorPaletteService.applySelectedColors()
                                                    } else {
                                                        Theme.switchTheme(colorValue)
                                                    }
                                                }
                                            }

                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: Theme.shortDuration
                                                    easing.type: Theme.emphasizedEasing
                                                }
                                            }

                                            Behavior on border.width {
                                                NumberAnimation {
                                                    duration: Theme.shortDuration
                                                    easing.type: Theme.emphasizedEasing
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            spacing: Theme.spacingS
                            visible: Theme.currentThemeCategory === "catppuccin" && Theme.currentTheme !== Theme.dynamic && Theme.currentThemeName !== "custom"

                            Row {
                                spacing: Theme.spacingM

                                Repeater {
                                    model: ["cat-rosewater", "cat-flamingo", "cat-pink", "cat-mauve", "cat-red", "cat-maroon", "cat-peach"]

                                    Rectangle {
                                        property string themeName: modelData
                                        width: 40
                                        height: 40
                                        radius: 20
                                        color: Theme.getCatppuccinColor(themeName)
                                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                        border.width: (Theme.currentThemeName === themeName && Theme.currentTheme !== Theme.dynamic) ? 3 : 1
                                        scale: (Theme.currentThemeName === themeName && Theme.currentTheme !== Theme.dynamic) ? 1.1 : 1

                                        Rectangle {
                                            width: nameTextCat.contentWidth + Theme.spacingL
                                            height: nameTextCat.contentHeight + Theme.spacingS
                                            color: Theme.surfaceContainer
                                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                            border.width: 1
                                            radius: Theme.cornerRadius
                                            anchors.bottom: parent.top
                                            anchors.bottomMargin: Theme.spacingS
                                            visible: mouseAreaCat.containsMouse
                                            layer.enabled: true
                                            layer.smooth: true

                                            StyledText {
                                                id: nameTextCat
                                                text: Theme.getCatppuccinVariantName(themeName)
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.Medium
                                                color: Theme.surfaceText
                                                anchors.centerIn: parent
                                            }
                                        }

                                        MouseArea {
                                            id: mouseAreaCat
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Theme.switchTheme(themeName)
                                            }
                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: Theme.shortDuration
                                                easing.type: Theme.emphasizedEasing
                                            }
                                        }

                                        Behavior on border.width {
                                            NumberAnimation {
                                                duration: Theme.shortDuration
                                                easing.type: Theme.emphasizedEasing
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: Theme.spacingM

                                Repeater {
                                    model: ["cat-yellow", "cat-green", "cat-teal", "cat-sky", "cat-sapphire", "cat-blue", "cat-lavender"]

                                    Rectangle {
                                        property string themeName: modelData
                                        width: 40
                                        height: 40
                                        radius: 20
                                        color: Theme.getCatppuccinColor(themeName)
                                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                        border.width: (Theme.currentThemeName === themeName && Theme.currentTheme !== Theme.dynamic) ? 3 : 1
                                        scale: (Theme.currentThemeName === themeName && Theme.currentTheme !== Theme.dynamic) ? 1.1 : 1

                                        Rectangle {
                                            width: nameTextCat2.contentWidth + Theme.spacingL
                                            height: nameTextCat2.contentHeight + Theme.spacingS
                                            color: Theme.surfaceContainer
                                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                            border.width: 1
                                            radius: Theme.cornerRadius
                                            anchors.bottom: parent.top
                                            anchors.bottomMargin: Theme.spacingS
                                            visible: mouseAreaCat2.containsMouse
                                            layer.enabled: true
                                            layer.smooth: true

                                            StyledText {
                                                id: nameTextCat2
                                                text: Theme.getCatppuccinVariantName(themeName)
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.Medium
                                                color: Theme.surfaceText
                                                anchors.centerIn: parent
                                            }
                                        }

                                        MouseArea {
                                            id: mouseAreaCat2
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Theme.switchTheme(themeName)
                                            }
                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: Theme.shortDuration
                                                easing.type: Theme.emphasizedEasing
                                            }
                                        }

                                        Behavior on border.width {
                                            NumberAnimation {
                                                duration: Theme.shortDuration
                                                easing.type: Theme.emphasizedEasing
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingM
                            visible: Theme.currentTheme === Theme.dynamic

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledRect {
                                    width: 120
                                    height: 90
                                    radius: Theme.cornerRadius
                                    color: Theme.surfaceVariant
                                    border.color: Theme.outline
                                    border.width: 1

                                    CachingImage {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        source: Theme.wallpaperPath ? "file://" + Theme.wallpaperPath : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: Theme.wallpaperPath && !Theme.wallpaperPath.startsWith("#")
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            maskEnabled: true
                                            maskSource: autoWallpaperMask
                                            maskThresholdMin: 0.5
                                            maskSpreadAtMin: 1
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        radius: Theme.cornerRadius - 1
                                        color: Theme.wallpaperPath && Theme.wallpaperPath.startsWith("#") ? Theme.wallpaperPath : "transparent"
                                        visible: Theme.wallpaperPath && Theme.wallpaperPath.startsWith("#")
                                    }

                                    Rectangle {
                                        id: autoWallpaperMask
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        radius: Theme.cornerRadius - 1
                                        color: "black"
                                        visible: false
                                        layer.enabled: true
                                    }

                                    DarkIcon {
                                        anchors.centerIn: parent
                                        name: {
                                            if (ToastService.wallpaperErrorStatus === "error" || ToastService.wallpaperErrorStatus === "matugen_missing")
                                                return "error"
                                            else
                                                return "palette"
                                        }
                                        size: Theme.iconSizeLarge
                                        color: {
                                            if (ToastService.wallpaperErrorStatus === "error" || ToastService.wallpaperErrorStatus === "matugen_missing")
                                                return Theme.error
                                            else
                                                return Theme.surfaceVariantText
                                        }
                                        visible: !Theme.wallpaperPath
                                    }
                                }

                                Column {
                                    width: parent.width - 120 - Theme.spacingM
                                    spacing: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        text: {
                                            if (ToastService.wallpaperErrorStatus === "error")
                                                return "Wallpaper Error"
                                            else if (ToastService.wallpaperErrorStatus === "matugen_missing")
                                                return "Matugen Missing"
                                            else if (Theme.wallpaperPath)
                                                return Theme.wallpaperPath.split('/').pop()
                                            else
                                                return "No wallpaper selected"
                                        }
                                        font.pixelSize: Theme.fontSizeLarge
                                        color: Theme.surfaceText
                                        elide: Text.ElideMiddle
                                        maximumLineCount: 1
                                        width: parent.width
                                    }

                                    StyledText {
                                        text: {
                                            if (ToastService.wallpaperErrorStatus === "error")
                                                return "Wallpaper processing failed"
                                            else if (ToastService.wallpaperErrorStatus === "matugen_missing")
                                                return "Install matugen package for dynamic theming"
                                            else if (Theme.wallpaperPath)
                                                return Theme.wallpaperPath
                                            else
                                                return "Dynamic colors from wallpaper"
                                        }
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: {
                                            if (ToastService.wallpaperErrorStatus === "error" || ToastService.wallpaperErrorStatus === "matugen_missing")
                                                return Theme.error
                                            else
                                                return Theme.surfaceVariantText
                                        }
                                        elide: Text.ElideMiddle
                                        maximumLineCount: 2
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingM
                            visible: Theme.currentThemeName === "custom"

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                DarkActionButton {
                                    buttonSize: 48
                                    iconName: "folder_open"
                                    iconSize: Theme.iconSize
                                    backgroundColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                                    iconColor: Theme.primary
                                    onClicked: fileBrowserModal.open()
                                }

                                Column {
                                    width: parent.width - 48 - Theme.spacingM
                                    spacing: Theme.spacingXS
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        text: SettingsData.customThemeFile ? SettingsData.customThemeFile.split('/').pop() : "No custom theme file"
                                        font.pixelSize: Theme.fontSizeLarge
                                        color: Theme.surfaceText
                                        elide: Text.ElideMiddle
                                        maximumLineCount: 1
                                        width: parent.width
                                    }

                                    StyledText {
                                        text: SettingsData.customThemeFile || "Click to select a custom theme JSON file"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                        elide: Text.ElideMiddle
                                        maximumLineCount: 1
                                        width: parent.width
                                    }
                                }
                            }
                        }
                    }
                }
            }


            StyledRect {
                width: parent.width
                height: textColorAdjustmentSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: textColorAdjustmentSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "format_color_text"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS
                            width: parent.width - Theme.iconSize - Theme.spacingM

                            StyledText {
                                text: "Extracted Color Text Override"
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                            }

                            StyledText {
                                text: "Override the text color for extracted colors using RGB values"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Red: " + SettingsData.extractedColorTextR
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 32
                            value: SettingsData.extractedColorTextR
                            minimum: 0
                            maximum: 255
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {

                                SettingsData.extractedColorTextR = newValue
                            }
                            onSliderDragFinished: finalValue => {

                                SettingsData.setExtractedColorTextR(finalValue)
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Green: " + SettingsData.extractedColorTextG
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 32
                            value: SettingsData.extractedColorTextG
                            minimum: 0
                            maximum: 255
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {

                                SettingsData.extractedColorTextG = newValue
                            }
                            onSliderDragFinished: finalValue => {

                                SettingsData.setExtractedColorTextG(finalValue)
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Blue: " + SettingsData.extractedColorTextB
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 32
                            value: SettingsData.extractedColorTextB
                            minimum: 0
                            maximum: 255
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {

                                SettingsData.extractedColorTextB = newValue
                            }
                            onSliderDragFinished: finalValue => {

                                SettingsData.setExtractedColorTextB(finalValue)
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        StyledRect {
                            width: (parent.width - Theme.spacingM) / 2
                            height: 40
                            radius: Theme.cornerRadius
                            color: saveButtonMouseArea.containsMouse ? Theme.primary : Theme.primaryContainer

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DarkIcon {
                                    name: "save"
                                    size: 18
                                    color: Theme.primaryText || Theme.onPrimary || "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Save"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.primaryText || Theme.onPrimary || "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: saveButtonMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {

                                    if (SettingsData.currentColorTheme) {
                                        SettingsData.saveTextColorPreset(SettingsData.currentColorTheme)
                                    } else {
                                        SettingsData.saveTextColorPreset("")
                                    }
                                    if (typeof ToastService !== 'undefined') {
                                        ToastService.showInfo("RGB text color saved")
                                    }
                                }
                            }
                        }

                        StyledRect {
                            width: (parent.width - Theme.spacingM) / 2
                            height: 40
                            radius: Theme.cornerRadius
                            color: loadButtonMouseArea.containsMouse ? Theme.secondary : (typeof Theme !== 'undefined' && Theme.secondaryContainer ? Theme.secondaryContainer : Theme.surfaceVariant)

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DarkIcon {
                                    name: "folder_open"
                                    size: 18
                                    color: ColorPaletteService.getTextColorForBackground(loadButtonMouseArea.containsMouse ? Theme.secondary : (typeof Theme !== 'undefined' && Theme.secondaryContainer ? Theme.secondaryContainer : Theme.surfaceVariant))
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Load"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: ColorPaletteService.getTextColorForBackground(loadButtonMouseArea.containsMouse ? Theme.secondary : (typeof Theme !== 'undefined' && Theme.secondaryContainer ? Theme.secondaryContainer : Theme.surfaceVariant))
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: loadButtonMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {

                                    if (SettingsData.currentColorTheme) {
                                        const loaded = SettingsData.loadTextColorFromTheme(SettingsData.currentColorTheme)
                                        if (loaded) {
                                            if (typeof ToastService !== 'undefined') {
                                                ToastService.showInfo("RGB text color loaded from theme")
                                            }
                                        } else {
                                            if (typeof ToastService !== 'undefined') {
                                                ToastService.showInfo("No saved RGB values for this theme")
                                            }
                                        }
                                    } else {
                                        if (typeof ToastService !== 'undefined') {
                                            ToastService.showInfo("No theme selected")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Preview"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }

                        Rectangle {
                            width: parent.width
                            height: 60
                            radius: Theme.cornerRadius
                            color: ColorPaletteService.extractedColors.length > 0 && ColorPaletteService.extractedColors[0] ? ColorPaletteService.extractedColors[0] : "#000000"
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                            border.width: 1

                            StyledText {
                                id: previewText
                                anchors.centerIn: parent
                                text: "Sample Text"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                property string previewColor: ColorPaletteService.extractedColors.length > 0 && ColorPaletteService.extractedColors[0] ? ColorPaletteService.extractedColors[0] : "#000000"
                                color: ColorPaletteService.getTextColorForBackground(previewColor)

                                Connections {
                                    target: ColorPaletteService
                                    function onTextColorAdjustmentChanged() {
                                        previewText.color = ColorPaletteService.getTextColorForBackground(previewText.previewColor)
                                    }
                                }

                                Connections {
                                    target: SettingsData
                                    function onExtractedColorTextRChanged() {
                                        previewText.color = ColorPaletteService.getTextColorForBackground(previewText.previewColor)
                                    }
                                    function onExtractedColorTextGChanged() {
                                        previewText.color = ColorPaletteService.getTextColorForBackground(previewText.previewColor)
                                    }
                                    function onExtractedColorTextBChanged() {
                                        previewText.color = ColorPaletteService.getTextColorForBackground(previewText.previewColor)
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: uiScaleSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: uiScaleSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "zoom_in"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Settings UI Scale"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    StyledText {
                        text: "Scale the settings window, icons, and controls. Use Font Scale for text."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        StyledText {
                            text: "Scale"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            width: 60
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DarkSlider {
                            id: uiScaleSlider

                            width: parent.width - 60 - Theme.spacingM - 60
                            height: Theme.scaledHeight(32)
                            minimum: 80
                            maximum: 140
                            value: Math.round((SettingsData.settingsUiScale > 0 ? SettingsData.settingsUiScale : 1.0) * 100)
                            unit: "%"
                            showValue: false
                            wheelEnabled: false
                            anchors.verticalCenter: parent.verticalCenter

                            onSliderValueChanged: newValue => {
                                const scale = newValue / 100.0
                                SettingsData.setSettingsUiScale(scale)
                            }
                        }

                        StyledText {
                            text: (SettingsData.settingsUiScale * 100).toFixed(0) + "%"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            width: 60
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: advancedScaleSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: advancedScaleSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "tune"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Advanced Scaling"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            width: 1
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DarkToggle {
                            checked: SettingsData.settingsUiAdvancedScaling
                            anchors.verticalCenter: parent.verticalCenter
                            onToggled: value => {
                                SettingsData.settingsUiAdvancedScaling = value
                            }
                        }
                    }

                    StyledText {
                        text: "Individually adjust window size, controls, and icons in settings."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: SettingsData.settingsUiAdvancedScaling

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Window Scale"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            DarkSlider {
                                width: parent.width - 100 - Theme.spacingM - 60
                                height: Theme.scaledHeight(28)
                                minimum: 80
                                maximum: 140
                                value: Math.round((SettingsData.settingsUiWindowScale || 1.0) * 100)
                                unit: "%"
                                showValue: false
                                wheelEnabled: false
                                anchors.verticalCenter: parent.verticalCenter
                                onSliderValueChanged: newValue => {
                                    const scale = newValue / 100.0
                                    SettingsData.settingsUiWindowScale = scale
                                    SettingsData.setSettingsWindowWidth(0)
                                    SettingsData.setSettingsWindowHeight(0)
                                }
                            }

                            StyledText {
                                text: ((SettingsData.settingsUiWindowScale || 1.0) * 100).toFixed(0) + "%"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                width: 60
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Window Width"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            DarkSlider {
                                width: parent.width - 100 - Theme.spacingM - 60
                                height: Theme.scaledHeight(28)
                                minimum: 600
                                maximum: Math.min(Screen.width - 40, 3000)
                                value: SettingsData.settingsWindowWidth > 0
                                       ? SettingsData.settingsWindowWidth
                                       : Math.min(Screen.width - 40, 1280)
                                unit: "px"
                                showValue: true
                                wheelEnabled: false
                                anchors.verticalCenter: parent.verticalCenter
                                onSliderValueChanged: newValue => {
                                    SettingsData.setSettingsWindowWidth(newValue)
                                }
                            }

                            StyledText {
                                text: (SettingsData.settingsWindowWidth > 0
                                       ? SettingsData.settingsWindowWidth
                                       : Math.min(Screen.width - 40, 1280)) + "px"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                width: 60
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Window Height"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            DarkSlider {
                                width: parent.width - 100 - Theme.spacingM - 60
                                height: Theme.scaledHeight(28)
                                minimum: 500
                                maximum: Math.min(Screen.height - 20, 2000)
                                value: SettingsData.settingsWindowHeight > 0
                                       ? SettingsData.settingsWindowHeight
                                       : Math.min(Screen.height - 20, 950)
                                unit: "px"
                                showValue: true
                                wheelEnabled: false
                                anchors.verticalCenter: parent.verticalCenter
                                onSliderValueChanged: newValue => {
                                    SettingsData.setSettingsWindowHeight(newValue)
                                }
                            }

                            StyledText {
                                text: (SettingsData.settingsWindowHeight > 0
                                       ? SettingsData.settingsWindowHeight
                                       : Math.min(Screen.height - 20, 950)) + "px"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                width: 60
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Font Scale"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            DarkSlider {
                                width: parent.width - 100 - Theme.spacingM - 60
                                height: Theme.scaledHeight(28)
                                minimum: 80
                                maximum: 200
                                value: Math.round((SettingsData.fontScale || 1.0) * 100)
                                unit: "%"
                                showValue: false
                                wheelEnabled: false
                                anchors.verticalCenter: parent.verticalCenter
                                onSliderValueChanged: newValue => {
                                    const scale = newValue / 100.0
                                    SettingsData.setFontScale(scale)
                                }
                            }

                            StyledText {
                                text: (SettingsData.fontScale * 100).toFixed(0) + "%"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                width: 60
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Controls"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            DarkSlider {
                                width: parent.width - 100 - Theme.spacingM - 60
                                height: Theme.scaledHeight(28)
                                minimum: 80
                                maximum: 140
                                value: Math.round((SettingsData.settingsUiControlScale || 1.0) * 100)
                                unit: "%"
                                showValue: false
                                wheelEnabled: false
                                anchors.verticalCenter: parent.verticalCenter
                                onSliderValueChanged: newValue => {
                                    SettingsData.settingsUiControlScale = newValue / 100.0
                                }
                            }

                            StyledText {
                                text: ((SettingsData.settingsUiControlScale || 1.0) * 100).toFixed(0) + "%"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                width: 60
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Icons"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            DarkSlider {
                                width: parent.width - 100 - Theme.spacingM - 60
                                height: Theme.scaledHeight(28)
                                minimum: 80
                                maximum: 140
                                value: Math.round((SettingsData.settingsUiIconScale || 1.0) * 100)
                                unit: "%"
                                showValue: false
                                wheelEnabled: false
                                anchors.verticalCenter: parent.verticalCenter
                                onSliderValueChanged: newValue => {
                                    SettingsData.settingsUiIconScale = newValue / 100.0
                                }
                            }

                            StyledText {
                                text: ((SettingsData.settingsUiIconScale || 1.0) * 100).toFixed(0) + "%"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                width: 60
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }


            StyledRect {
                width: parent.width
                height: transparencySection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: transparencySection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "opacity"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    StyledText {
                        text: "Transparency & Opacity"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                StyledText {
                    text: "Control the transparency levels of various UI elements"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignLeft
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingL
                }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        Item {
                            width: parent.width
                            height: Math.max(transparencyLabel.height, widgetColorGroup.height)

                            StyledText {
                                id: transparencyLabel
                                text: "Top Bar Widget Transparency"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            DarkButtonGroup {
                                id: widgetColorGroup
                                property int currentColorIndex: {
                                    switch (SettingsData.widgetBackgroundColor) {
                                        case "sth": return 0
                                        case "s": return 1
                                        case "sc": return 2
                                        case "sch": return 3
                                        default: return 0
                                    }
                                }

                                model: ["sth", "s", "sc", "sch"]
                                currentIndex: currentColorIndex
                                selectionMode: "single"
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter

                                buttonHeight: 20
                                minButtonWidth: 32
                                buttonPadding: Theme.spacingS
                                checkIconSize: Theme.iconSizeSmall - 2
                                textSize: Theme.fontSizeSmall - 2
                                spacing: 1

                                onSelectionChanged: (index, selected) => {
                                    if (!selected) return
                                    const colorOptions = ["sth", "s", "sc", "sch"]
                                    SettingsData.setWidgetBackgroundColor(colorOptions[index])
                                }
                            }
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.topBarWidgetTransparency * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setTopBarWidgetTransparency(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Popup Transparency"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.popupTransparency * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setPopupTransparency(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Modal Transparency"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.modalTransparency * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setModalTransparency(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Notification Transparency"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.notificationTransparency * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setNotificationTransparency(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Control Center Transparency"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.controlCenterTransparency * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setControlCenterTransparency(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Control Center Widget Background Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.controlCenterWidgetBackgroundOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setControlCenterWidgetBackgroundOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: darkDashSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: darkDashSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "dashboard"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Dark Dash"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    StyledText {
                        text: "Customize transparency and shadow effects for the Dark Dash popout"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Dark Dash Transparency"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.darkDashTransparency * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setDarkDashTransparency(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Dark Dash Drop Shadow Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.darkDashDropShadowOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setDarkDashDropShadowOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Dark Dash Border Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.darkDashBorderOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setDarkDashBorderOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Dark Dash Border Thickness"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: SettingsData.darkDashBorderThickness
                            minimum: 0
                            maximum: 10
                            unit: "px"
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setDarkDashBorderThickness(
                                                          newValue)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Dark Dash Tab Bar Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.darkDashTabBarOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setDarkDashTabBarOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Dark Dash Content Background Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.darkDashContentBackgroundOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setDarkDashContentBackgroundOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Dark Dash Animated Tint Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.darkDashAnimatedTintOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setDarkDashAnimatedTintOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: desktopWidgetsSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: desktopWidgetsSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "widgets"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Desktop Widgets"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    StyledText {
                        text: "Customize transparency, shadow, and border effects for desktop widgets"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Desktop Widget Drop Shadow Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.desktopWidgetDropShadowOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setDesktopWidgetDropShadowOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Desktop Widget Border Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.desktopWidgetBorderOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setDesktopWidgetBorderOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Desktop Widget Border Thickness"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: SettingsData.desktopWidgetBorderThickness
                            minimum: 0
                            maximum: 10
                            unit: "px"
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setDesktopWidgetBorderThickness(
                                                          newValue)
                                                  }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: iconTintingSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: iconTintingSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "palette"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingM
                                   - iconTintingToggle.width - Theme.spacingM
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: "Icon Color Tinting"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: "Apply wallpaper-based color tinting to system icons and system tray icons"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }

                        DarkToggle {
                            id: iconTintingToggle

                            anchors.verticalCenter: parent.verticalCenter
                            checked: SettingsData.systemIconTinting
                            onToggled: checked => {
                                SettingsData.setSystemIconTinting(checked)
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: SettingsData.systemIconTinting

                        StyledText {
                            text: "Tint Intensity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(SettingsData.iconTintIntensity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                SettingsData.setIconTintIntensity(newValue / 100)
                            }
                        }

                        StyledText {
                            text: "Controls how strongly the wallpaper colors are applied to icons"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: bordersShadowsSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: bordersShadowsSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "border_style"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    StyledText {
                        text: "Borders & Shadows"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                StyledText {
                    text: "Customize border styles and shadow effects for UI components"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignLeft
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingL
                }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Control Center Drop Shadow Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.controlCenterDropShadowOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setControlCenterDropShadowOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Top Bar Drop Shadow Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.topBarDropShadowOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setTopBarDropShadowOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Control Center Border Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.controlCenterBorderOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setControlCenterBorderOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Control Center Border Thickness"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: SettingsData.controlCenterBorderThickness
                            minimum: 0
                            maximum: 10
                            unit: "px"
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setControlCenterBorderThickness(
                                                          newValue)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Settings Border Opacity"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: Math.round(
                                       SettingsData.settingsBorderOpacity * 100)
                            minimum: 0
                            maximum: 100
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setSettingsBorderOpacity(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Settings Border Thickness"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: SettingsData.settingsBorderThickness
                            minimum: 0
                            maximum: 10
                            unit: "px"
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setSettingsBorderThickness(
                                                          newValue)
                                                  }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: visualEffectsSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: visualEffectsSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "auto_fix_high"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    StyledText {
                        text: "Visual Effects"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                StyledText {
                    text: "Adjust color intensity, corner rounding, and blur effects"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignLeft
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingL
                }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Color Vibrance"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: SettingsData.colorVibrance * 100
                            minimum: 0
                            maximum: 100
                            unit: "%"
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setColorVibrance(
                                                          newValue / 100)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Corner Radius (0 = square corners)"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: SettingsData.cornerRadius
                            minimum: 0
                            maximum: 32
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setCornerRadius(
                                                          newValue)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Hyprland Blur Size"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: SettingsData.hyprlandBlurSize
                            minimum: 0
                            maximum: 20
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setHyprlandBlurSize(
                                                          newValue)
                                                  }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Hyprland Blur Passes"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        DarkSlider {
                            width: parent.width
                            height: 24
                            value: SettingsData.hyprlandBlurPasses
                            minimum: 1
                            maximum: 10
                            unit: ""
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                                      SettingsData.setHyprlandBlurPasses(
                                                          newValue)
                                                  }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: warningText.implicitHeight + Theme.spacingM * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.warning.r, Theme.warning.g,
                               Theme.warning.b, 0.12)
                border.color: Qt.rgba(Theme.warning.r, Theme.warning.g,
                                      Theme.warning.b, 0.3)
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    DarkIcon {
                        name: "info"
                        size: Theme.iconSizeSmall
                        color: Theme.warning
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        id: warningText
                        font.pixelSize: Theme.fontSizeSmall
                        text: "The below settings will modify your GTK and Qt settings. If you wish to preserve your current configurations, please back them up (qt5ct.conf|qt6ct.conf and ~/.config/gtk-3.0|gtk-4.0)."
                        wrapMode: Text.WordWrap
                        width: parent.width - Theme.iconSizeSmall - Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: iconThemeSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: iconThemeSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        DarkIcon {
                            name: "image"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DarkDropdown {
                            width: parent.width - Theme.iconSize - Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Icon Theme"
                            description: "DarkShell & System Icons\n(requires restart)"
                            currentValue: SettingsData.iconTheme
                            enableFuzzySearch: true
                            popupWidthOffset: 100
                            maxPopupHeight: 236
                            options: {
                                SettingsData.detectAvailableIconThemes()
                                return SettingsData.availableIconThemes
                            }
                            onValueChanged: value => {
                                                SettingsData.setIconTheme(value)
                                                if (Quickshell.env("QT_QPA_PLATFORMTHEME") != "gtk3" &&
                                                    Quickshell.env("QT_QPA_PLATFORMTHEME") != "qt6ct" &&
                                                    Quickshell.env("QT_QPA_PLATFORMTHEME_QT6") != "qt6ct") {
                                                    ToastService.showError("Missing Environment Variables", "You need to set either:\nQT_QPA_PLATFORMTHEME=gtk3 OR\nQT_QPA_PLATFORMTHEME=qt6ct\nas environment variables, and then restart the shell.\n\nqt6ct requires qt6ct-kde to be installed.")
                                                }
                                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: gtkThemeSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: gtkThemeSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        DarkIcon {
                            name: "palette"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DarkDropdown {
                            width: parent.width - Theme.iconSize - Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            text: "GTK Theme"
                            description: "GTK3/GTK4 Applications\n(requires restart)"
                            currentValue: SettingsData.gtkTheme
                            enableFuzzySearch: true
                            popupWidthOffset: 100
                            maxPopupHeight: 236
                            options: {
                                SettingsData.detectAvailableGtkThemes()
                                return SettingsData.availableGtkThemes
                            }
                            onValueChanged: value => {
                                                SettingsData.setGtkTheme(value)
                                                ToastService.showInfo("GTK theme changed", "Restart GTK applications to see changes")
                                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: shellThemeSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: shellThemeSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        DarkIcon {
                            name: "extension"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingXS
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            DarkDropdown {
                                width: parent.width
                                text: "GNOME Shell Theme"
                                description: SettingsData.userThemeExtensionAvailable && SettingsData.userThemeExtensionEnabled
                                            ? "Shell Interface Theme\n(requires shell restart)"
                                            : SettingsData.userThemeExtensionAvailable
                                            ? "Shell Interface Theme\n(extension not enabled)"
                                            : "Shell Interface Theme\n(CSS fallback, no extension)"
                                currentValue: SettingsData.shellTheme
                                enableFuzzySearch: true
                                popupWidthOffset: 100
                                maxPopupHeight: 236
                                options: {
                                    SettingsData.detectAvailableShellThemes()
                                    return SettingsData.availableShellThemes
                                }
                                onValueChanged: value => {
                                                    SettingsData.setShellTheme(value)
                                                }
                            }

                            StyledText {
                                visible: !SettingsData.userThemeExtensionAvailable
                                text: "Note: Using CSS fallback method. Only CSS styling is applied, not full theme assets. Install the user-theme extension for full theme support."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.warning || "#ff9800"
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }

                            StyledText {
                                visible: SettingsData.userThemeExtensionAvailable && !SettingsData.userThemeExtensionEnabled
                                text: "Note: Extension is installed but not enabled. Enable it in GNOME Tweaks or Extensions app for full theme support."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.warning || "#ff9800"
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: qtThemeSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: qtThemeSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        DarkIcon {
                            name: "settings"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingXS
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            DarkDropdown {
                                width: parent.width
                                text: "QT Theme"
                                description: SettingsData.qt5ctAvailable || SettingsData.qt6ctAvailable
                                            ? "QT5/QT6 Applications\n(requires restart)"
                                            : "QT5/QT6 Applications\n(qt5ct/qt6ct not found)"
                                currentValue: SettingsData.qtTheme
                                enableFuzzySearch: true
                                popupWidthOffset: 100
                                maxPopupHeight: 236
                                options: {
                                    SettingsData.detectAvailableQtThemes()
                                    return SettingsData.availableQtThemes
                                }
                                onValueChanged: value => {
                                                    SettingsData.setQtTheme(value)
                                                    if (SettingsData.qt5ctAvailable || SettingsData.qt6ctAvailable) {
                                                        ToastService.showInfo("QT theme changed", "Restart QT applications to see changes")
                                                    }
                                                }
                            }

                            StyledText {
                                visible: !SettingsData.qt5ctAvailable && !SettingsData.qt6ctAvailable
                                text: "Note: Install qt5ct or qt6ct for QT theme support. Without these tools, theme changes will not be applied."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.warning || "#ff9800"
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: cursorThemeSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: cursorThemeSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        DarkIcon {
                            name: "ads_click"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingXS
                            spacing: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter

                            DarkDropdown {
                                width: parent.width
                                text: "Cursor Theme"
                                description: "Mouse Cursor Appearance"
                                currentValue: SettingsData.cursorTheme
                                enableFuzzySearch: true
                                popupWidthOffset: 100
                                maxPopupHeight: 236
                                options: {
                                    SettingsData.detectAvailableCursorThemes()
                                    return SettingsData.availableCursorThemes
                                }
                                onValueChanged: value => {
                                                    SettingsData.setCursorTheme(value, SettingsData.cursorSize)
                                                    ToastService.showInfo("Cursor theme changed", "Cursor theme updated. You may need to log out and back in for full effect.")
                                                }
                            }

                            Column {
                                width: parent.width
                                spacing: Theme.spacingXS

                                StyledText {
                                    text: "Cursor Size: " + SettingsData.cursorSize + "px"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                DarkSlider {
                                    width: parent.width
                                    height: 24
                                    value: SettingsData.cursorSize
                                    minimum: 16
                                    maximum: 48
                                    unit: "px"
                                    showValue: true
                                    wheelEnabled: false
                                    onSliderValueChanged: newValue => {
                                                              SettingsData.setCursorTheme(SettingsData.cursorTheme, newValue)
                                                              ToastService.showInfo("Cursor size changed", "Cursor size updated to " + newValue + "px")
                                                          }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: systemThemingSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                               Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                                      Theme.outline.b, 0.2)
                border.width: 1
                visible: Theme.matugenAvailable

                Column {
                    id: systemThemingSection

                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "extension"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "System App Theming"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Rectangle {
                            width: (parent.width - Theme.spacingM) / 2
                            height: 48
                            radius: Theme.cornerRadius
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            border.color: Theme.primary
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingS

                                DarkIcon {
                                    name: "folder"
                                    size: 16
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Apply GTK Colors"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.primary
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Theme.applyGtkColors()
                            }
                        }

                        Rectangle {
                            width: (parent.width - Theme.spacingM) / 2
                            height: 48
                            radius: Theme.cornerRadius
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            border.color: Theme.primary
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingS

                                DarkIcon {
                                    name: "settings"
                                    size: 16
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Apply Qt Colors"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.primary
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Theme.applyQtColors()
                            }
                        }
                    }

                    StyledText {
                        text: `Generate baseline GTK3/4 or QT5/QT6 (requires qt6ct-kde) configurations to follow DMS colors. Only needed once.<br /><br />It is recommended to install <a href="https://github.com/AvengeMedia/DarkMaterialShell/blob/master/README.md#Theming" style="text-decoration:none; color:${Theme.primary};">Colloid</a> GTK theme prior to applying GTK themes.`
                        textFormat: Text.RichText
                        linkColor: Theme.primary
                        onLinkActivated: url => Qt.openUrlExternally(url)
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            acceptedButtons: Qt.NoButton
                            propagateComposedEvents: true
                        }
                    }
                }
            }
                }
            }

            WallpaperTab {
                id: wallpaperTab
                parentModal: themeColorsTab.parentModal
            }

            DarkFlickable {
                id: displaysFlickable
                clip: true
                contentHeight: displaysColumn.height
                contentWidth: width

                Column {
                    id: displaysColumn
                    width: parent.width
                    spacing: Theme.spacingXL

                    property var variantComponents: [{
                        "id": "topBar",
                        "name": "Top Bar",
                        "description": "System bar with widgets and system information",
                        "icon": "toolbar"
                    }, {
                        "id": "dock",
                        "name": "Application Dock",
                        "description": "Bottom dock for pinned and running applications",
                        "icon": "dock"
                    }, {
                        "id": "notifications",
                        "name": "Notification Popups",
                        "description": "Notification toast popups",
                        "icon": "notifications"
                    }, {
                        "id": "wallpaper",
                        "name": "Wallpaper",
                        "description": "Desktop background images",
                        "icon": "wallpaper"
                    }, {
                        "id": "osd",
                        "name": "On-Screen Displays",
                        "description": "Volume, brightness, and other system OSDs",
                        "icon": "picture_in_picture"
                    }, {
                        "id": "toast",
                        "name": "Toast Messages",
                        "description": "System toast notifications",
                        "icon": "campaign"
                    }, {
                        "id": "notepad",
                        "name": "Notepad Slideout",
                        "description": "Quick note-taking slideout panel",
                        "icon": "sticky_note_2"
                    }, {
                        "id": "systemTray",
                        "name": "System Tray",
                        "description": "System tray icons",
                        "icon": "notifications"
                    }, {
                        "id": "desktopWidgets",
                        "name": "Desktop Widgets",
                        "description": "Floating desktop widgets for system monitoring",
                        "icon": "widgets"
                    }]

                    function getScreenPreferences(componentId) {
                        return SettingsData.screenPreferences && SettingsData.screenPreferences[componentId] || ["all"];
                    }

                    function setScreenPreferences(componentId, screenNames) {
                        var prefs = SettingsData.screenPreferences ? Object.assign({}, SettingsData.screenPreferences) : {};
                        prefs[componentId] = screenNames;
                        SettingsData.setScreenPreferences(prefs);
                    }

                    StyledRect {
                        width: parent.width
                        height: screensInfoSection.implicitHeight + Theme.spacingL * 2
                        radius: Theme.cornerRadius
                        color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                        border.width: 1

                        Column {
                            id: screensInfoSection

                            anchors.fill: parent
                            anchors.margins: Theme.spacingL
                            spacing: Theme.spacingM

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                DarkIcon {
                                    name: "monitor"
                                    size: Theme.iconSize
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    width: parent.width - Theme.iconSize - Theme.spacingM
                                    spacing: Theme.spacingXS
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        text: "Connected Displays"
                                        font.pixelSize: Theme.fontSizeLarge
                                        font.weight: Font.Medium
                                        color: Theme.surfaceText
                                    }

                                    StyledText {
                                        text: "Configure which displays show shell components"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                    }

                                }

                            }

                            Column {
                                width: parent.width
                                spacing: Theme.spacingS

                                StyledText {
                                    text: "Available Screens (" + Quickshell.screens.length + ")"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }

                                Repeater {
                                    model: Quickshell.screens

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: screenRow.implicitHeight + Theme.spacingS * 2
                                        radius: Theme.cornerRadius
                                        color: Theme.surfaceContainerHigh
                                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                                        border.width: 1

                                        Row {
                                            id: screenRow

                                            anchors.fill: parent
                                            anchors.margins: Theme.spacingS
                                            spacing: Theme.spacingM

                                            DarkIcon {
                                                name: "desktop_windows"
                                                size: Theme.iconSize - 4
                                                color: Theme.primary
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Column {
                                                width: parent.width - Theme.iconSize - Theme.spacingM * 2
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: Theme.spacingXS / 2

                                                StyledText {
                                                    text: modelData.name
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    font.weight: Font.Medium
                                                    color: Theme.surfaceText
                                                }

                                                Row {
                                                    spacing: Theme.spacingS

                                                    StyledText {
                                                        text: modelData.width + "×" + modelData.height
                                                        font.pixelSize: Theme.fontSizeSmall
                                                        color: Theme.surfaceVariantText
                                                    }

                                                    StyledText {
                                                        text: "•"
                                                        font.pixelSize: Theme.fontSizeSmall
                                                        color: Theme.surfaceVariantText
                                                    }

                                                    StyledText {
                                                        text: modelData.model || "Unknown Model"
                                                        font.pixelSize: Theme.fontSizeSmall
                                                        color: Theme.surfaceVariantText
                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                            }

                        }

                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingL

                        Repeater {
                            model: displaysColumn.variantComponents

                            delegate: StyledRect {
                                width: parent.width
                                height: componentSection.implicitHeight + Theme.spacingL * 2
                                radius: Theme.cornerRadius
                                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                border.width: 1

                                Column {
                                    id: componentSection

                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingL
                                    spacing: Theme.spacingM

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingM

                                        DarkIcon {
                                            name: modelData.icon
                                            size: Theme.iconSize
                                            color: Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Column {
                                            width: parent.width - Theme.iconSize - Theme.spacingM
                                            spacing: Theme.spacingXS
                                            anchors.verticalCenter: parent.verticalCenter

                                            StyledText {
                                                text: modelData.name
                                                font.pixelSize: Theme.fontSizeLarge
                                                font.weight: Font.Medium
                                                color: Theme.surfaceText
                                            }

                                            StyledText {
                                                text: modelData.description
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.surfaceVariantText
                                                wrapMode: Text.WordWrap
                                                width: parent.width
                                            }

                                        }

                                    }

                                    Column {
                                        width: parent.width
                                        spacing: Theme.spacingS

                                        StyledText {
                                            text: "Show on screens:"
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceText
                                            font.weight: Font.Medium
                                        }

                                        Column {
                                            property string componentId: modelData.id
                                            property var selectedScreens: displaysColumn.getScreenPreferences(componentId)

                                            width: parent.width
                                            spacing: Theme.spacingXS

                                            DarkToggle {
                                                width: parent.width
                                                text: "All displays"
                                                description: "Show on all connected displays"
                                                checked: parent.selectedScreens.includes("all")
                                                onToggled: (checked) => {
                                                    if (checked) {
                                                        displaysColumn.setScreenPreferences(parent.componentId, ["all"]);
                                                    } else {
                                                        var allScreenNames = [];
                                                        for (var i = 0; i < Quickshell.screens.length; i++) {
                                                            allScreenNames.push(Quickshell.screens[i].name);
                                                        }
                                                        displaysColumn.setScreenPreferences(parent.componentId, allScreenNames);
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                width: parent.width
                                                height: 1
                                                color: Theme.outline
                                                opacity: 0.2
                                                visible: !parent.selectedScreens.includes("all")
                                            }

                                            Column {
                                                width: parent.width
                                                spacing: Theme.spacingXS
                                                visible: !parent.selectedScreens.includes("all")

                                                Repeater {
                                                    model: Quickshell.screens

                                                    delegate: DarkToggle {
                                                        property string screenName: modelData.name
                                                        property string componentId: parent.parent.componentId

                                                        width: parent.width
                                                        text: screenName
                                                        description: modelData.width + "×" + modelData.height + " • " + (modelData.model || "Unknown Model")
                                                        checked: {
                                                            var prefs = displaysColumn.getScreenPreferences(componentId);
                                                            return !prefs.includes("all") && prefs.includes(screenName);
                                                        }
                                                        onToggled: (checked) => {
                                                            var currentPrefs = displaysColumn.getScreenPreferences(componentId);
                                                            if (currentPrefs.includes("all"))
                                                                currentPrefs = [];

                                                            var newPrefs = currentPrefs.slice();
                                                            if (checked) {
                                                                if (!newPrefs.includes(screenName))
                                                                    newPrefs.push(screenName);

                                                            } else {
                                                                var index = newPrefs.indexOf(screenName);
                                                                if (index > -1)
                                                                    newPrefs.splice(index, 1);

                                                            }
                                                            displaysColumn.setScreenPreferences(componentId, newPrefs);
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                            }

                        }

                    }

                }
            }
        }
    }

    FileBrowserModal {
        id: fileBrowserModal
        browserTitle: "Select Custom Theme"
        filterExtensions: ["*.json"]
        showHiddenFiles: true

        function selectCustomTheme() {
            shouldBeVisible = true
        }

        onFileSelected: function(filePath) {
            if (filePath.endsWith(".json")) {
                SettingsData.setCustomThemeFile(filePath)
                Theme.switchTheme("custom")
                close()
            }
        }
    }
}
