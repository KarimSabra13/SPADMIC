# Digital Assembly V1 Execution Journal

This journal records measured execution evidence for the progressive SPADMIC2
digital assembly. A phase is marked `PASS` only from the reports produced by
that phase. Planned commands, tool return codes, and estimates are not physical
signoff evidence by themselves.

The flow remains restricted to `SPADMIC_test`. It must not launch full-top
Genus or Innovus and must not modify MPTDC internals.

## Evidence Rules

- Preserve every run under a unique timestamped directory.
- Record the repository HEAD, input hashes, run ID, return code, and report
  paths for every phase.
- Keep Innovus DRC, PVS DRC, PVS LVS, PG connectivity, geometry, pin parity,
  and layer-map status as separate gates.
- Treat an Innovus or PVS process return code of zero as execution evidence,
  not as proof that DRC or LVS passed.
- Do not promote a handoff package when any required gate is `FAIL`, `UNKNOWN`,
  or `PENDING`.
- Never overwrite an existing package under
  `/sim/ksabra/SPADMIC_work/handoff/innovus`.

## Phase Ledger

| Phase | Scope | Current status | Required evidence |
| --- | --- | --- | --- |
| P00 | Local flow implementation and static validation | PASS | Unit tests, syntax checks, RTL compile, geometry regression |
| P01 | Narrow `spadmic_tx_ddr_strip` signal PnR | PASS | OOC status, LEF size, DRC, markers, regular connectivity |
| P02 | Restore-only internal PG for the narrow strip | R4_HELPER_METHOD_FAIL_DIAG_PENDING | PG marker decomposition, post-PG connectivity/DRC, merged GDS audit |
| P03 | Canonical `spadmic_tx_packet_core` rebuild and historical LVS intake | INNOVUS_R1_REVIEW_REQUIRED_DIAG_PENDING | Read-only mismatch classification, RTL mapping oracle, Genus/Innovus gates |
| P04 | Per-block PVS closure, density qualification, and handoff promotion | BLOCKED_BY_P03_INNOVUS_R1 | PVS DRC zero outside antenna, explicit LVS match, hashes, promotion gate |
| P05 | Requalified strip and Phase-A TX assembly geometry gate | BLOCKED_BY_P04 | Strip PG/PVS closure, no obstacle overlap, exact paired 19-net contract |
| P06 | Phase-A TX assembly route | BLOCKED_BY_P05 | Checkpoints 00/01/02, selected-net connectivity, DRC, timing |
| P07 | Assembly PVS and promoted handoff | BLOCKED_BY_P06 | GDS audit, PVS DRC zero, LVS match or approved source contract |

Later position, event/control, matrix-interface, MPTDC-frontend, and CSR/I2C
phases remain outside this initial TX gate.

## P00 - Local Implementation

Status: `PASS`

Implemented artifacts:

- Phase-A RTL/black-box/filelist/connectivity contracts under
  `TOP/pnr/assembly/`.
- Top-coordinate floorplan, hard obstacle blockages, and pin-guide Tcl.
- Assembly generator with geometry rejection before Innovus starts.
- Innovus assembly runner with restoreable `00_import`, `01_tx_placed`, and
  `02_tx_routed` checkpoints.
- Restore-only strip PG patch flow.
- Immutable per-block and per-assembly handoff staging.
- OA/LEF contract, XStream GDS, Innovus GDS, PG, and promotion audits.
- PVS DRC/LVS template replay and explicit result parsing.

Validated locally:

- 8 focused unit tests passed.
- Python compilation passed.
- Bash syntax checks passed.
- Tcl files were syntactically complete.
- Icarus assembly compilation passed.
- Verilator passed with only the pre-existing `mptdc_pkg.sv` width warning.
- `git diff --check` passed.
- Handoff staging/audit and promotion-gate smoke tests passed.

Server EDA was not run locally because `/sim` and the Cadence server
environment are not available in this checkout.

## P01 - Narrow TX DDR Strip Signal PnR

Status: `PASS`

Reason for this phase:

```text
old strip bbox = 61.980,3061.110 -> 3584.940,3241.990
TXRX4TDC2      = 3505.519,464.920 -> 3638.910,3265.795
overlap        = 79.421 x 180.880 um
```

The old strip cannot enter the assembly. The first server run reuses the
accepted Genus netlist and changes only the OOC strip core width to
`3413.000 um`. PG remains deferred during P01 by design.

Acceptance gates:

- `STRIP_SIGNAL_RC=0`
- `RESULT=ABSTRACT_READY_FOR_TOP_REVIEW`
- `INNOVUS_DRC_STATUS=PASS`
- `DRC_MARKER_TOTAL=0`
- `REGULAR_CONNECTIVITY_STATUS=PASS`
- abstract LEF total width near `3433 um`, subject to the generator's exact
  SPADMIC2 obstacle check;
- no full-top or unrelated block run.

Measured evidence:

```text
REPO_HEAD=1bf29069837b0a992b98aead50e98be28196a601
RUN_ID=innovus_ooc_harden_tx_ddr_strip_narrow_20260710_133516
RUN_ROOT=/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_ddr_strip_narrow_20260710_133516/blocks/tx_ddr_strip
RETURN_CODE=NOT_INCLUDED_IN_RETURNED_EXCERPT
STATUS_REPORT=<RUN_ROOT>/reports/ooc_harden_status.rpt
DRC_REPORT=<RUN_ROOT>/reports/verify_drc_post_route.rpt
MARKER_REPORT=<RUN_ROOT>/reports/DRC_MARKER_CLASSIFICATION.rpt
CONNECTIVITY_REPORT=<RUN_ROOT>/reports/verify_connectivity_regular.rpt
ABSTRACT_LEF=<RUN_ROOT>/outputs/tx_ddr_strip.abstract.lef
CORE_SIZE_UM=3413.000 x 160.776
MACRO_SIZE_UM=3433.360 x 180.880
PLACED_BBOX=61.980,3061.110 -> 3495.340,3241.990
TXRX4TDC2_X_CLEARANCE_UM=10.179
INNOVUS_DRC_STATUS=PASS
DRC_MARKER_TOTAL=0
ANTENNA_MARKER_COUNT=0
REGULAR_CONNECTIVITY_STATUS=PASS
PG_CONNECTIVITY_STATUS=DEFERRED_TOP_LEVEL_HOOKUP
SIGNOFF_READY=NO
VERDICT=PASS_SIGNAL_PNR_PG_PENDING
```

The regular-connectivity transcript contains exactly two problems: VDD and
VSS have no global or special route. These are expected in P01 and are not
waived for final handoff; they are the explicit input condition for P02.

## P02 - Narrow Strip Restore-Only PG

Status: `R4_HELPER_METHOD_FAIL_DIAG_PENDING`

P02 restores the P01 `05_postroute_export` checkpoint. It must not run
placement, CTS, signal `routeDesign`, or synthesis. It adds only VDD/VSS METTP
stripes and special routes, then exports a GDS merged with the JIHD standard
cell GDS through the official XFAB stream map.

Acceptance gates:

- `PG_PATCH_RC=0`
- `RESTORE_DESIGN=PASS`
- `SIGNAL_ROUTE_ACTION=PRESERVED_NO_ROUTE_DESIGN`
- `ADD_STRIPE_VDD=PASS` and `ADD_STRIPE_VSS=PASS`
- `SROUTE_PG=PASS`
- `PG_CONNECTIVITY_STATUS=PASS` with zero violations;
- `REGULAR_CONNECTIVITY_STATUS=PASS` with zero violations;
- `INNOVUS_DRC_STATUS=PASS` with zero markers;
- `RESULT=PG_STITCHED_DRC_CLEAN_PENDING_PVS`;
- merged GDS, abstract LEF, DEF, and PG netlist present.

PVS DRC/LVS remain later independent gates even if all P02 Innovus checks
pass.

First-attempt evidence:

```text
REPO_HEAD=c6c4beb24500ba15bf2d1ea9826d741aa9df56de
RUN_ID=innovus_ooc_pg_only_tx_ddr_strip_20260710_135413
RUN_ROOT=/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_pg_only_tx_ddr_strip_20260710_135413
PG_PATCH_RC=8
RESTORE_DESIGN=PASS
SIGNAL_ROUTE_ACTION=PRESERVED_NO_ROUTE_DESIGN
PLACE_ACTION=NOT_RUN
CTS_ACTION=NOT_RUN
ADD_STRIPE_VDD=PASS
ADD_STRIPE_VSS=PASS
SROUTE_PG=PASS
VDD_STRIPE_CENTER_SOURCE=DB_PG_TERM
VDD_STRIPE_CENTER_X_UM=858.480
VSS_STRIPE_CENTER_SOURCE=DB_PG_TERM
VSS_STRIPE_CENTER_X_UM=2574.880
PG_CONNECTIVITY_STATUS=FAIL
PG_CONNECTIVITY_VIOLATION_COUNT=9
REGULAR_CONNECTIVITY_STATUS=PASS
REGULAR_CONNECTIVITY_VIOLATION_COUNT=0
INNOVUS_DRC_STATUS=PASS
DRC_MARKER_TOTAL=0
RESULT=REVIEW_REQUIRED
SIGNOFF_READY=NO
```

The 9 PG violations are classified by Innovus as:

```text
IMPVFC-96  unconnected terminals                    2
IMPVFC-200 disconnected special-wire pieces         4
IMPVFC-94  dangling special wires                    3
```

This proves that command acceptance by `addStripe` and `sroute` did not prove
electrical PG closure. The signal route remains usable as the restore source;
the failed PG run is not a handoff candidate.

The generated GDS is 749026 bytes with SHA256
`b917fcaa74f69234cdd6dc0aaa9a8b5d051e77c4f74669c6079eb7f88f4fc4ca`.
Its first audit is non-authoritative because the audit imposed a 1 MB minimum
and compared the resolved `/data/pdk` map path literally against the lexical
`/eda/pdk` command path. The stream-map hash itself matched the approved XFAB
hash. A corrected audit must be run under a new immutable report name, but no
GDS can be promoted while PG connectivity remains FAIL.

Next P02 action: read-only extraction of the existing DEF special-net
sections, route reports, and focused Innovus log messages. Do not rerun
`sroute` until the open topology is identified.

The first read-only extraction completed under
`/sim/ksabra/SPADMIC_work/diagnostics/tx_ddr_strip_pg_diag_20260710_140628`.
It established:

- the corrected GDS audit is PASS for file size, official XFAB map, and JIHD
  merge;
- both METTP stripes stop at the core top `y=170.800 um`;
- both boundary PG pins start at `y=176.960 um`, leaving a `6.160 um` gap;
- `sroute` explicitly reported that VDD/VSS block pins were not found;
- VDD followpin rows at `y=135.520 um` and `y=144.480 um` have no via stack
  to the vertical METTP stripe, while the other reported rows do;
- the MPTDC oscillator Liberty diagnostics are unrelated library-load noise
  because this strip contains no MPTDC instance and no MPTDC files are changed.

The next action is a restore-only connectivity probe using
`run_innovus_ooc_pg_probe.sh`. It captures the detailed `-report` output,
marker boxes, PG-term geometry, and special-wire database rows. It makes no
design modification and creates no replacement handoff.

The marker probe completed successfully:

```text
PROBE_ID=tx_ddr_strip_pg_marker_probe_20260710_141525
PROBE_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/tx_ddr_strip_pg_marker_probe_20260710_141525
PG_PROBE_RC=0
RESTORE_DESIGN=PASS
DESIGN_MODIFICATION=NOT_RUN
MARKER_COUNT=9
RESULT=PG_DIAGNOSTIC_CAPTURED
```

Exact marker classification:

| Marker | Net | Location or box (um) | Proven cause |
| --- | --- | --- | --- |
| 1 | VDD | `828.240,176.960 -> 888.720,180.880` | north PG terminal unconnected |
| 2 | VDD | `10.080,9.680 -> 3423.280,170.800` | main PG network has multiple components |
| 3 | VDD | `10.080,143.245 -> 3423.280,145.715` | row at y=144.480 lacks stripe via |
| 4 | VDD | `10.080,134.540 -> 3423.280,136.755` | row at y=135.520 lacks stripe via |
| 5 | VDD | `868.560,170.800` | stripe top endpoint dangling |
| 6 | VSS | `2544.640,176.960 -> 2605.120,180.880` | north PG terminal unconnected |
| 7 | VSS | `10.080,10.080 -> 3423.280,170.800` | routed PG component is separate from terminal |
| 8 | VSS | `2584.960,10.080` | stripe extends below first VSS row at y=14.560 |
| 9 | VSS | `2584.960,170.800` | stripe top endpoint dangling |

The intended stripe centers were read from DB PG terms as VDD `858.480 um`
and VSS `2574.880 um`, but the generated DEF centers are `868.560 um` and
`2584.960 um`. The exact `+10.080 um` error equals the core-left coordinate.
The original offset formula omitted that reference origin.

P02 repair contract:

- restore the clean P01 signal checkpoint, never the failed PG checkpoint;
- center VDD at x=858.480 and span y=10.080 through the north pin at 180.880;
- center VSS at x=2574.880 and span y=14.560 through the north pin at 180.880;
- connect standard-cell core pins to stripes without requesting nonexistent
  `blockPin` objects;
- require a via stack on every VDD and VSS followpin row;
- rerun special and regular connectivity plus DRC before any export;
- keep the validated signal route unchanged;
- do not modify or diagnose MPTDC internals from unrelated library-load noise.

Before implementing this geometry, capture the Innovus 22.33 command help for
`addStripe` area/offset semantics and the supported explicit special-route
geometry commands. This avoids guessing tool syntax.

The command-help capture completed successfully:

```text
HELP_ID=innovus_pg_command_help_20260710_151605
COMMAND_HELP_RC=0
COMMAND_addStripe=MAN
COMMAND_sroute=MAN
COMMAND_editAddRoute=MAN
COMMAND_add_shape=MAN
POLICY=NO_DESIGN_LOADED_NO_DESIGN_MODIFICATION
```

The installed manual confirms `addStripe -area`, `-extend_to
design_boundary`, explicit offset controls, and `sroute` connection classes.
It also confirms that `add_shape` directly creates DEF `SPECIALNETS` shapes.

P02-R2 uses deterministic `add_shape -shape STRIPE` centerlines and then
`sroute -connect {corePin}`. It does not request nonexistent block pins. The
permanent command notes and exact geometry are recorded in
`TOP/docs/34_INNOVUS_22_33_PG_ROUTING_COMMAND_NOTES.md`.

P02-R2 implementation:

- `TOP/pnr/scripts/run_innovus_ooc_pg_geometry_fix.sh`
- `TOP/pnr/scripts/run_innovus_ooc_pg_geometry_fix.tcl`

Export is fail-closed: no promoted outputs are emitted unless PG
connectivity, regular connectivity, and Innovus DRC all report zero
violations. PVS remains pending after a successful P02-R2 run.

P02-R2 executed as
`innovus_ooc_pg_geometry_fix_tx_ddr_strip_20260710_153213`. It reduced the PG
violations from 9 to 3 while preserving zero regular-connectivity and zero DRC
violations. It correctly emitted no handoff outputs.

```text
PG_GEOMETRY_FIX_RC=8
RESTORE_DESIGN=PASS
GEOMETRY_GUARD=PASS
PG_TERM_CENTER_GUARD=PASS
ADD_SHAPE_VDD=PASS
ADD_SHAPE_VSS=PASS
SROUTE_CORE_PIN=PASS
PG_CONNECTIVITY_VIOLATION_COUNT=3
REGULAR_CONNECTIVITY_VIOLATION_COUNT=0
DRC_MARKER_TOTAL=0
RESULT=REVIEW_REQUIRED
```

The boundary-pin gaps, VSS network, stripe offsets, and dangling endpoints are
fixed. All remaining markers are VDD opens:

- the followpin row centered at `y=135.520 um`;
- the followpin row centered at `y=144.480 um`;
- the aggregate VDD network marker caused by those two isolated rows.

P02-R3 attempted to extend the same fail-closed script with a local VDD helper
stripe spanning `y=126.560..153.440 um`. The main geometry was recreated and
saved correctly, but the candidate loop attempted a second `restoreDesign` in
the same Innovus process. Innovus 22.33 rejected every such attempt with
`IMPIMEX-7031`.

```text
REPO_HEAD=1ac210cdee536329c162a23fb22e7fadac7f0a3f
RUN_ID=innovus_ooc_pg_geometry_fix_r3_tx_ddr_strip_20260710_154616
RUN_ROOT=/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_pg_geometry_fix_r3_tx_ddr_strip_20260710_154616
R3_RC=8
RESTORE_DESIGN=PASS
MAIN_PG_CONNECTIVITY_VIOLATION_COUNT=3
MAIN_PG_MARKER_COUNT=3
CHECKPOINT_01=PASS_PRESENT
CHECKPOINT_02=PASS_PRESENT
CANDIDATE_ROWS=10
CANDIDATES_ELECTRICALLY_EVALUATED=0
CANDIDATE_VERDICT=RESTORE_FAIL
OUTPUT_FILES=0
FAILURE_CLASS=INNOVUS_PROCESS_RESTORE_GUARD
```

The checkpoint inventory and hashes prove that
`02_core_pin_stitched.enc.dat` is a complete self-contained checkpoint. The
failure therefore does not change the physical diagnosis: VSS remains closed
and the same two VDD followpin rows remain isolated. It also does not reject any
candidate X, because no helper `add_shape`, helper `sroute`, connectivity check,
or DRC check ran in the candidate phase.

P02-R4 fixes only the orchestration. It never disables the Innovus restore
guard. Each candidate runs in a fresh process that restores P01 once, recreates
the exact main stripes, checks the approved three-marker VDD residual, adds one
helper, and requires these independent gates:

- special PG connectivity: zero violations and zero DB markers;
- regular connectivity: zero violations;
- Innovus DRC: zero violations.

Trial processes emit reports and logs only. After a clean trial, the selected X
is replayed from P01 in one more fresh process; only that canonical process may
export DEF, LEF, PG netlist, GDS, and the final checkpoint. The wrapper then
requires the official stream-map and JIHD-merge GDS audit to pass. This policy
is recorded as `PROCESS_ISOLATION=ONE_INNOVUS_PROCESS_PER_CANDIDATE`.

P02-R4 executed the process-isolated search:

```text
REPO_HEAD=38a923e7687b7e2b43c5b21517d154cdd9bc9e0c
RUN_ID=innovus_ooc_pg_geometry_fix_r4_tx_ddr_strip_20260710_161123
RUN_ROOT=/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_pg_geometry_fix_r4_tx_ddr_strip_20260710_161123
R4_RC=8
PROCESS_ISOLATION=ONE_INNOVUS_PROCESS_PER_CANDIDATE
CANDIDATE_ROWS=10
CANDIDATES_ELECTRICALLY_EVALUATED=10
CANDIDATES_WITH_PG_ZERO=0
COMMON_PG_CONNECTIVITY_VIOLATION_COUNT=6
COMMON_PG_MARKER_COUNT=6
COMMON_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0
COMMON_DRC_MARKER_TOTAL=0
VDD_HELPER_SELECTED_X_UM=NONE
CANONICAL_REPLAY=NOT_RUN
GDS_AUDIT_RC=NOT_RUN
OUTPUT_FILES=0
```

R4 therefore has two separate verdicts:

- process-isolated candidate orchestration: `PASS`;
- bounded helper plus local second-`sroute` method: `FAIL`.

All ten X coordinates from `298.480` through `1418.480 um` produced the same
six-marker result. This rules out another blind X sweep with the same method.
It does not yet prove the exact electrical cause. Relative to R2's three
markers, the increase to six suggests that the helper may preserve the original
components and add new disconnected or dangling geometry, but this remains an
inference until the final marker TSV and detailed connectivity report are
compared.

The missing parent `verify_connectivity_*`, DRC, GDS-audit, and output files are
expected fail-closed behavior. They belong to the canonical replay, which was
correctly skipped because no trial passed. They are not an export failure.

Next P02 action: read-only comparison of one representative trial's main and
final marker reports, plus marker-class and `sroute` transcript comparison
across all ten trials. Do not modify geometry or launch R5 before that evidence
is reviewed. The reusable failure ledger is
`TOP/docs/35_INNOVUS_PG_DEBUGGING_PLAYBOOK_AND_FAILURE_LEDGER.md`.

## Parallel P03/P04 Registration - TX Packet Core HV LVS

Status: `READ_ONLY_INTAKE_PASS_MISMATCH_CLASSIFIED_REBUILD_REQUIRED`

Candidate historical LVS directory:

```text
/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PvsLVS/spadmic_tx_packet_core_HV
```

The read-only collector completed with source stability `PASS`, 98 source
entries, 88 files, 32 selected text files, and no collector errors. Raw bundle:

```text
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_tx_packet_core/
  tx_packet_core_hv_lvs_inventory_20260710_165038/pvs/lvs/raw/
    tx_packet_core_hv_lvs_inventory_20260710_165038
```

The historical PVS run is an explicit `MISMATCH`, but it does not compare the
reported final fixed-DIFFCON GDS. Its compared GDS SHA256 is
`6d29b54199bb961062acd2057bb9f28ec27aebae3e694293e8ae423d92ecbadf`.
It uses layout top `spadmic_tx_packet_core_HV`, source top
`spadmic_tx_packet_core`, recognizes zero layout pins versus 156 source pins,
and provides no official JIHD CDL while the source retains JIHD Verilog module
definitions. These are independent input, hierarchy, boundary, and library
contract failures.

One concrete extracted connectivity issue is also recorded: layout net 44 has
both `output_fifo_free_words_o[0]` and `output_fifo_level_o[0]` labels. The
missing-pin pattern affects every top pin, not only `src_data_i[i][j]`, so the
adjacent bracket naming hypothesis is refuted as the primary cause of this
run. DIFFCON remains unassigned as a cause because the input GDS identity is
wrong and no localized device delta proves it.

P03/P04 now rebuild the canonical block rather than rerunning this template:
canonical top on both sides, mapped Innovus GDS, filtered PG netlist, official
JIHD CDL, strict pin-set and input-hash gates, PVS DRC zero outside antenna,
and explicit LVS `MATCH`. The detailed evidence and negative command ledger
are in `TOP/docs/33_TX_PACKET_CORE_HV_PVS_LVS_TRIAGE.md`.

### P03-R1 Active TX Scalar Interface

Status: `PASS_LOCAL_GENUS_SERVER_PENDING`

The active matrix TX boundary now exposes 64 unique scalar pins
`src_data_i_s<source>_b<bit>`. A checked-in CSV manifest drives generated RTL
regions; ordinary 1D buses and the legacy `spadmic_top_v1` arbiter path are
unchanged. `spadmic_event_bundle_tx` reconstructs the 4x16 array internally.

Measured local results:

- manifest/generator tests: 4 pass, 0 fail;
- exhaustive mapping oracle: 258 pass, 0 fail;
- event bundle: 14 pass, 0 fail;
- TX egress core: 11 pass, 0 fail;
- TX egress cluster: 13 pass, 0 fail;
- matrix top shell: 32 pass, 0 fail.

These results prove API mapping and RTL behavior only. P03 remains open until
fresh server Xcelium, packet OOC Genus, Innovus, and PVS evidence pass. The
canonical rebuild contract and negative command ledger are maintained in
`TOP/docs/36_TX_PACKET_CORE_CANONICAL_REBUILD_AND_PVS_CLOSURE.md`.

## Update Procedure

After each server phase:

1. Return the complete status report and the focused gate reports listed in
   the phase.
2. Review the reports independently of the wrapper return code.
3. Update this journal with immutable paths and measured values.
4. Commit and push the evidence update on `SPADMIC_test`.
5. Issue only the next unblocked phase command.

The complete flow contract and server command reference are maintained in
`TOP/docs/31_DIGITAL_ASSEMBLY_V1_HANDOFF_AND_PVS_FLOW.md`.

## P03-R2 Paired Pin and Clean-PG Implementation

Status: `PASS_LOCAL_CADENCE_SERVER_PENDING`

The canonical packet/strip physical contract is now implemented. A versioned
19-row CSV assigns identical local MET3 X coordinates to packet north and strip
south. The active packet OOC plan consumes all 64 scalar source-data names and
contains no nested source-data physical port. The assembly generator scores R0
and MY from transformed LEF geometry instead of forcing MY.

The generic OOC PG implementation was corrected at its source. The old
`addStripe -start_offset` formula omitted the core-left reference and caused
the measured 10.080 um displacement. TX runs now use explicit `add_shape`
centerlines shared with their PG terminals, `sroute -connect {corePin}`, and PG
insertion before signal route. Streamout now includes the official map and JIHD
merge; the wrapper requires the mapped/merged GDS audit.

Measured local gates:

```text
PY_COMPILE=PASS
BASH_SYNTAX=PASS
PACKET_PLAN_GENERATION=PASS
STRIP_PLAN_GENERATION=PASS
TOP_PNR_UNIT_TESTS=24_PASS_0_FAIL
GIT_DIFF_CHECK=PASS
CADENCE_INNOVUS=NOT_RUN_LOCAL
PVS=NOT_RUN_LOCAL
```

This entry does not close packet or strip physical implementation. Fresh
packet server Genus/Innovus/PVS is next. Strip rebuild starts only after the
packet report gates are understood, then the two actual LEFs are scored and
the signal-only assembly smoke is run.

## P03-R3 Staged No-Auto-Advance Server Procedure

Status: `PHASE1_XCELIUM_AND_GENUS_FEASIBILITY_PASS`

The first canonical server phase is now encoded in
`TOP/ci/server_run_tx_packet_canonical_phase1.sh`. The procedure separates
repository synchronization, tool/static preflight, five focused Xcelium tests,
the full Xcelium regression, Genus execution, report extraction, and packaging
into independent commands. Every step writes a structured status report and
appends an execution journal under one timestamped `/sim` diagnostic root.

This procedure was added because a long interactive command block has two
failure modes: shell guards can terminate an SSH session, and automatic
chaining can start an expensive downstream tool before the previous evidence
has been reviewed. The new driver uses `set +e`, contains no explicit `exit`,
is always invoked as a child process, and never advances by itself.

The five focused tests are not a replacement for regression. They are an early
diagnostic gate for scalar source mapping, event-bundle reconstruction, TX core
and cluster behavior, and matrix-shell integration. Only a clean focused gate
permits the full Xcelium run; only a clean full run permits Genus.

Genus tool completion remains distinct from Genus closure. The generated
review preserves `check_design`, timing-intent, post-opt timing, QoR, warning
classification, unique scalar-name count, nested-name count, and netlist/SDC
hashes. These reports must be analyzed before packet Innovus is unblocked.

Local implementation evidence:

```text
DRIVER_BASH_SYNTAX=PASS
DRIVER_NO_EXPLICIT_EXIT=ENFORCED_BY_UNIT_TEST
DRIVER_NO_INNOVUS_OR_PVS=ENFORCED_BY_UNIT_TEST
DRIVER_INIT_TEMP_SESSION=PASS
GENUS_GATE_VALIDATOR_TESTS=6_PASS_0_FAIL
TOP_PNR_UNIT_TESTS=48_PASS_0_FAIL
PY_COMPILE=PASS
GIT_DIFF_CHECK=PASS
CADENCE_SERVER_XCELIUM_AND_GENUS=CAPTURED
CADENCE_SERVER_GENUS_GATE_REPLAY=PASS
```

### P03-R3 Server Evidence - 2026-07-13

Status: `XCELIUM_AND_GENUS_FEASIBILITY_PASS`

The staged procedure ran from Git commit
`55a9f9b122a063afd8fb169b112110c22d810fe4` with diagnostic root:

```text
/sim/ksabra/SPADMIC_work/diagnostics/tx_packet_canonical_phase1_20260713_102822
```

Measured Xcelium evidence:

```text
FOCUSED_TESTS=5_PASS_0_FAIL
SCALAR_MAPPING_ORACLE=258_PASS_0_FAIL
FULL_REGRESSION=35_PASS_0_FAIL_0_MISSING
XCELIUM_RUN=/sim/ksabra/SPADMIC_work/xcelium/xcelium_tx_packet_canonical_20260713_102822
```

The focused gate proves the scalar mapping, event-bundle reconstruction, TX
core, TX cluster, and matrix-shell boundary before the full regression. The
full run then passed all 35 required benches. The original report extractor's
broad `fail|error` grep produced false-positive review lines from text such as
`0 fail`, `errors: 0`, `[PASS] ... error expectation`, and the functional port
name `bundle_missing_source_error_o`. These strings are not simulation or
Genus failures. Report-driver commit
`b164b8d10daad7b45f6004d6e785dbe432f82ab0` restricted extraction to
FAIL/MISSING summary rows and explicit simulator error syntax. Replaying only
`xcelium-report` against the immutable run produced:

```text
PASS=35
FAIL=0
MISSING=0
FAILURE_MARKER_COUNT=0
```

Measured Genus evidence:

```text
GENUS_RUN=/sim/ksabra/SPADMIC_work/genus/genus_ooc_tx_packet_core_canonical_20260713_102822
GENUS_TOOL_RC=0
POSTSYN_NETLIST_SHA256=2462d912e33581c32b72562e1fc9d10878e742d1dedf43c3af1845650303b968
POSTSYN_SDC_SHA256=e30c45484581d6edad2fcdde60807ad4d4587e921214f9a1174afdd123fbd33d
NESTED_SRC_DATA_NAME_COUNT=0
UNIQUE_SCALAR_SRC_DATA_NAME_COUNT=64
UNRESOLVED_REFERENCES=0
TOOL_ERROR_COUNT=0
CLOCK_NAME=clk_sys
CLOCK_PERIOD_PS=6250.0
CLOCK_REGISTER_COUNT=4407
SEQUENTIAL_INSTANCE_COUNT=4407
WNS_PS=845.1
TNS_PS=0.0
VIOLATING_PATH_COUNT=0
DEFAULT_PATH_GROUP_STATUS=NO_PATHS
INPUTS_WITHOUT_CLOCKED_EXTERNAL_DELAY=0
OUTPUTS_WITHOUT_CLOCKED_EXTERNAL_DELAY=0
INPUTS_WITHOUT_EXTERNAL_DRIVER_TRANSITION=101
OUTPUTS_WITHOUT_EXTERNAL_LOAD=52
NONBLOCKING_TOOL_WARNING_COUNT=2
```

The complete reports close the intended typical OOC feasibility criteria. The
only clock is `clk_sys`; its clock-table register count equals the QoR
sequential instance count, so all 4407 sequential instances are covered. WNS
is positive by 845.1 ps, TNS is zero, and there are no violating paths. All
required timing-intent categories are zero, including unclocked sequential
logic, conflicting clocks, multiple drivers, invalid exceptions, and missing
clocked external delays.

The 101 inputs without an external driver/transition and 52 outputs without an
external load are not connectivity failures. They are an explicit OOC
environment limitation: this run proves internal typical feasibility but its
IO timing is optimistic. It is not MMMC and is not signoff. The two classified
tool warnings are nonblocking `MESG-11` maximum-message-print-count notices.
The old `undriven count=8` was a classifier defect: it counted zero-valued
summary headings such as `Undriven Port(s) 0`. Future Genus runs ignore those
headings; the immutable old report is tolerated only because the underlying
summary value is zero.

