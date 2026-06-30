# RO_tune6 V2 Route DRC Closure Commands

Date: 2026-06-30

Use this flow for the next focused RO route-DRC iteration after:

```text
RUN=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_ro_lef_access_patch_real_lef_nofiller_v2
```

The target for this iteration is only RO geometry cleanup:

```text
RO Short = 0
RO MetSpc = 0
No marker messages with Blockage of Cell u_core_u_osc_*
```

Special PG connectivity can remain noisy in this focused run because PG/sroute
is intentionally disabled.

## 1. Sync Repo On Server

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source .venv/bin/activate

git fetch origin
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test

EXPECTED_HEAD="$(git rev-parse HEAD)"
echo "EXPECTED_HEAD=$EXPECTED_HEAD"
```

## 2. Refresh The Editable RO Source Copy

The original RO source was newer than the copied ksabra layout. Backup the
editable copy, then refresh it from the original source tree.

```bash
TS="$(date +%Y%m%d_%H%M%S)"
SRC_CELL=/group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL/RO_tune6
DST_CELL=/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/RO_tune6
BACKUP_CELL="${DST_CELL}.pre_source_refresh_${TS}"

mkdir -p /group/validmgr/PROJET/Prj_xh018/ksabra/lef/logs

echo "SRC_CELL=$SRC_CELL"
echo "DST_CELL=$DST_CELL"
echo "BACKUP_CELL=$BACKUP_CELL"

rsync -ani --checksum "$SRC_CELL/" "$DST_CELL/" \
  | tee "/group/validmgr/PROJET/Prj_xh018/ksabra/lef/logs/RO_tune6_source_refresh_dryrun_${TS}.txt"

mv "$DST_CELL" "$BACKUP_CELL"
mkdir -p "$DST_CELL"

rsync -av --no-owner --no-group "$SRC_CELL/" "$DST_CELL/"
find "$DST_CELL" \( -name "*.cdslck" -o -name ".cdslock" \) -delete 2>/dev/null || true
chmod -R u+rwX "$DST_CELL"

find "$SRC_CELL" "$DST_CELL" -maxdepth 3 -type f -printf '%p\t%TY-%Tm-%Td %TH:%TM:%TS\t%s\n' \
  | sort \
  | tee "/group/validmgr/PROJET/Prj_xh018/ksabra/lef/logs/RO_tune6_source_refresh_filelist_${TS}.txt"
```

Then rerun the Abstract Generator flow on `Prj_xh018_ksabra/RO_tune6` with the
same Block macro, physical-terminal, and OBS-pin-cutout settings used for the
previous handoff. After AG has regenerated the `abstract` view, export a
versioned source-synced LEF:

```bash
cd /group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0

TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
FULL_LEF="/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6_source_sync_${TS}.full_with_tech.lef"
SRC_SYNC_LEF="/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6_source_sync_${TS}.macro_only.lef"
LEFOUT_LOG="/group/validmgr/PROJET/Prj_xh018/ksabra/lef/logs/lefout_RO_tune6_source_sync_${TS}.log"

lefout \
  -lib Prj_xh018_ksabra \
  -cells "RO_tune6" \
  -views "abstract" \
  -log "$LEFOUT_LOG" \
  -lef "$FULL_LEF" \
  -ver 5.8 \
  -noTech

awk '
BEGIN {
  print "VERSION 5.8 ;"
  print "BUSBITCHARS \"[]\" ;"
  print "DIVIDERCHAR \"/\" ;"
  print ""
  print "UNITS"
  print "  DATABASE MICRONS 1000 ;"
  print "END UNITS"
  print ""
}
/^[[:space:]]*MACRO[[:space:]]+RO_tune6[[:space:]]*$/ {inside=1}
inside {print}
/^[[:space:]]*END[[:space:]]+RO_tune6[[:space:]]*$/ {
  print "END LIBRARY"
  exit
}
' "$FULL_LEF" > "$SRC_SYNC_LEF"

grep -nE 'MACRO|CLASS|ORIGIN|SIZE|PIN|DIRECTION|USE|OBS|END LIBRARY' "$SRC_SYNC_LEF" | head -220
grep -nE 'SITE|CLASS CORE|LAYER MET1|LAYER VIA1|PROPERTYDEFINITIONS' "$SRC_SYNC_LEF" || true

