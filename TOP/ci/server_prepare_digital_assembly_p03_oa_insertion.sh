#!/usr/bin/env bash

###############################################################################
# Read-only p03 OA candidate audit plus immutable SPADMIC2 backup.
# No OA layout is modified by this transaction.
#
# Usage:
#   bash TOP/ci/server_prepare_digital_assembly_p03_oa_insertion.sh \
#     <expected-head> <accepted-p03-lvs-root> <source-assembly-audit-root> \
#     [oa-library-filesystem-root]
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
PVS_ROOT="${2:-MISSING}"
AUDIT_ROOT="${3:-MISSING}"
OA_LIBRARY_ROOT="${4:-/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
PREP_ROOT="$WORK_ROOT/diagnostics/digital_assembly_p03_oa_preparation_$TIMESTAMP"
BACKUP_ROOT="$WORK_ROOT/handoff/oa_backups/SPADMIC2/pre_p03_insertion_$TIMESTAMP"

PHASE=p03_matrix_interface
TOP_MODULE=spadmic_digital_assembly_v1_p03_matrix_interface
TARGET_LIBRARY=SPADMIC
TARGET_CELL=SPADMIC2
CANDIDATE_LIBRARY=SPADMIC
CANDIDATE_CELL="$TOP_MODULE"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
PVS_MANIFEST_RC=NOT_RUN
PVS_STATUS_RC=NOT_RUN
AUDIT_MANIFEST_RC=NOT_RUN
AUDIT_STATUS_RC=NOT_RUN
SOURCE_CURRENT_RC=NOT_RUN
OA_PATH_GATE_RC=NOT_RUN
OA_AUDIT_RC=NOT_RUN
OA_CANDIDATE_GATE_RC=NOT_RUN
BACKUP_RC=NOT_RUN
SOURCE_STABILITY_RC=NOT_RUN
BACKUP_MANIFEST_RC=NOT_RUN
PREP_MANIFEST_RC=NOT_RUN
PACKAGE=UNKNOWN

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

if [ "$EXPECTED_HEAD" = "MISSING" ] || \
   [ "$PVS_ROOT" = "MISSING" ] || \
   [ "$AUDIT_ROOT" = "MISSING" ]; then
  echo "STOP_HERE_DO_NOT_CONTINUE: expected HEAD, p03 LVS root, and source audit root are required"
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
  if [ -d "$PVS_ROOT" ] && [ -d "$AUDIT_ROOT" ]; then
    PVS_ROOT="$(cd "$PVS_ROOT" && pwd -P)"
    AUDIT_ROOT="$(cd "$AUDIT_ROOT" && pwd -P)"
  else
    echo "STOP_HERE_DO_NOT_CONTINUE: accepted evidence root missing"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  mkdir -p "$PREP_ROOT/logs" "$PREP_ROOT/oa_audit" "$PREP_ROOT/source_evidence"
  if [ "$?" != "0" ]; then
    RUN_OK=0
  fi
fi

