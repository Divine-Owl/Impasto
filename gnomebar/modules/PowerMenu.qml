import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

PanelWindow {
    id: root
    property bool show: false
    visible: show
    anchors.top: true
    anchors.right: true
    implicitWidth: 190
    implicitHeight: 290
    color: "transparent"
    WlrLayershell.namespace: "gnomebar-power"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0

    onShowChanged: if (show) focusScope.forceActiveFocus()

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 36
        width: 190
        height: 250
        radius: 12
        color: "#0D0D0D"
        border.color: "#525252"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text {
                text: "Power"
                color: "#E2DFD2"
                font.bold: true
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter
            }

            Repeater {
                model: [
                    { label: "Lock", cmd: "exec swaylock" },
                    { label: "Suspend", cmd: "exec loginctl suspend" },
                    { label: "Reboot", cmd: "exec loginctl reboot" },
                    { label: "Shutdown", cmd: "exec loginctl poweroff" },
                    { label: "Logout", cmd: "exit" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 38
                    radius: 8
                    color: btnMa.containsMouse ? "#525252" : "#0D0D0D"
                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: "#E2DFD2"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: btnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            Hypr.dispatch(parent.modelData.cmd)
                            root.show = false
                        }
                    }
                }
            }
        }
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        Keys.onEscapePressed: root.show = false
    }
}
