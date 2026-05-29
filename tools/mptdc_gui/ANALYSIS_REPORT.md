# MPTDC RTL Architecture Analysis Report

Generated for the local interactive architecture GUI in `tools/mptdc_gui/`.

This report is repo-grounded. Claims marked **direct** come from parsed RTL or
compile scripts. Claims marked **documented** come from maintained project docs.
Claims marked **inferred** are static-analysis conclusions from module
definitions and instantiations. Claims marked **uncertain** require manual
review or a fresh run.

## 1. Active Top Module

**Direct finding:** the active standalone MPTDC top is `mptdc_top_asic`.

Evidence:

- `MPTDC/README.md:26-27` names `rtl/top/mptdc_top_asic.sv` as the top level and `rtl/top/mptdc_core.sv` as core integration.
- `MPTDC/rtl/filelist.f:1-35` compiles package, CDC, oscillator, PD, async, control, readout, then `rtl/top/mptdc_core.sv` and `rtl/top/mptdc_top_asic.sv`.
- `MPTDC/ci/run_smoke.sh:46` and `MPTDC/ci/run_full_regression.sh:50` lint/compile with `--top-module mptdc_top_asic`.
- `MPTDC/rtl/top/mptdc_top_asic.sv:25` declares `module mptdc_top_asic`.

**Direct finding:** `mptdc_vernier_top_silicon` is not present in the repo files searched by `rg` across RTL, docs, filelists, scripts, and Tcl. The expected name is therefore not the active top in this checkout.

**Integration context:** the active full-chip SPADMIC top is `spadmic_top_v1`, which instantiates three preserved `mptdc_top_asic` axes through `spadmic_tdc_axis_wrapper`.

Evidence:

- Root `README.md:14` lists three preserved `mptdc_top_asic` TDC axes.
- Root `README.md:40` describes the TDC path as `spadmic_tdc_axis_wrapper -> mptdc_top_asic -> acquisition records -> spadmic_tdc_packet_adapter -> ARB`.
- Root `README.md:57-61` shows full-chip lint using `MPTDC/rtl/filelist.f`, `TOP/filelist.f`, and `--top-module spadmic_top_v1`.
- `TOP/rtl/spadmic_top_v1.sv:282-356` instantiates three per-axis wrappers.
- `TOP/rtl/spadmic_tdc_axis_wrapper.sv:61-85` instantiates `mptdc_top_asic`, ties off local narrow output, enables `shared_readout_en_i`, and exports `acq_*`.

## 2. Repository Map

Top-level folders relevant to MPTDC architecture:

- `MPTDC/rtl/` - active standalone MPTDC RTL compiled by `MPTDC/rtl/filelist.f`.
- `MPTDC/tb/` - unit, integration, characterization, and VIP harnesses.
- `MPTDC/scripts/` - simulation, campaign, analysis, calibration, report flows.
- `MPTDC/ci/` - smoke, full regression, VIP smoke, coverage, Xcelium regression wrappers.
- `MPTDC/docs/` - active architecture, output protocol, CSR, verification, calibration, review, runbook, status, shared-readout export, block guide.
- `MPTDC/report_artifacts/` and `MPTDC/results/` - committed characterization/calibration result artifacts.
- `MPTDC/analog_handoff/`, `MPTDC/pnr/`, `MPTDC/syn/`, `docs/timing_closure/` - oscillator/PD macro, timing, CDC, PnR, and signoff collateral.
- `TOP/rtl/`, `TOP/docs/` - chip-level integration around three MPTDC axes.
- `arb/rtl/` - packet adapters, stream buffers, packet arbiter, and correlated TX used by TOP.
- `Rapport_5PSM_KS/` and `charac/` - thesis/report sources and characterization narrative; useful as secondary evidence, not a substitute for RTL.

Key active MPTDC RTL files from `MPTDC/rtl/filelist.f:4-35`:

- `rtl/pkg/mptdc_pkg.sv`
- `rtl/cdc/mptdc_reset_sync.sv`
- `rtl/cdc/mptdc_pulse_sync.sv`
- `rtl/cdc/mptdc_gray_cnt_sync.sv`
- `rtl/cdc/mptdc_sync_fifo.sv`
- `rtl/osc/mptdc_osc_model.sv`
- `rtl/osc/mptdc_osc_stub.sv`
- `rtl/osc/mptdc_osc_wrapper.sv`
- `rtl/pd/mptdc_pd_cell.sv`
- `rtl/async/mptdc_stop_capture_async.sv`
- `rtl/async/mptdc_async_frontend_v2.sv`
- `rtl/async/mptdc_hit_capture_bridge.sv`
- `rtl/async/mptdc_context_bank.sv`
- `rtl/ctrl/mptdc_input_mux.sv`
- `rtl/ctrl/mptdc_meas_ctrl.sv`
- `rtl/ctrl/mptdc_drain_ctrl.sv`
- `rtl/ctrl/mptdc_watchdog.sv`
- `rtl/readout/mptdc_tconv_reco.sv`
- `rtl/readout/mptdc_narrow16_tx_v2.sv`
- `rtl/readout/mptdc_csr_minimal.sv`
- `rtl/top/mptdc_core.sv`
- `rtl/top/mptdc_top_asic.sv`

