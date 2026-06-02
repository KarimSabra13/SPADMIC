# O5 Oscillator PVT Timing Model Audit

Branch: `SPADMIC_localtag`

Latest evidence: O4 R600 closure, `results/genus_osc_pd/20260602_o4_muxless_tags_r600_o4_r600_closure`

## Current SDC/MMMC Model

The active flow creates oscillator tap clocks in `MPTDC/syn/inputs/mptdc.sdc` using fixed values from `MPTDC/syn/inputs/mptdc.defines` or environment overrides:

- nominal slow period: `1.0 ns`
- nominal fast period: `0.9 ns`
- nominal slow tap step: `0.055 ns`
- nominal fast tap step: `0.050 ns`
- oscillator setup uncertainty: `0.050 ns`
- oscillator hold uncertainty: `0.020 ns`

O4 R600 what-if overrode these with:

- slow period: `1.667 ns`
- fast period: `1.567 ns`
- slow tap step: `0.1041875 ns`
- fast tap step: `0.0979375 ns`

The MMMC flow uses the standard-cell slow view for setup:

- operating condition in reports: `slow_1_62V_125C`
- interconnect mode: global
- oscillator clocks remain fixed period values in that view

## Modeling Risk

The current setup analysis pairs slow standard-cell timing with fixed oscillator periods. That may be pessimistic if `RO_tune4` is an open-loop oscillator whose frequency slows with the same PVT environment as the standard cells.

The current flow does not yet prove a PVT-correlated model such as:

- slow standard-cell view plus slow RO period
- fast standard-cell view plus fast RO period
- corner-specific tap spacing and jitter

Instead, it uses a single fixed oscillator period per run. Therefore, O5 must not conclude that the standard-cell PD is fundamentally impossible until the oscillator PVT model is clarified.

## What The Current Evidence Still Shows

Even with the modeling risk, the R600 closure report is useful because it identifies the structural path:

- `hit_latched_reg -> nfast_hit_latched_reg[*]`
- resettable flops plus data freeze mux/control
- 1062 ps C->Q, 640 ps setup, and roughly 1.1 ns logic on the representative path

So O5 should improve the implementation style first, while also asking analog for a real correlated timing model.

## Required Analog Inputs

For each `RO_tune4` mode, analog should provide:

- nominal slow and fast periods
- slow-corner slow and fast periods
- fast-corner slow and fast periods
- tap spacing per corner
- jitter or clock uncertainty per corner
- tune code per corner if the oscillator is tuned open loop
- whether the frequency is open-loop, calibrated, or regulated
- max load used for S[0:7] characterization
- startup delay and valid-edge behavior after `rstb` rises

## Signoff Principle

If the oscillator is open-loop and built in the same PVT environment, final STA should not blindly use:

`slow standard cells + fastest/nominal oscillator`

unless the system specification requires the RO to run at that period under the slow-cell PVT condition.

The preferred final model is correlated:

- slow cells with slow RO period and slow tap spacing
- typical cells with typical RO period and typical tap spacing
- fast cells with fast RO period and fast tap spacing

## O5 What-If Plan

O5 nominal/no-frequency-reduction runs should use the current fixed nominal oscillator clocks so the result is directly comparable with O4.

Optional `O5_PVT_AWARE` is prepared only if real analog PVT period/tap data is available through:

- `O5_PVT_SLOW_PERIOD_NS`
- `O5_PVT_FAST_PERIOD_NS`
- `O5_PVT_SLOW_TAP_STEP_NS`
- `O5_PVT_FAST_TAP_STEP_NS`

Without those values, O5 should skip the PVT-aware mode rather than inventing analog data.
