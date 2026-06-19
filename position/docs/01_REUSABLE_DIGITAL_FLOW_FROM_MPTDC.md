# Position Flow Reuse Extracted From MPTDC

Author: Karim Sabra

## Scope

This document extracts reusable digital-flow structure from the MPTDC Genus and
Innovus work before creating a dedicated position-block physical flow.

The goal is to reuse hard-won flow mechanics without copying MPTDC-only timing
and physical assumptions into `spadmic_position_block`.

The position block should inherit the reusable infrastructure:

- clean wrapper discipline,
- run manifests,
- source and environment guards,
- report collection,
- Genus handoff packaging,
- pre-PnR gates,
- Innovus staged execution,
- status reporting,
- technology/library discovery.

The position block should not inherit MPTDC-only logic:

- RO_tune4 macro checks,
- PD Vernier exceptions,
- fast-tag repair policies,
- phase-buffer topology checks,
- RO/phase generated-clock audits,
- 8 x 8 PD island symmetry constraints.

## Current Position

The active position synthesis script is:

- `position/syn/scripts/run_genus_position.tcl`

It already reuses the MPTDC technology setup:

- `MPTDC/syn/libraries/libraries.xh018.tcl`
- `MPTDC/syn/libraries/libraries.xh018-stdcells.tcl`

It also already performs useful block-local Genus work:

- creates a typical-only analysis view,
- reads available LEFs,
- limits routing estimation to the XH018 digital stack,
- reads the position RTL and shared packages,
- preserves the explicit line synchronizer stages,
- avoids scan cells when possible,
- writes timing, QoR, area, power, design-rule, netlist, SDC, SDF, and Innovus
  handoff outputs.

What it does not yet have:

- stable shell wrapper,
- run ID validation,
- clean tracked-worktree guard,
- expected-HEAD manifest,
- fixed profile file,
- source-only validation mode,
- handoff package manifest,
- reusable pre-PnR gate,
- position-specific Innovus wrapper,
- position PnR status schema.

## Reusable Values And Files

This section is the concrete extraction inventory: values and files that should
be carried into the position flow, values that are reusable only as templates,
and MPTDC-specific files that must stay out of the position flow.

### Technology Values To Reuse

These come from `MPTDC/syn/libraries/libraries.xh018.tcl` and are technology
context, not MPTDC behavior:

| Value | Current setting | Position use |
|-------|-----------------|--------------|
| Technology | `xh018` | Reuse |
| Process node | `180` | Reuse |
| Metal stack | `1P4M` | Reuse |
| Default PDK root | `/data/pdk/xfab/xh018` | Reuse, environment-overridable |
| Technology LEF | `cadence/v9_0/techLEF/v9_0_1/xh018_xx41_HD_MET4_METMID.lef` | Reuse |
| Layer names | `MET1 MET2 MET3 METTP` | Reuse |
| Row height | `7.56 um` | Reuse |
| Placement grid | `0.18 um` | Reuse |
| Typical temperature | `25 C` | Reuse |
| Worst-case temperature | `125 C` | Reuse when later using multi-view |
| Best-case temperature | `-40 C` | Reuse when later using multi-view |
| QRC typical file | `QRC-Typ/qrcTechFile` | Reuse if present |
| Cap table typical | `xh018_xx41_MET4_METMID_typ.capTbl` | Reuse if present |

CTS layer values from the same file are also reusable:

| CTS segment | Bottom | Top |
|-------------|--------|-----|
| Top | `MET3` | `METTP` |
| Trunk | `MET3` | `METTP` |
| Leaf | `MET2` | `MET3` |

### Standard-Cell Values To Reuse

These come from `MPTDC/syn/libraries/libraries.xh018-stdcells.tcl`.

