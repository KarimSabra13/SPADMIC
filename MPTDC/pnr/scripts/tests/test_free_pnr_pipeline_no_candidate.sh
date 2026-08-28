#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_SCRIPTS="$(cd "$SCRIPT_DIR/.." && pwd)"
PIPELINE="$PNR_SCRIPTS/server_run_mptdc_free_pnr_pipeline.sh"
TMP_ROOT="$(mktemp -d /tmp/mptdc_free_pipeline_test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

FAKE_REPO="$TMP_ROOT/repo"
FAKE_SCRIPTS="$FAKE_REPO/MPTDC/pnr/scripts"
FAKE_PVS="$FAKE_REPO/MPTDC/scripts/pvs"
FAKE_CI="$FAKE_REPO/MPTDC/ci"
WORK="$TMP_ROOT/work/innovus"
mkdir -p "$FAKE_SCRIPTS" "$FAKE_PVS" "$FAKE_CI" "$WORK"
cp "$PIPELINE" "$FAKE_SCRIPTS/"

cat > "$FAKE_SCRIPTS/server_run_mptdc_free_placement_attempt.sh" <<'STUB'
#!/usr/bin/env bash
set -u
run_id=""
work=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) run_id="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    *) shift ;;
  esac
done
mkdir -p "$work/$run_id/reports"
printf 'MPTDC_FREE_PLACEMENT_ATTEMPT_STATUS=FAIL\n' > \
  "$work/$run_id/reports/operator_gate_mptdc_free_placement_attempt.rpt"
exit 1
STUB

cat > "$FAKE_PVS/server_run_mptdc_free_trial_pvs.sh" <<'STUB'
#!/usr/bin/env bash
echo 'ERROR: PVS must not run without a selected PnR candidate' >&2
exit 98
STUB

cat > "$FAKE_CI/publish_mptdc_server_snapshot.sh" <<'STUB'
#!/usr/bin/env bash
echo "NEXT_EXPECTED_HEAD=$(git rev-parse HEAD)"
STUB
chmod +x "$FAKE_SCRIPTS/server_run_mptdc_free_placement_attempt.sh" \
  "$FAKE_PVS/server_run_mptdc_free_trial_pvs.sh" \
  "$FAKE_CI/publish_mptdc_server_snapshot.sh"

git -C "$FAKE_REPO" init -q -b SPADMIC_test
git -C "$FAKE_REPO" config user.name test
git -C "$FAKE_REPO" config user.email test@example.invalid
git -C "$FAKE_REPO" add MPTDC
git -C "$FAKE_REPO" commit -qm fixture
HEAD_SHA="$(git -C "$FAKE_REPO" rev-parse HEAD)"

set +e
OUTPUT="$(MPTDC_INNOVUS_WORK="$WORK" bash "$FAKE_SCRIPTS/$(basename "$PIPELINE")" \
  --run-id no_candidate --expected-head "$HEAD_SHA" --no-auto-density 2>&1)"
RC=$?
set -e

[[ "$RC" -eq 1 ]]
grep -Fq 'ATTEMPT50_RC=1' <<< "$OUTPUT"
grep -Fq 'ATTEMPT45_RC=NOT_RUN' <<< "$OUTPUT"
grep -Fq 'SELECTED_PNR_RUN=NONE' <<< "$OUTPUT"
grep -Fq 'PVS_RC=NOT_RUN' <<< "$OUTPUT"
grep -Fq 'MPTDC_FREE_PNR_PIPELINE_STATUS=FAIL' <<< "$OUTPUT"
! grep -Fq 'unbound variable' <<< "$OUTPUT"
! grep -Fq 'PVS must not run' <<< "$OUTPUT"

echo 'FREE_PNR_PIPELINE_NO_CANDIDATE_TEST=PASS'
