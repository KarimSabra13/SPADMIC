# Evidence: 20260609_o13_abs5_source_fix_validate_only

Status: `VALIDATE_ONLY_NOT_CLOSURE`

Labels:

- `TYPICAL_ONLY_TAPEOUT_PACKAGE`
- `NOT_MMMC_SIGNOFF`
- `FINAL_SIGNOFF=NO`

## Source

- Local evidence path: `results/genus_osc_pd/20260609_o13_abs5_source_fix_validate_only/`
- Historical HEAD in summary: `8c20025402280b90ed736db111338d34f4fe5097`
- Mode: `validate_only`
- Genus launched: no

## Result

- Input validation passed.
- SDC overlay selected the exact PD Vernier exception path.
- SDC command failure count in the generated review file: `0`.
- No post-synthesis netlist was generated.
- Clock counts, endpoint counts, timing, and DRV were not measurable.

## Interpretation

This run proves only wrapper/file selection. It does not prove:

- raw RO clocks found = `16`
- buffered phase clocks found = `16`
- PD q1 endpoints found = `64`
- slow buffered sources found = `8`
- PD Vernier exception applied = `YES`
- timing closure
- DRV closure

The next lab-server run must launch Genus through the stable wrapper and must
write output under `work/genus/<RUN_ID>/`.
