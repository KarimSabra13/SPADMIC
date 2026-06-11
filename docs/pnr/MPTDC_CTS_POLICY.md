# MPTDC CTS Policy

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

## CTS Scope

Run CTS only for:

```text
clk_sys
```

Exclude and audit:

- raw RO clocks
- `clk_osc_slow`
- `clk_osc_fast`
- `clk_osc_*_buf_tap*`
- any buffered phase clocks derived from RO taps

## Rationale

The RO clocks and buffered phase clocks are measurement fabric. Treating them
as ordinary CTS-managed clocks would change the physical interpretation of the
Vernier/phase fabric and could hide the load and symmetry problem the prototype
is meant to measure.

## Required Evidence

- `clk_sys` clock-tree summary
- list of excluded RO and buffered phase clocks
- report showing no CTS buffers inserted on excluded clocks
- post-CTS timing separated by `clk_sys`, RO/phase, IO, and reset classes
