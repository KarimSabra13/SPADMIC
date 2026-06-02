# O3 Genus Review - Raw Epoch / PD Capture Cleanup

Run reviewed: `results/genus_osc_pd/20260601_o3_raw_epoch_cleanup_genus`

Current repository HEAD after pulling server results: `fb8210c55c01f95ec5fc795d4da39d8b543e9a5a`

Genus run HEAD: `54f361c9143fd8aea2949723ef60fe1729d94a03`

Status:

- Genus exit code: 0
- Snapshot exit code: 0
- RO_tune4 instances: 2
- old oscillator stubs: 0
- old global `u_fast_cnt` residue: 0
- old `u_slow_cnt` residue: 0
- generated clocks on `RO_tune4/S[0:7]`: 16 matches
- status label: `REAL_PHYSICAL_ABSTRACT_WITH_RAW_FAST_TAG_AND_SLOW_JOHNSON_EPOCH`

This is not timing closure and not analog oscillator signoff. `RO_tune4` still uses a Liberty shell.

## O3 Effects

Confirmed improvements:

- The old global fast counter to PD `nfast_hit_latched` path is gone.
- The old slow binary/Gray counter source is gone.
- The old fast-domain slow Gray decode is gone.
- The START watchdog binary counter is no longer in the slow oscillator domain.
- The netlist contains the intended slow Johnson epoch and local fast-tag generators.

New or remaining blockers:

- `OSC_FAST_REAL` is still dominant.
- PD `hit_latched` still feeds the D path of every `nfast_hit_latched` bit through the freeze/hold mux.
- Local fast LFSR tag generators still contain same-cycle state update/hold/reset logic that does not close at the 0.9 ns fast oscillator period.
- The slow Johnson source still contains same-cycle self/hold mux timing and does not close at the 1.0 ns slow oscillator period.
- `clk_sys` drain/readout is still around -0.85 ns.
- The clk_sys START watchdog compare path is now visible and around -0.83 ns.
- DRV max-transition count increased and remains severe.

## Timing Summary

From `PARSED_SUMMARY.md`:

| Group | WNS ps | TNS ps | Paths |
|---|---:|---:|---:|
| `clk_osc_fast` | -2084.5 | -165885.3 | 88 |
| `clk_osc_fast_tap1` | -2069.4 | -162305.3 | 87 |
| `clk_osc_fast_tap2` | -2005.1 | -160644.3 | 87 |
| `clk_osc_fast_tap3` | -2045.7 | -160951.3 | 87 |
| `clk_osc_fast_tap4` | -2069.4 | -162208.4 | 87 |
| `clk_osc_fast_tap5` | -2024.0 | -160247.7 | 87 |
| `clk_osc_fast_tap6` | -2069.4 | -162390.6 | 87 |
| `clk_osc_fast_tap7` | -2069.4 | -162740.3 | 87 |
| `clk_osc_slow` | -1296.2 | -80816.5 | 64 |
| `clk_sys` | -852.8 | -61397.9 | 233 |

Total TNS: `-1439587.6 ps`; total violating paths: `994`.

Classification from `timing_path_classification_summary.md`:

| Classification | Paths | WNS ps | TNS ps |
|---|---:|---:|---:|
| `OSC_FAST_REAL` | 400 | -2084 | -793473 |
| `OSC_SLOW_REAL` | 44 | -1296 | -55794 |
| `CLK_SYS_REAL` | 100 | -853 | -60634 |
| `UNKNOWN_REVIEW_REQUIRED` | 0 | n/a | n/a |

The classifier parsed 544 detailed paths. Aggregate timing reports list 994 total violating paths, so the detailed classifier is representative, not exhaustive.

## Root Cause Families

### 1. PD hit freeze control to captured tag bits

Representative path:

`u_core_gen_pd_row[7].gen_pd_col[0].u_pd/hit_latched_reg/C`
to
`u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit_latched_reg[4]/D`

Evidence:

- Class: `OSC_FAST_REAL`
- WNS: about `-2084 ps`
- Family count in classifier: 312 paths to `PD nfast_hit_latched`
- Data path example: DFF C->Q plus inverter/AND/NAND/ON21 mux chain, about `2290 ps`
- Required time after setup and uncertainty is only about `206 ps` for same-clock fast paths.

Cause:

O3 shadow tag capture removed q1/q2 edge detect from the tag data, but `hit_latched` still controls the freeze/hold mux for every tag bit. Genus correctly treats this as a real same-clock path: after `hit_latched` becomes 1, the tag register must hold its previous value by the next fast clock edge. With the XH018 DFF timing shell at slow corner, even local control-to-D mux timing is far beyond a 0.9 ns oscillator cycle.

Potential fixes:

1. Remove conditional freeze muxes from the PD-cell fast domain. This likely requires a measurement-fabric semantic change: capture only hit bitmap in PD cells and snapshot/derive epoch elsewhere, or use a custom PD timestamp macro.
2. Use a real characterized PD/timestamp macro or latch primitive if the analog/layout team owns that high-speed capture function.
3. Derate oscillator frequency only if analog can preserve Vernier delta and the target period exceeds DFF Cq + setup + uncertainty. R800 alone is not enough for these reported Cq/setup numbers.
4. Do not false-path this as ordinary digital timing unless the architecture changes so the path is no longer a functional data requirement.

### 2. Local fast LFSR tag generator

Representative path:

`u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[6]/C`
to
`u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[0]/D`

Evidence:

- Class: `OSC_FAST_REAL`
- WNS: about `-1992 ps`
- Family count in classifier: 63 paths
- Data path example: DFF C->Q around `1023 ps` plus buffer/NAND logic to `2130 ps`.

Cause:

The LFSR next-state/seed/enable structure is still synthesized as same-cycle fast-domain standard-cell logic. Even though it is local per column, ordinary DFF Cq + setup + small logic is too slow at the 0.9 ns fast clock.

Potential fixes:

1. Remove the explicit synchronous enable/hold mux from the fast tag generator if the oscillator clock is already stopped by `RO_tune4.rstb` outside the measurement window.
2. If a tag must advance every fast edge, use a simpler ring/Johnson/one-hot style with no XOR feedback and no enable mux.
3. If even a shift-only local tag fails, the conclusion is that ordinary synthesized fast-domain registers cannot be used at nominal oscillator speed.

### 3. Slow Johnson epoch source

Representative path:

`u_core_u_slow_epoch_johnson_o_reg[49]/C`
to
`u_core_u_slow_epoch_johnson_o_reg[49]/D`

Evidence:

- Class: `OSC_SLOW_REAL`
- WNS: about `-1296 ps`
- Family count in classifier: 44 detailed paths
- Data path example: DFF C->Q about `999 ps`, inverter/mux to `1556 ps`, required time about `259 ps`.

Cause:

O3 removed the old binary/Gray counter, which was the right architectural direction. The remaining Johnson implementation still has enable/hold/reset mux logic in the slow oscillator domain. Genus reports self/hold-style paths because the register can hold state when enable is false.

Potential fixes:

1. Remove the slow-domain enable/hold mux. Since the slow oscillator itself is enabled/stopped by `rstb`, the Johnson source can advance on every slow clock edge and reset/clear to zero.
2. If clear mux/reset fanout remains too slow, use asynchronous clear only and keep D path as pure shift/inverted-feedback.
3. Do not decode Johnson in slow or fast oscillator domains.

### 4. clk_sys drain/readout build path

Representative path:

`u_core_u_drain_ctrl_drain_ctx_q_reg[0]/C`
to
`u_core_u_drain_ctrl_emit_wr_data_q_reg[hit][nfast][1]/D`

Evidence:

- Class: `CLK_SYS_REAL`
- WNS: about `-853 ps`
- Family count: 43 paths to `emit_wr_data_q`, plus smaller scan/control families.
- Data path example includes about 18 logic stages from `drain_ctx_q` to HIT record build.

