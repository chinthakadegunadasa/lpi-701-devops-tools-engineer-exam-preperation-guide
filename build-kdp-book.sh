#!/usr/bin/env bash
# build-kdp-book.sh

echo "Building Combined Markdown Document..."
cat README.md Chapter*.md > FULL_BOOK.md

echo "Converting Markdown to DOCX via Pandoc..."
pandoc FULL_BOOK.md \
  -o dist/LPIC-701-DevOps-Guide.docx \
  --toc --toc-depth=3 \
  --highlight-style=kate

echo "Converting DOCX to B5 PDF via Headless LibreOffice..."
soffice --headless --convert-to pdf \
  --outdir dist/ dist/LPIC-701-DevOps-Guide.docx
echo "Build complete: dist/LPIC-701-DevOps-Guide.pdf generated for deshapriyabooks.com and KDP!"

