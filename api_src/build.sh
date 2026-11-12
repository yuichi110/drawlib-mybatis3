#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Building API Catalog HTML ==="
"$SCRIPT_DIR/build_html.sh"

echo "API Catalog build completed successfully!"
