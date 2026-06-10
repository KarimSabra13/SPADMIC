# O11 RO Output Load Budget From Analog

## Status

This is a report-repair and feasibility/debug note, not final signoff.  It preserves the analog load budget and explains how O11 should compare routed RO_tune4 source-pin loads against that budget.

## Analog Budget

The analog handoff gives two useful per-output load numbers for each RO_tune4 `S[n]` pin:

- Strict D-load budget: `58.72 fF`, or `0.05872 pF`.
- CN/clock-like estimate: `75.59 fF`, or `0.07559 pF`.

The current production shell, `MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib`, still uses `max_capacitance : 0.050` on bus `S`, and the shell declares `capacitive_load_unit (1, pf)`.  That means the shell limit is `50 fF`, close to the strict D-load budget.

## O10.2 Evidence

O10.2 reported max-cap violations in `results/innovus/20260604_o10_2_pnr_repair/reports/drv_max_cap.rpt`:

| Source pin | Actual load | Strict ratio | CN ratio | Label |
|---|---:|---:|---:|---|
| fast `S[4]` | `718 fF` | `12.23x` | `9.50x` | `CRITICAL` |
| fast `S[5]` | `696 fF` | `11.85x` | `9.21x` | `CRITICAL` |
| fast `S[6]` | `665 fF` | `11.32x` | `8.80x` | `CRITICAL` |
| fast `S[0]` | `653 fF` | `11.12x` | `8.64x` | `CRITICAL` |
| fast `S[7]` | `652 fF` | `11.10x` | `8.63x` | `CRITICAL` |
| fast `S[1]` | `643 fF` | `10.95x` | `8.51x` | `CRITICAL` |
| fast `S[3]` | `614 fF` | `10.46x` | `8.12x` | `CRITICAL` |
| fast `S[2]` | `569 fF` | `9.69x` | `7.53x` | `CRITICAL` |
| slow `S[0]` | `508 fF` | `8.65x` | `6.72x` | `CRITICAL` |

Those numbers are far above both analog estimates.  This is not primarily a Liberty-relaxation issue; it is a physical load and reporting-classification blocker until the loads are measured from the actual RO source pins and traced to sink classes.

## O11 Budget Labels

O11 uses these labels in the source-pin CSVs:

| Label | Condition |
|---|---:|
| `OK_STRICT` | `<= 58.72 fF` |
| `OK_CN` | `<= 75.59 fF` |
| `WARN_OVER_CN` | `<= 150 fF` |
| `FAIL_HIGH_LOAD` | `> 150 fF` and `<= 300 fF` |
| `CRITICAL` | `> 300 fF` |

Any `FAIL_HIGH_LOAD` or `CRITICAL` row needs physical load reduction, sink repartitioning, or an explicit analog/backend decision.  O11 does not waive those rows.

## Interpretation

The existing O10.2 `phase_net_loads.csv` and `fast_tag_loads.csv` are not usable evidence because every row is `NO_NET_MATCH`.  O11 replaces that path with exact source-pin resolution:

- `u_core/u_osc_slow/u_ro_tune4/S[0:7]`
- `u_core/u_osc_fast/u_ro_tune4/S[0:7]`
- `u_core_u_osc_slow_u_ro_tune4/S[0:7]`
- `u_core_u_osc_fast_u_ro_tune4/S[0:7]`

The net is derived only after a source pin has been found.
