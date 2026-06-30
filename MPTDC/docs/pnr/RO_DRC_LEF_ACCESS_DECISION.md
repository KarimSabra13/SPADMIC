# RO DRC / LEF Access Decision

Date: 2026-06-30

Scope: TC-only Innovus PnR closure for `mptdc_axis_core`.

## Current Decision

The corrected audit moved this from diagnosis to a PnR-only LEF-access patch.
Do not edit the golden `/group/.../RO_tune6.lef`; generate a diagnostic/closure
copy under `/sim/...` and use it through `O1_RO_LEF_PATH`.

The latest no-filler diagnostic route reached the route gate and localized the
remaining route DRCs at the two `RO_tune6` macro edges.  That strongly points to
macro signal escape or LEF abstract access, but the first LEF comparison used an
incorrect coordinate transform:

```text
lef_box = marker_local_box + LEF_ORIGIN
```

For the current `RO_tune6` abstract this is wrong.  The LEF declares:

```text
ORIGIN 68.695 88.51 ;
SIZE 168.935 BY 70.49 ;
```

The macro pins use negative LEF coordinates.  A marker box reported relative to
the placed macro bounding box must be transformed back to LEF coordinates as:

```text
R0:   lef = local - ORIGIN
MX:   lef_x = local_x - origin_x
      lef_y = SIZE_Y - local_y - origin_y
MY:   lef_x = SIZE_X - local_x - origin_x
      lef_y = local_y - origin_y
R180: lef_x = SIZE_X - local_x - origin_x
      lef_y = SIZE_Y - local_y - origin_y
```

The previous `local+ORIGIN` output produced marker LEF boxes around positive
`y ~= 88..90`, hundreds of microns from the real `S[*]` pin rectangles.  That is
not physically credible and must not be used to trim OBS.

## Corrected Audit

Run the checked-in audit script on the server:

```bash
RUN=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_mesh_bypass_broken_ro_probe_route_v1
LOC=$RUN/local_route_drc_probe
RO_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef

python3 MPTDC/pnr/scripts/audit_ro_marker_vs_lef.py \
  --markers "$LOC/ro_marker_to_inst_audit.tsv" \
  --instances "$LOC/ro_instance_boxes.tsv" \
  --lef "$RO_LEF" \
  --macro RO_tune6 \
  --out-tsv "$LOC/ro_marker_vs_lef_oriented.tsv" \
  --summary "$LOC/ro_marker_vs_lef_oriented_summary.txt"
```

Required outputs:

```text
$LOC/ro_marker_vs_lef_oriented.tsv
$LOC/ro_marker_vs_lef_oriented_summary.txt
```

Observed result on the diagnostic checkpoint:

```text
MARKER_ROWS_ANALYZED=18
COUNT 9 MX|MET2|OBS_OVERLAP_NO_PIN
COUNT 7 R0|MET2|OBS_OVERLAP_NO_PIN
COUNT 2 R0|MET3|OBS_OVERLAP_NO_PIN
```

The route DRC markers map to the legal `S[*]` and `rstb` access x-coordinates,
but the marker boxes sit just below the pin rectangles and overlap same-layer
OBS.  The nearest legal pin clearance is about `0.42um` for the shown rows.
This is exactly the case where a narrow generated PnR-only OBS trim is the next
controlled experiment.

## Interpretation

Use the `classification` column in `ro_marker_vs_lef_oriented.tsv`:

```text
OBS_OVERLAP_NO_PIN
```

The abstract OBS blocks the marker region without a legal same-layer pin.  A
generated PnR-only LEF with narrowly trimmed/split OBS windows is appropriate.

```text
PIN_AND_OBS_OVERLAP
```

A pin-access window is likely covered by OBS.  Generate a PnR-only LEF and trim
only the implicated OBS rectangles around the legal pin windows.

```text
NO_OBS_OR_PIN_OVERLAP
```

Do not patch OBS blindly.  The next patch should be bounded local route guidance
or blockage around the two RO escape bands, not a global METTP strategy.

```text
PIN_OVERLAP_NO_OBS
```

The marker reaches legal pin geometry.  Investigate via/access spacing or local
escape routing, not OBS trimming.

## Constraints

- Do not modify the golden LEF under `/group/...`.
- If a LEF patch is required, generate a PnR-only copy under `/sim/...`.
- Preserve macro name `RO_tune6`, macro size, pin names, pin directions, and
  `VDD`/`vdd!`/`VSS` power semantics.
- Do not change RTL for this issue.
- Do not add broad false paths or multicycle exceptions on
  `FAST_TAG_TO_PD_TS_PHYSICAL`.
