import QtQuick
import qs.Common
import qs.Modals.Settings
import qs.Widgets

Item {
    id: sidebarContainer

    property int currentIndex: 0
    property var parentModal: null
    property real cornerRadius: parentModal ? parentModal.cornerRadius : Theme.cornerRadius
    readonly property var sidebarItems: [{
        "text": "Personalization",
        "icon": "person"
    }, {
        "text": "Theme & Colors",
        "icon": "palette"
    }, {
        "text": "Dock",
        "icon": "dock_to_bottom"
    }, {
        "text": "Top Bar",
        "icon": "toolbar"
    }, {
        "text": "Widgets",
        "icon": "widgets"
    }, {
        "text": "Desktop Widgets",
        "icon": "widgets"
    }, {
        "text": "Positioning",
        "icon": "open_with"
    }, {
        "text": "Launcher",
        "icon": "apps"
    }, {
        "text": "Default Apps",
        "icon": "apps"
    }, {
        "text": "Display Config",
        "icon": "settings"
    }, {
        "text": "Sound",
        "icon": "volume_up"
    }, {
        "text": "Network",
        "icon": "wifi"
    }, {
        "text": "Bluetooth",
        "icon": "bluetooth"
    }, {
        "text": "Keyboard & Language",
        "icon": "keyboard"
    }, {
        "text": "Time & Date",
        "icon": "schedule"
    }, {
        "text": "Power",
        "icon": "power_settings_new"
    }, {
        "text": "About",
        "icon": "info"
    }, {
        "text": "Weather",
        "icon": "cloud"
    }, {
        "text": "Keybinds",
        "icon": "keyboard"
    }]

    width: {
        const screenWidth = Screen.width
        let baseWidth
        if (screenWidth >= 3840) baseWidth = 300
        else if (screenWidth >= 2560) baseWidth = 280
        else if (screenWidth >= 1920) baseWidth = 260
        else if (screenWidth >= 1280) baseWidth = 240
        else baseWidth = Math.max(200, Math.min(240, screenWidth * 0.25))
        

        const uiScale = typeof Theme !== "undefined" && typeof Theme.getSettingsUiScale === "function" 
            ? Theme.getSettingsUiScale() 
            : (typeof SettingsData !== "undefined" && SettingsData.settingsUiScale !== undefined 
                ? SettingsData.settingsUiScale 
                : 1.0)
        
        return (baseWidth * uiScale) + 16
    }
    height: parent.height

    Rectangle {
        id: sidebarBackground
        anchors.top: parent.top
        anchors.topMargin: 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.left: parent.left
        anchors.leftMargin: 16
        width: {
            const screenWidth = Screen.width
            let baseWidth
            if (screenWidth >= 3840) baseWidth = 300
            else if (screenWidth >= 2560) baseWidth = 280
            else if (screenWidth >= 1920) baseWidth = 260
            else if (screenWidth >= 1280) baseWidth = 240
            else baseWidth = Math.max(200, Math.min(240, screenWidth * 0.25))
            

            const uiScale = typeof Theme !== "undefined" && typeof Theme.getSettingsUiScale === "function" 
                ? Theme.getSettingsUiScale() 
                : (typeof SettingsData !== "undefined" && SettingsData.settingsUiScale !== undefined 
                    ? SettingsData.settingsUiScale 
                    : 1.0)
            
            return baseWidth * uiScale
        }
        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.6)
        radius: cornerRadius
        clip: true
        layer.enabled: true
        layer.smooth: true

        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1

        DarkFlickable {
            id: sidebarFlickable
            anchors.fill: parent
            contentHeight: sidebarColumn.height
            contentWidth: width
            clip: true

        Column {
            id: sidebarColumn
            width: parent.width
            spacing: 0

            ProfileSection {
                id: profileSection
                parentModal: sidebarContainer.parentModal
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
            }

            Item {
                width: parent.width
                height: {
                    const baseHeight = 16
                    const uiScale = typeof SettingsData !== "undefined" && SettingsData.settingsUiScale !== undefined 
                        ? SettingsData.settingsUiScale 
                        : 1.0
                    const controlScale = typeof SettingsData !== "undefined" && SettingsData.settingsUiAdvancedScaling && SettingsData.settingsUiControlScale !== undefined
                        ? SettingsData.settingsUiControlScale
                        : 1.0
                    return baseHeight * uiScale * controlScale
                }
            }

            Repeater {
                id: sidebarRepeater

                model: sidebarContainer.sidebarItems

                Item {
                    id: navItem
                    property bool isActive: sidebarContainer.currentIndex === index

                    width: parent.width
                    height: {
                        const baseHeight = 40
                        const uiScale = typeof SettingsData !== "undefined" && SettingsData.settingsUiScale !== undefined 
                            ? SettingsData.settingsUiScale 
                            : 1.0
                        const controlScale = typeof SettingsData !== "undefined" && SettingsData.settingsUiAdvancedScaling && SettingsData.settingsUiControlScale !== undefined
                            ? SettingsData.settingsUiControlScale
                            : 1.0
                        return baseHeight * uiScale * controlScale
                    }


                    Rectangle {
                        id: activeIndicator
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        color: Theme.primary
                        visible: navItem.isActive
                        radius: 0
                    }


                    Rectangle {
                        id: backgroundLayer
                        anchors.fill: parent
                        radius: 0
                        color: {
                            if (navItem.isActive) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                            }
                            if (navMouseArea.containsMouse) {
                                return Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.06)
                            }
                            return "transparent"
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }
                        }
                    }


                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: {
                            const baseMargin = 20
                            const uiScale = typeof SettingsData !== "undefined" && SettingsData.settingsUiScale !== undefined 
                                ? SettingsData.settingsUiScale 
                                : 1.0
                            const controlScale = typeof SettingsData !== "undefined" && SettingsData.settingsUiAdvancedScaling && SettingsData.settingsUiControlScale !== undefined
                                ? SettingsData.settingsUiControlScale
                                : 1.0
                            return baseMargin * uiScale * controlScale
                        }
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: modelData.icon || ""
                            size: Theme.iconSize
                            color: {
                                if (navItem.isActive) {
                                    return Theme.primary
                                }
                                if (navMouseArea.containsMouse) {
                                    return Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.85)
                                }
                                return Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                            }
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: modelData.text || ""
                            font.pixelSize: Theme.fontSizeMedium
                            color: {
                                if (navItem.isActive) {
                                    return Theme.primary
                                }
                                if (navMouseArea.containsMouse) {
                                    return Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.95)
                                }
                                return Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.85)
                            }
                            font.weight: navItem.isActive ? Font.Medium : Font.Normal
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: {
                                const uiScale = typeof SettingsData !== "undefined" && SettingsData.settingsUiScale !== undefined 
                                    ? SettingsData.settingsUiScale 
                                    : 1.0
                                const controlScale = typeof SettingsData !== "undefined" && SettingsData.settingsUiAdvancedScaling && SettingsData.settingsUiControlScale !== undefined
                                    ? SettingsData.settingsUiControlScale
                                    : 1.0
                                const margin = 20 * uiScale * controlScale
                                const spacing = Theme.spacingM
                                const iconSize = Theme.iconSize
                                return Math.max(0, navItem.width - margin - spacing - iconSize - margin)
                            }
                        }
                    }

                    MouseArea {
                        id: navMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: () => {
                            sidebarContainer.currentIndex = index;
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: {
                    const baseHeight = 12
                    const uiScale = typeof SettingsData !== "undefined" && SettingsData.settingsUiScale !== undefined 
                        ? SettingsData.settingsUiScale 
                        : 1.0
                    const controlScale = typeof SettingsData !== "undefined" && SettingsData.settingsUiAdvancedScaling && SettingsData.settingsUiControlScale !== undefined
                        ? SettingsData.settingsUiControlScale
                        : 1.0
                    return baseHeight * uiScale * controlScale
                }
            }
        }
        }
    }
}
