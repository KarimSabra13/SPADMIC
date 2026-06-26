# MPTDC Timing Closure Status

Author: Karim Sabra

The June 25, 2026 `mptdc_axis_core` TC-only Innovus baseline is extracted and
clean in the official TC setup/hold gates at source commit `010285dc`. This is
not MMMC, foundry DRC/LVS, or final tapeout signoff.

| Metric | Result |
| --- | ---: |
| Commit | `010285dc` |
| Reference run | `20260625_mptdc_tc_fullclosure_010285dc_postfiller1` |
| Genus handoff | `20260623_1207_mptdc_axis_core_typical_closed_ba2b2932` |
| Extracted TC setup WNS | `0.000 ns` |
| Extracted TC setup TNS | `0.000 ns` |
| Setup violating paths | `0` |
| Extracted TC hold WNS | `+0.048 ns` |
| Extracted TC hold TNS | `0.000 ns` |
| Hold violating paths | `0` |
| Transition violations | `0` |
| Capacitance violations | `0` |
| Fanout violations | `0` |
| Decision | `TC_ONLY_PROVISIONAL_BASELINE` |

The official `timeDesign` setup and hold reports pass after post-route
extraction. The route/filler/extraction/DRV/timing stack is therefore a useful
TC-only baseline for continued physical closure.

There is one timing-report discrepancy to keep visible: the focused
`fast_tag_to_pd_timing_focus.rpt` still shows command-specific negative setup
paths down to about `-0.065 ns`, while the official extracted TC setup summary
reports WNS/TNS `0.000/0.000` with zero violating paths and
`fast_tag_timing_focus.rpt` reports `GROUP_PATH_STATUS=PASS`. Resolve that
accounting difference before making any stronger closure claim. Do not use false
paths or broad multicycle suppression to hide it.

Reproduce the repository policy and timing flow with:

```bash
bash MPTDC/syn/scripts/check_genus_axis_core_typical_closed_profile.sh
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  --mode full_signoff \
  --genus-run-id MPTDC_TC_Closure_Genus \
  --handoff-dir <handoff_dir>
```

The current baseline evidence and server-side inspection commands are in
`MPTDC/docs/pnr/MPTDC_TC_CLOSURE_20260625_BASELINE.md`.

Remaining work is independent route-DRC cleanup, foundry DRC/LVS, row
qualification, antenna signoff, IR/EM, WC/BC timing, RO stress review, analog
confirmation, and physical verification.

```text
TC_ONLY_PROVISIONAL_NOT_MMMC_NOT_FINAL_SIGNOFF
```
