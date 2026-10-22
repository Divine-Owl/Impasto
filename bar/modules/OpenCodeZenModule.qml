import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "../../components"

// OpenCode Zen's free-model usage, read from OpenCode's local statistics. The
// chip carries today's request count; the card lists the free models used
// today, most used first.
Item {
    id: root

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Component.onCompleted: OpenCodeZenService.subscribe()
    Component.onDestruction: OpenCodeZenService.release()

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    Component {
        id: detail

        ModuleCard {
            title: "OpenCode Zen"
            subtitle: OpenCodeZenService.available ? "Free" : "Unavailable"
            figure: OpenCodeZenService.available ? `${OpenCodeZenService.requests}` : "—"

            mark: Image {
                anchors.centerIn: parent
                width: 20
                height: 20
                source: Quickshell.shellPath("icons/opencode-symbol.svg")
                fillMode: Image.PreserveAspectFit
            }

            Repeater {
                model: OpenCodeZenService.models.slice(0, 3)

                CardFact {
                    required property var modelData

                    name: OpenCodeZenService.displayName(modelData.id)
                    value: `${modelData.steps}`
                }
            }

            Text {
                width: parent.width
                text: {
                    if (!OpenCodeZenService.available)
                        return "reading OpenCode"
                    if (OpenCodeZenService.models.length === 0)
                        return "no free-model requests today"
                    const parts = []
                    const more = OpenCodeZenService.models.length - 3
                    if (more > 0)
                        parts.push(`and ${more} more`)
                    if (OpenCodeZenService.age !== "")
                        parts.push(OpenCodeZenService.age)
                    return parts.length > 0 ? parts.join(" · ") : "today"
                }
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                color: Theme.textMuted
            }
        }
    }
}
