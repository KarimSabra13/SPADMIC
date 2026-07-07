# O13 Phase Net XLIBD Load Budget Summary

REPORT_STATUS=REVIEW_REQUIRED

- Source run: `unknown`
- XLIBD library: `D_CELLS_HD_LPMOS_typ_1.80V_25C`
- Strict analog RO D-load budget: `58.72 fF`.
- CN/clock-like analog estimate: `75.59 fF`.
- DFRRQHDX1 D/C/RN caps: `3.19` / `3.62` / `7.32` fF.
- DFRRQHDX2 D/C/RN caps: `3.20` / `3.45` / `6.51` fF.
- DFRQHDX2 D/C caps: `2.70` / `3.63` fF.
- DFRHDX1 D/C caps: `2.71` / `3.63` fF.
- BUJIHDX4 input cap: `UNKNOWN fF`.
- BUJIHDX12 input cap: `UNKNOWN fF`.
- Max measured raw RO source load: `29.00 fF` at `slow S[7] u_core_u_osc_slow_u_ro_tune4/S[7]`.
- Max raw equivalent DFRRQHDX2 D/C/RN inputs: `9.1` / `8.4` / `4.5`.
- Max measured final driver output load: `779.00 fF` at `fast tap[0] u_core_u_phase_buf_fast/gen_phase_buf[0].u_drv/Q`.
- Max final-output equivalent DFRRQHDX2 D/C/RN inputs: `243.4` / `225.8` / `119.7`.

Required companion CSVs: `ro_phase_raw_pin_loads_xlibd.csv`, `phase_buffer_output_loads_xlibd.csv`, `fast_tag_loads_xlibd.csv`, and `phase_net_loads_xlibd_enhanced.csv`.

This summary does not waive analog RO budgets or Liberty design-rule checks.
