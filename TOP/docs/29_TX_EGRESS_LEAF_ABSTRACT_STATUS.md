# TX Egress Leaf Abstract Status

Status: four TX egress digital leaves are ready for top-layout review as
typical-only OOC abstracts. This is not final timing closure, not MMMC, not PVS,
not PEX, and not foundry LVS.

## Evidence Snapshot

Server evidence was collected on `SPADMIC_test` on 2026-07-09. The two first
leaf runs predate the scan-policy commit but the RTL/abstract behavior did not
change for those leaves. The scanfix runs for `output_fifo` and
`event_bundle_tx` use commit `08129bbb50233298e79d795654a6742330470ad3`.

| Block | Top module | Genus run | Innovus run | Commit | Result |
| --- | --- | --- | --- | --- | --- |
| `ddrs2_adapter` | `spadmic_ddrs2_adapter` | `genus_ooc_tx_leafs_20260709_1417` | `innovus_ooc_harden_ddrs2_adapter_leaf_20260709_1421` | `b5daae207836cbe7b441f30945f4fc96db68be2f` | `ABSTRACT_READY_FOR_TOP_REVIEW` |
| `ddr16_pairer` | `spadmic_ddr16_tx_pairer` | `genus_ooc_tx_leafs_20260709_1417` | `innovus_ooc_harden_ddr16_pairer_leaf_20260709_1422` | `b5daae207836cbe7b441f30945f4fc96db68be2f` | `ABSTRACT_READY_FOR_TOP_REVIEW` |
| `output_fifo` | `spadmic_output_fifo_topcfg` | `genus_ooc_tx_leafs_scanfix_20260709_1435` | `innovus_ooc_harden_output_fifo_scanfix_20260709_1438` | `08129bbb50233298e79d795654a6742330470ad3` | `ABSTRACT_READY_FOR_TOP_REVIEW` |
| `event_bundle_tx` | `spadmic_event_bundle_tx` | `genus_ooc_tx_leafs_scanfix_20260709_1435` | `innovus_ooc_harden_event_bundle_tx_scanfix_20260709_1450` | `08129bbb50233298e79d795654a6742330470ad3` | `ABSTRACT_READY_FOR_TOP_REVIEW` |

Required review gates passed for all four leaves:

- `INNOVUS_DRC_STATUS=PASS`
- `DRC_MARKER_CLASSIFICATION=PASS`
- `DRC_MARKER_TOTAL=0`
- `REGULAR_CONNECTIVITY_STATUS=PASS`
- `POSTROUTE_SETUP_TIMING=PASS`
- `POSTROUTE_HOLD_TIMING=PASS`
- `EXPORT_DEF_FILE=PASS`
- `EXPORT_LEF_FILE=PASS`
- `EXPORT_GDS_FILE=PASS`
- `HANDOFF_COPY=PASS`
- `PG_CONNECTIVITY_STATUS=DEFERRED_TOP_LEVEL_HOOKUP`
- `SIGNOFF_READY=NO`

The PG status is intentional: the local OOC abstracts export north `METTP`
`VDD`/`VSS` access pins and top assembly owns the final PG hookup.

## Physical Anchors

Use the read-only top layout audit as the placement source of truth:

- `TOP/docs/layout_audits/SPADMIC2_20260709_072331/csv/SPADMIC2_instances_enriched.csv`
- `TOP/docs/layout_audits/SPADMIC2_20260709_072331/csv/SPADMIC2_instance_pins_topcoords.csv`
- `TOP/docs/layout_audits/SPADMIC2_20260709_072331/reports/SPADMIC2_ddr_slvs_pins.csv`
- `TOP/docs/layout_audits/SPADMIC2_20260709_072331/reports/SPADMIC2_matrix_pins.csv`
- `TOP/docs/layout_audits/SPADMIC2_20260709_072331/reports/SPADMIC2_mptdc_pins.csv`

Important top-coordinate anchors from the audit:

| Object | Top-coordinate bbox / span |
| --- | --- |
| DDRs2 macro `M1` | `(21.980, 3261.886) - (3620.495, 3393.959) um` |
| DDRs2 DATA/CLK span | `x=(85.540, 3475.095) um`, span `3389.555 um` |
| TXRX4TDC2 `I6` | `(3505.519, 464.920) - (3638.910, 3265.795) um` |
| MPTDC top macro `I3` | `(2250.020, 2239.190) - (3311.220, 3041.110) um` |
| Matrix array `M182` | `(25.915, 776.039) - (2112.884, 2674.624) um` |

The generated DDRs2 adapter plan uses the DDRs2 DATA/CLK coordinates for north
pin placement. Do not re-space the `ddrs2_data_l_o`, `ddrs2_data_h_o`, or
`ddrs2_clk_160m_o` north pins unless the DDRs2 CSV changes.

