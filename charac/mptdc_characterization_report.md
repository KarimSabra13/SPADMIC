# MPTDC RTL Architecture and Characterization Methodology

This report intentionally focuses on the committed `MPTDC` RTL and only uses `TOP` context where it changes how MPTDC acquisition records leave the chip. It separates repository facts from external methodology and from engineering recommendations.

Companion bibliography: [`mptdc_characterization_sources.bib`](mptdc_characterization_sources.bib).

## 1. Repo-grounded architecture explanation

### 1.1 Active architectural identity

The committed MPTDC is a Vernier multi-phase TDC for SPAD readout, not a generic synchronous timestamp counter. The active constants are defined in `MPTDC/rtl/pkg/mptdc_pkg.sv`: `NE = 8`, `OSC_TS_SLOW_PS = 55`, `OSC_TS_FAST_PS = 50`, `PD_N = NE * NE = 64`, `MAX_HITS = 15`, and `N_CTX = 2` (`MPTDC/rtl/pkg/mptdc_pkg.sv:30-48`, `MPTDC/rtl/pkg/mptdc_pkg.sv:80-98`). The docs state the same architecture explicitly: one slow oscillator, one fast oscillator, an `8 x 8` PD matrix, two contexts, fast-domain measurement, and system-domain drain/serialization (`MPTDC/docs/01_ARCHITECTURE.md:11-18`).

Two timing constants must not be collapsed:

| Quantity | Repo value | Meaning |
|---|---:|---|
| `DELTA_STEP` | `5 ps` | Physical Vernier tap-delay difference, `55 ps - 50 ps` (`MPTDC/rtl/pkg/mptdc_pkg.sv:44-48`). |
| `DELTA_LSB` | `10 ps` | Package-level timestamp reconstruction LSB, `2 * DELTA_STEP`, used by `vernier_tconv_ps()` (`MPTDC/rtl/pkg/mptdc_pkg.sv:47`, `MPTDC/rtl/pkg/mptdc_pkg.sv:318-327`). |
| `K_VERNIER` | `11` | `OSC_TS_SLOW_PS / DELTA_STEP`, used as the slow/fast coefficient ratio (`MPTDC/rtl/pkg/mptdc_pkg.sv:48`, `MPTDC/rtl/pkg/mptdc_pkg.sv:299-327`). |

The raw timestamp helper is:

```text
coef = (Nslow + VERNIER_NSLOW_ORIGIN_BIAS + slow_boundary_inc - 1) * K_VERNIER * NE
     + (Nfast + VERNIER_NFAST_ORIGIN_BIAS - 1) * NE
     + ns * K_VERNIER
     - nf * (K_VERNIER - 1)
     + VERNIER_COEF_BIAS

t_raw_ps = coef * DELTA_LSB
```

That is repo code, not an inferred formula (`MPTDC/rtl/pkg/mptdc_pkg.sv:294-327`). Because `DELTA_LSB = 10 ps`, timestamp results produced by `RAW_TIMESTAMP`/`FULL` are quantized through this package contract even though the oscillator tap-delay difference is 5 ps.

### 1.2 Timing domains

The design crosses intentionally among asynchronous event logic, generated oscillator clocks, and `clk_sys`:

| Domain | What runs there | Important repo evidence |
|---|---|---|
| Async START/STOP/latch domain | START acceptance, STOP latch, context allocation, oscillator enables | `mptdc_async_frontend_v2` uses explicit latches and async START/STOP inputs (`MPTDC/rtl/async/mptdc_async_frontend_v2.sv:20-60`, `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:108-185`). |
| Slow oscillator phases | Slow coarse counter source, sampled signals for PD matrix | Slow oscillator instance uses `OSC_TS_SLOW_PS`; slow counter clocks from `slow_phase[0]` (`MPTDC/rtl/top/mptdc_core.sv:320-328`, `MPTDC/rtl/top/mptdc_core.sv:373-391`). |
| Fast oscillator phases | PD sampling clocks; `fast_phase[0]` drives measurement FSM and fast counter | Fast oscillator instance uses `OSC_TS_FAST_PS`; measurement FSM clocks on `osc_fast_ph0` (`MPTDC/rtl/top/mptdc_core.sv:330-338`, `MPTDC/rtl/top/mptdc_core.sv:413-430`). |
| `clk_sys` | CSR, status, drain FSM, FIFO, local serializer, TOP shared-readout glue | `mptdc_top_asic` wraps CSR and core on `clk_sys`; drain/FIFO/TX all instantiate under `clk_sys` (`MPTDC/rtl/top/mptdc_top_asic.sv:151-190`, `MPTDC/rtl/top/mptdc_core.sv:451-511`). |

This is not a design where every cross-domain path can be treated as a normal digital CDC. The PD cells are intentional asynchronous samplers, the STOP metadata capture is intentional asynchronous capture, and the context-bank read path relies on static-data handoff after a synchronized drain flag (`MPTDC/docs/01_ARCHITECTURE.md:79-90`, `MPTDC/rtl/top/mptdc_core.sv:126-128`, `MPTDC/rtl/async/mptdc_context_bank.sv:16-23`).

### 1.3 START/STOP semantics and conversion flow

**START is accepted only when the core is armed and a context can be allocated.** `mptdc_async_frontend_v2` computes `start_accept_level = start_async_i & any_ctx_free & conv_arm_i & ~start_latched_q` and separately raises `start_rejected_o` if START arrives while already active, unarmed, or all contexts are unavailable (`MPTDC/rtl/async/mptdc_async_frontend_v2.sv:75-105`). On accepted START, it latches the active context and asserts `osc_slow_en_async_o = start_latched_q` (`MPTDC/rtl/async/mptdc_async_frontend_v2.sv:138-145`, `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:174-185`).

