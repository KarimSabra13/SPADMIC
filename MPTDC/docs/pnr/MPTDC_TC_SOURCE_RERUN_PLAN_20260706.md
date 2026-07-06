# MPTDC TC Source Rerun Plan - 2026-07-06

## Status

This note records the source-level rerun path for the MPTDC TC-only closure
after the 2026-07-02 PVS PG-short analysis.

Current local implementation status:

```text
RO probe outputs added at mptdc_axis_core boundary: YES
RO probe timing exception added to canonical SDC: YES
Simple VDD/VSS block-pin policy selected for clean-LEF Innovus wrapper: YES
Legacy left/right PG label topology selected by default: NO
Block-pin sroute probe selected by default: NO
Local Verilator smoke: PASS
Server Genus/Innovus/PVS proof: PENDING
Final signoff ready: NO
Ready for tapeout: NO
```

This is still a source-change implementation checkpoint. It is not a signoff
result.

## Why A Source Rerun Is Required

The previous dryGDS/PVS failure was not only a label problem. The PVS short
analysis classified the failure as:

```text
ROOT_CAUSE_CLASS=EXPORTED_SPECIALNET_GEOMETRY
STREAMOUT_ONLY_SUSPECT=NO
```

The short path matched exported DEF special-net geometry in the lower-left PG
bridge window. A safe-copy surgical proof deleted three small BLOCKWIRE
candidates and preserved Innovus geometry/regular checks, but it still required
fresh dryGDS/PVS and was not a clean source fix.

The next clean candidate should therefore be generated from RTL/Genus/Innovus
with a simpler PG boundary:

```text
external PG block pins: VDD, VSS only
legacy VDD_LEFT/VSS_LEFT/VDD_RIGHT/VSS_RIGHT block pin labels: not default
postplace block-pin sroute probe: disabled by default
final PG gate target: zero special PG connectivity failures
```

## Implemented Source Changes

The MPTDC core now exposes two buffered observability taps:

```text
ro_slow_tap0_o
ro_fast_tap0_o
```

Both are sourced from the already buffered phase buses:

```text
slow source: slow_phase[0]
fast source: fast_phase[0]
```

The helper buffer is `mptdc_ro_probe_buffer` in:

```text
MPTDC/rtl/osc/mptdc_phase_buffer_bank.sv
```

Under the active JIHD two-stage phase-buffer topology, each probe branch adds a
dedicated `BUJIHDX12` after the internal phase distribution buffer. In
simulation, the probe remains transparent unless a physical buffer topology is
selected.

The MPTDC boundary files are updated:

```text
MPTDC/rtl/top/mptdc_core.sv
MPTDC/rtl/top/mptdc_axis_core.sv
TOP/syn/blackboxes/mptdc_axis_core_blackbox.sv
```

The TOP wrapper consumes the new block outputs internally as unused wires. The
probes are intentionally not routed through TOP pads yet:

```text
TOP/rtl/spadmic_tdc_axis_wrapper.sv
```

## Timing Policy

The canonical Genus SDC now requires and false-paths the two probe outputs:

```text
MPTDC/syn/inputs/mptdc_axis_core_typical_closed.sdc
```

The ports are debug observability outputs, not synchronous product datapath
endpoints. If either port is missing, the SDC errors out so a stale netlist
cannot silently drop the feature.

## PnR PG Policy

The clean-LEF launcher now defaults to:

```text
MPTDC_PG_STRATEGY=conservative_ro_hookup
MPTDC_BLOCK_PG_PIN_STYLE=simple_vdd_vss_pair
MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY=0
MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE=0
MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN=0
MPTDC_ENABLE_RO_PG_PROBE=0
MPTDC_ENABLE_RO_PG_HOOKUP=1
MPTDC_REQUIRE_RO_PG_HOOKUP=1
```

The lower-level Innovus policy guard accepts the simple pair styles:

```text
simple_vdd_vss_pair
vdd_vss_pair
left_vdd_right_vss
```

The historical mesh styles remain in the Tcl implementation for explicit debug
or legacy replay, but they are not the default clean source rerun path.

## Area Sweep Hook

The clean-LEF launcher accepts:

```text
--core-util <value>
```

Use this only after the baseline source rerun has clean Genus, Innovus, dryGDS,
and PVS evidence. The first run should keep the conservative `0.55` baseline.

## Local Verification

Local checks run on 2026-07-06:

```text
bash -n MPTDC/pnr/scripts/server_run_mptdc_tc_ro6_cleanlef.sh
git diff --check
bash MPTDC/syn/scripts/check_genus_axis_core_typical_closed_profile.sh
bash MPTDC/sim/verilator/run_smoke.sh 20260706_ro_probe_simple_pg_local_v2
```

Results:

```text
PROFILE_CHECK=PASS
Verilator lint=PASS
tb_axis_core_product_smoke=PASS
```

These are local checks only. They do not replace server Genus, Innovus,
Xcelium, dryGDS, or PVS.

## Recommended Server Sequence

After committing and pushing this source change, run on the server:

```sh
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source /eda/cadence/eda_2023-2024
source .venv/bin/activate 2>/dev/null || true

git fetch origin SPADMIC_test
git checkout SPADMIC_test
git pull --ff-only

export EXPECTED_HEAD=$(git rev-parse HEAD)
echo "EXPECTED_HEAD=$EXPECTED_HEAD"

bash MPTDC/syn/scripts/check_genus_axis_core_typical_closed_profile.sh

export GENUS_RUN_ID=MPTDC_TC_Source_RO6_ProbeTap_SimplePG_$(date +%Y%m%d_%H%M%S)
MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh "$GENUS_RUN_ID"
```

Push a reviewable Genus evidence snapshot:

```sh
MPTDC/ci/collect_mptdc_server_snapshot.sh genus "$GENUS_RUN_ID"

git status --short --untracked-files=no
git add "MPTDC/docs/server_snapshots/genus/$GENUS_RUN_ID"
git commit -m "docs: add MPTDC Genus snapshot $GENUS_RUN_ID"
git push origin SPADMIC_test
```

Then run the first conservative Innovus source candidate from that new Genus
handoff:

```sh
export HANDOFF_DIR=/sim/ksabra/SPADMIC_work/genus/$GENUS_RUN_ID
export INNOVUS_RUN_ID=20260706_mptdc_tc_ro6_probe_simplepg_base_$(date +%H%M%S)

MPTDC/pnr/scripts/server_run_mptdc_tc_ro6_cleanlef.sh \
  --run-id "$INNOVUS_RUN_ID" \
  --stage base_route \
  --expected-head "$EXPECTED_HEAD" \
  --genus-run-id "$GENUS_RUN_ID" \
  --handoff-dir "$HANDOFF_DIR" \
  --core-util 0.55
```

Inspect the mandatory gates:

```sh
export INNOVUS_DIR=/sim/ksabra/SPADMIC_work/innovus/$INNOVUS_RUN_ID

grep -nE 'FINAL_DRC=|FINAL_SHORTS=|FINAL_REGULAR_CONNECTIVITY_BAD=|FINAL_SPECIAL_CONNECTIVITY_BAD=|SIGNOFF_READY=|READY_FOR_TAPEOUT=' \
  "$INNOVUS_DIR/reports/digital_pnr_signoff_status.rpt"

grep -nE 'BLOCK_PG_PIN_STYLE=|BLOCK_PG_PIN_MESH_ALIGNED=|BLOCK_PG_PIN_STATUS=' \
  "$INNOVUS_DIR/reports/block_pg_pin_status.rpt"

grep -nE 'POSTPLACE_PRE_ROUTE_SROUTE_STATUS=|POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=|POSTPLACE_PRE_ROUTE_RO_PG_HOOKUP_STATUS=' \
  "$INNOVUS_DIR/reports/postplace_pre_route_sroute_status.rpt"
```

Push a reviewable Innovus evidence snapshot:

```sh
MPTDC/ci/collect_mptdc_server_snapshot.sh innovus "$INNOVUS_RUN_ID"

git status --short --untracked-files=no
git add "MPTDC/docs/server_snapshots/innovus/$INNOVUS_RUN_ID"
git commit -m "docs: add MPTDC Innovus snapshot $INNOVUS_RUN_ID"
git push origin SPADMIC_test
```

Only proceed to dryGDS/PVS if the Innovus reports show:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=0
```

After dryGDS/PVS exists, push a text-only snapshot of that run. Set `DBG_DIR`
to the actual dryGDS directory created by the streamout/PVS flow:

```sh
export DBG_DIR=/sim/ksabra/SPADMIC_work/innovus/$INNOVUS_RUN_ID/<drygds_dir_name>
export DRYGDS_SNAPSHOT_ID=${INNOVUS_RUN_ID}_$(basename "$DBG_DIR")

MPTDC_SNAPSHOT_SOURCE_DIR="$DBG_DIR" \
  MPTDC/ci/collect_mptdc_server_snapshot.sh drygds "$DRYGDS_SNAPSHOT_ID"

git status --short --untracked-files=no
git add "MPTDC/docs/server_snapshots/drygds/$DRYGDS_SNAPSHOT_ID"
git commit -m "docs: add MPTDC dryGDS PVS snapshot $DRYGDS_SNAPSHOT_ID"
git push origin SPADMIC_test
```

Final signoff is still blocked until fresh dryGDS/PVS DRC and LVS are clean.
