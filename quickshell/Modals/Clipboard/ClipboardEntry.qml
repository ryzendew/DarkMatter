import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modals.Clipboard

Rectangle {
    id: entry

    required property string entryData
    required property int entryIndex
    required property int itemIndex
    required property bool isSelected
    required property var modal
    required property var listView

    signal copyRequested
    signal deleteRequested

    readonly property string entryType: modal ? modal.getEntryType(entryData) : "text"
    readonly property string entryPreview: modal ? modal.getEntryPreview(entryData) : entryData

    radius: Theme.cornerRadius
    color: {
        if (isSelected) {
            return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.2)
        }
        return mouseArea.containsMouse ? Theme.primaryHover : Theme.primaryBackground
    }
    border.color: {
        if (isSelected) {
            return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5)
        }
        return Theme.outlineStrong
    }
    border.width: isSelected ? 1.5 : 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        anchors.rightMargin: Theme.spacingS
        spacing: Theme.spacingL

        Rectangle {
            width: 24
            height: 24
            radius: Theme.cornerRadius
            color: Theme.primarySelected
            Layout.alignment: Qt.AlignVCenter

            StyledText {
                anchors.centerIn: parent
                text: entryIndex.toString()
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Bold
                color: Theme.primary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacingM

            ClipboardThumbnail {
                width: entryType === "image" ? ClipboardConstants.thumbnailSize : Theme.iconSize
                height: entryType === "image" ? ClipboardConstants.thumbnailSize : Theme.iconSize
                Layout.alignment: Qt.AlignVCenter
                entryData: entry.entryData
                entryType: entry.entryType
                modal: entry.modal
                listView: entry.listView
                itemIndex: entry.itemIndex
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.spacingXS

                StyledText {
                    text: {
                        switch (entryType) {
                        case "image":
                            return "Image • " + entryPreview
                        case "long_text":
                            return "Long Text"
                        default:
                            return "Text"
                        }
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primary
                    font.weight: Font.Medium
                    width: parent.width
                    elide: Text.ElideRight
                }

                StyledText {
                    text: entryPreview
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    width: parent.width
                    wrapMode: Text.WordWrap
                    maximumLineCount: entryType === "long_text" ? 3 : 1
                    elide: Text.ElideRight
                }
            }
        }
    }

    DarkActionButton {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingM
        anchors.verticalCenter: parent.verticalCenter
        iconName: "close"
        iconSize: Theme.iconSize - 6
        iconColor: Theme.surfaceText
        onClicked: deleteRequested()
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.rightMargin: 40
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: copyRequested()
    }
}
