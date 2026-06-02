# O4 Current SPADMIC Localtag Review

Date: 2026-06-02

Branch: `SPADMIC_localtag`

Latest Genus result used: `results/genus_osc_pd/20260601_o3_raw_epoch_cleanup_genus`

Current HEAD before O4 edits: `fb8210c55c01f95ec5fc795d4da39d8b543e9a5a`

## Architecture Status

| Item | Status | Evidence |
| --- | --- | --- |
| Old global fast counter path | removed | O3 netlist summary reports old fast-counter residue count `0`; RTL no longer instantiates `u_fast_cnt` into PD capture. |
| Local fast tags | present | `mptdc_core` instantiates eight `mptdc_fast_epoch_tag` instances, one per `fast_phase[nf]` column. |
| Slow Johnson epoch | present | `mptdc_core` instantiates `mptdc_slow_epoch_johnson`; STOP captures the raw Johnson state. |
| PD cell behavior | locked | PD still samples `slow_phase` on `fast_phase[nf]`, detects the existing falling-edge condition, shadows tag before hit, then freezes. |
| `nfast` raw-tag export | present | `mptdc_drain_ctrl` emits `snapshot_i.nfast_hit_packed[...]` directly into HIT `nfast`. |
| `nslow` Johnson decode | present | `mptdc_hit_capture_bridge` decodes STOP-captured Johnson state to existing 7-bit `nslow_snap`. |
| START watchdog | clk_sys countdown in O4 | O3 moved it from slow domain to `clk_sys`; O4 changes compare/increment to reload/decrement/zero-detect. |
| Drain timing | not changed in O4 | Existing `ST_D_EMIT` remains. Full `ST_D_BUILD` is deferred to avoid destabilizing the PD/R600 experiment. |

## O3 Genus Interpretation

O3 removed stale global binary/Gray families, but the remaining violations are still real:

- `OSC_FAST_REAL`: about `-2084 ps`, dominated by local PD timestamp freeze and local fast tag logic.
- `OSC_SLOW_REAL`: about `-1296 ps`, dominated by slow Johnson update logic.
- `CLK_SYS_REAL`: about `-853 ps`, dominated by drain/readout and START watchdog compare/count.
- `UNKNOWN_REVIEW_REQUIRED`: `0`.
- DRV max-transition count remains very high and must be handled after the architecture is timing-plausible.

The old `u_fast_cnt/bin_q_reg -> u_pd/nfast_hit_latched` path is stale and must not be optimized as a current blocker.

## O4 Scope

O4 keeps the local-tag architecture and the PD behavior. It removes unnecessary synchronous enable/hold muxes from tag generators, converts the START watchdog to a countdown, and prepares nominal plus R600 Genus feasibility runs.

No Innovus, R800/R600 signoff, broad exceptions, cell sizing, packet layout change, or PD redesign is part of this patch.
