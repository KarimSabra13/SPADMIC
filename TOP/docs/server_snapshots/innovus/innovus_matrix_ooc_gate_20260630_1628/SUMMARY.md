# SPADMIC Matrix TOP Innovus OOC Collateral Gate

- Run ID: `innovus_matrix_ooc_gate_20260630_1628`
- Run directory: `/sim/ksabra/SPADMIC_work/innovus/innovus_matrix_ooc_gate_20260630_1628`
- Genus run ID: `genus_matrix_ooc_staged_20260630_1516`
- Genus root: `/sim/ksabra/SPADMIC_work/genus/genus_matrix_ooc_staged_20260630_1516`
- Branch: `SPADMIC_test`
- Commit: `211bc80f0e46dafd6874f76bff46b32c4db2cea8`
- XH018 stack: `xx31`
- Standard-cell family: `JIHD`
- Route layers: `MET1 MET2 MET3 METTP`
- Ordinary signal top layer: `MET3`
- DDR16 included: `0`
- Signoff: non-signoff OOC collateral gate

## Connectivity-First Blocks

- `or64_tree`
- `matrix_reset_ctrl`
- `matrix_cfg_ctrl`
- `position_snapshot`
- `output_fifo`
- `event_bundle_tx`
- `event_coordinator`
- `matrix_top_csr`
- `i2c_csr_bridge`
- `i2c_slave`

## Result

- Result: READY_FOR_NEXT_IMPORT_TEMPLATE
- Missing required collateral count: 0

Per-block run directories were created. The next reviewed patch should add
the Innovus import/place/preCTS template rather than copying MPTDC-specific
RO/PD signoff scripts blindly.

This wrapper does not run placement, route, CTS, DRC/LVS, PEX, MMMC, or signoff.
