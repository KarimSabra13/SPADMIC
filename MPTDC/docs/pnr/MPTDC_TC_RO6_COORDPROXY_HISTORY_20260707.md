# MPTDC TC RO6 Coordinate-Proxy History - 2026-07-07

## Purpose

This note preserves the command history, result labels, and stop rules for the
RO6 coordinate-proxy Innovus checkpoint and the follow-up PVS/PDK alignment
audit. It is intended as a recovery trail for later review, not as a final
tapeout signoff claim.

## Current Decision

```text
GENUS_HANDOFF_STATUS=PASS
ROUTE_STATUS=PASS
PG_CONNECTIVITY_STATUS=PASS
EXTRACTION_STATUS=PASS
DRV_STATUS=PASS
SETUP_STATUS_TC=FAIL
DRC_STATUS=DEFERRED
LVS_STATUS=DEFERRED
MPTDC_TC_PHYSICAL_SIGNOFF=NO
TC_ONLY_TAPEOUT_EXCEPTION_READY=NO
READY_FOR_TAPEOUT=NO
DIGITAL_PNR_SIGNOFF=PROVISIONAL
```

The coordinate-proxy run proves the digital router can route around a simplified
RO placement proxy with clean Innovus route/connectivity/DRV gates. It does not
prove final physical verification because the real RO integration, PVS/DRC/LVS,
row-infrastructure DRC/LVS, and TC setup timing closure are still open.

## Main Identifiers

```text
branch=SPADMIC_test
server_repo=/home/validmgr/ksabra/2026_SPAD/SPADMIC
work_root=/sim/ksabra/SPADMIC_work
genus_run_id=MPTDC_TC_Source_RO6_ProbeTap_SimplePG_20260706_142804
innovus_run_id=20260706_mptdc_tc_ro6_coordproxy_final_154018
innovus_dir=/sim/ksabra/SPADMIC_work/innovus/20260706_mptdc_tc_ro6_coordproxy_final_154018
pvs_audit_id=20260706_mptdc_tc_ro6_coordproxy_final_154018_pvs_pdk_alignment_20260707_104925
pvs_audit_dir=/sim/ksabra/SPADMIC_work/innovus/20260706_mptdc_tc_ro6_coordproxy_final_154018/20260706_mptdc_tc_ro6_coordproxy_final_154018_pvs_pdk_alignment_20260707_104925
timing_review_dir=/sim/ksabra/SPADMIC_work/innovus/20260706_mptdc_tc_ro6_coordproxy_final_154018/timing_closure_review_20260707_104941
snapshot_commit=72b6ab42
coordproxy_code_commit=49a3e884
```

The Innovus run manifest was produced from `coordproxy_code_commit=49a3e884`.
The server snapshot was later committed and pushed at `snapshot_commit=72b6ab42`.

## Genus Baseline

The Genus handoff used for Innovus was:

```text
MPTDC_TC_Source_RO6_ProbeTap_SimplePG_20260706_142804
FINAL_DECISION=GENUS_TYPICAL_CLOSED
GENUS_TYPICAL_STATUS=GENUS_TYPICAL_CLOSED
READY_FOR_O13_INNOVUS_FEASIBILITY=YES
ACTIVE_SDC_FAILURE_COUNT=0
Setup WNS ps=0.3
Real timed WNS ps=0.3
Max transition/capacitance/fanout violations=0
```

The pre-PNR gate passed before launching Innovus.

## Coordinate-Proxy Innovus Result

The run used the coordinate proxy LEF:

```text
O1_RO_LEF_PATH=/sim/ksabra/SPADMIC_work/lef/ro_tune6_coordinate_proxy_20260706_154018/RO_tune6_coordinate_proxy.lef
O1_RO_LIBERTY_PATH=/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/macros/RO_tune6_real_layout_shell.lib
MPTDC_PNR_OSC_WIDTH_UM=168.945
MPTDC_PNR_OSC_HEIGHT_UM=70.5
core_util=0.55
route_layers=MET1 MET2 MET3 METTP
```

Key result lines:

```text
MPTDC_DIGITAL_SIGNOFF_EXECUTION=COMPLETE_TC_ONLY_PROVISIONAL_TIMING_NOT_CLOSED
MPTDC_TC_PNR_CLOSURE=DEFERRED evidence=tc_timing_not_closed
PG_CONNECTIVITY_STATUS=PASS
ROUTE_STATUS=PASS
FILLER_STATUS=PASS
EXTRACTION_STATUS=PASS
POWER_STATUS=PROVISIONAL
SETUP_STATUS_TC=FAIL
TC_HOLD_STATUS=PASS
DRV_STATUS=PASS
DRC_STATUS=DEFERRED
LVS_STATUS=DEFERRED
DIGITAL_PNR_SIGNOFF=PROVISIONAL evidence=row_and_block_drc_lvs_deferred_timing_not_closed
```

Route gate details:

```text
ROUTE_IMPLEMENTATION_STATUS=PASS
INNOVUS_VERIFY_DRC_STATUS=PASS
GEOMETRY_DRC_VIOLATIONS=0
SHORTS=0
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=0
REGULAR_NET_OPENS=0
SPECIAL_NET_OPENS=0
UNROUTED_NETS=0
```

## Timing Status

The extracted TC setup summary still failed:

```text
WNS=-0.063 ns
TNS=-2.045 ns
violating_paths=125
path_group=FAST_TAG_TO_PD_TS_PHYSICAL
```

The focused timing diagnosis reported:

```text
FAST_TAG_TO_PD_TS_FALSE_PATH=NO
FAST_TAG_TO_PD_TS_MULTICYCLE=NO
POSTROUTE_OPT_SETUP_WNS_NS=-0.063
POSTROUTE_OPT_SETUP_CLOSURE_STATUS=FAIL
FAST_TAG_FOCUSED_WORST_SLACK_NS=-0.043
FAST_TAG_DIAGNOSIS_SOURCE_FLOP_SCORE=900
FAST_TAG_DIAGNOSIS_BUFFER_INVERTER_ON22_SCORE=3698
FAST_TAG_DIAGNOSIS_PHYSICAL_NET_SCORE=1
FAST_TAG_DIAGNOSIS_PATH_MARKERS=1200
FAST_TAG_DIAGNOSIS_DOMINANT_TERM=BUFFER_INVERTER_ON22_DELAY
FAST_TAG_DIAGNOSIS_ACTION=STOP_OPT_LOOP_AND_REPORT_RESIDUAL_PATH
FAST_TAG_TIMING_DIAGNOSIS_STATUS=PASS
```

Representative failing path markers copied into
`timing_closure_review_20260707_104941/timing_tc_marker_extract.txt` include
paths from fast-tag flops to PD `nfast_hit_latched_reg[*]/D`, with `DFRRQJIHDX*`
source flops, `INJIHDX*`/`BUJIHDX*` buffers, and `ON22JIHDX0/1` logic before
the endpoint flops. The diagnosis indicates residual logic/cell delay rather
than a dominant physical-net problem.

## PVS And PDK Alignment Audit

The PVS/PDK audit was run after sourcing the Cadence environment and setting the
same XH018 xx31 stack used by Innovus:

```bash
source /eda/cadence/eda_2023-2024
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source .venv/bin/activate 2>/dev/null || true
git checkout SPADMIC_test
git pull --ff-only

export EXPECTED_HEAD=$(git rev-parse HEAD)
export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_INNOVUS_WORK=$MPTDC_WORK_ROOT/innovus
export INNOVUS_RUN_ID=20260706_mptdc_tc_ro6_coordproxy_final_154018
export INNOVUS_DIR="$MPTDC_INNOVUS_WORK/$INNOVUS_RUN_ID"
export PDK_ROOT=/eda/pdk/xfab/xh018
export PVS_ROOT=$PDK_ROOT/cadence/v10_1/pvs/v10_1_1/PVS
export PVS_STACK=XH018_1131
export PVS_STACK_DIR="$PVS_ROOT/$PVS_STACK"
export PVS_DRC_RULE="$PVS_ROOT/xh018_DRC.rul"
export PVS_LVS_RULE="$PVS_ROOT/xh018_LVS.rul"
export PVS_CFG="$PVS_ROOT/pvs.cfg"
export PVS_TECH_RULESETS="$PVS_STACK_DIR/techRuleSets"
export QRC_ROOT=$PDK_ROOT/cadence/v10_1/QRC_pvs/v10_1_1/XH018_1131
export QRC_LVSFILE_TC="$QRC_ROOT/QRC-Typ/lvsfile"
export PVS_AUDIT_ID="${INNOVUS_RUN_ID}_pvs_pdk_alignment_$(date +%Y%m%d_%H%M%S)"
export PVS_AUDIT_DIR="$INNOVUS_DIR/$PVS_AUDIT_ID"
mkdir -p "$PVS_AUDIT_DIR/reports" "$PVS_AUDIT_DIR/manifests"
```

