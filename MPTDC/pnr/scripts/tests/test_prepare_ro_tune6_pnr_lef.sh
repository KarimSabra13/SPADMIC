#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PNR_DIR/../../.." && pwd)"
PREP="$PNR_DIR/server_prepare_ro_tune6_pnr_lef.sh"
FIXTURE="$REPO_ROOT/MPTDC/docs/pnr/generated/20260630_mptdc_ro_lef_access_patch_nofiller_v1_evidence"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

RUN="$TMP_ROOT/failed_route"
MARKERS="$TMP_ROOT/pre_sroute_markers.tsv"
FAILED_DEF="$TMP_ROOT/selected_failed_route.def"
SOURCE_LEF="$FIXTURE/lef/GOLDEN_RO_tune6.lef"
OUT_LEF="$TMP_ROOT/RO_tune6_marker_access.lef"
OUT_SUMMARY="$TMP_ROOT/RO_tune6_marker_access.summary.txt"

mkdir -p "$RUN/reports" "$RUN/def"
cp "$FIXTURE/reports/route_drc_markers.tsv" "$MARKERS"
cp "$FIXTURE/def/04_route_failed.def" "$FAILED_DEF"

python3 - "$PNR_DIR/generate_ro_pnr_lef_access.py" <<'PY'
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("generate_ro_pnr_lef_access", sys.argv[1])
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)

assert module.infer_pin_name({
    "nearest_pin_same_layer": "VDD:MET3:0 0 1 1",
    "message": "Regular Wire of Net u_core_fast_phase_raw[3]",
}) == "S[3]"
assert module.infer_pin_name({
    "nearest_pin_same_layer": "VDD:MET3:0 0 1 1",
    "message": "Regular Wire of Net u_core_fe_osc_slow_en",
}) == "rstb"
assert module.infer_pin_name({
    "nearest_pin_same_layer": "VDD:MET3:0 0 1 1",
    "message": "Regular Wire of Net unrelated",
}) == "VDD"
PY

bash "$PREP" \
  --run "$RUN" \
  --source-lef "$SOURCE_LEF" \
  --markers "$MARKERS" \
  --failed-def "$FAILED_DEF" \
  --out-lef "$OUT_LEF" \
  > "$TMP_ROOT/prep.stdout"

test -s "$OUT_LEF"
test -s "$OUT_SUMMARY"
grep -Fxq "MARKERS=$MARKERS" "$OUT_SUMMARY"
grep -Fxq "FAILED_DEF=$FAILED_DEF" "$OUT_SUMMARY"
grep -Fxq 'REQUIRED_ACCESS_PIN_SET_STATUS=PASS' "$OUT_SUMMARY"
grep -Fxq 'UNEXPECTED_ACCESS_PIN_COUNT=0' "$OUT_SUMMARY"
grep -Fxq 'PNR_LEF_PREP_STATUS=PASS' "$OUT_SUMMARY"
grep -Eq '^MET2_ACCESS_WINDOW_COUNT=[1-9][0-9]*$' "$OUT_SUMMARY"
grep -Eq '^MET3_ACCESS_WINDOW_COUNT=[1-9][0-9]*$' "$OUT_SUMMARY"
for pin in 'S[0]' 'S[1]' 'S[2]' 'S[3]' 'S[4]' 'S[5]' 'S[6]' 'S[7]' rstb; do
  awk -v pin="$pin" '$1 == "ACCESS_WINDOWS_BY_PIN" && $2 == pin && $3 > 0 {found=1} END {exit !found}' \
    "$OUT_SUMMARY"
done

set +e
bash "$PREP" \
  --run "$RUN" \
  --source-lef "$SOURCE_LEF" \
  --markers "$MARKERS" \
  --failed-def "$FAILED_DEF" \
  --out-lef "$SOURCE_LEF" \
  > "$TMP_ROOT/source_overwrite.stdout" 2>&1
SOURCE_OVERWRITE_RC=$?
set -e
test "$SOURCE_OVERWRITE_RC" -ne 0
grep -q 'refusing to overwrite the source LEF' "$TMP_ROOT/source_overwrite.stdout"

echo 'MPTDC_RO6_PNR_LEF_PREPARATION_TEST=PASS'
