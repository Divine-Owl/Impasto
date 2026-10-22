import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root
    visible: show
    property bool show: false

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 480
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "gnomebar-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0

    property string query: ""
    onShowChanged: {
        if (show) {
            searchField.forceActiveFocus()
            searchField.text = ""
            root.query = ""
        }
    }

    readonly property var desktopEntries: Quickshell.DesktopEntries
    readonly property var allApps: root.desktopEntries ? root.desktopEntries.applications : []
    readonly property var filtered: {
        const q = root.query.toLowerCase()
        var a = q === "" ? root.allApps.slice(0, 200) : root.allApps.filter(e => e.name.toLowerCase().includes(q) || (e.genericName || "").toLowerCase().includes(q)).slice(0, 200)
        return a
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        MouseArea { anchors.fill: parent; onClicked: root.show = false }
    }

    Rectangle {
        width: 640
        height: 420
        anchors.top: parent.top
        anchors.topMargin: 40
        anchors.left: parent.left
        anchors.leftMargin: 12
        radius: 16
        color: "#0D0D0D"
        border.color: "#525252"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                spacing: 8
                Text {
                    text: "search"
                    color: "#525252"
                    font.family: "Material Symbols Outlined"
                    font.pointSize: 18
                }
                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    color: "#E2DFD2"
                    font.pixelSize: 15
                    clip: true
                    onTextEdited: root.query = text
                    Keys.onReturnPressed: {
                        if (root.filtered.length > 0)
                            root.filtered[0].execute()
                        root.show = false
                    }
                    Keys.onEscapePressed: root.show = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#525252"
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: root.filtered
                currentIndex: 0
                onModelChanged: currentIndex = 0

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 40
                    radius: 8
                    color: (ListView.view.currentIndex === index) ? "#525252" : "#0D0D0D"
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10
                        Image {
                            source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                            width: 22
                            height: 22
                            visible: source !== ""
                        }
                        Text {
                            text: modelData.name
                            color: "#E2DFD2"
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: parent.ListView.view.currentIndex = parent.index
                        onClicked: {
                            parent.modelData.execute()
                            root.show = false
                        }
                    }
                }
            }
        }
    }
}
