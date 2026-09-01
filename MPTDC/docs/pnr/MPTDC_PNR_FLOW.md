# MPTDC PnR Flow

Author: Karim Sabra

This document defines the physical-implementation path for the active
`mptdc_axis_core` digital block. It separates the existing typical Innovus
helpers from the digital PNR closure flow. A feasibility result must not be
renamed into signoff, and a TC-only result must not be renamed into MMMC or
tapeout readiness.

## Current Status

The active physical-recovery checkpoint is the canonical V13 Tie1 minimum-area
replay `20260831_175532_mptdc_tie1_minarea_clearance_v13_replay`, published at
commit `b61dfd1a6c476aa41cab43735a28199fa164bc05`. It restores the immutable Tie1
checkpoint, reproduces one exact fixed MET1 addition, and ends with fresh
Innovus DRC `0`, shorts `0`, regular-connectivity failures `0`, and unroutes
`0`. Raw special connectivity still has 15 VDD/VSS dangling endpoints, and the
last attributable PVS result is LVS `MISMATCH`; therefore signoff eligibility
remains `NO`.

The next action remains a disposable `tie1-pg-ro-ring-probe` stage. The first
server attempt, `20260901_115029_mptdc_tie1_pg_ro_ring_probe`, preserved the
exact V13 physical tuple but stopped before ring creation because the source
matcher returned zero exact candidates for all 15 endpoints. Its checkpoint is
not selected. Review found a code-level point canonicalization and length
calculation defect consistent with that result; the first report did not retain
enough raw DB evidence to prove it was the sole server-side cause. The corrected
probe now exercises flat and nested point encodings and publishes detailed
object-inventory diagnostics. A clean probe authorizes one ring-stitch trial;
an explicitly rejected physical probe authorizes the exact 13-handle long-prune
fallback. A topology-preflight tool failure authorizes neither branch. Both
mutating branches require canonical replay from V13 before PVS.

The exact command, accepted checkpoint SHA-256, repair geometry, V8-V13
failure history, PG endpoint inventory, compositional LVS contract, and stop conditions are in
[`MPTDC_TIE1_DRC_LVS_CLOSURE_HANDOFF.md`](MPTDC_TIE1_DRC_LVS_CLOSURE_HANDOFF.md).
That handoff is the current execution source of truth. Do not resume from an
older recovery command embedded in a historical run narrative.

The June 25 TC-only digital-PNR state remains reference evidence:

- Reviewed PNR source HEAD: `010285dc`.
- Genus handoff run: `20260623_1207_mptdc_axis_core_typical_closed_ba2b2932`.
- Last routed/filled/extracted/timed TC-only Innovus run:
  `20260625_mptdc_tc_fullclosure_010285dc_postfiller1`.
- Post-route extracted TC setup WNS: `0.000 ns`.
- Post-route extracted TC hold WNS: `+0.048 ns`.
- TC setup TNS: `0.000 ns`.
- TC setup violations: `0`.
- TC hold violations: `0`.
- Post-route DRV status: `PASS`.
- Route connectivity: shorts `0`, regular opens `0`, special opens `0`,
  unroutes `0`.
- Route DRC status: `PROVISIONAL`, with independent `verify_drc` reporting
  `2` non-short `MET1 Mar` violations.
- PD Vernier exception: 64 paths from 8 sources, no overmatch, no undermatch.
- Local ON22 repair: enabled in the Genus handoff and checked by the pre-PNR gate.
- Pre-PnR gate: PASS, with low-WNS warning.
- Phase-buffer topology: `BUJIHDX4 -> BUJIHDX12`.
- Row-infrastructure status: PROVISIONAL, because no dedicated CORE tap/endcap
  master was found and DRC/LVS qualification is still required.
- Full foundry DRC/LVS, row DRC/LVS, WC setup, BC hold, RO stress, and IR/EM
  remain deferred or external.

This is enough to keep the June 25 run as the TC-only provisional baseline for
continued physical cleanup. It is not enough to claim MMMC signoff, final
digital PNR PASS, or tapeout readiness. The detailed baseline and inspection
commands are recorded in
[`MPTDC_TC_CLOSURE_20260625_BASELINE.md`](MPTDC_TC_CLOSURE_20260625_BASELINE.md).

The active rerun target uses the layout-backed `RO_tune6` macro from
`SPADMIC/RO_tune6/layout`. Innovus expects a canonical exported LEF at
`/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef` and a shell Liberty
at `MPTDC/syn/macros/RO_tune6_real_layout_shell.lib`. The RO instance path
remains `u_ro_tune4` intentionally so the existing oscillator SDC/report paths
stay stable. The full OA-to-LEF handoff contract is in
`MPTDC/analog_handoff/RO_TUNE6_LAYOUT_EXPORT.md`.

## Owner-Facing Commands

Run from the repository root on the Cadence server:

