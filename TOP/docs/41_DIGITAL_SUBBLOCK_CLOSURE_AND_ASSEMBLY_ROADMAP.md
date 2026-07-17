# Digital Subblock Closure and Assembly Roadmap

Status: phased server execution active; Position TC Genus accepted.

Date: 2026-07-17.

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
| 1 | Position core | Hard macro | `spadmic_position_core` | TC Genus PASS; run isolated Innovus |
| 2 | Event coordinator | Hard macro | `spadmic_event_coordinator` | Run after position OOC evidence |
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
position core = 931.695 um x 640.000 um
event core    = 217.460 um x 200.000 um
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
Position TC Genus now passes on the recorded exact commit. Position Innovus
and PVS, plus every Event Genus/Innovus/PVS gate, remain server work and must
stay labeled `NOT_RUN` until separately executed and reviewed.

## 13. Immediate Next Action

Position Step 1 is accepted. The next server action is Position Step 2 only:
pull the documented release commit, bind Innovus to
`genus_ooc_position_core_20260717_101642`, run one isolated OOC implementation,
and return the DRC, regular-connectivity, special-PG-connectivity, timing, and
mapped/merged-GDS reports. Do not stage an immutable package or start Event
Genus until the Position Innovus tuple has been reviewed.
