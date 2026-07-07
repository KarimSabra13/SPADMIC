# MPTDC Real RO6 OA/PVS Next Steps - 2026-07-07

Author: Karim Sabra

This note records the current MPTDC physical-verification decision after the
manual real-RO6 PVS DRC evidence on the `SPADMIC_test` branch. It is an
execution-order note, not a signoff claim.

```text
READY_FOR_TAPEOUT=NO
PVS_DRC_RUN_ON_REAL_RO6_LAYOUT=YES
PVS_LVS_RUN_ON_REAL_RO6_LAYOUT=NO
OA_REAL_RO6_ASSEMBLY_REQUIRED=DONE_FOR_DRC_TRIAGE
REAL_RO6_PVS_DRC_STATUS=FAIL_RO_BOUNDARY_DRC
DIGITAL_REROUTE_REQUIRED=YES
```

## Current Real-RO6 Evidence

After the earlier streamout-wrapper failures, a manual OA assembly did produce a
real-RO6 PVS DRC run:

```text
manual_assembly_run=/sim/ksabra/SPADMIC_work/innovus/mptdc_manual_gui_streamout_realro6_20260707_165027
pvs_drc_run=/sim/ksabra/SPADMIC_work/innovus/mptdc_manual_gui_streamout_realro6_20260707_165027/pvs_drc_realro6_20260707_01
oa_top=MPTDC_GDS_REALRO6_20260707/mptdc_axis_core/layout
real_ro_master=MPTDC_GDS_REALRO6_20260707/RO_tune6/layout
repo_evidence=MPTDC/docs/signoff_notes/pvs_drc_realro6_20260707_01_evidence
```

The committed evidence shows that the layout was not missing:

- `PIPO1.LOG` translated `MPTDC_GDS_REALRO6_20260707/mptdc_axis_core/layout`
  with `130049` scalar instances, `2323` polygons, `23588` rectangles, `174840`
  paths, `433` cells, and `0` streamout errors.
- `mptdc_axis_core_drc.sum` reports `Total DRC Results : 4783 (4783)`.
- `pvsdrcctl` has `DENSITY`, `DUMMY_FILL`, `PIMIDE`, and variable antenna ratio
  disabled, so this is hard layout DRC triage, not a fill-density-only result.
- The nonzero rule buckets are `B2V1`, `B2V2`, `E3M3V2`, `E4M1V1`, `E7M2V1`,
  `E8M2V2`, `S1M1`, `S1M2`, `S1M3`, `S1V1`, `S1V2`, `S1WM`, `S3V1`, `S9V2`,
  `W1M2`, `W1M3`, `W1V1`, `W1V2`, `W2V1`, and `W2V2`.

The project conclusion is that this is no longer primarily a PVS export setup
problem. The manual assembly exposed a real digital/RO abstraction mismatch:
the router used a coordinate proxy that did not protect the real `RO_tune6`
internal metal footprint. The standalone RO remains treated as clean based on
the analog-side statement; the digital fix is therefore upstream in the PnR
abstract and route keepout policy.

The PVS warning that `VDD_LEFT`, `VDD_RIGHT`, `VSS_LEFT`, and `VSS_RIGHT` labels
collapse to one assigned net remains an LVS/PG-label risk to resolve after hard
DRC is controlled. It is not the immediate reason to hand-waive the 4,783 DRCs.

## Previous Automation Failure

The latest failed automated replay before the real-RO6 manual assembly was:

```text
PVS_RUN_ID=20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549_pvs_drc_reality_20260707_155255
SOURCE_HEAD_BEFORE_WRAPPER_HOTFIX=da55566f30034a0341bc12ba8357b9df59959718
FAILED_RUN_ID=20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549
SOURCE_CKPT=/sim/ksabra/SPADMIC_work/innovus/20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549/checkpoints/04_route_failed.enc.dat
PVS_DIR=/sim/ksabra/SPADMIC_work/innovus/20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549_pvs_drc_reality_20260707_155255
```

That failure stopped before producing `mptdc_axis_core_merged_stdcell_ro6.gds`.
It remains useful as wrapper-debug history, but it has been superseded by the
manual real-RO6 PVS DRC evidence above.

## Protected-LEF Free-Internal Launch Attempt

The first protected-LEF/free-internal reroute attempt was launched from:

```text
attempt_date=2026-07-07T18:23 local server time
source_head=8bcd8f62e375d7863c106d3e4b594eda265d5438
run_id=mptdc_tc_ro6_realobs_freeint_reroute_20260707_182343
protected_lef=/sim/ksabra/SPADMIC_work/lef/mptdc_tc_ro6_realobs_freeint_reroute_20260707_182343/RO_tune6_protected_pnr.lef
protected_lef_summary=/sim/ksabra/SPADMIC_work/lef/mptdc_tc_ro6_realobs_freeint_reroute_20260707_182343/RO_tune6_protected_pnr.summary.rpt
```