| Value | HD setting | JIHD setting | Position use |
|-------|------------|--------------|--------------|
| Family selector | `MPTDC_STDCELL_FAMILY=HD` by default | `MPTDC_STDCELL_FAMILY=JIHD` | Choose explicitly for position |
| Library name | `D_CELLS_HD` | `D_CELLS_JIHD` | Reuse selector logic |
| Site | `core_hd` | `core_jihd` | Must match chosen family |
| LEF | `xh018_D_CELLS_HD.lef` | `xh018_D_CELLS_JIHD.lef` | Reuse path discovery |
| TC Liberty | `*_typ_1_80V_25C.lib` | `*_typ_1_80V_25C.lib` | Reuse |
| WC Liberty | `*_slow_1_62V_125C.lib` | `*_slow_1_62V_125C.lib` | Reuse later |
| BC Liberty | `*_fast_1_98V_m40C.lib` | `*_fast_1_98V_m40C.lib` | Reuse later |
| Stdcell VDD pins | `vdd` | `vddi` | Reuse through library helper |
| Stdcell GND pins | `gnd` | `gndi` | Reuse through library helper |
| Default SDC driving cell | `BUHDX4` | Needs explicit JIHD choice if using JIHD | Template only |
| External SDC load | `0.05 pF` | `0.05 pF` | Template only |

The current position OOC script says it targets `D_CELLS_HD` typical. If the
position physical implementation should align with the newer MPTDC JIHD backend,
the position wrapper must set `MPTDC_STDCELL_FAMILY=JIHD` deliberately and rerun
Genus. Do not silently inherit whichever family is in the caller environment.

### Position Genus Values To Keep

These are already position-specific and should be carried into the stable
position Genus wrapper/profile.

Source files:

- `position/syn/scripts/run_genus_position.tcl`
- `position/syn/inputs/spadmic_position.sdc`

Core Genus setup:

| Value | Current setting |
|-------|-----------------|
| Top module | `spadmic_position_block` |
| SDC | `position/syn/inputs/spadmic_position.sdc` |
| Work dir | `position/syn/work` |
| Reports dir | `position/syn/reports` |
| Outputs dir | `position/syn/outputs` |
| Logs dir | `position/syn/logs` |
| Technology | `xh018` |
| Standard-cell technology file | `xh018-stdcells` |
| Analysis view | `tc_view` |
| Constraint mode | `functional_mode` |
| Library set | `tc_libset` |
| Delay corner | `tc_corner` |
| Genus PLE bottom layer | `MET1` |
| Genus PLE top layer | `METTP` |

RTL inputs:

- `MPTDC/rtl/pkg/mptdc_pkg.sv`
- `MPTDC/rtl/cdc/mptdc_sync_fifo.sv`
- `TOP/rtl/spadmic_pkg.sv`
- `position/rtl/spadmic_axis_cluster_scan.sv`
- `position/rtl/spadmic_position_block.sv`

The stable filelist should contain exactly this active set unless the position
RTL changes.

### Position SDC Values To Keep

These values are from `position/syn/inputs/spadmic_position.sdc`.

| Constraint value | Current setting | Meaning |
|------------------|-----------------|---------|
| `POS_CLK_SYS_PERIOD_NS` | `6.250` | 160 MHz `clk_sys` |
| `POS_CLK_UNCERTAINTY_NS` | `0.300` | OOC clock uncertainty |
| `POS_CLK_TRANSITION_NS` | `0.150` | OOC clock transition |
| `POS_SYNC_INPUT_DELAY_NS` | `0.750` | CSR/control/ready input budget |
| `POS_SYNC_INPUT_TRANSITION_NS` | `0.200` | synchronous input transition |
| `POS_ASYNC_LINE_INPUT_DELAY_NS` | `2.000` | pessimistic matrix-line boundary delay |
| `POS_ASYNC_LINE_INPUT_TRANSITION_NS` | `2.000` | pessimistic 3.5 mm line slew |
| `POS_OUTPUT_DELAY_NS` | `1.000` | OOC output budget |
| `POS_TX_OUTPUT_LOAD_PF` | `0.075` | position packet output load |
| `POS_STATUS_OUTPUT_LOAD_PF` | `0.025` | CSR/status/reset output load |
| `set_max_fanout` | `20` | block-level fanout guard |
| `set_max_transition` | `2.000` | block-level transition guard |

False-path policy to keep:

- false path from `x_lines_i[*]`, `y_lines_i[*]`, and `z_lines_i[*]`;
- preferred endpoint is only the first synchronizer stage D pins;
- fallback broad false path is allowed only when the named stage-1 pins cannot
  be resolved, and should be reported as review-needed in a stable flow.

Synchronizer preservation patterns to keep:

- `*x_sync_ff1_q*`, `*x_sync_ff2_q*`
- `*y_sync_ff1_q*`, `*y_sync_ff2_q*`
- `*z_sync_ff1_q*`, `*z_sync_ff2_q*`

### Innovus Values To Reuse Carefully

Reusable from `MPTDC/pnr/inputs/mptdc_pnr_config.tcl`:

| Value | MPTDC setting | Position recommendation |
|-------|---------------|-------------------------|
| Core utilization | `0.60` | Good initial value |
| Max global placement density | `0.70` | Good initial guard |
| Core margin | `20.0 um` | Good initial value |
| Metal stack | `1P4M` | Reuse |
| Signal bottom layer | `MET1` | Reuse |
| Signal top layer | `MET3` | Reuse for normal digital routing |
| Power reserved layer | `METTP` | Reuse |
| Route directions | `MET1 horizontal`, `MET2 vertical`, `MET3 horizontal`, `METTP vertical` | Reuse as manifest expectation |
| Pre-CTS opt | `1` | Reuse |
| Detail route default | `0` | Reuse as early validation default |
| Vectorless activity | enabled, toggle `0.2`, static probability `0.5` | Template only |

MPTDC-only values in that config:

- `timing_measurement_symmetry_first`;
- `phase_exception_enable`;
- `phase_route_top_layer=METTP`;
- PD matrix region dimensions;
- oscillator macro width/height/halo;
- PD instance patterns.

Position should replace those with position-specific values:

- line-input pin grouping by X/Y/Z;
- synchronizer placement/region policy;
- matrix reset output pin policy;
- ordinary digital timing/routability priority.

### Innovus MMMC Template

Source example:

- `MPTDC/pnr/inputs/mptdc_innovus.mmmc`

Reusable structure:

- create constraint mode from post-synth SDC;
- create BC/TC/WC RC corners;
- create BC/TC/WC library sets;
- create `TC_NOMINAL`, `WC_SETUP`, and `BC_HOLD` views;
- set setup views to `TC_NOMINAL WC_SETUP`;
- set hold views to `TC_NOMINAL BC_HOLD`;
- keep old `bc_view`, `tc_view`, `wc_view` aliases only if legacy reports need
  them.

Do not reuse for position:

- `RO_MAX_FREQ_STRESS_MODE`;
- `RO_MAX_FREQ_STRESS`;
- `MPTDC_OSC_PD_SDC_OVERLAY`;
- `MPTDC_RO_STRESS_SDC_OVERLAY`;
- any oscillator/PD overlay naming.

Position replacement:

- file name should be `position/pnr/inputs/position_innovus.mmmc`;
- constraint mode can be `POSITION_FUNCTIONAL`;
- analysis views can remain `TC_NOMINAL`, `WC_SETUP`, `BC_HOLD`;
- no report-only RO stress view.

### Physical Cell Values

Source example:

- `MPTDC/pnr/config/xh018_cells.tcl`

Reusable when using JIHD:

| Class | Current value |
|-------|---------------|
| Site | `core_jihd` |
| PG power pin | `vddi` |
| PG ground pin | `gndi` |
| Fillers | `FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD` |
| Spacers | `FCPE32JIHD FCPE16JIHD FCPE8JIHD FCPE4JIHD FCPE2JIHD` plus fillers |
| Decaps | `DECAP25JIHD DECAP15JIHD DECAP10JIHD DECAP7JIHD DECAP5JIHD DECAP3JIHD` |
| Antenna cells | `ANTENNACELLN2JIHD ANTENNACELLNP2JIHD ANTENNACELLP2JIHD` |
| Tie high | `LOGIC1DJIHD LOGIC1LVJIHD` |
| Tie low | `LOGIC0DJIHD LOGIC0LVJIHD` |
| CTS buffer | `CLKVBUFJIHD` |
| CTS inverters | `INJIHDX0 INJIHDX1 INJIHDX2 INJIHDX3 INJIHDX4 INJIHDX6 INJIHDX8 INJIHDX12` |

Reusable policy:

- no dedicated CORE tap/endcap master has been confirmed;
- implementation is provisional if using the no-core-tap/endcap policy;
- final PASS still requires block or row DRC/LVS evidence.