Key testbench files:

- Unit benches under `MPTDC/tb/unit/`: reset sync, watchdog, input mux, measurement control, drain control, context bank, gray counter sync, hit capture bridge, narrow serializer.
- Integration benches under `MPTDC/tb/int/`: `tb_single_conv`, `tb_multi_conv_stress`, `tb_deadtime_measure`, `tb_cal_inject`, `tb_backpressure`, `tb_lossless_pressure`, `tb_watchdog_recovery`, `tb_start_wdt`, `tb_overflow_count`, `tb_firsthit_mode`, and characterization benches.
- VIP harness and interfaces under `MPTDC/tb/vip/` and `MPTDC/tb/tests/mptdc_vip_tb.sv`.
- `MPTDC/tb/vip/filelist.f:1-20` compiles the VIP interfaces, package, and harness.

Key scripts:

- `MPTDC/scripts/sim/run_tb.sh`
- `MPTDC/scripts/sim/run_vip_test.sh`
- `MPTDC/scripts/sim/run_campaign.sh`
- `MPTDC/scripts/sim/run_characterization_baseline.sh`
- `MPTDC/scripts/sim/run_fixed_delay_campaign.sh`
- `MPTDC/scripts/sim/run_characterization_overnight.sh`
- `MPTDC/scripts/sim/run_report_flow.sh`
- `MPTDC/scripts/analysis/analyze_campaign.py`
- `MPTDC/scripts/analysis/analyze_fixed_delay_campaign.py`
- `MPTDC/scripts/analysis/analyze_tdc_linearity.py`
- `MPTDC/scripts/analysis/generate_report_plots.py`
- `MPTDC/scripts/calibration/calibrate_6d_lut.py`
- `MPTDC/scripts/calibration/ablate_lut_observables.py`

Key documentation:

- `MPTDC/docs/01_ARCHITECTURE.md`
- `MPTDC/docs/02_OUTPUT_PROTOCOL.md`
- `MPTDC/docs/03_CSR_MAP.md`
- `MPTDC/docs/04_VERIFICATION.md`
- `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md`
- `MPTDC/docs/06_DEADTIME_ANALYSIS.md`
- `MPTDC/docs/07_DESIGN_REVIEW.md`
- `MPTDC/docs/10_SHARED_READOUT_EXPORT.md`
- `MPTDC/docs/11_BLOCK_GUIDE.md`
- `TOP/docs/01_ACTIVE_ARCHITECTURE.md`
- `TOP/docs/08_TX_INTERFACE.md`
- `docs/timing_closure/cdc_async_waiver_package.md`
- `docs/timing_closure/oscillator_macro_contract.md`
- `docs/timing_closure/pd_matrix_physical_contract.md`
- `charac/mptdc_characterization_report.md`

## 3. Module Hierarchy

Direct/parsed MPTDC hierarchy:

```text
mptdc_top_asic
  |- mptdc_reset_sync          u_rst_input_mux_sync
  |- mptdc_reset_sync          u_rst_csr_sync
  |- mptdc_reset_sync          u_rst_core_sync
  |- mptdc_input_mux           u_input_mux
  |- mptdc_csr_minimal         u_csr
  `- mptdc_core                u_core
       |- mptdc_reset_sync     u_rst_status_sync
       |- mptdc_reset_sync     u_rst_drain_sync
       |- mptdc_reset_sync     u_rst_fifo_sync
       |- mptdc_reset_sync     u_rst_tx_sync
       |- mptdc_reset_sync     u_rst_wdt_sync
       |- mptdc_reset_sync     u_rst_fast_sync
       |- mptdc_async_frontend_v2
       |- mptdc_osc_wrapper    u_osc_slow
       |- mptdc_osc_wrapper    u_osc_fast
       |- mptdc_pd_cell        64 generated cells
       |- mptdc_stop_capture_async
       |- mptdc_gray_cnt_sync  slow counter/snapshot
       |- mptdc_gray_cnt_sync  fast counter
       |- mptdc_meas_ctrl
       |- mptdc_hit_capture_bridge
       |- mptdc_context_bank
       |- mptdc_drain_ctrl
       |- mptdc_sync_fifo
       |- mptdc_narrow16_tx_v2
       `- mptdc_watchdog
```

Evidence:

