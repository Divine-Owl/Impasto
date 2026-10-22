import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "../../components"

Item {
    id: root
    property bool compact: false

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Component.onCompleted: OpenRouterService.subscribe()
    Component.onDestruction: OpenRouterService.release()

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
                progress: (OpenRouterService.freeModelDailyLimit > 0)
                    ? OpenRouterService.freeModelDailyUsed / OpenRouterService.freeModelDailyLimit
                    : 0
                trackColor: Theme.indicatorDim
                fillColor: OpenRouterService.tint

                Image {
                    anchors.centerIn: parent
                    source: Quickshell.shellPath("icons/openrouter-glyph.svg")
                    fillMode: Image.PreserveAspectFit
                onStatusChanged: console.log(source, status)
                }
            }
        }
    }

    Component {
        id: detail

        ModuleCard {
            title: "OpenRouter"
            subtitle: OpenRouterService.freeTier ? "Free" : "Paid"

            mark: RingIndicator {
                anchors.fill: parent
                thickness: 3
                progress: (OpenRouterService.freeModelDailyLimit > 0)
                    ? OpenRouterService.freeModelDailyUsed / OpenRouterService.freeModelDailyLimit
                    : 0
                trackColor: Theme.indicatorDim
                fillColor: OpenRouterService.tint

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: Quickshell.shellPath("icons/openrouter-glyph.svg")
                    fillMode: Image.PreserveAspectFit
                }
            }

            CardLimit {
                name: "Daily"
                fraction: (OpenRouterService.freeModelDailyLimit > 0)
                    ? OpenRouterService.freeModelDailyUsed / OpenRouterService.freeModelDailyLimit
                    : 0
                known: OpenRouterService.freeModelDailyLimit > 0
                resets: OpenRouterService.nextResetAt.getTime() / 1000
                tint: OpenRouterService.tint
            }
            Text {
                width: parent.width
                text: "resets at " + Qt.formatDateTime(OpenRouterService.nextResetAt, "HH:mm")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                color: Theme.textMuted
            }

        }
    }
}
