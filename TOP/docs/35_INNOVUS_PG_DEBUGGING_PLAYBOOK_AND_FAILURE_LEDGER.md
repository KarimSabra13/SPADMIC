# Innovus PG Debugging Playbook and Failure Ledger

Status: living document, updated through the canonical packet/strip rebuild implementation on 2026-07-10.

This document captures both successful techniques and negative knowledge from
the Phase-A TX work. Its purpose is to prevent later blocks from repeating
commands that were accepted by a tool but were physically ineffective, unsafe,
non-reproducible, or aimed at the wrong failure class.

The chronological evidence remains in
`TOP/docs/32_DIGITAL_ASSEMBLY_V1_EXECUTION_JOURNAL.md`. Verified Innovus command
syntax remains in `TOP/docs/34_INNOVUS_22_33_PG_ROUTING_COMMAND_NOTES.md`.

## 1. Rules That Apply to Every Later Phase

1. Separate execution, geometry, connectivity, DRC, streamout, PVS DRC, and LVS
   into independent gates. A command return code is not a physical verdict.
2. Preserve the clean source checkpoint. Never use a failed PG experiment as
   the next baseline.
3. Change one physical mechanism at a time and preserve each run under a unique
   immutable directory.
4. Capture detailed marker boxes and messages before proposing a correction.
   Counts alone identify trends, not the exact repair.
5. If candidate trials require restore, use one fresh Innovus process per
   candidate and one more fresh process for the canonical replay.
6. Do not export or promote trial geometry. Export only after special
   connectivity, marker count, regular connectivity, and DRC are all zero.
7. Treat invariant results across widely separated coordinates as evidence
   against the routing method, not as a reason to try more coordinates.

## 2. TX DDR Strip Attempt Ledger

| Attempt | Mechanism or option | Measured result | Why it behaved that way | Reuse decision |
| --- | --- | --- | --- | --- |
| P01 | Signal-only OOC PnR, PG deferred | Signal DRC 0, regular signals clean, VDD/VSS unrouted | PG was deliberately excluded to preserve the narrow signal implementation | Valid clean restore baseline |
| P02 initial | `addStripe` with `-start_from left`, `-start_offset`, one set | 9 PG violations, DRC 0 | Offset was measured from the core reference, shifting both intended centers by core-left `10.080 um`; stripes also stopped at core top | Do not reuse this offset formula |
| P02 initial | `sroute -connect {corePin blockPin}` | Command completed, but block-pin warnings and PG remained open | Top-level VDD/VSS PG terminals are not hierarchical `blockPin` objects | Do not request `blockPin` for these terminals |
| Read-only probe | Detailed special connectivity plus DB marker dump | Exact 9-marker topology captured | Distinguished boundary gaps, stripe dangles, and two missing VDD row via stacks | Reuse before every PG repair |
| P02-R2 | Exact full-height `add_shape` VDD/VSS stripes | PG reduced from 9 to 3; VSS and both north terminals closed | Explicit path geometry removed offset ambiguity and overlapped the boundary pins | Reuse for exact audited geometry |
| P02-R2 | `sroute -connect {corePin}` with geometry checks | Most rail-to-stripe stacks created; two VDD rows remained isolated | `sroute` did not create stacks on VDD rows at `135.520` and `144.480 um` | Partial success; verify every row |
| P02-R3 | Save main-PG checkpoint, restore it for each candidate in one process | All candidate rows `RESTORE_FAIL`; zero candidates evaluated | Innovus rejects a second `restoreDesign` in one process with `IMPIMEX-7031` | Never repeat restore in one process |
| P02-R4 | One fresh process per helper X and fresh P01 restore | Infrastructure worked; all 10 candidates were physically evaluated | Process isolation removed R3's orchestration failure | Reuse this candidate architecture |
| P02-R4 | Local METTP helper plus local second `sroute` | Every X produced PG=6, markers=6, regular=0, DRC=0 | The method is electrically ineffective and X-invariant; exact marker decomposition is pending | Do not expand or repeat this candidate list |
| Canonical rebuild, server pending | Fresh Genus/Innovus, common pin/stripe centers, exact `add_shape`, PG before signal route | Local generation/tests pass; no Cadence verdict yet | Removes checkpoint damage, core/die offset ambiguity, old nested source ports, and post-signal PG insertion from the experiment | Run packet first; accept only report-level zero gates |

