# MPTDC Server Snapshot

- Kind: `pvs`
- Run ID: `20260901_191119_mptdc_v13_pg15_compositional_pvs_02_template_audit`
- Source directory: `/sim/ksabra/SPADMIC_work/innovus/20260901_191119_mptdc_v13_pg15_compositional_pvs`
- Snapshot directory: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/docs/server_snapshots/pvs/20260901_191119_mptdc_v13_pg15_compositional_pvs_02_template_audit`
- Collection branch: `SPADMIC_test`
- Collection commit: `7258c72f37ec8141174f8be3bc96e6a4c10c62ac`
- Created UTC: `2026-09-01T17:12:48Z`

## Included Files
- `README.md`
- `logs/innovus_prepare_pvs_inputs.log.messages.tail`
- `logs/operator_template_audit.log.messages.tail`
- `logs/prepare_pvs_inputs.log.messages.tail`
- `manifests/pvs_diagnostic_scope.rpt`
- `manifests/pvs_input_hashes.rpt`
- `manifests/pvs_input_manifest.txt`
- `outputs/pvs_hcell_ro6.txt`
- `reports/check_place_before_streamout.rpt`
- `reports/connectivity_regular_before_streamout.rpt`
- `reports/connectivity_special_before_streamout.rpt`
- `reports/lvs_source_filter.rpt`
- `reports/operator_gate_pvs_prepare.rpt`
- `reports/operator_gate_pvs_template_audit.rpt`
- `reports/pvs_prepared_inputs.rpt`
- `reports/pvs_template_audit.rpt`
- `reports/streamout_map_binding.rpt`
- `reports/streamout_merged_ro6_manifest.txt`
- `reports/tap_pin_contract.rpt`
- `reports/verify_drc_before_streamout.rpt`

## Excluded By Policy

- Innovus checkpoints and databases;
- raw GDS/OAS files;
- full raw logs unless converted to message tails;
- text files larger than 2097152 bytes;
- large binary artifacts, except bounded manager images when explicitly requested;
- server work directories outside this snapshot.
