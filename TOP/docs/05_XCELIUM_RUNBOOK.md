# SPADMIC TOP — Xcelium Lab-Server Runbook

## 1. Prerequisites

- **Xcelium** (Cadence) installed and on `$PATH` (`xrun`, `imc`)
- **MPTDC repo** accessible at `../MPTDC/` relative to `TOP/`
- **Git branch**: `SPADMIC_top` (or local `SPADMIC_top_v1`)
- **Server resources**: 16–32 cores recommended for parallel campaign

## 2. Quick Start

```bash
# From the TOP/ directory:
cd /path/to/SPADMIC/TOP

# Step 1: Smoke check (compile + first directed bench)
bash ci/run_smoke.sh

# Step 2: All directed benches
bash ci/run_directed_regression.sh

# Step 3: VIP smoke (3 tests)
bash ci/run_vip_smoke.sh

# Step 4: Full VIP coverage regression (11 tests + merge)
bash ci/run_vip_coverage.sh

# Step 5: Multi-seed stress campaign (20+ seeds, parallel)
bash ci/run_coverage_campaign.sh --seeds 50 --max-jobs 16

# Step 6: View coverage report
cat build/campaign_report/summary.txt
# Or open HTML in browser:
# firefox build/campaign_report/report/dashboard.html
```

## 3. Individual Test Runs

### Directed bench
```bash
bash scripts/sim/run_tb.sh tb_spadmic_stress_csr --sim xrun
bash scripts/sim/run_tb.sh tb_spadmic_stress_position --sim xrun --waves
```

### VIP test (without coverage)
```bash
bash scripts/sim/run_vip_test.sh smoke_tdc
bash scripts/sim/run_vip_test.sh tdc_modes --seed 42
```

### VIP test (with coverage)
```bash
bash scripts/sim/run_vip_test.sh tdc_modes \
  --func-cov --code-cov \
  --seed 42
```

### VIP test (with waveforms)
```bash
bash scripts/sim/run_vip_test.sh smoke_tdc --waves
# Waveforms in: build/vip/smoke_tdc_s1/waves/waves.shm
```

### VIP test (I2C driver mode)
```bash
bash scripts/sim/run_vip_test.sh i2c_end_to_end --drv-mode I2C
```

## 4. Configuration Plusargs

| Plusarg | Default | Description |
|---------|---------|-------------|
| `+SPADMIC_TEST=<name>` | `smoke_tdc` | Test selection |
| `+SPADMIC_SEED=<N>` | `1` | Random seed |
| `+SPADMIC_DRV_MODE=<I2C\|CSR>` | `CSR` | Control stimulus path |
| `+SPADMIC_PROFILE=<name>` | `TDC_CHAR` | Mission profile |
| `+SPADMIC_NUM_CONV=<N>` | `10` | Number of TDC conversions |
| `+SPADMIC_NUM_PHASES=<N>` | `20` | Number of random phases |
| `+SPADMIC_MAX_HITS=<N>` | `15` | TDC max_hits setting |
| `+SPADMIC_OUT_MODE=<N>` | `0` | TDC output mode |
| `+SPADMIC_TIMEOUT=<ns>` | `500000` | Test timeout |

## 5. Coverage Merge & Inspection

```bash
# Manual merge
bash scripts/sim/report_coverage.sh build/coverage build/coverage_report

# Interactive IMC session
imc -load build/coverage_report/merged_cov
```

### Key IMC commands:
```tcl
report_metrics -kind aggregate              ;# overall summary
report_metrics -kind cover_group -detail    ;# functional coverage detail
report_metrics -kind code -detail           ;# code coverage detail
report_metrics -kind assertion              ;# SVA assertion summary
```

## 6. Waveform Debug

```bash
# Run with waves
bash scripts/sim/run_vip_test.sh smoke_tdc --waves

# Open SimVision
simvision build/vip/smoke_tdc_s1/waves/waves.shm &
```

## 7. Regression Order (Recommended)

| Phase | Command | Duration Estimate |
|-------|---------|-------------------|
| 0. Compile check | `bash ci/run_smoke.sh` | ~2 min |
| 1. Directed benches | `bash ci/run_directed_regression.sh` | ~10 min |
| 2. VIP smoke | `bash ci/run_vip_smoke.sh` | ~5 min |
| 3. VIP coverage | `bash ci/run_vip_coverage.sh` | ~30 min |
| 4. Stress campaign | `bash ci/run_coverage_campaign.sh --seeds 50` | ~2 hr |
| 5. Coverage report | `bash scripts/sim/report_coverage.sh` | ~1 min |

## 8. Troubleshooting

### Common issues:

**"Cannot find MPTDC filelist"**
- Ensure `MPTDC/` is at `../MPTDC/` relative to `TOP/`

**"xrun: command not found"**
- Source your Cadence environment: `source /path/to/cadence/setup.sh`

**Compile errors in VIP classes**
- Check that `MPTDC/rtl/filelist.f` compiles first (package dependencies)

**Coverage numbers low after single run**
- This is expected — run the full campaign with multiple seeds

**I2C timeout in i2c_end_to_end**
- I2C is inherently slow; increase `+SPADMIC_TIMEOUT=10000000`
