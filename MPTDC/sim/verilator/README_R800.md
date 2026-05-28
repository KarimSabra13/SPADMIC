# R800 Verilator Notes

O1B R800 currently changes STA/PnR frequency variables only through:

- `MPTDC/syn/inputs/mptdc_freq_modes.defines`
- `MPTDC/syn/inputs/mptdc_osc_pd_r800.sdc`

No RTL packet field, calibration field, or oscillator behavioral-model parameter has been changed in this collateral commit.

The existing Verilator smoke flow remains the local check for syntax and backend behavior. It does not prove R800 analog timing, oscillator startup, jitter, or tap delay.

Before claiming an R800 simulation regression, one of these must exist:

- analog-confirmed tune constants wired into a guarded behavioral-model compile mode; or
- an Xcelium/server testbench that can parameterize the oscillator model without changing packet semantics.

Until then, the R800 Xcelium wrapper records a blocked/what-if status rather than claiming calibration-safe simulation coverage.
