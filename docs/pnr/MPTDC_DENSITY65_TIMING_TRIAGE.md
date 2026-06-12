# MPTDC Density65 Timing Triage

Status: `TIMING_REVIEW_REQUIRED`, `TRUE_SETUP_NOT_PROVEN_CLEAN`,
`RESET_RECOVERY_NOT_WAIVED`, `CTS_NOT_CLOSED`, `NOT_FINAL_SIGNOFF`

## Purpose

The density65 physical candidate is route-clean enough that the next decision
must be timing classification, not density exploration. The important question
is whether the observed `-0.903 ns` class is true register-to-register setup,
recovery/removal, or a mixed report artifact.

Do not report the block as core setup failing only because the aggregate
`CORE_INTERNAL` summary is negative. The top negative paths must be classified
by check type.

## Required Reports

The next rerun from `65acb8e5` or later should emit these reports:

```text
reports/timing_true_setup_core.rpt
reports/timing_true_setup_clk_sys.rpt
reports/timing_true_setup_ro_domain.rpt
reports/timing_recovery_removal.rpt
reports/timing_io_block_level.rpt
reports/timing_fast_tag_to_pd_post_route.rpt
reports/timing_by_class.md
```

Legacy names remain useful for comparison:

```text
reports/timing_post_route_core_internal.rpt
reports/timing_post_route_clk_sys_internal.rpt
reports/timing_post_route_ro_osc_domain.rpt
reports/timing_post_route_reset_recovery.rpt
reports/timing_post_route_io_output.rpt
reports/timing_post_route_summary_by_class.md
```

The explicit `timing_true_setup_*` reports are the decision reports for true
setup. The recovery/removal report is the decision report for reset protocol
work.

## Current Symptoms

From `mptdc_final_typical_pnr_density65_clean_20260612_171922`:

| Class | WNS | Interpretation before triage |
|---|---:|---|
| `CORE_INTERNAL` | about `-0.903 ns` | ambiguous until explicit setup paths are reviewed |
| `ASYNC_RESET_RECOVERY` | about `-0.903 ns` | recovery/removal likely aliases the headline core value |
| `CLK_SYS_INTERNAL` | about `-0.488 ns` | likely true clk_sys setup or clock-tree issue; CTS was skipped |
| `IO_OUTPUT` | about `-0.488 ns` | block-level provisional IO budget, not pad signoff |
| `RO_OSC_DOMAIN` | no violated paths reported | oscillator-domain setup does not currently dominate |

If `timing_true_setup_core.rpt` is clean while `timing_recovery_removal.rpt`
shows `-0.903 ns`, then the `-0.903 ns` value must not be called a core setup
failure. It becomes a reset/recovery signoff decision.

If `timing_true_setup_core.rpt` also reports about `-0.903 ns`, the report must
identify the exact logic cone and clock pair before any CTS or RTL change is
proposed.

## Path Classification Rules

For the top 50 negative paths, capture:

| Field | Required use |
|---|---|
| check type | classify as setup, hold, recovery, removal, pulse width, or unknown |
| launch clock | identify source clock or reset/clear assertion source |
| capture clock | identify receiving clock or recovery/removal clock |
| startpoint | preserve exact instance/pin name |
| endpoint | preserve exact instance/pin name |
| data path | record whether it is real data, reset, clear, IO, or generated clock fabric |
| clock path | record whether clock tree is ideal/skipped CTS/propagated |
| reset/clear signal | required for recovery/removal or async clear paths |
| class | one of the classes below |

Allowed final classes:

```text
REAL_CORE_SETUP
CLK_SYS_SETUP
RO_DOMAIN_SETUP
ASYNC_RESET_RECOVERY
IO_BLOCK_LEVEL
UNKNOWN
```

`UNKNOWN` is not acceptable for closure. It is acceptable only as an interim
triage label that blocks signoff.

## Specific Decisions

### Core Setup

Use `timing_true_setup_core.rpt`. A path belongs to `REAL_CORE_SETUP` only if
the check type is setup and both source and sink are internal sequential
elements. Recovery/removal endpoints, reset pins, clear pins, async set/clear
pins, and block outputs are not core setup.

### clk_sys Setup

Use `timing_true_setup_clk_sys.rpt`. If this remains around `-0.4 ns` to
`-0.5 ns`, the likely next lever is clk_sys-only CTS, not density and not
postroute AAE-SI optimization. A skipped CTS run means the clock tree is not a
closed implementation result.

### RO Domain

Use `timing_true_setup_ro_domain.rpt`. Any true RO-domain setup failure must be
reviewed against the O13 topology and raw RO load reports. Do not let a generic
clock-tree repair touch raw RO clocks or buffered phase clocks.

### Reset/Recovery

Use `timing_recovery_removal.rpt`. A recovery/removal failure can be waived only
by exact protocol proof or fixed in RTL. It must not be globally false-pathed.

### IO

Use `timing_io_block_level.rpt`. This is block-level typical evidence with the
current provisional IO load model. It is not pad-level signoff.

### FAST_TAG_TO_PD_TS

Use `timing_fast_tag_to_pd_post_route.rpt`. This path family must stay timed.
It must not be fixed by false path or multicycle unless a separate architecture
decision changes the contract.

## Triage Outcome Table

Fill this table after the log-clean density65 rerun:

| Path rank | WNS ns | Check type | Launch clock | Capture clock | Startpoint | Endpoint | Class | Decision |
|---:|---:|---|---|---|---|---|---|---|
| 1 | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| 2 | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| 3 | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |

## Closure Rules

- If true setup is clean and recovery/removal is failing, move to the reset
  recovery decision document.
- If true setup is failing in clk_sys, prepare a safe clk_sys-only CTS
  experiment.
- If true setup is failing in real core logic, identify the exact cone before
  changing placement or RTL.
- If RO-domain setup regresses, stop and review O13 topology/load/placement.
- If FAST_TAG_TO_PD_TS is unavailable because exact pins do not match, fix the
  report helper before claiming the family is clean.