- `MPTDC/rtl/top/mptdc_top_asic.sv:116-189` instantiates reset syncs, input mux, CSR, and core.
- `MPTDC/rtl/top/mptdc_core.sv:182-217` instantiates per-domain reset synchronizers.
- `MPTDC/rtl/top/mptdc_core.sv:358-584` instantiates frontend, oscillators, PD cells, stop capture, counters, measurement control, hit bridge, context bank, drain control, FIFO, narrow serializer, and watchdog.
- `MPTDC/rtl/top/mptdc_core.sv:406-417` generates the `NE x NE` PD matrix and maps `CELL = ns * NE + nf`.

Parameters and fixed architectural constants:

- `CLK_SYS_HZ = 160_000_000`, `NE = 8`, `OSC_TS_SLOW_PS = 55`, `OSC_TS_FAST_PS = 50` in `MPTDC/rtl/pkg/mptdc_pkg.sv:31-34`.
- `PD_N = NE * NE`, `PH_W = clog2(NE)` in `MPTDC/rtl/pkg/mptdc_pkg.sv:36-40`.
- `MAX_HITS = 15`, `MAX_HITS_W = 4`, `FIFO_DEPTH = 64` in `MPTDC/rtl/pkg/mptdc_pkg.sv:82-87`.
- `N_CTX = 2`, `CTX_W = 1` in `MPTDC/rtl/pkg/mptdc_pkg.sv:97-102`.
- `mptdc_core` fatal-checks `NE == 8`, `N_CTX == 2`, and `MAX_HITS <= 15` at elaboration in `MPTDC/rtl/top/mptdc_core.sv:65-72`.

Compiled support or legacy/unused items:

- `mptdc_pulse_sync` is compiled support but not instantiated in the live top path; see `MPTDC/docs/01_ARCHITECTURE.md:321-327` and `MPTDC/docs/07_DESIGN_REVIEW.md:135`.
- `mptdc_tconv_reco` is compiled but not instantiated in the active top path; see `MPTDC/docs/01_ARCHITECTURE.md:625-631` and `MPTDC/docs/07_DESIGN_REVIEW.md:149`.
- `mptdc_osc_model` is simulation-only; `mptdc_osc_stub` is a synthesis placeholder until the real oscillator macro exists; see `MPTDC/docs/01_ARCHITECTURE.md:382-407`, `MPTDC/docs/07_DESIGN_REVIEW.md:139-140`, and `MPTDC/rtl/osc/mptdc_osc_wrapper.sv:62-101`.
- `OUT_MODE_RAW_TIMESTAMP` and `OUT_MODE_FULL` are retained legacy CSR codes ignored by maintained RTL; see `MPTDC/rtl/pkg/mptdc_pkg.sv:132-136` and `MPTDC/docs/02_OUTPUT_PROTOCOL.md:109-113`.

## 4. Major Dataflow

### 4.1 External Inputs and Source Selection

`mptdc_top_asic` receives async SPAD START/STOP, async CAL START/STOP, CSR bus, narrow ready, optional shared-readout ready, and reset in `MPTDC/rtl/top/mptdc_top_asic.sv:29-65`.

`mptdc_input_mux` selects SPAD or CAL async inputs based on `input_sel_i`; it is a combinational async mux and assumes the selection is stable during conversion.

Evidence:

- `MPTDC/rtl/ctrl/mptdc_input_mux.sv:19-24` documents stable selection intent.
- `MPTDC/rtl/ctrl/mptdc_input_mux.sv:31-50` declares SPAD/CAL inputs and assigns selected async outputs.
- CSR packs `cfg_o.input_sel` and hardwires `cfg_o.out_mode` to `OUT_MODE_RAW_FEATURES` in `MPTDC/rtl/readout/mptdc_csr_minimal.sv:71-77`.

### 4.2 START Path

The frontend accepts `START` when a context is free, `conv_arm_i` is high, no START is already latched, no clear is active, and no reject has been latched for that input pulse.

Evidence:

- Context free detection and allocation are in `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:76-96`.
- `start_accept_level` and `start_reject_set_level` are defined in `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:98-113`.
- START latch is set by accepted async START and reset by clear/reset in `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:116-123`.
- Active context captures allocation on accepted START in `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:155-162`.
- Slow oscillator enable is `start_latched_q` in `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:191-200`.

### 4.3 STOP Path and Oscillator Control

STOP is accepted only after START is latched. STOP or the slow-domain missing-STOP timeout sets `stop_latched_q`. The fast oscillator enable is `stop_latched_q | osc_keep_alive_i`, and PD enable is `start_latched_q & stop_latched_q`.

Evidence:

- STOP latch logic is in `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:144-151`.
- Slow/fast oscillator and PD enable assignments are in `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:191-201`.
- Missing-STOP watchdog lives in the slow oscillator domain and injects a held synthetic STOP in `MPTDC/rtl/top/mptdc_core.sv:225-258`.
- STOP boundary metadata is captured on `posedge stop_async_i` in `MPTDC/rtl/async/mptdc_stop_capture_async.sv:41-49`.

