# O1 Macro Binding Audit

Review date: 2026-05-28

## Current RTL Binding

RTL oscillator wrapper:

- File: `MPTDC/rtl/osc/mptdc_osc_wrapper.sv`
- Module: `mptdc_osc_wrapper`
- Parameters: `NE`, `TS_STEP_PS`
- Ports: `en`, `rst_n`, `trim_i`, `phase[NE-1:0]`, `phase0_guard_o`, `phase7d_probe_o`

Synthesis implementation inside wrapper:

- File: `MPTDC/rtl/osc/mptdc_osc_stub.sv`
- Module: `mptdc_osc_stub`
- Ports: `en`, `rst_n`, `phase[NE-1:0]`, `phase0_guard_o`, `phase7d_probe_o`
- Attributes: `keep_hierarchy`, `dont_touch`, `preserve`

Top/core instances:

- slow wrapper: `u_core/u_osc_slow`
- fast wrapper: `u_core/u_osc_fast`
- O0 Genus mapped slow child: `u_core_u_osc_slow_u_stub`
- O0 Genus mapped fast child: `u_core_u_osc_fast_u_stub`

O0 Genus area masters:

- slow: `mptdc_osc_stub_NE8`
- fast: `mptdc_osc_stub_NE8_1252`

## Real Macro Identity

Analog abstract identity from Virtuoso:

- Library: `SPADMIC`
- Cell: `RO_tune4`
- View: `abstract`
- Expected LEF macro name: unknown until exported, but likely `RO_tune4`.

The real LEF macro name must be parsed from `RO_tune4_real_abstract.lef` after `server_export_ro_tune4_lef.sh` runs.

## Known Mismatch

The current post-synthesis netlist is not expected to instantiate `RO_tune4`. It instantiates synthesized logic derived from `mptdc_osc_stub`.

This means loading `RO_tune4` LEF alone is insufficient. Innovus cannot place a hard `RO_tune4` macro unless the netlist has a matching master or a documented mapping/alias is applied.

## Pin Compatibility Unknowns

Current synthesis stub pins:

- input `en`
- input `rst_n`
- output bus `phase[0:7]`
- output `phase0_guard_o`
- output `phase7d_probe_o`

O0 provisional analog-shell pins:

- input `start_i` or `stop_i`
- input `rst_n`
- input `test_i`
- input bus `ctrl_i[0:7]`
- output bus `phase_o[0:7]`
- supply pins `VDDA`, `VSSA`

Real `RO_tune4` pins are unknown until LEF export. They may use bus naming such as `phase<0>`, `S<0>`, `slow_phase[0]`, or another analog convention.

## Slow/Fast Use

Assumption to prove with analog designer:

- slow and fast oscillator instances are both `RO_tune4` geometry;
- slow/fast differ only by tune code or control pins;
- pin order and drive strength are identical for both tuned instances.

If slow and fast require different physical abstracts, O1A must stop for human/analog decision.

## Preferred Fix Path

Do not randomly rename RTL.

Preferred sequence after real LEF pin summary is available:

1. create a synthesis-only blackbox macro wrapper whose module/cell name and pins match the real `RO_tune4` LEF;
2. adapt `mptdc_osc_wrapper` with a guarded synthesis macro-binding mode only after pin compatibility is proven;
3. keep simulation using `mptdc_osc_model` and keep normal Verilator smoke tests unchanged;
4. if separate slow/fast logical masters are required, generate controlled LEF aliases only after proving the two macro geometries and pins are identical.

## O1A Script Behavior

The O1A Genus/Innovus wrappers require a real LEF file. They do not enable O0 provisional LEF.

If the real LEF exists but current netlist does not instantiate `RO_tune4`, the wrappers write a blocking summary instead of pretending that real macro binding occurred.
