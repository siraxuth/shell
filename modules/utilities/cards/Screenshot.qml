pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils

StyledRect {
    id: root

    required property var props
    required property DrawerVisibilities visibilities

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer

    function takeScreenshot(mode) {
        if (mode === "screen") {
            Quickshell.execDetached(["/home/siraxuth/.local/bin/caelestia-screenshot", "screen"])
            root.visibilities.utilities = false
            root.visibilities.sidebar = false
        } else if (mode === "active") {
            Quickshell.execDetached(["/home/siraxuth/.local/bin/caelestia-screenshot", "active"])
            root.visibilities.utilities = false
            root.visibilities.sidebar = false
        } else if (mode === "region") {
            root.visibilities.utilities = false
            root.visibilities.sidebar = false
            Quickshell.execDetached(["bash", "-c", "sleep 0.5 && caelestia shell picker openFreeze"])
        } else if (mode === "clip") {
            root.visibilities.utilities = false
            root.visibilities.sidebar = false
            Quickshell.execDetached(["bash", "-c", "sleep 0.5 && caelestia shell picker openFreezeClip"])
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        RowLayout {
            spacing: Appearance.spacing.normal

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: {
                    const h = icon.implicitHeight + Appearance.padding.smaller * 2
                    return h - (h % 2)
                }
                radius: Appearance.rounding.full
                color: Colours.palette.m3secondaryContainer

                MaterialIcon {
                    id: icon
                    anchors.centerIn: parent
                    text: "screenshot"
                    color: Colours.palette.m3onSecondaryContainer
                    font.pointSize: Appearance.font.size.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Screenshot")
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Saved to ~/Pictures/Screenshots")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }
            }

            IconButton {
                icon: "fullscreen"
                type: IconButton.Tonal
                font.pointSize: Appearance.font.size.large
                onClicked: root.takeScreenshot("screen")
            }

            IconButton {
                icon: "screenshot_region"
                type: IconButton.Tonal
                font.pointSize: Appearance.font.size.large
                onClicked: root.takeScreenshot("region")
            }

            IconButton {
                icon: "web_asset"
                type: IconButton.Tonal
                font.pointSize: Appearance.font.size.large
                onClicked: root.takeScreenshot("active")
            }

            IconButton {
                icon: "content_copy"
                type: IconButton.Tonal
                font.pointSize: Appearance.font.size.large
                onClicked: root.takeScreenshot("clip")
            }
        }

        ScreenshotList {
            Layout.fillWidth: true
            props: root.props
            visibilities: root.visibilities
        }
    }
}
