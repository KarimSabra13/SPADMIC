#!/usr/bin/env bash

###############################################################################
# Perform one reviewed p03 OA insertion after immutable backup preparation.
#
# Usage:
#   bash TOP/ci/server_insert_digital_assembly_p03_into_spadmic2.sh \
#     <expected-head> <accepted-oa-preparation-root>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
PREP_ROOT="${2:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_ROOT="$WORK_ROOT/diagnostics/digital_assembly_p03_oa_insertion_$TIMESTAMP"

TOP_MODULE=spadmic_digital_assembly_v1_p03_matrix_interface
RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
PREP_MANIFEST_RC=NOT_RUN
PREP_STATUS_RC=NOT_RUN
BACKUP_MANIFEST_RC=NOT_RUN
SOURCE_PRECHECK_RC=NOT_RUN
PVS_POSTCHECK_RC=NOT_RUN
AUDIT_POSTCHECK_RC=NOT_RUN
VIRTUOSO_RC=NOT_RUN
OA_MUTATION_ATTEMPTED=NO
OA_MUTATION_EXECUTED=NO
INSERTION_STATUS_RC=NOT_RUN
TARGET_CHANGED_RC=NOT_RUN
CANDIDATE_STABLE_RC=NOT_RUN
TARGET_POST_RC=NOT_RUN
CANDIDATE_POST_RC=NOT_RUN
DIAGNOSTIC_MANIFEST_RC=NOT_RUN
BACKUP_ROOT=UNKNOWN
TARGET_OA_PATH=UNKNOWN
CANDIDATE_OA_PATH=UNKNOWN
PVS_ROOT=UNKNOWN
AUDIT_ROOT=UNKNOWN

check_manifest() {
  local root="$1"
  local manifest="$2"
  if [ ! -r "$manifest" ]; then
    return 1
  fi
  (
    cd "$root"
    local local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      sha256sum -c "$manifest"
    else
      false
    fi
  )
}

require_lines() {
  local file="$1"
  shift
  local rc=0
  local line
  for line in "$@"; do
    grep -Fxq -- "$line" "$file" 2>/dev/null
    if [ "$?" != "0" ]; then
      echo "STATUS_LINE_MISSING=$file|$line"
      rc=1
    fi
  done
  return "$rc"
}

inventory_tree() {
  local root="$1"
  local output="$2"
  if [ ! -d "$root" ]; then
    return 1
  fi
  find "$root" -type f -print0 2>/dev/null | sort -z | xargs -0 -r sha256sum > "$output"
}

if [ "$EXPECTED_HEAD" = "MISSING" ] || [ "$PREP_ROOT" = "MISSING" ]; then
  echo "STOP_HERE_DO_NOT_CONTINUE: expected HEAD and OA preparation root are required"
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
  if [ -d "$PREP_ROOT" ]; then
    PREP_ROOT="$(cd "$PREP_ROOT" && pwd -P)"
  else
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  mkdir -p "$OUTPUT_ROOT/logs" "$OUTPUT_ROOT/source_preparation" "$OUTPUT_ROOT/source_identity"
  if [ "$?" != "0" ]; then
    RUN_OK=0
  fi
fi

