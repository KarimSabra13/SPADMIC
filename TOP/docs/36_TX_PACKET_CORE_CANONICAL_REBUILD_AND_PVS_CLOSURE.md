# TX Packet Core Canonical Rebuild And PVS Closure

Status: `P03_GENUS_PASS_INNOVUS_PREFLIGHT_READY`

This runbook replaces the invalid historical `spadmic_tx_packet_core_HV` LVS
contract with a fresh canonical `spadmic_tx_packet_core` implementation. The
mapped Innovus GDS is the physical authority. OA is a derived, versioned review
copy only.

## Fixed Decisions

- PVS scope is DRC plus LVS; PEX is deferred.
- Layout and source top are both `spadmic_tx_packet_core`.
- The packet core is rebuilt from RTL through Genus and Innovus; the historical
  `_HV` GDS is evidence only.
- Active matrix-path TX source-data ports are scalar. Legacy
  `spadmic_top_v1` and `spadmic_packet_arbiter4` remain unchanged.
- Packet footprint remains `2066.960 x 366.800 um`.
- Packet and strip stream pins use one paired absolute-coordinate contract.
- Signal routing uses MET1-MET3. METTP is reserved for complete internal PG.
- PVS base DRC and density-enabled DRC must both be zero outside antenna.
- An antenna-only result may pass the PVS milestone but blocks final handoff.
- LVS passes only from an explicit report-level `MATCH`.

## P01 Scalar Source-Data Contract

The canonical manifest is:

```text
TOP/rtl/interfaces/tx_src_data_flat.csv
```

It contains exactly 64 unique source-major entries:

```text
src_data_i_s0_b0 ... src_data_i_s0_b15
src_data_i_s1_b0 ... src_data_i_s1_b15
src_data_i_s2_b0 ... src_data_i_s2_b15
src_data_i_s3_b0 ... src_data_i_s3_b15
```

`TOP/scripts/generate_tx_src_data_flat.py` writes explicit declarations and
connections into marked RTL regions. `--check` is mandatory in CI and fails on
any generated drift. This avoids simulator/synthesis include-path differences
while retaining one source of truth.

The API change is intentional for the active matrix path. Ordinary 1D buses
retain normal bracketed names. `spadmic_event_bundle_tx` reconstructs the
original 4x16 array internally, so arbitration behavior and dynamic indexing
remain unchanged.

Local evidence:

| Gate | Result |
| --- | --- |
| Manifest/generator unit tests | `4 pass / 0 fail` |
| Exhaustive scalar mapping oracle | `258 pass / 0 fail` |
| Event bundle regression | `14 pass / 0 fail` |
| TX egress core regression | `11 pass / 0 fail` |
| TX egress cluster regression | `13 pass / 0 fail` |
| Matrix top shell compile/regression | `32 pass / 0 fail` |

The mapping oracle drives every source/bit independently and compares all four
reconstructed source words. It detects aliases, source swaps, bit swaps,
duplicates, and missing connections.

## Required Server Gates

1. Run Xcelium for the same four TX regressions and matrix top compile.
2. Run fresh packet OOC Genus at 6.25 ns. Require no unresolved references,
   no unclocked sequential logic, no unconstrained paths, WNS non-negative,
   and TNS zero.
3. Generate the paired packet/strip pin guide from the new scalar netlist.
4. Run fresh packet Innovus with complete internal PG, then require regular
   and special connectivity zero, post-route setup/hold closure, and DRC zero
   outside the separately classified antenna markers.
5. Export mapped Innovus GDS with the official XH018 stream map and merged JIHD
   GDS. Do not promote an OA XStream GDS as the authority.
6. Prepare a filtered PG LVS source plus official JIHD CDL, create one fresh
   canonical GUI template, and replay it immutably for base DRC, density DRC,
   and LVS.
7. Re-pin/re-route and qualify the strip, then run the connected signal-route
   assembly smoke. Assembly PG remains a later phase.

## Staged Phase-1 Server Driver

`TOP/ci/server_run_tx_packet_canonical_phase1.sh` implements the first two
server gates as independent operator actions. It deliberately does not launch
Innovus or PVS. Run it as a child process with `bash`; its status reports are
the source of truth, and a failing child command cannot terminate the login
shell. The driver itself uses `set +e`, has no explicit `exit`, and never
advances automatically.

The command sequence is:

```bash
set +e
bash TOP/ci/server_run_tx_packet_canonical_phase1.sh init <expected-head>
bash TOP/ci/server_run_tx_packet_canonical_phase1.sh sync
bash TOP/ci/server_run_tx_packet_canonical_phase1.sh preflight
bash TOP/ci/server_run_tx_packet_canonical_phase1.sh xcelium-focus
bash TOP/ci/server_run_tx_packet_canonical_phase1.sh xcelium-full
bash TOP/ci/server_run_tx_packet_canonical_phase1.sh xcelium-report
bash TOP/ci/server_run_tx_packet_canonical_phase1.sh genus
bash TOP/ci/server_run_tx_packet_canonical_phase1.sh genus-report
bash TOP/ci/server_run_tx_packet_canonical_phase1.sh package
bash TOP/ci/server_run_tx_packet_canonical_phase1.sh status
```

Stop after every command and inspect `STEP_STATUS`. The prerequisite chain is
`sync -> preflight -> xcelium-focus -> xcelium-full -> genus`; report and
package commands may still run after a failure so that evidence can be
collected. A Genus process return code of zero means only that the tool flow
completed and wrote a netlist. It does not prove timing closure, resolved
references, clock coverage, or constraint completeness.

