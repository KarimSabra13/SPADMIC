# DDRs2 / TXRX4TDC Interface Audit

Status: schematic-informed digital contract. DDRs2 and TXRX4TDC are
analog/custom macros and are not synthesized by TOP Genus.

## DDRs2

DDRs2 is the north fast-output macro.

Schematic-visible structure:

- `Iddr_iface<18:0>`: 19 `DDR_interface` instances;
- `tx<18:0>`: 19 `DRV_SLVS2` drivers;
- `I6`: `Bias_DRV_diode2`;
- top terms: `DATA_L<18:0>`, `DATA_H<18:0>`, `CLK_160M`,
  `Out_P<18:0>`, `Out_N<18:0>`, `DVDD`, `DVSS`, `PAD_VREF_EXT`,
  `S_DRV<3:0>`, `EN_VREF_EXT`, `EN_DRV`, `VREF_ADJ_B`,
  `EN_VREF_400mV`, `EN_REF_DRV_B`.

Frozen v1 lane meaning:

| Lane | Meaning | Digital source |
| ---: | --- | --- |
| `0..15` | Data | `spadmic_ddr16_tx_pairer.ddr_data_l/h_o[15:0]` |
| `16` | Valid | `ddr_pair_valid_o`, not an error flag |
| `17` | Forwarded clock | DDR pattern, default `DATA_L=0`, `DATA_H=1` |
| `18` | Spare | tied low |

There is no marker lane. Packet framing remains inside the logical event stream
and output FIFO flush-marker handling; it is not exported as a DDRs2 lane.

## TXRX4TDC

TXRX4TDC is an analog/custom receiver/tap-monitor macro.

Schematic-visible structure:

- `tx<0:5>`: 6 SLVS drivers;
- `rx<0:5>`: 6 SLVS receivers;
- `Bias_DRV_diode2`;
- top terms: `R<0:5>`, `T<0:5>`, `R_P<0:5>`, `R_N<0:5>`,
  `T_P<0:5>`, `T_N<0:5>`, `S_RX<3:0>`, `EN_RX`, `EN_TERM`,
  `S_DRV<3:0>`, `EN_VREF_EXT`, `EN_DRV`, `VREF_ADJ_B`,
  `EN_VREF_400mV`, `EN_REF_DRV_B`, `PAD_VREF_EXT`, `DVDD`, `DVSS`.

TXRX4TDC stays a black box. TOP digital only provides shared CSR GPIO controls
and, later, wrapper-level tap/monitor routing. It does not modify or synthesize
MPTDC internals.

## Shared GPIO Controls

`SPADMIC_CSR_SLVS_GPIO_CTRL = 16'h7010` drives the common SLVS/RX controls for
v1. The same stored values may be routed to DDRs2 and TXRX4TDC where the macros
expose matching control terms.

`PAD_VREF_EXT` is a real external analog pad. Digital CSR does not generate this
pad value; it only drives `EN_VREF_EXT` and related control bits.

## Integration Boundary

The current active digital matrix-top core remains `spadmic_top_matrix_v1`. It
is not the final pad-ring wrapper. The final wrapper is responsible for:

- instantiating DDRs2 and TXRX4TDC as macros;
- routing `spadmic_ddrs2_adapter` outputs to DDRs2 `DATA_L/H<18:0>` and
  `CLK_160M`;
- routing `slvs_*` and `rx_*` CSR outputs to the matching macro control pins;
- routing `PAD_VREF_EXT`, supplies, and external differential outputs through
  the analog/custom pad-ring layout.