`TOP/syn/scripts/validate_tx_packet_genus_ooc.py` now encodes this decision as
a fail-closed gate. It also requires exact 64-port scalar parity, no nested top
port names, exact 4407/4407 clock coverage, complete external drive/load rows,
output hashes, and `SIGNOFF_READY=NO`.

Report-driver commit `96674eb9d91cd148a725fc78c35e6ce2b24a9d70`
replayed only `genus-report` against the immutable Genus run on 2026-07-13 at
10:09:29 UTC. The resulting gate is:

```text
GENUS_GATE_STATUS=PASS
GENUS_GATE_RESULT=READY_FOR_PACKET_INNOVUS_FEASIBILITY
GENUS_GATE_ERROR_COUNT=0
NESTED_TOP_PORT_COUNT=0
SCALAR_SOURCE_PORT_COUNT=64
CLOCK_REGISTER_COUNT=4407
SEQUENTIAL_INSTANCE_COUNT=4407
WNS_PS=845.1
TNS_PS=0.0
VIOLATING_PATH_COUNT=0
INNOVUS_FEASIBILITY_READY=YES
MMMC_STATUS=NOT_RUN_TYPICAL_ONLY
SIGNOFF_READY=NO
```

This replay unblocks only the staged packet Innovus preflight. It does not
prove placement, routing, PG connectivity, post-route timing, GDS correctness,
PVS closure, or final handoff readiness.

The absent `clk_sys` to `clk_cfg_40m` / `clk_ref_40m` reports are expected for
this OOC block because `spadmic_tx_packet_core.sdc` creates only `clk_sys`; the
generic report helper writes cross-clock files only when both named clocks
exist. Their absence is therefore not itself a packet-core timing failure.

Negative knowledge retained from this review:

- Do not rerun Genus merely to repair report extraction or the old warning
  classifier; replay the validator against the immutable netlist and reports.
- Do not infer timing closure from twenty displayed `Slack:= 845` lines. Use
  the full QoR row, timing-intent categories, and clock/register coverage.
- Do not treat `default No paths` as proof by itself. It is accepted only with
  zero missing clocked IO delays and the other timing-intent checks.
- Do not treat this typical-only OOC pass as IO closure, MMMC, or signoff while
  drive/transition and output-load models remain deferred.

The text evidence package is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/tx_packet_canonical_phase1_20260713_102822/packages/tx_packet_canonical_phase1_20260713_102822_text_evidence.tar.gz
SHA256=fde94d254d7636161c4ff473f1c0ee9b88a72ff43c145e81a0983f5a5f21c0e7
BYTES=197803
```

This archive was created before the automated Genus gate replay. Preserve it
as evidence of the immutable source run, but do not claim that it contains the
later `07_genus_gate.rpt`. A refreshed package is useful only after the next
staged evidence is collected; rerunning Genus is neither required nor allowed
for this reporting-only update.

## P03-R4 Staged Packet Innovus Procedure

Status: `SERVER_R1_REVIEW_REQUIRED_DIAGNOSTIC_STAGED`

`TOP/ci/server_run_tx_packet_canonical_phase2.sh` continues from the accepted
Phase-1 gate. It creates a separate active session and unique Innovus run root,
then exposes repository sync, Innovus preflight, one foreground packet Innovus
run, report collection, and packaging as independent operator commands. It
does not launch PVS and does not modify historical OA, GDS, PVS, or `_HV`
evidence.

The fixed physical policy for this attempt is:

```text
CANONICAL_TOP=spadmic_tx_packet_core
SIGNAL_ROUTE_POLICY=MET1_TO_MET3
PG_POLICY=EXPLICIT_EXACT_METTP_STRIPES_COREPIN_SROUTE
ROUTE_PROFILE=met1_effort
ANTENNA_REPAIR=DISABLED_FOR_THIS_MILESTONE
ANTENNA_POLICY=DEFERRED_BUT_FINAL_HANDOFF_BLOCKED
PVS_STATUS=NOT_RUN
```

The preflight rechecks the Phase-1 gate, exact post-synthesis netlist and SDC
hashes, Cadence/Innovus availability, official stream map, JIHD merge GDS,
layout-audit inputs, generated route/PG policy, and that the new Innovus root
does not already exist. No Innovus command may run unless every preflight
field is `PASS`.

The execution step pins the XH018 `xx31`/JIHD stack, MET1-MET3 signal layer
names and indices, exact requested core dimensions, placement density, scan
handling, min-area repair, and DRC-safe filler policy. Do not rely on inherited
shell defaults here: shared OOC Tcl intentionally supports experimental
environment overrides, and a stale override from another block could otherwise
change the canonical database after a clean generated-plan preflight.

The canonical OOC validator previously trusted
`POSTROUTE_SETUP_TIMING=PASS` and `POSTROUTE_HOLD_TIMING=PASS`. Those fields
only prove that the `timeDesign` command returned successfully; they do not
prove timing closure. The validator now parses the actual Innovus setup and
hold `.summary` or `.summary.gz` files and requires, independently for both
modes, nonnegative WNS, zero TNS, and zero violating paths. When selected-net
min-area repair changes routing, its post-repair timing summaries take
precedence over the earlier reports. Missing, ambiguous, malformed, or
negative timing evidence fails closed.

The DRC marker policy also had an internal contradiction: Python allowed an
antenna-only milestone, while Tcl made every nonzero antenna count force the
overall marker classification to `FAIL`. Tcl now accepts antenna markers only
when `SPADMIC_OOC_REQUIRE_ANTENNA_CLEAN=0`, records
`ANTENNA_MARKER_STATUS=REVIEW_REQUIRED` and
`ANTENNA_MILESTONE_ACCEPTED=1`, and continues to reject min-area or other DRC
markers. The canonical report still emits `FINAL_HANDOFF_READY=NO`; this is a
deferred repair debt, not a DRC waiver or signoff result.

Negative operating rules for this stage:

- Do not rerun Xcelium or Genus; inherit and hash-check the accepted outputs.
- Do not infer closure from the Innovus wrapper return code or successful
  `timeDesign` commands; inspect measured timing and all canonical gate fields.
- Do not repair antenna during this first deterministic route. Preserve the
  marker evidence for a later targeted repair and PVS classification.
- Do not run PVS, stage a PVS package, or modify OA after this phase. PVS starts
  only after packet Innovus reports `READY_FOR_PVS_CANDIDATE`.
- Do not reuse an Innovus run directory after a failure. Diagnose that unique
  run and initialize a new session for any changed candidate.
- Do not launch several restore-and-try candidates in one Innovus process.

Local implementation evidence is recorded separately from server evidence:

```text
PHASE2_DRIVER_BASH_SYNTAX=PASS
PHASE2_DRIVER_NO_EXPLICIT_EXIT=ENFORCED_BY_UNIT_TEST
PHASE2_DRIVER_NO_AUTO_ADVANCE=ENFORCED_BY_UNIT_TEST
PHASE2_DRIVER_NO_PVS=ENFORCED_BY_UNIT_TEST
PHASE2_CANONICAL_ENVIRONMENT_PINNING=ENFORCED_BY_UNIT_TEST
CANONICAL_TIMING_PARSER_PLAIN_AND_GZIP=PASS
CANONICAL_TIMING_POST_REPAIR_PRECEDENCE=PASS
REAL_INNOVUS_GZIP_NEGATIVE_SETUP_DETECTION=PASS_WNS_M0P140_TNS_M0P885_PATHS_8
ANTENNA_DEFER_POLICY_TEST=PASS
TOP_PNR_UNIT_TESTS=57_PASS_0_FAIL
CADENCE_PACKET_INNOVUS=R1_CAPTURED_REVIEW_REQUIRED
```

### P03-R4 Server Evidence - Packet Innovus R1

Status: `FAIL_THREE_BLOCKER_CLASSES_PVS_NOT_RUN`

The Phase-2 preflight passed at
`aae354384ff5cb354132954ec53dba5904c24838`, then the foreground packet run
completed under:

```text
SESSION_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/tx_packet_canonical_phase2_20260713_124110
BLOCK_ROOT=/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_packet_core_canonical_20260713_124110/blocks/tx_packet_core
INNOVUS_RC=0
WRAPPER_RC=8
CANONICAL_GATE_STATUS=FAIL
PVS_STATUS=NOT_RUN
```

Positive evidence retained from the failed candidate:

```text
REGULAR_CONNECTIVITY_STATUS=PASS
SETUP_WNS_NS=0.169 TNS_NS=0.000 VIOLATING_PATHS=0
HOLD_WNS_NS=0.209 TNS_NS=0.000 VIOLATING_PATHS=0
GDS_FILE_STATUS=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
GDS_SHA256=e4d83514ed2014e28cce911703f4befab897762edd2f96c58bc5473eb0c74dba
OTHER_MARKER_COUNT=0
```

The candidate failed for three non-antenna classes:

- `PG_CONNECTIVITY_STATUS=FAIL` while `SROUTE_PG=PASS`; execution of `sroute`
  is not proof that all special-wire components connect.
- Seven MET1 minimum-area markers remain on `n_9705`, `n_9709`, `n_9725`,
  `n_9733`, `n_9736`, `n_9744`, and `n_9747` after selected-net repair.
- Every one of the 19 north stream-pin centers is `+0.280 um` from its CSV
  target. The delta is uniform from valid through data bit 15 and equals half
  the configured `0.56 um` grid.

The 29 antenna markers are recorded separately as
`DEFERRED_FINAL_HANDOFF_BLOCKED`. They are accepted for this diagnostic
milestone only; final handoff remains `NO`. No unrelated DRC class exists.

The exact pin delta strongly suggests command-reference or grid-snap behavior,
not random placement. It does not authorize changing the canonical CSV or
validator. The packet and strip local X contract remains identical; a later
candidate must compensate the Innovus command mapping and prove the emitted LEF
centers.

The normal PG report did not retain detailed component geometry. Two new
operator gates therefore precede any reroute:

1. `diagnose` reads and hashes existing artifacts only, compares planned and
   emitted stream-pin geometry, and preserves the min-area repair ledger.
2. `pg-probe` launches one fresh Innovus process, restores
   `05_postroute_export` once, runs connectivity/database queries only, and
   records `DESIGN_MODIFICATION=NOT_RUN`.

Local diagnostic implementation evidence:

```text
ANALYZER_PY_COMPILE=PASS
PHASE2_DRIVER_BASH_SYNTAX=PASS
GENERIC_PG_PROBE_BASH_SYNTAX=PASS
FOCUSED_DIAGNOSTIC_TESTS=7_PASS_0_FAIL
TOP_PNR_UNIT_TESTS=60_PASS_0_FAIL
GIT_DIFF_CHECK=PASS
```

The first `diagnose` replay at commit `13057f1b...` captured all physical
evidence and emitted `STATUS=PASS`, but the same report later copied the
min-area ledger as an unqualified `STATUS=REVIEW_REQUIRED`. The driver's
last-value key reader therefore wrote `04_innovus_diagnose STATUS=FAIL` despite
an analyzer return code of zero. This was report-schema shadowing, not a new
physical failure. The prerequisite gate correctly prevented `pg-probe`, so no
Innovus probe process ran. Nested repair fields are now prefixed `REPAIR_`, and
the driver gates on the dedicated `DIAGNOSIS_STATUS` key.

Negative knowledge from R1:

- Do not rerun Genus; its accepted netlist and SDC hashes remain the source.
- Do not run PVS on this GDS despite the mapped/merged export passing.
- Do not call this a generic signal-route failure; regular connectivity and
  both measured timing modes pass.
- Do not repair or waive antenna while PG, min-area, and paired-pin geometry
  are unresolved.
- Do not reuse the failed Innovus root or restore several candidates in one
  process.
- Do not accept the `+0.280 um` pin drift by moving the assembly contract.
- Do not infer PG closure from `add_shape`, `sroute`, or tool return codes.

## P04-R1 Canonical PVS Source And Replay Implementation

Status: `PASS_LOCAL_CADENCE_SERVER_PENDING`

The handoff package now preserves the raw Innovus PG source and creates a
separate canonical LVS source by official JIHD CDL membership. The gate requires
VDD/VSS, rejects nested top dimensions, and compares expanded source ports to
the LEF pin set exactly. The package carries the exact CDL and records all
source/CDL hashes.

Template replay now fails when a requested old value has zero occurrences,
applies artifact replacements before template-root relocation, and verifies
canonical top/GDS/source/CDL presence after patching. DRC wrappers expose
explicit `base` and `density` variants. LVS runs only after package and pin
parity audits.

Measured local evidence:

```text
TOP_PNR_UNIT_TESTS=37_PASS_0_FAIL
PY_COMPILE=PASS
BASH_SYNTAX=PASS
PVS_GUI_TEMPLATE=NOT_CREATED_YET
PVS_BASE_DRC=NOT_RUN
PVS_DENSITY_DRC=NOT_RUN
PVS_LVS=NOT_RUN
```

The reusable source, replay, and anti-pattern notes are in
`TOP/docs/37_PVS_CANONICAL_SOURCE_AND_REPLAY_CONTRACT.md`.

## P04-R2 Canonical Innovus-To-PVS Gate

Status: `PASS_LOCAL_SERVER_REPORTS_PENDING`

The TX OOC wrapper now invokes a canonical candidate validator after the GDS
audit. It verifies the physical LEF interface, scalar packet boundary, exact
paired-pin X coordinates, PG pin semantics, DRC/connectivity/timing/export
statuses, and mapped/merged GDS evidence. Immutable staging can require this
gate with `--qualification-profile canonical_tx`.

Local tests prove that deferred antenna is recorded as a final-handoff block,
non-deferred antenna rejects a candidate, and a stream-pin coordinate drift
rejects a candidate. Cadence-generated reports remain required before any real
package can pass.

### P03-R5 Server Evidence - Packet Restore-Only PG Probe

Status: `PASS_READ_ONLY_TOPOLOGY_CAPTURED_PHYSICAL_CANDIDATE_STILL_FAIL`

After the report-schema fix at `50306e960dc6d86ac625d2270e688a65bd8a6bd6`,
`diagnose` replayed with:

```text
DIAGNOSIS_STATUS=PASS
RESULT=BLOCKERS_CLASSIFIED
DESIGN_MODIFICATION=NOT_RUN
```

The subsequent probe used one fresh Innovus process and one restore from the
packet `05_postroute_export` checkpoint:

```text
RESTORE_DESIGN=PASS
DESIGN_MODIFICATION=NOT_RUN
VERIFY_SPECIAL_REPORT=PASS
SPECIAL_CONNECTIVITY_VIOLATIONS=4
VDD_SWIRE_COUNT=40
VSS_SWIRE_COUNT=40
```

All four connectivity findings are VDD. Three are horizontal components with
boxes `{10.080 125.000 2056.880 128.120}`, `{10.080 133.960 2056.880
137.080}`, and `{10.080 277.320 2056.880 280.440}`. The fourth is the aggregate
VDD network box `{10.080 9.680 2056.880 366.240}`. VSS has no special open.

The probe marker count `40` decomposes as seven minimum-area, 29 antenna, and
four VDD connectivity markers. It must not be reported as 40 PG failures.

The minimum-area repair ledger proves a rejected method, not merely an
unclean result:

```text
SELECTED_NET_COUNT=7
AREA_DELETE_COUNT=7
AREA_DELETE_FAILURES=NONE
ROUTE_FAILURES=NONE
PRE_MIN_AREA_COUNT=7
POST_MIN_AREA_COUNT=7
```

Every marker is the same `0.38 x 0.28 um` MET1 rectangle with actual area
`0.1064 um2`, below required `0.2020 um2`. The three route commands recreated
the same access stubs. Do not retry this sequence.

R2 local implementation now separates canonical center from command argument.
TX pin target `100.800` produces `assign_x_um=100.520`; the validator still
requires an emitted center of `100.800`. A read-only SWIRE analyzer, installed
command-help gate, and isolated `via-only`/`patch-stack` PG trials were added.
Each PG method gets a fresh process and no save/export. A method passes only at
special connectivity zero, regular connectivity zero, and no DRC increase.

```text
R2_PY_COMPILE=PASS
R2_SHELL_SYNTAX=PASS
R2_TOP_PNR_UNIT_TESTS=64_PASS_0_FAIL
R2_CADENCE_PG_ANALYSIS=SERVER_PENDING
R2_CADENCE_PG_VIA_TRIAL=NOT_RUN
```

The analysis report records both `SOURCE_ARTIFACT_HEAD` (the immutable R1
implementation) and `REPORT_DRIVER_HEAD` (the newer read-only parser). A newer
report driver does not change or requalify the physical candidate.

Negative rules added by this probe:

- Do not run another helper-X scan or local second `sroute`; packet and strip
  evidence both identify a method/topology problem.
- Do not infer that `editPowerVia` works because its command RC is zero; older
  MPTDC evidence had accepted commands with failing downstream connectivity.
- Do not combine via-only and patch-stack in one process.
- Do not save, export, stage, or run PVS from an in-memory method trial.
- Do not let a PG repair hide the independent minimum-area and antenna gates.

### P03-R6 Server Evidence - PG Topology Correlation And Count-Format Repair

Status: `PASS_GEOMETRY_CORRELATED_TRIAL_STILL_BLOCKED_BY_REPORT_FORMAT`

The read-only analyzer at report-driver head
`54e7ba486109ed5cd32f1d985c30aacb5e4c5e66` correlated all three VDD row
components with one actual MET1 rail and the single vertical METTP VDD stripe.
It produced bounded overlap windows at row centers `126.560`, `135.520`, and
`278.880 um`. VSS remained clean and marker decomposition remained
`7 minimum-area + 29 antenna + 4 VDD connectivity`.

The analyzer correctly remained blocked because
`SPECIAL_CONNECTIVITY_VIOLATION_COUNT=UNKNOWN`. This was not missing topology:
the parser recognized only the console form `Verification Complete : N Viols`,
while this Innovus 22.33 detail report used the summary form
`N Problem(s) (IMPVFC-200): Special Wires`. The repair accepts either official
form, records which form supplied the count, and requires both values to agree
when both appear. A disagreement still blocks the trial. No design or Cadence
command changed during this correction.

```text
R3_PG_ANALYZER_TESTS=5_PASS_0_FAIL
R3_TOP_PNR_UNIT_TESTS=66_PASS_0_FAIL
R3_PY_COMPILE=PASS
R3_DIFF_CHECK=PASS
R3_CADENCE_DESIGN_MODIFICATION=NOT_RUN
```

### P03-R7 Server Evidence - PG Topology Trial Authorization

Status: `PASS_ONE_ISOLATED_VIA_ONLY_TRIAL_AUTHORIZED`

The parser replay at report-driver head
`53aa3b1b6e5454a52ec4d4e87eda6fb615094e82` consumed the same immutable probe
artifacts and resolved the Innovus summary count without reopening the design:

```text
SPECIAL_CONNECTIVITY_VIOLATION_COUNT=4
SPECIAL_CONNECTIVITY_COUNT_SOURCE=IMPVFC_200_PROBLEM_SUMMARY
SPECIAL_CONNECTIVITY_COUNT_CONSISTENCY=PASS
OPEN_COMPONENT_COUNT=4
CONNECTIVITY_MARKER_VDD_COUNT=4
CONNECTIVITY_MARKER_VSS_COUNT=0
EDIT_POWER_VIA_TRIAL_DECISION=READY_FOR_ONE_ISOLATED_TRIAL
```

Each disconnected VDD row has exactly one intersecting MET1 SWIRE and the same
selected METTP stripe. The bounded via-search windows are:

```text
row 1: {515.200 126.160 518.560 126.960}
row 2: {515.200 135.120 518.560 135.920}
row 3: {515.200 278.480 518.560 279.280}
```

This authorizes only the next no-design command-help capture and then one
fresh-process `via-only` experiment. It does not authorize patch-stack,
canonical replay, export, staging, or PVS. The trial parser now recognizes the
same two Innovus count formats and returns `CONFLICT` when both are present but
disagree; all non-integer count states fail closed.

### P03-R8 Server Evidence - Installed Via-Generation Semantics

Status: `PASS_HELP_CAPTURED_TRIAL_METHOD_CORRECTED_BEFORE_RESTORE`

The no-design help process captured `man editPowerVia` successfully from the
installed Innovus release. It proved `-nets`, `-area`, `-bottom_layer`, and
`-top_layer`, but also exposed two requirements absent from the unrun first
harness: run `setViaGenMode -area_only 1` to constrain insertion to the supplied
windows, and set `-exclude_stack_vias 0` to permit a stack across non-adjacent
layers.

```text
COMMAND_editPowerVia=MAN
PG_COMMAND_HELP_RC=0
STATUS=PASS
RESULT=EDIT_POWER_VIA_HELP_CAPTURED_NO_DESIGN_LOADED
```

The probe has `VDD_MET2_SWIRE_COUNT=0` and `VDD_MET3_SWIRE_COUNT=0`. Therefore
three adjacent-layer calls have no proven intermediate target wires. This is
also the method older MPTDC evidence showed as command-PASS but
connectivity-FAIL. It was stopped before execution and replaced by one direct
MET1-to-METTP stack call per row. Adjacent calls remain only in the separate
patch-stack fallback after explicit intermediate shapes exist. No design was
loaded or modified while making this correction.

```text
R4_FOCUSED_TESTS=11_PASS_0_FAIL
R4_TOP_PNR_UNIT_TESTS=66_PASS_0_FAIL
R4_BASH_SYNTAX=PASS
R4_TCL_INFO_COMPLETE=1
R4_DESIGN_MODIFICATION=NOT_RUN
```

### P03-R9 Server Evidence - Direct Stack Closes PG And Fails DRC

Status: `REJECTED_TOPOLOGY_CORRECT_GEOMETRY_UNSAFE`

The isolated `via-only` trial at report-driver head
`1ea182b757a451cf522bdf37b56f49e974d7f1c7` restored the immutable packet
checkpoint once, enabled area-only via generation, and issued one bounded
direct MET1-to-METTP stack command for each of the three proven VDD rows. All
four commands returned PASS, and special connectivity improved from four
violations to zero. Regular connectivity stayed at zero.

The method is nevertheless rejected. Authoritative `verify_drc` increased
from seven to 25 violations:

```text
PRE:  MET1 Mar=7                                      total=7
POST: MET1 Mar=7
      MET2 Short=6 MetSpc=2                           subtotal=8
      VIA2 CShort=3 CutSpc=1                          subtotal=4
      MET3 Short=6                                    subtotal=6
                                                     total=25
DRC_DELTA=18
```

The seven original minimum-area markers remain. The added violations are on
the intermediate stack layers, so `patch-stack` is not the next experiment:
adding MET2/MET3 patches before understanding these collisions would add
geometry on layers already failing short and spacing rules. The trial saved no
checkpoint and exported no DEF, LEF, GDS, or netlist.

The Innovus startup log repeats pre-existing MPTDC black-box library messages,
including missing antenna attributes and `TECHLIB-704/702` VDDA/VSSA mappings.
They precede the three `editPowerVia` commands. Restore succeeded, all four
trial commands passed, and the physical rejection is established by the
post-command DRC report; do not misclassify those startup messages as the cause
of the 18 new markers.

The first trial ended without saving marker objects, so summaries alone cannot
prove which generated via geometries collide. R5 adds one separately named,
fresh-process diagnostic replay. It repeats the same rejected command only to
dump the DRC marker database immediately before and after, compares it with the
immutable R9 tuple, attributes each new marker to the nearest proven VDD row,
and still saves/exports nothing. The gate passes only as a diagnostic capture;
it cannot validate the physical method.

```text
R5_FOCUSED_TESTS=10_PASS_0_FAIL
R5_TOP_PNR_UNIT_TESTS=70_PASS_0_FAIL
R5_PY_COMPILE=PASS
R5_BASH_SYNTAX=PASS
R5_TCL_INFO_COMPLETE=1
R5_CANONICAL_RERUN=BLOCKED
R5_PVS=BLOCKED
```

### P03-R10 Server Evidence - Marker Database Scope And Abort Semantics

Status: `DIAGNOSTIC_HARNESS_REJECTED_NO_VIA_COMMAND_EXECUTED`

The first instrumented replay stopped before `setViaGenMode` or any
`editPowerVia` call:

```text
BASELINE_PRECONDITION_FAILED: drc=7 markers=40 regular=0 special=4
```

The mismatch is a reporting-scope defect. `verify_drc` reports the seven
current non-antenna DRC violations, while restored `top.markers` retains all
known classes: seven minimum-area, 29 antenna, and four connectivity markers.
The marker dump must preserve the raw total but exclude `type=Antenna` and
`type=Connectivity` from the DRC-comparison TSV. Its accounting is now explicit
instead of assuming `top.markers` equals the most recent command's count.

The failed guard also exposed an Innovus batch-control defect. Raising Tcl
`error` from the `-init` script left `innovus -nowin` at an interactive prompt,
so subsequent shell lines were interpreted as Tcl. `trial_abort` now writes its
status and calls `exit 8`, ensuring every fail-closed guard terminates the
Innovus child. The corrected replay uses a new immutable `_drc_probe_r2` root
and Step 10 report paths; the failed Step 09 root is not reused or deleted.
The shell wrapper also connects Innovus stdin to `/dev/null`, so any other
unhandled Tcl error receives EOF instead of consuming subsequent shell input.

### P03-R11 Server Evidence - Direct Stack Marker Classification

Status: `PASS_DIAGNOSTIC_CLASSIFIED_PHYSICAL_METHOD_REMAINS_REJECTED`

Step 10 at report-driver head
`61c9e89dbe30dc6901b906205dc9ce3e1d06db5a` reproduced the reviewed direct
stack result in a fresh process and reconciled the marker database exactly:

```text
special connectivity:  4 -> 0
regular connectivity:  0 -> 0
filtered DRC markers:   7 -> 25
raw marker database:   40 -> 54
excluded antenna:      29 -> 29
excluded connectivity: 4 -> 0
new DRC markers:       18
removed baseline:       0
```

The 18 new markers are six MET2 shorts, two MET2 parallel-run-length spacing
violations, six MET3 shorts, three VIA2 cut-shorts, and one VIA2 cut-spacing
violation. Row attribution is `6 / 9 / 3` for VDD rows 1, 2, and 3. The marker
messages identify existing routed signal nets at every row, including
`CTS_20`, `CTS_26`, `FE_OFN265_n_19`, `FE_OFN356_n_7096`,
`FE_OFN122_n_221`, `FE_OFN4997_n_293`, and one output-FIFO data net. This is
direct evidence that the default generated stack footprint collides with
ordinary MET2/MET3 routing and VIA2 cuts; it is not a PG topology ambiguity.

`patch-stack` remains blocked because it would add geometry on the already
conflicting intermediate layers. The next and only authorized experiment is
one fresh-process `via-1x1` trial using the same three areas and explicit
`-via_rows 1 -via_columns 1`. It tests via multiplicity without changing X,
row selection, stripe geometry, or the source checkpoint. The gate saves and
exports nothing, classifies both accepted and rejected physical outcomes, and
still blocks canonical replay and PVS pending operator review.

### P03-R12 Server Evidence - 1x1 Stack Rejection And Pre-CTS Candidate

Status: `PASS_DIAGNOSTIC_CLASSIFIED_PHYSICAL_METHOD_REMAINS_REJECTED`

Step 11 at report-driver head
`ab0b86fc6a292fa073dae4e1b6263d90699e5c05` completed with the exact reviewed
tuple:

```text
special connectivity:  4 -> 0
regular connectivity:  0 -> 0
filtered DRC markers:   7 -> 22
new DRC markers:       15
removed baseline:       0
new marker classes:     MET2=8 MET3=6 VIA2=1
```

Constraining every direct stack to `-via_rows 1 -via_columns 1` removed the
three VIA2 cut-short markers from the default-stack trial. It did not remove
any of the six MET2 shorts, two MET2 spacing violations, six MET3 shorts, or
the remaining VIA2 cut-spacing violation. The same routed `CTS_20`, `CTS_26`,
FE_OFN, and output-FIFO nets still appear in the collision messages. Via cut
multiplicity was therefore a secondary defect; inserting the stack into an
already clocked and routed design is the controlling defect.

No coordinate sweep or `patch-stack` trial is authorized from this result.
Step 12 instead creates one fresh full-flow candidate from the accepted Genus
inputs. Its opt-in order is:

```text
place -> explicit PG sroute -> bounded 1x1 MET1-to-METTP stacks
      -> zero-special-connectivity and zero-DRC pre-CTS gates
      -> CTS -> filler -> ordinary MET1-MET3 route -> final gates
