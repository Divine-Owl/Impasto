import Quickshell
import QtQuick
import "modules"

ShellRoot {
    id: root
    Variants {
        model: Quickshell.screens
        delegate: Component {
            TopBar {
                screen: Quickshell.screens[0]
            }
        }
    }
}
