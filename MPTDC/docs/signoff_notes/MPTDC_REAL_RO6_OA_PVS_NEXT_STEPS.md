# MPTDC Real RO6 OA/PVS Next Steps - 2026-07-07

Author: Karim Sabra

This note records the current MPTDC physical-verification decision after the
latest PVS-prep failure on the `SPADMIC_test` branch. It is an execution-order
note, not a signoff claim.

```text
READY_FOR_TAPEOUT=NO
PVS_DRC_RUN_ON_REAL_RO6_LAYOUT=NO
PVS_LVS_RUN_ON_REAL_RO6_LAYOUT=NO
OA_REAL_RO6_ASSEMBLY_REQUIRED=YES
```

## Last Known Attempt

The latest attempted run before this note was:

```text
PVS_RUN_ID=20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549_pvs_drc_reality_20260707_155255
SOURCE_HEAD_BEFORE_WRAPPER_HOTFIX=da55566f30034a0341bc12ba8357b9df59959718
FAILED_RUN_ID=20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549
SOURCE_CKPT=/sim/ksabra/SPADMIC_work/innovus/20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549/checkpoints/04_route_failed.enc.dat
PVS_DIR=/sim/ksabra/SPADMIC_work/innovus/20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549_pvs_drc_reality_20260707_155255
```

Observed state:

- Git/head gate passed at `da55566f30034a0341bc12ba8357b9df59959718`.
- The Innovus checkpoint restored and loaded `mptdc_axis_core`.
- The restored database still had `4` Innovus geometry DRC markers.
- DEF and LVS netlists were written.
- PVS template audit passed structurally; empty `.config.rul` files are expected
  and must be reported as `PASS_EMPTY`.
- Prep failed before producing the final layout view/GDS because the sourced old
  streamout template attempted to read `::env(STREAM_MAP)`.
- Because `outputs/mptdc_axis_core_merged_stdcell_ro6.gds` was not produced, the
  later PVS DRC replay stopped on missing input. That is not a foundry DRC result.

The immediate wrapper defect was fixed after the failed run by exporting
`::env(STREAM_MAP)` before sourcing the old streamout template. That fix only
unblocks replay triage. It does not make the old GDS-stitch path the preferred
signoff assembly path.

## Decision

Use OA/Virtuoso as the real physical assembly point for signoff triage:

digital layout from the restorable Innovus checkpoint + real
`SPADMIC/RO_tune6/layout` + XFAB/JIHD standard-cell OA libraries.

The old streamout replay wrappers remain useful for reproducing automation
failures and generating DEF/netlists, but do not treat a stitched GDS replay as
more authoritative than an OA assembly that instantiates the real RO6 layout.

## Correct Order

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
   export FAILED_RUN_ID=20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549
   export SOURCE_CKPT=$MPTDC_INNOVUS_WORK/$FAILED_RUN_ID/checkpoints/04_route_failed.enc.dat
   export RO6_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
   export DCELL_CDL=/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl
   export PVS_TECH_LIB=/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0/pvtech.lib

   test -e "$SOURCE_CKPT"
   test -f "$RO6_LEF"
   test -f "$DCELL_CDL"
   test -f "$PVS_TECH_LIB"
   ```

3. Preserve the checkpoint evidence before editing anything.

   In Innovus, restore `SOURCE_CKPT` and save reports that prove the baseline
   state: DRC marker count, marker coordinates/rules, route connectivity, macro
   placements/orientations, and generated DEF/netlists. The four Innovus markers
   must remain classified separately from any PVS result.

4. Export or import the digital layout into an OA library/cell/view.

   Use the site-supported Cadence method that preserves placement, routing,
   layers, pin text, instance names, and transforms. Acceptable approaches are a
   direct Innovus-to-OA export if the environment supports it, or a Virtuoso OA
   import from Innovus DEF/GDS evidence. Name the assembled digital OA view with a
   dated, non-final name such as:

   ```text
   library: MPTDC_DIGITAL_20260707
   cell:    mptdc_axis_core_from_innovus
   view:    layout
   ```

5. Configure `cds.lib` before opening the top.

   The session must resolve all of these libraries before PVS is launched:

   - the new digital OA library;
   - `SPADMIC`, containing `RO_tune6/layout`;
   - the XFAB/JIHD standard-cell OA libraries used by the placed netlist;
   - any technology/display libraries required by `/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0/pvtech.lib`.

6. Replace RO proxy/abstract instances with the real RO6 layout master.

   For every RO instance in the digital top, preserve:

   - instance name;
   - origin;
   - orientation;
   - pin/net connectivity;
   - `VDD`/`VSS` supply names;
   - the intentional RTL/report path convention where the instance path remains
     `u_ro_tune4` while the physical macro master is `RO_tune6`.

   The required real master is:

   ```text
   SPADMIC/RO_tune6/layout
   ```

7. Run PVS DRC from the Virtuoso GUI on the OA top.

   First objective: prove that PVS actually runs on the assembled real RO6
   layout. Do not continue to LVS from a missing-layout, missing-GDS, unresolved
   cellview, or unresolved-standard-cell state. If DRC reports violations, triage
   them in this order:

   1. unresolved/missing cell or layer-map problems;
   2. real RO6 boundary, pin, well, text, and supply-label problems;
   3. standard-cell row/tap/endcap infrastructure problems;
   4. the four known Innovus geometry DRC-marker regions;
   5. ordinary route/spacing/antenna violations.

8. Run LVS only after the DRC run is real and understood.

   Use the layout OA top as layout input. Use the Innovus `-includePowerGround`
   source netlist from the same checkpoint attempt as source input. Add the
   D_CELLS CDL and RO6 schematic/CDL/HCell mapping as required by the PVS GUI
   setup. Do not run LVS against a proxy RO layout if the question is real-RO6
   signoff.

9. Record the result without overstating it.

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
