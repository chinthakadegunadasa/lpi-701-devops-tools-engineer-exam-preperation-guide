#!/usr/bin/env bash
set -euo pipefail

INTERMEDIATE_DOCX="temp_combined.docx"
FINAL_PDF="LPIC-701-Exam-Guide-KDP.pdf"
BUILD_DIR="build_out"
COMBINED_MD="combined_manuscript.md"
REF_DOC="reference.docx"

echo "=== [Step 1/5] Force Removing & Rebuilding reference.docx ==="

# 1. Force removal of old reference.docx
if [[ -f "$REF_DOC" ]]; then
    echo "Force deleting existing $REF_DOC..."
    rm -rf "$REF_DOC"
fi

# Ensure file is completely gone before proceeding
if [[ -f "$REF_DOC" ]]; then
    echo "Error: Failed to delete $REF_DOC. Check file permissions or open locks."
    exit 1
fi

# 2. Generate raw reference.docx from Chapter1.md or pandoc defaults
if [[ -f "Chapter1.md" ]]; then
    echo "Generating base $REF_DOC from Chapter1.md..."
    pandoc Chapter1.md -o "$REF_DOC"
else
    echo "Warning: Chapter1.md not found. Generating default reference.docx..."
    pandoc --print-default-data-file reference.docx > "$REF_DOC"
fi

# 3. Modify internal XML attributes directly using python-docx
python3 - << 'EOF'
import sys
import docx
from docx.shared import Inches, Pt, Mm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

try:
    doc = docx.Document('reference.docx')

    # Force Page Setup (B5: 176mm x 250mm & Margins)
    for section in doc.sections:
        section.page_width = Mm(176)   # B5 Width
        section.page_height = Mm(250)  # B5 Height
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)   # Inside/Gutter
        section.right_margin = Inches(0.6)  # Outside

    # Force Justification & Font on Normal Style
    style_normal = doc.styles['Normal']
    style_normal.font.name = 'Cambria'
    style_normal.font.size = Pt(11)
    
    p_format = style_normal.paragraph_format
    p_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p_format.line_spacing = 1.15
    p_format.space_after = Pt(2.16) # 0.03 in

    # Direct XML modification for Default Paragraph Justification (w:jc)
    pPr = style_normal._element.get_or_add_pPr()
    jc = OxmlElement('w:jc')
    jc.set(qn('w:val'), 'both')  # 'both' equals Fully Justified in OpenXML
    pPr.append(jc)

    # Configure Code Block Styles
    for style_name in ['Source Code', 'Preformatted Text', 'CodeBlock']:
        if style_name in doc.styles:
            code_style = doc.styles[style_name]
            code_style.font.name = 'Consolas'
            code_style.font.size = Pt(9.5)
            # Disable justification for code blocks
            code_pPr = code_style._element.get_or_add_pPr()
            code_jc = OxmlElement('w:jc')
            code_jc.set(qn('w:val'), 'left')
            code_pPr.append(code_jc)

    doc.save('reference.docx')
    print("Direct XML configuration applied successfully to reference.docx")
except Exception as e:
    print(f"Error updating reference.docx XML properties: {e}", file=sys.stderr)
    sys.exit(1)
EOF

# 4. Strict Validation Verification
if [[ -f "$REF_DOC" ]] && [[ $(wc -c < "$REF_DOC") -gt 5000 ]]; then
    echo "=== Verification Passed: $REF_DOC rebuilt cleanly ($(du -h "$REF_DOC" | cut -f1)) ==="
else
    echo "Error: $REF_DOC build failed or created invalid output."
    exit 1
fi

echo "=== [Step 2/5] Assembling Chapters with Page Breaks ==="

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

# Concatenate files with raw OpenXML/Pandoc page breaks
> "$COMBINED_MD"

first_file=true
for f in "${FILES[@]}"; do
    if [ "$first_file" = true ]; then
        cat "$f" >> "$COMBINED_MD"
        first_file=false
    else
        # Inject explicit Pandoc PageBreak tag
        echo -e "\n\n```{=openxml}\n<w:p><w:r><w:br w:type=\"page\"/></w:r></w:p>\n```\n\n" >> "$COMBINED_MD"
        cat "$f" >> "$COMBINED_MD"
    fi
done

if [[ -f "references.bib" ]] || grep -q "### References" "Chapter1.md" 2>/dev/null; then
    echo -e "\n\n```{=openxml}\n<w:p><w:r><w:br w:type=\"page\"/></w:r></w:p>\n```\n\n# References\n" >> "$COMBINED_MD"
fi

echo "=== [Step 3/5] Compiling Intermediate DOCX with Pandoc ==="

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

echo "=== [Step 4/5] Rendering Print-Ready PDF via LibreOffice ==="

mkdir -p "$BUILD_DIR"
LO_PROFILE=$(mktemp -d)

soffice -env:UserInstallation=file://"$LO_PROFILE" \
    --headless \
    --convert-to pdf \
    --outdir "$BUILD_DIR" \
    "$INTERMEDIATE_DOCX"

rm -rf "$LO_PROFILE" "$INTERMEDIATE_DOCX" "$COMBINED_MD"

echo "=== [Step 5/5] Final Verification ==="

if [[ -f "$BUILD_DIR/temp_combined.pdf" ]]; then
    mv "$BUILD_DIR/temp_combined.pdf" "$FINAL_PDF"
    rmdir "$BUILD_DIR"
    echo "=== Success! KDP Print-Ready PDF Generated: ${FINAL_PDF} ==="
else
    echo "Error: PDF output file was not generated properly by LibreOffice."
    exit 1
fi
