#!/usr/bin/env bash
set -euo pipefail

MEDIA_ROOT="/mnt/user/Media"
RIPS_DIR="$MEDIA_ROOT/rips"
MOVIES_DIR="$MEDIA_ROOT/movies"

cd "$MEDIA_ROOT"

shopt -s nullglob

for dir in "$RIPS_DIR"/*/; do
    rip_name="$(basename "$dir")"

    # Gate 1: open file handles (actively ripping or stalled writer)
    if lsof +D "$dir" >/dev/null 2>&1; then
        echo "SKIP rip $rip_name (open files)"
        continue
    fi

    # Gate 2: recent writes (must be idle for 5 minutes)
    if find "$dir" -type f -mmin -5 | grep -q .; then
        echo "SKIP rip $rip_name (recent activity < 5 min)"
        continue
    fi

    # Strip trailing slash and path
    original_dir="${dir%/}"
    base_name="$(basename "$original_dir")"

    # 1. Normalize folder name: ALL CAPS, underscores as spaces
    normalized_name="$(
        echo "$base_name" \
        | tr '[:lower:]' '[:upper:]' \
        | sed -E 's/[^A-Z0-9]+/_/g; s/^_+|_+$//g'
    )"

    normalized_dir="$RIPS_DIR/$normalized_name"

    # Rename directory if needed
    if [[ "$original_dir" != "$normalized_dir" ]]; then
        mv "$original_dir" "$normalized_dir"
    fi

    cd "$normalized_dir"

    # Count regular files only
    mapfile -t files < <(find . -maxdepth 1 -type f)

    # 3. If more than one file exists
    if (( ${#files[@]} > 1 )); then
        mkdir -p Extras
        mv -- *.?* Extras/ 2>/dev/null || true
        cd Extras
    fi

    # 4. Find largest file
    largest_file="$(find . -type f -printf '%s\t%p\n' | sort -nr | head -n1 | cut -f2-)"

    if [[ -z "$largest_file" ]]; then
        cd "$RIPS_DIR"
        continue
    fi

    # Preserve extension
    extension="${largest_file##*.}"
    new_name="$normalized_name.$extension"

    mv "$largest_file" "$new_name"

    # 5. If inside Extras, move file up
    if [[ "$(basename "$PWD")" == "Extras" ]]; then
        mv "$new_name" ..
        cd ..
    fi

    # 6. Move finalized folder to /movies
    cd "$RIPS_DIR"
    mv "$normalized_dir" "$MOVIES_DIR/"

    echo "OK   rip $normalized_name"

done
