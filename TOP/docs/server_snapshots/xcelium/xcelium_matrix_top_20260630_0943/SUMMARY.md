# SPADMIC Matrix TOP Xcelium Run

- Run ID: `xcelium_matrix_top_20260630_0943`
- Repository: `/home/validmgr/ksabra/2026_SPAD/SPADMIC`
- Run directory: `/sim/ksabra/SPADMIC_work/xcelium/xcelium_matrix_top_20260630_0943`
- Command: `bash TOP/ci/server_run_matrix_top_xcelium.sh xcelium_matrix_top_20260630_0943`
- Branch: `SPADMIC_test`
- Commit: `fe8f68712e5e6a3f990c996c3daf2b957613a889`
- Xrun version: `TOOL:	xrun(64)	23.03-s007`
- Status: see Final Result

## Tests

| Test | Result | Notes |
| --- | --- | --- |
| `tb_spadmic_arb_modes` | PASS | log: `logs/tb_spadmic_arb_modes.log` |
| `tb_spadmic_arb_stress` | PASS | log: `logs/tb_spadmic_arb_stress.log` |
| `tb_spadmic_i2c_control_plane_unit` | PASS | log: `logs/tb_spadmic_i2c_control_plane_unit.log` |
| `tb_spadmic_i2c_matrix_top_16b_unit` | PASS | log: `logs/tb_spadmic_i2c_matrix_top_16b_unit.log` |
| `tb_spadmic_matrix_or_tree_unit` | PASS | log: `logs/tb_spadmic_matrix_or_tree_unit.log` |
| `tb_spadmic_matrix_snapshot_frontend_unit` | PASS | log: `logs/tb_spadmic_matrix_snapshot_frontend_unit.log` |
| `tb_spadmic_matrix_reset_ctrl_unit` | PASS | log: `logs/tb_spadmic_matrix_reset_ctrl_unit.log` |
| `tb_spadmic_event_coordinator_modes_unit` | PASS | log: `logs/tb_spadmic_event_coordinator_modes_unit.log` |
| `tb_spadmic_position_snapshot_packetizer_unit` | PASS | log: `logs/tb_spadmic_position_snapshot_packetizer_unit.log` |
| `tb_spadmic_position_modes_unit` | PASS | log: `logs/tb_spadmic_position_modes_unit.log` |
| `tb_spadmic_position_snapshot_cluster_unit` | PASS | log: `logs/tb_spadmic_position_snapshot_cluster_unit.log` |
| `tb_spadmic_output_fifo_unit` | PASS | log: `logs/tb_spadmic_output_fifo_unit.log` |
| `tb_spadmic_output_fifo_ddr_marker_unit` | PASS | log: `logs/tb_spadmic_output_fifo_ddr_marker_unit.log` |
| `tb_spadmic_ddr16_tx_pairer_unit` | PASS | log: `logs/tb_spadmic_ddr16_tx_pairer_unit.log` |
| `tb_spadmic_matrix_cfg_ctrl_unit` | PASS | log: `logs/tb_spadmic_matrix_cfg_ctrl_unit.log` |
| `tb_spadmic_matrix_cfg_cout_readback_unit` | PASS | log: `logs/tb_spadmic_matrix_cfg_cout_readback_unit.log` |
| `tb_spadmic_event_bundle_tx_unit` | PASS | log: `logs/tb_spadmic_event_bundle_tx_unit.log` |
| `tb_spadmic_matrix_top_csr_unit` | PASS | log: `logs/tb_spadmic_matrix_top_csr_unit.log` |
| `tb_spadmic_matrix_top_csr_16b_unit` | PASS | log: `logs/tb_spadmic_matrix_top_csr_16b_unit.log` |
| `tb_spadmic_top_matrix_v1_shell_unit` | PASS | log: `logs/tb_spadmic_top_matrix_v1_shell_unit.log` |
| `tb_spadmic_top_output_pressure_unit` | PASS | log: `logs/tb_spadmic_top_output_pressure_unit.log` |
| `tb_spadmic_top_output_fifo_pressure_integration_unit` | PASS | log: `logs/tb_spadmic_top_output_fifo_pressure_integration_unit.log` |
| `tb_spadmic_top_matrix_v1_both_full_unit` | FAIL | rc=2; tail: `logs/tb_spadmic_top_matrix_v1_both_full_unit.tail` |

### Failure Detail: `tb_spadmic_top_matrix_v1_both_full_unit`

- First error: `No explicit ERROR/FATAL marker found; inspect the log tail.`
- Tail file: `logs/tb_spadmic_top_matrix_v1_both_full_unit.tail`