The protected PnR LEF generation succeeded:

```text
PROXY_KIND=PROTECTED_PNR_REAL_OBS
MACRO=RO_tune6
PINS_SOURCE=19
PINS_KEPT=19
PINS_DROPPED=NONE
OBS_COPIED=YES
OBS_COUNT=1
OBS_LAYERS=MET1 MET2 MET3 METTP
METAL_OBS_LAYERS=MET1 MET2 MET3 METTP
```

The `PINS_DROPPED=NONE` result means the current source LEF already did not
contain a `vdd!` alias pin. The important checks still passed: the generated LEF
has a real `OBS` section and no `PIN vdd!`.

Innovus did not launch in this attempt. The wrapper stopped immediately with:

```text
ERROR: unknown option: --run-id
Usage:
  server_run_innovus_mptdc_digital_signoff.sh <RUN_ID> [options]
```

This was a command-interface mistake, not a PnR, LEF, license, or Innovus
failure. The wrapper historically required positional `RUN_ID`, and full Innovus
execution also requires explicit review gates:

```text
MPTDC_DIGITAL_SIGNOFF_APPROVED=1
MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
--mode full_signoff
```

The wrapper has now been updated to accept `--run-id` and `--expected-head` as
well, so the documented command style is consistent with the route-checkpoint
wrappers and still protects against launching on the wrong git commit.

## Protected-LEF Free-Internal Innovus Import Attempt

The next attempt used the updated wrapper interface and did launch Innovus:

```text
attempt_date=2026-07-07T18:27 local server time
source_head=f015d3a4e67d30a5e9d0a0ddf1edd3119519b592
run_id=mptdc_tc_ro6_realobs_freeint_reroute_20260707_182715
result_dir=/sim/ksabra/SPADMIC_work/innovus/mptdc_tc_ro6_realobs_freeint_reroute_20260707_182715
protected_lef=/sim/ksabra/SPADMIC_work/lef/mptdc_tc_ro6_realobs_freeint_reroute_20260707_182715/RO_tune6_protected_pnr.lef
```

This attempt proved these front-end gates:

```text
expected_head=f015d3a4e67d30a5e9d0a0ddf1edd3119519b592
O1_RO_LEF_MACRO=RO_tune6
MPTDC_PNR_OSC_WIDTH_UM=168.945
MPTDC_PNR_OSC_HEIGHT_UM=70.5
MPTDC_RO_LEF_SIZE_STATUS=PASS
PRE_PNR_GATE=PASS
MPTDC_DIGITAL_SIGNOFF_SOURCE_CHECK=PASS
MPTDC_DIGITAL_SIGNOFF_APPROVED=1
MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
```

The manifest also captured the intended reroute policy:

```text
free_all_internal_placement=1
free_internal_placement=1
fix_ro_macros=1
create_ro_halos=1
create_ro_route_blockages=1
ro_route_blockage_margin_um=1.0
ro_route_blockage_layers=MET1 MET2 MET3 METTP
ro_route_blockage_open_sides=north south
ro_phase_min_clearance_um=5.0
skip_phase_buffer_preplace=1
place_fast_tags_by_column=0
```

Innovus failed before floorplan, RO placement, halo creation, route blockage
creation, placement, or routing:

```text
MPTDC_DIGITAL_SIGNOFF_STAGE_FAILED: stage=import_mmmc
error=MPTDC_DIGITAL_SIGNOFF_MISSING_FILE: post-synthesis netlist path=
```

Therefore the missing `ro_macro_status.rpt`, `ro_halo_status.rpt`, and
`ro_route_blockage_status.rpt` reports are expected. Those stages did not run.

Root cause: the wrapper's pre-PNR gate resolved the default closed Genus handoff
internally, but the wrapper itself still passed an empty
`MPTDC_SIGNOFF_HANDOFF_DIR` into Innovus. The pre-PNR gate was therefore checking
`/sim/ksabra/SPADMIC_work/handoff/genus_typical/mptdc_genus_typical_closed`,
while Innovus searched an empty/default result directory for
`mptdc_axis_core.postsyn.v`.

The wrapper has now been fixed to resolve and pass the same default closed
handoff directory before both source validation and Innovus execution. The next
rerun should show a concrete `handoff_dir` in `run_manifest.txt`, not `unset`.

