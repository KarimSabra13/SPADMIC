# SPADMIC Matrix TOP Next Steps To ASIC

Status: planning and execution roadmap for controlled implementation after commit `5cdf489f`.

## Metadata

- Branch: `SPADMIC_test`
- Baseline commit: `5cdf489fbfb0a13e1a5ee7f5a253002e023602ac`
- Date: `2026-06-28`
- Target top: `TOP/rtl/spadmic_top_matrix_v1.sv`
- Legacy top: `TOP/rtl/spadmic_top_v1.sv` remains protected and unchanged.
- Cadence access: not available locally. Xcelium, Genus, Innovus, CDC/RDC, DRC/LVS, PEX, MMMC, DDR timing, and matrix macro timing must be run/reviewed from server results before any signoff claim.

## Preflight Baseline

Local commands run on the baseline:

- `git status --short` captured before creating this documentation diff
  - untracked user references only: `ParameterDefs.sv`, `multi_ShiftRegisterChain_cfg_v1.sv`, `pixel_readout.pdf`
- `git branch --show-current`
  - `SPADMIC_test`
- `git rev-parse HEAD`
  - `5cdf489fbfb0a13e1a5ee7f5a253002e023602ac`
- `git log -1 --oneline`
  - `5cdf489f matrix top phased integration`
- `git diff --name-only HEAD -- MPTDC/...protected TOP/rtl/spadmic_top_v1.sv`
  - no output, so no local protected diffs.
- `git diff --check`
  - pass.
- `bash TOP/ci/run_tapeout_readiness.sh`
  - 14 pass, 0 fail, 4 skipped.
  - Skips are Xcelium-related or retired VIP; they are not pass evidence.

## Current Architecture Target

The new matrix-top architecture is centered on `spadmic_top_matrix_v1`:

```text
R/Y/B[63:0]
  |-- independent OR64_R/Y/B --> TOP-owned START gate --> TDC wrappers
  |-- snapshot frontend -------> selective reset controller -> Rz/Yz/Bz
  |-- snapshot frontend -------> position packet path

TDC packet streams + position stream
  -> event bundle TX
  -> output FIFO (planned)
  -> DDR16 pairer
  -> future DDR16 macro boundary

I2C -> CSR bridge -> matrix-top CSR -> mode/event/config controls

clk_sys     : CSR, event, snapshot, reset, packet/output control
clk_cfg_40m : matrix configuration Din/Cin/Dout/Cout controller
clk_ref_40m : MPTDC STOP qualifier reference
```

## Already Implemented

- New top shell with final-style matrix pins, reset pins, configuration pins, calibration pins, and DDR16 provisional pins.
- Explicit operating modes: disabled, TDC-only, position-only, BOTH, calibration.
- Mode-dependent event masks in the coordinator.
- TOP-owned one-shot START gating per axis during an event.
- Independent OR64 blocks for R/Y/B.
- Raw matrix snapshot frontend with settle and watchdog behavior.
- Active-low selective reset controller.
- DDR16 pairer without generic dual-edge final RTL.
- Matrix configuration controller with separate `clk_cfg_40m` domain and a basic stable-bus toggle handshake.
- Initial matrix-top CSR endpoint.
- Snapshot-owned position packetizer with CSR-selected raw bitmap mode and
  fixed 8-word cluster mode.
- Event bundle transmitter with common event ID patching.
- Verilator local readiness gate that lints both legacy and matrix top modules.

## Not Yet Final

- CSR address width is now 16 bits in the matrix-top target path. Legacy old-top
  decode remains outside the matrix-top target.
- Shared TDC `max_hits`, slow RO code, fast RO code, `fifo_clr`, and
  `soft_reset` are CSR-plumbed into the three matrix-top TDC wrappers.
- Position path now supports raw bitmap mode and fixed cluster mode from frozen
  snapshots. Compact cluster packets and a deeper position queue remain
  deferred.
- Matrix configuration readback still mirrors write data for write commands and samples `Dout` on `clk_cfg_40m`; it does not yet use returned `Cout` edges.
- There is no real output FIFO between bundle TX and DDR16 pairer.
- Event admission does not yet reserve FIFO space for worst-case events.
- Full-top BOTH test and directed R/Y/B skew campaign are missing from the local readiness gate.
- Xcelium has not been run locally.
- Genus/Innovus scripts for matrix-top ASIC preparation are not yet present.

## Final V1 Feature List

- 16-bit CSR address path from I2C pointer through matrix-top CSR decode.
- Mode/config writes accepted only at `safe_idle`; rejected with `PATH_BUSY` otherwise.
- Shared TDC configuration registers:
  - `max_hits`, default 15.
  - shared slow RO code.
  - shared fast RO code.
  - optional safe `soft_reset` pulse.
  - optional safe `fifo_clr` pulse.
  - calibration axis mask.
- Position packet mode CSR:
  - raw bitmap.
  - cluster.
  - optional compact cluster if the existing packet format is cleanly reused.
