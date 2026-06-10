# Final Genus FAST_TAG_TO_PD_TS Analysis

- Run directory: `/tmp/spadmic_genus_logs_124954/work/genus/final_typical_mptdc_genus_20260610_124954`
- Source CSV: `/tmp/spadmic_genus_logs_124954/work/genus/final_typical_mptdc_genus_20260610_124954/timing_path_classification.csv`
- Source timing report: `/tmp/spadmic_genus_logs_124954/work/genus/final_typical_mptdc_genus_20260610_124954/timing_violations.rpt`
- Rows analyzed: `41`

This is real fast oscillator-domain setup timing. It is not CDC, not the intentional PD Vernier crossing, and not a candidate for false-path or multicycle relaxation.

The QoR timing summary reports `42` setup violating paths and `-77.1 ps`
TNS. The detailed `timing_violations.rpt` has `41` negative-slack path
rows plus one rounded boundary row reported as `MET (-0 ps)`, so this table
lists the 41 negative detailed rows while the wrapper still uses the QoR
count of 42 as the pass/fail source of truth.

The clock-path delay is `0 ps` in these rows because the buffered phase clocks
are modeled as ideal generated clocks in Genus. That does not make the data
path a CDC path; the start and endpoint clocks are the same buffered fast
phase clock group.

## Top Violating Paths