The active session pointer is
`/sim/ksabra/SPADMIC_work/diagnostics/tx_packet_canonical_active.env`. Each
timestamped session records:

- the objective and immutable historical-HV policy;
- exact Git HEAD and dirty-tree inventory without touching unrelated files;
- generator, local unit-test, and EDA-tool preflight results;
- five focused scalar-boundary Xcelium tests before the full regression;
- the full Xcelium summary and compact failure extraction;
- Genus command, summaries, critical reports, source-interface counts, and
  output hashes;
- a text-only evidence package that excludes large console logs and tool
  databases.

Negative operating rules:

- Do not source this driver; invoke it with `bash`.
- Do not continue because the command prompt returned. Read the corresponding
  `status/<step>.rpt` and require `STATUS=PASS` for prerequisites.
- Do not skip the five focused tests. They isolate scalar alias/order defects
  before paying for the full regression.
- Do not call Genus after a failed full Xcelium gate.
- Do not interpret `06_genus STATUS=PASS` as timing closure. Review
  `07_genus_review.rpt` and require `07_genus_gate.rpt STATUS=PASS` before
  issuing any Innovus command.
- Do not add raw console logs or tool databases to Git. Promote only reviewed
  small reports and the measured diagnosis.

Report extraction must distinguish tool failures from verification vocabulary.
Do not grep case-insensitively for bare `fail` or `error` across test tails:
passing summaries contain `0 fail`, compiler summaries contain `errors: 0`,
negative tests intentionally print `[PASS] ... error expectation`, and the TX
interface has a valid `bundle_missing_source_error_o` port. Xcelium failure
collection is restricted to FAIL/MISSING summary rows and explicit simulator
error syntax. Genus review includes the complete QoR, clock, and warning
classification reports plus focused timing-intent categories; wrapper RC alone
still cannot close the gate.

`genus-report` runs
`TOP/syn/scripts/validate_tx_packet_genus_ooc.py` after collecting the readable
evidence. The validator fails closed unless all of the following are true:

- the post-synthesis netlist and SDC are present and hashed;
- the top has exactly the canonical 64 scalar source ports and no nested top
  port names;
- unresolved references and required timing-intent problem categories are
  zero;
- `clk_sys` is 6250 ps and its clocked-register count equals the QoR
  sequential-instance count;
- WNS is nonnegative, TNS and violating-path count are zero, and the default
  path group has no paths;
- external drive/transition and output-load limitation rows are present, even
  though their nonzero values do not block physical feasibility;
- blocking warning classes are zero.

The gate intentionally emits `MMMC_STATUS=NOT_RUN_TYPICAL_ONLY` and
`SIGNOFF_READY=NO` on a pass. A passing result permits packet Innovus
feasibility; it cannot be used as a timing-signoff claim. The 2026-07-13 run
measured WNS `+845.1 ps`, TNS `0`, zero violating paths, and complete
`4407/4407` register coverage. Its 101 inputs without external
driver/transition and 52 outputs without external load remain deferred OOC
modeling limitations.

Future warning classification skips zero-valued report headings such as
`Undriven Port(s) 0`. Do not rerun an otherwise immutable Genus result solely
because an older classifier counted those words. The validator checks the
underlying blocking categories and records the legacy count explicitly.

Evidence packaging excludes its own `08_package` status and package-detail
report. This prevents a repeated package command from embedding stale hashes
for an earlier archive inside the new archive.

The accepted 2026-07-13 Phase-1 session is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/tx_packet_canonical_phase1_20260713_102822
GENUS_GATE_STATUS=PASS
GENUS_GATE_RESULT=READY_FOR_PACKET_INNOVUS_FEASIBILITY
GENUS_GATE_ERROR_COUNT=0
```

The Genus tool run remains tied to source commit `55a9f9b...`; report-driver
commit `96674eb9...` added and replayed the fail-closed validator without
modifying the netlist or SDC. Do not rerun Genus for that reporting change.

## Staged Phase-2 Packet Innovus Driver

`TOP/ci/server_run_tx_packet_canonical_phase2.sh` implements packet Innovus as
another no-auto-advance sequence. It inherits the accepted Phase-1 gate and
hashes, creates a unique run root, and never launches PVS.

Run each command separately and inspect its status before continuing:

```bash
set +e
bash TOP/ci/server_run_tx_packet_canonical_phase2.sh init <expected-head> \
  /sim/ksabra/SPADMIC_work/diagnostics/tx_packet_canonical_phase1_20260713_102822
