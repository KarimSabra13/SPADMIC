# MPTDC PVS Replay Flow

These wrappers replay known GUI-generated PVS controls on one immutable MPTDC
layout/source tuple. A zero shell return code is never treated as DRC or LVS
closure by itself.

The full RO6 recovery sequence is documented in
[`MPTDC_RO6_PHYSICAL_FIRST_RECOVERY.md`](../../docs/pnr/MPTDC_RO6_PHYSICAL_FIRST_RECOVERY.md).

## Required Input

Start only from an Innovus `04_route.enc.dat` checkpoint whose route report has:

```text
ROUTE_STATUS=PASS
INNOVUS_VERIFY_DRC_STATUS=PASS
GEOMETRY_DRC_VIOLATIONS=0
SHORTS=0
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_RAW_BAD=0
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
UNROUTED_NETS=0
```

The preparation step also requires an explicitly selected GDS export of the
real `RO_tune6` OA layout. A proxy, LEF-generated shell, or no-RO streamout is
not an acceptable substitute.

For RO6 recovery, export both views afresh into a run-local directory outside
the OA library:

- `RO_tune6/layout` to GDS
- `RO_tune6/schematic` to CDL

The standalone driver rejects artifacts older than 24 hours by default,
fingerprints both OA view directories before and after the run, copies the GDS
and CDL into an immutable result directory, and accepts only an explicit PVS
`Run Result: MATCH` with no blackboxed cells:

```bash
MPTDC/scripts/pvs/server_run_mptdc_ro6_standalone_lvs.sh \
  --source-pvs-run-id "$SOURCE_PVS_RUN" \
  --run-id "$RO6_STANDALONE_RUN" \
  --ro-gds "$RO_GDS" \
  --ro-cdl "$RO_CDL" \
  --expected-head "$EXPECTED_HEAD"
```

This is a macro proof and is deliberately `SIGNOFF_ELIGIBLE=NO`. It authorizes
regenerating the digital physical source with the exact same GDS hash; it does
not authorize a GDS release.

If the standalone comparison reduces to the exact published VDD-only mismatch
(18 layout pins versus 19 source pins, all 190 reduced devices matched, no
blackboxes, and only source `VDD` missing while bound to layout net 12), do not
rerun PVS or edit routing. Run the read-only OA/export-contract probe:

```bash
MPTDC/scripts/pvs/server_probe_mptdc_ro6_oa_vdd_export_contract.sh \
  --source-standalone-run-id "$RO6_STANDALONE_RUN" \
  --run-id "$RO6_OA_VDD_PROBE_RUN" \
  --expected-head "$EXPECTED_HEAD"
```

The probe independently locks the exact `.cls` signature, opens the OA layout
with mode `r`, inventories top terminal pin figures, labels, supply-net shapes,
and shapes overlapping the golden-LEF VDD pin box, correlates their
layer-purpose pairs against the exact zero-error XStream log and XH018/1131
maps, and requires identical OA content and metadata fingerprints before and
after. Classification success is separate from
`OA_TERMINAL_CONTRACT_STATUS`: a complete diagnosis may pass while the observed
OA terminal contract correctly remains `FAIL`. `PASS_REVIEW_EXPORT_CONTRACT`
is diagnostic evidence only. It selects a review action; it is not an LVS pass
and does not authorize an OA write.
Cadence `XSTRM-234` with zero errors is the authoritative translation-complete
record. The separate `strmout completed.` wrapper message is captured when
present but is optional because GUI/CIW output is not always copied into the
XStream log.

The published V2 probe identified one unique live repair target: the existing
`VDD` `METTP:pin` rectangle at
`(-68.700,-31.950)-(-66.670,-30.115)`. Its coincident MET1/MET2/MET3 drawing
stack is present, but the existing `VDD` terminal owns no pin figure and no
`VDD` text label exists. The historical golden-LEF VDD box does not overlap
this OA revision's `VDD` shapes and must not be used for an OA edit.

`server_apply_mptdc_ro6_oa_vdd_pin_label_repair.sh` is the only supported
write transaction for this defect. Before opening OA for append, it requires
the exact published probe, current OA content hashes, a clean repository, no
OA lock files, and the explicit authorization token. It then copies and
verifies the complete `RO_tune6` OA cell under
`$MPTDC_WORK_ROOT/handoff/oa_backups/RO_tune6`. The SKILL action attaches the
existing pin-purpose rectangle to the existing terminal and creates one
`MET3:TEXT` label on the coincident exported MET3 drawing shape. The pin-purpose
METTP shape itself is ignored by XStream, so labeling METTP would not bind a
streamed polygon. The transaction cannot create or delete metal,
rename nets or terminals, edit `vdd!`/`gnd!`, or edit the schematic.

