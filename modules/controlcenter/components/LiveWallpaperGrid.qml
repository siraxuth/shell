pragma ComponentBehavior: Bound

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services
import qs.config
import qs.utils

GridView {
    id: root

    required property Session session

    readonly property string videoDir: Paths.absolutePath(Config.paths.liveWallpaperDir)
    readonly property string thumbDir: `${Paths.cache}/live-thumbs`
    readonly property int minCellWidth: 200 + Appearance.spacing.normal
    readonly property int columnsCount: Math.max(1, Math.floor(width / minCellWidth))

    property string currentVideo: ""
    property var videoFiles: []

    cellWidth: width / columnsCount
    cellHeight: 140 + Appearance.spacing.normal

    clip: true

    ListModel {
        id: videoModel
    }

    model: videoModel

    Process {
        id: listProc
        command: ["/home/siraxuth/.local/bin/live-wallpaper.sh", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                videoModel.clear();
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                for (const name of lines) {
                    videoModel.append({
                        itemName: name,
                        itemPath: `${root.videoDir}/${name}`,
                        itemThumb: `${root.thumbDir}/${name}.jpg`
                    });
                }
            }
        }
    }

    Process {
        id: currentProc
        command: ["bash", "-c", "cat /tmp/.live_wallpaper_current 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.currentVideo = text.trim();
            }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    delegate: Item {
        required property string itemName
        required property string itemPath
        required property string itemThumb
        required property int index

        readonly property bool isCurrent: itemPath === root.currentVideo
        readonly property real itemMargin: Appearance.spacing.normal / 2
        readonly property real itemRadius: Appearance.rounding.normal

        width: root.cellWidth
        height: root.cellHeight

        StateLayer {
            function onClicked(): void {
                Quickshell.execDetached(["/home/siraxuth/.local/bin/live-wallpaper.sh", "set", itemPath]);
                root.currentVideo = itemPath;
            }

            anchors.fill: parent
            anchors.leftMargin: itemMargin
            anchors.rightMargin: itemMargin
            anchors.topMargin: itemMargin
            anchors.bottomMargin: itemMargin
            radius: itemRadius
        }

        StyledClippingRect {
            id: thumbRect

            anchors.fill: parent
            anchors.leftMargin: itemMargin
            anchors.rightMargin: itemMargin
            anchors.topMargin: itemMargin
            anchors.bottomMargin: itemMargin
            color: Colours.tPalette.m3surfaceContainer
            radius: itemRadius

            MaterialIcon {
                anchors.centerIn: parent
                text: "play_circle"
                color: Colours.tPalette.m3outline
                font.pointSize: Appearance.font.size.extraLarge * 2
                visible: thumbImg.status !== Image.Ready
            }

            Image {
                id: thumbImg
                anchors.fill: parent
                source: itemThumb
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                sourceSize: Qt.size(width, height)
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 500; easing.type: Easing.OutQuad }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: nameText.implicitHeight + Appearance.padding.normal * 1.5

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                    GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.6) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: itemMargin
            anchors.rightMargin: itemMargin
            anchors.topMargin: itemMargin
            anchors.bottomMargin: itemMargin
            color: "transparent"
            radius: itemRadius + border.width
            border.width: isCurrent ? 2 : 0
            border.color: Colours.palette.m3primary

            Behavior on border.width {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }

            MaterialIcon {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Appearance.padding.small
                visible: isCurrent
                text: "check_circle"
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.large
            }
        }

        StyledText {
            id: nameText

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Appearance.padding.normal + Appearance.spacing.normal / 2
            anchors.rightMargin: Appearance.padding.normal + Appearance.spacing.normal / 2
            anchors.bottomMargin: Appearance.padding.normal

            text: itemName
            font.pointSize: Appearance.font.size.smaller
            font.weight: 500
            color: isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
            elide: Text.ElideMiddle
            maximumLineCount: 1
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
