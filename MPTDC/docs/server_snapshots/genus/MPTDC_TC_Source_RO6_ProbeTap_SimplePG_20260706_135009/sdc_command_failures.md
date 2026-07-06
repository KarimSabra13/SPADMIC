# O13 abs3 SDC Command Failure Review

- Run ID: `MPTDC_TC_Source_RO6_ProbeTap_SimplePG_20260706_135009`
- SDC overlay: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/inputs/mptdc_axis_core_typical_closed.sdc`
- Genus log: `genus_MPTDC_TC_Source_RO6_ProbeTap_SimplePG_20260706_135009.log`

SDC_COMMAND_FAILURE_COUNT=2
ACTIVE_SDC_FAILURE_COUNT=2
REPORT_DIAGNOSTIC_WARNING_COUNT=0
RAW_SDC_DIAGNOSTIC_COUNT=0
SDC_235_COUNT=0
TUI_61_COUNT=0
SDC_INVALID_OBJECT_COUNT=0

## Extracted SDC/Timing-Intent Diagnostics

419:@file(procedures.tcl) 4972: proc mptdc_report_timing ...
2222:-- The command 'set_false_path -to [get_pins -quiet -hierarchical $pattern]' is present in line '15' of proc '::mptdc_try_false_path_pins'
2223:-- The command passed to the interpreter is : '::dc::set_false_path -to 0x78'
2227:        : If, as a result of 'set_max_delay' or 'set_disable_timing' constraint operations, the to-point does not become a valid timing endpoint, then the exception will not be applied to this to-point.
2238:-- The command 'set_false_path -to [get_pins -quiet -hierarchical $pattern]' is present in line '15' of proc '::mptdc_try_false_path_pins'
2239:-- The command passed to the interpreter is : '::dc::set_false_path -to 0x82'
2245:MPTDC_SDC_INFO: false-pathing PD conversion clear pins (2 pattern-expanded pins)
2246:MPTDC_SDC_INFO: false-pathing PD conversion clear pins applied without pattern failures
2247:MPTDC_SDC_WARN: no pins matched for Gray counter async clear pins
2248:MPTDC_SDC_INFO: false-pathing START watchdog async clear pins (4 pattern-expanded pins)
2249:MPTDC_SDC_INFO: false-pathing START watchdog async clear pins applied without pattern failures
2250:MPTDC_SDC_INFO: false-pathing STOP metadata async capture data pins (5 pattern-expanded pins)
2251:MPTDC_SDC_INFO: false-pathing STOP metadata async capture data pins applied without pattern failures
2377:MPTDC_SDC_INFO: max-delaying STOP metadata static bus into clk_sys snapshot from 4 pattern-expanded pin(s) to 2 pattern-expanded pin(s)
2378:MPTDC_SDC_INFO: max-delay STOP metadata static bus into clk_sys snapshot applied across 8 pattern pair(s)
2379:MPTDC_SDC_INFO: RO probe outputs are load-only debug ports, excluded from clk_sys output delay
2380:MPTDC_SDC_INFO: design max-transition target 0.5 ns is checked by DRV reports; direct set_max_transition on current_design is skipped because this Genus SDC mode rejects that object form
2381:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_*_n* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
2382:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_n_o* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
2383:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_sys_*_n* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
2395: "set_clock_groups"         - successful      1 , failed      0 (runtime  0.00)
2398: "set_false_path"           - successful     27 , failed      0 (runtime  0.01)
2403: "set_max_delay"            - successful     11 , failed      0 (runtime  0.02)
2412:MPTDC_O13_ABS3_SDC_INFO: loading O13_ABS3_CLOCK_CDC_CONSTRAINT_REPAIR overlay
2413:MPTDC_O13_ABS3_SDC_INFO: signoff status = TYPICAL_ONLY_NOT_MMMC_NOT_FINAL_SIGNOFF
2414:MPTDC_O13_ABS3_SDC_INFO: expected RTL define = MPTDC_PHASE_BUFFER_TOPO_BUJIHDX4_BUJIHDX12
2415:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap0 from 0x191 to 0x223
2416:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap1 from 0x233 to 0x265
2417:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap2 from 0x275 to 0x307
2418:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap3 from 0x317 to 0x349
2419:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap4 from 0x359 to 0x391
2420:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap5 from 0x401 to 0x433
2421:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap6 from 0x443 to 0x475
2422:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap7 from 0x485 to 0x517
2423:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap0 from 0x527 to 0x559
2424:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap1 from 0x569 to 0x601
2425:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap2 from 0x611 to 0x643
2426:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap3 from 0x653 to 0x685
2427:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap4 from 0x695 to 0x727
2428:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap5 from 0x737 to 0x769
2429:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap6 from 0x779 to 0x811
2430:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap7 from 0x821 to 0x853
2431:MPTDC_O13_ABS3_SDC_INFO: matched raw RO pins = 16
2432:MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX4 iso A pins = 16
2433:MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX4 iso Q pins = 16
2434:MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX12 driver A pins = 16
2435:MPTDC_O13_ABS3_SDC_INFO: matched BUJIHDX12 driver Q pins = 16
2436:MPTDC_O13_ABS3_SDC_INFO: raw clock count = 16
2437:MPTDC_O13_ABS3_SDC_INFO: buffer slow clock count = 8
2438:MPTDC_O13_ABS3_SDC_INFO: buffer fast clock count = 8
2439:MPTDC_O13_ABS3_SDC_INFO: generated final-driver clocks = 16
2440:MPTDC_O13_ABS3_SDC_INFO: oscillator clocks in async group = 32
2441:MPTDC_O13_ABS3_SDC_INFO: clk_sys async to raw+buffer oscillator clocks = YES
2442:MPTDC_O13_ABS3_SDC_INFO: raw RO clocks remain analog load-check source clocks
2443:MPTDC_O13_ABS3_SDC_INFO: BUJIHDX12 Q clocks are downstream digital phase-clock sources
2444:MPTDC_O13_ABS3_SDC_INFO: phase-buffer chain and same-domain oscillator paths remain timed
2448:Error   : Could not interpret SDC command. [SDC-202] [read_sdc]
2464: "set_clock_groups"         - successful      1 , failed      0 (runtime  0.00)
2466:Warning : One or more commands failed when these constraints were applied. [SDC-209]
460452:    {mptdc_report_timing $design(synthesis_reports)} \
464147:|SDC-202    |Error  |    1|Could not interpret SDC command.                                                                                                                                                  |
464149:|SDC-209    |Warning|    1|One or more commands failed when these constraints were applied.                                                                                                                  |
464155:|           |       |     |If, as a result of 'set_max_delay' or 'set_disable_timing' constraint operations, the to-point does not become a valid timing endpoint, then the exception will not be applied to |
465632:    {mptdc_report_timing $design(synthesis_reports)} \
580845:    {mptdc_report_timing $design(synthesis_reports)} \
581679:    {mptdc_report_timing $design(synthesis_reports)} \

## Interpretation

- ACTIVE_SDC_FAILURE_COUNT gates timing intent and closure readiness.
- REPORT_DIAGNOSTIC_WARNING_COUNT captures report-only Genus diagnostics such as retrieve_mode noise.
- Final buffer clocks must be grouped asynchronously against clk_sys.
- Any remaining failed false-path, max-delay, clock-group, or generated-clock command requires review before Innovus.