```

The default OOC order remains unchanged unless
`SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS=1`. The candidate uses the same
three measured row windows and fails closed before CTS if either pre-CTS gate
is nonzero. A completed run is classified separately as clean for PVS
preflight review, PG-closed with only the known MET1 minimum-area blocker, or
rejected. Step 12 does not run immutable PVS staging or PVS automatically.

```text
STEP12_LOCAL_TOP_PNR_TESTS=80_PASS_0_FAIL
STEP12_PY_COMPILE=PASS
STEP12_BASH_SYNTAX=PASS
STEP12_TCL_INFO_COMPLETE=1
```

The full OOC wrapper also connects Innovus stdin to `/dev/null`. Any fail-closed
pre-CTS Tcl error therefore receives EOF and cannot consume the operator's
subsequent interactive shell commands.

### P03-R13 Server Evidence - Pre-CTS Dangling-Only Classification

Status: `PASS_DIAGNOSTIC_CLASSIFIED_PHYSICAL_CANDIDATE_REJECTED_PRE_CTS`

Step 12 at report-driver head
`cfb9898f1e534f069b8108773af0e73b5c66d635` proved that the three bounded
1x1 stacks are geometrically legal before CTS:

```text
direct-via commands:             5 PASS / 0 FAIL
pre-CTS DRC:                     0
pre-CTS special connectivity:  156
connectivity class:             IMPVFC-94 dangling wire only
```

The candidate stopped before CTS by design because Step 12 required strict
zero special connectivity. The count is structured rather than arbitrary:
the probe established 39 VDD plus 39 VSS MET1 row wires, and
`156 = 2 * (39 + 39)`, matching two unfinished endpoints per row before
filler insertion. No `IMPVFC-96`, `IMPVFC-200`, or DRC class was reported at
this milestone.

Step 13 keeps Step 12 immutable and introduces a separate opt-in candidate.
Before CTS it accepts only the exact tuple `156 IMPVFC-94`, zero other
connectivity classes, and zero DRC. After CTS and filler it reruns only
`sroute -connect {corePin}` and then requires strict zero special connectivity
and zero DRC before ordinary routing. Any changed count, different IMPVFC
class, failed command, remaining post-filler open, or new DRC marker aborts
before signal routing. The step still performs no automatic immutable staging
or PVS.

### P03-R14 Server Evidence - Post-Filler Restitch Rejection

Status: `PASS_DIAGNOSTIC_CLASSIFIED_PHYSICAL_CANDIDATE_REJECTED`

Step 13 at report-driver head
`e17128ab5f2b007a8eeaee5f06e6fb054d5fd7a3` accepted the exact pre-CTS
milestone and reached the intended post-filler gate:

```text
pre-CTS direct-via commands:       5 PASS / 0 FAIL
pre-CTS special connectivity:    156 IMPVFC-94 only
pre-CTS DRC:                       0
post-filler corePin sroute:        PASS
post-filler special connectivity: 0
post-filler DRC:                 165
```

The second core-pin `sroute` is electrically effective, but the resulting
physical state is rejected. The run stopped before ordinary signal routing,
timing, and export, so the missing LEF/GDS/DEF/netlist and canonical-gate
errors are consequences of the post-filler DRC abort, not additional root
causes. No candidate output was staged and PVS remained `NOT_RUN`.

The Step 13 reports do not show whether the 165 violations already existed
after CTS, appeared when fillers were inserted, or were created by the second
`sroute`. Step 14 resolves only that ambiguity. It restores this candidate's
immutable `03_cts` checkpoint in one fresh Innovus process, captures DRC plus
special/regular connectivity, inserts the exact reviewed filler list with
DRC-safe filler mode, and captures the same evidence before any PG restitch.
It dumps filtered marker TSVs at both stages and performs no `sroute`, save,
export, immutable staging, or PVS.

Step 14 classifications are fail-closed:

- post-CTS DRC nonzero: attribute the first defect to CTS;
- post-CTS clean and post-filler DRC nonzero: attribute it to filler insertion;
- both stages DRC-clean: attribute the Step 13 count of 165 to post-filler
  `sroute`;
- pre-restitch connectivity zero: the second `sroute` was redundant;
- pre-restitch special connectivity nonzero: the second `sroute` was
  electrically necessary but needs a bounded DRC-safe replacement.

No new full-flow candidate is authorized until the Step 14 classification is
reviewed.

```text
STEP14_LOCAL_TOP_PNR_TESTS=86_PASS_0_FAIL
STEP14_PY_COMPILE=PASS
STEP14_BASH_SYNTAX=PASS
STEP14_TCL_INFO_COMPLETE=1
STEP14_DIFF_CHECK=PASS
```

### P03-R15 Server Evidence - CTS VIA1 Capture And Filler PG Closure

Status: `PASS_DIAGNOSTIC_CLASSIFIED_PHYSICAL_CANDIDATE_REMAINS_REJECTED`

Step 14 at report-driver head
`2e03ac5bf082baccfaf309b4886e1b26a36908bc` restored the immutable post-CTS
checkpoint and produced this reviewed tuple before any second `sroute`:

```text
post-CTS DRC capture:                 1000 VIA1 markers
post-CTS special connectivity:        154
post-CTS regular connectivity:        239
post-filler/pre-restitch DRC capture: 1000 VIA1 markers
post-filler/pre-restitch special:        0
post-filler/pre-restitch regular:      239
filler marker signatures added:          0
filler marker signatures removed:        0
```

Exactly 1000 violations were both reported and dumped at each stage. That is
proof of at least 1000 post-CTS VIA1 violations, but it is not proof that the
complete total is exactly 1000; capture completeness remains unproven at this
round number. The two marker hashes differ because runtime marker handles can
change, while the analyzer's geometry/layer/type/subtype/message signature
multisets are identical. Filler insertion did not create this DRC class.

The filler command closed special connectivity `154 -> 0` without any
post-filler `sroute`. The second Step 13 `sroute` is therefore not electrically
required for special connectivity. The 239 regular-connectivity findings are
from the post-CTS, pre-signal-route milestone and are not a final regular
connectivity gate. Step 13's later count of 165 cannot be subtracted directly
from the capped pre-restitch capture because the exact pre-restitch total is
unknown and the geometry state changed.

Step 15 is text-only. It classifies all captured VIA1 subtypes, normalized rule
templates, named nets, spatial extent, and the Step 13 layer summary. It runs
no Innovus process and performs no design modification, save, export, staging,
or PVS. No new candidate is authorized until its representative marker table
identifies the actual VIA1 rule and the responsible CTS via-generation
mechanism.

```text
STEP15_LOCAL_TOP_PNR_TESTS=89_PASS_0_FAIL
STEP15_PY_COMPILE=PASS
STEP15_BASH_SYNTAX=PASS
STEP15_DIFF_CHECK=PASS
```

### P03-R16 Server Evidence - Step 15 VIA1 Templates And Route-Through Decision

Status: `PASS_DIAGNOSTIC_CLASSIFIED_STEP16_FRESH_CANDIDATE_AUTHORIZED`

Step 15 completed at report-driver head
`641a8f0af895d74f134e675f0193d8ccc9763233` with no Innovus process and no
design modification. All 1000 captured markers belong to one rule class:

```text
layer/subtype:              VIA1/Cut_Enclosure
actual/required enclosure:  0.010 / 0.060 um above
single-regular-net form:    962
two-regular-net form:        38
unique regular nets:        403
special nets:                 0
```

The marker list is still a lower bound because both the report and TSV stop at
exactly 1000. Its spatial extent also ends near `x=178.490 um`, far short of
the full block width, so the capture must not be treated as a complete block
distribution.

The decisive correction is stage semantics. Checkpoint `03_cts.enc.dat` is
saved before filler insertion and before ordinary `routeDesign`. The 403 data,
control, and clock-related regular nets therefore identify incomplete
pre-signal-route geometry, not a final PG topology defect and not an
authoritative DRC result. Step 13's 165 MET1 violations were also measured
before ordinary routing, after a redundant second `sroute`; that gate cannot
be used as a final physical verdict either.

Step 16 is the shortest bounded full-flow candidate:

1. Recreate the proven three pre-CTS 1x1 VDD stacks in a fresh run root.
2. Accept only exact `156 IMPVFC-94`, zero other connectivity classes, and
   zero pre-CTS DRC.
3. Run CTS and the reviewed DRC-safe filler command.
4. Do not run the redundant post-filler `sroute` and do not run a pre-route
   DRC-zero gate.
5. Run canonical ordinary signal routing and all existing post-route cleanup,
   timing, final DRC, regular connectivity, PG connectivity, export, GDS-map,
   and canonical-gate checks.
6. Classify the fresh run and stop. Immutable staging and PVS remain separate
   operator-reviewed actions even if the candidate reaches
   `READY_FOR_PVS_PREFLIGHT`.

The analyzer now records the exact dangling policy independently from the
restitch switch. It fails closed unless the run manifest contains the reviewed
count, the pre-CTS milestone report proves the exact class, restitch is `0`,
and final artifacts exist after the accepted pre-CTS milestone.

```text
STEP16_LOCAL_TOP_PNR_TESTS=90_PASS_0_FAIL
STEP16_PY_COMPILE=PASS
STEP16_BASH_SYNTAX=PASS
STEP16_DIFF_CHECK=PASS
```

### P03-R17 Server Evidence - Step 16 Final Route Narrows Closure

Status: `PASS_CLASSIFIED_PHYSICAL_REPAIR_REQUIRED_PVS_BLOCKED`

Step 16 completed at report-driver head
`0a768d9d381cc771ffece6f6b4c3195e48af38be`. The fresh no-restitch candidate
passed the exact pre-CTS policy with 156 `IMPVFC-94` dangling observations,
zero other pre-CTS connectivity classes, and zero pre-CTS DRC. Ordinary
signal routing then completed without a second PG `sroute`.

The authoritative final gates are:

```text
regular connectivity:      PASS, 0 violations
PG connectivity:           PASS, 0 violations
post-route DRC:             FAIL, 6 MET1 minimum-area markers
other DRC marker classes:  0
antenna milestone:          177, deferred final-handoff blocker
setup WNS/TNS:             +0.131 ns / 0.000 ns
hold WNS/TNS:              +0.206 ns / 0.000 ns
GDS file/map/merge audit:  PASS/PASS/PASS
```

This proves that the capped pre-route VIA1 enclosure population was not an
authoritative final DRC class. It also closes the PG investigation: no further
PG-via coordinate, stack, or restitch experiment is justified by this run.
The six remaining minimum-area nets are `n_9706`, `n_9677`, `n_9721`,
`n_9697`, `n_9693`, and `n_9696`.

The canonical gate also found all 19 stream pins uniformly `-0.280 um` from
their contract centers. The checked-in plan generator records a separate
canonical target and generated `editPin` assignment, so Step 17 reuses the
existing failure analyzer to compare target, assignment, emitted LEF center,
and final marker/repair ledgers. It runs no Innovus process and performs no
design modification, save, export, immutable staging, or PVS. Another
candidate remains unauthorized until this read-only report proves the exact
pin-command mapping and captures the six-marker repair evidence.

```text
STEP17_LOCAL_TOP_PNR_TESTS=91_PASS_0_FAIL
STEP17_PY_COMPILE=PASS
STEP17_BASH_SYNTAX=PASS
STEP17_DIFF_CHECK=PASS
```

### P03-R18 Server Evidence - Step 17 Proves Two Bounded Corrections

Status: `PASS_CLASSIFIED_STEP18_ISOLATED_TRIAL_READY`

Step 17 completed at report-driver head
`278aa40b10edf61ad1a657efcbada7baaa6a676e` without launching Innovus or
modifying the candidate. Final regular and PG connectivity are both
zero-violation PASS results. The first selected-net minimum-area repair reduced
the authoritative final MET1 population from 10 markers to 6, all with the
same `0.1064 um^2` actual area against `0.2020 um^2` required area:

```text
n_9677 n_9693 n_9696 n_9697 n_9706 n_9721
```

The pin evidence is also conclusive. All 19 planned targets equal the
canonical contract, every generated assignment is exactly `-0.280 um` from
its target, and every emitted LEF center exactly equals that generated
assignment. The contract centers remain authoritative. The generator's
negative compensation is removed by setting it to zero; no placement-contract
CSV or historical report is rewritten.

Step 18 is not a full candidate rerun. It restores the Step 16 final routed
checkpoint once in one fresh Innovus process, applies at most three additional
iterations of the already observed selected-net repair sequence, and runs
independent DRC, regular-connectivity, and PG-connectivity gates after every
iteration. It stops on zero DRC, no improvement, any new marker class, an
antenna-count change from 177, or any connectivity regression. The trial is
in-memory only and runs no save, export, immutable staging, or PVS action.

```text
STEP18_LOCAL_TOP_PNR_TESTS=96_PASS_0_FAIL
STEP18_PY_COMPILE=PASS
STEP18_BASH_SYNTAX=PASS
STEP18_TCL_STRUCTURE_CHECK=PASS
STEP18_DIFF_CHECK=PASS
```

### P03-R19 Server Evidence - Step 18 Guard Failure And Step 19 R2

Status: `FAIL_SAFE_NO_REPAIR_COMMAND_R2_REQUIRED`

Step 18 ran at report-driver head
`9979fdf66290532731934f4b61cf4fca170dfa20` and stopped before opening the
repair loop. The restored physical baseline was the exact reviewed six-net
state: DRC 6, six filtered MET1 minimum-area markers, regular connectivity 0,
PG connectivity 0, and the same six nets from Step 17. No selection, delete,
or route command ran; `ITERATION_COUNT=0`, and save, export, immutable staging,
and PVS all remained `NOT_RUN`.

The rejected precondition compared two different marker representations. Step
17's authoritative final source-run antenna population remains 177. After
restoring `05_postroute_export.enc.dat`, the marker database contains 21
antenna entries, six DRC entries, and zero connectivity entries, for an exact
database total of 27. The restored 21 must not be relabelled as the source-run
final antenna count or used to clear the 177-marker handoff blocker.

Step 19 R2 keeps the Step 17 source-run proof at 177, requires the exact
restored tuple `6 + 21 + 0 = 27`, and then requires the restored antenna count
of 21 to remain unchanged after every in-memory repair iteration. It uses a
new immutable `_min_area_second_pass_trial_r2` root and refuses to run unless
the failed Step 18 reports prove `BASELINE_PRECONDITION_FAILED` with zero
iterations. The repair method itself is unchanged. Canonical replay and PVS
remain blocked pending the R2 classification.

```text
STEP19_R2_LOCAL_TOP_PNR_TESTS=98_PASS_0_FAIL
STEP19_R2_PY_COMPILE=PASS
STEP19_R2_BASH_SYNTAX=PASS
STEP19_R2_TCL_STRUCTURE_CHECK=PASS
STEP19_R2_DIFF_CHECK=PASS
```

### P03-R20 Server Evidence - Step 19 Rejects Selected-Net Reroute

Status: `PASS_CLASSIFIED_METHOD_REJECTED_STEP20_READ_ONLY_PROBE_READY`

Step 19 completed at report-driver head
`08477b2b3327f3ac22547be855cfaaa3e24187e7`. R2 accepted the corrected
restored-marker tuple and entered the repair loop. Every one of the 22 bounded
commands passed: selected-net mode, six net selections, six area deletes, six
DRC-wire deletes, `globalDetailRoute -select`, `detailRoute -select`, and
`ecoRoute -fix_drc`.

Independent verification after the first iteration was unchanged:

```text
DRC_COUNT_SEQUENCE=6 6
regular connectivity=0 -> 0
PG connectivity=0 -> 0
restored antenna entries=21 -> 21
marker database total=27 -> 27
```

The same six nets and same six `0.38 x 0.28 um` MET1 boxes were recreated.
Each remains `0.1064 um^2` against `0.2020 um^2` required. Command success is
therefore not repair progress; the selected-net delete/reroute sequence is
retired for this residual class. Iterations two and three correctly did not
run after the non-decreasing DRC count.

Step 20 is `min-area-geometry-probe`. It restores the same checkpoint once in
one fresh process and performs only schema, help, DB-query, and verification
captures. For each marker it records nearby regular wires and via instances,
connected instance terms, instance placement/orientation, master-local pin
shapes, and top terms.
It repeats DRC and both connectivity checks afterward and requires identical
marker signatures. Unsupported DB attributes remain explicit failed queries;
they are not interpreted as absent geometry.

The probe cannot edit, route, save, export, stage immutable PVS input, or run
PVS. Its purpose is to choose a reviewed direct geometry method and extension
direction; it does not authorize that method automatically.

```text
STEP20_LOCAL_TOP_PNR_TESTS=100_PASS_0_FAIL
STEP20_PY_COMPILE=PASS
STEP20_BASH_SYNTAX=PASS
STEP20_TCL_STRUCTURE_CHECK=PASS
STEP20_DIFF_CHECK=PASS
```

### P03-R21 Server Evidence - Step 20 Resolves The Landing Topology

Status: `PASS_CLASSIFIED_STEP21_ISOLATED_TRIAL_READY`

Step 20 completed at report-driver head
`94b62259a11d4b3c05aa38f37791c9366acae2fd`. The read-only probe preserved
the exact restored tuple before and after its queries: DRC 6, regular
connectivity 0, PG connectivity 0, restored antenna entries 21, and marker
database total 27. All six marker signatures stayed identical.

The local topology is now specific enough for one bounded trial. Every marker
is a `0.38 x 0.28 um` MET1 landing centered on an exact `VIA1_o`. A routed
MET2 segment terminates at that same center, and each net has exactly two
instance terms. The source `Q` instance is adjacent to the landing and gives
an unambiguous horizontal extension direction. The six reviewed extensions
are:

```text
n_9696  719.88,158.76  ->  719.32,158.76
n_9693  210.28,201.88  ->  209.72,201.88
n_9697  663.32,192.92  ->  662.76,192.92
n_9677 1666.28,201.88  -> 1666.84,201.88
n_9721 1792.84,212.52  -> 1792.28,212.52
n_9706 1827.00,212.52  -> 1827.56,212.52
```

Step 21, `min-area-landing-patch-trial`, restores the immutable checkpoint
once in a fresh Innovus process. Before the first edit it must reproduce all
six marker boxes, center `VIA1_o` points, width-`0.28 um` MET2 endpoints,
source `Q` names and points, source direction, and containment of both patch
endpoints inside the source instance box. It then uses Wire Editor to add one
regular MET1 segment per net, width `0.28 um` and length `0.56 um`, without
invoking a router.

The trial runs independent post-edit DRC, regular-connectivity, and
PG-connectivity checks and preserves restored-marker accounting. It classifies
both a coherent DRC-zero result and a coherent rejection, but never saves,
exports, stages immutable PVS inputs, launches a canonical rerun, or runs PVS.
Only `METHOD_STATUS=VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY` can justify later
integration into a fresh canonical replay.

```text
STEP21_LOCAL_TOP_PNR_TESTS=103_PASS_0_FAIL
STEP21_PY_COMPILE=PASS
STEP21_BASH_SYNTAX=PASS
STEP21_TCL_STRUCTURE_CHECK=PASS
STEP21_DIFF_CHECK=PASS
```

### P03-R22 Server Evidence - Step 21 Narrows The Patch Length

Status: `PASS_CLASSIFIED_STEP22_MIXED_LENGTH_TRIAL_READY`

Step 21 completed at report-driver head
`9c2c4fb96e1844ac261e94306ca1c72530ea6935`. All six reviewed contracts and
all 24 Wire Editor commands passed. Independent verification preserved regular
and PG connectivity at zero and the restored antenna sentinel at 21. DRC
improved from six markers to four, while marker-database accounting changed
from 27 to 25.

The `0.56 um` extensions closed `n_9706` and `n_9721`. The four surviving
markers on `n_9677`, `n_9693`, `n_9696`, and `n_9697` all changed from
`0.1064 um^2` to `0.1777 um^2`, leaving `0.0243 um^2` below the
`0.2020 um^2` rule. This proves that the direct connected-wire method changes
the intended geometry, but the uniform length is not sufficient for all six
local contexts.

Step 22, `min-area-landing-patch-trial-r2`, starts from the immutable routed
checkpoint again. It does not continue from Step 21's in-memory database. The
two already closed nets retain total length `0.56 um`; only the four survivors
receive total length `0.84 um`, one additional `0.28 um` increment:

```text
n_9696  719.88,158.76  ->  719.04,158.76  length 0.84
n_9693  210.28,201.88  ->  209.44,201.88  length 0.84
n_9697  663.32,192.92  ->  662.48,192.92  length 0.84
n_9677 1666.28,201.88  -> 1667.12,201.88  length 0.84
n_9721 1792.84,212.52  -> 1792.28,212.52  length 0.56
n_9706 1827.00,212.52  -> 1827.56,212.52  length 0.56
```

All endpoints remain inside the reviewed source-instance boxes. Step 22 must
revalidate the original six-marker checkpoint tuple and every local contract
before editing. It remains in-memory only and stops after DRC, regular
connectivity, PG connectivity, restored-antenna, and marker-database evidence.
Canonical replay, save, export, immutable PVS staging, and PVS remain blocked.

```text
STEP22_LOCAL_TOP_PNR_TESTS=108_PASS_0_FAIL
STEP22_PY_COMPILE=PASS
STEP22_BASH_SYNTAX=PASS
STEP22_TCL_STRUCTURE_CHECK=PASS
STEP22_DIFF_CHECK=PASS
```

### P03-R23 Server Evidence - Step 22 Proves Same-Direction Length Saturation

Status: `PASS_CLASSIFIED_STEP23_MIXED_DIRECTION_TRIAL_READY`

Step 22 completed at report-driver head
`fd0670189c7cca1bac496fb35c5ce8f71f9033d7`. All six mixed-length contracts
and all 24 Wire Editor commands passed, but authoritative DRC remained at four.
Regular and PG connectivity stayed zero, the restored antenna sentinel stayed
21, and marker-database accounting stayed 25.

The decisive result is geometric, not only numerical. After removing volatile
marker indices and handles, the four Step 22 marker signatures are identical
to Step 21: the same boxes, classes, nets, messages, and `0.1777 um^2` actual
areas. Moving each requested endpoint another `0.28 um` toward its source pin
therefore added no counted regular-wire geometry. This is consistent with the
source-pin boundary absorbing or clipping the extra Wire Editor length, but
Step 20 did not directly capture the complete pin shape. The exact mechanism
remains inferred; the measured same-direction saturation is sufficient to
retire further length scaling in that direction.

Step 23, `min-area-landing-patch-trial-r3`, restores the original immutable
checkpoint again. It first requires the full Step 22 rejection tuple and a
normalized SHA-256 equality check between the Step 21 and Step 22 post-trial
marker signatures. It then keeps the two proven patches and reverses only the
four saturated patches onto the opposite side of each VIA1 landing:

```text
n_9696  719.88,158.76  ->  720.72,158.76  away from source, 0.84 um
n_9693  210.28,201.88  ->  211.12,201.88  away from source, 0.84 um
n_9697  663.32,192.92  ->  664.16,192.92  away from source, 0.84 um
n_9677 1666.28,201.88  -> 1665.44,201.88  away from source, 0.84 um
n_9721 1792.84,212.52  -> 1792.28,212.52  toward source, retained
n_9706 1827.00,212.52  -> 1827.56,212.52  toward source, retained
```

Every segment remains `0.28 um` wide. The four reversed segments preserve the
reviewed `0.84 um` total length so that direction is the only changed repair
variable; the two already-closing segments remain `0.56 um`. Every segment
starts at the exact reviewed `VIA1_o` center and remains inside the reviewed
source-instance box. The trial is in-memory only and stops after DRC, regular
connectivity, PG connectivity, restored-antenna, and marker-database evidence.
Save, export, canonical replay, immutable PVS staging, and PVS remain blocked.

```text
STEP23_LOCAL_TOP_PNR_TESTS=113_PASS_0_FAIL
STEP23_PY_COMPILE=PASS
STEP23_BASH_SYNTAX=PASS
STEP23_TCL_STRUCTURE_CHECK=PASS
STEP23_DIFF_CHECK=PASS
```

### P03-R24 Server Evidence - Step 23 Retires The Opposite Direction

Status: `PASS_CLASSIFIED_STEP24_MIXED_WIDTH_TRIAL_READY`

Step 23 completed at report-driver head
`68af46725451ed2181bbafdb6567ec96158925eb`. All six mixed-direction
contracts and all 24 Wire Editor commands passed. Authoritative DRC again
changed from six markers to four, regular and PG connectivity remained zero,
the restored antenna sentinel remained 21, and marker-database accounting
changed from 27 to 25.

The four `0.84 um` segments directed away from their source terms had no
effect on the target landings. Their post-trial markers are the original
`0.1064 um^2` signatures at the original boxes, not the `0.1777 um^2`
signatures produced by a `0.56 um` toward-source segment. Only the retained
toward-source patches on `n_9706` and `n_9721` closed. Length and direction
are therefore both exhausted for the other four nets.

Step 24, `min-area-landing-patch-trial-r4`, restores the original immutable
checkpoint once more and changes width only. It replays the useful
`0.56 um` toward-source endpoints on all six nets. The four survivors use
width `0.56 um`; the two already-closing controls retain width `0.28 um`:

```text
n_9696  719.88,158.76  ->  719.32,158.76  width 0.56
n_9693  210.28,201.88  ->  209.72,201.88  width 0.56
n_9697  663.32,192.92  ->  662.76,192.92  width 0.56
n_9677 1666.28,201.88  -> 1666.84,201.88  width 0.56
n_9721 1792.84,212.52  -> 1792.28,212.52  width 0.28
n_9706 1827.00,212.52  -> 1827.56,212.52  width 0.28
```

For each survivor, the reviewed source-Q point is offset by `0.26 um` in Y
from the VIA1 center. Width `0.28 um` reaches only `0.14 um` from the route
centerline, whereas width `0.56 um` reaches `0.28 um`. The wider replay is
therefore a geometry-driven connectivity-to-pin experiment, not another
arbitrary area increment. Before editing, the Tcl contract validates all four
strip-edge corners against the source-instance box. The driver also requires
the four Step 23 post-trial signatures to equal the corresponding four
original pre-trial signatures.

Step 24 remains in-memory only. Save, export, canonical replay, immutable PVS
staging, and PVS remain blocked regardless of whether the trial classifies a
validated closure or a coherent rejection.

```text
STEP24_LOCAL_TOP_PNR_TESTS=116_PASS_0_FAIL
STEP24_PY_COMPILE=PASS
STEP24_BASH_SYNTAX=PASS
STEP24_TCL_STRUCTURE_CHECK=PASS
STEP24_DIFF_CHECK=PASS
```

### P03-R25 Server Evidence - Step 24 Retires Width As An Outcome Variable

Status: `PASS_CLASSIFIED_STEP25_MATERIALIZATION_PROBE_READY`

Step 24 completed at report-driver head
`88f3e8d3720c4495666057559709fa1ef0a9e32a`. All six mixed-width contracts
and all 24 Wire Editor commands passed. The physical result nevertheless
remained rejected:

```text
TRIAL_PROCESS_RESULT=MIXED_WIDTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
METHOD_STATUS=REJECTED_OR_INCOMPLETE
DRC=6 -> 4
REGULAR_CONNECTIVITY=0 -> 0
SPECIAL_CONNECTIVITY=0 -> 0
RESTORED_ANTENNA=21 -> 21
MARKER_DATABASE_TOTAL=27 -> 25
```

The four `0.56 um` width requests did not change the authoritative marker
outcome. `n_9677`, `n_9693`, `n_9696`, and `n_9697` again ended at the same
four `0.1777 um^2` boxes produced by Step 21's `0.28 um` replay. The complete
normalized Step 21 and Step 24 post-marker signatures are identical after
volatile indices and handles are excluded. Command success therefore does not
establish that a `0.56 um` regular MET1 wire was materialized in the database.

Step 25, `min-area-landing-materialization-probe`, resolves that ambiguity in
one fresh process. It restores the immutable source checkpoint, replays the
exact R4 commands, and captures every wire on the six nets immediately before
and after editing. Each row records handle, box, layer, width, length, points,
route status, shape, and its local relation to the target marker. The analyzer
compares semantic signatures separately from volatile handles and classifies
one of four outcomes:

```text
REQUESTED_0P56_WIDTH_MATERIALIZED
WIDE_REQUEST_CANONICALIZED_TO_0P28
NO_LOCAL_MET1_WIRE_DELTA
MIXED_LOCAL_MET1_MATERIALIZATION
```

The probe is diagnostic only. It cannot save or export the design, launch a
canonical rerun, stage immutable PVS inputs, or run PVS. Another endpoint,
direction, or width sweep is blocked until this materialization evidence is
reviewed.

```text
STEP25_LOCAL_TOP_PNR_TESTS=121_PASS_0_FAIL
STEP25_PY_COMPILE=PASS
STEP25_BASH_SYNTAX=PASS
STEP25_TCL_STRUCTURE_CHECK=PASS
STEP25_DIFF_CHECK=PASS
```

### P03-R26 Server Evidence - Step 25 Resolves Wire Materialization

Status: `PASS_CLASSIFIED_STEP26_EXACT_TEXT_REVIEW_READY`

Step 25 completed at report-driver head
`d03eb3302e92d90d2a7df6c0700c5acb5942d777`. The fresh R5 process restored
the original checkpoint, reproduced the R4 command contract, and captured all
wire objects before and after the six edits. The physical result remained the
reviewed evidence-only tuple:

```text
TRIAL_PROCESS_RESULT=WIRE_MATERIALIZATION_REPLAY_CHANGED_NOT_CLOSED
METHOD_STATUS=DIAGNOSTIC_CAPTURE_COMPLETE
DRC=6 -> 4
REGULAR_CONNECTIVITY=0 -> 0
SPECIAL_CONNECTIVITY=0 -> 0
RESTORED_ANTENNA=21 -> 21
MARKER_DATABASE_TOTAL=27 -> 25
```

The analyzer's coarse `MIXED_LOCAL_MET1_MATERIALIZATION` label obscures a
strictly uniform raw result. Every net added exactly one local MET1 object with
the same attributes:

```text
route_status=fixed
shape=0x0
width=0.23 um
centerline_length=0.385 um
added_local_met1_signatures=6
removed_local_met1_signatures=0
```

This is independent of whether Wire Editor was asked for width `0.56 um` on
the four survivors or `0.28 um` on the two controls. Each edit also replaced
one local routed MET2 segment with two routed MET2 segments around the new
landing coordinate: six removed local MET2 signatures and twelve added local
MET2 signatures. The edit therefore spliced the MET2 endpoint and emitted a
canonical fixed MET1 stub; it did not materialize the requested width or
requested endpoint distance literally.

The strongest control is internal to the same run. `n_9706` and `n_9721`
closed with this canonical primitive, while `n_9677`, `n_9693`, `n_9696`, and
`n_9697` retained `0.1777/0.2020 um^2` markers with the same primitive. Patch
materialization cannot explain that split. The remaining discriminator must be
in the pre-existing connected landing component, VIA1 enclosure, or source-pin
geometry.

Step 26, `min-area-landing-materialization-review`, is text-only. It reruns the
independent R5 analyzer against the immutable Step 25 trial root, requires all
six canonical stubs and all six MET2 splits, and emits:

```text
MATERIALIZATION_STATUS=UNIFORM_FIXED_0P23_BY_0P385_MET1_WITH_MET2_SPLIT
WIRE_EDITOR_PARAMETER_CONTROL_STATUS=REQUESTED_WIDTH_AND_ENDPOINT_NORMALIZED
CLOSED_CONTROL_MATERIALIZATION_MATCH_STATUS=PASS_SAME_CANONICAL_STUB_CLASS_AS_SURVIVORS
PATCH_PARAMETER_SWEEP_DECISION=RETIRED_LENGTH_DIRECTION_AND_WIDTH
NEXT_METHOD_DECISION=COMPARE_CLOSED_CONTROL_AND_SURVIVOR_LANDING_COMPONENT_GEOMETRY
```

Step 26 does not launch Innovus. Save, export, canonical replay, immutable PVS
staging, and PVS remain blocked.

```text
STEP26_LOCAL_TOP_PNR_TESTS=122_PASS_0_FAIL
STEP26_PY_COMPILE=PASS
STEP26_BASH_SYNTAX=PASS
STEP26_TCL_STRUCTURE_CHECK=NOT_APPLICABLE_NO_TCL_CHANGE
STEP26_DIFF_CHECK=PASS
```

### P03-R27 Step 26 Result And Chained-Endpoint Closure Trial

Status: `STEP27_R6_READY_FOR_ONE_ISOLATED_SERVER_TRIAL`

Step 26 completed at report-driver head
`85a9a1b06bd8674fed8a0f57ee6122c772998950`. The read-only review proved the
same exact canonical materialization on all six nets: one fixed `0.23 um` wide,
`0.385 um` long MET1 stub and one split MET2 endpoint per edit. It also
confirmed that requested endpoint distance and width are normalized, so those
parameters are retired.

The four survivors are only `0.0243 um^2` below the `0.2020 um^2` requirement
after the first canonical stub. Step 27 therefore tests a different physical
operation: continue the connected component from the actual far endpoint of
that materialized stub. It first reproduces the six uniform width-`0.28 um`,
length-`0.56 um` requests and requires the exact intermediate tuple:

```text
BASE_DRC_VIOLATION_COUNT=4
BASE_MIN_AREA_NETS=n_9677 n_9693 n_9696 n_9697
BASE_MARKER_VALUE_STATUS=PASS
BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0
BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0
BASE_EXCLUDED_ANTENNA_MARKER_COUNT=21
BASE_MARKER_DATABASE_TOTAL=25
```

Only then does R6 query the fixed `0.23 x 0.385 um` MET1 objects and issue a
second requested width-`0.28 um`, length-`0.56 um` edit from each measured far
endpoint toward its source instance:

```text
n_9696  719.495 158.795 -> 718.935 158.795
n_9693  209.895 201.845 -> 209.335 201.845
n_9697  662.935 192.885 -> 662.375 192.885
n_9677 1666.665 201.845 -> 1667.225 201.845
```

The trial is accepted only for exact DRC zero, zero regular and special
connectivity violations, unchanged antenna count `21`, and marker-database
total `21`. Any other coherent result is classification evidence only. The
process remains in-memory and cannot save, export, launch canonical replay,
stage immutable PVS inputs, or run PVS.

```text
STEP27_LOCAL_TOP_PNR_TESTS=125_PASS_0_FAIL
STEP27_PY_COMPILE=PASS
STEP27_BASH_SYNTAX=PASS
STEP27_TCL_INFO_COMPLETE=PASS
STEP27_DIFF_CHECK=PASS
```

### P03-R28 Step 27 Rejection And Normalized-VIA-Side Trial

Status: `STEP28_R7_READY_FOR_ONE_ISOLATED_SERVER_TRIAL`

Step 27 completed at report-driver head
`94cccda4a1834691f9df80e1b71f6922cf6e225b`. The base stage reproduced the
known four-marker state exactly, and all four chained endpoint contracts and
commands passed. The source-side continuation was nevertheless rejected:

```text
TRIAL_PROCESS_RESULT=CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED
METHOD_STATUS=REJECTED_OR_INCOMPLETE
DRC=6 -> 4
REGULAR_CONNECTIVITY=0 -> 0
SPECIAL_CONNECTIVITY=0 -> 0
RESTORED_ANTENNA=21 -> 21
MARKER_DATABASE_TOTAL=27 -> 25
```

The post-chain wire snapshot explains the failure. On `n_9696`, `n_9693`,
and `n_9697`, the fixed MET1 centerline grew only from `0.385 um` to
`0.500 um`; the requested `0.56 um` second stage contributed only
`0.115 um` after normalization. On `n_9677`, the fixed MET1 object remained
`0.385 um` long. All four DRC markers remained exactly
`0.1777/0.2020 um^2`. Continuing from the source-side endpoint is therefore
retired.

Step 28 revision R7 starts from the measured normalized VIA-side endpoint of
the canonical fixed stub and extends away from the source:

```text
n_9696   719.880 158.795 ->  720.440 158.795
n_9693   210.280 201.845 ->  210.840 201.845
n_9697   663.320 192.885 ->  663.880 192.885
n_9677  1666.280 201.845 -> 1665.720 201.845
```

The gate requires both routed MET2 split segments to terminate at each exact
start point, verifies that the opposite endpoint is the measured source-side
endpoint, and checks that the edit direction is away from the source
instance. It also compares the local regular-MET1 signatures before and after
R7 and requires the two unedited controls, `n_9706` and `n_9721`, to remain
stable.

Only exact DRC zero, zero regular and special connectivity violations,
unchanged antenna count `21`, and marker-database total `21` validate the
method. Any nonzero tuple remains rejected evidence. Step 28 is in-memory
only; save, export, canonical replay, immutable PVS staging, and PVS remain
blocked.

```text
STEP28_LOCAL_TOP_PNR_TESTS=129_PASS_0_FAIL
STEP28_PY_COMPILE=PASS
STEP28_BASH_SYNTAX=PASS
STEP28_TCL_INFO_COMPLETE=PASS
STEP28_DIFF_CHECK=PASS
```

### P04 Provisional Four-Marker Waiver And Early PVS LVS

Status: `PHASE3_PROVISIONAL_LVS_MATCH_ACHIEVED_DRC_DEBT_OPEN`

The operator chose to defer the Step 28 normalized-VIA-side repair trial and
obtain an early LVS diagnosis. This is recorded as
`STEP28_NORMALIZED_VIA_SIDE_TRIAL=SKIPPED_BY_OPERATOR_TEMPORARY_WAIVER_DECISION`;
it is not a rejection of R7.

Phase 3 restores the original packet-core checkpoint in a fresh process,
replays only the six validated base edits, and requires the exact known
four-marker state before saving or exporting. The temporary waiver is limited
to the four named MET1 minimum-area markers on `n_9677`, `n_9693`, `n_9696`,
and `n_9697`. Connectivity must remain zero and the mapped/merged GDS audit
must pass.

PVS DRC and LVS are independent after immutable staging. PVS DRC is not
waived; an explicit nonzero PVS result is retained as DRC debt while LVS may
still run. LVS passes only on report-level `MATCH`. Even a PVS DRC zero plus
LVS `MATCH` remains provisional until the four Innovus markers are fixed, a
new package is exported, base and density DRC are zero, LVS is rerun, and the
waiver is retired.

The complete contract, marker inventory, result matrix, server gates, and
manual closure checklist are in
`38_TX_PACKET_CORE_PROVISIONAL_DRC_WAIVER_AND_PVS_LVS_EXECUTION.md`.

### P04-R01 First Waiver Export Control Failure

The first Phase 3 export run
`innovus_tx_packet_min_area_waiver_export_20260716_123932` failed before
creating any staged artifacts. Innovus restored the source checkpoint, but a
double-quoted Tcl regex executed `[[:space:]]` as command substitution and
raised `invalid command name ":space:"`. Because the script stopped before
its final status write, the wrapper observed Innovus RC `0`, missing status,
missing GDS, and `GDS_AUDIT_RC=NOT_RUN`.

This is classified as a control-script failure only. No DRC, LVS, or export
conclusion was drawn. The parser now uses braced numeric extraction, writes
phase checkpoints, catches marker-classification errors, and returns a
nonzero driver status on failed gates. The failed immutable run is retained;
the corrected flow requires a new Phase 3 session.

### P04-R02 First PVS DRC Reference-Scanner Failure

Phase 3 session `tx_packet_pvs_waiver_20260716_124911` passed waiver export,
GDS audit, immutable staging, source preparation, `156/156` pin parity, and
resolution of all `97` referenced masters through the package-local official
JIHD CDL. Its first base-DRC replay passed the strict path/top contract but
stopped before PVS execution.

The external-reference scanner interpreted a PVS rule-deck comment separator
as path `//===`, emitted `MISSING=//===`, and correctly blocked execution.
There is no DRC result from this attempt. The scanner now removes PVS/C line
and block comments before path extraction and has an exact separator
regression. The failed run is retained, and the corrected flow requires a
fresh Phase 3 session and run identifier.