**STOP closes the event interval and launches the fast side.** The STOP latch is set by `stop_async_i` or by the slow-domain missing-STOP watchdog only after START is latched (`MPTDC/rtl/async/mptdc_async_frontend_v2.sv:126-135`). Once STOP is latched, the frontend enables the fast oscillator and PD matrix eligibility (`MPTDC/rtl/async/mptdc_async_frontend_v2.sv:183-185`). The core then gates actual PD sampling with `pd_enable_gated = fe_pd_enable & meas_pd_gate`, so PD cells are not allowed to see valid slow edges during oscillator warmup or teardown (`MPTDC/rtl/top/mptdc_core.sv:288-292`, `MPTDC/rtl/top/mptdc_core.sv:340-356`).

**The fast-domain FSM is the conversion owner after STOP.** `mptdc_meas_ctrl` runs on `osc_fast_ph0` and transitions:

```text
IDLE -> MEASURE -> SNAPSHOT -> CAPTURE -> STOP_OSC -> CLEAR -> IDLE
```

This exact sequence is encoded in the package and implemented in the FSM (`MPTDC/rtl/pkg/mptdc_pkg.sv:128-142`, `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:224-238`). It matters because:

1. `MEASURE` accumulates PD hits.
2. `SNAPSHOT` freezes wide PD/counter/boundary data into context-bank holding registers.
3. `CAPTURE` commits the frozen image into the selected context and marks it drainable.
4. `STOP_OSC` clears frontend latches, stopping the oscillators in a controlled order.
5. `CLEAR` clears PD cells and counters only after the slow phases are static (`MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:256-270`).

The close condition depends on `max_hits`. If `max_hits == 1`, close is a fast OR-reduction of any PD hit. If `max_hits > 1`, close uses a pipelined cumulative hit-count tree and compares the registered count against `max_hits_cfg_i` (`MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:79-139`, `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:156-172`). This is why `max_hits = 1` is the active minimum-latency single-hit mode; the former separate `FIRST_HIT` mode bit is gone (`MPTDC/README.md:9-18`, `MPTDC/docs/01_ARCHITECTURE.md:20-22`).

### 1.4 Coarse/fine timing capture

The MPTDC does not produce a timestamp from one scalar counter. It captures a tuple:

| Field | Where it comes from | Why it matters |
|---|---|---|
| `nslow` | STOP-side slow Gray snapshot | Coarse slow count aligned to STOP, not a later capture time (`MPTDC/rtl/top/mptdc_core.sv:373-391`). |
| `nfast_hit` | Latched per PD cell on first detected crossing | Per-hit fast coarse count; this is exported as the hit `nfast` field (`MPTDC/rtl/pd/mptdc_pd_cell.sv:24-32`, `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:148-155`). |
| `ns`, `nf` | PD matrix scan indices | Fine phase pair identifying which slow/fast phase cell crossed (`MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:119-155`). |
| `phase0_snap` | STOP-side async capture of slow phase 0 | Boundary class observable exported in packet header (`MPTDC/rtl/async/mptdc_stop_capture_async.sv:14-18`, `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:100-110`). |
| `slow_boundary_inc` | STOP-side guard-window carry | Corrects boundary cases in `vernier_tconv_ps()` (`MPTDC/rtl/async/mptdc_stop_capture_async.sv:35-44`, `MPTDC/rtl/pkg/mptdc_pkg.sv:299-327`). |

The slow counter uses `mptdc_gray_cnt_sync` with `USE_ASYNC_SNAPSHOT=1`, which captures a Gray-coded STOP snapshot and synchronizes it into the fast destination domain. The module explicitly states that async STOP snapshot bounds ambiguity to at most one count when STOP lands close to a source clock edge (`MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv:123-139`). The fast counter uses the same module but with no async snapshot; it is local to `osc_fast_ph0` and feeds both the PD cells and context bank (`MPTDC/rtl/top/mptdc_core.sv:393-411`).

### 1.5 Phase-detector matrix operation

The matrix is 8 slow phases by 8 fast phases. In `mptdc_core`, each cell receives:

```systemverilog
slow_phase   = pd_enable_gated & slow_phase[ns]
fast_phase   = fast_phase[nf]
nfast_count  = nfast_src_count
```

for `CELL = ns * NE + nf` (`MPTDC/rtl/top/mptdc_core.sv:340-356`). Each `mptdc_pd_cell` samples its slow phase on the rising edge of the selected fast phase and detects a falling edge of the slow signal. On first detection, it latches `hit_level = 1` and stores the current `nfast_count` (`MPTDC/rtl/pd/mptdc_pd_cell.sv:10-32`, `MPTDC/rtl/pd/mptdc_pd_cell.sv:77-99`).

Consequences for characterization:

- A conversion may have multiple active PD cells, not one canonical code.
- Hit order in the external packet is scan order, not physical event time.
- `nfast_hit` is per hit; `nfast_snap` and `nfast_stop` are internal metadata and are not in the live narrow packet (`MPTDC/docs/02_OUTPUT_PROTOCOL.md:161-171`).
- The most useful characterization source is `RAW_FEATURES` or `FULL`, not only `RAW_TIMESTAMP`, because raw tuples reveal phase-cell occupancy, boundary classes, and illegal/bubble patterns.

### 1.6 Double-buffered contexts

