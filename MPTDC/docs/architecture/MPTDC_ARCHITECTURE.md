# MPTDC Architecture

Author: Karim Sabra

This document is the source-of-truth architecture guide for the active SPADMIC
product-axis MPTDC. It explains what the RTL does, why the block boundaries
exist, and which choices are timing/PPA decisions. It is not a final
physical-signoff statement.

## Product Boundary

The maintained synthesis and verification top is
`MPTDC/rtl/top/mptdc_axis_core.sv`. It owns one TDC axis:

- SPAD or calibration START/STOP input selection.
- Local reset synchronization.
- Two independent slow/fast RO tuning-code inputs from the TOP-owned CSR image.
- One integrated Vernier measurement core.
- One fixed 16-bit packet stream with `valid/ready`, `sop`, and `eop`.
- Busy, ready, FIFO-level, overflow, and diagnostic status.

`mptdc_top_asic` is a retired standalone boundary. It may still exist for
historical correlation, but it is not the product synthesis top and must not be
used as the handoff entrypoint.

## End-to-End Flow

```text
SPAD/CAL async inputs
  -> mptdc_input_mux
  -> mptdc_async_frontend_v2
TOP CSR RO code image
  -> idle-only local slow/fast RO code shadow registers
  -> RO_tune6 slow/fast phase families
  -> BUJIHDX4 -> BUJIHDX12 phase distribution
  -> 8 x 8 PD matrix and local fast tag capture
  -> static held context image
  -> mptdc_hit_capture_bridge into clk_sys
  -> mptdc_context_bank
  -> mptdc_meas_ctrl and mptdc_drain_ctrl
  -> mptdc_sync_fifo
  -> mptdc_packet16_tx
  -> product 16-bit stream
```

The design intentionally keeps measurement-local structures close to the
oscillator phases and moves ordinary control, drain, FIFO, and packet work into
`clk_sys`. That split is the main timing/PPA strategy: do not build one large
high-speed synchronous timestamp counter when the measurement can be represented
by local phase capture and a static context transfer.

## Block Map

| Block | Function | Why this architecture | Timing/PPA effect |
| --- | --- | --- | --- |
| `mptdc_axis_core` | Product wrapper for one axis. Selects input source, synchronizes reset, instantiates `mptdc_core`, and exposes packet/status outputs. | Keeps the SPADMIC integration boundary narrow and stable. TOP owns arbitration/source tagging; the axis owns one measurement engine. | Limits top-level fanout and prevents full-chip packet/control policy from leaking into the timing-closed TDC core. |
| `mptdc_core` | Integration core tying oscillators, phase distribution, PD matrix, async frontend, context, drain, FIFO, packetizer, and watchdog. | Centralizes the measurement/readout contract while preserving sub-block ownership. | Gives synthesis a stable hierarchy for local repairs and lets reports classify oscillator, PD, CDC, drain, and packet paths separately. |
| `mptdc_input_mux` | Combinational selection between SPAD and calibration START/STOP. | Calibration must use the same downstream timing path as real SPAD events. | Avoids a second frontend and avoids duplicating async capture logic. |
| `mptdc_reset_sync` | Async-assert, sync-deassert reset leaf. | Reset release must be local to the consuming domain, not one rebuilt global tree. | Reduces recovery/removal risk and avoids unnecessary high-fanout reset buffering. |
| `mptdc_osc_wrapper` | Selects behavioral model for simulation or real `RO_tune6` macro binding for synthesis. | Keeps simulation portable while preserving the physical macro interface. | Prevents the synthesizable filelist from accidentally using the behavioral oscillator model. |
| `mptdc_phase_buffer_bank` | Buffers each slow/fast `RO_tune6/S[n]` tap through `BUJIHDX4 -> BUJIHDX12`. | Raw RO pins are analog load points; digital fabric needs isolated, stronger phase drivers. | The topology controls RO loading and gives Genus/Innovus explicit load/report points. |
| Local RO code shadows | Two 8-bit `clk_sys` register banks close to the slow and fast RO code sides. | Software-visible CSR values may be routed from TOP, but live RO code must be stable during a measurement. | Long static TOP routes terminate at local flops; only short local nets drive `RO_tune6/code[7:0]`, reducing load and measurement disturbance. |
| `mptdc_fast_epoch_tag` | Produces the local fast raw tag sampled by PD cells. | A local tag is cheaper and more timing-local than a global fast binary counter. | Reduces global fast-domain fanout and avoids wide high-speed counter distribution. |
| `mptdc_slow_epoch_johnson` | Produces the slow Johnson epoch. | Johnson coding changes one bit per step and is robust for sampled phase context. | Lowers switching and decode complexity versus a wider binary epoch source. |
| `mptdc_pd_cell` | Implements the intentional slow-to-fast Vernier q1 sampling relation and captures local `nfast` data. | The q1 relation is the measurement itself, not an accidental CDC path. | Requires a narrow count-checked exception only on q1; downstream hit/tag paths remain real timed logic. |
| `mptdc_async_frontend_v2` | Owns START/STOP event latching, oscillator enables, PD eligibility, context allocation, reject/overflow behavior, and clear sequencing. | Async event ownership is explicit so START/STOP policy is not spread across the PD matrix and system FSM. | Keeps analog/event-domain work local and exposes only stable ownership state to `clk_sys`. |
| `mptdc_stop_capture_async` | Captures STOP-related phase metadata. | STOP is asynchronous to `clk_sys`; metadata must be captured at the event boundary. | Avoids late system-domain reconstruction of information that only exists at STOP time. |
| `mptdc_stop_epoch_capture_async` | Captures slow Johnson epoch at STOP. | Epoch capture must align with the measurement event, not later drain timing. | Keeps timestamp semantics independent of FIFO/backpressure latency. |
| `mptdc_hit_capture_bridge` | Samples the held measurement image into `clk_sys` after the frontend handshake says it is stable. | Multi-bit PD/tag context is transferred as a static bus under ownership control, not as independent bit synchronizers. | Avoids synchronizer arrays on every data bit and keeps the high-fanout context image static during transfer. |
| `mptdc_context_bank` | Stores retained measurement contexts before drain. | Two contexts decouple event acceptance from slower packet drain. | Improves burst tolerance without paying the area/power of a large multi-entry acquisition RAM. |
| `mptdc_meas_ctrl` | `clk_sys` measurement FSM for snapshot, commit, clear, teardown, and hit-count control. | Ordinary sequencing belongs in one synchronous domain after the event image is held. | Keeps complex control timing in `clk_sys` instead of oscillator domains. |
| `mptdc_drain_ctrl` | Scans a committed context and emits META/HIT/EOC records into FIFO. | Sparse hit readout is cheaper than exporting a full 64-cell image every time. | STRIDE2/empty-row skip reduce drain latency and switching while preserving the packet contract. |
| `mptdc_watchdog` | Forces recovery if a conversion stalls. | Async measurement circuits need a bounded escape path. | Protects system availability without adding timing pressure to normal data paths. |
| `mptdc_sync_fifo` | Synchronous FWFT FIFO for acquisition records. | Packet output can backpressure independently of measurement completion. | Buffers short packet bursts while keeping the interface simple and fully `clk_sys` timed. |
| `mptdc_packet16_tx` | Serializes acquisition records into the fixed product 16-bit packet. | The SPADMIC top-level arbiter expects a stable narrow stream contract. | Prevents wide context buses from crossing the product boundary and keeps I/O activity controlled. |

