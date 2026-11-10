#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PARENT_DIR"

export UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX:-https://pypi.org/simple}"
DRAWLIB_CMD="${DRAWLIB_CMD:-uvx drawlib}"

echo "Building API Catalog HTML site -> docs/api/..."
$DRAWLIB_CMD build html api_src/ -o docs/api/
echo "API Catalog HTML site build complete: docs/api/"
