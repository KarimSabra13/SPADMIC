# MPTDC Lab Server Runbook

> **Author:** Karim Sabra
> **Target:** Linux server with Cadence Xcelium + Genus + Python 3.8+
> **Repo:** `https://github.com/KarimSabra13/SPADMIC.git`

Complete step-by-step guide to run the full MPTDC flow: verification →
data collection → calibration → exploratory synthesis.

---

## Current recommended command sequence

If you want the shortest path from repo checkout to the **current best lab-server checkpoint**, run in this order:

```bash
cd /path/to/your/workspace/SPADMIC
git fetch origin
git pull --ff-only origin main
cd MPTDC

# 1) Xrun sanity first
bash scripts/sim/run_tb.sh tb_single_conv --sim xcelium
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim xrun
bash scripts/sim/run_campaign.sh --sim xrun --smoke --out-dir results/calib_xrun/smoke

# 2) Full xrun calibration datasets
bash scripts/sim/run_campaign.sh --sim xrun --jobs 32 --seeds 100 --n-conv 50000 --delay-min 20 --delay-max 30000 --configs multihit_15_cal_nominal --out-dir results/calib_xrun/train_nominal_100s
bash scripts/sim/run_campaign.sh --sim xrun --jobs 32 --seeds 30 --n-conv 50000 --delay-min 20 --delay-max 30000 --seed-start 100 --configs multihit_15_cal_nominal --out-dir results/calib_xrun/val_nominal_30s
bash scripts/sim/run_campaign.sh --sim xrun --jobs 32 --seeds 30 --n-conv 50000 --delay-min 20 --delay-max 30000 --seed-start 200 --configs multihit_15_cal_jitter --out-dir results/calib_xrun/val_jitter_30s

# 3) Baseline LUT recalibration
python3 scripts/calibration/calibrate_6d_lut.py \
  --train-dir results/calib_xrun/train_nominal_100s/multihit_15_cal_nominal \
  --val-dir results/calib_xrun/val_nominal_30s/multihit_15_cal_nominal \
  --fresh-dir results/calib_xrun/val_jitter_30s/multihit_15_cal_jitter \
  --train-seeds 100 \
  --out-dir results/calib_xrun/calibration_lut6d

# 4) Enhanced comparison (GBR, trimmed/weighted averaging, etc.)
python3 scripts/calibration/calibrate_enhanced.py \
  --input "results/calib_xrun/val_nominal_30s/multihit_15_cal_nominal/seed_*.csv" \
  --out-dir results/calib_xrun/calibration_enhanced_nominal

python3 scripts/calibration/calibrate_enhanced.py \
  --input "results/calib_xrun/val_jitter_30s/multihit_15_cal_jitter/seed_*.csv" \
  --out-dir results/calib_xrun/calibration_enhanced_jitter

python3 scripts/calibration/analyze_fine_grid.py \
  -o results/calib_xrun/fine_grid_analysis.pdf

# 5) Pointwise same-delay proof
bash scripts/sim/run_fixed_delay_campaign.sh \
  --sim xrun \
  --jobs 32 \
  --configs multihit_15_cal_nominal \
  --delay-list "20,50,100,200,500,1000,2000,5000,10000,30000" \
  --seeds 8 \
  --n-conv 5000 \
  --out-dir results/calib_xrun/fixed_delay_nominal \
  --analyze

# 6) Coverage refresh before any freeze decision (recommended, but not required
#    before an exploratory Genus run)
bash ci/run_vip_coverage.sh --sim xrun --clean
bash ci/run_coverage_campaign.sh --sim xrun --seeds 100 --conv-per-seed 5000 --jobs 32 --clean
bash scripts/sim/report_coverage.sh --cov-root build/coverage_campaign
imc -load build/coverage_campaign/cov_work/scope/merged_cov &

# 7) Exploratory synthesis with oscillator stub / virtual clocks
cd syn/scripts
genus -batch -files genus.tcl 2>&1 | tee ../logs/genus_run.log
```

Use the rest of this document when you want the detailed step-by-step breakdown and expected results.

---

## Prerequisites

