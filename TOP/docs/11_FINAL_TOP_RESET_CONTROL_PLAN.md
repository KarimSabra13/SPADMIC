# Final TOP Reset, Control, And Event Plan

Status: Phase 6 local implementation and verification status. This document supersedes older TOP reset/control assumptions for the matrix-top integration work.

## Scope

This plan defines the final v1 control architecture for:

- explicit operating modes;
- event acceptance and mode-dependent masks;
- skew-safe TDC START gating;
- raw snapshot and selective reset coordination;
- packet bundle correlation;
- safe mode/configuration transitions;
- reset and power-up behavior.

Protected MPTDC measurement internals are outside this scope.

## Implemented RTL Status

Phase 2/3 added the first matrix-top shell and CSR/I2C endpoint. Phase 4/5/6 connected the first event/output path and local readiness coverage:

- `TOP/rtl/spadmic_top_matrix_v1.sv` exposes the final/provisional chip-level matrix ports, separate `clk_cfg_40m`, calibration inputs, and DDR16 `DATA_L/DATA_H` style boundary.
- `TOP/rtl/spadmic_matrix_top_csr.sv` implements the new matrix-top CSR endpoint used by `spadmic_top_matrix_v1`.
- `TOP/rtl/spadmic_top_v1.sv` remains untouched and is not retired.
- No protected MPTDC internals are modified.

Remaining local limitations:

- BOTH-mode full top event generation still needs a dedicated top-level test.
- Full directed R/Y/B physical skew campaign is not complete.
- Cluster packetization remains in the legacy position block and is not yet snapshot-driven.
- Shared TDC `max_hits` and RO code CSRs are not fully migrated into the matrix-top CSR endpoint.

Validated Phase 2/3 behavior:

- reset-select outputs idle high on global reset;
- matrix config outputs idle on reset;
- I2C can read the matrix-top ID;
- I2C can write/read reset-width and active mode controls;
- I2C can launch a `WRITE_COLUMN_64` matrix configuration command through the command/status CDC controller;
- matrix config readback is visible through CSR;
- position-only events generate selective reset, raw position packets, bundle output, DDR16 output, and safe-idle drain;
- TDC-only events generate selective reset, real MPTDC wrapper packets for R/Y/B, bundle output, DDR16 output, and safe-idle drain;
- Verilator readiness now lints both legacy `spadmic_top_v1` and matrix `spadmic_top_matrix_v1`.

## Explicit Modes

The final TOP shall use explicit modes:

| Mode | Matrix events | TDC | Raw snapshot | Position packet | Matrix reset | Calibration | Expected packet mask `{POSITION,B,Y,R}` |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `MODE_DISABLED` | no | no | no | no | no | optional CSR only | `4'b0000` |
| `MODE_TDC_ONLY` | yes | R/Y/B | reset only | no | yes if width nonzero | no | `4'b0111` |
| `MODE_POSITION_ONLY` | yes | no | yes | yes | yes if width nonzero | no | `4'b1000` |
| `MODE_BOTH` | yes | R/Y/B | yes | yes | yes if width nonzero | no | `4'b1111` |
| `MODE_CALIBRATION` | no | selected axes | no | no | no | yes | `{1'b0, calib_axis_mask[2:0]}` |

Source bit order is fixed:

- bit 0: R TDC, legacy X;
- bit 1: Y TDC;
- bit 2: B TDC, legacy Z;
- bit 3: POSITION.

## Mode-Dependent Equations

No block may use one fixed all-source AND. The coordinator latches required masks at event open.

Conceptual equations:

```systemverilog
mode_has_tdc =
    active_mode == MODE_TDC_ONLY ||
    active_mode == MODE_BOTH ||
    active_mode == MODE_CALIBRATION;

mode_has_position_packet =
    active_mode == MODE_POSITION_ONLY ||
    active_mode == MODE_BOTH;

mode_uses_matrix =
    active_mode == MODE_TDC_ONLY ||
    active_mode == MODE_POSITION_ONLY ||
    active_mode == MODE_BOTH;

required_tdc_mask =
    active_mode == MODE_CALIBRATION ? calib_axis_mask :
    mode_has_tdc                  ? 3'b111 :
                                    3'b000;

required_packet_mask = {
    mode_has_position_packet,
    required_tdc_mask
};

required_reset_ack_mask = {
    mode_uses_matrix && raw_snapshot_required,
    mode_uses_matrix ? required_tdc_mask : 3'b000
};

observed_reset_ack_mask = {
    raw_snapshot_valid,
    tdc_start_seen[2:0]
};
```

All masks above are frozen in event registers while `event_open` is true.

## Event Coordinator Ownership

`spadmic_event_coordinator` owns:

- active event state;
- frozen event grant;
- current event ID;
- required TDC mask;
- required packet mask;
- required reset-ack mask;
- completed packet mask;
- reset-start request;
- bundle-start request;
- event rejection/fault counters;
- event-safe idle indication.

It does not own:

- MPTDC conversion internals;
- raw matrix synchronization details;
- matrix reset pulse generation;
- matrix configuration clocking;
- final packet word serialization.

## Skew-Safe Grant

Before a matrix event, TOP computes a stable `pre_event_grant`.

For TDC modes the grant includes:

- required MPTDC axes ready and armed;
- snapshot/reset service available;
- output path safe for a new event;
- no active event;
- matrix configuration idle;
- global enable and active mode allow matrix events.

On first observed matrix activity, the coordinator latches:

- `event_open`;
- `event_granted`;
- `active_mode`;
- `required_tdc_mask`;
- `required_packet_mask`;
- `required_reset_ack_mask`;
- `event_id`.

During the event, per-axis START gates use only the frozen grant and frozen axis mask. They must not recompute a live `all_tdc_ready` gate after the first axis starts.

If the pre-event grant is false:

- all normal TDC START paths are blocked for that physical event;
- no partial normal TDC event is accepted;
- the raw matrix snapshot/reset path attempts to clear asserted lines if possible;
- a not-ready/rejected counter increments;
- no normal packet bundle is generated.

## Event Lifecycles

### TDC-Only

1. `ARMED`: wait for matrix activity while R/Y/B MPTDC axes are ready.
2. `EVENT_OPEN`: latch event ID and masks.
3. `WAIT_STARTS`: wait for required R/Y/B start confirmations.
4. `WAIT_SNAPSHOT`: wait for raw R/Y/B snapshot.
5. `RESET_ACTIVE`: start selective reset when snapshot and starts are seen.
6. `WAIT_PACKETS`: wait only for R/Y/B TDC packet pending.
7. `TRANSMIT_BUNDLE`: transmit contiguous R/Y/B bundle.
8. `WAIT_TX_DRAIN`: wait for arbiter/FIFO/DDR pairer idle.
9. `REARM`: require snapshot frontend rearm condition.

TDC-only never waits for the position queue, cluster scanner, or position packetizer.

### Position-Only

1. `ARMED`: MPTDC paths disabled.
2. `EVENT_OPEN`: detect and qualify matrix activity through the snapshot frontend.
3. Allocate/commit event ID when snapshot is accepted.
4. Reset may start when raw snapshot is valid.
5. Position packetizer consumes the frozen snapshot.
6. Wait only for position packet pending.
7. Transmit position packet, drain TX, rearm.

Position-only never waits for MPTDC ready, busy, armed, packet pending, or FIFO state.

### BOTH

1. `ARMED`: require R/Y/B MPTDC axes, position storage, snapshot/reset service, and output path ready.
2. `EVENT_OPEN`: latch frozen grant and masks.
3. Preserve R/Y/B physical skew through independent START paths.
4. Capture raw snapshot.
5. Reset starts after snapshot and all required TDC starts.
6. Wait for R/Y/B TDC packets and position packet.
7. Transmit the four-packet bundle contiguously.
8. Drain output and rearm.

