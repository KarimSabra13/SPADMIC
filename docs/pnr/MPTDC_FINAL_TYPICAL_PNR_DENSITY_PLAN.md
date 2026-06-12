# MPTDC Final Typical P&R Density Plan

Status: `READY_FOR_INNOVUS_TYPICAL_CLOSURE`, `NOT_MMMC_SIGNOFF`,
`NOT_FINAL_SILICON_SIGNOFF`

## Density Campaign

Default:

```text
PNR_DENSITY_60_DEFAULT
MPTDC_PNR_CORE_UTIL=0.60
```

Allowed first-pass range:

```text
58% to 62%
```

Do not exceed:

```text
65%
```

## Rationale

`55%` utilization can spread the design enough to lengthen local RC routes.
`60%` is the preferred first closure point because it shortens local routes
while preserving routing capacity. Above `65%`, congestion, transition
degradation, and antenna risk become first-order risks for this flow.

Density alone is not the timing fix. The key physical requirement is local,
regular placement:

- fast tag generators near their corresponding PD columns;
- compact regular 8x8 PD matrix;
- slow RO north and fast RO south;
- slow `BUHDX4` isolation and `BUHDX12` final drivers between slow RO and PD;
- fast `BUHDX12` final drivers and `BUHDX4` isolation between PD and fast RO;
- clk_sys context bank, drain/readout, FIFO, CSR/control, and acq interface east of the phase island;
- no wide backend buses over the PD island;
- no CTS on raw RO or buffered phase clocks.

## Modes

| Mode | Core Utilization | Use |
|---|---:|---|
| `PNR_DENSITY_60_DEFAULT` | `0.60` | First closure run |
| `PNR_DENSITY_58_FALLBACK` | `0.58` | If 60% shows congestion |
| `PNR_DENSITY_62_COMPACT` | `0.62` | Only if 60% is congestion-clean and routes remain long |

Do not run 65% or higher until the 60% and 62% route/congestion evidence has
been reviewed.

## Required Report Focus

- `reports/congestion.rpt`
- `reports/density.rpt`
- `reports/fast_tag_to_pd_route_lengths.csv`
- `reports/fast_tag_to_pd_timing_post_route.rpt`
- `reports/phase_buffer_balance_summary.md`
- `reports/route_drc.rpt`
- `reports/antenna_repair_status.rpt`