MPTDC-only physical-cell values:

- `phase_iso_buffer=BUJIHDX4`;
- `phase_final_buffer=BUJIHDX12`;
- `phase_buffer_policy`.

These phase-buffer cells are not a position-block requirement.

### Reusable File Inventory

Use directly:

| File | Reuse level | Reason |
|------|-------------|--------|
| `MPTDC/syn/libraries/libraries.xh018.tcl` | Direct | XH018 technology setup |
| `MPTDC/syn/libraries/libraries.xh018-stdcells.tcl` | Direct | HD/JIHD standard-cell setup |
| `position/syn/inputs/spadmic_position.sdc` | Direct seed | Correct position timing intent |
| `position/syn/scripts/run_genus_position.tcl` | Direct seed | Existing position Genus backend |
| `MPTDC/scripts/mptdc_flow_common.sh` | Template/direct short term | Good shell wrapper mechanics |
| `MPTDC/pnr/scripts/audit_def_io_pins.sh` | Direct/template | Generic DEF pin geometry audit |
| `MPTDC/pnr/scripts/audit_def_power_grid.sh` | Direct/template | Generic DEF PG geometry audit |
| `MPTDC/pnr/scripts/discover_xh018_physical_cells.sh` | Direct/template | XH018 library discovery |

Use as template, not direct:

| File | Reuse level | What to change |
|------|-------------|----------------|
| `MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh` | Template | Rename variables, paths, run labels, backend |
| `MPTDC/syn/scripts/profiles/genus_axis_core_typical_closed.sh` | Template | Remove MPTDC repair policies; add position policy |
| `MPTDC/syn/scripts/package_genus_typical_handoff.sh` | Template | Replace output names and required checks |
| `MPTDC/pnr/scripts/prepare_mptdc_genus_typical_handoff.sh` | Template | Replace MPTDC handoff names/checks |
| `MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh` | Template | Replace MPTDC gate checks with position checks |
| `MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh` | Template | Replace approval variable, modes, gate, Tcl entry |
| `MPTDC/pnr/scripts/innovus_mptdc_digital_signoff.tcl` | Template | Remove RO/PD/phase stages; add line/reset stages |
| `MPTDC/pnr/inputs/mptdc_pnr_config.tcl` | Template | Keep digital defaults; replace PD/RO parameters |
| `MPTDC/pnr/inputs/mptdc_innovus.mmmc` | Template | Remove RO stress and oscillator overlays |

Do not reuse for position:

| File pattern | Reason |
|--------------|--------|
| `MPTDC/syn/inputs/mptdc_pd_vernier_exceptions.sdc` | PD Vernier-only exception |
| `MPTDC/syn/inputs/mptdc_osc_*.sdc` | MPTDC oscillator/phase-clock model |
| `MPTDC/pnr/constraints/mptdc_osc_*.sdc` | MPTDC oscillator/phase-clock model |
| `MPTDC/pnr/constraints/mptdc_phase_distribution.sdc` | Phase-buffer distribution only |
| `MPTDC/pnr/constraints/mptdc_ro_1ghz_stress.sdc` | RO stress only |
| `MPTDC/pnr/scripts/report_osc_tap_loads.tcl` | RO load reporting |
| `MPTDC/pnr/scripts/report_pd_instance_symmetry.tcl` | PD island symmetry |
| `MPTDC/pnr/scripts/report_pd_phase_routes.tcl` | PD/phase routing |
| `MPTDC/pnr/scripts/innovus_mptdc_pd_matrix_place.tcl` | MPTDC PD matrix placement |
| `MPTDC/pnr/scripts/innovus_mptdc_phase_buffer_place.tcl` | MPTDC phase-buffer placement |

## Reusable MPTDC Flow Mechanics

### Stable Public Wrapper

Source example:

- `MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh`

Reusable behavior:

- resolves script, block, and repository roots;
- sources a fixed profile;
- rejects unsupported command-line overrides;
- validates a simple `RUN_ID`;
- initializes work roots under `work/`;
- requires a clean tracked tree before closure/handoff runs;
- checks that canonical RTL, SDC, profile, and backend entrypoints exist;
- records `EXPECTED_HEAD`;
- prints a manifest-style run header;
- hands off to the historical backend without exposing all backend internals as
  the public interface.