### P04-R03 PVS Returned Zero Without Run-Local DRC Evidence

Fresh Phase 3 session `tx_packet_pvs_waiver_20260716_130442` passed export,
GDS audit, staging, source/CDL preparation, and corrected external-reference
validation. PVS executed and returned zero, but the parser found no immutable
run-local summary:

```text
PVS_RC=0
PVS_DRC_STATUS=UNKNOWN
EVIDENCE=NONE
PARSE_RC=8
```

The reference inventory showed that the `_HV` GUI template still named the
historical sibling `layoutverification/pvs_drc/spadmic_tx_packet_core`
directory for execution artifacts. Inputs had been patched, but absolute
working-directory, control, cell-tree, and output paths were not yet required
to be package-local. The zero return code is therefore not attributable DRC
evidence and cannot be promoted to zero or nonzero classification.

Replay now discovers and relocates the actual GUI execution root, copies an
external cell tree when required, and forces all DRC/LVS reports and databases
under the immutable run directory. `output_isolation.rpt` proves the rewritten
paths. The result parser writes a scanned-file inventory, rejects conflicting
totals, and the Phase 3 driver requires underlying PVS tool RC zero before
accepting a report-level nonzero count as DRC debt.

The `130442` failed PVS directory remains immutable negative evidence. Since
the exported package itself passed all staging/hash gates, an urgent
replay-only retry may reuse that exact package with the corrected commit, a
new PVS run ID, and a fresh wrapper audit. It must not overwrite the old run
or claim a complete Phase 3 status chain. A formal driver-owned summary still
requires a fresh session. Either path must obtain a unique run-local
`Total DRC Results` line before classifying base DRC.

### P04-R04 PVS Base DRC Classified Nonzero

The replay-only retry at commit `13cc2e14` reused the unchanged, audited
`tx_packet_pvs_waiver_20260716_130442` package and wrote only to new immutable
run `tx_packet_pvs_waiver_20260716_130442_pvs_drc_base_outputiso_13cc2e14`.
Replay and output isolation passed, PVS returned zero, and three run-local
artifacts agreed on:

```text
Total DRC Results : 135 (135)
PVS_DRC_STATUS=FAIL
```

This is now a design DRC verdict rather than a replay-control failure. The
`135` foundry-rule results are not waived, base DRC is not clean, density DRC
is not run, and the block remains ineligible for promotion. The classified
nonzero result does permit the independent diagnostic LVS.

Before that LVS, replay validation found that the historical `_HV`
`pvslvsctl` had a Verilog `schematic_path` but no executable standard-cell
CDL input. The GUI preset's OA-generated CDL field was not sufficient.
Replay now forces the canonical GDS and filtered Verilog inputs, inserts the
package-local official JIHD CDL when absent, rejects duplicate source/CDL
directives, and records the executable-input actions in
`output_isolation.rpt`.

### P04-R05 Provisional PVS LVS Explicit Match

Commit `5bcaaf7d` reused the unchanged audited `130442` package and created
new immutable LVS run
`tx_packet_pvs_waiver_20260716_130442_pvs_lvs_execinputs_5bcaaf7d`.
The replay replaced the historical executable Verilog input, added the
previously missing executable package-local JIHD CDL, relocated every output,
and passed both the strict replay and output-isolation contracts.

PVS and the conservative parser both passed:

```text
PVS_RC=0
PARSE_RC=0
PVS_LVS_STATUS=MATCH
LVS_NEGATIVE_MATCH_COUNT=0
LVS_POSITIVE_MATCH_COUNT=3
EVIDENCE=svdb/matched
```

The positive result is independently visible in `pvs.stdout.log`, the
comparison `.cls`, and `svdb/matched`. All 55 eligible run-local text
artifacts were scanned and none contained a negative match pattern. The
compared GDS, source, and JIHD CDL hashes are recorded in Section 16 of
`38_TX_PACKET_CORE_PROVISIONAL_DRC_WAIVER_AND_PVS_LVS_EXECUTION.md`.

This achieves the early LVS objective. It does not change the nonzero base
DRC result:

```text
PVS_BASE_DRC_RESULTS=135
INNOVUS_TEMPORARY_MET1_MIN_AREA_MARKERS=4
PVS_DENSITY_DRC=NOT_RUN
FINAL_SIGNOFF_READY=NO
```

The block must still receive manual DRC repair, a new mapped/merged export,
base and density PVS DRC zero, and a new LVS match on the repaired GDS.

GUI inspection is permitted only through
`TOP/pnr/scripts/open_pvs_lvs_gui_review.sh`. The helper validates the match
and opens a disposable relocated copy so Cadence lock or browser state cannot
modify the immutable evidence.

### P04-R06 Base PVS DRC Non-Antenna Analysis Prepared

After the explicit provisional LVS match, the next open packet-core gate is
the classified base PVS DRC debt:

```text
PVS_BASE_DRC_RESULTS=135
PVS_DRC_STATUS=FAIL
PVS_DENSITY_DRC=NOT_RUN
```

`TOP/pnr/scripts/analyze_pvs_drc_run.py` now provides a read-only decomposition
of the existing immutable DRC run. It validates the replay and output
isolation, reconciles the per-rule totals with `135 (135)`, parses every ASCII
result polygon into micron coordinates, and writes all analysis outside the
source run.

The initial antenna split was deliberately literal: only explicit antenna
wording in the rule name or foundry description was excluded, while ambiguous
rules remained in the non-antenna repair inventory. The executed control's
`DENSITY` and `VAR_ANT_RATIO` states were recorded separately. Server evidence
in P04-R07 later proved that this first semantic policy was incomplete for
foundry descriptions that encode the antenna mechanism without using the word
`antenna`.

The analysis also correlates PVS geometry against the four Innovus
temporary-waiver boxes and emits spatial bins for repeated hotspots. The
actual rule distribution remains pending the one server-side read-only
extraction. No PVS rerun, GDS edit, waiver expansion, signoff claim, or block
promotion is authorized by this preparation step.

See
`39_TX_PACKET_CORE_PVS_BASE_DRC_NON_ANTENNA_ANALYSIS.md` for the exact evidence
contract and manual repair sequence.

### P04-R07 PVS Base DRC Semantic Correction

The read-only extraction at commit `44f7ec51` reconciled all `1277` rulechecks,
the exact `135 (135)` total, and every ASCII result geometry. It found only:

```text
R2M3P1=93
R1M3P1=42
```

Both executed foundry descriptions are:

```text
Maximum ratio of MET3 area to connected GATE area ... 400
```

The first analyzer classified them as generic `AREA` because the description
does not contain the literal word `antenna`. That semantic result and its
recommendation to increase connected polygon area are rejected. The counts,
hashes, geometries, bins, and zero Innovus-box overlap remain valid negative
evidence and the original output directory must not be overwritten.

Metal area divided by connected gate area is the antenna-ratio mechanism.
The corrected tuple is:

```text
ANTENNA_RULE_COUNT=2
ANTENNA_PRIMARY_RESULT_COUNT=135
NON_ANTENNA_RULE_COUNT=0
NON_ANTENNA_PRIMARY_RESULT_COUNT=0
VAR_ANT_RATIO_STATE=UNDEFINED
VAR_ANT_RATIO_SCOPE=ADDITIONAL_OPTIONAL_RULE_FAMILY_ONLY
DENSITY_STATE=UNDEFINED
```

The optional `VAR_ANT_RATIO` family being disabled does not disable the fixed
`R1M3P1` and `R2M3P1` checks. The four known Innovus MET1 minimum-area boxes
had zero PVS-result overlap at `0.35 um`, so the physical debt is now separated:

```text
INNOVUS_MET1_MIN_AREA_DEBT=4
PVS_BASE_ANTENNA_DEBT=135
PVS_BASE_NON_ANTENNA_DEBT=0
PVS_DENSITY_DRC=NOT_RUN
PVS_LVS_STATUS=MATCH
FINAL_SIGNOFF_READY=NO
```

This removes the proposed non-antenna PVS repair campaign. It does not make
base DRC pass: antenna remains open for final closure, the four Innovus
minimum-area markers still require manual repair, density is unrun, and any
new GDS requires a fresh explicit LVS match.

### P04-R08 Corrected PVS Rule Classification Confirmed

The corrected analyzer at commit
`03a430d75fcff3f301440c550c40096ffb3ea775` was executed against the unchanged
immutable base-DRC run. It wrote only to:

```text
/sim/ksabra/SPADMIC_work/diagnostics/
tx_packet_pvs_waiver_20260716_130442/drc_analysis/
base_rule_classification_03a430d7_20260716_130727
```

The correction passed every evidence gate:

```text
STATUS=PASS
RESULT=PVS_DRC_RULE_DEBT_CLASSIFIED
SOURCE_RUN_MUTATION_AUTHORIZED=NO
OUTPUT_LOCATION_STATUS=OUTSIDE_IMMUTABLE_SOURCE_RUN
RESULT_COUNT_RECONCILIATION=PASS
ASCII_ERROR_GEOMETRY_RECONCILIATION=PASS
ANTENNA_RULE_COUNT=2
ANTENNA_PRIMARY_RESULT_COUNT=135
NON_ANTENNA_RULE_COUNT=0
NON_ANTENNA_PRIMARY_RESULT_COUNT=0
PVS_RESULTS_OVERLAPPING_WAIVER_BOXES=0
```

The raw foundry records add these exact qualifiers:

```text
R1M3P1=42  "(gate output)"
R2M3P1=93  "(met3 output)"
```

Both retain the same controlling description:

```text
Maximum ratio of MET3 area to connected GATE area ... 400
```

Therefore all 135 PVS base results are process-antenna ratio violations. There
is no residual non-antenna PVS base-rule class. The qualifiers are preserved
as raw evidence and must not be expanded into an unsupported explanation of
the foundry's internal `R1` versus `R2` derivation without the licensed rule
manual or result browser.

The current packet-core state is:

```text
PVS_LVS_STATUS=MATCH
PVS_BASE_DRC_STATUS=FAIL
PVS_BASE_ANTENNA_RESULTS=135
PVS_BASE_NON_ANTENNA_RESULTS=0
INNOVUS_MET1_MIN_AREA_RESULTS=4
INNOVUS_REGULAR_CONNECTIVITY_RESULTS=0
INNOVUS_SPECIAL_CONNECTIVITY_RESULTS=0
PVS_DENSITY_DRC_STATUS=NOT_RUN
FINAL_SIGNOFF_READY=NO
BLOCK_PROMOTION_AUTHORIZED=NO
```

This state is electrically coherent but physically incomplete. LVS and
antenna answer different questions: an electrically correct net can still
accumulate excessive manufacturing charge. The four Innovus minimum-area
markers are also separate geometric debt and were not reproduced among the
135 PVS antenna-result boxes.

### P04-R09 Virtuoso Import Artifact Selected

The exact immutable package GDS used by the explicit PVS LVS `MATCH` is now
the selected Virtuoso import baseline:

```text
PACKAGE=
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/
spadmic_tx_packet_core/tx_packet_pvs_waiver_20260716_130442

GDS=
package/gds/spadmic_tx_packet_core.gds

LAYOUT_TOP=spadmic_tx_packet_core
GDS_BYTES=16103546
GDS_SHA256=
48bbf0294f49e2f2201a2e86db71547ead33a9d426e43488df940d0c9e8b242e
```

No new Innovus export is authorized before import. The selected GDS already
passed the official stream-map and JIHD-merge audit and is the exact layout
input bound to:

```text
PVS_LVS_STATUS=MATCH
```

A fresh export would create a new physical hash without a matching PVS
comparison. The first Virtuoso import must therefore use the immutable package
GDS directly, or a byte-identical copy whose SHA256 is rechecked.

The destination must be a new empty OA library attached to the active project
XH018 technology. XStream In must use the recorded project layer table and
object map, preserve case and labels, convert pins as geometry and text, and
select top `spadmic_tx_packet_core`. The imported top must then prove:

```text
EXPECTED_SIZE_UM=2066.960000 366.800000
EXPECTED_TOP_TERMINAL_COUNT=156
ROUTING_LAYERS_VISIBLE=MET1_MET2_MET3_METTP
OA_BBOX_PARITY=PASS
OA_PIN_PARITY=PASS
```

The import is for review and manual physical repair, not promotion:

```text
PVS_BASE_ANTENNA_RESULTS=135
INNOVUS_MET1_MIN_AREA_RESULTS=4
PVS_DENSITY_DRC_STATUS=NOT_RUN
FINAL_SIGNOFF_READY=NO
```

Any OA edit creates a new physical state and invalidates transfer of the old
LVS verdict. The repaired state requires a new mapped streamout, base and
density PVS DRC, and a new explicit LVS `MATCH`.

The complete import paths, hashes, XStream settings, verification commands,
evidence locations, and post-import audit are documented in:

```text
TOP/docs/40_TX_PACKET_CORE_VIRTUOSO_IMPORT_HANDOFF.md
```

## P08 - Digital Subblock Portfolio and Reusable Closure Flow

Date: 2026-07-16.

Status:

```text
LOCAL_IMPLEMENTATION_STATUS=PASS
FLOORPLAN_PORTFOLIO_STATUS=PASS
POSITION_RTL_REGRESSION_STATUS=PASS
EVENT_RTL_REGRESSION_STATUS=PASS
POSITION_GENUS_STATUS=NOT_RUN
POSITION_INNOVUS_STATUS=NOT_RUN
POSITION_PVS_STATUS=NOT_RUN
EVENT_GENUS_STATUS=NOT_RUN
EVENT_INNOVUS_STATUS=NOT_RUN
EVENT_PVS_STATUS=NOT_RUN
```

This phase converts the TX-specific learning into a reusable sequence for the
remaining digital blocks. It does not alter the packet GDS, clear packet DRC
debt, or authorize `p00_tx` promotion.

### P08-R01 Portfolio and Floorplan Contract

The audited layout snapshot remains:

```text
TOP/docs/layout_audits/SPADMIC2_20260709_072331
```

The machine-readable portfolio and reservation contracts are:

```text
TOP/pnr/assembly/spadmic_digital_subblock_portfolio.csv
TOP/pnr/assembly/spadmic_digital_floorplan_regions.csv
TOP/pnr/assembly/spadmic_digital_assembly_phases.csv
```

The new validator proved:

```text
LABEL=SPADMIC_DIGITAL_SUBBLOCK_PORTFOLIO
STATUS=PASS
ERROR_COUNT=0
```

The next two hard reservations are fixed at:

```text
POSITION_CORE=528.305,20.000,1480.000,680.000
EVENT_COORDINATOR=1500.000,280.000,1737.460,500.000
```

The MPTDC phase is explicitly blocked:

```text
MPTDC_FRONTEND_STATUS=BLOCKED_ABSTRACT_MISSING
MPTDC_PROMOTION_POLICY=NO_PROMOTION_WHILE_BLOCKED
```

No placeholder MPTDC pin or geometry was created.

### P08-R02 Position Physical Boundary

`spadmic_position_core` was added as a transparent wrapper around
`spadmic_position_snapshot_packetizer`. The active matrix top now instantiates
the wrapper without changing the instance connections or behavior.

The physical boundary includes:

```text
TOP/rtl/spadmic_position_core.sv
TOP/syn/filelists/ooc/spadmic_position_core.f
TOP/syn/constraints/ooc/spadmic_position_core.sdc
```

The wrapper contains no `always_ff` or `always_comb` block. It exists to give
Genus, Innovus, LEF, GDS, and LVS one stable canonical top.

### P08-R03 TC Genus Gates

The event and position constraints now model:

```text
CLOCK_NAME=clk_sys
CLOCK_PERIOD_NS=6.25
INPUT_DELAY_NS=0.50
OUTPUT_DELAY_NS=0.50
INPUT_TRANSITION_NS=0.20
OUTPUT_LOAD_PF=0.02
```

`validate_genus_tc_ooc.py` fails closed on:

- wrong or duplicate top-module definition;
- nested/multidimensional top ports;
- unresolved references;
- missing clock waveform;
- missing external delays, transitions, or loads;
- nonzero warning classes;
- negative WNS, nonzero TNS, or violating setup paths;
- missing or empty output/report evidence.

The gate remains typical-only:

```text
MMMC_STATUS=NOT_RUN_TYPICAL_ONLY
SIGNOFF_READY=NO
```

### P08-R04 Innovus OOC Extensions

The common OOC generator and wrapper now support:

```text
position_core / spadmic_position_core
event_coordinator / spadmic_event_coordinator
```

The position plan uses:

```text
CORE_WIDTH_UM=931.695
CORE_HEIGHT_UM=640.000
SNAPSHOT_INPUT_SIDE=NORTH
PACKET_OUTPUT_SIDE=EAST
```

The event plan uses:

```text
CORE_WIDTH_UM=217.460
CORE_HEIGHT_UM=200.000
```

Both use:

```text
PG_ROUTE_STRATEGY=explicit_exact
ENABLE_PG_SROUTE=1
ROUTE_PROFILE=met1_effort
```

East-side pin placement is now conditional. Older three-side block
configurations remain valid because only configured sides are required to
pass.

### P08-R05 Hash-Bound PVS and Promotion Evidence

PVS base DRC, density DRC, and LVS status files now record:

```text
PACKAGE=<immutable-package>
GDS=<package-GDS>
GDS_SHA256=<exact-hash>
```

LVS additionally records the canonical package source path and source
SHA-256. The promotion gate re-hashes both the GDS and source before approval.

DRC status also records:

```text
PVS_DRC_VARIANT=BASE
PVS_DRC_VARIANT=DENSITY
```

The promotion gate now independently requires:

```text
HANDOFF_AUDIT_STATUS=PASS
CANONICAL_NAME_STATUS=PASS
BBOX_PARITY_STATUS=PASS
PIN_PARITY_STATUS=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
INTERNAL_PG_STATUS=PASS
TC_TIMING_STATUS=PASS
PVS_BASE_DRC_STATUS=PASS or FORMALLY_WAIVED
PVS_DENSITY_DRC_STATUS=PASS or FORMALLY_WAIVED
PVS_LVS_STATUS=MATCH
```

Every evidence file is hashed into the gate. Promotion rechecks those hashes
and the GDS hash before writing approval or moving `current`.

The formal waiver schema is exact-GDS and exact-rule scoped. Its canonical
JSON SHA-256 provides tamper evidence only:

```text
ATTESTATION_SECURITY=INTEGRITY_ONLY_NOT_CRYPTOGRAPHIC_IDENTITY
```

The external approval reference remains responsible for signer identity. The
existing TX four-marker diagnostic waiver is not eligible for this promotion
path.

### P08-R06 Negative Knowledge Preserved

The following failures are now explicit flow rules:

1. `addStripe` offsets are core-relative unless an explicit area changes the
   reference. The first strip run shifted both stripes by `10.080 um`.
2. `addStripe -area` and `-extend_to design_boundary` are mutually exclusive.
3. Top-level VDD/VSS terminals are not `blockPin` objects. The failed request
   produced `IMPSR-1254`.
4. Repeated `restoreDesign` in one process produced `IMPIMEX-7031`; candidate
   isolation requires one fresh process per candidate.
5. A command PASS or zero wrapper RC is not a physical PASS.
6. The helper-X sweep was physically invariant and is not a reusable repair
   strategy.
7. Post-route direct power-via stacks closed connectivity but created
   MET2/MET3 shorts. New blocks build PG before ordinary signal routing.
8. Raw `top.markers` totals mix DRC, antenna, and connectivity classes.
9. PVS output must be isolated and parsed; process RC zero alone can still be
   `UNKNOWN`.
10. DRC/LVS evidence cannot move between GDS hashes.
11. Missing MPTDC abstracts must block the phase rather than trigger invented
    interfaces.

### P08-R07 Local Verification

Local RTL evidence:

```text
tb_spadmic_position_snapshot_packetizer_unit=25 pass / 0 fail
tb_spadmic_event_coordinator_modes_unit=24 pass / 0 fail
```

The focused Python tests, Python compilation, shell syntax checks, generated
position/event plans, floorplan validation, and `git diff --check` passed
during implementation. Cadence server runs were deliberately not started from
the local checkout.

The complete execution order and server commands are recorded in:

```text
TOP/docs/41_DIGITAL_SUBBLOCK_CLOSURE_AND_ASSEMBLY_ROADMAP.md
```

### P08-R08 Exact Genus Boundary Gate

The final pre-commit review found a shared Verilog parser defect. In an ANSI
module header, a numeric packed range was inherited across a later explicit
direction keyword. For example:

```systemverilog
input logic [2:0] active_axis_mask_i,
input logic       matrix_activity_i
```

was incorrectly interpreted as if `matrix_activity_i` were also three bits.
The event coordinator appeared to have 118 scalar ports instead of the
correct 63 scalar bits across 30 base ports.

The parser now resets inherited range state whenever a new `input`, `output`,
or `inout` begins, while preserving legal inheritance within one declaration:

```systemverilog
input logic [1:0] first_i, second_i
```

The TC Genus gate now requires exact post-synthesis contracts:

```text
spadmic_position_core:
  EXPECTED_BASE_PORT_COUNT=20
  EXPECTED_BIT_PORT_COUNT=249

spadmic_event_coordinator:
  EXPECTED_BASE_PORT_COUNT=30
  EXPECTED_BIT_PORT_COUNT=63
```

Missing ports, extra ports, wrong directions, wrong widths, nested ports, or
multiple top definitions all force:

```text
BOUNDARY_PORT_STATUS=FAIL
RESULT=REVIEW_REQUIRED
```

Negative rule: never promote a netlist merely because a parser returned a
nonempty port list or a plausible total count. Exact names, directions, and
widths must agree with the block contract.

### P08-R09 Formal Waiver Cannot Replace DRC Execution

The formal waiver path is restricted to a completed, exact-GDS DRC result
whose parsed status is explicitly `FAIL`. A valid waiver manifest may convert
that gate to `FORMALLY_WAIVED`, but it cannot convert any of the following:

```text
PVS_DRC_STATUS=NOT_RUN
PVS_DRC_STATUS=UNKNOWN
missing DRC report
unattributed DRC report
```

This prevents administrative evidence from replacing physical verification.
The waiver also remains invalid when its GDS cannot be read, its payload hash
does not match, or its exact rule/result coverage is incomplete.

## P09 - Position Core Server Closure

### P09-R01 TC Genus Accepted

The first Position hard-macro server gate ran in the foreground on 2026-07-17
from exact repository state:

```text
BRANCH=SPADMIC_test
HEAD=67570818ac8e9cf38b44b4c8f91dca6f0a45673b
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
PORTFOLIO_STATUS=PASS
PORTFOLIO_ERROR_COUNT=0
EDA_RC=0
```

Run identity:

```text
POSITION_GENUS_RUN=genus_ooc_position_core_20260717_101642
POSITION_GENUS_ROOT=/sim/ksabra/SPADMIC_work/genus/genus_ooc_position_core_20260717_101642/position_core
POSITION_GENUS_RC=0
```

The exact TC and boundary tuple is:

```text
STATUS=PASS
TC_TIMING_STATUS=PASS
RESULT=READY_FOR_ISOLATED_INNOVUS_OOC
TOP_MODULE=spadmic_position_core
CLOCK_PERIOD_PS=6250.0
CLOCK_REGISTER_COUNT=2437
BOUNDARY_PORT_STATUS=PASS
EXPECTED_BASE_PORT_COUNT=20
ACTUAL_BASE_PORT_COUNT=20
EXPECTED_BIT_PORT_COUNT=249
ACTUAL_BIT_PORT_COUNT=249
UNRESOLVED_REFERENCE_COUNT=0
WNS_PS=14.0
TNS_PS=0.0
VIOLATING_PATH_COUNT=0
ERROR_COUNT=0
MMMC_STATUS=NOT_RUN_TYPICAL_ONLY
SIGNOFF_READY=NO
```

Artifact hashes:

```text
POSTSYN_NETLIST_SHA256=53bc725784e78fba8c2188f8ef9e31965abc84ffa02c195be1bf8e6e916518c6
POSTSYN_SDC_SHA256=69929a339cb2b2951bee4f7b2b6b558277e13bfac504951c57b38cf497d4f21f
```

Every timing-intent lint count was zero. The warning classifier reported zero
for design rules, inferred latches, missing external delays, missing clock
waveforms, tool errors, undriven objects, and unresolved references. The two
generic tool warnings were `MESG-11` maximum-message-print-count records; they
are retained as diagnostic context and are not a blocking class in this gate.

Classification:

```text
GENUS_MILESTONE=TYPICAL_CLOSED
INNOVUS_HANDOFF_STATUS=READY
MMMC_SIGNOFF_STATUS=NOT_RUN
FINAL_SIGNOFF_READY=NO
NEXT_GATE=POSITION_ISOLATED_INNOVUS_OOC
```

