import QtQuick
import Quickshell
import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import qs.config

Item {
    id: root

    required property var modelData
    required property var visibilities

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: thumb.width + Appearance.padding.larger * 2
    implicitHeight: thumb.height + label.height + Appearance.spacing.small / 2 + Appearance.padding.large + Appearance.padding.normal

    StateLayer {
        function onClicked(): void {
            Quickshell.execDetached(["/home/siraxuth/.local/bin/live-wallpaper.sh", "set", root.modelData.path]);
            root.visibilities.launcher = false;
        }
        radius: Appearance.rounding.normal
    }

    Elevation {
        anchors.fill: thumb
        radius: thumb.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4
        Behavior on opacity { Anim {} }
    }

    StyledClippingRect {
        id: thumb

        anchors.horizontalCenter: parent.horizontalCenter
        y: Appearance.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.normal

        implicitWidth: Config.launcher.sizes.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: "play_circle"
            color: Colours.tPalette.m3outline
            font.pointSize: Appearance.font.size.extraLarge * 2
            font.weight: 600
            visible: thumbImg.status !== Image.Ready
        }

        CachingImage {
            id: thumbImg
            path: root.modelData.thumb
            smooth: !root.PathView.view.moving
            cache: true
            anchors.fill: parent
        }
    }

    StyledText {
        id: label

        anchors.top: thumb.bottom
        anchors.topMargin: Appearance.spacing.small / 2
        anchors.horizontalCenter: parent.horizontalCenter

        width: thumb.width - Appearance.padding.normal * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData.name
        font.pointSize: Appearance.font.size.normal
    }

    Behavior on scale { Anim {} }
    Behavior on opacity { Anim {} }
}
