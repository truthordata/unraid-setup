#!/usr/bin/env bash
set -euo pipefail

MEDIA_ROOT="/mnt/user/Media"

UPLOAD_ROOT="$MEDIA_ROOT/user_uploads"
MOVIE_DEST="$MEDIA_ROOT/movies"
SHOW_DEST="$MEDIA_ROOT/shows"

IDLE_MINUTES=1

normalize_name() {
    echo "$1" \
        | tr '[:lower:]' '[:upper:]' \
        | sed -E 's/[^A-Z0-9]+/_/g; s/^_+|_+$//g'
}

file_active() {
    local f="$1"
    local name
    name="$(basename "$f")"

    case "$name" in
        *.part|*.crdownload|*.tmp|*.partial)
            return 0
            ;;
    esac

    if lsof "$f" >/dev/null 2>&1; then
        return 0
    fi

    if find "$f" -mmin "-$IDLE_MINUTES" | grep -q .; then
        return 0
    fi

    return 1
}

########################################
# MOVIES
########################################

MOVIE_SRC="$UPLOAD_ROOT/movies"

if [[ -d "$MOVIE_SRC" ]]; then
    shopt -s nullglob
    for entry in "$MOVIE_SRC"/*; do
        base="$(basename "$entry")"

        ################################
        # Standalone movie file
        ################################
        if [[ -f "$entry" ]]; then
            if file_active "$entry"; then
                echo "SKIP movie $base (active)"
                continue
            fi

            ext="${base##*.}"
            name="${base%.*}"
            norm="$(normalize_name "$name")"

            dest_dir="$MOVIE_DEST/$norm"
            mkdir -p "$dest_dir"

            mv "$entry" "$dest_dir/$norm.$ext"
            echo "OK   movie $norm"
        fi

        ################################
        # Movie folder
        ################################
        if [[ -d "$entry" ]]; then
            if find "$entry" -type f | while read -r f; do
                file_active "$f" && exit 1
            done; then
                :
            else
                echo "SKIP movie $base (active files)"
                continue
            fi

            norm="$(normalize_name "$base")"
            dest_dir="$MOVIE_DEST/$norm"

            mv "$entry" "$dest_dir"
            echo "OK   movie $norm (folder)"
        fi
    done
fi

########################################
# SHOWS
########################################

SHOW_SRC="$UPLOAD_ROOT/shows"
[[ -d "$SHOW_SRC" ]] || exit 0

shopt -s nullglob

for entry in "$SHOW_SRC"/*; do
    [[ -d "$entry" ]] || continue

    show_base="$(basename "$entry")"

    if find "$entry" -type f | while read -r f; do
        file_active "$f" && exit 1
    done; then
        :
    else
        echo "SKIP show  $show_base (active files)"
        continue
    fi

    SHOW_NAME="$(normalize_name "$show_base")"

    WORK_DIR="$(mktemp -d)"
    SHOW_DIR="$WORK_DIR/$SHOW_NAME"
    mkdir -p "$SHOW_DIR"

    mapfile -t files < <(find "$entry" -type f)

    parse_failed=false

    for f in "${files[@]}"; do
        fname="$(basename "$f")"

        if [[ "$fname" =~ [Ss]([0-9]{1,2})[^0-9]*[Ee]([0-9]{1,2}) ]] || \
           [[ "$fname" =~ ([0-9]{1,2})x([0-9]{1,2}) ]]; then

            S="${BASH_REMATCH[1]}"
            E="${BASH_REMATCH[2]}"

            printf -v SS "%02d" "$S"
            printf -v EE "%02d" "$E"

            SEASON_DIR="$SHOW_DIR/${SHOW_NAME}_S$SS"
            mkdir -p "$SEASON_DIR"

            ext="${fname##*.}"
            mv "$f" "$SEASON_DIR/${SHOW_NAME}_S$SS.E$EE.$ext"
        else
            parse_failed=true
            break
        fi
    done

    if $parse_failed; then
        rm -rf "$SHOW_DIR"
        mkdir -p "$SHOW_DIR"
        find "$entry" -type f -exec mv {} "$SHOW_DIR/" \;
        echo "WARN show  $SHOW_NAME (fallback structure)"
    else
        echo "OK   show  $SHOW_NAME"
    fi

    mv "$SHOW_DIR" "$SHOW_DEST/"
    rm -rf "$WORK_DIR"
    rm -rf "$entry"

done