`N_CTX = 2` gives one context for capture while another can drain (`MPTDC/rtl/pkg/mptdc_pkg.sv:95-98`). `mptdc_context_bank` freezes a complete conversion image into holding registers on `snapshot_en_i` and commits it to the selected context on `capture_en_i` (`MPTDC/rtl/async/mptdc_context_bank.sv:78-107`). The frontend marks a context drainable when `capture_en_i` arrives for the active context (`MPTDC/rtl/async/mptdc_async_frontend_v2.sv:148-157`). The drain flag crosses into `clk_sys` through a 2-FF synchronizer before the system drain FSM reads static context data (`MPTDC/rtl/top/mptdc_core.sv:247-260`).

This double buffer is central to the design:

- It decouples measurement-path re-arm from packet drain most of the time.
- It does **not** make the design unbounded. If one context is draining and another is capturing, a new START is rejected and `OVF_COUNT` increments (`MPTDC/rtl/top/mptdc_core.sv:263-273`, `MPTDC/rtl/top/mptdc_core.sv:529-531`).
- Output backpressure can still become a measurement acceptance problem indirectly by preventing context release and eventually filling both contexts.

### 1.7 How raw hits become packets

After `ctx_drain` crosses into `clk_sys`, `mptdc_drain_ctrl` selects a drainable context, emits exactly one META record, scans all 64 PD cells, emits one HIT record per active cell until `hit_count` is reached, then releases the context and pulses `conv_done` (`MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:12-23`, `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:170-207`). META carries conversion-level data: `nslow`, `nfast_snap`, `nfast_stop`, `hit_count`, flags, `phase0_snap`, `slow_boundary_inc`, and `ctx_id`; HIT carries `ns`, `nf`, `nfast_hit`, and internal `event_seq` (`MPTDC/rtl/pkg/mptdc_pkg.sv:172-201`, `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:131-155`).

Those acquisition records enter a synchronous FWFT FIFO (`MPTDC/rtl/cdc/mptdc_sync_fifo.sv:10-17`, `MPTDC/rtl/top/mptdc_core.sv:466-481`). In standalone mode, `mptdc_narrow16_tx_v2` consumes the FIFO and emits:

```text
HEADER
HIT payload words
EOC
```

for `RAW_FEATURES`, `RAW_TIMESTAMP`, or `FULL` (`MPTDC/docs/02_OUTPUT_PROTOCOL.md:7-20`, `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:14-20`). In `RAW_FEATURES`, each hit is two words: `nslow/nfast_hit` and `ns/nf`. In `RAW_TIMESTAMP`, the second hit word is `t_raw_ps[15:0]`. In `FULL`, the packet emits both raw feature words and the derived timestamp (`MPTDC/docs/02_OUTPUT_PROTOCOL.md:55-150`).

Important packet-decoding rule: receivers must parse by packet structure. Timestamp payload words can look like headers or EOC if interpreted out of context (`MPTDC/docs/02_OUTPUT_PROTOCOL.md:22-31`, `MPTDC/docs/02_OUTPUT_PROTOCOL.md:173-184`).

### 1.8 Immediate role inside TOP

TOP does not replace the MPTDC kernels. It preserves three axis-local `mptdc_top_asic` instances and changes only the post-FIFO sharing/egress architecture. `spadmic_tdc_axis_wrapper` gates async axis events, qualifies one STOP pulse using `clk_ref_40m`, instantiates `mptdc_top_asic`, disables the per-axis narrow output, and enables the acquisition-record export interface (`TOP/rtl/spadmic_tdc_axis_wrapper.sv:43-87`).

`spadmic_tdc_shared_readout` arbitrates among the three axis FIFOs at acquisition-record granularity. It only grants on META records, holds the selected axis until the advertised HIT records are consumed, and feeds one shared `mptdc_narrow16_tx_v2` instance (`TOP/rtl/spadmic_tdc_shared_readout.sv:46-59`, `TOP/rtl/spadmic_tdc_shared_readout.sv:104-140`). The TOP docs state this same rule: each axis still owns its local MPTDC acquisition FIFO; arbitration starts on META; packetization remains `mptdc_narrow16_tx_v2` compatible (`TOP/docs/01_ACTIVE_ARCHITECTURE.md:138-160`).

What TOP changes:

- where final packetization occurs: per-axis local serializer vs shared serializer (`MPTDC/docs/10_SHARED_READOUT_EXPORT.md:118-131`);
- source tagging / event ID patching upstream of the physical DDR TX (`TOP/docs/03_CORRELATED_EVENT_EXPORT.md:32-73`);
- system-level throughput/backpressure behavior.

What TOP does **not** change:

- the MPTDC measurement kernel;
- the START/STOP-to-PD mechanism;
- context capture semantics;
- raw feature definitions;
- the logical narrow-packet grammar (`MPTDC/docs/10_SHARED_READOUT_EXPORT.md:122-131`).

## 2. Characterization metric map

This section is external-research-backed methodology, adapted to this repo’s MPTDC. For TDC terminology and architecture taxonomy, use Kalisz, Tancock et al., and Henzler [kalisz2004review; tancock2019review; henzler2010tdc]. For Vernier implementation behavior, use Nutt, Dudek et al., and Park/Wentzloff [nutt1968tdi; dudek2000vernier; park2011cyclic]. For code-density statistics, use Doernberg et al., Blair, IEEE 1241, Tontini et al., and Vornicu et al. [doernberg1984fullspeed; blair1994histogram; ieee1241_2010; tontini2018fpga; vornicu2016tig]. For SPAD timing/dead-time/pile-up, use Cova et al., Ghioni et al., Bronzi et al., Acconcia et al., and Veerappan et al. [cova1981picosecond; ghioni2007progress; bronzi2016spad; acconcia2018pileup; acconcia2023timing; veerappan2011spad].

