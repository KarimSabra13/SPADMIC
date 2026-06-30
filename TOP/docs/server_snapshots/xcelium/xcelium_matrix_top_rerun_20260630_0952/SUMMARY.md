# SPADMIC Matrix TOP Xcelium Run

- Run ID: `xcelium_matrix_top_rerun_20260630_0952`
- Repository: `/home/validmgr/ksabra/2026_SPAD/SPADMIC`
- Run directory: `/sim/ksabra/SPADMIC_work/xcelium/xcelium_matrix_top_rerun_20260630_0952`
- Command: `bash TOP/ci/server_run_matrix_top_xcelium.sh xcelium_matrix_top_rerun_20260630_0952`
- Branch: `SPADMIC_test`
- Commit: `d89a3f7e0e6180554038413491ad918606227740`
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
| `tb_spadmic_top_matrix_v1_both_full_unit` | PASS | log: `logs/tb_spadmic_top_matrix_v1_both_full_unit.log` |
| `tb_spadmic_top_matrix_v1_skew_campaign` | PASS | log: `logs/tb_spadmic_top_matrix_v1_skew_campaign.log` |
| `tb_spadmic_top_reset_during_event_unit` | PASS | log: `logs/tb_spadmic_top_reset_during_event_unit.log` |
| `tb_spadmic_top_reset_during_matrix_cfg_unit` | PASS | log: `logs/tb_spadmic_top_reset_during_matrix_cfg_unit.log` |
| `tb_spadmic_top_mode_transition_unit` | PASS | log: `logs/tb_spadmic_top_mode_transition_unit.log` |
| `tb_spadmic_top_sequencer_unit` | PASS | log: `logs/tb_spadmic_top_sequencer_unit.log` |
| `tb_spadmic_stress_csr` | PASS | log: `logs/tb_spadmic_stress_csr.log` |
| `tb_spadmic_stress_position` | PASS | log: `logs/tb_spadmic_stress_position.log` |
| `tb_spadmic_ddr_tx_unit` | PASS | log: `logs/tb_spadmic_ddr_tx_unit.log` |

## Final Result

- PASS: 31
- FAIL: 0
- MISSING: 0

Result: PASS for the required Xcelium regression scope.

## Limitations

- This is Xcelium functional simulation, not CDC/RDC signoff.
- This is not Genus, Innovus, STA, DRC/LVS, PEX, MMMC, DDR macro timing, or matrix macro timing signoff.
