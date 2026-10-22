// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C   O   D   E   X       F   A   C   E                                  │
// │   command code usage as a fuel gauge                                            │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import "../../../theme"
import "../../../services"
import "../../../components"

// Codex usage as a fuel gauge: F with the fullest window untouched, E when it
// is spent, red at the empty end. Wide, the window it reads and its reset.
Instrument {
    id: face

    line: !CommandCodeService.available ? "No usage found"
        : CommandCodeService.fullest ? `${CommandCodeService.figure} of the ${CommandCodeService.fullestName}`
        : "Nothing to read until Codex runs"
    reading: CommandCodeService.figure
    note: !CommandCodeService.available ? "no usage found"
        : CommandCodeService.fullest ? CommandCodeService.windowLine(CommandCodeService.fullest)
                + ((CommandCodeService.monthlyTotal > 0) ? ` · ${CommandCodeService.monthlyUsed.toFixed(1)}/${CommandCodeService.monthlyTotal.toFixed(1)} credits` : "")
        : "until Command Code runs again"
    filled: true

    Gauge {
        anchors.centerIn: parent
        ink: face.ink
        size: Math.min(parent.width, parent.height)
        fraction: 1 - CommandCodeService.gauge
        lowIsBad: true
        ends: ["E", "F"]

        Text {
            x: (parent.width - width) / 2
            y: parent.height * 0.28
            width: 22
            height: 22
            color: face.ink.text
            text: "CC"
            font.family: Theme.fontMono
            font.pixelSize: 22
            font.weight: Font.Black
        }
    }

    extra: [
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 4

            UsageBar {
                width: parent.width
                progress: CommandCodeService.gauge
                fillColor: face.ink.accent
                trackColor: face.ink.raised
            }

            Text {
                text: [CommandCodeService.plan, CommandCodeService.age].filter(part => part !== "").join(" · ")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                color: face.ink.muted
            }
        }
    ]
}
