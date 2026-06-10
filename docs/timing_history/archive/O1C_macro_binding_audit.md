# O1C Macro Binding Audit

Date: 2026-05-28
Branch: SPADMIC_TOP
Base HEAD reviewed: `d8c8cc464d1015c856b8971886fb0d7d87485988`

## O1A Genus Status

O1A Genus completed, but real macro binding failed.

Evidence:

- Result directory: `results/genus_osc_pd/20260528_o1a_real_abstract_nominal_genus/`
- O1A summary status: `O1A_REAL_ABSTRACT_BINDING=FAILED`
- Binding reason: post-synthesis netlist does not bind to `RO_tune4`
- Post-synthesis masters still present:
  - `mptdc_osc_stub_NE8`
  - `mptdc_osc_stub_NE8_1252`
- No `RO_tune4` instances were present in the O1A post-synthesis netlist.

O1A timing therefore remained a stub/provisional timing result, not real
RO_tune4 oscillator/PD timing.

## O1A Timing Snapshot

From `PARSED_SUMMARY.md`:

- Worst group: `clk_osc_fast_tap1`
- WNS: `-3163.0 ps`
- Total TNS: `-1583170.0 ps`
- Violating paths: `697`
- `clk_sys` WNS: `-720.4 ps`
- DRV: max transition total `256097`

Path classification:

- `OSC_FAST_REAL`: 280 paths
- `CLK_SYS_REAL`: 77 paths
- `OSC_SLOW_REAL`: 14 paths
- `UNKNOWN_REVIEW_REQUIRED`: 0 paths

Dominant conceptual blocker:

```text
fast counter -> nfast_src_count -> PD nfast_hit_latched
```

Representative O1A endpoint:

```text
u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit_latched_reg[0]/D
```

## RTL Wrapper Before O1C

The architectural oscillator wrapper is:

```text
MPTDC/rtl/osc/mptdc_osc_wrapper.sv
```

Before O1C:

- With `MPTDC_USE_OSC_MODEL`: instantiates `mptdc_osc_model`
- Otherwise: instantiates `mptdc_osc_stub`

The core instances are:

```text
u_core/u_osc_slow : mptdc_osc_wrapper
u_core/u_osc_fast : mptdc_osc_wrapper
```

Core-level enables:

```text
u_osc_slow.en <= fe_osc_slow_en
u_osc_fast.en <= fe_osc_fast_en
```

Those frontend outputs preserve the architecture:

- slow oscillator starts on START
- fast oscillator starts on STOP

## Real RO_tune4 Macro

Real physical abstract source:

```text
/group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL/RO_tune4/abstract
```

Committed exported/copied LEF:

```text
results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef
```

Real LEF macro name:

```text
RO_tune4
```

Real LEF pins:

```text
S[0:7]     output phase taps
code[0:7] input tune code
rstb       input active-high run/start control
VDD        power
VSS        ground
vdd!       power alias in analog LEF
```

New analog information:

```text
rstb = 1 -> oscillator starts/runs
rstb = 0 -> oscillator stops/is held off
```

Therefore `rstb` is not a global reset. It must map to the architectural
oscillator enable.

## O1C RTL/Synthesis Mapping

O1C adds guarded synthesis macro mode:

```text
MPTDC_USE_RO_TUNE4_MACRO
```

Required mapping in macro mode:

```text
RO_tune4.S[0:7]    -> phase[0:7]
RO_tune4.code[0:7] -> trim_i[7:0]
RO_tune4.rstb      -> en
```

Core-level O1C mapping:

```text
slow RO_tune4.rstb <= fe_osc_slow_en
fast RO_tune4.rstb <= fe_osc_fast_en
```

Current tune-code status:

```text
slow code[7:0] <= 8'h00 placeholder
fast code[7:0] <= 8'h00 placeholder
```

This is sufficient for logical binding, but not for analog timing signoff.
Nominal slow/fast tune codes still require analog confirmation.

## Binding Criteria For O1C Genus

O1C is only a valid binding candidate if Genus reports:

- exactly two `RO_tune4` instances in the post-synthesis netlist
- no `mptdc_osc_stub` residue in the post-synthesis netlist
- `rstb` is not tied to global reset
- `S[0:7]` drive the slow/fast phase nets
- generated clocks attach to `u_ro_tune4/S[0:7]`
- no unresolved macro/pin mismatch remains

O1C is not oscillator signoff. It remains:

```text
REAL PHYSICAL LEF AVAILABLE
LIBERTY SHELL ONLY
NO ANALOG STARTUP/JITTER/TAP-DELAY/SLEW SIGNOFF
```
