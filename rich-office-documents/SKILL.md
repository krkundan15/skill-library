---
name: rich-office-documents
description: "Create rich UI office documents across DOCX, PDF, PPTX, and XLSX with a shared visual system, polished layouts, and format-specific workflows. Use when Codex needs to produce client-ready or executive-ready office files, multi-format document packs, branded reports, dashboard workbooks, visually strong presentations, or polished exports that should feel intentionally designed rather than plain."
---

# Rich Office Documents

Use this skill as the entry point for polished office-document work. Route to the existing format-specific skills after defining the visual system and deliverable strategy.

## Use this workflow

1. Identify the output set first: `docx`, `pdf`, `pptx`, `xlsx`, or a bundle.
2. Define a compact design brief before generating files:
   - audience
   - purpose
   - tone
   - brand or industry cues
   - palette
   - typography approach
   - recurring UI components such as title bands, callouts, cards, tables, dividers, charts
3. Read [`references/design-language.md`](references/design-language.md) when the user asks for "rich UI", "premium", "modern", "polished", "board-ready", or "client-ready" output.
4. Route to the format skill:
   - DOCX: read [`../docx/SKILL.md`](../docx/SKILL.md)
   - PDF: read [`../pdf/SKILL.md`](../pdf/SKILL.md)
   - PPTX: read [`../pptx/SKILL.md`](../pptx/SKILL.md)
   - XLSX: read [`../xlsx/SKILL.md`](../xlsx/SKILL.md)
5. Keep one shared design language across all outputs in the bundle.
6. Write every generated file and every intermediate artifact to `outputs/<document-name>/`.

## Routing rules

### DOCX

Choose DOCX for editable reports, proposals, briefs, policies, manuals, and narrative documents.

Prefer:
- cover pages
- section dividers
- strong heading hierarchy
- branded tables
- pull quotes or callout boxes
- icon-and-text summary rows

For new DOCX files, use the format skill's document-creation workflow. For edits to formal or third-party files, default to tracked changes.

### PDF

Choose PDF for fixed-layout handoffs, print-ready deliverables, forms, and non-editable exports.

For visually rich PDFs, prefer designing in an authoring format first and exporting only when that improves fidelity:
- PPTX to PDF for presentation-like reports
- DOCX to PDF for narrative reports
- direct PDF workflow for forms, merging, extraction, and PDF-native operations

### PPTX

Choose PPTX for storytelling, executive updates, sales decks, training materials, and visual summaries.

Default to the `html2pptx` workflow for new high-design decks. Treat slide design as UI work: hierarchy, spacing, contrast, and intentional color usage matter more than adding decorative elements.

### XLSX

Choose XLSX for dashboards, operating models, trackers, calculators, and structured data outputs.

Use formulas instead of hardcoded calculations. Add a presentation layer when appropriate:
- title sheet
- assumptions sheet
- dashboard sheet
- clearly separated input, calc, and output areas
- conditional formatting and chart styling that matches the design brief

## Multi-format bundles

When the request spans multiple file types:

1. Define the shared visual system once.
2. Choose one "source of truth" artifact for the content structure.
3. Reuse the same titles, metric naming, colors, and chart logic across formats.
4. Export a PDF only after the editable source files are correct.

Recommended patterns:
- `pptx + pdf` for board decks and sales decks
- `docx + pdf` for proposals and reports
- `xlsx + pptx` for dashboards plus executive summary
- `xlsx + docx + pdf` for financial or operational report packs

## Quality bar

Require these qualities in all outputs:

- intentional layout, not default templates
- consistent spacing and alignment
- readable contrast
- restrained palette with 1-2 accent colors
- tables and charts styled to match the document
- no placeholder copy, clipped text, or broken formulas

If the design quality is weak, revise the source file rather than shipping a plain default export.
