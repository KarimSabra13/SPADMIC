#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTOR="$(cd "$SCRIPT_DIR/.." && pwd)/collect_mptdc_server_snapshot.sh"
PUBLISHER="$(cd "$SCRIPT_DIR/.." && pwd)/publish_mptdc_server_snapshot.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

SRC="$TMP_ROOT/source"
SNAPSHOT_ROOT="$TMP_ROOT/snapshots"
SNAPSHOT="$SNAPSHOT_ROOT/pvs/fixture_pvs"

mkdir -p \
  "$SRC/reports" \
  "$SRC/manifests" \
  "$SRC/outputs" \
  "$SRC/pvs_drc/run_base" \
  "$SRC/pvs_lvs/run_lvs"

printf 'STATUS=PASS\n' > "$SRC/reports/operator_gate_fixture.rpt"
printf 'STRICT_ATTRIBUTION=1\n' > "$SRC/manifests/pvs_input_hashes.rpt"
dd if=/dev/zero of="$SRC/reports/oversized.rpt" bs=2048 count=1 status=none
printf 'binary layout placeholder\n' > "$SRC/outputs/layout.gds"
printf 'pvs -drc run control\n' > "$SRC/pvs_drc/run_base/run.pvs"
printf 'drc control\n' > "$SRC/pvs_drc/run_base/pvsdrcctl"
printf 'INFO starting\nERROR fixture failure\nordinary noise\n' \
  > "$SRC/pvs_drc/run_base/pvs_replay.stdout"
printf 'pvs -lvs run control\n' > "$SRC/pvs_lvs/run_lvs/run.pvs"
printf 'lvs control\n' > "$SRC/pvs_lvs/run_lvs/pvslvsctl"
printf 'Final comparison: MATCH\n' > "$SRC/pvs_lvs/run_lvs/PIPO1.OUT"
printf 'INFO LVS started\nPASS LVS complete\n' > "$SRC/pvs_lvs/run_lvs/PIPO1.LOG"

MPTDC_SNAPSHOT_ROOT="$SNAPSHOT_ROOT" \
MPTDC_SNAPSHOT_SOURCE_DIR="$SRC" \
MPTDC_SNAPSHOT_MAX_TEXT_BYTES=1024 \
bash "$COLLECTOR" pvs fixture_pvs > "$TMP_ROOT/collector.stdout"

test -s "$SNAPSHOT/reports/operator_gate_fixture.rpt"
test -s "$SNAPSHOT/manifests/pvs_input_hashes.rpt"
test -s "$SNAPSHOT/pvs_drc/run_base/run.pvs"
test -s "$SNAPSHOT/pvs_drc/run_base/pvsdrcctl"
test -s "$SNAPSHOT/pvs_lvs/run_lvs/pvslvsctl"
test -s "$SNAPSHOT/pvs_drc/run_base/pvs_replay.stdout.messages.tail"
test -s "$SNAPSHOT/pvs_lvs/run_lvs/PIPO1.OUT"
test -s "$SNAPSHOT/pvs_lvs/run_lvs/PIPO1.OUT.messages.tail"
test -s "$SNAPSHOT/pvs_lvs/run_lvs/PIPO1.LOG.messages.tail"
test ! -e "$SNAPSHOT/reports/oversized.rpt"
test ! -e "$SNAPSHOT/outputs/layout.gds"
grep -Fq 'oversized.rpt' "$SNAPSHOT/README.md"
grep -Fq 'ERROR fixture failure' \
  "$SNAPSHOT/pvs_drc/run_base/pvs_replay.stdout.messages.tail"

set +e
MPTDC_SNAPSHOT_ROOT="$SNAPSHOT_ROOT" \
MPTDC_SNAPSHOT_SOURCE_DIR="$SRC" \
MPTDC_SNAPSHOT_MAX_TEXT_BYTES=0 \
bash "$COLLECTOR" pvs invalid_limit > "$TMP_ROOT/invalid.stdout" 2>&1
INVALID_RC=$?
set -e
test "$INVALID_RC" -eq 2

PUBLISH_REPO="$TMP_ROOT/publish_repo"
PUBLISH_ORIGIN="$TMP_ROOT/publish_origin.git"
mkdir -p "$PUBLISH_REPO"
git init -q -b SPADMIC_test "$PUBLISH_REPO"
git -C "$PUBLISH_REPO" config user.name 'MPTDC snapshot test'
git -C "$PUBLISH_REPO" config user.email 'mptdc-snapshot-test@example.invalid'
printf 'baseline\n' > "$PUBLISH_REPO/README.md"
git -C "$PUBLISH_REPO" add README.md
git -C "$PUBLISH_REPO" commit -q -m baseline
git init -q --bare "$PUBLISH_ORIGIN"
git -C "$PUBLISH_REPO" remote add origin "$PUBLISH_ORIGIN"
git -C "$PUBLISH_REPO" push -q -u origin SPADMIC_test

printf 'generated evidence with trailing whitespace \n\n' \
  > "$SRC/reports/generated_whitespace.rpt"
MPTDC_SNAPSHOT_ROOT="$PUBLISH_REPO/MPTDC/docs/server_snapshots" \
MPTDC_SNAPSHOT_SOURCE_DIR="$SRC" \
MPTDC_SNAPSHOT_MAX_TEXT_BYTES=1024 \
bash "$COLLECTOR" pvs publish_fixture > "$TMP_ROOT/precollect.stdout"

MPTDC_PUBLISH_REPO_ROOT="$PUBLISH_REPO" \
MPTDC_PUBLISH_COLLECTOR="$COLLECTOR" \
MPTDC_SNAPSHOT_REUSE_EXISTING=1 \
bash "$PUBLISHER" pvs publish_fixture "$SRC" PVS_TEST \
  > "$TMP_ROOT/publisher.stdout"

PUBLISH_HEAD="$(git -C "$PUBLISH_REPO" rev-parse HEAD)"
ORIGIN_HEAD="$(git --git-dir="$PUBLISH_ORIGIN" rev-parse refs/heads/SPADMIC_test)"
test "$PUBLISH_HEAD" = "$ORIGIN_HEAD"
grep -Fq 'EVIDENCE_PUSH_RC=0' "$TMP_ROOT/publisher.stdout"
grep -Eq '[[:space:]]$' \
  "$PUBLISH_REPO/MPTDC/docs/server_snapshots/pvs/publish_fixture/reports/generated_whitespace.rpt"

echo "PASS: collect_and_publish_mptdc_server_snapshot"
