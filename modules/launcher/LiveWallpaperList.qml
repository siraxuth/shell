pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import Quickshell.Io
import qs.components.controls
import qs.services
import qs.config

PathView {
    id: root

    required property StyledTextField search
    required property var visibilities
    required property var panels
    required property var content

    readonly property string videoDir: Paths.absolutePath(Config.paths.liveWallpaperDir)
    readonly property int itemWidth: Config.launcher.sizes.wallpaperWidth * 0.8 + Appearance.padding.larger * 2

    readonly property int numItems: {
        const screen = (QsWindow.window as QsWindow)?.screen;
        if (!screen)
            return 0;

        const barMargins = Math.max(Config.border.thickness, panels.bar.implicitWidth);
        let outerMargins = 0;
        if (panels.popouts.hasCurrent && panels.popouts.currentCenter + panels.popouts.nonAnimHeight / 2 > screen.height - content.implicitHeight - Config.border.thickness * 2)
            outerMargins = panels.popouts.nonAnimWidth;
        if ((visibilities.utilities || visibilities.sidebar) && panels.utilities.implicitWidth > outerMargins)
            outerMargins = panels.utilities.implicitWidth;
        const maxWidth = screen.width - Config.border.rounding * 4 - (barMargins + outerMargins) * 2;

        if (maxWidth <= 0)
            return 0;

        const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
        const total = videoModel.count > 0 ? videoModel.count : 9; const visible = Math.min(maxItemsOnScreen, Config.launcher.maxWallpapers, total);

        if (visible === 2)
            return 1;
        if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return visible;
    }

    ListModel {
        id: videoModel
    }

    Process {
        id: listProc
        command: ["/home/siraxuth/.local/bin/live-wallpaper.sh", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                videoModel.clear();
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                for (const name of lines)
                    videoModel.append({ itemName: name, itemPath: `${root.videoDir}/${name}`, itemThumb: `/home/siraxuth/.cache/caelestia/live-thumbs/${name}.jpg` });
            }
        }
    }

    model: videoModel

    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: Math.max(1, count)
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: LiveWallpaperItem {
        required property string itemName
        required property string itemPath
        required property string itemThumb

        modelData: ({ name: itemName, path: itemPath, thumb: itemThumb })
        visibilities: root.visibilities
    }

    path: Path {
        startY: root.height / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
    }
}
