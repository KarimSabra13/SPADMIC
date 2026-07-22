#!/usr/bin/env bash

###############################################################################
# Hash-bound one-action Genus TC execution for a cumulative assembly phase.
#
# Usage:
#   bash TOP/ci/server_run_digital_assembly_phase_genus.sh \
#     <expected-head> <phase> <accepted-preflight-root>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
PHASE="${2:-MISSING}"
PREFLIGHT_ROOT="${3:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_ROOT="$WORK_ROOT/genus/digital_assembly_${PHASE}_${TIMESTAMP}"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
PREFLIGHT_MANIFEST_RC=NOT_RUN
PREFLIGHT_STATUS_GATE_RC=NOT_RUN
GENUS_ENV_RC=NOT_RUN
GENUS_RC=NOT_RUN
GENUS_GATE_RC=NOT_RUN
GENUS_EXECUTED=NO
RUN_MANIFEST_RC=NOT_RUN

case "$PHASE" in
  p00_tx)
    TOP_MODULE=spadmic_digital_assembly_v1_p00_tx
    PRESERVE_PATTERNS="*u_tx_packet_core* *u_tx_ddr_strip*"
    ;;
  p01_position)
    TOP_MODULE=spadmic_digital_assembly_v1_p01_position
    PRESERVE_PATTERNS="*u_tx_packet_core* *u_tx_ddr_strip* *u_position*"
    ;;
  p02_event_control)
    TOP_MODULE=spadmic_digital_assembly_v1_p02_event_control
    PRESERVE_PATTERNS="*u_tx_packet_core* *u_tx_ddr_strip* *u_position* *u_event*"
    ;;
  p03_matrix_interface)
    TOP_MODULE=spadmic_digital_assembly_v1_p03_matrix_interface
    PRESERVE_PATTERNS="*u_tx_packet_core* *u_tx_ddr_strip* *u_position* *u_event* *u_matrix_or_* *u_matrix_snapshot* *u_matrix_reset* *u_matrix_cfg*"
    ;;
  *)
    TOP_MODULE=UNKNOWN
    echo "STOP_HERE_DO_NOT_CONTINUE: unsupported assembly phase: $PHASE"
    RUN_OK=0
    ;;
esac

if [ -d "$REPO/.git" ]; then
  cd "$REPO"
  CD_RC=$?
else
  echo "STOP_HERE_DO_NOT_CONTINUE: repository missing: $REPO"
  CD_RC=1
  RUN_OK=0
fi

