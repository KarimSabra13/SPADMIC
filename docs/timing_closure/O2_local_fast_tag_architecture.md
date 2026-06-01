# O2 Local Fast Tag Architecture

Date: 2026-06-01

Branch: `SPADMIC_localtag`

Base HEAD before O2 edits: `226549ca4064d8dcb1f5e06fc3223c2454e1d0b7`

## Objective

Remove the live global binary `nfast_src_count` bus from the fast-domain PD
capture path.  O1C2/O1C3 Genus showed the previous path:

```text
fast_phase[0] binary counter
  -> nfast_src_count[6:0]
  -> 64 PD cells
  -> nfast_hit_latched_reg[*] clocked by fast_phase[nf]
```

This path is not physically meaningful in XH018 as ordinary standard-cell
timing, especially for `nf=1/2/3` windows around 50/100/150 ps.

## Chosen Architecture

O2 uses one local 7-bit LFSR fast epoch tag per fast column:

```text
fast_phase[nf]
  -> mptdc_fast_epoch_tag gen_fast_tag_col[nf]
  -> fast_tag_col[nf][6:0]
  -> 8 PD cells in column nf
```

Each PD cell captures the local column tag on hit.  The static-bus bridge and
context bank continue to store a packed `nfast_hit_packed` field.  In
`O2_RAW_TAG_SW_DECODE`, that stored field is emitted directly in the existing
packet/acquisition `nfast` field.  There is no RTL tag-to-binary decode and no
RTL offset correction.

## Tag Sequence

The tag generator is `MPTDC/rtl/pd/mptdc_fast_epoch_tag.sv`.

Parameters:

- width: `NFAST_W = 7`
- seed: `FAST_TAG_SEED = 7'b0000001`
- polynomial: `x^7 + x^6 + 1`
- next state: `{tag[5:0], tag[6] ^ tag[5]}`
- sequence length: 127 non-zero states

The local Verilator test `tb_fast_epoch_tag_unit` verifies:

- reset and clear load the seed
- disabled tag holds state
- enabled tag advances
- no zero state appears
- no repeat occurs before 127 states
- the software decoder maps every state back to its sequence count

## PD Cell Change

`mptdc_pd_cell` now has a separate `detect_en_i`.

Before O2:

```text
slow_phase input = pd_enable_gated & slow_phase[ns]
nfast_hit_latched <= live binary nfast_count
```

After O2:

```text
slow_phase input = raw slow_phase[ns]
detect_en_i = pd_enable_gated
nfast_hit_latched <= local nfast_tag_i
```

When `detect_en_i=0`, the PD sampler holds `q1/q2` and cannot fabricate a
falling-edge hit by forcing the sampled slow input low.  This keeps the O1C3
false-hit fix and removes the external slow-input gate.

## Packet Semantics

The packet/acquisition record schema is unchanged:

- `ns` remains the slow tap index
- `nf` remains the fast tap index
- `nfast` remains a 7-bit packet-visible fast epoch/count field
- `hit_bitmap`, metadata fields, context fields, and record ordering are unchanged

Semantic change:

- Before O2, PD cells attempted to capture a live binary phase-0 fast count.
- After `O2_RAW_TAG_SW_DECODE`, PD cells capture a local encoded tag and the
  drain path emits that raw tag unchanged in `HIT.nfast`.

The packet bit layout is unchanged, but the meaning of `HIT.nfast` is changed:

```text
pre-O2: HIT.nfast = binary fast counter value captured by the PD cell
O2:     HIT.nfast = raw 7-bit local LFSR tag captured by the PD cell
```

Software/calibration must decode the field before any reconstruction that
expects a binary fast-cycle index:

```text
decoded_fast_cycle = decode_table[nf][raw_tag]
fast_cycle = decoded_fast_cycle + column_offsets[nf] + detection_offset
```

For the first pass, `column_offsets[nf] = 0` and `detection_offset = 0`.
Those are characterization placeholders, not silicon calibration constants.

Do not mix pre-O2 logs and O2 raw-tag logs without run metadata.  O2 outputs
must carry at least:

```text
nfast_encoding = "raw_lfsr_tag"
tag_decode_mode = "software"
tag_width = 7
tag_columns = 8
```

## `nfast_snap`

The old fast binary counter is removed from the O2 RTL timing graph.  The
compatibility signal named `nfast_src_count` now carries the phase-0 raw tag
into the held-bus snapshot.  `mptdc_drain_ctrl` emits `snapshot_i.nfast_snap`
directly in the META record.

This preserves field widths and record layout, but O2 requires
software-characterization and Xcelium review before the raw-tag epoch origin is
treated as calibration-safe.

## Expected Timing Impact

Expected removed paths:

- `u_fast_cnt/bin_q_reg[] -> u_pd/nfast_hit_latched_reg[*]`
- global `nfast_src_count` fanout to 64 PD cells
- fast binary carry-chain counter from the PD timestamp path

Expected new fast paths:

- local `mptdc_fast_epoch_tag` LFSR feedback in each fast column
- local `fast_tag_col[nf] -> 8 PD nfast_hit_latched` paths in the same
  `fast_phase[nf]` domain

`clk_sys` does not contain the tag decode in the default O2 branch.  The drain
FSM emits raw tag data; Python/software calibration performs decode and offset
correction.

## Local Evidence

Run IDs:

- `20260601_o2_raw_tag_lint`
- `20260601_o2_raw_tag_smoke`
- `20260601_o2_raw_tag_charac_smoke`

Result:

- Verilator lint PASS.
- Verilator smoke PASS, 14/14 steps.
- Synthetic Python raw-tag characterization smoke PASS.

Included tests:

- `tb_fast_epoch_tag_unit`
- `tb_pd_cell_tag_capture_unit`
- `tb_pd_gate_false_hit_unit`
- `tb_drain_raw_tag_unit`
- `tb_meas_ctrl_unit`
- `tb_hit_capture_bridge_unit`
- `tb_context_bank_unit`
- `tb_drain_ctrl_unit`
- `tb_single_conv`
- `tb_backpressure`
- `vip_smoke_single_conv`
- `vip_backpressure_integrity`
- `vip_vip_maxhits_matrix`

Additional checks:

- `python3 tools/mptdc_decode/test_fast_tag_decode.py`: PASS
- O2 synthesis filelist Verilator syntax check with `MPTDC_USE_RO_TUNE4_MACRO`:
  PASS
- Characterization baseline dry-run with `--nfast-encoding raw_lfsr_tag`: PASS
- VIP overnight char-stage dry-run with `--char-nfast-encoding raw_lfsr_tag`: PASS

## Remaining Risks

Functional risk: medium until Xcelium exercises async START/STOP timing sweeps
and reconstruction checks.

Calibration risk: medium/high until raw-tag characterization confirms that the
software decode and per-`nf` offset model reconstruct a monotonic fast cycle.
The packet field is stable, but its O2 semantic meaning is different.

Linearity risk: low/medium.  O2 removes an asymmetric global count load but
adds one local tag generator per fast column.  Innovus must later verify tag
generators are placed near their columns and do not pollute phase routing.

Signoff status:

```text
REAL_PHYSICAL_ABSTRACT_WITH_RAW_LOCAL_FAST_TAG_AND_LIBERTY_SHELL
NOT ANALOG OSCILLATOR SIGNOFF
NOT CALIBRATION-SAFE UNTIL SOFTWARE/XCELIUM/CALIBRATION REVIEW
```
