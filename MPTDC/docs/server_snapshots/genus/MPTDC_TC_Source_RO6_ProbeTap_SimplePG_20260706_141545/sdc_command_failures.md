# O13 abs3 SDC Command Failure Review

- Run ID: `MPTDC_TC_Source_RO6_ProbeTap_SimplePG_20260706_141545`
- SDC overlay: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/inputs/mptdc_axis_core_typical_closed.sdc`
- Genus log: `genus_MPTDC_TC_Source_RO6_ProbeTap_SimplePG_20260706_141545.log`

SDC_COMMAND_FAILURE_COUNT=2
ACTIVE_SDC_FAILURE_COUNT=2
REPORT_DIAGNOSTIC_WARNING_COUNT=0
RAW_SDC_DIAGNOSTIC_COUNT=0
SDC_235_COUNT=0
TUI_61_COUNT=0
SDC_INVALID_OBJECT_COUNT=0

## Extracted SDC/Timing-Intent Diagnostics

419:@file(procedures.tcl) 4972: proc mptdc_report_timing ...
2214:MPTDC_SDC_INFO: false-pathing PD conversion clear pins (2 pattern-expanded pins)
2215:MPTDC_SDC_INFO: false-pathing PD conversion clear pins uses -through only for async control pins
2216:MPTDC_SDC_INFO: false-pathing PD conversion clear pins applied without pattern failures
2217:MPTDC_SDC_WARN: no pins matched for Gray counter async clear pins
2218:MPTDC_SDC_INFO: false-pathing START watchdog async clear pins (4 pattern-expanded pins)
2219:MPTDC_SDC_INFO: false-pathing START watchdog async clear pins uses -through only for async control pins
2220:MPTDC_SDC_INFO: false-pathing START watchdog async clear pins applied without pattern failures
2221:MPTDC_SDC_INFO: false-pathing STOP metadata async capture data pins (5 pattern-expanded pins)
2222:MPTDC_SDC_INFO: false-pathing STOP metadata async capture data pins applied without pattern failures
2348:MPTDC_SDC_INFO: max-delaying STOP metadata static bus into clk_sys snapshot from 4 pattern-expanded pin(s) to 2 pattern-expanded pin(s)
2349:MPTDC_SDC_INFO: max-delay STOP metadata static bus into clk_sys snapshot applied across 8 pattern pair(s)
2350:MPTDC_SDC_INFO: RO probe outputs are load-only debug ports, excluded from clk_sys output delay
2351:MPTDC_SDC_INFO: design max-transition target 0.5 ns is checked by DRV reports; direct set_max_transition on current_design is skipped because this Genus SDC mode rejects that object form
2352:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_*_n* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
2353:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_n_o* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
2354:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_sys_*_n* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
2366: "set_clock_groups"         - successful      1 , failed      0 (runtime  0.00)
2369: "set_false_path"           - successful     21 , failed      0 (runtime  0.01)
2374: "set_max_delay"            - successful     11 , failed      0 (runtime  0.02)
2383:MPTDC_O13_ABS3_SDC_INFO: loading O13_ABS3_CLOCK_CDC_CONSTRAINT_REPAIR overlay
2384:MPTDC_O13_ABS3_SDC_INFO: signoff status = TYPICAL_ONLY_NOT_MMMC_NOT_FINAL_SIGNOFF
2385:MPTDC_O13_ABS3_SDC_INFO: expected RTL define = MPTDC_PHASE_BUFFER_TOPO_BUJIHDX4_BUJIHDX12
2386:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap0 from 0x185 to 0x217
2387:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap1 from 0x227 to 0x259
2388:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap2 from 0x269 to 0x301
2389:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap3 from 0x311 to 0x343
2390:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap4 from 0x353 to 0x385
2391:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap5 from 0x395 to 0x427
2392:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap6 from 0x437 to 0x469
2393:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap7 from 0x479 to 0x511
2394:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap0 from 0x521 to 0x553
2395:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap1 from 0x563 to 0x595
2396:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap2 from 0x605 to 0x637
2397:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap3 from 0x647 to 0x679
2398:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap4 from 0x689 to 0x721
2399:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap5 from 0x731 to 0x763
2400:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap6 from 0x773 to 0x805
2401:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap7 from 0x815 to 0x847
2402:MPTDC_O13_ABS3_SDC_INFO: matched raw RO pins = 16
2403:MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX4 iso A pins = 16
2404:MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX4 iso Q pins = 16
2405:MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX12 driver A pins = 16
2406:MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX12 driver Q pins = 16
2407:MPTDC_O13_ABS3_SDC_INFO: raw clock count = 16
2408:MPTDC_O13_ABS3_SDC_INFO: buffer slow clock count = 8
2409:MPTDC_O13_ABS3_SDC_INFO: buffer fast clock count = 8
2410:MPTDC_O13_ABS3_SDC_INFO: generated final-driver clocks = 16
2411:MPTDC_O13_ABS3_SDC_INFO: oscillator clocks in async group = 32
2412:MPTDC_O13_ABS3_SDC_INFO: clk_sys async to raw+buffer oscillator clocks = YES
2413:MPTDC_O13_ABS3_SDC_INFO: raw RO clocks remain analog load-check source clocks
2414:MPTDC_O13_ABS3_SDC_INFO: BUJIHDX12 Q clocks are downstream digital phase-clock sources
2415:MPTDC_O13_ABS3_SDC_INFO: phase-buffer chain and same-domain oscillator paths remain timed
2419:Error   : Could not interpret SDC command. [SDC-202] [read_sdc]
2435: "set_clock_groups"         - successful      1 , failed      0 (runtime  0.00)
2437:Warning : One or more commands failed when these constraints were applied. [SDC-209]
460345:    {mptdc_report_timing $design(synthesis_reports)} \
464040:|SDC-202    |Error  |    1|Could not interpret SDC command.                                                                                                                                                  |
464042:|SDC-209    |Warning|    1|One or more commands failed when these constraints were applied.                                                                                                                  |
465522:    {mptdc_report_timing $design(synthesis_reports)} \
580735:    {mptdc_report_timing $design(synthesis_reports)} \
581569:    {mptdc_report_timing $design(synthesis_reports)} \

## Interpretation

- ACTIVE_SDC_FAILURE_COUNT gates timing intent and closure readiness.
- REPORT_DIAGNOSTIC_WARNING_COUNT captures report-only Genus diagnostics such as retrieve_mode noise.
- Final buffer clocks must be grouped asynchronously against clk_sys.
- Any remaining failed false-path, max-delay, clock-group, or generated-clock command requires review before Innovus.
