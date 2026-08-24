#!/usr/bin/env bash
set -euo pipefail
set -E

LOCK_FILE="/tmp/handle_user_uploads.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "SKIP another instance is already running"
    exit 0
fi

MEDIA_ROOT="/mnt/user/Media"

UPLOAD_ROOTS=(
    "$MEDIA_ROOT/user_uploads"
    "$MEDIA_ROOT/plex_uploads"
)
MOVIE_DEST="$MEDIA_ROOT/movies"
SHOW_DEST="$MEDIA_ROOT/shows"

IDLE_MINUTES=1

CURRENT_ITEM=""

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

trap 'rc=$?; log "ERROR item=$CURRENT_ITEM rc=$rc line=$LINENO cmd=$BASH_COMMAND"' ERR

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

dir_active() {
    local dir="$1"

    if lsof +D "$dir" >/dev/null 2>&1; then
        return 0
    fi

    if find "$dir" -type f -mmin "-$IDLE_MINUTES" | grep -q .; then
        return 0
    fi

    return 1
}

# Move contents of one directory into another safely (no copies)
merge_dir_contents() {
    local src="$1"
    local dest="$2"

    mkdir -p "$dest"

    shopt -s dotglob nullglob
    mv -n "$src"/* "$dest"/
    shopt -u dotglob nullglob

    rmdir "$src" 2>/dev/null || true
}

normalize_movie_upload_files() {
    local upload_dir="$1"
    local original_base="$2"
    local normalized_base="$3"

    shopt -s nullglob

    for f in "$upload_dir"/*; do
        [[ -f "$f" ]] || continue

        local fname new_name

        fname="$(basename "$f")"

        # If file starts with original folder name, replace prefix
        if [[ "$fname" == "$original_base"* ]]; then
            new_name="${fname/#$original_base/$normalized_base}"

            if [[ "$fname" != "$new_name" ]]; then
                log "PRE-NORMALIZE $fname -> $new_name"
                mv -n "$f" "$upload_dir/$new_name"
            fi
        fi
    done

    shopt -u nullglob
}

normalize_episode_filename() {
    local fname="$1"
    local parent_dir="$2"

    local full_match S E SS EE season=""
    local ext stem normalized_token placeholder

    # Detect season from parent directory (e.g. SHOW_S02)
    if [[ "$(basename "$parent_dir")" =~ _S([0-9]{2})$ ]]; then
        season="${BASH_REMATCH[1]}"
    fi

    ########################################################
    # 1. S01E02
    ########################################################
    if [[ "$fname" =~ ([Ss]([0-9]{1,2})[^0-9]*[Ee]([0-9]{1,2})) ]]; then
        full_match="${BASH_REMATCH[1]}"
        S="${BASH_REMATCH[2]}"
        E="${BASH_REMATCH[3]}"
        printf -v SS "%02d" "$((10#$S))"
        printf -v EE "%02d" "$((10#$E))"
        season="$SS"
        normalized_token="S${SS}.E${EE}"

    ########################################################
    # 2. 1x02
    ########################################################
    elif [[ "$fname" =~ (([0-9]{1,2})x([0-9]{1,2})) ]]; then
        full_match="${BASH_REMATCH[1]}"
        S="${BASH_REMATCH[2]}"
        E="${BASH_REMATCH[3]}"
        printf -v SS "%02d" "$((10#$S))"
        printf -v EE "%02d" "$((10#$E))"
        season="$SS"
        normalized_token="S${SS}.E${EE}"

    ########################################################
    # 3. E02
    ########################################################
    elif [[ "$fname" =~ ([Ee]([0-9]{1,2})) ]]; then
        full_match="${BASH_REMATCH[1]}"
        E="${BASH_REMATCH[2]}"
        printf -v EE "%02d" "$((10#$E))"

        if [[ -z "$season" ]]; then
            season="01"
        fi

        normalized_token="S${season}.E${EE}"

    ########################################################
    # 4. Bare number (fallback)
    ########################################################
    elif [[ "$fname" =~ (^|[^0-9])([0-9]{1,2})([^0-9]|$) ]]; then
        full_match="${BASH_REMATCH[2]}"
        E="${BASH_REMATCH[2]}"
        printf -v EE "%02d" "$((10#$E))"

        if [[ -z "$season" ]]; then
            season="01"
        fi

        normalized_token="S${season}.E${EE}"

    else
        return 1
    fi

    ext="${fname##*.}"
    stem="${fname%.*}"

    placeholder="__EP_TOKEN__"
    stem="${stem/$full_match/$placeholder}"
    stem="${stem//./_}"
    stem="${stem/$placeholder/$normalized_token}"

    echo "${season}|${stem}.${ext}"
}

########################################
# MOVIE PROCESSOR
########################################

process_movie() {
    local entry="$1"
    local base norm ext name dest_dir

    base="$(basename "$entry")"
    CURRENT_ITEM="movie:$base"

    log "START movie $base"

    # Case 1 — Directory Upload
    if [[ -d "$entry" ]]; then
        log "INFO  movie $base is directory"

        if dir_active "$entry"; then
            log "SKIP movie $base (active files)"
            return 0
        fi

        norm="$(normalize_name "$base")"
        dest_dir="$MOVIE_DEST/$norm"

        log "INFO  movie normalized name: $norm"
        log "INFO  movie destination: $dest_dir"

        normalize_movie_upload_files "$entry" "$base" "$norm"

        log "MERGE movie directory contents"
        merge_dir_contents "$entry" "$dest_dir"

        log "OK   movie $norm (merged directory)"
        return 0
    fi

    # Case 2 — Single File Upload
    if [[ -f "$entry" ]]; then
        log "INFO  movie $base is file"

        if file_active "$entry"; then
            log "SKIP movie $base (active file)"
            return 0
        fi

        ext="${base##*.}"
        name="${base%.*}"
        norm="$(normalize_name "$name")"
        dest_dir="$MOVIE_DEST/$norm"

        log "INFO  movie normalized name: $norm"
        log "INFO  movie destination: $dest_dir"

        mkdir -p "$dest_dir"

        log "MOVE  $base -> $dest_dir/$norm.$ext"
        mv -n "$entry" "$dest_dir/$norm.$ext"

        log "OK   movie $norm (single file)"
        return 0
    fi

    # Unknown Entry Type
    log "ERROR movie $base (unknown entry type)"
    return 1
}

########################################
# SHOW PROCESSOR
########################################

process_show() {
    local entry="$1"
    local show_base SHOW_NAME files parse_failed
    local f fname result SS new_fname SEASON_DIR final_dir

    show_base="$(basename "$entry")"
    CURRENT_ITEM="show:$show_base"

    if dir_active "$entry"; then
        log "SKIP show  $show_base (active files)"
        return 0
    fi

    SHOW_NAME="$(normalize_name "$show_base")"
    log "START show $SHOW_NAME"

    mapfile -d '' -t files < <(find "$entry" -type f -print0)

    parse_failed=false

    for f in "${files[@]}"; do
        fname="$(basename "$f")"

        if result="$(normalize_episode_filename "$fname" "$(dirname "$f")")"; then
            SS="${result%%|*}"
            new_fname="${result#*|}"

            SEASON_DIR="$SHOW_DEST/$SHOW_NAME/${SHOW_NAME}_S$SS"
            mkdir -p "$SEASON_DIR"

            log "MOVE $fname -> $new_fname"
            mv -n "$f" "$SEASON_DIR/$new_fname"
        else
            log "PARSE FAIL: $fname (no SxxExx or N x N match)"
            parse_failed=true
            break
        fi
    done

    if $parse_failed; then
        log "WARN show  $SHOW_NAME (fallback structure)"
        return 1
    fi

    log "OK   show  $SHOW_NAME"
}


########################################
# CLEANUP
########################################

cleanup_empty_dirs() {
    local parent="$1"
    find "$parent" -mindepth 1 -type d -empty -delete 2>/dev/null || true
}






## -------- BEGIN PROCESSING LOOP --------------

for UPLOAD_ROOT in "${UPLOAD_ROOTS[@]}"; do


########################################
# MOVIES LOOP
########################################

MOVIE_SRC="$UPLOAD_ROOT/movies"

if [[ -d "$MOVIE_SRC" ]]; then
    shopt -s nullglob
    for entry in "$MOVIE_SRC"/*; do
        if ! process_movie "$entry"; then
            log "FAIL movie $(basename "$entry") — continuing"
        fi
    done
fi

cleanup_empty_dirs "$MOVIE_SRC"



########################################
# SHOWS LOOP
########################################

SHOW_SRC="$UPLOAD_ROOT/shows"
[[ -d "$SHOW_SRC" ]] || exit 0

shopt -s nullglob

for entry in "$SHOW_SRC"/*; do
    [[ -d "$entry" ]] || continue

    process_show "$entry" || {
        log "FAIL show $(basename "$entry") — continuing"
    }
done

cleanup_empty_dirs "$SHOW_SRC"


## ------- END PROCESSING LOOP -----------

done

