pragma ComponentBehavior: Bound

import ".."
import "../../components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.config
import qs.utils

CollapsibleSection {
    id: root

    required property var rootPane

    title: qsTr("Live Wallpaper")
    showBackground: true

    SwitchRow {
        label: qsTr("Autostart on login")
        checked: Config.launcher.liveWallpaperAutostart
        onToggled: checked => {
            Config.launcher.liveWallpaperAutostart = checked;
            Config.save();
        }
    }

    // Controls
    SwitchRow {
        label: qsTr("Stop live wallpaper")
        checked: false
        onToggled: checked => {
            if (checked) {
                Quickshell.execDetached(["/home/siraxuth/.local/bin/live-wallpaper.sh", "stop"]);
            }
        }
    }

    SwitchRow {
        id: pauseRow
        label: qsTr("Pause live wallpaper")
        checked: false
        onToggled: checked => {
            if (checked) {
                Quickshell.execDetached(["bash", "-c", "pkill -STOP mpvpaper"]);
            } else {
                Quickshell.execDetached(["bash", "-c", "pkill -CONT mpvpaper"]);
            }
        }
    }

    // Settings
    StyledText {
        Layout.topMargin: Appearance.spacing.normal
        text: qsTr("Settings")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    SpinBoxRow {
        label: qsTr("Max wallpapers shown")
        value: Config.launcher.maxLiveWallpapers
        min: 1
        max: 19
        step: 2
        onValueModified: value => {
            Config.launcher.maxLiveWallpapers = value;
            Config.save();
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                text: qsTr("Video folder")
                font.pointSize: Appearance.font.size.normal
            }

            StyledTextField {
                Layout.fillWidth: true
                text: Config.paths.liveWallpaperDir
                placeholderText: qsTr("e.g. ~/Videos/Wallpapers")
                onEditingFinished: {
                    Config.paths.liveWallpaperDir = text;
                    Config.save();
                    listProc.running = true;
                }
            }
        }
    }

    // Video grid
    StyledText {
        Layout.topMargin: Appearance.spacing.normal
        text: qsTr("Videos")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: grid.implicitHeight

        GridView {
            id: grid

            readonly property string videoDir: Paths.absolutePath(Config.paths.liveWallpaperDir)
            readonly property string thumbDir: `${Paths.cache}/live-thumbs`
            readonly property int minCellWidth: 180 + Appearance.spacing.normal
            readonly property int columnsCount: Math.max(1, Math.floor(width / minCellWidth))

            property string currentVideo: ""

            width: parent.width
            implicitHeight: Math.ceil(videoModel.count / columnsCount) * (130 + Appearance.spacing.normal)
            cellWidth: width / columnsCount
            cellHeight: 130 + Appearance.spacing.normal
            clip: true
            interactive: false

            model: ListModel { id: videoModel }

            Process {
                id: listProc
                command: ["/home/siraxuth/.local/bin/live-wallpaper.sh", "list"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        videoModel.clear();
                        const lines = text.trim().split("\n").filter(l => l.length > 0);
                        for (const name of lines)
                            videoModel.append({ itemName: name, itemPath: `${grid.videoDir}/${name}`, itemThumb: `${grid.thumbDir}/${name}.jpg` });
                    }
                }
            }

            Process {
                id: currentProc
                command: ["bash", "-c", "cat /tmp/.live_wallpaper_current 2>/dev/null"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: { grid.currentVideo = text.trim(); }
                }
            }

            delegate: Item {
                required property string itemName
                required property string itemPath
                required property string itemThumb
                required property int index

                readonly property bool isCurrent: itemPath === grid.currentVideo
                readonly property real itemMargin: Appearance.spacing.normal / 2
                readonly property real itemRadius: Appearance.rounding.normal

                width: grid.cellWidth
                height: grid.cellHeight

                StateLayer {
                    function onClicked(): void {
                        Quickshell.execDetached(["/home/siraxuth/.local/bin/live-wallpaper.sh", "set", itemPath]);
                        grid.currentVideo = itemPath;
                    }
                    anchors.fill: parent
                    anchors.margins: itemMargin
                    radius: itemRadius
                }

                StyledClippingRect {
                    anchors.fill: parent
                    anchors.margins: itemMargin
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
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 500 } }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        implicitHeight: nameText.implicitHeight + Appearance.padding.normal * 1.5
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: itemMargin
                    color: "transparent"
                    radius: itemRadius + border.width
                    border.width: isCurrent ? 2 : 0
                    border.color: Colours.palette.m3primary
                    Behavior on border.width { NumberAnimation { duration: 150 } }

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
    }
}
