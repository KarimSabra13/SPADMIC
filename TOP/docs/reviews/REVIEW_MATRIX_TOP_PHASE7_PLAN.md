# Review: Matrix TOP Phase 7 Planning Baseline

Status: Phase 0/Phase 1 preflight and roadmap review.

## Metadata

- Branch: `SPADMIC_test`
- Commit reviewed: `5cdf489fbfb0a13e1a5ee7f5a253002e023602ac`
- Commit message: `5cdf489f matrix top phased integration`
- Date: `2026-06-28`
- Reviewer role: SUBAGENT B / Verifier, read-only preflight plus Builder cross-check.

## Files Reviewed

- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/rtl/spadmic_matrix_top_csr.sv`
- `TOP/rtl/spadmic_event_coordinator.sv`
- `TOP/rtl/spadmic_matrix_snapshot_frontend.sv`
- `TOP/rtl/spadmic_matrix_cfg_ctrl.sv`
- `TOP/rtl/spadmic_position_snapshot_packetizer.sv`
- `TOP/rtl/spadmic_event_bundle_tx.sv`
- `TOP/rtl/spadmic_ddr16_tx_pairer.sv`
- `TOP/rtl/spadmic_pkg.sv`
- `I2C/rtl/spadmic_i2c_slave.sv`
- `I2C/rtl/spadmic_i2c_csr_bridge.sv`
- `TOP/filelist.f`
- `TOP/ci/run_tapeout_readiness.sh`

## Repository Guard

Commands:

- `git status --short`, captured before creating this documentation diff
  - only user-owned untracked reference files are present.
- `git branch --show-current`
  - `SPADMIC_test`.
- `git rev-parse HEAD`
  - `5cdf489fbfb0a13e1a5ee7f5a253002e023602ac`.
- `git log -1 --oneline`
  - `5cdf489f matrix top phased integration`.
- `git diff --name-only HEAD -- MPTDC/...protected TOP/rtl/spadmic_top_v1.sv`
  - no output.

Result: no protected MPTDC internal diff and no `spadmic_top_v1.sv` diff at preflight.

## Tests Run

- `git diff --check`: pass.
- `bash TOP/ci/run_tapeout_readiness.sh`: pass locally.
  - Summary: 14 pass, 0 fail, 4 skipped.
  - Skipped: Xcelium TOP smoke, Xcelium directed regression, retired VIP smoke, retired VIP feature suite.

The skipped Xcelium items are not pass evidence.

## Findings

| Severity | Finding | Evidence | Required Fix |
| --- | --- | --- | --- |
| HIGH | Full-top BOTH coverage is missing from the readiness gate. | `tb_spadmic_top_matrix_v1_shell_unit.sv` covers position-only and TDC-only, while BOTH is only coordinator-level. | Add `tb_spadmic_top_matrix_v1_both_full_unit` with real wrappers and add it to readiness. |
| HIGH | Matrix configuration readback is not Cout-based. | `spadmic_matrix_cfg_ctrl.sv` leaves `matrix_cout_i` unused and returns write data for write readback. | Use returned Cout edge/strobe to sample Dout, add timeout/error/status. |
| MEDIUM | New-top position path is raw-only. | `spadmic_position_snapshot_packetizer.sv` emits raw bitmap packet words only. | Integrate snapshot-driven raw/cluster mode packetization. |
| MEDIUM | No real output FIFO is present. | `spadmic_event_bundle_tx` feeds `spadmic_ddr16_tx_pairer` directly. | Insert 512-word `clk_sys` FIFO and mode/worst-case admission threshold. |
| MEDIUM | CSR path is still 12-bit. | `SPADMIC_CSR_ADDR_W = 12`; I2C pointer high byte stores only four high bits. | Widen CSR address path to 16 bits and add final 0x0000-0x7FFF regions. |
| MEDIUM | Shared TDC config is not plumbed. | New top wires `max_hits_i` to constant `MAX_HITS` and RO codes to `8'h00`. | Add shared TDC config CSRs and connect all wrappers. |
| MEDIUM | Skew campaign is not in local readiness. | No current `tb_spadmic_top_matrix_v1_skew_campaign` in `TOP/tb` or readiness list. | Add directed six-order skew tests with required offsets. |
| HIGH | Phase 1 docs initially described server wrapper commands before the scripts existed. | Verifier review of the doc-only diff. | Fixed by marking Xcelium/Genus/Innovus command blocks as planned-after-script-creation. |

## Builder Response

Accepted. Phase 1 documentation now records these as known limitations and creates the execution roadmap. RTL implementation will be split into reviewed phases:

1. CSR16 and shared TDC config.
2. Position raw/cluster.
3. Cout-based matrix readback.
4. Output FIFO/admission.
5. Verification expansion.
6. Server Xcelium/Genus/Innovus scripts.

## Signoff Statement

This review is local/open-source only. It does not claim Xcelium pass, CDC/RDC signoff, Genus timing closure, Innovus closure, DRC/LVS/PEX, MMMC, DDR timing signoff, matrix macro timing signoff, or tapeout readiness.
