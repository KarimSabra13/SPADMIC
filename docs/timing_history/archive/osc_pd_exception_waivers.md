# Oscillator/PD Exception Waivers

Status: DRAFT - not signoff approved.

Every exception below must be correlated with Genus/Innovus reports and analog
or calibration evidence before final signoff.

## PD Slow-To-Fast Vernier Sampling

Path: `slow_phase[ns]` data sampled by `fast_phase[nf]` in `mptdc_pd_cell`

Source: slow oscillator tap

Destination: PD fast-clocked sampling flops

Why it is not ordinary STA: this is the Vernier measurement relation.
Conventional setup/hold closure would remove the timing information being
measured.

Replacement evidence:

- symmetric PD placement report
- slow and fast phase-route RC/load balance report
- analog oscillator tap mismatch and jitter report
- calibration/DNL/INL evidence

Residual risk: high until real macro views and extracted RC are available.

## Fast Counter To nfast_hit

Path: `u_fast_cnt` / `nfast_src_count` to PD `nfast_hit` capture flops

Source: fast coarse counter, clocked by `fast_phase[0]`

Destination: PD cells clocked by `fast_phase[nf]`

Why it is not waived by default: this is potentially real high-speed logic.

Replacement evidence if waived: explicit generated-clock phase relation,
controlled bus skew/RC, and proof that captured count is stable at all PD
sampling phases.  Until then classify as `OSC_FAST_REAL`.

Residual risk: medium/high.

## PD Async Clear

Path: `meas_pd_clear` to PD clear pins and gray-counter async clears

Source: clk_sys teardown/control

Destination: PD and oscillator-domain async clear pins

Why it is not ordinary STA: clear is asserted only after snapshot/context
capture is protected and oscillator fabric is tearing down.

Replacement evidence:

- capture-before-clear assertions/tests
- recovery/removal review
- Xcelium async-edge stress on server when available
- no active conversion is overwritten before snapshot/context storage

Residual risk: medium until recovery/removal review is complete.

## Held Bus Into clk_sys Bridge

Path: frozen PD/counter/STOP metadata image into `mptdc_hit_capture_bridge`

Source: oscillator/event-domain held levels

Destination: clk_sys snapshot flops

Why it is not a bit synchronizer: the source image is held stable and sampled as
a coherent static bus before source clear.

Replacement evidence:

- `mptdc_hit_capture_bridge` Verilator tests
- measurement controller sample-before-clear tests
- SDC bounded max-delay on STOP metadata into bridge
- Xcelium directed/random stress when available

Residual risk: low/medium, dependent on source hold protocol and physical bus
bounding.
