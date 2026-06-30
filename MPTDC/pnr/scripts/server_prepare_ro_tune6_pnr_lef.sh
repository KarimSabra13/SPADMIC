#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN=""
SOURCE_LEF="${O1_RO_SOURCE_LEF_PATH:-/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef}"
OUT_LEF=""
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
MARKERS="$RUN/reports/route_drc_markers.tsv"
FAILED_DEF="$RUN/def/04_route_failed.def"
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

{
  echo "# RO_tune6 PnR LEF preparation"
  echo "RUN=$RUN"
  echo "RUN_ID=$RUN_ID"
  echo "SOURCE_LEF=$SOURCE_LEF"
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

cat <<EOF

Generated PnR-only LEF:
  $OUT_LEF

Use this for the next focused diagnostic:
  export O1_RO_SOURCE_LEF_PATH=$SOURCE_LEF
  export O1_RO_LEF_PATH=$OUT_LEF
EOF
