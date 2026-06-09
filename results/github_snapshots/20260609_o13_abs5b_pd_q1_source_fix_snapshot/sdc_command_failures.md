# O13 abs3 SDC Command Failure Review

- Run ID: `20260609_o13_abs5b_pd_q1_source_fix`
- SDC overlay: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5_o13_abs5.sdc`
- Genus log: `genus_20260609_o13_abs5b_pd_q1_source_fix.log`

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
18942:MPTDC_SDC_INFO: set_case_analysis 1 shared_readout_en_i
18943:MPTDC_SDC_INFO: set_case_analysis 0 narrow_ready_i
18952:-- The command 'set_false_path -to [get_pins -quiet -hierarchical $pattern]' is present in line '15' of proc '::mptdc_try_false_path_pins'
18953:-- The command passed to the interpreter is : '::dc::set_false_path -to 0x80'
18957:        : If, as a result of 'set_max_delay' or 'set_disable_timing' constraint operations, the to-point does not become a valid timing endpoint, then the exception will not be applied to this to-point.
18968:-- The command 'set_false_path -to [get_pins -quiet -hierarchical $pattern]' is present in line '15' of proc '::mptdc_try_false_path_pins'
18969:-- The command passed to the interpreter is : '::dc::set_false_path -to 0x84'
18975:MPTDC_SDC_INFO: false-pathing PD conversion clear pins (2 pattern-expanded pins)
18976:MPTDC_SDC_INFO: false-pathing PD conversion clear pins applied without pattern failures
18977:MPTDC_SDC_WARN: no pins matched for Gray counter async clear pins
18978:MPTDC_SDC_INFO: false-pathing START watchdog async clear pins (4 pattern-expanded pins)
18979:MPTDC_SDC_INFO: false-pathing START watchdog async clear pins applied without pattern failures
18980:MPTDC_SDC_INFO: false-pathing STOP metadata async capture data pins (5 pattern-expanded pins)
18981:MPTDC_SDC_INFO: false-pathing STOP metadata async capture data pins applied without pattern failures
18988:Warning : Invalid object passed to SDC command. [SDC-248] [set_dont_touch]
18993:MPTDC_SDC_INFO: max-delaying STOP metadata static bus into clk_sys snapshot from 4 pattern-expanded pin(s) to 2 pattern-expanded pin(s)
18994:MPTDC_SDC_INFO: max-delay STOP metadata static bus into clk_sys snapshot applied across 8 pattern pair(s)
18995:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_*_n* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
18996:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_n_o* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
18997:MPTDC_SDC_INFO: reset net max-transition target 0.35 ns for *rst_sys_*_n* is checked by DRV reports; direct set_max_transition on nets is skipped because this Genus SDC mode rejects net objects
19010: "set_clock_groups"         - successful      1 , failed      0 (runtime  0.00)
19014: "set_false_path"           - successful     27 , failed      0 (runtime  0.01)
19019: "set_max_delay"            - successful     11 , failed      0 (runtime  0.02)
19021: "set_max_transition"       - successful      1 , failed      0 (runtime  0.00)
19028:MPTDC_O13_ABS5_SDC_INFO: loading O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH overlay
19029:MPTDC_O13_ABS5_SDC_INFO: sourcing O13 abs3 clock/CDC repair overlay first
19030:MPTDC_O13_ABS3_SDC_INFO: loading O13_ABS3_CLOCK_CDC_CONSTRAINT_REPAIR overlay
19031:MPTDC_O13_ABS3_SDC_INFO: signoff status = TYPICAL_ONLY_NOT_MMMC_NOT_FINAL_SIGNOFF
19032:MPTDC_O13_ABS3_SDC_INFO: expected RTL define = MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12
19033:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap0 from 0x191 to 0x223
19034:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap1 from 0x233 to 0x265
19035:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap2 from 0x275 to 0x307
19036:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap3 from 0x317 to 0x349
19037:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap4 from 0x359 to 0x391
19038:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap5 from 0x401 to 0x433
19039:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap6 from 0x443 to 0x475
19040:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_slow_buf_tap7 from 0x485 to 0x517
19041:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap0 from 0x527 to 0x559
19042:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap1 from 0x569 to 0x601
19043:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap2 from 0x611 to 0x643
19044:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap3 from 0x653 to 0x685
19045:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap4 from 0x695 to 0x727
19046:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap5 from 0x737 to 0x769
19047:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap6 from 0x779 to 0x811
19048:MPTDC_O13_ABS3_SDC_INFO: created clk_osc_fast_buf_tap7 from 0x821 to 0x853
19049:MPTDC_O13_ABS3_SDC_INFO: matched raw RO pins = 16
19050:MPTDC_O13_ABS3_SDC_INFO: matched BUHDX4 iso A pins = 16
19051:MPTDC_O13_ABS3_SDC_INFO: matched BUHDX4 iso Q pins = 16
19052:MPTDC_O13_ABS3_SDC_INFO: matched BUHDX12 driver A pins = 16
19053:MPTDC_O13_ABS3_SDC_INFO: matched BUHDX12 driver Q pins = 16
19054:MPTDC_O13_ABS3_SDC_INFO: raw clock count = 16
19055:MPTDC_O13_ABS3_SDC_INFO: buffer slow clock count = 8
19056:MPTDC_O13_ABS3_SDC_INFO: buffer fast clock count = 8
19057:MPTDC_O13_ABS3_SDC_INFO: generated final-driver clocks = 16
19058:MPTDC_O13_ABS3_SDC_INFO: oscillator clocks in async group = 32
19059:MPTDC_O13_ABS3_SDC_INFO: clk_sys async to raw+buffer oscillator clocks = YES
19060:MPTDC_O13_ABS3_SDC_INFO: raw RO clocks remain analog load-check source clocks
19061:MPTDC_O13_ABS3_SDC_INFO: BUHDX12 Q clocks are downstream digital phase-clock sources
19062:MPTDC_O13_ABS3_SDC_INFO: phase-buffer chain and same-domain oscillator paths remain timed
19064:Error   : Could not interpret SDC command. [SDC-202] [read_sdc]
19091:Error   : Could not interpret SDC command. [SDC-202] [read_sdc]
19105:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_FOUND_ENDPOINTS=0
19106:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXPECTED_ENDPOINTS=64
19107:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_FOUND_SOURCES=8
19108:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXPECTED_SOURCES=8
19109:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXCEPTION_APPLIED=NO
19110:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_OVERMATCH=NO
19111:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_UNDERMATCH=YES
19112:MPTDC_O13_ABS5_SDC_INFO: PD_VERNIER_EXCEPTION_FAILURES=0
19113:Error   : Could not interpret SDC command. [SDC-202] [read_sdc]
19163:Error   : Could not interpret SDC command. [SDC-202] [read_sdc]
19220:Error   : Could not interpret SDC command. [SDC-202] [read_sdc]
19265: "set_clock_groups"         - successful      1 , failed      0 (runtime  0.00)
19267:Warning : One or more commands failed when these constraints were applied. [SDC-209]
19778:@file(genus.tcl) 177: mptdc_report_timing $design(synthesis_reports)
19821:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19824:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19826:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19828:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19830:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19832:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19834:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19836:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19840:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19842:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19844:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19846:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19848:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19850:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19852:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19854:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19856:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19858:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19860:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19862:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
19865:        : Maximum print count of '20' reached for message 'TIM-234'.
23733:|SDC-202    |Error  |    5|Could not interpret SDC command.                                                                                                                                                  |
23735:|SDC-209    |Warning|    1|One or more commands failed when these constraints were applied.                                                                                                                  |
23737:|SDC-248    |Warning|    1|Invalid object passed to SDC command.                                                                                                                                             |
23743:|TIM-234    |Error  |   28|Invalid path specification.  A 'to' object is invalid.                                                                                                                            |
23746:|           |       |     |If, as a result of 'set_max_delay' or 'set_disable_timing' constraint operations, the to-point does not become a valid timing endpoint, then the exception will not be applied to |
26127:@file(genus.tcl) 211: mptdc_report_timing $design(synthesis_reports)
26144:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
26146:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
26148:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
26150:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
28283:|TIM-234  |Error  |    4|Invalid path specification.  A 'to' object is invalid.                                                                                                                              |
28638:@file(genus.tcl) 218: mptdc_report_timing $design(synthesis_reports)
28655:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
28657:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
28659:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
28661:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
30344:|TIM-234  |Error  |    4|Invalid path specification.  A 'to' object is invalid.                                                                                                                              |
30589:@file(genus.tcl) 235: mptdc_report_timing $design(synthesis_reports)
30606:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
30608:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
30610:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]
30612:Error   : Invalid path specification.  A 'to' object is invalid. [TIM-234] [report_timing]

## Interpretation

- Object-handle SDC failures are expected to disappear after the abs3 helper repair.
- Final buffer clocks must be grouped asynchronously against clk_sys.
- Any remaining failed false-path, max-delay, clock-group, or generated-clock command requires review before Innovus.