PREP_STATUS="$PREP_ROOT/digital_assembly_p03_oa_preparation_status.rpt"
if [ "$RUN_OK" = "1" ]; then
  check_manifest "$PREP_ROOT" "$PREP_ROOT/SHA256SUMS" \
    > "$OUTPUT_ROOT/logs/preparation_manifest.log" 2>&1
  PREP_MANIFEST_RC=$?
  require_lines "$PREP_STATUS" \
    'STATUS=PASS' \
    'PHASE=p03_matrix_interface' \
    "TOP_MODULE=$TOP_MODULE" \
    "EXPECTED_HEAD=$EXPECTED_HEAD" \
    "ACTUAL_HEAD=$EXPECTED_HEAD" \
    'PVS_STATUS_RC=0' \
    'AUDIT_STATUS_RC=0' \
    'SOURCE_CURRENT_RC=0' \
    'OA_AUDIT_RC=0' \
    'OA_CANDIDATE_GATE_RC=0' \
    'BACKUP_RC=0' \
    'SOURCE_STABILITY_RC=0' \
    'OA_INSERTION_PREPARED=YES' \
    'OA_MUTATION_EXECUTED=NO'
  PREP_STATUS_RC=$?
  BACKUP_ROOT="$(sed -n 's/^BACKUP_ROOT=//p' "$PREP_STATUS" | head -n 1)"
  TARGET_OA_PATH="$(sed -n 's/^TARGET_OA_PATH=//p' "$PREP_STATUS" | head -n 1)"
  CANDIDATE_OA_PATH="$(sed -n 's/^CANDIDATE_OA_PATH=//p' "$PREP_STATUS" | head -n 1)"
  PVS_ROOT="$(sed -n 's/^SOURCE_PVS_ROOT=//p' "$PREP_STATUS" | head -n 1)"
  AUDIT_ROOT="$(sed -n 's/^SOURCE_AUDIT_ROOT=//p' "$PREP_STATUS" | head -n 1)"
  if [ -d "$BACKUP_ROOT" ]; then
    check_manifest "$BACKUP_ROOT" "$BACKUP_ROOT/manifests/SHA256SUMS" \
      > "$OUTPUT_ROOT/logs/backup_manifest.log" 2>&1
    BACKUP_MANIFEST_RC=$?
  else
    BACKUP_MANIFEST_RC=1
  fi
  echo "PREP_MANIFEST_RC=$PREP_MANIFEST_RC"
  echo "PREP_STATUS_RC=$PREP_STATUS_RC"
  echo "BACKUP_MANIFEST_RC=$BACKUP_MANIFEST_RC"
  if [ "$PREP_MANIFEST_RC" != "0" ] || \
     [ "$PREP_STATUS_RC" != "0" ] || \
     [ "$BACKUP_MANIFEST_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  sha256sum -c "$PREP_ROOT/source_evidence/target.pre.sha256" \
    > "$OUTPUT_ROOT/logs/target_precheck.log" 2>&1
  TARGET_PRECHECK_RC=$?
  sha256sum -c "$PREP_ROOT/source_evidence/candidate.pre.sha256" \
    > "$OUTPUT_ROOT/logs/candidate_precheck.log" 2>&1
  CANDIDATE_PRECHECK_RC=$?
  if [ "$TARGET_PRECHECK_RC" = "0" ] && [ "$CANDIDATE_PRECHECK_RC" = "0" ]; then
    SOURCE_PRECHECK_RC=0
  else
    SOURCE_PRECHECK_RC=1
  fi
  check_manifest "$PVS_ROOT" "$PVS_ROOT/SHA256SUMS" \
    > "$OUTPUT_ROOT/logs/pvs_postcheck.log" 2>&1
  PVS_POSTCHECK_RC=$?
  check_manifest "$AUDIT_ROOT" "$AUDIT_ROOT/SHA256SUMS" \
    > "$OUTPUT_ROOT/logs/audit_postcheck.log" 2>&1
  AUDIT_POSTCHECK_RC=$?
  echo "SOURCE_PRECHECK_RC=$SOURCE_PRECHECK_RC"
  echo "PVS_POSTCHECK_RC=$PVS_POSTCHECK_RC"
  echo "AUDIT_POSTCHECK_RC=$AUDIT_POSTCHECK_RC"
  if [ "$SOURCE_PRECHECK_RC" != "0" ] || \
     [ "$PVS_POSTCHECK_RC" != "0" ] || \
     [ "$AUDIT_POSTCHECK_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  command -v virtuoso >/dev/null 2>&1
  if [ "$?" != "0" ]; then
    echo "STOP_HERE_DO_NOT_MODIFY_OA: Virtuoso is not in PATH"
    RUN_OK=0
  fi
fi

INSERTION_REPORT="$OUTPUT_ROOT/digital_assembly_p03_oa_insertion_action.rpt"
if [ "$RUN_OK" = "1" ]; then
  cp -p "$PREP_STATUS" "$OUTPUT_ROOT/source_preparation/"
  cp -p "$PREP_ROOT/oa_candidate_gate.rpt" "$OUTPUT_ROOT/source_preparation/"
  export SPADMIC_OA_INSERT_TARGET_LIBRARY=SPADMIC
  export SPADMIC_OA_INSERT_TARGET_CELL=SPADMIC2
  export SPADMIC_OA_INSERT_TARGET_VIEW=layout
  export SPADMIC_OA_INSERT_SOURCE_LIBRARY=SPADMIC
  export SPADMIC_OA_INSERT_SOURCE_CELL="$TOP_MODULE"
  export SPADMIC_OA_INSERT_SOURCE_VIEW=layout
  export SPADMIC_OA_INSERT_INSTANCE_NAME=I_digital_assembly_p03
  export SPADMIC_OA_INSERT_AUTHORIZATION=EXACT_P03_BACKUP_REVIEWED
  export SPADMIC_OA_INSERT_REPORT="$INSERTION_REPORT"
  OA_MUTATION_ATTEMPTED=YES
  OA_MUTATION_EXECUTED=UNKNOWN
  virtuoso -nograph \
    -restore TOP/pnr/scripts/insert_digital_assembly_p03_into_spadmic2.il \
    -log "$OUTPUT_ROOT/logs/virtuoso_p03_insertion.log"
  VIRTUOSO_RC=$?
  if [ "$VIRTUOSO_RC" = "0" ]; then
    OA_MUTATION_EXECUTED=YES
  fi
fi

if [ "$OA_MUTATION_ATTEMPTED" = "YES" ]; then
  require_lines "$INSERTION_REPORT" \
    'STATUS=PASS' \
    'RESULT=EXACT_P03_INSTANCE_INSERTED' \
    'TARGET=SPADMIC/SPADMIC2/layout' \
    "SOURCE=SPADMIC/$TOP_MODULE/layout" \
    'INSTANCE=I_digital_assembly_p03' \
    'ORIGIN_UM=0.000000 0.000000' \
    'ORIENT=R0' \
    'NONALLOWLIST_INSTANCE_REMOVAL_COUNT=0' \
    'CREATED_INSTANCE_COUNT=1' \
    'FINAL_ALLOWLISTED_ASSEMBLY_COUNT=1' \
    'FINAL_EXACT_P03_INSTANCE_COUNT=1' \
    'FULL_TOP_GDS_EXPORT_STATUS=NOT_RUN' \
    'FULL_TOP_PVS_BASE_DRC_STATUS=NOT_RUN' \
    'FULL_TOP_PVS_DENSITY_DRC_STATUS=NOT_RUN' \
    'FULL_TOP_PVS_LVS_STATUS=NOT_RUN' \
    'SIGNOFF_READY=NO'
  INSERTION_STATUS_RC=$?
fi

if [ "$OA_MUTATION_ATTEMPTED" = "YES" ] && [ -d "$OUTPUT_ROOT" ]; then
  inventory_tree "$TARGET_OA_PATH" "$OUTPUT_ROOT/source_identity/target.post.sha256"
  TARGET_POST_RC=$?
  inventory_tree "$CANDIDATE_OA_PATH" "$OUTPUT_ROOT/source_identity/candidate.post.sha256"
  CANDIDATE_POST_RC=$?
  cmp -s "$PREP_ROOT/source_evidence/target.pre.sha256" "$OUTPUT_ROOT/source_identity/target.post.sha256"
  if [ "$?" != "0" ] && [ "$TARGET_POST_RC" = "0" ]; then
    TARGET_CHANGED_RC=0
  else
    TARGET_CHANGED_RC=1
  fi
  cmp -s "$PREP_ROOT/source_evidence/candidate.pre.sha256" "$OUTPUT_ROOT/source_identity/candidate.post.sha256"
  CANDIDATE_STABLE_RC=$?
fi

if [ "$RUN_OK" = "1" ] && \
   [ "$VIRTUOSO_RC" = "0" ] && \
   [ "$INSERTION_STATUS_RC" = "0" ] && \
   [ "$TARGET_CHANGED_RC" = "0" ] && \
   [ "$CANDIDATE_POST_RC" = "0" ] && \
   [ "$CANDIDATE_STABLE_RC" = "0" ]; then
  STATUS_VALUE=PASS
  RESULT=P03_ASSEMBLY_INSERTED_AS_UNVERIFIED_FULL_TOP_CANDIDATE
  NEXT_GATE=EXPORT_EXACT_SPADMIC2_GDS_THEN_RUN_FULL_TOP_DRC_AND_LVS
else
  STATUS_VALUE=FAIL
  RESULT=OA_INSERTION_REVIEW_REQUIRED_USE_IMMUTABLE_BACKUP
  NEXT_GATE=STOP_AND_REVIEW_OA_INSERTION_BEFORE_ANY_FURTHER_MUTATION
fi

STATUS_REPORT="$OUTPUT_ROOT/digital_assembly_p03_oa_insertion_status.rpt"
if [ -d "$OUTPUT_ROOT" ]; then
  {
    echo "LABEL=SPADMIC_DIGITAL_ASSEMBLY_P03_OA_INSERTION_TRANSACTION"
    echo "STATUS=$STATUS_VALUE"
    echo "RESULT=$RESULT"
    echo "EXPECTED_HEAD=$EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$ACTUAL_HEAD"
    echo "PHASE=p03_matrix_interface"
    echo "TOP_MODULE=$TOP_MODULE"
    echo "SOURCE_PREPARATION_ROOT=$PREP_ROOT"
    echo "SOURCE_PREPARATION_STATUS_SHA256=$(sha256sum "$PREP_STATUS" 2>/dev/null | awk '{print $1}')"
    echo "IMMUTABLE_BACKUP_ROOT=$BACKUP_ROOT"
    echo "TARGET_OA_PATH=$TARGET_OA_PATH"
    echo "CANDIDATE_OA_PATH=$CANDIDATE_OA_PATH"
    echo "PREP_MANIFEST_RC=$PREP_MANIFEST_RC"
    echo "PREP_STATUS_RC=$PREP_STATUS_RC"
    echo "BACKUP_MANIFEST_RC=$BACKUP_MANIFEST_RC"
    echo "SOURCE_PRECHECK_RC=$SOURCE_PRECHECK_RC"
    echo "PVS_POSTCHECK_RC=$PVS_POSTCHECK_RC"
    echo "AUDIT_POSTCHECK_RC=$AUDIT_POSTCHECK_RC"
    echo "VIRTUOSO_RC=$VIRTUOSO_RC"
    echo "OA_MUTATION_ATTEMPTED=$OA_MUTATION_ATTEMPTED"
    echo "INSERTION_STATUS_RC=$INSERTION_STATUS_RC"
    echo "TARGET_CHANGED_RC=$TARGET_CHANGED_RC"
    echo "CANDIDATE_STABLE_RC=$CANDIDATE_STABLE_RC"
    echo "OA_MUTATION_EXECUTED=$OA_MUTATION_EXECUTED"
    echo "ASSEMBLY_LAYOUT_STATUS=CANDIDATE_NOT_SIGNOFF"
    echo "FULL_TOP_GDS_EXPORT_STATUS=NOT_RUN"
    echo "FULL_TOP_PVS_BASE_DRC_STATUS=NOT_RUN"
    echo "FULL_TOP_PVS_DENSITY_DRC_STATUS=NOT_RUN"
    echo "FULL_TOP_PVS_LVS_STATUS=NOT_RUN"
    echo "BLOCK_PROMOTION_AUTHORIZED=NO"
    echo "SIGNOFF_READY=NO"
    echo "NEXT_GATE=$NEXT_GATE"
  } > "$STATUS_REPORT"
  (
    cd "$OUTPUT_ROOT"
    local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
    else
      false
    fi
  )
  DIAGNOSTIC_MANIFEST_RC=$?
fi

echo "OUTPUT_ROOT=$OUTPUT_ROOT"
echo "DIAGNOSTIC_MANIFEST_RC=$DIAGNOSTIC_MANIFEST_RC"
cat "$STATUS_REPORT" 2>/dev/null
if [ "$STATUS_VALUE" = "PASS" ] && [ "$DIAGNOSTIC_MANIFEST_RC" = "0" ]; then
  echo "DIGITAL_ASSEMBLY_P03_OA_INSERTION_TRANSACTION_STATUS=PASS"
  echo "RETURN_OUTPUT_FOR_FULL_TOP_EXPORT_PREPARATION"
  echo "DO_NOT_CLAIM_FULL_TOP_DRC_LVS_OR_SIGNOFF"
  true
else
  echo "DIGITAL_ASSEMBLY_P03_OA_INSERTION_TRANSACTION_STATUS=FAIL"
  echo "STOP_HERE_USE_IMMUTABLE_BACKUP_FOR_RECOVERY_REVIEW"
  false
fi