PVS_STATUS="$PVS_ROOT/digital_assembly_pvs_gate.rpt"
AUDIT_STATUS="$AUDIT_ROOT/processed_contract/assembly_audit_status.rpt"
if [ "$RUN_OK" = "1" ]; then
  check_manifest "$PVS_ROOT" "$PVS_ROOT/SHA256SUMS" \
    > "$PREP_ROOT/logs/pvs_manifest.log" 2>&1
  PVS_MANIFEST_RC=$?
  require_lines "$PVS_STATUS" \
    'STATUS=PASS' \
    'PHASE=p03_matrix_interface' \
    'MODE=LVS' \
    "TOP_MODULE=$TOP_MODULE" \
    "LAYOUT_TOP=$TOP_MODULE" \
    "SOURCE_TOP=$TOP_MODULE" \
    'PVS_BASE_DRC_STATUS=PASS' \
    'PVS_DENSITY_DRC_STATUS=PASS' \
    'PVS_LVS_STATUS=MATCH' \
    'ASSEMBLY_PHASE_ACCEPTED=YES' \
    'OA_INSERTION_AUTHORIZED=YES'
  PVS_STATUS_RC=$?
  PACKAGE="$(sed -n 's/^PACKAGE=//p' "$PVS_STATUS" | head -n 1)"

  check_manifest "$AUDIT_ROOT" "$AUDIT_ROOT/SHA256SUMS" \
    > "$PREP_ROOT/logs/source_audit_manifest.log" 2>&1
  AUDIT_MANIFEST_RC=$?
  require_lines "$AUDIT_STATUS" \
    'STATUS=PASS' \
    'SOURCE_IDENTITY_GATE_STATUS=PASS' \
    'EXACT_MATRICE5_INSTANCE_GATE_STATUS=PASS' \
    'MATRIX_TERMINAL_PARITY_STATUS=PASS' \
    'UNKNOWN_FAMILY_GATE_STATUS=PASS' \
    'MATRIX_PROXY_PIN_ACCESS_STATUS=PASS' \
    'PG_ANCHOR_GATE_STATUS=PASS' \
    'P03_IMPLEMENTATION_AUTHORIZED=YES'
  AUDIT_STATUS_RC=$?
  sha256sum -c "$AUDIT_ROOT/spadmic2_source.post.sha256" \
    > "$PREP_ROOT/logs/source_current.log" 2>&1
  SOURCE_CURRENT_RC=$?
  echo "PVS_MANIFEST_RC=$PVS_MANIFEST_RC"
  echo "PVS_STATUS_RC=$PVS_STATUS_RC"
  echo "AUDIT_MANIFEST_RC=$AUDIT_MANIFEST_RC"
  echo "AUDIT_STATUS_RC=$AUDIT_STATUS_RC"
  echo "SOURCE_CURRENT_RC=$SOURCE_CURRENT_RC"
  if [ "$PVS_MANIFEST_RC" != "0" ] || \
     [ "$PVS_STATUS_RC" != "0" ] || \
     [ "$AUDIT_MANIFEST_RC" != "0" ] || \
     [ "$AUDIT_STATUS_RC" != "0" ] || \
     [ "$SOURCE_CURRENT_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

TARGET_OA_PATH="$OA_LIBRARY_ROOT/$TARGET_CELL"
CANDIDATE_OA_PATH="$OA_LIBRARY_ROOT/$CANDIDATE_CELL"
if [ "$RUN_OK" = "1" ]; then
  OA_PATH_GATE_RC=0
  for path in "$TARGET_OA_PATH/layout" "$CANDIDATE_OA_PATH/layout"; do
    if [ ! -d "$path" ]; then
      echo "MISSING_OA_CELLVIEW_PATH=$path"
      OA_PATH_GATE_RC=1
    fi
  done
  command -v virtuoso >/dev/null 2>&1
  if [ "$?" != "0" ]; then
    OA_PATH_GATE_RC=1
  fi
  if [ ! -s "$PACKAGE/lef/$TOP_MODULE.lef" ] || [ ! -s "$PACKAGE/gds/$TOP_MODULE.gds" ]; then
    OA_PATH_GATE_RC=1
  fi
  echo "OA_PATH_GATE_RC=$OA_PATH_GATE_RC"
  if [ "$OA_PATH_GATE_RC" != "0" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: import exact p03 GDS into the distinct OA candidate cell before preparation"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  inventory_tree "$TARGET_OA_PATH" "$PREP_ROOT/source_evidence/target.pre.sha256"
  TARGET_PRE_RC=$?
  inventory_tree "$CANDIDATE_OA_PATH" "$PREP_ROOT/source_evidence/candidate.pre.sha256"
  CANDIDATE_PRE_RC=$?
  export SPADMIC_OA_CANDIDATE_TARGET_LIBRARY="$TARGET_LIBRARY"
  export SPADMIC_OA_CANDIDATE_TARGET_CELL="$TARGET_CELL"
  export SPADMIC_OA_CANDIDATE_TARGET_VIEW=layout
  export SPADMIC_OA_CANDIDATE_SOURCE_LIBRARY="$CANDIDATE_LIBRARY"
  export SPADMIC_OA_CANDIDATE_SOURCE_CELL="$CANDIDATE_CELL"
  export SPADMIC_OA_CANDIDATE_SOURCE_VIEW=layout
  export SPADMIC_OA_CANDIDATE_TARGET_REPORT="$PREP_ROOT/oa_audit/target_oa_contract.rpt"
  export SPADMIC_OA_CANDIDATE_SOURCE_REPORT="$PREP_ROOT/oa_audit/candidate_oa_contract.rpt"
  virtuoso -nograph \
    -restore TOP/pnr/scripts/audit_digital_assembly_oa_candidate.il \
    -log "$PREP_ROOT/logs/virtuoso_candidate_audit.log"
  OA_AUDIT_RC=$?
  if [ "$OA_AUDIT_RC" = "0" ]; then
    python3 TOP/pnr/scripts/validate_digital_assembly_oa_candidate.py \
      --pvs-status "$PVS_STATUS" \
      --source-audit-status "$AUDIT_STATUS" \
      --candidate-oa-report "$PREP_ROOT/oa_audit/candidate_oa_contract.rpt" \
      --target-oa-report "$PREP_ROOT/oa_audit/target_oa_contract.rpt" \
      --lef "$PACKAGE/lef/$TOP_MODULE.lef" \
      --status "$PREP_ROOT/oa_candidate_gate.rpt" \
      > "$PREP_ROOT/logs/oa_candidate_gate.log" 2>&1
    OA_CANDIDATE_GATE_RC=$?
  fi
  echo "OA_AUDIT_RC=$OA_AUDIT_RC"
  echo "OA_CANDIDATE_GATE_RC=$OA_CANDIDATE_GATE_RC"
  if [ "$TARGET_PRE_RC" != "0" ] || \
     [ "$CANDIDATE_PRE_RC" != "0" ] || \
     [ "$OA_AUDIT_RC" != "0" ] || \
     [ "$OA_CANDIDATE_GATE_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  if [ -e "$BACKUP_ROOT" ]; then
    BACKUP_RC=1
  else
    mkdir -p "$BACKUP_ROOT/oa" "$BACKUP_ROOT/evidence" "$BACKUP_ROOT/manifests"
    BACKUP_RC=$?
  fi
  if [ "$BACKUP_RC" = "0" ]; then
    cp -a "$TARGET_OA_PATH" "$BACKUP_ROOT/oa/"
    TARGET_COPY_RC=$?
    cp -a "$CANDIDATE_OA_PATH" "$BACKUP_ROOT/oa/"
    CANDIDATE_COPY_RC=$?
    cp -p "$PACKAGE/gds/$TOP_MODULE.gds" "$BACKUP_ROOT/evidence/"
    GDS_COPY_RC=$?
    cp -p "$PACKAGE/lef/$TOP_MODULE.lef" "$BACKUP_ROOT/evidence/"
    LEF_COPY_RC=$?
    cp -p "$PVS_STATUS" "$BACKUP_ROOT/evidence/"
    PVS_COPY_RC=$?
    cp -p "$AUDIT_STATUS" "$BACKUP_ROOT/evidence/"
    AUDIT_COPY_RC=$?
    cp -p "$PREP_ROOT/oa_candidate_gate.rpt" "$BACKUP_ROOT/evidence/"
    CANDIDATE_GATE_COPY_RC=$?
    if [ "$TARGET_COPY_RC" != "0" ] || [ "$CANDIDATE_COPY_RC" != "0" ] || \
       [ "$GDS_COPY_RC" != "0" ] || [ "$LEF_COPY_RC" != "0" ] || \
       [ "$PVS_COPY_RC" != "0" ] || [ "$AUDIT_COPY_RC" != "0" ] || \
       [ "$CANDIDATE_GATE_COPY_RC" != "0" ]; then
      BACKUP_RC=1
    fi
  fi
fi

if [ -d "$PREP_ROOT" ]; then
  inventory_tree "$TARGET_OA_PATH" "$PREP_ROOT/source_evidence/target.post.sha256"
  TARGET_POST_RC=$?
  inventory_tree "$CANDIDATE_OA_PATH" "$PREP_ROOT/source_evidence/candidate.post.sha256"
  CANDIDATE_POST_RC=$?
  cmp -s "$PREP_ROOT/source_evidence/target.pre.sha256" "$PREP_ROOT/source_evidence/target.post.sha256"
  TARGET_STABLE_RC=$?
  cmp -s "$PREP_ROOT/source_evidence/candidate.pre.sha256" "$PREP_ROOT/source_evidence/candidate.post.sha256"
  CANDIDATE_STABLE_RC=$?
  if [ "$TARGET_POST_RC" = "0" ] && [ "$CANDIDATE_POST_RC" = "0" ] && \
     [ "$TARGET_STABLE_RC" = "0" ] && [ "$CANDIDATE_STABLE_RC" = "0" ]; then
    SOURCE_STABILITY_RC=0
  else
    SOURCE_STABILITY_RC=1
  fi
fi

if [ "$RUN_OK" = "1" ] && [ "$BACKUP_RC" = "0" ] && [ "$SOURCE_STABILITY_RC" = "0" ]; then
  STATUS_VALUE=PASS
  RESULT=IMMUTABLE_BACKUP_READY_FOR_ONE_P03_OA_INSERTION
  NEXT_GATE=REVIEW_BACKUP_THEN_RUN_ONE_P03_OA_INSERTION
else
  STATUS_VALUE=FAIL
  RESULT=OA_INSERTION_PREPARATION_REVIEW_REQUIRED
  NEXT_GATE=STOP_AND_REVIEW_OA_PREPARATION
fi

STATUS_REPORT="$PREP_ROOT/digital_assembly_p03_oa_preparation_status.rpt"
if [ -d "$PREP_ROOT" ]; then
  {
    echo "LABEL=SPADMIC_DIGITAL_ASSEMBLY_P03_OA_PREPARATION"
    echo "STATUS=$STATUS_VALUE"
    echo "RESULT=$RESULT"
    echo "EXPECTED_HEAD=$EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$ACTUAL_HEAD"
    echo "PHASE=$PHASE"
    echo "TOP_MODULE=$TOP_MODULE"
    echo "SOURCE_PVS_ROOT=$PVS_ROOT"
    echo "SOURCE_PVS_STATUS_SHA256=$(sha256sum "$PVS_STATUS" 2>/dev/null | awk '{print $1}')"
    echo "SOURCE_AUDIT_ROOT=$AUDIT_ROOT"
    echo "SOURCE_AUDIT_STATUS_SHA256=$(sha256sum "$AUDIT_STATUS" 2>/dev/null | awk '{print $1}')"
    echo "PACKAGE=$PACKAGE"
    echo "PACKAGE_GDS=$PACKAGE/gds/$TOP_MODULE.gds"
    echo "PACKAGE_GDS_SHA256=$(sha256sum "$PACKAGE/gds/$TOP_MODULE.gds" 2>/dev/null | awk '{print $1}')"
    echo "OA_LIBRARY_ROOT=$OA_LIBRARY_ROOT"
    echo "TARGET_OA_PATH=$TARGET_OA_PATH"
    echo "CANDIDATE_OA_PATH=$CANDIDATE_OA_PATH"
    echo "BACKUP_ROOT=$BACKUP_ROOT"
    echo "PVS_MANIFEST_RC=$PVS_MANIFEST_RC"
    echo "PVS_STATUS_RC=$PVS_STATUS_RC"
    echo "AUDIT_MANIFEST_RC=$AUDIT_MANIFEST_RC"
    echo "AUDIT_STATUS_RC=$AUDIT_STATUS_RC"
    echo "SOURCE_CURRENT_RC=$SOURCE_CURRENT_RC"
    echo "OA_PATH_GATE_RC=$OA_PATH_GATE_RC"
    echo "OA_AUDIT_RC=$OA_AUDIT_RC"
    echo "OA_CANDIDATE_GATE_RC=$OA_CANDIDATE_GATE_RC"
    echo "BACKUP_RC=$BACKUP_RC"
    echo "SOURCE_STABILITY_RC=$SOURCE_STABILITY_RC"
    echo "OA_EQUIVALENCE_SCOPE=BBOX_AND_BOUNDARY_PIN_CONTRACT_ONLY"
    echo "OA_INSERTION_PREPARED=$([ "$STATUS_VALUE" = "PASS" ] && echo YES || echo NO)"
    echo "OA_MUTATION_EXECUTED=NO"
    echo "FULL_TOP_GDS_EXPORT_STATUS=NOT_RUN"
    echo "FULL_TOP_PVS_BASE_DRC_STATUS=NOT_RUN"
    echo "FULL_TOP_PVS_DENSITY_DRC_STATUS=NOT_RUN"
    echo "FULL_TOP_PVS_LVS_STATUS=NOT_RUN"
    echo "SIGNOFF_READY=NO"
    echo "NEXT_GATE=$NEXT_GATE"
  } > "$STATUS_REPORT"
  (
    cd "$PREP_ROOT"
    local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
    else
      false
    fi
  )
  PREP_MANIFEST_RC=$?
fi

if [ "$STATUS_VALUE" = "PASS" ] && [ -d "$BACKUP_ROOT" ]; then
  cp -p "$STATUS_REPORT" "$BACKUP_ROOT/manifests/"
  (
    cd "$BACKUP_ROOT"
    local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > manifests/SHA256SUMS
    else
      false
    fi
  )
  BACKUP_MANIFEST_RC=$?
fi

echo "PREP_ROOT=$PREP_ROOT"
echo "BACKUP_ROOT=$BACKUP_ROOT"
echo "PREP_MANIFEST_RC=$PREP_MANIFEST_RC"
echo "BACKUP_MANIFEST_RC=$BACKUP_MANIFEST_RC"
cat "$STATUS_REPORT" 2>/dev/null
if [ "$STATUS_VALUE" = "PASS" ] && \
   [ "$PREP_MANIFEST_RC" = "0" ] && \
   [ "$BACKUP_MANIFEST_RC" = "0" ]; then
  echo "DIGITAL_ASSEMBLY_P03_OA_PREPARATION_TRANSACTION_STATUS=PASS"
  echo "RETURN_OUTPUT_FOR_IMMUTABLE_BACKUP_REVIEW"
  echo "DO_NOT_MODIFY_OA_UNTIL_REVIEWED"
  true
else
  echo "DIGITAL_ASSEMBLY_P03_OA_PREPARATION_TRANSACTION_STATUS=FAIL"
  echo "STOP_HERE_DO_NOT_MODIFY_OA"
  false
fi
