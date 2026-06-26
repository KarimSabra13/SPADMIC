# SPAD Matrix Abstract Handoff For Position PnR

Author: Karim Sabra

## Scope

The SPAD matrix physical layout is owned by the analog/layout side. Before the
digital position block can be floorplanned correctly, the digital flow needs a
geometry contract for that matrix:

- macro name,
- macro width and height,
- pin names,
- pin layers,
- exact pin rectangles or polygon bounding boxes,
- pin centers,
- pin side relative to the matrix boundary,
- X/Y/Z line index mapping,
- reset/control pin location,
- obstruction shapes if present in the abstract.

The first extraction target is the **LEF abstract**. If the available server
handoff is only OA or GDS, export a LEF abstract first using the analog/Cadence
environment, then run the scripts below on the LEF.

## Why This Comes Before Position PnR

The current RTL position block receives:

- `x_lines_i[63:0]`,
- `y_lines_i[63:0]`,
- `z_lines_i[63:0]`,
- and drives `spad_matrix_rst_o`.

The physical position implementation should not start as one blind rectangular
standard-cell block. The first physical problem is local to the matrix:

1. receive 192 async matrix line pins;
2. keep the first synchronizer stages close to the matrix exits;
3. preserve X/Y/Z line ordering and side grouping;
4. then move into the main position rectangle containing settle/filter,
   cluster scan, queue, CSR, and packetizer logic.

So the matrix abstract extract becomes the seed for:

- line-pin placement,
- synchronizer clustering,
- block-shape planning,
- reset pin placement,
- route length estimation,
- async-line CDC waiver documentation.

## Server Command

For the finalized matrix handoff, use the read-only directory inventory wrapper.
It scans the analog directory, writes nothing there, finds LEF/GDS/OAS/DEF/CDL
candidates, and parses all LEF abstracts it can find.

Run this on the server checkout that can see the analog handoff path:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only

MATRIX3_DIR=/group/validgmr/PROJET/Prj_xh018/spadmic/TOPLEVEL/matrice3

bash position/scripts/run_spad_matrix_final_layout_extract.sh \
  --source-dir "$MATRIX3_DIR" \
  --run-id 20260626_matrice3_final_extract \
  --svg-labels all
```

All outputs go under:

```text
work/position/matrix_handoff/20260626_matrice3_final_extract/
```

The script refuses to write inside `--source-dir`.

If the server path was typed with the older group spelling, first check which
directory exists:

```bash
ls -ld /group/validgmr/PROJET/Prj_xh018/spadmic/TOPLEVEL/matrice3
ls -ld /group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL/matrice3
```

Use the path that exists as `MATRIX3_DIR`.

The older LEF-only wrapper is still available when the exact abstract LEF is
already known:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only

bash position/scripts/run_spad_matrix_abstract_extract.sh \
  --lef /path/to/analog/SPAD_MATRIX_ABSTRACT.lef \
  --macro <macro_name_if_needed> \
  --run-id 20260619_spad_matrix_abstract
```

If the LEF contains only one macro, `--macro` can be omitted.

If the SVG is too dense and pin names are needed visually:

```bash
bash position/scripts/run_spad_matrix_abstract_extract.sh \
  --lef /path/to/analog/SPAD_MATRIX_ABSTRACT.lef \
  --macro <macro_name_if_needed> \
  --run-id 20260619_spad_matrix_abstract_labeled \
  --svg-labels all
```

Default output directory:

```text
work/position/matrix_handoff/<run_id>/
```

## Generated Files

| File | Purpose |
|------|---------|
| `matrix_handoff_report.md` | Human-readable summary and review flags |
| `matrix_macro_summary.json` | Full machine-readable macro/pin/shape payload |
| `matrix_pin_summary.csv` | One row per pin, with bbox, center, side, axis/index guess |
| `matrix_pin_shapes.csv` | One row per pin shape/rectangle |
| `matrix_pin_map.svg` | Visual macro outline, obstructions, and pins |
| `position_pnr_seed.tcl` | Tcl seed data for later Innovus floorplan work |
| `logs/extract_spad_matrix_abstract.log` | Reproducibility manifest and script log |

## First Review Checklist

Do not start custom position PnR until these are reviewed:

- macro name matches the analog matrix expected by TOP integration;
- macro width and height are plausible;
- total pin count is plausible;
- X/Y/Z guesses find 64 indices each, or missing/renamed pins are explained;
- `spad_matrix_rst_o` destination/reset pin is identified;
- line pins are on expected matrix sides, or internal pins are explained;
- pin layers are routable in the digital plan;
- no line bus appears reversed without documentation;
- obstruction shapes do not block the intended synchronizer ring;
- the extracted SVG agrees with the analog/layout owner's expectation.

## What To Send Back From The Server

After running the script, bring back at least:

```text
work/position/matrix_handoff/<run_id>/matrix_handoff_report.md
work/position/matrix_handoff/<run_id>/matrix_macro_summary.json
work/position/matrix_handoff/<run_id>/matrix_pin_summary.csv
work/position/matrix_handoff/<run_id>/matrix_pin_shapes.csv
work/position/matrix_handoff/<run_id>/matrix_pin_map.svg
work/position/matrix_handoff/<run_id>/position_pnr_seed.tcl
work/position/matrix_handoff/<run_id>/logs/extract_spad_matrix_abstract.log
```

The CSV/JSON are the important inputs for automated floorplan work. The SVG is
for fast human review with the analog designer.

## Expected Position PnR Direction After Extraction

Once the matrix pins are known, the position physical plan should be staged:

1. treat the SPAD matrix as a fixed physical anchor or obstruction;
2. create X/Y/Z line ingress regions around the macro sides;
3. place first/second synchronizer stages close to the corresponding matrix
   exits;
4. route the synchronized buses toward the main rectangular position block;
5. keep cluster scan, queue/FIFO, CSR/status, and packetizer logic in the main
   rectangle;
6. place `spad_matrix_rst_o` toward the analog matrix reset input;
7. time all logic after synchronizer stage 1 normally;
8. false-path only the async launch into stage 1.

This keeps the position block physically honest: the async analog boundary is
near the matrix, while the heavy digital scan/packet logic can be optimized as a
normal `clk_sys` block.
