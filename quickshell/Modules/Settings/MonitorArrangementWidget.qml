import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

StyledRect {
    id: root
    
    property var monitors: []
    property var monitorCapabilities: ({})
    property string selectedMonitor: ""
    signal monitorSelected(string monitorName)
    signal positionChanged(string monitorName, string newPosition)
    
    height: arrangementColumn.implicitHeight
    radius: Theme.cornerRadius
    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.20)
    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
    border.width: 1
    
    function parsePosition(pos) {
        if (!pos || pos === "") return {x: 0, y: 0}
        var parts = pos.split("x")
        if (parts.length >= 2) {
            return {x: parseInt(parts[0]) || 0, y: parseInt(parts[1]) || 0}
        }
        return {x: 0, y: 0}
    }
    
    function calculateAutoPosition(index) {
        var x = 0
        for (var i = 0; i < index; i++) {
            if (i < monitors.length && !monitors[i].disabled) {
                var caps = monitorCapabilities[monitors[i].name] || {}
                var width = caps.width || 1920
                var scale = parseFloat(monitors[i].scale || "1.0")
                x += (width / scale)
            }
        }
        return {x: x, y: 0}
    }
    
    function getMonitorBounds() {
        var minX = 0, minY = 0, maxX = 0, maxY = 0
        for (var i = 0; i < monitors.length; i++) {
            var monitor = monitors[i]
            if (monitor.disabled) continue
            var pos
            if (monitor.position && monitor.position !== "") {
                pos = parsePosition(monitor.position)
            } else {
                pos = calculateAutoPosition(i)
            }
            var caps = monitorCapabilities[monitor.name] || {}
            var width = caps.width || 1920
            var height = caps.height || 1080
            var scale = parseFloat(monitor.scale || "1.0")
            
            var scaledWidth = width / scale
            var scaledHeight = height / scale
            
            if (pos.x < minX) minX = pos.x
            if (pos.y < minY) minY = pos.y
            if (pos.x + scaledWidth > maxX) maxX = pos.x + scaledWidth
            if (pos.y + scaledHeight > maxY) maxY = pos.y + scaledHeight
        }
        return {minX: minX, minY: minY, maxX: maxX, maxY: maxY, width: maxX - minX, height: maxY - minY}
    }
    
    function alignMonitorsToTop() {
        // Find the topmost Y position
        var topmostY = null
        for (var i = 0; i < monitors.length; i++) {
            var monitor = monitors[i]
            if (monitor.disabled) continue
            var pos
            if (monitor.position && monitor.position !== "") {
                pos = parsePosition(monitor.position)
            } else {
                pos = calculateAutoPosition(i)
            }
            if (topmostY === null || pos.y < topmostY) {
                topmostY = pos.y
            }
        }
        
        // If no valid monitors found, return
        if (topmostY === null) return
        
        // Align all monitors to the topmost Y position
        for (var j = 0; j < monitors.length; j++) {
            var monitorToAlign = monitors[j]
            if (monitorToAlign.disabled) continue
            
            var currentPos
            if (monitorToAlign.position && monitorToAlign.position !== "") {
                currentPos = parsePosition(monitorToAlign.position)
            } else {
                currentPos = calculateAutoPosition(j)
            }
            
            // Only update if Y position is different
            if (currentPos.y !== topmostY) {
                var newPosition = currentPos.x + "x" + topmostY
                positionChanged(monitorToAlign.name, newPosition)
            }
        }
    }
    
    Column {
        id: arrangementColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingM
        
        Item {
            width: parent.width
            height: Math.max(monitorArrangementText.implicitHeight, alignButton.height)
            
            StyledText {
                id: monitorArrangementText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Monitor Arrangement"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
            }
            
            StyledRect {
                id: alignButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 32
                width: alignButtonText.implicitWidth + Theme.spacingM * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                border.color: Theme.primary
                border.width: 1
                visible: monitors.length > 0
                
                StyledText {
                    id: alignButtonText
                    anchors.centerIn: parent
                    text: "Align Top"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primary
                }
                
                StateLayer {
                    stateColor: Theme.primary
                    cornerRadius: parent.radius
                    onClicked: {
                        root.alignMonitorsToTop()
                    }
                }
            }
        }
        
        Flickable {
            id: arrangementFlickable
            width: parent.width
            height: Math.max(300, Math.min(800, arrangementArea.bounds.height * arrangementArea.scaleFactor + 40))
            clip: true
            flickableDirection: Flickable.HorizontalAndVerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            
            ScrollBar.horizontal: DarkScrollbar {
                id: hbar
                orientation: Qt.Horizontal
            }
            
            ScrollBar.vertical: DarkScrollbar {
                id: vbar
                orientation: Qt.Vertical
            }
            
            property var bounds: getMonitorBounds()
            property real baseScaleFactor: {
                if (bounds.width === 0 || bounds.height === 0) return 0.1
                var widthScale = (width - 40) / Math.max(bounds.width, 1920)
                var heightScale = (height - 40) / Math.max(bounds.height, 1080)
                return Math.min(widthScale, heightScale, 0.2)
            }
            property real zoomLevel: 0.8  // Start 1.5x zoomed out (1/1.5 = 0.67)
            property real scaleFactor: baseScaleFactor * zoomLevel
            
            contentWidth: Math.max(width * 5, bounds.width * scaleFactor + 1000)
            contentHeight: Math.max(height * 5, bounds.height * scaleFactor + 1000)
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onWheel: wheel => {
                    var delta = wheel.angleDelta.y
                    var oldZoom = arrangementFlickable.zoomLevel
                    var zoomFactor = delta > 0 ? 1.1 : 0.9
                    arrangementFlickable.zoomLevel = Math.max(0.1, Math.min(3.0, arrangementFlickable.zoomLevel * zoomFactor))
                    
                    if (oldZoom !== arrangementFlickable.zoomLevel) {
                        var zoomRatio = arrangementFlickable.zoomLevel / oldZoom
                        var centerX = wheel.x
                        var centerY = wheel.y
                        
                        var oldContentX = arrangementFlickable.contentX
                        var oldContentY = arrangementFlickable.contentY
                        
                        var newContentX = oldContentX + (centerX - oldContentX) * (1 - zoomRatio)
                        var newContentY = oldContentY + (centerY - oldContentY) * (1 - zoomRatio)
                        
                        arrangementFlickable.contentX = Math.max(0, Math.min(arrangementFlickable.contentWidth - arrangementFlickable.width, newContentX))
                        arrangementFlickable.contentY = Math.max(0, Math.min(arrangementFlickable.contentHeight - arrangementFlickable.height, newContentY))
                    }
                    wheel.accepted = true
                }
            }
            
            Item {
                id: arrangementArea
                width: Math.max(arrangementFlickable.contentWidth, parent.width * 5)
                height: Math.max(arrangementFlickable.contentHeight, parent.height * 5)
                
                property var bounds: arrangementFlickable.bounds
                property real scaleFactor: arrangementFlickable.scaleFactor
                
                Repeater {
                    model: root.monitors
                    
                    delegate: Item {
                        id: monitorDelegate
                        property var monitor: modelData
                        property var pos: {
                            if (monitor.position && monitor.position !== "") {
                                return parsePosition(monitor.position)
                            }
                            return calculateAutoPosition(index)
                        }
                        property var caps: root.monitorCapabilities[monitor.name] || {}
                        property real monitorWidth: caps.width || 1920
                        property real monitorHeight: caps.height || 1080
                        property real monitorScale: parseFloat(monitor.scale || "1.0")
                        property real scaledWidth: (monitorWidth / monitorScale) * arrangementArea.scaleFactor
                        property real scaledHeight: (monitorHeight / monitorScale) * arrangementArea.scaleFactor
                        property bool isSelected: root.selectedMonitor === monitor.name
                        
                        x: (pos.x - arrangementArea.bounds.minX) * arrangementArea.scaleFactor + 20
                        y: (pos.y - arrangementArea.bounds.minY) * arrangementArea.scaleFactor + 20
                        width: scaledWidth
                        height: scaledHeight
                        z: isSelected ? 10 : 1
                        
                        property point dragStart: Qt.point(0, 0)
                        property point startPos: Qt.point(0, 0)
                    
                    StyledRect {
                        anchors.fill: parent
                        radius: Theme.cornerRadius
                        color: isSelected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.4)
                        border.color: isSelected ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                        border.width: isSelected ? 2 : 1
                        
                        Item {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            
                            StyledText {
                                id: monitorNameText
                                anchors.centerIn: parent
                                text: monitor.name
                                font.pixelSize: Math.max(24, Math.min(48, Math.min(parent.width / 8, parent.height / 4)))
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: monitorNameText.bottom
                                anchors.topMargin: Theme.spacingXS
                                text: {
                                    var make = caps.make || ""
                                    var model = caps.model || ""
                                    if (make && model) {
                                        return make + " " + model
                                    } else if (make) {
                                        return make
                                    } else if (model) {
                                        return model
                                    } else {
                                        var desc = caps.description || ""
                                        if (desc) {
                                            var parts = desc.split(" ")
                                            if (parts.length > 0) {
                                                return parts[0]
                                            }
                                        }
                                        return ""
                                    }
                                }
                                font.pixelSize: Math.max(10, Math.min(16, Math.min(parent.width / 20, parent.height / 10)))
                                font.weight: Font.Medium
                                color: Theme.surfaceVariantText
                                horizontalAlignment: Text.AlignHCenter
                                visible: text !== ""
                            }
                        }
                    }
                    
                    function checkCollision(newX, newY) {
                        for (var i = 0; i < root.monitors.length; i++) {
                            var otherMonitor = root.monitors[i]
                            if (otherMonitor.name === monitor.name || otherMonitor.disabled) continue
                            
                            var otherCaps = root.monitorCapabilities[otherMonitor.name] || {}
                            var otherPos
                            if (otherMonitor.position && otherMonitor.position !== "") {
                                otherPos = root.parsePosition(otherMonitor.position)
                            } else {
                                otherPos = root.calculateAutoPosition(i)
                            }
                            var otherWidth = (otherCaps.width || 1920) / parseFloat(otherMonitor.scale || "1.0")
                            var otherHeight = (otherCaps.height || 1080) / parseFloat(otherMonitor.scale || "1.0")
                            
                            var otherScaledX = (otherPos.x - arrangementArea.bounds.minX) * arrangementArea.scaleFactor + 20
                            var otherScaledY = (otherPos.y - arrangementArea.bounds.minY) * arrangementArea.scaleFactor + 20
                            var otherScaledWidth = otherWidth * arrangementArea.scaleFactor
                            var otherScaledHeight = otherHeight * arrangementArea.scaleFactor
                            
                            var padding = 0.05
                            if (newX < otherScaledX + otherScaledWidth + padding &&
                                newX + scaledWidth + padding > otherScaledX &&
                                newY < otherScaledY + otherScaledHeight + padding &&
                                newY + scaledHeight + padding > otherScaledY) {
                                return true
                            }
                        }
                        return false
                    }
                    
                    function findSnapY(newY) {
                        var snapThreshold = 15 // pixels in scaled coordinates
                        var currentTop = newY
                        var currentBottom = newY + scaledHeight
                        var bestSnapY = newY
                        var bestDistance = snapThreshold + 1
                        
                        for (var i = 0; i < root.monitors.length; i++) {
                            var otherMonitor = root.monitors[i]
                            if (otherMonitor.name === monitor.name || otherMonitor.disabled) continue
                            
                            var otherCaps = root.monitorCapabilities[otherMonitor.name] || {}
                            var otherPos
                            if (otherMonitor.position && otherMonitor.position !== "") {
                                otherPos = root.parsePosition(otherMonitor.position)
                            } else {
                                otherPos = root.calculateAutoPosition(i)
                            }
                            var otherHeight = (otherCaps.height || 1080) / parseFloat(otherMonitor.scale || "1.0")
                            
                            var otherScaledY = (otherPos.y - arrangementArea.bounds.minY) * arrangementArea.scaleFactor + 20
                            var otherScaledHeight = otherHeight * arrangementArea.scaleFactor
                            var otherTop = otherScaledY
                            var otherBottom = otherScaledY + otherScaledHeight
                            
                            // Check top-to-top alignment
                            var topDiff = Math.abs(currentTop - otherTop)
                            if (topDiff < bestDistance) {
                                bestSnapY = otherTop
                                bestDistance = topDiff
                            }
                            
                            // Check top-to-bottom alignment
                            var topBottomDiff = Math.abs(currentTop - otherBottom)
                            if (topBottomDiff < bestDistance) {
                                bestSnapY = otherBottom
                                bestDistance = topBottomDiff
                            }
                            
                            // Check bottom-to-top alignment
                            var bottomTopDiff = Math.abs(currentBottom - otherTop)
                            if (bottomTopDiff < bestDistance) {
                                bestSnapY = otherTop - scaledHeight
                                bestDistance = bottomTopDiff
                            }
                            
                            // Check bottom-to-bottom alignment
                            var bottomDiff = Math.abs(currentBottom - otherBottom)
                            if (bottomDiff < bestDistance) {
                                bestSnapY = otherBottom - scaledHeight
                                bestDistance = bottomDiff
                            }
                        }
                        
                        // Only snap if within threshold
                        if (bestDistance < snapThreshold) {
                            return bestSnapY
                        }
                        return newY
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        drag.target: parent
                        drag.axis: Drag.XAndYAxis
                        drag.threshold: 0
                        drag.minimumX: -50000
                        drag.maximumX: 50000
                        drag.minimumY: -50000
                        drag.maximumY: 50000
                        
                        property real lastValidX: monitorDelegate.x
                        property real lastValidY: monitorDelegate.y
                        property bool isDragging: false
                        
                        onPressed: mouse => {
                            root.selectedMonitor = monitor.name
                            root.monitorSelected(monitor.name)
                            monitorDelegate.dragStart = Qt.point(mouse.x, mouse.y)
                            monitorDelegate.startPos = Qt.point(monitorDelegate.x, monitorDelegate.y)
                            lastValidX = monitorDelegate.x
                            lastValidY = monitorDelegate.y
                            isDragging = false
                        }
                        
                        onPositionChanged: mouse => {
                            if (drag.active) {
                                isDragging = true
                                var newX = monitorDelegate.x
                                var newY = monitorDelegate.y
                                
                                // Apply snap-to-align for top and bottom edges
                                var snappedY = findSnapY(newY)
                                newY = snappedY
                                
                                if (checkCollision(newX, newY)) {
                                    monitorDelegate.x = lastValidX
                                    monitorDelegate.y = lastValidY
                                    return
                                }
                                
                                monitorDelegate.y = newY
                                lastValidX = newX
                                lastValidY = newY
                            }
                        }
                        
                        onReleased: {
                            isDragging = false
                            
                            // Only send position change when drag is complete
                            var actualX = ((monitorDelegate.x - 20) / arrangementArea.scaleFactor) + arrangementArea.bounds.minX
                            var actualY = ((monitorDelegate.y - 20) / arrangementArea.scaleFactor) + arrangementArea.bounds.minY
                            
                            actualX = Math.round(actualX / 10) * 10
                            actualY = Math.round(actualY / 10) * 10
                            
                            var newPosition = actualX + "x" + actualY
                            if (newPosition !== monitor.position) {
                                root.positionChanged(monitor.name, newPosition)
                            }
                        }
                    }
                }
            }
        }
    }
    }
}

