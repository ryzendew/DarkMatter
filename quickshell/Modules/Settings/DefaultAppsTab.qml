import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets

Item {
    id: root


    property var queryQueue: []
    property bool queryInProgress: false
    property var activeQueryCallback: null

    Process {
        id: queryProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.activeQueryCallback) {
                    var result = (text || "").trim()
                    root.activeQueryCallback(result)
                    root.activeQueryCallback = null
                }
                root.queryInProgress = false
                root.processNextQuery()
            }
        }
    }

    function processNextQuery() {
        if (root.queryInProgress || root.queryQueue.length === 0) return

        root.queryInProgress = true
        var item = root.queryQueue.shift()
        root.activeQueryCallback = item.callback
        queryProcess.command = ["xdg-mime", "query", "default", item.mime]
        queryProcess.running = true
    }

    function queryDefault(mime, cb) {
        if (!mime || !cb) return
        root.queryQueue.push({mime: mime, callback: cb})
        root.processNextQuery()
    }


    function normalizeDesktopId(id) {
        if (!id || typeof id !== 'string') return ""
        var normalized = id.toLowerCase().trim()
        if (normalized.endsWith('.desktop')) {
            normalized = normalized.slice(0, -8)
        }
        return normalized
    }

    function desktopIdsMatch(id1, id2) {
        return root.normalizeDesktopId(id1) === root.normalizeDesktopId(id2)
    }

    function ensureDesktopExtension(id) {
        if (!id) return ""
        var normalized = id.trim()
        if (!normalized.endsWith('.desktop')) {
            normalized = normalized + '.desktop'
        }
        return normalized
    }

    function setDefault(mime, desktopId) {
        if (!mime || !desktopId) return

        var finalId = root.ensureDesktopExtension(desktopId)


        Quickshell.execDetached(["gio", "mime", mime, finalId])
        Quickshell.execDetached(["xdg-mime", "default", finalId, mime])
    }

    readonly property var allApps: (
        (typeof DesktopEntries !== "undefined" && DesktopEntries.applications)
            ? (function(){
                  var raw = DesktopEntries.applications
                  var list = Array.isArray(raw) ? raw : (raw && raw.values ? raw.values : [])
                  return list.filter(function(app){ return !(app && (app.noDisplay || app.runInTerminal)) })
              })()
            : []
    )

    function appsByCategory(cat) {
        return allApps.filter(a => (a.categories || []).includes(cat))
    }

    function appsByMime(mime) {
        return allApps.filter(a => (a.mimeTypes || []).includes(mime))
    }

    function uniqueApps(list) {
        const seen = new Set()
        const out = []
        for (const a of list) {
            if (!a) continue
            const id = root.getAppId(a)
            const normalizedId = root.normalizeDesktopId(id)
            if (!seen.has(normalizedId)) {
                seen.add(normalizedId)
                out.push(a)
            }
        }
        return out
    }

    function getAppId(app) {
        if (!app) return ""
        return app.id || app.desktopId || app.filename || app.appId || ((app.name || "Unknown") + ".desktop")
    }


    function getAppsForMimeTypes(mimeTypes) {
        if (!mimeTypes || mimeTypes.length === 0) return []

        var apps = root.allApps || []
        var matchingApps = []
        var seenIds = new Set()


        for (var i = 0; i < mimeTypes.length; i++) {
            var mime = mimeTypes[i]
            for (var j = 0; j < apps.length; j++) {
                var app = apps[j]
                var appMimes = app.mimeTypes || []
                if (appMimes.includes(mime)) {
                    var appId = root.getAppId(app)
                    var normalizedId = root.normalizeDesktopId(appId)
                    if (!seenIds.has(normalizedId)) {
                        seenIds.add(normalizedId)
                        matchingApps.push(app)
                    }
                }
            }
        }


        for (var k = 0; k < mimeTypes.length; k++) {
            var mime = mimeTypes[k]
            if (mime.startsWith('x-scheme-handler/')) {
                var handler = mime.split('/')[1]
                var categoryApps = []

                if (handler === 'http' || handler === 'https') {
                    categoryApps = root.appsByCategory('WebBrowser')
                } else if (handler === 'mailto') {
                    categoryApps = root.appsByCategory('Email')
                }

                for (var l = 0; l < categoryApps.length; l++) {
                    var app = categoryApps[l]
                    var appId = root.getAppId(app)
                    var normalizedId = root.normalizeDesktopId(appId)
                    if (!seenIds.has(normalizedId)) {
                        seenIds.add(normalizedId)
                        matchingApps.push(app)
                    }
                }
            }
        }

        return matchingApps
    }

    function displayName(app) {
        if (!app)
            return "Unknown"
        return app.name || app.displayName || app.genericName || app.comment || app.title || app.id || app.filename || "Unknown"
    }

    readonly property var defaultsModel: [
        { key: "browser",    title: "Web Browser",      icon: "web",
          mimes: ["x-scheme-handler/http", "x-scheme-handler/https"],
          candidates: () => uniqueApps(appsByCategory("WebBrowser")) },
        { key: "mailer",     title: "Mail Client",      icon: "mail",
          mimes: ["x-scheme-handler/mailto"],
          candidates: () => uniqueApps(appsByCategory("Email")) },
        { key: "pdf",        title: "PDF Viewer",       icon: "picture_as_pdf",
          mimes: ["application/pdf"],
          candidates: () => uniqueApps(appsByMime("application/pdf").concat(appsByCategory("Office"))) },
        { key: "images",     title: "Image Viewer",     icon: "photo",
          mimes: ["image/jpeg", "image/png"],
          candidates: () => uniqueApps(appsByCategory("Graphics").concat(appsByCategory("Photography"))) },
        { key: "video",      title: "Video Player",     icon: "movie",
          mimes: ["video/mp4", "video/x-matroska"],
          candidates: () => uniqueApps(appsByCategory("Video").concat(appsByCategory("AudioVideo"))) },
        { key: "text",       title: "Text Editor",      icon: "edit",
          mimes: ["text/plain"],
          candidates: () => uniqueApps(appsByCategory("TextEditor").concat(appsByCategory("Development"))) },
        { key: "files",      title: "File Manager",     icon: "folder",
          mimes: ["inode/directory"],
          candidates: () => uniqueApps(appsByCategory("FileManager").concat(appsByCategory("Utilities"))) },
        { key: "terminal",   title: "Terminal Emulator", icon: "terminal",
          mimes: [],
          isTerminal: true,
          candidates: () => [] },
        { key: "aurhelper",  title: "AUR Helper",        icon: "",
          mimes: [],
          isAurHelper: true,
          candidates: () => [] }
    ]

    DarkFlickable {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingL
        clip: true
        contentHeight: mainColumn.height
        contentWidth: width

        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.spacingXL

            StyledRect {
                width: parent.width
                height: headerSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Column {
                    id: headerSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingM

                        DarkIcon {
                            name: "apps"
                            size: Theme.iconSize
                            color: Theme.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXS
                            Layout.alignment: Qt.AlignVCenter

                            StyledText {
                                text: "Default Applications"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: "Configure default applications for different file types and actions. Changes apply immediately."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            Repeater {
                model: root.defaultsModel

                StyledRect {
                    required property var modelData
                    width: parent.width
                    height: innerCol.implicitHeight + Theme.spacingL * 2
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                    border.width: 1

                    Column {
                        id: innerCol
                        anchors.fill: parent
                        anchors.margins: Theme.spacingL
                        spacing: Theme.spacingM

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            DarkIcon {
                                name: modelData.icon || "application-x-executable"
                                size: Theme.iconSize
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: parent.width - Theme.iconSize - Theme.spacingM
                                spacing: Theme.spacingXS
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    text: modelData.title
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                            }
                        }

                        Column {
                            id: appSelector
                            width: parent.width
                            spacing: Theme.spacingM

                            property var candidates: []
                            property string currentDesktopId: ""

                            function initCandidates() {
                                if (modelData.isTerminal) {
                                    candidates = (SettingsData.availableTerminals || []).map(function(term) {
                                        return { name: term, id: term, displayName: term }
                                    })
                                } else if (modelData.isAurHelper) {
                                    candidates = (SettingsData.availableAurHelpers || []).map(function(helper) {
                                        return { name: helper, id: helper, displayName: helper }
                                    })
                                } else {

                                    var mimeTypes = modelData.mimes || []
                                    var detectedApps = root.getAppsForMimeTypes(mimeTypes)


                                    if (detectedApps.length === 0 && modelData.candidates) {
                                        detectedApps = modelData.candidates() || []
                                    }

                                    candidates = root.uniqueApps(detectedApps)
                                }
                            }

                            function findAppById(desktopId) {
                                if (!desktopId) return null

                                var normalizedTarget = root.normalizeDesktopId(desktopId)


                                for (var i = 0; i < candidates.length; i++) {
                                    var app = candidates[i]
                                    if (!app) continue


                                    var idFields = [
                                        app.id,
                                        app.desktopId,
                                        app.filename,
                                        app.appId
                                    ]

                                    for (var f = 0; f < idFields.length; f++) {
                                        if (idFields[f] && root.desktopIdsMatch(idFields[f], desktopId)) {
                                            return app
                                        }
                                    }


                                    var appId = root.getAppId(app)
                                    if (root.desktopIdsMatch(appId, desktopId)) {
                                        return app
                                    }
                                }


                                for (var j = 0; j < root.allApps.length; j++) {
                                    var app = root.allApps[j]
                                    if (!app) continue


                                    var idFields = [
                                        app.id,
                                        app.desktopId,
                                        app.filename,
                                        app.appId
                                    ]

                                    for (var f = 0; f < idFields.length; f++) {
                                        if (idFields[f] && root.desktopIdsMatch(idFields[f], desktopId)) {
                                            return app
                                        }
                                    }


                                    var appId = root.getAppId(app)
                                    if (root.desktopIdsMatch(appId, desktopId)) {
                                        return app
                                    }
                                }


                                if (typeof DesktopEntries !== "undefined") {
                                    var entry = DesktopEntries.heuristicLookup(desktopId)
                                    if (entry) {

                                        return {
                                            id: entry.id || desktopId,
                                            desktopId: entry.id || desktopId,
                                            filename: entry.id || desktopId,
                                            name: entry.name,
                                            displayName: entry.name,
                                            icon: entry.icon,
                                            mimeTypes: entry.mimeTypes || []
                                        }
                                    }
                                }

                                return null
                            }

                            function ensureCurrentAppInCandidates() {
                                if (modelData.isTerminal || modelData.isAurHelper || !currentDesktopId) return


                                var found = false
                                for (var i = 0; i < candidates.length; i++) {
                                    var appId = root.getAppId(candidates[i])
                                    if (root.desktopIdsMatch(appId, currentDesktopId)) {
                                        found = true
                                        break
                                    }
                                }

                                if (!found) {

                                    var app = findAppById(currentDesktopId)
                                    if (app) {

                                        candidates = [app].concat(candidates)
                                    }
                                }


                                if (currentDisplayName && currentDisplayName !== "") {
                                    var nameFound = false
                                    for (var j = 0; j < optionNames.length; j++) {
                                        if (optionNames[j] === currentDisplayName) {
                                            nameFound = true
                                            break
                                        }
                                    }
                                    if (!nameFound && currentName) {

                                        Qt.callLater(function() {
                                            ensureCurrentAppInCandidates()
                                        })
                                    }
                                }
                            }
                            property var optionNames: (candidates || []).map(a => ((modelData.isTerminal || modelData.isAurHelper) ? a.name : root.displayName(a)))
                            property var optionIcons: (candidates || []).map(a => (modelData.isTerminal ? "terminal" : (modelData.isAurHelper ? "" : (a.icon || "application-x-executable"))))
                            property var nameToDesktopId: {
                                var _ = candidates.length // Dummy access to make this reactive
                                const m = {}
                                for (var i = 0; i < (candidates || []).length; i++) {
                                    var a = candidates[i]
                                    var id = ((modelData.isTerminal || modelData.isAurHelper) ? a.id : root.getAppId(a))
                                    var name = ((modelData.isTerminal || modelData.isAurHelper) ? a.name : root.displayName(a))
                                    m[name] = id
                                }
                                return m
                            }

                            property string currentName: {
                                if (modelData.isTerminal) {
                                    return SettingsData.terminalEmulator || ""
                                }
                                if (modelData.isAurHelper) {
                                    return SettingsData.aurHelper || ""
                                }


                                var app = findAppById(currentDesktopId)
                                if (app) {
                                    return root.displayName(app)
                                }


                                if (currentDesktopId && typeof DesktopEntries !== "undefined") {
                                    var entry = DesktopEntries.heuristicLookup(currentDesktopId)
                                    if (entry && entry.name) {
                                        return entry.name
                                    }
                                }


                                if (currentDesktopId) {
                                    var base = root.normalizeDesktopId(currentDesktopId)

                                    var parts = base.split('.')

                                    if (parts.length > 2) {

                                        var skipPrefixes = ["org", "com", "io", "net", "dev"]
                                        var meaningfulParts = parts.filter(function(p) {
                                            return p && !skipPrefixes.includes(p.toLowerCase())
                                        })
                                        if (meaningfulParts.length > 0) {

                                            var name = meaningfulParts[meaningfulParts.length - 1]
                                            return name.charAt(0).toUpperCase() + name.slice(1)
                                        }
                                    }

                                    return parts[parts.length - 1] || base
                                }

                                return ""
                            }

                            property string currentIcon: {
                                if (modelData.isTerminal) return "terminal"
                                if (modelData.isAurHelper) return ""

                                var app = findAppById(currentDesktopId)
                                if (app && app.icon) {
                                    return app.icon
                                }


                                if (currentDesktopId && typeof DesktopEntries !== "undefined") {
                                    var entry = DesktopEntries.heuristicLookup(currentDesktopId)
                                    if (entry && entry.icon) {
                                        return entry.icon
                                    }
                                }

                                return "application-x-executable"
                            }

                            property string currentDisplayName: {
                                return currentName
                            }

                            function refreshDefault() {
                                if (modelData.isTerminal) {
                                    currentDesktopId = SettingsData.terminalEmulator || ""
                                    return
                                }

                                if (modelData.isAurHelper) {
                                    currentDesktopId = SettingsData.aurHelper || ""
                                    return
                                }


                                var mime = (modelData.mimes || [])[0]
                                if (!mime) {
                                    currentDesktopId = ""
                                    return
                                }

                                root.queryDefault(mime, function(id) {
                                    currentDesktopId = id || ""
                                    ensureCurrentAppInCandidates()
                                })
                            }

                            Component.onCompleted: {
                                initCandidates()
                                refreshDefault()
                            }

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                            DarkDropdown {
                                id: dropdown
                                    width: Math.min(300, parent.width * 0.5)
                                text: ""
                                description: ""
                                    options: appSelector.optionNames || []
                                    optionIcons: appSelector.optionIcons || []
                                    currentValue: (appSelector.currentDisplayName && appSelector.currentDisplayName !== "") ? appSelector.currentDisplayName : ""
                                onValueChanged: (value) => {
                                        var desktopId = appSelector.nameToDesktopId[value] || ""
                                    if (!desktopId) return

                                    if (modelData.isTerminal) {
                                        SettingsData.terminalEmulator = desktopId
                                            appSelector.currentDesktopId = desktopId
                                    } else if (modelData.isAurHelper) {
                                        SettingsData.aurHelper = desktopId
                                            appSelector.currentDesktopId = desktopId
                                    } else {

                                        for (const mime of (modelData.mimes || [])) {
                                            root.setDefault(mime, desktopId)
                                        }


                                            appSelector.currentDesktopId = desktopId
                                            appSelector.ensureCurrentAppInCandidates()



                                        Qt.callLater(function() {
                                            Qt.callLater(function() {
                                                Qt.callLater(function() {
                                                        appSelector.refreshDefault()
                                                    })
                                                })
                                            })
                                    }
                                }
                            }

                            Row {
                                    id: currentAppRow
                                spacing: Theme.spacingS
                                anchors.verticalCenter: dropdown.verticalCenter

                                Image {
                                    width: 24
                                    height: 24
                                        source: "image://icon/" + (appSelector.currentIcon || "application-x-executable")
                                    sourceSize.width: 24
                                    sourceSize.height: 24
                                    fillMode: Image.PreserveAspectFit
                                        visible: appSelector.currentIcon && appSelector.currentIcon !== ""
                                        anchors.verticalCenter: parent.verticalCenter
                                }

                                    StyledText {
                                        text: appSelector.currentName || "Not set"
                                    font.pixelSize: Theme.fontSizeMedium
                                        color: appSelector.currentName ? Theme.surfaceText : Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter
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