| Path | Family | Slack ps | Tap | Tag Bit | Start Cell | Endpoint Cell | Row | Col | Data Path ps | Clock Path ps | Setup ps | Source Fanout | Source Load fF | Source Trans ps | Freeze Mux | Dominant Term |
|---:|---|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| 1 | `FAST_TAG_TO_PD_TS` | -4 | 7 | 5 | `DFRRQHDX2` | `DFRHDX2` | 7 | 7 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 2 | `FAST_TAG_TO_PD_TS` | -4 | 5 | 5 | `DFRRQHDX2` | `DFRHDX2` | 7 | 5 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 3 | `FAST_TAG_TO_PD_TS` | -4 | 7 | 5 | `DFRRQHDX2` | `DFRHDX2` | 6 | 7 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 4 | `FAST_TAG_TO_PD_TS` | -4 | 5 | 5 | `DFRRQHDX2` | `DFRHDX2` | 6 | 5 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 5 | `FAST_TAG_TO_PD_TS` | -4 | 7 | 5 | `DFRRQHDX2` | `DFRHDX2` | 5 | 7 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 6 | `FAST_TAG_TO_PD_TS` | -4 | 5 | 5 | `DFRRQHDX2` | `DFRHDX2` | 5 | 5 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 7 | `FAST_TAG_TO_PD_TS` | -4 | 7 | 5 | `DFRRQHDX2` | `DFRHDX2` | 4 | 7 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 8 | `FAST_TAG_TO_PD_TS` | -4 | 5 | 5 | `DFRRQHDX2` | `DFRHDX2` | 4 | 5 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 9 | `FAST_TAG_TO_PD_TS` | -4 | 7 | 5 | `DFRRQHDX2` | `DFRHDX2` | 3 | 7 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 10 | `FAST_TAG_TO_PD_TS` | -4 | 5 | 5 | `DFRRQHDX2` | `DFRHDX2` | 3 | 5 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 11 | `FAST_TAG_TO_PD_TS` | -4 | 7 | 5 | `DFRRQHDX2` | `DFRHDX2` | 2 | 7 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 12 | `FAST_TAG_TO_PD_TS` | -4 | 5 | 5 | `DFRRQHDX2` | `DFRHDX2` | 2 | 5 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 13 | `FAST_TAG_TO_PD_TS` | -4 | 7 | 5 | `DFRRQHDX2` | `DFRHDX2` | 1 | 7 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 14 | `FAST_TAG_TO_PD_TS` | -4 | 5 | 5 | `DFRRQHDX2` | `DFRHDX2` | 1 | 5 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 15 | `FAST_TAG_TO_PD_TS` | -4 | 7 | 5 | `DFRRQHDX2` | `DFRHDX2` | 0 | 7 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 16 | `FAST_TAG_TO_PD_TS` | -4 | 5 | 5 | `DFRRQHDX2` | `DFRHDX2` | 0 | 5 | 1062 | 0 | 264 | 11 | 102.8 | 242 | YES | SOURCE_CQ_DOMINATED |
| 17 | `LOCAL_FAST_TAG_SELF` | -2 | 7 | 5 | `DFRRQHDX2` | `DFRSQHDX2` | NA | NA | 1012 | 0 | 313 | 11 | 102.8 | 242 | NO | SOURCE_CQ_DOMINATED |
| 18 | `LOCAL_FAST_TAG_SELF` | -2 | 5 | 5 | `DFRRQHDX2` | `DFRSQHDX2` | NA | NA | 1012 | 0 | 313 | 11 | 102.8 | 242 | NO | SOURCE_CQ_DOMINATED |
| 19 | `FAST_TAG_TO_PD_TS` | -1 | 6 | 5 | `DFRRQHDX2` | `DFRHDX2` | 7 | 6 | 1059 | 0 | 265 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 20 | `FAST_TAG_TO_PD_TS` | -1 | 3 | 5 | `DFRRQHDX2` | `DFRHDX2` | 7 | 3 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 21 | `FAST_TAG_TO_PD_TS` | -1 | 3 | 5 | `DFRRQHDX2` | `DFRHDX2` | 6 | 3 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 22 | `FAST_TAG_TO_PD_TS` | -1 | 3 | 5 | `DFRRQHDX2` | `DFRHDX2` | 5 | 3 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 23 | `FAST_TAG_TO_PD_TS` | -1 | 3 | 5 | `DFRRQHDX2` | `DFRHDX2` | 4 | 3 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 24 | `FAST_TAG_TO_PD_TS` | -1 | 3 | 5 | `DFRRQHDX2` | `DFRHDX2` | 3 | 3 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 25 | `FAST_TAG_TO_PD_TS` | -1 | 3 | 5 | `DFRRQHDX2` | `DFRHDX2` | 1 | 3 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 26 | `FAST_TAG_TO_PD_TS` | -1 | 3 | 5 | `DFRRQHDX2` | `DFRHDX2` | 0 | 3 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 27 | `FAST_TAG_TO_PD_TS` | -1 | 1 | 5 | `DFRRQHDX2` | `DFRHDX2` | 7 | 1 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 28 | `FAST_TAG_TO_PD_TS` | -1 | 6 | 5 | `DFRRQHDX2` | `DFRHDX2` | 6 | 6 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 29 | `FAST_TAG_TO_PD_TS` | -1 | 1 | 5 | `DFRRQHDX2` | `DFRHDX2` | 6 | 1 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 30 | `FAST_TAG_TO_PD_TS` | -1 | 6 | 5 | `DFRRQHDX2` | `DFRHDX2` | 5 | 6 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 31 | `FAST_TAG_TO_PD_TS` | -1 | 1 | 5 | `DFRRQHDX2` | `DFRHDX2` | 5 | 1 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 32 | `FAST_TAG_TO_PD_TS` | -1 | 6 | 5 | `DFRRQHDX2` | `DFRHDX2` | 4 | 6 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 33 | `FAST_TAG_TO_PD_TS` | -1 | 1 | 5 | `DFRRQHDX2` | `DFRHDX2` | 4 | 1 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 34 | `FAST_TAG_TO_PD_TS` | -1 | 1 | 5 | `DFRRQHDX2` | `DFRHDX2` | 3 | 1 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 35 | `FAST_TAG_TO_PD_TS` | -1 | 6 | 5 | `DFRRQHDX2` | `DFRHDX2` | 2 | 6 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 36 | `FAST_TAG_TO_PD_TS` | -1 | 3 | 5 | `DFRRQHDX2` | `DFRHDX2` | 2 | 3 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 37 | `FAST_TAG_TO_PD_TS` | -1 | 1 | 5 | `DFRRQHDX2` | `DFRHDX2` | 2 | 1 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 38 | `FAST_TAG_TO_PD_TS` | -1 | 6 | 5 | `DFRRQHDX2` | `DFRHDX2` | 1 | 6 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 39 | `FAST_TAG_TO_PD_TS` | -1 | 1 | 5 | `DFRRQHDX2` | `DFRHDX2` | 1 | 1 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 40 | `FAST_TAG_TO_PD_TS` | -1 | 6 | 5 | `DFRRQHDX2` | `DFRHDX2` | 0 | 6 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |
| 41 | `FAST_TAG_TO_PD_TS` | -1 | 1 | 5 | `DFRRQHDX2` | `DFRHDX2` | 0 | 1 | 1059 | 0 | 264 | 11 | 101.1 | 240 | YES | SOURCE_CQ_DOMINATED |

## Repair Direction

- Keep these paths timed in the fast buffered phase clock domains.
- First try targeted source-register drive and local nfast distribution buffering.
- Do not alter the O13 PD Vernier exception; it applies to slow buffered phase sources into q1 endpoints, not these nfast tag paths.

## 134332 Residual Update

Run `final_typical_genus_repair_1_20260610_134332` reproduced the same real
timing shape with the corrected parser:

- setup WNS/TNS: `-3.5 ps` / `-77.1 ps`
- setup violating paths: `42`
- worst real family: `FAST_TAG_TO_PD_TS`
- affected buffered fast taps: mainly `1`, `3`, `5`, `6`, and `7`

Because the source cells are still reported as `DFRRQHDX2` and the path is
source C->Q dominated, the next repair pressure is to compile the final-typical
repair filelist with `MPTDC_RELAX_FAST_TAG_PRESERVE`, bias the source tag flops
toward `DFRRQHDX4`, and constrain the fast-tag Q distribution to lower fanout
and transition. This remains a real timing repair, not a false-path or
multicycle change.
