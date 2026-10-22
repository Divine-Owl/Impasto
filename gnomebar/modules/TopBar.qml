import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.services

PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: 48
    exclusiveZone: 48
    color: "#0D0D0D"
    WlrLayershell.namespace: "gnomebar"

    property bool powerShown: false
    property bool launcherShown: false
    property bool settingsShown: false
    property int batteryLevel: -1

    Process {
        id: batteryProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || cat /sys/class/power_supply/BAT1/capacity 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var n = parseInt(text.trim())
                if (!isNaN(n))
                    root.batteryLevel = n
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: batteryProc.running = true
    }

    Component.onCompleted: batteryProc.running = true

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        // --- Left: Activities + active window + workspaces ---
        Repeater {
            model: 5
            delegate: Rectangle {
                readonly property int wsId: index + 1
                readonly property bool active: wsId === Hypr.activeWsId
                width: 22
                height: 22
                radius: 11
                color: active ? "#E2DFD2" : "#525252"
                Layout.alignment: Qt.AlignVCenter
                Text {
                    anchors.centerIn: parent
                    visible: parent.active
                    text: parent.wsId
                    color: "#0D0D0D"
                    font.pixelSize: 16
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Hypr.focusWorkspace(parent.wsId)
                }
            }
        }

        Item { Layout.preferredWidth: 8 }

        Rectangle {
            radius: 16
            color: launchMa.containsMouse ? "#525252" : "#0D0D0D"
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Text {
                anchors.centerIn: parent
                text: "search"
                color: "#E2DFD2"
                font.family: "Material Symbols Outlined"
                font.pointSize: 16
            }
            MouseArea {
                id: launchMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.launcherShown = !root.launcherShown
            }
        }

        Item { Layout.fillWidth: true }

        // --- Center: clock (one line, hh:mm + AM/PM | ddd MMM d) ---
        Text {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            text: {
                const ap = Time.amPmStr ? " " + Time.amPmStr.toUpperCase() : ""
                return Time.hourStr + ":" + Time.minuteStr + ap + " | " + Time.format("ddd MMM d")
            }
            color: "#E2DFD2"
            font.bold: true
            font.pixelSize: 16

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.settingsShown = !root.settingsShown
            }
        }

        Item { Layout.fillWidth: true }

        // --- Power button (just before status) ---
        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: powerMa.containsMouse ? "#525252" : "#0D0D0D"
            border.color: "#525252"
            border.width: 1
            Layout.alignment: Qt.AlignVCenter
            Text {
                anchors.centerIn: parent
                text: "⏻"
                color: "#E2DFD2"
                font.pixelSize: 16
            }
            MouseArea {
                id: powerMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.powerShown = !root.powerShown
            }
        }

        // --- Right: status ---
        Row {
            spacing: 10
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: (Nmcli.active ? Nmcli.active.ssid : "NET")
                color: "#E2DFD2"
                font.pixelSize: 16
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.preferredWidth: 180
            }
            Text {
                text: "BT"
                color: "#525252"
                font.pixelSize: 16
            }
            Text {
                text: root.batteryLevel >= 0 ? "BAT " + root.batteryLevel + "%" : "BAT"
                color: "#E2DFD2"
                font.pixelSize: 16
            }
            Text {
                text: "VOL " + Math.round(Audio.volume * 100) + "%"
                color: "#E2DFD2"
                font.pixelSize: 16
            }
        }
    }

    PowerMenu {
        show: root.powerShown
    }

    Launcher {
        show: root.launcherShown
    }

    QuickSettings {
        show: root.settingsShown
        screen: root.screen
    }
}
