# DDRs2 Adapter Plan

Status: implemented RTL adapter plan for the staged, block-by-block TOP flow.

## Purpose

`spadmic_ddrs2_adapter` is the small digital block between
`spadmic_ddr16_tx_pairer` and the DDRs2 analog/custom macro. It keeps the
internal event stream and pairer at 16 data bits, while localizing the 19-lane
DDRs2 macro mapping in one easy-to-review RTL block.

The active path is:

```text
event_bundle_tx
  -> output_fifo_256
  -> spadmic_ddr16_tx_pairer
  -> spadmic_ddrs2_adapter
  -> DDRs2 macro
```

## RTL Interface

Inputs:

- `clk_160m_i`
- `rst_n`
- `enable_i`
- `ddr_data_l_i[15:0]`
- `ddr_data_h_i[15:0]`
- `ddr_pair_valid_i`

Outputs:

- `ddrs2_data_l_o[18:0]`
- `ddrs2_data_h_o[18:0]`
- `ddrs2_clk_160m_o`

`ddrs2_clk_160m_o` follows `clk_160m_i`; the adapter does not implement a clock
mux, divider, or pad driver.

## Lane Mapping

| DDRs2 lane | `DATA_L` | `DATA_H` | Notes |
| ---: | --- | --- | --- |
| `0..15` | `ddr_data_l_i[15:0]` when enabled | `ddr_data_h_i[15:0]` when enabled | data |
| `16` | `ddr_pair_valid_i` | `ddr_pair_valid_i` | data-valid lane |
| `17` | `0` by default | `1` by default | forwarded-clock DDR pattern |
| `18` | `0` | `0` | spare, unused |

If `rst_n=0` or `enable_i=0`, all `DATA_L/H` lanes are driven low. The macro
clock output still follows the input clock.

The forwarded-clock lane has parameter `FORWARDED_CLK_INVERT`. If the analog
designer confirms the opposite polarity, set that parameter instead of changing
`spadmic_ddr16_tx_pairer`.

## Verification

`tb_spadmic_ddrs2_adapter_unit` checks:

- reset/disabled lane quieting;
- data lane mapping `0..15`;
- valid lane `16`;
- forwarded clock lane `17`;
- spare lane `18`;
- direct 160 MHz clock forwarding;
- polarity swap through `FORWARDED_CLK_INVERT`.

## Physical Flow

`spadmic_ddrs2_adapter` is a standalone hardenable digital block for the staged
flow. It is included after `ddr16_pairer` in:

- `TOP/syn/scripts/run_genus_all_matrix_ooc.sh`;
- `TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh`.

DDRs2 itself remains a black-box analog/custom macro and must not be synthesized
by TOP Genus.
