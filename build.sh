#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

export UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX:-https://pypi.org/simple}"

echo "=== [1/5] Building MyBatis 3 User Guide (user_guide_src/ -> docs/user_guide/) ==="
./user_guide_src/build.sh

echo "=== [2/5] Building MyBatis 3 API & XML Reference Catalog (api_src/ -> docs/api/) ==="
./api_src/build.sh

echo "=== [3/5] Building MyBatis 3 Internal Architecture Guide (architecture_src/ -> docs/architecture/) ==="
./architecture_src/build.sh

echo "=== [4/5] Building PNI501 Diagnostic Report (pni501_src/ -> docs/pni501/) ==="
./pni501_src/build.sh

echo "=== [5/5] Regenerating root docs/sitemap.xml & verifying assets ==="
echo "mybatis3.drawlib.com" > docs/CNAME
touch docs/.nojekyll
mkdir -p docs/_assets
cp -f user_guide_src/_assets/favicon.png docs/_assets/favicon.png
cp -f user_guide_src/_assets/ogp.png docs/_assets/ogp.png

python3 -c '
import pathlib, re

base = pathlib.Path("docs")
urls = ["  <url>\n    <loc>https://mybatis3.drawlib.com/</loc>\n  </url>"]
for sub in ("user_guide", "api", "architecture", "pni501"):
    sm = base / sub / "sitemap.xml"
    if sm.exists():
        content = sm.read_text(encoding="utf-8")
        for m in re.finditer(r"  <url>.*?</url>", content, flags=re.DOTALL):
            urls.append(m.group(0))

out = (
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\" xmlns:xhtml=\"http://www.w3.org/1999/xhtml\">\n"
    + "\n".join(urls)
    + "\n</urlset>\n"
)
(base / "sitemap.xml").write_text(out, encoding="utf-8")
print(f"Generated docs/sitemap.xml with {len(urls)} URL entries.")
'

echo "All 4 portals and root Showcase Hub built successfully!"