Negative rule: the positive `14 ps` WNS is deliberately not called MMMC
closure. Position still needs isolated Innovus placement/CTS/route, zero DRC,
zero regular and special connectivity debt, mapped/merged GDS audit, immutable
packaging, PVS base and density DRC, and explicit LVS `MATCH` before promotion.

### P09-R02 Clean Innovus Baseline Rejected by Top Bbox Review

The isolated Position Innovus run executed in the foreground on 2026-07-17
from exact repository state:

```text
BRANCH=SPADMIC_test
HEAD=64a1a29846f42b382aea4d1afbed8455963fbbec
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
POSITION_GENUS_RUN=genus_ooc_position_core_20260717_101642
POSITION_PNR_RUN=innovus_ooc_harden_position_core_20260717_111443
POSITION_PNR_RC=0
```

The accepted physical evidence inside the run is:

```text
RESULT=ABSTRACT_READY_FOR_TOP_REVIEW
INNOVUS_DRC_STATUS=PASS
DRC_MARKER_TOTAL=0
MET1_MIN_AREA_MARKER_COUNT=0
ANTENNA_MARKER_COUNT=0
OTHER_MARKER_COUNT=0
REGULAR_CONNECTIVITY_STATUS=PASS
PG_CONNECTIVITY_STATUS=PASS
POSTROUTE_SETUP_TIMING=PASS
POSTROUTE_HOLD_TIMING=PASS
WORST_REPORTED_SETUP_SLACK_PS=26
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
GDS_BYTES=11490808
GDS_SHA256=49a7a030f24752226b39ba7a4371ab62a1927c42bf7494ecc6abccf75f12eaac
ABSTRACT_LEF_SHA256=db1634f39f3bd74d367165543adf1d886aee5b62efdd46c37e8205599778faf7
ROUTED_PG_NETLIST_SHA256=d747840553b92ed974fc64e819735bbccfb188b13eb5e18ba49d7e5053fbc24f
```

Regular and VDD/VSS special connectivity each report zero violations and zero
warnings. `verify_drc` reports zero violations across all 12 subareas. The 50
reported setup paths are positive; the worst shown path has `0.026 ns` slack
in `tc_view`. This remains typical-only, non-OCV evidence with SI off, not MMMC
or signoff.

Top review found a separate package blocker. The connectivity reports expose
the actual Innovus design boundary as `952.000 x 660.240 um`, while the audited
`POSITION_CORE` reservation is `951.695 x 660.000 um`. Therefore:

```text
OOC_ROUTE_STATUS=CLEAN
TOP_RESERVATION_WIDTH_EXCESS_UM=0.305
TOP_RESERVATION_HEIGHT_EXCESS_UM=0.240
TOP_RESERVATION_FIT_STATUS=FAIL_DERIVED_FROM_REPORTED_BOUNDARY
IMMUTABLE_PACKAGE_AUTHORIZED=NO
PVS_AUTHORIZED=NO
NEXT_GATE=POSITION_GRID_SAFE_INNOVUS_REPLAY
```

The run is retained as useful route-feasibility evidence, but its GDS is not
an immutable PVS candidate. PVS would be wasted because a corrected floorplan
replay necessarily changes the GDS hash.

Root causes and corrections:

- Position and Event OOC plans duplicated hard-coded reservation coordinates
  instead of consuming `spadmic_digital_floorplan_regions.csv`.
- The requested core did not reserve for Innovus's `0.560 um` site/grid
  snapping of the core margins and dimensions.
- The wrapper did not compare the actual `top.fPlan.box` against the fixed
  top-level reservation.
- Run `SUMMARY.md` echoed environment defaults for route/PG fields instead of
  the generated physical status.

The generator now reads the checked-in reservation, requests a grid-safe
Position core of `931.280 x 639.520 um`, and predicts a
`951.440 x 659.680 um` die. Innovus now writes `floorplan_geometry.rpt` and
cannot return `ABSTRACT_READY_FOR_TOP_REVIEW` when
`TOP_RESERVATION_FIT_STATUS` is not `PASS`. Summary route profile, route-layer,
PG mode, and PG strategy fields now come from `ooc_harden_status.rpt`.

No RTL, accepted Genus artifact, timing constraint, placement reservation, or
PDK input changed. The next run must reuse the exact accepted Genus netlist and
SDC hashes, then repeat every Innovus physical gate before packaging.

### P09-R03 Grid-Safe Innovus Replay Accepted

The corrected Position replay executed in one fresh foreground Innovus process
on 2026-07-17 from an attributable checkout:

```text
BRANCH=SPADMIC_test
HEAD=179baaf3fc35c931d95d47d70f84c760ccfd17ed
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
PORTFOLIO_RC=0
POSITION_GENUS_RUN=genus_ooc_position_core_20260717_101642
POSTSYN_NETLIST_SHA256=53bc725784e78fba8c2188f8ef9e31965abc84ffa02c195be1bf8e6e916518c6
POSTSYN_SDC_SHA256=69929a339cb2b2951bee4f7b2b6b558277e13bfac504951c57b38cf497d4f21f
POSITION_PNR_RUN=innovus_ooc_harden_position_core_gridfit_20260717_114810
POSITION_PNR_RC=0
```

The generated plan and the actual Innovus geometry agree with the grid-safe
contract:

```text
REQUESTED_CORE_WIDTH_UM=931.280
REQUESTED_CORE_HEIGHT_UM=639.520
ACTUAL_DIE_WIDTH_UM=951.440
ACTUAL_DIE_HEIGHT_UM=659.680
TOP_RESERVATION_WIDTH_UM=951.695
TOP_RESERVATION_HEIGHT_UM=660.000
TOP_RESERVATION_WIDTH_MARGIN_UM=0.255
TOP_RESERVATION_HEIGHT_MARGIN_UM=0.320
TOP_RESERVATION_FIT_STATUS=PASS
ABSTRACT_LEF_SIZE_UM=951.440 x 659.680
```

Every reviewed Innovus gate remained clean after the geometry correction:

```text
RESULT=ABSTRACT_READY_FOR_TOP_REVIEW
INNOVUS_DRC_STATUS=PASS
DRC_MARKER_TOTAL=0
MET1_MIN_AREA_MARKER_COUNT=0
ANTENNA_MARKER_COUNT=0
OTHER_MARKER_COUNT=0
REGULAR_CONNECTIVITY_STATUS=PASS
REGULAR_CONNECTIVITY_VIOLATION_COUNT=0
REGULAR_CONNECTIVITY_WARNING_COUNT=0
PG_CONNECTIVITY_STATUS=PASS
PG_CONNECTIVITY_VIOLATION_COUNT=0
PG_CONNECTIVITY_WARNING_COUNT=0
POSTROUTE_SETUP_TIMING=PASS
POSTROUTE_HOLD_TIMING=PASS
WORST_REPORTED_SETUP_SLACK_NS=0.048
TIMING_ANALYSIS_VIEW=tc_view
ROUTE_PROFILE=met1_effort
SIGNAL_ROUTE_LAYERS=MET1-MET3
PG_LOCAL_ROUTE_MODE=EXPLICIT_EXACT
PG_ROUTE_STRATEGY=EXPLICIT_EXACT
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
GDS_EXPORT_ERROR_COUNT=0
```

Accepted output identity:

```text
GDS_BYTES=11523506
GDS_SHA256=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
ABSTRACT_LEF_BYTES=61822
ABSTRACT_LEF_SHA256=1eb91d021edccd4806a5516ef1f2aa0a2718607ee84c248d2d0e12cd8e698683
ROUTED_PG_NETLIST_BYTES=1486584
ROUTED_PG_NETLIST_SHA256=4078d8b5f277923948371898663ea2b0093fae205bad09e2f91c5f502f251cfd
POSITION_GRID_SAFE_REPLAY_STATUS=PASS
NEXT_GATE=IMMUTABLE_POSITION_HANDOFF_STAGING
```

The old `49a7a030...` GDS remains a rejected feasibility artifact because its
boundary exceeds the reservation. The new `ebba26a4...` GDS is authorized for
immutable staging, not for promotion or signoff. This run is typical-only;
MMMC, PVS base and density DRC, PEX, and foundry LVS remain unexecuted or
deferred. No PVS result may be attached until staging reproduces these hashes
and the package-local source preparation and pin-parity audit pass.

### P09-R04 Immutable Position Handoff Accepted

The corrected Position replay was staged and audited in the foreground on
2026-07-17 from an attributable checkout:

```text
BRANCH=SPADMIC_test
HEAD=8a617c9f8049340cebc777783255acffd55212d6
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
PORTFOLIO_RC=0
SOURCE_FILE_GATE_RC=0
SOURCE_HASH_GATE_RC=0
SOURCE_STATUS_GATE_RC=0
PACKAGE_ABSENCE_RC=0
```

The staging runner rechecked the original physical source commit
`179baaf3fc35c931d95d47d70f84c760ccfd17ed`, accepted Genus input hashes, and
all three primary Innovus output hashes before creating the package. The
immutable package identity is:

```text
PACKAGE=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810
PACKAGE_CREATED_UTC=2026-07-17T10:18:24.257509+00:00
PACKAGE_KIND=block
PACKAGE_NAME=spadmic_position_core
PACKAGE_VERSION=innovus_ooc_harden_position_core_gridfit_20260717_114810
PACKAGE_STATE=candidate
QUALIFICATION_PROFILE=basic
LAYOUT_TOP=spadmic_position_core
SOURCE_TOP=spadmic_position_core
PACKAGE_REPO_HEAD=8a617c9f8049340cebc777783255acffd55212d6
```

Staging and independent package audit both passed:

```text
HANDOFF_STAGE_RC=0
HANDOFF_AUDIT_RC=0
HANDOFF_AUDIT_STATUS=PASS
CANONICAL_NAME_STATUS=PASS
LVS_SOURCE_PREPARATION_STATUS=PASS
PIN_PARITY_STATUS=PASS
STDCELL_CDL_STATUS=PASS
HANDOFF_AUDIT_ERROR_COUNT=0
```

The package preserved the reviewed physical artifacts byte-for-byte and
created a separately hashed canonical LVS source:

```text
GDS_BYTES=11523506
GDS_SHA256=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
ABSTRACT_LEF_BYTES=61822
ABSTRACT_LEF_SHA256=1eb91d021edccd4806a5516ef1f2aa0a2718607ee84c248d2d0e12cd8e698683
RAW_PG_NETLIST_BYTES=1486584
RAW_PG_NETLIST_SHA256=4078d8b5f277923948371898663ea2b0093fae205bad09e2f91c5f502f251cfd
CANONICAL_LVS_SOURCE_BYTES=1471851
CANONICAL_LVS_SOURCE_SHA256=a5e81c21e633ae1b55d8da5c8e971997f890d9cee42dff2f6cf9f9f43cad9ffb
STDCELL_CDL_BYTES=2306599
STDCELL_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
```

Canonical-source preparation removed only official CDL-owned standard-cell
definitions and retained the complete design hierarchy required by PVS:

```text
INPUT_MODULE_COUNT=160
RETAINED_MODULE_COUNT=2
REMOVED_STDCELL_MODULE_COUNT=158
SOURCE_TOP_PORT_COUNT=251
LEF_PIN_COUNT=251
NESTED_TOP_PORT_COUNT=0
REFERENCED_MASTER_COUNT=159
CDL_RESOLVED_MASTER_COUNT=158
DESIGN_RESOLVED_MASTER_COUNT=1
UNRESOLVED_MASTER_COUNT=0
ERROR_COUNT=0
```

The package-local floorplan report still proves `951.440 x 659.680 um` with
positive reservation margins, and the copied GDS audit still binds the exact
`ebba26a4...` GDS to the approved stream map and JIHD merge.

Final staging acceptance was exact:

```text
RUN_OK=1
PACKAGE_HASH_GATE_RC=0
MANIFEST_GATE_RC=0
QUALIFICATION_GATE_RC=0
AUDIT_REPORT_GATE_RC=0
SOURCE_PREP_GATE_RC=0
PACKAGE_EVIDENCE_GATE_RC=0
POSITION_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

The `basic` qualification profile intentionally leaves package-promotion
fields `BBOX_PARITY_STATUS`, `GDS_LAYER_MAP_STATUS`,
`GDS_MERGE_STATUS`, and `INTERNAL_PG_STATUS` as `UNKNOWN`, and
`TC_TIMING_STATUS` as `NOT_RUN`. This does not erase the independently copied
and hashed Innovus reports, but those placeholders cannot be promoted to
package-level PASS without their later dedicated gates.

No PVS tool was launched. The next gate is an attributable Position base-DRC
template and strict replay preflight. Base DRC, density DRC, and exact-package
LVS all remain `NOT_RUN`.

### P09-R05 Position PVS DRC Template Discovery

The discovery-only transaction ran in the foreground on 2026-07-17 from the
exact checked-in discovery implementation:

```text
BRANCH=SPADMIC_test
EXPECTED_HEAD=ddf80bdceb61f64e7fb2b2891603fa6e38463795
ACTUAL_HEAD=ddf80bdceb61f64e7fb2b2891603fa6e38463795
CHECKOUT_RC=0
PULL_RC=0
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
DISCOVERY_RC=0
POSITION_TEMPLATE_DISCOVERY_COMMAND_STATUS=PASS
```

Before searching, the runner re-audited the accepted immutable package and
reproduced the exact Position GDS identity:

```text
PACKAGE_FILE_GATE_RC=0
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
ACTUAL_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
PACKAGE_HASH_GATE_RC=0
PACKAGE_STATUS_GATE_RC=0
PACKAGE_SHA_MANIFEST_RC=0
PACKAGE_MODIFIED=NO
```

One configured search root existed. The two alternate capitalization paths
did not:

```text
SEARCH_ROOT_STATUS=FOUND ROOT=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc
SEARCH_ROOT_STATUS=MISSING ROOT=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PvsDRC
SEARCH_ROOT_STATUS=MISSING ROOT=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PVS_DRC
```

The found root contained 114 GUI-generated DRC directories. Every candidate
was inventoried with control-file sizes, hashes, embedded GDS/top references,
technology information, and DENSITY-hook evidence. None had a path or control
reference attributable to `position` or `spadmic_position_core`:

```text
STATUS=PASS
RESULT=CANDIDATES_RECORDED_FOR_REVIEW
TEMPLATE_CANDIDATE_COUNT=114
POSITION_NAMED_CANDIDATE_COUNT=0
POSITION_TEMPLATE_EVIDENCE_STATUS=NOT_FOUND
ATTRIBUTABLE_POSITION_TEMPLATE_STATUS=NOT_PROVEN
TEMPLATE_SELECTION_AUTHORIZED=NO
CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

`STATUS=PASS` classifies the immutable discovery transaction, not the missing
Position template and not PVS DRC. Therefore Position base DRC, density DRC,
and LVS all remain `NOT_RUN`.

The nearest review candidate is the non-HV `spadmic_tx_packet_core` directory.
It is a same-project digital-block rule scaffold using `XH018_1131`,
`TECH_XH018_HD`, and an explicit DENSITY hook. Its exact controls were pinned
from the discovery output:

```text
CONFIG_SHA256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
PRESET_SHA256=97b3a7e63c3e8a01ea1291a19de384e2c41f77cd11653a92c7f5618e73421000
TECHNOLOGY_SHA256=74a297facf6422635df2c58d79aa8b8ae46ca0b8232380471a88a182d8400ab6
PIPO1_SHA256=949ce7ec915d1ddbd3e78534720c33aad9036d83932c6bac33730a113aba00dd
PVSDRCCTL_SHA256=b9a8451c6cc43647ec606ae706e450893e3673e22215dc5a64edeeb383b902ef
RUN_PVS_SHA256=11ae3fc935041b8a4e0f3b406941c699c769ed1d50a504e8df36fcb544c7255a
```

This is not Position evidence and has not been selected for replay. The next
gate is `server_review_position_core_pvs_drc_seed.sh`: it binds the exact R05
inventory and seed hashes, snapshots the controls into a separate diagnostic
directory, checks executable GDS/top/technology/DENSITY/output directives,
and scans for waiver or rule-suppression controls. It deliberately runs no
replay and no PVS and leaves every authorization field at `NO` pending review.

Compact source evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_drc/position_template_discovery_20260717_125002/
```

### P09-R06 Position PVS DRC Cross-Block Seed Review

The read-only seed review ran in the foreground on 2026-07-17 after the
server checkout was updated to the exact review implementation:

```text
BRANCH=SPADMIC_test
EXPECTED_HEAD=2c6b0170845bf125d48700ed8594e5d3da121e14
ACTUAL_HEAD=2c6b0170845bf125d48700ed8594e5d3da121e14
CHECKOUT_RC=0
PULL_RC=0
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
REVIEW_RC=0
POSITION_SEED_CONTROL_REVIEW_COMMAND_STATUS=PASS
```

The reviewer reproduced all three R05 diagnostic hashes, re-audited the
immutable Position package, and reproduced the accepted Position GDS hash.
The package SHA manifest passed before and after review, and every pinned
primary-seed control retained its R05 identity:

```text
DISCOVERY_FILE_GATE_RC=0
DISCOVERY_HASH_GATE_RC=0
DISCOVERY_STATUS_GATE_RC=0
PACKAGE_FILE_GATE_RC=0
PACKAGE_HASH_GATE_RC=0
PACKAGE_STATUS_GATE_RC=0
PACKAGE_SHA_MANIFEST_RC=0
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=0
PRIMARY_CONTROL_IDENTITY_GATE_RC=0
PRIMARY_CONTROL_COPY_GATE_RC=0
SOURCE_TEMPLATE_RECHECK_RC=0
PACKAGE_MODIFIED=NO
PINNED_SOURCE_CONTROLS_UNCHANGED=YES
```

The selected review input remained the exact non-HV packet-core directory,
classified only as a cross-block launch-scaffold candidate. Its `run.pvs`,
`pvsdrcctl`, and `.technology.rul` checks passed; its executable risk scan
contained zero matching lines. The reviewer also observed one DENSITY
directive among five preprocessor directives.

The sole reported contract failure was not a seed-control mismatch. The
`pipo1.setup` inventory visibly contained:

```text
16:techLib    "TECH_XH018_HD"
```

but the original checker searched for one literal run of spaces while the
file separates the field and value with a tab. It therefore emitted:

```text
CONTRACT_LINE_RC=1 FILE=.../spadmic_tx_packet_core/pipo1.setup EXPECTED=techLib    "TECH_XH018_HD"
PRIMARY_EXECUTABLE_CONTRACT_GATE_RC=1
```

This is retained as a checker false-negative, not converted into a control
PASS after the fact. The checked-in follow-up changes that one gate to a
POSIX-whitespace expression, regression-tests tabs and spaces, and emits all
five preprocessor directives into a dedicated report. Since only one of the
five is DENSITY, the other four still require explicit semantic review even
after the corrected executable contract is rerun.

The original server status remains authoritative for this diagnostic:

```text
STATUS=PASS
RESULT=CROSS_BLOCK_SEED_CONTROLS_RECORDED_FOR_REVIEW
PRIMARY_CONTROL_IDENTITY_STATUS=PASS
PRIMARY_EXECUTABLE_CONTRACT_STATUS=FAIL
DENSITY_HOOK_STATUS=PASS
AUTOMATED_CONTROL_RISK_SCAN_STATUS=PASS
EXECUTABLE_RISK_LINE_COUNT=0
SEED_TECHNICAL_REVIEW_STATUS=REVIEW_REQUIRED
ATTRIBUTABLE_POSITION_TEMPLATE_STATUS=NOT_PROVEN
TEMPLATE_SELECTION_AUTHORIZED=NO
CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO
STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=POSITION_PVS_DRC_SEED_CONTROL_MANUAL_REVIEW
```

No source template or immutable package file was modified and no PVS tool was
launched. The next transaction is a rerun of the corrected read-only reviewer,
followed by manual classification of its complete preprocessor-directive
report. Strict dry-run preflight remains unauthorized until that review is
accepted.

Compact source evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_drc/position_seed_review_20260717_132208/
```

### P09-R06b Corrected Position Seed Review

The corrected read-only reviewer ran in the foreground on 2026-07-17 from
exact commit `6baf4a95224edf0a2669ae5d4db43df925f8d73c`:

```text
CHECKOUT_RC=0
PULL_RC=0
EXPECTED_HEAD=6baf4a95224edf0a2669ae5d4db43df925f8d73c
ACTUAL_HEAD=6baf4a95224edf0a2669ae5d4db43df925f8d73c
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
REVIEW_RC=0
POSITION_SEED_CONTROL_REVIEW_COMMAND_STATUS=PASS
```

All R05 discovery, immutable package, Position GDS, and primary seed-control
hashes reproduced. The package SHA manifest passed before and after review,
the source controls remained unchanged, and the corrected whitespace-tolerant
technology-library contract passed:

```text
PRIMARY_CONTROL_IDENTITY_STATUS=PASS
PRIMARY_EXECUTABLE_CONTRACT_STATUS=PASS
CONTRACT_REGEX_RC=0 EXPECTED_TECHLIB=TECH_XH018_HD
AUTOMATED_CONTROL_RISK_SCAN_STATUS=PASS
EXECUTABLE_RISK_LINE_COUNT=0
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=0
PACKAGE_MODIFIED=NO
PINNED_SOURCE_CONTROLS_UNCHANGED=YES
```

The exact preprocessor tuple is now known:

```text
#UNDEFINE DENSITY
#UNDEFINE POPPING
#UNDEFINE PIMIDE
#UNDEFINE DUMMY_FILL
#DEFINE VAR_ANT_RATIO
```

`DENSITY=UNDEFINED` establishes the seed as a base-DRC configuration and
requires a separate density-enabled run. `VAR_ANT_RATIO=DEFINED` enables the
additional variable-ratio antenna family; it is not a suppression. The
primary control labels `DUMMY_FILL` as a dummy-pattern generation selector,
but its rule-deck impact still requires review. The meanings and coverage
effects of `POPPING` and `PIMIDE` are not established by the generated control
alone and must not be guessed.

The corrected review therefore closed the executable-contract defect without
authorizing the next execution stage:

```text
STATUS=PASS
PREPROCESSOR_DIRECTIVE_COUNT=5
NON_DENSITY_PREPROCESSOR_DIRECTIVE_COUNT=4
PREPROCESSOR_DIRECTIVE_REVIEW_STATUS=REVIEW_REQUIRED
SEED_TECHNICAL_REVIEW_STATUS=REVIEW_REQUIRED
ATTRIBUTABLE_POSITION_TEMPLATE_STATUS=NOT_PROVEN
TEMPLATE_SELECTION_AUTHORIZED=NO
CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO
STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=POSITION_PVS_DRC_SEED_PREPROCESSOR_MANUAL_REVIEW
```

The next checked-in transaction,
`server_review_position_core_pvs_drc_preprocessor.sh`, binds this exact R06b
diagnostic, compares the directive tuple across all 114 discovered controls,
captures the primary GUI-preset descriptions and adjacent comments, and
snapshots the exact `pvtech.lib` configuration and references. It remains
read-only and cannot create a replay directory or launch PVS.

Compact R06b evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_drc/position_seed_review_20260717_133839/
```

### P09-R07 Position Preprocessor Evidence Collection

The read-only PDK/preprocessor collector ran in the foreground on 2026-07-17
from exact commit `0d549dc248b9e315113cee1a7af68887c6fcb487` and corrected
R06b diagnostic `position_pvs_drc_seed_review_20260717_133839`:

```text
CHECKOUT_RC=0
PULL_RC=0
EXPECTED_HEAD=0d549dc248b9e315113cee1a7af68887c6fcb487
ACTUAL_HEAD=0d549dc248b9e315113cee1a7af68887c6fcb487
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
COLLECT_RC=0
POSITION_PREPROCESSOR_REVIEW_COMMAND_STATUS=PASS
```

All pinned R06b reports, source controls, the accepted Position GDS, and the
immutable package reproduced. Package manifests passed before and after the
collection, and no source or package file changed.

The complete 114-candidate matrix has only two tuples:

```text
candidate_count  DENSITY    POPPING    PIMIDE     DUMMY_FILL  VAR_ANT_RATIO
111              UNDEFINED  UNDEFINED  UNDEFINED  UNDEFINED   UNDEFINED
3                UNDEFINED  UNDEFINED  UNDEFINED  UNDEFINED   DEFINED
```

This proves that `DENSITY`, `POPPING`, `PIMIDE`, and `DUMMY_FILL` have the
same undefined state in every discovered control. It does not prove the PDK
coverage effect of those states. `VAR_ANT_RATIO` is the sole varying selector;
the exact three candidate names remain in the immutable matrix and are
isolated by the next collector.

The 52-byte technology library is exact:

```text
UNDEFINE XH018_1131
DEFINE XH018_1131 .pvsSetup/PVS
```

The R07 reference extractor emitted `/PVS` because it retained only the
slash-prefixed suffix of the relative token. `/PVS` is therefore a parser
artifact, not an attributable absolute path. The follow-up preserves the raw
`.pvsSetup/PVS` token, resolves it against the directory containing
`pvtech.lib`, and performs a bounded read-only inventory and directive search.

R07 remains an evidence-capture pass rather than a PVS authorization:

```text
STATUS=PASS
MATRIX_CANDIDATE_COUNT=114
MATRIX_INCOMPLETE_COUNT=0
UNIQUE_DIRECTIVE_TUPLE_COUNT=2
MATRIX_COMPLETENESS_STATUS=PASS
PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=0
PACKAGE_MODIFIED=NO
PVS_TEMPLATE_CREATED=NO
TEMPLATE_SELECTION_AUTHORIZED=NO
CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO
STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

Compact evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_drc/position_preprocessor_review_20260717_140420/
```

### P09-R08 Position PVS Rule-Setup Discovery

The relative-mapping and bounded rule-setup collector ran in the foreground on
2026-07-17 from exact commit
`329950f10f42d8ddc50a4ada8d626a3cdebf04ea` and immutable preprocessor
diagnostic `position_pvs_drc_preprocessor_review_20260717_140420`:

```text
CHECKOUT_RC=0
PULL_RC=0
EXPECTED_HEAD=329950f10f42d8ddc50a4ada8d626a3cdebf04ea
ACTUAL_HEAD=329950f10f42d8ddc50a4ada8d626a3cdebf04ea
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
RULE_SETUP_RC=0
POSITION_RULE_SETUP_DISCOVERY_COMMAND_STATUS=PASS
```

All prior diagnostic hashes, the accepted Position GDS, the package manifest,
the source `pvtech.lib`, and the primary seed control reproduced. Package
manifests passed before and after collection, and neither package nor source
controls changed.

The previous `/PVS` rendering is conclusively a substring-extraction artifact.
The exact raw mapping and its resolved project path are:

```text
PVTECH_MAPPING_RAW=.pvsSetup/PVS
MAPPING_LEXICAL=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.pvsSetup/PVS
MAPPING_CANONICAL=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.pvsSetup/PVS
MAPPING_CANONICAL_EXISTS=YES
```

The scan also found the canonical PDK setup at
`/data/pdk/xfab/xh018/cadence/v10_1/pvs/v10_1_1/PVS`. It recorded 59 bounded
inventory entries, 35 readable text files, and seven directive-bearing files.
The exact DRC deck is 922441 bytes with SHA-256
`0b1ce563da515dd50d17a5e16baa2a2addc10354aa06ab5e1a111b01ed039cb6`.

The normal `pvs.cfg` defaults every reviewed selector to `0`. The primary
cross-block seed differs only by defining `VAR_ANT_RATIO`; the only three
controls with that state are `SPADMIC2`, `TXRX4TDC2_HV`, and
`spadmic_tx_packet_core`.

Bounded deck context establishes the selector classes without proving Position
applicability:

```text
DENSITY      = separate optional density family
POPPING      = optional IMD Popping Checks family
PIMIDE       = optional pad-marker branch
DUMMY_FILL   = dummy generation and output selector
VAR_ANT_RATIO= additional variable-ratio antenna family
```

The reference excerpt showed four `DrcRules` variants but omitted their
surrounding rule-set names. It therefore does not yet bind the source
`-ruleSet "default"` selector to one exact entry. Likewise, seeing an optional
branch in the deck does not prove that the Position block requires that branch.

P09-R08 remains a discovery pass:

```text
STATUS=PASS
PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED
TEMPLATE_SELECTION_AUTHORIZED=NO
CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO
STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

Compact evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_drc/position_rule_setup_discovery_20260717_150856/
```

The next read-only transaction is
`TOP/ci/server_review_position_core_pvs_drc_rule_semantics.sh`. It records the
full numbered rule-set metadata, exact metal-switch selection and PDK revision,
balanced conditional-block hashes and bounded semantic context, and an
optional user-guide text scan. It does not create a template or execute PVS.

### P09-R09 Position PVS Rule-Semantics Review

The named-rule-set and conditional-block reviewer ran in the foreground on
2026-07-17 from exact commit
`8f4154d658c7fd9d6cb8deca98c6f5bf04807705` and immutable rule-setup
diagnostic `position_pvs_drc_rule_setup_discovery_20260717_150856`:

```text
CHECKOUT_RC=0
PULL_RC=0
EXPECTED_HEAD=8f4154d658c7fd9d6cb8deca98c6f5bf04807705
ACTUAL_HEAD=8f4154d658c7fd9d6cb8deca98c6f5bf04807705
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
REVIEW_RC=0
POSITION_RULE_SEMANTICS_REVIEW_COMMAND_STATUS=PASS
```

All pinned R08 evidence, the accepted Position GDS, the immutable package,
project and PDK rule-set metadata, PDK deck/configuration, metal switch, and
user guide reproduced. Package manifests passed before and after review, and
no package or source file changed.

The project and PDK metadata agree on the selected named rule set:

```text
RULE_SET=default
DRC_RULES=metalswitch.pvl+xh018_DRC.rul
DRC_GUI_CONFIG=pvs.cfg
DEFAULT_RULE_SET_EVIDENCE_STATUS=PASS
```

The selected XH018 v10.1.1 switch is `MET3 / METMID`: `METAL3` and `MIDMET`
are defined; `METAL4`, `METAL5`, `METAL6`, `THKMET`, and
`XFAB_IP_BBOX_ANTENNA` are undefined. The normal `pvs.cfg` default for
`DENSITY`, `POPPING`, `PIMIDE`, `DUMMY_FILL`, and `VAR_ANT_RATIO` is zero.

The complete conditional inventory is balanced:

```text
DENSITY_CONDITIONAL_BLOCK_COUNT=1
DENSITY_RULE_COUNT=34
POPPING_CONDITIONAL_BLOCK_COUNT=1
POPPING_RULE_COUNT=6
PIMIDE_CONDITIONAL_BLOCK_COUNT=1
DUMMY_FILL_CONDITIONAL_BLOCK_COUNT=2
VAR_ANT_RATIO_CONDITIONAL_BLOCK_COUNT=78
UNMATCHED_CONDITIONAL_COUNT=0
```

The PDK guide establishes that density is an additional post-fill family,
dummy fill generates virtual shapes, popping adds W5M* checks intended mostly
for post-fill chip-level use, and `VAR_ANT_RATIO` adds user-ratio `ADD_*`
antenna checks. The primary seed's defined `VAR_ANT_RATIO` therefore adds
coverage rather than suppressing standard antenna rules.

`PIMIDE` remains the only unresolved Position-specific selector. Its exact
deck branch checks PAD geometry for a PIMIDE marker when enabled, but the deck
and guide do not prove whether the accepted Position hierarchy contains either
stream layer. R09 therefore remains an evidence pass and does not authorize
preflight:

```text
STATUS=PASS
DEFAULT_RULE_SET_EVIDENCE_STATUS=PASS
DEFAULT_RULE_SET_SELECTION_STATUS=REVIEW_REQUIRED
PIMIDE_APPLICABILITY_STATUS=REVIEW_REQUIRED
PACKAGE_MODIFIED=NO
PVS_TEMPLATE_CREATED=NO
STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