### 4.4 Phase Detector and Counter Path

The slow and fast oscillators produce `slow_phase[7:0]` and `fast_phase[7:0]`. The slow counter is clocked by `slow_phase[0]` and has async STOP snapshot support. The fast counter is clocked by `osc_fast_ph0`. Each PD cell samples one gated slow phase on one fast phase tap and latches the first crossing plus fast count.

Evidence:

- Oscillator wrappers are instantiated at `MPTDC/rtl/top/mptdc_core.sv:381-395`.
- `mptdc_osc_wrapper` exposes `phase[NE-1:0]`, `phase0_guard_o`, and `phase7d_probe_o` in `MPTDC/rtl/osc/mptdc_osc_wrapper.sv:34-43`.
- PD enable is gated as `fe_pd_enable & meas_pd_gate` in `MPTDC/rtl/top/mptdc_core.sv:349-351`.
- The generated PD matrix wires `pd_enable_gated & slow_phase[ns]`, `fast_phase[nf]`, and `nfast_src_count` into each cell in `MPTDC/rtl/top/mptdc_core.sv:404-417`.
- `mptdc_pd_cell` documents and implements slow-on-fast sampling and falling-edge detection in `MPTDC/rtl/pd/mptdc_pd_cell.sv:10-32` and `MPTDC/rtl/pd/mptdc_pd_cell.sv:83-103`.
- Slow and fast counters are `mptdc_gray_cnt_sync` instances in `MPTDC/rtl/top/mptdc_core.sv:438-476`.

### 4.5 Snapshot, Context, Drain, FIFO, and Output Path

The held measurement image is sampled into `clk_sys`, committed into a two-entry context bank, marked drainable, scanned by drain control into META/HIT records, written to an FWFT sync FIFO, then consumed either by local `mptdc_narrow16_tx_v2` or by the shared-readout export interface.

Evidence:

- `mptdc_meas_ctrl` emits `snapshot_en`, `capture_en`, `fe_clear`, `pd_clear`, and `pd_gate` in `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:165-179`.
- `mptdc_hit_capture_bridge` samples the static PD/counter/STOP-boundary image in `MPTDC/rtl/async/mptdc_hit_capture_bridge.sv:33-50`.
- `mptdc_context_bank` writes one frozen snapshot on capture and reads by `read_ctx_i` in `MPTDC/rtl/async/mptdc_context_bank.sv:34-52`.
- Context drain flags cross into `clk_sys` via a 2-FF synchronizer in `MPTDC/rtl/top/mptdc_core.sv:280-290`.
- `mptdc_drain_ctrl` emits META/HIT records and releases the context in `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:13-23` and `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:173-222`.
- The FIFO is instantiated in `MPTDC/rtl/top/mptdc_core.sv:545-559`.
- Shared-readout selection is in `MPTDC/rtl/top/mptdc_core.sv:563-568`: shared mode drains on `acq_ready_i`, exposes `acq_valid_o`, and bypasses the local serializer.
- The local serializer is instantiated in `MPTDC/rtl/top/mptdc_core.sv:571-580`.
- Shared-readout behavior is documented in `MPTDC/docs/10_SHARED_READOUT_EXPORT.md:37-52` and record ordering in `MPTDC/docs/10_SHARED_READOUT_EXPORT.md:99-115`.

## 5. Major Control Flow

### 5.1 Measurement FSM

The live `mptdc_meas_ctrl` sequence is:

```text
ST_M_IDLE -> ST_M_MEASURE -> ST_M_SNAPSHOT -> ST_M_COUNT
          -> ST_M_EVAL -> ST_M_CAPTURE -> ST_M_CLEAR -> ST_M_IDLE
```

Evidence:

- State encodings are defined in `MPTDC/rtl/pkg/mptdc_pkg.sv:153-161`.
- Transitions are implemented in `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:119-133`.
- `ST_M_IDLE` waits for `meas_active_i` before moving to `ST_M_MEASURE` in `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:122-125`.
- Output pulses are tied to state in `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:165-176`.
- Assertions check snapshot/capture/clear state consistency in `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:182-193`.

Important detail: the package still contains `ST_M_STOP_OSC` at `MPTDC/rtl/pkg/mptdc_pkg.sv:158`, but the implemented FSM in `mptdc_meas_ctrl.sv` does not transition through it. Treat `ST_M_STOP_OSC` as a retained/legacy enum value unless future RTL proves otherwise.

### 5.2 Drain FSM

The drain sequence is:

```text
ST_D_IDLE -> ST_D_META -> ST_D_EMIT -> ST_D_SCAN -> ST_D_EMIT ... -> ST_D_EOC -> ST_D_IDLE
```

Evidence:

