import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.config

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    function triggerAction(): void {
        const action = root.modelData?.action ?? "";
        if (action === "change") {
            root.list.search.text = Config.launcher.actionPrefix + "live wallpaper ";
        } else if (action === "stop") {
            root.list.visibilities.launcher = false;
            Quickshell.execDetached(["/home/siraxuth/.local/bin/live-wallpaper.sh", "stop"]);
        } else if (action === "pause") {
            root.list.visibilities.launcher = false;
            Quickshell.execDetached(["bash", "-c", "pkill -STOP mpvpaper"]);
        }
    }

    StateLayer {
        function onClicked(): void {
            root.triggerAction();
        }
        radius: Appearance.rounding.normal
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.larger
        anchors.rightMargin: Appearance.padding.larger
        anchors.margins: Appearance.padding.smaller

        MaterialIcon {
            id: icon
            text: root.modelData?.icon ?? ""
            font.pointSize: Appearance.font.size.extraLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Appearance.spacing.normal
            anchors.verticalCenter: icon.verticalCenter
            implicitWidth: parent.width - icon.width
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name
                text: root.modelData?.name ?? ""
                font.pointSize: Appearance.font.size.normal
            }

            StyledText {
                id: desc
                text: root.modelData?.desc ?? ""
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
                width: root.width - icon.width - Appearance.rounding.normal * 2
                anchors.top: name.bottom
            }
        }
    }
}
