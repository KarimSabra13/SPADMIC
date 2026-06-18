# MPTDC Timing Closure Status

Author: Karim Sabra

The June 18, 2026 `mptdc_axis_core` reference baseline is closed in the typical
Genus view and was ready for an Innovus feasibility study at its exact Git HEAD.
This is not MMMC, extracted, or final tapeout signoff.

| Metric | Result |
| --- | ---: |
| Commit | `fa66cc4d36936e2bf0d41e6b24f2f9486569e242` |
| Reference run | `20260618_111124_axis_core_genus_timing_close_on22x1_final_guarded` |
| Setup WNS | `+0.3 ps` |
| Setup TNS | `-0.0 ps` |
| Setup violating paths | `0` |
| Transition violations | `0` |
| Capacitance violations | `0` |
| Fanout violations | `0` |
| Decision | `GENUS_TYPICAL_CLOSED` |

The exact PD exception matched 64 paths from eight sources. The final scoped
local repair resolved 355 mapped X0 instances and selected the safe X1 target.
The stronger X2 trial was rejected because it introduced a new local regression.
The canonical profile therefore keeps X2 disabled.

Repository cleanup commits above the reference timing commit do not change this
timing evidence by themselves. RTL changes do. The slow/fast RO-code interface
and local shadow registers create a new netlist contract, so this timing result
is now reference evidence, not the active PnR handoff for the current checkout.
A clean canonical wrapper rerun is required before the newer checkout becomes
the accepted PnR handoff head.

Reproduce the repository policy with:

```bash
bash MPTDC/syn/scripts/check_genus_axis_core_typical_closed_profile.sh
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh
```

The values and full rationale are in
`MPTDC/syn/scripts/profiles/genus_axis_core_typical_closed.sh` and
`MPTDC/docs/synthesis/GENUS_AXIS_CORE_TYPICAL_CLOSED_PROFILE.md`.

Remaining work is a clean server rerun of the new wrapper, Innovus feasibility,
post-placement and post-clock-tree review, MMMC/extracted timing, analog
confirmation, characterization, and physical verification.

```text
TYPICAL_ONLY_NOT_MMMC_NOT_FINAL_SIGNOFF
```
