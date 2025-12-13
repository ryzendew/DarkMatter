import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals
import qs.Modals.FileBrowser
import qs.Services
import qs.Widgets

Item {
    id: wallpaperTab

    property var parentModal: null
    property string selectedMonitorName: {
        var screens = Quickshell.screens
        return screens.length > 0 ? screens[0].name : ""
    }
    property var monitors: []
    property var monitorCapabilities: ({})
    property bool loading: false

    Component.onCompleted: {
        loadMonitors()
    }

    function loadMonitors() {
        loading = true
        monitors = []
        monitorCapabilities = {}

        var screens = Quickshell.screens
        for (var i = 0; i < screens.length; i++) {
            var screen = screens[i]
            monitors.push({
                name: screen.name,
                width: screen.width,
                height: screen.height,
                scale: "1.0",
                position: "",
                disabled: false
            })
            monitorCapabilities[screen.name] = {
                width: screen.width,
                height: screen.height,
                make: screen.manufacturer || "",
                model: screen.model || "",
                description: screen.name
            }
        }

        loading = false
    }

    DarkFlickable {
        anchors.fill: parent
        clip: true
        contentHeight: mainColumn.height
        contentWidth: width

        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.spacingL

            StyledRect {
                width: parent.width
                height: wallpaperHeaderSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                border.width: 1

                Column {
                    id: wallpaperHeaderSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "wallpaper"
                            size: Theme.iconSize
                            color: Theme.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXS
                            Layout.alignment: Qt.AlignVCenter

                            StyledText {
                                text: "Wallpaper"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: SessionData.perMonitorWallpaper ? "Set wallpapers for each monitor individually" : "Set wallpaper for all displays"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }

                    DarkToggle {
                        width: parent.width
                        text: "Per-Monitor Wallpapers"
                        description: "Enable different wallpapers for each connected monitor"
                        checked: SessionData.perMonitorWallpaper
                        onToggled: toggled => {
                            SessionData.setPerMonitorWallpaper(toggled)
                        }
                    }
                }
            }

            MonitorArrangementWidget {
                id: arrangementWidget
                width: parent.width
                monitors: wallpaperTab.monitors
                monitorCapabilities: wallpaperTab.monitorCapabilities
                selectedMonitor: SessionData.perMonitorWallpaper ? selectedMonitorName : ""
                visible: wallpaperTab.monitors.length > 0 && !wallpaperTab.loading
                onMonitorSelected: function(monitorName) {
                    selectedMonitorName = monitorName
                }
            }

            StyledText {
                text: "Loading monitors..."
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
                visible: wallpaperTab.loading
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            StyledRect {
                width: parent.width
                height: allDisplaysWallpaperSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                border.width: 1
                visible: !wallpaperTab.loading && wallpaperTab.monitors.length > 0 && !SessionData.perMonitorWallpaper

                Column {
                    id: allDisplaysWallpaperSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "desktop_windows"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingM
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: "All Displays"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: "Set the same wallpaper for all connected displays"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingL

                        StyledRect {
                            width: 200
                            height: 112
                            radius: Theme.cornerRadius
                            color: Theme.surfaceVariant
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                            border.width: 1

                            property string currentWallpaper: SessionData.wallpaperPath

                            CachingImage {
                                anchors.fill: parent
                                anchors.margins: 1
                                property var weExtensions: [".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tga"]
                                property int weExtIndex: 0
                                property string currentWallpaperPath: {
                                    var wp = parent.currentWallpaper
                                    if (wp && wp.startsWith("we:")) {
                                        var sceneId = wp.substring(3)
                                        return StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                            + "/.local/share/Steam/steamapps/workshop/content/431960/"
                                            + sceneId + "/preview" + weExtensions[weExtIndex]
                                    }
                                    return (wp !== "" && !wp.startsWith("#")) ? wp : ""
                                }
                                imagePath: currentWallpaperPath
                                onStatusChanged: {
                                    var wp = parent.currentWallpaper
                                    if (wp && wp.startsWith("we:") && status === Image.Error) {
                                        if (weExtIndex < weExtensions.length - 1) {
                                            weExtIndex++
                                            imagePath = ""
                                            Qt.callLater(() => {
                                                imagePath = StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                                    + "/.local/share/Steam/steamapps/workshop/content/431960/"
                                                    + wp.substring(3)
                                                    + "/preview" + weExtensions[weExtIndex]
                                            })
                                        } else {
                                            visible = false
                                        }
                                    }
                                }
                                fillMode: {
                                    switch (SessionData.wallpaperFillMode) {
                                    case "center": return Image.Pad
                                    case "crop": return Image.PreserveAspectCrop
                                    case "fit": return Image.PreserveAspectFit
                                    case "stretch": return Image.Stretch
                                    case "tile": return Image.Tile
                                    default: return Image.PreserveAspectCrop
                                    }
                                }
                                visible: {
                                    var wp = parent.currentWallpaper
                                    return wp !== "" && !wp.startsWith("#")
                                }
                                maxCacheSize: 200
                                layer.enabled: true

                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: allDisplaysWallpaperMask
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Theme.cornerRadius - 1
                                color: {
                                    var wp = parent.currentWallpaper
                                    return wp && wp.startsWith("#") ? wp : "transparent"
                                }
                                visible: {
                                    var wp = parent.currentWallpaper
                                    return wp !== "" && wp && wp.startsWith("#")
                                }
                            }

                            Rectangle {
                                id: allDisplaysWallpaperMask
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Theme.cornerRadius - 1
                                color: "black"
                                visible: false
                                layer.enabled: true
                            }

                            DarkIcon {
                                anchors.centerIn: parent
                                name: "image"
                                size: Theme.iconSizeLarge + 8
                                color: Theme.surfaceVariantText
                                visible: {
                                    var wp = parent.currentWallpaper
                                    return wp === ""
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Theme.cornerRadius - 1
                                color: Qt.rgba(0, 0, 0, 0.7)
                                visible: allDisplaysPreviewMouseArea.containsMouse

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingS

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: Theme.cornerRadius
                                        color: Qt.rgba(255, 255, 255, 0.9)

                                        DarkIcon {
                                            anchors.centerIn: parent
                                            name: "folder_open"
                                            size: 20
                                            color: "black"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (parentModal) {
                                                    parentModal.allowFocusOverride = true
                                                    parentModal.shouldHaveFocus = false
                                                }
                                                wallpaperBrowser.open()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: Theme.cornerRadius
                                        color: Qt.rgba(255, 255, 255, 0.9)

                                        DarkIcon {
                                            anchors.centerIn: parent
                                            name: "palette"
                                            size: 20
                                            color: "black"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                colorPicker.open()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: Theme.cornerRadius
                                        color: Qt.rgba(255, 255, 255, 0.9)
                                        visible: SessionData.wallpaperPath !== ""

                                        DarkIcon {
                                            anchors.centerIn: parent
                                            name: "clear"
                                            size: 20
                                            color: "black"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (Theme.currentTheme === Theme.dynamic)
                                                    Theme.switchTheme("blue")
                                                SessionData.clearWallpaper()
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: allDisplaysPreviewMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                propagateComposedEvents: true
                                acceptedButtons: Qt.NoButton
                            }
                        }

                        Column {
                            width: parent.width - 200 - Theme.spacingL
                            spacing: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: SessionData.wallpaperPath ? SessionData.wallpaperPath.split('/').pop() : "No wallpaper selected"
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.surfaceText
                                elide: Text.ElideMiddle
                                maximumLineCount: 1
                                width: parent.width
                            }

                            StyledText {
                                text: SessionData.wallpaperPath ? SessionData.wallpaperPath : ""
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                elide: Text.ElideMiddle
                                maximumLineCount: 1
                                width: parent.width
                                visible: SessionData.wallpaperPath !== ""
                            }

                            Row {
                                spacing: Theme.spacingS
                                visible: SessionData.wallpaperPath !== "" && !SessionData.wallpaperPath.startsWith("#") && !SessionData.wallpaperPath.startsWith("we")

                                DarkActionButton {
                                    buttonSize: 36
                                    iconName: "skip_previous"
                                    iconSize: Theme.iconSizeSmall
                                    backgroundColor: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.4)
                                    iconColor: Theme.surfaceText
                                    onClicked: {
                                        WallpaperCyclingService.cyclePrevManually()
                                    }
                                }

                                DarkActionButton {
                                    buttonSize: 36
                                    iconName: "skip_next"
                                    iconSize: Theme.iconSizeSmall
                                    backgroundColor: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.4)
                                    iconColor: Theme.surfaceText
                                    onClicked: {
                                        WallpaperCyclingService.cycleNextManually()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Repeater {
                model: SessionData.perMonitorWallpaper ? wallpaperTab.monitors : []
                visible: !wallpaperTab.loading && wallpaperTab.monitors.length > 0

                delegate: StyledRect {
                    width: parent.width
                    height: monitorWallpaperSection.implicitHeight + Theme.spacingL * 2
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                    border.width: 1

                    Column {
                        id: monitorWallpaperSection
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
                                    text: modelData.name
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: {
                                        var caps = wallpaperTab.monitorCapabilities[modelData.name] || {}
                                        return (caps.width || modelData.width) + "×" + (caps.height || modelData.height)
                                    }
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingL

                            StyledRect {
                                width: 200
                                height: 112
                                radius: Theme.cornerRadius
                                color: Theme.surfaceVariant
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                border.width: 1

                                property string currentWallpaper: SessionData.perMonitorWallpaper ? SessionData.getMonitorWallpaper(modelData.name) : SessionData.wallpaperPath

                                CachingImage {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    property var weExtensions: [".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tga"]
                                    property int weExtIndex: 0
                                    property string currentWallpaperPath: {
                                        var wp = parent.currentWallpaper
                                        if (wp && wp.startsWith("we:")) {
                                            var sceneId = wp.substring(3)
                                            return StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                                + "/.local/share/Steam/steamapps/workshop/content/431960/"
                                                + sceneId + "/preview" + weExtensions[weExtIndex]
                                        }
                                        return (wp !== "" && !wp.startsWith("#")) ? wp : ""
                                    }
                                    imagePath: currentWallpaperPath
                                    onStatusChanged: {
                                        var wp = parent.currentWallpaper
                                        if (wp && wp.startsWith("we:") && status === Image.Error) {
                                            if (weExtIndex < weExtensions.length - 1) {
                                                weExtIndex++
                                                imagePath = ""
                                                Qt.callLater(() => {
                                                    imagePath = StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                                        + "/.local/share/Steam/steamapps/workshop/content/431960/"
                                                        + wp.substring(3)
                                                        + "/preview" + weExtensions[weExtIndex]
                                                })
                                            } else {
                                                visible = false
                                            }
                                        }
                                    }
                                    fillMode: {
                                        switch (SessionData.wallpaperFillMode) {
                                        case "center": return Image.Pad
                                        case "crop": return Image.PreserveAspectCrop
                                        case "fit": return Image.PreserveAspectFit
                                        case "stretch": return Image.Stretch
                                        case "tile": return Image.Tile
                                        default: return Image.PreserveAspectCrop
                                        }
                                    }
                                    visible: {
                                        var wp = parent.currentWallpaper
                                        return wp !== "" && !wp.startsWith("#")
                                    }
                                    maxCacheSize: 200
                                    layer.enabled: true

                                    layer.effect: MultiEffect {
                                        maskEnabled: true
                                        maskSource: wallpaperMask
                                        maskThresholdMin: 0.5
                                        maskSpreadAtMin: 1
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: Theme.cornerRadius - 1
                                    color: {
                                        var wp = parent.currentWallpaper
                                        return wp && wp.startsWith("#") ? wp : "transparent"
                                    }
                                    visible: {
                                        var wp = parent.currentWallpaper
                                        return wp !== "" && wp && wp.startsWith("#")
                                    }
                                }

                                Rectangle {
                                    id: wallpaperMask
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: Theme.cornerRadius - 1
                                    color: "black"
                                    visible: false
                                    layer.enabled: true
                                }

                                DarkIcon {
                                    anchors.centerIn: parent
                                    name: "image"
                                    size: Theme.iconSizeLarge + 8
                                    color: Theme.surfaceVariantText
                                    visible: {
                                        var wp = parent.currentWallpaper
                                        return wp === ""
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: Theme.cornerRadius - 1
                                    color: Qt.rgba(0, 0, 0, 0.7)
                                    visible: wallpaperPreviewMouseArea.containsMouse

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingS

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            radius: Theme.cornerRadius
                                            color: Qt.rgba(255, 255, 255, 0.9)

                                            DarkIcon {
                                                anchors.centerIn: parent
                                                name: "folder_open"
                                                size: 20
                                                color: "black"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (parentModal) {
                                                        parentModal.allowFocusOverride = true
                                                        parentModal.shouldHaveFocus = false
                                                    }
                                                    wallpaperBrowser.open()
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            radius: Theme.cornerRadius
                                            color: Qt.rgba(255, 255, 255, 0.9)

                                            DarkIcon {
                                                anchors.centerIn: parent
                                                name: "palette"
                                                size: 20
                                                color: "black"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    colorPicker.open()
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            radius: Theme.cornerRadius
                                            color: Qt.rgba(255, 255, 255, 0.9)
                                            visible: {
                                                var wp = parent.parent.parent.parent.currentWallpaper
                                                return wp !== ""
                                            }

                                            DarkIcon {
                                                anchors.centerIn: parent
                                                name: "clear"
                                                size: 20
                                                color: "black"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (SessionData.perMonitorWallpaper) {
                                                        SessionData.setMonitorWallpaper(modelData.name, "")
                                                    } else {
                                                        if (Theme.currentTheme === Theme.dynamic)
                                                            Theme.switchTheme("blue")
                                                        SessionData.clearWallpaper()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: wallpaperPreviewMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    propagateComposedEvents: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }

                            Column {
                                width: parent.width - 200 - Theme.spacingL
                                spacing: Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    text: {
                                        var wp = SessionData.perMonitorWallpaper ? SessionData.getMonitorWallpaper(modelData.name) : SessionData.wallpaperPath
                                        return wp ? wp.split('/').pop() : "No wallpaper selected"
                                    }
                                    font.pixelSize: Theme.fontSizeLarge
                                    color: Theme.surfaceText
                                    elide: Text.ElideMiddle
                                    maximumLineCount: 1
                                    width: parent.width
                                }

                                StyledText {
                                    text: {
                                        var wp = SessionData.perMonitorWallpaper ? SessionData.getMonitorWallpaper(modelData.name) : SessionData.wallpaperPath
                                        return wp ? wp : ""
                                    }
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideMiddle
                                    maximumLineCount: 1
                                    width: parent.width
                                    visible: {
                                        var wp = SessionData.perMonitorWallpaper ? SessionData.getMonitorWallpaper(modelData.name) : SessionData.wallpaperPath
                                        return wp !== ""
                                    }
                                }

                                Row {
                                    spacing: Theme.spacingS
                                    visible: {
                                        var wp = SessionData.perMonitorWallpaper ? SessionData.getMonitorWallpaper(modelData.name) : SessionData.wallpaperPath
                                        return wp !== "" && !wp.startsWith("#") && !wp.startsWith("we")
                                    }

                                    DarkActionButton {
                                        buttonSize: 36
                                        iconName: "skip_previous"
                                        iconSize: Theme.iconSizeSmall
                                        backgroundColor: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.4)
                                        iconColor: Theme.surfaceText
                                        onClicked: {
                                            if (SessionData.perMonitorWallpaper) {
                                                WallpaperCyclingService.cyclePrevForMonitor(modelData.name)
                                            } else {
                                                WallpaperCyclingService.cyclePrevManually()
                                            }
                                        }
                                    }

                                    DarkActionButton {
                                        buttonSize: 36
                                        iconName: "skip_next"
                                        iconSize: Theme.iconSizeSmall
                                        backgroundColor: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.4)
                                        iconColor: Theme.surfaceText
                                        onClicked: {
                                            if (SessionData.perMonitorWallpaper) {
                                                WallpaperCyclingService.cycleNextForMonitor(modelData.name)
                                            } else {
                                                WallpaperCyclingService.cycleNextManually()
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
        id: wallpaperBrowser

        browserTitle: "Select Wallpaper"
        browserIcon: "wallpaper"
        browserType: "wallpaper"
        fileExtensions: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp"]
        onFileSelected: path => {
            if (SessionData.perMonitorWallpaper) {
                SessionData.setMonitorWallpaper(selectedMonitorName, path)
            } else {
                SessionData.setWallpaper(path)
            }
            close()
        }
        onDialogClosed: {
            if (parentModal) {
                parentModal.allowFocusOverride = false
                parentModal.shouldHaveFocus = Qt.binding(() => {
                    return parentModal.shouldBeVisible
                })
            }
        }
    }

    DarkColorPicker {
        id: colorPicker

        pickerTitle: "Choose Wallpaper Color"
        onColorSelected: selectedColor => {
            if (SessionData.perMonitorWallpaper) {
                SessionData.setMonitorWallpaper(selectedMonitorName, selectedColor)
            } else {
                SessionData.setWallpaperColor(selectedColor)
            }
        }
    }
}

