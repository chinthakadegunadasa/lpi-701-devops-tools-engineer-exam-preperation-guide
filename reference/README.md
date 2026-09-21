To generate a customized `reference.docx` template using **`Chapter1.md`** as your baseline document, you can use Pandoc to convert `Chapter1.md` into DOCX format. Once converted, you can open that `.docx` file in LibreOffice Writer or Microsoft Word, adjust all required styles (such as paragraph spacing, auto-hyphenation, page numbers, and code block formatting), and save it as your master `reference.docx` template.

Here is the step-by-step workflow:

---

### Step 1: Generate the Base DOCX from `Chapter1.md`

Run the following command in your terminal to create the initial document:

```bash
pandoc Chapter1.md -o reference.docx

```

---

### Step 2: Configure Styles in `reference.docx`

Open `reference.docx` in LibreOffice Writer or Microsoft Word to set up all the formatting rules required for your Amazon KDP release:

1. **Page Geometry & Margins (B5 Format):**
* Go to **Format $\rightarrow$ Page Style** (or **Page Setup** in Word).
* Set Width: `176 mm` (6.93 in), Height: `250 mm` (9.84 in).
* Margins: Inside (Left) = `0.8 in` ($20.32\text{ mm}$ for binding gutter), Outside (Right) = `0.6 in` ($15.24\text{ mm}$), Top = `0.8 in`, Bottom = `0.8 in`.


2. **Body Text Style (`Normal` or `Text Body`):**
* **Font:** Cambria, 11pt.
* **Line Spacing:** 1.15 lines.
* **Paragraph Spacing:** Set Space Before and Space After to `0.03 in` (`2.16 pt`).
* **Auto-Hyphenation:** Turn on **Automatic Hyphenation** for the `Normal` / `Text Body` paragraph style.


3. **Code Blocks (`Source Code` / `Preformatted Text`):**
* **Font:** Consolas (or Courier New), 9.5pt.
* **Hyphenation:** **Disable Auto-Hyphenation** specifically for this style so command lines and technical paths do not break unexpectedly.


4. **Footer Page Numbering:**
* Insert a **Footer** on the page style.
* Center-align the footer text and insert the **Page Number** field code.
* Set page numbering to restart at `1` starting on Chapter 1.


5. **Image & Tagline Alignment:**
* Select paragraph properties for inserted images and captions/taglines and set alignment to **Center**.


6. **Save Changes:**
* Save and close `reference.docx`.



---

### Step 3: Run the Automated Bash Command

If you want an all-in-one terminal command to extract default reference styles, create `reference.docx` from `Chapter1.md`, and verify it before compilation, run:

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "Chapter1.md" ]]; then
    echo "Error: Chapter1.md not found in the current directory!"
    exit 1
fi

echo "=== Generating reference.docx from Chapter1.md ==="

# Convert Chapter1.md directly into reference.docx
pandoc Chapter1.md \
    --from=markdown \
    --to=docx \
    --output=reference.docx \
    --variable=geometry:"paperwidth=176mm,paperheight=250mm,left=0.8in,right=0.6in,top=0.8in,bottom=0.8in" \
    --variable=mainfont="Cambria" \
    --variable=sansfont="Calibri" \
    --variable=monofont="Consolas" \
    --variable=fontsize=11pt \
    --variable=linestretch=1.15

echo "=== Success: reference.docx created! ==="
echo "You can now pass '--reference-doc=reference.docx' in your main Pandoc build script."

```
