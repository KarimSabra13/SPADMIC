# Final Genus XLIBD Cell Choice Notes

Source references:

- `docs/tech/xlibd_cell_values_spadmic_summary.md`
- `MPTDC/pnr/config/xlibd_spadmic_typical_cell_values.tcl`

These values are reference-only. Genus and Innovus still use the full Liberty
views for timing, optimization, and design-rule checks.

## Phase Buffer Topology

Decision: keep `RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric`.

Reasons:

- `BUHDX4` input cap is `10.56 fF`, safely below the strict analog RO D-load
  budget of `58.72 fF`.
- `BUHDX12` input cap is `32.24 fF`, also below the strict RO budget, but it is
  less conservative as a direct RO load than `BUHDX4`.
- `BUHDX12` is a much stronger final phase driver for the observed digital
  phase-load range:
  - at `0.6058 pF`: rise transition `0.3080 ns`, fall transition `0.2295 ns`;
  - at `1.2106 pF`: rise transition `0.5955 ns`, fall transition `0.4391 ns`.
- `BUHDX4` at about `0.8075 pF` has rise transition `1.1716 ns`, too weak as a
  final digital phase driver.

Therefore `BUHDX4` remains the RO isolation cell and `BUHDX12` remains the final
digital phase driver.

## Fast Tag Source Flop Candidate

The current worst paths launch from `DFRRQHDX2` fast-tag source flops. XLIBD
comparison:

| Cell | C cap fF | D cap fF | RN cap fF | Q max cap fF | Q max fanout |
|---|---:|---:|---:|---:|---:|
| `DFRRQHDX2` | 3.45 | 3.20 | 6.51 | 1587 | 667 |
| `DFRRQHDX4` | 3.60 | 3.19 | 6.37 | 3025 | 1272 |

`DFRRQHDX4` has nearly the same data/reset input loading and only slightly
higher clock cap, but about 1.9x the Q max-cap and fanout envelope. It is a
reasonable Genus repair candidate for the fast-tag source registers if the tool
can remap without changing RTL behavior.

Do not force scan flops:

- `SDFFQHDX2`: `dont_use true`
- `SDFFQHDX4`: `dont_use true`

## NFAST Capture Endpoint

The worst endpoints are `nfast_hit_latched_reg[5]/D`, currently mapped as
`DFRHDX2` in the detailed timing rows. The first repair should target source
drive and local nfast distribution before changing endpoint register mapping,
because the endpoint setup is about `264-265 ps` while the data path is about
`1059-1062 ps` and the source C-to-Q dominates.

## High-Fanout Control Net

The 124954 DRV root is `n_6984`, driver `g33116`, cell `INHDX8`, fanout `88`,
worst transition `511 ps` against `500 ps`.

`INHDX12` has:

- input cap `55.64 fF`;
- Q max cap `8679 fF`;
- Q max fanout `3651`.

It is too close to the strict analog RO input budget for direct RO use, but this
net is not a raw RO output. `INHDX12` or a local buffer tree is acceptable for
the high-fanout non-phase control-net repair experiment.

## Constraints

The repair package may:

- consider `DFRRQHDX4` only in a future exact-path fast-tag setup experiment,
  not as a broad default source-flop bias;
- prefer `INHDX12` over `INHDX8` on high-fanout non-phase control nets after
  the guarded run confirms the remaining root is `n_6984`;
- allow stronger local buffers/inverters on high-fanout PD control nets;
- set local max-fanout and max-transition targets on those nets/pins.

The repair package must not:

- use scan cells;
- relax fast oscillator clock periods;
- false-path `FAST_TAG_TO_PD_TS`;
- change `raw_lfsr_tag`;
- change packet format;
- change O13 `BUHDX4 -> BUHDX12` topology.
