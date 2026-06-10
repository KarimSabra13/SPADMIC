# O2 Raw-Tag Genus Review

Date: 2026-06-01

Branch: `SPADMIC_localtag`

Current HEAD reviewed: `1e3fb188303e2755de403ac5c3571b27bc2feca8`

Server run reviewed:

```text
results/genus_osc_pd/20260601_o2_raw_tag_genus/
```

## Run Status

- Genus exit code: `0`
- Snapshot exit code: `0`
- Server RTL commit used by Genus: `41983ce18c255fb21e331f88dd6f3b7ca0979fd1`
- `RO_tune4` instance count: `2`
- `mptdc_osc_stub` residue count: `0`
- `report_clocks` matches on `RO_tune4/S[0:7]`: `16`
- RTL tag-decode residue count: `0`

The O2 raw local fast-tag netlist is structurally present: the post-synthesis
netlist contains the local fast tag generators and no `u_fast_cnt` instance.

## Report Hygiene Finding

The top-level `fast_count_capture_summary.md` and the `timing_path_classification.csv`
entries sourced from `timing_fast_count_to_nfast_hit.rpt` are stale for this
O2 run.  They still name `u_core_u_fast_cnt_bin_q_reg[*]`, but that instance is
absent from `mptdc_top_asic.postsyn.v` and absent from `timing_violations.rpt`.

Root cause: the server wrapper allowed a repeated `RUN_ID` to reuse an existing
result directory, so old focused reports could survive when the current flow did
not regenerate them.  The wrapper has been patched to remove the result directory
at the start of each run and to stop counting any `bin_q_reg` as fast-counter
residue.

Use these files as current evidence:

- `SUMMARY.md` for binding state
- `mptdc_top_asic.postsyn.v` for actual instance residue
- `timing_violations.rpt` for current top timing paths
- `PARSED_SUMMARY.md` for timing group totals

Treat these as stale for O2:

- `timing_fast_count_to_nfast_hit.rpt`
- `fast_count_capture_paths.csv`
- `fast_count_capture_summary.md`
- `timing_path_classification.csv` rows whose `report` is `timing_fast_count_to_nfast_hit.rpt`

## Current Timing Evidence

From `PARSED_SUMMARY.md`:

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_slow` | -2813.8 | -50635.5 | 22 |
| `clk_osc_fast` | -2582.3 | -208414.3 | 102 |
| `clk_osc_fast_tap1` | -2334.8 | -184090.7 | 87 |
| `clk_osc_fast_tap2` | -2334.8 | -182775.3 | 87 |
| `clk_osc_fast_tap3` | -2334.8 | -185127.3 | 87 |
| `clk_osc_fast_tap4` | -2334.8 | -185193.5 | 87 |
| `clk_osc_fast_tap5` | -2334.8 | -184570.2 | 87 |
| `clk_osc_fast_tap6` | -2293.2 | -179180.6 | 87 |
| `clk_osc_fast_tap7` | -2334.8 | -184570.4 | 87 |
| `clk_sys` | -642.2 | -35632.7 | 64 |

Current `timing_violations.rpt` top paths:

1. `u_slow_cnt_bin_q_reg[1]` to `u_slow_cnt_gray_src_cont_q_reg[*]`, worst
   `-2814 ps`, group `clk_osc_slow`.
2. `start_wdt_cnt_reg[*]` to `start_wdt_cnt_reg[*]`, worst `-2700 ps`, group
   `clk_osc_slow`.
3. `u_slow_cnt_gray_snap_ff2_async_reg[*]` to
   `u_slow_cnt_dst_count_latched_reg[*]`, worst `-2582 ps`, group
   `clk_osc_fast`.
4. PD-cell internal `q1/q2` to `nfast_hit_latched_reg[*]`, worst `-2487 ps`,
   group `clk_osc_fast` / fast tap groups.

## Interpretation

O2 achieved its first objective: the impossible global
`fast_phase[0]` binary counter to 64 PD cells is not in the actual O2 netlist.

It did not close oscillator-domain timing because there is still ordinary
standard-cell sequential logic in near-1 GHz oscillator domains:

- slow coarse counter binary increment plus Gray encode/decode,
- slow-domain START watchdog binary increment,
- PD-cell hit-detection muxes feeding `nfast_hit_latched`,
- local fast tag flops and PD capture flops in the fast tap domains.

The current worst real path is now the slow coarse counter fabric, not the old
fast global counter.  This supports a follow-up slow-tag experiment, but a
plain slow LFSR copied from the fast path is not safe by itself because the slow
coarse count is STOP-captured asynchronously.

## Slow LFSR/Tag Conclusion

Confirmed direction:

```text
O3 should remove the binary slow counter and fast-domain Gray decode from the
oscillator timing graph.
```

Rejected naive direction:

```text
Do not simply replace the slow Gray counter with a raw LFSR captured by
posedge STOP.  A normal LFSR changes multiple bits per state, so an async STOP
edge near a slow clock transition can capture an incoherent tag.
```

Preferred O3 direction:

```text
Use a slow raw epoch tag clocked by slow_phase[0], but freeze the tag
synchronously in the slow clock domain when STOP is latched.  Then export the
frozen raw slow tag in the existing nslow field and decode it in software,
analogous to O2 raw nfast.
```

This changes packet semantics but not packet width/layout:

```text
pre-O3: HIT/META.nslow = binary/decoded slow coarse count
O3:     HIT/META.nslow = raw frozen slow epoch tag
```

Software must decode with metadata:

```text
nslow_encoding = raw_lfsr_tag
slow_tag_decode_mode = software
slow_tag_width = 7
```

The STOP freeze has a bounded one-slow-cycle ambiguity when STOP lands near a
slow edge; this must be modeled explicitly with `phase0_snap`,
`stop_slow_phase_disc`, and `slow_boundary_inc`, then verified by Xcelium and
characterization.

## Next Patch Recommendation

Rank 1: `O3_RAW_SLOW_TAG_SW_DECODE`

- Replace `mptdc_gray_cnt_sync` slow coarse counter with a slow raw tag plus
  STOP-freeze protocol.
- Replace `start_wdt_cnt` binary increment with a shallow timeout mechanism
  that does not synthesize an 8-bit binary counter in `clk_osc_slow`.
- Extend Python decode metadata to support both:
  - `nfast_encoding = raw_lfsr_tag`
  - `nslow_encoding = raw_lfsr_tag`
- Keep packet layout unchanged; document semantic change.

Rank 2: `O4_PD_CELL_FAST_CAPTURE_SIMPLIFY`

- Simplify PD-cell timestamp capture so `q1/q2` no longer drive seven
  `nfast_hit_latched` D muxes directly.
- Candidate: per-cell self-freezing raw tag, with a documented fixed one-cycle
  offset, or a custom PD macro handoff if standard cells remain infeasible.

Rank 3: targeted implementation levers

- Cell sizing, placement, and R800 only after O3/O4 reduce the real path classes
  to physically meaningful local paths.

## Blocked Actions

- Innovus remains blocked: current Genus is still dominated by oscillator-domain
  conceptual/RTL paths, not just placement.
- R800 remains blocked: derating does not solve the current slow binary/PD-cell
  architecture by itself and still needs analog tune data.
- H4b remains paused: `clk_sys` is not the dominant blocker.
