# O2 Raw-Tag Software Decode

Date: 2026-06-01

Branch: `SPADMIC_localtag`

## Contract

In `O2_RAW_TAG_SW_DECODE`, hardware exports the local fast-column LFSR tag in
the existing packet/acquisition `nfast` field.

Packet bit layout is unchanged.  Packet semantics are changed:

```text
legacy_binary_nfast:
  HIT.nfast = binary fast count captured by the PD cell

raw_lfsr_tag:
  HIT.nfast = raw 7-bit LFSR tag captured by the PD cell
```

Software must not treat `HIT.nfast` as a binary count when the run metadata
says `nfast_encoding = raw_lfsr_tag`.

## Decode

The maintained Python helper is:

```text
tools/mptdc_decode/fast_tag_decode.py
```

Main API:

```python
decoded_fast_cycle = decode_raw_tag(
    raw_tag=hit.nfast,
    nf=hit.nf,
    mode="raw_lfsr_tag",
    column_offsets=column_offsets,
    detection_offset=detection_offset,
)
```

The first-pass model uses:

```text
column_offsets[nf] = 0 for nf = 0..7
detection_offset = 0
```

Those values are placeholders for characterization.  Final offsets must come
from Xcelium/characterization/calibration evidence.

## Required Metadata

O2 raw-tag logs, CSVs, JSON summaries, and characterization outputs must carry:

```text
nfast_encoding = raw_lfsr_tag
tag_decode_mode = software
lfsr_width = 7
lfsr_seed = 1
tag_columns = 8
column_offsets_version = o2_initial_zero_offsets
```

Do not mix pre-O2 and O2 datasets without this metadata.

## Compatibility

Software helpers preserve legacy data by supporting:

```text
mode = legacy_binary_nfast
```

In legacy mode, `nfast_hit` is passed through as `nfast_decoded`.

## Characterization Status

Local synthetic decode smoke is required before Genus.  Server Xcelium/VIP and
overnight characterization remain required before calibration safety is claimed.