Compact R09 evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_drc/position_rule_semantics_review_20260717_161842/
```

The next read-only transaction is
`TOP/ci/server_review_position_core_pvs_drc_gds_layer_applicability.sh`. It
pins the accepted GDS, official stream map, exact PVS deck, and complete R09
diagnostic; resolves `pad` and `pimide` to exact stream tuples; parses the GDS
hierarchy; and counts target geometry only in structures reachable from
`spadmic_position_core`. It cannot create a template or execute PVS.

### P09-R10 Position PVS GDS Layer Applicability Review

The binary GDS applicability review ran in the foreground on 2026-07-20 from
exact commit `a622dd0bf88478ecf124a448296c7390702d2d1f` and immutable R09
diagnostic `position_pvs_drc_rule_semantics_review_20260717_161842`:

```text
CHECKOUT_RC=0
PULL_RC=0
EXPECTED_HEAD=a622dd0bf88478ecf124a448296c7390702d2d1f
ACTUAL_HEAD=a622dd0bf88478ecf124a448296c7390702d2d1f
TRACKED_DIFF_RC=0
STAGED_DIFF_RC=0
REVIEW_RC=0
POSITION_GDS_LAYER_APPLICABILITY_COMMAND_STATUS=PASS
```

Every pinned R09 report, the accepted package manifest, Position GDS, official
stream map, and DRC deck reproduced. The GDS parser consumed the complete
11,523,506-byte stream, found the declared `spadmic_position_core` top, and
proved the complete 218-structure hierarchy reachable with no unresolved
references or cycle edges:

```text
GDS_PARSE_STATUS=PASS
GDS_TOP_STRUCTURE_STATUS=PASS
GDS_HIERARCHY_STATUS=PASS
STRUCTURE_COUNT=218
REACHABLE_STRUCTURE_COUNT=218
REACHABLE_UNRESOLVED_REFERENCE_COUNT=0
REACHABLE_HIERARCHY_CYCLE_EDGE_COUNT=0
SERIALIZED_ELEMENT_RECORD_COUNT=129097
ERROR_COUNT=0
```

The exact PVS target mappings were resolved before counting geometry:

```text
PAD     internal=50190 GDS=19/0  reachable_geometry=0 reachable_text=0
PIMIDE  internal=22150 GDS=221/5 reachable_geometry=0 reachable_text=0
NOPIM   internal=50460 GDS=46/0  reachable_geometry=0 reachable_text=0
```

Because the exact accepted hierarchy contains neither PAD nor PIMIDE geometry,
the optional PIMIDE branch is not applicable to Position OOC DRC. The absence
of named target entries in the Innovus stream map is consistent with the
binary inventory and is not used as a substitute for the direct PVS deck
mapping.

The accepted Position option policy is now complete:

```text
DEFAULT_RULE_SET=default
DEFAULT_RULE_SET_SELECTION_STATUS=PASS
DENSITY_STATE=UNDEFINED
DENSITY_POLICY=BASE_DRC_PLUS_SEPARATE_DENSITY_DRC
POPPING_STATE=UNDEFINED
POPPING_POLICY=DEFER_TO_POST_FILL_CHIP_LEVEL_CONTEXT
DUMMY_FILL_STATE=UNDEFINED
DUMMY_FILL_POLICY=NO_VIRTUAL_DUMMY_GENERATION_DURING_POSITION_OOC_DRC
VAR_ANT_RATIO_STATE=DEFINED
VAR_ANT_RATIO_POLICY=RETAIN_SUPPLEMENTAL_ADD_RULE_FAMILY
PIMIDE_STATE=UNDEFINED
PIMIDE_POSITION_APPLICABILITY_STATUS=NOT_APPLICABLE_NO_REACHABLE_PAD_OR_PIMIDE_GEOMETRY
```

The server transaction itself correctly stopped at a recommendation and did
not self-authorize execution:

```text
STATUS=PASS
STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=READY_FOR_MANUAL_AUTHORIZATION
STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

Manual review accepts the recommendation for strict dry-run preflight only.
The pinned packet-core controls may now be reused as a control scaffold because
the exact named rule set, metal stack, option semantics, and Position-specific
PIMIDE applicability are all bound. This does not authorize a PVS process.

To avoid another single-question discovery cycle, P09-R11 materializes both
base and density run-local controls in one transaction. It must prove exact
Position GDS/top replacement, isolated output paths, complete external
references, preserved non-density selectors, opposite explicit DENSITY states,
source immutability, and package-manifest integrity. Only then may one
foreground base DRC execution be authorized and classified.

Compact R10 evidence and the manual decision are retained under:

```text
TOP/docs/server_snapshots/pvs_drc/position_gds_layer_applicability_20260720_105724/
```

### P09-R11 Position PVS Strict Preflight Initial Failure

The combined base and density strict dry-run preflight first ran in the
foreground on 2026-07-20 from exact commit
`3d8c0e025cbaa6caa300e7efc2290983bcec90e2` and immutable R10 diagnostic
`position_pvs_drc_gds_layer_applicability_20260720_105724`.

All attribution and input gates passed. The repository was clean at the exact
expected head, every R10 hash and status reproduced, the accepted Position GDS
remained `ebba26a4...`, the package manifest passed, and every pinned seed
control retained its expected hash. The base replay contract also materialized
successfully:

```text
INPUT_HASH_GATE_RC=0
INPUT_MANIFEST_GATE_RC=0
INPUT_STATUS_GATE_RC=0
PACKAGE_GATE_RC=0
PACKAGE_SHA_MANIFEST_RC=0
SEED_FILE_GATE_RC=0
SEED_IDENTITY_GATE_RC=0
PVS_REPLAY_PATCH_STATUS=PASS
PATCH_RC=0
```

The first base dry-run then rejected two false external references:

```text
MISSING=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_position_core
MISSING=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_position_core/PIPO1.LOG
ERROR: patched PVS template has missing external references
BASE_DRY_RUN_RC=1
DENSITY_DRY_RUN_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=1
```

This is a replay-tool path-order defect, not a Position package, PDK, seed, or
PVS result. The packet-core top token was replaced before the longer absolute
packet-core execution root. That changed the old root into an unrecognized
`.../spadmic_position_core` path before run-directory relocation could match
it. The repair applies all replacement sources longest-first and includes a
regression where the old top name is also the GUI execution-directory name.
The old wrapper also marked diagnostic copying failed because it required the
files of the deliberately unrun density variant. The corrected failure path
copies all available partial artifacts and requires a complete variant only
when that variant's dry-run return code is zero.

No PVS process ran, no source or package changed, and neither base nor density
DRC acquired a result:

```text
STATUS=FAIL
STRICT_DRY_RUN_PREFLIGHT_STATUS=FAIL
PVS_BASE_DRC_EXECUTION_AUTHORIZED=NO
PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

The failed transaction is retained rather than overwritten:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_strict_preflight_20260720_111548
TOP/docs/server_snapshots/pvs_drc/position_strict_preflight_20260720_111548_failed/
```

### P09-R11 Position PVS Strict Preflight Corrected Pass

The corrected combined preflight ran in the foreground on 2026-07-20 from
exact commit `130954a9ddd074633cea0e612fd4ea7355a44b84` against the unchanged
R10 applicability diagnostic. The fresh diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_strict_preflight_20260720_113452
```

All previously passing attribution, source, package, GDS, and seed-control
gates reproduced. The longest-source-first replay correction eliminated both
false external references. Fresh base and density control directories then
passed replay, output-isolation, external-reference, selector, and complete
run-manifest audits:

```text
PREFLIGHT_RC=0
BASE_DRY_RUN_RC=0
DENSITY_DRY_RUN_RC=0
RUN_AUDIT_GATE_RC=0
DIAGNOSTIC_COPY_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=0
STATUS=PASS
STRICT_DRY_RUN_PREFLIGHT_STATUS=PASS
DIAGNOSTIC_MANIFEST_RC=0
POSITION_PVS_STRICT_PREFLIGHT_COMMAND_STATUS=PASS
```

Both controls bind `spadmic_position_core` and exact GDS SHA-256
`ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`.
The base control has exactly one `#UNDEFINE DENSITY`; the density control has
exactly one `#DEFINE DENSITY`. Both keep `POPPING`, `PIMIDE`, and `DUMMY_FILL`
undefined and retain `VAR_ANT_RATIO` defined. Every external reference is a
resolved, hashed file. No PVS process ran:

```text
PVS_EXECUTED=NO
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=FOREGROUND_BASE_PVS_DRC
```

Compact successful evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_drc/position_strict_preflight_20260720_113452/
```

R11 is the final dry-run and closes the Position discovery/preflight sequence.
The next transaction is
`TOP/ci/server_run_position_core_pvs_base_drc.sh`. It executes one fresh base
PVS DRC in the foreground and accepts only two attributable outcomes:

1. PVS returns zero and the unique report-level total is `0 (0)`.
2. PVS returns zero but the wrapper returns classification RC `8` for a unique
   nonzero report total; the existing immutable rule analyzer must then
   reconcile every rule and geometry in the same transaction.

Transaction PASS does not flatten the physical result: the second outcome
retains `PVS_BASE_DRC_STATUS=FAIL` with explicit rule debt. Either accepted
outcome proceeds directly to foreground density DRC on the same GDS. There is
no further rule-set, preprocessor, PIMIDE, or template-discovery review unless
a pinned input changes.

### P09-R12 Position Base PVS DRC Attributable Zero

The authorized foreground base transaction ran on 2026-07-20 from exact
commit `31738aa650492516340e54b7535c5d805b897090`. It used the accepted Position
package and unchanged GDS SHA-256
`ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`.
The immutable evidence roots are:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_base_execution_20260720_115921
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810/pvs/drc/position_base_drc_20260720_115921
```

The PVS tool, replay, output-isolation, run-file, run-manifest, source
recheck, package recheck, diagnostic-copy, and diagnostic-manifest gates all
passed. Three independently scanned text observations agreed on the same zero
total:

```text
BASE_DRC_RC=0
STATUS=PASS
RESULT=PVS_BASE_DRC_ZERO_RESULTS_RECORDED
PVS_WRAPPER_RC=0
PVS_TOOL_RC=0
PVS_BASE_DRC_STATUS=PASS
DRC_TOTAL_PRIMARY=0
DRC_TOTAL_EXPANDED=0
DRC_TOTAL_MATCH_COUNT=3
OUTCOME_CLASS=ATTRIBUTABLE_ZERO_RESULTS
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
RUN_FILE_GATE_RC=0
RUN_AUDIT_GATE_RC=0
RUN_MANIFEST_RC=0
DIAGNOSTIC_COPY_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=0
DIAGNOSTIC_MANIFEST_RC=0
```

The report-level evidence is
`.drcSummaryReport:Total DRC Results=0(0)`. The three matches are consistent
copies of that result, not three violations. The base control retained exactly
one `#UNDEFINE DENSITY`; `POPPING`, `PIMIDE`, and `DUMMY_FILL` remained
undefined while `VAR_ANT_RATIO` remained defined.

No rule-analysis directory was created because a zero-result run has no rule
debt to classify:

```text
RULE_ANALYSIS_RC=NOT_APPLICABLE
RULE_ANALYSIS_STATUS=NOT_APPLICABLE_ZERO_RESULTS
```

The operator's optional inspection loop printed `MISSING=` for the two
rule-analysis paths. Those messages are expected on this branch and are not a
run or manifest failure. Compact accepted evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_drc/position_base_drc_20260720_115921/
```

Base DRC is closed only for the exact accepted GDS. Density DRC and LVS remain
independent. The next transaction is
`TOP/ci/server_run_position_core_pvs_density_drc.sh`, which runs one fresh
density variant in the foreground. An attributable zero closes density. An
attributable nonzero result is fully reconciled and classified without a PVS
rerun, after which exact-GDS LVS still proceeds as an independent evidence
gate. Block promotion remains forbidden until base, density, and LVS all meet
their separate contracts.

### P09-R13 Position Density PVS DRC Attributable Four-Rule Debt

The authorized foreground density transaction ran on 2026-07-20 from exact
commit `d327be8596fccc8a60d46d5cd0138b93b6c2f03e`. It reused the accepted
Position package and unchanged GDS SHA-256
`ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`.
The immutable evidence roots are:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_density_execution_20260720_133314
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810/pvs/drc/position_density_drc_20260720_133314
```

The PVS executable returned RC `0`, while three report-level observations
agreed on the physical result `4 (4)`. The wrapper returned classification RC
`8`, as designed for a physical nonzero result. Replay, output isolation, run
files, run manifest, package identity, source identity, rule analysis, and
diagnostic manifest all passed:

```text
DENSITY_DRC_RC=0
STATUS=PASS
RESULT=PVS_DENSITY_DRC_NONZERO_RULE_DEBT_CLASSIFIED
OUTCOME_CLASS=ATTRIBUTABLE_NONZERO_RESULTS
PVS_WRAPPER_RC=8
PVS_TOOL_RC=0
PVS_BASE_DRC_STATUS=PASS
PVS_DENSITY_DRC_STATUS=FAIL
DRC_TOTAL_PRIMARY=4
DRC_TOTAL_EXPANDED=4
DRC_TOTAL_MATCH_COUNT=3
RESULT_COUNT_RECONCILIATION=PASS
ASCII_ERROR_GEOMETRY_RECONCILIATION=PASS
RULE_ANALYSIS_STATUS=PASS
DIAGNOSTIC_MANIFEST_RC=0
```

The four rules are:

| Rule | Layer | Results | Foundry description |
| --- | --- | ---: | --- |
| `R1M1` | MET1 | 1 | Minimum layer-area / EXTENT-area ratio, 30.0% |
| `R1M2` | MET2 | 1 | Minimum layer-area / EXTENT-area ratio, 30.0% |
| `R1M3` | MET3 | 1 | Minimum layer-area / EXTENT-area ratio, 30.0% |
| `R1MT` | METTP | 1 | Minimum layer-area / EXTENT-area ratio, 30.0% |

Every marker covers the complete Position extent:

```text
0.000000 0.000000 951.440000 659.680000
```

These are four whole-window density deficits, not four localized minimum-area
defects. The immutable analyzer output classified them as generic `AREA` and
suggested increasing connected polygons near markers. That generic guidance is
wrong for this rule form and is retained only as original evidence. The
analyzer now classifies `ratio ... EXTENT area` as `DENSITY`, removes the TX
marker comparison from generic area guidance, and directs review to the
foundry fill and assembled chip-level policy.

The prior user-guide evidence classifies density checks as default-off,
post-fill/chip-level. This run used the required separate density variant, but
the unfilled OOC macro does not authorize virtual `DUMMY_FILL` or local polygon
repair. The four-result density gate remains `FAIL` pending assembled-fill
disposition or a formal waiver. Base zero remains valid and no antenna result
was present:

```text
ANTENNA_PRIMARY_RESULT_COUNT=0
NON_ANTENNA_PRIMARY_RESULT_COUNT=4
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

Compact evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_drc/position_density_drc_20260720_133314/
```

The aggressive next gate is one foreground exact-GDS PVS LVS transaction via
`TOP/ci/server_run_position_core_pvs_lvs.sh`. It binds the unchanged GDS,
canonical Position LVS source SHA-256
`a5e81c21e633ae1b55d8da5c8e971997f890d9cee42dff2f6cf9f9f43cad9ffb`,
and package-local JIHD CDL SHA-256
`5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf`.
An explicit `MATCH` starts Event OOC immediately while density disposition is
reviewed in parallel. An explicit `MISMATCH` is preserved and classified
without rerunning PVS. Neither outcome silently closes the density gate.

### P09-R14 Position Exact-GDS LVS Template-Identity Stop

The first authorized exact-GDS LVS transaction ran in the foreground on
2026-07-20 from exact commit
`285dfc53b6bcf544bb5a42545edb17f3edc6b2c1`. Its diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_execution_20260720_141229
```

The accepted density diagnostic, package manifest, exact GDS, canonical LVS
source, and package-local JIHD CDL all passed their hash and semantic gates.
The transaction then stopped before replay because four GUI-managed files in
the historical TX LVS control scaffold had changed since the July 10 intake:

```text
.preset.autosave  24a96996... -> 43d19579...
pipo1.setup        449148fe... -> ed8c1a13...
pvslvsctl          7fc5ffd6... -> 8e538767...
run.pvs            8c0c4e92... -> dfe5394b...
```

`.config.rul` remained the empty-file hash `e3b0c442...`, and
`.technology.rul` remained `74a297fa...`. The fail-closed result is:

```text
TEMPLATE_FILE_GATE_RC=0
TEMPLATE_IDENTITY_GATE_RC=1
PVS_WRAPPER_RC=NOT_RUN
PVS_TOOL_RC=UNKNOWN
PVS_LVS_STATUS=UNKNOWN
PVS_EXECUTED=NO
PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=0
STATUS=FAIL
RESULT=EXACT_GDS_PVS_LVS_NOT_EXECUTED
```

The missing run evidence and console log are therefore expected. This event is
not a `MISMATCH`, does not invalidate base DRC zero or the classified density
debt, and does not authorize a density rerun. Compact negative evidence is
retained under:

```text
TOP/docs/server_snapshots/pvs_lvs/position_lvs_template_identity_20260720_141229_failed/
```

The correction uses the exact six hashes observed by the failed transaction as
the new byte baseline and adds a read-only semantic audit before any clone or
PVS process can start. It requires one LVS launcher, no DRC mode, one layout
and source top, one executable GDS and Verilog source, safe port comparison,
one set of isolated LVS/ERC outputs, and `DUMMY_FILL` undefined. The audit
extracts the current scaffold values instead of guessing them. Replay then
clones the immutable scaffold and independently forces the accepted Position
GDS, canonical source, canonical tops, and package JIHD CDL. A GUI preset CDL
is never accepted as executable evidence.

The aggressive next action remains one corrected foreground exact-GDS LVS
transaction. An attributable `MATCH` starts Event OOC immediately while the
four-rule density disposition proceeds in parallel. An attributable
`MISMATCH` is classified once without rerunning PVS.

### P09-R15 Position Exact-GDS LVS Optional-SVDB Audit Stop

The scaffold-rebased foreground attempt ran on 2026-07-20 from exact commit
`0a0220a5c5d3914ffcd408432394e73c9b4a0f55`. Its fresh diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_execution_20260720_143505
```

All six observed control hashes matched. The density source diagnostic,
package GDS, canonical LVS source, JIHD CDL, package manifest, PVS executable,
foundry files, and post-transaction source/package rechecks also passed. The
read-only audit extracted the expected historical control contract:

```text
LVS_MODE_OCCURRENCES=1
DRC_MODE_OCCURRENCES=0
TEMPLATE_LAYOUT_TOP=spadmic_tx_packet_core_HV
TEMPLATE_SOURCE_TOP=spadmic_tx_packet_core
LAYOUT_PATH_COUNT=1
SCHEMATIC_VERILOG_COUNT=1
SCHEMATIC_SPICE_COUNT=0
```

The sole audit failure was:

```text
SVDB_DIRECTORY_COUNT=0
ERROR_COUNT=1
ERROR=svdb_directory_count=0
TEMPLATE_SEMANTIC_GATE_RC=1
```

This was an audit-policy defect, not an unsafe input. `mask_svdb_dir` is an
output-location directive. The replay implementation already allowed it to be
absent, but the new intake audit incorrectly required exactly one. No replay
or PVS process started:

```text
PVS_WRAPPER_RC=NOT_RUN
PVS_TOOL_RC=UNKNOWN
PVS_LVS_STATUS=UNKNOWN
PVS_EXECUTED=NO
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=0
```

Compact evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_lvs/position_lvs_semantic_audit_20260720_143505_failed/
```

The corrected contract accepts zero or one incoming `mask_svdb_dir`, rejects
duplicates, and makes replay materialize exactly one explicit run-local SVDB
path. This preserves the stronger output-isolation requirement without
requiring mutable GUI metadata. The next action remains one foreground
exact-GDS LVS retry on the unchanged Position artifacts. No DRC rerun or new
template-discovery stage is authorized.

### P09-R16 Position Exact-GDS LVS Auxiliary-CDL Reference Stop

The next foreground attempt ran on 2026-07-20 from exact commit
`98a616c30246f457f0f105e91868a9213825dc96`. Its fresh diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_execution_20260720_152848
```

Every inherited density, package, source, scaffold-byte, scaffold-semantic,
and foundry-reference gate passed. Replay also completed and proved the exact
Position GDS, canonical source, package JIHD CDL, Position tops, package-local
outputs, and newly materialized SVDB path:

```text
TEMPLATE_IDENTITY_GATE_RC=0
TEMPLATE_SEMANTIC_GATE_RC=0
PATCH_RC=0
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
SCHEMATIC_CDL_ACTION=ADDED_MISSING
SVDB_ACTION=ADDED_MISSING
```

The final external-reference gate then found one stale auxiliary path:

```text
MISSING=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/tx_packet_pvs_waiver_20260716_130442/pdk/xh018_D_CELLS_JIHD.cdl
ERROR: patched PVS template has missing external references
PVS_WRAPPER_RC=1
PVS_EXECUTED=NO
```

This is not a comparison-input failure. The executable control had no incoming
Spice path, and replay independently added the accepted package CDL. The mixed
Position block and TX run path identifies an auxiliary same-basename CDL
reference that was reached by the scalar top rewrite. PVS did not start, so
`PVS_LVS_STATUS=UNKNOWN` remains correct and no match or mismatch exists.

Compact evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_lvs/position_lvs_auxiliary_cdl_reference_20260720_152848_failed/
```

Replay now canonicalizes only absolute auxiliary references whose basename
exactly matches the already selected package CDL, and does so before scalar
top rewrites. The package CDL remains the sole executable comparison library;
GUI metadata never selects it. Different missing basenames remain visible to
the strict external-reference gate. Run one new foreground LVS transaction on
the unchanged Position artifacts. Do not rerun base or density DRC.

### P09-R17 Position Exact-GDS LVS Explicit Match With Post-Run Audit Stop

The auxiliary-CDL-normalized foreground transaction ran on 2026-07-20 from
exact commit `ea786a6b6f367dcf2a7e30ef1f81b38ef84b98e4`. Its immutable evidence
roots are:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_execution_20260720_155406
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810/pvs/lvs/position_exact_gds_lvs_20260720_155406
```

All inherited density, package, source, scaffold-byte, scaffold-semantic, and
foundry-reference gates passed. Replay bound the exact Position GDS SHA-256
`ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`,
canonical source SHA-256
`a5e81c21e633ae1b55d8da5c8e971997f890d9cee42dff2f6cf9f9f43cad9ffb`,
package JIHD CDL SHA-256
`5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf`,
and `spadmic_position_core` as both tops. The auxiliary CDL reference was
normalized to the package path and the strict external-reference report
contained no `MISSING` entry.

PVS executed. The wrapper, parser, and PVS process returned zero, and the raw
result report records an explicit match:

```text
PVS_WRAPPER_RC=0
PVS_TOOL_RC=0
PVS_LVS_STATUS=MATCH
LVS_NEGATIVE_MATCH_COUNT=0
LVS_POSITIVE_MATCH_COUNT=3
PVS_RESULT_EVIDENCE=.../position_exact_gds_lvs_20260720_155406/svdb/matched
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
RUN_FILE_GATE_RC=0
RUN_MANIFEST_RC=0
DIAGNOSTIC_COPY_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=0
DIAGNOSTIC_MANIFEST_RC=0
```

The top-level transaction nevertheless returned `STATUS=FAIL` and
`OUTCOME_CLASS=NOT_CLASSIFIED` because one post-run assertion was stale:

```text
STALE_EXPECTATION=SVDB_REWRITE_COUNT=1
SVDB_DIRECTORY=.../position_exact_gds_lvs_20260720_155406/svdb
SVDB_ACTION=ADDED_MISSING
SVDB_REWRITE_COUNT=0
RUN_AUDIT_GATE_RC=1
```

The accepted source scaffold has no `mask_svdb_dir`; replay adds one exact
run-local directive. No old directive was rewritten, so count zero is the
correct result. This is a post-execution audit-policy defect, not an LVS
mismatch or uncertain physical result. Rerunning PVS would add no evidence and
is not authorized.

The future execution driver now requires the exact run-local SVDB directory,
`SVDB_ACTION=ADDED_MISSING`, and `SVDB_REWRITE_COUNT=0`. A dedicated read-only
review driver, `TOP/ci/server_review_position_core_pvs_lvs_match.sh`, accepts
only the exact `15:54:06` diagnostic and run. It pins the compact report hashes,
checks the diagnostic, run, and package manifests, compares copied reports to
the immutable run, revalidates all GDS/source/CDL identities and control paths,
requires a nonempty positive evidence file, and requires zero negative match
patterns. It records `PVS_EXECUTED=NO` for the review and
`SOURCE_PVS_EXECUTED=YES` for the immutable source transaction.

Compact evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_lvs/position_lvs_match_20260720_155406_audit_stop/
```

On review `PASS`, Position has attributable exact-GDS LVS `MATCH`; base DRC
remains `PASS`; density remains `FAIL` with four OOC whole-extent coverage
rules. Event TC OOC may start immediately while density disposition proceeds
in parallel. Position promotion and signoff remain forbidden.

### P09-R18 Position LVS Match Review Raw-Control Count Stop

The first read-only match-acceptance review ran on 2026-07-20 from exact commit
`597d8f3e457b71b05bfdded450ebc8f91d4bc9e9`. Its fresh diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_match_review_20260720_161519
```

The source diagnostic and immutable run remained intact. Every report hash,
source and run manifest, package manifest, copied-report identity, explicit
match, replay, isolation, external-reference, and post-review recheck gate
passed. The review failed only this newly introduced aggregate gate:

```text
RUN_MATCH_GATE_RC=0
RUN_REPLAY_GATE_RC=0
RUN_ISOLATION_GATE_RC=0
RUN_REFERENCE_GATE_RC=0
RUN_CONTROL_GATE_RC=1
RUN_MANIFEST_RC=0
REVIEW_RUN_AUDIT_GATE_RC=1
```

The failed gate used `grep -Foc` on four full path strings in `pvslvsctl` and
required each line count to equal one. It did not scope matches to executable
PVS directives and did not emit the individual observed counts. Therefore the
specific raw literal that differed from one is unknown, and no more specific
claim is justified from the returned evidence. The already-passing replay and
isolation reports prove the exact executable GDS, Verilog, CDL, and run-local
SVDB bindings.

The corrected reviewer replaces those raw substring counts with
`audit_pvs_lvs_run_control.py`. The auditor strips comments, parses only
`layout_path`, Verilog and Spice `schematic_path`, and `mask_svdb_dir`, requires
one exact accepted value for each, records the control SHA-256 and parsed
values, and never mutates the source run. Regression coverage proves that
incidental metadata or comments cannot create a false failure and that a wrong
executable path remains a hard failure.

Compact evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_lvs/position_lvs_match_review_20260720_161519_failed/
```

The review launched no PVS process, and Event Genus correctly remained
`NOT_RUN`. Retry only the read-only review. If it records
`OUTCOME_CLASS=ATTRIBUTABLE_MATCH` and `EVENT_OOC_START_AUTHORIZED=YES`, start
Event TC Genus in the same foreground transaction. Position density debt still
blocks Position promotion and signoff.

### P09-R19 Position LVS Match Accepted Without PVS Rerun

The corrected read-only review ran on 2026-07-20 from exact commit
`b53b1fade963c6c57c6b0629ae9a4b21fdac06db`. Its diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_match_review_20260720_163037
```

The source diagnostic, immutable PVS run, package, GDS, canonical source, CDL,
positive evidence file, and every copied report retained their accepted
hashes. All independent review gates passed:

```text
REVIEW_RC=0
REVIEW_MANIFEST_RC=0
SOURCE_FILE_GATE_RC=0
SOURCE_HASH_GATE_RC=0
SOURCE_DIAGNOSTIC_MANIFEST_RC=0
SOURCE_STATUS_GATE_RC=0
RUN_COPY_IDENTITY_GATE_RC=0
RUN_MANIFEST_RC=0
PACKAGE_SHA_MANIFEST_RC=0
RUN_MATCH_GATE_RC=0
RUN_REPLAY_GATE_RC=0
RUN_ISOLATION_GATE_RC=0
RUN_REFERENCE_GATE_RC=0
RUN_CONTROL_GATE_RC=0
PACKAGE_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=0
```

The new directive-aware control audit recorded control SHA-256
`fd3f7a3647e8a7aaf5d0fbec03073d45af592bbabe0b2bca88373e84d1f1b1be`
and exactly one accepted executable value for each of `layout_path`, Verilog
`schematic_path`, Spice `schematic_path`, and `mask_svdb_dir`. Its
`ERROR_COUNT=0` resolves the prior unscoped literal-count failure.

The accepted physical result is:

```text
STATUS=PASS
RESULT=EXISTING_EXACT_GDS_PVS_LVS_MATCH_ACCEPTED
OUTCOME_CLASS=ATTRIBUTABLE_MATCH
PVS_WRAPPER_RC=0
PVS_TOOL_RC=0
PVS_LVS_STATUS=MATCH
LVS_NEGATIVE_MATCH_COUNT=0
LVS_POSITIVE_MATCH_COUNT=3
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
SOURCE_PVS_EXECUTED=YES
PVS_EXECUTED=NO
PVS_RERUN_AUTHORIZED=NO
EVENT_OOC_START_AUTHORIZED=YES
```

This acceptance does not erase other Position gates:

```text
PVS_BASE_DRC_STATUS=PASS
PVS_DENSITY_DRC_STATUS=FAIL
PVS_DENSITY_DRC_PRIMARY_RESULTS=4
DENSITY_DEBT_CLASS=OOC_WHOLE_EXTENT_MINIMUM_COVERAGE
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

Compact tracked evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_lvs/position_lvs_match_review_20260720_163037/
```

## P10 - Event Coordinator Server Closure

### P10-R01 TC Genus Accepted

Because the Position review authorized Event OOC start, Event Genus ran in the
same foreground shell transaction on exact commit
`b53b1fade963c6c57c6b0629ae9a4b21fdac06db`:

```text
EVENT_GENUS_RUN=genus_ooc_event_coordinator_20260720_163038
EVENT_GENUS_ROOT=/sim/ksabra/SPADMIC_work/genus/genus_ooc_event_coordinator_20260720_163038/event_coordinator
EVENT_ENV_RC=0
EVENT_GENUS_RC=0
```

The exact TC and boundary gate passed:

```text
STATUS=PASS
TC_TIMING_STATUS=PASS
RESULT=READY_FOR_ISOLATED_INNOVUS_OOC
TOP_MODULE=spadmic_event_coordinator
CLOCK_NAME=clk_sys
CLOCK_PERIOD_PS=6250.0
CLOCK_REGISTER_COUNT=51
EXPECTED_BASE_PORT_COUNT=30
ACTUAL_BASE_PORT_COUNT=30
EXPECTED_BIT_PORT_COUNT=63
ACTUAL_BIT_PORT_COUNT=63
UNRESOLVED_REFERENCE_COUNT=0
WNS_PS=2143.7
TNS_PS=0.0
VIOLATING_PATH_COUNT=0
MMMC_STATUS=NOT_RUN_TYPICAL_ONLY
SIGNOFF_READY=NO
POSTSYN_NETLIST_SHA256=b28454211dc5eeda84f17cc5864adcd1c15cd761a9d825e3f5a78182fe0b0ccb
POSTSYN_SDC_SHA256=c32e0a54b392017256a790ec73352d7161093c73a4360fe933083c88f7d1cb6a
ERROR_COUNT=0
```

The complete timing-intent report has zero findings in all classes. The QoR
summary records 184 leaf instances, 48 sequential instances, 136
combinational instances, cell area `5112.934`, net area `2713.204`, and total
area `7826.138`. Warning classification has zero physical or timing-risk
classes; the two retained tool warnings are `MESG-11` maximum-print-count
messages and did not invalidate the TC gate.

Compact tracked evidence is retained under:

```text
TOP/docs/server_snapshots/genus/genus_ooc_event_coordinator_20260720_163038/
```

### P10-R02 Isolated Event Innovus Transaction Prepared

`TOP/ci/server_run_event_coordinator_innovus.sh` is the only authorized next
Cadence command. It binds the exact P10-R01 source run, source commit, netlist
hash, and SDC hash; revalidates TC timing and the 30-port/63-bit boundary into
a new diagnostic; creates and post-checks a hash manifest for the complete
accepted Genus evidence set; checks the assembly portfolio; and launches one
fresh Event Innovus process.

The transaction accepts physical output only when all of these remain
separate and pass:

```text
RESULT=ABSTRACT_READY_FOR_TOP_REVIEW
TOP_RESERVATION_FIT_STATUS=PASS
ACTUAL_DIE_WIDTH_UM=237.440
ACTUAL_DIE_HEIGHT_UM=219.520
INNOVUS_DRC_STATUS=PASS
DRC_MARKER_TOTAL=0
REGULAR_CONNECTIVITY_STATUS=PASS
PG_CONNECTIVITY_STATUS=PASS
POSTROUTE_SETUP_TIMING=PASS
POSTROUTE_HOLD_TIMING=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
RUN_ARTIFACT_HASH_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
ASSEMBLY_INSERTION_AUTHORIZED=NO
FULL_TOP_PNR_AUTHORIZED=NO
```

An attributable pass authorizes only immutable Event handoff staging. Event
base DRC, density DRC, LVS, block promotion, MMMC, and signoff remain separate
future gates.

The full digital assembly remains ordered and blocked as follows:

```text
p00_tx: packet DRC debt plus strip PG/PVS closure remain
p01_position: OOC LVS accepted; density debt open; waits for promoted p00
p02_event_control: Event package staged; PVS preflight next; waits for promoted p01
p03_matrix_interface: soft guided assembly waits for promoted p02
p04_mptdc_frontend: blocked by missing final MPTDC abstracts and pin contract
p05_csr_i2c: deferred until promoted p04 and pad/control contract
```

The four TX implementation children (`event_bundle_tx`, `output_fifo`,
`ddr16_pairer`, and `ddrs2_adapter`) remain abstract-ready supporting evidence,
not additional top-level macros to duplicate in the assembly. Full-top Genus
and Innovus remain unauthorized.

### P10-R03 Event Innovus OOC Accepted

The hash-bound Event Innovus transaction ran in the foreground on 2026-07-20
from exact commit `1b922f0723112e5916107775069c767388ec500e`. Its immutable
roots are:

```text
EVENT_INNOVUS_RUN=innovus_ooc_harden_event_coordinator_20260720_173527
EVENT_INNOVUS_ROOT=/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_event_coordinator_20260720_173527/blocks/event_coordinator
DIAGNOSTIC_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/event_innovus_execution_20260720_173527
```

The driver rechecked the exact P10-R01 Genus run, source commit, netlist and
SDC hashes, TC status, 30-port/63-bit boundary, full source manifest, and
digital portfolio before launching one fresh Innovus process. It rechecked
the complete Genus source manifest after Innovus. All transaction-level gates
passed:

```text
EVENT_DRIVER_RC=0
DIAGNOSTIC_MANIFEST_RC=0
STATUS_CONTRACT_RC=0
STATUS=PASS
RESULT=EVENT_INNOVUS_OOC_ABSTRACT_READY_FOR_TOP_REVIEW
OUTCOME_CLASS=ATTRIBUTABLE_ABSTRACT_READY
EVENT_INNOVUS_RC=0
EVENT_CONSOLE_TEE_RC=0
RUN_FILE_GATE_RC=0
RUN_STATUS_GATE_RC=0
RUN_GDS_GATE_RC=0
RUN_ARTIFACT_HASH_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
DIAGNOSTIC_COPY_GATE_RC=0
EVENT_INNOVUS_TRANSACTION_STATUS=PASS
```

The accepted physical result is:

```text
ACTUAL_DIE_WIDTH_UM=237.440
ACTUAL_DIE_HEIGHT_UM=219.520
TOP_RESERVATION_WIDTH_UM=237.460
TOP_RESERVATION_HEIGHT_UM=220.000
TOP_RESERVATION_WIDTH_MARGIN_UM=0.020
TOP_RESERVATION_HEIGHT_MARGIN_UM=0.480
INNOVUS_DRC_STATUS=PASS
DRC_MARKER_TOTAL=0
MET1_MIN_AREA_MARKER_COUNT=0
ANTENNA_MARKER_COUNT=0
OTHER_MARKER_COUNT=0
REGULAR_CONNECTIVITY_STATUS=PASS
PG_CONNECTIVITY_STATUS=PASS
POSTROUTE_SETUP_TIMING=PASS
POSTROUTE_HOLD_TIMING=PASS
ROUTE_PROFILE=met1_effort
SIGNAL_ROUTE_LAYERS=MET1-MET3
PG_LOCAL_ROUTE_MODE=EXPLICIT_EXACT
PG_ROUTE_STRATEGY=EXPLICIT_EXACT
```

The raw regular and VDD/VSS special-connectivity reports each record zero
violations and zero warnings. Innovus `verify_drc` records zero violations.
The returned setup report contains 50 met paths; the worst reported setup
slack is `1.837 ns`. Hold is accepted by the independent generated status
gate, but no numeric hold summary was returned, so no hold value is invented.
This remains typical-only, non-OCV evidence.

The mapped and standard-cell-merged GDS audit and exact artifact identities
are:

```text
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
GDS_BYTES=549128
GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857
ABSTRACT_LEF_SHA256=56345986a887317f0374984b1ea8b3442ea482aeec0572614e9fd2c0b6732a14
DEF_SHA256=f9d6a927c7cecad40916cac67b8142f6fb6c6b013e3d57ab779889fd0ab21a68
ROUTED_PG_NETLIST_SHA256=0ecc571317f6beaa13c7f006ac3ecc4f1ff2a72b9655a176c0fa21e3c0a07398
```

Compact tracked evidence is retained under:

```text
TOP/docs/server_snapshots/innovus/innovus_ooc_harden_event_coordinator_20260720_173527/
```

The accepted boundary remains explicit:

```text
EVENT_HANDOFF_STAGE_AUTHORIZED=YES
EVENT_PVS_BASE_DRC_STATUS=NOT_RUN
EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN
EVENT_PVS_LVS_STATUS=NOT_RUN
ASSEMBLY_INSERTION_AUTHORIZED=NO
ASSEMBLY_BLOCKED_BY=p00_tx,p01_position
FULL_TOP_PNR_AUTHORIZED=NO
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=REVIEW_AND_STAGE_IMMUTABLE_EVENT_HANDOFF
```

Do not rerun Event Innovus. The next execution must preserve this run and
stage only its exact outputs.

### P10-R04 Immutable Event Handoff Staging Prepared

`TOP/ci/server_stage_event_coordinator_handoff.sh` is the only authorized next
server transaction. It is pinned to the P10-R03 diagnostic, Event Innovus
run, source commit, Genus commit, all four physical-output hashes, Genus
netlist and SDC hashes, and standard-cell CDL hash.

Before package creation it requires:

```text
SOURCE_DIAGNOSTIC_MANIFEST_RC=0
SOURCE_STATUS_GATE_RC=0
SOURCE_COPY_IDENTITY_GATE_RC=0
SOURCE_HASH_GATE_RC=0
PACKAGE_ABSENCE_RC=0
```

It refuses an existing package version and stages exactly:

```text
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_event_coordinator/innovus_ooc_harden_event_coordinator_20260720_173527
```

The package transaction copies the mapped/merged GDS, abstract LEF, DEF, raw
PG netlist, accepted physical reports, Genus TC gate, run manifests, and logs.
It derives a package-local canonical LVS source only by removing official
standard-cell definitions represented by the copied JIHD CDL. It then checks
source/LEF pin parity, audits the package manifest and SHA-256 inventory, and
rechecks every immutable source after staging.

An accepted staging status authorizes only preparation of a strict Event PVS
base-DRC dry-run:

```text
EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS
OUTCOME_CLASS=ATTRIBUTABLE_CANDIDATE_PACKAGE
EVENT_PVS_PREFLIGHT_AUTHORIZED=YES
EVENT_PVS_BASE_DRC_STATUS=NOT_RUN
EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN
EVENT_PVS_LVS_STATUS=NOT_RUN
PVS_EXECUTED=NO
ASSEMBLY_INSERTION_AUTHORIZED=NO
FULL_TOP_PNR_AUTHORIZED=NO
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=PREPARE_EVENT_PVS_BASE_DRC_STRICT_PREFLIGHT
```

The assembly-critical order is unchanged: TX packet-core DRC and TX-strip
PG/PVS closure must promote `p00_tx`; Position density disposition must then
permit `p01_position`; only after that can the independently qualified Event
macro and central-control soft region enter `p02_event_control`. Matrix,
MPTDC, and CSR/I2C remain later ordered phases. OOC progress is retained as
reusable evidence but does not bypass parent checkpoint promotion.

### P10-R05 Immutable Event Handoff Staging Accepted

The foreground staging transaction ran on 2026-07-21 from exact commit
`0fff3d2afb447f746c69ea946450ff6f5cdd7400`. The accepted immutable roots are:

```text
DIAGNOSTIC_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/event_handoff_staging_20260721_101249
PACKAGE=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_event_coordinator/innovus_ooc_harden_event_coordinator_20260720_173527
```

Repository attribution, source diagnostic identity, package staging, package
audit, canonical LVS-source preparation, post-staging source recheck, and both
SHA-256 manifests passed:

```text
EVENT_STAGE_RC=0
SOURCE_DIAGNOSTIC_MANIFEST_RC=0
SOURCE_STATUS_GATE_RC=0
SOURCE_COPY_IDENTITY_GATE_RC=0
SOURCE_HASH_GATE_RC=0
HANDOFF_STAGE_RC=0
HANDOFF_AUDIT_RC=0
PACKAGE_HASH_GATE_RC=0
PACKAGE_MANIFEST_GATE_RC=0
PACKAGE_SHA_MANIFEST_RC=0
SOURCE_POST_RECHECK_RC=0
DIAGNOSTIC_MANIFEST_RC=0
STATUS_CONTRACT_RC=0
PACKAGE_MANIFEST_RC=0
EVENT_HANDOFF_STAGING_TRANSACTION_STATUS=PASS
```

The package identity is exact:

```text
PACKAGE_GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857
PACKAGE_LEF_SHA256=56345986a887317f0374984b1ea8b3442ea482aeec0572614e9fd2c0b6732a14
PACKAGE_DEF_SHA256=f9d6a927c7cecad40916cac67b8142f6fb6c6b013e3d57ab779889fd0ab21a68
PACKAGE_RAW_PG_NETLIST_SHA256=0ecc571317f6beaa13c7f006ac3ecc4f1ff2a72b9655a176c0fa21e3c0a07398
PACKAGE_LVS_SOURCE_SHA256=f9ec957b23b1a229c7c2ff19309fb7463dfc5cac7e570ad1ca68ad8b08089b27
PACKAGE_STDCELL_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
```

Canonical source preparation retained one Event top, removed 52 standard-cell
module definitions represented by the official CDL, matched 65 source ports to
65 LEF pins, resolved all 52 referenced masters through the CDL, and left zero
unresolved masters. The package remains a `CANDIDATE`; no PVS process ran.

The basic qualification report still prints `UNKNOWN` for bbox parity, GDS
map/merge, and internal PG. Those are generic promotion placeholders, not
physical failures. The package separately hashes the accepted floorplan,
mapped/merged GDS, regular/PG connectivity, Innovus DRC, and setup/hold reports.

Compact tracked staging evidence is retained under:

```text
TOP/docs/server_snapshots/handoff/event_coordinator_20260720_173527/
```

The accepted boundary is:

```text
EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS
EVENT_PVS_BASE_DRC_STATUS=NOT_RUN
EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN
EVENT_PVS_LVS_STATUS=NOT_RUN
PVS_EXECUTED=NO
EVENT_PVS_PREFLIGHT_AUTHORIZED=YES
ASSEMBLY_INSERTION_AUTHORIZED=NO
ASSEMBLY_BLOCKED_BY=p00_tx,p01_position
FULL_TOP_PNR_AUTHORIZED=NO
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=PREPARE_EVENT_PVS_BASE_DRC_STRICT_PREFLIGHT
```

### P10-R06 Event PVS DRC Strict Preflight Prepared

`TOP/ci/server_preflight_event_coordinator_pvs_drc.sh` is the only authorized
next Event transaction. It binds the accepted staging diagnostic and package,
rechecks both manifests and all six package artifact hashes, and audits the
package before preparing any replay control.

The transaction parses the complete hierarchy reachable from
`spadmic_event_coordinator` in the exact staged GDS. It requires zero reachable
PAD, PIMIDE, and NOPIM geometry before accepting the OOC selector policy. It
then clones the already hash-reviewed TX GUI controls only as a cross-block
launch scaffold into two fresh, isolated run directories. The base control
contains one `#UNDEFINE DENSITY`; the density control contains one
`#DEFINE DENSITY`. Both require `POPPING`, `PIMIDE`, and `DUMMY_FILL` undefined
and `VAR_ANT_RATIO` defined.

Both helper calls include `--dry-run`. The wrapper rejects any generated PVS
stdout log, verifies replay and output isolation, checks every external
reference, rechecks all source identities, and writes a complete diagnostic
manifest. A passing result authorizes only the subsequent exact-GDS Event base
DRC execution:

```text
EVENT_STRICT_DRY_RUN_PREFLIGHT_STATUS=PASS
EVENT_PVS_BASE_DRC_EXECUTION_AUTHORIZED=YES
EVENT_PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=BASE_ONLY
PVS_EXECUTED=NO
EVENT_PVS_BASE_DRC_STATUS=NOT_RUN
EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN
EVENT_PVS_LVS_STATUS=NOT_RUN
ASSEMBLY_INSERTION_AUTHORIZED=NO
ASSEMBLY_BLOCKED_BY=p00_tx,p01_position
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=RUN_EVENT_PVS_BASE_DRC_ON_EXACT_STAGED_GDS
```

Do not start Event PVS before this preflight is returned and reviewed. Event
OOC qualification remains independent of assembly order: `p00_tx` promotion,
then Position density disposition and `p01_position` promotion, still precede
any `p02_event_control` insertion.

### P10-R07 Event PVS DRC Strict Preflight Accepted

The foreground dry-run transaction completed on 2026-07-21 from exact commit
`9223b07d86273d6e66c11c49691a8d1a2219bfd3`. Its immutable diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/event_pvs_drc_strict_preflight_20260721_104756
```

Repository attribution, staging and package manifests, all six package
artifact hashes, handoff audit, pinned PDK and seed identities, GDS hierarchy
parsing, selector applicability, both isolated dry-runs, post-preflight source
checks, and the 35-file diagnostic manifest passed:

```text
PREFLIGHT_RC=0
SOURCE_STAGING_MANIFEST_RC=0
PACKAGE_HASH_GATE_RC=0
PACKAGE_SHA_MANIFEST_RC=0
HANDOFF_AUDIT_RC=0
PDK_HASH_GATE_RC=0
SEED_IDENTITY_GATE_RC=0
GDS_LAYER_COLLECTOR_RC=0
GDS_LAYER_APPLICABILITY_GATE_RC=0
BASE_DRY_RUN_RC=0
DENSITY_DRY_RUN_RC=0
RUN_AUDIT_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
SOURCE_STAGING_POST_MANIFEST_RC=0
PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=0
STATUS_CONTRACT_RC=0
DIAGNOSTIC_MANIFEST_RC=0
EVENT_PVS_DRC_STRICT_PREFLIGHT_TRANSACTION_STATUS=PASS
```

The collector parsed all 86 structures reachable from
`spadmic_event_coordinator`. It found zero geometry and zero text on PAD 19/0,
PIMIDE 221/5, and NOPIM 46/0, so PIMIDE is not applicable to this exact OOC
GDS. Both controls bind GDS SHA-256
`837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857`.
The base has one `#UNDEFINE DENSITY`; the density variant has one
`#DEFINE DENSITY`. POPPING, PIMIDE, and DUMMY_FILL remain undefined, while
VAR_ANT_RATIO remains defined.

The applicability collector itself records `STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO`
and `PVS_REPLAY_AUTHORIZED=NO` because it only gathers evidence. The enclosing
preflight is the decision gate. After validating that evidence it records:

```text
EVENT_STRICT_DRY_RUN_PREFLIGHT_STATUS=PASS
EVENT_PVS_BASE_DRC_EXECUTION_AUTHORIZED=YES
EVENT_PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=BASE_ONLY
PVS_EXECUTED=NO
EVENT_PVS_BASE_DRC_STATUS=NOT_RUN
EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN
EVENT_PVS_LVS_STATUS=NOT_RUN
ASSEMBLY_INSERTION_AUTHORIZED=NO
ASSEMBLY_BLOCKED_BY=p00_tx,p01_position
FULL_TOP_PNR_AUTHORIZED=NO
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=RUN_EVENT_PVS_BASE_DRC_ON_EXACT_STAGED_GDS
```

Compact tracked evidence and the exact source-report hashes are retained under:

```text
TOP/docs/server_snapshots/pvs_drc/event_strict_preflight_20260721_104756/
```

### P10-R08 Event Base PVS DRC Execution Prepared

`TOP/ci/server_run_event_coordinator_pvs_base_drc.sh` is the only authorized
next Event EDA transaction. It binds the complete P10-R07 diagnostic manifest,
the exact status and control-report hashes, the accepted Event package and GDS,
the reviewed seed controls, and all external-reference hashes. It then launches
exactly one fresh base PVS DRC process in the foreground. It does not use the
dry-run option and does not invoke density DRC or LVS.

The driver keeps tool execution and physical closure separate. It accepts only
these two attributable transaction outcomes:

```text
ATTRIBUTABLE_ZERO_RESULTS:
  PVS_WRAPPER_RC=0
  PVS_TOOL_RC=0
  PVS_BASE_DRC_STATUS=PASS
  DRC_TOTAL_PRIMARY=0
  DRC_TOTAL_EXPANDED=0

ATTRIBUTABLE_NONZERO_RESULTS:
  PVS_WRAPPER_RC=8
  PVS_TOOL_RC=0
  PVS_BASE_DRC_STATUS=FAIL
  every summary count and ASCII error geometry reconciled
```

An attributable nonzero run is a successful evidence transaction but remains a
failed Event base-DRC physical gate. Any replay, output-isolation, result,
manifest, hash, or rule-analysis failure stops without rerunning PVS. In either
accepted evidence outcome, density execution remains unauthorized in this
transaction and the next gate is
`REVIEW_EVENT_BASE_DRC_AND_PREPARE_DENSITY_EXECUTION`. Event LVS, promotion,
assembly insertion, and full-top PnR remain forbidden.

### P10-R09 Event Base PVS DRC Zero Result Accepted

The authorized foreground base transaction completed on 2026-07-21 from
exact commit `e0325d688a73b261742dc70097b1059aba8e035b`. Its immutable roots are:

```text
DIAGNOSTIC_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/event_pvs_drc_base_execution_20260721_110404
RUN_DIR=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_event_coordinator/innovus_ooc_harden_event_coordinator_20260720_173527/pvs/drc/event_base_drc_20260721_110404
```

The repository, strict-preflight reports and manifest, package manifest, Event
GDS, seed controls, foundry deck, stream map, replay contract, output
isolation, run manifest, post-execution source and package identities, and the
24-file diagnostic manifest all passed. The exact physical result is:

```text
STATUS=PASS
RESULT=EVENT_PVS_BASE_DRC_ZERO_RESULTS_RECORDED
OUTCOME_CLASS=ATTRIBUTABLE_ZERO_RESULTS
PVS_WRAPPER_RC=0
PVS_TOOL_RC=0
PVS_BASE_DRC_STATUS=PASS
EVENT_PVS_BASE_DRC_STATUS=PASS
DRC_TOTAL_PRIMARY=0
DRC_TOTAL_EXPANDED=0
DRC_TOTAL_MATCH_COUNT=3
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
RULE_ANALYSIS_STATUS=NOT_APPLICABLE_ZERO_RESULTS
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=0
DIAGNOSTIC_MANIFEST_RC=0
```

PVS completed all 1290 rule checks, reported `Total DRC Results : 0 (0)`,
and finished normally. The three total matches are three consistent
report-level observations of the same zero-result tuple. They are not three
violations. Rule analysis is absent by design because there is no rule debt.

This closes only Event base DRC for GDS SHA-256
`837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857`.
Density DRC and exact-GDS LVS remain `NOT_RUN`; promotion, assembly insertion,
full-top PnR, and signoff remain unauthorized. Compact tracked evidence is
retained under:

```text
TOP/docs/server_snapshots/pvs_drc/event_base_drc_20260721_110404/
```

### P10-R10 Event Density PVS DRC Execution Prepared

`TOP/ci/server_run_event_coordinator_pvs_density_drc.sh` is the only
authorized next Event EDA transaction. It requires the exact P10-R09
diagnostic root and pins the accepted status, PVS result, replay, output
isolation, preprocessor, and external-reference report hashes. It also
rechecks the complete source diagnostic manifest, package manifest, exact GDS,
seed scaffold, foundry DRC deck, stream map, and external references before
launching exactly one fresh density PVS DRC process in the foreground.

The transaction requires one `#DEFINE DENSITY` and retains POPPING, PIMIDE,
and DUMMY_FILL undefined and VAR_ANT_RATIO defined. It accepts a report-level
zero result directly. A nonzero result is an accepted evidence transaction
only when the PVS wrapper returns its classified-result code, every total
reconciles, ASCII error geometry reconciles, and every rule is inventoried in
the same transaction. Infrastructure, replay, isolation, hash, manifest, or
classification failures stop without rerunning PVS.

The driver does not run LVS and does not authorize promotion or assembly. For
either attributable density outcome, the next gate is
`REVIEW_EVENT_DENSITY_DRC_AND_PREPARE_EXACT_GDS_LVS`. The density physical
gate is `PASS` only for `0 (0)`; an attributable nonzero transaction remains
a physical density `FAIL` with explicit rule debt.

### P10-R11 Event Density PVS DRC Classified Debt Accepted

The authorized foreground density transaction completed on 2026-07-21 from
exact commit `66ea5eb65de37387a023a77fc4239f1dfab6c6cf`. Its immutable roots are:

```text
DIAGNOSTIC_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/event_pvs_drc_density_execution_20260721_112300
RUN_DIR=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_event_coordinator/innovus_ooc_harden_event_coordinator_20260720_173527/pvs/drc/event_density_drc_20260721_112300
```

The repository, accepted base diagnostic, source and package manifests, exact
Event GDS, seed controls, foundry references, replay contract, output
isolation, run manifest, result reconciliation, post-execution identities, and
the 28-file diagnostic manifest passed. The evidence transaction and physical
gate remain deliberately separate:

```text
STATUS=PASS
RESULT=EVENT_PVS_DENSITY_DRC_NONZERO_RULE_DEBT_CLASSIFIED
OUTCOME_CLASS=ATTRIBUTABLE_NONZERO_RESULTS
PVS_WRAPPER_RC=8
PVS_TOOL_RC=0
PVS_BASE_DRC_STATUS=PASS
PVS_DENSITY_DRC_STATUS=FAIL
DRC_TOTAL_PRIMARY=4
DRC_TOTAL_EXPANDED=4
DRC_TOTAL_MATCH_COUNT=3
RESULT_COUNT_RECONCILIATION=PASS
ASCII_ERROR_GEOMETRY_RECONCILIATION=PASS
ANTENNA_RESULT_STATUS=ZERO
RULE_ANALYSIS_STATUS=PASS
DIAGNOSTIC_MANIFEST_RC=0
```

PVS completed all 1300 checks and finished normally. The four nonzero rules are
`R1M1`, `R1M2`, `R1M3`, and `R1MT`, one each for MET1, MET2, MET3, and METTP.
Each is a 30 percent area-to-EXTENT check with aggregate result bounding box
`0.000000 0.000000 237.360000 219.520000` um. They are whole-window density
coverage debt, not local minimum-area defects, and no antenna rule is nonzero.

No local polygon repair, virtual dummy fill, density rerun, or silent waiver is
authorized. The debt stays open for assembled-fill disposition or an exact
formal waiver. Compact tracked evidence is retained under:

```text
TOP/docs/server_snapshots/pvs_drc/event_density_drc_20260721_112300/
```

### P10-R12 Event Exact-GDS PVS LVS Execution Prepared

`TOP/ci/server_run_event_coordinator_pvs_lvs.sh` is the only authorized next
Event EDA transaction. It requires the exact P10-R11 diagnostic root, checks
the complete diagnostic manifest, pins the observed status, PVS-result,
preprocessor, rule-analysis, and rule-inventory hashes, and semantically
revalidates replay, output isolation, external references, and all four density
rules before execution.

The driver separately binds the immutable package manifest and these exact LVS
inputs:

```text
LAYOUT_TOP=spadmic_event_coordinator
SOURCE_TOP=spadmic_event_coordinator
GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857
LVS_SOURCE_SHA256=f9ec957b23b1a229c7c2ff19309fb7463dfc5cac7e570ad1ca68ad8b08089b27
STDCELL_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
```

It reuses the hash-reviewed TX LVS GUI controls only as a cross-block control
scaffold, writes all outputs into a fresh package-local run directory, and
launches exactly one PVS LVS process in the foreground. The corrected
directive-aware audit requires one executable GDS path, Verilog source, CDL,
and run-local SVDB path. It explicitly accepts the normal
`SVDB_ACTION=ADDED_MISSING` with `SVDB_REWRITE_COUNT=0`, avoiding the stale
post-run assertion that stopped the first Position LVS transaction.

Only an explicit `MATCH` with tool RC zero, zero negative evidence, positive
match evidence, replay and output-isolation passes, and valid run/source/package
manifests can produce `ATTRIBUTABLE_MATCH`. An explicit mismatch is recorded as
`ATTRIBUTABLE_MISMATCH` without being confused with infrastructure failure.
Neither outcome authorizes a rerun in the same transaction.

Event base DRC remains `PASS`; density remains `FAIL` with four classified
whole-extent rules. Even if LVS matches, promotion, `p02_event_control`
insertion, full-top PnR, and signoff remain unauthorized until density receives
an exact disposition and the preceding assembly phases promote.

### P10-R13 Event Exact-GDS PVS LVS Match Accepted

The authorized foreground exact-GDS LVS transaction completed on 2026-07-21
from exact commit `624ae1e2967eb66a63e3b33139c66f483e14886f`. Its immutable
roots are:

```text
DIAGNOSTIC_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/event_pvs_lvs_execution_20260721_121034
RUN_DIR=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_event_coordinator/innovus_ooc_harden_event_coordinator_20260720_173527/pvs/lvs/event_exact_gds_lvs_20260721_121034
```

The repository, complete source density diagnostic, package manifest, exact
GDS/source/CDL identities, reviewed template controls, external references,
replay contract, output isolation, executable run-control audit, run manifest,
post-execution source/package identities, and the 23-file diagnostic manifest
all passed. The exact accepted result is:

```text
STATUS=PASS
RESULT=EVENT_PVS_EXACT_GDS_LVS_MATCH_RECORDED
OUTCOME_CLASS=ATTRIBUTABLE_MATCH
PVS_WRAPPER_RC=0
PVS_TOOL_RC=0
PVS_LVS_STATUS=MATCH
LVS_NEGATIVE_MATCH_COUNT=0
LVS_POSITIVE_MATCH_COUNT=3
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
RUN_CONTROL_AUDIT_RC=0
RUN_AUDIT_GATE_RC=0
RUN_MANIFEST_RC=0
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=0
DIAGNOSTIC_MANIFEST_RC=0
```

PVS compared `spadmic_event_coordinator` against the same canonical source top
and reported `2660 insts vs 2660 insts` followed by explicit
`Run Result : MATCH`. ERC results were empty. The run-control audit proved one
exact executable GDS, one canonical Verilog source, one standard-cell CDL, and
one run-local SVDB path. The compared identities are:

```text
GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857
LVS_SOURCE_SHA256=f9ec957b23b1a229c7c2ff19309fb7463dfc5cac7e570ad1ca68ad8b08089b27
STDCELL_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
CONTROL_SHA256=2cff739bd7ea5a48d0fc62523385c3b6f4623caf3f5adc4f151b6384ce9d9740
SVDB_ACTION=ADDED_MISSING
SVDB_REWRITE_COUNT=0
```

The matched run retained the observed `NVN-13002`, `NVN-15191`, and
`NVN-13259` warnings plus
`joinNets - cell 'output_fifo_free_words_o' is not found`. They did not create
negative match evidence or prevent the explicit top-cell match; they remain
recorded warnings rather than silently discarded evidence.

This closes only the Event exact-GDS LVS gate. The independent physical tuple
remains:

```text
EVENT_PVS_BASE_DRC_STATUS=PASS
EVENT_PVS_DENSITY_DRC_STATUS=FAIL
PVS_DENSITY_DRC_PRIMARY_RESULTS=4
PVS_DENSITY_DRC_EXPANDED_RESULTS=4
EVENT_PVS_LVS_STATUS=MATCH
DENSITY_DEBT_CLASS=OOC_WHOLE_EXTENT_MINIMUM_COVERAGE
DENSITY_DISPOSITION_STATUS=REVIEW_REQUIRED_FOR_ASSEMBLED_FILL_OR_FORMAL_WAIVER
ASSEMBLY_INSERTION_AUTHORIZED=NO
ASSEMBLY_BLOCKED_BY=p00_tx,p01_position
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

Do not rerun Event Innovus, staging, DRC, or LVS. The Event OOC result is usable
as accepted evidence, but density disposition and the preceding `p00_tx` and
`p01_position` assembly promotions remain open. Compact tracked evidence is
retained under:

```text
TOP/docs/server_snapshots/pvs_lvs/event_lvs_match_20260721_121034/
```

## P11 Cumulative Soft Digital Assembly

### P11-R00 Local Flow Implementation Prepared

The p00-p03 assembly path was replaced locally on 2026-07-21 with four
cumulative fresh-from-RTL tops. This is a flow implementation record, not an
EDA result. Genus, Innovus, assembly PVS, OA insertion, and full-top PVS all
remain `NOT_RUN` for these new tops.

The canonical order is:

```text
p00_tx              spadmic_digital_assembly_v1_p00_tx
p01_position        spadmic_digital_assembly_v1_p01_position
p02_event_control   spadmic_digital_assembly_v1_p02_event_control
p03_matrix_interface spadmic_digital_assembly_v1_p03_matrix_interface
```

The implementation deliberately removes child hard-macro LEF/GDS reuse from
the p00-p03 critical path. Each phase carries the preceding RTL logic and adds
one reviewed group. p03 includes matrix OR trees, snapshot/reset controls, CFG
controls, and explicit matrix, CSR-side, and MPTDC-side boundary signals. p04
MPTDC and p05 CSR/I2C remain deferred and are not silently synthesized into
p03.

The checked-in contracts and generators are:

```text
TOP/pnr/assembly/spadmic_digital_assembly_contract.json
TOP/pnr/assembly/spadmic_digital_assembly_phases.csv
TOP/pnr/assembly/spadmic_digital_subblock_portfolio.csv
TOP/pnr/assembly/matrice5_unknown_family_policy.csv
TOP/pnr/assembly/spadmic_digital_assembly_v1.sv
TOP/pnr/scripts/process_spadmic2_assembly_audit.py
TOP/pnr/scripts/gen_spadmic_digital_assembly_v1.py
TOP/syn/scripts/collect_verilator_boundary.py
TOP/syn/scripts/validate_genus_digital_assembly_phase.py
TOP/pnr/scripts/validate_innovus_digital_assembly_phase.py
TOP/pnr/scripts/validate_digital_assembly_pvs_phase.py
TOP/pnr/scripts/validate_digital_assembly_oa_candidate.py
```

The physical contract is fixed at target utilization `0.60`, maximum local
density `0.70`, ordinary signal routing on MET1-MET3, and METTP restricted to
PG plus bounded pin access. Timing is TC-only with `clk_sys`, `clk_cfg_40m`,
and `clk_ref_40m` related to the 160 MHz root. There are no asynchronous clock
groups and no automated CDC/RDC claim.

The server sequence is split into attributable, review-stopped transactions:

```text
TOP/ci/server_audit_spadmic2_assembly_contract.sh
TOP/ci/server_preflight_digital_assembly_phase.sh
TOP/ci/server_run_digital_assembly_phase_genus.sh
TOP/ci/server_run_digital_assembly_phase_innovus.sh
TOP/ci/server_stage_digital_assembly_phase_handoff.sh
TOP/ci/server_preflight_digital_assembly_phase_pvs.sh
TOP/ci/server_run_digital_assembly_phase_pvs.sh
TOP/ci/server_prepare_digital_assembly_p03_oa_insertion.sh
TOP/ci/server_insert_digital_assembly_p03_into_spadmic2.sh
```

Each executable EDA driver launches one foreground tool action. Every accepted
root carries a SHA-256 manifest, exact source/status identity, independent
timing/connectivity/DRC/export gates, and a stop before the next action.

p00-p02 use base DRC then exact-GDS LVS; density is
`NOT_RUN_BY_POLICY`. p03 uses base DRC, density DRC, then exact-GDS LVS. A p03
density nonzero result is attributable only for the exact whole-extent set
`R1M1`, `R1M2`, `R1M3`, and `R1MT`; it remains physical debt and keeps
`OA_INSERTION_AUTHORIZED=NO`. OA preparation requires p03 base DRC `PASS`,
density DRC `PASS`, and LVS `MATCH`.

The OA path is intentionally two-stage. The first transaction opens the p03
candidate and SPADMIC2 read-only, checks candidate LEF bbox/pin parity and
full-target bbox parity, verifies unchanged source evidence, and writes
immutable backups. The second transaction may remove at most one allowlisted
p00-p03 assembly instance and create exactly one p03 instance at `(0,0) R0`.
It reports full-top GDS, base DRC, density DRC, and LVS as `NOT_RUN`; the OA
edit is only a candidate integration state.

Local unit coverage now exercises cumulative phase generation, portfolio
validation, independent Innovus gates, exact-name assembly handoff staging,
base/density/LVS classification, density-debt non-promotion, OA bbox/pin
parity, and insertion allowlisting. No Cadence executable was invoked while
preparing this record.

### P11-R01 First Read-Only OA Audit Interrupted Before Extraction

The first server attempt at commit
`675e6ea379a0317f788e83d878b6ea19f941cc0c` was interrupted manually during
Virtuoso startup/read-only traversal. The attributable failed root is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_matrice5_assembly_audit_20260722_125442
VIRTUOSO_RC=1
PROCESS_RC=NOT_RUN
SOURCE_STABILITY_RC=0
MANIFEST_RC=0
SPADMIC2_MATRICE5_ASSEMBLY_AUDIT_TRANSACTION_STATUS=FAIL
```

The console contained the standard unsupported-OS/glibc startup warnings and
context loading, followed by operator `Ctrl-C`; it did not contain processed
assembly evidence. No OA mutation was authorized, and pre/post source identity
remained unchanged. Do not use this root as an accepted audit.

Static review found that the initial SKILL extractor traversed every internal
instance and pin in `matrice5`, although the contract processor consumes only
its top terminals. The follow-up implementation restricts SPADMIC2 instance-pin
collection to the exact `SPADMIC/matrice5/layout` instance, collects only
SPADMIC2 top-level data required by the processor, and collects only matrice5
top terminals. Foreground progress markers identify each read-only stage.

### P11-R02 X-FAB Audit Launch-Directory Failure Classified

The bounded-audit retry at commit
`b037a1efa65131dcc78c78af55c8de470083ecde` entered the X-FAB `1131`
environment, but the audit wrapper changed to the Git repository before
starting Virtuoso. Virtuoso therefore loaded `/home/validmgr/ksabra/cds.lib`
instead of the generated project file under
`/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0`. The decisive evidence was:

```text
SPADMIC_OA_AUDIT_PROGRESS=OPEN_spadmic2
*WARNING* (DB-270210): dbOpenCellViewByType: library 'SPADMIC' does not exist
*Error* SPADMIC_ASSEMBLY_OA_OPEN_FAILED SPADMIC/SPADMIC2/layout
VIRTUOSO_RC=0
PROCESS_RC=2
SOURCE_STABILITY_RC=0
MANIFEST_RC=0
```

The failed diagnostic root is
`/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_matrice5_assembly_audit_20260722_131943`.
It is not accepted assembly evidence. Shell inspection text was subsequently
sent to the still-open Virtuoso SKILL prompt, producing parser warnings; none
of that input modified OA, and source pre/post identity remained unchanged.

The corrected contract uses
`xfab -p Prj_xh018 -t xh018 -m 1131 -y 2023 -v`, where `-v` prepares the
X-FAB shell without automatically starting Virtuoso. The wrapper now launches
its single foreground Virtuoso process from the generated `cds_V0` directory,
uses an absolute restore path, disconnects stdin, and requires an explicit
`virtuoso_export_status.rpt` `STATUS=PASS` plus every expected raw export before
running the processor. A zero Virtuoso process return code alone is no longer
accepted.

### P11-R03 X-FAB Launch Passed; IC23 SKILL Regex Call Rejected

The retry from exact commit
`ae90a1e0183e75e9eb4b3e5007493ec3825d1740` proved that the corrected X-FAB
launch contract works. Virtuoso started from
`/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0`, loaded the XH018 `1131` PDK,
resolved the `SPADMIC` OA library, opened `SPADMIC2/layout` read-only, and
reached the first export stage. The failed diagnostic root is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_matrice5_assembly_audit_20260723_094851
CADENCE_LAUNCH_GATE_RC=0
SPADMIC_OA_AUDIT_PROGRESS=OPEN_spadmic2
SPADMIC_OA_AUDIT_PROGRESS=WRITE_SPADMIC2_TOP_CONTRACT
```

The export then stopped on an IC23 SKILL API error:

```text
*Error* rexReplace: too many arguments (3 expected, 4 given) - ("I89" "[\t\n\r]" " " 0)
SPADMIC_OA_AUDIT_COMPLETION_STATUS=FAIL
OA_EXPORT_GATE_RC=1
PROCESS_RC=NOT_RUN
SPADMIC2_MATRICE5_ASSEMBLY_AUDIT_TRANSACTION_STATUS=FAIL
```

Only `spadmic2_instances.tsv` was partially emitted. The other required raw
exports were absent, the processor was correctly not started, and this root is
not accepted assembly evidence. The X-FAB/CDS setup warnings are not the
decisive blocker in this run.

IC23 uses a compiled regular expression followed by the three-argument
replacement call. Both the read-only audit helper and the later authorized OA
insertion helper now call `rexCompile("[\t\n\r]")` before
`rexReplace(text " " 0)`. This is a compatibility repair only; it does not
change traversal scope or authorize any OA write.

The same failed run reported unchanged `SPADMIC2` source identity but changed
`matrice5` source identity:

```text
SPADMIC2_PRE_POST_IDENTITY_RC=0
MATRICE5_PRE_POST_IDENTITY_RC=1
```

That delta is not waived or assumed to be harmless. The wrapper now writes
`spadmic2_source_delta.rpt` and `matrice5_source_delta.rpt` from the complete
pre/post hash inventories. Any nonempty or unreadable delta still fails the
source-stability gate, but future evidence identifies the exact changed files
for classification.

### P11-R04 Matrice5 Identity Delta Classified as Transient Locks

The pre/post inventories from failed root
`spadmic2_matrice5_assembly_audit_20260723_094851` were compared before any
additional Cadence run. `SPADMIC2_SOURCE_DELTA_RC=0`. The only `matrice5`
differences were removal of:

```text
layout/layout.oa.cdslck
layout/layout.oa.cdslck.RHEL30.lyoelectrosrv01.in2p3.fr.1263877
```

The hashes for `layout.oa`, `data.dm`, `master.tag`, the layout thumbnail, and
all other inventoried files were unchanged. This proves that the reported
identity failure was caused by Cadence lock cleanup, not an OA design-content
change.

Canonical source inventory policy `CANONICAL_OA_CONTENT_V1` therefore excludes
only basenames matching `.nfs*`, `*.cdslck`, and `*.cdslck.*`. These are NFS
temporary files and Cadence process-lock artifacts rather than persistent OA
source content. Every other file remains hash-bound before and after the
read-only transaction. The policy is emitted in
`source_inventory_policy.rpt`; exact pre/post delta reports remain mandatory,
and any canonical-content difference still fails the transaction.

### P11-R05 SPADMIC2 Export Passed; TOPLEVEL Library Binding Missing

The foreground retry from exact commit
`507e8e4fb916366d6caeec3512cb73dc668ddc9a` completed the bounded SPADMIC2
export, including its instance, matrix-instance-pin, and top-shape reports.
Canonical source stability also passed with both exact delta reports empty.
The attributable failed root is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_matrice5_assembly_audit_20260723_110753
SPADMIC_OA_AUDIT_PROGRESS=COMPLETE_spadmic2
SPADMIC2_PRE_POST_IDENTITY_RC=0
MATRICE5_PRE_POST_IDENTITY_RC=0
```

The next read-only open failed because the active X-FAB `cds.lib` did not
define library `TOPLEVEL`:

```text
SPADMIC_OA_AUDIT_PROGRESS=OPEN_matrice5
*WARNING* (DB-270210): dbOpenCellViewByType: library 'TOPLEVEL' does not exist
*Error* SPADMIC_ASSEMBLY_OA_OPEN_FAILED TOPLEVEL/matrice5/layout
OA_EXPORT_GATE_RC=1
PROCESS_RC=NOT_RUN
```

The on-disk library root and `matrice5` cell passed the wrapper source-file
gate, so this is a session library-definition failure rather than missing OA
content. The repeated missing `MPTDC_AXIS_CORE_V1_EB/.../abstract` warnings did
not stop the SPADMIC2 export and are retained for later contract review.

The corrected wrapper creates `audit_session.cds.lib` inside the fresh
diagnostic root. It includes the immutable X-FAB project `cds.lib` and defines
`TOPLEVEL` at `/group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL`. Virtuoso is
launched with `-cdslib` pointing to this run-local overlay. The shared project
library file and both OA sources remain mutation-forbidden and hash-checked.

### P11-R06 Self-Fast-Forward Continued the Stale Wrapper

The next invocation began while the server checkout was still at
`507e8e4fb916366d6caeec3512cb73dc668ddc9a`. The executing wrapper then pulled
exact commit `6d1cce83c52da0e166713ca1fc8329b312afff48`, but the already-running Bash
process continued the old wrapper body. The resulting failed root is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_matrice5_assembly_audit_20260723_113149
```

This root did not test the run-local library overlay. Decisive evidence is:

```text
audit_session.cds.lib=MISSING
CADENCE_SESSION_CDS_LIB=MISSING_FROM_LAUNCH_REPORT
DIAGNOSTIC_CREATE_RC=MISSING_FROM_CONSOLE
SESSION_CDS_LIB_CREATE_RC=MISSING_FROM_CONSOLE
```

The run therefore repeated the prior `TOPLEVEL`-undefined failure even though
the working tree contained the corrected file after the pull. SPADMIC2 export
again completed, canonical source stability passed, both source deltas were
empty, and no processor or OA write ran.

The wrapper now records its entry HEAD. If checkout or fast-forward changes
HEAD, it exports a one-time guard and replaces itself with the exact freshly
pulled wrapper before creating diagnostics or launching Virtuoso. A second
HEAD change during that guarded execution fails closed. Server command blocks
also pull and verify the expected commit before invoking the wrapper, avoiding
the race in normal operation.

### P11-R07 TOPLEVEL Alias Rejected; Source Bindings Process-Isolated

The fresh-wrapper retry at exact commit
`39574fa3d64ac10bc7b009e1f5a5d0beb2edd2fe` verified the wrapper SHA-256,
created the intended run-local overlay, and launched it with `-cdslib`. The
attributable failed root is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_matrice5_assembly_audit_20260723_132208
```

SPADMIC2 again opened and exported successfully. Cadence then rejected the
second logical alias for the matrix OA root:

```text
path /group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL already belongs to LIB SPADMIC
SPADMIC_OA_AUDIT_PROGRESS=OPEN_matrice5
*WARNING* (DB-270210): dbOpenCellViewByType: library 'TOPLEVEL' does not exist
*Error* SPADMIC_ASSEMBLY_OA_OPEN_FAILED TOPLEVEL/matrice5/layout
```

This proves that `TOPLEVEL` is a filesystem directory name, while the OA
library identity stored for `matrice5` is `SPADMIC`. A single Virtuoso process
cannot simultaneously map logical library `SPADMIC` to both the local
SPADMIC2 root and the historical matrix root. The processor did not run, no OA
write was authorized, and the failed root remains negative evidence.

The same run reported a canonical matrice5 pre/post delta:

```text
SPADMIC2_PRE_POST_IDENTITY_RC=0
MATRICE5_PRE_POST_IDENTITY_RC=1
```

That delta remains a separate stop gate and must be classified from
`matrice5_source_delta.rpt`; it is not waived by the library-binding repair.

The corrected audit now uses two sequential foreground Virtuoso processes.
The matrice5 process runs first with a run-local `cds.lib` that includes the
X-FAB project definitions, then applies `UNDEFINE SPADMIC` and rebinds
`SPADMIC` to `/group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL`. Only after
that role emits a passing status does the SPADMIC2 process run with the
unmodified X-FAB project mapping. Each process writes a role-specific source
identity, status report, and log. The wrapper combines identities only after
both role gates pass, then runs the contract processor. Shared `cds.lib` files
and both OA sources remain immutable and hash-bound.

### P11-R08 Matrice5 Delta Classified as Host/PID OA Cache

The exact delta from failed root
`spadmic2_matrice5_assembly_audit_20260723_132208` contained one added file:

```text
symbol/symbol.oa.lyoelectrosrv01.in2p3.fr.2486563.oacache
```

Its SHA-256,
`483b8d0c84a5ccee965cd0c85befe335e4b9ab56980874da7bedbc9161e5a019`,
is identical to the canonical `symbol/symbol.oa` file recorded immediately
before it in the inventory. The hostname and process identifier embedded in
the basename, together with byte identity to the canonical OA database file,
classify this as a process-local OA cache sidecar rather than changed design
content.

Canonical source inventory policy `CANONICAL_OA_CONTENT_V2` therefore adds
only the basename exclusion `*.oa.*.oacache`. It does not exclude arbitrary
`.oacache` files. Every canonical `.oa` file, `data.dm`, `master.tag`,
thumbnail, and any unrecognized sidecar remains hash-bound. Exact pre/post
delta reports remain mandatory, and any nonexcluded change still fails the
transaction.

### P11-R09 Process-Isolated Export Passed; P03 Reconciled, PG Still Blocked

The hash-bound foreground retry at exact commit
`37db9def5d486083172d5a0731032e231f002b7d` produced the first complete,
process-isolated OA evidence set:

```text
/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_matrice5_assembly_audit_20260723_135705
MATRICE5_EXPORT_GATE_RC=0
SPADMIC2_EXPORT_GATE_RC=0
SOURCE_STABILITY_RC=0
OUTER_MANIFEST_RC=0
PROCESSED_MANIFEST_RC=0
```

The source identity gate and exact-instance gate passed. `M182` is the only
`SPADMIC/matrice5/layout` instance. Its placed bbox is the source bbox
translated by exactly `(77.065000, 632.040000)` micrometers, with unchanged
width and height. The source and placed bboxes are:

```text
source=-51.390000 -143.716000 2035.579000 1754.869000
placed=25.675000 488.324000 2112.644000 2386.909000
```

All ten required digital families have exact index parity: 64 each for
`R/Y/B/Rz/Yz/Bz` and 44 each for `Din/Cin/Dout/Cout`. Their exported OA
direction is uniformly `inputOutput`, while the assembly JSON defines the
logical input/output direction. The processor therefore records
`OA_INPUTOUTPUT_WITH_CONTRACT_LOGICAL_DIRECTION`; this does not rewrite OA.
The same rows must remain real `PIN` geometry on the contract's ordinary
signal layers.

Process isolation necessarily leaves `spadmic2_instance_pins.tsv` empty:
logical library `SPADMIC` points to a different physical root in each
Virtuoso process. The processor now derives the 560 proxy pin shapes from the
matrix top-terminal geometry only when the exact source and placed bboxes
prove a translation-only mapping. Any nontranslation orientation, bbox
dimension mismatch, missing family, or nonpositive shape fails closed.

The 1,413 non-digital terminal names are classified by reviewed physical
evidence, not by name alone. `AVDD/DVDD/VSS` are supply drawings on
`MET2/MET3`; `SUB` and `VTUNE` are macro-owned non-digital drawings; and
`STI<0:1407>` is `PHODEF/VERIFICATION` geometry. The policy rejects those
families if their observed layers or purposes change.

P00-P02 remains independently blocked. The SPADMIC2 top contains exactly
three direct `METTP/drawing` path segments, all with `net=ABSENT`:

```text
1923.210000 166.235000 2739.435000 166.675000
314.855000 281.660000 324.855000 579.685000
198.375000 282.155000 208.375000 579.685000
```

Geometric overlaps with netted hierarchical shapes are emitted to
`mettp_overlap_candidates.tsv` as
`REVIEW_ONLY_NOT_A_PG_ANCHOR`. They do not prove VDD or VSS ownership.
`mettp_top_shape_attribution.tsv` keeps every unattributed direct METTP shape
blocking, even if other exact VDD/VSS shapes are later found. No Cadence
rerun, OA edit, Genus run, or implementation authorization follows from this
reconciliation. The next gate is exact PG-anchor attribution.

### P11-R10 Completed Evidence Root Was Truncated and Is Not Recoverable

A processor-only replay preflight on 2026-07-24 detected that the previously
complete P11-R09 root no longer matched its immutable outer manifest. A
subsequent read-only forensic pass proved that six regular files had been
truncated in place to zero bytes:

```text
processed_contract/matrice5_terminal_family_contract.tsv
raw_oa_export/matrice5_top_terminals.tsv
raw_oa_export/source_identity.tsv
raw_oa_export/spadmic2_instance_pins.tsv
raw_oa_export/spadmic2_instances.tsv
raw_oa_export/spadmic2_top_shapes.tsv
```

All six now hash to the SHA-256 of an empty payload,
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
Five files have the identical modification and change timestamp
`2026-07-24 10:08:41.631198813 +0200`; the instance report changed at
`10:08:43.335234484`, followed by the top-shape report at
`10:08:48.672346207`. The evidence root is on local read-write `ext4` mounted
at `/sim`, and no audit or processor writer was active when the forensic probe
ran. The latter observation does not identify the process responsible at the
earlier truncation time.

The manifest still records the expected pre-truncation hashes. Exact
hash-identical copies of the three SPADMIC2 reports survive in three older
diagnostic roots. The two role-specific identity reports also survive, so the
combined identity text can be reconstructed. These facts do not repair the
root: no expected-hash copy of `matrice5_top_terminals.tsv` survives, and its
exact terminal coordinates are required to derive the 560 matrix proxy pin
shapes. Rewriting the damaged files or its manifest would manufacture a new
provenance claim. The P11-R09 root is therefore retained only as negative
evidence and is prohibited as processor, P00-P02, P03, Genus, or OA-edit
input.

The audit wrapper now hardens every fresh evidence transaction before another
server run is authorized:

- resolve and invoke the disk `sha256sum` executable by absolute path;
- run a fixed-payload checksum create/check/nonmutation self-test before
  Cadence;
- create a timestamp-and-PID evidence root with exclusive directory creation,
  never `mkdir -p` reuse;
- create and verify the raw OA manifest, then seal the raw payload read-only
  before the processor;
- recheck the raw manifest after the processor and after evidence archiving;
- verify and seal the processor payload read-only before archiving, then verify
  it again after archiving;
- create and integrity-check `evidence_payload.tar.gz` plus its detached
  SHA-256;
- include nested payload manifests in the outer root manifest;
- remove all write bits recursively, then verify both root permissions and the
  outer manifest again.

Evidence preservation and audit acceptance remain separate gates. A
well-preserved run may still return the expected contract rejection while
direct METTP ownership remains unresolved. No fresh Cadence execution, Genus
run, or OA edit is authorized until the checksum probe and exact-commit
foreground wrapper retry pass their preservation gates.

### P11-R11 Fresh Evidence Capsule Passed; PG Attribution Remains the Only Entry Block

The exact-wrapper preflight and foreground retry at commit
`debaebf6b5dff5211ef0b6796f01cfd526ae6f0c` completed on 2026-07-24. The
wrapper hash was
`4e01c07945e794f291c725f5aebabdfd213f66c4aa2cbc974bd14e94fc6b7169`.
The fixed-payload `/usr/bin/sha256sum` probe passed before Cadence, the tracked
and staged trees were clean, and no audit writer was active. The fresh root is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_matrice5_assembly_audit_20260724_104441_pid30548
```

This root is accepted immutable evidence. Both process-isolated Virtuoso
exports passed, both canonical OA pre/post inventories were identical, and
the raw, processed, and outer manifests all passed independent post-run
verification. The recovery archive passed both gzip/tar traversal and detached
SHA-256 verification:

```text
SPADMIC2_MATRICE5_EVIDENCE_PRESERVATION_STATUS=PASS
EVIDENCE_ROOT_READ_ONLY=YES
RAW_MANIFEST_RC=0
PROCESSED_MANIFEST_RC=0
OUTER_MANIFEST_RC=0
ARCHIVE_HASH_RC=0
ARCHIVE_TAR_RC=0
WRITABLE_EVIDENCE_PATH=NONE
RECOVERY_ARCHIVE_SHA256=4fceb15acc3d6dc838c249d1abf2f69ed9937d88a9770b774f3b5c04c014665e
```

Audit acceptance remains a separate failed gate. The source identity and exact
`M182` instance passed. Matrix family parity, reviewed unknown-family policy,
all 560 translated proxy pin shapes, and the complete p03 interface contract
also passed. The only rejected p00-p02 entry requirement is direct PG
ownership:

```text
P03_INTERFACE_CONTRACT_STATUS=PASS
PG_ANCHOR_GATE_STATUS=FAIL
METTP_TOP_SHAPE_COUNT=3
UNATTRIBUTED_METTP_SHAPE_COUNT=3
DIRECT_METTP_ATTRIBUTION_STATUS=FAIL
METTP_OVERLAP_CANDIDATE_COUNT=0
P00_P02_CONTRACT_STATUS=FAIL
P00_P02_IMPLEMENTATION_AUTHORIZED=NO
P03_IMPLEMENTATION_AUTHORIZED=NO
NEXT_GATE=STOP_AND_RECONCILE_PG_ANCHORS
```

`PROCESS_RC=2` and wrapper `AUDIT_RC=1` are therefore the expected contract
rejection, not an extraction or preservation failure. No Genus run or OA edit
is authorized.

The processor now refuses any populated output directory before opening an
output report. It also emits `mettp_anchor_context_summary.tsv` and
`mettp_netted_shape_context.tsv` for a processor-only replay into a new sibling
root. The tracked replay driver is
`TOP/ci/server_replay_spadmic2_mettp_context.sh`; it rechecks the source
capsule and archive before and after processing, requires a new exclusive
output root, verifies its manifest, and seals it read-only. Those reports
distinguish positive-area overlap, exact boundary touch, same-layer context,
cross-layer context, and nearest supply-like nets. Every derived candidate
remains `REVIEW_ONLY_NOT_A_PG_ANCHOR`; proximity never changes the direct
exact-VDD/VSS authorization rule. The next transaction uses the sealed raw
payload above and does not start Cadence.

### P11-R12 Processor-Only METTP Context Passed; No PG Anchor Was Proven

The processor-only replay at exact commit
`daecb77e55fc931fa6b8b71ccd4a20d07d7d0869` completed on 2026-07-24
without Cadence, Genus, Innovus, or an OA edit. It consumed only the sealed
P11-R11 raw payload and wrote a new sibling root:

```text
/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_matrice5_mettp_context_replay_20260724_113950_pid69067
PROCESSOR_ONLY_METTP_CONTEXT_STATUS=PASS_EVIDENCE_READY
REPLAY_RC=0
PROCESS_RC=2
STATUS_GATE_RC=0
REPLAY_MANIFEST_PRE_SEAL_RC=0
REPLAY_MANIFEST_POST_SEAL_RC=0
REPLAY_WRITABLE_PATH=NONE
SOURCE_MANIFEST_POST_RC=0
RAW_MANIFEST_POST_RC=0
SOURCE_WRITABLE_PATH_POST=NONE
```

`PROCESS_RC=2` remains the expected rejected-contract result. Wrapper success
means that the derived review evidence is complete, manifest-valid, and
read-only; it does not mean that the PG gate passed.

No direct METTP shape has positive-area overlap, boundary contact, or
same-layer contact with any netted conductive shape. The nearest-net summary
is:

| Anchor | Geometry | Nearest netted context | Distance | Classification |
| --- | --- | --- | ---: | --- |
| 1 | horizontal, `0.440 x 816.225 um` | `I183\|VDDO_CLK_N`, `MET4/pin` | `0.420000 um` | cross-layer, separated |
| 2 | vertical, `10.000 x 298.025 um` | `I183\|PSUB_AVSS`, `MET4/pin` | `105.105000 um` | cross-layer, separated |
| 3 | vertical, `10.000 x 297.530 um` | `I183\|PSUB_AVSS`, `MET4/pin` | `107.224689 um` | cross-layer, separated |

`VDDO_CLK_N` and `PSUB_AVSS` are only supply-like lexical context. They are
not exact digital `VDD` or `VSS`, and none touches a candidate anchor.
Consequently all three rows remain
`REVIEW_ONLY_NOT_A_PG_ANCHOR`; the two visually rail-like vertical segments
cannot be assigned power or ground by shape, ordering, or proximity.

Automatic geometry classification is now exhausted. The next gate is a
reviewed chip-supply and anchor-ownership contract identifying the intended
digital power and ground domains and exact physically connected OA access
shapes. A read-only connectivity or via-provenance extraction may support
that decision, but absent-net geometry cannot authorize implementation.
Do not relabel a shape, infer `VDD/VSS` from a nearby hierarchical net, start
Genus, or edit OA.

### P11-R13 Chip PG Naming Confirmed; Exact Access Probe Prepared

The chip-domain naming question is now resolved by owner input:

```text
assembly VDD -> chip DVDD
assembly VSS -> chip DVSS
```

This answers only logical domain equivalence. It does not authorize any of the
three absent-net direct METTP shapes, select an instance pin, or define bridge
geometry. The physical blocker therefore remains narrower and measurable:
identify exact current METTP pin geometry whose terminal or connected net is
literally `DVDD` or `DVSS`, then review one pair relative to the verified
digital whitespace.

Commit-local implementation now provides one foreground read-only transaction:

```text
TOP/ci/server_probe_spadmic2_digital_pg_access.sh
TOP/pnr/scripts/probe_spadmic2_digital_pg_access.il
TOP/pnr/scripts/classify_spadmic2_digital_pg_access.py
```

The SKILL probe opens only `SPADMIC/SPADMIC2/layout` in read mode. It exports
top supply nets, top terminals, top shapes, transformed child-instance supply
pin boxes, and all direct METTP shapes. The CPU classifier binds local
`VDD/VSS` semantics to exact chip aliases `DVDD/DVSS`, rejects local-only
child pin names as chip-access proof, ranks exact candidates by evidence class
and distance to verified whitespace, and labels every result
`REVIEW_ONLY_NOT_AN_ASSEMBLY_ANCHOR`.

The server wrapper revalidates the sealed P11-R11 source capsule and detached
archive, requires the source to remain read-only, records canonical OA
pre/post inventories, seals raw evidence before CPU classification, verifies
all manifests, runs the fixed-payload checksum self-test, seals the processed
payload before archiving, creates and verifies a detached-hash recovery
archive, and seals the new root recursively. Its success means only
`PASS_EVIDENCE_READY`; it leaves Genus, Innovus, and OA edits unauthorized.

The machine-readable phase table is reconciled with this state:

```text
p00_tx=BLOCKED_BY_DVDD_DVSS_ACCESS_CONTRACT
p01_position=BLOCKED_BY_P00_REVIEW
p02_event_control=BLOCKED_BY_P01_REVIEW
p03_matrix_interface=BLOCKED_BY_P02_REVIEW
```

The p03 matrix signal contract remains proven. The next server action is only
the exact chip-PG access probe against the sealed P11-R11 root. Its reviewed
pair will determine whether the first isolated Innovus candidate uses direct
top access or explicit candidate-owned bridges to child `DVDD/DVSS` pins.