```text
		Always blocks:          959      93
		Initial blocks:         139      12
		Cont. assignments:      544     274
		Pseudo assignments:     461       -
		Assertions:             365      25
		Simulation timescale:   1ps
	Writing initial simulation snapshot: worklib.tb_spadmic_top_matrix_v1_both_full_unit:sv
Loading snapshot worklib.tb_spadmic_top_matrix_v1_both_full_unit:sv .................... Done
xcelium> source /eda/cadence/2023-24/RHELx86/XCELIUM_23.03.007/tools/xcelium/files/xmsimrc
xcelium> run
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=55 HALF_PERIOD=440
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=50 HALF_PERIOD=400
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=55 HALF_PERIOD=440
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=50 HALF_PERIOD=400
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=55 HALF_PERIOD=440
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=50 HALF_PERIOD=400
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
xmsim: *W,TRNEGDEL: negative delay encountered, using delay of zero.
            File: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_matrix_v1_both_full_unit.sv, line = 196, pos = 4
           Scope: tb_spadmic_top_matrix_v1_both_full_unit
            Time: 0 FS + 0

xmsim: *F,FATSEV (/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_matrix_v1_both_full_unit.sv,197): (time 0 FS).
tb_spadmic_top_matrix_v1_both_full_unit
tb_spadmic_top_matrix_v1_both_full_unit: TIMEOUT
Simulation terminated via $fatal(1) at time 0 FS + 1
/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_matrix_v1_both_full_unit.sv:197     $fatal(1, "tb_spadmic_top_matrix_v1_both_full_unit: TIMEOUT");
xcelium> exit
TOOL:	xrun(64)	23.03-s007: Exiting on Jun 30, 2026 at 09:44:38 CEST  (total: 00:00:02)
```
| `tb_spadmic_top_matrix_v1_skew_campaign` | FAIL | rc=2; tail: `logs/tb_spadmic_top_matrix_v1_skew_campaign.tail` |

### Failure Detail: `tb_spadmic_top_matrix_v1_skew_campaign`

- First error: `No explicit ERROR/FATAL marker found; inspect the log tail.`
- Tail file: `logs/tb_spadmic_top_matrix_v1_skew_campaign.tail`

```text
		Always blocks:          958      92
		Initial blocks:         139      12
		Cont. assignments:      544     274
		Pseudo assignments:     456       -
		Assertions:             365      25
		Simulation timescale:   1ps
	Writing initial simulation snapshot: worklib.tb_spadmic_top_matrix_v1_skew_campaign:sv
Loading snapshot worklib.tb_spadmic_top_matrix_v1_skew_campaign:sv .................... Done
xcelium> source /eda/cadence/2023-24/RHELx86/XCELIUM_23.03.007/tools/xcelium/files/xmsimrc
xcelium> run
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=55 HALF_PERIOD=440
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=50 HALF_PERIOD=400
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=55 HALF_PERIOD=440
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=50 HALF_PERIOD=400
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=55 HALF_PERIOD=440
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=50 HALF_PERIOD=400
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
xmsim: *W,TRNEGDEL: negative delay encountered, using delay of zero.
            File: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_matrix_v1_skew_campaign.sv, line = 329, pos = 4
           Scope: tb_spadmic_top_matrix_v1_skew_campaign
            Time: 0 FS + 0

xmsim: *F,FATSEV (/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_matrix_v1_skew_campaign.sv,330): (time 0 FS).
tb_spadmic_top_matrix_v1_skew_campaign
tb_spadmic_top_matrix_v1_skew_campaign: TIMEOUT
Simulation terminated via $fatal(1) at time 0 FS + 1
/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_matrix_v1_skew_campaign.sv:330     $fatal(1, "tb_spadmic_top_matrix_v1_skew_campaign: TIMEOUT");
xcelium> exit
TOOL:	xrun(64)	23.03-s007: Exiting on Jun 30, 2026 at 09:44:40 CEST  (total: 00:00:02)
```
| `tb_spadmic_top_reset_during_event_unit` | PASS | log: `logs/tb_spadmic_top_reset_during_event_unit.log` |
| `tb_spadmic_top_reset_during_matrix_cfg_unit` | FAIL | rc=1; tail: `logs/tb_spadmic_top_reset_during_matrix_cfg_unit.tail` |

### Failure Detail: `tb_spadmic_top_reset_during_matrix_cfg_unit`

- First error: `xmelab: *E,MULAXX (/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_reset_during_matrix_cfg_unit.sv,71_10): Multiple drivers to always_ff output variable saw_reset_error detected.`
- Tail file: `logs/tb_spadmic_top_reset_during_matrix_cfg_unit.tail`

```text
file: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/../arb/rtl/spadmic_correlated_tx.sv
	module worklib.spadmic_correlated_tx:sv
		errors: 0, warnings: 0
file: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/rtl/spadmic_ddr_tx.sv
	module worklib.spadmic_ddr_tx:sv
		errors: 0, warnings: 0
file: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/../position/rtl/spadmic_axis_cluster_scan.sv
	module worklib.spadmic_axis_cluster_scan:sv
		errors: 0, warnings: 0
file: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/../position/rtl/spadmic_position_block.sv
	module worklib.spadmic_position_block:sv
		errors: 0, warnings: 0
file: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/rtl/spadmic_tdc_axis_wrapper.sv
  input  mptdc_pkg::input_sel_e     input_sel_i,
                                              |
xmvlog: *W,NODNTW (/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/rtl/spadmic_tdc_axis_wrapper.sv,19|46): Implicit net port (input_sel_i) is not allowed since `default_nettype is declared as 'none'; 'wire' used instead [19.2(IEEE 2001)].
	module worklib.spadmic_tdc_axis_wrapper:sv
		errors: 0, warnings: 1
