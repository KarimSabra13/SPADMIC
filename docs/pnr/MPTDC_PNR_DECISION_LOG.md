# MPTDC PNR Decision Log

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

| Decision | Current Value | Rationale | Review Trigger |
|---|---|---|---|
| Genus source | Repair8 JIHD exact run `spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302` | Current Genus typical closure handoff | Any newer Genus source |
| Timing view | single typical view | User explicitly requested typical-only planning, not hidden MMMC | Any PVT expansion |
| Core utilization | `60%` default, `58-62%` first-pass range, `65%` first-run ceiling | Shortens local routes versus 55% while preserving routing capacity | Congestion or long-route evidence |
| Floorplan order | slow RO north, slow buffers, PD island, fast buffers, fast RO south, backend east | Keeps phase fabric physically interpretable | Pin-order or macro-abutment evidence |
| Phase topology | `RO -> BUHDX4 -> BUHDX12` | O13 closure contract and analog load isolation | Load or skew evidence |
| PD placement | optional enforced 8x8 grid | Matches RTL `NE=8`, supports row/column audit | Legalization failure |
| Fast tags | place by column when enabled | Keeps fast tag sources close to PD columns | Congestion or hold evidence |
| FAST_TAG_TO_PD_TS | keep timed and physically local | Final Genus WNS is only about +0.1 ps | Any post-route negative slack |
| RO load policy | `58.72 fF` preferred, `75.59 fF` warning | Analog budget evidence; do not waive Liberty as a fix | Real extraction |
| Supplies | `VDD/VSS`; RO `VDD` and `vdd!` to `VDD`, `VSS` to ground | Matches current plan and known abstract naming | LEF/analog contradiction |
| CTS | `clk_sys` only | Raw RO and phase clocks are measurement fabric, not CTS trees | Clock audit mismatch |
| IO load | medium block-level load by default | Provisional macro-level policy, not pad signoff | Top-level pad model arrival |
| Narrow output | low priority legacy output | Main chip-visible TX is outside MPTDC block | Top integration requires it |
