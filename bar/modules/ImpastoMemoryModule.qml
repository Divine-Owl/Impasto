import QtQuick
import "../../theme"
import "../../services"
import "../../components"

Item {
    id: root
    property bool compact: false
    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight
    Component.onCompleted: ImpastoMemoryService.subscribe()
    Component.onDestruction: ImpastoMemoryService.release()
    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: root.compact ? chip : detail
    }
    Component { id: chip
        Item {
            RingIndicator {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.capsuleHeight
                height: Theme.capsuleHeight
                thickness: 2.5
                progress: (ImpastoMemoryService.maxMB > 0 && ImpastoMemoryService.rssMB >= 0) ? ImpastoMemoryService.rssMB / ImpastoMemoryService.maxMB : 0
                trackColor: Theme.indicatorDim
                fillColor: Theme.indicator
                Text { anchors.centerIn: parent; text: "M"; color: Theme.indicator; font.family: Theme.fontMono; font.pixelSize: 12; font.weight: Font.Black }
            }
        }
    }
    Component { id: detail
        ModuleCard {
            title: "Impasto"
            subtitle: ImpastoMemoryService.pid > 0 ? "qs PID " + ImpastoMemoryService.pid : "stopped"
            mark: Text { anchors.centerIn: parent; text: "M"; color: Theme.indicator; font.family: Theme.fontMono; font.pixelSize: 18; font.weight: Font.Black }
            Text {
                width: parent.width
                text: (ImpastoMemoryService.maxMB > 0
                    ? (ImpastoMemoryService.rssMB / ImpastoMemoryService.maxMB * 100).toFixed(0) + " %  (" + ImpastoMemoryService.rssMB.toFixed(1) + " MB / " + ImpastoMemoryService.maxMB.toFixed(0) + " MB)"
                    : ImpastoMemoryService.rssMB.toFixed(1) + " MB")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textMuted
            }
        }
    }
}