bash TOP/ci/server_run_tx_packet_canonical_phase2.sh sync
bash TOP/ci/server_run_tx_packet_canonical_phase2.sh preflight
bash TOP/ci/server_run_tx_packet_canonical_phase2.sh innovus
bash TOP/ci/server_run_tx_packet_canonical_phase2.sh innovus-report
bash TOP/ci/server_run_tx_packet_canonical_phase2.sh diagnose
bash TOP/ci/server_run_tx_packet_canonical_phase2.sh pg-probe
bash TOP/ci/server_run_tx_packet_canonical_phase2.sh package
bash TOP/ci/server_run_tx_packet_canonical_phase2.sh status
```

The active pointer is
`/sim/ksabra/SPADMIC_work/diagnostics/tx_packet_canonical_phase2_active.env`.
The first review stop is after `preflight`. Require all of these fields before
running the expensive step:

```text
STATUS=PASS
PHASE1_GATE_STATUS=PASS
PHASE1_GATE_RESULT=READY_FOR_PACKET_INNOVUS_FEASIBILITY
PHASE1_GATE_ERROR_COUNT=0
PHASE1_INNOVUS_FEASIBILITY_READY=YES
PHASE1_SIGNOFF_READY=NO
PHASE1_MMMC_STATUS=NOT_RUN_TYPICAL_ONLY
INPUT_STATUS=PASS
HASH_STATUS=PASS
TOOL_STATUS=PASS
PLAN_STATUS=PASS
RUN_ROOT_UNUSED_STATUS=PASS
```

The run fixes ordinary signals to MET1-MET3 with `met1_effort`, reserves METTP
for explicit exact VDD/VSS stripes, and enables core-pin-only `sroute`.
Antenna repair is disabled during this deterministic first route. Nonzero
antenna markers may pass this milestone only with an explicit deferred status;
they always keep `FINAL_HANDOFF_READY=NO`. Min-area and all other DRC markers
remain blocking.

The driver also pins the core dimensions, density, route-layer indices,
XH018/JIHD library policy, scan handling, min-area repair, and DRC-safe filler
settings. This prevents environment variables left by an earlier OOC
experiment from changing the canonical run after preflight.

`timeDesign` returning successfully is not timing closure. The canonical gate
parses the generated setup and hold summary files, including gzip output, and
requires WNS greater than or equal to zero, TNS zero, and zero violating paths
for each mode. If selected-net min-area repair changes routing, only the newer
post-repair summaries are authoritative. Missing or ambiguous summaries fail
closed.

`innovus-report` is the second review stop. It requires the wrapper result and
canonical gate to pass with `READY_FOR_PVS_CANDIDATE`, then copies compact
connectivity, DRC classification, GDS audit, measured timing, and hash evidence
into the diagnostic session. This result authorizes only the later packet PVS
preflight; it is not PVS, MMMC, antenna closure, or signoff.

When that gate fails, run `diagnose` instead of starting another route. It
parses only the completed run's text artifacts and abstract LEF. After review,
`pg-probe` restores `05_postroute_export` once in one fresh Innovus process and
runs report/query commands only. The probe never edits or saves the design.

## P02 Paired Physical Contract

The canonical interface file is:

```text
TOP/pnr/interfaces/tx_packet_strip_pin_contract.csv
```

It contains 19 rows in this order: valid, ready, flush, then data bits 0 through
15. Packet pins are north MET3 pins; strip pins are south MET3 pins. Both local
X columns are identical and both assembly origins are `61.980 um`, so every
link has zero intended X displacement. The first center is `100.800 um`, the
pitch is `100.800 um`, and the last center is `1915.200 um`.

The generated packet plan also consumes the P01 scalar manifest. It cannot
emit a `src_data_i[i][j]` physical port without failing local tests. The strip
plan combines the paired south assignments with the existing DDRs2-derived
north assignments in one guided-pin Tcl file.

The assembly generator no longer forces packet `MY`. It evaluates R0 and MY
from transformed LEF rectangles and minimizes crossings, maximum X delta, then
total X delta. New exact-coordinate LEFs select R0/R0; historical geometry can
still select MY/R0 when that is objectively cleaner.

## P02 Internal PG Contract

Fresh packet and strip runs enable `explicit_exact` local PG:

1. Create VDD/VSS north terminals on METTP.
2. Reuse those snapped terminal centers for explicit METTP `add_shape` paths.
3. Start VDD on the first VDD followpin row and VSS at the JIHD half-row offset.
4. Stitch only `corePin` objects with `sroute` and geometry checking.
5. Create PG before ordinary MET1-MET3 signal route.
6. Require detailed special connectivity, regular connectivity, and Innovus
   DRC independently.
7. Stream out with official map plus merged JIHD GDS and require the audit.

The corrected legacy `addStripe` formula subtracts the core-left margin before
forming `-start_offset`. This correction is retained even though TX uses
`add_shape`, because the old formula caused the measured 10.080 um displacement.

Local evidence is limited to deterministic generation, Python tests, shell
syntax, and static fail-closed checks. The first server result is recorded
below. PVS DRC, density qualification, LVS, MMMC, and final antenna closure
remain unverified.

## P03 Packet Innovus R1 Measured Evidence

Status: `REVIEW_REQUIRED_DIAGNOSTIC_STAGED`

The canonical packet run executed at repository head
`aae354384ff5cb354132954ec53dba5904c24838`:

```text
SESSION_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/tx_packet_canonical_phase2_20260713_124110
INNOVUS_ROOT=/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_tx_packet_core_canonical_20260713_124110
INNOVUS_TOOL_RC=0
CANONICAL_GATE_STATUS=FAIL
CANONICAL_GATE_RESULT=REVIEW_REQUIRED
PVS_STATUS=NOT_RUN
```

The run is not a broad routing failure. The following independent gates are
measured clean:

```text
REGULAR_CONNECTIVITY_STATUS=PASS
SETUP_WNS_NS=0.169
SETUP_TNS_NS=0.000
SETUP_VIOLATING_PATH_COUNT=0
HOLD_WNS_NS=0.209
HOLD_TNS_NS=0.000
HOLD_VIOLATING_PATH_COUNT=0
GDS_FILE_STATUS=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
GDS_BYTES=16230970
GDS_SHA256=e4d83514ed2014e28cce911703f4befab897762edd2f96c58bc5473eb0c74dba
```

The actual blockers are separate and must not be collapsed into one status:

1. `PG_CONNECTIVITY_STATUS=FAIL` even though `SROUTE_PG=PASS`. The command
   executed, but the VDD/VSS special-net graph is not closed. Exact component
   geometry and marker coordinates were not captured by the normal report.
2. Seven MET1 minimum-area markers remain on `n_9705`, `n_9709`, `n_9725`,
   `n_9733`, `n_9736`, `n_9744`, and `n_9747`. The selected-net repair ran and
   post-repair timing is clean, but its physical result is still
   `REVIEW_REQUIRED`.
3. All 19 packet north stream pins are uniformly `+0.280 um` from the canonical
   X centers. The first pin is `101.080` instead of `100.800`; the last is
   `1915.480` instead of `1915.200`. This equals half the configured `0.56 um`
   grid. The generated command requested every canonical center directly and
   every emitted rectangle moved by the same half-grid amount, establishing a
   deterministic command-reference mapping rather than random pin placement.
4. Twenty-nine antenna markers remain. They are accepted only as the explicit
   intermediate status `DEFERRED_FINAL_HANDOFF_BLOCKED`; they are not why this
   milestone failed, and they still block final handoff.

The canonical pin CSV and validator remain unchanged. Do not normalize the
observed `+0.280 um` drift into the contract: packet and strip were deliberately
specified at identical local X centers for R0 assembly. The correct repair is
to map the requested center to the Innovus command coordinate and then verify
the emitted LEF center.

The next two gates are deliberately non-destructive:

- `diagnose` hashes and compares the pin plan, generated assignment Tcl,
  abstract LEF, PG report, repair ledger, and pre/post/final marker TSVs;
- `pg-probe` restores the final checkpoint once in a fresh Innovus process and
  captures detailed special connectivity, PG terminals, special-wire topology,
  and connectivity markers with `DESIGN_MODIFICATION=NOT_RUN`.

The first analyzer replay exposed a report-schema defect: its top-level
`STATUS=PASS` was shadowed by an unqualified repair-ledger
`STATUS=REVIEW_REQUIRED`, so the driver stopped before the probe. That stop was
correctly fail-closed and launched no Innovus process. Repair fields are now
namespaced as `REPAIR_*`, and the prerequisite reads `DIAGNOSIS_STATUS`.

Do not rerun Xcelium, Genus, packet Innovus, or PVS before these reports are
reviewed. Do not reuse this Innovus root for a modified candidate, do not scan
helper X coordinates blindly, and do not treat command success or mapped GDS
success as connectivity/DRC closure.

### P03-R1 Restore-Only Probe Result

The read-only probe completed from `05_postroute_export` in one fresh Innovus
22.33 process. It made no design change and produced:

```text
RESTORE_DESIGN=PASS
DESIGN_MODIFICATION=NOT_RUN
VERIFY_SPECIAL_REPORT=PASS
SPECIAL_CONNECTIVITY_VIOLATION_COUNT=4
VDD_SWIRE_COUNT=40
VSS_SWIRE_COUNT=40
```

All four special-connectivity findings belong to VDD. VSS has no open
component. Three VDD findings are full-width horizontal row components:

```text
{10.080 125.000 2056.880 128.120}
{10.080 133.960 2056.880 137.080}
{10.080 277.320 2056.880 280.440}
```

The fourth is the aggregate disconnected VDD network box:

```text
{10.080 9.680 2056.880 366.240}
```

The probe's marker count is `40`, but that does not mean 40 PG failures. It is
the existing `7` minimum-area plus `29` antenna DRC markers plus the `4` VDD
connectivity markers created by the explicit connectivity check. Keep these
classes separate.

This topology matches the earlier strip symptom closely enough to reject more
helper-X scans or another local `sroute`, but not closely enough to copy a
repair blindly. The strip helper method was coordinate invariant, and the
MPTDC history also proves that accepted `editPowerVia` commands can still fail
downstream connectivity. The next method is therefore a bounded trial, not a
canonical-flow edit.

### R2 Changes and Trial Contract

The paired stream center contract remains `100.800..1915.200 um`. Generated TX
guided-pin commands now carry a separate `assign_x_um` and subtract exactly
`0.280 um`; for example, target center `100.800` is issued to Innovus as
`editPin -assign {100.520 ...}`. The canonical validator continues to check the
emitted LEF center against `100.800`. Do not weaken it to `101.080`.

`pg-analyze` consumes only the probe text and must correlate each VDD row box
with an actual horizontal MET1 special wire and the vertical METTP VDD stripe.
It emits bounded intersection windows. If any row lacks that overlap, or if a
VSS row is open, the trial is blocked.

Innovus 22.33 emits the special-connectivity total in two observed forms:
`Verification Complete : N Viols` and
`N Problem(s) (IMPVFC-200): Special Wires`. The analyzer accepts either form,
reports its provenance, and requires agreement when both are present. The
first packet replay proved all three geometric overlaps but stayed blocked
solely because the detail report used the second form before parser support was
added. Do not reinterpret `UNKNOWN` as zero or bypass the count-consistency
gate.

The corrected replay resolved count `4` from the `IMPVFC-200` summary, matched
the four VDD connectivity markers, kept VSS at zero, and authorized exactly one
isolated `via-only` trial. Its three bounded windows are `{515.200 126.160
518.560 126.960}`, `{515.200 135.120 518.560 135.920}`, and `{515.200 278.480
518.560 279.280}`. Authorization is method-specific and in-memory only; it is
not physical closure or permission to run PVS.

`pg-help` starts Innovus with no design loaded and requires installed help for
`editPowerVia`. `pg-via-trial` then supports two separately isolated methods:

1. `via-only`: `setViaGenMode -area_only 1`, then one direct MET1-to-METTP
   `editPowerVia -exclude_stack_vias 0` call in each proven overlap window.
2. `patch-stack`: bounded VDD MET2/MET3 `add_shape` rectangles followed by the
   adjacent via pairs. Run this only in a new process after `via-only` is
   rejected.

The direct-stack correction comes from the installed 22.13 manual captured by
the 22.33 executable. The previous adjacent-only hypothesis was not run for the
packet and is now rejected because the SWIRE probe showed zero VDD MET2/MET3
special wires. Older MPTDC adjacent commands had also returned PASS without
closing connectivity. The driver refuses to restore a design unless the
captured manual contains both `-area_only 1` and `-exclude_stack_vias`.

Neither mode saves a checkpoint or exports DEF, LEF, GDS, or netlist data.
Method validation requires all commands to complete, post-trial special
connectivity zero, regular connectivity zero, and post-trial DRC no greater
than the pre-trial count. A PASS means only
`PG_VIA_METHOD_VALIDATED_NOT_CANONICAL`; it does not authorize PVS.

The seven MET1 minimum-area markers are a separate unresolved method failure.
All seven have identical `0.38 x 0.28 um` geometry, area `0.1064 um2`, below
the required `0.2020 um2`. The old repair deleted all seven areas, selected all
seven nets, and ran `globalDetailRoute -select`, `detailRoute -select`, and
`ecoRoute -fix_drc` without command errors. The same seven markers returned.
Do not repeat that delete-and-reroute sequence; it deterministically recreates
the illegal access stubs. A later minimum-area trial needs local wire-context
evidence and a different construction method.

### P03-R9 Direct-Stack Result And R5 Diagnostic Gate

The authorized direct MET1-to-METTP trial closed special connectivity from
four violations to zero and kept regular connectivity at zero. It failed the
independent DRC gate: the seven existing MET1 minimum-area markers remained,
while six MET2 shorts, two MET2 spacing markers, three VIA2 cut-shorts, one
VIA2 cut-spacing marker, and six MET3 shorts were added. The total changed
from seven to 25.

Therefore the method is topology-correct but geometry-rejected. Command PASS,
special-connectivity zero, and the prior positive timing result do not waive
the DRC increase; timing was not rerun for this rejected in-memory geometry.
The in-memory result was not saved or exported, and it is not a PVS source.
`patch-stack` is blocked because its added MET2/MET3 shapes would target layers
already carrying the new conflicts.

The next server action is `pg-via-drc-probe`. It uses a new immutable
diagnostic root, restores the same source checkpoint once, replays the same
three direct stacks, and dumps the DRC marker database immediately before and
after. Its analyzer requires exact replay of the reviewed `4 -> 0` special,
`0 -> 0` regular, and `7 -> 25` DRC tuple. It also requires all seven baseline
markers to remain equivalent at the marker-signature level and exactly 18 new
markers to account for the DRC delta. Diagnostic PASS does not validate a
repair; it only supplies the geometry needed to choose the next isolated
experiment.

The first Step 09 attempt did not reach a via command. Its baseline check
incorrectly compared `verify_drc=7` with raw `top.markers=40`; the latter also
contained 29 retained antenna and four retained connectivity markers. The R2
probe records raw and excluded counts separately and compares only the
non-antenna, non-connectivity TSV with the DRC report. It also exits Innovus
explicitly on any guard failure, rather than leaving a `-nowin` command prompt
alive. The failed Step 09 root remains immutable, and the corrected run uses
Step 10 plus `_drc_probe_r2`.

## P03 Canonical PVS Source And Replay

Immutable staging now preserves `<top>.innovus.pg.v` and derives
`<top>.lvs.pg.v`. Only module definitions listed as `.SUBCKT` in the official
JIHD CDL are removed; instances remain. The package includes its exact CDL copy
and hashes. Source preparation requires VDD/VSS, no nested top dimensions, and
exact expanded top-port parity with the canonical LEF.

PVS replay requires actual occurrences of all template GDS, source, CDL, and
top values before replacement. It then verifies the patched run names the
canonical paths and tops. Specific artifact paths are patched before template
root relocation; reversing that order was proven to invalidate exact path
replacement.

DRC is executed twice from immutable clones: `--variant base` forces DENSITY
undefined, and `--variant density` forces it defined. LVS is a third immutable
run and passes only on an explicit report-level `MATCH`. See
`TOP/docs/37_PVS_CANONICAL_SOURCE_AND_REPLAY_CONTRACT.md` for the full ledger.

## P04 Canonical OOC Candidate Gate

`validate_tx_canonical_ooc.py` runs automatically after Innovus and the mapped
GDS audit for packet and strip. It requires:

- exact expected macro name and footprint;
- all 19 stream pins on MET3 at the canonical X coordinates;
- all 64 packet source scalar pins and no nested LEF name;
- VDD/VSS pins on METTP with POWER/GROUND use;
- Innovus DRC, regular connectivity, and special PG connectivity PASS;
- both explicit PG shapes and `sroute` PASS;
- post-route setup and hold summaries with nonnegative WNS, zero TNS, and zero
  violating paths;
- DEF/LEF/GDS/PG-netlist exports present;
- official map and JIHD merge audit PASS.

The current milestone permits nonzero antenna markers only when
`SPADMIC_TX_ALLOW_ANTENNA_DEFERRED=1` (the wrapper default). The gate then emits
`ANTENNA_MILESTONE_STATUS=DEFERRED_FINAL_HANDOFF_BLOCKED` and always keeps
`FINAL_HANDOFF_READY=NO`. Set the variable to `0` for the later antenna-clean
candidate. This is a visible debt, not a waiver.

Immutable staging with `--qualification-profile canonical_tx` requires the
gate report to be `PASS` and `READY_FOR_PVS_CANDIDATE`. File presence alone is
no longer enough to enter PVS.

## Negative Command Ledger

- Do not flatten with `i+j`; use the explicit source/bit names above.
- Do not change 1D buses merely because the old layout had zero recognized
  pins.
- Do not rerun Genus from the old netlist after changing the RTL boundary.
- Do not reuse the `_HV` PVS template without canonical top, CDL, and pin-set
  checks.
- Do not export if regular or special connectivity is non-zero.
- Do not infer DRC clean from router transcript or LVS match from process RC.
- Do not infer timing closure from `timeDesign` command success; parse WNS,
  TNS, and violating-path counts from the authoritative summary.
- Do not claim the P02 implementation is physically clean from local generator
  tests; only the server connectivity and DRC reports can establish that.
- Do not force MY after the paired pin contract; use the measured orientation
  score from the actual LEFs.
- Do not allow mapped streamout without the JIHD `-merge` audit.
- Do not run multiple candidate `restoreDesign` operations in one Innovus
  process; isolate candidates when exploration is required.
- Do not let an antenna-deferred milestone silently become final handoff; the
  deferred status must remain visible until targeted repair and PVS replay.

## P03 Step 10 Marker Result And Constrained Candidate

The Step 10 replay passed as evidence capture and rejected the default physical
method. It preserved all seven baseline DRC signatures and found exactly 18
new markers: MET2 short 6, MET2 spacing 2, MET3 short 6, VIA2 cut-short 3, and
VIA2 cut-spacing 1. The row distribution is 6, 9, and 3. Existing signal-net
names in every marker prove that the generated intermediate stack footprint,
not stripe X or missing topology, is the immediate blocker.

The next gate uses the same direct stack and areas with explicit
`-via_rows 1 -via_columns 1`. It is a single process-isolated multiplicity
trial, not an X sweep or a canonical rerun. Its analyzer independently checks
the immutable baseline tuple, raw-marker accounting, filtered marker sets,
special/regular connectivity, and the trial's own PASS/FAIL classification.
Even a physically clean result is labeled `VALIDATED_NOT_CANONICAL` and stops
with no save/export. `patch-stack`, canonical Innovus replay, staging, and PVS
remain blocked pending review of the Step 11 report.

## P03 Step 11 Result And Step 12 Pre-CTS PG Candidate

Step 11 rejected the 1x1 post-route method with a coherent evidence PASS. It
closed special connectivity `4 -> 0` and kept regular connectivity `0 -> 0`,
but DRC changed `7 -> 22`. The only improvement over the default stack was the
removal of three VIA2 cut-short markers. All MET2/MET3 signal and CTS
collisions remained. The via syntax is usable; the insertion milestone is not.

Step 12 is a new full Innovus candidate, not a mutation of the Step 11 trial.
It preserves the accepted packet floorplan, pin contract, MET1-MET3 signal
policy, explicit METTP stripes, Genus netlist/SDC, and all three row windows.
The only behavioral change is opt-in pre-CTS PG construction:

1. Place standard cells.
2. Build explicit PG stripes and run core-pin `sroute`.
3. Add three bounded direct stacks with 1x1 multiplicity.
4. Require zero special-connectivity and zero DRC violations before CTS.
5. Run CTS, filler, ordinary route, timing, final DRC/connectivity, and export.
6. Classify the isolated candidate and stop without immutable PVS staging or
   PVS execution. Run-local exports and the run-ID handoff copy remain
   candidate evidence only.

`PG_CLOSED_MIN_AREA_REMAINS` is a useful but non-clean outcome: it proves the
PG stage-order hypothesis while leaving the seven independent MET1
minimum-area stubs as the next blocker. Only
`READY_FOR_PVS_PREFLIGHT` plus operator review can authorize a separate PVS
preflight gate. Neither outcome is final handoff or signoff.

## P03 Step 12 Result And Step 13 Post-Filler Restitch Candidate

Step 12 rejected the strict pre-CTS milestone while proving the stage-order
hypothesis geometrically. The bounded 1x1 stacks produced zero DRC violations,
but special connectivity found 156 `IMPVFC-94` dangling endpoints. The count
equals two endpoints across the 39 VDD and 39 VSS MET1 row wires; no terminal,
disconnected-component, short, or DRC class accompanied it. The flow stopped
before CTS, so missing final reports and exports are expected consequences,
not independent failures.

Step 13 is a fresh immutable candidate with two explicit gates:

1. Pre-CTS: exact `156 IMPVFC-94`, zero other connectivity classes, and zero
   DRC may advance as `EXPECTED_DANGLING_ONLY`.
2. Post-filler: rerun only core-pin `sroute`, then require zero special
   connectivity and zero DRC before ordinary MET1-MET3 routing.

The expected count and restitch behavior are opt-in environment values and are
recorded in the run manifest. A changed pre-CTS tuple fails closed. A failed
post-filler gate stops before signal routing. A completed candidate still
passes through final DRC, regular/PG connectivity, timing, export, stream-map,
and canonical-gate classification, with immutable staging and PVS remaining
separate operator-reviewed steps.

## P03 Step 13 Result And Step 14 Stage Attribution Probe

Step 13 reached the post-filler milestone at commit
`e17128ab5f2b007a8eeaee5f06e6fb054d5fd7a3`. Its direct-via setup and
pre-CTS milestone passed exactly as designed: five commands passed, the 156
special-connectivity violations were all expected `IMPVFC-94` dangling
endpoints, and DRC was zero. The post-filler core-pin `sroute` then closed
special connectivity to zero but left 165 DRC violations. This rejects the
candidate before signal route, export, staging, and PVS.

Step 14 reuses no exported candidate and changes no source run. It restores
only Step 13's `03_cts` checkpoint in a fresh process, measures the post-CTS
state, adds the exact canonical fillers in memory, and measures the
post-filler/pre-restitch state. Marker-database accounting excludes retained
antenna/connectivity classes and requires the filtered TSV count to equal the
authoritative `verify_drc` count at each stage.

The analyzer combines those two measurements with the immutable Step 13 tuple:

```text
pre-CTS DRC                     = 0
post-restitch special           = 0
post-restitch DRC               = 165
```

It reports one of `CTS_STAGE_INTRODUCES_DRC`,
`FILLER_STAGE_INTRODUCES_DRC`, or
`POST_FILLER_SROUTE_INTRODUCES_DRC`. In the last case it also distinguishes a
redundant restitch from an electrically required but physically destructive
restitch. Step 14 is evidence-only: `POST_FILLER_SROUTE=NOT_RUN`,
`SAVE_DESIGN=NOT_RUN`, `EXPORT=NOT_RUN`, and `PVS=NOT_RUN`. Its PASS status
means the stage was classified coherently, not that the block is physically
clean or ready for handoff.

## P03 Step 14 Result And Step 15 VIA1 Text Classification

Step 14 completed at report-driver head
`2e03ac5bf082baccfaf309b4886e1b26a36908bc`. The post-CTS checkpoint already
contained a captured 1000-marker VIA1 DRC class. Adding the canonical filler
set left every DRC signature unchanged, so the filler stage is exonerated for
that class. In the same in-memory run, filler insertion alone changed special
connectivity from 154 violations to zero. No post-filler `sroute` was run.

The rounded count has bounded semantics: both `verify_drc` and the filtered TSV
contain 1000 entries, proving at least 1000 violations but not proving capture
completeness or an exact total of 1000. The later Step 13 count of 165 belongs
to a changed geometry state and cannot be compared as a direct delta. The 239
regular-connectivity findings are also pre-signal-route observations, not a
final route-connectivity gate.

Step 15 performs only existing-text-artifact analysis. Its accepted tuple is:

```text
post-CTS:                  DRC>=1000 captured, special=154, regular=239
post-filler/pre-restitch:  DRC>=1000 captured, special=0,   regular=239
filler signature delta:    new=0, removed=0
Step 13 post-restitch:      special=0, reported DRC=165
```

The analyzer requires all 1000 captured markers to be VIA1, proves signature
identity independent of marker handles, groups subtype/rule-template/net
evidence, and emits representative messages. Its PASS result is
`POSTCTS_VIA1_CAPTURE_CLASSIFIED_NO_DESIGN_MODIFICATION`; this is a
diagnostic classification only. The next physical action remains blocked
until the VIA1 rule templates identify whether CTS via selection, cut spacing,
or another CTS-stage construction setting is responsible. Save, export,
immutable staging, canonical rerun, and PVS all remain `NOT_RUN`.

## P03 Step 15 Result And Step 16 No-Restitch Route-Through Candidate

Step 15 completed at report-driver head
`641a8f0af895d74f134e675f0193d8ccc9763233`. Every captured marker is
`VIA1/Cut_Enclosure` with `0.010 um` actual versus `0.060 um` required above.
The normalized templates split into 962 single-regular-net markers and 38
two-regular-net markers. They cover 403 unique regular nets and no special
net. The evidence is therefore not a PG-marker population.

This result refines the earlier stage attribution. The class is present in the
post-CTS checkpoint and filler does not change it, but that checkpoint is
saved before ordinary `routeDesign`. At the same point 239 regular
connectivity violations remain. These are incomplete pre-route signal
geometries, so neither the 1000 VIA1 capture nor Step 13's later 165 MET1
pre-route count is an authoritative final DRC gate. Changing CTS via rules on
this evidence would be premature.

Filler insertion independently closes special connectivity `154 -> 0`
without `sroute`. Step 16 therefore runs one fresh immutable candidate with
the already proven pre-CTS PG construction and this continuation policy:

```text
SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS=1
SPADMIC_OOC_PRE_CTS_EXPECTED_DANGLING_COUNT=156
SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH=0
```

The exact pre-CTS milestone remains fail-closed: three bounded 1x1 stack
commands, only 156 `IMPVFC-94`, no other connectivity class, and zero DRC.
After CTS and filler, the flow skips the redundant restitch and any pre-route
DRC-zero check, then runs the existing ordinary router. Acceptance still
depends on authoritative final regular connectivity, PG connectivity,
`verify_drc`, timing, exports, stream mapping, GDS audit, and canonical-gate
classification.

The Step 16 driver creates a new run-ID root and refuses to overwrite it. Its
PASS means the candidate outcome was classified coherently, not that physical
closure or signoff was achieved. Run-local exports remain evidence only;
immutable PVS staging and PVS execution remain `NOT_RUN` until a separate
operator review authorizes them.

## P03 Step 16 Result And Step 17 Final-Closure Analysis

Step 16 completed at report-driver head
`0a768d9d381cc771ffece6f6b4c3195e48af38be`. The candidate passed final
regular connectivity, final PG connectivity, setup timing, hold timing, and
the GDS file/map/merge audit. Final DRC contains only six MET1 minimum-area
markers; no PG-connectivity or other marker class remains. The earlier
post-CTS VIA1 capture was therefore incomplete pre-route geometry that normal
routing replaced.

The remaining gates are deliberately separate:

```text
FINAL_DRC_STATUS=FAIL
FINAL_MET1_MIN_AREA_MARKER_COUNT=6
FINAL_ANTENNA_MARKER_COUNT=177
STREAM_PIN_COUNT=19
STREAM_PIN_UNIQUE_DELTA_UM=-0.280000
PVS_DECISION=DO_NOT_RUN
```

Step 17, `final-closure-analyze`, is a read-only text-artifact gate over the
Step 16 block root. It requires the complete reviewed Step 16 tuple, checks
the current report-driver HEAD, and emits the final marker table and repair
ledger. For the pin mapping it independently verifies:

1. planned targets still equal the canonical contract;
2. generated assignments are uniformly `-0.280 um` from those targets;
3. emitted LEF centers equal the generated assignments.

Only that three-way proof can authorize removing the negative assignment
compensation while preserving the contract. Step 17 does not edit the
generator, modify design data, launch Innovus, save or export a design, stage
immutable PVS inputs, or run PVS. The next physical candidate must combine an
evidence-backed six-net minimum-area method with the reviewed pin-command
correction; it is not authorized automatically by a Step 17 PASS.

## P03 Step 17 Result And Step 18 Minimum-Area Second-Pass Trial

Step 17 completed at report-driver head
`278aa40b10edf61ad1a657efcbada7baaa6a676e`. It confirms that the Step 16
candidate has closed PG and regular connectivity and that only six
non-antenna DRC markers remain. The first repair pass reduced the exact MET1
minimum-area count `10 -> 6`; the six survivors all report `0.1064 um^2`
actual area against `0.2020 um^2` required area. The repair ledger contains no
selection, deletion, or route-command failure.

Step 18 reuses the final routed checkpoint only as an immutable source. The
trial contract is:

1. Start one fresh Innovus process and restore the checkpoint exactly once.
2. Require the exact baseline tuple: DRC 6, regular connectivity 0, PG
   connectivity 0, six filtered MET1 minimum-area markers, and 177 excluded
   antenna markers.
3. Run the existing area delete, DRC-wire delete, `globalDetailRoute -select`,
   `detailRoute -select`, and `ecoRoute -fix_drc` sequence on only the current
   minimum-area nets.
4. Re-run independent DRC and both connectivity checks after each iteration.
5. Accept the method only at DRC 0 with both connectivity counts still 0 and
   the antenna count still 177. Stop on no improvement, a new DRC class, or
   after three iterations.
6. Do not save, export, stage immutable PVS inputs, or run PVS.

The Step 18 driver classifies both a coherent success and a coherent rejection
as completed evidence. `STATUS=PASS` means the trial artifacts were classified
consistently; only
`METHOD_STATUS=VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY` authorizes folding the
iterative method into a fresh canonical replay.

The same Step 17 proof resolves the stream-pin mapping. Canonical targets and
contract centers already match. Generated assignments and emitted LEF centers
match each other at exactly `target - 0.280 um`. The generator compensation is
therefore set to zero while the 19 canonical centers remain unchanged. This
source correction is not applied to the immutable Step 16 checkpoint and is
validated only in a later fresh replay after Step 18 review.

## P03 Step 18 Safe Failure And Step 19 R2 Restored-Marker Guard

Step 18 completed as failed evidence at report-driver head
`9979fdf66290532731934f4b61cf4fca170dfa20`. Innovus restored the final routed
checkpoint and independently reproduced DRC 6, regular connectivity 0, PG
connectivity 0, and the exact six Step 17 minimum-area nets. It then stopped
at the baseline precondition with `ITERATION_COUNT=0`; no repair command,
save, export, immutable staging, or PVS action ran.

The only mismatch was antenna-marker representation. The source-run report
still authoritatively records 177 final antenna markers. The restored
checkpoint marker database records 21 antenna entries alongside six DRC
entries and zero connectivity entries, yielding an exact total of 27. The
restored 21 is a stability sentinel for the isolated trial, not a replacement
for the source-run 177-marker final-handoff blocker.

Step 19 uses a distinct R2 identity and enforces both contracts:

1. Step 17 must still prove `ANTENNA_FINAL_MARKER_COUNT=177`.
2. Failed Step 18 must prove the exact six-net baseline and zero iterations.
3. R2 must restore the exact marker tuple `DRC=6, antenna=21,
   connectivity=0, total=27`.
4. Every iteration must preserve restored antenna count 21, zero connectivity,
   and exact marker-database accounting.
5. The existing bounded repair sequence remains unchanged and in-memory only.

The new trial root ends in `_min_area_second_pass_trial_r2`; the Step 18 root
and copied reports remain immutable. A coherent Step 19 classification is
still not PVS authorization. A fresh canonical replay remains blocked until
the operator reviews whether R2 validates zero DRC without connectivity or
restored-marker drift.
