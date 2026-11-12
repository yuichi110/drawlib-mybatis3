#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Building PNI501 HTML ==="
"$SCRIPT_DIR/build_html.sh"

echo "=== Building PNI501 PDF ==="
"$SCRIPT_DIR/build_pdf.sh"

echo "PNI501 HTML & PDF builds completed successfully!"
