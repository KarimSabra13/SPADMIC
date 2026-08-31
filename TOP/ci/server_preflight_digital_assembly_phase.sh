#!/usr/bin/env bash

###############################################################################
# Hash-bound CPU-only preflight for one cumulative digital assembly phase.
# No Genus, Innovus, PVS, or OA mutation is performed by this transaction.
#
# Usage:
#   bash TOP/ci/server_preflight_digital_assembly_phase.sh \
#     <expected-head> <phase> <immutable-assembly-audit-root>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
PHASE="${2:-MISSING}"
AUDIT_ROOT="${3:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_ROOT="$WORK_ROOT/diagnostics/digital_assembly_phase_preflight_${PHASE}_${TIMESTAMP}"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
SCRIPT_GATE_RC=NOT_RUN
AUDIT_MANIFEST_RC=NOT_RUN
AUDIT_STATUS_GATE_RC=NOT_RUN
PORTFOLIO_RC=NOT_RUN
PHASE_CONTRACT_RC=NOT_RUN
FILELIST_RC=NOT_RUN
VERILATOR_RC=NOT_RUN
BOUNDARY_RC=NOT_RUN
SCALAR_GENERATOR_RC=NOT_RUN
MANIFEST_RC=NOT_RUN

case "$PHASE" in
  p00_tx) TOP_MODULE=spadmic_digital_assembly_v1_p00_tx ;;
  p01_position) TOP_MODULE=spadmic_digital_assembly_v1_p01_position ;;
  p02_event_control) TOP_MODULE=spadmic_digital_assembly_v1_p02_event_control ;;
  p03_matrix_interface) TOP_MODULE=spadmic_digital_assembly_v1_p03_matrix_interface ;;
  *)
    TOP_MODULE=UNKNOWN
    echo "STOP_HERE_DO_NOT_CONTINUE: unsupported assembly phase: $PHASE"
    RUN_OK=0
    ;;
esac

if [ "$EXPECTED_HEAD" = "MISSING" ] || [ "$AUDIT_ROOT" = "MISSING" ]; then
  echo "STOP_HERE_DO_NOT_CONTINUE: expected HEAD, phase, and audit root are required"
  RUN_OK=0