- Do not solve this by globally promoting more routing to `METTP`; the stable
  route DRC plateau already has `METTP=0`.

## Generate PnR-Only LEF

Use the checked-in generator.  It reads the audit TSV, creates narrow access
windows around the implicated marker and pin boxes, and splits only overlapping
OBS rectangles in the generated copy.

```bash
RUN=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_mesh_bypass_broken_ro_probe_route_v1
LOC=$RUN/local_route_drc_probe
RO_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
PNR_LEF=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_20260630.lef
PNR_LEF_SUMMARY=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_20260630.summary.txt

mkdir -p "$(dirname "$PNR_LEF")"

python3 MPTDC/pnr/scripts/generate_ro_pnr_lef_access.py \
  --source-lef "$RO_LEF" \
  --audit-tsv "$LOC/ro_marker_vs_lef_oriented.tsv" \
  --out-lef "$PNR_LEF" \
  --summary "$PNR_LEF_SUMMARY" \
  --macro RO_tune6

sed -n '1,220p' "$PNR_LEF_SUMMARY"
grep -n 'MPTDC_PNR_ACCESS_TRIM' "$PNR_LEF" | head -80
```

The generated LEF should preserve:

```text
MACRO RO_tune6
SIZE 168.935 BY 70.49
PIN S[0]..S[7]
PIN rstb
PIN VDD
PIN vdd!
PIN VSS
```

## Next No-Filler Route

Run route diagnosis with the generated LEF, still keeping filler, unsafe RO-PG
DB traversal, post-place sroute, and postroute timing ECO disabled:

```bash
source /eda/cadence/eda_2023-2024
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source .venv/bin/activate

git fetch origin
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test

for v in $(env | awk -F= '/^MPTDC_/ {print $1}'); do
  unset "$v"
done

export MPTDC_REPO_ROOT=$PWD
export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_GENUS_RUN_ID=MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233
export MPTDC_GENUS_HANDOFF_DIR=/sim/ksabra/SPADMIC_work/handoff/genus_typical/MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233_handoff

export MPTDC_DIGITAL_SIGNOFF_APPROVED=1
export MPTDC_DIGITAL_SIGNOFF_MODE=full_signoff
export MPTDC_CLOSURE_SCOPE=TC_ONLY
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
export MPTDC_PNR_CORE_UTIL=0.55

export O1_RO_LEF_PATH=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_20260630.lef

export MPTDC_ENABLE_BLOCK_PG_PINS=1
export MPTDC_BLOCK_PG_PIN_STYLE=mesh_lr_vdd_vss
export MPTDC_BLOCK_PG_PIN_LAYER=METTP
export MPTDC_BLOCK_PG_PIN_CREATE_MODE=geom
export MPTDC_BLOCK_PG_PIN_WIDTH_UM=4.0
export MPTDC_BLOCK_PG_PIN_DEPTH_UM=28.0
export MPTDC_BLOCK_PG_PIN_OUTSIDE_OVERLAP_UM=8.0
export MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES=0

export MPTDC_ALLOW_LEGACY_PG_TOPOLOGY=1
export MPTDC_ENABLE_RO_PG_HOOKUP=0
export MPTDC_REQUIRE_RO_PG_HOOKUP=0
export MPTDC_ENABLE_RO_PG_PROBE=0
export MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE=0
export MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN=0

export MPTDC_ENABLE_FINAL_FILLER=0
export MPTDC_ENABLE_POST_FILLER_SROUTE=0
export MPTDC_FILLER_ADD_FILLERS_WITH_DRC=0
export MPTDC_REQUIRE_DRC_SAFE_FILLER=1

export MPTDC_ENABLE_ROUTE_GATE_RECOVERY=1
export MPTDC_ROUTE_GATE_SROUTE_RECOVERY=0
export MPTDC_ROUTE_REPAIR_COMMANDS='{ecoRoute -target} {ecoRoute -fix_drc}'
export MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE=0
export MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS=0

export MPTDC_ENABLE_POSTROUTE_OPT=0
export MPTDC_ENABLE_TC_CLOSURE=0
export MPTDC_PNR_FAST_TAG_TIMING_FOCUS=0
export MPTDC_PNR_FAST_TAG_TARGETED_ECO=0

RUN_ID=20260630_mptdc_ro_lef_access_patch_nofiller_v1

bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  "$RUN_ID" \
  --mode full_signoff \
  --handoff-dir "$MPTDC_GENUS_HANDOFF_DIR"
```