- Drain states are defined in `MPTDC/rtl/pkg/mptdc_pkg.sv:167-172`.
- Drain comments describe `IDLE`, `META`, `SCAN`, `EMIT`, and `EOC` in `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:13-23`.
- `ctx_selectable` is masked by `released_mask` in `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:65-90`.
- META and HIT record construction is in `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:137-156`.
- Next-state and output decode are in `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:173-222`.
- Context release and `conv_done_o` occur in `ST_D_EOC` in `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:219-222`.

### 5.3 Serializer FSM

The local narrow serializer sequence is:

```text
S_IDLE -> S_HEADER -> S_HIT_FETCH -> S_HIT_W0 -> S_HIT_W1
       -> ... -> S_EOC -> S_IDLE
```

Evidence:

- Serializer states are in `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:47-54`.
- Header/HIT/EOC transitions are in `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:148-203`.
- Valid/data output decode is in `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:211-252`.
- Ready/valid stability assertions are in `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:259-274`.

### 5.4 Reset, Clear, Done, Busy, and Overflow

Reset is async asserted and locally synchronized into several reset leaves. Soft reset is implemented by a short hold on `local_async_rst_n`.

Evidence:

- `mptdc_top_asic` creates `local_async_rst_n` from pad reset and `soft_rst_hold_q` in `MPTDC/rtl/top/mptdc_top_asic.sv:90-99`.
- Reset leaves are instantiated in `MPTDC/rtl/top/mptdc_top_asic.sv:116-132` and `MPTDC/rtl/top/mptdc_core.sv:182-217`.
- FIFO clear is synchronous through `fifo_clr_i` in `MPTDC/rtl/top/mptdc_core.sv:545-559`.
- CSR write fields for `conv_arm`, `fifo_clr`, and `soft_rst` are in `MPTDC/rtl/readout/mptdc_csr_minimal.sv:102-105`.
- `status_o.ready` and `status_o.busy` are assigned in `MPTDC/rtl/top/mptdc_core.sv:617-621`.
- Conversion count, last hit count/flags, and rejected START overflow count are updated in `MPTDC/rtl/top/mptdc_core.sv:596-609`.
- `CSR_OVF_COUNT` reads `status_i.ovf_count` in `MPTDC/rtl/readout/mptdc_csr_minimal.sv:196-197`.

First-hit/multihit behavior:

- The RTL no longer has a separate first-hit mode enum; `max_hits = 1` exercises the fast-close path. This is documented in `MPTDC/docs/04_VERIFICATION.md:32-36`.
- `mptdc_meas_ctrl` sets `closed_by_fast_maxhit` when `effective_max_hits == 1` and any hit is observed, and sets `closed_by_maxhits` when configured max hits are reached in `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:108-115`.
- `pd_gate_o` remains high only in `IDLE` and `MEASURE`, freezing additional hits after snapshot begins in `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:175-176`.

## 6. Timing and CDC

Clock/reset domains:

- `clk_sys`: CSR, measurement FSM, hit-capture bridge, context bank, drain FSM, FIFO, serializer, global watchdog. Documented in `MPTDC/docs/01_ARCHITECTURE.md:89`.
- `osc_fast_ph0`: fast counter source clock and PD sampling reference. Documented in `MPTDC/docs/01_ARCHITECTURE.md:90`.
- `fast_phase[n]`: local PD-cell sampling clocks. Documented in `MPTDC/docs/01_ARCHITECTURE.md:91`.
- `slow_phase[n]`: sampled phase taps and slow counter clock. Documented in `MPTDC/docs/01_ARCHITECTURE.md:92`.
- Async event domain: START/STOP latch set/reset and STOP capture. Documented in `MPTDC/docs/01_ARCHITECTURE.md:93`.

CDC mechanisms:

- Reset synchronizers: conventional async-assert/sync-deassert, described in `MPTDC/docs/01_ARCHITECTURE.md:306-312` and instantiated in top/core reset leaves.
- Gray counters: `mptdc_gray_cnt_sync` counts in source domain, Gray-codes, synchronizes, and optionally snapshots; see `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv:43-64`.
- Async STOP snapshot: optional `USE_ASYNC_SNAPSHOT` path captures slow Gray counter on STOP; comments emphasize it is central to STOP-side `Nslow` correctness in `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv:138-144`.
- Context drain flag: `fe_ctx_drain` crosses into `clk_sys` through 2 FFs in `MPTDC/rtl/top/mptdc_core.sv:280-290`.
- Rejected START accounting: a pending latch plus sync pipe avoids missing narrow reject pulses; see `MPTDC/rtl/top/mptdc_core.sv:298-321`.
- Wide held-image CDC: PD/counter/STOP metadata remain static until `mptdc_hit_capture_bridge` samples them, then context commit and clear follow. This is documented as static-bus CDC in `MPTDC/docs/01_ARCHITECTURE.md:488-527` and waiver notes in `docs/timing_closure/cdc_async_waiver_package.md:74-84`.