No position salvage is added if a TDC resource is unavailable in BOTH. The event is rejected and matrix cleanup is attempted.

### Calibration

1. Matrix event paths are blocked.
2. Snapshot, position, and matrix auto-reset event flow are inactive.
3. Selected calibration axes drive MPTDC START/STOP muxes.
4. Required packet mask is selected calibration axes only.
5. Event ID is allocated when a selected calibration acquisition is accepted.
6. Unused axes and position must not block completion.

## Reset Architecture

Global chip reset:

- asserts asynchronously at the chip boundary;
- releases through local reset synchronizers per clock domain;
- clears matrix reset masks to zero, causing `Rz/Yz/Bz` to be all ones;
- forces matrix configuration outputs idle;
- forces TX valid low and data zero;
- clears requested/active control state to safe disabled defaults.

`clk_sys` remains running during normal recovery. The old reference design's broad gated-clock reset strategy is not used.

## Mode Transition Rules

Software writes requested controls. Hardware commits active controls only after old-mode resources are drained.

The transition sequence is:

1. Latch requested configuration if the write is legal.
2. Stop new event acceptance.
3. Preserve current active event.
4. Complete active matrix reset if any.
5. Drain packet sources required by the old active mode.
6. Drain arbiter, output FIFO, DDR16 pairer, and physical valid state.
7. Stop old-mode producers.
8. Commit requested active image.
9. Initialize new-mode ownership.
10. Reopen acceptance.

Inactive blocks in the new mode must not block `cfg_accept`. Blocks that belonged to the old mode must drain before the transition completes.

## Status And Faults

Phase 1 standalone blocks expose status to CSR integration:

- current event state;
- current event ID;
- required/completed packet masks;
- required/observed reset-ack masks;
- rejected-not-ready count;
- snapshot timeout count;
- reset disabled status;
- matrix-config busy status;
- output pressure status.

Fault bits are sticky W1C in the future CSR implementation. Fault counters saturate.

## Implemented Phase 4/5 RTL Status

The matrix-top shell now contains a first integrated event/output path:

- `spadmic_top_matrix_v1` instantiates the three existing `spadmic_tdc_axis_wrapper` blocks without changing protected MPTDC internals.
- The R/Y/B START gates are owned by TOP logic before the wrapper input. Before an event, they use the stable pre-event grant; after event open, they use the frozen `required_tdc_mask`.
- The START gate is one-shot per axis for one physical event. A held matrix line can deliver the first accepted START edge, but the corresponding axis gate closes after TOP-local `tdc_start_seen` is synchronized. This avoids repeated MPTDC conversions while preserving the first-arrival skew.
- `stop_armed_o` is not used as a pre-event ready signal because it responds to START; using it in the live grant can falsely reject the event at first START. It remains CSR/status-only until a stable wrapper-local acceptance signal is defined.
- `spadmic_event_coordinator` handles rejected/not-ready matrix activity as cleanup-only flow: it waits for raw snapshot, starts selective reset when enabled, waits for rearm, and emits no normal bundle.
- `spadmic_position_snapshot_packetizer` builds a 14-word raw position packet from the frozen snapshot. TDC-only remains independent of position packetization.
- `spadmic_event_bundle_tx` waits for all expected sources, drains only the latched source mask, patches every EOC with the coordinator-owned 14-bit event ID, and emits deterministic R/Y/B/POSITION order.
- `spadmic_ddr16_tx_pairer` is driven by the bundle stream and receives a bundle-end flush for odd-word padding.

Current limitations:

- Full cluster packetization is still in the legacy position block and is not yet snapshot-driven.
- Shared TDC max-hits and RO-code CSRs are not fully migrated into the matrix-top CSR endpoint.
- Position-only and TDC-only top-level flows are verified through the new matrix top shell. BOTH-mode top-level packet generation and the full directed R/Y/B skew campaign remain required.