echo "SRC_SYNC_LEF=$SRC_SYNC_LEF"
```

If AG cannot be rerun immediately, keep the next commands the same but set
`SRC_SYNC_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef`.

## 3. Generate A Fresh V2 PnR-Only LEF

This uses the failed v2 route markers and failed-route DEF, not the old v1
probe. The larger `0.45um` margins are deliberate because the previous
`0.20um` cuts left spacing markers at `0.200um` where `0.280um` was required.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source .venv/bin/activate

RUN=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_ro_lef_access_patch_real_lef_nofiller_v2
RUN_ID="$(basename "$RUN")"
SRC_SYNC_LEF="${SRC_SYNC_LEF:-/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef}"
PNR_LEF="/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_${RUN_ID}_v2.lef"

bash MPTDC/pnr/scripts/server_prepare_ro_tune6_pnr_lef.sh \
  --run "$RUN" \
  --source-lef "$SRC_SYNC_LEF" \
  --out-lef "$PNR_LEF" \
  --macro RO_tune6 \
  --x-margin-um 0.45 \
  --y-margin-um 0.45 \
  --instance-margin-um 0.50

LOC="$RUN/local_route_drc_probe_v2"
sed -n '1,140p' "$LOC/prepare_ro_pnr_lef_summary.txt"
grep -n 'MPTDC_PNR_ACCESS_TRIM' "$PNR_LEF" | head -120
```

## 4. Run The Focused No-Filler Diagnostic

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source .venv/bin/activate

git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test
test "$(git rev-parse HEAD)" = "$EXPECTED_HEAD" || {
  echo "ERROR: HEAD mismatch"
  echo "expected $EXPECTED_HEAD"
  echo "actual   $(git rev-parse HEAD)"
  exit 1
}

for v in $(env | awk -F= '/^(MPTDC_|O1_)/ {print $1}'); do
  unset "$v"
done

export MPTDC_REPO_ROOT=$PWD
export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_INNOVUS_WORK=/sim/ksabra/SPADMIC_work/innovus
export MPTDC_GENUS_RUN_ID=MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233
export MPTDC_GENUS_HANDOFF_DIR=/sim/ksabra/SPADMIC_work/handoff/genus_typical/MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233_handoff

export MPTDC_DIGITAL_SIGNOFF_APPROVED=1
export MPTDC_DIGITAL_SIGNOFF_MODE=full_signoff
export MPTDC_CLOSURE_SCOPE=TC_ONLY
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
export MPTDC_PNR_CORE_UTIL=0.55

export O1_USE_REAL_RO_ABSTRACT=1
export O1_RO_CELL_NAME=RO_tune6
export O1_RO_SOURCE_LEF_PATH="$SRC_SYNC_LEF"
export O1_RO_LEF_PATH="$PNR_LEF"
export O1_RO_LIBERTY_PATH=MPTDC/syn/macros/RO_tune6_real_layout_shell.lib

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

RUN_ID=20260630_mptdc_ro_lef_access_source_sync_v2_nofiller

bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  "$RUN_ID" \
  --mode full_signoff \
  --handoff-dir "$MPTDC_GENUS_HANDOFF_DIR"
```

## 5. Inspect The Result

```bash
RUN2=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_ro_lef_access_source_sync_v2_nofiller

sed -n '24,42p' "$RUN2/manifests/run_manifest.txt"
cat "$RUN2/manifests/stage_trace.csv"

for f in \
  route_status.rpt \
  route_recovery_status.rpt \
  route_drc.rpt \
  pg_postroute_connectivity_status.rpt
do
  echo "===== $f ====="
  sed -n '1,220p' "$RUN2/reports/$f" 2>/dev/null || echo MISSING
done

echo "===== RO geometry markers ====="
awk -F'\t' '
  NR==1 {next}
  $5 == "Geometry" && $7 ~ /u_core_(fast|slow)_phase_raw|u_core_fe_osc_(fast|slow)_en|Blockage of Cell u_core_u_osc/ {
    print
  }
' "$RUN2/reports/route_drc_markers.tsv" | head -120

echo "===== Route DRC class counts ====="
awk -F'\t' 'NR>1 && $5 == "Geometry" {c[$4 "|" $6]++} END {for (k in c) print c[k], k}' \
  "$RUN2/reports/route_drc_markers.tsv" | sort -nr
```

Pass this phase only when the RO geometry marker section is empty and
`route_status.rpt` no longer reports `Short` or `MetSpc` from the RO edge.
