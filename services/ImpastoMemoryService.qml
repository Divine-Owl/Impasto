pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

Singleton {
    id: root
    property int watchers: 0
    property bool available: false
    property int pid: 0
    property int rssKB: 0
    property int maxKB: 0
    property real rssMB: 0
    property real maxMB: 0
    Component.onCompleted: refresh()
    function subscribe(): void { root.watchers += 1; refresh() }
    function release(): void { root.watchers = Math.max(0, root.watchers - 1) }
    function refresh(): void { root.query.running = true }
    readonly property Process query: Process {
        command: [Quickshell.shellPath("scripts/impasto_memory.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                let r = null
                try { r = JSON.parse(text) } catch(e) { console.warn("impasto memory parse:", e); return }
                root.available = r.available === true
                if (!root.available) return
                root.pid = r.pid ?? 0
                root.rssKB = r.rssKB ?? 0
                root.rssMB = r.rssMB ?? 0
                root.maxKB = r.maxKB ?? 0
                root.maxMB = r.maxMB ?? 0
            }
        }
    }
    readonly property Timer poller: Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: refresh()
    }
}
