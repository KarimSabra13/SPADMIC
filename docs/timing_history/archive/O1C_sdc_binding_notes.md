# O1C SDC Binding Notes

Date: 2026-05-28

## Goal

Attach oscillator tap clocks to real `RO_tune4` macro output pins in the O1C
Genus run.

Expected slow clock source pins:

```text
u_core/u_osc_slow/u_ro_tune4/S[0]
u_core/u_osc_slow/u_ro_tune4/S[1]
...
u_core/u_osc_slow/u_ro_tune4/S[7]
```

Expected fast clock source pins:

```text
u_core/u_osc_fast/u_ro_tune4/S[0]
u_core/u_osc_fast/u_ro_tune4/S[1]
...
u_core/u_osc_fast/u_ro_tune4/S[7]
```

## Implementation

`MPTDC/syn/inputs/mptdc.defines` now switches oscillator tap pin names when:

```text
MPTDC_USE_RO_TUNE4_MACRO=1
```

`MPTDC/syn/inputs/mptdc_osc_pd_o1c.sdc` is an overlay loaded after the main SDC.
It checks that the real `S[0:7]` pins are visible, applies provisional
transition/capacitance bounds to phase nets, and creates report groups.

## No New Timing Hiding

O1C does not add broad false paths.

Still timed normally:

- `clk_sys` backend paths
- fast counter internal paths
- fast counter to `nfast_hit` paths
- ordinary slow-domain paths, if present

Still separately reviewed:

- intentional Vernier slow-to-fast PD sampling
- held-bus CDC into `mptdc_hit_capture_bridge`
- async START/STOP capture
- PD/counter async clear and recovery/removal protocol

## Required Genus Evidence

O1C Genus must prove:

- `report_clocks` sees slow and fast tap clocks
- clock source pins are `RO_tune4/S[0:7]`
- old `u_stub/phase[0:7]` pins are not used as clock sources
- `clk_sys` timing remains visible
- real fast-domain paths remain visible

## O1C2 Cleanup

The first successful O1C Genus run still contained SDC/Tcl noise.  O1C2 makes
the next run more useful by:

- constructing bracketed phase-net patterns with Tcl `format`, avoiding command
  substitution on names like `S[0]` and `fast_phase[0]`;
- deriving phase nets from matched `RO_tune4/S[0:7]` pins first, then falling
  back to name patterns only if needed;
- removing report-only `group_path` commands from the SDC overlay because broad
  cell collections created invalid/no-effect endpoint noise;
- keeping all real fast-counter to `nfast_hit` timing visible;
- adding focused report scripts instead of timing exceptions.

O1C2 must report:

```text
O1C_SDC_CLEAN_STATUS=PASS
O1C_BINDING_STATUS=O1C_ARCH_VALID_BINDING_CANDIDATE
```

If `O1C_SDC_CLEAN_STATUS` is not `PASS`, do not use the timing numbers for
architecture decisions until the log is reviewed.