The audit report was written with:

```bash
{
  echo "EXPECTED_HEAD=$EXPECTED_HEAD"
  echo "INNOVUS_RUN_ID=$INNOVUS_RUN_ID"
  echo "INNOVUS_DIR=$INNOVUS_DIR"
  echo "TECHNOLOGY_LEF_EXPECTED=/eda/pdk/xfab/xh018/cadence/v9_0/techLEF/v9_0_1/xh018_xx31_HD_MET3_METMID.lef"
  echo "CAPTABLE_TC_EXPECTED=/eda/pdk/xfab/xh018/cadence/v9_0/capTbl/v9_0_1/xh018_xx31_MET3_METMID_typ.capTbl"
  echo "PVS_STACK=$PVS_STACK"
  echo "PVS_DRC_RULE=$PVS_DRC_RULE"
  echo "PVS_LVS_RULE=$PVS_LVS_RULE"
  echo "PVS_CFG=$PVS_CFG"
  echo "PVS_TECH_RULESETS=$PVS_TECH_RULESETS"
  echo "QRC_LVSFILE_TC=$QRC_LVSFILE_TC"
  echo
  grep -nE 'technology_lef:|captable_tc:|qrc_root:|route_layers:|O1_RO_LEF_PATH:|O1_RO_LIBERTY_PATH:' \
    "$INNOVUS_DIR/manifests/run_manifest.txt" || true
  echo
  type -a pvs || true
  type -a pegasus || true
  command -v pvs || true
  command -v pegasus || true
  pvs -version 2>&1 | head -40 || true
  pegasus -version 2>&1 | head -40 || true
  echo
  for f in "$PVS_DRC_RULE" "$PVS_LVS_RULE" "$PVS_CFG" "$PVS_TECH_RULESETS" "$QRC_LVSFILE_TC"; do
    ls -ld "$f" 2>&1 || true
  done
} | tee "$PVS_AUDIT_DIR/reports/pvs_pdk_alignment.rpt"
```

Observed PDK alignment:

```text
EXPECTED_HEAD=72b6ab428d905ac740bf4a5ff11b3496ceec8753
PVS_STACK=XH018_1131
TECHNOLOGY_LEF_EXPECTED=/eda/pdk/xfab/xh018/cadence/v9_0/techLEF/v9_0_1/xh018_xx31_HD_MET3_METMID.lef
CAPTABLE_TC_EXPECTED=/eda/pdk/xfab/xh018/cadence/v9_0/capTbl/v9_0_1/xh018_xx31_MET3_METMID_typ.capTbl
PVS_DRC_RULE=/eda/pdk/xfab/xh018/cadence/v10_1/pvs/v10_1_1/PVS/xh018_DRC.rul
PVS_LVS_RULE=/eda/pdk/xfab/xh018/cadence/v10_1/pvs/v10_1_1/PVS/xh018_LVS.rul
PVS_CFG=/eda/pdk/xfab/xh018/cadence/v10_1/pvs/v10_1_1/PVS/pvs.cfg
PVS_TECH_RULESETS=/eda/pdk/xfab/xh018/cadence/v10_1/pvs/v10_1_1/PVS/XH018_1131/techRuleSets
QRC_LVSFILE_TC=/eda/pdk/xfab/xh018/cadence/v10_1/QRC_pvs/v10_1_1/XH018_1131/QRC-Typ/lvsfile
```

Observed tool-path issue:

```text
pvs is /usr/sbin/pvs
pvs is /eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs
pvs is /eda/cadence/2023-24/RHELx86/PVS_22.22.000/tools/bin/pvs
pvs is /eda/cadence/2023-24/RHELx86/PEGASUS_23.11.000/bin/pvs
pegasus is /eda/cadence/2023-24/RHELx86/PEGASUS_23.11.000/bin/pegasus
command -v pvs -> /usr/sbin/pvs
command -v pegasus -> /eda/cadence/2023-24/RHELx86/PEGASUS_23.11.000/bin/pegasus
pvs -version -> invalid option from /usr/sbin/pvs
pegasus -version -> Pegasus 23.11-s009
```