```bash
# MUTATES Prj_xh018_ksabra/RO_tune6/layout. Run only after explicit review.
MPTDC/scripts/pvs/server_apply_mptdc_ro6_oa_vdd_pin_label_repair.sh \
  --source-probe-run-id 20260827_mptdc_ro6_oa_vdd_export_probe_v2_141033 \
  --run-id "$RO6_OA_VDD_REPAIR_RUN" \
  --authorization EXACT_RO6_VDD_METTP_PIN_LABEL_REPAIR \
  --expected-head "$EXPECTED_HEAD"
```

A successful transaction requires the immutable backup, exact action report,
post-write read-only probe, effective terminal contract, and mutation-scope
gate all to pass. The two empty global aliases are preserved and accepted;
the required 19 terminals must all be present, `VDD` and `VSS` must both own
pin figures, and one exact `VDD` label must exist. Success advances only to
`EXPORT_FRESH_RO6_GDS_AND_RERUN_STANDALONE_LVS`; it is not an LVS or signoff
pass. If any post-write check fails, stop and use the named immutable backup
for reviewed recovery rather than attempting another mutation.

## Physical LVS Source Contract

Input preparation now builds LVS source only from Innovus
`saveNetlist -phys -includePowerGround` output. The contract:

- removes module definitions only for exact masters present in the selected
  canonical CDL set; RO handling is selected explicitly as either the default
  diagnostic wrapper/HCell mode or strict external-CDL mode;
- removes top-level filler instances only for the exact master list and total
  count jointly bound by the tracked `filler_status.rpt` and
  `row_infra_insertion.rpt` from the checkpoint lineage;
- preserves every non-filler top-level instance, including every observed
  report-declared physical tie instance, and accepts an explicit zero tie count;
- rejects filler-count drift, report-contract drift, unresolved active masters,
  and any observed tie master missing from the canonical CDL;
- scalarizes only `u_core_u_osc_fast_u_ro_tune4` and
  `u_core_u_osc_slow_u_ro_tune4` to exact same-index escaped pins `code<0>`
  through `code<7>` and `S<0>` through `S<7>`;
- in default `wrapper-hcell` mode, emits a matching 19-pin scalar `RO_tune6`
  wrapper and HCell entry while rejecting positional RO instances;
- in `external-cdl` mode, requires exactly one external `.SUBCKT RO_tune6`
  with the unique 19-pin set `VDD`, `VSS`, `rstb`, `code<0..7>`, and
  `S<0..7>`, emits no wrapper or HCell entry, and rejects any pre-existing
  HCell path.

The boundary replay does not use position-based bus mapping and does not hide
`tie1`. PVS may still list its effective default as
`lvs_verilog_bus_map_by_position no`; the gate accepts only an absent setting
or exactly one explicit `no`, and rejects `yes` or duplicate settings. Zero
physical tie instances is not a waiver: the boundary result must
still have zero tie mismatch residue. A diagnostic continuation is valid only
for either an explicit top `MATCH` or the exact four-open `RO6_PG_OPEN_ONLY`
remainder with zero bus, tie, net, and instance mismatch residue.

An explicit boundary `MATCH` is not the final full-top LVS result. It advances
only to `server_run_mptdc_ro6_monolithic_lvs.sh`. That driver binds the exact
raw source run, published boundary proof, standalone RO proof, merged GDS,
D-cell CDL, and standalone-matched RO CDL. It then runs one full-top LVS with
exactly three schematic paths and one layout path. `lvs_black_box`, `-hcell`,
position-based bus mapping, and global-signal port promotion are forbidden.
The replay template is taken from the tracked source `_04_lvs` snapshot, with
an empty `.config.rul` and a tracked nonempty `.technology.rul`; mutable live
run controls are not reused.
Only an explicit monolithic `MATCH`, zero blackboxed cells, zero mismatched
cells, exact top `59:59` and RO `19:19` pin matches, no missing instances, and
an empty shorts report set `LVS_SIGNOFF_ELIGIBLE=YES`. Density remains blocked
until that published monolithic gate passes.