| Metric | Why it matters | Recommended experiment | What to log | Sample-count guidance | Caveats |
|---|---|---|---|---|---|
| Single-shot precision / timing resolution | Measures random timing uncertainty at fixed true delay; more meaningful than LSB alone. | Repeated fixed-delay campaigns at representative delays across 20 ps..30 ns; include `max_hits=1`, `max_hits=15`, CAL and SPAD paths. | True delay, raw tuple, packet timestamp, hit count, flags, boundary class, context, seed, jitter setting. | Basic: >=1k conversions/delay. Credible RMS/P99: >=10k/delay/config. Tail/pile-up studies: >=100k/delay/config. | RTL behavioral oscillator jitter is synthetic; silicon SPAD jitter includes detector/front-end physics [cova1981picosecond; acconcia2023timing]. |
| Offset | Required to separate accuracy from precision. | Fixed-delay sweep; fit mean error vs true delay. | Same as above plus mean residual per delay. | >=10k/delay for stable per-delay offset. | Offset in RTL may reflect model origin constants; silicon offset shifts with routing, oscillator macro, input frontend. |
| Gain error | Shows slope mismatch in reconstructed time. | Sweep true delay uniformly; regress `t_raw_ps` vs `Tref_ps`; validate on held-out delays. | `Tref_ps`, `t_raw_ps`, raw features. | Broad sweep: millions of hit rows if covering full code space; at least multiple independent seeds. | Uniform pseudo-random delay can be biased if correlated with oscillator period. |
| Transfer curve shape | Reveals periodic structure, boundary classes, phase-cell bias. | Dense sweep plus per-bin residual plots vs `Tref`, `nslow`, `nfast_hit`, `ns`, `nf`, `slow_boundary_inc`. | RAW_FEATURES / FULL CSV fields. | Enough hits per phase cell: target >=10k per `ns,nf` cell for stable heatmaps. | `RAW_TIMESTAMP` alone hides which tuple caused the error. |
| DNL | Measures bin-width nonuniformity and missing/wide codes. | True code-density test with uncorrelated/uniform phase input; histogram raw codes and timestamp bins. | Raw tuple code, scalar timestamp, phase-cell code, invalid/bubble indicators. | If M scalar bins, DNL uncertainty is about `1/sqrt(N_bin)`. For 0.1 LSB at 95%, target ~400/bin minimum; for robust characterization use >=1k/bin; for 1% DNL use >=10k/bin. | Current broad random-delay sweep is useful but not automatically a formal code-density test unless stimulus uniformity and coverage are proven [doernberg1984fullspeed; blair1994histogram]. |
| INL | Captures cumulative transfer-function error. | Integrate DNL after endpoint correction or best-fit correction; also compare calibrated transfer curve to reference delay. | Same histogram plus calibrated cumulative bin widths. | Same as DNL; INL accumulates noise, so more samples and confidence intervals are needed. | Edge bins and underpopulated unreachable codes must be handled explicitly. |
| Missing codes / monotonicity | Critical for calibration validity and timestamp ordering. | Exhaustive/fine code-density plus monotonic true-delay sweep; look for zero-count bins and non-monotonic median code vs delay. | Occupancy per raw tuple and scalar code; ordered-delay medians. | For missing-code confidence, require expected counts/bin high enough that zero-count probability is negligible. With 1000 expected/bin, zero observed is decisive. | Some tuple codes may be physically unreachable; classify unreachable vs missing. |
| Boundary-code anomalies | STOP near phase-0 boundary can shift `nslow` and `slow_boundary_inc`. | Boundary-stress bench that sweeps STOP within sub-ps/ps offsets around slow phase transitions. | `phase0_snap`, `slow_boundary_inc`, `nslow`, `nfast_hit`, raw PD bitmap, raw tuple, error. | Many trials per boundary point: >=10k for probability curves; more for rare bubbles. | RTL can model deterministic guard behavior, not analog metastability probability unless injected. |
| Bubble / illegal PD patterns | Multi-cell PD matrix can produce illegal or discontinuous hit maps near transitions. | Log full 64-bit `hit_level` and packed `nfast_hit`; classify patterns vs expected wavefront. | Internal PD bitmap, per-cell `nfast_hit`, raw packet fields. | >=10k trials per stressed boundary point; Monte Carlo for mismatch. | Current external packet only exposes active cells, not empty cells; a dedicated bench should log internals. |
| True hardware deadtime | Determines earliest possible next START acceptance. | Persistent-arm double-pulse bench: keep `conv_arm=1`, avoid CSR re-arm, sweep STOP_N to START_N+1 at ps/ns resolution. | Accepted/rejected START, `ctx_state`, `meas_state`, `ctx_drain`, `OVF_COUNT`, packet IDs. | At each gap: enough trials to estimate acceptance probability; >=1k/gap for transition curve. | Existing `tb_deadtime_measure` includes CSR re-arm and only sweeps down to 20 ns, so it does not prove best-case hardware deadtime (`MPTDC/tb/int/tb_deadtime_measure.sv:93-97`, `MPTDC/tb/int/tb_deadtime_measure.sv:179-188`). |
| Sustained throughput | Determines data-loss behavior under real output rates. | Burst and continuous-rate tests with programmable output backpressure and axis-sharing if TOP mode matters. | Accepted events, rejected STARTs, FIFO level, context states, packet count, source ID. | Long runs over millions of event intervals for low loss-rate claims. | Measurement-path deadtime and output-path throughput are distinct. |
| Context-buffer effects | `N_CTX=2` can hide drain latency but only up to two in-flight/draining contexts. | Stress with event pairs/triples while stalling FIFO and varying hit count. | Context occupancy, release time, rejected starts. | Sweep phase/gap/backpressure; use many seeds. | Any claim of unlimited burst handling is false. |
| 15-hit saturation | Max exported hits per conversion is 15, although PD matrix has 64 cells. | High-hit patterns with delayed close and watchdog close; verify hit_count saturation and scan stop. | Full PD bitmap internally, exported hit_count, scan order, flags. | Directed plus randomized high-hit cases. | Header hit_count cannot express >15 because `MAX_HITS_W=4`. |
| Calibration residual | Shows post-LUT accuracy, not just raw behavior. | Train on one seed/PVT/temperature subset; validate on held-out seeds and fresh delay grids. | Train/validation split, LUT key, raw tuple, corrected timestamp, residual. | Use independent validation at least comparable to training size; report confidence intervals. | Reusing same campaign for training and validation overstates performance. |
| PVT sensitivity | Oscillator tap delays and mismatch drive Vernier gain/DNL. | PVT corner behavioral sweeps first; then extracted/gate/AMS oscillator macro sweeps; then silicon temp/voltage. | Same raw observables plus PVT corner, supply, temperature, trim. | Corners: all signoff corners. Monte Carlo: enough seeds for yield tail, often hundreds+ at circuit level if feasible. | RTL nominal constants cannot sign off PVT. Use analog macro/extracted views. |

