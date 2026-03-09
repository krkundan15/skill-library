# Office Document Skills for Codex

Professional Office document creation and editing workflows for the command line, packaged as Codex skills.

## What is this?

This repository packages Office document manipulation skills for Codex. It includes format-specific skills for Word, PDF, PowerPoint, and Excel plus an umbrella `rich-office-documents` skill for polished, UI-forward deliverables.

## Supported Formats

- **Rich Office Documents** - One entry skill that routes polished, client-ready document requests across formats
- **PowerPoint (PPTX)** - Create presentations from scratch or templates, with HTML-to-PPTX conversion
- **Word (DOCX)** - Edit documents with tracked changes, OOXML manipulation, redlining workflows
- **Excel (XLSX)** - Build financial models with formulas, formatting, and zero-error validation
- **PDF** - Fill forms, merge documents, extract data, convert to images

## Key Capabilities

### PowerPoint

- **HTML-to-PPTX conversion** - Design slides in HTML/CSS, render to PPTX with full formatting
- **Template-based creation** - Rearrange slides, replace text with JSON, preserve formatting
- **Visual validation** - Generate thumbnail grids to catch text cutoff and layout issues
- **OOXML editing** - Direct XML manipulation for precise control

### Word

- **Tracked changes (redlining)** - Professional document editing with change tracking
- **OOXML manipulation** - Add comments, modify structure, preserve formatting
- **Text extraction** - Export content with tracked changes preserved

### Excel

- **Formula-based models** - Working formulas with zero-error requirement
- **Professional formatting** - Color-coded inputs/formulas, custom number formats
- **Data validation** - Years as text, zeros formatted as "-", proper cell styling

### PDF

- **Form filling** - Populate fillable PDFs programmatically
- **Document merging** - Combine multiple PDFs
- **Format conversion** - PPTX to PDF, PDF to images
- **Data extraction** - Pull information from PDF forms and documents

## Getting Started

### Use with Codex

Copy the skill folders in this repository directly into your Codex skills directory, typically `$CODEX_HOME/skills/` or `~/.codex/skills/`.

This repository is now laid out for direct drop-in: the skill folders already live at the repository root.

Recommended skills:

- `docx`
- `pdf`
- `pptx`
- `xlsx`
- `rich-office-documents`

Example prompts:

```text
Use $rich-office-documents to create a polished quarterly business review deck and matching PDF.
Use $docx to draft a branded proposal document with a cover page and tracked changes ready for review.
Use $xlsx to build an executive KPI dashboard workbook with formulas and presentation-quality charts.
```

### Prerequisites

```bash
# Python dependencies
venv/bin/pip install -r requirements.txt

# Node.js dependencies (for html2pptx)
npm install

# System tools (usually pre-installed)
# - LibreOffice (soffice)
# - Poppler (pdftoppm)
# - Pandoc
```

### Using with Codex

Simply tell Codex what you want to create:

```text
> Use $rich-office-documents to create a quarterly sales presentation with 5 slides and export a matching PDF
> Use $pptx to create a powerpoint presentation based on @input/slide_notes.txt
> Use $docx to edit this Word document and add tracked changes
> Use $xlsx to build an Excel financial model for budget projections
> Use $pdf to fill out this PDF form with data from this JSON
```

Codex will:

1. Check if a skill exists for your task
2. Read the appropriate `SKILL.md` workflow
3. Execute the workflow step-by-step
4. Save all outputs to `outputs/<document-name>/`

### Manual Usage

All scripts can also be run directly:

```bash
# Create PowerPoint thumbnail grid
venv/bin/python pptx/scripts/thumbnail.py template.pptx outputs/review/thumbnails

# Rearrange slides
venv/bin/python pptx/scripts/rearrange.py template.pptx outputs/deck/final.pptx 0,5,5,12,3

# Extract text inventory
venv/bin/python pptx/scripts/inventory.py deck.pptx outputs/deck/inventory.json

# Replace text from JSON
venv/bin/python pptx/scripts/replace.py input.pptx outputs/deck/replacements.json outputs/deck/output.pptx
```

## Repository Structure

```text
rich-office-documents/ # Umbrella skill for polished multi-format outputs
pptx/                  # PowerPoint workflows
docx/                  # Word workflows
pdf/                   # PDF workflows
xlsx/                  # Excel workflows

outputs/               # Your generated documents (gitignored)
└── <project-name>/    # One directory per document
```

## Skill Testing Loop

This repo now includes a reusable skill evaluation harness at `tools/skill_feedback_loop.py`.
It creates a repeatable loop for:

1. writing a standard prompt for a skill test case
2. capturing the generated output
3. recording human feedback in a structured JSON file
4. producing the next revision prompt from that feedback
5. summarizing recurring issues into skill enhancement recommendations

