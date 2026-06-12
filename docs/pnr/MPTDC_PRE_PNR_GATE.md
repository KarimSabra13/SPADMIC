# MPTDC Pre-PNR Gate

Status: `GENUS_TYPICAL_CLOSED`, `READY_FOR_INNOVUS_TYPICAL_CLOSURE`,
`TYPICAL_ONLY_TAPEOUT_PACKAGE`, `NOT_MMMC_SIGNOFF`,
`NOT_FINAL_SILICON_SIGNOFF`

The pre-PNR gate checks that the Genus input package is the Repair8 typical
closure handoff before Innovus placement or routing is allowed.

## Accepted Run

```text
spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302
```

## Required Passing Markers

- setup WNS `>= 0 ps`
- setup TNS `0`
- setup violations `0`
- max transition/capacitance/fanout violations `0/0/0`
- `UNKNOWN_REVIEW_REQUIRED=0`
- `ACTIVE_SDC_FAILURE_COUNT=0`
- report helpers `PASS`
- summary/raw agreement `PASS`
- `RO_tune4` count `2`
- old oscillator stub residue `0`
- raw RO clocks `16`
- buffered phase clocks `16`
- `clk_sys` async to buffered phase clocks `YES`
- PD Vernier exception `64/64`, applied `YES`
- packet format unchanged
- `raw_lfsr_tag` unchanged
- O13 `BUHDX4 -> BUHDX12` phase-buffer topology verified
- STRIDE2 active
- exact fast-tag repair status `PASS`
- fast-tag mapping parser status `PASS`

The gate warns but does not block when:

```text
GENUS_WNS_MARGIN_LOW=YES
```

This warning is expected for Repair8 because WNS is about `+0.1 ps`, below the
20 ps margin threshold. P&R must then use timing-preserving placement and route
settings.

## Command

```bash
bash MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh \
  --genus-run-id spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302
```

The checker also accepts:

```bash
bash MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh \
  --handoff-dir work/handoff/genus_typical/mptdc_genus_typical_closed
```

## Source-Cell Report Policy

Missing `FAST_TAG_EXACT_SOURCE_CELL_*` reports are not blockers for Repair8
when setup is closed, DRV is clean, exact path repair status is `PASS`, and the
fast-tag mapping parser status is `PASS`. Source-cell repair reports are only
hard requirements for source-cell forcing experiments.

## Generated Clock Counter Policy

If `report_clocks final-driver generated-clock count = 0` disagrees with
`BUFFER_PHASE_CLOCKS_FOUND=16`, the buffered-clock fields are authoritative for
this gate. P&R readiness depends on the explicit O13 buffer-clock discovery and
async grouping checks, not the stale generated-clock text counter.
