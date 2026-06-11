# SPADMIC_test P&R Plan

Do not launch Innovus before Genus and characterization gates are clean.

This flow is typical-only P&R preparation. It is not final tapeout signoff.

## Preconditions

- `STRIDE2` local tests pass.
- Stage 1 characterization passes.
- Genus typical is clean.
- Stage 2 characterization passes or the user explicitly approves a feasibility-only P&R run.
- Pre-PNR gate passes for the selected Genus handoff.

## Command Template

Set `MPTDC_GENUS_RUN_ID` to the clean Genus run used as the source.

```bash
RUN=spadmic_test_stride2_pnr_$(date +%Y%m%d_%H%M%S)

EXPECTED_HEAD="$(git rev-parse HEAD)" \
MPTDC_GENUS_RUN_ID=<clean_stride2_genus_run_id> \
MPTDC_OPT_MODE=STRIDE2 \
MPTDC_PNR_IO_LOAD_CLASS=medium \
MPTDC_PNR_CORE_UTIL=0.55 \
MPTDC_RUN_CLK_SYS_CTS=1 \
MPTDC_RUN_POSTROUTE_OPT=1 \
MPTDC_PNR_PLACE_PD_GRID=1 \
MPTDC_PNR_PLACE_PHASE_BUFFERS=1 \
MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=1 \
MPTDC_PNR_LIBRARY=JIHD \
MPTDC_FINAL_TYPICAL_APPROVED=1 \
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_final_typical.sh "$RUN" \
  --genus-run-id "$MPTDC_GENUS_RUN_ID" \
  --mode report_only
```

## Required Outputs

- Timing by class.
- Core timing.
- `clk_sys` timing.
- RO-domain timing.
- IO timing separated.
- Reset/recovery report.
- DRV reports.
- Phase buffer loads.
- Raw RO loads.
- Fast tag data loads.
- PD placement and symmetry.
- Route congestion.
- Route DRC.
- Antenna.
- Power connectivity.
- Density if available.
- Checkpoint.
- DEF.
- GUI restore instructions.
- Manager summary.

## Reset Rule

If fast-tag reset cleanup is not completed, P&R can be feasibility only and must be labeled `RESET_RECOVERY_NOT_SIGNOFF_READY`.
