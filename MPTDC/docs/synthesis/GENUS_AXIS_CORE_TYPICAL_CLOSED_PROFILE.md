# Genus Axis-Core Typical-Closed Profile

Author: Karim Sabra

This document explains the fixed policy in
`MPTDC/syn/scripts/profiles/genus_axis_core_typical_closed.sh`. The profile is a
repository-owned configuration, not a collection of command-line knobs.

## Reference result

- Commit: `fa66cc4d36936e2bf0d41e6b24f2f9486569e242`
- Run: `20260618_111124_axis_core_genus_timing_close_on22x1_final_guarded`
- Setup WNS: `+0.3 ps`
- Setup TNS: `-0.0 ps`
- Setup violating paths: `0`
- Max transition/capacitance/fanout violations: `0 / 0 / 0`
- Decision: `GENUS_TYPICAL_CLOSED`
- Next use: Innovus feasibility, not MMMC signoff

This reference is not a floating approval for later RTL. If the product
interface, oscillator binding, phase buffers, filelist, SDC, profile, or parser
changes, rerun the canonical flow from the new Git HEAD and generate a new
handoff package.

## Public interface

Use:

```bash
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh [run_id]
```

Only the optional run ID is public. The profile rejects inherited experiment timing
variables before it exports the internal adapter values used by the historical
Genus backend. Machine paths and output roots remain configurable because they
do not select repair policy.

## Run and RTL policy

| Profile variable | Backend adapter | Default | Job and direct effect |
| --- | --- | --- | --- |
| `MPTDC_GENUS_BASELINE_OPTIMIZATION_POLICY` | `MPTDC_GENUS_CLOSURE_PROFILE` | `timing_ultra` | Prioritizes timing proof and keeps area/power recovery from changing the comparison. |
| `MPTDC_GENUS_BASELINE_DRAIN_RTL_POLICY` | `MPTDC_OPT_MODE` | `STRIDE2` | Enables safe teardown, empty-row skip, and two-column drain scanning. This changes synthesized drain structure and is therefore pinned. |

## Exact fast-tag policy

| Profile variable | Backend adapter | Default | Job and direct effect |
| --- | --- | --- | --- |
| `MPTDC_GENUS_BASELINE_FAST_TAG_SOURCE_CELL_REMAP_ENABLED` | inverse of `MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_DISABLE` | `0` | Disables forced source-flop remapping. The DFRRQJIHDX4 experiment increased C-to-Q delay and harmed `FAST_TAG_TO_PD_TS` and `LOCAL_FAST_TAG_SELF`. |
| `MPTDC_GENUS_BASELINE_FAST_TAG_SOURCE_REMAP_MODE` | `MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE` | `POLARITY_AWARE` | Inactive while remapping is disabled; records how the rejected experiment selected reset/set-compatible cells. |
| `MPTDC_GENUS_BASELINE_FAST_TAG_SOURCE_RESET0_TARGET_CELL` | `MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL` | `DFRRQJIHDX4` | Inactive reference target for reset-to-zero source flops. |
| `MPTDC_GENUS_BASELINE_FAST_TAG_SOURCE_SET1_TARGET_CELL` | `MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL` | `DFRSJIHDX2` | Inactive reference target for set-to-one source flops. |
| `MPTDC_GENUS_BASELINE_FAST_TAG_C_TO_D_BUDGET_NS` | `MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS` | `1.333` | Uses the known-safe full fast-period budget on exact C-to-D paths. |
| `MPTDC_GENUS_BASELINE_ALLOW_TIGHTER_FAST_TAG_BUDGET` | `MPTDC_ALLOW_TIGHT_FAST_TAG_MAX_DELAY` | `0` | Prevents an accidental budget below `1.333 ns` from becoming the canonical baseline. |
| `MPTDC_GENUS_BASELINE_FAST_TAG_TAPS` | `MPTDC_FAST_TAG_REPAIR_EXACT_TAPS` | `0 1 2 3 4 5 6 7` | Applies exact path handling to all fast taps. |
| `MPTDC_GENUS_BASELINE_FAST_TAG_BITS` | `MPTDC_FAST_TAG_REPAIR_EXACT_BITS` | `0 5 6` | Limits the exact mechanism to the validated critical tag bits. |
| `MPTDC_GENUS_BASELINE_FAST_TAG_MAX_FANOUT` | `MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT` | `2` | Keeps critical sources local without imposing a broad design rule. |
| `MPTDC_GENUS_BASELINE_FAST_TAG_MAX_TRANSITION_NS` | `MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS` | `0.50` | Retains the validated local slew target without global transition pressure. |

## Broad PD-to-nfast policy

