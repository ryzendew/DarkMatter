import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modals

Item {
    id: networkTab

    property var parentModal: null

    property bool dnsMethodAuto: true

    property int ipv4MethodIndex: 0
    property int ipv6MethodIndex: 0

    property int proxyMethodIndex: 0

    property int macAddressIndex: 0

    ConnectionEditModal {
        id: connectionEditModal
    }

    VpnAddModal {
        id: vpnAddModal
    }

    function getVpnAddModal() {
        return vpnAddModal
    }

    function getConnectionEditModal() {
        return connectionEditModal
    }

    function deleteVpnConnection(uuid, name) {
        deleteVpnProcess.command = ["nmcli", "connection", "delete", "uuid", uuid]
        deleteVpnProcess.running = true
        deleteVpnProcess.connectionName = name
    }

    Process {
        id: deleteVpnProcess
        running: false
        command: []
        property string connectionName: ""

        onExited: exitCode => {
            if (exitCode === 0) {
                ToastService.showInfo("VPN connection '" + connectionName + "' deleted")
                if (VpnService) {
                    VpnService.refreshAll()
                }
            } else {
                ToastService.showError("Failed to delete VPN connection")
            }
        }
    }

    Component.onCompleted: {
        if (NetworkService) {
            NetworkService.refreshNetworkState()
            if (NetworkService.wifiEnabled) {
                NetworkService.scanWifiNetworks()
            }
        }
    }

    DarkFlickable {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingL
        clip: true
        contentHeight: mainColumn.implicitHeight
        contentWidth: width

        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.spacingXL

            StyledRect {
                width: parent.width
                height: wifiColumn.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: wifiColumn
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "wifi"
                            size: Theme.iconSize
                            color: Theme.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        StyledText {
                            text: "WiFi"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 48
                            height: 28
                            radius: 14
                            color: NetworkService.wifiEnabled ? Theme.primary : Theme.surfaceVariant
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                                x: NetworkService.wifiEnabled ? 20 : 4

                                Behavior on x {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    NetworkService.toggleWifiRadio()
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: currentWifiInfo.visible ? currentWifiInfo.implicitHeight + Theme.spacingM * 2 : 0
                        radius: Theme.cornerRadius * 0.5
                        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)
                        visible: NetworkService.wifiConnected && NetworkService.currentWifiSSID

                        Column {
                            id: currentWifiInfo
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingS

                            Row {
                                width: parent.width
                                spacing: Theme.spacingS

                                StyledText {
                                    text: "Connected to:"
                                    font.pixelSize: Theme.fontSizeSmall
                                    opacity: 0.7
                                }

                                StyledText {
                                    text: NetworkService.currentWifiSSID || ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.primary
                                }

                                StyledText {
                                    text: "Signal: " + NetworkService.wifiSignalStrength + "%"
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                            }

                            RowLayout {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    text: "IP: " + (NetworkService.wifiIP || "Not assigned")
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Rectangle {

                                    TextMetrics {
                                        id: wifiDisconnectTextMetrics
                                        font.pixelSize: Theme.fontSizeSmall
                                        text: "Disconnect"
                                    }

                                    implicitWidth: wifiDisconnectTextMetrics.width + Theme.spacingS * 2
                                    implicitHeight: Math.max(wifiDisconnectTextMetrics.height, 28) + Theme.spacingS * 2
                                    width: implicitWidth
                                    height: implicitHeight
                                    radius: Theme.cornerRadius * 0.5
                                    color: Theme.error
                                    Layout.alignment: Qt.AlignVCenter

                                    StyledText {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: Theme.spacingS
                                        anchors.rightMargin: Theme.spacingS
                                        text: "Disconnect"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.onPrimary
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            NetworkService.disconnectWifi()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: NetworkService.wifiEnabled

                        StyledText {
                            text: "Available Networks"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: Theme.cornerRadius * 0.5
                            color: Theme.primaryContainer
                            visible: NetworkService.isScanning

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingS

                                Item {
                                    width: 16
                                    height: 16
                                    anchors.verticalCenter: parent.verticalCenter

                                    RotationAnimation on rotation {
                                        running: NetworkService.isScanning
                                        loops: Animation.Infinite
                                        duration: 1000
                                        from: 0
                                        to: 360
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: Theme.onPrimary
                                        opacity: 0.3
                                    }
                                }

                                StyledText {
                                    text: "Scanning for networks..."
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.onPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS

                            Repeater {
                                model: NetworkService.wifiNetworks || []

                                Rectangle {
                                    width: parent.width
                                    height: 48
                                    radius: Theme.cornerRadius * 0.5
                                    color: networkMouseArea.containsMouse ? Theme.surfaceHover : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)
                                    border.width: modelData.ssid === NetworkService.currentWifiSSID ? 2 : 0
                                    border.color: Theme.primary

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingS
                                        spacing: Theme.spacingM

                                        DarkIcon {
                                            name: modelData.secured ? "lock" : "lock_open"
                                            size: 20
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Column {
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 2

                                            StyledText {
                                                text: modelData.ssid || "Unknown"
                                                font.pixelSize: Theme.fontSizeMedium
                                                font.weight: Font.Medium
                                            }

                                            Row {
                                                spacing: Theme.spacingXS

                                                Repeater {
                                                    model: 4
                                                    Rectangle {
                                                        width: 4
                                                        height: (index + 1) * 4
                                                        radius: 2
                                                        color: {
                                                            const strength = modelData.signal || 0
                                                            const threshold = (index + 1) * 25
                                                            return strength >= threshold ? Theme.primary : Theme.surfaceVariant
                                                        }
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }

                                                StyledText {
                                                    text: modelData.signal ? modelData.signal + "%" : ""
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    opacity: 0.7
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        Rectangle {
                                            property string buttonText: modelData.ssid === NetworkService.currentWifiSSID ? "Connected" : "Connect"

                                            TextMetrics {
                                                id: wifiConnectTextMetrics
                                                font.pixelSize: Theme.fontSizeSmall
                                                text: buttonText
                                            }

                                            implicitWidth: wifiConnectTextMetrics.width + Theme.spacingS * 2
                                            implicitHeight: Math.max(wifiConnectTextMetrics.height, 28) + Theme.spacingS * 2
                                            width: implicitWidth
                                            height: implicitHeight
                                            radius: Theme.cornerRadius * 0.5
                                            color: modelData.ssid === NetworkService.currentWifiSSID ? Theme.primaryContainer : Theme.primary
                                            Layout.alignment: Qt.AlignVCenter

                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: Theme.spacingS
                                                anchors.rightMargin: Theme.spacingS
                                                text: buttonText
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: modelData.ssid === NetworkService.currentWifiSSID ? Theme.onPrimary : Theme.onPrimary
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                id: networkMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.ssid !== NetworkService.currentWifiSSID) {
                                                        if (modelData.secured) {
                                                            NetworkService.connectToWifi(modelData.ssid, "")
                                                        } else {
                                                            NetworkService.connectToWifi(modelData.ssid, "")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            StyledText {
                                text: "No networks found"
                                font.pixelSize: Theme.fontSizeSmall

                                opacity: 0.5
                                visible: !NetworkService.isScanning && (!NetworkService.wifiNetworks || NetworkService.wifiNetworks.length === 0)
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: Theme.cornerRadius * 0.5
                            color: refreshMouseArea.containsMouse ? Theme.surfaceHover : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingS

                                DarkIcon {
                                    name: "refresh"
                                    size: 18
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Refresh"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: refreshMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    NetworkService.scanWifiNetworks()
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: NetworkService.wifiEnabled && NetworkService.savedWifiNetworks && NetworkService.savedWifiNetworks.length > 0

                        Item {
                            width: parent.width
                            height: Theme.spacingM
                        }

                        StyledText {
                            text: "Saved Networks"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium

                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS

                            Repeater {
                                model: NetworkService.savedWifiNetworks || []

                                Rectangle {
                                    width: parent.width
                                    height: 40
                                    radius: Theme.cornerRadius * 0.5
                                    color: savedNetworkMouseArea.containsMouse ? Theme.surfaceHover : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingS
                                        spacing: Theme.spacingM

                                        DarkIcon {
                                            name: "wifi"
                                            size: 18

                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: (typeof modelData === 'string' ? modelData : modelData.ssid) || "Unknown"
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {

                                            TextMetrics {
                                                id: savedWifiEditTextMetrics
                                                font.pixelSize: Theme.fontSizeSmall
                                                text: "Edit"
                                            }

                                            implicitWidth: savedWifiEditTextMetrics.width + Theme.spacingS * 2
                                            implicitHeight: Math.max(savedWifiEditTextMetrics.height, 24) + Theme.spacingS * 2
                                            width: implicitWidth
                                            height: implicitHeight
                                            radius: Theme.cornerRadius * 0.5
                                            color: Theme.primaryContainer
                                            anchors.verticalCenter: parent.verticalCenter

                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: Theme.spacingS
                                                anchors.rightMargin: Theme.spacingS
                                                text: "Edit"
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.surfaceText
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    const ssid = typeof modelData === 'string' ? modelData : modelData.ssid
                                                    const connName = NetworkService.ssidToConnectionName[ssid] || ssid
                                                    connectionEditModal.show(connName, "")
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: 60
                                            height: 24
                                            radius: Theme.cornerRadius * 0.5
                                            color: Theme.error
                                            anchors.verticalCenter: parent.verticalCenter

                                            StyledText {
                                                anchors.centerIn: parent
                                                text: "Forget"
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.onPrimary
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    const ssid = typeof modelData === 'string' ? modelData : modelData.ssid
                                                    NetworkService.forgetWifiNetwork(ssid)
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: savedNetworkMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const ssid = typeof modelData === 'string' ? modelData : modelData.ssid
                                            NetworkService.connectToWifi(ssid, "")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: ethernetColumn.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: ethernetColumn
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "cable"
                            size: Theme.iconSize
                            color: Theme.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        StyledText {
                            text: "Ethernet"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: ethernetInfo.visible ? ethernetInfo.implicitHeight + Theme.spacingM * 2 : 0
                        radius: Theme.cornerRadius * 0.5
                        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)
                        visible: NetworkService.ethernetConnected

                        Column {
                            id: ethernetInfo
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingS

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    text: "Interface:"
                                    font.pixelSize: Theme.fontSizeSmall
                                    opacity: 0.7
                                }

                                StyledText {
                                    text: NetworkService.ethernetInterface || "Unknown"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.primary
                                }

                                StyledText {
                                    text: "IP: " + (NetworkService.ethernetIP || "Not assigned")
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                            }

                            RowLayout {
                                width: parent.width
                                spacing: Theme.spacingM

                                Item {
                                    Layout.fillWidth: true
                                }

                                Rectangle {

                                    TextMetrics {
                                        id: ethernetEditTextMetrics
                                        font.pixelSize: Theme.fontSizeSmall
                                        text: "Edit"
                                    }

                                    implicitWidth: ethernetEditTextMetrics.width + Theme.spacingS * 2
                                    implicitHeight: Math.max(ethernetEditTextMetrics.height, 28) + Theme.spacingS * 2
                                    width: implicitWidth
                                    height: implicitHeight
                                    radius: Theme.cornerRadius * 0.5
                                    color: Theme.primaryContainer
                                    Layout.alignment: Qt.AlignVCenter

                                    StyledText {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: Theme.spacingS
                                        anchors.rightMargin: Theme.spacingS
                                        text: "Edit"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (NetworkService.ethernetConnectionUuid) {
                                                connectionEditModal.show("", NetworkService.ethernetConnectionUuid)
                                            } else {
                                                findEthernetConnection.running = true
                                            }
                                        }
                                    }
                                }

                                Rectangle {

                                    TextMetrics {
                                        id: ethernetDisconnectTextMetrics
                                        font.pixelSize: Theme.fontSizeSmall
                                        text: "Disconnect"
                                    }

                                    implicitWidth: ethernetDisconnectTextMetrics.width + Theme.spacingS * 2
                                    implicitHeight: Math.max(ethernetDisconnectTextMetrics.height, 28) + Theme.spacingS * 2
                                    width: implicitWidth
                                    height: implicitHeight
                                    radius: Theme.cornerRadius * 0.5
                                    color: Theme.error
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: Theme.spacingS
                                        anchors.rightMargin: Theme.spacingS
                                        text: "Disconnect"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.onPrimary
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            NetworkService.toggleNetworkConnection("ethernet")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    StyledText {
                        text: NetworkService.ethernetConnected ? "Ethernet connected" : "No ethernet connection"
                        font.pixelSize: Theme.fontSizeSmall

                        opacity: 0.7
                        visible: !NetworkService.ethernetConnected
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: vpnColumn.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: vpnColumn
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "vpn_key"
                            size: Theme.iconSize
                            color: Theme.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        StyledText {
                            text: "VPN"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 100
                            height: 32
                            radius: Theme.cornerRadius * 0.5
                            color: addVpnMouseArea.containsMouse ? Theme.primaryContainer : Theme.primary
                            Layout.alignment: Qt.AlignVCenter

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DarkIcon {
                                    name: "add"
                                    size: 16
                                    color: Theme.onPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Add VPN"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.onPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: addVpnMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const modal = getVpnAddModal()
                                    if (modal) {
                                        modal.show()
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: VpnService && VpnService.activeConnections && VpnService.activeConnections.length > 0

                        StyledText {
                            text: "Active Connections"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        Repeater {
                            model: VpnService ? VpnService.activeConnections : []

                            Rectangle {
                                width: parent.width
                                height: Math.max(48, connectionInfoColumn.implicitHeight + Theme.spacingS * 2)
                                radius: Theme.cornerRadius * 0.5
                                color: Qt.rgba(Theme.primaryContainer.r, Theme.primaryContainer.g, Theme.primaryContainer.b, 0.5)
                                border.width: 2
                                border.color: Theme.primary

                                Column {
                                    id: connectionInfoColumn
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    spacing: Theme.spacingS

                                    RowLayout {
                                        width: parent.width
                                        spacing: Theme.spacingM

                                        DarkIcon {
                                            name: "vpn_key"
                                            size: 20
                                            color: Theme.primary
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Column {
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.fillWidth: true
                                            spacing: 2

                                            StyledText {
                                                text: modelData.name || "Unknown"
                                                font.pixelSize: Theme.fontSizeMedium
                                                font.weight: Font.Medium
                                            }

                                            Row {
                                                spacing: Theme.spacingS
                                                width: parent.width

                                                StyledText {
                                                    text: "State: " + (modelData.state || "unknown")
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    opacity: 0.7
                                                }

                                                StyledText {
                                                    text: VpnService && modelData.uuid ? " • " + VpnService.getConnectionDuration(modelData.uuid) : ""
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    opacity: 0.7
                                                    visible: text !== ""
                                                }
                                            }

                                            Column {
                                                width: parent.width
                                                spacing: 2
                                                visible: {
                                                    if (!VpnService || !modelData.uuid) return false
                                                    const details = VpnService.getConnectionDetails(modelData.uuid)
                                                    return !!(details && details.ipv4 && details.ipv4 !== "")
                                                }

                                                StyledText {
                                                    text: "IP: " + (VpnService ? VpnService.getConnectionDetails(modelData.uuid).ipv4 : "")
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    opacity: 0.6
                                                }

                                                StyledText {
                                                    text: "DNS: " + (VpnService ? VpnService.getConnectionDetails(modelData.uuid).dns : "")
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    opacity: 0.6
                                                    visible: text !== "DNS: "
                                                }
                                            }
                                        }

                                        Rectangle {
                                            id: disconnectVpnButton
                                            property bool isHovered: disconnectVpnMouseArea.containsMouse

                                            TextMetrics {
                                                id: vpnDisconnectTextMetrics
                                                font.pixelSize: Theme.fontSizeSmall
                                                text: "Disconnect"
                                            }

                                            implicitWidth: vpnDisconnectTextMetrics.width + Theme.spacingS * 2
                                            implicitHeight: Math.max(vpnDisconnectTextMetrics.height, 28) + Theme.spacingS * 2
                                            width: implicitWidth
                                            height: implicitHeight
                                            radius: Theme.cornerRadius * 0.5
                                            color: isHovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.8) : Theme.error
                                            Layout.alignment: Qt.AlignVCenter

                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: Theme.spacingS
                                                anchors.rightMargin: Theme.spacingS
                                                text: "Disconnect"
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: {
                                                    const err = Theme.error
                                                    const brightness = 0.299 * err.r + 0.587 * err.g + 0.114 * err.b
                                                    return brightness > 0.5 ? "#000000" : "#FFFFFF"
                                                }
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                id: disconnectVpnMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (VpnService) {
                                                        VpnService.disconnect(modelData.uuid || modelData.name)
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
                        spacing: Theme.spacingS

                        StyledText {
                            text: "VPN Profiles"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS

                            Repeater {
                                model: VpnService ? VpnService.profiles : []

                                Rectangle {
                                    width: parent.width
                                    height: vpnProfileLayout.implicitHeight + 8
                                    radius: Theme.cornerRadius * 0.5
                                    color: vpnProfileMouseArea.containsMouse ? Theme.surfaceHover : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5)
                                    border.width: VpnService && VpnService.isActiveUuid(modelData.uuid) ? 2 : 0
                                    border.color: Theme.primary

                                    RowLayout {
                                        id: vpnProfileLayout
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.leftMargin: 4
                                        anchors.rightMargin: 4
                                        anchors.topMargin: 4
                                        spacing: Theme.spacingM

                                        DarkIcon {
                                            name: "vpn_key"
                                            size: 20
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Column {
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.fillWidth: true
                                            spacing: 2

                                            StyledText {
                                                text: modelData.name || "Unknown"
                                                font.pixelSize: Theme.fontSizeMedium
                                                font.weight: Font.Medium
                                            }

                                            Row {
                                                spacing: Theme.spacingXS

                                                StyledText {
                                                    text: modelData.type || "vpn"
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    opacity: 0.7
                                                }

                                                StyledText {
                                                    text: modelData.serviceType ? " • " + modelData.serviceType : ""
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    opacity: 0.7
                                                }
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {

                                            TextMetrics {
                                                id: vpnEditTextMetrics
                                                font.pixelSize: Theme.fontSizeSmall
                                                text: "Edit"
                                            }

                                            implicitWidth: vpnEditTextMetrics.width + Theme.spacingS * 2
                                            implicitHeight: Math.max(vpnEditTextMetrics.height, 28) + Theme.spacingS * 2
                                            width: implicitWidth
                                            height: implicitHeight
                                            radius: Theme.cornerRadius * 0.5
                                            color: vpnEditMouseArea.containsMouse ? Theme.primaryContainer : Theme.surfaceContainer
                                            Layout.alignment: Qt.AlignVCenter

                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: Theme.spacingS
                                                anchors.rightMargin: Theme.spacingS
                                                text: "Edit"
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.surfaceText
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                id: vpnEditMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    const modal = getConnectionEditModal()
                                                    if (modal) {
                                                        modal.show(modelData.name, modelData.uuid)
                                                    }
                                                }
                                            }
                                        }

                                        DarkActionButton {
                                            buttonSize: 28
                                            circular: true
                                            iconName: "delete"
                                            iconSize: 16
                                            iconColor: Theme.error
                                            Layout.alignment: Qt.AlignVCenter
                                            visible: !(VpnService && VpnService.isActiveUuid(modelData.uuid))
                                            onClicked: {
                                                deleteVpnConnection(modelData.uuid, modelData.name)
                                            }
                                        }

                                        Rectangle {
                                            id: vpnConnectButton
                                            property string buttonText: VpnService && VpnService.isActiveUuid(modelData.uuid) ? "Connected" : "Connect"

                                            TextMetrics {
                                                id: vpnConnectTextMetrics
                                                font.pixelSize: Theme.fontSizeSmall
                                                text: vpnConnectButton.buttonText
                                            }

                                            implicitWidth: vpnConnectTextMetrics.width + Theme.spacingS * 2
                                            implicitHeight: Math.max(vpnConnectTextMetrics.height, 28) + Theme.spacingS * 2
                                            width: implicitWidth
                                            height: implicitHeight
                                            radius: Theme.cornerRadius * 0.5
                                            color: VpnService && VpnService.isActiveUuid(modelData.uuid) ? Theme.primaryContainer : Theme.primary
                                            Layout.alignment: Qt.AlignVCenter

                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: Theme.spacingS
                                                anchors.rightMargin: Theme.spacingS
                                                text: vpnConnectButton.buttonText
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: VpnService && VpnService.isActiveUuid(modelData.uuid) ? Theme.onPrimary : Theme.onPrimary
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                id: vpnProfileMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (VpnService) {
                                                        if (VpnService.isActiveUuid(modelData.uuid)) {
                                                            VpnService.disconnect(modelData.uuid)
                                                        } else {
                                                            VpnService.connect(modelData.uuid)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            StyledText {
                                text: "No VPN profiles configured"
                                font.pixelSize: Theme.fontSizeSmall

                                opacity: 0.5
                                visible: !VpnService || !VpnService.profiles || VpnService.profiles.length === 0
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: dnsColumn.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: dnsColumn
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "dns"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "DNS Configuration"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium

                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        StyledText {
                            text: "DNS Method:"
                            font.pixelSize: Theme.fontSizeMedium

                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            id: dnsMethodButtonContainer
                            implicitWidth: dnsMethodButtonRow.implicitWidth + Theme.spacingXS * 2
                            implicitHeight: dnsMethodButtonRow.implicitHeight + Theme.spacingXS * 2
                            width: implicitWidth
                            height: implicitHeight
                            radius: Theme.cornerRadius * 0.5
                            color: Theme.surfaceContainer
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                id: dnsMethodButtonRow
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                Repeater {
                                    model: ["Automatic", "Manual"]

                                    Rectangle {
                                        property bool isSelected: (index === 0 && networkTab.dnsMethodAuto) || (index === 1 && !networkTab.dnsMethodAuto)


                                        TextMetrics {
                                            id: dnsButtonTextMetrics
                                            font.pixelSize: Theme.fontSizeSmall
                                            text: modelData
                                        }

                                        implicitWidth: dnsButtonTextMetrics.width + Theme.spacingS * 2
                                        implicitHeight: Math.max(dnsButtonTextMetrics.height, 32) + Theme.spacingS * 2
                                        width: implicitWidth
                                        height: implicitHeight
                                        radius: Theme.cornerRadius * 0.5
                                        color: isSelected ? Theme.primary : "transparent"

                                        StyledText {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: Theme.spacingS
                                            anchors.rightMargin: Theme.spacingS
                                            text: modelData
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: isSelected ? Theme.onPrimary : Theme.surfaceText
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                networkTab.dnsMethodAuto = (index === 0)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: !networkTab.dnsMethodAuto

                        StyledText {
                            text: "DNS Servers"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium

                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Primary:"
                                font.pixelSize: Theme.fontSizeSmall

                                width: 80
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: parent.width - 80 - Theme.spacingM
                                height: 32
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                TextField {
                                    id: primaryDnsInput
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    font.pixelSize: Theme.fontSizeSmall
                                    placeholderText: "8.8.8.8"
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Secondary:"
                                font.pixelSize: Theme.fontSizeSmall

                                width: 80
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: parent.width - 80 - Theme.spacingM
                                height: 32
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                TextField {
                                    id: secondaryDnsInput
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    font.pixelSize: Theme.fontSizeSmall
                                    placeholderText: "8.8.4.4"
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            StyledText {
                                text: "Presets:"
                                font.pixelSize: Theme.fontSizeSmall

                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Repeater {
                                model: [
                                    { name: "Cloudflare", primary: "1.1.1.1", secondary: "1.0.0.1" },
                                    { name: "Google", primary: "8.8.8.8", secondary: "8.8.4.4" },
                                    { name: "Quad9", primary: "9.9.9.9", secondary: "149.112.112.112" },
                                    { name: "OpenDNS", primary: "208.67.222.222", secondary: "208.67.220.220" }
                                ]

                                Rectangle {
                                    property bool isHovered: dnsPresetMouseArea.containsMouse


                                    TextMetrics {
                                        id: dnsPresetTextMetrics
                                        font.pixelSize: Theme.fontSizeSmall
                                        text: modelData.name
                                    }

                                    implicitWidth: dnsPresetTextMetrics.width + Theme.spacingS * 2
                                    implicitHeight: Math.max(dnsPresetTextMetrics.height, 28) + Theme.spacingS * 2
                                    width: implicitWidth
                                    height: implicitHeight
                                    radius: Theme.cornerRadius * 0.5
                                    color: isHovered ? Theme.primaryContainer : Theme.surfaceContainer
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: Theme.spacingS
                                        anchors.rightMargin: Theme.spacingS
                                        text: modelData.name
                                        font.pixelSize: Theme.fontSizeSmall
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    MouseArea {
                                        id: dnsPresetMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            primaryDnsInput.text = modelData.primary
                                            secondaryDnsInput.text = modelData.secondary
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {

                            TextMetrics {
                                id: applyDnsTextMetrics
                                font.pixelSize: Theme.fontSizeSmall
                                text: "Apply"
                            }

                            implicitWidth: applyDnsTextMetrics.width + Theme.spacingS * 2
                            implicitHeight: Math.max(applyDnsTextMetrics.height, 32) + Theme.spacingS * 2
                            width: implicitWidth
                            height: implicitHeight
                            radius: Theme.cornerRadius * 0.5
                            color: applyDnsMouseArea.containsMouse ? Theme.primaryContainer : Theme.primary
                            anchors.right: parent.right

                            StyledText {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.spacingS
                                anchors.rightMargin: Theme.spacingS
                                text: "Apply"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.onPrimary
                                horizontalAlignment: Text.AlignHCenter
                            }

                            MouseArea {
                                id: applyDnsMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (primaryDnsInput.text.trim()) {
                                        NetworkService.setDnsServers("", primaryDnsInput.text.trim(), secondaryDnsInput.text.trim())
                                    } else {
                                        const connectionName = NetworkService.networkStatus === "wifi" ? NetworkService.wifiConnectionUuid :
                                                               NetworkService.networkStatus === "ethernet" ? NetworkService.ethernetConnectionUuid : ""
                                        if (connectionName) {
                                            Quickshell.execDetached(["nmcli", "connection", "modify", connectionName, "ipv4.dns", "", "ipv4.dns-search", ""])
                                            ToastService.showInfo("DNS reset to automatic")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: ipConfigColumn.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: ipConfigColumn
                    anchors.fill: parent
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

                        StyledText {
                            text: "IP Configuration"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium

                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: "IPv4"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium

                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Method:"
                                font.pixelSize: Theme.fontSizeSmall

                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                id: ipv4ButtonContainer
                                implicitWidth: ipv4ButtonRow.implicitWidth + Theme.spacingXS * 2
                                implicitHeight: ipv4ButtonRow.implicitHeight + Theme.spacingXS * 2
                                width: implicitWidth
                                height: implicitHeight
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainer
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    id: ipv4ButtonRow
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    Repeater {
                                        model: ["Automatic", "Manual", "Link-Local"]

                                        Rectangle {
                                            property bool isSelected: networkTab.ipv4MethodIndex === index
                                            property bool isHovered: buttonMouseArea.containsMouse


                                            TextMetrics {
                                                id: buttonTextMetrics
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: isSelected ? Font.Medium : Font.Normal
                                                text: modelData
                                            }

                                            implicitWidth: buttonTextMetrics.width + Theme.spacingS * 2
                                            implicitHeight: Math.max(buttonTextMetrics.height, 32) + Theme.spacingS * 2
                                            width: implicitWidth
                                            height: implicitHeight
                                            radius: Theme.cornerRadius * 0.75
                                            color: isSelected ? Theme.primary : (isHovered ? Theme.primaryHoverLight : "transparent")

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Theme.shorterDuration
                                                    easing.type: Theme.standardEasing
                                                }
                                            }

                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: Theme.spacingS
                                                anchors.rightMargin: Theme.spacingS
                                                text: modelData
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: isSelected ? Font.Medium : Font.Normal
                                                color: isSelected ? Theme.onPrimary : Theme.surfaceText
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                id: buttonMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    networkTab.ipv4MethodIndex = index
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingS
                            visible: networkTab.ipv4MethodIndex === 1

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    text: "IP Address:"
                                    font.pixelSize: Theme.fontSizeSmall

                                    width: 100
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: parent.width - 100 - Theme.spacingM
                                    height: 32
                                    radius: Theme.cornerRadius * 0.5
                                    color: Theme.surfaceContainer
                                    border.width: 1
                                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                    anchors.verticalCenter: parent.verticalCenter

                                    TextField {
                                        id: ipv4AddressInput
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingS
                                        font.pixelSize: Theme.fontSizeSmall
                                        placeholderText: "192.168.1.100/24"
                                        background: Rectangle {
                                            color: "transparent"
                                        }
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    text: "Gateway:"
                                    font.pixelSize: Theme.fontSizeSmall

                                    width: 100
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: parent.width - 100 - Theme.spacingM
                                    height: 32
                                    radius: Theme.cornerRadius * 0.5
                                    color: Theme.surfaceContainer
                                    border.width: 1
                                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                    anchors.verticalCenter: parent.verticalCenter

                                    TextField {
                                        id: ipv4GatewayInput
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingS
                                        font.pixelSize: Theme.fontSizeSmall

                                        placeholderText: "192.168.1.1"
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                    }
                                }
                            }

                            Rectangle {

                                TextMetrics {
                                    id: applyIpv4TextMetrics
                                    font.pixelSize: Theme.fontSizeSmall
                                    text: "Apply"
                                }

                                implicitWidth: applyIpv4TextMetrics.width + Theme.spacingS * 2
                                implicitHeight: Math.max(applyIpv4TextMetrics.height, 32) + Theme.spacingS * 2
                                width: implicitWidth
                                height: implicitHeight
                                radius: Theme.cornerRadius * 0.5
                                color: applyIpv4MouseArea.containsMouse ? Theme.primaryContainer : Theme.primary
                                anchors.right: parent.right

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: Theme.spacingS
                                    anchors.rightMargin: Theme.spacingS
                                    text: "Apply"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.onPrimary
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    id: applyIpv4MouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const method = networkTab.ipv4MethodIndex === 0 ? "auto" :
                                                      networkTab.ipv4MethodIndex === 1 ? "manual" : "link-local"
                                        const address = networkTab.ipv4MethodIndex === 1 ? ipv4AddressInput.text.trim() : ""
                                        const gateway = networkTab.ipv4MethodIndex === 1 ? ipv4GatewayInput.text.trim() : ""
                                        NetworkService.setIpv4Config("", method, address, gateway)
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        Item {
                            width: parent.width
                            height: Theme.spacingM
                        }

                        StyledText {
                            text: "IPv6"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium

                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Method:"
                                font.pixelSize: Theme.fontSizeSmall

                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                id: ipv6ButtonContainer
                                implicitWidth: ipv6ButtonRow.implicitWidth + Theme.spacingXS * 2
                                implicitHeight: ipv6ButtonRow.implicitHeight + Theme.spacingXS * 2
                                width: implicitWidth
                                height: implicitHeight
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainer
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    id: ipv6ButtonRow
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    Repeater {
                                        model: ["Automatic", "Manual", "Ignore"]

                                        Rectangle {
                                            property bool isSelected: networkTab.ipv6MethodIndex === index
                                            property bool isHovered: buttonMouseArea.containsMouse


                                            TextMetrics {
                                                id: buttonTextMetrics
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: isSelected ? Font.Medium : Font.Normal
                                                text: modelData
                                            }

                                            implicitWidth: buttonTextMetrics.width + Theme.spacingS * 2
                                            implicitHeight: Math.max(buttonTextMetrics.height, 32) + Theme.spacingS * 2
                                            width: implicitWidth
                                            height: implicitHeight
                                            radius: Theme.cornerRadius * 0.75
                                            color: isSelected ? Theme.primary : (isHovered ? Theme.primaryHoverLight : "transparent")

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Theme.shorterDuration
                                                    easing.type: Theme.standardEasing
                                                }
                                            }

                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: Theme.spacingS
                                                anchors.rightMargin: Theme.spacingS
                                                text: modelData
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: isSelected ? Font.Medium : Font.Normal
                                                color: isSelected ? Theme.onPrimary : Theme.surfaceText
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                id: buttonMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    networkTab.ipv6MethodIndex = index
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingS
                            visible: networkTab.ipv6MethodIndex === 1

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    text: "IPv6 Address:"
                                    font.pixelSize: Theme.fontSizeSmall

                                    width: 100
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: parent.width - 100 - Theme.spacingM
                                    height: 32
                                    radius: Theme.cornerRadius * 0.5
                                    color: Theme.surfaceContainer
                                    border.width: 1
                                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                    anchors.verticalCenter: parent.verticalCenter

                                    TextField {
                                        id: ipv6AddressInput
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingS
                                        font.pixelSize: Theme.fontSizeSmall

                                        placeholderText: "2001:db8::1/64"
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    text: "Gateway:"
                                    font.pixelSize: Theme.fontSizeSmall

                                    width: 100
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: parent.width - 100 - Theme.spacingM
                                    height: 32
                                    radius: Theme.cornerRadius * 0.5
                                    color: Theme.surfaceContainer
                                    border.width: 1
                                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                    anchors.verticalCenter: parent.verticalCenter

                                    TextField {
                                        id: ipv6GatewayInput
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingS
                                        font.pixelSize: Theme.fontSizeSmall

                                        placeholderText: "2001:db8::1"
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                    }
                                }
                            }

                            Rectangle {

                                TextMetrics {
                                    id: applyIpv6TextMetrics
                                    font.pixelSize: Theme.fontSizeSmall
                                    text: "Apply"
                                }

                                implicitWidth: applyIpv6TextMetrics.width + Theme.spacingS * 2
                                implicitHeight: Math.max(applyIpv6TextMetrics.height, 32) + Theme.spacingS * 2
                                width: implicitWidth
                                height: implicitHeight
                                radius: Theme.cornerRadius * 0.5
                                color: applyIpv6MouseArea.containsMouse ? Theme.primaryContainer : Theme.primary
                                anchors.right: parent.right

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: Theme.spacingS
                                    anchors.rightMargin: Theme.spacingS
                                    text: "Apply"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.onPrimary
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    id: applyIpv6MouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const method = networkTab.ipv6MethodIndex === 0 ? "auto" :
                                                      networkTab.ipv6MethodIndex === 1 ? "manual" : "ignore"
                                        const address = networkTab.ipv6MethodIndex === 1 ? ipv6AddressInput.text.trim() : ""
                                        const gateway = networkTab.ipv6MethodIndex === 1 ? ipv6GatewayInput.text.trim() : ""
                                        NetworkService.setIpv6Config("", method, address, gateway)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: proxyColumn.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: proxyColumn
                    anchors.fill: parent
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

                        StyledText {
                            text: "Proxy Configuration"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium

                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        StyledText {
                            text: "Proxy Method:"
                            font.pixelSize: Theme.fontSizeMedium

                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            id: proxyMethodButtonContainer
                            implicitWidth: proxyMethodButtonRow.implicitWidth + Theme.spacingXS * 2
                            implicitHeight: proxyMethodButtonRow.implicitHeight + Theme.spacingXS * 2
                            width: implicitWidth
                            height: implicitHeight
                            radius: Theme.cornerRadius * 0.5
                            color: Theme.surfaceContainer
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                id: proxyMethodButtonRow
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                Repeater {
                                    model: ["None", "Manual", "Automatic"]

                                    Rectangle {
                                        property bool isSelected: networkTab.proxyMethodIndex === index


                                        TextMetrics {
                                            id: proxyButtonTextMetrics
                                            font.pixelSize: Theme.fontSizeSmall
                                            text: modelData
                                        }

                                        implicitWidth: proxyButtonTextMetrics.width + Theme.spacingS * 2
                                        implicitHeight: Math.max(proxyButtonTextMetrics.height, 32) + Theme.spacingS * 2
                                        width: implicitWidth
                                        height: implicitHeight
                                        radius: Theme.cornerRadius * 0.5
                                        color: isSelected ? Theme.primary : "transparent"

                                        StyledText {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: Theme.spacingS
                                            anchors.rightMargin: Theme.spacingS
                                            text: modelData
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: isSelected ? Theme.onPrimary : Theme.surfaceText
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                networkTab.proxyMethodIndex = index
                                            }
                                        }
                                    }
                                }
                            }
                        }

                            Item { Layout.fillWidth: true }
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingS
                            visible: networkTab.proxyMethodIndex === 1

                        StyledText {
                            text: "Proxy Servers"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium

                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "HTTP Proxy:"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 120
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: parent.width - 120 - Theme.spacingM
                                height: 32
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                TextField {
                                    id: httpProxyInput
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    font.pixelSize: Theme.fontSizeSmall
                                    placeholderText: "proxy.example.com:8080"
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "HTTPS Proxy:"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 120
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: parent.width - 120 - Theme.spacingM
                                height: 32
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                TextField {
                                    id: httpsProxyInput
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    font.pixelSize: Theme.fontSizeSmall
                                    placeholderText: "proxy.example.com:8080"
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "FTP Proxy:"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 120
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: parent.width - 120 - Theme.spacingM
                                height: 32
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                TextField {
                                    id: ftpProxyInput
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    font.pixelSize: Theme.fontSizeSmall
                                    placeholderText: "proxy.example.com:8080"
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "SOCKS Proxy:"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                width: 120
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: parent.width - 120 - Theme.spacingM
                                height: 32
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                TextField {
                                    id: socksProxyInput
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    font.pixelSize: Theme.fontSizeSmall
                                    placeholderText: "proxy.example.com:1080"
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "No Proxy For:"
                                font.pixelSize: Theme.fontSizeSmall

                                width: 120
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: parent.width - 120 - Theme.spacingM
                                height: 32
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                TextField {
                                    id: noProxyInput
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    font.pixelSize: Theme.fontSizeSmall

                                    placeholderText: "localhost,127.0.0.1,*.local"
                                background: Rectangle {
                                    color: "transparent"
                                }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: networkTab.proxyMethodIndex === 2

                        StyledText {
                            text: "Automatic Proxy Configuration"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium

                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "PAC URL:"
                                font.pixelSize: Theme.fontSizeSmall

                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: parent.width - 100 - Theme.spacingM
                                height: 32
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                TextField {
                                    id: pacUrlInput
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    font.pixelSize: Theme.fontSizeSmall

                                    placeholderText: "http://proxy.example.com/proxy.pac"
                                background: Rectangle {
                                    color: "transparent"
                                }
                                }
                            }
                        }

                        Rectangle {

                            TextMetrics {
                                id: applyProxyTextMetrics
                                font.pixelSize: Theme.fontSizeSmall
                                text: "Apply"
                            }

                            implicitWidth: applyProxyTextMetrics.width + Theme.spacingS * 2
                            implicitHeight: Math.max(applyProxyTextMetrics.height, 32) + Theme.spacingS * 2
                            width: implicitWidth
                            height: implicitHeight
                            radius: Theme.cornerRadius * 0.5
                            color: applyProxyMouseArea.containsMouse ? Theme.primaryContainer : Theme.primary
                            anchors.right: parent.right

                            StyledText {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.spacingS
                                anchors.rightMargin: Theme.spacingS
                                text: "Apply"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.onPrimary
                                horizontalAlignment: Text.AlignHCenter
                            }

                            MouseArea {
                                id: applyProxyMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const method = networkTab.proxyMethodIndex === 0 ? "none" :
                                                  networkTab.proxyMethodIndex === 1 ? "manual" : "auto"

                                    if (method === "manual") {
                                        NetworkService.setProxyConfig("", method,
                                            httpProxyInput.text.trim(),
                                            httpsProxyInput.text.trim(),
                                            ftpProxyInput.text.trim(),
                                            socksProxyInput.text.trim(),
                                            noProxyInput.text.trim())
                                    } else {
                                        NetworkService.setProxyConfig("", method, "", "", "", "", "")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: advancedColumn.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: advancedColumn
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
                            text: "Advanced Settings"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium

                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "MTU:"
                                font.pixelSize: Theme.fontSizeSmall

                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 200
                                height: 65
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                TextField {
                                    id: mtuInput
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    font.pixelSize: Theme.fontSizeSmall

                                    placeholderText: "1500"
                                    validator: IntValidator { bottom: 576; top: 9000 }
                                }
                            }

                            StyledText {
                                text: "(576-9000, default: 1500)"
                                font.pixelSize: Theme.fontSizeSmall

                                opacity: 0.7
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Rectangle {

                            TextMetrics {
                                id: applyMtuTextMetrics
                                font.pixelSize: Theme.fontSizeSmall
                                text: "Apply"
                            }

                            implicitWidth: applyMtuTextMetrics.width + Theme.spacingS * 2
                            implicitHeight: Math.max(applyMtuTextMetrics.height, 32) + Theme.spacingS * 2
                            width: implicitWidth
                            height: implicitHeight
                            radius: Theme.cornerRadius * 0.5
                            color: applyMtuMouseArea.containsMouse ? Theme.primaryContainer : Theme.primary
                            anchors.right: parent.right

                            StyledText {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.spacingS
                                anchors.rightMargin: Theme.spacingS
                                text: "Apply"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.onPrimary
                                horizontalAlignment: Text.AlignHCenter
                            }

                            MouseArea {
                                id: applyMtuMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (mtuInput.text.trim()) {
                                        const mtu = parseInt(mtuInput.text.trim())
                                        if (mtu >= 576 && mtu <= 9000) {
                                            NetworkService.setMtu("", mtu)
                                        } else {
                                            ToastService.showError("MTU must be between 576 and 9000")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        Item {
                            width: parent.width
                            height: Theme.spacingS
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            StyledText {
                                text: "MAC Address:"
                                font.pixelSize: Theme.fontSizeSmall

                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                id: macAddressButtonContainer
                                implicitWidth: macAddressButtonRow.implicitWidth + Theme.spacingXS * 2
                                implicitHeight: macAddressButtonRow.implicitHeight + Theme.spacingXS * 2
                                width: implicitWidth
                                height: implicitHeight
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    id: macAddressButtonRow
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    Repeater {
                                        model: ["Default", "Cloned"]

                                        Rectangle {
                                            property bool isSelected: networkTab.macAddressIndex === index


                                            TextMetrics {
                                                id: macButtonTextMetrics
                                                font.pixelSize: Theme.fontSizeSmall
                                                text: modelData
                                            }

                                            implicitWidth: macButtonTextMetrics.width + Theme.spacingS * 2
                                            implicitHeight: Math.max(macButtonTextMetrics.height, 32) + Theme.spacingS * 2
                                            width: implicitWidth
                                            height: implicitHeight
                                            radius: Theme.cornerRadius * 0.5
                                            color: isSelected ? Theme.primary : "transparent"

                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: Theme.spacingS
                                                anchors.rightMargin: Theme.spacingS
                                                text: modelData
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: isSelected ? Theme.onPrimary : Theme.surfaceText
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    networkTab.macAddressIndex = index
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM
                            visible: networkTab.macAddressIndex === 1

                            StyledText {
                                text: "Cloned MAC:"
                                font.pixelSize: Theme.fontSizeSmall

                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: parent.width - 100 - Theme.spacingM
                                height: 32
                                radius: Theme.cornerRadius * 0.5
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                anchors.verticalCenter: parent.verticalCenter

                                TextField {
                                    id: clonedMacInput
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    font.pixelSize: Theme.fontSizeSmall

                                    placeholderText: "aa:bb:cc:dd:ee:ff"
                                background: Rectangle {
                                    color: "transparent"
                                }
                                }
                            }
                        }

                        Rectangle {

                            TextMetrics {
                                id: applyMacTextMetrics
                                font.pixelSize: Theme.fontSizeSmall
                                text: "Apply"
                            }

                            implicitWidth: applyMacTextMetrics.width + Theme.spacingS * 2
                            implicitHeight: Math.max(applyMacTextMetrics.height, 32) + Theme.spacingS * 2
                            width: implicitWidth
                            height: implicitHeight
                            radius: Theme.cornerRadius * 0.5
                            color: applyMacMouseArea.containsMouse ? Theme.primaryContainer : Theme.primary
                            anchors.right: parent.right

                            StyledText {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.spacingS
                                anchors.rightMargin: Theme.spacingS
                                text: "Apply"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.onPrimary
                                horizontalAlignment: Text.AlignHCenter
                            }

                            MouseArea {
                                id: applyMacMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (networkTab.macAddressIndex === 0) {
                                        NetworkService.setClonedMac("", "")
                                    } else if (networkTab.macAddressIndex === 1 && clonedMacInput.text.trim()) {
                                        NetworkService.setClonedMac("", clonedMacInput.text.trim())
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: findEthernetConnection
        running: false
        command: ["bash", "-c",
            "ETH_CONN=$(nmcli -t -f NAME,UUID connection show | grep ':802-3-ethernet$' | cut -d: -f1 | head -1); " +
            "ETH_UUID=$(nmcli -t -f NAME,UUID connection show | grep ':802-3-ethernet$' | cut -d: -f2 | head -1); " +
            "if [ -n \"$ETH_CONN\" ]; then echo \"$ETH_CONN:$ETH_UUID\"; fi"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(':')
                if (parts.length >= 2) {
                    connectionEditModal.show(parts[0], parts[1])
                }
            }
        }
    }
}

