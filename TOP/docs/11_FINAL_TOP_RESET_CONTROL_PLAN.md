# Final TOP Reset, Control, And Event Plan

Status: Phase 0 implementation plan. This document supersedes older TOP reset/control assumptions for the matrix-top integration work, but it does not by itself change RTL.

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