## Clock and Reset Domains

`clk_sys` owns control, status, context drain, FIFO, and packet transmission.
Slow and fast oscillator phases own measurement-local sampling. The design does
not assume a synchronous relationship between these families.

The important domains are:

- `clk_sys`: product control, FSMs, drain, FIFO, packet stream, watchdog.
- `slow_phase[n]`: Vernier launch/sample context for each slow tap.
- `fast_phase[n]`: PD sampling and local fast-tag capture for each fast tap.
- Async START/STOP event domain: frontend latch set/reset and STOP metadata.

Reset asserts asynchronously and deasserts through local synchronizers. Do not
merge synchronizer leaves, remove reset attributes, or rebuild reset as one
global tree without recovery/removal and CDC evidence.

## Oscillator and Phase Distribution

The physical model binds two `RO_tune6` layout-backed macros, one slow and one fast.
Their `S[0:7]` pins are raw analog phase pins and remain explicit audit points.
Their `code[7:0]` pins are driven by local shadow registers, not directly by a
long software CSR bus.
Each phase tap uses:

```text
RO_tune6/S[n] -> BUJIHDX4 isolation -> BUJIHDX12 digital driver -> PD/tag fabric
```

This topology was chosen because the RO pins are load-sensitive and the digital
fabric needs a repeatable drive point. The `BUJIHDX4` stage isolates the macro
pin; the `BUJIHDX12` stage provides the final digital phase driver. The active
typical flow models the final phase-driver outputs as buffered phase clocks.
They are not ordinary `clk_sys` CTS targets.

The RO tuning interface has three rules:

1. The external CSR image is the architectural source of truth.
2. The local shadow registers update only while the axis is idle and both
   oscillators are stopped.
3. The held local value drives the RO throughout the complete live measurement
   interval.

`soft_reset_i` does not clear these local shadows. The top asynchronous reset
does clear them and prevents arming until the first deterministic idle reload
has occurred. This preserves the previous all-zero behavior at reset while
allowing software to program nonzero slow/fast tuning values without a new
software-visible handshake.

## Vernier Matrix and Exception Boundary

