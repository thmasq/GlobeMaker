#!/bin/sh

GORE_WIDTH_PX=1024
GORE_WIDTH_DEGREES=60
GORE_OUTLINE_WIDTH=2
OUT_PATH="/output/globe.png"

while [ $# -gt 0 ]; do
    case "$1" in
        -p) GORE_WIDTH_PX="$2"; shift 2;;
        -d) GORE_WIDTH_DEGREES="$2"; shift 2;;
        -g) GORE_OUTLINE_WIDTH="$2"; shift 2;;
        -o) OUT_PATH="$2"; shift 2;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

mkdir -p "$(dirname "$OUT_PATH")"

python makeGlobe.py -p "$GORE_WIDTH_PX" -d "$GORE_WIDTH_DEGREES" -g "$GORE_OUTLINE_WIDTH" -o "$OUT_PATH"
