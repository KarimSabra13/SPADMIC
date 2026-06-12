# SPADMIC_test Repair5 Exact Fast-Tag Close

Repair5 is `SPADMIC_TEST_STRIDE2_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE`.

The goal is to close the remaining small negative `FAST_TAG_TO_PD_TS` setup
slack from the Repair4 baseline without changing the O13 clock model, PD
Vernier exception, packet format, `raw_lfsr_tag`, STRIDE2 behavior, or phase
buffer topology.

## Required Starting Point

- Exact fast-tag source discovery is correct: 24 / 24.
- Exact fast-tag endpoint discovery is correct: 192 / 192.
- Exact fast-tag source-to-endpoint path pairs are correct: 192 / 192.
- DRV is clean before applying Repair5 timing pressure.
- `FAST_TAG_TO_PD_TS` remains real same-fast-domain timing.

## Allowed Repair5 Knobs

- Exact source-cell target through `MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL`.
- Exact source Q-net fanout and transition pressure on bits 0, 5, and 6 only.
- Exact C-pin to endpoint-D path grouping and optional `set_max_delay`.
- Broad control-net DRV repair that was already proven clean in Repair4.

## Forbidden Knobs

- Broad strong fast-tag flop bias.
- Design-wide DRV pressure.
- Broad `dont_use` or global remapping of fast-tag flops.
- Endpoint `nfast_hit_latched` strengthening by default.
- Packet, `raw_lfsr_tag`, R750_delta5, O13 clock, PD Vernier, or phase-buffer changes.

## Required Evidence

- `fast_tag_exact_repair_status.rpt`
- `fast_tag_exact_source_discovery.csv`
- `fast_tag_exact_endpoint_discovery.csv`
- `fast_tag_exact_path_pairs.csv`
- `fast_tag_exact_source_cell_repair.csv`
- `fast_tag_cell_mapping_guardrail.rpt`
- `summary_parser_check.rpt`
- `sdc_command_failures.md`

Repair5 is clean only when timing, DRV, exact source mapping, SDC diagnostics,
summary/raw agreement, O13 clocks, and PD Vernier checks all pass.
