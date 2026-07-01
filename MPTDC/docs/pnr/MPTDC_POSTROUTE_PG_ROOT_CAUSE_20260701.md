# MPTDC Post-Route PG Root-Cause Plan - 2026-07-01

## Current Best Base

Use the RC-saved clean checkpoint as the source for all further PG experiments:

```text
/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_hold_setup_close_from_opt_182436/checkpoints/repaired_route_with_rc.enc.dat
```

It is the best base because it has:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY
```

The checkpoint is geometry-clean, regular-routing clean, and RC-restorable, but
it is not PG/signoff clean.

## Evidence Timeline

### `20260701_mptdc_hold_setup_close_from_opt_182436`

This is the current clean timing/route base.  Timing from this family is:

```text
setup WNS/TNS = -0.018 ns / -0.025 ns
hold  WNS/TNS = -0.119 ns / -1.204 ns
```

PG special connectivity remains open, so this cannot be called final signoff or
ready for tapeout.

### `20260701_mptdc_pg_special_repair_from_holdclose_183629`

This repair reduced the special-connectivity report from the original
`1000`-violation class down to `45` special violations:

```text
Net VDD: has an unconnected terminal, has special routes with opens, dangling Wire.
Net VSS: dangling Wire.
2 Problem(s) (IMPVFC-96): Terminal(s) are not connected.
1 Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.
42 Problem(s) (IMPVFC-94): The net has dangling wire(s).
```

It is not a usable base because geometry became dirty:

```text
FINAL_DRC=9
FINAL_SHORTS=5
```

### `20260701_mptdc_pg_filter_audit_from_clean_184623`

The RO macro filter does not explain the remaining special PG issue:

```text
FILTERED_AUDIT_TOTAL_VIOLATIONS=0
FILTERED_AUDIT_SHORTS=0
FILTERED_AUDIT_REGULAR_BAD=0
FILTERED_AUDIT_SPECIAL_BAD=1
FILTERED_AUDIT_SPECIAL_RAW_BAD=1
FILTERED_AUDIT_SPECIAL_FILTER_STATUS=FAIL
FILTERED_AUDIT_SPECIAL_FILTERED_RO_TERMINALS=2
FILTERED_AUDIT_SPECIAL_NON_RO_FAILURES=700
FILTERED_AUDIT_ROUTE_GATE_PASS=0
```

This proves the PG issue is not only RO macro abstraction noise. There are real
non-RO special-connectivity failures on the VDD/VSS topology.

The compact parser report from this audit refined the root-cause class:

```text
IMPVFC-96: 702 - Terminal(s) are not connected.
IMPVFC-92: 297 - Pieces of the net are not connected together.
IMPVFC-200: 1 - Special Wires: Pieces of the net are not connected together.

Unconnected Terminals By Net:
VDD: 702

Unconnected Terminals By Pin Name:
vddi: 700
VDD: 2

Coordinate-Bearing Net Lines:
VDD: 298

Probe Marker Classes:
OTHER: 701
SPECIAL_OPEN: 298
RO_PG_UNCONNECTED_PIN: 2
```

The main failure is therefore VDD standard-cell rail/followpin connectivity:
`700` lower-case `vddi` terminals are unconnected. The two RO macro VDD
terminals are real, but they are not the dominant failure. The problem is also
not symmetric VDD/VSS in this report; the high-count unconnected-terminal
failure is VDD-only.

### `20260701_mptdc_pg_sroute_sweep_from_clean_185145`

This cumulative sroute sweep is not a valid repair base. It created many
special wires in one session and damaged route geometry:

```text
FINAL_DRC=1000
FINAL_SHORTS=976
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
FINAL_ROUTE_GATE_PASS=0
```

The useful evidence is that the first sroute command created `818` wires but
still left:

```text
PG_SWEEP_ATTEMPT_1_OPEN_PORTS=26
PG_SWEEP_ATTEMPT_1_BLOCK_OPEN_PORTS=2
PG_SWEEP_ATTEMPT_1_CORE_OPEN_PORTS=24
```

The cumulative sweep must not be used as a base for timing or signoff.

### `20260701_mptdc_pg_isolated_sroute_from_clean_185942`

The first isolated candidate, `corepin_ring`, proved a useful but dangerous
point:

```text
PG_CANDIDATE_corepin_ring_TOTAL_VIOLATIONS=1000
PG_CANDIDATE_corepin_ring_SHORTS=976
PG_CANDIDATE_corepin_ring_REGULAR_BAD=0
PG_CANDIDATE_corepin_ring_SPECIAL_BAD=0
PG_CANDIDATE_corepin_ring_SPECIAL_RAW_BAD=1
PG_CANDIDATE_corepin_ring_SPECIAL_FILTER_STATUS=FILTERED_RO_ONLY
PG_CANDIDATE_corepin_ring_SPECIAL_FILTERED_RO_TERMINALS=4
PG_CANDIDATE_corepin_ring_SPECIAL_NON_RO_FAILURES=0
PG_CANDIDATE_corepin_ring_UNROUTED=0
PG_CANDIDATE_corepin_ring_ROUTE_GATE_PASS=0
```

This means post-route `sroute -connect {corePin}` can connect the non-RO VDD
PG failures, but doing it after signal/detail route causes massive shorts. It
is evidence for moving the PG repair earlier, before signal routing, not a
usable repaired checkpoint.

The first version of the isolated-sweep wrapper only ran this first candidate.
The child repair wrapper inherited the candidate-list stdin, so Innovus parsed
the remaining candidate rows as commands. The wrapper was corrected to run each
candidate with stdin redirected from `/dev/null`, and the summary extractor was
corrected to parse `PG_CANDIDATE_*` lines even when Innovus prefixes them with
`innovus 1>`.

## Root-Cause Direction

The actual issue is now narrowed enough to avoid another guess. The priority is
to prove which PG-stage action connects `vddi` standard-cell VDD rails without
creating route shorts:

1. Rerun isolated candidates from the clean checkpoint after the sweep-wrapper
   fix, so every candidate has an independent DRC/connectivity result.
2. If all post-route candidates connect VDD but create shorts, stop post-route
   repair attempts and move the fix before detail route.
3. Rerun from a post-place or post-CTS pre-route checkpoint with VDD/VSS
   followpin/special routing repaired before signal route.
4. Audit whether the `24` persistent core open ports are located in specific
   rows, near RO macros, near block PG pins, or along a missing
   followpin/stripe connection.
5. Identify which single pre-route sroute candidate, if any, improves special
   connectivity without increasing DRC/shorts.

Do not run cumulative sroute sweeps from this checkpoint.  Each candidate must
restore the same clean checkpoint and be evaluated independently.

## Added Tools

`MPTDC/pnr/scripts/summarize_mptdc_pg_connectivity.py` parses
verifyConnectivity/probe reports and writes a compact root-cause summary.

`MPTDC/pnr/scripts/server_sweep_mptdc_pg_sroute_candidates.sh` runs isolated
single-candidate sroute repairs from a clean checkpoint and writes CSV/Markdown
summaries.  It is aggressive, but controlled: every candidate starts from the
same checkpoint, so the result table shows the real effect of each command.

## Signoff Boundary

Current state is a post-route investigation checkpoint only:

- Innovus geometry and regular connectivity can be clean on the RC base.
- PG special connectivity is not clean and not RO-filterable.
- Setup is close but still negative.
- Hold is materially negative.
- Foundry DRC/LVS and antenna signoff are not complete.

The block is not ready for signoff or tapeout release until PG special
connectivity, timing, foundry DRC/LVS, antenna, and row-infrastructure
qualification are clean.
