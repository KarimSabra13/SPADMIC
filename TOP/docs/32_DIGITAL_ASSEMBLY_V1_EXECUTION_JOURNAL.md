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
