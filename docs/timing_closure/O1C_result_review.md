# O1C Genus Result Review

Date: 2026-06-01

Reviewed run:

```text
results/genus_osc_pd/20260528_o1c_macro_binding_genus
```

## Binding Status

O1C achieved the macro-binding objective at Genus level:

- `RO_tune4` instance count: 2
- old `mptdc_osc_stub` residue count: 0
- reset-like `rstb` connection count: 0
- `report_clocks` matches on `RO_tune4/S[0:7]`: 16
- status reported by the wrapper: `O1C_ARCH_VALID_BINDING_CANDIDATE`

This is still not final oscillator signoff.  The physical abstract is real, but
the Liberty is a shell.  Startup behavior, jitter, extracted tap delays, output
slew, and max load per tap still need analog data.

## Timing Summary

Top O1C timing groups:

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_fast_tap2` | -3044.9 | -187711.1 | 72 |
| `clk_osc_fast_tap3` | -3037.9 | -186622.2 | 72 |
| `clk_osc_fast_tap1` | -3024.0 | -185935.2 | 72 |
| `clk_osc_fast` | -2742.9 | -201092.8 | 94 |
| `clk_osc_slow` | -2613.1 | -50264.2 | 22 |
| `clk_sys` | -598.9 | -31436.5 | 74 |

Total TNS was `-1567440.3 ps` over `694` violating paths.

## Path Classification

The O1C classifier reported:

| Classification | Paths |
|---|---:|
| `OSC_FAST_REAL` | 280 |
| `CLK_SYS_REAL` | 74 |
| `OSC_SLOW_REAL` | 14 |
| `UNKNOWN_REVIEW_REQUIRED` | 0 |

The dominant real path class is:

```text
fast counter bin_q_reg[*]
  -> PD matrix nfast_hit_latched_reg[*]
```

Representative worst endpoint:

```text
u_core_u_fast_cnt/bin_q_reg[4]/C
  -> u_core_gen_pd_row[7].gen_pd_col[2].u_pd/nfast_hit_latched_reg[4]/D
```

This is not the intentional Vernier slow-to-fast sampling relation.  It is the
fast coarse count bus being sampled into PD cells on fast tap clocks.

## Constraint/Script Issues Found

The O1C run exited successfully, but the log still contained Tcl/SDC issues in
the O1C overlay.  The root cause is bracketed net patterns such as `S[0]` and
`phase[0]` being constructed inside Tcl double-quoted strings.  Tcl can
interpret bracket content as a command.

The O1C overlay also used `group_path` on broad cell collections for reporting
only.  That generated invalid/no-effect timing endpoint noise.  O1C2 removes
those report-only groups and keeps grouping in report scripts instead.

## Physical/Linearity Risk Exposed

The high-fanout report shows fast tap load asymmetry:

```text
fast_phase[0] fanout: 111
fast_phase[1:7] fanout: 80 each
```

This is probably because phase0 also drives the fast counter.  That is a
linearity and tap-load matching concern.  Do not add an ordinary buffer only to
phase0.  Preferred fixes remain analog-approved separate outputs or matched
loading/buffering across all taps.

## Decision

Do not run Innovus yet.  Do not run R800 yet.  The next expensive server run
should be one focused O1C2 Genus run that:

1. fixes the O1C SDC Tcl bracket issue;
2. removes invalid report-only `group_path` commands;
3. emits a focused `timing_fast_count_to_nfast_hit.rpt`;
4. emits endpoint bucket counts for `nfast_hit_latched`;
5. parses fast-count capture timing by tap, row, and bit;
6. keeps all real fast-count paths visible, with no broad false paths.
