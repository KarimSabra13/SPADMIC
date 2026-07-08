# RO6 Latest-LEF Simple-PG Innovus Rerun

This runbook is for the fixed `RO_tune6` LEF where `VDD` and `VSS` both expose
METTP access and `vdd!` is not exported as a physical LEF pin.

The goal is to avoid the old custom RO via-stack hook and prove the simplest
possible PG topology first: one top-level `VDD`, one top-level `VSS`, native
Innovus `sroute`, strict raw special connectivity.

## Policy

- Use `MPTDC_PG_STRATEGY=innovus_sroute_golden_ro`.
- Use `MPTDC_BLOCK_PG_PIN_STYLE=simple_vdd_vss_pair`.
- Disable `MPTDC_ENABLE_RO_PG_HOOKUP`; the fixed METTP LEF should not need the
  custom RO via-stack hook.
- Keep `MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN=1` so native Innovus can connect
  block pins directly.
- Set `MPTDC_ALLOW_LEGACY_PG_TOPOLOGY=1` only to allow the supported simple
  `VDD`/`VSS` pair style instead of the newer four-pin mesh naming.
- Accept only bounded `IMPVFC-94` dangling-wire reports at the pre-route PG
  proof gate. This still fails on special opens, shorts, unconnected terminals,
  missing reports, or more than 64 dangling markers.

## Stage 1: PG Proof

Run this first. It stops after post-place/pre-route sroute.

```bash
set -euo pipefail

source /eda/cadence/eda_2023-2024

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test

export EXPECTED_HEAD="$(git rev-parse HEAD)"

bash MPTDC/pnr/scripts/server_run_mptdc_ro6_latestlef_simplepg.sh \
  --stage pg_proof \
  --expected-head "$EXPECTED_HEAD"
```

Inspect the latest matching run:

```bash
bash MPTDC/pnr/scripts/server_inspect_mptdc_ro6_latestlef_simplepg.sh
```

Strict pass criteria:

```text
BLOCK_PG_PIN_NAME only shows VDD and VSS.
POSTPLACE_PRE_ROUTE_SROUTE_STATUS=PASS.
POSTPLACE_PRE_ROUTE_SROUTE_DANGLING_ONLY_OVERRIDE=1 is acceptable only when:
  POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_ONLY_STATUS=DANGLING_ONLY
  POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_FATAL_COUNT=0
  POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_COUNT <= 64
No RO VDD/VSS unconnected terminals.
```

The first simple-PG proof run on 2026-07-08 reached this exact reduced failure
class: native sroute created wires, block PG pins were only `VDD`/`VSS`, the
custom RO hook was skipped, and special connectivity reported only 36
`IMPVFC-94` dangling-wire markers. That is not the old RO PG open/floating-pin
failure.

Do not run full closure until these are true.

## Stage 2: Full Closure

After the PG proof passes:

```bash
set -euo pipefail

source /eda/cadence/eda_2023-2024

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test

export EXPECTED_HEAD="$(git rev-parse HEAD)"

bash MPTDC/pnr/scripts/server_run_mptdc_ro6_latestlef_simplepg.sh \
  --stage full_closure \
  --expected-head "$EXPECTED_HEAD"
```

Inspect:

```bash
bash MPTDC/pnr/scripts/server_inspect_mptdc_ro6_latestlef_simplepg.sh
```

## Package Evidence

After either stage, package reports/logs/manifests into git:

```bash
set -euo pipefail

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

export RUN_DIR="$(ls -td /sim/ksabra/SPADMIC_work/innovus/*mptdc_ro6_latestlef_simplepg_* | head -1)"
export RUN_ID="$(basename "$RUN_DIR")"
export ARTIFACT_DIR="MPTDC/pnr/evidence/${RUN_ID}"
export FINAL_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef

if [ -e "$ARTIFACT_DIR" ]; then
  echo "ERROR: ARTIFACT_DIR already exists: $ARTIFACT_DIR"
  exit 6
fi

mkdir -p "$ARTIFACT_DIR"
cp -a "$RUN_DIR/reports" "$ARTIFACT_DIR/" 2>/dev/null || true
cp -a "$RUN_DIR/logs" "$ARTIFACT_DIR/" 2>/dev/null || true
cp -a "$RUN_DIR/manifests" "$ARTIFACT_DIR/" 2>/dev/null || true

mkdir -p "$ARTIFACT_DIR/lef"
cp -p "$FINAL_LEF" "$ARTIFACT_DIR/lef/RO_tune6.latest_mettp.lef"

cat > "$ARTIFACT_DIR/RUN_METADATA.txt" <<EOF
RUN_ID=$RUN_ID
RUN_DIR=$RUN_DIR
ARTIFACT_DIR=$ARTIFACT_DIR
FINAL_LEF=$FINAL_LEF
PACKAGED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
NOTE=latest fixed RO_tune6 LEF; simple VDD/VSS top-level PG; native Innovus sroute; custom RO via-stack hook disabled
EOF

find "$ARTIFACT_DIR" -type f | sort > "$ARTIFACT_DIR/file_manifest.txt"

if find "$ARTIFACT_DIR" -type f \( -name "*.enc.dat" -o -name "*.gds" -o -name "*.oas" -o -name "*.spef" -o -name "*.db" -o -name "*.tar" -o -name "*.tgz" -o -name "*.gz" \) | grep -q .; then
  echo "ERROR: binary/heavy implementation artifacts found in $ARTIFACT_DIR"
  exit 7
fi

du -sh "$ARTIFACT_DIR"
find "$ARTIFACT_DIR" -type f | wc -l

git add "$ARTIFACT_DIR"
git commit -m "evidence: add ${RUN_ID} Innovus reports"
git push origin SPADMIC_test
git rev-parse HEAD
```