## Protected-LEF Free-Internal Route-Stage Attempt

The next rerun resolved the Genus handoff correctly and progressed well past the
previous import failure:

```text
attempt_date=2026-07-07T18:31 local server time
source_head=065e6d297ae5ba9a5659fae9558fffb8e93fe6ad
run_id=mptdc_tc_ro6_realobs_freeint_reroute_20260707_183153
result_dir=/sim/ksabra/SPADMIC_work/innovus/mptdc_tc_ro6_realobs_freeint_reroute_20260707_183153
default_closed_handoff=/sim/ksabra/SPADMIC_work/handoff/genus_typical/mptdc_genus_typical_closed
handoff_dir=/sim/ksabra/SPADMIC_work/handoff/genus_typical/mptdc_genus_typical_closed
```

This attempt proved that the protected-RO floorplan controls were applied:

```text
RO_TUNE6_COUNT=2
FREE_INTERNAL_PLACEMENT=1
FREE_DIGITAL_ONLY_RO_POLICY=RO_MACRO_FIXED_BY_POLICY
RO_MACRO_FIXED=YES
SLOW_RO_BBOX=50.4 610.4 219.345 680.9
FAST_RO_BBOX=50.4 120.4 219.345 190.9
RO_MACRO_STATUS=PASS
RO_HALO_STATUS=PASS
RO_ROUTE_BLOCKAGE_STATUS=PASS
RO_ROUTE_BLOCKAGE_COUNT=4
```

The slow and fast RO macros were fixed at the intended coordinates, the 5 um
hard placement halos were created, and west/east route blockage bands were
created on `MET1 MET2 MET3 METTP` with north/south left open for pin access.

The run then failed later, inside the route stage, before signal routing
completed:

```text
MPTDC_DIGITAL_SIGNOFF_STAGE_FAILED: stage=route
error=MPTDC_POSTPLACE_PRE_ROUTE_SROUTE_GATE_FAILED
report=/sim/ksabra/SPADMIC_work/innovus/mptdc_tc_ro6_realobs_freeint_reroute_20260707_183153/reports/postplace_pre_route_sroute_status.rpt
failure_def=/sim/ksabra/SPADMIC_work/innovus/mptdc_tc_ro6_realobs_freeint_reroute_20260707_183153/def/03b_postplace_pre_route_sroute_failed.def
failure_checkpoint_dat=/sim/ksabra/SPADMIC_work/innovus/mptdc_tc_ro6_realobs_freeint_reroute_20260707_183153/checkpoints/03b_postplace_pre_route_sroute_failed.enc.dat
```

The repeated stripe-generation warnings and manufacturing-grid adjustments are
not the root cause by themselves. The important signal is that the strict
post-place/pre-route PG `sroute` gate stopped the run and preserved a failure
checkpoint for review. This is the right behavior for this failure class: earlier
PG debug showed that broad PG relaxation or broad post-route `sroute` can create
or hide real VDD/VSS failures.

Do not relax this gate to continue routing blindly. Keep:

```text
MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN=1
MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY=0
MPTDC_ROUTE_GATE_SROUTE_RECOVERY=0
```

The next step is to inspect the failure reports and identify whether the
blocker is a PG pin placement issue, RO PG hookup issue, blockwire bridge, open
port, dangling special wire, or true VDD/VSS short. The prior PG docs to compare
against are:

```text
MPTDC/docs/mptdc_tc_pnr_pg_topology_diagnosis_20260630.md
MPTDC/docs/pnr/MPTDC_PVS_PG_SHORT_ROOT_CAUSE_20260702.md
MPTDC/docs/pnr/MPTDC_PNRLEF_FREEALL_AGGR_FINAL_CHECKPOINT_20260701.md
```

## New Decision

Do a fresh digital reroute from the Genus handoff using a protected PnR-only RO
LEF generated from the real RO abstract. The generated PnR LEF must preserve real
macro OBS and drop only the unwanted `vdd!` alias pin. Then create explicit RO
route-blockage perimeter bands in Innovus, leaving only intentional pin-access
sides open.

Do not hand-edit the assembled OA view as the final solution. The OA/PVS run is
diagnostic evidence. The production fix belongs in the digital route inputs.

## Correct Reroute Order

1. Sync the source tree and bind the run to the actual branch head.

   ```bash
   cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
   git checkout SPADMIC_test
   git pull --ff-only
   export EXPECTED_HEAD="$(git rev-parse HEAD)"
   test "$(git rev-parse HEAD)" = "$EXPECTED_HEAD"
   ```