| Tool | Version | Used for |
|------|---------|----------|
| **Xcelium (xrun)** | 23.09+ | Simulation, coverage |
| **Genus** | 21.1+ | RTL synthesis |
| **Python 3** | 3.8+ | Calibration scripts |
| **numpy** | any | Calibration |
| **pandas** | any | CSV processing |
| **matplotlib** | any | Plots |
| **IMC** | (bundled with Xcelium) | Coverage review |
| **SimVision** | (bundled with Xcelium) | Waveform debug |
| **Git** | 2.x | Clone repo |

### Verify your environment

```bash
which xrun    && xrun -version    | head -1
which genus   && genus -version   | head -1
python3 --version
python3 -c "import numpy, pandas, matplotlib; print('Python deps OK')"
```

If Python packages are missing:

```bash
pip3 install --user numpy pandas matplotlib
```

---

## Step 0 — Clone and Set Up

If this is your first checkout:

```bash
cd /path/to/your/workspace
git clone https://github.com/KarimSabra13/SPADMIC.git
cd SPADMIC/MPTDC
```

If the repository is already present on the lab server:

```bash
cd /path/to/your/workspace/SPADMIC
git fetch origin
git pull --ff-only origin main
cd MPTDC
```

Verify repo structure:

```bash
ls -d rtl/ tb/ scripts/ ci/ syn/ docs/
```

**Expected:** All 6 directories present.

---

## Step 1 — Directed Smoke Test (Single Conversion)

**Goal:** Confirm the RTL compiles and one basic conversion works.

```bash
bash scripts/sim/run_tb.sh tb_single_conv --sim xcelium
```

**Expected output:**
```
=== MPTDC v2.3 TB Runner ===
  Testbench: tb_single_conv
  Simulator: xcelium
  Build dir: .../build/tb_single_conv
--- Compiling with Xcelium ---
...
[TB] Configuring: MULTI_HIT, max_hits=15, OUT_MODE_RAW_FEATURES
[TB] Arming conversion...
[TB] Injecting START...
[TB] Injecting STOP...
[TB] Waiting for output packet...
[TB] Collected N words
[TB] Header: ctx=0, hits=X, flags=0000, mode=0
[TB] EOC: conv_id=0
[TB] ===== TEST PASSED =====
```

**Runtime:** ~30 seconds (compile + run)

**If it fails:** Check that `xrun` is in your PATH and licensed. Look for
compile errors in the xrun output — they indicate missing defines or
unsupported constructs.

---

## Step 2 — Full Directed Regression (10 Integration Tests)

**Goal:** Verify all integration scenarios pass on Xcelium.

```bash
PASS=0; FAIL=0
for tb in tb_single_conv tb_multi_conv_stress tb_deadtime_measure \
          tb_cal_inject tb_backpressure tb_watchdog_recovery \
          tb_start_wdt tb_overflow_count tb_firsthit_mode \
          tb_lossless_pressure; do
  echo "========================================"
  echo "  Running: $tb"
  echo "========================================"
  if bash scripts/sim/run_tb.sh "$tb" --sim xcelium; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "!!! FAILED: $tb !!!"
  fi
done
echo ""
echo "Results: $PASS passed, $FAIL failed out of 10"
```

**Expected:** `10 passed, 0 failed out of 10`

**Runtime:** ~3–5 minutes total

| Test | What it verifies |
|------|-----------------|
| `tb_single_conv` | Basic START→STOP→packet flow |
| `tb_multi_conv_stress` | Back-to-back conversions, conv_id sequencing |
| `tb_deadtime_measure` | Re-arm timing between conversions |
| `tb_cal_inject` | CAL input path (vs SPAD) |
| `tb_backpressure` | Ready/valid stalling, data preservation |
| `tb_watchdog_recovery` | Global watchdog timeout and recovery |
| `tb_start_wdt` | Missing-STOP → START watchdog fires |
| `tb_overflow_count` | Overflow counter / rejected-START accounting |
| `tb_firsthit_mode` | compatibility-named fast-close packet check (`max_hits = 1`) |
| `tb_lossless_pressure` | STOP-to-next-START pressure, saturation/release, exact rejected-START accounting |

---

## Step 3 — VIP Smoke Regression (13 Class-Based Tests)

**Goal:** Run the full VIP framework — transaction-driven, self-checking,
with scoreboard validation.

```bash
bash ci/run_vip_smoke.sh
```

If you want the explicit expanded form:

