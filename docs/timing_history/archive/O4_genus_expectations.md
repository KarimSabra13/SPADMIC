# O4 Genus Expectations

## Runs

The O4 server wrapper runs:

1. nominal, `GENUS_EFFORT=fast`
2. R600 what-if, `GENUS_EFFORT=fast`
3. optional closure only for the promising mode

Fast-feasibility mode lowers synthesis effort only. It does not change timing correctness, clocks, libraries, SDC, reports, or exceptions.

## Success Criteria

O4 nominal should show:

- fast tag enable/hold mux paths improved or removed
- slow Johnson enable/hold mux paths improved or removed
- START watchdog clk_sys path improved
- old global fast counter path still absent
- old slow binary/Gray counter path still absent
- no `UNKNOWN_REVIEW_REQUIRED` paths
- no broad new exceptions
- PD behavior unchanged

If nominal still fails in PD-local timestamp-freeze paths, compare against R600.

## R600 Decision

R600 is promising only if it produces a structural improvement:

- PD-local WNS improves by hundreds of ps or more
- dominant path family changes
- `OSC_FAST_REAL` moves into a semi-reasonable range
- no new unknown or exception-dominated class appears

Small low-effort differences are not meaningful. Closure evidence requires a closure-effort rerun of the promising mode.

## Blocked Until After O4 Review

- Innovus
- final R600 signoff
- cell sizing
- PD redesign
- PD macro conversion
