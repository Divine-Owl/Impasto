// OpenRouter usage
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

Singleton {
    id: root

    readonly property int pollInterval: 1800000

    property int watchers: 0
    property bool available: false
    property string label: ""
    property real usage: 0
    property real daily: 0
    property real weekly: 0
    property real monthly: 0
    property real byokMonthly: 0
    property bool activityAvailable: false
    property string activityDate: ""
    property int activityRequests: 0
    property int activityPromptTokens: 0
    property int activityCompletionTokens: 0
    property int activityReasoningTokens: 0
    property real activitySpend: 0
    property var activityModels: []
    property int freeModelDailyUsed: 0
    property int freeModelDailyLimit: 0
    property real limit: -1
    property real limitRemaining: -1
    property bool freeTier: false

    readonly property SystemClock clock: SystemClock {
        precision: SystemClock.Minutes
        enabled: true
    }

    readonly property date nextResetAt: {
        const ms = root.clock.date.getTime()
        const utcMidnight = Date.UTC(root.clock.date.getUTCFullYear(),
                                    root.clock.date.getUTCMonth(),
                                    root.clock.date.getUTCDate())
        const msTomorrow = utcMidnight + 86400000
        return new Date((ms >= utcMidnight) ? msTomorrow : utcMidnight)
    }

    readonly property double resetRemainingMs: root.nextResetAt.getTime() - root.clock.date.getTime()

    readonly property color tint: (root.freeModelDailyUsed >= root.freeModelDailyLimit)
        ? Theme.indicatorBad
        : (root.freeModelDailyUsed >= root.freeModelDailyLimit * 0.6
           ? Theme.indicatorWarn
           : Theme.indicator)

    function formatCountdown(ms: var): string {
        const left = Math.max(0, Number(ms))
        const hours = Math.floor(left / 3600000)
        const mins = Math.floor((left % 3600000) / 60000)
        if (left >= 3600000)
            return "resets in " + hours + "h " + mins + "m"
        if (left >= 600000)
            return "resets in " + mins + " min"
        return "resets in " + Math.max(1, Math.ceil(left / 60000)) + " min"
    }

    function money(x: var): string {
        if (x === null || x === undefined)
            return "—"
        return `$${Number(x).toFixed(2)}`
    }

    Component.onCompleted: root.refresh()

    function subscribe(): void {
        root.watchers += 1
        root.refresh()
    }
    function release(): void {
        root.watchers = Math.max(0, root.watchers - 1)
    }
    function refresh(): void {
        // Skip paid quota refresh when free daily quota is already exhausted
        // and the quota reset itself has not yet occurred.
        if (root.available && root.freeModelDailyLimit > 0
            && root.freeModelDailyUsed >= root.freeModelDailyLimit
            && root.resetRemainingMs > 0)
            return
        root.query.running = true
    }

    readonly property Process query: Process {
        command: [Quickshell.shellPath("scripts/openrouter_usage.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                let report = null
                try {
                    report = JSON.parse(text)
                } catch (error) {
                    console.warn("Cannot parse OpenRouter usage report:", error)
                    return
                }
                root.available = report.available === true
                if (!root.available)
                    return
                root.label = report.label ?? ""
                root.usage = report.usage ?? 0
                root.daily = report.daily ?? 0
                root.weekly = report.weekly ?? 0
                root.monthly = report.monthly ?? 0
                root.byokMonthly = report.byokMonthly ?? 0
                root.limit = report.limit === null ? -1 : (report.limit ?? -1)
                root.limitRemaining = report.limitRemaining === null ? -1 : (report.limitRemaining ?? -1)
                root.freeTier = report.freeTier === true
                root.freeModelDailyUsed = report.freeModelDailyUsed ?? 0
                root.freeModelDailyLimit = report.freeModelDailyLimit ?? 0
                root.activityDate = report.activityDate ?? ""
                root.activityRequests = report.activityRequests ?? 0
                root.activityPromptTokens = report.activityPromptTokens ?? 0
                root.activityCompletionTokens = report.activityCompletionTokens ?? 0
                root.activityReasoningTokens = report.activityReasoningTokens ?? 0
                root.activitySpend = report.activityUsageDollars ?? 0
                root.activityModels = report.activityModels ?? []
                root.activityAvailable = (root.activityRequests > 0)
            }
        }
    }
    readonly property Timer poller: Timer {
        interval: root.resetIntervalMs()
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    function resetIntervalMs(): double {
        const left = root.resetRemainingMs
        if (left <= 600000)
            return 60000
        if (left <= 3600000)
            return 600000
        return 3600000
    }
}