```bash
for test in smoke_single_conv full_mode_timestamp firsthit_contract \
            backpressure_integrity start_watchdog cal_inject \
            overflow_status long_random multi_conv_rearm_stress \
            global_watchdog_recovery csr_readback_control hard_reset_readback; do
  echo "=== VIP: $test ==="
  bash scripts/sim/run_vip_test.sh "$test" --sim xrun
done

echo "=== VIP: jitter_robustness ==="
bash scripts/sim/run_vip_test.sh jitter_robustness --sim xrun \
  --osc-jitter-sigma 8 --osc-jitter-bound 24
```

**Expected:** `13/13` pass, with each test printing `===== TEST PASSED =====` and exiting cleanly.

**Runtime:** ~5–8 minutes total

| Test | Key verification |
|------|-----------------|
| `smoke_single_conv` | Single conversion, ≥1 hit, no flags |
| `full_mode_timestamp` | FULL mode, timestamp vs Vernier algebra |
| `firsthit_contract` | fast-close flag set, min 1 hit |
| `backpressure_integrity` | Packets survive random stalls |
| `start_watchdog` | START-only → watchdog fires + recovery |
| `cal_inject` | CAL source produces valid hits |
| `overflow_status` | Deterministic rejected START / OVF_COUNT / recovery |
| `long_random` | 8 conversions, random delays, timestamp check |
| `multi_conv_rearm_stress` | 12 rapid conversions, conv_id tracking |
| `global_watchdog_recovery` | Global trip counter and recovery |
| `csr_readback_control` | CSR readback, FIFO clear, soft reset semantics |
| `hard_reset_readback` | `CSR_HIT_COUNT` readback and pad-reset recovery |
| `jitter_robustness` | 6 conversions with oscillator jitter |

---

## Step 4 — VIP Coverage Regression (Functional + Code)

**Goal:** Collect functional and code coverage for the pre-calibration / pre-synthesis closure checkpoint.

```bash
bash ci/run_vip_coverage.sh --sim xrun --clean
```

**Expected output:**
```
============================================
  MPTDC VIP Coverage Regression
============================================
  Simulator: xrun
  Tests: 14
...
=== Running VIP coverage: smoke_single_conv ===
--- smoke_single_conv: PASSED ---
...
 VIP coverage results: 14 passed, 0 failed
Coverage workdir: .../build/vip_coverage_xrun/cov_work
Logs: .../build/vip_coverage_xrun/logs
```

**Runtime:** ~10–20 minutes

Default merged coverage suite:

- `smoke_single_conv`
- `full_mode_timestamp`
- `firsthit_contract`
- `backpressure_integrity`
- `start_watchdog`
- `cal_inject`
- `overflow_status`
- `long_random`
- `multi_conv_rearm_stress`
- `global_watchdog_recovery`
- `csr_readback_control`
- `hard_reset_readback`
- `jitter_robustness`
- `coverage_exhaustive`

### Step 4b — Broader coverage + stress campaign

If you want a stronger pre-calibration checkpoint than the stable merged VIP suite alone, run:

```bash
bash ci/run_coverage_campaign.sh --sim xrun --seeds 100 --conv-per-seed 5000 --jobs 32 --clean
```

This runs:

- the merged coverage suite first
- then `stress_random` across many seeds
- a shared Cadence coverage database under `build/coverage_campaign/cov_work/`
- per-test logs under `build/coverage_campaign/logs/`

Most recent merged IMC report observed on the lab server before the latest local-only closure additions:

- aggregate IMC coverage `11486 / 16389 (70.08%)`,
- average grade `82.05%`,
- weakest reported modules: `mptdc_top_asic 45.95%`, `mptdc_csr_if 28.26%`, `mptdc_csr_minimal 61.39%`, `mptdc_reset_sync 61.67%`.

### Review coverage in IMC

```bash
# Stable VIP DB
bash scripts/sim/report_coverage.sh --cov-root build/vip_coverage_xrun --merge-name vip_merged
imc -load build/vip_coverage_xrun/cov_work/scope/vip_merged &

# Broader coverage-campaign DB
bash scripts/sim/report_coverage.sh --cov-root build/coverage_campaign
imc -load build/coverage_campaign/cov_work/scope/merged_cov &
```