Timing-sensitive and physical macro assumptions:

- `MPTDC/docs/07_DESIGN_REVIEW.md:205-212` states this is not a normal single-clock block; it mixes `clk_sys`, oscillator phase taps, and async event timing.
- `MPTDC/docs/07_DESIGN_REVIEW.md:350-362` says no real oscillator implementation exists in the active synthesis path, and generated-clock timing/startup/phase ordering remain abstract at the physical boundary.
- `docs/timing_closure/oscillator_macro_contract.md:3-7` identifies real oscillator Liberty/LEF contracts as a signoff blocker.
- `docs/timing_closure/oscillator_macro_contract.md:45-51` requires classifying oscillator/PD paths as real macro-timed, intentionally async/event, or false/test paths.
- `docs/timing_closure/pd_matrix_physical_contract.md:77-86` documents placement/routing intent for fast and slow taps around the PD matrix.

Uncertain CDC/timing points:

- Standard CDC/STA signoff is not proven by this repo alone. `MPTDC/docs/07_DESIGN_REVIEW.md:631-634` says the active RTL behaves coherently in simulation but the repo does not prove the async/generated-clock implementation is ready for standard ASIC signoff.
- Recovery/removal around async clear on oscillator-clocked PD/counter state needs explicit signoff proof; see `MPTDC/docs/07_DESIGN_REVIEW.md:463-473`.
- Physical oscillator macro behavior and phase skew are not represented by the synthesis stub; see `MPTDC/docs/07_DESIGN_REVIEW.md:354-362`.

## 7. Event and Output Format

The maintained standalone packet is fixed 16-bit ready/valid v2.7:

```text
Header
HIT0 W0
HIT0 W1
...
EOC
```

Evidence:

- `MPTDC/docs/02_OUTPUT_PROTOCOL.md:9-17` defines the active packet as header, two words per hit, and EOC; fixed cycle spacing is not guaranteed.
- Header bit layout is documented in `MPTDC/docs/02_OUTPUT_PROTOCOL.md:29-47` and implemented in `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:91-100`.
- Hit W0 layout is documented in `MPTDC/docs/02_OUTPUT_PROTOCOL.md:65-77` and implemented in `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:103-106`.
- Hit W1 layout includes `ns`, `nf`, reserved bits, and `stop_phase_disc`; see `MPTDC/docs/02_OUTPUT_PROTOCOL.md:79-101` and `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:108-117`.
- EOC layout is documented in `MPTDC/docs/02_OUTPUT_PROTOCOL.md:115-122` and implemented in `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:119-121`.
- `nfast_snap`, `nfast_stop`, `pd_idx`, and `event_seq` are not part of the live packet contract; see `MPTDC/docs/02_OUTPUT_PROTOCOL.md:15` and `MPTDC/docs/02_OUTPUT_PROTOCOL.md:133-134`.

Shared-readout TOP packetization:

- Each MPTDC axis exports acquisition records; TOP `spadmic_tdc_packet_adapter` reconstructs the same fixed v2.7 packet before packet-atomic arbitration.
- Evidence: `TOP/rtl/spadmic_tdc_axis_wrapper.sv:79-85`, `arb/rtl/spadmic_tdc_packet_adapter.sv:64-78`, `arb/rtl/spadmic_tdc_packet_adapter.sv:142-164`, and `TOP/docs/01_ACTIVE_ARCHITECTURE.md:154-164`.

## 8. Verification Evidence

Verification assets:

- Unit benches are listed in `MPTDC/docs/04_VERIFICATION.md:217-221`.
- Integration benches and their intent are listed in `MPTDC/docs/04_VERIFICATION.md:227-236`.
- Campaign collector and sweep flow are documented in `MPTDC/docs/04_VERIFICATION.md:242-249`.
- VIP architecture and entrypoints are described in `MPTDC/docs/04_VERIFICATION.md:36-88`.
- VIP interface assertions are described in `MPTDC/docs/04_VERIFICATION.md:180-190` and `MPTDC/tb/vip/README.md:337-339`.
- Embedded RTL safety assertions are described in `MPTDC/docs/04_VERIFICATION.md:193-208`.
- Coverage and signoff interpretation are documented in `MPTDC/docs/04_VERIFICATION.md:478-493`.

What is verified according to docs:

- Input mux routing, reset sync, watchdog, context bank retention, serializer formatting.
- End-to-end conversion, repeated conversion sequencing, deadtime trends, CAL injection, backpressure, watchdog recovery, start watchdog, overflow accounting, fast-close compatibility.
- VIP packet grammar, scoreboard checks, backpressure behavior, start-only watchdog, overflow status, global watchdog, CSR readback, hard reset readback, jitter robustness, ref-stop qualified flow, and max-hit matrix scenarios.