file: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/rtl/spadmic_top_v1.sv
	module worklib.spadmic_top_v1:sv
		errors: 0, warnings: 0
file: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/rtl/spadmic_top_matrix_v1.sv
	module worklib.spadmic_top_matrix_v1:sv
		errors: 0, warnings: 0
file: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_reset_during_matrix_cfg_unit.sv
	module worklib.tb_spadmic_top_reset_during_matrix_cfg_unit:sv
		errors: 0, warnings: 0
xmvlog: *W,SPDUSD: Include directory /home/validmgr/ksabra/2026_SPAD/SPADMIC given but not used.
xmvlog: *W,SPDUSD: Include directory /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb given but not used.
	Total errors/warnings found outside modules and primitives:
		errors: 0, warnings: 2
	Elaborating the design hierarchy:
		Caching library 'worklib' ....... Done
	Top level design units:
		tb_spadmic_top_reset_during_matrix_cfg_unit
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
          |
xmelab: *E,MULAXX (/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_reset_during_matrix_cfg_unit.sv,71|10): Multiple drivers to always_ff output variable saw_reset_error detected.
xrun: *E,ELBERR: Error (*E) or soft error (*SE) occurred during elaboration (status 1), exiting.
TOOL:	xrun(64)	23.03-s007: Exiting on Jun 30, 2026 at 09:44:42 CEST  (total: 00:00:00)
```
| `tb_spadmic_top_mode_transition_unit` | FAIL | rc=2; tail: `logs/tb_spadmic_top_mode_transition_unit.tail` |

### Failure Detail: `tb_spadmic_top_mode_transition_unit`

- First error: `No explicit ERROR/FATAL marker found; inspect the log tail.`
- Tail file: `logs/tb_spadmic_top_mode_transition_unit.tail`

```text
		Always blocks:          958      92
		Initial blocks:         139      12
		Cont. assignments:      544     274
		Pseudo assignments:     456       -
		Assertions:             365      25
		Simulation timescale:   1ps
	Writing initial simulation snapshot: worklib.tb_spadmic_top_mode_transition_unit:sv
Loading snapshot worklib.tb_spadmic_top_mode_transition_unit:sv .................... Done
xcelium> source /eda/cadence/2023-24/RHELx86/XCELIUM_23.03.007/tools/xcelium/files/xmsimrc
xcelium> run
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=55 HALF_PERIOD=440
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=50 HALF_PERIOD=400
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=55 HALF_PERIOD=440
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=50 HALF_PERIOD=400
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=55 HALF_PERIOD=440
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
[OSC_WRAPPER] MODE = MODEL (behavioural simulation with #delays)
[OSC_MODEL] NE=8 TS_STEP_PS=50 HALF_PERIOD=400
[OSC_MODEL] jitter_sigma_ps=0 jitter_bound_ps=0
xmsim: *W,TRNEGDEL: negative delay encountered, using delay of zero.
            File: /home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_mode_transition_unit.sv, line = 162, pos = 4
           Scope: tb_spadmic_top_mode_transition_unit
            Time: 0 FS + 0

xmsim: *F,FATSEV (/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_mode_transition_unit.sv,163): (time 0 FS).
tb_spadmic_top_mode_transition_unit
tb_spadmic_top_mode_transition_unit: TIMEOUT
Simulation terminated via $fatal(1) at time 0 FS + 1
/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/tb/tb_spadmic_top_mode_transition_unit.sv:163     $fatal(1, "tb_spadmic_top_mode_transition_unit: TIMEOUT");
xcelium> exit
TOOL:	xrun(64)	23.03-s007: Exiting on Jun 30, 2026 at 09:44:44 CEST  (total: 00:00:01)
```
| `tb_spadmic_top_sequencer_unit` | PASS | log: `logs/tb_spadmic_top_sequencer_unit.log` |
| `tb_spadmic_stress_csr` | PASS | log: `logs/tb_spadmic_stress_csr.log` |
| `tb_spadmic_stress_position` | PASS | log: `logs/tb_spadmic_stress_position.log` |
| `tb_spadmic_ddr_tx_unit` | PASS | log: `logs/tb_spadmic_ddr_tx_unit.log` |

## Final Result

- PASS: 27
- FAIL: 4
- MISSING: 0

Result: FAIL. Inspect logs and failure tails before making RTL decisions.

## Limitations

- This is Xcelium functional simulation, not CDC/RDC signoff.
- This is not Genus, Innovus, STA, DRC/LVS, PEX, MMMC, DDR macro timing, or matrix macro timing signoff.
