import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string title: ""
    property string iconName: ""
    property alias content: contentLoader.sourceComponent
    property bool expanded: false
    property bool collapsible: true
    property bool lazyLoad: true

    width: parent.width
    radius: Theme.cornerRadius
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
    border.width: 1
    clip: true

    Component.onCompleted: {
        if (!collapsible)
        expanded = true
    }

    Column {
        anchors.fill: parent
        spacing: 0

        MouseArea {
            width: parent.width
            height: headerRow.height + 16
            enabled: collapsible
            hoverEnabled: collapsible
            onClicked: {
                if (collapsible)
                expanded = !expanded
            }

            Rectangle {
                anchors.fill: parent
                color: parent.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.03) : "transparent"
                radius: root.radius
            }

            Row {
                id: headerRow

                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingM
                height: 20

                DarkIcon {
                    name: root.collapsible ? (root.expanded ? "expand_less" : "expand_more") : root.iconName
                    size: 16
                    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.collapsible

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                DarkIcon {
                    name: root.iconName
                    size: 16
                    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.iconName !== ""
                }

                StyledText {
                    text: root.title
                    font.pixelSize: 13
                    color: Theme.surfaceText
                    font.weight: Font.SemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
            visible: expanded || !collapsible
        }

        Column {
            width: parent.width
            spacing: 0
            clip: true

            Item {
                width: parent.width
                height: expanded || !collapsible ? contentColumn.height : 0
                clip: true

                Behavior on height {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    id: contentColumn
                    width: parent.width
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    spacing: 0

                    Loader {
                        id: contentLoader

                        width: parent.width
                        active: lazyLoad ? expanded || !collapsible : true
                        visible: expanded || !collapsible
                        asynchronous: true
                        opacity: visible ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
