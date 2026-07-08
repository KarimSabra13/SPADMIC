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
|   `-- <block>.abstract.lef
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
| `ABSTRACT_READY_FOR_TOP_REVIEW` | DEF/LEF/GDS/pin reports are present for top layout review. |
| `SIGNOFF_READY` | Reserved for explicit DRC/LVS/PEX/MMMC signoff evidence; do not use for current prototype flows. |

## First Blocks To Package

1. `matrix_reset_ctrl`;
2. `matrix_cfg_ctrl`;
3. `position_snapshot`;
4. `event_coordinator`;
5. `event_bundle_tx`;
6. `output_fifo`;
7. `ddr16_pairer`;
8. `ddrs2_adapter`;
9. `matrix_top_csr`.

## Top Reuse Rules

- A block abstract is a placement aid, not permission to route inside analog
  macros.
- Matrix, DDRs2, TXRX4TDC, PLL, pad ring, PTAT, and MPTDC protected internals
  remain external macro boundaries.
- If a block has too many matrix-facing pins on the wrong side, keep it soft or
  split only the boundary logic after a real congestion/timing reason appears.