2. Bind the known restorable checkpoint and external collateral.

   ```bash
   export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work
   export MPTDC_INNOVUS_WORK=$MPTDC_WORK_ROOT/innovus
   export MPTDC_GENUS_HANDOFF_DIR=$MPTDC_WORK_ROOT/handoff/genus_typical/mptdc_genus_typical_closed
   export FAILED_RUN_ID=20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549
   export SOURCE_CKPT=$MPTDC_INNOVUS_WORK/$FAILED_RUN_ID/checkpoints/04_route_failed.enc.dat
   export RO6_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
   export DCELL_CDL=/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl
   export PVS_TECH_LIB=/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0/pvtech.lib

   test -e "$SOURCE_CKPT"
   test -f "$MPTDC_GENUS_HANDOFF_DIR/mptdc_axis_core.postsyn.v"
   test -f "$MPTDC_GENUS_HANDOFF_DIR/mptdc_axis_core.postsyn.sdc"
   test -f "$RO6_LEF"
   test -f "$DCELL_CDL"
   test -f "$PVS_TECH_LIB"
   ```

3. Generate the protected PnR-only RO LEF.

   ```bash
   export REROUTE_RUN_ID=mptdc_tc_ro6_realobs_reroute_$(date +%Y%m%d_%H%M%S)
   export PROTECTED_RO6_LEF=$MPTDC_WORK_ROOT/lef/${REROUTE_RUN_ID}/RO_tune6_protected_pnr.lef
   export PROTECTED_RO6_LEF_SUMMARY=${PROTECTED_RO6_LEF%.lef}.summary.rpt

   python3 MPTDC/pnr/scripts/generate_ro_protected_pnr_lef.py \
     --source-lef "$RO6_LEF" \
     --out-lef "$PROTECTED_RO6_LEF" \
     --summary "$PROTECTED_RO6_LEF_SUMMARY" \
     --macro RO_tune6

   sed -n '1,120p' "$PROTECTED_RO6_LEF_SUMMARY"
   test -s "$PROTECTED_RO6_LEF"
   grep -n '^  OBS$' "$PROTECTED_RO6_LEF"
   ! grep -n '^  PIN vdd!$' "$PROTECTED_RO6_LEF"
   ```

4. Run a fresh digital Innovus route with the protected RO abstract and route
   blockage perimeter bands.

   ```bash
   export O1_USE_REAL_RO_ABSTRACT=1
   export O1_RO_CELL_NAME=RO_tune6
   export O1_RO_LEF_PATH="$PROTECTED_RO6_LEF"

   export MPTDC_CLOSURE_SCOPE=TC_ONLY
   export MPTDC_PNR_FIX_RO_MACROS=1
   export MPTDC_PNR_CREATE_RO_HALOS=1
   export MPTDC_RO_PHASE_MIN_CLEARANCE_UM=5.0
   export MPTDC_PNR_CREATE_RO_ROUTE_BLOCKAGES=1
   export MPTDC_RO_ROUTE_BLOCKAGE_MARGIN_UM=1.0
   export MPTDC_RO_ROUTE_BLOCKAGE_LAYERS="MET1 MET2 MET3 METTP"
   export MPTDC_RO_ROUTE_BLOCKAGE_OPEN_SIDES="north south"
   export MPTDC_PNR_FREE_ALL_INTERNAL_PLACEMENT=1
   export MPTDC_PNR_FREE_INTERNAL_PLACEMENT=1
   export MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE=1
   export MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=0
   export MPTDC_RO_PHASE_POSTPLACE_AUDIT_FATAL=0

   export MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN=1
   export MPTDC_ROUTE_GATE_SROUTE_RECOVERY=0
   export MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY=0
   export MPTDC_POSTPLACE_PRE_ROUTE_DANGLING_ONLY_MAX=64
   export MPTDC_DIGITAL_SIGNOFF_APPROVED=1
   export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1

   MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
     --run-id "$REROUTE_RUN_ID" \
     --expected-head "$EXPECTED_HEAD" \
     --mode full_signoff
   ```

