pragma Singleton

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root
    readonly property int totalNodeCount: (Pipewire.nodes?.values || []).length

    signal applicationVolumeChanged
    signal applicationMuteChanged
    signal streamsChanged

    Component.onCompleted: {
        if (Pipewire.nodes) {
        }

        if (Pipewire.nodes) {
            Pipewire.nodes.valuesChanged.connect(() => {

                streamsChanged()
            })
        }
    }

    function isValidNode(node) {
        if (!node) return false


        if (!node.audio) return false


        try {

            if (node.isStream) {


                return true
            }

            if (!node.ready) return false


            return true
        } catch (e) {
            return false
        }
    }

    function isValidStreamNode(node) {
        if (!node) return false

        if (!node.audio) return false


        try {


            return node.isStream !== undefined
        } catch (e) {
            return false
        }
    }
    
    function isNodeReadyForVolumeControl(node) {
        if (!node || !node.audio) return false




        if (node.ready === false) {
            return false
        }


        return true
    }

    readonly property var applicationStreams: (Pipewire.nodes?.values || []).filter(node => {
        if (!isValidStreamNode(node)) return false
        try {
            const isStream = node.isStream && node.isSink
            if (isStream) {
            }
            return isStream
        } catch (e) {
            return false
        }
    })

    readonly property var applicationInputStreams: (Pipewire.nodes?.values || []).filter(node => {
        if (!isValidStreamNode(node)) return false
        try {
            const isStream = node.isStream && !node.isSink
            if (isStream) {
            }
            return isStream
        } catch (e) {
            return false
        }
    })

    readonly property var outputDevices: (Pipewire.nodes?.values || []).filter(node => {
        if (!isValidNode(node)) return false
        try {
            return !node.isStream && node.isSink
        } catch (e) {
            return false
        }
    })

    readonly property var inputDevices: (Pipewire.nodes?.values || []).filter(node => {
        if (!isValidNode(node)) return false
        try {
            return !node.isStream && !node.isSink
        } catch (e) {
            return false
        }
    })

    function getApplicationName(node) {
        if (!node) return "Unknown Application"
        const props = node.properties || {}
        const base = props["application.name"] || (node.description && node.description !== "" ? node.description : node.name)
        const media = props["media.name"]
        return media !== undefined && media !== "" ? `${base} - ${media}` : base || "Unknown Application"
    }

    function getApplicationIconName(node) {
        if (!node) return ""
        const props = node.properties || {}
        let preferred = props["application.icon-name"] || props["node.name"] || props["application.name"] || ""
        const blacklist = [
            "speech-dispatcher-dummy",
        ]
        if (blacklist.indexOf(preferred) !== -1) return ""
        return preferred
    }

    function getApplicationIcon(node) {

        return getApplicationIconName(node)
    }

    function isNodeBound(node) {
        return isNodeReadyForVolumeControl(node)
    }

    function setApplicationVolume(node, percentage) {
        if (!node || !node.audio) {
            return "No audio stream available"
        }
        
        if (node.ready === false) {
            return "Node not ready"
        }

        try {
            const clampedVolume = Math.max(0, Math.min(100, percentage))
            const volumeValue = clampedVolume / 100
            node.audio.volume = volumeValue
            root.applicationVolumeChanged()
            return `Volume set to ${clampedVolume}%`
        } catch (e) {
            return "Failed to set volume"
        }
    }

    function toggleApplicationMute(node) {
        if (!node || !node.audio) {
            return "No audio stream available"
        }
        
        if (!isNodeBound(node)) {
            return "Node not ready"
        }

        try {
            node.audio.muted = !node.audio.muted
            root.applicationMuteChanged()
            return node.audio.muted ? "Application muted" : "Application unmuted"
        } catch (e) {
            return "Failed to toggle mute"
        }
    }

    function setApplicationInputVolume(node, percentage) {
        if (!node || !node.audio) {
            return "No audio input stream available"
        }
        
        if (!isNodeBound(node)) {
            return "Node not ready"
        }

        try {
            const clampedVolume = Math.max(0, Math.min(100, percentage))
            node.audio.volume = clampedVolume / 100
            root.applicationVolumeChanged()
            return `Input volume set to ${clampedVolume}%`
        } catch (e) {
            return "Failed to set input volume"
        }
    }

    function toggleApplicationInputMute(node) {
        if (!node || !node.audio) {
            return "No audio input stream available"
        }
        
        if (!isNodeBound(node)) {
            return "Node not ready"
        }

        try {
            node.audio.muted = !node.audio.muted
            root.applicationMuteChanged()
            return node.audio.muted ? "Application input muted" : "Application input unmuted"
        } catch (e) {
            return "Failed to toggle input mute"
        }
    }

    function routeStreamToOutput(streamNode, targetSinkNode) {
        if (!streamNode || !targetSinkNode) {
            return "Invalid stream or target device"
        }
        if (!streamNode.isStream || !streamNode.isSink) {
            return "Not an output stream"
        }
        if (targetSinkNode.isStream || !targetSinkNode.isSink) {
            return "Not a valid output device"
        }
        
        try {
            const streamId = streamNode.id
            const sinkId = targetSinkNode.id
            
            if (!streamId || !sinkId) {
                return "Invalid stream or sink ID"
            }
            
            




            const connectCmd = ["pw-link", streamId.toString(), sinkId.toString()]
            

            const connectProcess = connectProcessComponent.createObject(root, {
                streamId: streamId,
                sinkId: sinkId,
                deviceName: targetSinkNode.description || targetSinkNode.name,
                callback: function() {
                    root.applicationVolumeChanged()
                }
            })
            
            return "Routing stream..."
        } catch (e) {
            return "Failed to route stream: " + e
        }
    }
    
    Component {
        id: connectProcessComponent
        Process {
            property int streamId
            property int sinkId
            property string deviceName
            property var callback
            
            command: ["pw-link", streamId.toString(), sinkId.toString()]
            
            Component.onCompleted: {
                running = true
            }
            
            onExited: function(exitCode) {
                if (exitCode === 0) {
                    if (callback) callback()
                } else {

                    const altProcess = connectProcessAltComponent.createObject(root, {
                        streamId: streamId,
                        sinkId: sinkId,
                        deviceName: deviceName,
                        callback: callback
                    })
                }
                destroy()
            }
        }
    }
    
    Component {
        id: connectProcessAltComponent
        Process {
            property int streamId
            property int sinkId
            property string deviceName
            property var callback
            

            command: ["pw-link", streamId.toString() + ":output_FL", sinkId.toString() + ":input_FL"]
            
            Component.onCompleted: {
                running = true
            }
            
            onExited: function(exitCode) {
                if (exitCode === 0 && callback) {
                    callback()
                } else {
                }
                destroy()
            }
        }
    }

    function routeStreamToInput(streamNode, targetSourceNode) {
        if (!streamNode || !targetSourceNode) {
            return "Invalid stream or target device"
        }
        if (!streamNode.isStream || streamNode.isSink) {
            return "Not an input stream"
        }
        if (targetSourceNode.isStream || targetSourceNode.isSink) {
            return "Not a valid input device"
        }
        
        try {
            const streamId = streamNode.id
            const sourceId = targetSourceNode.id
            
            if (!streamId || !sourceId) {
                return "Invalid stream or source ID"
            }
            
            



            const connectCmd = ["pw-link", sourceId.toString(), streamId.toString()]
            
            const connectProcess = connectInputProcessComponent.createObject(root, {
                streamId: streamId,
                sourceId: sourceId,
                deviceName: targetSourceNode.description || targetSourceNode.name,
                callback: function() {
                    root.applicationVolumeChanged()
                }
            })
            
            return "Routing input stream..."
        } catch (e) {
            return "Failed to route stream: " + e
        }
    }
    
    Component {
        id: connectInputProcessComponent
        Process {
            property int streamId
            property int sourceId
            property string deviceName
            property var callback
            
            command: ["pw-link", sourceId.toString(), streamId.toString()]
            
            Component.onCompleted: {
                running = true
            }
            
            onExited: function(exitCode) {
                if (exitCode === 0) {
                    if (callback) callback()
                } else {

                    const altProcess = connectInputProcessAltComponent.createObject(root, {
                        streamId: streamId,
                        sourceId: sourceId,
                        deviceName: deviceName,
                        callback: callback
                    })
                }
                destroy()
            }
        }
    }
    
    Component {
        id: connectInputProcessAltComponent
        Process {
            property int streamId
            property int sourceId
            property string deviceName
            property var callback
            
            command: ["pw-link", sourceId.toString() + ":output_FL", streamId.toString() + ":input_FL"]
            
            Component.onCompleted: {
                running = true
            }
            
            onExited: function(exitCode) {
                if (exitCode === 0 && callback) {
                    callback()
                } else {
                }
                destroy()
            }
        }
    }

    function getCurrentOutputDevice(streamNode) {
        if (!streamNode || !streamNode.isStream || !streamNode.isSink) {
            return null
        }



        return AudioService.sink
    }

    function getCurrentInputDevice(streamNode) {
        if (!streamNode || !streamNode.isStream || streamNode.isSink) {
            return null
        }

        return AudioService.source
    }


    function getTrackableNodes() {
        if (!Pipewire.nodes?.values) return []
        const nodes = []
        for (let i = 0; i < Pipewire.nodes.values.length; i++) {
            const node = Pipewire.nodes.values[i]
            if (!node) continue


            if (node.ready && node.audio) {
                try {

                    if (node.properties !== undefined && node.name !== undefined) {
                        nodes.push(node)
                    }
                } catch (e) {

                }
            }
        }
        return nodes
    }

    PwObjectTracker { 
        objects: root.getTrackableNodes()
        Component.onCompleted: {
        }
    }

    function debugAllNodes() {
        if (!Pipewire.ready || !Pipewire.nodes?.values) {
            return
        }
    }
}
