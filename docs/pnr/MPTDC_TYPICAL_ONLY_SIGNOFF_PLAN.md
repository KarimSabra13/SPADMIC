# MPTDC Typical-Only Signoff Plan

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

## Objective

Build a controlled physical prototype and a near-signoff reporting package for
the MPTDC block using the accepted typical-only Genus handoff. This plan is the
bridge from clean Genus to physical evidence. It is not final chip signoff.

## Required Input Gate

The P&R flow must start from one approved Genus source:

`final_typical_genus_jihd_tap0_micro_v3_drvclean_20260610_175527`

Required gate result:

```text
PRE_PNR_GATE=PASS
FINAL_DECISION=GENUS_TYPICAL_CLOSED
GENUS_TYPICAL_STATUS=GENUS_TYPICAL_CLOSED
INNOVUS_READY=READY_FOR_O13_INNOVUS_FEASIBILITY
NOT_MMMC_SIGNOFF=YES
FINAL_SIGNOFF=NO
```

The gate must also prove zero setup, real timed, max transition, max
capacitance, and max fanout violations, plus exact O13 PD Vernier matching.

## Physical Evidence To Produce

- netlist and SDC import manifest
- floorplan and macro placement summary
- PD 8x8 grid placement/audit report
- O13 phase-buffer placement report
- power connectivity report for standard cells and `RO_tune4`
- IO pin side and block-level load report
- CTS report for `clk_sys`
- audit proving raw RO clocks and buffered phase clocks were excluded from CTS
- timing reports split by path class
- DRV reports for max transition, max capacitance, and max fanout
- raw RO output load report with strict `58.72 fF` preferred limit and
  `75.59 fF` warning limit
- phase-buffer output load report
- route, congestion, antenna, DRC, LVS, and extraction readiness reports

## Stop Conditions

Stop the flow for review if any of these are observed:

- the Genus gate does not pass
- RO_tune4 supply pin names contradict `VDD/vdd!/VSS`
- the LEF implies a dedicated analog RO supply that is not connected by plan
- raw RO output load exceeds the `75.59 fF` warning limit
- the O13 `BUHDX4 -> BUHDX12` topology is missing or asymmetric
- CTS inserts buffers on raw RO clocks or buffered phase clocks
- physical verification requires a foundry rule choice that is not documented