## 3. Exact Commands and Options Tried

### 3.1 First addStripe Commands

The first attempt used one vertical METTP stripe per net:

```tcl
addStripe -nets VDD -layer METTP -direction vertical \
  -width 3.36 -spacing 3.36 -set_to_set_distance 10000.0 \
  -start_from left -start_offset 856.8 -number_of_sets 1

addStripe -nets VSS -layer METTP -direction vertical \
  -width 3.36 -spacing 3.36 -set_to_set_distance 10000.0 \
  -start_from left -start_offset 2573.2 -number_of_sets 1
```

Observed DEF centerlines were `868.560` and `2584.960 um`, exactly `10.080 um`
east of the intended PG-term centers. The `-start_offset` values were treated as
offsets from the core-left reference, not absolute die X coordinates.

Innovus also reported that the VDD/VSS core rings were incomplete and that
stripes would therefore be generated only within the core area. That explains
why the first stripes stopped at `y=170.800 um` instead of reaching north PG
pins beginning at `y=176.960 um`. This warning was physically relevant and was
not cosmetic.

Negative rule: do not pass an absolute coordinate as `-start_offset` unless the
active reference origin has been explicitly included in the calculation.

Installed help also confirmed:

- `-area` and `-extend_to design_boundary` are supported;
- they are mutually exclusive;
- `-create_pins`, `-stop_offset`, and `-number_of_sets` are supported;
- `-area` was researched but not used in the accepted main-stripe geometry;
- `-extend_to design_boundary` was researched but not used.

### 3.2 First sroute Command

```tcl
sroute -connect {corePin blockPin} -nets {VDD VSS} \
  -blockPin all -blockPinTarget stripe -corePinTarget stripe \
  -allowLayerChange 1
```

Innovus issued `IMPSR-1254` for both nets because no VDD/VSS block pins were
present. `sroute` still created followpin wiring, so command completion did not
mean all requested object classes were connected.

Negative rule: a top-level PG terminal is not automatically a `blockPin`.
Inspect the DB object class before selecting the `sroute -connect` class.

### 3.3 Exact Main Geometry Used by R2-R4

```tcl
add_shape -net VDD -layer METTP -shape STRIPE -status ROUTED \
  -pathSeg {858.480 10.080 858.480 180.880} -width 3.360

add_shape -net VSS -layer METTP -shape STRIPE -status ROUTED \
  -pathSeg {2574.880 14.560 2574.880 180.880} -width 3.360

sroute -connect {corePin} -nets {VDD VSS} \
  -corePinTarget stripe -corePinCheckStdcellGeoms \
  -allowJogging 1 -allowLayerChange 1 \
  -layerChangeRange {MET1 METTP}
```

This fixed the boundary-terminal gaps, VSS connectivity, offset error, and
dangling full-height stripe endpoints. It did not close two VDD followpin rows.

### 3.4 R4 Local Helper Method

Each fresh process tested one helper:

```tcl
add_shape -net VDD -layer METTP -shape STRIPE -status ROUTED \
  -pathSeg {<candidate_x> 126.560 <candidate_x> 153.440} \
  -width 3.360

sroute -connect {corePin} -nets {VDD} -area {<local_box>} \
  -corePinTarget stripe -corePinCheckStdcellGeoms \
  -allowJogging 1 -allowLayerChange 1 \
  -layerChangeRange {MET1 METTP}
```

Candidate order:

```text
970.480, 746.480, 1082.480, 634.480, 1194.480,
522.480, 1306.480, 410.480, 1418.480, 298.480 um
```

Every candidate returned the same tuple:

```text
PG_CONNECTIVITY_VIOLATION_COUNT=6
PG_MARKER_COUNT=6
REGULAR_CONNECTIVITY_VIOLATION_COUNT=0
DRC_MARKER_TOTAL=0
```

Confirmed conclusion: changing X does not rescue this mechanism. Do not add
more X candidates or rerun these ten coordinates with the same commands.

Inference pending detailed marker comparison: because R2 had 3 markers and R4
has 6, the helper likely failed to close the original three components and
introduced three additional helper-related components. This is not yet an
accepted root cause; the final marker reports must prove the decomposition.

### 3.5 Commands Researched but Not Selected

- `editAddRoute`: supported, but stateful and coupled to Wire Editor setup plus
  `editCommitRoute`; keep for reviewed interactive work, not default batch flow.
- `addShape`: no useful installed help entry; use documented `add_shape`.
- `createShape` and `create_shape`: no useful installed help entry for this use.
- `restore_db_stop_at_design_in_memory=0`: suggested by the Innovus error text,
  intentionally not used because it disables a reliability guard.

## 4. Verification Commands and Their Meaning

### Special connectivity

```tcl
verifyConnectivity -type special -nets {VDD VSS} -report <detail_report>
```

Use the detail report and marker TSV together. The console count alone cannot
show whether a marker is a terminal gap, disconnected special-wire component,
or dangling endpoint.

Observed classes:

- `IMPVFC-96`: terminal not connected;
- `IMPVFC-200`: special-wire pieces are disconnected;
- `IMPVFC-94`: dangling special wire, shown as `ConnectivityAntenna` markers.

### Regular connectivity

```tcl
verifyConnectivity -type regular
```

R4 remaining at zero proves that the helper experiments did not damage the
signal implementation. It does not prove PG connectivity.

### Innovus DRC

```tcl
verify_drc
```

R4 DRC zero proves that all ten helper geometries were geometrically legal. It
does not prove that vias exist or that the PG graph is connected.

## 5. Tool and Flow Errors Already Encountered

### AWK portability failure

The LEF preflight used a multiline parenthesized assignment and the server AWK
reported `unexpected newline or end of string`. Use a single-line assignment or
a portable state-machine expression. Do not assume gawk parsing extensions.

### Wrong PVS binary

Bare `pvs` resolved first to `/usr/sbin/pvs`, the Linux LVM utility, and rejected
Cadence options. Always use the explicit Cadence binary:

```text
/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs
```

### Initial GDS audit false failure

The first audit reported `gds_missing_or_too_small` and
`mapped_streamout_command_missing` although streamout completed. Two audit
assumptions were wrong:

- the generated strip GDS was legitimately smaller than the old 1 MB floor;
- `/eda/pdk/...` and `/data/pdk/...` resolved to the same installation but were
  compared lexically.

The corrected audit resolves paths, checks the approved map hash, verifies the
actual `streamOut -mapFile` command, and requires the JIHD `-merge` GDS.

### PVS template GDS hash mismatch

The historical template GDS and current corrected handoff GDS are not byte
identical. A template may provide controls and rule configuration, but its old
DRC result cannot be transferred to a different GDS hash. Rerun PVS on the
actual promoted artifact.

### Repeated restore rejection

`IMPIMEX-7031` means a second `restoreDesign` in one process is not a reliable
flow operation. A valid checkpoint does not make this safe. Use process
isolation and never disable the guard for production candidate searches.

### Unsupported DB attributes

The probe tried `shape.box` and `layerShape.rect`; Innovus issued
`IMPDBTCL-204`. Query `dbSchema` before depending on object attributes and keep
fallback queries explicit. Do not treat an empty DB query as proof of absent
geometry when the attribute itself is unsupported.

### Obsolete route report command

`reportRoute` worked but issued `IMPFP-3803`. Use `report_route` in new scripts.

### Shared-library diagnostics unrelated to this strip

