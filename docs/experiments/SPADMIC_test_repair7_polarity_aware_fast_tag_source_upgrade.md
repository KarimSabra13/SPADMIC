# SPADMIC Test Repair7 Polarity-Aware Fast-Tag Source Upgrade

Repair7 is `SPADMIC_TEST_STRIDE2_GENUS_REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE`.

## Purpose

Close the remaining typical-only `FAST_TAG_TO_PD_TS` setup miss by upgrading only the exact fast-tag source registers for taps `0..7` and bits `0,5,6`.

Repair6 proved that the exact path repair infrastructure is active, but it did not request source-cell forcing. Repair5 requested a single `DFRRQHDX4` target, which is not correct for this source set because the exact sources include both reset-to-0 and set-to-1 flops.

## Policy

- `DFRRQHDX1` sources are upgraded to `DFRRQHDX4`.
- `DFRSQHDX1` sources are upgraded to `DFRSQHDX4` if legal, otherwise `DFRSQHDX2`.
- The repair fails if the required polarity-preserving targets are not legal in the active library.
- The flow does not replace set-style flops with reset-style flops.
- The flow does not resize PD endpoint flops, alter packet semantics, change `raw_lfsr_tag`, change `R750_delta5`, or touch the O13 phase-buffer topology.

## Required Evidence

- `fast_tag_exact_source_cell_legal_cells.rpt`
- `fast_tag_exact_source_cell_command_ladder.rpt`
- `fast_tag_exact_source_cell_repair.csv`
- `fast_tag_exact_source_freeze.rpt`
- `fast_tag_exact_repair_status.rpt`
- `fast_tag_cell_mapping_guardrail.rpt`

Pass requires final verified exact source mapping:

- `FAST_TAG_EXACT_SOURCE_CELL_MODE=POLARITY_AWARE`
- `FAST_TAG_EXACT_RESET0_SOURCE_COUNT=16`
- `FAST_TAG_EXACT_SET1_SOURCE_COUNT=8`
- `FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT=16`
- `FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT=8` or `FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT=8`
- `FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT=0`
- `FAST_TAG_EXACT_SOURCE_CELL_RESULT=PASS_FINAL_VERIFIED`

The run remains a typical-only tapeout package check, not MMMC signoff.