The detector matrix has `NE=8` slow phases by `NE=8` fast phases, for 64 PD
cells. The q1 slow-to-fast relation inside each PD cell is the intentional
Vernier measurement. The synthesis exception is therefore narrow and
count-checked:

- eight expected sources;
- 64 expected q1 endpoints;
- no overmatch;
- no undermatch.

The exception does not cut q1-to-q2, hit latching, local `nfast` capture,
fast-tag logic, reset, control, FIFO, packet, or any unrelated oscillator-domain
path. Those remain real timing paths. This distinction is why the final timing
work focused on local ON22 cells feeding `nfast_hit_latched_reg[*]/D` instead
of broad clock or SDC relaxation.

## Tags, Epochs, and Contexts

The current architecture uses a local fast raw tag and a slow Johnson epoch.
That choice avoids a global high-speed binary fast counter, which would be
larger, higher switching, and harder to route symmetrically across all PD
columns. The raw local tag is intentionally left for calibration/software
interpretation rather than over-decoding it in the oscillator domain.

`N_CTX=2` is a deliberate middle point: it absorbs a second accepted conversion
while the first context drains, but it avoids a large asynchronous context RAM.
The static held-bus bridge is part of that contract: once ownership says the
context is stable, `clk_sys` samples the multi-bit image and then releases the
frontend for cleanup.

## Drain, FIFO, and Packet Contract

The drain path converts a committed context into a compact record stream:
metadata, hit records, and end-of-conversion. `mptdc_packet16_tx` then emits the
fixed product packet. The packet grammar is an external integration contract:
cleanup must not silently change field order, width, SOP/EOP behavior, or
backpressure behavior.

The relevant frozen package constants are:

- `NE=8`, `PD_N=64`.
- `NSLOW_W=7`, `NFAST_W=7`.
- `MAX_HITS=15`.
- `FIFO_DEPTH=64`.
- `N_CTX=2`.
- `NARROW_W=16`.

Changing any of these is not a documentation cleanup. It is an RTL, verification,
synthesis, packet, calibration, and software interface change.

## Timing and PPA Rationale

The major choices are tied to timing and PPA:

1. Local phase capture replaces a global high-speed timestamp counter. This
   reduces fast-domain area, switching, and route load.
2. Buffered phase distribution protects analog RO pins and creates auditable
   digital phase-clock endpoints.
3. The q1 exception is narrow because only q1 is intentional measurement
   sampling. Keeping downstream logic timed exposed the real ON22 local path.
4. STRIDE2 drain and empty-row skip reduce readout latency and dynamic activity
   without changing the packet contract.
5. Two contexts improve short-burst tolerance with small area cost.
6. Fixed 16-bit output keeps product integration simple and avoids exporting
   the full PD image across top-level boundaries.
7. The local ON22 X0-to-X1 repair is scoped to real endpoint cones. X2 is
   blocked because it created a `LOCAL_FAST_TAG_SELF` regression.
8. Local RO code shadows convert a long static integration bus into short
   macro-adjacent load nets and prevent mid-measurement code changes from
   perturbing oscillator behavior.

## Active Physical Assumptions

- Product top: `mptdc_axis_core`.
- Frequency mode: `R750_delta5`.
- Standard-cell family for the closed Genus run: JIHD.
- Timing view: typical-only Genus.
- Macro binding: real `RO_tune6` layout-backed macro with shell Liberty.
- Phase topology: `BUJIHDX4 -> BUJIHDX12` per slow/fast tap.
- RO tuning: independent slow/fast 8-bit CSR images captured into local
  idle-only shadow registers before oscillator activity.
- PD exception: exact, narrow, count-checked q1 Vernier relation.
- Timing repair: scoped local ON22 X0-to-X1 repair, X2 prohibited.

Any RTL or phase-buffer-cell change after the June 18, 2026 Genus reference
invalidates that handoff netlist. The current RO-code interface must therefore
be followed by a fresh canonical Genus run before a new Innovus signoff attempt.
Final MMMC timing, extracted parasitics, analog phase/jitter confirmation, LVS,
DRC, PEX, and post-layout characterization remain outside this architecture
claim until server evidence exists.

## Refactor Rules

Use descriptive, purpose-based names for new modules, scripts, variables, and
profile fields. Do not rename existing RTL signals or backend script variables
just to make the tree look cleaner unless the refactor is validated like a real
logic change. In this design, names are part of report matching, waiver matching,
parser behavior, and external calibration/debug scripts.

A valid architecture refactor must state:

1. Which contract changes: product I/O, packet, oscillator/PD measurement, CDC,
   reset, drain, FIFO, calibration, synthesis policy, or PnR assumptions.
2. Which evidence is refreshed: smoke/regression, Xcelium, Genus, Innovus,
   calibration, or physical verification.
3. Which old public entrypoint is removed or aliased.

Documentation-only cleanup must not change RTL behavior, packet semantics,
canonical Genus profile values, SDC exception scope, or synthesis filelists.
