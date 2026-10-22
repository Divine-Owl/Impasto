// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C O D E X   M O D U L E                                                │
// │   codex usage · the plan's limits, from its own logs                     │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../../theme"
import "../../services"
import "../../components"

// Each window the plan limits, as CommandCode last wrote it down; the ring is the
// fullest one still running. A window past its reset shows no share until
// CommandCode runs again.
Item {
    id: root

    property bool compact: false

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Component.onCompleted: CommandCodeService.subscribe()
    Component.onDestruction: CommandCodeService.release()

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: root.compact ? chip : detail
    }

    Component {
        id: chip

        Item {
            RingIndicator {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.capsuleHeight
                height: Theme.capsuleHeight
                thickness: 2.5
                progress: CommandCodeService.gauge
                trackColor: Theme.indicatorDim
                fillColor: CommandCodeService.tint

                Image {
                    anchors.centerIn: parent
                    width: Math.round(Theme.capsuleHeight * 0.7)
                    height: Math.round(Theme.capsuleHeight * 0.7)
                    source: Quickshell.shellPath("icons/commandcode-symbol.svg")
                    fillMode: Image.PreserveAspectFit
                onStatusChanged: console.log(source, status)
                }
            }
        }
    }

    Component {
        id: detail

        ModuleCard {
            title: "CommandCode"
            subtitle: [CommandCodeService.plan, CommandCodeService.age].filter(part => part !== "").join(" · ")

            mark: RingIndicator {
                anchors.fill: parent
                thickness: 3
                progress: CommandCodeService.gauge
                trackColor: Theme.indicatorDim
                fillColor: CommandCodeService.tint

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: Quickshell.shellPath("icons/commandcode-symbol.svg")
                    fillMode: Image.PreserveAspectFit
                }
            }

            Repeater {
                model: CommandCodeService.limits

                CardLimit {
                    required property var modelData

                    readonly property bool running: CommandCodeService.current(modelData)

                    name: modelData.name
                    fraction: modelData.used
                    known: running
                    resets: modelData.resets
                    tint: modelData.used >= 0.85 ? Theme.indicatorBad
                        : modelData.used >= 0.6 ? Theme.indicatorWarn : Theme.indicator
                }
            }

            Text {
                width: parent.width
                text: (CommandCodeService.monthlyTotal > 0)
                    ? `${CommandCodeService.monthlyUsed.toFixed(1)} / ${CommandCodeService.monthlyTotal.toFixed(1)} credits`
                        + (CommandCodeService.monthlyRequests > 0 ? ` · ${CommandCodeService.monthlyRequests} req` : "")
                        + (CommandCodeService.monthlyTokens > 0 ? ` · ${(CommandCodeService.monthlyTokens / 1e6).toFixed(1)}M tok` : "")
                    : ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textMuted
                visible: text !== ""
            }

        }
    }
}