fi

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

  SCRIPT_GATE_RC=0
  for FILE in \
    TOP/pnr/assembly/spadmic_digital_assembly_contract.json \
    TOP/pnr/assembly/spadmic_digital_assembly_v1.sv \
    TOP/pnr/scripts/gen_spadmic_digital_assembly_v1.py \
    TOP/pnr/scripts/validate_digital_subblock_portfolio.py \
    TOP/syn/scripts/collect_verilator_boundary.py
  do
    if [ ! -s "$FILE" ]; then
      echo "MISSING_OR_EMPTY=$FILE"
      SCRIPT_GATE_RC=1
    fi
  done

  echo "CHECKOUT_RC=$CHECKOUT_RC"
  echo "PULL_RC=$PULL_RC"
  echo "EXPECTED_HEAD=$EXPECTED_HEAD"
  echo "ACTUAL_HEAD=$ACTUAL_HEAD"
  echo "TRACKED_DIFF_RC=$TRACKED_DIFF_RC"
  echo "STAGED_DIFF_RC=$STAGED_DIFF_RC"
  echo "SCRIPT_GATE_RC=$SCRIPT_GATE_RC"
  git status --short --branch --untracked-files=no

  if [ "$CHECKOUT_RC" != "0" ] || \
     [ "$PULL_RC" != "0" ] || \
     [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ] || \
     [ "$TRACKED_DIFF_RC" != "0" ] || \
     [ "$STAGED_DIFF_RC" != "0" ] || \
     [ "$SCRIPT_GATE_RC" != "0" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: checkout is not attributable"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  if [ -r "$AUDIT_ROOT/SHA256SUMS" ]; then
    (
      cd "$AUDIT_ROOT"
      LOCAL_CD_RC=$?
      if [ "$LOCAL_CD_RC" = "0" ]; then
        sha256sum -c SHA256SUMS
      else
        false
      fi
    )
    AUDIT_MANIFEST_RC=$?
  else
    AUDIT_MANIFEST_RC=1
  fi
  if [ -r "$AUDIT_ROOT/assembly_audit_status.rpt" ]; then
    grep -Fxq 'STATUS=PASS' "$AUDIT_ROOT/assembly_audit_status.rpt"
    AUDIT_STATUS_GATE_RC=$?
    if [ "$PHASE" = "p03_matrix_interface" ]; then
      grep -Fxq 'P03_IMPLEMENTATION_AUTHORIZED=YES' "$AUDIT_ROOT/assembly_audit_status.rpt"
    else
      grep -Fxq 'P00_P02_IMPLEMENTATION_AUTHORIZED=YES' "$AUDIT_ROOT/assembly_audit_status.rpt"
    fi
    if [ "$?" != "0" ]; then
      AUDIT_STATUS_GATE_RC=1
    fi
  else
    AUDIT_STATUS_GATE_RC=1
  fi
  echo "AUDIT_MANIFEST_RC=$AUDIT_MANIFEST_RC"
  echo "AUDIT_STATUS_GATE_RC=$AUDIT_STATUS_GATE_RC"
  if [ "$AUDIT_MANIFEST_RC" != "0" ] || [ "$AUDIT_STATUS_GATE_RC" != "0" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable assembly audit gate failed"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  mkdir -p "$OUTPUT_ROOT/filelists" "$OUTPUT_ROOT/boundary" "$OUTPUT_ROOT/logs" "$OUTPUT_ROOT/phase_contract"
  if [ "$?" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  python3 TOP/pnr/scripts/validate_digital_subblock_portfolio.py \
    --status "$OUTPUT_ROOT/portfolio_status.rpt" \
    > "$OUTPUT_ROOT/logs/portfolio.log" 2>&1
  PORTFOLIO_RC=$?

  python3 TOP/pnr/scripts/gen_spadmic_digital_assembly_v1.py \
    --phase "$PHASE" \
    --audit-root "$AUDIT_ROOT" \
    --out "$OUTPUT_ROOT/phase_contract" \
    > "$OUTPUT_ROOT/logs/phase_contract.log" 2>&1
  PHASE_CONTRACT_RC=$?

  python3 TOP/scripts/generate_tx_src_data_flat.py --check \
    > "$OUTPUT_ROOT/logs/scalar_generator.log" 2>&1
  SCALAR_GENERATOR_RC=$?

  echo "PORTFOLIO_RC=$PORTFOLIO_RC"
  echo "PHASE_CONTRACT_RC=$PHASE_CONTRACT_RC"
  echo "SCALAR_GENERATOR_RC=$SCALAR_GENERATOR_RC"
  if [ "$PORTFOLIO_RC" != "0" ] || \
     [ "$PHASE_CONTRACT_RC" != "0" ] || \
     [ "$SCALAR_GENERATOR_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  source TOP/scripts/sim/resolve_flist.sh
  resolve_flist "$REPO/MPTDC" "$REPO/MPTDC/rtl/filelist.f" "$OUTPUT_ROOT/filelists/mptdc_abs.f"
  MPTDC_FLIST_RC=$?
  resolve_flist "$REPO/TOP" "$REPO/TOP/filelist.f" "$OUTPUT_ROOT/filelists/top_abs.raw.f"
  TOP_FLIST_RC=$?
  grep -v -E '/TOP/rtl/spadmic_ddr_tx\.sv$' \
    "$OUTPUT_ROOT/filelists/top_abs.raw.f" > "$OUTPUT_ROOT/filelists/top_abs.f"
  FILTER_RC=$?
  if [ "$MPTDC_FLIST_RC" = "0" ] && [ "$TOP_FLIST_RC" = "0" ] && [ "$FILTER_RC" = "0" ]; then
    FILELIST_RC=0
  else
    FILELIST_RC=1
    RUN_OK=0
  fi
  echo "FILELIST_RC=$FILELIST_RC"
fi

if [ "$RUN_OK" = "1" ]; then
  verilator --xml-only --timing \
    -Wno-fatal -Wno-DECLFILENAME -Wno-UNUSED -Wno-UNDRIVEN \
    -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-PINCONNECTEMPTY \
    -Wno-SYNCASYNCNET -Wno-UNOPTFLAT \
    +define+MPTDC_USE_OSC_MODEL \
    -f "$OUTPUT_ROOT/filelists/mptdc_abs.f" \
    -f "$OUTPUT_ROOT/filelists/top_abs.f" \
    --top-module "$TOP_MODULE" \
    --xml-output "$OUTPUT_ROOT/boundary/verilator.xml" \
    > "$OUTPUT_ROOT/logs/verilator.log" 2>&1
  VERILATOR_RC=$?
  if [ "$VERILATOR_RC" = "0" ]; then
    python3 TOP/syn/scripts/collect_verilator_boundary.py \
      --xml "$OUTPUT_ROOT/boundary/verilator.xml" \
      --top "$TOP_MODULE" \
      --out "$OUTPUT_ROOT/boundary" \
      > "$OUTPUT_ROOT/logs/boundary.log" 2>&1
    BOUNDARY_RC=$?
  fi
  echo "VERILATOR_RC=$VERILATOR_RC"
  echo "BOUNDARY_RC=$BOUNDARY_RC"
  if [ "$VERILATOR_RC" != "0" ] || [ "$BOUNDARY_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

STATUS_REPORT="$OUTPUT_ROOT/digital_assembly_phase_preflight_status.rpt"
if [ "$RUN_OK" = "1" ]; then
  STATUS_VALUE=PASS
  RESULT=PHASE_READY_FOR_ONE_FOREGROUND_GENUS_TC_RUN
  NEXT_GATE=REVIEW_PREFLIGHT_THEN_RUN_PHASE_GENUS_TC
else
  STATUS_VALUE=FAIL
  RESULT=PHASE_PREFLIGHT_REVIEW_REQUIRED
  NEXT_GATE=STOP_AND_REVIEW_PHASE_PREFLIGHT
fi

if [ -d "$OUTPUT_ROOT" ]; then
  {
    echo "LABEL=SPADMIC_DIGITAL_ASSEMBLY_PHASE_PREFLIGHT"
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
    echo "AUDIT_ROOT=$AUDIT_ROOT"
    echo "AUDIT_MANIFEST_RC=$AUDIT_MANIFEST_RC"
    echo "AUDIT_STATUS_GATE_RC=$AUDIT_STATUS_GATE_RC"
    echo "PORTFOLIO_RC=$PORTFOLIO_RC"
    echo "PHASE_CONTRACT_RC=$PHASE_CONTRACT_RC"
    echo "SCALAR_GENERATOR_RC=$SCALAR_GENERATOR_RC"
    echo "FILELIST_RC=$FILELIST_RC"
    echo "VERILATOR_RC=$VERILATOR_RC"
    echo "BOUNDARY_RC=$BOUNDARY_RC"
    echo "PVS_EXECUTED=NO"
    echo "INNOVUS_EXECUTED=NO"
    echo "GENUS_EXECUTED=NO"
    echo "SIGNOFF_READY=NO"
    echo "NEXT_GATE=$NEXT_GATE"
  } > "$STATUS_REPORT"

  (
    cd "$OUTPUT_ROOT"
    LOCAL_CD_RC=$?
    if [ "$LOCAL_CD_RC" = "0" ]; then
      find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
    else
      false
    fi
  )
  MANIFEST_RC=$?
fi

echo "OUTPUT_ROOT=$OUTPUT_ROOT"
echo "MANIFEST_RC=$MANIFEST_RC"
cat "$STATUS_REPORT" 2>/dev/null

if [ "$RUN_OK" = "1" ] && [ "$MANIFEST_RC" = "0" ]; then
  echo "DIGITAL_ASSEMBLY_PHASE_PREFLIGHT_TRANSACTION_STATUS=PASS"
  echo "RETURN_OUTPUT_FOR_PHASE_GENUS_TC_REVIEW"
  echo "DO_NOT_START_GENUS_UNTIL_REVIEWED"
  true
else
  echo "DIGITAL_ASSEMBLY_PHASE_PREFLIGHT_TRANSACTION_STATUS=FAIL"
  echo "STOP_HERE_DO_NOT_START_GENUS"
  false
fi