Gaps / cautions:

- `MPTDC/docs/04_VERIFICATION.md:499-504` lists remaining gaps including simulator/hardware dependence and Cadence reruns.
- `MPTDC/docs/04_VERIFICATION.md:462-468` says oscillator assumptions must come from calibration/campaign manifests or macro contract rather than test code alone.
- The committed `MPTDC/artifacts/overnight/vip/vip_summary.json:2-4` reports `total=4096`, `pass=0`, `fail=4096`. This conflicts with current README status claims and should be treated as stale or failed artifact evidence until rerun and explained.

## 9. Calibration and Characterization Evidence

The active architecture is explicitly offline-calibrated: silicon exports raw features and host/FPGA software reconstructs and corrects timestamps.

Evidence:

- `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:9-17` says correction, fitting, and PVT compensation are host-side; no on-chip LUT is required for normal operation.
- Exported raw fields are documented in `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:20-32`.
- Packet-visible field mapping for calibration is documented in `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:177-186`.
- Maintained campaign commands are documented in `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:100-128`.
- 6D mean-correction LUT method is selected in `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:150-156`.
- LUT key and inference formula are documented in `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:156-169`.
- Calibration runner and outputs are documented in `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:260-276`.
- Final report plot generation is documented in `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:278-292`.
- The committed final v2.7 boundary-fix report uses `"STOP-discriminator Mean-Correction LUT"` in `MPTDC/report_artifacts/final_protocol_v27_boundaryfix/calibration/calibration_report.json:2`.
- That report lists the LUT key in `MPTDC/report_artifacts/final_protocol_v27_boundaryfix/calibration/calibration_report.json:3-12`.
- It reports pre-calibration RMSE `1940.324844527017 ps` and post-calibration RMSE `18.555103320036334 ps` in `MPTDC/report_artifacts/final_protocol_v27_boundaryfix/calibration/calibration_report.json:81-100`.
- It reports `slow_boundary_inc` present and nonzero in about `0.1225%` of held-out rows in `MPTDC/report_artifacts/final_protocol_v27_boundaryfix/calibration/calibration_report.json:72-80`.
- The corresponding characterization manifest is `completed` and reports `48000063` campaign rows in `MPTDC/report_artifacts/final_protocol_v27_boundaryfix/characterization_manifest.json:3` and `MPTDC/report_artifacts/final_protocol_v27_boundaryfix/characterization_manifest.json:75`.

Limitations:

- Calibration results are pre-silicon and depend on behavioral oscillator assumptions unless updated with silicon or extracted macro evidence.
- `MPTDC/docs/12_CHARACTERIZATION_OVERNIGHT.md:154-158` says RTL characterization validates packet structure, raw tuple coverage, digital deadtime sequencing, context pressure, and output backpressure, but is not silicon proof.
- `charac/mptdc_characterization_report.md:307` warns gate/SDF should not be used to claim oscillator fine resolution unless oscillator and PD matrix are represented by meaningful macro/timing models.

## 10. GUI Architecture Proposed

The GUI should be a local, dependency-light Python web app:

- `rtl_parser.py` builds `architecture_db.json` from RTL, docs, scripts, reports, and curated evidence.
- `diagram_generator.py` generates SVG diagrams and Markdown/HTML export artifacts from the JSON database.
- `app.py` serves a local interactive HTML/JS application through Python's standard-library HTTP server.
- `presentation_steps.json` stores the step-by-step acquisition animation sequence.
- `assets/` stores generated SVG diagrams.
- `exports/` stores Markdown, JSON, SVG, DOT, and HTML exports.

Views to implement:

- Architecture overview with clickable blocks.
- Dataflow animation for one acquisition.
- Control-flow explorer for measurement, drain, serializer, and TOP sequencer flow.
- Signal explorer with search, producer/consumer evidence, direction, width, and classification.
- Timing/CDC view with clocks, resets, crossings, synchronizers, and uncertainties.
- Event/output-format view with packet bit layout and shared-readout differences.
- Verification view with testbenches, scripts, assertions, coverage, and gaps.
- Calibration view with raw data flow, LUT generation, metrics, and references.
- Export mode for SVG/DOT/Markdown/HTML/JSON artifacts.

## 11. High-Value Uncertain Points for Manual Review

1. `mptdc_vernier_top_silicon` is absent; if this name exists in another branch or generated netlist, it is outside the current checkout.
2. `ST_M_STOP_OSC` remains in the package enum but is not used by the current measurement FSM.
3. `phase7d_probe_o`/`phase7d_snap` are diagnostic helpers and not part of live packet output; confirm whether future calibration still wants them.
4. The committed VIP overnight summary reports all failures, while README/docs claim newer smoke/regression success. Treat old artifacts as stale until a fresh local/server run resolves the contradiction.
5. Physical oscillator macro, generated-clock constraints, recovery/removal checks, and async CDC waiver closure remain signoff blockers.
6. TOP shared-readout packetization preserves MPTDC acquisition kernels but changes final egress behavior; any standalone vs TOP presentation should call out that split.

