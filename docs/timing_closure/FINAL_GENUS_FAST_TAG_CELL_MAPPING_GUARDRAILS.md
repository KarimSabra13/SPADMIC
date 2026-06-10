# Final Genus Fast Tag Cell Mapping Guardrails

Scope: final typical Genus reports only. These guardrails do not change RTL and
do not apply timing exceptions.

## Why This Exists

The cellbias run fixed DRV but regressed setup from the guarded `-3.5 ps` WNS
baseline to about `-84.7 ps`. The key signal was bad fast-tag source mapping:
top `FAST_TAG_TO_PD_TS` rows showed `DFRRQHDX0` or unknown source cells instead
of the previously near-clean `DFRRQHDX2` source mapping.

Do not globally ban `DFRRQHDX2`. The guarded baseline used it and was nearly
closed. The unsafe pattern is broad fast-tag flop bias that pushes Genus into
weaker or unknown source mapping.

## Generated Report

The wrapper writes:

`reports/fast_tag_cell_mapping.csv`

Columns:

- `instance`
- `tap_index`
- `bit_index`
- `mapped_cell`
- `drive_strength`
- `role`
- `appears_in_top_timing_paths`
- `top_timing_path_count`

Roles:

- `fast_tag_source`
- `nfast_hit_endpoint`
- `local_tag_feedback`

The wrapper also writes:

- `fast_tag_cell_mapping_guardrail.rpt`
- `fast_tag_cell_mapping.env`

## Summary Fields

`SUMMARY.md` includes:

- `FAST_TAG_FLOP_BIAS_MODE`
- `FAST_TAG_MAPPING_PARSE_STATUS`
- `FAST_TAG_MAPPING_STATUS`
- `FAST_TAG_SOURCE_DFRRQHDX0_COUNT`
- `FAST_TAG_SOURCE_DFRRQHDX1_COUNT`
- `FAST_TAG_SOURCE_DFRRQHDX2_COUNT`
- `FAST_TAG_SOURCE_DFRRQHDX4_COUNT`
- `FAST_TAG_SOURCE_UNKNOWN_COUNT`
- `FAST_TAG_MAPPED_SOURCE_COUNT`
- `FAST_TAG_MAPPED_ENDPOINT_COUNT`
- `FAST_TAG_TOP_PATH_COUNT`

The `FAST_TAG_SOURCE_*` counters refer to top negative
`FAST_TAG_TO_PD_TS` timing startpoints. The mapped-source counters enumerate
the exported netlist.

Source-cell resolution is intentionally two-step:

1. match the timing startpoint instance directly against exported netlist
   instances;
2. if flattened/escaped naming prevents a direct match, match by inferred
   fast-tag tap and tag bit.

After this fallback, a remaining `UNKNOWN` source count should be treated as a
real review item rather than a simple bracket/escape formatting miss.

## Guardrail

Mark the run `REVIEW_REQUIRED` if either appears on top negative
`FAST_TAG_TO_PD_TS` startpoints:

- `DFRRQHDX0`
- `UNKNOWN`

`DFRRQHDX2` is allowed. It is not globally harmful; it was the near-clean
guarded baseline mapping.

## Unsafe Mode Marker

If broad fast-tag flop bias is enabled, the summary must print:

`FAST_TAG_FLOP_BIAS_MODE=EXPERIMENTAL_UNSAFE`

That mode is opt-in only and must not be used for the control-only repair.
