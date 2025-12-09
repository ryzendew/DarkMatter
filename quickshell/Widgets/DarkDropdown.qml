import "../Common/fzf.js" as Fzf
import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

Rectangle {
    id: root
    
    readonly property bool notoSansAvailable: Qt.fontFamilies().some(f => f.includes("Noto Sans"))
    
    FontLoader {
        id: notoSansLoader
        source: root.notoSansAvailable ? "" : "/usr/share/fonts/google-noto/NotoSans-Regular.ttf"
    }
    
    readonly property string notoSansFamily: {
        if (root.notoSansAvailable) {
            const families = Qt.fontFamilies()
            for (let i = 0; i < families.length; i++) {
                if (families[i].includes("Noto Sans")) {
                    return families[i]
                }
            }
            return "Noto Sans"
        }
        return notoSansLoader.status === FontLoader.Ready ? notoSansLoader.name : ""
    }

    property string text: ""
    property string description: ""
    property string currentValue: ""
    property var options: []
    property var optionIcons: []
    property bool forceRecreate: false
    property bool enableFuzzySearch: false
    property int popupWidthOffset: 0
    property int maxPopupHeight: 400
    property int controlHeight: 48

    signal valueChanged(string value)

    width: parent.width
    height: Math.max(68, dropdown.height + Theme.spacingXL * 2)
    radius: Math.max(Theme.cornerRadius, 16)
    color: "transparent"
    
    // Padding constants for better spacing
    readonly property int horizontalPadding: Theme.spacingL
    readonly property int verticalPadding: Theme.spacingM
    readonly property int dropdownHorizontalPadding: Theme.spacingL + Theme.spacingS
    readonly property int dropdownVerticalPadding: Theme.spacingM
    Component.onCompleted: forceRecreateTimer.start()
    Component.onDestruction: {
        const popup = popupLoader.item
        if (popup && popup.visible) {
            popup.close()
        }
    }
    onVisibleChanged: {
        const popup = popupLoader.item
        if (!visible && popup && popup.visible) {
            popup.close()
        } else if (visible) {
            forceRecreateTimer.start()
        }
    }

    Timer {
        id: forceRecreateTimer

        interval: 50
        repeat: false
        onTriggered: root.forceRecreate = !root.forceRecreate
    }

    Column {
        anchors.left: parent.left
        anchors.right: dropdown.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: Theme.spacingL
        spacing: Theme.spacingXS

        StyledText {
            text: root.text
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
            visible: root.text.length > 0 && (!root.currentValue || root.currentValue === "")
            width: parent.width
            elide: Text.ElideRight
        }

        StyledText {
            text: root.description
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            visible: description.length > 0
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    // TextMetrics to calculate text width and height for auto-expanding dropdown
    TextMetrics {
        id: textMetrics
        font.pixelSize: Theme.fontSizeMedium
        font.weight: (root.currentValue && root.currentValue !== "") ? Font.Normal : Font.Medium
        text: {
            if (root.currentValue && root.currentValue !== "") {
                return root.currentValue
            }
            return root.text || "Select..."
        }
    }
    
    // Force recalculation when text changes
    onCurrentValueChanged: {
        Qt.callLater(() => {
            textMetrics.text = root.currentValue && root.currentValue !== "" ? root.currentValue : (root.text || "Select...")
        })
    }
    
    onTextChanged: {
        if (!root.currentValue || root.currentValue === "") {
            Qt.callLater(() => {
                textMetrics.text = root.text || "Select..."
            })
        }
    }

    Rectangle {
        id: dropdown

        // Auto-expand width based on content with min/max constraints
        width: {
            const minWidth = 120
            const maxWidth = Math.min(600, root.width * 0.8)
            const hasIcon = root.currentValue && root.currentValue !== "" && root.optionIcons.length > 0 && root.options.indexOf(root.currentValue) >= 0 && root.optionIcons[root.options.indexOf(root.currentValue)] !== ""
            const iconWidth = hasIcon ? 20 + Theme.spacingM : 0
            const expandIconWidth = 20 // Fixed width for expand icon
            const textWidth = textMetrics.width
            const horizontalPadding = root.dropdownHorizontalPadding * 2
            const spacing = Theme.spacingM // Space between icon and text, and between text and expand icon
            const contentWidth = textWidth + iconWidth + horizontalPadding + expandIconWidth + spacing
            return Math.max(minWidth, Math.min(maxWidth, contentWidth))
        }
        
        // Auto-expand height based on content with min/max constraints
        height: {
            const minHeight = root.controlHeight // Minimum height (48px default)
            const maxHeight = 200 // Maximum height to prevent excessive expansion
            // Use boundingRect.height for accurate text height measurement
            const textHeight = textMetrics.boundingRect.height || textMetrics.height || Theme.fontSizeMedium * 1.5
            const iconHeight = 20 // Icon height (if present)
            const verticalPadding = root.dropdownVerticalPadding * 2
            const contentHeight = Math.max(textHeight, iconHeight) + verticalPadding
            return Math.max(minHeight, Math.min(maxHeight, contentHeight))
        }
        anchors.right: parent.right
        anchors.rightMargin: root.horizontalPadding
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.cornerRadius
        color: dropdownArea.containsMouse ? Theme.primaryHover : Theme.contentBackground()
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, dropdownArea.containsMouse ? 0.2 : 0.12)
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

        MouseArea {
            id: dropdownArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const popup = popupLoader.item
                if (!popup) {
                    return
                }

                if (popup.visible) {
                    popup.close()
                    return
                }

                const pos = dropdown.mapToItem(Overlay.overlay, 0, dropdown.height + 4)
                popup.x = pos.x - (root.popupWidthOffset / 2)
                popup.y = pos.y
                popup.open()
            }
        }

        Row {
            id: contentRow

            anchors.left: parent.left
            anchors.right: expandIcon.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: root.dropdownHorizontalPadding
            anchors.rightMargin: Theme.spacingM
            spacing: Theme.spacingM

            Item {
                width: {
                    if (!root.currentValue || root.currentValue === "") return 0
                    const currentIndex = root.options.indexOf(root.currentValue)
                    if (currentIndex >= 0 && root.optionIcons.length > currentIndex && root.optionIcons[currentIndex] !== "" && root.width > 60) {
                        return 20
                    }
                    return 0
                }
                height: 20
                visible: width > 0
                
                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: {
                        const currentIndex = root.options.indexOf(root.currentValue)
                        const iconName = currentIndex >= 0 && root.optionIcons.length > currentIndex ? root.optionIcons[currentIndex] : ""
                        return iconName && iconName !== "" ? "image://icon/" + iconName : ""
                    }
                    sourceSize.width: 20
                    sourceSize.height: 20
                    fillMode: Image.PreserveAspectFit
                }
            }

            StyledText {
                id: dropdownText
                
                text: {
                    if (root.currentValue && root.currentValue !== "") {
                        return root.currentValue
                    }
                    return root.text
                }
                font.pixelSize: Theme.fontSizeMedium
                font.weight: (root.currentValue && root.currentValue !== "") ? Font.Normal : Font.Medium
                color: (root.currentValue && root.currentValue !== "") ? Theme.surfaceText : Theme.surfaceVariantText
                width: parent.width
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }
        }

        DarkIcon {
            id: expandIcon
            width: 20
            height: 20
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: root.dropdownHorizontalPadding
            name: "expand_more"
            size: 20
            color: Theme.surfaceText
            opacity: dropdownArea.containsMouse ? 1.0 : 0.6
            
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.shortDuration
                    easing.type: Theme.standardEasing
                }
            }
        }
    }

    Loader {
        id: popupLoader

        property bool recreateFlag: root.forceRecreate

        active: true
        onRecreateFlagChanged: {
            active = false
            active = true
        }

        sourceComponent: Component {
            Popup {
                id: dropdownMenu

                property string searchQuery: ""
                property var filteredOptions: []
                property int selectedIndex: -1
                readonly property string notoSansFamily: root.notoSansFamily
                property var fzfFinder: (function() {
                    try {
                        return Fzf.Finder(root.options, {
                            "selector": option => option,
                            "limit": 50,
                            "casing": "case-insensitive"
                        })
                    } catch (e) {
                        return null
                    }
                })()

                function updateFilteredOptions() {
                    if (!root.enableFuzzySearch || searchQuery.length === 0) {
                        filteredOptions = root.options
                        selectedIndex = -1
                        return
                    }

                    const results = fzfFinder.find(searchQuery)
                    filteredOptions = results.map(result => result.item)
                    selectedIndex = -1
                }

                function selectNext() {
                    if (filteredOptions.length === 0) {
                        return
                    }
                    selectedIndex = (selectedIndex + 1) % filteredOptions.length
                    listView.positionViewAtIndex(selectedIndex, ListView.Contain)
                }

                function selectPrevious() {
                    if (filteredOptions.length === 0) {
                        return
                    }
                    selectedIndex = selectedIndex <= 0 ? filteredOptions.length - 1 : selectedIndex - 1
                    listView.positionViewAtIndex(selectedIndex, ListView.Contain)
                }

                function selectCurrent() {
                    if (selectedIndex < 0 || selectedIndex >= filteredOptions.length) {
                        return
                    }
                    root.currentValue = filteredOptions[selectedIndex]
                    root.valueChanged(filteredOptions[selectedIndex])
                    close()
                }

                parent: Overlay.overlay
                width: dropdown.width + root.popupWidthOffset
                height: Math.min(root.maxPopupHeight, (root.enableFuzzySearch ? 44 + Theme.spacingS : 0) + Math.min(filteredOptions.length, 10) * 44 + Theme.spacingS * 2)
                padding: 0
                modal: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                onOpened: {
                    searchQuery = ""
                    updateFilteredOptions()
                    if (root.enableFuzzySearch && searchField.visible) {
                        searchField.forceActiveFocus()
                    }
                }

                background: Rectangle {
                    color: "transparent"
                }

                contentItem: Rectangle {
                    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 1)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                    border.width: 1
                    radius: Theme.cornerRadius
                    layer.enabled: true
                    layer.smooth: true

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS

                        Rectangle {
                            id: searchContainer

                            width: parent.width
                            height: 44
                            visible: root.enableFuzzySearch
                            radius: Theme.cornerRadius
                            color: Theme.surfaceVariantAlpha
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                            border.width: 1

                            DarkTextField {
                                id: searchField

                                anchors.fill: parent
                                anchors.margins: 1
                                placeholderText: "Search..."
                                text: searchQuery
                                topPadding: Theme.spacingS
                                bottomPadding: Theme.spacingS
                                onTextChanged: {
                                    searchQuery = text
                                    updateFilteredOptions()
                                }
                                Keys.onDownPressed: selectNext()
                                Keys.onUpPressed: selectPrevious()
                                Keys.onReturnPressed: selectCurrent()
                                Keys.onEnterPressed: selectCurrent()
                            }
                        }

                        Item {
                            width: 1
                            height: root.enableFuzzySearch ? Theme.spacingS : 0
                        }

                        DarkListView {
                            id: listView

                            property var popupRef: dropdownMenu

                            width: parent.width
                            height: parent.height - (root.enableFuzzySearch ? searchContainer.height + Theme.spacingS : 0)
                            clip: true
                            model: filteredOptions
                            spacing: 2

                            interactive: true
                            flickDeceleration: 1500
                            maximumFlickVelocity: 2000
                            boundsBehavior: Flickable.DragAndOvershootBounds
                            boundsMovement: Flickable.FollowBoundsBehavior
                            pressDelay: 0
                            flickableDirection: Flickable.VerticalFlick

                            delegate: Rectangle {
                                property bool isSelected: selectedIndex === index
                                property bool isCurrentValue: root.currentValue === modelData
                                property int optionIndex: root.options.indexOf(modelData)

                                width: ListView.view.width
                                height: 44
                                radius: Theme.cornerRadius
                                color: isSelected ? Theme.primaryHover : optionArea.containsMouse ? Theme.primaryHoverLight : "transparent"
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, (isSelected || optionArea.containsMouse) ? 0.2 : 0.08)
                                border.width: (isSelected || optionArea.containsMouse) ? 1 : 0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shorterDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }
                                
                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: Theme.shorterDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }
                                
                                Behavior on border.width {
                                    NumberAnimation {
                                        duration: Theme.shorterDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: Theme.spacingL + Theme.spacingS
                                    anchors.rightMargin: Theme.spacingL + Theme.spacingS
                                    spacing: Theme.spacingM

                                    Item {
                                        width: {
                                            if (optionIndex >= 0 && root.optionIcons.length > optionIndex && root.optionIcons[optionIndex] !== "") {
                                                return 20
                                            }
                                            return 0
                                        }
                                        height: 20
                                        visible: width > 0
                                        
                                        Image {
                                            anchors.centerIn: parent
                                            width: 20
                                            height: 20
                                            source: {
                                                const iconName = optionIndex >= 0 && root.optionIcons.length > optionIndex ? root.optionIcons[optionIndex] : ""
                                                return iconName && iconName !== "" ? "image://icon/" + iconName : ""
                                            }
                                            sourceSize.width: 20
                                            sourceSize.height: 20
                                            fillMode: Image.PreserveAspectFit
                                        }
                                    }

                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: isCurrentValue ? Font.Medium : Font.Normal
                                        color: isCurrentValue ? Theme.primary : Theme.surfaceText
                                        width: parent.parent.width - parent.x - (Theme.spacingL + Theme.spacingS)
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: optionArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.currentValue = modelData
                                        root.valueChanged(modelData)
                                        dropdownMenu.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
