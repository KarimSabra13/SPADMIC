# SPADMIC Matrix TOP Genus OOC Run

- Run ID: `genus_matrix_ooc_rerun_20260630_1009`
- Run directory: `/sim/ksabra/SPADMIC_work/genus/genus_matrix_ooc_rerun_20260630_1009`
- Branch: `SPADMIC_test`
- Commit: `c306e947a86c5d1a545bf043b0a8ddd54096a51d`
- XH018 stack: `xx31`
- Standard-cell family: `JIHD`
- Route layers: `MET1 MET2 MET3 METTP`
- Ordinary signal top layer: `MET3`
- Effective top floor layer: `METTP`
- Signoff: non-signoff, typical-only feasibility

## Matrix TOP Genus Filelist

- Raw TOP filelist: `filelists/top_abs.raw.f`
- Genus TOP filelist: `filelists/top_abs.f`
- Excluded legacy/obsolete files: `filelists/top_genus_excluded.f`

Excluded files:
- `/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/rtl/spadmic_ddr_tx.sv`
- `/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/rtl/spadmic_top_v1.sv`

## Blocks

| Block | Top module | Result |
| --- | --- | --- |
| `position_snapshot` | `spadmic_position_snapshot_packetizer` | PASS |
| `output_fifo` | `spadmic_output_fifo` | PASS |
| `event_bundle_tx` | `spadmic_event_bundle_tx` | PASS |
| `or64_tree` | `spadmic_matrix_or_tree` | PASS |
| `matrix_reset_ctrl` | `spadmic_matrix_reset_ctrl` | PASS |
| `matrix_cfg_ctrl` | `spadmic_matrix_cfg_ctrl` | PASS |
| `ddr16_pairer` | `spadmic_ddr16_tx_pairer` | PASS |
| `event_coordinator` | `spadmic_event_coordinator` | PASS |
| `matrix_top_csr` | `spadmic_matrix_top_csr` | PASS |
| `i2c_csr_bridge` | `spadmic_i2c_csr_bridge` | PASS |
| `i2c_slave` | `spadmic_i2c_slave` | PASS |
| `spadmic_top_matrix_v1` | `spadmic_top_matrix_v1` | PASS |

## Final Result

- PASS: 12
- FAIL: 0

This run is not final timing closure, not MMMC, and not signoff.
