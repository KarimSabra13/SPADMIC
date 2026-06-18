#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID=""
GENUS_RUN_ID="${MPTDC_GENUS_RUN_ID:-}"
GENUS_RUN_DIR="${MPTDC_GENUS_RUN_DIR:-}"
HANDOFF_DIR="${MPTDC_GENUS_HANDOFF_DIR:-}"
MODE="${MPTDC_DIGITAL_SIGNOFF_MODE:-validate_only}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_innovus_mptdc_digital_signoff.sh <RUN_ID> [options]

Options:
  --genus-run-id <id>     Closed Genus run ID used to build the handoff.
  --genus-run-dir <path>  Explicit closed Genus run directory.
  --handoff-dir <path>    Explicit prepared handoff directory.
  --mode <mode>           validate_only, discover_only, or full_signoff.
  -h, --help              Show this help.

full_signoff launches Innovus and requires:
  MPTDC_DIGITAL_SIGNOFF_APPROVED=1

This is the digital block signoff entrypoint. It must not be replaced by a
renamed typical-feasibility wrapper.
USAGE
}

abs_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$REPO_ROOT" "$path" ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --genus-run-id)
      GENUS_RUN_ID="${2:?missing --genus-run-id value}"
      shift 2
      ;;
    --genus-run-dir)
      GENUS_RUN_DIR="$(abs_path "${2:?missing --genus-run-dir value}")"
      shift 2
      ;;
    --handoff-dir)
      HANDOFF_DIR="$(abs_path "${2:?missing --handoff-dir value}")"
      shift 2
      ;;
    --mode)
      MODE="${2:?missing --mode value}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -z "$RUN_ID" ]]; then
        RUN_ID="$1"
      else
        echo "ERROR: unexpected positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      shift
      ;;
  esac
done

case "$MODE" in
  validate_only|discover_only|full_signoff) ;;
  *)
    echo "ERROR: unsupported MPTDC_DIGITAL_SIGNOFF_MODE=$MODE" >&2
    exit 2
    ;;
esac

RUN_ID="${RUN_ID:-mptdc_digital_signoff_$(date +%Y%m%d_%H%M%S)}"
MPTDC_WORK_ROOT="$(abs_path "${MPTDC_WORK_ROOT:-work}")"
MPTDC_INNOVUS_WORK="$(abs_path "${MPTDC_INNOVUS_WORK:-$MPTDC_WORK_ROOT/innovus}")"
RESULT_DIR="$MPTDC_INNOVUS_WORK/$RUN_ID"
LOG_DIR="$RESULT_DIR/logs"
REPORT_DIR="$RESULT_DIR/reports"
MANIFEST_DIR="$RESULT_DIR/manifests"
mkdir -p "$LOG_DIR" "$REPORT_DIR" "$MANIFEST_DIR"
RUN_LOG="$LOG_DIR/digital_signoff_wrapper.log"

{
  echo "# MPTDC Digital Block Signoff Wrapper"
  echo "Author: Karim Sabra"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "mode: $MODE"
  echo "run_id: $RUN_ID"
  echo "result_dir: $RESULT_DIR"
  echo "genus_run_id: ${GENUS_RUN_ID:-unset}"
  echo "genus_run_dir: ${GENUS_RUN_DIR:-unset}"
  echo "handoff_dir: ${HANDOFF_DIR:-unset}"
  echo "labels: DIGITAL_PNR_SIGNOFF_FLOW NOT_FEASIBILITY_RENAME"
  echo
  echo "git status --short --untracked-files=no:"
  git -C "$REPO_ROOT" status --short --untracked-files=no 2>/dev/null || true
} | tee "$MANIFEST_DIR/run_manifest.txt" | tee "$RUN_LOG"

if [[ "$MODE" != "discover_only" && -n "$(git -C "$REPO_ROOT" status --short --untracked-files=no 2>/dev/null)" ]]; then
  echo "ERROR: tracked working tree must be clean before digital signoff launch." | tee -a "$RUN_LOG"
  exit 3
fi

report_tool_version() {
  local tool="$1"
  local path=""

  echo "===== $tool ====="
  path="$(type -P "$tool" 2>/dev/null || true)"
  if [[ -z "$path" ]]; then
    echo "MISSING"
    return 0
  fi

  if [[ "$tool" == "pvs" && "$path" == "/usr/sbin/pvs" ]]; then
    echo "NON_CADENCE_PVS_PATH=$path"
    echo "CADENCE_PVS_STATUS=MISSING_OR_NOT_IN_PATH"
    return 0
  fi

  echo "$path"
  case "$tool" in
    calibre)
      "$path" -version 2>&1 | head -40 || true
      ;;
    *)
      "$path" -version 2>&1 | head -40 || true
      ;;
  esac
}

