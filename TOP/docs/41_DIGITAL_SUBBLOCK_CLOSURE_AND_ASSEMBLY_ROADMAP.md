# Digital Subblock Closure and Assembly Roadmap

Status: phased server execution active; Position base PVS DRC is attributable
zero, density PVS DRC is attributable four-rule whole-extent debt, and one
foreground exact-GDS PVS LVS transaction is authorized next.

Date: 2026-07-20.

This document is the execution authority for converting the remaining
matrix-top digital logic into reusable hard macros or controlled soft regions.
It preserves the TX closure lessons, the audited full-chip floorplan, and the
evidence required before one block can be inserted into the next assembly
phase.

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

The packet debt does not prevent independent OOC work on the next digital
blocks. It does prevent promotion of the `p00_tx` assembly and therefore
prevents inserting a new child into an allegedly approved parent checkpoint.

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
TOP/pnr/assembly/spadmic_digital_subblock_portfolio.csv
TOP/pnr/assembly/spadmic_digital_floorplan_regions.csv
TOP/pnr/assembly/spadmic_digital_assembly_phases.csv
TOP/docs/34_INNOVUS_22_33_PG_ROUTING_COMMAND_NOTES.md
TOP/docs/38_TX_PACKET_CORE_PROVISIONAL_DRC_WAIVER_AND_PVS_LVS_EXECUTION.md
TOP/docs/39_TX_PACKET_CORE_PVS_BASE_DRC_NON_ANTENNA_ANALYSIS.md
TOP/docs/40_TX_PACKET_CORE_VIRTUOSO_IMPORT_HANDOFF.md
```

Run the floorplan gate before generating any new hard macro:

```bash
python3 TOP/pnr/scripts/validate_digital_subblock_portfolio.py
```

Acceptance is exactly:

```text
STATUS=PASS
ERROR_COUNT=0
```

Do not move a reservation by inspection alone. Update the CSV contract, rerun
the audit-backed validator, review clearances, and commit the new contract
before launching Cadence.

## 3. Portfolio and Order

| Priority | Block | Implementation | Physical top | Current action |
| --- | --- | --- | --- | --- |
| 0 | TX packet core | Hard macro | `spadmic_tx_packet_core` | Manual MET1 and antenna closure |
| 0 | TX DDR strip | Hard macro | `spadmic_tx_ddr_strip` | Internal PG and PVS closure |
| 1 | Position core | Hard macro | `spadmic_position_core` | Foreground exact-GDS PVS LVS; retain density disposition debt |
| 2 | Event coordinator | Hard macro | `spadmic_event_coordinator` | Start immediately after attributable Position LVS |
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
This blocks Position promotion but does not block the independent exact-GDS
electrical comparison. Run
`TOP/ci/server_run_position_core_pvs_lvs.sh` next. If it records an explicit
`MATCH`, start Event OOC immediately while density disposition remains tracked.

## 7. Event Coordinator

The event coordinator now has a complete TC OOC SDC with a `6.25 ns`
`clk_sys`, external input delays/transitions, output delays, and output loads.
Its logical and physical top remains `spadmic_event_coordinator`.

After position OOC review, repeat the same two-step process:

```bash
set +e
source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work

EVENT_GENUS_RUN="genus_ooc_event_coordinator_$(date +%Y%m%d_%H%M%S)"
bash TOP/syn/scripts/run_genus_ooc_block.sh \
    event_coordinator \
    "$EVENT_GENUS_RUN"
EVENT_GENUS_RC=$?

EVENT_GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$EVENT_GENUS_RUN/event_coordinator"
echo "EVENT_GENUS_RC=$EVENT_GENUS_RC"
cat "$EVENT_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt" 2>/dev/null
```

Only after that gate passes:

```bash
set +e
source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work

EVENT_PNR_RUN="innovus_ooc_harden_event_coordinator_$(date +%Y%m%d_%H%M%S)"
bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh \
    event_coordinator \
    "$EVENT_GENUS_RUN" \
    "$EVENT_PNR_RUN"
EVENT_PNR_RC=$?

EVENT_PNR_ROOT="$SPADMIC_WORK_ROOT/innovus/$EVENT_PNR_RUN/blocks/event_coordinator"
echo "EVENT_PNR_RC=$EVENT_PNR_RC"

for REPORT in \
    ooc_harden_status.rpt \
    verify_connectivity_regular.rpt \
    verify_connectivity_pg.rpt \
    verify_drc_post_route.rpt \
    gds_export_audit.rpt
do
    echo
    echo "===== $REPORT ====="
    cat "$EVENT_PNR_ROOT/reports/$REPORT" 2>/dev/null || \
        echo "MISSING: $EVENT_PNR_ROOT/reports/$REPORT"
done
```

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
| `p00_tx` | exact TX child packages | packet + strip | promoted TX phase package |
| `p01_position` | promoted `p00_tx` | hard position core | promoted position phase |
| `p02_event_control` | promoted `p01_position` | hard event + soft central control | promoted event phase |
| `p03_matrix_interface` | promoted `p02_event_control` | matrix-interface soft guide | promoted matrix phase |
| `p04_mptdc_frontend` | final MPTDC abstracts and pin contract | MPTDC frontend/corridor | currently blocked |
| `p05_csr_i2c` | promoted `p04` plus pad contract | CSR/I2C | deferred |

Never mutate an approved checkpoint in place. Each phase creates a new layout
top, immutable package, base DRC run, density DRC run, LVS run, and approval
gate.

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
not localized geometry debt. Exact-GDS LVS remains open. Every Event
Genus/Innovus/PVS gate also remains server work and must stay labeled `NOT_RUN`
until separately executed and reviewed.

## 13. Immediate Next Action

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

Run one foreground exact-GDS LVS transaction now through
`TOP/ci/server_run_position_core_pvs_lvs.sh`. It binds the same GDS SHA-256,
canonical package source, package-local JIHD CDL, canonical layout/source top,
and a hash-pinned XH018 launcher used only as a control scaffold. It accepts
only an explicit attributable `MATCH` or explicit attributable `MISMATCH`;
tool return code zero alone is insufficient. Do not rerun density and do not
insert another template-discovery stage.

On `MATCH`, start Event coordinator OOC immediately and review Position density
disposition in parallel. On `MISMATCH`, classify the one immutable mismatch
without rerunning PVS. Position promotion remains forbidden because density is
still `FAIL` even if LVS matches.
