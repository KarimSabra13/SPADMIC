# O9 Final Results Review

Date reviewed: 2026-06-04

This is an analysis-only review of the committed O9 R750 delta5 characterization
and final typical Genus synthesis outputs on branch `SPADMIC_localtag`.

This is not final signoff. The O9 synthesis is typical-only, does not use MMMC,
uses a screenshot-derived provisional oscillator timing model, and still depends
on analog confirmation.

## Checkout And Runs

| Item | Value |
|---|---|
| Current branch | `SPADMIC_localtag` |
| Current review HEAD | `1ee8e7101a7f263998b63cc736dfa38018e4e4ba` |
| Final Genus run | `results/genus_osc_pd/20260604_o9_final_typical_r750_delta5` |
| Characterization run stub | `results/o9_char/20260604_o9_r750_delta5_overnight` |
| Lab snapshot | `MPTDC/lab_snapshots/genus_osc_pd_20260604_o9_final_typical_r750_delta5` |
| Unrelated dirty files | Python `__pycache__` files under `tools/mptdc_decode` |

The latest relevant commits are:

- `1ee8e710 server-results: O9 final typical R750 delta5 Genus`
- `e1696b95 results: add O9 R750 delta5 characterization`
- `a6583c79 scripts: route MPTDC simulation scratch to external storage`
- `e226161c rtl/scripts: add O9 R750 delta-preserving frequency mode`

## Genus Configuration

| Item | Value |
|---|---|
| Run ID | `20260604_o9_final_typical_r750_delta5` |
| Genus Git HEAD | `e1696b9575febffe0d4a51cf5050c1b72835f2ca` |
| Synthesis mode | O9 final typical R750 delta5 |
| Frequency mode | `O9_R750_DELTA5` |
| RTL define | `+define+MPTDC_FREQ_R750_DELTA5` |
| NFAST encoding | `raw_lfsr_tag` |
| Packet format | `fixed_raw_features_v2_7`, unchanged |
| `OSC_TS_SLOW_PS` | 79 |
| `OSC_TS_FAST_PS` | 74 |
| `DELTA_STEP` | 5 ps |
| `DELTA_LSB` | 10 ps |
| `K_VERNIER` | 15 |
| Slow clock period | 1.430 ns, about 699.3 MHz |
| Fast clock period | 1.333 ns, about 750.2 MHz |
| Standard-cell Liberty | `/data/pdk/xfab/xh018/diglibs/D_CELLS_HD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib` |
| RO LEF | `/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef` |
| RO Liberty shell | `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib` |
| SDC overlay | `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5.sdc` |
| Genus effort | `closure` |
| MMMC | Disabled; no BC/WC views |
| Analysis view | `tc_view`, `typ_1_80V_25C` |
| Signoff label | `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF` |

The run manifest contains stale-looking oscillator uncertainty fields
(`0.050/0.020 ns`), but the final SDC overlay and violating path reports show
the intended O9 uncertainty was used: 10 ps setup uncertainty, 5 ps hold
uncertainty in the overlay, and 10 ps setup uncertainty in the reported failing
paths.

## Timing Result

The O9 final typical Genus view is near-clean but not clean.

| Metric | Value |
|---|---:|
| Total WNS | -1.6 ps |
| Total TNS | -11.2 ps |
| Violating paths | 7 |
| Clean classes | `OSC_SLOW_REAL`, `CLK_SYS_REAL` |
| Failing class | `OSC_FAST_REAL` |
| Unknown review paths | 0 |

Because there are still violations, the required clean-run phrase does not
apply. Do not label this `O9_TYPICAL_GENUS_CLEAN`.

### Timing By Class

| Class | WNS | TNS | Violating paths | Evidence |
|---|---:|---:|---:|---|
| `OSC_FAST_REAL` | -1.6 ps | -11.2 ps | 7 | `timing_summary.rpt` group `clk_osc_fast` |
| `OSC_SLOW_REAL` | 448.8 ps | 0.0 ps | 0 | `timing_summary.rpt` group `clk_osc_slow` |
| `CLK_SYS_REAL` | 13.0 ps | 0.0 ps | 0 | `timing_summary.rpt` group `clk_sys` |
| `PD_INTENTIONAL_VERNIER` | no separate failing class | 0.0 ps | 0 | no unknown paths in classification |
| `UNKNOWN_REVIEW_REQUIRED` | none | 0.0 ps | 0 | `timing_path_classification_summary.md` |

The path classification CSV parses 251 report paths: 207 `OSC_FAST_REAL`, 40
`OSC_SLOW_REAL`, and 4 `CLK_SYS_REAL`. The CSV includes paths from multiple
reports, so `timing_summary.rpt` is the authoritative source for total WNS, TNS,
and violation count.

### Timing By Family

The seven true setup violations are one repeated family:

| Family | Status | Evidence |
|---|---|---|
| `FAST_TAG_TO_PD_TS` | 7 residual setup violations, WNS -1.6 ps | startpoint `u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[5]/C` to row-local `nfast_hit_latched_reg[5]/D` |
| `PD_HIT_TO_TS_FREEZE` | no reported violation | no violating path in final timing violations |
| `LOCAL_FAST_TAG_SELF` | no reported violation | no violating path in final timing violations |
| `SLOW_JOHNSON_SELF` | clean, slow WNS 448.8 ps | `clk_osc_slow` group |
| `CLK_SYS_DRAIN` | clean inside `clk_sys`, WNS 13.0 ps | `clk_sys` group |
| `CLK_SYS_WATCHDOG` | no reported violation | no violating path in final timing violations |
| `OTHER` | no unknown timing paths | `UNKNOWN_REVIEW_REQUIRED` count 0 |

The failing endpoint set is:

- `u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D`
- `u_core_gen_pd_row[6].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D`
- `u_core_gen_pd_row[5].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D`
- `u_core_gen_pd_row[4].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D`
- `u_core_gen_pd_row[2].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D`
- `u_core_gen_pd_row[1].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D`
- `u_core_gen_pd_row[0].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D`

All seven launch from `u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[5]/C`.
The path requires 1055 ps after setup and uncertainty, and the data path reports
1056 ps. The repeated path structure is:

| Element | Cell | Fanout | Load | Transition | Delay |
|---|---|---:|---:|---:|---:|
| Launch flop Q | `DFRRQHDX1` | 3 | 49.3 fF | 216 ps | 653 ps C->Q |
| Optimizer buffer | `BUHDX8` | 9 | 118.0 fF | 81 ps | 229 ps |
| PD-local inverter | `INHDX2` | 1 | 13.4 fF | 64 ps | 72 ps |
| PD-local gate | `ON22HDX1` | 1 | 9.3 fF | 119 ps | 102 ps |
| Capture flop | `DFRHDX2` | 1 | - | - | endpoint |

This looks like a very small residual closure/optimization issue in the
fast-tag-to-PD timestamp path, not a broad architecture failure.

## DRV And QoR

| Item | Value |
|---|---:|
| Max transition violations | 1120 |
| Worst transition | 511 ps against 500 ps max |
| Max capacitance violations | 0 |
| Max fanout violations | 0 |
| High fanout threshold report | 325 nets at fanout >= 20 |
| Worst high fanout | `clk_sys`, fanout 4859 |
| Fast phase fanout | `u_core_fast_phase[0]` fanout 89, taps 1-7 fanout 87 |
| Slow phase fanout | `u_core_slow_phase[0]` fanout 73 |
| Cell count | 17216 |
| Cell area | 495908.241 |
| Net area | 241729.647 |
| Total area | 737637.888 |
| Total power estimate | 154445317.988 nW |
| Genus peak memory | 2293.04 |

The max transition violations are small in magnitude but numerous. This is not
DRV clean. It may be reasonable for a placement-aware next step only after the
remaining timing and characterization evidence are handled, but it should not be
called a clean Innovus handoff yet.

## Structure Checks

| Check | Result |
|---|---:|
| `RO_tune4` instances | 2 |
| `RO_tune4/S` clocks found | 16 |
| Old `mptdc_osc_stub` residue | 0 |
| Old fast-counter residue | 0 |
| Old slow-counter residue | 0 |
| Fast-tag reference count | 59 |
| PD cells | 64 in manual CDC audit |
| Intentional frontend latches | 7 |
| Context drain synchronizer cells | 4 |
| Hit capture bridge cells | 530 |

The packet-related logic remains present in the drain path, and the O9 summary
states `fixed_raw_features_v2_7` is unchanged. No evidence of packet widening
was found in the final summary or characterization manifest.

## Clock Checks

The final `report_clocks.rpt` shows the intended O9 clocks:

- `clk_osc_fast` and taps: 1.333 ns period, tap offsets 74/148/.../518 ps.
- `clk_osc_slow` and taps: 1.430 ns period, tap offsets 79/158/.../553 ps.
- `clk_sys`: 6.250 ns period, 160 MHz.
- 16 explicit `RO_tune4/S[0:7]` clocks are attached.
- No stale nominal 0.900 ns or 1.000 ns oscillator clocks are present in the
  final clock report.
- `report_clocks_generated.rpt` reports no generated clocks.

`report_exceptions.rpt` could not be generated because the Genus commands used
there were unavailable in this installation. `report_clock_groups.rpt` contains
no useful clock-group content. Those are reporting limitations, not evidence of
clean exception signoff.

## Review Decision From Genus Alone

Genus status: `O9_TYPICAL_GENUS_NEAR_CLEAN_RESIDUAL_FAST_TAG`,
`NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`.

The O9 R750 delta5 timing move did what it was supposed to do: the previous
hundreds-of-ps `OSC_FAST_REAL` miss is reduced to a 7-path, -1.6 ps residual in
one local fast-tag-to-PD family. However, final Genus is still technically
violating and has many max-transition DRVs. This is a strong candidate, not a
closed signoff result.

