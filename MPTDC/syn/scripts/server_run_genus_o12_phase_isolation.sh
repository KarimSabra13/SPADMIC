#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_o12_phase_isolation}"
RUN_MODE="${MPTDC_O12_MODE:-typical_synth}"
if [[ "${MPTDC_O12_VALIDATE_ONLY:-0}" == "1" ]]; then
  RUN_MODE="validate_only"
fi

RESULT_DIR="$REPO_ROOT/results/genus_osc_pd/$RUN_ID"
SNAPSHOT_TAG="genus_osc_pd_${RUN_ID}"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
GENUS_LOG="$RESULT_DIR/genus_${RUN_ID}.log"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
FREQ_DEFINES="$SYN_DIR/inputs/mptdc_freq_modes.defines"
O12_SDC="${O12_SDC_PATH:-$SYN_DIR/inputs/mptdc_osc_typical_r750_delta5_o12_phase_buffers.sdc}"
O12_FILELIST="${O12_FILELIST_PATH:-$SYN_DIR/filelist_o12_phase_isolation.f}"
DEFAULT_EXPORT_RUN_ID="${O1_RO_EXPORT_RUN_ID:-20260528_o1_export_ro_tune4_lef}"
DEFAULT_REAL_LEF="$REPO_ROOT/results/osc_pd/$DEFAULT_EXPORT_RUN_ID/real_abstract_lef/RO_tune4_real_abstract.lef"
DEFAULT_REAL_LIB="$SYN_DIR/macros/RO_tune4_real_abstract_shell.lib"
SC_ROOT_PATH="${SC_ROOT:-/data/pdk/xfab/xh018/diglibs/D_CELLS_HD/v6_0}"
STDCELL_TC_LIB="${SC_ROOT_PATH}/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib"

case "$RUN_ID" in
  ""|"/"|".")
    echo "ERROR: unsafe RUN_ID: '$RUN_ID'" >&2
    exit 2
    ;;
  *"/"*|".."*)
    echo "ERROR: RUN_ID must be a simple directory name, got '$RUN_ID'" >&2
    exit 2
    ;;
esac

case "$RUN_MODE" in
  validate_only|typical_synth) ;;
  *)
    echo "ERROR: unsupported MPTDC_O12_MODE=$RUN_MODE" >&2
    echo "Supported: validate_only, typical_synth" >&2
    exit 2
    ;;
esac

rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR" "$SYN_DIR/logs"

{
  echo "# O12 Phase Isolation Buffer Genus Run"
  echo "date: $(date -Iseconds)"
  echo "hostname: $(hostname)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "expected_head: ${EXPECTED_HEAD:-unset}"
  echo "run_id: $RUN_ID"
  echo "run_mode: $RUN_MODE"
  echo "snapshot_tag: $SNAPSHOT_TAG"
  echo "labels: O12_PHASE_ISOLATION_BUFFER_EXPERIMENT TYPICAL_ONLY NOT_MMMC NOT_FINAL_SIGNOFF"
  echo "packet_format: unchanged"
  echo "nfast_encoding: raw_lfsr_tag"
  echo "frequency_mode: r750_delta5"
  echo
  echo "git status --short:"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo
} | tee "$RESULT_DIR/run_manifest.txt" | tee "$GENUS_LOG"

INPUT_RC=0
require_file() {
  local label="$1"
  local path="$2"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: missing $label: $path" | tee -a "$GENUS_LOG"
    INPUT_RC=2
  fi
}

