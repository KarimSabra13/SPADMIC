# SPADMIC TOP — Tapeout Readiness and Robustness Map

## Scope

This document is the tapeout-focused RTL map for the active SPADMIC digital top.
It explains the active module relationships, clock/reset boundaries, CDC and STA
assumptions, placeholder macro contracts, and robustness work needed before a
silicon-ready claim.

It is intentionally conservative: a block can be functionally correct and still
carry a signoff action if its timing, CDC, DFT, or macro integration assumptions
are not frozen.

## Executive status

| Area | Functional RTL status | Tapeout-readiness status | Main action |
|------|-----------------------|--------------------------|-------------|
| TOP control sequencing | Coherent active/requested model | Needs full reset/mode-switch regression closure | Verify all non-idle reject and drain-commit cases |
| TDC axes | Preserved MPTDC kernels integrated cleanly | Blocked on oscillator macro and generated-clock signoff | Freeze macro contract and CDC/STA waiver deck |
| Shared readout | Packet-atomic META-first architecture | Needs stress and packet-integrity evidence | Run/extend shared-readout and correlated-TX tests |
| Position path | Robust queued detector/packetizer plus raw bitmap mode and SPAD reset output exist | Needs final SPAD-matrix contract and async-line/reset stress evidence | Stress settle, glitch, overflow, raw packets, reset modes, and disable cases |
| I2C/CSR | Region decode and timeout protection exist | Needs negative-path coverage | Test invalid regions, timeout, reset, NACK, and CSR error propagation |
| DDR TX | Simple source-synchronous contract | Needs output timing constraints | Define output delay and receiver sampling assumptions |
| PLL/SPAD/oscillator macros | Not final | Not signoff-ready | Keep wrappers/constraints explicit until real macros arrive |

## Active chip-level graph

```text
clk_sys / async_rst_n / clk_ref_40m / async SPAD inputs
  |
  `- spadmic_top_v1
       |- spadmic_i2c_slave
       |- spadmic_i2c_csr_bridge
       |- spadmic_csr_decoder
       |- spadmic_global_csr
       |- spadmic_top_sequencer
       |- spadmic_tdc_axis_wrapper x3
       |    |- spadmic_ref_stop_qualifier
       |    `- mptdc_top_asic
       |         `- mptdc_core
       |              |- async frontend / oscillator wrappers / PD matrix
       |              |- Gray counters / hit-capture bridge / sys context bank / drain controller
       |              `- acquisition FIFO export
       |- spadmic_tdc_shared_readout
       |- spadmic_position_block
       |    `- spadmic_axis_cluster_scan x3
       |- spadmic_correlated_tx
       `- spadmic_ddr_tx
```

Legacy TOP modules still in-tree but not on the active chip datapath:

- `spadmic_tdc_arbiter3`
- `spadmic_tdc_packet_fifo`
- `spadmic_shared_tx_mux`

## Clock and reset boundary map

| Boundary | Source | Destination | Classification | Required signoff treatment |
|----------|--------|-------------|----------------|----------------------------|
| `async_rst_n` to TOP glue | pad reset | `clk_sys` | async-assert/sync-deassert reset | Check reset-tree constraints and recovery/removal |
| `i2c_scl_i/sda_i` | I2C pins | `clk_sys` | 2FF synchronized sampled protocol | Check max supported I2C rate versus `clk_sys` sampling |
| SPAD event to TDC wrapper | async event | async gate + `clk_ref_40m` qualifier | intentional async request plus ref-clock pulse qualification | Verify no held-high retrigger and no mode-switch glitch |
| `x/y/z_lines_i` | SPAD matrix | `clk_sys` position block | multibit async sampled bus with settle filter | CDC waiver plus functional settle/glitch tests |
| `clk_ref_40m` STOP qualifier | external ref clock | MPTDC STOP input | generated async pulse from ref edge | Treat as cross-domain/async input to MPTDC |
| MPTDC slow/fast oscillators | oscillator macro | PD/counter measurement fabric | generated clocks | Real macro generated clocks and uncertainty required |
| PD cell sampling | slow/fast oscillator taps | async latch/sampler | intentional measurement structure | CDC/STA exception and physical symmetry constraints |
| Gray counter snapshots | oscillator domains | `clk_sys` hit-capture image | Gray/snapshot CDC | Constrain source clocks and document bounded ambiguity |
| held PD/counter image | oscillator/PD fabric | `mptdc_hit_capture_bridge` in `clk_sys` | static-data CDC after synchronized STOP visibility | Waive only with frozen-data proof: STOP visible, image held, bridge sampled, context committed, then PD clear |
| context bank snapshot | `clk_sys` context bank | `clk_sys` drain | ordinary synchronous storage/readout | Time normally; no CDC waiver needed for context bank storage itself |
| correlated TX to DDR TX | `clk_sys` | forwarded output clock | synchronous logical word stream | Normal `clk_sys` timing plus output delay constraints |
| `chip_tx_*` pins | forwarded `clk_sys` | off-chip receiver | source-synchronous DDR | Board/receiver setup-hold budget required |
| `spad_matrix_rst_o` | `clk_sys` position CSR/reset controller | SPAD matrix reset input | synchronous pulse leaving digital top | Matrix reset pulse-width and recovery contract required |

