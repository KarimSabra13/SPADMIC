# MPTDC v2.4 — Deadtime, Throughput, and Overflow Analysis

> - **Author:** Karim Sabra
> - **Purpose:** Define the live deadtime metrics and the practical throughput limits implied by the `clk_sys` control/context pivot.
> - **Scope:** Uses the checked-in RTL and nominal oscillator assumptions; it is not a silicon timing-signoff report.

## 1. Definitions

Do not quote a deadtime number without its envelope. The active project uses three related metrics:

| Metric | Definition | Why it matters |
|---|---|---|
| Best-case lossless deadtime | Minimum STOP-to-next-START gap where the next event is accepted and produces one complete packet with sink ready/no artificial backpressure | Hero-mode throughput with `conv_arm` held high |
| Backpressure-tolerant lossless deadtime | Same STOP-to-next-START acceptance criterion, but under a stated ready/FIFO/context-pressure envelope | Real shared-readout or bus-arbitration robustness |
| Frontend re-arm latency | Internal STOP-to-frontend/PD/counter readiness, independent of downstream packet pressure | Implementation diagnostic, not the published product metric by itself |

Software-paced CSR re-arm latency is a separate system-use-case number and should not be mixed with hardware deadtime.

## 2. Live control sequence

The pivot moved `mptdc_meas_ctrl` and `mptdc_context_bank` to `clk_sys`. The oscillator/PD/counter fabric remains the measurement-local exception.

The live sequence is:

```text
IDLE -> MEASURE -> SNAPSHOT -> EVAL -> CAPTURE -> STOP_OSC -> CLEAR -> IDLE
```

Ordering contract:

1. STOP/front-end ownership becomes visible in `clk_sys`.
2. `SNAPSHOT` samples the held PD/counter/STOP-boundary image through `mptdc_hit_capture_bridge`.
3. `EVAL` computes hit count and close flags from that registered image.
4. `CAPTURE` commits the image to the `clk_sys` context bank and marks it drainable.
5. `STOP_OSC` clears frontend START/STOP ownership.
6. `CLEAR` clears PD/counter/STOP-capture fabric only after the context image has been committed.

This intentionally trades the obsolete few-fast-cycle teardown target for a reviewable CDC and STA structure.

## 3. Current evidence

`tb_deadtime_measure` is useful for measuring requested gaps, but the maintained pressure proof is now:

```bash
bash scripts/sim/run_tb.sh tb_lossless_pressure --sim verilator
```

That bench exercises:

- always-ready sink behavior,
- randomized short output stalls,
- full saturation and release,
- `max_hits = {1,2,8,15}`,
- START/STOP gaps around the 40-60 ns region,
- one packet per accepted START,
- exact rejected-START overflow accounting,
- no context double-use,
- `pd_clear` only after context commit.

At the current RTL checkpoint, the practical best-case STOP-to-next-START acceptance floor is expected around the synchronized STOP plus `clk_sys` teardown window, not `4-6 ns`. The exact number remains an RTL/model evidence number until a non-dry-run characterization/regression bundle and the final oscillator macro contract exist.

## 4. Backpressure and deterministic overflow

The intended policy is deterministic saturation:

- accept STARTs while a safe context/FIFO slot exists,
- reject STARTs only when accepting would risk overwrite or corruption,
- never corrupt context 0, context 1, or FIFO data,
- increment `OVF_COUNT` exactly once per rejected START,
- recover and accept new events as soon as pressure releases.

The frontend and core now hold a rejected START indication until `clk_sys` can count it, so short async rejected pulses are not sampled opportunistically as one-cycle levels.

## 5. Precision implications

The pivot should not bias the Vernier measurement itself because START/STOP boundaries, oscillator launch, PD sampling, STOP-side boundary capture, and counter snapshots remain measurement-local. The risk is not arithmetic bias from `clk_sys`; the risk is violating the held-image CDC contract.

Before claiming precision/linearity stability, collect both:

- pre-calibration raw tuple/code-density evidence in `RAW_FEATURES`,
- post-calibration reconstructed timestamp evidence in `RAW_TIMESTAMP` or `FULL`.

The maintained wrapper is:

```bash
bash scripts/sim/run_characterization_baseline.sh --analyze --calibrate --with-fixed-delay
```

The `--analyze --calibrate` outputs are mandatory evidence, not optional polish, for post-pivot signoff discussion.

## 6. Remaining silicon caveats

The digital RTL currently assumes ideal oscillator enable/disable behavior in simulation. Final silicon deadtime and precision still depend on:

- oscillator enable/disable latency,
- phase idle behavior,
- jitter and duty-cycle distortion,
- output slew/load and tap matching,
- final generated-clock periods and uncertainties,
- physical matching of the 8x8 PD island.

Until those are available in the macro Liberty/LEF and implementation constraints, the design can be functionally coherent and STA-friendlier without being final signoff-ready.
