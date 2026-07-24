# Digital Subblock Closure and Assembly Roadmap

Status: cumulative soft-assembly flow implemented locally; sealed OA source
evidence and the complete p03 signal-interface preclassification pass. Local
`VDD/VSS` maps to chip `DVDD/DVSS`. The corrected master-terminal probe proves
four current METTP review candidates on `I5/BOX_RING2` and
`I6/TXRX4TDC2_HV`, but no bridge is accepted. The earlier `I5` recommendation
used invalid exterior whitespace because the hollow `BOX_RING2` pad boundary
was treated as a solid obstacle. The corrected processor-only normalized
floorplan replay is accepted and selects the complete `I6` pair against the
largest true interior region. The sole next action is a bounded read-only
hierarchical METTP corridor probe around I6. Position and Event OOC results
remain immutable supporting evidence, not child hard macros on the p00-p03
implementation path. No assembly phase is promoted.

Date: 2026-07-24.

This document is the execution authority for building the matrix-top digital
logic as four cumulative fresh-from-RTL phases. It preserves the TX, Position,
and Event closure evidence as diagnostics while avoiding child LEF/GDS reuse
in the p00-p03 physical implementation.

## 0. Cumulative Soft Assembly Authority

This section supersedes the hard-macro integration language in Sections 3-5
for phases p00-p03. Those sections remain historical OOC closure context.

The exact phase order is:

| Phase | Canonical source/layout top | Cumulative groups | Density gate |
| --- | --- | --- | --- |
| `p00_tx` | `spadmic_digital_assembly_v1_p00_tx` | TX packet + TX DDR strip | `NOT_RUN` |
| `p01_position` | `spadmic_digital_assembly_v1_p01_position` | p00 + Position | `NOT_RUN` |
| `p02_event_control` | `spadmic_digital_assembly_v1_p02_event_control` | p01 + Event | `NOT_RUN` |
| `p03_matrix_interface` | `spadmic_digital_assembly_v1_p03_matrix_interface` | p02 + matrix OR, snapshot/reset, and CFG | exact whole-extent density set |

Every phase is independently synthesized and implemented from RTL. The
critical-path contract is:

```text
IMPLEMENTATION=CUMULATIVE_SOFT_LOGIC
BUILD_MODE=FRESH_FROM_RTL
HARD_MACRO_COUNT=0
CHILD_GDS_MERGE_COUNT=0
TARGET_UTILIZATION=0.60
MAX_LOCAL_DENSITY=0.70
SIGNAL_ROUTE_LAYERS=MET1-MET3
METTP_POLICY=PG_AND_BOUNDED_PIN_ACCESS_ONLY
TIMING_CORNER=TC
ROOT_CLOCK=clk_160m_i
AUTOMATED_CDC_RDC_GATE=NO
```

`clk_sys`, `clk_cfg_40m`, and `clk_ref_40m` are related generated clocks from
the 160 MHz root. No asynchronous clock groups may be introduced to suppress
timing paths. Setup and hold WNS must be nonnegative, TNS and violating-path
counts must be zero, and design-rule constraints must be clean before Innovus.

The immutable read-only OA audit of `SPADMIC/SPADMIC2/layout` and
`SPADMIC/matrice5/layout` is a prerequisite. Those two cells reside in
different physical OA roots that both use the logical library name `SPADMIC`,
so the audit uses two sequential process-isolated `cds.lib` contexts. It emits
fixed obstacles, soft group guides, and exact matrix proxy pin access. METTP
VDD/VSS anchors are emitted only when direct exact net ownership is proven;
overlap, boundary contact, and nearest-net context remain review-only. Unknown
matrix terminal families block p03 only when they fail the reviewed physical
policy; they do not invalidate a reviewed p00-p02 contract.

The logical-to-chip PG naming contract is explicit:

```text
assembly VDD -> chip DVDD
assembly VSS -> chip DVSS
```

Name equivalence alone does not select geometry. The read-only
`server_probe_spadmic2_digital_pg_access.sh` transaction inventories exact
current top-level geometry and every child master `DVDD/DVSS` terminal figure,
including disconnected terminals that have no `instTerm`. It records optional
connected-net evidence separately. For child figures it also records the OA
object type, transform provenance, master-local bbox, and top-level bbox.
Only a database transform or a bbox-verified ordinary-instance reconstruction
may produce candidate coordinates; unresolved mosaic or nonstandard transforms
remain master-local review evidence. The classifier treats exact
`I5/SPADMIC/BOX_RING2/layout R0` as a hollow physical boundary, normalizes its
lower-left corner to `(0,0)`, insets the core by `164 um`, and subtracts every
other top-instance bbox as a fixed obstacle. It ranks only complete same-owner
`VDD/VSS` pairs against the largest corrected interior region. The legacy
cellview-exterior whitespace report is retained only as superseded provenance.
Every discovered geometry remains review-only until a selected-instance METTP
corridor probe and a separate candidate bridge contract pass.

### Per-Phase Transaction Order

For each phase, use one foreground EDA action and stop for review after every
transaction:

```text
1. server_audit_spadmic2_assembly_contract.sh             # complete, sealed OA
2. server_probe_spadmic2_digital_pg_access.sh             # complete, sealed OA
3. server_replay_spadmic2_digital_pg_floorplan.sh         # complete, sealed CPU
4. server_probe_spadmic2_selected_pg_corridor.sh          # current read-only OA gate
5. review and bind one VDD/VSS-to-DVDD/DVSS bridge contract
6. server_preflight_digital_assembly_phase.sh             # phase + RTL checks
7. server_run_digital_assembly_phase_genus.sh             # one Genus action
8. server_run_digital_assembly_phase_innovus.sh           # one Innovus action
9. server_stage_digital_assembly_phase_handoff.sh         # immutable package
10. server_preflight_digital_assembly_phase_pvs.sh        # controls only
11. server_run_digital_assembly_phase_pvs.sh ... base
12. p03 only: server_run_digital_assembly_phase_pvs.sh ... density
13. server_run_digital_assembly_phase_pvs.sh ... lvs
14. review the phase gate before starting the next phase
```

p00-p02 deliberately skip density. Their accepted physical tuple is base DRC
`PASS` plus exact-GDS LVS `MATCH`, with density recorded as
`NOT_RUN_BY_POLICY`. p03 must run density. A nonzero p03 density transaction is
classifiable only when every result belongs to `R1M1`, `R1M2`, `R1M3`, or
`R1MT`, every marker spans the exact assembly extent, and count reconciliation
passes. Classified debt remains a physical density failure and does not
authorize OA insertion.

### OA Insertion Boundary

Insertion into `SPADMIC2/layout` is authorized only after p03 has this exact
tuple:

```text
PVS_BASE_DRC_STATUS=PASS
PVS_DENSITY_DRC_STATUS=PASS
PVS_LVS_STATUS=MATCH
ASSEMBLY_PHASE_ACCEPTED=YES
OA_INSERTION_AUTHORIZED=YES
```

Then run the read-only candidate gate and immutable backup transaction before
the write transaction:

```text
server_prepare_digital_assembly_p03_oa_insertion.sh
server_insert_digital_assembly_p03_into_spadmic2.sh
```

The current write script can replace at most one allowlisted p00-p03 assembly
instance, but its existing `(0,0) R0` insertion assumption is explicitly
blocked. A normalized assembly whose `BOX_RING2` boundary starts at `(0,0)`
must be inserted at the reviewed assembly-to-source translation
`(-0.240,-287.715) R0`; that translation must be generated from sealed
evidence and verified by the read-only candidate gate before any write is
authorized. The script cannot remove an unrelated instance. OA bbox and
boundary-pin parity prove only the integration contract, not logical
equivalence or full-chip signoff. After insertion, full-top GDS export, base
DRC, density DRC, and LVS are separate mandatory gates and remain `NOT_RUN`
until explicitly executed.

p04 MPTDC remains blocked on final abstracts and an exact pin contract. p05
CSR/I2C remains deferred. Neither is inferred into p03.

## 1. Current Milestone

`spadmic_tx_packet_core` is an electrically matched provisional baseline, not
a promoted hard macro:

```text
PVS_LVS_STATUS=MATCH
PVS_BASE_DRC_STATUS=FAIL
PVS_BASE_ANTENNA_RESULTS=135
PVS_BASE_NON_ANTENNA_RESULTS=0
INNOVUS_MET1_MIN_AREA_MARKERS=4
PVS_DENSITY_DRC_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
FINAL_SIGNOFF_READY=NO
```

The matched GDS remains useful as an immutable diagnostic and Virtuoso repair
baseline. Any physical edit changes its hash and requires new base DRC,
density DRC, and explicit LVS evidence.

The packet debt does not prevent the fresh cumulative `p00_tx` build because
that phase does not reuse the provisional packet GDS as a child hard macro.
It remains diagnostic evidence: the new p00 implementation must independently
pass its own timing, connectivity, DRC, export, and exact-GDS LVS gates.

## 2. Sources of Truth

The following files are authoritative:

```text
TOP/docs/layout_audits/SPADMIC2_20260709_072331/
TOP/docs/server_snapshots/handoff/position_core_gridfit_20260717_114810/
TOP/docs/server_snapshots/pvs_drc/position_template_discovery_20260717_125002/
TOP/docs/server_snapshots/pvs_drc/position_rule_semantics_review_20260717_161842/
TOP/docs/server_snapshots/pvs_drc/position_gds_layer_applicability_20260720_105724/
TOP/docs/server_snapshots/pvs_drc/position_strict_preflight_20260720_111548_failed/
TOP/docs/server_snapshots/pvs_drc/position_strict_preflight_20260720_113452/
TOP/docs/server_snapshots/pvs_drc/position_base_drc_20260720_115921/
TOP/docs/server_snapshots/pvs_drc/position_density_drc_20260720_133314/
TOP/docs/server_snapshots/pvs_lvs/position_lvs_template_identity_20260720_141229_failed/
TOP/docs/server_snapshots/pvs_lvs/position_lvs_semantic_audit_20260720_143505_failed/
TOP/docs/server_snapshots/pvs_lvs/position_lvs_auxiliary_cdl_reference_20260720_152848_failed/
TOP/docs/server_snapshots/pvs_lvs/position_lvs_match_review_20260720_163037/
TOP/docs/server_snapshots/genus/genus_ooc_event_coordinator_20260720_163038/
TOP/docs/server_snapshots/innovus/innovus_ooc_harden_event_coordinator_20260720_173527/
TOP/docs/server_snapshots/handoff/event_coordinator_20260720_173527/
TOP/docs/server_snapshots/pvs_drc/event_strict_preflight_20260721_104756/
TOP/docs/server_snapshots/pvs_drc/event_base_drc_20260721_110404/
TOP/docs/server_snapshots/pvs_drc/event_density_drc_20260721_112300/
TOP/docs/server_snapshots/pvs_lvs/event_lvs_match_20260721_121034/
TOP/pnr/assembly/spadmic_digital_subblock_portfolio.csv
TOP/pnr/assembly/spadmic_digital_floorplan_regions.csv
TOP/pnr/assembly/spadmic_digital_assembly_phases.csv
TOP/pnr/assembly/spadmic_digital_assembly_contract.json
TOP/pnr/assembly/matrice5_unknown_family_policy.csv
TOP/pnr/assembly/spadmic_digital_assembly_v1.sv
TOP/ci/server_audit_spadmic2_assembly_contract.sh
TOP/ci/server_probe_spadmic2_digital_pg_access.sh
TOP/ci/server_replay_spadmic2_digital_pg_floorplan.sh
TOP/pnr/scripts/classify_spadmic2_digital_pg_access.py
TOP/ci/server_preflight_digital_assembly_phase.sh
TOP/ci/server_run_digital_assembly_phase_genus.sh
TOP/ci/server_run_digital_assembly_phase_innovus.sh
TOP/ci/server_stage_digital_assembly_phase_handoff.sh
TOP/ci/server_preflight_digital_assembly_phase_pvs.sh
TOP/ci/server_run_digital_assembly_phase_pvs.sh
TOP/ci/server_prepare_digital_assembly_p03_oa_insertion.sh
TOP/ci/server_insert_digital_assembly_p03_into_spadmic2.sh
TOP/pnr/scripts/probe_spadmic2_digital_pg_access.il
TOP/pnr/scripts/classify_spadmic2_digital_pg_access.py
TOP/docs/34_INNOVUS_22_33_PG_ROUTING_COMMAND_NOTES.md
TOP/docs/38_TX_PACKET_CORE_PROVISIONAL_DRC_WAIVER_AND_PVS_LVS_EXECUTION.md
TOP/docs/39_TX_PACKET_CORE_PVS_BASE_DRC_NON_ANTENNA_ANALYSIS.md
TOP/docs/40_TX_PACKET_CORE_VIRTUOSO_IMPORT_HANDOFF.md
```

Run the portfolio/phase gate before generating any cumulative phase contract:

```bash
python3 TOP/pnr/scripts/validate_digital_subblock_portfolio.py
```

Acceptance is exactly:

```text
STATUS=PASS
ERROR_COUNT=0
```

Do not move a reservation by inspection alone. Update the JSON/CSV contract,
rerun the read-only OA audit and validator, review clearances, and bind the
result to the release commit before launching Cadence.

## 3. Portfolio and Order

| Priority | Block | Implementation | Physical top | Current action |
| --- | --- | --- | --- | --- |
| 0 | TX packet core | Hard macro | `spadmic_tx_packet_core` | Manual MET1 and antenna closure |
| 0 | TX DDR strip | Hard macro | `spadmic_tx_ddr_strip` | Internal PG and PVS closure |
| 1 | Position core | Hard macro | `spadmic_position_core` | Retain accepted LVS match; resolve density only at assembled-fill review or by formal waiver |
| 2 | Event coordinator | Hard macro | `spadmic_event_coordinator` | Retain accepted LVS match; resolve density only at assembled-fill review or by formal waiver |
| 3 | Central control | Soft region | stable logical modules | Insert with `p02_event_control` |
| 4 | Matrix interface | Soft region | stable logical modules | Guided assembly placement |
| 5 | MPTDC frontend | Blocked soft region | unavailable final boundary | Wait for abstracts and pin contract |
| 6 | CSR/I2C | Deferred soft region | stable logical modules | Add after pad/control contract |

Only one Cadence implementation run is launched at a time. Position and event
can be qualified OOC while TX manual repair proceeds, but their assembly
insertion remains gated by the preceding promoted phase.

## 4. Fixed Floorplan Reservations

All coordinates are top-level microns:

| Region | Bounding box |
| --- | --- |
| Position hard macro | `(528.305, 20.000)` to `(1480.000, 680.000)` |
| Event hard macro | `(1500.000, 280.000)` to `(1737.460, 500.000)` |
| Central-control soft guide | `(1500.000, 20.000)` to `(2040.000, 220.000)` |
| CSR/I2C deferred guide | `(1500.000, 220.000)` to `(1737.460, 260.000)` |
| Matrix-interface soft guide | `(25.915, 700.000)` to `(2112.884, 756.039)` |
| MPTDC route-only corridor | `(2132.884, 776.039)` to `(2230.020, 3041.110)` |

The OOC generators subtract a `10 um` margin from each hard reservation:

```text
position requested core = 931.280 um x 639.520 um
position expected die   = 951.440 um x 659.680 um
event requested core    = 217.280 um x 199.360 um
event expected die      = 237.440 um x 219.520 um
```

These are maximum reserved envelopes, not permission to increase placement
density until the design fits. The generated plan must fail if it no longer
matches the reservation.

## 5. Hard-Macro Closure Contract

A reusable hard child is accepted only when all independent gates are
attributable to one immutable GDS:

```text
RTL_BOUNDARY_STATUS=PASS
GENUS_TC_TIMING_STATUS=PASS
INNOVUS_REGULAR_CONNECTIVITY_STATUS=PASS
INNOVUS_SPECIAL_CONNECTIVITY_STATUS=PASS
INNOVUS_DRC_STATUS=PASS
TOP_RESERVATION_FIT_STATUS=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
LEF_BBOX_PARITY_STATUS=PASS
LEF_PIN_PARITY_STATUS=PASS
PVS_BASE_DRC_STATUS=PASS or FORMALLY_WAIVED
PVS_DENSITY_DRC_STATUS=PASS or FORMALLY_WAIVED
PVS_LVS_STATUS=MATCH
```

Typical-corner closure is the current project milestone:

```text
MMMC_STATUS=NOT_RUN_TYPICAL_ONLY
PEX_STATUS=NOT_RUN
SIGNOFF_READY=BLOCK_LEVEL_ONLY
```

Do not translate `BLOCK_LEVEL_ONLY` into full-chip signoff.

## 6. Position Core Boundary

`TOP/rtl/spadmic_position_core.sv` is a transparent physical wrapper around
`spadmic_position_snapshot_packetizer`. It does not change behavior, add
state, or rename the active top-level connections. The wrapper creates a
stable physical and LVS top while the raw snapshot frontend remains soft.

Boundary files:

```text
TOP/rtl/spadmic_position_core.sv
TOP/syn/filelists/ooc/spadmic_position_core.f
TOP/syn/constraints/ooc/spadmic_position_core.sdc
```

The position OOC pin plan places snapshot inputs on the north boundary and
packet outputs on the east boundary. VDD/VSS use explicit exact `METTP`
geometry and `corePin` stitching.

### Position Step 1: Server Preflight and Genus

Use a foreground interactive shell. The release message must provide the exact
`EXPECTED_HEAD`.

