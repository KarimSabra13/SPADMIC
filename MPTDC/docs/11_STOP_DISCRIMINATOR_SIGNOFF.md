# MPTDC STOP-Discriminator ECO Signoff Log

> **Scope:** Documents the post-ECO RTL/VIP/Python evidence for exporting the
> STOP-edge slow-phase discriminator in `RAW_FEATURES`/`FULL` packets and using it
> in host-side calibration.
>
> **Dataset root:** `/sim/ksabra/vip_overnight_stop_disc_halfseed`
>
> **Source commits:**
> - `7af16fe` — `MPTDC: add STOP phase discriminator to packet and calibration flow`
> - `4e0646c` — `MPTDC: fix raw-features calibration runner path`

## 1. ECO summary

The ECO captures `slow_phase[5:3]` on the STOP edge and exports it as
`stop_phase_disc` in packet feature word W1 `[2:0]` for `RAW_FEATURES` and
`FULL` modes. `RAW_TIMESTAMP` mode remains unchanged.

The discriminator is routed through the existing STOP metadata/static-bus path:

```text
mptdc_core.sv
  -> mptdc_stop_capture_async.sv
  -> mptdc_hit_capture_bridge.sv
  -> mptdc_context_bank / mptdc_drain_ctrl
  -> mptdc_narrow16_tx_v2.sv
  -> tb/VIP/Python CSV schema
```

The maintained calibration key is:

```text
ns_inf, nf_inf, nslow, nfast_hit, stop_phase_disc, phase0_snap, hit_idx
```

`ns_inf` and `nf_inf` are inferred from the raw Vernier algebra so the key works
for compact packet modes.

## 2. Xcelium VIP evidence

The post-ECO VIP CDV run completed cleanly:

| Metric | Result |
|---|---:|
| Tests | 512 |
| Pass | 512 |
| Fail | 0 |

This verifies the packet decode, stop-discriminator field propagation, and
ready/valid packet protocol at the macro verification level.

## 3. Raw-features characterization campaign

Command used on the Cadence server:

```bash
bash scripts/sim/run_vip_overnight.sh \
  --stages char \
  --sim xrun \
  --jobs 32 \
  --clean \
  --rerun-char \
  --char-seeds 32 \
  --char-train-seeds 24 \
  --char-n-conv 100000 \
  --char-out-mode raw_features \
  --fixed-delay-seeds 6 \
  --fixed-delay-n-conv 5000 \
  --fixed-delay-jobs 32 \
  --out-dir /sim/ksabra/vip_overnight_stop_disc_halfseed
```

Sweep campaign summary:

| Item | Value |
|---|---:|
| Config | `multihit_15_cal_nominal_raw_features` |
| Seeds | 32 |
| Conversions per seed | 100000 |
| CSV files | 32 |
| Hit rows | 48,000,000 |
| Mean offset | -157.57 ps |
| Std | 431.01 ps |
| Raw RMSE | 458.91 ps |
| Vernier cross-check | PASS |
| Peak DNL | 1.190 LSB |
| Peak INL | 90.792 LSB |
| Boundary classes | 3 |
| Worst delay bin | 20..520 ps |
| Worst-bin RMSE | 1106.51 ps |
| Worst-bin P99 | 1729.00 ps |

All campaign artifacts are under:

```text
/sim/ksabra/vip_overnight_stop_disc_halfseed/characterization
```

## 4. Manual calibration recovery and result

The first automated calibration failed because the wrapper pointed at:

```text
campaign/multihit_15_cal_nominal
```

while `--out-mode raw_features` writes:

```text
campaign/multihit_15_cal_nominal_raw_features
```

The wrapper was fixed in commit `4e0646c`. The manual recovery used the correct
directory:

```bash
CFG_DIR=/sim/ksabra/vip_overnight_stop_disc_halfseed/characterization/campaign/multihit_15_cal_nominal_raw_features
OUT_CAL=/sim/ksabra/vip_overnight_stop_disc_halfseed/characterization/analysis/calibration

python3 scripts/calibration/calibrate_6d_lut.py \
  --train-dir "$CFG_DIR" \
  --val-dir "$CFG_DIR" \
  --out-dir "$OUT_CAL" \
  --train-seeds 24
```

Training summary:

| Item | Value |
|---|---:|
| Training files | 24 |
| Total rows loaded | 36,000,000 |
| Core rows (`nslow > 0`) | 34,052,940 |
| LUT bins | 9,388 |
| Minimum bin population | 1 |
| Median bin population | 3,674 |
| Maximum bin population | 6,704 |

Held-out validation on seeds 24..29:

| Metric | Pre-calibration | Post-calibration |
|---|---:|---:|
| Rows | 8,512,620 | 8,512,620 |
| RMSE | 435.20 ps | 18.57 ps |
| MAE | 375.46 ps | 15.24 ps |
| Mean error | -137.807 ps | -0.011 ps |
| Std | 412.808 ps | 18.573 ps |
| \|err\| P50 | 327.00 ps | 13.51 ps |
| \|err\| P90 | 731.00 ps | 31.46 ps |
| \|err\| P95 | 794.00 ps | 35.41 ps |
| \|err\| P99 | 864.00 ps | 39.00 ps |
| Min / Max | -1260.00 / +795.00 ps | -40.59 / +40.40 ps |

