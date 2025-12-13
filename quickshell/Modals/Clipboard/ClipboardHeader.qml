import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Modals.Clipboard

Item {
    id: header

    property int totalCount: 0
    property bool showKeyboardHints: false

    signal keyboardHintsToggled
    signal clearAllClicked
    signal closeClicked

    height: ClipboardConstants.headerHeight

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingM

        DarkIcon {
            name: "content_paste"
            size: Theme.iconSize - 4
            color: Theme.primary
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            text: "Clipboard History (" + totalCount + ")"
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.surfaceText
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: Theme.spacingS

            DarkActionButton {
                iconName: "info"
                iconSize: Theme.iconSize - 4
                iconColor: showKeyboardHints ? Theme.primary : Theme.surfaceText
                Layout.alignment: Qt.AlignVCenter
                onClicked: keyboardHintsToggled()
            }

            DarkActionButton {
                iconName: "delete_sweep"
                iconSize: Theme.iconSize - 4
                iconColor: Theme.surfaceText
                Layout.alignment: Qt.AlignVCenter
                onClicked: clearAllClicked()
            }

            DarkActionButton {
                iconName: "close"
                iconSize: Theme.iconSize - 4
                iconColor: Theme.surfaceText
                Layout.alignment: Qt.AlignVCenter
                onClicked: closeClicked()
            }
        }
    }
}