```bash
set +e

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
RUN_OK=1

git checkout SPADMIC_test
CHECKOUT_RC=$?
git pull --ff-only origin SPADMIC_test
PULL_RC=$?

EXPECTED_HEAD=REPLACE_WITH_RELEASE_COMMIT
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"

echo "CHECKOUT_RC=$CHECKOUT_RC"
echo "PULL_RC=$PULL_RC"
echo "EXPECTED_HEAD=$EXPECTED_HEAD"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"

if [ "$CHECKOUT_RC" -ne 0 ] || [ "$PULL_RC" -ne 0 ] || \
   [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: repository head mismatch"
    RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    source /eda/cadence/eda_2023-2024
    EDA_RC=$?
    echo "EDA_RC=$EDA_RC"
    if [ "$EDA_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: Cadence environment failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
    POSITION_GENUS_RUN="genus_ooc_position_core_$(date +%Y%m%d_%H%M%S)"

    bash TOP/syn/scripts/run_genus_ooc_block.sh \
        position_core \
        "$POSITION_GENUS_RUN"
    POSITION_GENUS_RC=$?

    POSITION_GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$POSITION_GENUS_RUN/position_core"
    echo "POSITION_GENUS_RC=$POSITION_GENUS_RC"
    echo "POSITION_GENUS_RUN=$POSITION_GENUS_RUN"
    echo "POSITION_GENUS_ROOT=$POSITION_GENUS_ROOT"

    cat "$POSITION_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt" 2>/dev/null
    cat "$SPADMIC_WORK_ROOT/genus/$POSITION_GENUS_RUN/SUMMARY.md" 2>/dev/null
fi
```

Stop after this command. Continue only when the gate says:

```text
STATUS=PASS
TC_TIMING_STATUS=PASS
BOUNDARY_PORT_STATUS=PASS
RESULT=READY_FOR_ISOLATED_INNOVUS_OOC
WNS_PS>=0
TNS_PS=0
VIOLATING_PATH_COUNT=0
```

The TC gate has an exact elaborated-netlist boundary contract. It rejects
missing or additional base ports, wrong directions, wrong scalar/vector
widths, nested ports, and duplicate top definitions. The current contracts
are 20 base ports / 249 scalar bits for `spadmic_position_core` and 30 base
ports / 63 scalar bits for `spadmic_event_coordinator`.

#### Recorded Position Step 1 Result

The foreground server run completed on 2026-07-17 from exact commit
`67570818ac8e9cf38b44b4c8f91dca6f0a45673b`:

```text
POSITION_GENUS_RUN=genus_ooc_position_core_20260717_101642
POSITION_GENUS_RC=0
STATUS=PASS
TC_TIMING_STATUS=PASS
RESULT=READY_FOR_ISOLATED_INNOVUS_OOC
BOUNDARY_PORT_STATUS=PASS
EXPECTED_BASE_PORT_COUNT=20
ACTUAL_BASE_PORT_COUNT=20
EXPECTED_BIT_PORT_COUNT=249
ACTUAL_BIT_PORT_COUNT=249
UNRESOLVED_REFERENCE_COUNT=0
CLOCK_PERIOD_PS=6250.0
CLOCK_REGISTER_COUNT=2437
WNS_PS=14.0
TNS_PS=0.0
VIOLATING_PATH_COUNT=0
ERROR_COUNT=0
```

The netlist and SDC evidence hashes are:

```text
POSTSYN_NETLIST_SHA256=53bc725784e78fba8c2188f8ef9e31965abc84ffa02c195be1bf8e6e916518c6
POSTSYN_SDC_SHA256=69929a339cb2b2951bee4f7b2b6b558277e13bfac504951c57b38cf497d4f21f
```

All blocking warning classes were zero. `tool_warning count=2` records the
generic `MESG-11` maximum-message-print-count warning and does not override
the explicit zero design-rule, latch, timing-intent, tool-error, and
unresolved-reference gates. This result is `TYPICAL_CLOSED` and
`INNOVUS_HANDOFF_READY`; it is not MMMC or signoff evidence.

### Position Step 2: Isolated Innovus

Run this as a separate command after reviewing Step 1:

```bash
set +e
source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work

POSITION_PNR_RUN="innovus_ooc_harden_position_core_$(date +%Y%m%d_%H%M%S)"

bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh \
    position_core \
    "$POSITION_GENUS_RUN" \
    "$POSITION_PNR_RUN"
POSITION_PNR_RC=$?

POSITION_PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$POSITION_PNR_RUN/blocks/position_core"
echo "POSITION_PNR_RC=$POSITION_PNR_RC"
echo "POSITION_PNR_ROOT=$POSITION_PNR_ROOT"

for REPORT in \
    ooc_harden_status.rpt \
    verify_connectivity_regular.rpt \
    verify_connectivity_pg.rpt \
    verify_drc_post_route.rpt \
    gds_export_audit.rpt
do
    echo
    echo "===== $REPORT ====="
    cat "$POSITION_PNR_ROOT/reports/$REPORT" 2>/dev/null || \
        echo "MISSING: $POSITION_PNR_ROOT/reports/$REPORT"
done
```

Do not stage a package unless all Innovus gates are zero and the GDS audit
proves both map and merge.

#### Recorded Position Step 2 Result

The first isolated Position implementation ran in the foreground on
2026-07-17 from exact commit
`64a1a29846f42b382aea4d1afbed8455963fbbec`, bound to the accepted Genus run
`genus_ooc_position_core_20260717_101642`:

```text
POSITION_PNR_RUN=innovus_ooc_harden_position_core_20260717_111443
POSITION_PNR_RC=0
RESULT=ABSTRACT_READY_FOR_TOP_REVIEW
INNOVUS_DRC_STATUS=PASS
DRC_MARKER_TOTAL=0
REGULAR_CONNECTIVITY_STATUS=PASS
PG_CONNECTIVITY_STATUS=PASS
MET1_MIN_AREA_MARKER_COUNT=0
ANTENNA_MARKER_COUNT=0
OTHER_MARKER_COUNT=0
POSTROUTE_SETUP_TIMING=PASS
POSTROUTE_HOLD_TIMING=PASS
WORST_REPORTED_SETUP_SLACK_PS=26
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
GDS_SHA256=49a7a030f24752226b39ba7a4371ab62a1927c42bf7494ecc6abccf75f12eaac
```

The physical route tuple is clean, but top review rejected this GDS as an
immutable package candidate. `verifyConnectivity` reports an actual design
boundary of `952.000 x 660.240 um`; the fixed `POSITION_CORE` reservation is
only `951.695 x 660.000 um`. The excess is `0.305 um` in width and `0.240 um`
in height. Packaging or PVS on this GDS would be wasted because the required
floorplan replay changes its hash.

The OOC generator now reads the checked-in region CSV rather than duplicating
Position/Event coordinates, floors the usable core to the `0.560 um` grid,
and predicts a Position die of `951.440 x 659.680 um`. Innovus now records
actual die dimensions and requires `TOP_RESERVATION_FIT_STATUS=PASS` before
returning `ABSTRACT_READY_FOR_TOP_REVIEW`.

The run-level `SUMMARY.md` also contained three nonphysical fallback strings:
`default`, `MET1 MET3`, and deferred PG hookup. The authoritative status
report proves `met1_effort`, `MET1-MET3`, and `EXPLICIT_EXACT`. The wrapper
now sources those summary fields from `ooc_harden_status.rpt`; this reporting
defect did not invalidate the zero-violation route evidence.

#### Recorded Position Step 2 Corrected Replay

The reservation-corrected replay ran in one fresh foreground Innovus process
on 2026-07-17 from exact commit
`179baaf3fc35c931d95d47d70f84c760ccfd17ed`. It reused the accepted Genus
netlist and SDC without modification:

```text
POSITION_GENUS_RUN=genus_ooc_position_core_20260717_101642
POSTSYN_NETLIST_SHA256=53bc725784e78fba8c2188f8ef9e31965abc84ffa02c195be1bf8e6e916518c6
POSTSYN_SDC_SHA256=69929a339cb2b2951bee4f7b2b6b558277e13bfac504951c57b38cf497d4f21f
POSITION_PNR_RUN=innovus_ooc_harden_position_core_gridfit_20260717_114810
POSITION_PNR_RC=0
```

The actual die is `951.440 x 659.680 um` inside the fixed
`951.695 x 660.000 um` reservation. The remaining width and height margins
are `0.255 um` and `0.320 um`, respectively. The abstract LEF records the
same `951.440 x 659.680 um` macro size.

```text
POSITION_GRID_SAFE_REPLAY_STATUS=PASS
RESULT=ABSTRACT_READY_FOR_TOP_REVIEW
TOP_RESERVATION_FIT_STATUS=PASS
INNOVUS_DRC_STATUS=PASS
DRC_MARKER_TOTAL=0
REGULAR_CONNECTIVITY_STATUS=PASS
PG_CONNECTIVITY_STATUS=PASS
POSTROUTE_SETUP_TIMING=PASS
POSTROUTE_HOLD_TIMING=PASS
WORST_REPORTED_SETUP_SLACK_NS=0.048
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
GDS_SHA256=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
ABSTRACT_LEF_SHA256=1eb91d021edccd4806a5516ef1f2aa0a2718607ee84c248d2d0e12cd8e698683
ROUTED_PG_NETLIST_SHA256=4078d8b5f277923948371898663ea2b0093fae205bad09e2f91c5f502f251cfd
```

This tuple supersedes the overflowed `49a7a030...` GDS as the Position
candidate for immutable staging. It is still typical-only and is not a
qualified hard macro: package audit, package-local source preparation and pin
parity, PVS base DRC, PVS density DRC, and explicit exact-GDS LVS `MATCH`
remain separate gates.

#### Recorded Position Step 3 Immutable Handoff

The corrected replay was staged from exact release commit
`8a617c9f8049340cebc777783255acffd55212d6` into:

```text
PACKAGE=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810
PACKAGE_STATUS=CANDIDATE
HANDOFF_STAGE_RC=0
HANDOFF_AUDIT_RC=0
HANDOFF_AUDIT_STATUS=PASS
HANDOFF_AUDIT_ERROR_COUNT=0
POSITION_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS
```

The package preserves the accepted physical identity and creates a separate
canonical LVS source:

```text
PACKAGE_GDS_SHA256=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
PACKAGE_ABSTRACT_LEF_SHA256=1eb91d021edccd4806a5516ef1f2aa0a2718607ee84c248d2d0e12cd8e698683
PACKAGE_RAW_PG_NETLIST_SHA256=4078d8b5f277923948371898663ea2b0093fae205bad09e2f91c5f502f251cfd
PACKAGE_CANONICAL_LVS_SOURCE_SHA256=a5e81c21e633ae1b55d8da5c8e971997f890d9cee42dff2f6cf9f9f43cad9ffb
PACKAGE_STDCELL_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
```

Source preparation is clean: 160 input module definitions reduce to 2
design-owned modules after 158 official JIHD definitions are removed. All 159
referenced masters resolve through 158 CDL definitions and 1 retained design
module. The source and LEF both expose 251 pins, nested top-port count is zero,
and unresolved-master count is zero.

The basic package profile deliberately leaves promotion-only fields such as
`BBOX_PARITY_STATUS`, `INTERNAL_PG_STATUS`, and qualification-level timing at
`UNKNOWN` or `NOT_RUN`. Those are not staging failures. The copied floorplan,
GDS-export, connectivity, DRC, and timing reports remain independently hashed,
while PVS base DRC, density DRC, and LVS remain genuinely `NOT_RUN`.

#### Recorded Position Step 4 PVS DRC Template Discovery

The discovery-only gate ran on 2026-07-17 from exact commit
`ddf80bdceb61f64e7fb2b2891603fa6e38463795`. It rechecked the immutable
package, reproduced GDS SHA-256 `ebba26a4...`, and verified the package SHA
manifest before reading any template controls.

The configured PVS DRC root contained 114 candidate directories, but no path
or inventoried control named Position:

```text
DISCOVERY_RC=0
STATUS=PASS
RESULT=CANDIDATES_RECORDED_FOR_REVIEW
TEMPLATE_CANDIDATE_COUNT=114
POSITION_NAMED_CANDIDATE_COUNT=0
POSITION_TEMPLATE_EVIDENCE_STATUS=NOT_FOUND
ATTRIBUTABLE_POSITION_TEMPLATE_STATUS=NOT_PROVEN
TEMPLATE_SELECTION_AUTHORIZED=NO
CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PACKAGE_MODIFIED=NO
PVS_EXECUTED=NO
```

The command passed because the search and immutable evidence capture were
complete. It did not find a Position template and did not execute DRC. The
non-HV `spadmic_tx_packet_core` controls are the closest same-project digital
scaffold candidate, but they remain cross-block input requiring explicit
control-risk review and strict dry-run proof. Historical packet DRC results
cannot transfer to the Position GDS.

#### Recorded Position Step 5 Cross-Block Seed Review

P09-R06 ran on 2026-07-17 from exact commit
`2c6b0170845bf125d48700ed8594e5d3da121e14`. It reproduced the R05 discovery
hashes, immutable Position GDS SHA-256 `ebba26a4...`, package manifest, and all
pinned non-HV packet-core seed-control hashes before and after review.

```text
REVIEW_RC=0
STATUS=PASS
RESULT=CROSS_BLOCK_SEED_CONTROLS_RECORDED_FOR_REVIEW
PRIMARY_CONTROL_IDENTITY_STATUS=PASS
DENSITY_HOOK_STATUS=PASS
AUTOMATED_CONTROL_RISK_SCAN_STATUS=PASS
EXECUTABLE_RISK_LINE_COUNT=0
PACKAGE_MODIFIED=NO
PINNED_SOURCE_CONTROLS_UNCHANGED=YES
PVS_EXECUTED=NO
```

The original reviewer reported `PRIMARY_EXECUTABLE_CONTRACT_STATUS=FAIL`
only because its `TECH_XH018_HD` check required literal spaces while the
verified `pipo1.setup` field is tab-separated. R06b reran the corrected gate
from exact commit `6baf4a95224edf0a2669ae5d4db43df925f8d73c` and proved:

```text
REVIEW_RC=0
PRIMARY_EXECUTABLE_CONTRACT_STATUS=PASS
PREPROCESSOR_DIRECTIVE_COUNT=5
NON_DENSITY_PREPROCESSOR_DIRECTIVE_COUNT=4
PREPROCESSOR_DIRECTIVE_REVIEW_STATUS=REVIEW_REQUIRED
PACKAGE_MODIFIED=NO
PINNED_SOURCE_CONTROLS_UNCHANGED=YES
PVS_EXECUTED=NO
```

The exact tuple is `DENSITY=UNDEFINED`, `POPPING=UNDEFINED`,
`PIMIDE=UNDEFINED`, `DUMMY_FILL=UNDEFINED`, and
`VAR_ANT_RATIO=DEFINED`. The first is the base/density variant split, and the
last enables an additional antenna family. The dummy-fill selector is
undefined, but its rule-deck impact plus the meanings of `POPPING` and
`PIMIDE` still require exact PDK evidence.

R07 compared all 114 candidates and found only two tuples. All candidates
undefine `DENSITY`, `POPPING`, `PIMIDE`, and `DUMMY_FILL`; 111 undefine
`VAR_ANT_RATIO` and three define it. The exact `pvtech.lib` maps
`XH018_1131` to the relative token `.pvsSetup/PVS`. The rendered `/PVS`
reference is a collector parsing artifact and must not be used as a path.

Cross-block reuse, strict dry-run preflight, replay, and PVS execution remain
unauthorized. The next read-only gate resolves the relative mapping, identifies
the three enabled candidates, and inventories the bounded rule setup for
manual review.

#### Recorded Position Step 6 Rule-Setup Discovery

P09-R08 ran on 2026-07-17 from exact commit
`329950f10f42d8ddc50a4ada8d626a3cdebf04ea`. It reproduced the immutable
preprocessor diagnostic, accepted Position GDS SHA-256 `ebba26a4...`, package
manifest, source `pvtech.lib`, and primary seed-control identity before reading
the bounded setup.

```text
RULE_SETUP_RC=0
STATUS=PASS
PVTECH_MAPPING_RAW=.pvsSetup/PVS
MATRIX_CANDIDATE_COUNT=114
VAR_ANT_DEFINED_CANDIDATE_COUNT=3
RULE_SETUP_COLLECTOR_GATE_RC=0
PACKAGE_MODIFIED=NO
RULE_DECK_COPIED=NO
PVS_EXECUTED=NO
```

The raw mapping resolves to the project `.pvsSetup/PVS` directory, and the
canonical XH018 v10.1 PVS root also exists. The normal PDK configuration
defaults all five reviewed options to zero. Deck context identifies `POPPING`
as an IMD-popping family, `PIMIDE` as a pad-marker branch, `DUMMY_FILL` as a
generation/output selector, and `VAR_ANT_RATIO` as an additional antenna
family. Those facts do not yet prove which optional process branches apply to
the internal Position block.

The prior rule-reference excerpt omitted the names surrounding its four
`DrcRules` entries. A final read-only semantic review must therefore capture
the complete named `techRuleSets` files and balanced conditional blocks before
the `default` selection or cross-block seed policy can be accepted. Strict
preflight, template creation, PVS execution, and promotion remain unauthorized.

#### Recorded Position Step 7 Rule-Semantics Review

P09-R09 ran on 2026-07-17 from exact commit
`8f4154d658c7fd9d6cb8deca98c6f5bf04807705`. It reproduced all R08 hashes,
the accepted GDS and package manifest, and every inspected PDK/project source
before and after collection.

```text
REVIEW_RC=0
STATUS=PASS
DEFAULT_RULE_SET_EVIDENCE_STATUS=PASS
DIRECTIVE_CONDITIONAL_BLOCK_GATE_STATUS=PASS
USER_GUIDE_TEXT_STATUS=PASS_MATCHES_FOUND
PACKAGE_MODIFIED=NO
PVS_EXECUTED=NO
```

The named `default` DRC rule set is exactly `metalswitch.pvl` plus
`xh018_DRC.rul` with `pvs.cfg`, using the XH018 v10.1.1 `MET3 / METMID`
switch. All five normal GUI defaults are zero. The deck contains one density
family with 34 rules, one popping family with six W5M* rules, one PIMIDE
branch, two dummy-fill branches, and 78 variable-ratio antenna blocks, with no
unmatched conditionals.

The guide resolves the OOC policy for density, dummy generation, post-fill
popping checks, and supplemental `VAR_ANT_RATIO` checks. It does not resolve
whether the PIMIDE pad-marker branch applies to the accepted Position layout.
The next read-only gate therefore resolves exact `pad`/`pimide` stream tuples
from the pinned deck and counts only geometry reachable from
`spadmic_position_core` in the exact accepted GDS. Strict preflight, template
creation, PVS execution, and promotion remain unauthorized until that evidence
is returned and manually accepted.

#### Recorded Position Step 8 Applicability and Strict Preflight