The helper script also generates HTML reports under
`build/*/cov_report_aggregate/index.html` and `build/*/cov_report_expand/index.html`.

**Coverage targets:**

| Metric | Target | Where to check |
|--------|--------|---------------|
| `stim_cg` (stimulus coverage) | >90% | IMC → Functional Coverage → stim_cg |
| `pkt_cg` (packet coverage) | >85% | IMC → Functional Coverage → pkt_cg |
| Line coverage | >90% | IMC → Code Coverage → Line |
| Condition coverage | >80% | IMC → Code Coverage → Condition |
| Toggle coverage | >70% | IMC → Code Coverage → Toggle |

---

## Step 5 — Data Collection Campaign

**Goal:** Generate large-scale simulation data for calibration training.

> **Note:** `scripts/sim/run_campaign.sh` now supports both `--sim verilator`
> and `--sim xrun|xcelium`. Use Verilator for the fastest local collection;
> use `xrun` / Xcelium on Cadence-equipped servers when you want the same
> collection flow under the industry simulator.

### Option A: Native campaign runner (recommended)

```bash
# Check Verilator first
verilator --version

# Or check Xcelium on a Cadence server
which xrun && xrun -version | head -1

# Run the full maintained campaign with Verilator
bash scripts/sim/run_campaign.sh --sim verilator --jobs 12

# Quick smoke first
bash scripts/sim/run_campaign.sh --sim verilator --smoke
bash scripts/sim/run_campaign.sh --sim xrun --smoke

# Or collect only the calibration-focused configuration
bash scripts/sim/run_campaign.sh --sim xrun --jobs 32 --configs multihit_15_cal_nominal
```

**Expected output:**
```
Campaign complete
  Configs run: 24
  Total CSV files: 720
  Total data rows: ~36,000,000
```

By default, results land in `results/campaign/`:

```
results/campaign/
  multihit_15_cal_nominal/seed_0.csv ... seed_29.csv
  multihit_15_cal_jitter/seed_0.csv ... seed_29.csv
  multihit_15_spad_nominal/seed_0.csv ... seed_29.csv
  ...
  firsthit_5_spad_jitter/seed_0.csv ... seed_29.csv
```

Use `--out-dir DIR` if you want a separate run location.

### Option B: Native Xcelium campaign collection

For Cadence collection with the same runner interface:

```bash
# Single config, single seed smoke
bash scripts/sim/run_campaign.sh --sim xrun --smoke --out-dir results/campaign_xrun_smoke

# 100 seeds × 50k conversions on the calibration-focused config
bash scripts/sim/run_campaign.sh \
  --sim xrun \
  --jobs 32 \
  --seeds 100 \
  --n-conv 50000 \
  --delay-min 20 \
  --delay-max 30000 \
  --configs multihit_15_cal_nominal \
  --out-dir results/campaign_xrun_train
```

The runner handles Xcelium correctly by launching each seed with its own
`xcelium.d` library under `build/campaign_xrun/`, so 32-way parallel jobs do
not contend for one shared Cadence worklib.

**v2.3 CSV note:** `FULL` mode now emits a **19-column** schema:

```csv
conv_id,hit_idx,Tref_ps,nslow,nfast_hit,nfast_snap,nfast_stop,ns,nf,pd_idx,event_seq,phase0_snap,slow_boundary_inc,hit_count,flags,ctx_id,t_raw_ps,mode,max_hits
```

`nfast_stop` is reserved and currently always `0` because the fast oscillator
starts at `STOP` time in the active architecture. Calibration scripts remain
backward-compatible with legacy 18-column CSV files.

**Runtime:**
- Smoke: ~2 minutes
- Full campaign (12 cores): ~30–60 minutes
- Native Xcelium campaign: slower than Verilator because each seed runs through `xrun`

---

## Step 6 — Calibration Refresh (6D LUT baseline + enhanced comparison)

**Goal:** retrain the maintained baseline LUT, then rerun the richer
post-processing so the Xrun server results can be compared against the current
repository baselines.