## 12. Correction du parsing SystemVerilog

Avant correction, `tools/mptdc_gui/rtl_parser.py` tronquait certains noms de ports lorsque la largeur SystemVerilog était absente. Le cas fautif était un remplacement de chaîne vide qui séparait les caractères de noms tels que `clk_sys`, ce qui produisait des ports visibles comme `s`, `n`, `i` ou `o` dans `architecture_db.json`.

Correction appliquée :

- Le parser retire les commentaires SystemVerilog en conservant les numéros de ligne.
- Les ports ANSI multi-lignes sont découpés sur les virgules de niveau supérieur.
- Les directions groupées sont propagées correctement.
- Les types `logic`, `wire`, `reg`, les types package tels que `mptdc_pkg::mptdc_cfg_t`, les largeurs `[N-1:0]` et les tableaux de ports sont conservés sans tronquer le nom réel.
- La recherche de la liste de ports saute maintenant les éventuelles listes de paramètres `#(...)` et les imports de module avant `(...)`.

Validation locale ajoutée :

- `mptdc_input_mux` : ports vérifiés, notamment `clk_sys`, `rst_n`, `start_spad_async_i`, `stop_spad_async_i`, `cal_start_async_i`, `cal_stop_async_i`, `input_sel_i`, `start_async_o`, `stop_async_o`.
- `mptdc_core` : ports vérifiés, notamment `clk_sys`, `rst_sys_n`, `start_async_i`, `stop_async_i`, `cfg_i`, `conv_arm_i`, `fifo_clr_i`, `narrow_valid_o`, `narrow_data_o`, `acq_valid_o`, `acq_data_o`.
- `mptdc_top_asic` : ports vérifiés avec les noms réellement présents dans le RTL courant : `clk_sys`, `async_rst_n`, `input_sel_override_en_i`, `input_sel_override_i`, `out_mode_override_en_i`, `out_mode_override_i`, `csr_*`, `narrow_*`, `acq_*`, `fifo_full_o`.
- `mptdc_async_frontend_v2` : ports vérifiés, notamment `conv_arm_i`, `start_async_i`, `stop_async_i`, `fe_clear_async_i`, `ctx_release_async_i`, `capture_en_i`, `osc_slow_en_async_o`, `osc_fast_en_async_o`, `pd_enable_async_o`, `ctx_drain_o`, `all_ctx_busy_o`, `start_rejected_o`.
- `mptdc_narrow16_tx_v2` : ports vérifiés, notamment `fifo_rd_valid_i`, `fifo_rd_data_i`, `fifo_rd_en_o`, `narrow_ready_i`, `narrow_valid_o`, `narrow_data_o`.

Après correction, la commande suivante passe :

```bash
python tools/mptdc_gui/rtl_parser.py --validate-ports
```

Limites restantes :

- Le parser reste un parseur statique robuste par heuristiques, pas un front-end SystemVerilog complet.
- Les relations producteur/consommateur complexes issues de macros, generate imbriqués ou expressions structurées restent marquées comme inférées dans l'interface.

## 13. Interface React interactive

Une nouvelle interface React/Vite est ajoutée dans `tools/mptdc_gui/frontend/`.
Elle conserve l'ancienne application Python comme fallback, mais la vue
principale devient une simulation interactive de mesure Vernier:

`Entrées → MUX → frontend → oscillateurs → matrice Vernier → capture → contexte → drain → FIFO → packets → calibration logicielle`.

Choix de conception :

- La vue principale ne dessine plus de grandes swimlanes de domaines d'horloge.
  Les informations de domaines, synchronizers, snapshots et signoff sont
  déplacées dans la vue séparée `CDC / timing`.
- Le scénario START/STOP est configurable en source `SPAD`/`CAL`, délai
  START→STOP, `max_hits`, vitesse d'animation et mode sortie `narrow16` ou
  shared `acq_*`.
- Le modèle `frontend/src/sim/vernierModel.ts` utilise les constantes parsées
  depuis `mptdc_pkg` lorsque disponibles: `NE`, `OSC_TS_SLOW_PS`,
  `OSC_TS_FAST_PS`, `DELTA_STEP`, `MAX_HITS`, `NSLOW_W`, `NFAST_W`,
  `FIFO_DEPTH`.
- Les hits, corrections et graphes affichés sont explicitement marqués comme
  `modèle pédagogique`; ils ne sont pas une simulation transistor, STA, CDC ou
  preuve silicon.
- La calibration reste décrite comme logicielle/off-chip: le RTL produit les
  données brutes et packets; le logiciel reconstruit, calibre, moyenne et
  fournit la valeur finale.
