# O5 Current PD Timing Root Cause

Branch: `SPADMIC_localtag`

Current local HEAD before O5 edits: `53ddfffeac333ae1e293bed4327169960b660c3a`

Latest committed Genus evidence:

- Master summary: `results/genus_osc_pd/20260602_o4_muxless_tags_r600_SUMMARY.md`
- Nominal fast run: `results/genus_osc_pd/20260602_o4_muxless_tags_r600_o4_nominal_fast`
- R600 fast run: `results/genus_osc_pd/20260602_o4_muxless_tags_r600_o4_r600_fast`
- R600 closure run: `results/genus_osc_pd/20260602_o4_muxless_tags_r600_o4_r600_closure`

## Netlist And Architecture Status

O4 structurally did what it was supposed to do:

- `RO_tune4` binding is still valid: two real `RO_tune4` instances are present.
- Old oscillator stubs are absent.
- Old global fast counter residue is absent.
- Old slow binary/Gray counter residue is absent.
- `report_clocks` still attaches clocks to `RO_tune4/S[0:7]`.
- Local fast tags are present: one `mptdc_fast_epoch_tag` per fast column.
- Slow Johnson epoch is present.
- The real timing classifier reports zero `UNKNOWN_REVIEW_REQUIRED` paths.

Important reporting caveat:

The O4 helper file `o4_class_wns_summary.txt` is stale/buggy because it looked for CSV field `class`, while `timing_path_classification.csv` uses `classification`. The reliable evidence is `timing_path_classification_summary.md`, `PARSED_SUMMARY.md`, and the raw timing reports.

## Current R600 Closure Timing

R600 closure parsed timing groups:

| Group | WNS ps | TNS ps | Paths |
|---|---:|---:|---:|
| `clk_osc_fast*` | about -1316 | about -768k over all fast taps | 696 reported in QoR |
| `clk_sys` | -764.6 | -44257.1 | 179 |
| `clk_osc_slow` | -114.9 | -3551.3 | 64 |

Timing classifier for detailed paths:

| Class | Paths | WNS ps | TNS ps |
|---|---:|---:|---:|
| `OSC_FAST_REAL` | 392 | -1316 | -448387 |
| `CLK_SYS_REAL` | 100 | -765 | -43681 |
| `OSC_SLOW_REAL` | 52 | -115 | -2920 |
| `UNKNOWN_REVIEW_REQUIRED` | 0 | 0 | 0 |

Root-cause families from the classification CSV:

| Family | Paths | WNS ps | TNS ps |
|---|---:|---:|---:|
| PD `hit_latched` -> `nfast_hit_latched` freeze | 312 | -1316 | -410592 |
| local fast LFSR self path | 55 | -886 | -17615 |
| slow Johnson self path | 52 | -115 | -2920 |
| clk_sys drain/readout | 55 | -765 | -39810 |
| clk_sys watchdog | 1 | -18 | -18 |

## Dominant PD Path

Representative path from `timing_violations.rpt`:

- Group: `clk_osc_fast_tap6`
- Startpoint: `u_core_gen_pd_row[7].gen_pd_col[6].u_pd/hit_latched_reg/C`
- Endpoint: `u_core_gen_pd_row[7].gen_pd_col[6].u_pd/nfast_hit_latched_reg[3]/D`
- Required time: 1464 ps
- Data path: 2193 ps
- Slack: -1316 ps

Data path detail:

- `hit_latched_reg` C->Q: 1062 ps
- gate path through `NA2I1HDX4`: 517 ps
- gate path through `NA2HDX1`: 338 ps
- gate path through `ON21HDX1`: 276 ps
- endpoint is a resettable timestamp flop, mapped as `DFRRQHDX4`
- setup is 640 ps, uncertainty is 50 ps

Conclusion: the dominant path is truly the PD-local timestamp freeze logic. It is not the stale O1/O2 global fast-counter path.

## RTL Root Cause

`mptdc_pd_cell.sv` currently implements the timestamp as an enable-style shadow register:

```systemverilog
if (!hit_latched)
  nfast_hit_latched <= nfast_tag_i;
```

That preserves the intended semantics: before a hit the timestamp tracks the local raw tag, and after the hit it freezes. Synthesis implements this as a data mux or equivalent data-enable cone controlled by `hit_latched`. The resulting real path is:

`hit_latched_reg/Q -> freeze mux/control logic -> nfast_hit_latched_reg[*]/D`

The timestamp flops were also reset/cleared together with the hit detector. That is over-protective because `nfast_hit_latched` is only meaningful when `hit_latched=1`; no-hit cells are ignored by the bridge/drain path.

## Safety Analysis For No-Reset Timestamp Flops

`nfast_hit_latched` can be unreset safely if these invariants hold:

- `hit_latched` is reset/cleared to zero.
- The snapshot/drain path uses a cell timestamp only when its corresponding hit bit is one.
- Before the next real hit, the shadow register is overwritten by the local tag.
- No-hit cells may hold stale or X-like timestamp data, but that data is ignored.
- Packet layout is unchanged; raw-tag semantics are unchanged for hit records.

Corner-case review:

- Hit on first valid fast edge after clear: timestamp captures `nfast_tag_i` on that edge while `hit_latched` is still zero.
- Clear immediately followed by new conversion: `hit_latched=0`; timestamp follows tag again before the next hit.
- No-hit cells: timestamp value is irrelevant because `hit_level=0`.
- Snapshot after clear: protocol remains capture-before-clear; after clear the source image is no longer used.
- Simulation X risk: unit tests must avoid checking `nfast_hit` when `hit_level=0`; a translate-off initialization is acceptable for 2-state smoke stability.

## Clock-Gating Interpretation

The timestamp freeze is logically a clock-enable function: timestamp flops should update while `hit_latched=0` and hold after `hit_latched=1`.

Potential standard-cell implementation:

- D input: always `nfast_tag_i`.
- Clock enable: `!hit_latched`.
- Clock gate drives the seven timestamp flops in one PD cell.

This preserves the raw measurement meaning but moves the critical control from the timestamp D path to a clock-gating enable check. That is the only O5 micro-architecture path with a plausible structural benefit while preserving same-edge PD semantics.

## Current Protection Problem

The PD cell and instances were over-protected:

- RTL module attribute included `dont_touch` and `preserve`.
- RTL instance attribute included `dont_touch` and `preserve`.
- `mptdc_preserve_physical_hierarchy` applied `dont_touch` to `*u_pd*` and `*mptdc_pd_cell*`.

This can block remapping, no-reset flop selection, and clock-gating inference. O5 should keep hierarchy visible but relax internal `dont_touch`.

## O5 Patch Direction

O5 should test two standard-cell implementation changes:

1. `O5_NORESET_TS`
   - remove reset/clear from timestamp flops only
   - keep q1/q2/hit_latched reset/clear
   - relax PD `dont_touch`

2. `O5_CLOCK_GATED_TS`
   - use the same RTL enable semantics
   - enable Genus clock-gating insertion as a controlled experiment
   - allow ICG `dont_use` override only in this experiment
   - report whether ICG cells actually appear in the netlist

Do not false-path the PD timestamp path. Do not change packet layout. Do not change raw-tag software decode.