```bash
# Recommended lab-server split: train nominal + held-out nominal + fresh jitter
bash scripts/sim/run_campaign.sh \
  --sim xrun \
  --jobs 32 \
  --seeds 100 \
  --n-conv 50000 \
  --delay-min 20 \
  --delay-max 30000 \
  --configs multihit_15_cal_nominal \
  --out-dir results/calib_xrun/train_nominal_100s

bash scripts/sim/run_campaign.sh \
  --sim xrun \
  --jobs 32 \
  --seeds 30 \
  --n-conv 50000 \
  --delay-min 20 \
  --delay-max 30000 \
  --seed-start 100 \
  --configs multihit_15_cal_nominal \
  --out-dir results/calib_xrun/val_nominal_30s

bash scripts/sim/run_campaign.sh \
  --sim xrun \
  --jobs 32 \
  --seeds 30 \
  --n-conv 50000 \
  --delay-min 20 \
  --delay-max 30000 \
  --seed-start 200 \
  --configs multihit_15_cal_jitter \
  --out-dir results/calib_xrun/val_jitter_30s

python3 scripts/calibration/calibrate_6d_lut.py \
  --train-dir results/calib_xrun/train_nominal_100s/multihit_15_cal_nominal \
  --val-dir results/calib_xrun/val_nominal_30s/multihit_15_cal_nominal \
  --fresh-dir results/calib_xrun/val_jitter_30s/multihit_15_cal_jitter \
  --train-seeds 100 \
  --out-dir results/calib_xrun/calibration_lut6d
```

Optional explicit directory control:

```bash
python3 scripts/calibration/calibrate_6d_lut.py \
  --train-dir results/calib_xrun/train_nominal_100s/multihit_15_cal_nominal \
  --val-dir results/calib_xrun/val_nominal_30s/multihit_15_cal_nominal \
  --fresh-dir results/calib_xrun/val_jitter_30s/multihit_15_cal_jitter \
  --out-dir results/calib_xrun/calibration_lut6d
```

The calibrator does **not** use a `--data-dir` flag. Its maintained interface is:

- `--train-dir`
- `--val-dir`
- `--fresh-dir`
- `--out-dir`
- `--train-seeds`
- `--chunk-load`

**Expected output:**

```
Training LUT on N data points...
LUT bins: ~16,014
Validation on M fresh points...

Pre-calibration:
  RMSE:  425.8 ps
  MAE:   350.8 ps

Post-calibration (nominal core subset: nslow > 0):
  RMSE:  18.89 ps    ← nominal baseline
  MAE:   14.6 ps
  P90:   32.9 ps
  P99:   45.0 ps

Averaging study (analysis-side resampling, not fixed-delay TB proof):
  N=1:    18.95 ps
  N=4:     9.49 ps
  N=10:    6.03 ps
  N=100:   1.90 ps
  N=1000:  0.60 ps
```

**Generated files:**
- Pre/post calibration scatter plots (PNG)
- Residual distribution histograms
- Averaging performance curve
- LUT data (pickle/CSV)

**Runtime:** ~5–15 minutes depending on dataset size

### Interpreting results

- **~18.9 ps on the nominal core subset** = the classic nominal LUT baseline is healthy
- **RMSE > 25 ps on the same nominal scope** = investigate the dataset, constants, and LUT coverage first
- **Averaging follows 1/√N in `calibrate_6d_lut.py`** = the nominal calibrated pool is largely random after correction, but this is still analysis-side resampling
- **Use the fixed-delay flow below** when you need empirical same-delay one-shot RMS / averaging proof

### Step 6a — Enhanced calibration comparison

Use the maintained enhanced script to compare LUT variants, GBR, and
quality-gated averaging on the new Xrun datasets:

```bash
python3 scripts/calibration/calibrate_enhanced.py \
  --input "results/calib_xrun/val_nominal_30s/multihit_15_cal_nominal/seed_*.csv" \
  --out-dir results/calib_xrun/calibration_enhanced_nominal

python3 scripts/calibration/calibrate_enhanced.py \
  --input "results/calib_xrun/val_jitter_30s/multihit_15_cal_jitter/seed_*.csv" \
  --out-dir results/calib_xrun/calibration_enhanced_jitter

python3 scripts/calibration/analyze_fine_grid.py \
  -o results/calib_xrun/fine_grid_analysis.pdf
```

Current maintained repo baselines to compare against:

| Metric | Nominal | Jitter (`σ = 6 ps`) |
|--------|---------|---------------------|
| 6D LUT single-shot RMSE | `18.99 ps` | `53.64 ps` |
| GBR single-shot RMSE | `18.56 ps` | `48.24 ps` |
| 15-hit weighted / trimmed RMSE | `5.19 ps` / `5.29 ps` | `19.75 ps` (trimmed) |

If your Xrun results are materially worse than these baselines, check:

- whether the campaign used the same configuration names (`multihit_15_cal_nominal`, `multihit_15_cal_jitter`)
- whether the server build picked up the latest `main`
- whether the CSV schema is the new 19-column `FULL` mode output
- whether the calibration script filtered to the same `nslow > 0` core subset

### Step 6b — Fixed-delay characterization

**Goal:** prove same-delay one-shot RMS and real same-delay averaging behavior from measured conversions.

```bash
bash scripts/sim/run_fixed_delay_campaign.sh \
  --sim xrun \
  --jobs 32 \
  --configs multihit_15_cal_nominal \
  --delay-list "20,50,100,200,500,1000,2000,5000,10000,30000" \
  --seeds 8 \
  --n-conv 5000 \
  --out-dir results/calib_xrun/fixed_delay_nominal \
  --analyze
```

Key outputs:

- `results/calib_xrun/fixed_delay_nominal/analysis/fixed_delay_summary.csv`
- `results/calib_xrun/fixed_delay_nominal/analysis/fixed_delay_averaging.csv`
- `results/calib_xrun/fixed_delay_nominal/analysis/fixed_delay_report.txt`

These reports distinguish:

- row-level error
- first scanned hit per conversion
- per-conversion mean estimator

Important interpretation note:

- this fixed-delay flow is the right tool for **pointwise same-delay** RMS / averaging proof
- it is **not** the headline deployment-proof flow for jitter-limited `RAW_FEATURES`
  operation across a continuous delay population
- for that question, use `scripts/calibration/analyze_shortformat_models.py`, which now
  reports delay-bucketed oracle/practical curves and separates the incremental value of
  `boundary_aug`, `nfast_snap`, and `all_visible`

---

## Step 7 — Trial Synthesis with Genus

**Goal:** Verify the RTL synthesizes cleanly and check timing.

> **Important:** this synthesis step is still **exploratory** until the analog
> oscillator macro is available. You can advance now because the maintained
> synthesis flow already excludes the behavioral oscillator model and constrains
> the oscillator domains through a stub + virtual clocks. That is enough for
> logic- and flow-readiness work, but **not** for final signoff on the analog
> boundary or final QoR.

### 7a. Prepare PDK paths

Edit exactly two files with your XFAB PDK installation paths:

**File 1:** `syn/libraries/libraries.xh018.tcl`
```tcl
# Line ~30 — set your PDK root
set paths(PDK_ROOT) "/path/to/your/xfab/XH018"
```

**File 2:** `syn/libraries/libraries.xh018-stdcells.tcl`
```tcl
# Verify these .lib filenames match your PDK version:
set tech_files(STDCELLS_TC_LIB) "$paths(PDK_ROOT)/D_CELLS_HD/v3_0/liberty_LPMOS/v3_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib"
set tech_files(STDCELLS_BC_LIB) "..."  # best-case corner
set tech_files(STDCELLS_WC_LIB) "..."  # worst-case corner
```

> **See `syn/inputs/README.md`** for detailed constraint rationale and a
> checklist of what to update when you have the real PDK.

### 7b. Run synthesis

```bash
cd syn/scripts
genus -files genus.tcl
```

Or in batch mode (no GUI):

```bash
cd syn/scripts
genus -batch -files genus.tcl 2>&1 | tee ../logs/genus_run.log
```

### 7c. Expected Genus output

```
╔══════════════════════════════════════════════════════════╗
║          MPTDC Synthesis — Stage Summary                ║
╠════════════╦═════════════╦═══════════════════════════════╣
║ Stage      ║ Elapsed     ║ Status                        ║
╠════════════╬═════════════╬═══════════════════════════════╣
║ init       ║ 0:00:02     ║ Libraries loaded              ║
║ mmmc       ║ 0:00:01     ║ TC corner active              ║
║ read_rtl   ║ 0:00:05     ║ 20 files read                 ║
║ elaborate  ║ 0:00:10     ║ mptdc_top_asic elaborated     ║
║ post_elab  ║ 0:00:03     ║ check_timing_intent clean     ║
║ synthesis  ║ 0:02:00     ║ Synthesis complete             ║
║ post_synth ║ 0:00:30     ║ 6 latches (expected: 6) ✓     ║
║ export     ║ 0:00:05     ║ Netlist + SDC exported         ║
╚════════════╩═════════════╩═══════════════════════════════╝
```

