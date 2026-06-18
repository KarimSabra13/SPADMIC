# MPTDC Visualization Tool

Author: Karim Sabra

This optional tool visualizes the MPTDC measurement flow for review and
presentation. It is not the source of truth for architecture, verification,
synthesis, timing, or PnR decisions.

Use the active handoff documents first:

- `MPTDC/HANDOFF.md`
- `MPTDC/docs/architecture/MPTDC_ARCHITECTURE.md`
- `MPTDC/docs/verification/MPTDC_VERIFICATION.md`
- `MPTDC/docs/synthesis/MPTDC_SYNTHESIS_FLOW.md`

## Scope

The active RTL boundary is `MPTDC/rtl/top/mptdc_axis_core.sv`. Any generated
diagram or JSON database from this tool must be regenerated from the current RTL
before it is used in a review. Old exported Markdown reports were removed during
documentation consolidation because they referenced retired MPTDC handoff docs.

## Regenerate

From the repository root:

```bash
python tools/mptdc_gui/rtl_parser.py --validate-ports
python tools/mptdc_gui/diagram_generator.py
```

If validation fails, fix the parser or explicitly mark the tool blocked. Do not
change RTL to satisfy this visualization tool.

## Web UI

```bash
cd tools/mptdc_gui/frontend
npm install
npm run dev
```

Open the Vite URL printed by the command, typically:

```text
http://127.0.0.1:5173
```

Static preview:

```bash
cd tools/mptdc_gui/frontend
npm run build
npm run preview
```

## Evidence Rule

Screenshots, generated JSON, CSV, SVG, PNG, and presentation exports are
generated artifacts. Keep them under a run directory or external review package;
do not treat them as maintained architecture documentation.
