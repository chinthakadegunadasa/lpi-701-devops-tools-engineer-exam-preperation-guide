#!/usr/bin/env bash
set -euo pipefail

INTERMEDIATE_DOCX="temp_combined.docx"
FINAL_PDF="LPIC-701-Exam-Guide-KDP.pdf"
BUILD_DIR="build_out"
COMBINED_MD="combined_manuscript.md"
REF_DOC="reference.docx"

echo "=== [Step 1/5] Force Rebuilding & Validating reference.docx ==="

# 1. Remove existing reference.docx to ensure a completely clean build
if [[ -f "$REF_DOC" ]]; then
    echo "Removing existing $REF_DOC to apply updated parameters..."
    rm -f "$REF_DOC"
fi

# 2. Generate raw reference.docx from Chapter1.md
if [[ -f "Chapter1.md" ]]; then
    echo "Generating base $REF_DOC from Chapter1.md..."
    pandoc Chapter1.md -o "$REF_DOC"
else
    echo "Warning: Chapter1.md not found. Generating default reference.docx..."
    pandoc --print-default-data-file reference.docx > "$REF_DOC"
fi

# 3. Use Python (python-docx) to modify XML styles directly (Geometry, Justification, Fonts)
python3 - << 'EOF'
import sys
import docx
from docx.shared import Inches, Pt, Mm
from docx.enum.text import WD_ALIGN_PARAGRAPH

try:
    doc = docx.Document('reference.docx')

    # Configure Section Properties (B5 Geometry & KDP Margins)
    for section in doc.sections:
        section.page_width = Mm(176)   # B5 Width
        section.page_height = Mm(250)  # B5 Height
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)   # Inside/Gutter
        section.right_margin = Inches(0.6)  # Outside

    # Configure 'Normal' Paragraph Style (Justified, Cambria 11pt, 1.15 line spacing)
    style_normal = doc.styles['Normal']
    style_normal.font.name = 'Cambria'
    style_normal.font.size = Pt(11)
    style_normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    style_normal.paragraph_format.line_spacing = 1.15
    style_normal.paragraph_format.space_after = Pt(2.16) # 0.03 in

    # Configure Code/Preformatted Text Style if present
    for style_name in ['Source Code', 'Preformatted Text']:
        if style_name in doc.styles:
            code_style = doc.styles[style_name]
            code_style.font.name = 'Consolas'
            code_style.font.size = Pt(9.5)

    doc.save('reference.docx')
    print("Successfully configured DOCX styles inside reference.docx")
except Exception as e:
    print(f"Error modifying reference.docx styles: {e}", file=sys.stderr)
    sys.exit(1)
EOF

# 4. Verification Check: Confirm reference.docx exists and is non-empty
if [[ -f "$REF_DOC" ]] && [[ $(wc -c < "$REF_DOC") -gt 5000 ]]; then
    echo "=== Verification Passed: $REF_DOC created successfully ($(du -h "$REF_DOC" | cut -f1)) ==="
else
    echo "Error: $REF_DOC validation failed or file is corrupted."
    exit 1
fi

echo "=== [Step 2/5] Assembling Chapters with Strict \\newpage Breaks ==="

FILES=()
if [[ -f "README.md" ]]; then
    FILES+=("README.md")
fi

while IFS= read -r file; do
    FILES+=("$file")
done < <(find . -maxdepth 1 -name "Chapter*.md" | sort -V)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: No Chapter*.md or README.md files found!"
    exit 1
fi

echo "Processing source files in order: ${FILES[*]}"

# Build combined manuscript with explicit page break (\newpage)
> "$COMBINED_MD"

first_file=true
for f in "${FILES[@]}"; do
    if [ "$first_file" = true ]; then
        cat "$f" >> "$COMBINED_MD"
        first_file=false
    else
        echo -e "\n\n\\newpage\n\n" >> "$COMBINED_MD"
        cat "$f" >> "$COMBINED_MD"
    fi
done

if [[ -f "references.bib" ]] || grep -q "### References" "Chapter1.md" 2>/dev/null; then
    echo -e "\n\n\\newpage\n\n# References\n" >> "$COMBINED_MD"
fi

echo "=== [Step 3/5] Generating Intermediate DOCX via Pandoc ==="

PANDOC_ARGS=(
    "$COMBINED_MD"
    --from=markdown
    --to=docx
    --output="$INTERMEDIATE_DOCX"
    --reference-doc="$REF_DOC"
    --lang=en-US
    --toc
    --toc-depth=3
    --number-sections
)

if [[ -f "references.bib" ]]; then
    PANDOC_ARGS+=(--citeproc --bibliography=references.bib)
fi

pandoc "${PANDOC_ARGS[@]}"

echo "=== [Step 4/5] Compiling Print-Ready PDF via LibreOffice ==="

mkdir -p "$BUILD_DIR"
LO_PROFILE=$(mktemp -d)

soffice -env:UserInstallation=file://"$LO_PROFILE" \
    --headless \
    --convert-to pdf \
    --outdir "$BUILD_DIR" \
    "$INTERMEDIATE_DOCX"

rm -rf "$LO_PROFILE" "$INTERMEDIATE_DOCX" "$COMBINED_MD"

echo "=== [Step 5/5] Verifying Final Output ==="

if [[ -f "$BUILD_DIR/temp_combined.pdf" ]]; then
    mv "$BUILD_DIR/temp_combined.pdf" "$FINAL_PDF"
    rmdir "$BUILD_DIR"
    echo "=== Success! KDP Print-Ready PDF Generated: ${FINAL_PDF} ==="
else
    echo "Error: PDF output file was not generated properly by LibreOffice."
    exit 1
fi
