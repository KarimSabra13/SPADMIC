#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN=""
SOURCE_LEF="${O1_RO_SOURCE_LEF_PATH:-/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef}"
OUT_LEF=""
MARKERS=""
FAILED_DEF=""
MACRO="RO_tune6"
X_MARGIN="0.45"
Y_MARGIN="0.45"
INSTANCE_MARGIN="0.50"

usage() {
  cat <<'USAGE'
Usage:
  server_prepare_ro_tune6_pnr_lef.sh --run <innovus-run-dir> [options]

Options:
  --source-lef <path>        RO_tune6 source LEF. Defaults to O1_RO_SOURCE_LEF_PATH,
                             then /group/.../RO_tune6.lef.
  --out-lef <path>           Generated PnR-only LEF path. Defaults under
                             /sim/ksabra/SPADMIC_work/lef using the run id.
  --markers <path>           Marker TSV used to derive access windows. Defaults to
                             <run>/reports/route_drc_markers.tsv.
  --failed-def <path>        Routed DEF used for RO placement/orientation. Defaults
                             to <run>/def/04_route_failed.def.
  --macro <name>             Macro name. Default: RO_tune6.
  --x-margin-um <value>      OBS access trim x margin. Default: 0.45.
  --y-margin-um <value>      OBS access trim y margin. Default: 0.45.
  --instance-margin-um <v>   Marker-to-RO instance matching margin. Default: 0.50.
  -h, --help                 Show this help.

This script builds fresh RO-local marker evidence from a failed route run,
runs the orientation-aware LEF audit, and generates a PnR-only LEF copy.
It does not modify the golden /group LEF.
USAGE
}

while (($#)); do
  case "$1" in
    --run)
      RUN="${2:-}"
      shift 2
      ;;
    --source-lef)
      SOURCE_LEF="${2:-}"
      shift 2
      ;;
    --out-lef)
      OUT_LEF="${2:-}"
      shift 2
      ;;
    --markers)
      MARKERS="${2:-}"
      shift 2
      ;;
    --failed-def)
      FAILED_DEF="${2:-}"
      shift 2
      ;;
    --macro)
      MACRO="${2:-}"
      shift 2
      ;;
    --x-margin-um)
      X_MARGIN="${2:-}"
      shift 2
      ;;
    --y-margin-um)
      Y_MARGIN="${2:-}"
      shift 2
      ;;
    --instance-margin-um)
      INSTANCE_MARGIN="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$RUN" ]]; then
  echo "ERROR: --run is required" >&2
  usage >&2
  exit 2
fi

if [[ ! -d "$RUN" ]]; then
  echo "ERROR: run directory not found: $RUN" >&2
  exit 1
fi

if [[ ! -r "$SOURCE_LEF" ]]; then
  echo "ERROR: source LEF not readable: $SOURCE_LEF" >&2
  exit 1
fi

RUN_ID="$(basename "$RUN")"
MARKERS="${MARKERS:-$RUN/reports/route_drc_markers.tsv}"
FAILED_DEF="${FAILED_DEF:-$RUN/def/04_route_failed.def}"
LOC="$RUN/local_route_drc_probe_v2"

if [[ ! -r "$MARKERS" ]]; then
  echo "ERROR: route marker TSV not readable: $MARKERS" >&2
  exit 1
fi

if [[ ! -r "$FAILED_DEF" ]]; then
  echo "ERROR: failed-route DEF not readable: $FAILED_DEF" >&2
  exit 1
fi

if [[ -z "$OUT_LEF" ]]; then
  OUT_LEF="/sim/ksabra/SPADMIC_work/lef/${MACRO}_pnr_pin_access_${RUN_ID}_v2.lef"
fi

SOURCE_LEF_REAL="$(readlink -f "$SOURCE_LEF" 2>/dev/null || printf '%s' "$SOURCE_LEF")"
OUT_LEF_REAL="$(readlink -m "$OUT_LEF" 2>/dev/null || printf '%s' "$OUT_LEF")"
if [[ "$SOURCE_LEF_REAL" == "$OUT_LEF_REAL" ]]; then
  echo "ERROR: refusing to overwrite the source LEF: $SOURCE_LEF" >&2
  exit 1
fi
if [[ -e "$OUT_LEF" ]]; then
  echo "ERROR: output LEF already exists; choose a fresh path: $OUT_LEF" >&2
  exit 1
fi

OUT_SUMMARY="${OUT_LEF%.lef}.summary.txt"
mkdir -p "$LOC" "$(dirname "$OUT_LEF")"

python3 "$SCRIPT_DIR/build_ro_route_drc_probe.py" \
  --markers "$MARKERS" \
  --def "$FAILED_DEF" \
  --lef "$SOURCE_LEF" \
  --macro "$MACRO" \
  --out-dir "$LOC" \
  --instance-margin-um "$INSTANCE_MARGIN"

python3 "$SCRIPT_DIR/audit_ro_marker_vs_lef.py" \
  --markers "$LOC/ro_marker_to_inst_audit.tsv" \
  --instances "$LOC/ro_instance_boxes.tsv" \
  --lef "$SOURCE_LEF" \
  --macro "$MACRO" \
  --out-tsv "$LOC/ro_marker_vs_lef_oriented.tsv" \
  --summary "$LOC/ro_marker_vs_lef_oriented_summary.txt"

