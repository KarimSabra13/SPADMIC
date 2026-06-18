# MPTDC RTL

Author: Karim Sabra

This directory contains the active product-axis RTL. The synthesis and product
verification top is `top/mptdc_axis_core.sv`; `top/mptdc_core.sv` is the internal
measurement/readout integration core.

## Compile order and ownership

| Directory | Responsibility | Key contract |
| --- | --- | --- |
| `pkg/` | constants, enums, structs, packet types | Compile first; packet-visible types are interface contracts. |
| `cdc/` | reset synchronization and synchronous FIFO primitives | Preserve async-assert/sync-deassert and explicit CDC intent. |
| `osc/` | behavioral/physical oscillator binding and phase buffering | Simulation model is excluded from synthesis; real `RO_tune4` binding is required physically. |
| `pd/` | fast tag, slow epoch, and `8 x 8` phase detector cells | Clock-as-data Vernier behavior is intentional and narrowly constrained. |
| `async/` | START/STOP capture, frontend ownership, held-context bridge | Latch-style storage and static held-bus CDC are intentional design structures. |
| `ctrl/` | input selection, measurement control, drain, watchdog | Ordinary state/control is primarily in `clk_sys`. |
| `readout/` | fixed 16-bit packet transmitter | Field order and SOP/EOP behavior must remain compatible. |
| `top/` | product boundary and integration core | `mptdc_axis_core` is the maintained product top. |

`filelist.f` is the simulation compile-order source of truth. Synthesis uses
`syn/filelist_axis_core_typical_closed.f`, which excludes the behavioral
oscillator model and enables the real macro/phase-distribution defines.

The RTL is organized by ownership boundary, not by synthesis convenience. Keep
new logic in the directory that owns the contract it changes; do not hide CDC,
oscillator, or packet-interface changes inside unrelated cleanup commits.
For the block-by-block architecture, timing/PPA rationale, and refactor rules,
use `../docs/architecture/MPTDC_ARCHITECTURE.md`.

## Frozen functional invariants

- `NE=8`, two retained contexts, and an `8 x 8` PD matrix.
- One slow and one fast `RO_tune4` phase family.
- `R750_delta5` timing/frequency mode for the current physical baseline.
- `BUHDX4 -> BUHDX12` buffered phase distribution.
- Fixed 16-bit packet stream at `mptdc_axis_core`.
- Local fast raw tag plus slow Johnson epoch; no reintroduction of a global
  oscillator-domain binary fast counter.
- Async frontend ownership and teardown semantics remain explicit.
- Context data is held stable before the `clk_sys` drain path consumes it.

## RTL change checklist

Before changing RTL, identify which contract is affected: product I/O, packet
format, oscillator/PD measurement behavior, CDC/reset, context ownership,
drain/FIFO, or calibration interpretation. A change is not handoff-ready until:

1. `bash MPTDC/ci/run_smoke.sh` passes.
2. `bash MPTDC/ci/run_full_regression.sh` passes.
3. Xcelium smoke passes on the Cadence server.
4. The canonical Genus profile is rerun if hierarchy, logic depth, fanout,
   cell preservation, clocking, reset, or CDC structure changed.
5. Packet/calibration documentation is updated if any observable field changes.

Do not “clean up” intentional latches, synchronizer attributes, preserved phase
buffers, clock-as-data paths, or the static held-bus bridge without a replacement
architecture and matching timing/verification evidence.

## Naming policy

New modules, signals, parameters, scripts, and generated reports should use
purpose-based names that reveal ownership and intent. Examples are product top,
timing view, phase topology, packet role, or repair scope.

Existing RTL names are not renamed in this documentation cleanup. In this block,
hierarchy and signal names are consumed by filelists, reports, parser checks,
timing exceptions, calibration/debug scripts, and external review notes. Rename
them only in a separate refactor with local regression, Xcelium, Genus, and
affected calibration evidence.
