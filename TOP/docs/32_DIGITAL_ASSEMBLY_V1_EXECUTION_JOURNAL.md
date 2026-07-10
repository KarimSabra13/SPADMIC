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
| P03 | Canonical corrected `spadmic_tx_packet_core` OA handoff and historical LVS intake | READ_ONLY_COLLECTOR_READY | OA backup, bbox/pin parity, GDS audit, read-only LVS input inventory |
| P04 | Per-block PVS closure, mismatch classification, and handoff promotion | BLOCKED_BY_P02_P03 | PVS DRC zero, explicit LVS verdict, diagnostic, hashes, promotion gate |
| P05 | Phase-A TX assembly generation and geometry gate | BLOCKED_BY_P04 | No obstacle overlap, exact placements, exact 19-net contract |
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