The monolithic LVS proof does not relabel the whole block as physically ready.
The current recovery policy records the 136 base-DRC results as the exact four
accepted antenna rule classes with zero non-antenna rules, but this is an
auto-classified project-policy exception, not an independently signed or
tool-clean DRC result. The V13 source also retains 15 Innovus special-PG
dangling endpoints. Both facts remain visible as
`FINAL_PHYSICAL_SIGNOFF_READY=NO`.

The separately reviewed Step 5R `TOP_CONNECTIVITY_MISMATCH` signature has one
allowed follow-up before any physical edit:
`MPTDC/pnr/scripts/server_run_mptdc_tie1_checkpoint_probe.sh`. The probe binds
the published boundary reports to their tracked copies, restores only a
hash-checked checkpoint copy, inventories `tie1`, tie flags, and the four
configured `LOGIC[01]*JIHD` candidates, and publishes with
`SIGNOFF_ELIGIBLE=NO`. `PASS_REVIEW_TIE1_EVIDENCE` means the read-only evidence
is complete; it is not an LVS pass and does not authorize tie insertion.

The only dirty-checkpoint exception is explicit diagnostic mode:

```bash
MPTDC/scripts/pvs/server_run_mptdc_ro6_recovery_pvs.sh \
  --pnr-run-id 20260826_mptdc_bufftap0_route_minarea_patch_trial_v6r_180659 \
  --ro-gds "$RO_GDS" \
  --expected-head "$EXPECTED_HEAD" \
  --diagnostic-deferred-minarea
```

That mode admits only the tracked failed-V6R one-MET1-minimum-area signature,
runs base DRC plus LVS, skips density, and always reports
`PVS_RUN_CLASS=DIAGNOSTIC_NOT_SIGNOFF` and `MPTDC_TC_PVS_CLOSED=NO`.

## Replay Sequence

Run in the foreground after sourcing the Cadence environment:

```bash
set +e

MPTDC/scripts/pvs/00_prepare_pvs_inputs_from_checkpoint.sh \
  --checkpoint "$SOURCE_CKPT" \
  --run-id "$PVS_RUN_ID" \
  --ro-gds "$RO_GDS" \
  --filler-report "$FILLER_REPORT" \
  --row-infra-report "$ROW_INFRA_REPORT" \
  --strict-attribution \
  --expected-head "$EXPECTED_HEAD"
PREP_RC=$?

PVS_DIR="$MPTDC_INNOVUS_WORK/$PVS_RUN_ID"

if [ "$PREP_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/01_audit_pvs_templates.sh \
    --result-dir "$PVS_DIR" \
    --expected-head "$EXPECTED_HEAD"
  AUDIT_RC=$?
else
  AUDIT_RC=99
fi

if [ "$AUDIT_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --variant base \
    --expected-head "$EXPECTED_HEAD"
  DRC_BASE_RC=$?
else
  DRC_BASE_RC=99
fi

if [ "$DRC_BASE_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --variant density \
    --expected-head "$EXPECTED_HEAD"
  DRC_DENSITY_RC=$?
else
  DRC_DENSITY_RC=99
fi

if [ "$DRC_BASE_RC" -eq 0 ] && [ "$DRC_DENSITY_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/03_replay_pvs_lvs_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --expected-head "$EXPECTED_HEAD"
  LVS_RC=$?
else
  LVS_RC=99
fi
```

## Passing Evidence

- `reports/tap_pin_contract.rpt`: exactly one slow and one fast buffered tap-0
  top pin, both output pins on MET3.
- `manifests/pvs_input_hashes.rpt`: exact GDS, source, CDL, HCell, DEF, map,
  and real-RO hashes.
- `reports/pvs_drc_base_status.rpt`: `PVS_DRC_STATUS=PASS` and both totals zero.
- `reports/pvs_drc_base_nonzero_rules.tsv`: complete rule-level inventory when
  diagnostic base DRC is nonzero; it is evidence of debt, never a pass.
- `reports/pvs_drc_density_status.rpt`: the same, with `DENSITY` proven enabled.
- `reports/pvs_lvs_status.rpt`: `PVS_LVS_STATUS=MATCH` with explicit
  report-level match evidence.

Any missing control, stale path, hash mismatch, nonzero report-level DRC total,
or missing explicit LVS MATCH fails closed. These results are a TC-only
physical package gate; they do not claim MMMC timing, IR/EM, PEX, or final
tapeout readiness.
