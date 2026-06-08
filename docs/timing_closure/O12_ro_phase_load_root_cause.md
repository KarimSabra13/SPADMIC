# O12 RO Phase Load Root Cause

Status: `O12_PHASE_ISOLATION_BUFFER_EXPERIMENT`

This is a feasibility/debug document, not final signoff.

## Analog Load Budget

Edouard's RO output buffer feedback gives two useful load limits:

| Budget | Load |
|---|---:|
| strict D-input load | 58.72 fF |
| heavier CN/clock-like input estimate | 75.59 fF |

The current production RO shell still uses `max_capacitance : 0.050` pF on
`RO_tune4/S`, so the checked-in Liberty limit is near the strict analog budget.
The O12 work must not silently relax that shell to hide a physical load problem.

## Measured O11 Loads

Source run: `results/innovus/20260608_o11_ro_load_analysis2`

| Family | Tap | Net | Fanout | Cap | Strict Ratio | CN Ratio | Status |
|---|---:|---|---:|---:|---:|---:|---|
| slow | S[0] | `u_core_slow_phase[0]` | 73 | 508 fF | 8.65x | 6.72x | CRITICAL |
| slow | S[1] | `u_core_slow_phase[1]` | 1 | unknown | unknown | unknown | not in max-cap report |
| slow | S[2] | `u_core_slow_phase[2]` | 1 | unknown | unknown | unknown | not in max-cap report |
| slow | S[3] | `u_core_slow_phase[3]` | 1 | unknown | unknown | unknown | not in max-cap report |
| slow | S[4] | `u_core_slow_phase[4]` | 1 | unknown | unknown | unknown | not in max-cap report |
| slow | S[5] | `u_core_slow_phase[5]` | 1 | unknown | unknown | unknown | not in max-cap report |
| slow | S[6] | `u_core_slow_phase[6]` | 1 | unknown | unknown | unknown | not in max-cap report |
| slow | S[7] | `u_core_slow_phase[7]` | 1 | unknown | unknown | unknown | not in max-cap report |
| fast | S[0] | `u_core_fast_phase[0]` | 89 | 653 fF | 11.12x | 8.64x | CRITICAL |
| fast | S[1] | `u_core_fast_phase[1]` | 87 | 643 fF | 10.95x | 8.51x | CRITICAL |
| fast | S[2] | `u_core_fast_phase[2]` | 87 | 569 fF | 9.69x | 7.53x | CRITICAL |
| fast | S[3] | `u_core_fast_phase[3]` | 87 | 614 fF | 10.46x | 8.12x | CRITICAL |
| fast | S[4] | `u_core_fast_phase[4]` | 87 | 718 fF | 12.23x | 9.50x | CRITICAL |
| fast | S[5] | `u_core_fast_phase[5]` | 87 | 696 fF | 11.85x | 9.21x | CRITICAL |
| fast | S[6] | `u_core_fast_phase[6]` | 87 | 665 fF | 11.32x | 8.80x | CRITICAL |
| fast | S[7] | `u_core_fast_phase[7]` | 87 | 652 fF | 11.10x | 8.63x | CRITICAL |

The seven slow fanout-1 taps are not proven OK by O11; they simply did not
appear in the max-cap violation report.  The physical blocker is the nine
measured CRITICAL source pins.

## Why Fast Fanout Is High

Each fast tap is a column clock.  It drives:

- eight PD cells in the corresponding fast column;
- multiple flops per PD cell, including `q1`, `q2`, `hit_latched`, and the local
  `nfast_hit_latched` timestamp shadow flops;
- the local fast tag generator for that column;
- reset/synchronizer loads on fast phase0.

This creates 87 to 89 loads per fast RO output tap.  The measured 569-718 fF
loads are therefore not an SDC artifact; they are the physical result of asking
an analog RO output to directly drive a digital clock distribution fabric.

## Why Slow S[0] Is High

Slow phase0 drives the slow epoch and boundary/metadata fabric:

- `mptdc_slow_epoch_johnson` raw epoch state;
- STOP-side phase0 snapshot metadata;
- slow boundary increment support;
- phase guard/probe metadata.

O11 measured `slow S[0]` at 508 fF, 8.65x over the strict D-load budget.

## Why It Matters

Excess direct RO output load affects:

- RO frequency and startup behavior;
- edge slew and max-cap design-rule quality;
- jitter and deterministic phase noise;
- Vernier tap spacing and monotonicity;
- phase linearity and calibration stability;
- dynamic power in the oscillator and digital phase fabric.

## Conclusion

The direct RO-to-digital fabric connection is too heavy.  The O12 experiment
inserts a matched phase-isolation buffer bank so each `RO_tune4/S[n]` directly
drives only one local buffer input.  The existing PD matrix, fast tags, slow
epoch, and metadata then use the buffered phase nets.