The loaded MPTDC oscillator Liberty emitted `TECHLIB-704`, `TECHLIB-702`, and
LEF/Liberty PG-pin warnings. These are real library-hygiene issues, but they are
not the demonstrated cause of TX DDR strip VDD/VSS opens: this strip has no
MPTDC oscillator instance, and the errors occur during shared library loading
before the local PG commands. Do not modify MPTDC internals to repair this
strip. Also do not globally waive these messages for future designs that do
instantiate those macros.

### Other warnings and operational noise

| Message | Classification | Required response |
| --- | --- | --- |
| `The core ring ... is incomplete` | Relevant to first stripe extent | Do not assume `addStripe` reaches the die boundary without an explicit supported extent mechanism |
| `IMPPP-133` cell boundary increased around `vddi` pins | Library/instance geometry warning | Preserve in logs; confirm DRC and connectivity, but do not call it the open-row root cause without marker correlation |
| `IMPLF-200` / `IMPLF-201` missing antenna areas | Library antenna-data incompleteness | Not the current PG-open cause; retain as a separate antenna-signoff limitation |
| `Tk package not loaded` | Expected headless-tool warning | No action for `-nowin` batch diagnostics |
| `X11 forwarding request failed` during Git operations | SSH display-channel noise | Check Git return code and HEAD; do not classify as pull failure when both pass |
| Repeated tool paths in `type -a` output | PATH duplication, not multiple executions | Record the selected absolute binary and deduplicate inventory output |
| `/usr/sbin/pvs` non-root/option errors | Wrong executable | Stop and select the explicit Cadence PVS path |

## 6. Commands and Strategies Not to Retry

- Do not rerun the original `addStripe -start_offset` values.
- Do not add `blockPin` to the TX strip `sroute` command.
- Do not stop a stripe at core top when its boundary terminal begins above it.
- Do not interpret `addStripe created 1 wire` or `sroute created N wires` as a
  connectivity pass.
- Do not treat DRC zero as PG closure.
- Do not restore multiple candidate checkpoints in one Innovus process.
- Do not disable `restore_db_stop_at_design_in_memory`.
- Do not try more helper X values with the current R4 helper plus local-sroute
  method; ten widely separated values produced the same result.
- Do not run canonical export, GDS audit, PVS, staging, or promotion after a
  rejected trial. Missing parent final reports in R4 are expected fail-closed
  behavior, not missing evidence from a run that should have occurred.
- Do not invoke bare `pvs`.
- Do not reuse DRC/LVS evidence across different GDS hashes.
- Do not change the clean signal route, placement, CTS, or MPTDC internals while
  the failure remains localized to two VDD rows.

## 7. R4 Interpretation and Required Read-Only Diagnostic

R4 separates four statuses:

```text
PROCESS_ISOLATION_STATUS=PASS
CANDIDATE_EXECUTION_STATUS=PASS_10_OF_10
HELPER_METHOD_STATUS=FAIL_INVARIANT_6_MARKERS
CANONICAL_EXPORT_STATUS=NOT_RUN_BY_POLICY
```

Before R5, compare one representative trial's main and final connectivity
reports, then verify marker-class consistency across all ten trials. Required
evidence:

1. Exact six final marker boxes, layers, subtypes, and messages.
2. Whether the original three R2 markers remain after the helper.
3. Whether the helper adds new dangling endpoints or disconnected components.
4. The second `sroute` transcript, including how many wires/vias it created and
   any `IMPSR` warnings.
5. Confirmation that trials 1 and 10 have the same marker classes after
   replacing only X-dependent coordinates.

No R5 geometry should be coded until those five facts are available.

Reusable read-only extraction recipe:

```bash
set +e
R4_ROOT=<immutable-r4-run-root>
REP="$R4_ROOT/trials/trial_01_x_970p480"

cat "$REP/reports/pg_geometry_fix_status.rpt"
cat "$REP/reports/verify_connectivity_pg_main_detail.rpt"
cat "$REP/reports/verify_connectivity_pg_detail.rpt"
cat "$REP/reports/pg_connectivity_main_markers.tsv"
cat "$REP/reports/pg_connectivity_markers.tsv"

diff -u \
  "$REP/reports/verify_connectivity_pg_main_detail.rpt" \
  "$REP/reports/verify_connectivity_pg_detail.rpt"

grep -nEi \
  '<CMD> (add_shape|sroute)|sroute created|IMPSR|IMPVFC|dangling|unconnected' \
  "$REP/logs/innovus.log"

for MARKERS in "$R4_ROOT"/trials/*/reports/pg_connectivity_markers.tsv; do
  TRIAL_ROOT="${MARKERS%/reports/pg_connectivity_markers.tsv}"
  TRIAL="${TRIAL_ROOT##*/}"
  awk -F '\t' -v trial="$TRIAL" \
    'NR > 1 {print trial "\t" $4 "\t" $5 "\t" $6 "\t" $7}' \
    "$MARKERS"
done | sort
```

This recipe reads only existing reports and logs. It does not restore a design,
launch Innovus, change geometry, or create a handoff.

## 8. R5 Decision Tree

- If the original three markers remain and three helper markers are added, stop
  using a second `sroute` as the repair mechanism. Capture installed help for
  supported explicit PG-via creation or reviewed power-via editing first.
- If the two original row markers disappear but six new markers replace them,
  the helper connected the rows but broke its anchors; revise endpoint/anchor
  geometry rather than X.
- If the helper `sroute` creates zero wires or vias, the selected object class
  or area does not target the already-routed followpin rails; changing X alone
  cannot fix it.
- If marker classes vary by X, use the cleanest class as a new narrowly-scoped
  candidate only after proving why its topology differs.
- If all classes are identical, design one explicit topology repair and test it
  once before reopening any candidate sweep.

After a future P02 PASS, freeze and hash the strip handoff, run same-artifact
PVS DRC/LVS, and only then unblock Phase-A assembly. The registered packet-core
historical LVS intake remains a separate read-only P03/P04 activity.

## 9. Canonical Rebuild Rules Added After R4

The user stopped the restore-only strip repair and prioritized a canonical
packet-core LVS rebuild. This is a different experiment, not R5 continuation.

### Interface and pin contract

- The active packet source boundary is 64 scalar ports from
  `TOP/rtl/interfaces/tx_src_data_flat.csv`; do not restore
  `src_data_i[outer][inner]` at the hard-macro boundary.
- Packet north and strip south use the 19-row contract in
  `TOP/pnr/interfaces/tx_packet_strip_pin_contract.csv`.
- MET3 pin centers are identical in both local macros: `100.800 um` through
  `1915.200 um` at a constant `100.800 um` pitch.
- Both assembly origins are `x=61.980 um`, so absolute pin X is also identical:
  `162.780 um` through `1977.180 um`.
- The intended short inter-block route is vertical MET2 with MET2/MET3 vias.
  Do not spread either interface independently after generating this contract.

### Orientation

The assembly generator evaluates packet `R0` and `MY` when LEF symmetry allows
both. It minimizes, in order: crossing count, maximum absolute X delta, total
absolute X delta, then prefers R0 on an exact tie. MY is no longer mandatory.
This preserves compatibility with historical LEFs, where MY removed ordering
crossings, while selecting R0 for the new exact-X LEFs.

Negative rule: do not infer the correct orientation from pin names or visual
left-to-right order. Score transformed LEF coordinates after placement.

### PG and route ordering

For the two TX macros only, generated config enables `explicit_exact` PG. The
new sequence is placement, CTS, filler, exact PG geometry, `sroute corePin`,
then ordinary signal route. This differs from the old sequence that inserted
PG after signal routing. Signals remain constrained to MET1-MET3; METTP is the
power layer.

Negative rule: a fresh flow removes known orchestration and geometry defects,
but it does not guarantee the JIHD row graph is connected. `add_shape` PASS,
`sroute` PASS, and DRC 0 are still insufficient without special connectivity 0.

