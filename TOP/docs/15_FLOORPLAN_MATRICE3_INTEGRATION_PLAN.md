# Floorplan Plan For `matrice3` Integration

Status: Phase 0 floorplan-aware implementation plan. Coordinates and pin groups come from the normalized matrix CSV.

## Source Data

Primary source:

`position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv`

Use normalized columns:

- `ll_center_x`
- `ll_center_y`
- `ll_bbox_*`

Do not use naive raw LEF coordinates without correcting for the non-zero origin.

Macro facts:

- macro: `matrice3`
- size: approximately `1999.91 um x 1725.54 um`
- LEF origin: `51.395, 65.86`
- pins: 565
- pin shapes: 567
- obstruction shapes: 1916

## Pin Family Classification

| Family | Count | Normalized side distribution |
| --- | ---: | --- |
| R | 64 | 50 TOP, 14 INTERNAL_NEAREST_RIGHT |
| Rz | 64 | 50 TOP, 14 INTERNAL_NEAREST_RIGHT |
| Y | 64 | 64 INTERNAL_NEAREST_RIGHT |
| Yz | 64 | 64 INTERNAL_NEAREST_RIGHT |
| B | 64 | 50 BOTTOM, 14 INTERNAL_NEAREST_RIGHT |
| Bz | 64 | 50 BOTTOM, 14 INTERNAL_NEAREST_RIGHT |
| Din | 44 | 44 BOTTOM |
| Cin | 44 | 44 BOTTOM |
| Dout | 44 | 44 TOP |
| Cout | 44 | 44 TOP |
| AVDD | 1 | LEFT |
| DVDD | 1 | TOP |
| VSS | 1 | LEFT |
| SUB | 1 | TOP |
| VTUNE | 1 | LEFT |

Key risk: several R/B and all Y/Yz pins are `INTERNAL_NEAREST_RIGHT`, so the floorplan must reserve routing corridors. Treating all matrix signals as simple edge pins is wrong.

## Placement Intent

- Place `matrice3` on the left side of the chip, roughly centered vertically.
- Place all three MPTDC blocks to the right of `matrice3` and close to each other.
- Keep final OR-tree buffers close to the MPTDC START inputs.
- Distribute early position/snapshot registers, AOR, and preprocessing near matrix pin banks where physically useful.
- Group the main cluster/packet position logic into a central digital block after the distributed front end.
- Place arbiter, FIFO, and DDR16 TX logic toward north-east/north because final DDR outputs are on the north side of the chip.
- Place control/reset/supervision registers toward the bottom of the matrix.
- Place PLL toward bottom-right.
- Reserve corridors for `INTERNAL_NEAREST_RIGHT` pins before routing dense MPTDC/position logic.

## OR64 Placement

R/Y/B OR trees must not share logic.

Recommended physical strategy:

- leaf OR groups close to the corresponding matrix pin banks or corridor exits;
- balanced logical depth within each axis;
- final local buffer near the MPTDC START input;
- comparable cell types and loads across equivalent stages;
- report line-to-line delay spread and axis-to-axis delay offset;
- preserve enough hierarchy or constraints so synthesis does not collapse the tree into an unreviewable position-dependent cone.

## Reset Output Placement

Rz/Yz/Bz registers and final buffers should be placed close to the corresponding matrix reset pin banks/corridors:

- Rz mostly top plus internal-right;
- Yz internal-right;
- Bz mostly bottom plus internal-right.

The path from reset-mask register to matrix pin should be short and physically reviewable. The design must not generate reset outputs directly from asynchronous event inputs.

## Matrix Configuration Placement

Din/Cin drivers:

- place near the lower matrix side where `Din/Cin` pins are located;
- generate clean clock/control outputs from `clk_cfg_40m` domain logic;
- avoid combinational clock gates.

Dout/Cout capture:

- place near top matrix pins;
- treat timing as non-signoff until macro handoff gives Dout/Cout delay and Cout meaning.

## Output Placement

The DDR final outputs are on the north side of the chip. Place:

- packet arbiter/FIFO toward north-east/north;
- DDR16 pairer close to the macro boundary;
- macro wrapper next to the final DDR macro/pad region.

Do not optimize the plan for a right-side DDR location from simplified diagrams.

## Open Floorplan Items

- Exact top-chip die outline.
- Exact `matrice3` instance coordinate.
- Required halo around `matrice3`.
- Pin-access blockages and obstruction keepouts.
- MPTDC macro orientation and relative order.
- Whether the three MPTDCs should be physically ordered R/Y/B top-to-bottom or simply tightly grouped.
- PLL keepout and clock routing rules.
- North DDR macro/pad placement details.
- Power-grid strategy for the left matrix and right digital regions.

## Verification Requirements

Floorplan review must check:

- use of `ll_*` normalized coordinates;
- preservation of `INTERNAL_NEAREST_RIGHT` corridors;
- no accidental reliance on raw LEF origin coordinates;
- OR64 trees physically balanced and reviewable;
- reset registers close to Rz/Yz/Bz banks;
- matrix configuration drivers near bottom pins and readback capture near top pins;
- no broad async false path hiding unreviewed START-tree delay spread.