P09-R10 ran on 2026-07-20 from exact commit
`a622dd0bf88478ecf124a448296c7390702d2d1f`. It parsed the complete accepted
GDS hierarchy and proved zero reachable PAD `19/0`, PIMIDE `221/5`, and NOPIM
`46/0` geometry or text. The PIMIDE branch is not applicable to Position OOC
DRC, so strict preflight was manually authorized with the accepted base and
density option policy.

The first P09-R11 attempt ran from exact commit
`3d8c0e025cbaa6caa300e7efc2290983bcec90e2`. All repository, R10, package,
GDS, and seed identity gates passed, and the base replay patch contract passed.
The dry-run then stopped before density because scalar replacement of
`spadmic_tx_packet_core` corrupted the longer historical execution path before
that path could be relocated. It reported:

```text
MISSING=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_position_core
MISSING=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_position_core/PIPO1.LOG
BASE_DRY_RUN_RC=1
DENSITY_DRY_RUN_RC=NOT_RUN
PVS_EXECUTED=NO
```

The replay helper now orders replacements by descending source length, with a
regression for this exact top-name/execution-root collision. This failed
attempt is tooling evidence only.

The corrected P09-R11 transaction then ran from exact commit
`130954a9ddd074633cea0e612fd4ea7355a44b84` and produced diagnostic
`position_pvs_drc_strict_preflight_20260720_113452`. Both fresh control sets
passed every input, replay, output-isolation, external-reference, selector,
run-manifest, source-recheck, and package-recheck gate:

```text
BASE_DRY_RUN_RC=0
DENSITY_DRY_RUN_RC=0
RUN_AUDIT_GATE_RC=0
STRICT_DRY_RUN_PREFLIGHT_STATUS=PASS
DIAGNOSTIC_MANIFEST_RC=0
PVS_EXECUTED=NO
```

The base control has DENSITY undefined and the density control has it defined;
all other accepted option states are identical. Strict preflight is complete.
No additional rule-set, PIMIDE, or control-discovery step is allowed unless a
pinned input changes.

#### Recorded Position Step 9 Base And Density PVS DRC

The foreground base run at commit
`31738aa650492516340e54b7535c5d805b897090` produced attributable report-level
`0 (0)` evidence. The subsequent density run at commit
`d327be8596fccc8a60d46d5cd0138b93b6c2f03e` produced an attributable,
fully reconciled `4 (4)` result:

```text
PVS_BASE_DRC_STATUS=PASS
PVS_DENSITY_DRC_STATUS=FAIL
DRC_TOTAL_PRIMARY=4
DRC_TOTAL_EXPANDED=4
RULE_ANALYSIS_STATUS=PASS
ANTENNA_PRIMARY_RESULT_COUNT=0
NON_ANTENNA_PRIMARY_RESULT_COUNT=4
```

The rules are `R1M1`, `R1M2`, `R1M3`, and `R1MT`, one per routed metal layer.
Each compares layer area against the complete `951.440 x 659.680 um` extent and
requires 30 percent coverage. They are whole-window density checks, not four
localized minimum-area defects. The immutable analyzer output is preserved,
including its original generic `AREA` guidance, but the reviewed semantic
classification is `DENSITY`. The analyzer regression now applies that
classification automatically.

Foundry guidance classifies these checks as post-fill/chip-level. Position OOC
therefore carries explicit density debt pending assembled-fill review or a
formal waiver. No virtual dummy fill or local shape repair is authorized.
This blocks Position promotion but did not block the independent exact-GDS
electrical comparison. That comparison has now produced an explicit `MATCH`;
the remaining Position action is a read-only acceptance review of its immutable
evidence while density disposition remains tracked.

#### Recorded Position Step 10 Exact-GDS LVS No-Execution Stop

The first foreground exact-GDS LVS transaction at commit
`285dfc53b6bcf544bb5a42545edb17f3edc6b2c1` passed all density, package, GDS,
canonical source, and CDL gates, then stopped before replay. Four mutable GUI
controls in the historical TX LVS scaffold no longer matched their July 10
hashes. The resulting diagnostic
`position_pvs_lvs_execution_20260720_141229` records:

```text
TEMPLATE_IDENTITY_GATE_RC=1
PVS_WRAPPER_RC=NOT_RUN
PVS_LVS_STATUS=UNKNOWN
PVS_EXECUTED=NO
STATUS=FAIL
RESULT=EXACT_GDS_PVS_LVS_NOT_EXECUTED
```

This is neither an LVS match nor mismatch. Base DRC remains `PASS`; density
remains attributable `FAIL` with four whole-extent rules; the package is
unchanged. The corrected driver pins the exact observed six-file state and
adds a read-only semantic audit of the current launcher and control before
cloning. The clone still forces the package GDS, canonical LVS source, both
Position tops, and package JIHD CDL, and it must pass replay, output-isolation,
external-reference, and run-manifest gates before PVS starts. No additional
rule discovery or density rerun is authorized. Run the corrected foreground
LVS transaction once.

#### Recorded Position Step 11 Optional-SVDB Audit Correction

The next foreground attempt at commit
`0a0220a5c5d3914ffcd408432394e73c9b4a0f55` passed all six current scaffold
hashes and every accepted input/source/package gate. Its semantic audit then
stopped on exactly one condition:

```text
SVDB_DIRECTORY_COUNT=0
ERROR=svdb_directory_count=0
TEMPLATE_SEMANTIC_GATE_RC=1
PVS_WRAPPER_RC=NOT_RUN
PVS_EXECUTED=NO
```

The current GUI control has no explicit `mask_svdb_dir`. That absence does not
change the comparison inputs and is supported by the existing replay output
normalizer. The corrected contract now accepts zero or one input directive,
rejects duplicates, and adds or rewrites exactly one SVDB path under the
unique package-local run. This closes the false audit gate while strengthening
output isolation. Run one foreground retry; do not rerun DRC.

#### Recorded Position Step 12 Auxiliary-CDL Reference Correction

The foreground attempt at commit
`98a616c30246f457f0f105e91868a9213825dc96` passed scaffold identity and
semantics, canonical comparison-input checks, replay, and output isolation.
The replay report proved that the package CDL and run-local SVDB were added.
The final external-reference gate stopped on one path before PVS started:

```text
MISSING=.../blocks/spadmic_position_core/tx_packet_pvs_waiver_20260716_130442/pdk/xh018_D_CELLS_JIHD.cdl
PVS_WRAPPER_RC=1
PVS_EXECUTED=NO
PVS_LVS_STATUS=UNKNOWN
```

This hybrid path is auxiliary copied-control metadata, not the executable CDL
selected for comparison. Replay now maps same-basename auxiliary CDL paths to
the exact package-local CDL before scalar top-name rewrites. It still reports
and rejects every unrelated missing reference. Run one foreground retry on the
unchanged Position package; do not rerun DRC or add another discovery stage.

#### Recorded Position Step 13 Exact-GDS LVS Match And Audit Correction

The foreground retry at commit
`ea786a6b6f367dcf2a7e30ef1f81b38ef84b98e4` passed the corrected auxiliary-CDL
gate and executed PVS on the unchanged Position GDS, canonical source, package
JIHD CDL, and canonical tops. The immutable roots are:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_execution_20260720_155406
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810/pvs/lvs/position_exact_gds_lvs_20260720_155406
```

The PVS process and wrapper returned zero. The raw result report records one
unambiguous report-level verdict with no negative evidence:

```text
PVS_LVS_STATUS=MATCH
LVS_NEGATIVE_MATCH_COUNT=0
LVS_POSITIVE_MATCH_COUNT=3
PVS_RESULT_EVIDENCE=.../position_exact_gds_lvs_20260720_155406/svdb/matched
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
RUN_MANIFEST_RC=0
DIAGNOSTIC_MANIFEST_RC=0
```

The execution driver returned `STATUS=FAIL` only because its post-run audit
still expected `SVDB_REWRITE_COUNT=1`. The accepted scaffold had no incoming
SVDB directive, so replay correctly reported `SVDB_ACTION=ADDED_MISSING` and
`SVDB_REWRITE_COUNT=0` for the exact run-local SVDB path. This is a stale audit
assertion after PVS, not an LVS mismatch. No PVS rerun is authorized.

Future executions now audit the exact SVDB directory, `ADDED_MISSING`, and
rewrite count zero. For this already completed run,
`TOP/ci/server_review_position_core_pvs_lvs_match.sh` performs a read-only,
hash-pinned acceptance review of the source diagnostic, immutable run,
manifests, comparison inputs, positive evidence, and zero negative count. A
passing review records `OUTCOME_CLASS=ATTRIBUTABLE_MATCH` and authorizes Event
OOC start. Position promotion and signoff remain forbidden because density is
still `FAIL` with four whole-extent rules.

## 7. Event Coordinator

The event coordinator now has a complete TC OOC SDC with a `6.25 ns`
`clk_sys`, external input delays/transitions, output delays, and output loads.
Its logical and physical top remains `spadmic_event_coordinator`.

### Recorded Event Genus Result

The read-only Position review passed at diagnostic
`position_pvs_lvs_match_review_20260720_163037`, so Event Genus started in the
same foreground transaction. The exact synthesis run is:

```text
SOURCE_COMMIT=b53b1fade963c6c57c6b0629ae9a4b21fdac06db
EVENT_GENUS_RUN=genus_ooc_event_coordinator_20260720_163038
EVENT_GENUS_RC=0
STATUS=PASS
TC_TIMING_STATUS=PASS
RESULT=READY_FOR_ISOLATED_INNOVUS_OOC
CLOCK_PERIOD_PS=6250.0
CLOCK_REGISTER_COUNT=51
EXPECTED_BASE_PORT_COUNT=30
ACTUAL_BASE_PORT_COUNT=30
EXPECTED_BIT_PORT_COUNT=63
ACTUAL_BIT_PORT_COUNT=63
UNRESOLVED_REFERENCE_COUNT=0
WNS_PS=2143.7
TNS_PS=0.0
VIOLATING_PATH_COUNT=0
POSTSYN_NETLIST_SHA256=b28454211dc5eeda84f17cc5864adcd1c15cd761a9d825e3f5a78182fe0b0ccb
POSTSYN_SDC_SHA256=c32e0a54b392017256a790ec73352d7161093c73a4360fe933083c88f7d1cb6a
MMMC_STATUS=NOT_RUN_TYPICAL_ONLY
SIGNOFF_READY=NO
```

The timing-intent report has zero findings in every class. Warning
classification has zero design-rule, inferred-latch, missing-delay,
no-clock-waveform, tool-error, undriven, and unresolved findings. The two
remaining tool warnings are the accepted `MESG-11` maximum-print-count class.
QoR records 184 leaf instances, 48 sequential instances, cell area
`5112.934`, and total estimated area `7826.138`.

Compact tracked evidence is under:

```text
TOP/docs/server_snapshots/genus/genus_ooc_event_coordinator_20260720_163038/
```

### Recorded Event Innovus Result

The hash-bound Event transaction ran from exact commit
`1b922f0723112e5916107775069c767388ec500e`. Its immutable diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/event_innovus_execution_20260720_173527
```

