# Subblock Abstract Handoff Plan

Status: expected package shape for digital OOC blocks. This is not a completed
abstract handoff yet.

## Purpose

Each hardenable block should produce enough collateral for the analog/top layout
team to place it as a digital lego in Virtuoso/OA or a top-level Innovus
assembly. The package must stay clear about what was actually run.

## Per-Block Package

Expected directory shape under the work root:

```text
/sim/ksabra/SPADMIC_work/handoff/abstracts/<block>/
|-- README.md
|-- manifest.txt
|-- netlist/
|   |-- <block>.postsyn.v
|   `-- <block>.postsyn.sdc
|-- innovus/
|   |-- <block>.def
|   |-- <block>.lef
|   |-- <block>.gds
|   |-- <block>.abstract.lef
|   |-- <block>.routed.v
|   `-- <block>.routed.pg.v
`-- reports/
    |-- area.rpt
    |-- timing.rpt
    |-- warnings.rpt
    |-- pins.rpt
    |-- congestion.rpt
    |-- drc_oriented.rpt
    `-- power_pins.rpt
```

If Innovus has not run place/route yet, the package must say
`COLLATERAL_ONLY` or `READY_FOR_IMPORT_TEMPLATE`, not `PLACED_ROUTE_DONE`.

## Required Manifest Fields

- repo branch and commit;
- block key and top module;
- source RTL list;
- Genus run ID and root;
- Innovus run ID and root;
- library/stack settings;
- clock constraints used;
- reset polarity;
- known black boxes;
- signoff status label;
- list of missing or deferred items.

## Status Labels

| Label | Meaning |
| --- | --- |
| `GENUS_OOC_PASS` | Genus produced mapped netlist/SDC and required reports. |
| `READY_FOR_IMPORT_TEMPLATE` | Genus collateral exists; Innovus template still pending. |
| `INNOVUS_IMPORTED` | Innovus imported design and libraries. |
| `PLACED_PRECTS` | Placement ran; CTS/route not complete. |
| `ROUTED_FEASIBILITY` | Route ran for feasibility only; not signoff. |
| `INNOVUS_TC_OOC_REVIEW_REQUIRED` | Typical-only Innovus OOC ran but at least one report/export/status needs review before top use. |
| `ABSTRACT_READY_FOR_TOP_REVIEW` | DEF/LEF/GDS/pin reports are present for top layout review. |
| `SIGNOFF_READY` | Reserved for explicit DRC/LVS/PEX/MMMC signoff evidence; do not use for current prototype flows. |

## Current Hardening Wrapper

The first real hardening wrapper is:

```bash
TOP/pnr/scripts/run_innovus_ooc_harden_block.sh <block> <GENUS_RUN_ID> [RUN_ID]
```

It writes the package under:

```text
/sim/ksabra/SPADMIC_work/handoff/abstracts/<block>/<RUN_ID>/
```

The wrapper supports `event_bundle_tx`, `output_fifo`, `ddr16_pairer`,
`ddrs2_adapter`, `tx_egress_core`, and `tx_egress_assembly`. It uses a local
abstract plan generated from
`TOP/docs/layout_audits/SPADMIC2_20260709_072331`, with signal routing on
`MET1`-`MET3` and one north `VDD` plus one north `VSS` access bar on `METTP`.
Local special PG routing is disabled by default; the exported `METTP`
`VDD`/`VSS` access pins must be connected by the top-level assembly flow.
Set `SPADMIC_OOC_ENABLE_PG_SROUTE=1` only for an experimental local PG
special-route run.
It is typical-only Innovus OOC implementation; PVS, PEX, MMMC, foundry LVS, and
direct OA import are separate future gates.

## First Blocks To Package

1. `ddrs2_adapter` as a wide, shallow bridge with DDRs2-aligned north pins;
2. `ddr16_pairer`;
3. `output_fifo`;
4. `event_bundle_tx`;
5. `tx_egress_assembly` after the four TX leaves are DRC-clean;
6. `event_coordinator`;
7. `position_snapshot`;
8. `matrix_reset_ctrl`;
9. `matrix_cfg_ctrl`;
10. `matrix_top_csr`.

Current TX leaf evidence is recorded in
`TOP/docs/29_TX_EGRESS_LEAF_ABSTRACT_STATUS.md`. The four TX leaf abstracts are
ready for top-layout review, but `SIGNOFF_READY` remains `NO` and the current
`tx_egress_assembly` alias is still a monolithic RTL-shaped regression path,
not a true fixed-leaf macro assembly.

Use the fixed-leaf assembly planning wrapper after collecting the four-leaf
manifest:

```bash
bash TOP/pnr/scripts/run_tx_egress_leaf_assembly_plan.sh \
  /sim/ksabra/SPADMIC_work/assembly/tx_egress_leaf_assembly_inputs_20260709_1515/tx_leaf_manifest.csv \
  tx_egress_leaf_assembly_plan_$(date +%Y%m%d_%H%M)
```

The wrapper writes source/placement CSVs and an Innovus Tcl placement include
under `/sim/ksabra/SPADMIC_work/assembly/<RUN_ID>/`. It is the input to a real
top/assembly importer; it does not perform top route, PG hookup, PVS, LVS, PEX,
or MMMC.

## Top Reuse Rules

- A block abstract is a placement aid, not permission to route inside analog
  macros.
- Matrix, DDRs2, TXRX4TDC, PLL, pad ring, PTAT, and MPTDC protected internals
  remain external macro boundaries.
- If a block has too many matrix-facing pins on the wrong side, keep it soft or
  split only the boundary logic after a real congestion/timing reason appears.
