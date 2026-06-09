# O13 abs3 SDC Command Failure Review

- Run ID: `20260609_o13_abs5e_pd_q1_constraint_mode_fix`
- SDC overlay: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5_o13_abs5.sdc`
- Genus log: `genus_20260609_o13_abs5e_pd_q1_constraint_mode_fix.log`

## Extracted SDC/Timing-Intent Diagnostics

12671: D MPTDC/lab_snapshots/genus_20260518_1456_phase3_rowbank/prects/extra_report_timing_100.rpt
12672: D MPTDC/lab_snapshots/genus_20260518_1456_phase3_rowbank/prects/extra_report_timing_full_clock.rpt
15429: D MPTDC/lab_snapshots/innovus_20260513_0925_osc_stub_pd_keep_extra/prects/extra_report_timing_100.rpt
15430: D MPTDC/lab_snapshots/innovus_20260513_0925_osc_stub_pd_keep_extra/prects/extra_report_timing_full_clock.rpt
15498: D MPTDC/lab_snapshots/innovus_20260513_1201_hitpipe_deep_with_db/prects/extra_report_timing_100.rpt
15499: D MPTDC/lab_snapshots/innovus_20260513_1201_hitpipe_deep_with_db/prects/extra_report_timing_full_clock.rpt
15535: D MPTDC/lab_snapshots/innovus_20260518_1401_signoff_taps_pdmatrix/prects/extra_report_timing_100.rpt
15536: D MPTDC/lab_snapshots/innovus_20260518_1401_signoff_taps_pdmatrix/prects/extra_report_timing_full_clock.rpt
15578: D MPTDC/lab_snapshots/innovus_20260518_1456_phase3_rowbank/prects/extra_report_timing_100.rpt
15579: D MPTDC/lab_snapshots/innovus_20260518_1456_phase3_rowbank/prects/extra_report_timing_full_clock.rpt
15666: D MPTDC/lab_snapshots/innovus_20260519_1041_clk_sys_pivot/prects/extra_report_timing_100.rpt
15667: D MPTDC/lab_snapshots/innovus_20260519_1041_clk_sys_pivot/prects/extra_report_timing_full_clock.rpt
15856: D MPTDC/lab_snapshots/innovus_osc_pd_20260527_1500_o0_osc_pd_signoff_innovus/prects/extra_report_timing_100.rpt
15857: D MPTDC/lab_snapshots/innovus_osc_pd_20260527_1500_o0_osc_pd_signoff_innovus/prects/extra_report_timing_full_clock.rpt
17558: M position/syn/reports/timing/report_timing_pre_synth.rpt
18945:MPTDC_SDC_INFO: set_case_analysis 1 shared_readout_en_i
18946:MPTDC_SDC_INFO: set_case_analysis 0 narrow_ready_i
18955:-- The command 'set_false_path -to [get_pins -quiet -hierarchical $pattern]' is present in line '15' of proc '::mptdc_try_false_path_pins'
18956:-- The command passed to the interpreter is : '::dc::set_false_path -to 0x80'
18960:        : If, as a result of 'set_max_delay' or 'set_disable_timing' constraint operations, the to-point does not become a valid timing endpoint, then the exception will not be applied to this to-point.
18971:-- The command 'set_false_path -to [get_pins -quiet -hierarchical $pattern]' is present in line '15' of proc '::mptdc_try_false_path_pins'
18972:-- The command passed to the interpreter is : '::dc::set_false_path -to 0x84'
18978:MPTDC_SDC_INFO: false-pathing PD conversion clear pins (2 pattern-expanded pins)
18979:MPTDC_SDC_INFO: false-pathing PD conversion clear pins applied without pattern failures
18980:MPTDC_SDC_WARN: no pins matched for Gray counter async clear pins
18981:MPTDC_SDC_INFO: false-pathing START watchdog async clear pins (4 pattern-expanded pins)
18982:MPTDC_SDC_INFO: false-pathing START watchdog async clear pins applied without pattern failures
18983:MPTDC_SDC_INFO: false-pathing STOP metadata async capture data pins (5 pattern-expanded pins)
18984:MPTDC_SDC_INFO: false-pathing STOP metadata async capture data pins applied without pattern failures
18991:Warning : Invalid object passed to SDC command. [SDC-248] [set_dont_touch]
18996:MPTDC_SDC_INFO: max-delaying STOP metadata static bus into clk_sys snapshot from 4 pattern-expanded pin(s) to 2 pattern-expanded pin(s)
18997:MPTDC_SDC_INFO: max-delay STOP metadata static bus into clk_sys snapshot applied across 8 pattern pair(s)
18998:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_*_n* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
18999:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_n_o* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
19000:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_sys_*_n* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
19013: "set_clock_groups"         - successful      1 , failed      0 (runtime  0.00)
19017: "set_false_path"           - successful     27 , failed      0 (runtime  0.01)
19022: "set_max_delay"            - successful     11 , failed      0 (runtime  0.02)
19024: "set_max_transition"       - successful      1 , failed      0 (runtime  0.00)
19031:MPTDC_O13_ABS5_SDC_INFO: loading O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH overlay
19032:MPTDC_O13_ABS5_SDC_INFO: sourcing O13 abs3 clock/CDC repair overlay first
19033:MPTDC_O13_ABS3_SDC_INFO: loading O13_ABS3_CLOCK_CDC_CONSTRAINT_REPAIR overlay
19034:MPTDC_O13_ABS3_SDC_INFO: signoff status = TYPICAL_ONLY_NOT_MMMC_NOT_FINAL_SIGNOFF
19035:MPTDC_O13_ABS3_SDC_INFO: expected RTL define = MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12
19036:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap0 from 0x191 to 0x223
19037:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap1 from 0x233 to 0x265
19038:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap2 from 0x275 to 0x307
19039:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap3 from 0x317 to 0x349
19040:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap4 from 0x359 to 0x391
19041:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap5 from 0x401 to 0x433
19042:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap6 from 0x443 to 0x475
19043:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap7 from 0x485 to 0x517
19044:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap0 from 0x527 to 0x559
19045:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap1 from 0x569 to 0x601
19046:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap2 from 0x611 to 0x643
19047:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap3 from 0x653 to 0x685
19048:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap4 from 0x695 to 0x727
19049:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap5 from 0x737 to 0x769
19050:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap6 from 0x779 to 0x811
19051:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap7 from 0x821 to 0x853
19052:MPTDC_O13_ABS3_SDC_INFO: matched raw RO pins = 16
19053:MPTDC_O13_ABS3_SDC_INFO: matched BUHDX4 iso A pins = 16
19054:MPTDC_O13_ABS3_SDC_INFO: matched BUHDX4 iso Q pins = 16
19055:MPTDC_O13_ABS3_SDC_INFO: matched BUHDX12 driver A pins = 16
19056:MPTDC_O13_ABS3_SDC_INFO: matched BUHDX12 driver Q pins = 16
19057:MPTDC_O13_ABS3_SDC_INFO: raw clock count = 16
19058:MPTDC_O13_ABS3_SDC_INFO: buffer slow clock count = 8
19059:MPTDC_O13_ABS3_SDC_INFO: buffer fast clock count = 8
19060:MPTDC_O13_ABS3_SDC_INFO: generated final-driver clocks = 16
19061:MPTDC_O13_ABS3_SDC_INFO: oscillator clocks in async group = 32
19062:MPTDC_O13_ABS3_SDC_INFO: clk_sys async to raw+buffer oscillator clocks = YES
19063:MPTDC_O13_ABS3_SDC_INFO: raw RO clocks remain analog load-check source clocks
19064:MPTDC_O13_ABS3_SDC_INFO: BUHDX12 Q clocks are downstream digital phase-clock sources
19065:MPTDC_O13_ABS3_SDC_INFO: phase-buffer chain and same-domain oscillator paths remain timed
19067:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_FOUND_ENDPOINTS=0
19068:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXPECTED_ENDPOINTS=64
19069:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_FOUND_SOURCES=8
19070:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXPECTED_SOURCES=8
19071:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXCEPTION_APPLIED=NO
19072:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_OVERMATCH=NO
19073:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_UNDERMATCH=YES
19074:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXCEPTION_FAILURES=0
19080: "set_clock_groups"         - successful      1 , failed      0 (runtime  0.00)
19590:@file(genus.tcl) 177: mptdc_report_timing $design(synthesis_reports)
19640:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19643:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19645:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19647:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
23767:|SDC-248    |Warning|    1|Invalid object passed to SDC command.                                                                                                                                             |
23773:|TIM-234    |Error  |    4|Invalid path specification.  A 'to' object is invalid.                                                                                                                            |
23776:|           |       |     |If, as a result of 'set_max_delay' or 'set_disable_timing' constraint operations, the to-point does not become a valid timing endpoint, then the exception will not be applied to |
26149:@file(genus.tcl) 211: mptdc_report_timing $design(synthesis_reports)
26170:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
26172:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
26174:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
26176:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
28285:|TIM-234  |Error  |    4|Invalid path specification.  A 'to' object is invalid.                                                                                                                              |
28658:@file(genus.tcl) 218: mptdc_report_timing $design(synthesis_reports)
28679:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
28681:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
28683:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
28685:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
30029:|TIM-234  |Error  |    4|Invalid path specification.  A 'to' object is invalid.                                                                                                                              |
30272:@file(genus.tcl) 235: mptdc_report_timing $design(synthesis_reports)
30295:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
30297:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
30299:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
30301:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]

## Interpretation

- Object-handle SDC failures are expected to disappear after the abs3 helper repair.
- Final buffer clocks must be grouped asynchronously against clk_sys.
- Any remaining failed false-path, max-delay, clock-group, or generated-clock command requires review before Innovus.
