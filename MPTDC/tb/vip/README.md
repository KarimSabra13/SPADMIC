# MPTDC VIP Status

Author: Karim Sabra

The standalone class-based MPTDC VIP harness was retired by the product-only
`mptdc_axis_core` cleanup. It depended on the old standalone CSR/readout
top-level boundary and no longer represents the active SPADMIC product path.

Maintained product checks now live in:

- `MPTDC/tb/int/tb_axis_core_product_smoke.sv`
- `MPTDC/ci/run_smoke.sh`
- `MPTDC/ci/run_full_regression.sh`
- `TOP/tb/tb_spadmic_arb_modes.sv`
- `TOP/tb/tb_spadmic_arb_stress.sv`

The remaining files under `MPTDC/tb/vip/` are retained as archival/reuse
collateral only. They are not part of the maintained product smoke or
regression filelists.
