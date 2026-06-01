# O3 PD Shadow Tag Capture

## Why Change

O2 removed the global fast binary counter path, but Genus still reports local
PD paths where q1/q2/hit_latched control the D path of every
`nfast_hit_latched` bit.

That path is real timing, not a false path. It is part of timestamp capture in
the fast tap domains.

## O3 Design

Before O3, the PD cell captured the tag only when the falling edge was detected:

```systemverilog
if (!hit_latched && !q1 && q2)
  nfast_hit_latched <= nfast_tag_i;
```

After O3, the PD cell shadows the current local tag until the first hit:

```systemverilog
if (!hit_latched)
  nfast_hit_latched <= nfast_tag_i;

if (!hit_latched && !q1 && q2)
  hit_latched <= 1'b1;
```

With nonblocking semantics, the hit edge freezes the current tag. Future fast
edges do not update the tag because `hit_latched` is already set.

## Expected Timing Benefit

The 7-bit tag capture D path no longer depends on q1/q2 falling-edge detection.
q1/q2 still control `hit_latched`, but they no longer feed the mux/select logic
for every tag bit.

## Semantics

The exported HIT `nfast` field remains the raw local fast LFSR tag in O2/O3
raw-tag mode. Software decodes it using `nf` and the LFSR sequence metadata.

The packet bit layout is unchanged.

## Tests

Local Verilator tests check:

- `detect_en_i=0` prevents false hits.
- real falling edge creates exactly one hit.
- current tag is captured on hit.
- tag remains stable after hit.
- clear resets hit and tag.