### Antenna milestone

The canonical OOC route profile is `met1_effort`, not the old
`met2_first_antenna` profile. Antenna repair is intentionally not a milestone
acceptance dependency while DRC/LVS root causes are isolated. Any antenna
marker remains a final-handoff blocker and must be classified and repaired
before promotion; this is not a global waiver.

### Streamout

Every canonical OOC wrapper run requires the official XH018 map and the JIHD
standard-cell GDS merge. The wrapper now audits the actual Innovus command log
and output hash. Missing map, missing merge, or failed audit makes the wrapper
fail even if Innovus itself returns zero.

### Candidate staging gate

The canonical TX gate checks actual LEF dimensions, stream-pin centers, scalar
packet pins, PG pin layers/use, timing, regular/special connectivity, DRC,
exports, and the GDS map/merge report. A candidate with deferred antenna can
enter PVS analysis but remains explicitly blocked from final handoff. Do not
stage from file existence, Innovus RC, or `ABSTRACT_READY` alone.

## 10. Packet R1 Probe and Explicit Via Trial

The fresh packet rebuild did reproduce the row-graph failure, but only on VDD.
The restore-only probe reported three horizontal VDD open components at
`y=125.000..128.120`, `133.960..137.080`, and `277.320..280.440 um`, plus one
aggregate VDD component. VSS special connectivity and all regular connectivity
are clean. This is a topology failure after successful `add_shape` and
`sroute`, not evidence that the stripe X center is wrong.

Do not confuse the probe's 40 total markers with its PG count. The total is:

```text
7 MET1 minimum-area + 29 antenna + 4 VDD connectivity = 40
```

The repository contains accepted command-level syntax for adjacent-layer power
vias:

```tcl
editPowerVia -add_vias 1 -nets {VDD} \
  -bottom_layer MET1 -top_layer MET2 -area {<bounded-overlap>}
```

However, older MPTDC evidence records `editPowerVia` commands as PASS while
the required downstream `verifyConnectivity -type special -nets {VDD VSS}`
still failed. Therefore command availability and command RC are only
capability evidence. They are never closure evidence.

The packet SWIRE probe changes the first trial method. It has one MET1 VDD rail
and one METTP VDD stripe at each failed row, but zero VDD MET2/MET3 SWIREs.
Therefore adjacent calls have no proven intermediate target and must not be
repeated as `via-only`. Installed `man editPowerVia` explicitly requires
`setViaGenMode -area_only 1` for bounded generation and exposes
`-exclude_stack_vias 0` for direct non-adjacent stack creation. The packet
`via-only` trial uses those two controls with `MET1` and `METTP`; patch-stack
alone retains adjacent calls after creating intermediate shapes.

The packet trial policy is:

1. Parse the saved SWIRE table and require each open row to overlap an actual
   VDD MET1 followpin and the VDD METTP stripe.
2. Capture installed `editPowerVia` help from the same Innovus release.
3. Launch one fresh process and restore once for one method.
4. Run `via-only` first. If it fails, preserve its root and use a new process
   for `patch-stack`; never accumulate both methods in one session.
5. Save/export nothing from either trial.
6. Accept a method only at special connectivity 0, regular connectivity 0,
   and no DRC increase.

The packet pin correction is independent. All 19 canonical centers were
emitted at exactly target plus `0.280 um`, so generated TX `editPin` commands
now subtract that half-grid amount while retaining the original target center
in the plan CSV and validator. Do not move the interface contract.

The seven minimum-area markers are also independent. The selected-net repair
deleted seven areas without error and reran three route commands without error,
yet the exact same seven `0.1064 um2` stubs remained below the `0.2020 um2`
rule. Repeating those commands is ruled out. Explicit PG-via success, if any,
does not clear or waive this DRC blocker.

## 11. Packet Direct-Stack Rejection And Marker Replay

