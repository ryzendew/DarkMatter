import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modals
import qs.Modals.FileBrowser

Item {
    id: keybindsTab

    readonly property string defaultKeybindsPath: (Quickshell.env("HOME") || Paths.stringify(StandardPaths.writableLocation(StandardPaths.HomeLocation))) + "/.config/hypr/hyprland/keybinds.conf"

    property string keybindsPath: (SettingsData.keybindsPath && SettingsData.keybindsPath !== "") ? SettingsData.keybindsPath : defaultKeybindsPath

    property var keybinds: []
    property bool isLoading: false
    property bool hasUnsavedChanges: false
    property int editingIndex: -1
    property string searchQuery: ""
    property string selectedCategory: ""
    property bool showingNewBind: false
    property string expandedKey: ""

    property var _filteredBinds: []
    property var _cachedCategories: []
    property real _savedScrollY: 0
    property bool _preserveScroll: false
    property bool _configFileExists: true
    property bool _checkingFileExists: false

    readonly property var builtInKeybinds: [
        { "name": "Open Terminal", "modifiers": "SUPER", "key": "Q", "command": "exec, $terminal" },
        { "name": "Close Window", "modifiers": "SUPER", "key": "X", "command": "killactive" },
        { "name": "Toggle Floating", "modifiers": "SUPER", "key": "SPACE", "command": "togglefloating" },
        { "name": "Toggle Fullscreen", "modifiers": "SUPER", "key": "F", "command": "fullscreen" },
        { "name": "Move Focus Left", "modifiers": "SUPER", "key": "H", "command": "movefocus, l" },
        { "name": "Move Focus Right", "modifiers": "SUPER", "key": "L", "command": "movefocus, r" },
        { "name": "Move Focus Up", "modifiers": "SUPER", "key": "K", "command": "movefocus, u" },
        { "name": "Move Focus Down", "modifiers": "SUPER", "key": "J", "command": "movefocus, d" },
        { "name": "Move Window Left", "modifiers": "SUPER SHIFT", "key": "H", "command": "movewindow, l" },
        { "name": "Move Window Right", "modifiers": "SUPER SHIFT", "key": "L", "command": "movewindow, r" },
        { "name": "Move Window Up", "modifiers": "SUPER SHIFT", "key": "K", "command": "movewindow, u" },
        { "name": "Move Window Down", "modifiers": "SUPER SHIFT", "key": "J", "command": "movewindow, d" },
        { "name": "Resize Window Left", "modifiers": "SUPER CTRL", "key": "H", "command": "resizewindow, l -20 0" },
        { "name": "Resize Window Right", "modifiers": "SUPER CTRL", "key": "L", "command": "resizewindow, r 20 0" },
        { "name": "Resize Window Up", "modifiers": "SUPER CTRL", "key": "K", "command": "resizewindow, u 0 -20" },
        { "name": "Resize Window Down", "modifiers": "SUPER CTRL", "key": "J", "command": "resizewindow, d 0 20" },
        { "name": "Toggle Split", "modifiers": "SUPER", "key": "E", "command": "togglesplit" },
        { "name": "Toggle Pseudo", "modifiers": "SUPER", "key": "P", "command": "pseudo" },
        { "name": "Pin Window", "modifiers": "SUPER", "key": "S", "command": "pin" },
        { "name": "Move to Workspace 1", "modifiers": "SUPER", "key": "1", "command": "workspace, 1" },
        { "name": "Move to Workspace 2", "modifiers": "SUPER", "key": "2", "command": "workspace, 2" },
        { "name": "Move to Workspace 3", "modifiers": "SUPER", "key": "3", "command": "workspace, 3" },
        { "name": "Move to Workspace 4", "modifiers": "SUPER", "key": "4", "command": "workspace, 4" },
        { "name": "Move to Workspace 5", "modifiers": "SUPER", "key": "5", "command": "workspace, 5" },
        { "name": "Move to Workspace 6", "modifiers": "SUPER", "key": "6", "command": "workspace, 6" },
        { "name": "Move to Workspace 7", "modifiers": "SUPER", "key": "7", "command": "workspace, 7" },
        { "name": "Move to Workspace 8", "modifiers": "SUPER", "key": "8", "command": "workspace, 8" },
        { "name": "Move to Workspace 9", "modifiers": "SUPER", "key": "9", "command": "workspace, 9" },
        { "name": "Move Window to Workspace 1", "modifiers": "SUPER SHIFT", "key": "1", "command": "movetoworkspace, 1" },
        { "name": "Move Window to Workspace 2", "modifiers": "SUPER SHIFT", "key": "2", "command": "movetoworkspace, 2" },
        { "name": "Move Window to Workspace 3", "modifiers": "SUPER SHIFT", "key": "3", "command": "movetoworkspace, 3" },
        { "name": "Move Window to Workspace 4", "modifiers": "SUPER SHIFT", "key": "4", "command": "movetoworkspace, 4" },
        { "name": "Move Window to Workspace 5", "modifiers": "SUPER SHIFT", "key": "5", "command": "movetoworkspace, 5" },
        { "name": "Move Window to Workspace 6", "modifiers": "SUPER SHIFT", "key": "6", "command": "movetoworkspace, 6" },
        { "name": "Move Window to Workspace 7", "modifiers": "SUPER SHIFT", "key": "7", "command": "movetoworkspace, 7" },
        { "name": "Move Window to Workspace 8", "modifiers": "SUPER SHIFT", "key": "8", "command": "movetoworkspace, 8" },
        { "name": "Move Window to Workspace 9", "modifiers": "SUPER SHIFT", "key": "9", "command": "movetoworkspace, 9" },
        { "name": "Scroll Workspace", "modifiers": "SUPER", "key": "mouse_down", "command": "workspace, e+1" },
        { "name": "Scroll Workspace (Reverse)", "modifiers": "SUPER", "key": "mouse_up", "command": "workspace, e-1" },
        { "name": "Toggle Special Workspace", "modifiers": "SUPER", "key": "S", "command": "togglespecialworkspace" },
        { "name": "Move Window to Special Workspace", "modifiers": "SUPER SHIFT", "key": "S", "command": "movetoworkspace, special" },
        { "name": "Toggle Overview", "modifiers": "SUPER", "key": "O", "command": "overview" },
        { "name": "Toggle Group", "modifiers": "SUPER", "key": "G", "command": "togglegroup" },
        { "name": "Change Group Window", "modifiers": "SUPER", "key": "Tab", "command": "changegroupactive" },
        { "name": "Lock Screen", "modifiers": "SUPER", "key": "L", "command": "exec, $lock" },
        { "name": "Exit Hyprland", "modifiers": "SUPER SHIFT", "key": "Q", "command": "exit" },
        { "name": "Reload Config", "modifiers": "SUPER SHIFT", "key": "R", "command": "exec, hyprctl reload" },
        { "name": "Open App Launcher", "modifiers": "SUPER", "key": "A", "command": "exec, $menu" },
        { "name": "Screenshot", "modifiers": "SUPER", "key": "PRINT", "command": "exec, $screenshot" },
        { "name": "Screenshot Area", "modifiers": "SUPER SHIFT", "key": "S", "command": "exec, $screenshotarea" },
        { "name": "Dock - Toggle Dock", "modifiers": "SUPER", "key": "D", "command": "exec, hyprctl dispatch togglespecialworkspace quickshell:dock:blur" },
        { "name": "Dock - Show Dock", "modifiers": "SUPER", "key": "B", "command": "exec, hyprctl dispatch togglespecialworkspace quickshell:dock:blur" },
        { "name": "Dock - Hide Dock", "modifiers": "SUPER SHIFT", "key": "D", "command": "exec, hyprctl dispatch togglespecialworkspace quickshell:dock:blur" },
        { "name": "Toggle Overview (IPC)", "modifiers": "ALT", "key": "Tab", "command": "exec,qs ipc call overview toggle" },
        { "name": "Toggle Overview (IPC - Reverse)", "modifiers": "ALT SHIFT", "key": "Tab", "command": "exec,qs ipc call overview toggle" },
        { "name": "Toggle HyprMenu (IPC)", "modifiers": "", "key": "Super", "command": "exec,quickshell ipc call hyprmenu toggle" },
        { "name": "Toggle Cheatsheet (IPC)", "modifiers": "SUPER", "key": "Slash", "command": "exec,quickshell ipc call cheatsheet toggle" },
        { "name": "Toggle Overview (CLI)", "modifiers": "SUPER", "key": "Tab", "command": "exec,quickshell --overview" },
        { "name": "Toggle Bar (CLI)", "modifiers": "SUPER", "key": "B", "command": "exec,quickshell --toggle-bar" },
        { "name": "Toggle Media Player (IPC)", "modifiers": "SUPER", "key": "M", "command": "exec,quickshell ipc call simpleMediaPlayer toggle" },
        { "name": "Toggle Keyboard (CLI)", "modifiers": "SUPER", "key": "K", "command": "exec,quickshell --toggle-keyboard" },
        { "name": "Toggle Dark Dash (IPC)", "modifiers": "SUPER SHIFT", "key": "D", "command": "exec,quickshell ipc call dash toggle" },
        { "name": "Toggle Power Menu (CLI)", "modifiers": "CTRL ALT", "key": "Delete", "command": "exec,quickshell --toggle-power" },
        { "name": "Toggle App Drawer (IPC)", "modifiers": "SUPER", "key": "a", "command": "exec,qs ipc call appDrawerPopout toggle" }
    ]

    Component.onCompleted: {
        checkConfigFileExists()
        loadKeybinds()
    }

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(scrollToTop)
            checkConfigFileExists()
        }
    }

    function checkConfigFileExists() {
        if (_checkingFileExists) return
        _checkingFileExists = true
        checkFileProcess.command = ["test", "-f", keybindsPath]
        checkFileProcess.running = true
    }

    function loadKeybinds() {
        isLoading = true
        keybindsFile.path = ""
        keybindsFile.path = keybindsPath
    }

    function parseKeybinds(content) {
        var lines = content.split('\n')
        var parsed = []

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()

            if (line.length === 0 || line.startsWith('#')) {
                parsed.push({
                    type: 'comment',
                    original: lines[i],
                    text: line
                })
                continue
            }

            var bindMatch = line.match(/^bind[rs]?\s*=\s*(.+)$/)
            if (bindMatch) {
                var parts = bindMatch[1].split(',').map(p => p.trim())
                if (parts.length >= 2) {
                    var modifiers = parts[0]
                    var key = parts[1]
                    var command = parts.slice(2).join(',').trim()

                    parsed.push({
                        type: 'keybind',
                        original: lines[i],
                        modifiers: modifiers,
                        key: key,
                        command: command,
                        isRelease: line.startsWith('bindr')
                    })
                } else {
                    parsed.push({
                        type: 'raw',
                        original: lines[i],
                        text: line
                    })
                }
            } else {
                parsed.push({
                    type: 'raw',
                    original: lines[i],
                    text: line
                })
            }
        }

        keybinds = parsed
        isLoading = false
        hasUnsavedChanges = false
        _updateCategories()
        _updateFiltered()
    }

    function _updateFiltered() {
        const allBinds = keybinds.filter(k => k.type === 'keybind')
        if (!searchQuery && !selectedCategory) {
            _filteredBinds = allBinds
            return
        }

        const q = searchQuery.toLowerCase()
        const result = []

        for (let i = 0; i < allBinds.length; i++) {
            const bind = allBinds[i]

            if (q) {
                const keyStr = (bind.modifiers || "") + " " + (bind.key || "") + " " + (bind.command || "")
                if (keyStr.toLowerCase().indexOf(q) === -1) {
                    continue
                }
            }

            if (selectedCategory) {
                const category = _getCategoryForBind(bind)
                if (category !== selectedCategory) {
                    continue
                }
            }

            result.push(bind)
        }
        _filteredBinds = result
    }

    function _getCategoryForBind(bind) {
        if (!bind.command) return ""
        const cmd = bind.command.toLowerCase()
        if (cmd.includes("workspace")) return "Workspaces"
        if (cmd.includes("move") || cmd.includes("resize")) return "Window Management"
        if (cmd.includes("exec") || cmd.includes("$")) return "Applications"
        if (cmd.includes("toggle") || cmd.includes("fullscreen") || cmd.includes("floating")) return "Window Actions"
        if (cmd.includes("focus")) return "Focus"
        if (cmd.includes("ipc") || cmd.includes("quickshell")) return "Quickshell"
        return "Other"
    }

    function _updateCategories() {
        const allBinds = keybinds.filter(k => k.type === 'keybind')
        const categories = new Set()
        for (let i = 0; i < allBinds.length; i++) {
            const cat = _getCategoryForBind(allBinds[i])
            if (cat) categories.add(cat)
        }
        _cachedCategories = Array.from(categories).sort()
    }

    function toggleExpanded(bind) {
        const key = (bind.modifiers || "") + "+" + (bind.key || "")
        expandedKey = expandedKey === key ? "" : key
    }

    function isExpanded(bind) {
        const key = (bind.modifiers || "") + "+" + (bind.key || "")
        return expandedKey === key
    }

    function saveKeybinds() {
        _savedScrollY = flickable.contentY
        _preserveScroll = true

        var lines = []
        var lastWasEmpty = false

        for (var i = 0; i < keybinds.length; i++) {
            var item = keybinds[i]
            var line = ""

            if (item.type === 'comment' || item.type === 'raw') {
                line = item.original
            } else if (item.type === 'keybind') {
                var bindType = item.isRelease ? 'bindr' : 'bind'
                var parts = [item.modifiers, item.key]
                if (item.command) {
                    parts.push(item.command)
                }
                line = bindType + ' = ' + parts.join(', ')
            } else {
                line = item.original
            }

            line = line.replace(/\s+$/, '')

            var isEmpty = line.length === 0 || line.trim().length === 0
            if (isEmpty && lastWasEmpty) {
                continue
            }
            lastWasEmpty = isEmpty

            lines.push(line)
        }

        while (lines.length > 0 && lines[lines.length - 1].trim().length === 0) {
            lines.pop()
        }

        var content = lines.join('\n')

        var dirPath = keybindsPath.substring(0, keybindsPath.lastIndexOf('/'))
        ensureDirProcess.command = ["mkdir", "-p", dirPath]
        ensureDirProcess.running = true
        pendingSaveContent = content
    }

    Process {
        id: ensureDirProcess
        command: ["mkdir", "-p"]
        running: false

        onExited: exitCode => {
            if (pendingSaveContent !== "") {
                touchFileProcess.command = ["touch", keybindsPath]
                touchFileProcess.running = true
            }
        }
    }

    Process {
        id: touchFileProcess
        command: ["touch"]
        running: false

        onExited: exitCode => {
            if (pendingSaveContent !== "") {
                saveKeybindsFile.path = ""
                Qt.callLater(() => {
                    saveKeybindsFile.path = keybindsPath
                    Qt.callLater(() => {
                        saveKeybindsFile.setText(pendingSaveContent)
                    })
                })
            }
        }
    }

    property string pendingSaveContent: ""

    function addNewKeybind() {
        var newKeybind = {
            type: 'keybind',
            original: 'bind = , , ',
            modifiers: '',
            key: '',
            command: '',
            isRelease: false
        }
        keybinds.push(newKeybind)
        editingIndex = keybinds.length - 1
        hasUnsavedChanges = true
        showingNewBind = true
        _updateFiltered()
        Qt.callLater(() => {
            if (newModifiersField) {
                newModifiersField.forceActiveFocus()
            }
        })
    }

    function cancelNewBind() {
        if (editingIndex >= 0 && editingIndex < keybinds.length) {
            keybinds.splice(editingIndex, 1)
        }
        editingIndex = -1
        showingNewBind = false
        hasUnsavedChanges = false
        _updateFiltered()
    }

    function saveNewBind() {
        if (editingIndex >= 0 && editingIndex < keybinds.length) {
            var bind = keybinds[editingIndex]
            if (bind.modifiers && bind.key && bind.command) {
                hasUnsavedChanges = true
                showingNewBind = false
                editingIndex = -1
                _updateFiltered()
            } else {
                cancelNewBind()
            }
        }
    }

    function addBuiltInKeybind(builtIn) {
        var newKeybind = {
            type: 'keybind',
            original: 'bind = ' + builtIn.modifiers + ', ' + builtIn.key + ', ' + builtIn.command,
            modifiers: builtIn.modifiers,
            key: builtIn.key,
            command: builtIn.command,
            isRelease: false
        }
        keybinds.push(newKeybind)
        editingIndex = keybinds.length - 1
        hasUnsavedChanges = true
        builtInKeybindsPopup.close()
        _updateFiltered()
    }

    function startEditing(index) {
        editingIndex = index
    }

    function stopEditing() {
        editingIndex = -1
    }

    function scrollToTop() {
        flickable.contentY = 0
    }

    Timer {
        id: searchDebounce
        interval: 150
        onTriggered: keybindsTab._updateFiltered()
    }

    FileView {
        id: keybindsFile
        path: keybindsTab.keybindsPath
        blockWrites: true
        blockLoading: false
        atomicWrites: true
        printErrors: true

        onLoaded: {
            var fileContent = text()
            const savedY = keybindsTab._savedScrollY
            const wasPreserving = keybindsTab._preserveScroll
            keybindsTab._preserveScroll = false
            parseKeybinds(fileContent)
            if (wasPreserving) {
                Qt.callLater(() => {
                    flickable.contentY = savedY
                })
            }
        }

        onLoadFailed: {
            isLoading = false
            if (typeof ToastService !== "undefined") {
                ToastService.showError("Failed to load keybinds file")
            }
        }
    }

    Process {
        id: checkFileProcess
        command: ["test", "-f"]
        running: false

        onExited: exitCode => {
            _configFileExists = (exitCode === 0)
            _checkingFileExists = false
        }
    }

    FileView {
        id: saveKeybindsFile
        blockWrites: false
        blockLoading: true
        atomicWrites: true
        printErrors: true

        onSaved: {
            hasUnsavedChanges = false
            if (typeof ToastService !== "undefined") {
                ToastService.showInfo("Keybinds saved successfully")
            }
            const savedY = keybindsTab._savedScrollY
            const wasPreserving = keybindsTab._preserveScroll
            keybindsTab._preserveScroll = false
            Qt.callLater(() => {
                keybindsFile.reload()
                if (wasPreserving) {
                    Qt.callLater(() => {
                        flickable.contentY = savedY
                    })
                }
            })
            reloadHyprlandProcess.running = true
            pendingSaveContent = ""
        }

        onSaveFailed: (error) => {
            if (typeof ToastService !== "undefined") {
                ToastService.showError("Failed to save keybinds file: " + (error || "Unknown error"))
            }
            pendingSaveContent = ""
        }
    }

    Process {
        id: reloadHyprlandProcess
        command: ["hyprctl", "reload"]
        running: false

        onExited: exitCode => {
            if (exitCode === 0) {
                if (typeof ToastService !== "undefined") {
                    ToastService.showInfo("Hyprland configuration reloaded")
                }
            } else {
                if (typeof ToastService !== "undefined") {
                    ToastService.showError("Failed to reload Hyprland configuration")
                }
            }
        }
    }

    DarkFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight

        Column {
            id: contentColumn
            width: flickable.width
            spacing: Theme.spacingL
            topPadding: Theme.spacingXL
            bottomPadding: Theme.spacingXL
            leftPadding: Theme.spacingL
            rightPadding: Theme.spacingL

            StyledRect {
                width: parent.width - parent.leftPadding - parent.rightPadding
                height: headerSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, Theme.popupTransparency)
                border.width: 0

                Column {
                    id: headerSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "keyboard"
                            size: Theme.iconSize
                            color: Theme.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXS
                            Layout.alignment: Qt.AlignVCenter

                            StyledText {
                                text: "Keybinds"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: "Manage keyboard shortcuts for Hyprland"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkTextField {
                            id: searchField
                            width: parent.width - addButton.width - Theme.spacingM
                            height: 44
                            placeholderText: "Search keybinds..."
                            leftIconName: "search"
                            autoExpandWidth: false
                            autoExpandHeight: false
                            onTextChanged: {
                                keybindsTab.searchQuery = text
                                searchDebounce.restart()
                            }
                        }

                        DarkActionButton {
                            id: addButton
                            width: 44
                            height: 44
                            circular: false
                            iconName: "add"
                            iconSize: Theme.iconSize
                            iconColor: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: !keybindsTab.showingNewBind
                            opacity: enabled ? 1 : 0.5
                            onClicked: keybindsTab.addNewKeybind()
                        }
                    }

                }
            }

            StyledRect {
                id: warningBox
                width: parent.width - parent.leftPadding - parent.rightPadding
                height: warningSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                readonly property bool showWarning: !_configFileExists && !isLoading
                color: showWarning ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"
                border.color: showWarning ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"
                border.width: 1
                visible: showWarning

                Column {
                    id: warningSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "warning"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingM
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: "Config File Missing"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.primary
                            }

                            StyledText {
                                text: "The keybinds config file does not exist. It will be created when you save your first keybind."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }
                }
            }

            Flow {
                width: parent.width - parent.leftPadding - parent.rightPadding
                spacing: Theme.spacingS
                visible: _cachedCategories.length > 0

                        Rectangle {
                            width: allChipText.implicitWidth + Theme.spacingL
                            height: 32
                            radius: Theme.cornerRadius
                            color: !keybindsTab.selectedCategory ? Theme.primary : Theme.surfaceContainer

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.shortDuration
                                    easing.type: Theme.standardEasing
                                }
                            }

                            StyledText {
                                id: allChipText
                                text: "All"
                                font.pixelSize: Theme.fontSizeSmall
                                color: !keybindsTab.selectedCategory ? Theme.primaryText : Theme.surfaceVariantText
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    keybindsTab.selectedCategory = ""
                                    keybindsTab._updateFiltered()
                                }
                            }
                        }

                        Repeater {
                            model: keybindsTab._cachedCategories

                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                width: catText.implicitWidth + Theme.spacingL
                                height: 32
                                radius: Theme.cornerRadius
                                color: keybindsTab.selectedCategory === modelData ? Theme.primary : Theme.surfaceContainer

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }

                                StyledText {
                                    id: catText
                                    text: modelData
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: keybindsTab.selectedCategory === modelData ? Theme.primaryText : Theme.surfaceVariantText
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        keybindsTab.selectedCategory = modelData
                                        keybindsTab._updateFiltered()
                                    }
                                }
                            }
                        }
            }

            Column {
                id: newBindSection
                width: parent.width - parent.leftPadding - parent.rightPadding
                spacing: Theme.spacingM
                visible: keybindsTab.showingNewBind
                opacity: visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }

                StyledText {
                    text: "New Keybind"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                Row {
                    id: keybindEditRow
                    width: parent.width
                    spacing: Theme.spacingM

                            DarkTextField {
                                id: newModifiersField
                                width: 140
                                height: 40
                                placeholderText: "MODIFIER"
                                autoExpandWidth: false
                                autoExpandHeight: false
                                text: editingIndex >= 0 && editingIndex < keybinds.length ? keybinds[editingIndex].modifiers || "" : ""
                                onTextChanged: {
                                    if (editingIndex >= 0 && editingIndex < keybinds.length) {
                                        keybinds[editingIndex].modifiers = text
                                        hasUnsavedChanges = true
                                    }
                                }
                                Keys.onEscapePressed: cancelNewBind()
                                Keys.onTabPressed: newKeyField.forceActiveFocus()
                                Keys.onEnterPressed: {
                                    if (newKeyField.text && newCommandField.text) {
                                        saveNewBind()
                                    } else {
                                        newKeyField.forceActiveFocus()
                                    }
                                }
                                Keys.onReturnPressed: {
                                    if (newKeyField.text && newCommandField.text) {
                                        saveNewBind()
                                    } else {
                                        newKeyField.forceActiveFocus()
                                    }
                                }
                            }

                            DarkTextField {
                                id: newKeyField
                                width: 120
                                height: 40
                                placeholderText: "KEY"
                                autoExpandWidth: false
                                autoExpandHeight: false
                                text: editingIndex >= 0 && editingIndex < keybinds.length ? keybinds[editingIndex].key || "" : ""
                                onTextChanged: {
                                    if (editingIndex >= 0 && editingIndex < keybinds.length) {
                                        keybinds[editingIndex].key = text
                                        hasUnsavedChanges = true
                                    }
                                }
                                Keys.onEscapePressed: cancelNewBind()
                                Keys.onTabPressed: newCommandField.forceActiveFocus()
                                Keys.onEnterPressed: {
                                    if (newModifiersField.text && newCommandField.text) {
                                        saveNewBind()
                                    } else {
                                        newCommandField.forceActiveFocus()
                                    }
                                }
                                Keys.onReturnPressed: {
                                    if (newModifiersField.text && newCommandField.text) {
                                        saveNewBind()
                                    } else {
                                        newCommandField.forceActiveFocus()
                                    }
                                }
                            }

                            DarkTextField {
                                id: newCommandField
                                width: parent.width - 140 - 120 - Theme.spacingM * 2 - 80
                                height: 40
                                placeholderText: "COMMAND"
                                autoExpandWidth: false
                                autoExpandHeight: false
                                text: editingIndex >= 0 && editingIndex < keybinds.length ? keybinds[editingIndex].command || "" : ""
                                onTextChanged: {
                                    if (editingIndex >= 0 && editingIndex < keybinds.length) {
                                        keybinds[editingIndex].command = text
                                        hasUnsavedChanges = true
                                    }
                                }
                                Keys.onEscapePressed: cancelNewBind()
                                Keys.onEnterPressed: {
                                    if (newModifiersField.text && newKeyField.text) {
                                        saveNewBind()
                                    }
                                }
                                Keys.onReturnPressed: {
                                    if (newModifiersField.text && newKeyField.text) {
                                        saveNewBind()
                                    }
                                }
                            }

                            DarkActionButton {
                                width: 36
                                height: 36
                                circular: true
                                iconName: "close"
                                iconSize: 18
                                iconColor: Theme.error
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: cancelNewBind()
                            }
                }
            }

            Item {
                width: parent.width
                height: isLoading ? 40 : 0
                visible: isLoading

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingM

                    DarkIcon {
                        name: "sync"
                        size: 20
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: isLoading
                        }
                    }

                    StyledText {
                        text: "Loading keybinds..."
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            StyledText {
                text: "No keybinds found"
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
                visible: !isLoading && _filteredBinds.length === 0
            }

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                Repeater {
                    model: keybindsTab._filteredBinds

                    Item {
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: bindItem.height

                        StyledRect {
                            id: bindItem
                            width: contentColumn.width - contentColumn.leftPadding - contentColumn.rightPadding
                            height: collapsedContent.height + (isExpanded ? expandedContent.height + Theme.spacingM : 0) + Theme.spacingL * 2
                            radius: Theme.cornerRadius
                            color: itemMouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, Theme.popupTransparency)
                            border.color: Theme.outlineVariant
                            border.width: 1

                            property bool isExpanded: keybindsTab.isExpanded(modelData)

                            Behavior on height {
                                NumberAnimation {
                                    duration: Theme.shortDuration
                                    easing.type: Theme.standardEasing
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.shortDuration
                                    easing.type: Theme.standardEasing
                                }
                            }

                            Column {
                                id: collapsedContent
                                anchors.left: parent.left
                                anchors.right: expandButton.left
                                anchors.top: parent.top
                                anchors.leftMargin: Theme.spacingL
                                anchors.rightMargin: Theme.spacingM
                                anchors.topMargin: Theme.spacingL
                                spacing: Theme.spacingXS

                                Row {
                                    width: parent.width
                                    spacing: Theme.spacingM

                                    StyledText {
                                        width: 140
                                        text: modelData.modifiers || "MOD"
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: modelData.modifiers ? Theme.surfaceText : Theme.surfaceVariantText
                                        wrapMode: Text.Wrap
                                    }

                                    StyledText {
                                        width: 120
                                        text: modelData.key || "key"
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: modelData.key ? Theme.surfaceText : Theme.surfaceVariantText
                                        wrapMode: Text.Wrap
                                    }

                                    StyledText {
                                        width: parent.width - 140 - 120 - Theme.spacingM * 2
                                        text: modelData.command || "command"
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: modelData.command ? Theme.surfaceText : Theme.surfaceVariantText
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Column {
                                id: expandedContent
                                anchors.left: parent.left
                                anchors.right: expandButton.left
                                anchors.top: collapsedContent.bottom
                                anchors.leftMargin: Theme.spacingL
                                anchors.rightMargin: Theme.spacingM
                                anchors.topMargin: Theme.spacingM
                                spacing: Theme.spacingM
                                visible: bindItem.isExpanded
                                height: visible ? implicitHeight : 0

                                Behavior on height {
                                    NumberAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }

                                opacity: visible ? 1 : 0

                                Row {
                                    width: parent.width
                                    spacing: Theme.spacingM

                                    DarkTextField {
                                        id: modifiersField
                                        width: 140
                                        height: 40
                                        placeholderText: "MODIFIER"
                                        autoExpandWidth: false
                                        autoExpandHeight: false
                                        text: modelData.modifiers || ""
                                        onTextChanged: {
                                            if (modelData.modifiers !== text) {
                                                var bindIndex = -1
                                                for (var i = 0; i < keybindsTab.keybinds.length; i++) {
                                                    if (keybindsTab.keybinds[i] === modelData) {
                                                        bindIndex = i
                                                        break
                                                    }
                                                }
                                                if (bindIndex >= 0) {
                                                    keybindsTab.keybinds[bindIndex].modifiers = text
                                                }
                                                modelData.modifiers = text
                                                keybindsTab.hasUnsavedChanges = true
                                            }
                                        }
                                        Keys.onEscapePressed: keybindsTab.toggleExpanded(modelData)
                                        Keys.onTabPressed: {
                                            keyField.forceActiveFocus()
                                            keyField.selectAll()
                                        }
                                    }

                                    DarkTextField {
                                        id: keyField
                                        width: 120
                                        height: 40
                                        placeholderText: "KEY"
                                        autoExpandWidth: false
                                        autoExpandHeight: false
                                        text: modelData.key || ""
                                        onTextChanged: {
                                            if (modelData.key !== text) {
                                                var bindIndex = -1
                                                for (var i = 0; i < keybindsTab.keybinds.length; i++) {
                                                    if (keybindsTab.keybinds[i] === modelData) {
                                                        bindIndex = i
                                                        break
                                                    }
                                                }
                                                if (bindIndex >= 0) {
                                                    keybindsTab.keybinds[bindIndex].key = text
                                                }
                                                modelData.key = text
                                                keybindsTab.hasUnsavedChanges = true
                                            }
                                        }
                                        Keys.onEscapePressed: keybindsTab.toggleExpanded(modelData)
                                        Keys.onTabPressed: {
                                            commandField.forceActiveFocus()
                                            commandField.selectAll()
                                        }
                                    }

                                    DarkTextField {
                                        id: commandField
                                        width: parent.width - 140 - 120 - Theme.spacingM * 2
                                        height: 40
                                        placeholderText: "COMMAND"
                                        autoExpandWidth: false
                                        autoExpandHeight: false
                                        text: modelData.command || ""
                                        onTextChanged: {
                                            if (modelData.command !== text) {
                                                var bindIndex = -1
                                                for (var i = 0; i < keybindsTab.keybinds.length; i++) {
                                                    if (keybindsTab.keybinds[i] === modelData) {
                                                        bindIndex = i
                                                        break
                                                    }
                                                }
                                                if (bindIndex >= 0) {
                                                    keybindsTab.keybinds[bindIndex].command = text
                                                }
                                                modelData.command = text
                                                keybindsTab.hasUnsavedChanges = true
                                            }
                                        }
                                        Keys.onEscapePressed: keybindsTab.toggleExpanded(modelData)
                                    }
                                }

                                Row {
                                    width: parent.width
                                    spacing: Theme.spacingM
                                    layoutDirection: Qt.RightToLeft

                                    DarkActionButton {
                                        buttonSize: 36
                                        circular: false
                                        iconName: "delete"
                                        iconSize: 18
                                        iconColor: Theme.error
                                        onClicked: {
                                            var bindIndex = -1
                                            for (var i = 0; i < keybindsTab.keybinds.length; i++) {
                                                if (keybindsTab.keybinds[i] === modelData) {
                                                    bindIndex = i
                                                    break
                                                }
                                            }
                                    if (bindIndex >= 0) {
                                        keybindsTab._savedScrollY = flickable.contentY
                                        keybindsTab._preserveScroll = true
                                        keybindsTab.hasUnsavedChanges = true
                                        keybindsTab.keybinds.splice(bindIndex, 1)
                                        keybindsTab._updateFiltered()
                                        Qt.callLater(() => {
                                            if (keybindsTab._preserveScroll) {
                                                flickable.contentY = keybindsTab._savedScrollY
                                                keybindsTab._preserveScroll = false
                                            }
                                        })
                                    }
                                }
                            }
                                }
                            }

                            DarkActionButton {
                                id: expandButton
                                buttonSize: 32
                                circular: true
                                iconName: bindItem.isExpanded ? "expand_less" : "expand_more"
                                iconSize: 18
                                iconColor: Theme.surfaceVariantText
                                anchors.top: parent.top
                                anchors.topMargin: Theme.spacingL
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingM
                                onClicked: keybindsTab.toggleExpanded(modelData)

                                Behavior on iconColor {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                propagateComposedEvents: true
                                onClicked: {
                                    if (!bindItem.isExpanded) {
                                        keybindsTab.toggleExpanded(modelData)
                                        Qt.callLater(() => {
                                            if (modifiersField) {
                                                modifiersField.forceActiveFocus()
                                                modifiersField.selectAll()
                                            }
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: builtInKeybindsPopup

        parent: Overlay.overlay
        width: 500
        height: Math.min(600, builtInList.height + Theme.spacingL * 2)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: StyledRect {
            color: Theme.surfaceContainer
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
            border.width: 1
            radius: Theme.cornerRadius

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.3)
                shadowBlur: 0.8
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 4
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            Row {
                width: parent.width
                spacing: Theme.spacingM

                DarkIcon {
                    name: "list"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - Theme.iconSize - Theme.spacingM
                    spacing: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        text: "Built-in Keybinds"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Select a keybind to add to your configuration"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }
                }
            }

            DarkFlickable {
                width: parent.width
                height: parent.height - 100
                clip: true
                contentHeight: builtInList.height
                contentWidth: width

                Column {
                    id: builtInList
                    width: parent.width
                    spacing: Theme.spacingXS

                    Repeater {
                        model: keybindsTab.builtInKeybinds

                        Rectangle {
                            width: parent.width
                            height: 56
                            radius: Theme.cornerRadius
                            color: builtInMouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.3)
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingM

                                Column {
                                    width: parent.width - 100
                                    spacing: Theme.spacingXS
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        text: modelData.name
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Medium
                                        color: Theme.surfaceText
                                    }

                                    StyledText {
                                        text: modelData.modifiers + " + " + modelData.key + " → " + modelData.command
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                        font.family: "monospace"
                                        elide: Text.ElideRight
                                    }
                                }

                                DarkActionButton {
                                    buttonSize: 32
                                    circular: true
                                    iconName: "add"
                                    iconSize: 18
                                    iconColor: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: keybindsTab.addBuiltInKeybind(modelData)
                                }
                            }

                            MouseArea {
                                id: builtInMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: keybindsTab.addBuiltInKeybind(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    FileBrowserModal {
        id: keybindsFileBrowser

        browserTitle: "Select Keybinds Config File"
        browserIcon: "keyboard"
        browserType: "generic"
        fileExtensions: ["*.conf"]
        saveMode: false
        showHiddenFiles: true

        onFileSelected: path => {
            var cleanPath = path.replace(/^file:\/\//, '')
            SettingsData.keybindsPath = cleanPath
            SettingsData.saveSettings()
            keybindsTab.keybindsPath = cleanPath
            checkConfigFileExists()
            loadKeybinds()
            close()
        }
    }
}