5. Inspect the strict PG failure evidence before rerunning.

   ```bash
   export REROUTE_DIR="$MPTDC_INNOVUS_WORK/$REROUTE_RUN_ID"
   test -d "$REROUTE_DIR/reports"

   grep -E '^(head|expected_head|run_id|result_dir|handoff_dir|block_pg_pin_style|preplace_pg_sroute|postplace_pre_route_sroute|postplace_pre_route_sroute_require_clean|postplace_pre_route_allow_dangling_only|route_gate_sroute_recovery|ro_pg_hookup|ro_pg_hookup_required|ro_pg_hookup_search_um|ro_pg_hookup_margin_um|ro_pg_hookup_spacing_um):' \
     "$REROUTE_DIR/manifests/run_manifest.txt"

   for f in \
     "$REROUTE_DIR/reports/block_pg_pin_status.rpt" \
     "$REROUTE_DIR/reports/ro_macro_status.rpt" \
     "$REROUTE_DIR/reports/ro_halo_status.rpt" \
     "$REROUTE_DIR/reports/ro_route_blockage_status.rpt" \
     "$REROUTE_DIR/reports/ro_pg_hookup_status.rpt" \
     "$REROUTE_DIR/reports/ro_pg_probe_before_hookup.rpt" \
     "$REROUTE_DIR/reports/ro_pg_probe_after_hookup.rpt" \
     "$REROUTE_DIR/reports/postplace_pre_route_sroute_status.rpt" \
     "$REROUTE_DIR/reports/postplace_pre_route_pg_topology_before_sroute.rpt" \
     "$REROUTE_DIR/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt" \
     "$REROUTE_DIR/reports/postplace_pre_route_pg_topology_after_sroute.rpt" \
     "$REROUTE_DIR/reports/postplace_pre_route_verify_connectivity_special.rpt" \
     "$REROUTE_DIR/reports/postplace_pre_route_pg_topology_after_sroute_verify_special.rpt" \
     "$REROUTE_DIR/reports/pg_verify_connectivity_special.rpt" \
     "$REROUTE_DIR/reports/pg_verify_connectivity_all.rpt"; do
       echo "===== $f ====="
       sed -n '1,260p' "$f" 2>/dev/null || echo "MISSING: $f"
   done

   grep -RniE 'POSTPLACE_PRE_ROUTE_SROUTE_STATUS|POSTPLACE_PRE_ROUTE_SROUTE_GATE_ACTION|POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY|BLOCK_PG_PIN_STATUS|RO_PG_HOOKUP|Net VDD|Net VSS|IMPVFC|dangling|open|short|unconnected|Verification Complete|Problem\\(s\\)|Different labels|Metal_Short|VDD_LEFT|VDD_RIGHT|VSS_LEFT|VSS_RIGHT' \
     "$REROUTE_DIR/reports" | head -300

   find "$REROUTE_DIR/reports" -maxdepth 1 -type f \
     \( -name '*pg*' -o -name '*sroute*' -o -name '*connectivity*' -o -name '*block_pg*' -o -name '*ro_pg*' \) \
     -print | sort
   ```

6. Reassemble the fresh route with real `SPADMIC/RO_tune6/layout` and rerun PVS
   DRC from Virtuoso/OA.

   First objective: prove that PVS actually runs on the assembled real RO6
   layout after the protected-abstract reroute. Do not continue to LVS from a
   missing-layout, missing-GDS, unresolved cellview, or unresolved-standard-cell
   state. If DRC reports violations, triage them in this order:

   1. unresolved/missing cell or layer-map problems;
   2. real RO6 boundary, pin, well, text, and supply-label problems;
   3. standard-cell row/tap/endcap infrastructure problems;
   4. the four known Innovus geometry DRC-marker regions;
   5. ordinary route/spacing/antenna violations.

7. Run LVS only after the DRC run is real and understood.

   Use the layout OA top as layout input. Use the Innovus `-includePowerGround`
   source netlist from the same checkpoint attempt as source input. Add the
   D_CELLS CDL and RO6 schematic/CDL/HCell mapping as required by the PVS GUI
   setup. Do not run LVS against a proxy RO layout if the question is real-RO6
   signoff.

8. Record the result without overstating it.

   Commit only concise evidence summaries. Keep raw PVS databases, logs,
   checkpoints, GDS, OA databases, and large generated reports outside the repo.
   A valid summary must state the branch head, source checkpoint, OA top
   library/cell/view, PVS deck/template, whether DRC actually ran, whether LVS
   actually ran, and whether any violations are waived or still open.

## Hard Stops

Stop and preserve evidence if any of these occurs:

- the checked-out branch head does not match `EXPECTED_HEAD`;
- `SOURCE_CKPT` cannot be restored;
- the OA top cannot resolve `SPADMIC/RO_tune6/layout`;
- standard-cell OA masters are unresolved;
- PVS starts on a proxy RO view instead of the real RO6 layout;
- PVS fails before opening the real layout;
- a generated GDS/OA view is missing but the report is being interpreted as a DRC
  result;
- LVS is attempted before the layout assembly and DRC state are understood.

Do not use the manual MET1 patch checkpoint as a source for this flow. It is not
safe evidence for signoff triage because it introduced real shorts and dangling
wires.
