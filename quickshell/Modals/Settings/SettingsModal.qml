import QtQuick
import QtQuick.Effects
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.Modals.FileBrowser
import qs.Modules.Settings
import qs.Services
import qs.Widgets

DarkModal {
    id: settingsModal

    property Component settingsContent
    property alias profileBrowser: profileBrowser
    
    showBackground: true

    signal closingModal()

    function show() {
        open();
        Qt.callLater(function() {
            if (settingsContent && settingsContent.forceInitialize) {
                settingsContent.forceInitialize()
            }
        })
    }

    function hide() {
        close();
    }

    function toggle() {
        if (shouldBeVisible) {
            hide();
        } else {
            show();
        }
    }

    objectName: "settingsModal"
    positioning: "center"
    width: {
        if (SettingsData.settingsWindowWidth > 0) {
            return SettingsData.settingsWindowWidth
        }
        const screenWidth = Screen.width
        let baseWidth
        if (screenWidth >= 3840) baseWidth = 2560
        else if (screenWidth >= 2560) baseWidth = 1920
        else if (screenWidth >= 1920) baseWidth = 1280
        else baseWidth = 800
        
        let scale = 1.0
        if (typeof Theme !== "undefined" && Theme.getWindowScaleFactor !== undefined) {
            scale = Theme.getWindowScaleFactor()
        }
        const scaledWidth = baseWidth * scale
        return Math.max(600, Math.min(scaledWidth, screenWidth - 40))
    }
    height: {
        if (SettingsData.settingsWindowHeight > 0) {
            return SettingsData.settingsWindowHeight
        }
        const screenHeight = Screen.height
        let baseHeight
        if (screenHeight >= 2160) baseHeight = 1710
        else if (screenHeight >= 1440) baseHeight = 1325
        else if (screenHeight >= 1080) baseHeight = 950
        else baseHeight = 760
        
        let scale = 1.0
        if (typeof Theme !== "undefined" && Theme.getWindowScaleFactor !== undefined) {
            scale = Theme.getWindowScaleFactor()
        }
        const scaledHeight = baseHeight * scale
        return Math.max(500, Math.min(scaledHeight, screenHeight - 20))
    }
    visible: false
    onBackgroundClicked: () => {
        return hide();
    }
    content: settingsContent

    IpcHandler {
        function open(): string {
            settingsModal.show();
            return "SETTINGS_OPEN_SUCCESS";
        }

        function close(): string {
            settingsModal.hide();
            return "SETTINGS_CLOSE_SUCCESS";
        }

        function toggle(): string {
            settingsModal.toggle();
            return "SETTINGS_TOGGLE_SUCCESS";
        }

        target: "settings"
    }


    IpcHandler {
        function browse(type: string) {
            if (type === "wallpaper") {
                wallpaperBrowser.allowStacking = false;
                wallpaperBrowser.open();
            } else if (type === "profile") {
                profileBrowser.allowStacking = false;
                profileBrowser.open();
            }
        }

        target: "file"
    }

    FileBrowserModal {
        id: profileBrowser

        allowStacking: true
        browserTitle: "Select Profile Image"
        browserIcon: "person"
        browserType: "profile"
        fileExtensions: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp"]
        onFileSelected: (path) => {
            PortalService.setProfileImage(path);
            close();
        }
        onDialogClosed: () => {
            if (settingsModal) {
                settingsModal.allowFocusOverride = false;
                settingsModal.shouldHaveFocus = Qt.binding(() => {
                    return settingsModal.shouldBeVisible;
                });
            }
            allowStacking = true;
        }
    }

    FileBrowserModal {
        id: wallpaperBrowser

        allowStacking: true
        browserTitle: "Select Wallpaper"
        browserIcon: "wallpaper"
        browserType: "wallpaper"
        fileExtensions: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp"]
        
        onOpened: {
        }
        
        onFileSelected: (path) => {
            SessionData.setWallpaper(path);
            close();
        }
        
        onDialogClosed: () => {
            allowStacking = true;
        }
    }

    settingsContent: Component {
        Item {
            anchors.fill: parent
            focus: false
            clip: false

            Column {
                anchors.fill: parent
                spacing: 0
                clip: false

                // Header bar with clean design
                Rectangle {
                    width: parent.width
                    height: 56
                    color: "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        DarkIcon {
                            name: "settings"
                            size: 20
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Settings"
                            font.pixelSize: 17
                            color: Theme.surfaceText
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    DarkActionButton {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        circular: false
                        iconName: "close"
                        iconSize: 18
                        iconColor: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                        onClicked: () => {
                            return settingsModal.hide();
                        }
                    }
                }

                // Main content area
                Row {
                    width: parent.width
                    height: parent.height - 56
                    spacing: 0
                    clip: false

                    SettingsSidebar {
                        id: sidebar

                        parentModal: settingsModal
                        onCurrentIndexChanged: {
                            if (contentLoader.item) {
                                contentLoader.item.currentIndex = currentIndex
                            }
                        }
                    }

                    // Divider between sidebar and content
                    Rectangle {
                        width: 1
                        height: parent.height
                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                    }

                    Loader {
                        id: contentLoader
                        width: parent.width - sidebar.width - 1
                        height: parent.height
                        source: "SettingsContent.qml"
                        onLoaded: {
                            item.parentModal = settingsModal
                            item.currentIndex = sidebar.currentIndex
                        }
                    }
                }
            }
        }
    }

}
