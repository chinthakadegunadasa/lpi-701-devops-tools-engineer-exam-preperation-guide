#!/usr/bin/env bash
set -euo pipefail

INTERMEDIATE_DOCX="temp_combined.docx"
FINAL_PDF="LPIC-701-Exam-Guide-KDP.pdf"
BUILD_DIR="build_out"
COMBINED_MD="combined_manuscript.md"
REF_DOC="reference.docx"

echo "=== [Step 1/5] Checking Reference Template ==="

# Generate reference.docx from Chapter1.md if missing
if [[ ! -f "$REF_DOC" ]]; then
    if [[ -f "Chapter1.md" ]]; then
        echo "Generating reference.docx baseline from Chapter1.md..."
        pandoc Chapter1.md \
            --from=markdown \
            --to=docx \
            --output="$REF_DOC" \
            --variable=geometry:"paperwidth=176mm,paperheight=250mm,left=0.8in,right=0.6in,top=0.8in,bottom=0.8in" \
            --variable=mainfont="Cambria" \
            --variable=sansfont="Calibri" \
            --variable=monofont="Consolas" \
            --variable=fontsize=11pt \
            --variable=linestretch=1.15 \
            --variable=alignment=justified
    else
        echo "Warning: Chapter1.md not found. Generating default reference.docx..."
        pandoc --print-default-data-file reference.docx > "$REF_DOC"
    fi
else
    echo "Using existing $REF_DOC."
fi

echo "=== [Step 2/5] Assembling Chapters with Strict \\newpage Breaks ==="

# Identify README / Frontmatter
FILES=()
if [[ -f "README.md" ]]; then
    FILES+=("README.md")
fi

# Collect all Chapter files in natural numeric order
while IFS= read -r file; do
    FILES+=("$file")
done < <(find . -maxdepth 1 -name "Chapter*.md" | sort -V)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: No Chapter*.md or README.md files found!"
    exit 1
fi

echo "Processing source files in order: ${FILES[*]}"

# Build combined manuscript with explicit \newpage tags before each chapter
> "$COMBINED_MD"

first_file=true
for f in "${FILES[@]}"; do
    if [ "$first_file" = true ]; then
        cat "$f" >> "$COMBINED_MD"
        first_file=false
    else
        # Explicitly inject \newpage tag before each chapter
        echo -e "\n\n\\newpage\n\n" >> "$COMBINED_MD"
        cat "$f" >> "$COMBINED_MD"
    fi
done

# Append references section on a new page if a BibTeX file or embedded references exist
if [[ -f "references.bib" ]] || grep -q "### References" "Chapter1.md" 2>/dev/null; then
    echo -e "\n\n\\newpage\n\n# References\n" >> "$COMBINED_MD"
fi

echo "=== [Step 3/5] Generating Justified OpenXML DOCX via Pandoc ==="

PANDOC_ARGS=(
    "$COMBINED_MD"
    --from=markdown
    --to=docx
    --output="$INTERMEDIATE_DOCX"
    --reference-doc="$REF_DOC"
    --variable=geometry:"paperwidth=176mm,paperheight=250mm,left=0.8in,right=0.6in,top=0.8in,bottom=0.8in"
    --variable=lang=en-US
    --variable=alignment=justified
    --toc
    --toc-depth=3
    --number-sections
)

# Enable automatic bibliography processing if references.bib exists
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
