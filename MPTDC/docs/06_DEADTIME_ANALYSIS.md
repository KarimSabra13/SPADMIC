# MPTDC v2.2 — Deadtime and Throughput Analysis

> - **Author:** Karim Sabra
> - **Purpose:** Explain the active deadtime path and the practical throughput limits implied by the current RTL.
> - **Scope:** Uses the checked-in architecture and nominal oscillator assumptions; it is not a silicon signoff timing report.

## 1. Definition

Deadtime is the time from the STOP edge of conversion `N` to the earliest moment a new START can be accepted for conversion `N+1`.

In this architecture, deadtime is dominated by the fast-domain measurement FSM and frontend clear/re-arm path, not by the system-domain drain and serializer path.

## 2. Why the current design is fast

The current architecture uses two contexts:

- one context can be in `CAPTURING`
- the other can be in `DRAINING`

That means packet drain, FIFO buffering, and 16-bit serialization are largely off the critical re-arm path.

## 3. Active closure path

The measurement FSM is:

```text
IDLE -> MEASURE -> SNAPSHOT -> CAPTURE -> STOP_OSC -> CLEAR -> IDLE
```

Approximate role of each state:

- `MEASURE`   : accumulate hits and wait for close condition
- `SNAPSHOT`  : freeze the wide context image into holding registers
- `CAPTURE`   : commit the frozen context snapshot and mark it drainable
- `STOP_OSC`  : clear frontend latches so the slow oscillator stops cleanly
- `CLEAR`     : asynchronously clear PD cells and counters once oscillators are safe
- `IDLE`      : frontend may accept the next START

## 4. Nominal deadtime components

Using the nominal oscillator values in the live package:

- fast half-period = `450 ps`
- full fast period = `900 ps`

The post-close sequence costs roughly:

| Stage | Approximate cost |
|-------|------------------|
| close detect -> `CAPTURE` | 2 fast cycles |
| `CAPTURE` -> `STOP_OSC` | 1 fast cycle |
| `STOP_OSC` -> `CLEAR` | 1 fast cycle |
| `CLEAR` -> `IDLE` | 1 fast cycle |
| async frontend re-arm | sub-cycle / small additional margin |

That gives a nominal practical deadtime on the order of `5-6 ns`. The added
snapshot-settle cycle is intentional implementation margin for the wide
oscillator-domain context snapshot.

## 5. Why drain does not dominate deadtime

After capture:

1. the context is marked `DRAINING`
2. the frontend is released for a new measurement path
3. the system-domain drain FSM handles packetization separately

So the 16-bit output path mainly affects sustained throughput and overflow risk, not the immediate re-arm latency of the frontend.

## 6. Factors that still affect effective deadtime

### 6.1 Fast close (`max_hits = 1`) vs higher-`max_hits` close path

- fast close uses a direct OR reduction of the PD matrix
- higher `max_hits` values use a pipelined count tree, adding one fast-cycle latency to close detection

That added cycle is intentionally accepted to make the fast-domain logic synthesizable.

### 6.2 Persistent arm vs software re-arm

If `conv_arm` is kept high continuously, the frontend can re-arm as soon as the measurement path returns to idle.

If software drops and rewrites `conv_arm`, the effective system-level gap becomes much larger because now `clk_sys` software/control latency is in the loop.

### 6.3 Output backpressure and context pressure

Heavy output backpressure does not directly stretch the frontend deadtime, but it can make both contexts unavailable:

- one context may still be draining
- the other may become the active capturing context

If both are occupied when a START arrives, the frontend rejects the START and `OVF_COUNT` increments.

### 6.4 Missing STOP

The slow-domain START watchdog prevents the system from hanging forever if START arrives and STOP never follows. This is a robustness feature, not a throughput optimization, but it matters for real deployment.

## 7. Practical throughput interpretation

There are really three different notions of speed:

1. **frontend re-arm deadtime**: about `4-5 ns` nominal
2. **conversion acceptance under sustained streaming**: depends on whether both contexts remain available
3. **output bandwidth**: depends on packet size and host backpressure on the 16-bit stream

For example, in `RAW_FEATURES` mode with 15 hits, one packet is:

```text
1 header + 15*3 hit words + 1 EOC = 47 words
```

At `160 MHz`, that is many system-clock cycles of output activity, but it is mostly overlapped with future frontend activity because of the double-buffer structure.

## 8. Reviewer checklist

When evaluating deadtime before synthesis, review:

- whether the oscillator implementation preserves the assumed startup behavior
- whether generated-clock constraints correctly cover `osc_fast_ph0`
- whether the async frontend clear path is constrained and implemented as intended
- whether `conv_arm` will be held persistently in the target use case
- whether downstream backpressure can realistically fill the FIFO or tie up both contexts

## 9. Bottom line

The active architecture is no longer output-serialization-limited in the same way as older single-context or older writer-centered flows. Its critical deadtime is the measurement shutdown and re-arm path, and that path is intentionally short and silicon-structured.
