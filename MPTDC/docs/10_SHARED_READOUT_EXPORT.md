# MPTDC — Shared Readout Export Contract

## Scope

This document defines the optional acquisition-record export path added to `mptdc_top_asic` / `mptdc_core` for the SPADMIC shared-readout architecture.

It complements:

- [`01_ARCHITECTURE.md`](01_ARCHITECTURE.md)
- [`02_OUTPUT_PROTOCOL.md`](02_OUTPUT_PROTOCOL.md)
- [`03_CSR_MAP.md`](03_CSR_MAP.md)

## 1. Why this interface exists

The original standalone MPTDC flow packetized each core locally into a 16-bit narrow stream.

The active SPADMIC top instead shares one final serializer across three axes to save duplicated top-level readout logic. To do that safely, each axis exports **acquisition records** from its local `mptdc_core` FIFO before final packetization.

## 2. Exposed ports

### `rtl/top/mptdc_top_asic.sv`

| Port | Dir | Meaning |
|------|-----|---------|
| `shared_readout_en_i` | in | select exported-record mode instead of the local narrow serializer |
| `acq_ready_i` | in | downstream ready for the next acquisition record |
| `acq_valid_o` | out | acquisition record valid |
| `acq_data_o[ACQ_REC_W-1:0]` | out | acquisition record payload |
| `fifo_full_o` | out | local acquisition FIFO full flag |

### `rtl/top/mptdc_core.sv`

These ports have the same semantics inside `mptdc_core`; `mptdc_top_asic` simply forwards them to the outside world.

## 3. Mode selection

### `shared_readout_en_i = 0`

- legacy standalone behavior
- the local `mptdc_narrow16_tx_v2` consumes the internal FIFO
- `acq_valid_o` stays low
- `acq_data_o` still reflects the FIFO word, but it is not part of the active contract

### `shared_readout_en_i = 1`

- export behavior used by the active SPADMIC top
- the local narrow serializer is disabled
- the FIFO read enable is driven by `acq_ready_i`
- `acq_valid_o` mirrors FIFO validity
- `acq_data_o` carries the acquisition record currently at the FIFO output

Only one consumer is active at a time because both modes share the same internal FIFO reader.

## 4. Acquisition-record format

The exported payload type is `mptdc_acq_rec_t` from `rtl/pkg/mptdc_pkg.sv`.

```text
mptdc_acq_rec_t
  kind : ACQ_REC_META or ACQ_REC_HIT
  hit  : per-hit raw record
  meta : per-conversion metadata record
```

### 4.1 `kind`

| Value | Name | Meaning |
|-------|------|---------|
| `0` | `ACQ_REC_HIT` | per-hit record |
| `1` | `ACQ_REC_META` | one conversion-level metadata record |

### 4.2 META payload (`meta`)

| Field | Meaning |
|-------|---------|
| `nslow` | STOP-side slow coarse snapshot |
| `nfast` | capture-time fast coarse snapshot (`nfast_snap`) |
| `nfast_stop` | reserved STOP-edge fast snapshot field |
| `hit_count` | number of HIT records that follow for this conversion |
| `flags` | `closed_by_fast_maxhit`, `closed_by_maxhits`, `closed_by_watchdog` |
| `phase0_snap` | STOP-side phase-0 snapshot |
| `stop_slow_phase_disc` | STOP-edge `slow_phase[5:3]` discriminator exported in fixed Hit W1 `[2:0]` |
| `slow_boundary_inc` | STOP-side boundary carry |
| `ctx_id` | owning context ID |

### 4.3 HIT payload (`hit`)

| Field | Meaning |
|-------|---------|
| `ns` | slow phase index of the hit PD cell |
| `nf` | fast phase index of the hit PD cell |
| `nfast` | per-hit fast coarse count (`nfast_hit`) |
| `event_seq` | drain/scan order within the frozen bitmap |

## 5. Sequencing rules

For each accepted conversion, `mptdc_drain_ctrl` emits:

1. one META record
2. zero or more HIT records

The contract is therefore:

- a packet always starts with META
- `meta.hit_count` tells the downstream consumer how many HIT records follow
- no second META may appear for that axis until the current conversion has drained

This is the rule used by the TOP `spadmic_tdc_packet_adapter` instances and packet arbiter to start each TDC packet on META and keep the source fixed until packet end.

## 6. Backpressure behavior

- `acq_valid_o` remains asserted while the FIFO has a valid front record
- the record advances only when `acq_valid_o && acq_ready_i`
- if the downstream shared readout stalls, the local FIFO simply stops draining
- `fifo_full_o` reports whether the local FIFO has reached its capacity limit

Backpressure therefore affects sustained throughput and context availability, but it does not change the measurement kernel itself.

## 7. Relationship to the narrow packet protocol

The narrow 16-bit packet format remains defined by [`02_OUTPUT_PROTOCOL.md`](02_OUTPUT_PROTOCOL.md).

The shared-readout export path does **not** change:

- header semantics
- hit payload formats
- EOC semantics

It only changes where packetization happens:

- standalone: inside each `mptdc_core`
- shared-top flow: in each per-axis `spadmic_tdc_packet_adapter`, before packet-atomic arbitration
