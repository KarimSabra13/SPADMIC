# Final Typical Genus 124954 Deep Review

Run:

`final_typical_mptdc_genus_20260610_124954`

Local extracted evidence:

`/tmp/spadmic_genus_logs_124954/work/genus/final_typical_mptdc_genus_20260610_124954`

This run is a meaningful Genus improvement, but it is not Innovus-ready and
not signoff. It remains a typical-only, not-MMMC feasibility run.

## What Passed

- Genus reached export.
- `mptdc_top_asic.postsyn.v`, `.sdc`, `.sdf`, and Genus DB outputs exist.
- `RO_tune4` instances: `2`.
- Old `mptdc_osc_stub` residue: `0`.
- Raw RO clocks found: `16`.
- Final buffered phase clocks found: `16 / 16`.
- O13 phase topology is present: `RO_tune4/S[n] -> BUHDX4 -> BUHDX12`.
- `clk_sys` is asynchronous to buffered phase clocks.
- RO LEF/Liberty/RTL audit: `PASS`.
- Packet contract unchanged: `YES`.
- `raw_lfsr_tag` unchanged: `YES`.
- Exact PD Vernier q1 exception is solved:
  - expected endpoints: `64`
  - found endpoints: `64`
  - slow buffered sources: `8`
  - exception applied: `YES`
  - overmatch: `NO`
  - undermatch: `NO`
  - `UNKNOWN_REVIEW_REQUIRED`: `0`

## Wrong Previous Summary

The previous wrapper summary reported optimistic timing values:

- Real timed WNS ps: `+1.0`
- Real timed TNS ps: `0.0`

Those values are not consistent with the raw Genus timing summary. The raw
`timing_summary.rpt` is the source of truth for pass/fail timing:

- Setup WNS: `-3.5 ps`
- Setup TNS: `-77.1 ps`
- Setup violating paths: `42`
- Worst real family: `FAST_TAG_TO_PD_TS`

The repair package adds `tools/timing/summarize_mptdc_genus_run.py` and makes
the wrapper consume `timing_summary.rpt` instead of stale shell variables or
duplicated focused reports.

## Real Timing Failure

The worst setup path is a real fast oscillator-domain path:

- start: `u_core_gen_fast_tag_col[7].u_fast_tag_tag_o_reg[5]/C`
- endpoint: `u_core_gen_pd_row[7].gen_pd_col[7].u_pd/nfast_hit_latched_reg[5]/D`
- clock group: `clk_osc_fast_buf_tap7`
- required time: about `1836 ps`
- arrival time: about `1839 ps`
- slack: about `-3.5 ps`

This is not the intentional PD Vernier slow-phase q1 crossing. It is also not
CDC. The path must remain timed.

The top detailed negative rows are dominated by the source fast-tag register
C-to-Q and local PD timestamp latch fanout:

- source cell: `DFRRQHDX2`
- endpoint cell: `DFRHDX2`
- source Q fanout: `11`
- source Q load: about `101-103 fF`
- source transition: about `240-242 ps`
- data path delay: about `1059-1062 ps`
- setup: about `264-265 ps`

See `FINAL_GENUS_FAST_TAG_TO_PD_TS_ANALYSIS.md` for the top path table.

## DRV Failure

`report_design_rules.rpt` shows:

- Max transition violations: `1015`
- Max capacitance violations: `0`
- Max fanout violations: `0`

The root visible in the compressed report is:

- net: `n_6984`
- logical group: PD detect-enable or clear-derived local control
- driver: `g33116`
- driver cell: `INHDX8`
- fanout: `88`
- worst transition: `511 ps`
- limit: `500 ps`
- violation: `11 ps`

This should be fixed by targeted rebuffering or stronger local control-net
drive, not by relaxing `max_transition`.

## Report-Helper Failures

The 124954 log still contained report-helper failures:

- `Invalid list of objects`
- `Error: <Start> word is not recognized. [TUI-182] [get_db]`
- `extra characters after close-quote`

The fragile path is bracketed hierarchy string handling around
`mptdc_glob_escape` and object collection conversion. The repair package keeps
collections as collections where possible, converts to names only for reporting,
and adds a Genus-side helper selftest with representative bracketed names.

Unsupported report command variants were also present:

- `report_gates -depth`
- `report_gates -hier`
- `report_gates -hierarchy`
- unsupported `report_design_rules` variants

The repair package replaces those with supported reports or explicit substitute
reports.

## Current Decision

`124954` is a useful checkpoint, but the decision remains:

`GENUS_TYPICAL_REVIEW_REQUIRED`

Do not run Innovus from this result. Run `FINAL_TYPICAL_GENUS_REPAIR_1` first
and require clean timing, DRV, and report status before O13 Innovus feasibility.
