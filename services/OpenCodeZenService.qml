// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   O P E N C O D E   Z E N   S E R V I C E                                │
// │   today's free-model requests, as OpenCode last recorded them            │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

// Read from OpenCode's own session database (`opencode_zen_usage.py`). Nothing
// is asked of the network: the figures are as old as the last request this
// machine made, and only free models on the `opencode` provider are counted.
Singleton {
    id: root

    readonly property int pollInterval: 300000

    property int watchers: 0
    property bool available: false
    // Today's total free-model requests.
    property int requests: 0
    // `[{ id, steps }]`, most used first.
    property var models: []
    // Epoch seconds of the last successful read.
    property real updated: 0
    // True when the report came from the cache rather than a fresh read.
    property bool stale: false

    // Query once on construction, as `CommandCodeService` does: the module is
    // offered only once `available` is true.
    Component.onCompleted: root.refresh()

    readonly property SystemClock clock: SystemClock {
        precision: SystemClock.Minutes
        enabled: root.watchers > 0
    }

    // "updated just now", "updated 5 min ago", "updated Mon 14:20".
    readonly property string age: {
        if (root.updated <= 0)
            return ""
        const minutes = Math.floor((root.clock.date.getTime() - root.updated * 1000) / 60000)
        if (minutes < 1)
            return "updated just now"
        if (minutes < 60)
            return `updated ${minutes} min ago`
        if (minutes < 24 * 60)
            return `updated ${Math.floor(minutes / 60)} h ago`
        return `updated ${Qt.formatDateTime(new Date(root.updated * 1000), "ddd d MMM")}`
    }

    // "deepseek-v4.1-flash-free" -> "deepseek v4.1 flash"; the card is already
    // headed "Free", so the suffix is noise.
    function displayName(id: string): string {
        return String(id)
            .replace(/^opencode\//, "")
            .replace(/-free$/, "")
            .replace(/-/g, " ")
    }

    function subscribe(): void {
        root.watchers += 1
        root.refresh()
    }

    function release(): void {
        root.watchers = Math.max(0, root.watchers - 1)
    }

    function refresh(): void {
        if (!root.query.running)
            root.query.running = true
    }

    readonly property Timer poller: Timer {
        interval: root.pollInterval
        repeat: true
        running: root.watchers > 0
        onTriggered: root.refresh()
    }

    readonly property Process query: Process {
        command: [Quickshell.shellPath("scripts/opencode_zen_usage.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                let report = null
                try {
                    report = JSON.parse(text)
                } catch (error) {
                    console.warn("Cannot parse the OpenCode Zen usage report:", error)
                    return
                }
                root.available = report.available === true
                if (!root.available)
                    return
                root.requests = report.requests ?? 0
                root.models = report.models ?? []
                root.updated = report.updated ?? 0
                root.stale = report.stale === true
            }
        }
    }
}
