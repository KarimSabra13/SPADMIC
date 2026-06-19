# MPTDC PnR Flow

Author: Karim Sabra

This document defines the physical-implementation path for the active
`mptdc_axis_core` digital block. It separates the existing typical Innovus
helpers from the required digital signoff flow. A feasibility result must not be
renamed into signoff.

## Current Status

The active digital-PNR preparation state is:

- Reviewed PNR source HEAD: `eb7a2c0fc66ff9daffa0751bc683c3d68df8d649`.
- Genus handoff run: `20260618_axis_core_typical_closed_bujihd_846a580d`.
- Setup WNS: `+0.3 ps`.
- Setup TNS: `-0.0 ps`.
- Setup violations: `0`.
- Max transition/capacitance/fanout violations: `0 / 0 / 0`.
- PD Vernier exception: 64 paths from 8 sources, no overmatch, no undermatch.
- Local ON22 repair: 355 `ON22JIHDX0` instances changed to `ON22JIHDX1`.
- Pre-PnR gate: PASS, with low-WNS warning.
- Phase-buffer topology: `BUJIHDX4 -> BUJIHDX12`.
- Row-infrastructure status: PROVISIONAL, because no dedicated CORE tap/endcap
  master was found and DRC/LVS qualification is still required.

This is enough to launch implementation under the reviewed provisional row
policy. It is not enough to claim final digital PNR PASS.

## Owner-Facing Commands

Run from the repository root on the Cadence server:

```bash
# 1. Discover real physical-cell names from the installed PDK inputs when the
#    PDK installation changes.
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  20260618_mptdc_digital_signoff_discovery \
  --mode discover_only

# 2. Rerun Genus after RTL/netlist changes.
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh \
  <fresh_genus_run_id>

# 3. Build the handoff package and gate it.
bash MPTDC/pnr/scripts/prepare_mptdc_genus_typical_handoff.sh \
  <fresh_genus_run_id>
bash MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh \
  --genus-run-id <fresh_genus_run_id> \
  --handoff-dir <handoff_dir>

# 4. Validate digital PNR sources without launching Innovus.
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  <digital_signoff_validate_run_id> \
  --mode validate_only \
  --genus-run-id <fresh_genus_run_id> \
  --handoff-dir <handoff_dir>

# 5. Launch implementation under the provisional row policy after review.
export MPTDC_DIGITAL_SIGNOFF_APPROVED=1
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  <digital_signoff_run_id> \
  --mode full_signoff \
  --genus-run-id <fresh_genus_run_id> \
  --handoff-dir <handoff_dir>

# 6. Package the row-infrastructure DRC/LVS qualification request/evidence.
bash MPTDC/pnr/scripts/qualify_xh018_row_infrastructure.sh \
  <row_qualification_run_id>
```

The digital signoff wrapper records tool versions and rejects a dirty tracked
source tree. `full_signoff` is an explicit Innovus implementation launch, but
the resulting digital PNR status remains PROVISIONAL until row and final block
DRC/LVS evidence are clean.

## Physical Intent

The block must be horizontally elongated. The final MPTDC boundary target is:

```text
width / height = 4 / 3 = 1.333333
allowed range = 1.20 .. 1.47
```

The automatic dimensioning logic must account for standard-cell area, two
`RO_tune4` macros, halos, phase-buffer rows, the full PD island, east-side
backend, route channels, power structures, IO pin capacity, target utilization,
and guard bands.

Initial density policy:

- core utilization target: `0.60`;
- normal adjustment range: `0.58 .. 0.62`;
- `0.65` maximum only as a labelled experiment;
- moderate placement density to preserve routability.

Optimization priority is:

1. timing and measurement symmetry;
2. area;
3. routability;
4. power.

Area must not be reduced by destroying phase symmetry or the already tiny timing
margin.

## Measurement Stack

The intended north-to-south stack is:

```text
north boundary
  slow RO_tune4, orientation R0
  slow isolation buffer row
  slow final-driver row
  8 x 8 PD detector matrix
  fast final-driver row
  fast isolation buffer row
  fast RO_tune4, orientation MX
south boundary
```

The RO `S[0:7]` pins should face the PD matrix. The RO `code[7:0]` pins should
face away from the PD matrix and toward the corresponding external/local-code
region. The backend region belongs on the east side and contains ordinary
`clk_sys` logic, drain, context bank, FIFO, packet readout, and control/status.

Counters and local tag logic may sit near the oscillator or PD column when that
improves timing and preserves symmetry.

## PD Matrix

The physical matrix represents all pairs:

```text
slow phase ns = 0..7
fast phase nf = 0..7
```

There must be exactly 64 identifiable tiles. The implementation must document
which physical axis maps to `ns` and which maps to `nf`. Do not assume the
hierarchical `u_pd` instance is directly placeable; discover and constrain the
leaf cells belonging to each tile.

Required checks:

- exactly 64 tiles found;
- no tile outside its assigned matrix location;
- uniform tile dimensions;
- uniform internal leaf-cell count unless an RTL difference is proven;
- regular row and column pitch;
- no backend cell inside a PD tile;
- no unexplained orientation difference;
- no unplaced or out-of-core leaf cell.

## Phase Buffers

Each raw tap must keep the same topology:

```text
RO_tune4/S[n] -> isolation buffer -> final driver -> phase consumers
```

Required counts:

- 8 slow raw taps;
- 8 fast raw taps;
- 16 isolation stages;
- 16 final-driver stages.

If valid JIHD `BUJIHDX4` and `BUJIHDX12` equivalents exist in both LEF and
Liberty, propose a uniform JIHD topology before changing the netlist. If they do
not exist, retaining `BUHDX4/BUHDX12` requires evidence that both masters are
loaded, legal, site-compatible, PG-connected, and not unresolved black boxes.
The 2026-06-18 JIHD discovery proved `BUJIHDX4` and `BUJIHDX12` in the exact
JIHD LEF and all 1.8 V JIHD Liberty corners. Switching to that uniform topology
is therefore the preferred next netlist experiment, but it still invalidates the
old Genus handoff and requires a fresh Genus closure run.

Raw RO nets must not receive arbitrary buffering. Any route promotion, shielding,
resizing, antenna repair, or extra stage on phase nets must be reviewed for
symmetry and should be applied equivalently across the affected tap family.

Target phase-family matching after extraction:

- capacitance spread <= 10%;
- route-delay spread <= 10%;
- route-length spread <= 10%;
- identical buffer-stage count;
- equivalent routing-layer sequence;
- nearly equivalent via count.

Also report absolute worst mismatch in ps, fF, micrometres, and via count.

## RO Code Placement

TOP-owned CSR values feed `ro_slow_code_i[7:0]` and `ro_fast_code_i[7:0]` into
each product axis. `mptdc_core` captures them into local shadow registers only
while idle, and the local registers drive `RO_tune4/code[7:0]`.

Place the slow local code registers near the external/code side of the slow RO.
Place the fast local code registers near the external/code side of the fast RO.
The long TOP/CSR routes may reach those registers; the short register-to-RO
nets are the load-sensitive physical interface.

## Backend Separation

The measurement island must be visually and physically distinct from the
east-side backend. Normal backend buses should not cross over or under the PD
matrix when a reasonable alternative exists.

Create route blockages or restrictions for lower metals over the matrix where
practical. Allowed crossings must be classified. The final crossing report must
use:

- `ALLOWED_MEASUREMENT_CROSSING`;
- `APPROVED_CRITICAL_EXCEPTION`;
- `UNEXPECTED_BACKEND_CROSSING`.

`UNEXPECTED_BACKEND_CROSSING` must be empty for PASS.

## IO Pin Plan

Use a functional pin plan with explicit exceptions:

- west: detector-facing asynchronous START/STOP/CAL inputs;
- north: packet outputs and status outputs;
- east: `clk_sys`, packet ready, input select, conversion arm, FIFO clear,
  soft reset, max-hit/config control;
- north or nearest clean slow-side segment: `ro_slow_code_i[7:0]`;
- south or nearest clean fast-side segment: `ro_fast_code_i[7:0]`;
- south: `async_rst_n` and selected low-priority controls.

Power pins are not ordinary signal pins. Create wide VDD/VSS access shapes on
east/south boundaries aligned with the power ring and parent integration.

## Power Plan

The digital implementation uses VDD = 1.8 V and VSS = ground. RO `VDD` and
`vdd!` must connect to VDD; RO VSS must connect to VSS. No RO pin may connect to
a 3.3 V rail.

Required implementation evidence:

- core ring;
- regular straps;
- standard-cell rail connection;
- macro pin connection;
- east/south block PG access;
- zero unconnected PG pins;
- zero special-route opens;
- zero accidental shorts.

