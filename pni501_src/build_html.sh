#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "pni501_src" = "." ]; then
    cd "$SCRIPT_DIR"
else
    PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
    cd "$PARENT_DIR"
fi

if [ -z "${DRAWLIB_CMD:-}" ]; then
    if ( [ -f "uv.lock" ] || [ -f "../uv.lock" ] ) && command -v uv &> /dev/null && uv run drawlib --version &> /dev/null; then
        DRAWLIB_CMD="uv run drawlib"
    elif command -v drawlib &> /dev/null; then
        DRAWLIB_CMD="drawlib"
    elif python3 -m drawlib --version &> /dev/null; then
        DRAWLIB_CMD="python3 -m drawlib"
    elif python -m drawlib --version &> /dev/null; then
        DRAWLIB_CMD="python -m drawlib"
    elif command -v uv &> /dev/null && uv run drawlib --version &> /dev/null; then
        DRAWLIB_CMD="uv run drawlib"
    elif command -v uvx &> /dev/null; then
        DRAWLIB_CMD="uvx drawlib"
    else
        DRAWLIB_CMD="drawlib"
    fi
fi

echo "Using Drawlib command: $DRAWLIB_CMD"
TMP_PRESERVE="$(mktemp -d)"
trap 'rm -rf "$TMP_PRESERVE"' EXIT
for f in pni501.pdf pni501_score.json; do
    if [ -f "docs/pni501/$f" ]; then
        cp "docs/pni501/$f" "$TMP_PRESERVE/$f"
    fi
done
echo "Building PNI501 HTML -> docs/pni501/..."
$DRAWLIB_CMD build html pni501_src/ -o docs/pni501/
for f in pni501.pdf pni501_score.json; do
    if [ -f "$TMP_PRESERVE/$f" ] && [ ! -f "docs/pni501/$f" ]; then
        cp "$TMP_PRESERVE/$f" "docs/pni501/$f"
    fi
done
echo "HTML build complete: docs/pni501/"
