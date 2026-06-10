# O12C Phase Buffer Topology Options

REPORT_STATUS=REVIEW_REQUIRED

The O12 phase-isolation architecture should stay.  The decision is now the digital phase-driver topology after the RO has been protected.

## Option A - Keep Single BUHDX4

Pros:

- Already isolates `RO_tune4/S[n]` correctly.
- Simplest topology.
- Lowest added area and power among the listed options.
- Least change to the existing O12 physical experiment.

Cons:

- BUHDX4 outputs see large digital loads: fast taps are roughly `584-707 fF`, and slow `0` is `520 fF`.
- Transition may be poor.
- Delay and mismatch may be too large unless placement is controlled.

Use this if output transition, delay, mismatch, and power are acceptable after O12C reporting and constrained placement.

## Option B - Stronger Single-Stage Buffer

Candidate cells:

- `BUHDX6`
- `BUHDX8`
- `BUHDX12`

Pros:

- Better drive for the `500-700 fF` digital phase load.
- Minimal topology change.
- Easier to keep all taps identical than a branched or two-stage tree.

Cons:

- Larger input capacitance at the RO output.
- The first-stage input cap must stay within the analog budget target.
- More dynamic power.
- Different phase delay requires characterization.

Use this only after auditing input caps.  If a stronger cell exceeds the chosen RO input budget, do not use it directly after the RO.

## Option C - Two-Stage Buffer

Examples:

```text
RO -> BUHDX2 -> BUHDX8 -> fabric
RO -> BUHDX4 -> BUHDX12 -> fabric
```

Pros:

- Small first stage can keep analog RO load low.
- Strong second stage can drive the digital fabric.
- Better transition control than one weak buffer.

Cons:

- Adds delay.
- Adds mismatch risk.
- Adds cells, area, and power.
- Requires calibration and characterization.

Use this if stronger single-stage drive is needed but direct stronger-cell input cap is not acceptable.

## Option D - Split Load Tree Per Phase

Example:

```text
RO -> isolation buffer -> branch A to PD matrix
                      -> branch B to tag / epoch / metadata
```

Pros:

- Lower load per driver.
- Can separate timing-critical PD loads from metadata/epoch loads.

Cons:

- More skew and matching complexity.
- More placement complexity.
- Must keep topology identical across taps unless there is an explicit calibration strategy.

This is a later option if single-stage and two-stage buffer topology cannot close.

## Decision Rules

- Never buffer only one tap differently without documenting calibration impact.
- Prefer identical topology for all fast taps.
- Slow `0` may need special treatment later, but any one-off slow `0` path must be documented and characterized.
- All topology changes require characterization before final adoption.
- Do not broad false-path the phase buffer delay.
