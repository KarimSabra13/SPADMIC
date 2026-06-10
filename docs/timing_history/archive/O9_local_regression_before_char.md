# O9 Local Regression Before Characterization

Run these before launching the O9 Xcelium overnight:

```bash
bash -n MPTDC/scripts/sim/run_tb.sh \
  MPTDC/scripts/sim/run_vip_test.sh \
  MPTDC/scripts/sim/run_campaign.sh \
  MPTDC/scripts/sim/run_fixed_delay_campaign.sh \
  MPTDC/scripts/sim/run_characterization_baseline.sh \
  MPTDC/scripts/sim/run_vip_overnight.sh \
  MPTDC/sim/verilator/run_lint.sh \
  MPTDC/sim/verilator/run_smoke.sh \
  MPTDC/syn/scripts/server_run_genus_o9_final_typical_r750_delta5.sh
python3 -m py_compile \
  MPTDC/scripts/analysis/mptdc_char_common.py \
  MPTDC/scripts/analysis/analyze_campaign.py \
  MPTDC/scripts/analysis/analyze_characterization_overnight.py \
  MPTDC/scripts/calibration/analyze_fine_grid.py \
  MPTDC/scripts/calibration/calibrate_6d_lut.py
bash MPTDC/scripts/sim/run_tb.sh tb_fast_epoch_tag_unit --sim verilator --fast-tag-encoding raw_lfsr_tag --freq-mode nominal
bash MPTDC/scripts/sim/run_tb.sh tb_fast_epoch_tag_unit --sim verilator --fast-tag-encoding raw_lfsr_tag --freq-mode r750_delta5
bash MPTDC/scripts/sim/run_tb.sh tb_narrow16_tx_v2_unit --sim verilator --fast-tag-encoding raw_lfsr_tag --freq-mode r750_delta5
python3 tools/mptdc_decode/test_fast_tag_decode.py
python3 MPTDC/scripts/analysis/o2_raw_tag_charac_smoke.py --freq-mode r750_delta5 --run-id 20260604_o9_r750_raw_tag_smoke
```

Pass criteria:

- Nominal mode still compiles.
- R750 mode compiles with `MPTDC_FREQ_R750_DELTA5`.
- Packet format unit test passes.
- Raw LFSR tag decode table test passes.
- Python analysis/calibration modules compile.
- Shell syntax checks pass.

Full local Verilator smoke may be run with:

```bash
MPTDC_FREQ_MODE=r750_delta5 MPTDC_FAST_TAG_ENCODING=raw_lfsr_tag \
  bash MPTDC/sim/verilator/run_smoke.sh 20260604_o9_r750_delta5_local_smoke
```
