# O8 Preserve Relaxation Plan

Purpose: prepare a controlled O8B mode only if O8A high-effort typical closure
does not improve enough.

## Why This Is Considered

O7 remaining paths are mostly `FAST_TAG_TO_PD_TS`, starting in
`mptdc_fast_epoch_tag` and ending in `mptdc_pd_cell` timestamp flops.  The
current fast-tag generator instances in `mptdc_core` are marked:

```systemverilog
(* keep_hierarchy = "yes", preserve *)
```

That can restrict Genus remapping/sizing inside or near the tag generators,
including LFSR XOR mapping, launch flop implementation, and buffering toward
the eight PD cells in a column.

## O8B Scope

O8B keeps:

- `keep_hierarchy = "yes"` on `mptdc_fast_epoch_tag` instances
- `mptdc_pd_cell` hierarchy
- packet format
- `raw_lfsr_tag` encoding
- nominal O7 period and tap model
- O7 typical-only `tc_view`

O8B relaxes only:

- the `preserve` attribute on `mptdc_fast_epoch_tag` instances

This is define-gated by:

```text
+define+MPTDC_RELAX_FAST_TAG_PRESERVE
```

The default O8A run does not set this define.

## Server Mode

Use only after O8A is reviewed and not enough:

```bash
O8_MODE=relax_fast_tag_preserve \
bash MPTDC/syn/scripts/server_run_genus_o8_typical_closure.sh 20260604_o8b_typical_relax_fast_tag_preserve
```

## Acceptance Checks

O8B is acceptable only if:

- WNS improves materially versus O8A
- old global fast-counter paths do not reappear
- `RO_tune4` instance count remains `2`
- old oscillator stubs remain `0`
- `RO_tune4/S[0:7]` clock attachment remains `16`
- PD hierarchy remains reviewable
- packet format remains unchanged

O8B does not by itself approve a final architecture.  It is a targeted Genus
optimization experiment.
