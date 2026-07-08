# DDR16 TX Macro Contract

Status: staged macro-boundary contract. The DDRs2 schematic now fixes the lane
count and v1 mapping, but final analog timing remains TBD.

## Final Direction

The final physical TX macro is DDRs2, an analog/custom north-side fast-output
macro. It must not be synthesized by TOP Genus.

DDRs2 has 19 homogeneous DDR lanes:

- lanes `0..15`: data;
- lane `16`: valid;
- lane `17`: forwarded clock;
- lane `18`: spare.

There is no marker lane. The valid lane is a simple data-valid indicator for
the FPGA receiver, not an error flag. The spare lane is tied low by the digital
adapter and is unused by the v1 protocol.

The current 8-bit DDR TX RTL is obsolete for final silicon and must not be used
as the final macro boundary.

The digital design shall provide a clean single-edge RTL boundary to custom
SLVS/DDR driver wrappers. It shall not implement final DDR behavior using
generic dual-edge procedural logic.

## Internal Digital Boundary

```systemverilog
output logic [15:0] ddr_data_l_o;
output logic [15:0] ddr_data_h_o;
output logic        ddr_pair_valid_o;
output logic        ddr_clk_o;
```

Defaults:

- `ddr_data_l_o` is the older logical 16-bit word.
- `ddr_data_h_o` is the next logical 16-bit word.
- `ddr_pair_valid_o` qualifies the pair and feeds DDRs2 lane 16 through the adapter.
- `ddr_clk_o` remains the internal 160 MHz forwarded-clock source signal.
- Idle drives data zero and valid low.

Exact DATA_L/DATA_H edge mapping is TBD with the DDR macro designer.

## DDRs2 Adapter Boundary

`spadmic_ddrs2_adapter` is the only RTL block that expands the internal DDR16
stream to the 19-lane DDRs2 macro input contract:

```systemverilog
input  logic [15:0] ddr_data_l_i;
input  logic [15:0] ddr_data_h_i;
input  logic        ddr_pair_valid_i;
input  logic        clk_160m_i;
input  logic        rst_n;
input  logic        enable_i;
output logic [18:0] ddrs2_data_l_o;
output logic [18:0] ddrs2_data_h_o;
output logic        ddrs2_clk_160m_o;
```

Mapping:

- `ddrs2_data_l_o[15:0] = ddr_data_l_i[15:0]` when enabled;
- `ddrs2_data_h_o[15:0] = ddr_data_h_i[15:0]` when enabled;
- lane `16` drives `ddr_pair_valid_i` on both low/high phases;
- lane `17` drives the forwarded-clock DDR pattern, default `DATA_L=0`,
  `DATA_H=1`;
- lane `18` is tied low;
- `ddrs2_clk_160m_o = clk_160m_i`.

The adapter has a local `FORWARDED_CLK_INVERT` parameter so the lane-17
`DATA_L/DATA_H` polarity can be flipped without touching `spadmic_ddr16_tx_pairer`.
The final top wrapper maps adapter outputs to DDRs2 `DATA_L<18:0>`,
`DATA_H<18:0>`, and `CLK_160M`.

## SLVS/Receiver GPIO Controls

The matrix-top digital core also exposes CSR-driven internal control outputs
for the SLVS driver and receiver/tap-monitor custom block. These are not pad
signals by themselves; the final chip wrapper routes them to the analog/custom
receiver/driver block placed near the right/top side of the chip.

Control register:

- `SPADMIC_CSR_SLVS_GPIO_CTRL = 16'h7010`

Implemented fields:

- `[3:0]`  -> `slvs_s_drv_o[3:0]`
- `[4]`    -> `slvs_en_vref_ext_o`
- `[5]`    -> `slvs_en_drv_o`
- `[6]`    -> `slvs_vref_adj_b_o`
- `[7]`    -> `slvs_en_vref_400mv_o`
- `[8]`    -> `slvs_en_ref_drv_b_o`
- `[12:9]` -> `rx_s_rx_o[3:0]`
- `[13]`   -> `rx_en_rx_o`
- `[14]`   -> `rx_en_term_o`
- `[31:15]` reserved, read as zero

`VREF_ADJ_B` and `EN_REF_DRV_B` are passed through exactly as stored by CSR.
They are likely analog active-low controls, but the digital RTL intentionally
does not invert them. Reset defaults are zero until the analog designer confirms
whether different active-low defaults are required.

## Pairing Stage

The matrix-top output path is:

```text
spadmic_event_bundle_tx
  -> spadmic_output_fifo
  -> spadmic_ddr16_tx_pairer
  -> spadmic_ddrs2_adapter
  -> DDRs2 macro boundary
```

`spadmic_output_fifo` is synchronous to `clk_sys`, has 256 entries in the
current physical-planning target, and is used by event admission through a
129-entry reservation threshold. That
threshold covers the 128-word logical bundle estimate plus one ordered flush
marker. In the top integration each FIFO entry carries 16 logical data bits plus
one internal flush-marker bit. Bundle TX words enter the FIFO as data entries;
bundle `flush_o` enters as an ordered marker. This prevents an odd final word
from one bundle from being paired with the first word of a later bundle.

`spadmic_ddr16_tx_pairer` converts FIFO data entries into DDR macro pairs:

- collects the first word into a low/first holding register;
- collects the second word into a high/second holding register;
- presents both words together for one pair transfer;
- exposes `busy_o` and `empty_o` for TOP safe-idle logic.
- pads the high/second half with zero when it receives a flush marker while one
  word is held.

Because v1 defaults to one valid per pair, odd bundle lengths are represented by
a padded DDR pair rather than a per-half valid. If the final macro supports
per-half valid, this contract can be extended to `valid_l/valid_h` and the
pairer can avoid padding.

## Open DDR Designer Items

- Final confirmation of DDRs2 DATA_L/DATA_H polarity for lane 17.
- Which of DATA_L/DATA_H appears on the rising/falling edge?
- Whether DDRs2 needs additional enable/reset controls beyond the GPIO CSR set.
- Reset behavior and required idle values.
- Clock-to-output delay.
- Duty-cycle requirements.
- Pin load and board assumptions.

## Constraints And Signoff Status

- No final board timing exists.
- No final DDR macro timing exists.
- SDC for this boundary is placeholder only until macro and board contracts arrive.
- TOP safe idle must include bundle TX idle, output FIFO empty, no pending FIFO
  flush marker, DDR pairer empty/busy state, and no pending physical valid.