## 3. Assessment of current repo characterization

### 3.1 What exists today

The repo already has a maintained characterization stack:

- `tb_campaign_collect.sv` collects configurable campaigns, writes CSV rows with `conv_id`, `hit_idx`, `Tref_ps`, `nslow`, `nfast_hit`, `ns`, `nf`, `phase0_snap`, `slow_boundary_inc`, `hit_count`, `flags`, `ctx_id`, `t_raw_ps`, mode, and max-hits (`MPTDC/tb/int/tb_campaign_collect.sv:226-320`, `MPTDC/tb/int/tb_campaign_collect.sv:501-526`).
- `run_campaign.sh` sweeps seeds/configurations, supports `--delay-min`, `--delay-max`, `--out-mode`, and oscillator jitter plusargs, and enumerates multihit/fast-close, max-hit, SPAD/CAL, nominal/jitter configs (`MPTDC/scripts/sim/run_campaign.sh:7-23`, `MPTDC/scripts/sim/run_campaign.sh:229-259`, `MPTDC/scripts/sim/run_campaign.sh:320-370`).
- `run_fixed_delay_campaign.sh` reuses the campaign collector with `delay_min == delay_max` for same-delay characterization (`MPTDC/scripts/sim/run_fixed_delay_campaign.sh:1-18`, `MPTDC/scripts/sim/run_fixed_delay_campaign.sh:137-185`).
- `run_characterization_baseline.sh` standardizes the baseline at `20..30000 ps`, default `30` seeds x `100000` conversions/seed, optional analysis, calibration, fixed-delay stage, jitter override, and manifest (`MPTDC/scripts/sim/run_characterization_baseline.sh:6-27`, `MPTDC/scripts/sim/run_characterization_baseline.sh:156-230`, `MPTDC/scripts/sim/run_characterization_baseline.sh:285-341`).
- `analyze_campaign.py` computes residual statistics, cross-checks Python timestamp reconstruction against RTL, produces DNL/INL from `t_raw_ps`, boundary-class summaries, `ns x nf` heatmaps, hit-count distribution, and profiles vs delay/counters (`MPTDC/scripts/analysis/analyze_campaign.py:35-58`, `MPTDC/scripts/analysis/analyze_campaign.py:151-172`, `MPTDC/scripts/analysis/analyze_campaign.py:279-360`, `MPTDC/scripts/analysis/analyze_campaign.py:719-854`).
- `analyze_fixed_delay_campaign.py` builds conversion-level views and same-delay averaging curves (`MPTDC/scripts/analysis/analyze_fixed_delay_campaign.py:72-125`, `MPTDC/scripts/analysis/analyze_fixed_delay_campaign.py:331-427`).

### 3.2 What is solid

Current repo flows are strong for **functional characterization of the RTL data path**:

- Packet grammar and parser consistency are checked through the maintained protocol and serializer path.
- The campaign CSV contains the right first-order raw observables for offline calibration: raw feature tuple, boundary flags, hit count, context ID, and timestamp.
- The fixed-delay flow correctly distinguishes same-delay RMS/averaging from broad mixed-delay residual analysis.
- The analysis already highlights important architecture-dependent effects: residual vs true delay, residual vs `nslow`, residual vs `nfast_hit`, residual vs hit index, phase occupancy heatmaps, and boundary-class significance.
- The baseline wrapper records configuration metadata in a manifest, which is essential for reproducible characterization.

### 3.3 What is weak or incomplete

The current repo flows are not yet a complete credible silicon characterization package:

1. **DNL/INL methodology is only partial.** `analyze_campaign.py` computes DNL/INL by histogramming `t_raw_ps` (`MPTDC/scripts/analysis/analyze_campaign.py:279-306`), but a formal code-density test must prove that the input time distribution is uniform and uncorrelated with the TDC quantization grid. A pseudo-random sweep over delay values is useful, but it is not automatically a standards-grade histogram test [doernberg1984fullspeed; blair1994histogram; ieee1241_2010].

2. **RAW_FEATURES should be treated as the characterization source of truth.** The repo docs already recommend `RAW_FEATURES` for silicon characterization and offline calibration (`MPTDC/docs/02_OUTPUT_PROTOCOL.md:55-58`, `MPTDC/docs/02_OUTPUT_PROTOCOL.md:186-190`). `RAW_TIMESTAMP` is useful for compact operation but hides the raw tuple and cannot diagnose phase-cell occupancy, boundary anomalies, or tuple-specific calibration residuals.