All repository, source Genus, source hash, revalidation, Innovus, report,
artifact-hash, copy, and diagnostic-manifest gates passed. The accepted
physical tuple is:

```text
STATUS=PASS
OUTCOME_CLASS=ATTRIBUTABLE_ABSTRACT_READY
EVENT_INNOVUS_OOC_STATUS=PASS
ACTUAL_DIE_WIDTH_UM=237.440
ACTUAL_DIE_HEIGHT_UM=219.520
TOP_RESERVATION_WIDTH_MARGIN_UM=0.020
TOP_RESERVATION_HEIGHT_MARGIN_UM=0.480
DRC_MARKER_TOTAL=0
REGULAR_CONNECTIVITY_STATUS=PASS
PG_CONNECTIVITY_STATUS=PASS
POSTROUTE_SETUP_TIMING=PASS
POSTROUTE_HOLD_TIMING=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857
SOURCE_POST_RECHECK_RC=0
```

The exact abstract LEF, DEF, and routed PG netlist hashes are retained in the
diagnostic and compact tracked snapshot:

```text
TOP/docs/server_snapshots/innovus/innovus_ooc_harden_event_coordinator_20260720_173527/
```

### Recorded Event PVS Progress

Immutable staging passed at
`event_handoff_staging_20260721_101249` from exact commit
`0fff3d2afb447f746c69ea946450ff6f5cdd7400`. The resulting candidate package,
canonical LVS source, 65-port LEF/source parity, standard-cell CDL resolution,
package audit, and both manifests are attributable. Compact evidence is under
`TOP/docs/server_snapshots/handoff/event_coordinator_20260720_173527/`.

The strict dry-run passed at
`event_pvs_drc_strict_preflight_20260721_104756` from exact commit
`9223b07d86273d6e66c11c49691a8d1a2219bfd3`. All 86 structures are reachable
from `spadmic_event_coordinator`; PAD 19/0, PIMIDE 221/5, and NOPIM 46/0 each
have zero reachable geometry and text elements. Both isolated controls bind
GDS SHA-256 `837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857`.
The base control contains one `#UNDEFINE DENSITY`, and the density control one
`#DEFINE DENSITY`; every other accepted selector is identical. No PVS process
ran. Compact evidence is under
`TOP/docs/server_snapshots/pvs_drc/event_strict_preflight_20260721_104756/`.

The resulting base transaction ran at
`event_pvs_drc_base_execution_20260721_110404` from exact commit
`e0325d688a73b261742dc70097b1059aba8e035b`. PVS completed all 1290 checks,
finished normally, and three report-level observations agreed on exact total
`0 (0)`. Replay, output isolation, all source and package identities, and the
diagnostic manifest passed. Compact evidence is under
`TOP/docs/server_snapshots/pvs_drc/event_base_drc_20260721_110404/`.

The density transaction then ran at
`event_pvs_drc_density_execution_20260721_112300` from exact commit
`66ea5eb65de37387a023a77fc4239f1dfab6c6cf`. PVS completed all 1300 checks
normally and reported exact total `4 (4)`. All counts and ASCII result geometry
reconciled. The four rules are `R1M1`, `R1M2`, `R1M3`, and `R1MT`, one each on
MET1, MET2, MET3, and METTP. Every marker spans the same complete
`237.360 x 219.520 um` extent and checks 30 percent area coverage. These are
whole-window density rules, not localized minimum-area defects; antenna debt is
zero. Compact evidence is under
`TOP/docs/server_snapshots/pvs_drc/event_density_drc_20260721_112300/`.

### Recorded Event Exact-GDS LVS Result

The exact-GDS transaction ran at `event_pvs_lvs_execution_20260721_121034`
from exact commit `624ae1e2967eb66a63e3b33139c66f483e14886f`. It bound the
unchanged package GDS, canonical package-local LVS source, standard-cell CDL,
reviewed control scaffold, and external references. Replay, output isolation,
the directive-aware run-control audit, run/source/package manifests, and the
23-file diagnostic manifest all passed.

PVS returned tool RC zero and explicit `MATCH` evidence with zero negative and
three positive observations. The top comparison was
`2660 insts vs 2660 insts`, and ERC results were empty. Compact evidence is
under
`TOP/docs/server_snapshots/pvs_lvs/event_lvs_match_20260721_121034/`.

This accepts only the Event exact-GDS LVS gate. Base DRC remains `PASS`, and
density DRC remains `FAIL` with four classified whole-extent rules. Do not
rerun Event DRC or LVS. `p02_event_control` still waits for density disposition
and promoted `p01_position`, which itself waits for promoted `p00_tx`.

## 8. Immutable Package and PVS

Stage only the reviewed canonical replay, never an exploratory candidate.
Package the mapped/merged GDS, abstract LEF, DEF, PG netlist, Genus TC gate,
Innovus reports, and Innovus log with `stage_innovus_handoff.py`.

The exact Position staging transaction is checked in as
`TOP/ci/server_stage_position_core_handoff.sh`. It requires an explicit
repository HEAD argument, refuses an existing package version, rechecks the
source-run commit and accepted artifact hashes, runs package-local LVS source
preparation and pin parity, audits the immutable package, and stops before
PVS. The recorded execution passed every staging gate on package version
`innovus_ooc_harden_position_core_gridfit_20260717_114810`.

The equivalent Event transaction is
`TOP/ci/server_stage_event_coordinator_handoff.sh`. It is pinned to the
accepted `event_innovus_execution_20260720_173527` diagnostic and package
version `innovus_ooc_harden_event_coordinator_20260720_173527`. Staging passed
at `event_handoff_staging_20260721_101249`; strict preflight then passed at
`event_pvs_drc_strict_preflight_20260721_104756`; base DRC then passed with
exact report-level `0 (0)` at `event_pvs_drc_base_execution_20260721_110404`.
Density DRC then completed with four attributable whole-extent coverage rules
at `event_pvs_drc_density_execution_20260721_112300`, and exact-GDS LVS
returned an attributable `MATCH` at `event_pvs_lvs_execution_20260721_121034`.

For each hard child:

1. Audit the staged package.
2. Run base PVS DRC with `--variant base`.
3. Run density PVS DRC with `--variant density`.
4. Run PVS LVS and require report-level `MATCH`.
5. Confirm every PVS status includes the exact package path and GDS SHA-256;
   LVS must also bind the canonical package source and its SHA-256.
6. Build the promotion gate.
7. Promote only when the gate itself is immutable and PASS.

The gate command is:

```bash
python3 TOP/pnr/scripts/build_innovus_handoff_gate.py \
    --package "$PACKAGE" \
    --base-drc-status "$BASE_DRC_STATUS" \
    --density-drc-status "$DENSITY_DRC_STATUS" \
    --lvs-status "$LVS_STATUS" \
    --pg-status "$PG_STATUS" \
    --contract-status "$CONTRACT_STATUS" \
    --layer-status "$LAYER_STATUS" \
    --timing-status "$TC_TIMING_STATUS" \
    --run-id "gate_$(date -u +%Y%m%dT%H%M%SZ)"
GATE_RC=$?

GATE_STATUS="$(find "$PACKAGE/status" -maxdepth 1 -name 'gate_*.rpt' \
    -type f | sort | tail -1)"
cat "$GATE_STATUS" 2>/dev/null

if [ "$GATE_RC" -eq 0 ]; then
    python3 TOP/pnr/scripts/promote_innovus_handoff.py \
        "$PACKAGE" \
        --gate-status "$GATE_STATUS"
    PROMOTE_RC=$?
    echo "PROMOTE_RC=$PROMOTE_RC"
else
    echo "STOP_HERE_DO_NOT_PROMOTE: promotion gate failed"
fi
```

