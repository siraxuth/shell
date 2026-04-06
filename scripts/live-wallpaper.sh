#!/usr/bin/env bash
VIDEO_DIR="$(python3 -c "import json; d=json.load(open(\"$HOME/.config/caelestia/shell.json\")); print(d.get(\"paths\",{}).get(\"liveWallpaperDir\",\"~/Videos/Wallpapers\"))" 2>/dev/null || echo ~/Videos/Wallpapers)"
VIDEO_DIR="${VIDEO_DIR/#\~/$HOME}"
STATE_FILE="$HOME/.local/state/caelestia/live_wallpaper_current"
LOCK_FILE="/tmp/.live_wallpaper_lock"
THUMB_DIR="$HOME/.cache/caelestia/live-thumbs"

mkdir -p "$(dirname "$STATE_FILE")" "$THUMB_DIR"

make_thumb() {
    local file="$1"
    local name="$(basename "$file")"
    local thumb="$THUMB_DIR/$name.jpg"
    ffmpeg -i "$file" -ss 00:00:03 -vframes 1 -q:v 1 "$thumb" -y 2>/dev/null
}

list() {
    find "$VIDEO_DIR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) \
        -printf "%f\n" | sort | while read -r name; do
        local thumb="$THUMB_DIR/$name.jpg"
        # regenerate ถ้า thumbnail เก่ากว่าวิดีโอ หรือไม่มี
        if [[ ! -f "$thumb" ]] || [[ "$VIDEO_DIR/$name" -nt "$thumb" ]]; then
            make_thumb "$VIDEO_DIR/$name"
        fi
        echo "$name"
    done
}

set_wallpaper() {
    local file="$1"
    [[ "$file" != /* ]] && file="$VIDEO_DIR/$file"
    if [[ ! -f "$file" ]]; then
        notify-send "Live Wallpaper" "File not found: $file" -i dialog-error
        exit 1
    fi
    local current
    current=$(cat "$STATE_FILE" 2>/dev/null)
    if [[ "$current" == "$file" ]] && pgrep -x mpvpaper > /dev/null; then
        exit 0
    fi
    exec 9>"$LOCK_FILE"
    flock -n 9 || exit 0
    pkill -x mpvpaper 2>/dev/null
    sleep 0.3
    mpvpaper -o "no-audio loop" '*' "$file" &
    echo "$file" > "$STATE_FILE"
    notify-send "Live Wallpaper" "▶ $(basename "$file")" -i video-x-generic
    flock -u 9
}

stop() {
    pkill -x mpvpaper 2>/dev/null
    rm -f "$STATE_FILE" "$LOCK_FILE"
    notify-send "Live Wallpaper" "⏹ Stopped" -i video-x-generic
}

pause() {
    pkill -STOP mpvpaper 2>/dev/null
    notify-send "Live Wallpaper" "⏸ Paused" -i video-x-generic
}

resume() {
    pkill -CONT mpvpaper 2>/dev/null
    notify-send "Live Wallpaper" "▶ Resumed" -i video-x-generic
}

autostart() {
    local last
    last=$(cat "$STATE_FILE" 2>/dev/null)
    if [[ -n "$last" && -f "$last" ]]; then
        set_wallpaper "$last"
    fi
}

case "$1" in
    list)      list ;;
    set)       set_wallpaper "$2" ;;
    stop)      stop ;;
    pause)     pause ;;
    resume)    resume ;;
    autostart) autostart ;;
    *)         echo "Usage: $0 {list|set <file>|stop|pause|resume|autostart}" ;;
esac