The packet `via-only` trial returned PASS for `setViaGenMode` and all three
direct MET1-to-METTP `editPowerVia` commands. It also closed the four VDD
special-connectivity findings without changing regular connectivity. It still
failed the physical gate because DRC changed from seven to 25.

The exact delta is:

```text
MET1 minimum-area: 7 -> 7
MET2 short:         0 -> 6
MET2 spacing:       0 -> 2
VIA2 cut-short:     0 -> 3
VIA2 cut-spacing:   0 -> 1
MET3 short:         0 -> 6
```

This is a rejected geometry with a proven topology, not a partial PASS. No
checkpoint or physical handoff was written. The many MPTDC black-box startup
messages are pre-existing library diagnostics; they are not evidence that the
three via commands failed, and they do not override the post-command DRC.

The next gate is an instrumented replay from the same immutable checkpoint in
one new Innovus process. `verify_drc` must be followed immediately by a marker
TSV dump before connectivity checks replace the active marker set. The replay
must reproduce the original counts, preserve all seven baseline marker
signatures, and explain exactly 18 new marker signatures. Its PASS label means
only `DIRECT_STACK_DRC_MARKERS_CLASSIFIED_NO_SAVE_EXPORT`.

Decision rules:

- Do not rerun the uninstrumented via-only trial.
- Do not run patch-stack while MET2/MET3 shorts and VIA2 conflicts are
  unclassified.
- Do not save, export, stage, run canonical Innovus, or run PVS from the replay.
- Do not choose `-via_rows 1 -via_columns 1`, row-by-row insertion, or manual
  cut placement until the marker boxes show which generated cuts collide.
- If replay counts differ from `4 -> 0` special, `0 -> 0` regular, or `7 -> 25`
  DRC, stop as nondeterministic evidence rather than selecting a repair.

The first marker replay stopped before construction because raw
`top.markers=40` was compared directly with `verify_drc=7`. A restored marker
database can retain antenna and connectivity classes across verification
commands. For DRC delta analysis, record the raw database total separately and
filter `type=Antenna` plus `type=Connectivity`; require the filtered count to
match `verify_drc` and require raw-count accounting to balance.

Do not use Tcl `error` as the terminal fail-closed action in a `-nowin -init`
diagnostic. Innovus may enter its command prompt and consume the caller's next
shell lines. Write the status report, use an explicit nonzero Innovus exit, and
redirect batch-child stdin from `/dev/null` as a fallback EOF. Preserve the
failed diagnostic root and assign a new run ID after repairing the harness.

## 12. Packet Direct-Stack Geometry Classification

The corrected Step 10 replay balanced the restored marker database as seven
DRC, 29 antenna, and four connectivity markers before the command. After the
direct stacks it balanced as 25 DRC, 29 antenna, and zero connectivity
markers. All seven baseline minimum-area signatures remained and exactly 18
new signatures explained the count delta.

The new markers are not distributed noise. Six are nearest row 1, nine row 2,
and three row 3. They consist only of MET2/MET3 signal shorts or spacing and
VIA2 cut conflicts in the bounded stack areas. This rejects both more helper-X
searches and the existing patch-stack fallback: the topology is already
closed, while the intermediate-layer footprint is the measured defect.

One constrained multiplicity candidate is now permitted:

1. Start one fresh Innovus process and restore the clean checkpoint once.
2. Keep the same three row windows and direct MET1-to-METTP method.
3. Add `-via_rows 1 -via_columns 1` to each bounded `editPowerVia` call.
4. Dump and reconcile pre/post markers, special connectivity, and regular
   connectivity before classifying the result.
5. Save and export nothing; stop after the classification report.

The candidate is accepted only as `VALIDATED_NOT_CANONICAL` when connectivity
is zero and DRC does not increase. A coherent rejection is still a successful
diagnostic gate, but it does not authorize another method automatically.
Canonical replay and PVS remain blocked in both cases until review.

## Step 11 Failure Ledger - 1x1 Is Necessary But Not Sufficient

The three explicit 1x1 stacks returned command PASS and closed all four VDD
opens. Final DRC was 22, with 15 new markers and no removed baseline marker:

```text
MET2/Metal_Short=6
MET2/Parallel_Run_Length_Spacing=2
MET3/Metal_Short=6
VIA2/Cut_Spacing=1
```

Rejected interpretations:

- Do not claim the 1x1 method is clean because connectivity is zero.
- Do not restore and move X; every reviewed row window intersects the required
  VDD MET1 row and METTP stripe, while the measured failures name routed nets.
- Do not add intermediate-layer patches; MET2 and MET3 are already the failing
  layers.
- Do not repeat selected-net repair for the seven unchanged MET1 minimum-area
  stubs.
- Do not run PVS from the trial; it saved and exported nothing.

The shortest independent experiment changes only stage order. One fresh full
run inserts the proven 1x1 topology after placement, verifies it before CTS,
and then lets CTS and signal routing avoid it. This is not a replay of a
failed checkpoint mutation. The run ID is immutable, the feature is opt-in,
and classification never triggers immutable PVS staging or PVS execution.

## Step 12 Failure Ledger - Unfilled Row Endpoints

The fresh pre-CTS candidate changed the DRC conclusion but exposed a stage
milestone error. All five setup/direct-via commands passed and pre-CTS DRC was
zero, so the post-route MET2/MET3 collision mechanism was removed. Special
connectivity reported exactly 156 `IMPVFC-94` dangling-wire violations and no
other class.

The count matches two endpoints on each of the 39 VDD and 39 VSS MET1 row
wires. Treating this as arbitrary PG failure would discard the successful DRC
result; treating every pre-CTS open as acceptable would weaken the gate too
far. The bounded policy is therefore:

1. Accept either strict zero special connectivity, or exactly 156
   `IMPVFC-94` with zero other problem summaries.
2. Require pre-CTS DRC zero in both cases.
3. Run CTS and insert DRC-safe fillers with the PG geometry already present.
4. Rerun only core-pin `sroute`; do not recreate stripes or direct stacks.
5. Require post-filler special connectivity zero and DRC zero before signal
   routing.

This policy is enabled only by the Step 13 environment tuple. The default OOC
flow and Step 12 strict policy remain unchanged. A coherent Step 13 rejection
is diagnostic PASS only; it does not authorize PVS or another geometry sweep.

## Step 13 Failure Ledger - Restitch Closes PG And Creates 165 DRC

The fresh post-filler candidate passed its bounded pre-CTS gate with exactly
156 `IMPVFC-94` dangling endpoints and zero DRC. After CTS and filler, the
second core-pin `sroute` returned command PASS and reduced special
connectivity to zero, but `verify_drc` reported 165 violations. The flow
correctly aborted before ordinary routing and export.

Rejected interpretations:

- Do not call the candidate clean because special connectivity is zero.
- Do not treat 165 as a final-route result; ordinary signal routing never ran.
- Do not count missing LEF/GDS/timing reports as independent defects; they are
  expected after the post-filler milestone abort.
- Do not rerun the same full candidate or start PVS; the stage that introduced
  DRC is not yet identified.
- Do not assume filler insertion caused the markers merely because the gate is
  named post-filler; the gate measured only after the second `sroute`.

The bounded Step 14 experiment is stage attribution, not another PG method:

1. Restore the rejected candidate's immutable `03_cts` checkpoint once in one
   fresh Innovus process.
2. Capture `verify_drc`, filtered marker TSV, special connectivity, and regular
   connectivity before filler insertion.
3. Apply the same DRC-safe filler mode and exact canonical JIHD filler command
   used by Step 13.
4. Repeat the four captures before any post-filler `sroute`.
5. Save, export, stage, and run PVS nowhere in the probe.

Because Step 13 already establishes post-restitch `connectivity=0` and
`DRC=165`, two DRC-clean Step 14 stages directly attribute the violations to
the second `sroute`. The pre-restitch connectivity count then decides whether
that command can be removed or must be replaced with a bounded DRC-safe
stitching method.
