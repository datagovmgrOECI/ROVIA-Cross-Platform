#!/bin/bash
# ROVIA Clip Cutter — Linux / Mac
# Cuts highlight clips from a ROVIA dry-run manifest CSV.
#
# Usage:
#   bash rovia_cut_clips.sh <manifest_csv>
#
# Example:
#   bash rovia_cut_clips.sh ./Rovia_Clips/rovia_manifest_20250325T214500Z.csv
#
# Requires: ffmpeg (sudo apt-get install ffmpeg  OR  brew install ffmpeg)
# Video stream is copied (no re-encode). Audio is re-encoded to AAC for
# MP4 container compatibility (handles pcm_s16be and other raw codecs).

CSV="$1"

if [ -z "$CSV" ]; then
    echo "ERROR: No manifest file specified."
    echo "Usage: bash rovia_cut_clips.sh <manifest_csv>"
    exit 1
fi

if [ ! -f "$CSV" ]; then
    echo "ERROR: File not found: $CSV"
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "ERROR: ffmpeg not found. Install it first:"
    echo "  Ubuntu/Debian: sudo apt-get install ffmpeg"
    echo "  Mac:           brew install ffmpeg"
    exit 1
fi

echo "============================================================"
echo "ROVIA Clip Cutter"
echo "Manifest: $CSV"
echo "============================================================"

COUNT=0
# Skip header row, read CSV fields
tail -n +2 "$CSV" | while IFS=, read -r source start end duration output; do
    echo ""
    echo "Cutting: $(basename "$source")"
    echo "  ${start}s -> ${end}s  =>  $(basename "$output")"
    ffmpeg -y -i "$source" -ss "$start" -to "$end" -c:v copy -c:a aac "$output" -loglevel error
    echo "  Done."
    COUNT=$((COUNT + 1))
done

echo ""
echo "============================================================"
echo "Clip cutting complete."
echo "============================================================"
