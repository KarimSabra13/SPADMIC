# O4 Muxless Fast and Slow Tags

## Fast Local Tags

Before O4, `mptdc_fast_epoch_tag` advanced only when `enable_i` was high:

```systemverilog
else if (enable_i)
  tag_o <= lfsr_next(tag_o);
```

This creates a synchronous enable/hold mux on the fast oscillator domain. O3 Genus showed local fast tag register-to-register paths still failing badly at nominal frequency.

O4 changes the tag to advance on every `clk_fast` edge after reset/clear:

```systemverilog
else
  tag_o <= lfsr_next(tag_o);
```

The `enable_i` port is retained for wrapper/test compatibility but ignored. The RO_tune4 `rstb`/run control already stops the clock outside active windows, so the tag naturally holds when there are no fast edges.

## Slow Johnson Epoch

Before O4, `mptdc_slow_epoch_johnson` also had a synchronous enable/hold mux. O4 removes it for the same reason:

```systemverilog
else
  johnson_o <= {johnson_o[STAGES-2:0], ~johnson_o[STAGES-1]};
```

The slow epoch remains Johnson encoded, not LFSR encoded, because STOP captures it asynchronously and Johnson transitions change one bit per state.

## Functional Impact

Expected impact is low:

- When the oscillator is stopped, there are no tag clock edges.
- During oscillator keep-alive, tags may continue advancing; raw-tag mode already requires software/calibration decode.
- Packet width and field layout are unchanged.
- HIT `nfast` remains a raw LFSR tag in O2/O3/O4 raw-tag mode.
- META `nslow` remains decoded from the STOP-captured Johnson state.

## Timing Intent

This removes unnecessary mux logic from the oscillator-domain tag self paths. It does not claim closure of PD-local timestamp-freeze paths; those remain real PD measurement logic and are evaluated at nominal and R600.