ACTUAL_HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
if [[ -n "${EXPECTED_HEAD:-}" && "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ]]; then
  echo "ERROR: HEAD mismatch. expected=$EXPECTED_HEAD actual=$ACTUAL_HEAD" | tee -a "$GENUS_LOG"
  INPUT_RC=5
fi

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
else
  echo "ERROR: missing O1/O9 env file: $ENV_FILE" | tee -a "$GENUS_LOG"
  INPUT_RC=2
fi

REAL_LEF="${O1_RO_LEF_PATH:-$DEFAULT_REAL_LEF}"
REAL_LIB="${O1_RO_LIBERTY_PATH:-$DEFAULT_REAL_LIB}"

require_file "RO_tune4 real LEF" "$REAL_LEF"
require_file "RO_tune4 Liberty shell" "$REAL_LIB"
require_file "O12 SDC overlay" "$O12_SDC"
require_file "O12 HDL filelist" "$O12_FILELIST"
require_file "frequency-mode defines" "$FREQ_DEFINES"

if [[ -f "$REAL_LEF" ]]; then
  MACRO_NAME="$(awk '/^[[:space:]]*MACRO[[:space:]]+/ {print $2; exit}' "$REAL_LEF")"
  echo "O12 real LEF: $REAL_LEF" | tee -a "$GENUS_LOG"
  echo "O12 real LEF macro: ${MACRO_NAME:-unknown}" | tee -a "$GENUS_LOG"
  if [[ "${MACRO_NAME:-}" != "RO_tune4" ]]; then
    echo "ERROR: LEF macro '${MACRO_NAME:-unknown}' does not match expected RO_tune4" | tee -a "$GENUS_LOG"
    INPUT_RC=3
  fi
fi

if [[ "$INPUT_RC" == "0" ]] && [[ "$RUN_MODE" != "validate_only" ]] && ! command -v genus >/dev/null 2>&1; then
  echo "ERROR: genus not found in PATH; run on the lab server." | tee -a "$GENUS_LOG"
  INPUT_RC=127
fi

export MPTDC_TIMING_VIEW=tc_only
export MPTDC_TC_ONLY_VIEW=1
export MPTDC_FREQ_MODE=r750_delta5
export MPTDC_FREQ_MODE_DEFINES="$FREQ_DEFINES"
export O1_USE_REAL_RO_ABSTRACT=1
export O1_RO_LEF_PATH="$REAL_LEF"
export O1_RO_LIBERTY_PATH="$REAL_LIB"
export MPTDC_USE_RO_TUNE4_MACRO=1
export MPTDC_READ_HDL_LIST="$O12_FILELIST"
export MPTDC_OSC_PD_USE_PROVISIONAL=0
export MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY=0
export MPTDC_OSC_PD_SDC_OVERLAY="$O12_SDC"
export O1_RUN_FLAVOR="O12_PHASE_ISOLATION_BUFFER_EXPERIMENT"
export GENUS_EFFORT="${O12_GENUS_EFFORT:-closure}"
export MPTDC_OPT_GOAL="o12_phase_isolation_buffer_experiment"
export MPTDC_OSC_SLOW_PERIOD_NS="${O12_OSC_SLOW_PERIOD_NS:-1.430}"
export MPTDC_OSC_FAST_PERIOD_NS="${O12_OSC_FAST_PERIOD_NS:-1.333}"
export MPTDC_OSC_SLOW_TAP_STEP_NS="${O12_OSC_SLOW_TAP_STEP_NS:-0.079}"
export MPTDC_OSC_FAST_TAP_STEP_NS="${O12_OSC_FAST_TAP_STEP_NS:-0.074}"
export MPTDC_ENABLE_CLOCK_GATING="${O12_ENABLE_CLOCK_GATING:-0}"
export MPTDC_ALLOW_ICG_DONT_USE_OVERRIDE="${O12_ALLOW_ICG_DONT_USE_OVERRIDE:-0}"
export MPTDC_ALLOW_DISCRETE_CLOCK_GATING="${O12_ALLOW_DISCRETE_CLOCK_GATING:-0}"
export MPTDC_RELAX_PD_PRESERVE="${O12_RELAX_PD_PRESERVE:-1}"

{
  echo
  echo "O12 inputs:"
  echo "  STDCELL_TC_LIB=$STDCELL_TC_LIB"
  echo "  REAL_LEF=$REAL_LEF"
  echo "  REAL_LIB=$REAL_LIB"
  echo "  O12_SDC=$O12_SDC"
  echo "  O12_FILELIST=$O12_FILELIST"
  echo "  MPTDC_FREQ_MODE=$MPTDC_FREQ_MODE"
  echo "  GENUS_EFFORT=$GENUS_EFFORT"
  echo "  MPTDC_TIMING_VIEW=$MPTDC_TIMING_VIEW"
  echo "  PHASE_BUFFER_TOPOLOGY=one BUHDX4 per tap"
  echo "  PHASE_BUFFER_DEFINE=MPTDC_PHASE_BUFFER_USE_BUHDX4"
  echo
} | tee -a "$RESULT_DIR/run_manifest.txt" | tee -a "$GENUS_LOG"

GENUS_RC="$INPUT_RC"
if [[ "$INPUT_RC" == "0" && "$RUN_MODE" == "validate_only" ]]; then
  echo "MPTDC_O12_VALIDATE_ONLY=1: input validation passed; Genus not launched." | tee -a "$GENUS_LOG"
  GENUS_RC=0
elif [[ "$INPUT_RC" == "0" ]]; then
  echo "[GENUS_O12] Cleaning generated synthesis outputs/reports for a non-stale run" | tee -a "$GENUS_LOG"
  rm -rf "$SYN_DIR/reports/synthesis" "$SYN_DIR/outputs"
  mkdir -p "$SYN_DIR/reports" "$SYN_DIR/outputs" "$SYN_DIR/logs"

  echo "[GENUS_O12] Starting TC-only O12 phase-isolation synthesis" | tee -a "$GENUS_LOG"
  (
    cd "$SCRIPT_DIR"
    genus -files genus.tcl -log "../logs/genus_o12_phase_isolation.log"
  ) 2>&1 | tee -a "$GENUS_LOG"
  GENUS_RC=${PIPESTATUS[0]}
fi

SNAPSHOT_RC=0
if [[ "$RUN_MODE" != "validate_only" ]]; then
  echo "[SNAPSHOT] Collecting Genus O12 snapshot into $SNAPSHOT_DIR" | tee -a "$GENUS_LOG"
  if ! bash "$SCRIPT_DIR/collect_snapshot.sh" "$SNAPSHOT_TAG" >> "$GENUS_LOG" 2>&1; then
    SNAPSHOT_RC=$?
    echo "WARNING: collect_snapshot.sh failed with rc=$SNAPSHOT_RC" | tee -a "$GENUS_LOG"
  fi

  if [[ -d "$SNAPSHOT_DIR" ]]; then
    cp -a "$SNAPSHOT_DIR/." "$RESULT_DIR/"
  fi
fi

cp "$GENUS_LOG" "$RESULT_DIR/genus_${RUN_ID}.log" 2>/dev/null || true
cp "$O12_SDC" "$RESULT_DIR/final_sdc_overlay_used.sdc" 2>/dev/null || true
cp "$O12_FILELIST" "$RESULT_DIR/final_filelist_used.f" 2>/dev/null || true

POSTSYN_NETLIST="$RESULT_DIR/mptdc_top_asic.postsyn.v"
if [[ ! -f "$POSTSYN_NETLIST" ]]; then
  POSTSYN_NETLIST="$SYN_DIR/outputs/mptdc_top_asic.postsyn.v"
fi

RO_COUNT=0
STUB_COUNT=0
BUHDX4_COUNT=0
PHASE_BUF_TEXT_COUNT=0
CLOCKS_ON_RO=0
BUFFER_CLOCKS=0
if [[ -f "$POSTSYN_NETLIST" ]]; then
  RO_COUNT="$(grep -cE '^[[:space:]]*RO_tune4[[:space:]]+' "$POSTSYN_NETLIST" || true)"
  STUB_COUNT="$(grep -cE 'mptdc_osc_stub' "$POSTSYN_NETLIST" || true)"
  BUHDX4_COUNT="$(grep -cE '^[[:space:]]*BUHDX4[[:space:]]+' "$POSTSYN_NETLIST" || true)"
  PHASE_BUF_TEXT_COUNT="$(grep -cE 'u_phase_buf_slow|u_phase_buf_fast|mptdc_phase_buffer_bank' "$POSTSYN_NETLIST" || true)"
fi
if [[ -f "$RESULT_DIR/report_clocks.rpt" ]]; then
  CLOCKS_ON_RO="$(grep -cE 'u_ro_tune4.*/?S\[[0-7]\]|u_ro_tune4.*S\[[0-7]\]' "$RESULT_DIR/report_clocks.rpt" || true)"
  BUFFER_CLOCKS="$(grep -cE 'clk_osc_(slow|fast)_buf_tap[0-7]' "$RESULT_DIR/report_clocks.rpt" || true)"
fi

CHECK_REPORT="$RESULT_DIR/o12_phase_isolation_check.rpt"
{
  echo "# O12 Phase Isolation Check"
  echo
  echo "post_synth_netlist=$POSTSYN_NETLIST"
  echo "ro_tune4_count=$RO_COUNT"
  echo "mptdc_osc_stub_count=$STUB_COUNT"
  echo "buhdx4_count=$BUHDX4_COUNT"
  echo "phase_buffer_text_count=$PHASE_BUF_TEXT_COUNT"
  echo "report_clocks_ro_pin_count=$CLOCKS_ON_RO"
  echo "report_clocks_buffer_clock_count=$BUFFER_CLOCKS"
  echo
  if [[ -f "$POSTSYN_NETLIST" ]]; then
    echo "## RO_tune4 instances"
    grep -nE '^[[:space:]]*RO_tune4[[:space:]]+' "$POSTSYN_NETLIST" || true
    echo
    echo "## O12 phase-buffer cells"
    grep -nE 'BUHDX4|u_phase_buf_slow|u_phase_buf_fast|mptdc_phase_buffer_bank' "$POSTSYN_NETLIST" || true
    echo
    echo "## forbidden structure residues"
    grep -nE 'mptdc_osc_stub|u_fast_cnt|u_slow_cnt|gray_src_cont_q|gray_snap_ff|dst_count_latched' "$POSTSYN_NETLIST" || true
  else
    echo "ERROR: post-synthesis netlist not found"
  fi
} > "$CHECK_REPORT"

STATUS="O12_SERVER_REVIEW_REQUIRED"
if [[ "$RUN_MODE" == "validate_only" ]]; then
  STATUS="O12_VALIDATE_ONLY_OK"
elif [[ "$RO_COUNT" == "2" && "$STUB_COUNT" == "0" && "$BUHDX4_COUNT" -ge 16 ]]; then
  STATUS="O12_NETLIST_CANDIDATE"
fi

{
  echo "# Genus O12 Phase Isolation Buffer Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run mode: \`$RUN_MODE\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Genus exit code: $GENUS_RC"
  echo "- Snapshot exit code: $SNAPSHOT_RC"
  echo "- Signoff status: \`TYPICAL_ONLY_NOT_MMMC_NOT_FINAL_SIGNOFF\`"
  echo "- Frequency mode: \`r750_delta5\`"
  echo "- Packet format: unchanged"
  echo "- NFAST encoding: \`raw_lfsr_tag\`"
  echo "- Phase buffer topology: \`one BUHDX4 per tap\`"
  echo "- HDL filelist: \`$O12_FILELIST\`"
  echo "- SDC overlay: \`$O12_SDC\`"
  echo "- RO_tune4 instance count: $RO_COUNT"
  echo "- mptdc_osc_stub residue count: $STUB_COUNT"
  echo "- BUHDX4 phase-buffer instance count: $BUHDX4_COUNT"
  echo "- phase-buffer hierarchy text count: $PHASE_BUF_TEXT_COUNT"
  echo "- report_clocks RO_tune4/S match count: $CLOCKS_ON_RO"
  echo "- report_clocks buffer generated-clock count: $BUFFER_CLOCKS"
  echo
  echo "O12_STATUS=$STATUS"
  echo "FINAL_SIGNOFF=NO"
  echo "INNOVUS_READY=RUN_O12_LOAD_FEASIBILITY_AFTER_REVIEW"
  echo
  echo "## Key Files"
  for file in \
    "genus_${RUN_ID}.log" \
    mptdc_top_asic.postsyn.v \
    mptdc_top_asic.postsyn.sdc \
    final_sdc_overlay_used.sdc \
    final_filelist_used.f \
    o12_phase_isolation_check.rpt \
    run_manifest.txt \
    report_clocks.rpt \
    report_design_rules.rpt \
    report_high_fanout.rpt \
    timing_summary.rpt \
    timing_violations.rpt \
    timing_pd_capture_hotspots.rpt \
    timing_clk_sys_violations.rpt; do
    if [[ -f "$RESULT_DIR/$file" ]]; then
      echo "- present: \`$file\`"
    else
      echo "- missing: \`$file\`"
    fi
  done
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"

if [[ "$GENUS_RC" != "0" ]]; then
  exit "$GENUS_RC"
fi
if [[ "$SNAPSHOT_RC" != "0" ]]; then
  exit "$SNAPSHOT_RC"
fi
[[ "$STATUS" == "O12_NETLIST_CANDIDATE" || "$STATUS" == "O12_VALIDATE_ONLY_OK" ]]