{
  for t in innovus genus tempus quantus qrc voltus pvs pegasus calibre xrun verilator; do
    report_tool_version "$t"
  done
} > "$MANIFEST_DIR/tool_versions.rpt"

GATE_ARGS=()
if [[ -n "$GENUS_RUN_ID" ]]; then GATE_ARGS+=(--genus-run-id "$GENUS_RUN_ID"); fi
if [[ -n "$GENUS_RUN_DIR" ]]; then GATE_ARGS+=(--genus-run-dir "$GENUS_RUN_DIR"); fi
if [[ -n "$HANDOFF_DIR" ]]; then GATE_ARGS+=(--handoff-dir "$HANDOFF_DIR"); fi

if [[ "${#GATE_ARGS[@]}" -gt 0 ]]; then
  "$SCRIPT_DIR/check_mptdc_pre_pnr_gate.sh" "${GATE_ARGS[@]}" | tee "$REPORT_DIR/pre_pnr_gate.rpt" | tee -a "$RUN_LOG"
  if ! grep -q '^PRE_PNR_GATE=PASS$' "$REPORT_DIR/pre_pnr_gate.rpt"; then
    echo "ERROR: pre-PNR gate failed." | tee -a "$RUN_LOG"
    exit 4
  fi
else
  if [[ "$MODE" == "discover_only" ]]; then
    echo "INFO: no Genus handoff source passed; discover_only only inspects technology inputs." | tee -a "$RUN_LOG"
  else
    echo "WARN: no Genus handoff source passed; validate_only will not prove netlist handoff." | tee -a "$RUN_LOG"
  fi
fi

if [[ "$MODE" == "discover_only" ]]; then
  "$SCRIPT_DIR/discover_xh018_physical_cells.sh" \
    --root "${MPTDC_PDK_ROOT:-/eda/pdk/xfab/xh018}" \
    --root "${PDK_ROOT:-/data/pdk/xfab/xh018}" \
    --out "$REPORT_DIR/xh018_cells_candidates.tcl" \
    | tee "$REPORT_DIR/xh018_cells_candidates.rpt" | tee -a "$RUN_LOG"
  exit 0
fi

if command -v tclsh >/dev/null 2>&1; then
  set +e
  (
    cd "$REPO_ROOT"
    MPTDC_REPO_ROOT="$REPO_ROOT" \
    MPTDC_SIGNOFF_RESULT_DIR="$RESULT_DIR" \
    MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY=1 \
      tclsh MPTDC/pnr/scripts/innovus_mptdc_digital_signoff.tcl
  ) 2>&1 | tee "$REPORT_DIR/source_check.rpt" | tee -a "$RUN_LOG"
  source_rc=${PIPESTATUS[0]}
  set -e
else
  echo "ERROR: tclsh is required for source validation." | tee -a "$RUN_LOG"
  exit 127
fi

if [[ "$source_rc" != "0" ]]; then
  echo "ERROR: digital signoff source check failed. Review $REPORT_DIR/source_check.rpt" | tee -a "$RUN_LOG"
  exit "$source_rc"
fi

if [[ "$MODE" == "validate_only" ]]; then
  echo "MPTDC_DIGITAL_SIGNOFF_MODE=validate_only: source gates passed; Innovus not launched." | tee -a "$RUN_LOG"
  exit 0
fi

if [[ "${MPTDC_DIGITAL_SIGNOFF_APPROVED:-0}" != "1" ]]; then
  echo "ERROR: full_signoff launches Innovus. Set MPTDC_DIGITAL_SIGNOFF_APPROVED=1 after review." | tee -a "$RUN_LOG"
  exit 5
fi

if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus not found in PATH; run this on the lab server." | tee -a "$RUN_LOG"
  exit 127
fi

(
  cd "$REPO_ROOT"
  MPTDC_REPO_ROOT="$REPO_ROOT" \
  MPTDC_SIGNOFF_RESULT_DIR="$RESULT_DIR" \
    innovus -nowin -init MPTDC/pnr/scripts/innovus_mptdc_digital_signoff.tcl \
      -log "$LOG_DIR/innovus_mptdc_digital_signoff.log"
) 2>&1 | tee -a "$RUN_LOG"
