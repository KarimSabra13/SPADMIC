# O1B R800 Derate Plan

Work package: `O1_real_abstract_and_R800_derate`
Sub-experiment: `O1B_real_abstract_R800`

Status target for current scripts: `REAL_PHYSICAL_ABSTRACT + R800 WHAT-IF, NOT CALIBRATION-SAFE UNTIL ANALOG CONFIRMS DELTA`

## Purpose

O1B evaluates whether oscillator frequency derating around 800 MHz slow can reduce real fast-domain timing pressure after O1A real abstract binding is understood.

O1B must compare against O1A, not directly against O0. O0 uses provisional macro geometry and is not a fair physical/timing baseline for a frequency-mode decision.

## Non-Negotiable Measurement Rule

The primary delta to preserve is the Vernier tap delta:

`delta_tap = slow_tap_phase_step - fast_tap_phase_step`

Current nominal notes:

- slow tap delay: 55 ps
- fast tap delay: 50 ps
- Vernier tap step: 5 ps
- nominal exported LSB note: 10 ps

The current SDC model uses:

- slow oscillator period: 1.000 ns
- fast oscillator period: 0.900 ns
- slow tap phase step: 0.055 ns
- fast tap phase step: 0.050 ns

## Frequency Modes

### nominal

- slow period: current nominal
- fast period: current nominal
- slow tap step: current nominal
- fast tap step: current nominal
- status: current baseline

### r800_period_delta_whatif

- slow period: 1.250 ns
- fast period: 1.150 ns
- preserves old oscillator-period separation of 0.100 ns
- keeps current tap steps unless analog data overrides them
- status: STA/PnR WHAT-IF ONLY

This mode does not prove Vernier delta preservation. It is a timing experiment only.

### r800_vernier_delta_preferred

- slow period: around 1.250 ns
- fast period: from analog tune code
- slow tap step: from extracted analog data
- fast tap step: from extracted analog data
- required `slow_tap_step - fast_tap_step = 0.005 ns`
- status: blocked until analog tune table

## Required Analog Data

Ask the analog designer for:

- tune code for slow around 800 MHz;
- tune code for fast paired with it;
- extracted slow tap delay per tap;
- extracted fast tap delay per tap;
- delta tap over PVT;
- output slew under extracted PD load;
- jitter under extracted PD load;
- startup time;
- max allowed tap load;
- whether the same `RO_tune4` abstract is used for slow and fast;
- whether two differently tuned instances have identical pin order and drive strength.

## Digital Checks

O1B must not alter:

- packet schema;
- raw calibration field meanings;
- `ns`, `nf`, `nfast_hit`, `nslow`, `phase0_snap`, `stop_slow_phase_disc`, `slow_boundary_inc`;
- `hit_count`, flags, `ctx_id`, `conv_id`;
- capture-before-clear ordering.

The current O1B SDC/defines only change timing variables for STA/PnR. They do not change RTL behavior.

The R800 Xcelium wrapper is intentionally conservative: it will not claim an R800 behavioral regression unless a calibration-safe behavioral model/tune mode exists. Without that, it records a blocked result.

## Decision Rules

Proceed with R800 only if one of these is true:

- O1A shows real fast-domain timing pressure after real macro binding;
- extracted analog tap loads/slews violate nominal capability;
- analog PVT simulations show insufficient nominal margin;
- fast counter to `nfast_hit` paths remain a true timing blocker and derating is the cleanest reversible experiment.

Reject or block R800 if:

- the 5 ps Vernier tap delta cannot be preserved;
- raw field meanings change;
- watchdog or `nfast_hit` range becomes invalid;
- analog tune-code data is missing for final calibration use.
