# Design Language For Rich UI Office Files

Use this reference when the user wants output that feels premium, modern, branded, visual, or executive-ready.

## Core principle

Make the file feel designed on purpose. Avoid the untouched default look of Word themes, PowerPoint templates, spreadsheet grids, and generic PDF exports.

## Build a small system first

Define these choices before building the file:

- primary background color
- primary text color
- one accent color
- one muted neutral
- heading style
- body style
- table style
- chart style
- callout style

Keep the system small enough to repeat consistently.

## Layout patterns

Prefer these patterns over dense, uniform blocks:

- hero header with subhead and metadata row
- two-column summary sections
- card-based KPI strips
- section bands with strong labels
- sidebars for notes, assumptions, or next steps
- full-width charts paired with short narrative interpretation

## Format-specific UI moves

### DOCX

- Use a branded cover page and running header/footer
- Use table header fills, subtle row striping, and consistent spacing before/after headings
- Use callout tables or bordered text boxes for key findings

### PDF

- Preserve the intended page rhythm; do not let exported pages become text-heavy dumps
- Check page breaks and visual balance after export

### PPTX

- Use a grid and align to it strictly
- Limit each slide to one main message
- Give charts and metrics more room than decorative shapes

### XLSX

- Separate input, calculation, and output zones clearly
- Freeze panes and set print areas where useful
- Use chart titles, axis labels, and number formats that match the story

## Anti-patterns

Avoid:

- rainbow palettes
- too many font sizes
- center-aligning everything
- giant paragraphs in slides
- default Excel look with unstyled grids
- exporting to PDF before the editable source looks correct