Headline result:

```text
435.20 ps -> 18.57 ps RMSE, 95.7% improvement
```

Averaging thresholds from the held-out core subset:

| Target | Required averages |
|---|---:|
| Sub-15 ps RMSE | N >= 2 |
| Sub-10 ps RMSE | N >= 4 |
| Sub-5 ps RMSE | N >= 15 |
| Sub-2 ps RMSE | N >= 100 |
| Sub-1 ps RMSE | N >= 400 |

## 5. Fixed-delay campaign evidence

Fixed-delay collection command:

```bash
bash scripts/sim/run_fixed_delay_campaign.sh \
  --sim xrun \
  --jobs 32 \
  --seeds 6 \
  --n-conv 5000 \
  --configs multihit_15_cal_nominal \
  --out-mode raw_features \
  --delay-list 20,50,100,200,500,1000,2000,5000,10000,30000 \
  --out-dir /sim/ksabra/vip_overnight_stop_disc_halfseed/characterization/fixed_delay \
  --analyze
```

The fixed-delay campaign completed for all 10 delay points with 6 seeds per
point. Each delay point produced 450,000 hit rows, for 4,500,000 rows total.

Initial all-row alias diagnostic:

```bash
python3 scripts/analysis/analyze_raw_aliases.py \
  --campaign-dir /sim/ksabra/vip_overnight_stop_disc_halfseed/characterization/fixed_delay \
  --config-filter 'multihit_15_cal_nominal*' \
  --out-dir /sim/ksabra/vip_overnight_stop_disc_halfseed/characterization/fixed_delay/analysis/raw_aliases
```

All-row result:

| Key | Rows | Unique keys | Aliased keys | Aliased rows | Alias fraction | Oracle RMSE | Max span |
|---|---:|---:|---:|---:|---:|---:|---:|
| `raw_formula_inputs` | 4,500,000 | 228 | 54 | 1,680,084 | 0.373352 | 186.23 ps | 980 ps |
| `packet_no_hit` | 4,500,000 | 228 | 54 | 1,680,084 | 0.373352 | 186.23 ps | 980 ps |
| `packet_with_hit` | 4,500,000 | 228 | 54 | 1,680,084 | 0.373352 | 186.23 ps | 980 ps |
| `packet_stop_disc` | 4,500,000 | 276 | 24 | 720,000 | 0.16 | 180.00 ps | 900 ps |
| `packet_all_csv` | 4,500,000 | 276 | 24 | 720,000 | 0.16 | 180.00 ps | 900 ps |
| `debug_aug` | 4,500,000 | 228 | 54 | 1,680,084 | 0.373352 | 186.23 ps | 980 ps |

This table is intentionally recorded as a diagnostic, not as final calibration
signoff: it includes `nslow == 0` boundary rows, while the maintained calibration
flow signs off and reports the `nslow > 0` core subset. The updated alias
analyzer now supports the exact calibration key and explicit core/non-core
subsets. Run the following after pulling the source update:

```bash
python3 scripts/analysis/analyze_raw_aliases.py \
  --campaign-dir /sim/ksabra/vip_overnight_stop_disc_halfseed/characterization/fixed_delay \
  --config-filter 'multihit_15_cal_nominal*' \
  --core-only \
  --out-dir /sim/ksabra/vip_overnight_stop_disc_halfseed/characterization/fixed_delay/analysis/raw_aliases_core

column -s, -t < \
  /sim/ksabra/vip_overnight_stop_disc_halfseed/characterization/fixed_delay/analysis/raw_aliases_core/multihit_15_cal_nominal_raw_features/alias_key_summary.csv
```

The row to check is `cal_lut_key` on subset `core_nslow_gt_0`.

## 6. Signoff interpretation

Completed and clean:

- RTL packet field and metadata propagation are implemented.
- VIP CDV passed 512/512.
- Broad raw-features Xcelium characterization completed with 48M rows.
- Discriminator-aware held-out calibration reached 18.57 ps RMSE on the core
  subset, with 95.7% improvement and no meaningful held-out bias.
- The characterization wrapper now uses the correct raw-features campaign
  directory and does not silently mix pre-ECO fresh-validation data.

Still required before treating fixed-delay alias closure as signed off:

- Re-run `analyze_raw_aliases.py --core-only` with the updated analyzer.
- Confirm `cal_lut_key` has `aliased_keys = 0`, `aliased_rows = 0`, and
  `oracle_floor_rmse_ps = 0.0` on subset `core_nslow_gt_0`.
- Keep `nslow == 0` rows flagged as boundary/low-confidence in host software;
  they are not part of the maintained LUT accuracy claim.

Do not commit `/sim` CSVs, plots, or calibration binaries into the repository.
The repository records source, scripts, documentation, commands, paths, and
headline metrics; large generated artifacts remain under `/sim`.
