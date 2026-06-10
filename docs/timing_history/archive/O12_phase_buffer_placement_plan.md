# O12 Phase Buffer Placement Plan

Status: `O12_PHASE_ISOLATION_BUFFER_EXPERIMENT`

This is a physical feasibility plan, not final signoff.

## Topology

The O12 topology is:

```text
RO_tune4/S[0:7]
  -> mptdc_phase_buffer_bank
  -> buffered slow_phase[0:7] / fast_phase[0:7]
  -> PD matrix, tag generators, slow epoch, and metadata
```

The RTL implementation uses two instances:

- `u_core/u_phase_buf_slow`
- `u_core/u_phase_buf_fast`

For the O12 synthesis experiment, every tap uses exactly one `BUHDX4`:

```text
phase_raw_i[n] -> BUHDX4 -> phase_buf_o[n]
```

No tap gets a different size, a longer chain, or a one-off phase0 fix.

## Placement Intent

Slow side:

```text
slow RO
  -> slow phase isolation buffers
  -> PD matrix / slow epoch / stop metadata
```

Fast side:

```text
fast RO
  -> fast phase isolation buffers
  -> PD matrix / fast tag columns
```

Place each buffer bank close to its RO macro and between the RO and the PD
matrix.  The buffer cells should be arranged with the same orientation and
sequence for every tap.

## Matching Requirements

The backend experiment must preserve:

- one identical buffer topology per tap;
- matched cell orientation across taps;
- matched source-to-buffer route length as much as practical;
- reviewable buffer-output phase routes into the PD matrix;
- no CTS-style restructuring of the RO phase buffers;
- no arbitrary per-tap buffer resizing.

## Required O12 Physical Reports

The report package must include:

- `reports/ro_phase_raw_pin_loads.csv`
- `reports/phase_buffer_output_loads.csv`
- `reports/phase_buffer_balance_summary.md`
- `reports/phase_net_load_budget_summary.md`

For each tap, review:

- raw RO `S` pin load;
- buffer output load;
- fanout;
- route length if Innovus exposes it in the routed database;
- max-cap status;
- source-to-buffer matching;
- buffer-output matching.

## Pass Criteria

Preferred:

- raw `RO_tune4/S[n]` direct load <= 58.72 fF.

Acceptable for the CN-like interpretation:

- raw `RO_tune4/S[n]` direct load <= 75.59 fF.

Because the current RO shell limit is 50 fF, any matched raw RO pin with no
`drv_max_cap.rpt` violation is bounded below both O12 targets.  Numeric cap is
still preferred when Innovus exposes a reliable all-net cap report.

## Review Risks

The buffer bank can fix raw RO max-cap and still fail the architecture if it
creates excessive:

- tap-to-tap delay mismatch;
- route imbalance;
- dynamic power;
- buffer output max-cap violations;
- congestion between RO and PD matrix;
- non-monotonic effective Vernier phase order.

If those risks cannot be controlled, the fallback is RTL load reduction, not a
silent RO Liberty relaxation.
