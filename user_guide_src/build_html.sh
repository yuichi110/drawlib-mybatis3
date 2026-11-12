#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PARENT_DIR"

export UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX:-https://pypi.org/simple}"
DRAWLIB_CMD="${DRAWLIB_CMD:-uvx drawlib}"

echo "Building User Guide HTML site -> docs/user_guide/..."
$DRAWLIB_CMD build html user_guide_src/ -o docs/user_guide/
echo "User Guide HTML site build complete: docs/user_guide/"