PVS process return code zero is not enough. DRC must parse to PASS, and LVS
must contain positive match evidence without negative match evidence.

## 9. Formal DRC Waiver Policy

The preferred result is clean base and density DRC. A formal waiver is an
exception and must use:

```text
TOP/pnr/templates/formal_drc_waiver.template.json
TOP/pnr/scripts/validate_formal_drc_waiver.py
```

The manifest must name the canonical block, exact GDS SHA-256, approver,
approval reference, exact rules/counts/disposition, review-reopen condition,
and whether base and/or density are covered. The canonical JSON payload hash
detects modification after review. It does not prove the cryptographic
identity of the approver; project review records remain the identity
authority.

The four-marker TX diagnostic waiver is not a formal PVS waiver and cannot be
used for promotion.

## 10. Assembly Phase Gates

| Phase | Entry gate | Added content | Exit gate |
| --- | --- | --- | --- |
| `p00_tx` | accepted source audit plus reviewed `VDD/VSS -> DVDD/DVSS` bridge contract | fresh soft packet + strip RTL | TC timing, Innovus physical gates, base DRC zero, exact-GDS LVS `MATCH` |
| `p01_position` | promoted `p00_tx` exact package | fresh cumulative p00 + Position RTL | TC timing, Innovus physical gates, base DRC zero, exact-GDS LVS `MATCH` |
| `p02_event_control` | promoted `p01_position` exact package | fresh cumulative p01 + Event/control RTL | TC timing, Innovus physical gates, base DRC zero, exact-GDS LVS `MATCH` |
| `p03_matrix_interface` | promoted `p02_event_control` plus accepted matrix proxy contract | fresh cumulative p02 + matrix-interface RTL | TC timing, Innovus physical gates, base+density DRC pass, exact-GDS LVS `MATCH` |
| `p04_mptdc_frontend` | final MPTDC abstracts and pin contract | MPTDC frontend/corridor | currently blocked |
| `p05_csr_i2c` | promoted `p04` plus pad contract | CSR/I2C | deferred |

Never mutate an approved checkpoint in place. Each phase creates a new layout
top, immutable package, base DRC run, density DRC run, LVS run, and approval
gate.

### Current Cross-Block Disposition

Independent OOC qualification may move ahead of assembly insertion. The
current state must therefore be read as this gate matrix, not as one global
ready flag:

| Scope | Current attributable state | Remaining gate | Assembly effect |
| --- | --- | --- | --- |
| SPADMIC2/matrice5 OA | sealed source/export evidence passes; source identity, exact M182, 560 matrix proxies, and p03 interface pass | exact reviewed `DVDD/DVSS` physical access and candidate bridge contract | sole blocker before cumulative `p00_tx` preflight |
| TX packet core OOC | exact-GDS LVS `MATCH`; provisional physical baseline | 4 Innovus MET1 minimum-area markers, 135 PVS antenna results, density not run | supporting diagnostic only; not reused as a p00 hard macro |
| TX DDR strip OOC | signal route DRC/connectivity clean | internal PG reconstruction, mapped GDS, base+density DRC, LVS | supporting diagnostic only; p00 rebuilds this logic from RTL |
| TX implementation children | `event_bundle_tx`, `output_fifo`, `ddr16_pairer`, and `ddrs2_adapter` abstracts are ready for top review | parent/package-level PG and PVS remain | supporting leaf evidence only; do not place as duplicate top macros |
| Position core OOC | base DRC `PASS`; density `FAIL` with four whole-extent rules; exact-GDS LVS accepted `MATCH` | assembled-fill disposition or exact formal density waiver | diagnostic guidance only; p01 rebuilds Position cumulatively from RTL |
| Event coordinator OOC | TC Genus boundary `PASS`; grid-fit Innovus clean; base DRC `PASS`; density has four whole-extent rules; exact-GDS LVS accepted `MATCH` | assembled-fill disposition or exact formal density waiver | diagnostic guidance only; p02 rebuilds Event cumulatively from RTL |
| Central control | stable RTL in a soft guide | assembled timing, congestion, connectivity, and verification | inserted only with `p02_event_control` |
| Matrix interface | exact family parity and all 560 proxy shapes pass | guided placement, pin access, congestion, timing, DRC/LVS | signal contract ready; phase still waits for promoted `p02` |
| MPTDC/TC frontend | route corridor and three axis blockages reserved | final MPTDC abstracts and exact pin contract are missing | hard stop at `p04_mptdc_frontend`; no invented dimensions or pins |
| CSR/I2C | RTL present; physical wrapper deferred | promoted `p04`, pad contract, physical wrapper, assembled verification | deferred `p05_csr_i2c` |

The required promotion order remains `p00_tx`, `p01_position`,
`p02_event_control`, `p03_matrix_interface`, `p04_mptdc_frontend`, then
`p05_csr_i2c`. Event OOC progress does not bypass TX or Position phase gates.

## 11. Negative Knowledge

Do not repeat these failed or misleading methods:

- Do not equate a tool return code or successful construction command with
  physical closure.
- Do not transfer DRC or LVS status to a different GDS hash.
- Do not call repeated `restoreDesign` operations in one Innovus process.
  `IMPIMEX-7031` identifies unreliable retained application/global state.
- Do not evaluate multiple repair candidates in one process. Use one process,
  one restore, and one method per candidate.
- Do not request `blockPin` when the objects are top-level VDD/VSS terminals.
  The strip run produced `IMPSR-1254`.
- Do not calculate `addStripe -start_offset` from zero when the command is
  core-relative.
- Do not combine `addStripe -area` with
  `-extend_to design_boundary`.
- Do not import the TX helper-X coordinate sweep into another block. Every
  candidate produced the same rejected physical tuple.
- Do not insert default direct power-via stacks after signal routing. They
  closed connectivity while creating MET2/MET3 shorts.
- Do not rely on raw `top.markers` totals without separating DRC, antenna, and
  connectivity marker classes.
- Do not run PG after signal routing by default. New hard macros create exact
  PG first so signal routing sees it as an obstruction.
- Do not harden multidimensional or unstable RTL boundaries without an exact
  physical wrapper and pin-parity audit.
- Do not accept a nonempty parsed port list as boundary proof. An ANSI parser
  must reset an inherited packed range when a new `input`, `output`, or
  `inout` starts. The previous behavior falsely expanded event-coordinator
  scalar ports and reported 118 instead of 63 scalar bits.
- Do not invent MPTDC pins or dimensions while its final abstract is missing.
- Do not call a provisional diagnostic waiver a signoff waiver.
- Do not use a formal waiver to replace an unexecuted or unparsed DRC run.
  Only an exact-GDS DRC result explicitly classified `FAIL` can become
  `FORMALLY_WAIVED`; `NOT_RUN`, `UNKNOWN`, and missing evidence remain hard
  failures.
- Do not describe an explicit PVS `MATCH` as a percentage.
- Do not launch full-top Genus or Innovus from this subblock flow.

## 12. Local Validation

The implementation is locally checked with:

```bash
python3 TOP/pnr/scripts/validate_digital_subblock_portfolio.py
python3 -m unittest discover -s TOP/pnr/tests -p 'test_*.py'
bash TOP/scripts/sim/run_tb.sh \
    tb_spadmic_position_snapshot_packetizer_unit --sim verilator
bash TOP/scripts/sim/run_tb.sh \
    tb_spadmic_event_coordinator_modes_unit --sim verilator
```

The RTL regressions pass `25/25` position checks and `24/24` event checks.
Position TC Genus and the corrected grid-safe Position Innovus replay pass on
their recorded exact commits. Position immutable handoff staging, canonical
source preparation, pin parity, rule semantics, option applicability, and
strict preflight pass. Base PVS DRC has attributable report-level `0 (0)`
evidence. Density PVS DRC has attributable `4 (4)` whole-extent coverage debt,
not localized geometry debt. Exact-GDS LVS has explicit `MATCH` evidence. The
directive-aware read-only review accepted that immutable match without rerunning
PVS. Event TC Genus now passes with exact boundary parity, nonnegative WNS,
zero TNS, zero violating paths, and pinned post-synthesis artifact hashes.
Event Innovus now has an attributable grid-fit pass with zero DRC, clean
regular and PG connectivity, typical setup/hold pass, and mapped/merged GDS.
The immutable Event package is staged and audited with canonical source
preparation and pin parity. Event base PVS DRC is an attributable `0 (0)`
`PASS`; density DRC is an attributable `4 (4)` physical `FAIL`, and exact-GDS
LVS is an attributable accepted `MATCH`. No Event PVS rerun is authorized.

## 13. Immediate Next Action

The current action supersedes the older OOC chronology retained below. The
corrected foreground master-terminal probe passed at exact commit
`94416d98f091c629171261245e7b7d03bd1c9584` and created sealed root:

