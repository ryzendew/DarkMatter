import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: root

    property string iconName: ""
    property int iconSize: Theme.iconSize - 4
    property color iconColor: Theme.surfaceText
    property color backgroundColor: "transparent"
    property bool circular: true
    property int buttonSize: 40
    property int buttonPadding: 10

    signal clicked

    width: buttonSize
    height: buttonSize
    radius: circular ? buttonSize / 2 : Theme.cornerRadius
    color: backgroundColor
    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
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

    DarkIcon {
        anchors.centerIn: parent
        name: root.iconName
        size: root.iconSize
        color: root.iconColor
    }

    StateLayer {
        stateColor: Theme.primary
        cornerRadius: root.radius
        onClicked: root.clicked()
    }
}
