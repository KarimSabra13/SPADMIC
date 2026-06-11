# SPADMIC_test Genus Plan

Run only after local Verilator passes.

## STRIDE2 Typical Command

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source /eda/cadence/eda_2023-2024
git checkout SPADMIC_test
git pull --ff-only

RUN=spadmic_test_stride2_genus_$(date +%Y%m%d_%H%M%S)

EXPECTED_HEAD="$(git rev-parse HEAD)" \
MPTDC_OPT_MODE=STRIDE2 \
bash MPTDC/syn/scripts/server_run_genus_mptdc_final_typical.sh "$RUN"
```

## Required Clean Gates

- Setup WNS >= 0.
- Setup TNS = 0.
- Setup violations = 0.
- Max transition = 0.
- Max cap = 0.
- Max fanout = 0.
- SDC failures = 0.
- Helper failures = 0.
- UNKNOWN = 0.
- PD Vernier exception PASS.
- RO audit PASS.
- Packet unchanged YES.
- `raw_lfsr_tag` unchanged YES.
- O13 topology preserved.

## Focus Reports

- `mptdc_drain_ctrl` `clk_sys` paths.
- `context_bank -> drain_ctrl`.
- `hit_capture_bridge -> context_bank`.
- `meas_pd_clear` fanout and transition.
- High fanout reports.
- DRV.
- q1/q2/fast tag paths unchanged.
- Phase buffer bank untouched.
- RO raw load model untouched.

Reject the mode if a new fast/oscillator-domain violation appears or if phase topology changes.
