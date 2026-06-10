# Oscillator Macro Contract

Status: signoff blocker until real macro views exist.

The current Genus run uses placeholder oscillator stubs and black-box timing
data. Timing closure cannot be claimed for the Vernier fabric until slow and
fast oscillator macros have reviewed Liberty/LEF contracts.

## Required Slow-Oscillator Data

- macro pins: enable/start, control, reset/test if any, phase taps, supplies
- nominal period
- PVT min/max period
- tap-to-tap delay min/max
- phase order and monotonicity
- startup behavior and first-valid-cycle behavior
- output transition min/max
- max load per tap
- jitter and uncertainty budget
- duty-cycle range
- pin placement and physical orientation
- obstructions and routing keepouts

## Required Fast-Oscillator Data

- macro pins: enable/stop, control, reset/test if any, phase taps, supplies
- nominal period
- PVT min/max period
- tap-to-tap delay min/max
- phase order and monotonicity
- startup behavior and first-valid-cycle behavior
- output transition min/max
- max load per tap
- jitter and uncertainty budget
- duty-cycle range
- pin placement and physical orientation
- obstructions and routing keepouts

## SDC Representation

Until real macro views exist, tap clocks are placeholders used to keep the
measurement fabric visible to reports. They are not proof that the Vernier tap
mesh is signoff-realistic.

Paths inside the oscillator/PD measurement fabric must be reviewed as one of:

- true macro-timed paths covered by Liberty/LEF
- intentionally asynchronous/event paths covered by waiver and physical bounds
- RTL architecture issues requiring explicit user approval before changing

Ordinary backend retiming must not be applied inside PD cells, oscillator taps,
or Vernier-sensitive paths.
