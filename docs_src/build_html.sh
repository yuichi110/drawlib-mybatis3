#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PARENT_DIR"

export UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX:-https://pypi.org/simple}"
DRAWLIB_CMD="${DRAWLIB_CMD:-uvx drawlib}"

BACKUP_DIR="$SCRIPT_DIR/.subportals_backup"
mkdir -p "$BACKUP_DIR"

restore_subportals() {
    for sub in api architecture reports; do
        if [ -d "$BACKUP_DIR/$sub" ]; then
            rm -rf "docs/$sub"
            mkdir -p "docs"
            mv "$BACKUP_DIR/$sub" "docs/$sub"
        fi
    done
    rm -rf "$BACKUP_DIR"
}
trap restore_subportals EXIT

for sub in api architecture reports; do
    if [ -d "docs/$sub" ] && [ ! -d "$BACKUP_DIR/$sub" ]; then
        mv "docs/$sub" "$BACKUP_DIR/$sub"
    fi
done

echo "Building User Guide HTML site -> docs/..."
$DRAWLIB_CMD build html docs_src/ -o docs/

echo "mybatis3.drawlib.com" > docs/CNAME
touch docs/.nojekyll
echo "User Guide HTML site build complete: docs/"