## Abstract Dimensions

| Block | Core target | Observed design boundary |
| --- | ---: | ---: |
| `ddrs2_adapter` | `3433.979 x 30.000 um` | `3449.600 x 45.920 um` |
| `ddr16_pairer` | `120.000 x 80.000 um` | `140.000 x 100.240 um` |
| `output_fifo` | `720.000 x 520.000 um` | `740.320 x 540.400 um` |
| `event_bundle_tx` | `320.000 x 220.000 um` | `339.920 x 240.240 um` |

## Handoff Roots

The top assembly should consume the package under each handoff root, not route
inside the analog/custom macros:

| Block | Handoff root |
| --- | --- |
| `ddrs2_adapter` | `/sim/ksabra/SPADMIC_work/handoff/abstracts/ddrs2_adapter/innovus_ooc_harden_ddrs2_adapter_leaf_20260709_1421` |
| `ddr16_pairer` | `/sim/ksabra/SPADMIC_work/handoff/abstracts/ddr16_pairer/innovus_ooc_harden_ddr16_pairer_leaf_20260709_1422` |
| `output_fifo` | `/sim/ksabra/SPADMIC_work/handoff/abstracts/output_fifo/innovus_ooc_harden_output_fifo_scanfix_20260709_1438` |
| `event_bundle_tx` | `/sim/ksabra/SPADMIC_work/handoff/abstracts/event_bundle_tx/innovus_ooc_harden_event_bundle_tx_scanfix_20260709_1450` |

## Assembly Rule

The next TX task is a real top placement assembly using the four leaf abstract
packages above. The current `tx_egress_assembly` hardening alias still uses the
`spadmic_tx_egress_core` RTL shape for regression and review; it is not yet a
true macro-assembly flow that imports the four leaf LEF/DEF/GDS packages as
fixed placement objects.

Top assembly should place the DDRs2 adapter directly under DDRs2 and preserve
its north pin alignment. The other three leaves can be packed below or slightly
south-east/south-west of the adapter depending on routing congestion, but the
signal order should remain:

```text
event_bundle_tx -> output_fifo -> ddr16_pairer -> ddrs2_adapter -> DDRs2
```

## Future Subblocks

After the TX leaf package is frozen, continue with blocks that are safe as
separate OOC abstracts:

1. `event_coordinator`
2. `matrix_top_csr`
3. `i2c_csr_bridge` / `i2c_slave` if the pad-ring/I2C wrapper remains separate

Treat these as region-guided or soft until top congestion proves otherwise:

1. `matrix_reset_ctrl`
2. `matrix_cfg_ctrl`
3. `position_snapshot`
4. matrix OR/snapshot input capture

Those blocks touch matrix pins and reset/config routes; their final placement
should be derived from `SPADMIC2_matrix_pins.csv` and the matrix/top-coordinate
CSV, not from isolated rectangular convenience alone.

## Robust Audit Command

Use `awk` instead of a long `grep -E` expression when auditing the four leaf
status files; it is less fragile in SSH terminals:

```bash
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work

DDRS2_RUN_ID=innovus_ooc_harden_ddrs2_adapter_leaf_20260709_1421
DDR16_RUN_ID=innovus_ooc_harden_ddr16_pairer_leaf_20260709_1422
FIFO_RUN_ID=innovus_ooc_harden_output_fifo_scanfix_20260709_1438
EVENT_RUN_ID=innovus_ooc_harden_event_bundle_tx_scanfix_20260709_1450

for ITEM in \
  "ddrs2_adapter:$DDRS2_RUN_ID" \
  "ddr16_pairer:$DDR16_RUN_ID" \
  "output_fifo:$FIFO_RUN_ID" \
  "event_bundle_tx:$EVENT_RUN_ID"
do
  BLOCK="${ITEM%%:*}"
  RUN_ID="${ITEM##*:}"
  ROOT="$SPADMIC_WORK_ROOT/innovus/$RUN_ID"
  HB="$ROOT/blocks/$BLOCK"

  echo "===== $BLOCK ====="
  echo "RUN_ID=$RUN_ID"
  awk -F= '
    BEGIN {
      split("RESULT SIGNOFF_READY INNOVUS_DRC_STATUS DRC_MARKER_CLASSIFICATION DRC_MARKER_TOTAL REGULAR_CONNECTIVITY_STATUS PG_CONNECTIVITY_STATUS POSTROUTE_SETUP_TIMING POSTROUTE_HOLD_TIMING EXPORT_LEF_FILE EXPORT_GDS_FILE EXPORT_DEF_FILE HANDOFF_COPY", wanted)
      for (i in wanted) key[wanted[i]]=1
    }
    $1 in key {print}
  ' "$HB/reports/ooc_harden_status.rpt"
  find "$HB/outputs" -maxdepth 1 -type f -print | sort
done
```