- Matrix configuration physical readback:
  - `WRITE_COLUMN_64`.
  - `READ_COLUMN_64`.
  - `GLOBAL_FILL_0`.
  - `GLOBAL_FILL_1`.
  - returned `Cout` edge used to qualify `Dout` sampling.
  - timeout/error status if `Cout` does not return.
- Output FIFO:
  - 512 x 16-bit initial depth.
  - level/free-space/almost-full CSR status.
  - admission blocked when free space is below the worst-case event reservation.
- Verification:
  - CSR16 and I2C 16-bit tests.
  - shared TDC config tests.
  - raw and cluster position tests.
  - Cout readback tests.
  - output FIFO pressure tests.
  - BOTH full-top test with real wrappers.
  - directed R/Y/B skew campaign.
  - reset-during-event and reset-during-matrix-config tests.

## Protected Boundaries

Do not modify:

- `MPTDC/rtl/top/mptdc_axis_core.sv`
- `MPTDC/rtl/top/mptdc_core.sv`
- `MPTDC/rtl/async/*`
- `MPTDC/rtl/pd/*`
- `MPTDC/rtl/osc/*`
- `MPTDC/rtl/ctrl/*`
- `MPTDC/rtl/readout/*`
- `TOP/rtl/spadmic_top_v1.sv`
- root references: `ParameterDefs.sv`, `multi_ShiftRegisterChain_cfg_v1.sv`, `pixel_readout.pdf`

MPTDC integration changes should stay in TOP-owned wrappers, coordinators, and CSR plumbing.

## Phase Ordering

1. Documentation and roadmap.
2. CSR/I2C 16-bit address migration.
3. Shared TDC configuration plumbing.
4. Snapshot-driven position raw/cluster integration.
5. Matrix configuration physical Cout/Dout readback.
6. Output FIFO and event admission reservation.
7. Local open-source verification expansion.
8. Xcelium server script preparation.
9. CDC/RDC/reset pre-Genus review.
10. Genus OOC script preparation.
11. Innovus OOC/top floorplan script preparation.
12. Server result review and convergence loop.

## Tests Required Before Genus

Genus should not be used as a substitute for functional verification. Before a meaningful matrix-top OOC Genus run:

- `git diff --check` passes.
- Verilator lint passes for `spadmic_top_v1` and `spadmic_top_matrix_v1`.
- Matrix-top unit tests pass for CSR16, I2C16, shared TDC config, position modes, Cout readback, FIFO, coordinator, snapshot, reset, DDR16 pairer, and event bundle TX.
- Full-top tests pass for TDC-only, position-only, BOTH, calibration, mode transitions, reset during event, and reset during matrix config.
- Directed skew campaign is either passing or has documented open bugs.
- Xcelium server matrix-top regression is run and reviewed when available.

## Xcelium-Before-Genus Policy

Xcelium is required before treating Genus results as implementation-ready evidence because:

- Cadence event scheduling can expose issues that Verilator does not.
- `always_ff`, enum, packed-array, and interface/filelist portability must be checked in the target simulator.
- The current local environment cannot run `xrun`.

Local Verilator pass means "open-source bring-up confidence", not Xcelium pass.

## Genus OOC Plan

Genus OOC is a typical-only feasibility step for matrix-top blocks. It must:

- use `clk_sys = 6.25 ns`;
- use `clk_cfg_40m = 25 ns`;
- use `clk_ref_40m = 25 ns` only where relevant;
- classify asynchronous matrix inputs instead of hiding them with broad false paths;
- preserve ASYNC_REG synchronizers;
- preserve OR64 structure sufficiently to report line-to-line path spread;
- report warnings, latches, unresolved modules, unconstrained clocks, design-rule violations, area, QoR, and timing.

It must not claim final top closure, MMMC, extraction, DRC/LVS, PEX, or DDR/matrix macro timing signoff.

## Innovus Feasibility Plan

Innovus planning must use:

- matrix LEF on server: `/group/validmgr/PROJET/Prj_xh018/ksabra/lef/matrice3.lef`;
- normalized pin CSV in repo: `position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv`;
- `ll_*` normalized coordinates, not raw LEF-origin coordinates.

Floorplan intent:

- place `matrice3` left and roughly vertically centered;
- place three MPTDC axes to the right, close together;
- reserve internal-right corridors for R/B/Y/Yz/Rz/Bz pins reported by the CSV;
- place reset drivers near reset pin banks;
- place Din/Cin drivers near bottom config pins;
- place Dout/Cout capture near top config pins;
- place FIFO/bundle/TX north or north-east for north-side DDR outputs;
- place CSR/I2C/control/reset bottom;
- reserve bottom-right PLL placeholder.

## Signoff Limitations

This roadmap does not claim:

- final RTL completeness;
- Xcelium regression pass until server logs prove it;
- CDC/RDC signoff;
- Genus timing closure;
- Innovus routed closure;
- DRC/LVS/PEX;
- MMMC;
- final DDR macro timing;
- final matrix macro timing;
- final board timing.
