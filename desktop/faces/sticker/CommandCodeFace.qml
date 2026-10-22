// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C   O   D   E   X       F   A   C   E                                  │
// │   the window left as a ring round the mark · sticker                     │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import "../../../theme"
import "../../../services"
import "../../../components"

// What is left of the fullest window as a ring round the mark, on a
// nine-lobed sticker; wide, the window and its reset on the tag.
Spread {
    id: face

    hue: face.ink.accent
    reading: !CommandCodeService.available ? "No usage found"
        : CommandCodeService.fullest ? `${CommandCodeService.figure} of the ${CommandCodeService.fullestName}`
        : "Nothing to read yet"
    note: !CommandCodeService.available ? "nothing to read"
        : CommandCodeService.fullest ? CommandCodeService.windowLine(CommandCodeService.fullest)
                + ((CommandCodeService.monthlyTotal > 0) ? ` · ${CommandCodeService.monthlyUsed.toFixed(1)}/${CommandCodeService.monthlyTotal.toFixed(1)} credits` : "")
        : "until Command Code runs again"

    Tone { id: tone; hue: face.ink.accent }

    Cut {
        id: plate

        anchors.fill: parent
        shape: "cookie"
        lobes: 9
        depth: 0.06
        seed: face.seed
        fill: tone.fill

        Ring {
            anchors.centerIn: parent
            width: plate.side * 0.66
            height: width
            thickness: plate.side * 0.075
            fraction: 1 - CommandCodeService.gauge
            color: CommandCodeService.gauge > 0.85 ? face.ink.red : tone.deep
            track: tone.track
        }

        Column {
            anchors.centerIn: parent
            spacing: plate.side * 0.02

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: plate.side * 0.14
                height: width
                color: tone.deep
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: CommandCodeService.figure
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(plate.side * 0.13)
                font.weight: Font.Bold
                color: tone.deep
            }
        }
    }
}