### Quick Start

Use the sample suite for `rich-office-documents`:

```bash
python tools/skill_feedback_loop.py init --config evals/rich-office-documents.sample.json
```

This creates a run folder under `outputs/skill-tests/<run-name>/` with:

- `cases/<case-id>/iteration-01/prompt.txt`
- `cases/<case-id>/iteration-01/output.md`
- `cases/<case-id>/iteration-01/feedback.template.json`
- `summary.md`

### Human Review Loop

1. Run the prompt in your preferred model or workflow.
2. Replace `output.md` with the generated output if the harness did not do that automatically.
3. Copy `feedback.template.json` to `feedback.json` and fill in:
   - `approved`
   - `score`
   - `summary`
   - `items[]` with `severity`, `category`, `issue`, and `desired_change`
4. Advance the loop:

```bash
python tools/skill_feedback_loop.py advance --run-dir outputs/skill-tests/<run-name>
```

The next iteration prompt includes:

- the original prompt
- the previous output
- the human feedback summary
- the required fixes for the next run

Refresh the summary at any time:

```bash
python tools/skill_feedback_loop.py summarize --run-dir outputs/skill-tests/<run-name>
```

### Optional Command-Based Generation

If you want the harness to invoke a generator automatically, add a `generator` block to your JSON config:

```json
{
  "generator": {
    "command": "your-command-here --prompt-file \"{prompt_file}\"",
    "shell": true
  }
}
```

Template values available in the command:

- `{skill_name}`
- `{skill_path}`
- `{case_id}`
- `{iteration}`
- `{prompt_file}`
- `{output_file}`
- `{run_dir}`

The harness also exports matching `SKILL_EVAL_*` environment variables for external tools.

## How It Works

Each format has a `SKILL.md` file that defines the workflow. Codex:

1. **Checks for skills** - Before writing custom code, checks if a skill exists
2. **Reads the skill** - Loads the complete workflow from `SKILL.md`
3. **Follows the skill** - Executes each step precisely
4. **Validates outputs** - Runs validation scripts where available
5. **Organizes files** - All outputs go to `outputs/<document-name>/`

### Example: Creating a Presentation from Template

```bash
# 1. Extract template text
venv/bin/python -m markitdown template.pptx

# 2. Generate thumbnails
venv/bin/python pptx/scripts/thumbnail.py template.pptx outputs/sales-deck/thumbnails

# 3. Rearrange slides
venv/bin/python pptx/scripts/rearrange.py template.pptx outputs/sales-deck/working.pptx 0,15,15,23,8

# 4. Extract text inventory
venv/bin/python pptx/scripts/inventory.py outputs/sales-deck/working.pptx outputs/sales-deck/inventory.json

# 5. Generate replacement JSON
# Creates outputs/sales-deck/replacements.json

# 6. Apply replacements
venv/bin/python pptx/scripts/replace.py outputs/sales-deck/working.pptx outputs/sales-deck/replacements.json outputs/sales-deck/final.pptx
```

Codex handles these steps automatically when you ask it to create a presentation.

## Why Use This?

### Codex Is Great For

- **Automation** - Generate monthly reports, process batches of documents
- **Custom workflows** - Combine with other tools (databases, APIs, scripts)
- **Server environments** - Run headless without desktop GUI
- **Template iteration** - Rapidly test changes to document templates

## Use Cases

- **Automated reporting** - Generate weekly or monthly presentations from database data
- **Batch processing** - Convert large sets of HTML pages to PPTX slides
- Create sales decks based on product data pulled from a RAG system
- **Document pipelines** - Pull data, populate Excel, generate PDF, and send downstream
- **API integration** - Trigger document generation from webhooks or jobs
- Learn how to build similar agents for other tasks

## Documentation

- **Getting started**: See `codex.md` for repository conventions
- **Workflows**: Each root-level skill folder contains its own `SKILL.md`
- **Skills system**: `skills-system.md` explains the skills-check pattern

## Output Directory Convention

All generated files go to `outputs/<document-name>/`:

```text
outputs/
├── quarterly-sales-report/
│   ├── final.pptx
│   ├── thumbnails_grid.png
│   ├── inventory.json
│   └── replacements.json
├── employee-handbook/
│   ├── handbook.docx
│   └── unpacked/
└── budget-2024/
    └── budget.xlsx
```

This keeps your working directory clean and makes automation easier.

## Attribution

Most scripts and workflows in this repository come directly from Claude (Anthropic's AI assistant) and are included here verbatim. If Anthropic wishes for this repository to be taken down, please contact the repository owner.

## Contributing

This is a skills repository. To add capabilities:

1. Add scripts to `<format>/scripts/`
2. Document them in the appropriate `SKILL.md`
3. Update `codex.md` with new commands
4. Ensure validation scripts pass