```text
/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_digital_pg_access_probe_20260724_132453_pid735750
RECOVERY_ARCHIVE_SHA256=9c16001006fed909c8704e9bdeb68dfc3dfa5a487f3d5d6730878213537ba261
READ_ONLY_DIGITAL_PG_ACCESS_PROBE_STATUS=PASS_EVIDENCE_READY
SOURCE_STABILITY_RC=0
OUTER_MANIFEST_POST_SEAL_RC=0
WRITABLE_EVIDENCE_PATH=NONE
```

It proved exact local-to-chip naming and four current, transform-eligible
METTP review candidates:

```text
I5/BOX_RING2       DVDD 1391.500 49.245 1444.500 115.260
I5/BOX_RING2       DVSS 1203.500 49.245 1256.500 115.260
I6/TXRX4TDC2_HV    DVDD 3515.960 2241.710 3550.960 2243.845
I6/TXRX4TDC2_HV    DVSS 3555.960 2241.985 3590.960 2243.845
```

All four have `NO_INSTTERM_CONNECTIVITY`; they prove physical pin figures, not
top-net ownership. Direct top-level exact METTP access remains absent. Mosaic
rows remain master-local and cannot enter bridge selection.

The probe's original `I5` recommendation is rejected. The source cellview bbox
is `-451.632 -287.715 4115.791 3453.077`, while exact
`I5/BOX_RING2/layout R0` is the hollow pad boundary
`-0.240 -287.715 4115.791 3453.077`. Treating `I5` as a solid obstacle left
only the external strip west of the ring as "verified whitespace" and biased
the ranking toward `I5`.

The first processor-only replay at exact commit
`0a0d5d6225e459701147f0ab7c272a77c809280a` passed every input-integrity gate
and completed the classifier with `PROCESS_RC=0`, but the wrapper rejected its
own stale `ASSEMBLY_FIXED_OBSTACLE_COUNT=10` assertion. That value came from
the July 9 key-instance fixture, which has 11 total rows. The sealed July 24 OA
export has 14 total rows. The failed replay root
`spadmic2_digital_pg_floorplan_replay_20260724_141037_pid775347` remained
writable and is not accepted evidence.

The corrected processor-only replay passed at exact commit
`a2f5f90c058743517f5d566e9b50320b645b0837` and sealed:

```text
/sim/ksabra/SPADMIC_work/diagnostics/spadmic2_digital_pg_floorplan_replay_20260724_141934_pid779817
PROCESS_RC=0
STATUS_GATE_RC=0
REPLAY_SEAL_RC=0
REPLAY_WRITABLE_PATH=NONE
PROCESSOR_ONLY_DIGITAL_PG_FLOORPLAN_REPLAY_STATUS=PASS_EVIDENCE_READY
```

Its accepted classification is:

```text
ASSEMBLY_BOUNDARY_INSTANCE=I5
ASSEMBLY_BOUNDARY_POLICY=HOLLOW_PAD_RING_REFERENCE
ASSEMBLY_NORMALIZED_DIE_BBOX_UM=0.000000 0.000000 4116.031000 3740.792000
SOURCE_TO_ASSEMBLY_TRANSLATION_UM=0.240000 287.715000
ASSEMBLY_TO_SOURCE_TRANSLATION_UM=-0.240000 -287.715000
ASSEMBLY_CORE_KEEPOUT_UM=164.000000
SOURCE_INSTANCES_SHA256=9dc5e18abadd3b3d38fb43347ff11486ec8c1b13f194bf070dd6ac5957709360
ASSEMBLY_FIXED_OBSTACLE_COUNT=13
ASSEMBLY_CORE_OVERLAP_OBSTACLE_COUNT=13
ASSEMBLY_VERIFIED_INTERIOR_WHITESPACE_RECT_COUNT=62
ASSEMBLY_PRIMARY_WHITESPACE_NORMALIZED_BBOX_UM=3662.775000 164.000000 3952.031000 3576.792000
ASSEMBLY_PRIMARY_WHITESPACE_AREA_UM2=987170.562752
COMPLETE_SAME_INSTANCE_PG_PAIR_STATUS=PASS
REVIEW_CANDIDATE_PAIR_INSTANCE=I6
TARGET_INSTANCE_METTP_CONTEXT_STATUS=NOT_PROBED
BRIDGE_GEOMETRY_STATUS=NOT_AUTHORIZED
NEXT_GATE=RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE
```

Do not draw a bridge. The accepted I6 `DVDD` and
`DVSS` pin figures are adjacent on METTP and a direct horizontal DVDD
extension intersects the DVSS access region. Run exactly one foreground
`server_probe_spadmic2_selected_pg_corridor.sh` transaction. It binds the
accepted pair and `x=3662.535` primary-whitespace entry, queries all hierarchy
through depth 32 in source window
`3415.960 2141.710 3762.535 2343.845`, and keeps every result review-only.

The expected gate is evidence readiness, not route readiness:

```text
TARGET_INSTANCE=I6
TARGET_PIN_PAIR_STATUS=PASS
TARGET_PIN_HIERARCHICAL_COVERAGE_STATUS=PASS
DVDD_DIRECT_EAST_TO_WHITESPACE_STATUS=REJECT_TARGET_DVSS_INTERSECTION
CORRIDOR_SEARCH_REGION_STATUS=PASS_EVIDENCE_READY
BRIDGE_GEOMETRY_STATUS=NOT_AUTHORIZED
NEXT_GATE=RETURN_I6_CORRIDOR_EVIDENCE_FOR_BRIDGE_CANDIDATE_DEFINITION
```

Only review of the actual north, south, DVSS-direct, and whitespace-entry
occupancy may define bounded bridge candidates. After one bridge contract is
accepted, repair the phase generator to consume normalized obstacles and PG
geometry, repair the OA insertion translation, run phase preflight, then
start one Genus transaction. Innovus remains after Genus and must test one
bridge topology per fresh process with DRC, regular connectivity, special PG
connectivity, timing, and export reported separately.

P09-R10 parsed the complete accepted Position GDS hierarchy and proved zero
reachable geometry and text for PAD `19/0`, PIMIDE `221/5`, and NOPIM `46/0`.
The PIMIDE branch is therefore not applicable to Position OOC DRC. The default
rule-set selection and full option policy are accepted: base DRC keeps DENSITY,
POPPING, PIMIDE, and DUMMY_FILL undefined while retaining VAR_ANT_RATIO; the
density variant changes only DENSITY to defined.

The foreground base transaction passed on immutable diagnostic
`position_pvs_drc_base_execution_20260720_115921` with exact total `0 (0)`.
The foreground density transaction passed its attribution/classification
contract on diagnostic `position_pvs_drc_density_execution_20260720_133314`,
while its physical result remains `FAIL` with exactly four whole-extent 30
percent coverage rules: `R1M1`, `R1M2`, `R1M3`, and `R1MT`.

Do not rerun PVS. The exact-GDS transaction
`position_exact_gds_lvs_20260720_155406` already executed and produced
`PVS_LVS_STATUS=MATCH`, zero negative patterns, three positive patterns, and a
nonempty run-local `svdb/matched` file. Replay, output isolation, all exact
input hashes, run and diagnostic manifests, and post-execution package/source
checks passed. The original transaction failed only its stale
`SVDB_REWRITE_COUNT=1` assertion after execution.

The corrected read-only review passed at
`position_pvs_lvs_match_review_20260720_163037`. Its directive-aware audit
proved one exact executable GDS, Verilog source, CDL, and run-local SVDB path;
the review returned `OUTCOME_CLASS=ATTRIBUTABLE_MATCH` and did not rerun PVS.

Event TC Genus passed at `genus_ooc_event_coordinator_20260720_163038`, and
the exact downstream Innovus transaction passed at
`innovus_ooc_harden_event_coordinator_20260720_173527`. Immutable handoff
staging then passed at `event_handoff_staging_20260721_101249`, followed by the
strict dry-run pass at `event_pvs_drc_strict_preflight_20260721_104756`.
Event base DRC then passed at `event_pvs_drc_base_execution_20260721_110404`
with exact total `0 (0)`. Event density DRC completed at
`event_pvs_drc_density_execution_20260721_112300` with four attributable,
reconciled whole-extent 30 percent coverage rules: `R1M1`, `R1M2`, `R1M3`, and
`R1MT`. Event exact-GDS LVS then completed at
`event_pvs_lvs_execution_20260721_121034` from exact commit
`624ae1e2967eb66a63e3b33139c66f483e14886f`. It returned explicit
`PVS_LVS_STATUS=MATCH`, zero negative observations, three positive
observations, and a passing directive-aware run-control audit. Do not rerun
Event Innovus, staging, preflight, base DRC, density DRC, or LVS.

The remaining Event sequence is:

1. Retain the accepted exact-GDS LVS result without rerunning it.
2. Resolve the four density rules through assembled-fill disposition or an
   exact formal waiver.
3. Promote Event only when all required Event gates pass or an exact formal
   disposition exists.

In parallel, retain the Position density debt for assembled-fill review or a
formal exact-rule waiver; do not rerun its accepted LVS. The assembly-critical
workstream still starts with TX packet DRC repair and TX strip PG/PVS closure,
because `p00_tx` must promote before Position or Event can be inserted into an
assembly checkpoint. Full-top Genus and Innovus remain unauthorized.
