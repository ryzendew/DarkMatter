import QtQuick
import QtQuick.Controls
import qs.Common

ScrollBar {
    id: scrollbar

    property bool _scrollBarActive: false
    property alias hideTimer: hideScrollBarTimer
    property bool _isParentMoving: parent && ((parent.moving !== undefined && parent.moving) || (parent.flicking !== undefined && parent.flicking) || (parent.isMomentumActive !== undefined && parent.isMomentumActive))
    property bool _shouldShow: pressed || hovered || active || _isParentMoving || _scrollBarActive

    policy: (parent && parent.contentHeight !== undefined && parent.height !== undefined && parent.contentHeight > parent.height) ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
    minimumSize: 0.08
    implicitWidth: 8
    interactive: true
    hoverEnabled: true
    z: 1000
    opacity: (policy !== ScrollBar.AlwaysOff && _shouldShow) ? 1.0 : 0.0
    visible: policy !== ScrollBar.AlwaysOff

    Behavior on opacity {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutQuad
        }
    }

    contentItem: Rectangle {
        implicitWidth: 6
        radius: width / 2
        color: scrollbar.pressed ? Theme.primary : scrollbar._shouldShow ? Theme.outline : Theme.outlineMedium
        opacity: scrollbar.pressed ? 1.0 : scrollbar._shouldShow ? 1.0 : 0.6
    }

    background: Item {}

    Timer {
        id: hideScrollBarTimer
        interval: 1200
        onTriggered: scrollbar._scrollBarActive = false
    }
}