Conclusion: do not invoke bare `pvs` while `/usr/sbin/pvs` is first in `PATH`.
Use the full Cadence PVS path or Pegasus explicitly for any physical-verification
debug run.

The audit also copied:

```text
manifests/innovus_run_manifest.txt
reports/digital_pnr_signoff_status.rpt
reports/route_status.rpt
reports/physical_verification_status.md
```

## Historical PVS Short Reminder

The previous PVS PG short was not label-only. The documented classification was:

```text
ROOT_CAUSE_CLASS=EXPORTED_SPECIALNET_GEOMETRY
STREAMOUT_ONLY_SUSPECT=NO
```

It involved VDD/VSS label collapse and physical conductor evidence. Any next
PVS/LVS debug must explicitly check for:

```text
VDD_LEFT
VDD_RIGHT
VSS_LEFT
VSS_RIGHT
Different labels
VDD/VSS shorts
```

Do not treat `INNOVUS_VERIFY_DRC_STATUS=PASS` or `SPECIAL_NET_CONNECTIVITY_BAD=0`
as equivalent to foundry PVS/LVS pass.

## Stop Rules

```text
Do not claim READY_FOR_TAPEOUT=YES while SETUP_STATUS_TC=FAIL.
Do not claim READY_FOR_TAPEOUT=YES while DRC_STATUS/LVS_STATUS are DEFERRED.
Do not call bare pvs until PATH is fixed away from /usr/sbin/pvs.
Do not broaden post-route sroute to repair a PVS short; prior broad PG repair created shorts.
Do not false-path or multicycle FAST_TAG_TO_PD_TS_PHYSICAL without a signed timing-intent decision.
Do not treat the coordinate-proxy RO as final real-RO layout integration.
```

## Immediate Capture Commands

The audit and timing-review directories were created under the server work tree.
Run this next to preserve them in the tracked snapshot area:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source /eda/cadence/eda_2023-2024
source .venv/bin/activate 2>/dev/null || true
git checkout SPADMIC_test
git pull --ff-only

export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_INNOVUS_WORK=$MPTDC_WORK_ROOT/innovus
export INNOVUS_RUN_ID=20260706_mptdc_tc_ro6_coordproxy_final_154018
export INNOVUS_DIR="$MPTDC_INNOVUS_WORK/$INNOVUS_RUN_ID"
export PVS_AUDIT_ID=20260706_mptdc_tc_ro6_coordproxy_final_154018_pvs_pdk_alignment_20260707_104925
export PVS_AUDIT_DIR="$INNOVUS_DIR/$PVS_AUDIT_ID"
export TIMING_REVIEW_DIR="$INNOVUS_DIR/timing_closure_review_20260707_104941"

mkdir -p "$PVS_AUDIT_DIR/reports/timing_closure_review"
cp "$TIMING_REVIEW_DIR"/* "$PVS_AUDIT_DIR/reports/timing_closure_review/" 2>/dev/null || true

MPTDC_SNAPSHOT_SOURCE_DIR="$PVS_AUDIT_DIR" MPTDC/ci/collect_mptdc_server_snapshot.sh pvs "$PVS_AUDIT_ID"
git add "MPTDC/docs/server_snapshots/pvs/$PVS_AUDIT_ID"
if git commit -m "docs: add MPTDC PVS PDK and timing audit $PVS_AUDIT_ID"; then PVS_AUDIT_COMMIT_RC=0; else PVS_AUDIT_COMMIT_RC=$?; fi
if git push origin SPADMIC_test; then PUSH_RC=0; else PUSH_RC=$?; fi

echo "PVS_AUDIT_COMMIT_RC=$PVS_AUDIT_COMMIT_RC"
echo "PUSH_RC=$PUSH_RC"
```

After this evidence is captured, the next technical closure item is the residual
TC setup failure in `FAST_TAG_TO_PD_TS_PHYSICAL`. Physical verification can be
run for debug/provenance, but it should remain a debug gate until timing is
closed.