| Profile variable | Backend adapter | Default | Job and direct effect |
| --- | --- | --- | --- |
| `MPTDC_GENUS_BASELINE_BROAD_PD_HIT_TO_NFAST_REPAIR_ENABLED` | `MPTDC_GENUS_REPAIR_PD_HIT_TO_NFAST_LOCAL` | `0` | Disables the older broad grouping/constraint experiment so it cannot contaminate optimization. |
| `MPTDC_GENUS_BASELINE_BROAD_PD_MAX_DELAY_NS` | `MPTDC_PD_HIT_TO_NFAST_MAX_DELAY_NS` | `0` | Adds no broad local max-delay clamp. The `1.10 ns` experiment over-constrained the run. |
| `MPTDC_GENUS_BASELINE_BROAD_PD_MAX_TRANSITION_NS` | `MPTDC_PD_HIT_TO_NFAST_MAX_TRANSITION_NS` | `0` | Adds no broad local slew pressure. |
| `MPTDC_GENUS_BASELINE_PD_DATA_BITS` | `MPTDC_PD_HIT_TO_NFAST_BITS` and `MPTDC_PD_LOCAL_ON22_BITS` | `0 1 2 3 4 5 6` | Covers all seven nfast bits in discovery and audit. |
| `MPTDC_GENUS_BASELINE_PD_SOURCE_COUNT` | `MPTDC_PD_HIT_TO_NFAST_EXPECTED_SOURCES` | `64` | Records one source cone per PD cell for the disabled broad-repair audit. |
| `MPTDC_GENUS_BASELINE_PD_ENDPOINT_COUNT` | `MPTDC_PD_HIT_TO_NFAST_EXPECTED_ENDPOINTS` | `448` | Records seven endpoint bits across 64 PD cells. |

## Scoped local ON22 policy

| Profile variable | Backend adapter | Default | Job and direct effect |
| --- | --- | --- | --- |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_ON22_REPAIR_ENABLED` | `MPTDC_GENUS_REPAIR_PD_LOCAL_ON22` | `1` | Enables repair only on intended local PD endpoint cones. |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_SOURCE_CELL` | `MPTDC_PD_LOCAL_ON22_SOURCE_CELL` | `ON22JIHDX0` | Matches the mapped source cell observed on the real critical paths. |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_CANDIDATE_TARGETS` | `MPTDC_PD_LOCAL_ON22_TARGET_CELLS` | `ON22JIHDX1 ON22JIHDX2` | Keeps the reference request visible in reports and exercises the X2 guard. |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_ALLOW_X2` | `MPTDC_PD_LOCAL_ON22_ALLOW_X2` | `0` | Removes X2 before target selection. X2 produced WNS `-80.6 ps`, TNS `-2344.2 ps`, 167 violations, and a `LOCAL_FAST_TAG_SELF` regression. |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_EXPECTED_EFFECTIVE_TARGET` | profile checker | `ON22JIHDX1` | Asserts that candidate ordering plus the X2 guard still selects X1. |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_EXPECTED_ENDPOINTS` | `MPTDC_PD_LOCAL_ON22_EXPECTED_ENDPOINTS` | `448` | Fails closed unless all seven bits across 64 PD cells are discovered. |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_EXPECTED_DRIVERS` | `MPTDC_PD_LOCAL_ON22_EXPECTED_DRIVERS` | `AUTO` | Avoids the incorrect assumption that 448 endpoints imply 448 unique ON22 drivers; the reference run validly found 355. |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_EXPECTED_CELLS` | `MPTDC_PD_LOCAL_ON22_EXPECTED_CELLS` | `AUTO` | Uses resolved timing-report instances as the valid source-cell count. |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_DISCOVERY_METHOD` | `MPTDC_PD_LOCAL_ON22_DISCOVERY_MODE` | `TIMING_REPORT` | Treats mapped timing points as the source of truth for instance discovery. |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_TIMING_PATH_LIMIT` | `MPTDC_PD_LOCAL_ON22_TIMING_MAX_PATHS` | `1000` | Requests enough paths to expose the relevant ON22 rows without an unbounded report. |
| `MPTDC_GENUS_BASELINE_PD_LOCAL_APPLY_RESIZE` | `MPTDC_PD_LOCAL_ON22_APPLY_REPAIR` | `1` | Applies resolved X0-to-X1 changes instead of discovery-only reporting. |

## Why timing-report discovery is required

Genus reports the mapped instance inside the first timing-point token, not in a
separate final instance column. For example:

```text
u_core_gen_pd_row[4].gen_pd_col[7].u_pd/g436__5122/Q ... ON22JIHDX0 ...
```

The resizable instance is:

```text
u_core_gen_pd_row[4].gen_pd_col[7].u_pd/g436__5122
```

The parser finds `ON22JIHDX0` rows, removes the output-pin suffix, keeps only
instances under the endpoint's local PD prefix, resolves the exact Genus object,
and then resizes it. The corrected reference discovery reported 355 timing rows,
355 unique instances, 355 resolved instances, and 355 changed cells.

## Failed X2 experiment retained as a guard

The X2 experiment proved that larger drive is not monotonically better. Although
the same 355 instances were changed, X2 altered local delay/load balance and
created a new `LOCAL_FAST_TAG_SELF` critical family. The canonical profile keeps
X2 in the requested list but forces `ALLOW_X2=0`, so reports retain the request
while the effective target remains X1.

This is a local protected-family rule. It prohibits `ON22JIHDX2` for the scoped
PD local ON22 repair described above; it is not a global ban on every X2 cell in
the design.

## Change procedure

Copy the canonical profile and wrapper under a hypothesis-based name. Record the
expected affected path family, rollback threshold, and baseline comparison. Do
not export a backend experiment variable on the command line. Promote a profile only
after exact object counts, SDC cleanliness, WNS/TNS/path counts, DRVs, and
path-family classification are clean and the server run is tied to a commit.