3. **Current deadtime evidence is not best-case hardware evidence.** `tb_deadtime_measure` re-arms through CSR (`arm()` writes `CSR_CTRL`) and sweeps requested gaps only from 60 ns down to 20 ns (`MPTDC/tb/int/tb_deadtime_measure.sv:75-83`, `MPTDC/tb/int/tb_deadtime_measure.sv:93-97`, `MPTDC/tb/int/tb_deadtime_measure.sv:179-188`). The docs themselves distinguish persistent-arm behavior from software re-arm and note that software/control latency makes the effective gap much larger (`MPTDC/docs/06_DEADTIME_ANALYSIS.md:79-84`). Therefore the existing bench proves an integration-level re-arm trend, not the best-case measurement-path hardware deadtime.

4. **Boundary/metastability is not physically proven at RTL.** The RTL has deterministic `phase0_guard` behavior in the oscillator model and a 1 ps guard delay (`MPTDC/rtl/osc/mptdc_osc_model.sv:78-91`), but analog metastability probabilities, aperture uncertainty, and phase-detector resolution require circuit-level simulation and silicon data [parekh2022metastability; yuan2022metastability].

5. **Oscillator realism is limited.** The behavioral oscillator supports nominal tap delays and optional jitter (`MPTDC/rtl/osc/mptdc_osc_model.sv:15-29`, `MPTDC/rtl/osc/mptdc_osc_model.sv:54-76`), while synthesis uses a stub that is not a real oscillator (`MPTDC/rtl/osc/mptdc_osc_wrapper.sv:45-70`). PVT, startup dynamics, phase mismatch, supply noise, and layout parasitics must wait for the real oscillator macro and extracted views.

6. **Calibration validation must be kept strictly independent.** The baseline wrapper supports training seeds, explicit validation directory, and fresh validation directory (`MPTDC/scripts/sim/run_characterization_baseline.sh:14-18`, `MPTDC/scripts/sim/run_characterization_baseline.sh:201-214`), but characterization reports must explicitly state whether numbers are trained/held-out/fresh/PVT-crossed.

### 3.4 What the repo already characterizes well

- End-to-end RTL packet/data integrity across output modes.
- Raw timestamp reconstruction consistency between RTL and Python analysis.
- Broad nominal residual behavior over `20 ps..30 ns`.
- Same-delay one-shot RMS and averaging behavior at selected fixed delays.
- Boundary-class and `ns x nf` heatmap diagnostics at the behavioral RTL level.
- Functional effects of `max_hits = 1` fast close vs multi-hit close.

### 3.5 What it only partially characterizes

- Formal DNL/INL.
- True best-case hardware deadtime.
- Sustained throughput under realistic TOP shared-readout backpressure.
- Context-switch edge cases under simultaneous capture/drain/FIFO full stress.
- 15-hit saturation under dense PD activity.
- Boundary/bubble/metastability probability.
- Calibration stability across PVT, mismatch, and time.

### 3.6 What is missing for a truly credible package

- A dedicated code-density bench with uniform asynchronous phase stimulus and per-code confidence intervals.
- A persistent-arm deadtime bench that bypasses CSR/software re-arm.
- A boundary-stress bench that logs full internal PD bitmap and counter snapshots.
- A throughput/backpressure bench that separates measurement acceptance from output drain.
- A context/overflow stress bench with two contexts, FIFO stalls, and triple-burst attempts.
- A calibration train/validation harness that enforces independent seeds, independent delay grids, and eventually independent PVT/silicon sessions.
- Gate-level/SDF and extracted/AMS characterization once oscillator and PD macro implementation exists.
- Silicon lab procedures for SPAD IRF, DCR/PDP/afterpulsing, TDC code density, dead time, count-rate linearity, pile-up, and temperature/supply sweeps.

## 4. Recommended characterization plan for this MPTDC

This section is engineering judgment based on the repo architecture plus the external methodology above.

### 4.1 Priority order

1. **Preserve and reuse current campaign infrastructure.** It already logs the right raw fields for calibration and broad sweeps.
2. **Add missing RTL benches that isolate architecture-specific risks.** Deadtime, code density, boundary stress, context pressure, and output backpressure should be separated.
3. **Promote characterization from behavioral RTL to implementation-aware views.** Gate/SDF can test digital timing/packet/control integrity, but oscillator/PD truth requires macro/extracted/AMS.
4. **Only make silicon-grade accuracy/deadtime claims after silicon or extracted analog-aware validation.**

### 4.2 RTL-level plan

Reuse:

- `bash MPTDC/scripts/sim/run_characterization_baseline.sh --analyze --calibrate --with-fixed-delay`
- `bash MPTDC/scripts/sim/run_campaign.sh`
- `bash MPTDC/scripts/sim/run_fixed_delay_campaign.sh`
- `python3 MPTDC/scripts/analysis/analyze_campaign.py`
- `python3 MPTDC/scripts/analysis/analyze_fixed_delay_campaign.py`

Add:

1. **Persistent-arm best-case deadtime bench.**
   - Keep `conv_arm=1`.
   - Do not call CSR `arm()` between conversions.
   - Sweep `STOP_N -> START_N+1` from below expected hardware limit upward in ps/sub-ns increments.
   - Record acceptance probability, `start_rejected_o`, `OVF_COUNT`, contexts, `meas_state`, and packets.
   - Run separately for `max_hits=1`, `max_hits=15`, zero-hit/watchdog, and representative hit patterns.

2. **True code-density histogram bench.**
   - Use an uncorrelated periodic or random-phase START/STOP source.
   - Prove stimulus uniformity before reporting DNL/INL.
   - Log RAW_FEATURES and internal full-code tuple.
   - Report DNL/INL with confidence intervals, missing-code classification, and edge-bin treatment.