## Active module risk map

| Module | Role | Domain | Tapeout risk | Required evidence |
|--------|------|--------|--------------|-------------------|
| `spadmic_top_v1` | chip integration shell | mostly `clk_sys` | incomplete top-level mode/reset stress can hide integration bugs | smoke, directed, VIP mode-switch/reset regressions |
| `spadmic_pkg` | shared constants and packet helpers | none | protocol changes ripple broadly | packet-format tests and doc alignment |
| `spadmic_i2c_slave` | I2C protocol sampler | pins into `clk_sys` | sampled-I2C corner cases, ACK hold, reset during transaction | I2C negative-path tests |
| `spadmic_i2c_csr_bridge` | I2C transaction to CSR | `clk_sys` | single in-flight assumption | back-to-back and reset tests |
| `spadmic_csr_decoder` | CSR region decode and timeout | `clk_sys` | invalid/stalled slaves must not hang software | invalid-region and timeout tests |
| `spadmic_global_csr` | requested image and status | `clk_sys` | status/fault semantics drive software safety | readback and rejected-write tests |
| `spadmic_top_sequencer` | active image commit after drain | `clk_sys` | wrong idle definition can corrupt packets | transition assertions/tests |
| `spadmic_tdc_axis_wrapper` | per-axis top glue | async + `clk_ref_40m` + `clk_sys` | enable gating is quasi-static and must not change mid-event | mode-switch drain tests and CDC review |
| `spadmic_ref_stop_qualifier` | one STOP pulse per event | async/ref clock | latch-based gating requires careful review | hold/rearm/random timing tests |
| `mptdc_top_asic` | preserved axis wrapper | `clk_sys` + async | depends on stable top-level overrides | per-axis CSR/readout tests |
| `mptdc_core` | Vernier measurement kernel | generated clocks + async + `clk_sys` | highest signoff risk: oscillator, PD, CDC, constraints | MPTDC regression, CDC/STA waiver deck, macro contract |
| `spadmic_tdc_shared_readout` | shared TDC serializer | `clk_sys` | source interleaving or starvation would corrupt event stream | META-first, fairness, zero-hit, stall tests |
| `spadmic_position_block` | position detect/queue/packetize and matrix reset control | async lines into `clk_sys` | async bus sampling, queue overflow, raw payload framing, reset timing versus matrix behavior | settle/glitch/queue/raw/reset stress tests |
| `spadmic_axis_cluster_scan` | two-cycle cluster extraction | `clk_sys` datapath | scan timing and edge correctness | stress cluster tests and synthesis timing |
| `spadmic_correlated_tx` | packet arbiter/event tagger/FIFO | `clk_sys` | event-ID wrap, packet interleaving, FIFO pressure | correlated TX unit/stress tests |
| `spadmic_ddr_tx` | physical DDR packer | both edges of `clk_sys` | output timing and tool support for dual-edge logic | DDR unit test and STA output-delay constraints |

## Placeholder macro contracts

### PLL

Until the final PLL macro is selected, treat `clk_sys` and `clk_ref_40m` as
externally supplied ideal clocks in RTL simulation. For implementation, the PLL
wrapper must define:

- output clock frequencies and duty-cycle assumptions,
- reset/lock behavior,
- whether clocks can stop or glitch during lock acquisition,
- clock uncertainty/jitter values,
- generated-clock names used by STA.

### SPAD matrix

Until the final SPAD matrix is integrated, treat `spad_x/y/z_event_async_i` and
`x/y/z_lines_i` as asynchronous black-box outputs. The integration contract must
define:

- event pulse width or held-level behavior,
- line-bus settle/clear behavior,
- maximum event rate and overlap behavior,
- reset/disable behavior, including one-cycle active-high `spad_matrix_rst_o` pulse width and recovery time,
- whether outputs can glitch during bias or mode transitions.

### MPTDC oscillator

The current synthesis placeholder is not a signoff oscillator. The final macro
contract must define:

- slow/fast tap count and tap order,
- nominal/min/max tap delays,
- enable/disable latency,
- reset or deterministic idle phase behavior,
- generated clock names for tap 0 and phase taps,
- physical matching/symmetry requirements for the 8x8 PD island.

## Constraint and waiver checklist

The starting point for TOP-level constraint capture is
[`../syn/inputs/spadmic_top_tapeout_template.sdc`](../syn/inputs/spadmic_top_tapeout_template.sdc).
It is a template and must be updated with final PLL, SPAD matrix, oscillator,
package, and board budgets before signoff.

Do not mark the full chip tapeout-ready until this checklist has explicit owner
evidence:

- primary `clk_sys` and `clk_ref_40m` clocks defined,
- PLL generated clocks defined after macro selection,
- MPTDC slow/fast oscillator generated clocks defined after macro selection,
- asynchronous clock groups justified between unrelated domains,
- reset recovery/removal checked for synchronizer outputs,
- `ASYNC_REG` synchronizers preserved and physically clustered,
- held PD/counter static-bus CDC waived only after frozen-data protocol review,
- context-bank storage/readout timed as ordinary `clk_sys` logic,
- PD-cell intentional async sampling waived with physical-design constraints,
- DDR TX output delays defined against the off-chip receiver for both rising and falling data edges,
- SPAD matrix reset output timing/load and matrix-side recovery constraints defined,
- false paths do not mask real synchronous logic,
- no unconstrained active output or control path remains.

## Verification closure checklist

The repeatable gate for this checklist is:

```bash
cd /home/karim/SPADMIC
bash TOP/ci/run_tapeout_readiness.sh
```

Minimum digital evidence before a tapeout-readiness review:

- TOP smoke compile and directed bench pass.
- TOP directed regression pass.
- VIP smoke tests pass: TDC, position, switching.
- VIP feature tests pass: TDC modes, position clusters, control reject, reset recovery, backpressure stress, I2C end-to-end.
- MPTDC smoke/regression pass.
- Fixed-delay or equivalent TDC characterization campaign has current results.
- Correlated export tests prove packet atomicity and event-ID behavior.
- Raw position export tests prove EOC-looking bitmap payload words do not terminate packets early.
- I2C negative tests prove errors do not hang the control plane.
- Reset tests cover reset during TDC, position, TX, and I2C activity.
- Documentation and RTL packet contracts agree.
- Every active TOP and MPTDC block has direct bench/stress/VIP/assertion evidence or an explicit waiver.
- A shared Python off-chip decoder cross-checks dumped/captured logical TX streams against the documented packet grammar.
- Functional coverage bins are 100% reviewed, aggregate functional coverage is at least 95%, code coverage is at least 90%, and all waivers are tied to spec rationale.
- Non-waivable safety/protocol coverage categories are closed: reset, CDC boundaries, CSR faults, packet grammar, event IDs, FIFO pressure, overflow/drop behavior, and mode transitions.

Verification signoff is tiered:

| Tier | Required evidence |
|------|-------------------|
| Local Verilator | portable compile/lint and directed sanity for changed blocks |
| Xcelium regression | full SystemVerilog simulation for TOP and MPTDC VIP suites |
| Coverage campaign | merged functional/code coverage, zero-bin review, waiver list |
| CDC/lint/formal-style | static reset/CDC exception review and assertion/formal evidence where available |
| Synthesis/timing sanity | clean elaboration, constraints reviewed, no unconstrained active output/control path |
| Characterization | MPTDC campaign/fixed-delay reports using verified output data, tracked separately from functional correctness |

## Low-risk hardening policy

Before tapeout, prefer changes in this order:

1. tests and assertions,
2. status/fault observability,
3. constraints and wrappers,
4. documentation,
5. RTL behavior changes only when a verified bug or signoff blocker exists.

Avoid broad rewrites of the MPTDC measurement path, PD matrix, packet grammar, or
source-synchronous TX pins unless a real signoff blocker requires it.
