#!/usr/bin/env bash

###############################################################################
# Hash-bound immutable handoff staging for one accepted assembly phase.
#
# Usage:
#   bash TOP/ci/server_stage_digital_assembly_phase_handoff.sh \
#     <expected-head> <phase> <accepted-Innovus-root>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
PHASE="${2:-MISSING}"
INNOVUS_ROOT="${3:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
VERSION="assembly_${PHASE}_${TIMESTAMP}"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
STAGE_RC=NOT_RUN
PACKAGE=UNKNOWN
PACKAGE_MANIFEST_RC=NOT_RUN
PACKAGE_AUDIT_RC=NOT_RUN

case "$PHASE" in
  p00_tx) TOP_MODULE=spadmic_digital_assembly_v1_p00_tx ;;
  p01_position) TOP_MODULE=spadmic_digital_assembly_v1_p01_position ;;
  p02_event_control) TOP_MODULE=spadmic_digital_assembly_v1_p02_event_control ;;
  p03_matrix_interface) TOP_MODULE=spadmic_digital_assembly_v1_p03_matrix_interface ;;
  *) TOP_MODULE=UNKNOWN; RUN_OK=0 ;;
esac

if [ -d "$REPO/.git" ]; then
  cd "$REPO"
  CD_RC=$?
else
  echo "STOP_HERE_DO_NOT_CONTINUE: repository missing: $REPO"
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
     [ "$STAGED_DIFF_RC" != "0" ] || \
     [ ! -x TOP/pnr/scripts/stage_digital_assembly_handoff.sh ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: checkout is not attributable"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  bash TOP/pnr/scripts/stage_digital_assembly_handoff.sh \
    "$PHASE" "$INNOVUS_ROOT" "$VERSION"
  STAGE_RC=$?
fi

PACKAGE="$WORK_ROOT/handoff/innovus/assemblies/$TOP_MODULE/$VERSION"
if [ "$STAGE_RC" = "0" ] && [ -r "$PACKAGE/manifests/SHA256SUMS" ]; then
  (
    cd "$PACKAGE"
    local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      sha256sum -c manifests/SHA256SUMS
    else
      false
    fi
  )
  PACKAGE_MANIFEST_RC=$?
  python3 TOP/pnr/scripts/audit_innovus_handoff.py "$PACKAGE"
  PACKAGE_AUDIT_RC=$?
fi

echo "EXPECTED_HEAD=$EXPECTED_HEAD"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "PHASE=$PHASE"
echo "TOP_MODULE=$TOP_MODULE"
echo "STAGE_RC=$STAGE_RC"
echo "PACKAGE=$PACKAGE"
echo "PACKAGE_MANIFEST_RC=$PACKAGE_MANIFEST_RC"
echo "PACKAGE_AUDIT_RC=$PACKAGE_AUDIT_RC"

if [ "$STAGE_RC" = "0" ] && [ "$PACKAGE_MANIFEST_RC" = "0" ] && [ "$PACKAGE_AUDIT_RC" = "0" ]; then
  echo "DIGITAL_ASSEMBLY_HANDOFF_STAGING_TRANSACTION_STATUS=PASS"
  echo "RETURN_OUTPUT_FOR_PHASE_PVS_BASE_DRC_PREFLIGHT"
  echo "DO_NOT_START_PVS_UNTIL_REVIEWED"
  true
else
  echo "DIGITAL_ASSEMBLY_HANDOFF_STAGING_TRANSACTION_STATUS=FAIL"
  echo "STOP_HERE_DO_NOT_START_PVS"
  false
fi