python3 "$SCRIPT_DIR/generate_ro_pnr_lef_access.py" \
  --source-lef "$SOURCE_LEF" \
  --audit-tsv "$LOC/ro_marker_vs_lef_oriented.tsv" \
  --out-lef "$OUT_LEF" \
  --summary "$OUT_SUMMARY" \
  --macro "$MACRO" \
  --x-margin-um "$X_MARGIN" \
  --y-margin-um "$Y_MARGIN"

summary_count() {
  local kind="$1"
  local name="$2"
  awk -v kind="$kind" -v name="$name" \
    '$1 == kind && $2 == name {count += $3} END {print count + 0}' "$OUT_SUMMARY"
}

PREP_STATUS=PASS
REQUIRED_PIN_SET_STATUS=PASS
UNEXPECTED_ACCESS_PIN_COUNT="$(awk '
  $1 == "ACCESS_WINDOWS_BY_PIN" &&
  $2 !~ /^S\[[0-7]\]$/ && $2 != "rstb" {count += $3}
  END {print count + 0}
' "$OUT_SUMMARY")"
MET2_WINDOW_COUNT="$(summary_count ACCESS_WINDOWS_BY_LAYER MET2)"
MET3_WINDOW_COUNT="$(summary_count ACCESS_WINDOWS_BY_LAYER MET3)"
OBS_RECTS_TOUCHED="$(sed -n 's/^OBS_RECTS_TOUCHED=//p' "$OUT_SUMMARY" | tail -1)"

for pin in 'S[0]' 'S[1]' 'S[2]' 'S[3]' 'S[4]' 'S[5]' 'S[6]' 'S[7]' rstb; do
  count="$(summary_count ACCESS_WINDOWS_BY_PIN "$pin")"
  if [[ "$count" -lt 1 ]]; then
    REQUIRED_PIN_SET_STATUS=FAIL
    PREP_STATUS=FAIL
  fi
done
if [[ "$UNEXPECTED_ACCESS_PIN_COUNT" -ne 0 || "$MET2_WINDOW_COUNT" -lt 1 || \
      "$MET3_WINDOW_COUNT" -lt 1 || ! "$OBS_RECTS_TOUCHED" =~ ^[1-9][0-9]*$ ]]; then
  PREP_STATUS=FAIL
fi

SOURCE_LEF_SHA256="$(sha256sum "$SOURCE_LEF" | awk '{print $1}')"
OUT_LEF_SHA256="$(sha256sum "$OUT_LEF" | awk '{print $1}')"
{
  echo
  echo "MARKERS=$MARKERS"
  echo "FAILED_DEF=$FAILED_DEF"
  echo "SOURCE_LEF_SHA256=$SOURCE_LEF_SHA256"
  echo "OUTPUT_LEF_SHA256=$OUT_LEF_SHA256"
  echo "REQUIRED_ACCESS_PIN_SET=S[0],S[1],S[2],S[3],S[4],S[5],S[6],S[7],rstb"
  echo "REQUIRED_ACCESS_PIN_SET_STATUS=$REQUIRED_PIN_SET_STATUS"
  echo "UNEXPECTED_ACCESS_PIN_COUNT=$UNEXPECTED_ACCESS_PIN_COUNT"
  echo "MET2_ACCESS_WINDOW_COUNT=$MET2_WINDOW_COUNT"
  echo "MET3_ACCESS_WINDOW_COUNT=$MET3_WINDOW_COUNT"
  echo "PNR_LEF_PREP_STATUS=$PREP_STATUS"
} >> "$OUT_SUMMARY"

{
  echo "# RO_tune6 PnR LEF preparation"
  echo "RUN=$RUN"
  echo "RUN_ID=$RUN_ID"
  echo "SOURCE_LEF=$SOURCE_LEF"
  echo "MARKERS=$MARKERS"
  echo "FAILED_DEF=$FAILED_DEF"
  echo "OUT_LEF=$OUT_LEF"
  echo "OUT_SUMMARY=$OUT_SUMMARY"
  echo "LOCAL_PROBE_DIR=$LOC"
  echo "X_MARGIN_UM=$X_MARGIN"
  echo "Y_MARGIN_UM=$Y_MARGIN"
  echo "INSTANCE_MARGIN_UM=$INSTANCE_MARGIN"
  echo
  sed -n '1,80p' "$LOC/ro_route_drc_probe_summary.txt"
  echo
  sed -n '1,80p' "$LOC/ro_marker_vs_lef_oriented_summary.txt"
  echo
  sed -n '1,120p' "$OUT_SUMMARY"
} | tee "$LOC/prepare_ro_pnr_lef_summary.txt"

if [[ "$PREP_STATUS" != PASS ]]; then
  echo "ERROR: generated PnR LEF failed the bounded access-window gate" >&2
  exit 1
fi

cat <<EOF

Generated PnR-only LEF:
  $OUT_LEF

PNR_LEF_PREP_STATUS=PASS

Use this for the next focused diagnostic:
  export O1_RO_SOURCE_LEF_PATH=$SOURCE_LEF
  export O1_RO_LEF_PATH=$OUT_LEF
EOF