if [ "$RUN_OK" = "1" ]; then
  git checkout SPADMIC_test
  CHECKOUT_RC=$?
  if [ "$CHECKOUT_RC" = "0" ]; then
    git pull --ff-only origin SPADMIC_test
    PULL_RC=$?
  fi
  ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
  git diff --quiet
  TRACKED_DIFF_RC=$?
  git diff --cached --quiet
  STAGED_DIFF_RC=$?
  echo "CHECKOUT_RC=$CHECKOUT_RC"
  echo "PULL_RC=$PULL_RC"
  echo "EXPECTED_HEAD=$EXPECTED_HEAD"
  echo "ACTUAL_HEAD=$ACTUAL_HEAD"
  echo "TRACKED_DIFF_RC=$TRACKED_DIFF_RC"
  echo "STAGED_DIFF_RC=$STAGED_DIFF_RC"
  git status --short --branch --untracked-files=no
  if [ "$CHECKOUT_RC" != "0" ] || \
     [ "$PULL_RC" != "0" ] || \
     [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ] || \
     [ "$TRACKED_DIFF_RC" != "0" ] || \
     [ "$STAGED_DIFF_RC" != "0" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: checkout is not attributable"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  if [ -r "$PREFLIGHT_ROOT/SHA256SUMS" ]; then
    (
      cd "$PREFLIGHT_ROOT"
      LOCAL_CD_RC=$?
      if [ "$LOCAL_CD_RC" = "0" ]; then
        sha256sum -c SHA256SUMS
      else
        false
      fi
    )
    PREFLIGHT_MANIFEST_RC=$?
  else
    PREFLIGHT_MANIFEST_RC=1
  fi
  PREFLIGHT_STATUS="$PREFLIGHT_ROOT/digital_assembly_phase_preflight_status.rpt"
  PREFLIGHT_STATUS_GATE_RC=0
  for LINE in \
    'STATUS=PASS' \
    "EXPECTED_HEAD=$EXPECTED_HEAD" \
    "ACTUAL_HEAD=$EXPECTED_HEAD" \
    "PHASE=$PHASE" \
    "TOP_MODULE=$TOP_MODULE" \
    'IMPLEMENTATION=CUMULATIVE_SOFT_LOGIC' \
    'HARD_MACRO_COUNT=0' \
    'VERILATOR_RC=0' \
    'BOUNDARY_RC=0' \
    'GENUS_EXECUTED=NO'
  do
    grep -Fxq "$LINE" "$PREFLIGHT_STATUS" 2>/dev/null
    if [ "$?" != "0" ]; then
      echo "PREFLIGHT_STATUS_LINE_MISSING=$LINE"
      PREFLIGHT_STATUS_GATE_RC=1
    fi
  done
  echo "PREFLIGHT_MANIFEST_RC=$PREFLIGHT_MANIFEST_RC"
  echo "PREFLIGHT_STATUS_GATE_RC=$PREFLIGHT_STATUS_GATE_RC"
  if [ "$PREFLIGHT_MANIFEST_RC" != "0" ] || [ "$PREFLIGHT_STATUS_GATE_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  mkdir -p "$RUN_ROOT/logs" "$RUN_ROOT/reports/timing"
  if [ "$?" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  command -v genus >/dev/null 2>&1
  GENUS_ENV_RC=$?
  if [ "$GENUS_ENV_RC" != "0" ]; then
    echo "STOP_HERE_DO_NOT_START_GENUS: genus is not in PATH"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  GENUS_EXECUTED=YES
  export MPTDC_XH018_STACK="${MPTDC_XH018_STACK:-xx31}"
  export MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}"
  export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-MET1 MET2 MET3 METTP}"
  export MPTDC_PNR_SIGNAL_TOP_LAYER="${MPTDC_PNR_SIGNAL_TOP_LAYER:-MET3}"
  export MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER="${MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER:-METTP}"
  export MPTDC_PNR_POWER_LAYER="${MPTDC_PNR_POWER_LAYER:-METTP}"
  export MPTDC_PNR_PHASE_TOP_LAYER="${MPTDC_PNR_PHASE_TOP_LAYER:-METTP}"

  CONSTRAINT="$REPO/TOP/syn/constraints/assembly/${TOP_MODULE}.sdc"
  SPADMIC_REPO_ROOT="$REPO" \
  SPADMIC_TOP_ROOT="$REPO/TOP" \
  SPADMIC_MPTDC_ROOT="$REPO/MPTDC" \
  GENUS_RUN_DIR="$RUN_ROOT" \
  GENUS_TOP_MODULE="$TOP_MODULE" \
  GENUS_BLOCK_NAME="$TOP_MODULE" \
  GENUS_MPTDC_FILELIST="$PREFLIGHT_ROOT/filelists/mptdc_abs.f" \
  GENUS_TOP_FILELIST="$PREFLIGHT_ROOT/filelists/top_abs.f" \
  GENUS_COMMON_SDC="$CONSTRAINT" \
  GENUS_PRESERVE_HIER_PATTERNS="$PRESERVE_PATTERNS" \
    genus -files TOP/syn/scripts/run_genus_matrix_block.tcl \
      -log "$RUN_ROOT/logs/genus.log" \
      > "$RUN_ROOT/logs/genus.stdout.log" 2>&1
  GENUS_RC=$?
  echo "GENUS_RC=$GENUS_RC"
fi

if [ "$GENUS_RC" = "0" ]; then
  python3 TOP/syn/scripts/validate_genus_digital_assembly_phase.py \
    --phase "$PHASE" \
    --block-root "$RUN_ROOT" \
    --boundary-bits "$PREFLIGHT_ROOT/boundary/rtl_boundary_bits.tsv" \
    --status "$RUN_ROOT/reports/timing/digital_assembly_genus_tc_gate.rpt" \
    > "$RUN_ROOT/logs/genus_gate.log" 2>&1
  GENUS_GATE_RC=$?
  cat "$RUN_ROOT/reports/timing/digital_assembly_genus_tc_gate.rpt" 2>/dev/null
fi

if [ "$GENUS_RC" = "0" ] && [ "$GENUS_GATE_RC" = "0" ]; then
  STATUS_VALUE=PASS
  RESULT=PHASE_GENUS_TC_ACCEPTED_FOR_INNOVUS
  NEXT_GATE=REVIEW_GENUS_TC_THEN_RUN_PHASE_INNOVUS
else
  STATUS_VALUE=FAIL
  RESULT=PHASE_GENUS_TC_REVIEW_REQUIRED
  NEXT_GATE=STOP_AND_REVIEW_PHASE_GENUS_TC
fi

if [ -d "$RUN_ROOT" ]; then
  {
    echo "LABEL=SPADMIC_DIGITAL_ASSEMBLY_PHASE_GENUS_EXECUTION"
    echo "STATUS=$STATUS_VALUE"
    echo "RESULT=$RESULT"
    echo "EXPECTED_HEAD=$EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$ACTUAL_HEAD"
    echo "PHASE=$PHASE"
    echo "TOP_MODULE=$TOP_MODULE"
    echo "SOURCE_TOP=$TOP_MODULE"
    echo "LAYOUT_TOP=$TOP_MODULE"
    echo "IMPLEMENTATION=CUMULATIVE_SOFT_LOGIC"
    echo "HARD_MACRO_COUNT=0"
    echo "SOURCE_PREFLIGHT_ROOT=$PREFLIGHT_ROOT"
    echo "PREFLIGHT_MANIFEST_RC=$PREFLIGHT_MANIFEST_RC"
    echo "PREFLIGHT_STATUS_GATE_RC=$PREFLIGHT_STATUS_GATE_RC"
    echo "GENUS_ENV_RC=$GENUS_ENV_RC"
    echo "GENUS_RC=$GENUS_RC"
    echo "GENUS_GATE_RC=$GENUS_GATE_RC"
    echo "GENUS_EXECUTED=$GENUS_EXECUTED"
    echo "TYPICAL_CLOSED=$(if [ "$GENUS_GATE_RC" = "0" ]; then echo YES; else echo NO; fi)"
    echo "MMMC_STATUS=NOT_RUN_TC_ONLY"
    echo "CDC_RDC_STATUS=STA_ONLY_NO_DEDICATED_TOOL"
    echo "INNOVUS_EXECUTED=NO"
    echo "PVS_EXECUTED=NO"
    echo "SIGNOFF_READY=NO"
    echo "NEXT_GATE=$NEXT_GATE"
  } > "$RUN_ROOT/digital_assembly_genus_execution_status.rpt"
  (
    cd "$RUN_ROOT"
    LOCAL_CD_RC=$?
    if [ "$LOCAL_CD_RC" = "0" ]; then
      find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
    else
      false
    fi
  )
  RUN_MANIFEST_RC=$?
fi

echo "RUN_ROOT=$RUN_ROOT"
echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
cat "$RUN_ROOT/digital_assembly_genus_execution_status.rpt" 2>/dev/null

if [ "$STATUS_VALUE" = "PASS" ] && [ "$RUN_MANIFEST_RC" = "0" ]; then
  echo "DIGITAL_ASSEMBLY_PHASE_GENUS_TRANSACTION_STATUS=PASS"
  echo "RETURN_OUTPUT_FOR_PHASE_GENUS_REVIEW"
  echo "DO_NOT_START_INNOVUS_UNTIL_REVIEWED"
  true
else
  echo "DIGITAL_ASSEMBLY_PHASE_GENUS_TRANSACTION_STATUS=FAIL"
  echo "STOP_HERE_DO_NOT_START_INNOVUS"
  false
fi
