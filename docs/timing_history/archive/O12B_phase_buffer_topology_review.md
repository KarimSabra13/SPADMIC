# O12B Phase Buffer Topology Review

Status: `O12B_PHASE_BUFFER_BALANCE_AND_CLEAN_PNR`

This is a feasibility/debug review, not signoff.

## Expected Topology

Each oscillator tap must use the same single-stage topology:

```text
RO_tune4/S[n] -> *_phase_raw[n] -> BUHDX4 -> *_phase[n]
```

Required topology:

- 8 slow buffers.
- 8 fast buffers.
- One `BUHDX4` per tap.
- Same cell sequence for every tap.
- No tap-specific sizing.
- No extra isolation stage.
- No phase0 special case.

## Required Report

O12B generates:

```text
reports/phase_buffer_topology.csv
```

Required columns:

```text
family,tap,buffer_chain_depth,cell_sequence,input_net,output_net,status,notes
```

Expected status for all rows:

```text
TOPOLOGY_MATCH
```

Invalid statuses:

- `MISSING_BUFFER`
- `TOPOLOGY_MISMATCH`
- `EXTRA_BUFFER`

## Acceptance Gate

Topology is acceptable only if:

- all 16 rows are present;
- all 16 rows are `TOPOLOGY_MATCH`;
- all 16 rows use `BUHDX4`;
- raw RO fanout is exactly 1 for every tap.

If any mismatch exists, do not interpret timing or calibration quality until the
topology is fixed or explicitly documented.
