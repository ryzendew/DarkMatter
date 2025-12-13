import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.Services
import qs.Widgets

DarkModal {
    id: root

    property string connectionName: ""
    property string connectionUuid: ""
    property string connectionType: ""
    property string editedConnectionName: ""
    
    property string currentIpv4Method: "auto"
    property string currentIpv4Address: ""
    property string currentIpv4Gateway: ""
    property string currentIpv6Method: "auto"
    property string currentIpv6Address: ""
    property string currentIpv6Gateway: ""
    property string currentDnsPrimary: ""
    property string currentDnsSecondary: ""
    property string currentMtu: ""
    property string currentMacAddress: ""
    
    property bool loading: true

    property bool modalOpen: false

    function show(connName, connUuid) {
        console.log("[ConnectionEditModal] show() called with name:", connName, "uuid:", connUuid)
        try {
            connectionName = connName || ""
            connectionUuid = connUuid || ""
            editedConnectionName = connName || ""
            console.log("[ConnectionEditModal] Set connectionName:", connectionName, "connectionUuid:", connectionUuid)
            loading = true
            console.log("[ConnectionEditModal] Setting modalOpen to true")
            modalOpen = true
            console.log("[ConnectionEditModal] modalOpen:", modalOpen, "shouldBeVisible:", shouldBeVisible)
            console.log("[ConnectionEditModal] Opening modal...")
            open()
            console.log("[ConnectionEditModal] After open(), modalOpen:", modalOpen, "shouldBeVisible:", shouldBeVisible, "visible:", visible)
            console.log("[ConnectionEditModal] Loading connection settings...")
            loadConnectionSettings()
        } catch (error) {
            console.error("[ConnectionEditModal] Error in show():", error, error.stack)
            loading = false
            modalOpen = false
        }
    }

    shouldBeVisible: modalOpen
    
    onShouldBeVisibleChanged: {
        console.log("[ConnectionEditModal] shouldBeVisible changed to:", shouldBeVisible, "modalOpen:", modalOpen, "visible:", visible)
        if (!shouldBeVisible && modalOpen) {
            console.log("[ConnectionEditModal] shouldBeVisible is false but modalOpen is true, setting modalOpen to false")
            modalOpen = false
        }
    }
    
    onModalOpenChanged: {
        console.log("[ConnectionEditModal] modalOpen changed to:", modalOpen, "shouldBeVisible:", shouldBeVisible)
    }
    
    onVisibleChanged: {
        console.log("[ConnectionEditModal] visible changed to:", visible, "shouldBeVisible:", shouldBeVisible, "modalOpen:", modalOpen)
    }
    
    onOpened: {
        console.log("[ConnectionEditModal] DarkModal opened signal received, ensuring modalOpen is true")
        modalOpen = true
    }
    
    onDialogClosed: {
        console.log("[ConnectionEditModal] DarkModal closed signal received, setting modalOpen to false")
        modalOpen = false
    }
    width: 800
    height: 900
    positioning: "center"
    enableShadow: true
    allowStacking: true
    
    onBackgroundClicked: () => {
        console.log("[ConnectionEditModal] Background clicked")
        modalOpen = false
        close()
    }
    
    function closeModal() {
        console.log("[ConnectionEditModal] closeModal() called")
        modalOpen = false
        close()
    }
    
    Component.onCompleted: {
        console.log("[ConnectionEditModal] Component created")
    }
    
    Component.onDestruction: {
        console.log("[ConnectionEditModal] Component destroyed")
    }

    content: Component {
        FocusScope {
            id: contentScope
            anchors.fill: parent
            focus: true
            
            Component.onCompleted: {
                console.log("[ConnectionEditModal] Content component created")
            }
            
            Component.onDestruction: {
                console.log("[ConnectionEditModal] Content component destroyed")
            }
            
            Keys.onEscapePressed: event => {
                console.log("[ConnectionEditModal] Escape key pressed")
                root.closeModal()
                event.accepted = true
            }

            Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DarkIcon {
                        name: "settings_ethernet"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS
                        width: parent.width - 200

                        StyledText {
                            text: "Edit Connection"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        Rectangle {
                            width: parent.width
                            radius: Theme.cornerRadius * 0.5
                            color: Theme.surfaceContainer
                            border.width: 1
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

                            Text {
                                id: connectionNameMeasure
                                width: parent.width - Theme.spacingS * 2 - 2
                                font.pixelSize: Theme.fontSizeMedium
                                text: editConnectionName.text || editConnectionName.placeholderText
                                wrapMode: Text.Wrap
                                visible: false
                            }

                            Connections {
                                target: editConnectionName
                                function onTextChanged() {
                                    root.editedConnectionName = editConnectionName.text
                                    Qt.callLater(() => {
                                        parent.height = Math.max(56, connectionNameMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                    })
                                }
                            }

                            Connections {
                                target: root
                                function onEditedConnectionNameChanged() {
                                    Qt.callLater(() => {
                                        parent.height = Math.max(56, connectionNameMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                    })
                                }
                                function onConnectionNameChanged() {
                                    Qt.callLater(() => {
                                        parent.height = Math.max(56, connectionNameMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                    })
                                }
                            }

                            height: Math.max(56, connectionNameMeasure.implicitHeight + Theme.spacingM * 2 + 8)

                            TextField {
                                id: editConnectionName
                                anchors.fill: parent
                                anchors.margins: Theme.spacingS
                                font.pixelSize: Theme.fontSizeMedium
                                text: root.editedConnectionName || root.connectionName || "Unknown Connection"
                                placeholderText: "Connection Name"
                                color: Theme.surfaceText
                                selectionColor: Theme.primary
                                selectedTextColor: Theme.onPrimary
                                wrapMode: TextField.Wrap
                                background: Rectangle {
                                    color: "transparent"
                                }
                                onTextChanged: {
                                    root.editedConnectionName = text
                                }
                            }
                        }
                    }

                    Item { width: parent.width - 200 }

                    DarkActionButton {
                        iconName: "close"
                        iconSize: Theme.iconSize - 4
                        iconColor: Theme.surfaceText
                        onClicked: () => {
                            root.closeModal()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                }

                DarkFlickable {
                    width: parent.width
                    height: Math.max(0, parent.height - 250)
                    contentHeight: settingsColumn.implicitHeight
                    contentWidth: width
                    clip: true

                    Column {
                        id: settingsColumn
                        width: parent.width
                        spacing: Theme.spacingXL

                        Rectangle {
                            width: parent.width
                            height: 200
                            color: "transparent"
                            visible: loading

                            Column {
                                anchors.centerIn: parent
                                spacing: Theme.spacingM

                                Item {
                                    width: 40
                                    height: 40
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    RotationAnimation on rotation {
                                        running: loading
                                        loops: Animation.Infinite
                                        duration: 1000
                                        from: 0
                                        to: 360
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 20
                                        color: Theme.primary
                                        opacity: 0.3
                                    }
                                }

                                StyledText {
                                    text: "Loading connection settings..."
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingL
                            visible: !loading

                            StyledRect {
                                width: parent.width
                                height: ipv4Column.implicitHeight + Theme.spacingL * 2
                                radius: Theme.cornerRadius
                                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                border.width: 1

                                Column {
                                    id: ipv4Column
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingXL
                                    spacing: Theme.spacingL

                                    StyledText {
                                        text: "IPv4 Configuration"
                                        font.pixelSize: Theme.fontSizeLarge
                                        font.weight: Font.Medium
                                        color: Theme.surfaceText
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingL

                                        StyledText {
                                            text: "Method:"
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: Theme.surfaceText
                                            width: 120
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            width: 240
                                            height: 40
                                            radius: Theme.cornerRadius * 0.5
                                            color: Theme.surfaceContainer
                                            anchors.verticalCenter: parent.verticalCenter

                                            Row {
                                                anchors.fill: parent
                                                anchors.margins: 2

                                                Repeater {
                                                    model: ["Automatic", "Manual", "Link-Local"]

                                                    Rectangle {
                                                        width: parent.width / 3
                                                        height: parent.height
                                                        radius: Theme.cornerRadius * 0.5
                                                        color: {
                                                            const methods = ["auto", "manual", "link-local"]
                                                            return methods[index] === root.currentIpv4Method ? Theme.primary : "transparent"
                                                        }

                                                        StyledText {
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            font.pixelSize: Theme.fontSizeSmall
                                                            color: {
                                                                const methods = ["auto", "manual", "link-local"]
                                                                return methods[index] === root.currentIpv4Method ? Theme.onPrimary : Theme.surfaceText
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                const methods = ["auto", "manual", "link-local"]
                                                                root.currentIpv4Method = methods[index]
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        width: parent.width
                                        spacing: Theme.spacingM
                                        visible: root.currentIpv4Method === "manual"

                                        Row {
                                            width: parent.width
                                            spacing: Theme.spacingM

                                            StyledText {
                                                text: "IP Address:"
                                                font.pixelSize: Theme.fontSizeMedium
                                                color: Theme.surfaceText
                                                width: 120
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Rectangle {
                                                width: parent.width - 120 - Theme.spacingL
                                                radius: Theme.cornerRadius * 0.5
                                                color: Theme.surfaceContainer
                                                border.width: 1
                                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

                                                Text {
                                                    id: ipv4AddressMeasure
                                                    width: parent.width - Theme.spacingS * 2 - 2
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    text: editIpv4Address.text || editIpv4Address.placeholderText
                                                    wrapMode: Text.Wrap
                                                    visible: false
                                                    Component.onCompleted: {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, ipv4AddressMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                Connections {
                                                    target: editIpv4Address
                                                    function onTextChanged() {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, ipv4AddressMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                Connections {
                                                    target: root
                                                    function onCurrentIpv4AddressChanged() {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, ipv4AddressMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                height: Math.max(56, ipv4AddressMeasure.implicitHeight + Theme.spacingM * 2 + 8)

                                                TextField {
                                                    id: editIpv4Address
                                                    anchors.fill: parent
                                                    anchors.margins: Theme.spacingS
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    text: root.currentIpv4Address
                                                    placeholderText: "192.168.1.100/24"
                                                    color: Theme.surfaceText
                                                    selectionColor: Theme.primary
                                                    selectedTextColor: Theme.onPrimary
                                                    wrapMode: TextField.Wrap
                                                    background: Rectangle {
                                                        color: "transparent"
                                                    }
                                                    onTextChanged: {
                                                        root.currentIpv4Address = text
                                                    }
                                                }
                                            }
                                        }

                                        Row {
                                            width: parent.width
                                            spacing: Theme.spacingM

                                            StyledText {
                                                text: "Gateway:"
                                                font.pixelSize: Theme.fontSizeMedium
                                                color: Theme.surfaceText
                                                width: 120
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Rectangle {
                                                width: parent.width - 120 - Theme.spacingL
                                                radius: Theme.cornerRadius * 0.5
                                                color: Theme.surfaceContainer
                                                border.width: 1
                                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

                                                Text {
                                                    id: ipv4GatewayMeasure
                                                    width: parent.width - Theme.spacingS * 2 - 2
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    text: editIpv4Gateway.text || editIpv4Gateway.placeholderText
                                                    wrapMode: Text.Wrap
                                                    visible: false
                                                }

                                                Connections {
                                                    target: editIpv4Gateway
                                                    function onTextChanged() {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, ipv4GatewayMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                Connections {
                                                    target: root
                                                    function onCurrentIpv4GatewayChanged() {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, ipv4GatewayMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                height: Math.max(56, ipv4GatewayMeasure.implicitHeight + Theme.spacingM * 2 + 8)

                                                TextField {
                                                    id: editIpv4Gateway
                                                    anchors.fill: parent
                                                    anchors.margins: Theme.spacingS
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    text: root.currentIpv4Gateway
                                                    placeholderText: "192.168.1.1"
                                                    color: Theme.surfaceText
                                                    selectionColor: Theme.primary
                                                    selectedTextColor: Theme.onPrimary
                                                    wrapMode: TextField.Wrap
                                                    background: Rectangle {
                                                        color: "transparent"
                                                    }
                                                    onTextChanged: {
                                                        root.currentIpv4Gateway = text
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            StyledRect {
                                width: parent.width
                                height: ipv6Column.implicitHeight + Theme.spacingL * 2
                                radius: Theme.cornerRadius
                                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                border.width: 1

                                Column {
                                    id: ipv6Column
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingXL
                                    spacing: Theme.spacingL

                                    StyledText {
                                        text: "IPv6 Configuration"
                                        font.pixelSize: Theme.fontSizeLarge
                                        font.weight: Font.Medium
                                        color: Theme.surfaceText
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingL

                                        StyledText {
                                            text: "Method:"
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: Theme.surfaceText
                                            width: 120
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            width: 240
                                            height: 40
                                            radius: Theme.cornerRadius * 0.5
                                            color: Theme.surfaceContainer
                                            anchors.verticalCenter: parent.verticalCenter

                                            Row {
                                                anchors.fill: parent
                                                anchors.margins: 2

                                                Repeater {
                                                    model: ["Automatic", "Manual", "Ignore"]

                                                    Rectangle {
                                                        width: parent.width / 3
                                                        height: parent.height
                                                        radius: Theme.cornerRadius * 0.5
                                                        color: {
                                                            const methods = ["auto", "manual", "ignore"]
                                                            return methods[index] === root.currentIpv6Method ? Theme.primary : "transparent"
                                                        }

                                                        StyledText {
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            font.pixelSize: Theme.fontSizeSmall
                                                            color: {
                                                                const methods = ["auto", "manual", "ignore"]
                                                                return methods[index] === root.currentIpv6Method ? Theme.onPrimary : Theme.surfaceText
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                const methods = ["auto", "manual", "ignore"]
                                                                root.currentIpv6Method = methods[index]
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        width: parent.width
                                        spacing: Theme.spacingM
                                        visible: root.currentIpv6Method === "manual"

                                        Row {
                                            width: parent.width
                                            spacing: Theme.spacingM

                                            StyledText {
                                                text: "IPv6 Address:"
                                                font.pixelSize: Theme.fontSizeMedium
                                                color: Theme.surfaceText
                                                width: 120
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Rectangle {
                                                width: parent.width - 120 - Theme.spacingL
                                                radius: Theme.cornerRadius * 0.5
                                                color: Theme.surfaceContainer
                                                border.width: 1
                                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

                                                Text {
                                                    id: ipv6AddressMeasure
                                                    width: parent.width - Theme.spacingS * 2 - 2
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    text: editIpv6Address.text || editIpv6Address.placeholderText
                                                    wrapMode: Text.Wrap
                                                    visible: false
                                                }

                                                Connections {
                                                    target: editIpv6Address
                                                    function onTextChanged() {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, ipv6AddressMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                Connections {
                                                    target: root
                                                    function onCurrentIpv6AddressChanged() {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, ipv6AddressMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                height: Math.max(56, ipv6AddressMeasure.implicitHeight + Theme.spacingM * 2 + 8)

                                                TextField {
                                                    id: editIpv6Address
                                                    anchors.fill: parent
                                                    anchors.margins: Theme.spacingS
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    text: root.currentIpv6Address
                                                    placeholderText: "2001:db8::1/64"
                                                    color: Theme.surfaceText
                                                    selectionColor: Theme.primary
                                                    selectedTextColor: Theme.onPrimary
                                                    wrapMode: TextField.Wrap
                                                    background: Rectangle {
                                                        color: "transparent"
                                                    }
                                                    onTextChanged: {
                                                        root.currentIpv6Address = text
                                                    }
                                                }
                                            }
                                        }

                                        Row {
                                            width: parent.width
                                            spacing: Theme.spacingM

                                            StyledText {
                                                text: "Gateway:"
                                                font.pixelSize: Theme.fontSizeMedium
                                                color: Theme.surfaceText
                                                width: 120
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Rectangle {
                                                width: parent.width - 120 - Theme.spacingL
                                                radius: Theme.cornerRadius * 0.5
                                                color: Theme.surfaceContainer
                                                border.width: 1
                                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

                                                Text {
                                                    id: ipv6GatewayMeasure
                                                    width: parent.width - Theme.spacingS * 2 - 2
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    text: editIpv6Gateway.text || editIpv6Gateway.placeholderText
                                                    wrapMode: Text.Wrap
                                                    visible: false
                                                }

                                                Connections {
                                                    target: editIpv6Gateway
                                                    function onTextChanged() {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, ipv6GatewayMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                Connections {
                                                    target: root
                                                    function onCurrentIpv6GatewayChanged() {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, ipv6GatewayMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                height: Math.max(56, ipv6GatewayMeasure.implicitHeight + Theme.spacingM * 2 + 8)

                                                TextField {
                                                    id: editIpv6Gateway
                                                    anchors.fill: parent
                                                    anchors.margins: Theme.spacingS
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    text: root.currentIpv6Gateway
                                                    placeholderText: "2001:db8::1"
                                                    color: Theme.surfaceText
                                                    selectionColor: Theme.primary
                                                    selectedTextColor: Theme.onPrimary
                                                    wrapMode: TextField.Wrap
                                                    background: Rectangle {
                                                        color: "transparent"
                                                    }
                                                    onTextChanged: {
                                                        root.currentIpv6Gateway = text
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            StyledRect {
                                width: parent.width
                                height: dnsEditColumn.implicitHeight + Theme.spacingL * 2
                                radius: Theme.cornerRadius
                                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                border.width: 1

                                Column {
                                    id: dnsEditColumn
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingXL
                                    spacing: Theme.spacingL

                                    StyledText {
                                        text: "DNS Configuration"
                                        font.pixelSize: Theme.fontSizeLarge
                                        font.weight: Font.Medium
                                        color: Theme.surfaceText
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingM

                                        StyledText {
                                            text: "Primary DNS:"
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: Theme.surfaceText
                                            width: 120
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            width: parent.width - 120 - Theme.spacingL
                                            radius: Theme.cornerRadius * 0.5
                                            color: Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

                                            Text {
                                                id: dnsPrimaryMeasure
                                                width: parent.width - Theme.spacingS * 2 - 2
                                                font.pixelSize: Theme.fontSizeMedium
                                                text: editDnsPrimary.text || editDnsPrimary.placeholderText
                                                wrapMode: Text.Wrap
                                                visible: false
                                            }

                                            Connections {
                                                target: editDnsPrimary
                                                function onTextChanged() {
                                                    Qt.callLater(() => {
                                                        parent.height = Math.max(56, dnsPrimaryMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                    })
                                                }
                                            }

                                            Connections {
                                                target: root
                                                function onCurrentDnsPrimaryChanged() {
                                                    Qt.callLater(() => {
                                                        parent.height = Math.max(56, dnsPrimaryMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                    })
                                                }
                                            }

                                            height: Math.max(56, dnsPrimaryMeasure.implicitHeight + Theme.spacingM * 2 + 8)

                                            TextField {
                                                id: editDnsPrimary
                                                anchors.fill: parent
                                                anchors.margins: Theme.spacingS
                                                font.pixelSize: Theme.fontSizeMedium
                                                text: root.currentDnsPrimary
                                                placeholderText: "8.8.8.8"
                                                color: Theme.surfaceText
                                                selectionColor: Theme.primary
                                                selectedTextColor: Theme.onPrimary
                                                wrapMode: TextField.Wrap
                                                background: Rectangle {
                                                    color: "transparent"
                                                }
                                                onTextChanged: {
                                                    root.currentDnsPrimary = text
                                                }
                                            }
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingM

                                        StyledText {
                                            text: "Secondary DNS:"
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: Theme.surfaceText
                                            width: 120
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                            Rectangle {
                                                width: parent.width - 120 - Theme.spacingL
                                                radius: Theme.cornerRadius * 0.5
                                                color: Theme.surfaceContainer
                                                border.width: 1
                                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

                                                Text {
                                                    id: dnsSecondaryMeasure
                                                    width: parent.width - Theme.spacingS * 2 - 2
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    text: editDnsSecondary.text || editDnsSecondary.placeholderText
                                                    wrapMode: Text.Wrap
                                                    visible: false
                                                }

                                                Connections {
                                                    target: editDnsSecondary
                                                    function onTextChanged() {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, dnsSecondaryMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                Connections {
                                                    target: root
                                                    function onCurrentDnsSecondaryChanged() {
                                                        Qt.callLater(() => {
                                                            parent.height = Math.max(56, dnsSecondaryMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                        })
                                                    }
                                                }

                                                height: Math.max(56, dnsSecondaryMeasure.implicitHeight + Theme.spacingM * 2 + 8)

                                                TextField {
                                                    id: editDnsSecondary
                                                    anchors.fill: parent
                                                    anchors.margins: Theme.spacingS
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    text: root.currentDnsSecondary
                                                    placeholderText: "8.8.4.4"
                                                    color: Theme.surfaceText
                                                    selectionColor: Theme.primary
                                                    selectedTextColor: Theme.onPrimary
                                                    wrapMode: TextField.Wrap
                                                    background: Rectangle {
                                                        color: "transparent"
                                                    }
                                                    onTextChanged: {
                                                        root.currentDnsSecondary = text
                                                    }
                                                }
                                            }
                                    }
                                }
                            }

                            StyledRect {
                                width: parent.width
                                height: advancedEditColumn.implicitHeight + Theme.spacingL * 2
                                radius: Theme.cornerRadius
                                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                border.width: 1

                                Column {
                                    id: advancedEditColumn
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingXL
                                    spacing: Theme.spacingL

                                    StyledText {
                                        text: "Advanced Settings"
                                        font.pixelSize: Theme.fontSizeLarge
                                        font.weight: Font.Medium
                                        color: Theme.surfaceText
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingM

                                        StyledText {
                                            text: "MTU:"
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: Theme.surfaceText
                                            width: 120
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            width: 120
                                            radius: Theme.cornerRadius * 0.5
                                            color: Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

                                            Text {
                                                id: mtuMeasure
                                                width: parent.width - Theme.spacingS * 2 - 2
                                                font.pixelSize: Theme.fontSizeMedium
                                                text: editMtu.text || editMtu.placeholderText
                                                wrapMode: Text.Wrap
                                                visible: false
                                            }

                                            Connections {
                                                target: editMtu
                                                function onTextChanged() {
                                                    Qt.callLater(() => {
                                                        parent.height = Math.max(56, mtuMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                    })
                                                }
                                            }

                                            Connections {
                                                target: root
                                                function onCurrentMtuChanged() {
                                                    Qt.callLater(() => {
                                                        parent.height = Math.max(56, mtuMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                    })
                                                }
                                            }

                                            height: Math.max(56, mtuMeasure.implicitHeight + Theme.spacingM * 2 + 8)

                                            TextField {
                                                id: editMtu
                                                anchors.fill: parent
                                                anchors.margins: Theme.spacingS
                                                font.pixelSize: Theme.fontSizeMedium
                                                text: root.currentMtu
                                                placeholderText: "1500"
                                                color: Theme.surfaceText
                                                selectionColor: Theme.primary
                                                selectedTextColor: Theme.onPrimary
                                                wrapMode: TextField.Wrap
                                                validator: IntValidator { bottom: 576; top: 9000 }
                                                background: Rectangle {
                                                    color: "transparent"
                                                }
                                                onTextChanged: {
                                                    root.currentMtu = text
                                                }
                                            }
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingM

                                        StyledText {
                                            text: "MAC Address:"
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: Theme.surfaceText
                                            width: 120
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            width: parent.width - 120 - Theme.spacingL
                                            radius: Theme.cornerRadius * 0.5
                                            color: Theme.surfaceContainer
                                            border.width: 1
                                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

                                            Text {
                                                id: macAddressMeasure
                                                width: parent.width - Theme.spacingS * 2 - 2
                                                font.pixelSize: Theme.fontSizeMedium
                                                text: editMacAddress.text || editMacAddress.placeholderText
                                                wrapMode: Text.Wrap
                                                visible: false
                                            }

                                            Connections {
                                                target: editMacAddress
                                                function onTextChanged() {
                                                    Qt.callLater(() => {
                                                        parent.height = Math.max(56, macAddressMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                    })
                                                }
                                            }

                                            Connections {
                                                target: root
                                                function onCurrentMacAddressChanged() {
                                                    Qt.callLater(() => {
                                                        parent.height = Math.max(56, macAddressMeasure.implicitHeight + Theme.spacingM * 2 + 8)
                                                    })
                                                }
                                            }

                                            height: Math.max(56, macAddressMeasure.implicitHeight + Theme.spacingM * 2 + 8)

                                            TextField {
                                                id: editMacAddress
                                                anchors.fill: parent
                                                anchors.margins: Theme.spacingS
                                                font.pixelSize: Theme.fontSizeMedium
                                                text: root.currentMacAddress
                                                placeholderText: "aa:bb:cc:dd:ee:ff"
                                                color: Theme.surfaceText
                                                selectionColor: Theme.primary
                                                selectedTextColor: Theme.onPrimary
                                                wrapMode: TextField.Wrap
                                                background: Rectangle {
                                                    color: "transparent"
                                                }
                                                onTextChanged: {
                                                    root.currentMacAddress = text
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                }

                Row {
                    width: parent.width
                    height: 50
                    spacing: Theme.spacingL

                    Item { width: parent.width - 275; height: parent.height }

                    Rectangle {
                        width: 110
                        height: 40
                        radius: Theme.cornerRadius * 0.5
                        color: cancelMouseArea.containsMouse ? Theme.surfaceVariant : Theme.surfaceContainer
                        border.width: 1
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

                        StyledText {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: cancelMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closeModal()
                            }
                        }
                    }

                    Rectangle {
                        width: 110
                        height: 40
                        radius: Theme.cornerRadius * 0.5
                        color: saveMouseArea.containsMouse ? Theme.primaryContainer : Theme.primary

                        StyledText {
                            anchors.centerIn: parent
                            text: "Save"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.onPrimary
                        }

                        MouseArea {
                            id: saveMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                saveConnectionSettings()
                            }
                        }
                    }
                }
            }
        }
    }

    function loadConnectionSettings() {
        console.log("[ConnectionEditModal] loadConnectionSettings() called")
        try {
            const connId = connectionUuid || connectionName
            console.log("[ConnectionEditModal] Connection ID:", connId, "uuid:", connectionUuid, "name:", connectionName)
            if (!connId) {
                console.warn("[ConnectionEditModal] No connection ID provided, skipping load")
                loading = false
                return
            }

            const cmd = connectionUuid ? ["nmcli", "connection", "show", "uuid", connId] : 
                                          ["nmcli", "connection", "show", "id", connId]
            console.log("[ConnectionEditModal] Command:", cmd)
            
            loadSettingsProcess.command = lowPriorityCmd.concat(cmd)
            console.log("[ConnectionEditModal] Full command:", loadSettingsProcess.command)
            loadSettingsProcess.running = true
            console.log("[ConnectionEditModal] Process started")
        } catch (error) {
            console.error("[ConnectionEditModal] Error in loadConnectionSettings():", error, error.stack)
            loading = false
        }
    }

    Process {
        id: loadSettingsProcess
        running: false
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[ConnectionEditModal] stdout received, length:", text.length)
                try {
                    const lines = text.trim().split('\n')
                    console.log("[ConnectionEditModal] Parsed", lines.length, "lines")
                    const settings = {}
                    
                    lines.forEach(line => {
                        const trimmedLine = line.trim()
                        if (!trimmedLine) return
                        
                        let key, value
                        const colonIndex = trimmedLine.indexOf(':')
                        const equalsIndex = trimmedLine.indexOf('=')
                        
                        if (colonIndex >= 0 && (equalsIndex < 0 || colonIndex < equalsIndex)) {
                            key = trimmedLine.substring(0, colonIndex).trim()
                            value = trimmedLine.substring(colonIndex + 1).trim()
                        } else if (equalsIndex >= 0) {
                            key = trimmedLine.substring(0, equalsIndex).trim()
                            value = trimmedLine.substring(equalsIndex + 1).trim()
                        } else {
                            return
                        }
                        
                        if (key && value && value !== "--" && value !== "~") {
                            settings[key] = value
                        } else if (key && (value === "--" || value === "~")) {
                            settings[key] = ""
                        }
                    })

                    console.log("[ConnectionEditModal] Parsed settings keys:", Object.keys(settings).length)
                    const sampleKeys = Object.keys(settings).slice(0, 5)
                    const sampleObj = {}
                    for (let i = 0; i < sampleKeys.length; i++) {
                        sampleObj[sampleKeys[i]] = settings[sampleKeys[i]]
                    }
                    console.log("[ConnectionEditModal] Sample settings:", JSON.stringify(sampleObj))

                    const ipv4Method = settings["ipv4.method"] || ""
                    root.currentIpv4Method = (ipv4Method === "manual" || settings["ipv4.addresses"] || settings["IP4.ADDRESS[1]"]) ? "manual" : "auto"
                    root.currentIpv4Address = settings["ipv4.addresses"] || settings["IP4.ADDRESS[1]"] || ""
                    root.currentIpv4Gateway = settings["ipv4.gateway"] || settings["IP4.GATEWAY"] || ""

                    const ipv6Method = settings["ipv6.method"] || ""
                    root.currentIpv6Method = (ipv6Method === "manual" || settings["ipv6.addresses"] || settings["IP6.ADDRESS[1]"]) ? "manual" : "auto"
                    root.currentIpv6Address = settings["ipv6.addresses"] || settings["IP6.ADDRESS[1]"] || ""
                    root.currentIpv6Gateway = settings["ipv6.gateway"] || settings["IP6.GATEWAY"] || ""

                    const dnsValue = settings["ipv4.dns"] || settings["IP4.DNS[1]"] || ""
                    const dnsServers = dnsValue.split(/\s+/).filter(s => s && s !== "--" && s !== "~")
                    root.currentDnsPrimary = dnsServers[0] || ""
                    root.currentDnsSecondary = dnsServers[1] || ""

                    root.currentMtu = settings["802-3-ethernet.mtu"] || settings["wireguard.mtu"] || settings["802-11-wireless.mtu"] || settings["GENERAL.MTU"] || ""
                    root.currentMacAddress = settings["802-3-ethernet.cloned-mac-address"] || settings["802-11-wireless.cloned-mac-address"] || ""

                    console.log("[ConnectionEditModal] Settings loaded successfully")
                    console.log("[ConnectionEditModal] IPv4:", root.currentIpv4Method, root.currentIpv4Address)
                    console.log("[ConnectionEditModal] IPv6:", root.currentIpv6Method, root.currentIpv6Address)
                    console.log("[ConnectionEditModal] Before setting loading=false, modalOpen:", root.modalOpen, "shouldBeVisible:", root.shouldBeVisible, "visible:", root.visible)
                    root.loading = false
                    console.log("[ConnectionEditModal] After setting loading=false, modalOpen:", root.modalOpen, "shouldBeVisible:", root.shouldBeVisible, "visible:", root.visible)
                } catch (error) {
                    console.error("[ConnectionEditModal] Error parsing settings:", error, error.stack)
                    root.loading = false
                }
            }
        }

        onExited: exitCode => {
            console.log("[ConnectionEditModal] loadSettingsProcess exited with code:", exitCode)
            if (exitCode !== 0) {
                console.error("[ConnectionEditModal] Failed to load connection settings, exit code:", exitCode)
                ToastService.showError("Failed to load connection settings")
                root.loading = false
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    console.error("[ConnectionEditModal] loadSettingsProcess stderr:", text)
                }
            }
        }
    }

    function saveConnectionSettings() {
        console.log("[ConnectionEditModal] saveConnectionSettings() called")
        try {
            const connId = connectionUuid || connectionName
            console.log("[ConnectionEditModal] Connection ID for save:", connId)
            if (!connId) {
                console.error("[ConnectionEditModal] No connection specified for save")
                ToastService.showError("No connection specified")
                return
            }

            // First, rename the connection if the name changed
            const newName = editedConnectionName && editedConnectionName.trim() ? editedConnectionName.trim() : null
            if (newName && newName !== connectionName) {
                console.log("[ConnectionEditModal] Renaming connection from", connectionName, "to", newName)
                renameConnectionProcess.command = lowPriorityCmd.concat(["nmcli", "connection", "modify", connId, "connection.id", newName])
                renameConnectionProcess.running = true
                // The rename will trigger the rest of the save via onExited
                return
            }

            // Continue with normal save
            const finalConnId = newName || connId
            let cmd = ["nmcli", "connection", "modify", finalConnId]
            console.log("[ConnectionEditModal] Building command, checking TextFields...")

            cmd.push("ipv4.method", root.currentIpv4Method)
            if (root.currentIpv4Method === "manual") {
                console.log("[ConnectionEditModal] Checking editIpv4Address:", typeof editIpv4Address)
                if (editIpv4Address && editIpv4Address.text && editIpv4Address.text.trim()) {
                    cmd.push("ipv4.addresses", editIpv4Address.text.trim())
                }
                console.log("[ConnectionEditModal] Checking editIpv4Gateway:", typeof editIpv4Gateway)
                if (editIpv4Gateway && editIpv4Gateway.text && editIpv4Gateway.text.trim()) {
                    cmd.push("ipv4.gateway", editIpv4Gateway.text.trim())
                }
            }

            cmd.push("ipv6.method", root.currentIpv6Method)
            if (root.currentIpv6Method === "manual") {
                console.log("[ConnectionEditModal] Checking editIpv6Address:", typeof editIpv6Address)
                if (editIpv6Address && editIpv6Address.text && editIpv6Address.text.trim()) {
                    cmd.push("ipv6.addresses", editIpv6Address.text.trim())
                }
                console.log("[ConnectionEditModal] Checking editIpv6Gateway:", typeof editIpv6Gateway)
                if (editIpv6Gateway && editIpv6Gateway.text && editIpv6Gateway.text.trim()) {
                    cmd.push("ipv6.gateway", editIpv6Gateway.text.trim())
                }
            }

            const dnsServers = []
            console.log("[ConnectionEditModal] Checking editDnsPrimary:", typeof editDnsPrimary)
            if (editDnsPrimary && editDnsPrimary.text && editDnsPrimary.text.trim()) {
                dnsServers.push(editDnsPrimary.text.trim())
            }
            console.log("[ConnectionEditModal] Checking editDnsSecondary:", typeof editDnsSecondary)
            if (editDnsSecondary && editDnsSecondary.text && editDnsSecondary.text.trim()) {
                dnsServers.push(editDnsSecondary.text.trim())
            }
            cmd.push("ipv4.dns", dnsServers.join(" ") || "")

            console.log("[ConnectionEditModal] Checking editMtu:", typeof editMtu)
            if (editMtu && editMtu.text && editMtu.text.trim()) {
                cmd.push("802-3-ethernet.mtu", editMtu.text.trim())
            }
            console.log("[ConnectionEditModal] Checking editMacAddress:", typeof editMacAddress)
            if (editMacAddress && editMacAddress.text && editMacAddress.text.trim()) {
                cmd.push("802-3-ethernet.cloned-mac-address", editMacAddress.text.trim())
            }

            console.log("[ConnectionEditModal] Final command:", cmd)
            saveSettingsProcess.command = lowPriorityCmd.concat(cmd)
            saveSettingsProcess.running = true
            console.log("[ConnectionEditModal] Save process started")
        } catch (error) {
            console.error("[ConnectionEditModal] Error in saveConnectionSettings():", error, error.stack)
            ToastService.showError("Error saving settings: " + error.toString())
        }
    }

    Process {
        id: renameConnectionProcess
        running: false
        command: []

        onExited: exitCode => {
            if (exitCode === 0) {
                console.log("[ConnectionEditModal] Connection renamed successfully")
                // Update connectionName to the new name
                connectionName = editedConnectionName.trim()
                // Now continue with the rest of the save
                const finalConnId = editedConnectionName.trim()
                let cmd = ["nmcli", "connection", "modify", finalConnId]
                console.log("[ConnectionEditModal] Building command after rename...")
                
                cmd.push("ipv4.method", root.currentIpv4Method)
                if (root.currentIpv4Method === "manual") {
                    if (root.currentIpv4Address && root.currentIpv4Address.trim()) {
                        cmd.push("ipv4.addresses", root.currentIpv4Address.trim())
                    }
                    if (root.currentIpv4Gateway && root.currentIpv4Gateway.trim()) {
                        cmd.push("ipv4.gateway", root.currentIpv4Gateway.trim())
                    }
                }

                cmd.push("ipv6.method", root.currentIpv6Method)
                if (root.currentIpv6Method === "manual") {
                    if (root.currentIpv6Address && root.currentIpv6Address.trim()) {
                        cmd.push("ipv6.addresses", root.currentIpv6Address.trim())
                    }
                    if (root.currentIpv6Gateway && root.currentIpv6Gateway.trim()) {
                        cmd.push("ipv6.gateway", root.currentIpv6Gateway.trim())
                    }
                }

                const dnsServers = []
                if (root.currentDnsPrimary && root.currentDnsPrimary.trim()) {
                    dnsServers.push(root.currentDnsPrimary.trim())
                }
                if (root.currentDnsSecondary && root.currentDnsSecondary.trim()) {
                    dnsServers.push(root.currentDnsSecondary.trim())
                }
                cmd.push("ipv4.dns", dnsServers.join(" ") || "")

                if (root.currentMtu && root.currentMtu.trim()) {
                    cmd.push("802-3-ethernet.mtu", root.currentMtu.trim())
                }
                if (root.currentMacAddress && root.currentMacAddress.trim()) {
                    cmd.push("802-3-ethernet.cloned-mac-address", root.currentMacAddress.trim())
                }

                console.log("[ConnectionEditModal] Final command after rename:", cmd)
                saveSettingsProcess.command = lowPriorityCmd.concat(cmd)
                saveSettingsProcess.running = true
            } else {
                console.error("[ConnectionEditModal] Failed to rename connection, exit code:", exitCode)
                ToastService.showError("Failed to rename connection")
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    console.error("[ConnectionEditModal] renameConnectionProcess stderr:", text)
                }
            }
        }
    }

    Process {
        id: saveSettingsProcess
        running: false
        command: []

        onExited: exitCode => {
            console.log("[ConnectionEditModal] saveSettingsProcess exited with code:", exitCode)
            if (exitCode === 0) {
                console.log("[ConnectionEditModal] Settings saved successfully")
                ToastService.showInfo("Connection settings saved")
                root.closeModal()
                if (NetworkService) {
                    NetworkService.refreshNetworkState()
                }
            } else {
                console.error("[ConnectionEditModal] Failed to save settings, exit code:", exitCode)
                ToastService.showError("Failed to save connection settings")
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    console.error("[ConnectionEditModal] saveSettingsProcess stderr:", text)
                }
            }
        }
    }

    readonly property var lowPriorityCmd: ["nice", "-n", "19", "ionice", "-c3"]
}

