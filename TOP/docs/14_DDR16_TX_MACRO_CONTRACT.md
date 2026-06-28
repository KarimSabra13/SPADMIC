# DDR16 TX Macro Contract

Status: Phase 0 macro-boundary plan. The final analog DDR macro handoff is still TBD.

## Final Direction

The final physical TX interface is 16 DDR data bits. The current 8-bit DDR TX RTL is obsolete for final silicon and must not be used as the final macro boundary.

The digital design shall provide a clean single-edge RTL boundary to a custom DDR macro model/wrapper. It shall not implement final DDR behavior using generic dual-edge procedural logic.

## Provisional Digital Boundary

```systemverilog
output logic [15:0] ddr_data_l_o;
output logic [15:0] ddr_data_h_o;
output logic        ddr_pair_valid_o;
output logic        ddr_clk_o;
output logic        ddr_enable_o; // optional if macro requires it
```

Defaults:

- `ddr_data_l_o` is the older logical 16-bit word.
- `ddr_data_h_o` is the next logical 16-bit word.
- `ddr_pair_valid_o` qualifies the pair.
- `ddr_clk_o` is derived from `clk_sys` unless macro ownership changes.
- Idle drives data zero and valid low.

Exact DATA_L/DATA_H edge mapping is TBD with the DDR macro designer.

## Pairing Stage

The matrix-top output path is:

```text
spadmic_event_bundle_tx
  -> spadmic_output_fifo
  -> spadmic_ddr16_tx_pairer
  -> DDR16 macro boundary
```

`spadmic_output_fifo` is synchronous to `clk_sys`, has 512 entries in v1, and
is used by event admission through a 129-entry reservation threshold. That
threshold covers the 128-word logical bundle estimate plus one ordered flush
marker. In the top integration each FIFO entry carries 16 logical data bits plus
one internal flush-marker bit. Bundle TX words enter the FIFO as data entries;
bundle `flush_o` enters as an ordered marker. This prevents an odd final word
from one bundle from being paired with the first word of a later bundle.

`spadmic_ddr16_tx_pairer` converts FIFO data entries into DDR macro pairs:

- collects the first word into a low/first holding register;
- collects the second word into a high/second holding register;
- presents both words together for one pair transfer;
- exposes `busy_o` and `empty_o` for TOP safe-idle logic.
- pads the high/second half with zero when it receives a flush marker while one
  word is held.

Because v1 defaults to one valid per pair, odd bundle lengths are represented by
a padded DDR pair rather than a per-half valid. If the final macro supports
per-half valid, this contract can be extended to `valid_l/valid_h` and the
pairer can avoid padding.

## Open DDR Designer Items

- Is the macro one 16-bit block or 16 one-bit lanes?
- Exact port names for DATA_L, DATA_H, clock, valid, enable, reset.
- Which side owns/generated the forwarded clock?
- Which of DATA_L/DATA_H appears on the rising/falling edge?
- Is valid single-data-rate per pair, DDR, or per half?
- Is output enable required?
- Reset behavior and required idle values.
- Clock-to-output delay.
- Duty-cycle requirements.
- Pin load and board assumptions.

## Constraints And Signoff Status

- No final board timing exists.
- No final DDR macro timing exists.
- SDC for this boundary is placeholder only until macro and board contracts arrive.
- TOP safe idle must include bundle TX idle, output FIFO empty, no pending FIFO
  flush marker, DDR pairer empty/busy state, and no pending physical valid.
