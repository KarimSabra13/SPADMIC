# SPADMIC I2C — Block Guide

Author: Karim Sabra

## Scope

This is the block-by-block guide for the SPADMIC I2C control path.

The I2C directory is intentionally small. The point of this document is not to
invent complexity; it is to make the integration contract explicit.

## 1. Active control-path map

```text
I2C pins
  -> spadmic_i2c_slave
  -> spadmic_i2c_csr_bridge
  -> TOP/rtl/spadmic_csr_decoder
  -> global / X / Y / Z / position CSR blocks
```

Only the first two modules live in `I2C/rtl/`, but the third block is part of
the end-to-end software-visible behavior and is therefore documented here too.

## 2. Module summary

| Block | File | Domain | Role |
|-------|------|--------|------|
| `spadmic_i2c_slave` | `rtl/spadmic_i2c_slave.sv` | `clk_sys`-synchronized view of SCL/SDA | decode pointer-based I2C reads/writes and emit local transactions |
| `spadmic_i2c_csr_bridge` | `rtl/spadmic_i2c_csr_bridge.sv` | `clk_sys` | convert I2C transactions into the local CSR request/response handshake |
| `spadmic_csr_decoder` | `../TOP/rtl/spadmic_csr_decoder.sv` | `clk_sys` | route requests to the correct CSR region and bound read latency |

## 3. `spadmic_i2c_slave`

### What it owns

This block owns the pin-facing protocol work:

- double-synchronizing `i2c_scl_i` and `i2c_sda_i` into `clk_sys`
- detecting START and STOP conditions
- decoding the 7-bit device address plus R/W bit
- capturing the 16-bit register pointer
- collecting or transmitting the 32-bit data payload
- generating ACK timing correctly on SDA

### Why it is written this way

The slave is not a generic high-feature I2C controller. It is a deliberately
small control-plane frontend for SPADMIC:

- one pointer per transaction
- one 32-bit payload
- repeated-start reads
- no burst mode
- no clock stretching

That keeps the off-chip programming model simple and maps cleanly onto the local
CSR fabric.

### Key internal state groups

The slave FSM naturally splits into:

1. address phase
2. pointer capture phase
3. write-data capture phase or read-response phase
4. ACK handling states

One subtle but important behavior is the ACK hold timing: the design keeps ACK
driven across the full SCL-high phase and only releases SDA on the following
SCL-low phase, which avoids self-generated false STOP conditions.

## 4. `spadmic_i2c_csr_bridge`

### What it owns

The bridge is the contract translator between:

- the transaction-style outputs of the I2C slave
- the local ready/valid CSR handshake used by the TOP

It accepts one command, waits for one response, and then returns that response to
the slave.

### Why only one outstanding transaction exists

The block is intentionally single-issue:

1. the I2C side is already pointer-based and serialized
2. the TOP CSR fabric is simple and deterministic
3. the software-visible behavior is easier to reason about

That means the bridge becomes a tiny three-state machine instead of a queueing
subsystem.

## 5. `spadmic_csr_decoder` in the end-to-end path

Although it is not part of the `I2C/` directory, the decoder completes the I2C
software contract.

It is responsible for:

- choosing the CSR region from address bits `[11:8]`
- returning an immediate error on invalid regions
- timing out stalled reads instead of letting the I2C side wait forever

So when software observes an errored I2C read, the root cause may be:

1. invalid region selection
2. stalled valid region
3. target block returning an error

## 6. End-to-end behavior by operation

### Write

```text
I2C write frame
  -> slave captures pointer + data
  -> bridge emits one CSR write request
  -> decoder routes it
  -> response returns immediately when accepted
```

### Read

```text
pointer write / repeated-start read
  -> slave captures pointer
  -> bridge emits one CSR read request
  -> decoder routes it and waits
  -> returned 32-bit value is shifted back out over I2C
```

## 7. Limits and non-goals

| Item | Current behavior |
|------|------------------|
| addressing | one 7-bit slave address |
| register pointer | 16-bit pointer, narrowed to the local CSR width |
| data width | 32-bit read/write payload |
| burst transfers | not supported |
| clock stretching | not supported |
| outstanding requests | one at a time |
| runtime flow control | not part of this block; this is a management path only |

## 8. Debug checklist

If an I2C access fails, check in this order:

1. device address match in `spadmic_i2c_slave`
2. pointer capture and repeated-start behavior
3. bridge stuck in `ST_WAIT_RSP`
4. decoder region selection
5. decoder timeout path
6. target CSR block response

## 9. Cross-reference

- [`01_INTEGRATION_GUIDE.md`](01_INTEGRATION_GUIDE.md)
- [`../../TOP/docs/02_CSR_MAP.md`](../../TOP/docs/02_CSR_MAP.md)