Cause:

Even with `ST_D_EMIT`, `drain_ctx_q`, scan selection, context selection, hit field extraction, and record packing still feed a wide packet register in one `clk_sys` cycle.

Potential fixes:

1. Add a real `ST_D_BUILD` stage between scan/select and emit.
2. Register selected hit fields (`ns`, `nf`, raw tag, flags, event seq) before building `emit_wr_data_q`.
3. Keep packet layout and scan order unchanged.

### 5. clk_sys START watchdog compare path

Representative path:

`u_csr_r_wdt_ctx_timeout_reg[6]/C`
to
`u_core_start_wdt_cnt_reg[9]/D`

Evidence:

- Class: `CLK_SYS_REAL`
- WNS: about `-831 ps`
- Family count: 16 paths to watchdog.
- The path is now in `clk_sys`, which is the correct domain, but the comparison against programmable `cfg_i.wdt_ctx_timeout` is wide and combinational.

Cause:

The O3 migration correctly removed the watchdog from `slow_phase[0]`. The new clk_sys implementation uses a programmable compare in the counter update path.

Potential fixes:

1. Register the watchdog limit on arm/start and compare against the registered limit.
2. Prefer a countdown counter loaded with the timeout value, then test zero. This removes a wide `>= limit - 1` compare from the update path.
3. If watchdog precision does not need programmability at full width, clamp or predecode the limit in CSR/arm state.

## DRV and Intent

Design rules:

- Max-transition violations: `287264`
- This worsened from the O2 parsed summary (`218008`).
- High fanout remains severe: `clk_sys` fanout `4858`, fast phase taps around `87-89`, slow phase0 `73`, stop epoch clear/reset net `132`.

Timing intent:

- Sequential data pins driven by clock signal: `70`, mostly intentional PD slow-phase sampling and STOP metadata.
- Sequential clock pins without waveform: `78`, largely async/frontend/STOP capture pins reported as disabled timing.
- Timing exceptions with no effect: `10`.
- Exception report command is not usable in this Genus build; `report_exceptions` fails.

Reporting issue:

- `timing_pd_capture_hotspots.rpt` failed to generate.
- The O3 summary reported `PD q/hit_latched to nfast timing text count: 0`, but the classifier shows many `hit_latched -> nfast_hit_latched` paths. The grep checker is too weak because the startpoint and endpoint are on separate timing-report lines.

## Current Decision

Do not run Innovus yet.

Reason:

The remaining dominant blockers are not placement-only. The reports show that ordinary synthesized DFF-to-DFF timing in oscillator domains is still infeasible at 0.9 ns/1.0 ns with the current standard-cell Liberty. Innovus cannot fix a 2.0 ns data path against a roughly 0.2 ns post-setup required time.

Do not run R800 yet.

Reason:

R800 is not enough by itself. The reported Cq + setup + uncertainty for simple same-clock paths can exceed 1.6 ns before meaningful logic. R800 slow period is 1.25 ns, and analog Vernier delta is still not confirmed.

Recommended next patch:

O4_FAST_DOMAIN_NO_HOLD_MUX_EXPERIMENT

Scope:

1. Remove enable/hold muxes from local fast tag generators and slow Johnson source by relying on oscillator `rstb` to stop clocks outside the active window.
2. Simplify or replace the fast tag sequence with a shift/Johnson style if LFSR XOR feedback remains too slow.
3. Decide whether PD-cell timestamp freeze can remain in synthesized standard-cell logic. Current evidence says no; if nfast timestamp must freeze at hit, this likely needs either a custom timestamp/PD macro or a changed raw-data architecture.
4. Add missing report checks so `hit_latched -> nfast_hit_latched` is explicitly counted.
5. Pipeline clk_sys drain and watchdog only after oscillator-domain feasibility is resolved, or include them as low-risk clk_sys fixes if one more Genus run is planned.

