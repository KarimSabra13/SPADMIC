# O13 IO Load Model From XLIBD

Status: `PROVISIONAL_BLOCK_IO_MODEL_NOT_PAD_SIGNOFF`

O10/O12 Innovus timing has repeatedly shown top-level output paths dominating aggregate WNS. For block-level feasibility, IO timing should remain visible but should not dominate the phase-buffer architecture decision when the real chip-level output load is not yet known.

## Reference Cell

Use `DFRRQHDX2 D_CAP = 3.20 fF` as the first simple output load unit.

## Load Classes

| Class | Equivalent D inputs | Load fF | Load pF |
|---|---:|---:|---:|
| `light` | 4 | 12.8 | 0.0128 |
| `medium` | 8 | 25.6 | 0.0256 |
| `heavy` | 16 | 51.2 | 0.0512 |
| `very_heavy` | 32 | 102.4 | 0.1024 |

The default block-level feasibility class is `medium`. Use `heavy` if the system manager expects a stronger local block load. Do not use this for pad-level signoff.

## Innovus Option

O13 report scripts recognize:

```bash
MPTDC_PNR_IO_LOAD_CLASS=light|medium|heavy|very_heavy
```

The scripts write:

```text
reports/io_load_model.rpt
```

The report records the selected load class, fF/pF value, and the top-level outputs being modeled.

## Outputs Of Interest

Review at least:

- `acq_data_o`
- `narrow_data_o`
- `csr_rdata_o`
- `csr_rvalid_o`
- `acq_valid_o`

## Rule

IO paths can remain failing in an O13 phase-buffer feasibility experiment, but they must be reported separately from:

- raw RO load
- final phase-driver load and transition
- local oscillator-domain timing
- reset/recovery timing
- real `clk_sys` internal timing