**Runtime:** ~3–5 minutes

### 7d. Check results

```bash
# Timing summary
cat ../reports/post_synth/timing_summary.rpt

# Area
cat ../reports/post_synth/area.rpt

# All reports
ls ../reports/post_synth/
```

**Key things to check:**

| Check | Where | Pass criteria |
|-------|-------|--------------|
| **Timing met** | `timing_summary.rpt` | No negative slack (or small violations acceptable for trial) |
| **Latch count = 6** | Genus log (latch audit) | Exactly 6 intentional SR latches |
| **No unresolved references** | Genus log | No `*W*` about missing modules |
| **Clock groups** | `check_timing_intent` | All 3 clocks in async groups |
| **Area reasonable** | `area.rpt` | Gate count in expected range for 180 nm |

### 7e. Generated output files

```
syn/
  outputs/
    mptdc_top_asic.v        ← gate-level netlist
    mptdc_top_asic.sdc      ← updated constraints for PnR
  reports/
    post_elab/              ← pre-synthesis checks
    post_synth/             ← timing, area, power, DRC reports
  logs/
    genus_run.log           ← full transcript
  work/
    genus.db/               ← Genus database (can reload)
```

### 7f. Common issues and fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| `Cannot find library file` | Wrong PDK path | Fix path in `libraries.xh018-stdcells.tcl` |
| `No .lib file` | PDK not installed | Get XFAB XH018 PDK from your foundry account |
| Large negative slack on osc domain | Combinational depth too deep for 0.9 ns | Expected at 180 nm — check if PD matrix is the bottleneck |
| `Warning: latch inferred` | Intentional latches in async frontend | Should be exactly 6 — latch audit checks this |
| `Error: undefined module mptdc_osc_model` | OSC model compiled during synthesis | Should not happen — `MPTDC_USE_OSC_MODEL` is NOT defined for synthesis |

---

## Full Flow Summary

```
Step  What                                Tool        Time         Pass Criteria
────────────────────────────────────────────────────────────────────────────────────
 1    Pull latest main                    Git         <1 min       Clean fast-forward
 2    Single-conv Xrun smoke             Xcelium     ~30s         TEST PASSED
 3    VIP single-test smoke              Xrun        ~1 min       TEST PASSED
 4    Xrun campaign smoke                Xrun        ~2 min       CSV + log generated
 5    Full Xrun campaign train/val       Xrun        hours        CSV datasets complete
 6    LUT + enhanced recalibration       Python      10-30 min    Baselines reproduced
 7    Fixed-delay proof run              Xrun+Py     variable     Summary/averaging CSVs
 8    Coverage refresh (recommended)     Xrun+IMC    variable     Coverage DB + merged report
 9    Exploratory synthesis              Genus       3-5 min      Timing clean, 6 latches
```

**Practical interpretation:** your next logical checkpoint on the lab server is
indeed **pull → Xrun sanity → Xrun campaign → recalibration → fixed-delay proof
→ exploratory synthesis**. Keep coverage as a recommended refresh before any
freeze/signoff decision, but it does not have to block a trial Genus run.

---

## Troubleshooting

### Xcelium compile errors

```bash
# Run with verbose output to see exact error
bash scripts/sim/run_tb.sh tb_single_conv --sim xcelium 2>&1 | head -100
```

Common fixes:
- Missing license → check `LM_LICENSE_FILE` or `CDS_LIC_FILE`
- Wrong xrun version → needs SystemVerilog 2017 support (Xcelium 23.09+)
- Path issues → run from the MPTDC directory root

### Python import errors

```bash
pip3 install --user numpy pandas matplotlib
```

### Genus license issues

```bash
# Check license availability
genus -batch -execute "puts [get_license_info]; exit"
```

### Waveform debug

```bash
# Run any test with --waves flag
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim xrun --waves

# Open in SimVision
simvision build/vip_smoke_single_conv_xrun/waves.shm &
```
