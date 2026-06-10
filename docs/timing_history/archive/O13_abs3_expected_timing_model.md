# O13 abs3 Expected Timing Model

Status: `EXPECTED_MODEL`

## Clock Domains

- `clk_sys`: system synchronous domain.
- Raw RO clocks: analog source/load-check clocks on `RO_tune4/S[0:7]`.
- Final buffer phase clocks: digital phase clocks on BUHDX12 `Q` outputs.

## Async Relationship

`clk_sys` is asynchronous to all oscillator clocks:

- raw slow clocks
- raw fast clocks
- final slow buffer clocks
- final fast buffer clocks

The oscillator clocks remain in one oscillator group relative to each other. This keeps phase-buffer propagation and local oscillator-domain paths visible.

## Timed Paths That Must Remain Visible

- Phase-buffer chain relationships.
- Fast tag and local PD timing under the buffered fast phase clocks.
- PD hit/freeze local timing.
- Slow Johnson/self timing under the buffered slow phase clock.

## Classified Non-Ordinary Paths

- Slow/fast Vernier sampling: `PD_INTENTIONAL_VERNIER`.
- Held snapshot/context bridge paths: `HELD_BUS_CDC`.
- Reset/recovery paths: reset class, not setup closure.
- Anything else: `UNKNOWN_REVIEW_REQUIRED`.