3. **Boundary-stress / bubble-error bench.**
   - Sweep STOP around every slow phase boundary and selected fast phase boundaries.
   - Use sub-`DELTA_STEP` timing increments.
   - Log internal 64-bit `pd_hit_level`, packed per-cell `nfast_hit`, `phase0_snap`, `slow_boundary_inc`, `nslow`, `nfast_src_count`, and external packet.
   - Classify legal wavefronts, bubbles, multiple hits, missing hits, and boundary carries.

4. **Context-switch / overflow stress bench.**
   - Generate bursts of 2, 3, and more conversions with controlled gaps.
   - Hold FIFO output ready low to keep context(s) draining.
   - Verify that two contexts overlap correctly and the third START is rejected/counts overflow.

5. **Throughput-under-backpressure bench.**
   - Sweep `narrow_ready`/`acq_ready` duty cycle and burst length.
   - Distinguish frontend accepted-rate from serialized-output rate.
   - Repeat in standalone MPTDC and TOP shared-readout mode.

6. **Calibration train-vs-validate harness.**
   - Enforce disjoint training/validation seeds.
   - Use a fresh validation delay grid.
   - Report raw, calibrated, held-out, and fresh-grid residuals.
   - Stratify by `ns,nf,nslow,nfast_hit,slow_boundary_inc,hit_idx`.

### 4.3 Gate-level / SDF plan

Gate-level/SDF should be used for:

- `clk_sys` drain/FIFO/serializer timing and packet integrity.
- Reset synchronizer release behavior and CSR status correctness.
- Fast-domain measurement FSM timing after synthesis where generated clocks are modeled.
- Context-bank static-data timing and drain flag handoff assumptions.

Gate/SDF should **not** be used to claim oscillator fine resolution unless the oscillator and PD matrix are represented by a meaningful macro/timing model. With the current synthesis stub, oscillator behavior is not real (`MPTDC/README.md:97-108`, `MPTDC/rtl/osc/mptdc_osc_wrapper.sv:59-70`).

### 4.4 AMS / extracted / analog-aware plan

Analog-aware characterization must cover:

- slow/fast oscillator tap delays and mismatch;
- oscillator startup latency and repeatability;
- phase ordering and duty-cycle distortion;
- phase-detector aperture/metastability;
- supply/temperature sensitivity;
- layout parasitics and local mismatch across the 8x8 PD island;
- effect of reset/enable/clear sequencing on actual oscillator and PD states.

Recommended experiments:

- transient simulation of START/STOP conversion at selected delays;
- PVT corners for oscillator tap delay and `DELTA_STEP`;
- Monte Carlo mismatch of tap delays and PD aperture;
- extracted RC simulation for oscillator/PD layout;
- mixed-signal co-sim with digital FSM and analog oscillator/PD macro models.

### 4.5 Silicon / lab plan

Silicon characterization should be staged:

1. Bring-up: CSR, reset, output parser, packet framing, `RAW_FEATURES` capture.
2. Electrical calibration input: fixed-delay and code-density TDC-only characterization without SPAD variability.
3. SPAD path: laser/TCSPC IRF measurement, DCR, afterpulsing, dead time, pile-up, count-rate linearity [cova1981picosecond; ghioni2007progress; bronzi2016spad; acconcia2018pileup; acconcia2023timing].
4. PVT: temperature chamber and supply sweeps; repeat code density and fixed-delay validation.
5. Stability: repeat calibration over time, across chips, and after thermal cycling.

## 5. Testbench design guidance

### 5.1 Stimulus philosophy

Functional verification asks, “does the RTL produce the right packet for a scenario?” Characterization asks, “what statistical transfer function does the TDC implement under a controlled stimulus?” Do not mix the two.

For characterization:

- Use `timescale 1ps/1ps` or finer if the simulator/model supports it; the repo already uses `1ps/1ps` in the MPTDC RTL/testbenches.
- Avoid synchronizing START/STOP stimulus to `clk_sys`; that biases phase coverage.
- Prefer CAL inputs for pure TDC characterization before SPAD-path studies.
- Keep `conv_arm` persistent for hardware deadtime measurement.
- Use independent PRNG seeds and record them.
- Use deterministic, replayable stimuli for debug; use statistically uniform stimuli for code-density.

### 5.2 Asynchronous injection requirements

START and STOP must be injected as asynchronous pulses relative to:

- `clk_sys`;
- slow oscillator phase;
- fast oscillator startup;
- each other.

For uniform code-density, the relative phase must be uncorrelated with the oscillator periods. A simple integer-picosecond PRNG can accidentally correlate with 50 ps/55 ps tap spacings. Use irrational-ish stepping, mixed LCG/jittered periods, or independent asynchronous periodic sources and then prove uniformity through a stimulus-only histogram.

### 5.3 Phase coverage requirements

At minimum, report:

- occupancy of all `ns,nf` phase cells;
- occupancy vs `nslow`;
- occupancy vs `nfast_hit`;
- boundary-class counts for `(phase0_snap, slow_boundary_inc)`;
- scalar timestamp-bin occupancy;
- missing/unreachable tuple codes.

For the 8x8 matrix, target at least `10k` hit rows per `ns,nf` cell for stable heatmaps. That is ~640k hit rows minimum for phase occupancy alone, not enough for full scalar DNL over a 30 ns range. For scalar code-density across roughly 3000 10 ps bins, 1000 counts/bin implies ~3M hit rows; 10k/bin implies ~30M hit rows.

### 5.4 What to log

Per conversion:

- true injected delay;
- START/STOP absolute sim times;
- accepted/rejected flag;
- `ctx_id`;
- `hit_count`;
- close flags;
- `phase0_snap`;
- `slow_boundary_inc`;
- packet word count;
- FIFO level/backpressure state;
- context states;
- `meas_state` timing for deadtime benches.

Per hit:

- `hit_idx` / scan order;
- `nslow`;
- `nfast_hit`;
- `ns`;
- `nf`;
- raw tuple code;
- `t_raw_ps`;
- corrected timestamp if calibration is applied;
- residual vs true delay.

For boundary/bubble benches, also log internal observables:

- full 64-bit `pd_hit_level`;
- full packed `pd_nfast_hit_packed`;
- `nslow_src_count`;
- `nslow_stop_latched`;
- `nfast_src_count`;
- `meas_pd_gate`;
- frontend latch states.

These internal observables should not become the normal host contract, but they are necessary for RTL characterization of the PD matrix.

### 5.5 Packet decoding

Decode packets structurally:

1. Wait for header.
2. Read `hit_count` and `out_mode`.
3. Consume exactly the expected number of hit words.
4. Expect EOC.

Do not infer word type from payload bit patterns inside timestamp modes; the repo explicitly warns against that (`MPTDC/docs/02_OUTPUT_PROTOCOL.md:22-31`, `MPTDC/docs/02_OUTPUT_PROTOCOL.md:173-184`). In TOP shared mode, remember that TOP patches source ID into TDC header bits, but the payload grammar remains MPTDC-compatible (`TOP/docs/01_ACTIVE_ARCHITECTURE.md:151-160`).

### 5.6 Reconstructing raw timestamps offline

For characterization, reconstruct timestamps offline from RAW_FEATURES using the package formula and compare with `FULL`/RTL timestamp only as a cross-check. The current Python analyzer already mirrors the package constants and formula (`MPTDC/scripts/analysis/analyze_campaign.py:35-58`, `MPTDC/scripts/analysis/analyze_campaign.py:158-172`). Keep `DELTA_STEP=5 ps` and `DELTA_LSB=10 ps` separate in documentation and scripts.

### 5.7 Calibration data separation

Use strict splits:

- **Training:** used to build LUT/correction.
- **Held-out validation:** same broad distribution, disjoint seeds.
- **Fresh delay-grid validation:** fixed delays not used in training.
- **PVT validation:** different voltage/temperature/corner/chip.

Report all four separately. A calibration result trained and validated on the same mixed corpus is not a credible deployed-performance number.

### 5.8 Deadtime methodology

Measure at least three different quantities:

1. **Measurement-path deadtime:** persistent arm, no CSR re-arm, no output bottleneck.
2. **Context-limited burst acceptance:** persistent arm plus deliberate FIFO/backpressure/context pressure.
3. **System-level throughput:** realistic readout, TOP arbitration, physical TX constraints.

Do not quote one number as “the deadtime” unless you define which one. The existing deadtime bench is useful as an integration check but includes CSR re-arm overhead and starts at 20 ns requested gaps (`MPTDC/tb/int/tb_deadtime_measure.sv:93-97`, `MPTDC/tb/int/tb_deadtime_measure.sv:179-188`).

### 5.9 Boundary cases

Boundary-stress testing should sweep:

- STOP exactly at slow phase-0 transitions;
- STOP within +/- several ps around slow phase-0 transitions;
- STOP near fast sampling edges;
- START/STOP near-coincident cases;
- missing STOP leading to start watchdog;
- `max_hits=1` first crossing vs `max_hits=15` accumulation;
- cases where `slow_boundary_inc` toggles.

For each boundary, produce probability curves, not only pass/fail. RTL can reveal deterministic boundary logic bugs; only circuit/silicon can establish metastability probability.

## 6. Online-research-backed references

Strong references for the methodology:

- Vernier/TDC architecture and terminology: Nutt [nutt1968tdi], Kalisz [kalisz2004review], Henzler [henzler2010tdc], Tancock et al. [tancock2019review].
- CMOS Vernier characterization: Dudek et al. [dudek2000vernier], Park and Wentzloff [park2011cyclic].
- Code-density and DNL/INL methods: Doernberg et al. [doernberg1984fullspeed], Blair [blair1994histogram], IEEE 1241 [ieee1241_2010], Tontini et al. [tontini2018fpga], Vornicu et al. [vornicu2016tig].
- Ring-oscillator / multi-phase context: Straayer and Perrott [straayer2009gro], Henzler [henzler2010tdc].
- Metastability/boundary behavior: Parekh et al. [parekh2022metastability], Yuan [yuan2022metastability], Fathi and Sheikhaei [fathi2024twostage].
- SPAD timing/dead-time/pile-up: Cova et al. [cova1981picosecond], Ghioni et al. [ghioni2007progress], Zappa et al. [zappa2007principles], Bronzi et al. [bronzi2016spad], Acconcia et al. [acconcia2018pileup; acconcia2023timing], Veerappan et al. [veerappan2011spad], Charbon and Fishburn [charbon2011spad].
- PVT/statistical converter characterization: Pelgrom [pelgrom2017adc], plus circuit-level Monte Carlo using the foundry statistical model.

Weaker/generic references:

- ADC histogram standards are not TDC-specific, but the definitions and statistical framework transfer directly when input voltage is replaced by input time. Use TDC-specific papers such as Tontini et al. and Vornicu et al. to justify that mapping [tontini2018fpga; vornicu2016tig].
- Public AMS/post-layout methodology sources are less authoritative than actual foundry/PDK/Cadence app notes. For this project, the decisive evidence must come from the oscillator/PD macro models, extracted layout, and silicon data.

