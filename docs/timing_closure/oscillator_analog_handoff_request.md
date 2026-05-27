# Oscillator Analog Handoff Request

Status: REQUIRED BEFORE SIGNOFF

The Virtuoso screenshot showing approximately 613 fs RMS after 45 START/STOP
events is treated as one useful simulation datapoint only.  It is not PVT,
extracted, load, startup, jitter, or phase-order signoff.

Please provide structured data for both slow and fast oscillators.

## Required Views

- Final or provisional LEF with pin geometry and obstructions
- Liberty timing/power shell, or an explicit statement that the oscillator is
  timing-modeled only through SDC clocks and physical RC reports
- Extracted-layout simulation summary
- PVT corner table
- Tune-code/frequency table

## Required Fields Per Oscillator

- macro name
- nominal supply
- legal orientation
- layout width and height
- pin names
- pin order
- pin side
- pin coordinates
- pin metal layer
- pin shape
- VDD/VSS or VDDA/VSSA pins
- internal obstructions
- keepout margin
- max load per tap
- load used in analog simulation
- output high/low levels
- output slew per tap
- duty cycle per tap
- period per tap
- tap-to-tap delay
- tap-to-tap mismatch
- cycle-to-cycle jitter
- accumulated jitter after startup
- startup delay from enable
- first-edge behavior
- enable-to-oscillation behavior
- disable behavior
- reset behavior
- PVT corners simulated
- extracted vs schematic-only status
- tune-code table
- slow/fast tune-code pair used for current nominal
- tune-code pair options for frequency derating

## Machine-Readable Templates

- `MPTDC/analog_handoff/oscillator_macro_contract.yaml`
- `MPTDC/analog_handoff/slow_osc_pins.csv`
- `MPTDC/analog_handoff/fast_osc_pins.csv`
- `MPTDC/analog_handoff/oscillator_sim_summary.csv`

If exact pin coordinates are not yet available, keep the coordinate fields blank
and mark the row as `PROVISIONAL - NOT ANALOG VERIFIED`.

## Phase0 Load Question

Please explicitly answer whether extra phase0 loads are allowed.  Current
digital use may add phase0 load for counters and metadata:

- `slow_phase[0]` drives slow coarse/watchdog-related logic and STOP metadata
- `fast_phase[0]` drives the fast coarse counter and reset synchronizer clock
- all taps drive PD matrix loads

Preferred analog solution: provide separately characterized buffered outputs
for PD and counter/metadata use, for example `slow_phase0_pd`,
`slow_phase0_cnt`, `fast_phase0_pd`, and `fast_phase0_cnt`.

Do not approve one-off ordinary digital buffering on phase0 unless an
analog-approved symmetric structure is applied to all sibling taps.
