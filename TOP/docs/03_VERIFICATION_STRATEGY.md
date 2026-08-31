# Verification Strategy

## Objectives

Verification targets the active `spadmic_top_matrix_v1` behavior and separates
four kinds of evidence:

1. generated-map consistency
2. directed block and integration behavior
3. end-to-end VIP, scoreboards, and assertions
4. Xcelium functional coverage

RTL verification does not substitute for synthesis or physical signoff.

## Directed layer

The directed suite checks retained datapaths plus the new ABI:

- router alignment, mapping, RO/WO/RW/W1C behavior
- global atomic enable and disabled/idle write policy
- shared R/Y/B configuration and calibration mask rules
- position cluster/raw configuration defaults and validation
- event, snapshot, and matrix-reset controls
- matrix config/readback and rejected commands
- TX status/fault/count behavior
- PLL/analog reset images and safe-write policy
- I2C pointer, repeated-start, current-pointer, partial-write, and reset-abort cases
- active matrix-top mode, reset, skew, snapshot, and FIFO-pressure behavior

`TOP/ci/run_directed_regression.sh` is the maintained directed manifest.

## VIP layer

The class-based VIP drives either the chip-realistic I2C path or a direct local
CSR path for fast scenarios. Both paths use 16-bit addresses and 32-bit data.
The DUT harness instantiates `spadmic_top_matrix_v1`.

The generator maintains an ABI configuration mirror for:

- global enable, mode, and R/Y/B masks
- shared TDC tuning and max hits
- position cluster/raw mode, gap, and minimum span
- snapshot timing and reset width

The event drivers generate coordinated R/Y/B events in normal modes. Named
calibration scenarios visit nonzero partial axis masks without weakening normal
mode requirements.

The TX monitor consumes each qualified low/high 16-bit DDR pair in logical word
order, parses packet boundaries/source/event ID, and sends complete packets to
the scoreboard. The scoreboard correlates expected R/Y/B and position packets
by shared event ID and checks reset observations.

## Assertions

`TOP/tb/vip/sva/spadmic_ctrl_sva.sv` binds to the active matrix top and checks
integration-level invariants, including:

- legal committed modes and masks
- disabled/idle configuration policy
- stable state after rejected writes
- nonzero reset width for enabled normal operation
- bounded CSR response behavior
- coordinated reset and event-control assumptions

The assertions intentionally do not restate the protected MPTDC internal proof
space.

## Functional coverage

Coverage is functional-only; there is no code-coverage target for this phase.
Maintained covergroups sample:

- every operating mode and R/Y/B calibration-mask class
- position cluster/raw and filter values
- legal and rejected control transitions
- every CSR access cause
- sticky fault set/clear and saturating counter activity
- event/reset lifecycle and reset-width classes
- packet source/kind/event-ID behavior

The Xcelium campaign is `TOP/ci/run_vip_coverage.sh`. A campaign pass requires
all tests to pass and the generated coverage database/reports to be retained for
bin review; a zero process return alone is insufficient evidence.

## Required negative tests

- misaligned and unmapped reads/writes
- writes to RO registers
- unsafe configuration while enabled or busy
- invalid mode/mask/reset/timing values
- 1-, 2-, and 3-byte I2C writes followed by STOP or repeated START
- `i2c_rst_i` during partial write, with CSR state preserved
- event reject, timeout, overlap, and reset-disabled faults
- matrix command reject and controller error
- TX missing source and FIFO overflow pressure

No false paths, multicycle exceptions, timeout relaxation, or functional waivers
may be introduced to make these tests pass.
