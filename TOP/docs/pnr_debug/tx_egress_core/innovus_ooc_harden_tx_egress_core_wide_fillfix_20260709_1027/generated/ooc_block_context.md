# TX_EGRESS_CORE OOC Hardening Context

This context was generated from the read-only SPADMIC2 layout audit. The block is hardened as a local abstract and includes a preliminary top-coordinate placement bbox for review.

- Layout audit dir: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/docs/layout_audits/SPADMIC2_20260709_072331`
- Block: `tx_egress_core`
- Top module: `spadmic_tx_egress_core`
- Contents: `spadmic_event_bundle_tx`, `spadmic_output_fifo_topcfg`, `spadmic_ddr16_tx_pairer`, `spadmic_ddrs2_adapter`
- DDRs2 macro: `M1` bbox=(21.980, 3261.886)-(3620.495, 3393.959) um
- DDRs2 DATA/CLK span: x=(85.540, 3475.095) um, span=3389.555 um
- Horizontal margin around DATA/CLK span: left `40.000 um`, right `20.424 um`
- Preliminary top bbox: (45.540, 3065.886)-(3495.519, 3231.886) um
- Local core target: `3433.979 um x 150.000 um`, target util `0.65`, max place density `0.72`
- Clearance estimate to MPTDC top bbox: `24.776 um`; matrix-array top clearance `391.262 um`; TXRX4TDC2 east clearance `10.000 um`
- Ordinary signal routing: `MET1`-`MET3`
- Power access: one north `VDD` bar and one north `VSS` bar on `METTP`
- Local special PG route is disabled by default; top-level assembly must connect the exported `METTP` VDD/VSS access pins.
- Pin intent: source/event inputs south, controls/status west, DDRs2 digital egress north aligned to DDRs2 DATA/CLK pins
- DDR/SLVS audit pins read: `90` total, `38` DATA_L/DATA_H pins, `42` top-side pins
- Visible DDRs2 CLK_160M source pins: `2`; the single cluster clock pin is assigned to the right/east CLK_160M coordinate
- Matrix audit pins read: `1977`; source-side pins remain top-level cluster pins until final top placement

## Instance Classes

- `MATRIX`: 6
- `MPTDC`: 3
- `PAD_RING`: 1
- `TX_RX_DDR_SLVS`: 1

## DDR/SLVS Anchors

- `I4` `RX_SLVS_rectangle` bbox=(2703.715, 458.360)-(2798.065, 501.225) um

## Pin Plan

- `WEST`: 61 pins
- `SOUTH`: 80 pins
- `NORTH`: 39 pins

## North Pin Alignment

- `ddrs2_data_h_o[18]` local_x=40.000 um from `M1/DATA_H<18>` top_x=85.540 um
- `ddrs2_data_l_o[18]` local_x=45.555 um from `M1/DATA_L<18>` top_x=91.095 um
- `ddrs2_data_h_o[17]` local_x=228.000 um from `M1/DATA_H<17>` top_x=273.540 um
- `ddrs2_data_l_o[17]` local_x=233.555 um from `M1/DATA_L<17>` top_x=279.095 um
- `ddrs2_data_h_o[16]` local_x=416.000 um from `M1/DATA_H<16>` top_x=461.540 um
- `ddrs2_data_l_o[16]` local_x=421.555 um from `M1/DATA_L<16>` top_x=467.095 um
- `ddrs2_data_h_o[15]` local_x=604.000 um from `M1/DATA_H<15>` top_x=649.540 um
- `ddrs2_data_l_o[15]` local_x=609.555 um from `M1/DATA_L<15>` top_x=655.095 um
- `ddrs2_data_h_o[14]` local_x=792.000 um from `M1/DATA_H<14>` top_x=837.540 um
- `ddrs2_data_l_o[14]` local_x=797.555 um from `M1/DATA_L<14>` top_x=843.095 um
- `ddrs2_data_h_o[13]` local_x=980.000 um from `M1/DATA_H<13>` top_x=1025.540 um
- `ddrs2_data_l_o[13]` local_x=985.555 um from `M1/DATA_L<13>` top_x=1031.095 um
- `ddrs2_data_h_o[12]` local_x=1168.000 um from `M1/DATA_H<12>` top_x=1213.540 um
- `ddrs2_data_l_o[12]` local_x=1173.555 um from `M1/DATA_L<12>` top_x=1219.095 um
- `ddrs2_data_h_o[11]` local_x=1356.000 um from `M1/DATA_H<11>` top_x=1401.540 um
- `ddrs2_data_l_o[11]` local_x=1361.555 um from `M1/DATA_L<11>` top_x=1407.095 um
- `ddrs2_data_h_o[10]` local_x=1544.000 um from `M1/DATA_H<10>` top_x=1589.540 um
- `ddrs2_data_l_o[10]` local_x=1549.555 um from `M1/DATA_L<10>` top_x=1595.095 um
- `ddrs2_data_h_o[9]` local_x=1732.000 um from `M1/DATA_H<9>` top_x=1777.540 um
- `ddrs2_data_l_o[9]` local_x=1737.555 um from `M1/DATA_L<9>` top_x=1783.095 um
- `ddrs2_data_h_o[8]` local_x=1920.000 um from `M1/DATA_H<8>` top_x=1965.540 um
- `ddrs2_data_l_o[8]` local_x=1925.555 um from `M1/DATA_L<8>` top_x=1971.095 um
- `ddrs2_data_h_o[7]` local_x=2108.000 um from `M1/DATA_H<7>` top_x=2153.540 um
- `ddrs2_data_l_o[7]` local_x=2113.555 um from `M1/DATA_L<7>` top_x=2159.095 um
- `ddrs2_data_h_o[6]` local_x=2296.000 um from `M1/DATA_H<6>` top_x=2341.540 um
- `ddrs2_data_l_o[6]` local_x=2301.555 um from `M1/DATA_L<6>` top_x=2347.095 um
- `ddrs2_data_h_o[5]` local_x=2484.000 um from `M1/DATA_H<5>` top_x=2529.540 um
- `ddrs2_data_l_o[5]` local_x=2489.555 um from `M1/DATA_L<5>` top_x=2535.095 um
- `ddrs2_data_h_o[4]` local_x=2672.000 um from `M1/DATA_H<4>` top_x=2717.540 um
- `ddrs2_data_l_o[4]` local_x=2677.555 um from `M1/DATA_L<4>` top_x=2723.095 um
- `ddrs2_data_h_o[3]` local_x=2860.000 um from `M1/DATA_H<3>` top_x=2905.540 um
- `ddrs2_data_l_o[3]` local_x=2865.555 um from `M1/DATA_L<3>` top_x=2911.095 um
- `ddrs2_data_h_o[2]` local_x=3048.000 um from `M1/DATA_H<2>` top_x=3093.540 um
- `ddrs2_data_l_o[2]` local_x=3053.555 um from `M1/DATA_L<2>` top_x=3099.095 um
- `ddrs2_data_h_o[1]` local_x=3236.000 um from `M1/DATA_H<1>` top_x=3281.540 um
- `ddrs2_data_l_o[1]` local_x=3241.555 um from `M1/DATA_L<1>` top_x=3287.095 um
- `ddrs2_data_h_o[0]` local_x=3424.000 um from `M1/DATA_H<0>` top_x=3469.540 um
- `ddrs2_clk_160m_o` local_x=3426.810 um from `M1/CLK_160M` top_x=3472.350 um
- `ddrs2_data_l_o[0]` local_x=3429.555 um from `M1/DATA_L<0>` top_x=3475.095 um
