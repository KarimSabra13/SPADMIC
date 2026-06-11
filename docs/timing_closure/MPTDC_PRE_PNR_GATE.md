# MPTDC Pre-PNR Gate

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

The pre-PNR gate is the hard input check before the stable MPTDC Innovus
wrapper may prepare or launch an implementation run.

## Command

```bash
bash MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh \
  --genus-run-id final_typical_genus_jihd_tap0_micro_v3_drvclean_20260610_175527
```

The checker accepts either `--genus-run-id` or `--genus-run-dir`.

## Required Passing Markers

- `FINAL_DECISION=GENUS_TYPICAL_CLOSED`
- `GENUS_TYPICAL_STATUS=GENUS_TYPICAL_CLOSED`
- `INNOVUS_READY=READY_FOR_O13_INNOVUS_FEASIBILITY`
- `TYPICAL_ONLY_TAPEOUT_PACKAGE=YES`
- `NOT_MMMC_SIGNOFF=YES`
- `FINAL_SIGNOFF=NO`
- Genus exit code `0`
- Snapshot exit code `0`
- setup violating path count `0`
- real timed violating path count `0`
- max transition/capacitance/fanout violations `0/0/0`
- PD intentional Vernier paths matched `64`
- PD intentional Vernier sources matched `8`
- PD intentional Vernier exception applied `YES`
- PD intentional Vernier overmatch and undermatch `NO`
- unknown review-required count `0`
- SDC command failure count `0`
- report helpers `PASS`
- fast-tag mapping `PASS`
- fast-tag top path count `0`

## Override Policy

The default policy is fail closed. Override is allowed only for deliberate
review/debug and must be explicit:

```bash
MPTDC_PRE_PNR_GATE_ALLOW_REVIEW=1 \
bash MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh --genus-run-id <RUN_ID>
```

Override does not convert the run into signoff. Any downstream Innovus result
must be labeled review/debug until the gate passes without override.