```bash
# 1. Discover real physical-cell names from the installed PDK inputs when the
#    PDK installation changes.
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  --mode discover_only

# 2. Rerun Genus after RTL/netlist changes.
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh

# 3. Build the handoff package and gate it.
bash MPTDC/pnr/scripts/prepare_mptdc_genus_typical_handoff.sh \
  MPTDC_TC_Closure_Genus
bash MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh \
  --genus-run-id MPTDC_TC_Closure_Genus \
  --handoff-dir <handoff_dir>

# 4. Validate digital PNR sources without launching Innovus.
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  --mode validate_only \
  --genus-run-id MPTDC_TC_Closure_Genus \
  --handoff-dir <handoff_dir>

# 5. Launch implementation under the provisional row policy after review.
export MPTDC_DIGITAL_SIGNOFF_APPROVED=1
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  --mode full_signoff \
  --genus-run-id MPTDC_TC_Closure_Genus \
  --handoff-dir <handoff_dir>

# 6. Package the row-infrastructure DRC/LVS qualification request/evidence.
bash MPTDC/pnr/scripts/qualify_xh018_row_infrastructure.sh \
  <row_qualification_run_id>
```

The digital signoff wrapper records tool versions and rejects a dirty tracked
source tree. `full_signoff` is an explicit Innovus implementation launch. In
`MPTDC_CLOSURE_SCOPE=TC_ONLY`, it may produce `MPTDC_TC_PNR_CLOSURE=PASS` when
the TC route/timing gates are clean, but `DIGITAL_PNR_SIGNOFF` remains
PROVISIONAL and `READY_FOR_TAPEOUT` remains NO until row and final block DRC/LVS
evidence are clean and the scope is no longer a TC-only exception.

## Physical Intent

The block must be horizontally elongated. The final MPTDC boundary target is:

```text
width / height = 4 / 3 = 1.333333
allowed range = 1.20 .. 1.47
```

The automatic dimensioning logic must account for standard-cell area, two
`RO_tune6` macros, halos, phase-buffer rows, the full PD island, east-side
backend, route channels, power structures, IO pin capacity, target utilization,
and guard bands.

The flow must measure the Innovus core box after `floorPlan`; passing the
requested ratio to Innovus is not sufficient. `FLOORPLAN_ASPECT_STATUS=PASS`
requires the measured width/height to be in the allowed range.

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
  slow RO_tune6, orientation R0
  slow isolation buffer row
  slow final-driver row
  8 x 8 PD detector matrix
  fast final-driver row
  fast isolation buffer row
  fast RO_tune6, orientation MX
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
RO_tune6/S[n] -> isolation buffer -> final driver -> phase consumers
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

Before global placement, CTS, or route, the flow must also run
`ro_phase_overlap_audit.rpt`. `RO_PHASE_PLACEMENT_STATUS=PASS` requires:

- exactly two `RO_tune6` macros;
- valid slow and fast RO macro bboxes;
- 8 slow isolation buffers and 8 slow final drivers;
- 8 fast isolation buffers and 8 fast final drivers;
- zero RO/phase-buffer bbox overlap;
- minimum RO-to-phase-buffer clearance at or above
  `MPTDC_RO_PHASE_MIN_CLEARANCE_UM`, default `10.0`.

The companion pre-placement `checkPlace` report is still captured and its
aggregate overlap text is reported as `CHECKPLACE_OVERLAP_STATUS`. By default,
that aggregate global report is review context rather than a hard RO/phase
gate, because it can include unrelated PD/fence placement violations. Set
`MPTDC_RO_PHASE_FAIL_ON_GLOBAL_CHECKPLACE_OVERLAP=1` only for strict
experiments that intentionally want any global checkPlace overlap text to fail
the RO/phase gate.

The slow phase-buffer rows belong below the slow RO macro, outside the slow RO
bbox plus halo, facing the PD matrix. The fast phase-buffer rows belong above the
fast RO macro, outside the fast RO bbox plus halo, facing the PD matrix.

## RO Code Placement

TOP-owned CSR values feed `ro_slow_code_i[7:0]` and `ro_fast_code_i[7:0]` into
each product axis. `mptdc_core` captures them into local shadow registers only
while idle, and the local registers drive `RO_tune6/code[7:0]`.

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

`PG_CONNECTIVITY_STATUS=PASS` requires physical evidence, not only successful
`globalNetConnect` commands. The physical PG gate must report ring/strap/sroute
creation, RO PG pin connection, standard-cell rail connection, and zero
special-net connectivity errors from parsed Innovus reports. If those reports
are missing or unparsed, PG remains FAIL or PROVISIONAL.

Fillers are inserted only after placement, CTS, route, and route ECO work. The
row-infrastructure stage records the no-dedicated-tap/endcap policy; it must not
pretend early filler insertion passed before Innovus placement is legal.

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