Tap, endcap, tie, filler, decap, and antenna cells must be discovered from the
exact physical collateral used by the run. The 2026-06-18 JIHD-only discovery
proved JIHD decaps, antenna cells, `LOGIC0/LOGIC1` tie candidates,
`CLKVBUFJIHD`, `INJIHDX*`, and `BUJIHDX4/BUJIHDX12`; it did not find tap,
endcap, or row-filler cells in the JIHD standard-cell LEF. The 2026-06-19
all-LEF row audit proved JIHD `FEED*` CORE fillers on `core_jihd` and JIHD
stdcell PG pins `vddi/gndi`, but found no CORE tap/endcap macros. The many
IO `CORNER*`/ENDCAP macros are pad-ring cells and are not accepted as
core-row tap/endcap infrastructure.

`MPTDC/pnr/config/xh018_cells.tcl` therefore uses a per-class reviewed policy:
JIHD filler/spacer/decap/antenna/tie/CTS/phase-buffer classes require real
masters, while tap/endcap classes use
`NO_DEDICATED_MASTER_PENDING_DRC_LVS`. This policy allows implementation only
when `MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1` is set. It does not allow final
PASS until DRC/LVS proves no floating wells and legal row edges.

The standard-cell PG mapping is:

```text
globalNetConnect VDD -type pgpin -pin vddi -inst *
globalNetConnect VSS -type pgpin -pin gndi -inst *
RO VDD  -> VDD
RO vdd! -> VDD
RO VSS  -> VSS
```

Global-net-connect failures must be reported, not hidden.

If no RO current model is available, do not block the rest of PnR. Report:

```text
RO_EM_IR_MODEL=NOT_AVAILABLE
RO_INTERNAL_EM_IR_SIGNOFF=EXTERNAL_OR_DEFERRED
```

## CTS Policy

Run real CTS for `clk_sys` only. The following clocks must not be included in
ordinary CTS:

- `clk_osc_slow`;
- `clk_osc_fast`;
- `clk_osc_slow_tap*`;
- `clk_osc_fast_tap*`;
- `clk_osc_*_buf_tap*`.

Do not use `set_ideal_network` on routed RO or phase networks for final STA.
Exclude them from CCOpt while keeping them propagated and RC-visible.

Moderate CTS targets:

- target skew: `0.15 ns`;
- pass maximum measured skew: `0.20 ns`;
- target maximum clock transition: `0.35 ns`.

Any CTS skip, ambiguous clock-tree spec, or RO-clock inclusion is a hard fail in
digital signoff.

## MMMC and Timing

The PnR signoff setup must include:

- `TC_NOMINAL`: JIHD typical Liberty, typical RC, nominal constraints;
- `WC_SETUP`: JIHD slow Liberty, worst RC, setup analysis;
- `BC_HOLD`: JIHD fast Liberty, best RC, hold analysis;
- `RO_MAX_FREQ_STRESS`: report-only 1.000 ns oscillator-domain stress overlay.

Use only PDK-supplied cap tables, QRC tech files, and variation data. Do not
invent OCV/AOCV/POCV/derates.

Temporary nominal oscillator assumptions:

- slow period: `1.430 ns`;
- fast period: `1.333 ns`.

Temporary IO model:

```text
MPTDC_PNR_IO_LOAD_CLASS=medium
output_load=0.0256 pF
IO_BUDGET_PROVISIONAL=YES
```

The final digital timing claim is therefore under documented RO period and IO
load assumptions until characterized RO PVT and final parent-level budgets are
available.

## Signoff Evidence

Final status must be reported as separate keys, never one vague READY label:

```text
PRE_PNR_GATE_STATUS
GENUS_HANDOFF_STATUS
ROW_INFRA_POLICY_STATUS
ROW_INFRA_DRC_LVS_STATUS
PHYSICAL_CELL_CONFIG_STATUS
PG_CONNECTIVITY_STATUS
FLOORPLAN_STATUS
IO_STATUS
RO_MACRO_STATUS
PD_MATRIX_STATUS
PHASE_BUFFER_STATUS
CTS_STATUS
ROUTE_STATUS
EXTRACTION_STATUS
SETUP_STATUS_TC
SETUP_STATUS_WC
HOLD_STATUS_BC
PHASE_LOAD_STATUS
RC_SYMMETRY_STATUS
BACKEND_CROSSING_STATUS
DRV_STATUS
ANTENNA_STATUS
DRC_STATUS
LVS_STATUS
DELIVERABLE_STATUS
DIGITAL_PNR_SIGNOFF
```

Every key must be `PASS`, `FAIL`, `EXTERNAL`, `DEFERRED`, or `PROVISIONAL` and
must reference concrete evidence.

Generated Innovus logs, databases, reports, routed DEF/GDS/SPEF/SDF, and
checkpoints belong under the configured work/artifact directory. Commit only
reviewed source changes, configuration, tests, compact documentation, and
evidence indexes.
