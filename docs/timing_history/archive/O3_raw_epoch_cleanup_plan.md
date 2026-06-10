# O3 Raw Epoch and PD Capture Cleanup Plan

## Objective

O3 removes standard-cell high-speed counter/decode logic from oscillator domains
while preserving the Vernier measurement architecture:

- slow oscillator starts on START.
- fast oscillator starts on STOP.
- 8x8 PD matrix remains.
- `ns`/`nf` meanings remain.
- packet width/layout remains unchanged.
- capture-before-clear ordering remains unchanged.

## Patch Scope

O3A replaces the slow binary/Gray counter with a 64-stage Johnson epoch source.

O3B removes slow Gray decode from the fast domain. STOP captures the raw Johnson
state and `clk_sys` decodes it into the existing 7-bit `nslow` field inside the
held-bus bridge.

O3C moves START-only timeout counting from `slow_phase[0]` into `clk_sys`.
The frontend still receives a held synthetic STOP level, not a narrow pulse.

O3D changes PD cells to shadow the local raw fast tag while no hit has occurred,
then freeze the shadow register on hit. This removes q1/q2 edge-detect logic
from the 7-bit tag capture D path.

O3E does not add a new drain pipeline because `ST_D_EMIT` is already present.
The remaining drain timing is left for post-O3 Genus review.

O3F adds an O3 Genus wrapper, O3 filelist, and O3 SDC/report overlay.

## Expected Genus Impact

| Family | Expected O3 effect |
| --- | --- |
| Slow binary/Gray counter | Removed from `clk_osc_slow`. |
| Slow START watchdog binary counter | Removed from `clk_osc_slow`. |
| Slow Gray decode in fast domain | Removed from `clk_osc_fast`. |
| PD q1/q2 to `nfast_hit_latched` | Substantially reduced; tag capture D path becomes local tag shadowing gated only by `hit_latched`. |
| clk_sys drain | Still present; expected to become more visible if oscillator-domain blockers improve. |
| DRV | May improve structurally, but final DRV needs Genus/Innovus evidence. |

## Non-Goals

- No Innovus request before O3 Genus review.
- No R800 derate.
- No PDK cell sizing.
- No broad new false paths.
- No packet field removal.
