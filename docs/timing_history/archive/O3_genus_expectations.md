# O3 Genus Expectations

## Server Wrapper

Use:

```bash
bash MPTDC/syn/scripts/server_run_genus_o3_raw_epoch_cleanup.sh 20260601_o3_raw_epoch_cleanup_genus
```

The wrapper cleans the result directory before running Genus to avoid stale
focused reports.

## Expected Checks

The summary must report:

- exactly two `RO_tune4` instances.
- zero oscillator stubs.
- zero `u_fast_cnt` residue.
- zero `u_slow_cnt` / old Gray slow-counter residue.
- slow Johnson epoch and STOP epoch capture references present.
- old fast-counter-to-PD timing text count zero.
- old slow-counter timing text count zero.
- PD q/hit-latched to nfast timing text count measured for review.

## Success Criteria

O3 is promising if:

- old slow binary/Gray source paths are gone.
- slow Gray-to-binary fast-domain decode paths are gone.
- slow watchdog binary counter paths are gone.
- PD q1/q2 to `nfast_hit_latched` paths are gone or much smaller.
- global fast counter path remains gone.
- no broad new exceptions were added.
- `clk_sys` becomes the dominant ordinary remaining timing class or remaining
  oscillator paths are local and physically meaningful.

## Failure Classification

If O3 fails, classify the remaining blocker as:

- Johnson source timing.
- Johnson decode timing in clk_sys.
- STOP epoch capture/held-bus CDC modeling.
- PD hit latch timing.
- drain/readout timing.
- constraint/modeling artifact.
- DRV/transition dominated.
