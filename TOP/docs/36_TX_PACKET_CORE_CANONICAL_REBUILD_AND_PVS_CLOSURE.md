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
   grid and is consistent with an `editPin -assign` reference/snap effect, but
   that causal interpretation remains a hypothesis until the generated command
   and emitted rectangles are classified together.
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