Position adaptation:

- create `position/syn/scripts/run_genus_position_typical_closed.sh`;
- use `POSITION_WORK_ROOT` or a generic `SPADMIC_WORK_ROOT`;
- default run ID should be `<timestamp>_position_typical_closed`;
- require `position/syn/filelist_position_typical_closed.f`;
- require `position/syn/inputs/spadmic_position_typical_closed.sdc`;
- call a position Genus backend or refactor the existing Tcl script to consume
  environment-provided run directories.

### Fixed Profile

Source example:

- `MPTDC/syn/scripts/profiles/genus_axis_core_typical_closed.sh`

Reusable behavior:

- separates edited, reviewable policy from backend compatibility variables;
- records baseline commit and baseline run;
- exports flow labels and signoff boundary labels;
- rejects inherited experiment variables that would silently change the flow;
- prints all important policy settings into the run manifest.

MPTDC-only content to exclude:

- fast-tag source-cell remap policy;
- PD local ON22 repair;
- PD hit-to-nfast repair counts;
- STRIDE2 drain policy if the run is not synthesizing MPTDC RTL;
- BUJIHD phase-buffer topology.

Position adaptation:

- create `position/syn/scripts/profiles/position_typical_closed.sh`;
- profile fields should cover only position-owned policy:
  - top module `spadmic_position_block`,
  - typical-only boundary,
  - source filelist,
  - SDC entrypoint,
  - minimum acceptable WNS,
  - zero setup-violation requirement,
  - zero DRV requirement,
  - synchronizer preservation requirement,
  - async line false-path scope,
  - packet format unchanged,
  - matrix reset output present.

### Common Shell Helpers

Source example:

- `MPTDC/scripts/mptdc_flow_common.sh`

Reusable behavior:

- repository-root detection;
- absolute-path conversion;
- work-root initialization;
- clean tracked-tree guard;
- required-file guard;
- run-header printing.

MPTDC-only content to exclude or rename:

- `MPTDC_OPT_MODE` define generation;
- MPTDC-specific work-root variable names if the helper becomes project-wide.

Position adaptation:

- short term: reuse the patterns directly in a position wrapper;
- later cleanup: extract a project-level helper, for example
  `tools/flow/spadmic_flow_common.sh`, then make MPTDC and position wrappers
  call the same helper.

### Genus Tcl Skeleton

Source examples:

- `position/syn/scripts/run_genus_position.tcl`
- `MPTDC/syn/scripts/genus.tcl`
- `MPTDC/syn/scripts/procedures.tcl`

Reusable behavior:

- create work, report, output, and log directories;
- source technology and standard-cell library files;
- create analysis views explicitly;
- read LEF files when available;
- apply routing-layer limits;
- read RTL from a stable file list;
- elaborate the exact top module;
- run `check_design` before synthesis;
- run `check_timing_intent`;
- write checkpoint reports at pre-synth, post-generic, post-map, and post-opt;
- avoid scan cells for non-DFT prototype runs;
- preserve synchronizer cells;
- write netlist, SDC, SDF, and Innovus design collateral.

Position custom content:

- synchronizer patterns are `x_sync_ff*`, `y_sync_ff*`, `z_sync_ff*`;
- SDC must false-path only to first-stage line synchronizers;
- matrix reset output must get real output-load and output-delay assumptions;
- line-bus timing contract must be documented as async sampled input, not as a
  synchronous 64-bit bus.

### Handoff Package

Source examples:

- `MPTDC/syn/scripts/package_genus_typical_handoff.sh`
- `MPTDC/pnr/scripts/prepare_mptdc_genus_typical_handoff.sh`
- `work/handoff/genus_typical/mptdc_genus_typical_closed/HANDOFF_MANIFEST.md`

Reusable behavior:

- copy or reference the exact post-synthesis netlist and SDC;
- record source run ID, branch, HEAD, profile, filelist, SDC, and generated
  outputs;
- include final decision keys in machine-readable `KEY=VALUE` form;
- preserve package checks in tabular form;
- distinguish handoff readiness from final signoff.

Position adaptation:

- package name: `position_genus_typical_closed`;
- required files:
  - `spadmic_position_block.postsyn.v`,
  - `spadmic_position_block.postsyn.sdc`,
  - final filelist used,
  - final SDC used,
  - timing summary,
  - design-rule report,
  - check-design report.

### Pre-PnR Gate

Source example:

- `MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh`

Reusable behavior:

- accepts either a source Genus run directory or a handoff directory;
- finds a summary or handoff manifest;
- extracts `KEY=VALUE` evidence;
- records every check as `check expected actual status`;
- exits hard on missing required evidence;
- permits an explicit review override mode;
- reports low WNS as a warning instead of hiding it.

MPTDC-only checks to remove:

- `RO_tune4 instance count`;
- oscillator stub residue;
- raw RO clocks found;
- buffered phase clocks found;
- PD Vernier paths/sources matched;
- phase-buffer cell counts;
- exact fast-tag repair status.

Position gate checks to add:

- `FINAL_DECISION=POSITION_GENUS_TYPICAL_CLOSED`;
- `POSITION_TYPICAL_STATUS=POSITION_GENUS_TYPICAL_CLOSED`;
- `READY_FOR_POSITION_PNR=YES`;
- `FINAL_SIGNOFF=NO`;
- Genus exit code `0`;
- setup WNS nonnegative;
- setup violating path count `0`;
- max transition/cap/fanout violations `0`;
- unresolved reference count `0`;
- async line false-path scope present;
- synchronizer preservation report present;
- matrix reset output constraint present;
- packet format unchanged;
- netlist and SDC files exist.

### Innovus Shell Wrapper

Source example:

- `MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh`

Reusable behavior:

- modes: `discover_only`, `validate_only`, `full_signoff`;
- captures branch, HEAD, mode, run ID, result directory, handoff directory;
- records tracked worktree status;
- rejects dirty tracked source tree outside discovery mode;
- captures tool versions;
- runs a pre-PnR gate before implementation;
- runs Tcl source validation before launching Innovus;
- requires explicit approval environment variable before full Innovus launch.

Position adaptation:

- wrapper name: `position/pnr/scripts/server_run_innovus_position_digital.sh`;
- mode names can remain `discover_only`, `validate_only`, `full_pnr`;
- full launch approval variable should be explicit, for example
  `POSITION_PNR_APPROVED=1`;
- pre-PnR gate should be position-specific;
- no RO/phase discovery mode is needed, but XH018 cell/PG discovery can be
  reused.

### Innovus Tcl Stage Framework

Source example:

- `MPTDC/pnr/scripts/innovus_mptdc_digital_signoff.tcl`

Reusable behavior:

- environment helpers;
- result/report/manifest/work/checkpoint/DEF/output directory helpers;
- status-key schema;
- status writer;
- stage trace CSV;
- required-file checks;
- report capture helpers;
- source-only mode;
- stage wrapper that writes failure reports and status before exiting.

MPTDC-only stages to remove:

- RO macro placement status;
- PD matrix placement status;
- phase-buffer placement status;
- phase-load and RC-symmetry reporting;
- backend-crossing status for RO/PD phase fabric.

Position stages to add:

- position line input pin placement status;
- line synchronizer physical clustering status;
- matrix reset pin/status;
- position queue/FIFO status;
- raw and compact packet output status;
- CDC waiver status for async line sampling.

### Standard-Cell and Row Infrastructure Discovery

Source examples:

- `MPTDC/pnr/scripts/discover_xh018_physical_cells.sh`
- `MPTDC/pnr/scripts/audit_xh018_row_infrastructure.sh`
- `MPTDC/pnr/config/xh018_cells.tcl`

Reusable behavior:

- discover fillers, ties, CTS cells, antenna cells, feed spacers, and row
  infrastructure candidates from the active XH018 library;
- record standard-cell PG pin names;
- make row-infrastructure assumptions explicit;
- distinguish implementation allowance from final DRC/LVS approval.

Position adaptation:

- reuse technology cell discovery;
- do not mark row infrastructure final without DRC/LVS;
- if no dedicated core tap/endcap master exists, keep the same provisional
  framing and require final physical verification evidence.

### IO, Power, CTS, Route, and Report Audits

Source examples:

- `MPTDC/pnr/scripts/audit_def_io_pins.sh`
- `MPTDC/pnr/scripts/audit_def_power_grid.sh`
- `MPTDC/pnr/scripts/innovus_mptdc_reports.tcl`
- `MPTDC/pnr/scripts/innovus_mptdc_cts.tcl`
- `MPTDC/pnr/scripts/innovus_mptdc_route.tcl`

Reusable behavior:

- verify pins are physically placed with layer geometry;
- verify power special-net geometry exists;
- separate CTS state from routing state;
- collect timing, DRV, congestion, antenna, and DEF outputs;
- keep final DRC/LVS separate from implementation progress.

Position adaptation:

- CTS should target only `clk_sys`;
- no RO or phase clocks should appear in CTS policy;
- line input pins should be grouped by X/Y/Z axis;
- `spad_matrix_rst_o` must be included in output timing and pin placement;
- report names should be position-specific to avoid confusing them with MPTDC
  evidence.

## Reusable Status Schema For Position

The position PnR status report should use explicit keys instead of a single
ambiguous ready label:

```text
PRE_PNR_GATE_STATUS=
GENUS_HANDOFF_STATUS=
PHYSICAL_CELL_CONFIG_STATUS=
ROW_INFRA_POLICY_STATUS=
ROW_INFRA_DRC_LVS_STATUS=
PG_CONNECTIVITY_STATUS=
FLOORPLAN_STATUS=
IO_STATUS=
LINE_INPUT_PIN_STATUS=
LINE_SYNC_CLUSTER_STATUS=
MATRIX_RESET_STATUS=
CTS_STATUS=
ROUTE_STATUS=
EXTRACTION_STATUS=
SETUP_STATUS_TC=
HOLD_STATUS_TC=
DRV_STATUS=
ANTENNA_STATUS=
DRC_STATUS=
LVS_STATUS=
CDC_WAIVER_STATUS=
DELIVERABLE_STATUS=
POSITION_DIGITAL_PNR=
```

Do not collapse these into `READY`.

Acceptable intermediate labels:

- `PASS evidence=<file>` when a check is actually proven;
- `FAIL evidence=<file>` when a run proves a problem;
- `PROVISIONAL evidence=<file>` when implementation can continue but final
  proof is missing;
- `DEFERRED evidence=<reason>` when a later tool or owner must provide proof.

## Position-Specific Work To Do Later

After the generic extraction is stable, the custom position work should be:

1. Create a stable position Genus wrapper and profile.
2. Convert the current position Genus Tcl into a run-directory driven backend.
3. Add a position handoff package generator.
4. Add `check_position_pre_pnr_gate.sh`.
5. Create a position Innovus wrapper with `validate_only` and `full_pnr`.
6. Add a position Innovus Tcl entrypoint with reusable stage/status mechanics.
7. Define position floorplan assumptions:
   - target utilization,
   - aspect ratio,
   - X/Y/Z line pin sides,
   - matrix reset pin side,
   - output/control pin placement,
   - synchronizer physical clustering.
8. Define the position PnR SDC:
   - `clk_sys`,
   - async false paths only to first sync stage,
   - synchronous paths after sync timed normally,
   - matrix reset output timing/load,
   - CSR/readout output timing assumptions.
9. Add position report parsers:
   - timing summary,
   - design rules,
   - unconstrained paths,
   - clock report,
   - pin geometry,
   - power geometry,
   - route/congestion,
   - antenna,
   - DRC/LVS placeholders.
10. Update project documentation only after the scripts produce evidence.

## Recommended Extraction Order

Do this in small additive steps:

1. Keep this document as the extraction map.
2. Add position Genus wrapper/profile without changing MPTDC scripts.
3. Add a position handoff package and pre-PnR gate.
4. Extract the analog SPAD matrix abstract using
   `02_SPAD_MATRIX_ABSTRACT_HANDOFF.md`.
5. Add position Innovus `validate_only` source-check mode.
6. Only then add the custom position floorplan, pin, CTS, route, and report
   stages.
7. After position can run end-to-end, consider moving common shell/Tcl helpers
   into a project-level flow library.

This order preserves the proven MPTDC flow while preventing the position block
from inheriting oscillator-specific constraints that do not belong to it.
