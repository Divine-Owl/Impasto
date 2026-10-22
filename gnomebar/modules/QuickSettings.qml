import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Controls.Basic as QtControls
import qs.services

PanelWindow {
    id: root

    property bool show: false
    visible: show
    required property var screen
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitWidth: 320
    implicitHeight: 420
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "gnomebar-quicksettings"
    exclusiveZone: 0

    readonly property var brightMonitor: Brightness.getMonitorForScreen(root.screen)
    property int batteryLevel: -1
    property bool nightLightOn: false

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

    Timer { interval: 10000; running: true; repeat: true; onTriggered: batteryProc.running = true }
    Component.onCompleted: batteryProc.running = true

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#0D0D0D"
        border.color: "#525252"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Item {
                Layout.preferredHeight: 48
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 8
                Text {
                    text: "Quick Settings"
                    color: "#E2DFD2"
                    font.bold: true
                    font.pixelSize: 16
                    Layout.fillWidth: true
                }
                Text {
                    text: root.batteryLevel >= 0 ? "BAT " + root.batteryLevel + "%" : "BAT"
                    color: "#525252"
                    font.pixelSize: 12
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#525252" }

            // Toggles
            RowLayout {
                spacing: 6
                Repeater {
                    model: ["Wi-Fi", "Bluetooth"]
                    delegate: Rectangle {
                        required property string modelData
                        Layout.fillWidth: true
                        height: 34
                        radius: 17
                        color: "#525252"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: "#E2DFD2"
                            font.pixelSize: 12
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData === "Wi-Fi")
                                    Quickshell.execDetached(["sh", "-c", "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"])
                                else
                                    Quickshell.execDetached(["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"])
                            }
                        }
                    }
                }
            }

            // Volume
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Volume"; color: "#E2DFD2"; font.pixelSize: 13; Layout.fillWidth: true }
                    Text { text: Math.round(Audio.volume * 100) + "%"; color: "#525252"; font.pixelSize: 12 }
                }
                QtControls.Slider {
                    id: volSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: Audio.volume
                    onMoved: Audio.setVolume(value)
                }
            }

            // Brightness
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Brightness"; color: "#E2DFD2"; font.pixelSize: 13; Layout.fillWidth: true }
                    Text { text: root.brightMonitor ? Math.round(root.brightMonitor.brightness * 100) + "%" : "N/A"; color: "#525252"; font.pixelSize: 12 }
                }
                QtControls.Slider {
                    id: brightSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: root.brightMonitor ? root.brightMonitor.brightness : 0
                    onMoved: if (root.brightMonitor) root.brightMonitor.setBrightness(value)
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#525252" }

            // Media-ish / extras (placeholder for lunar)
            RowLayout {
                spacing: 6
                Layout.fillWidth: true
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    color: "#525252"
                    Text { anchors.centerIn: parent; text: "Idle Inhibitor"; color: "#E2DFD2"; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["sh", "-c", "systemd-inhibit --what=idle --who=gnomebar --why=manual sleep 1h || true"]) }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    color: "#525252"
                    Text { anchors.centerIn: parent; text: "Night Light"; color: "#E2DFD2"; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["sh", "-c", "if pgrep -x gammastep >/dev/null; then pkill -x gammastep; else gammastep -O 3500; fi"]) }
                }
            }
        }
    }
}
