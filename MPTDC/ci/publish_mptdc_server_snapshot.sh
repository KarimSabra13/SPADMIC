#!/usr/bin/env bash
# Collect, commit, and push one bounded MPTDC text-evidence snapshot.
set -u

usage() {
  cat <<'USAGE'
Usage:
  publish_mptdc_server_snapshot.sh <kind> <snapshot-id> <source-dir> <step>

Optional environment:
  MPTDC_SNAPSHOT_REUSE_EXISTING=1  Reuse an already collected snapshot.
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=N  Forward the per-file text limit.

The script commits only MPTDC/docs/server_snapshots/<kind>/<snapshot-id>.
Generated evidence is preserved verbatim; whitespace lint is not a signoff gate.
USAGE
}

if [[ $# -ne 4 ]]; then
  usage >&2
  exit 2
fi

KIND="$1"
SNAPSHOT_ID="$2"
SOURCE_DIR="$3"
STEP_LABEL="$4"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${MPTDC_PUBLISH_REPO_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
COLLECTOR="${MPTDC_PUBLISH_COLLECTOR:-$SCRIPT_DIR/collect_mptdc_server_snapshot.sh}"
SNAPSHOT_REL="MPTDC/docs/server_snapshots/$KIND/$SNAPSHOT_ID"
SNAPSHOT_ABS="$REPO_ROOT/$SNAPSHOT_REL"
COLLECT_RC=99
CHECK_RC=99
COMMIT_RC=99
PUSH_RC=99
SNAPSHOT_COMMIT=NONE

cd "$REPO_ROOT" || exit 3

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "ERROR: snapshot source missing: $SOURCE_DIR"
elif [[ -e "$SNAPSHOT_ABS" && "${MPTDC_SNAPSHOT_REUSE_EXISTING:-0}" != "1" ]]; then
  echo "ERROR: snapshot destination already exists: $SNAPSHOT_REL"
elif [[ -e "$SNAPSHOT_ABS" ]]; then
  echo "Reusing existing snapshot: $SNAPSHOT_REL"
  COLLECT_RC=0
else
  MPTDC_SNAPSHOT_ROOT="$REPO_ROOT/MPTDC/docs/server_snapshots" \
  MPTDC_SNAPSHOT_SOURCE_DIR="$SOURCE_DIR" \
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES="${MPTDC_SNAPSHOT_MAX_TEXT_BYTES:-2097152}" \
  bash "$COLLECTOR" "$KIND" "$SNAPSHOT_ID"
  COLLECT_RC=$?
fi

if [[ "$COLLECT_RC" -eq 0 ]]; then
  FORBIDDEN="$(find "$SNAPSHOT_ABS" -type f \
    \( -iname '*.gds' -o -iname '*.gds.gz' -o -iname '*.oas' \
       -o -iname '*.oasis' -o -iname '*.def' -o -iname '*.enc' \) \
    -print -quit 2>/dev/null)"
  if [[ -n "$FORBIDDEN" ]]; then
    echo "ERROR: forbidden layout/database artifact in snapshot: $FORBIDDEN"
    CHECK_RC=5
  else
    git add "$SNAPSHOT_REL"
    STAGED_COUNT="$(git diff --cached --name-only -- "$SNAPSHOT_REL" | sed '/^[[:space:]]*$/d' | wc -l)"
    if [[ "$STAGED_COUNT" -gt 0 ]]; then
      CHECK_RC=0
    else
      echo "ERROR: snapshot has no staged files: $SNAPSHOT_REL"
      CHECK_RC=6
    fi
  fi
fi

if [[ "$CHECK_RC" -eq 0 ]]; then
  git commit -m "docs: add MPTDC $STEP_LABEL evidence $SNAPSHOT_ID" -- "$SNAPSHOT_REL"
  COMMIT_RC=$?
  if [[ "$COMMIT_RC" -eq 0 ]]; then
    SNAPSHOT_COMMIT="$(git rev-parse HEAD 2>/dev/null)"
  fi
fi

if [[ "$COMMIT_RC" -eq 0 ]]; then
  git push origin SPADMIC_test
  PUSH_RC=$?
fi

NEXT_HEAD="$(git rev-parse HEAD 2>/dev/null)"
echo "EVIDENCE_STEP=$STEP_LABEL"
echo "EVIDENCE_ID=$SNAPSHOT_ID"
echo "EVIDENCE_COLLECT_RC=$COLLECT_RC"
echo "EVIDENCE_CHECK_RC=$CHECK_RC"
echo "EVIDENCE_COMMIT_RC=$COMMIT_RC"
echo "EVIDENCE_PUSH_RC=$PUSH_RC"
echo "EVIDENCE_COMMIT=$SNAPSHOT_COMMIT"
echo "NEXT_EXPECTED_HEAD=$NEXT_HEAD"

if [[ "$PUSH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
