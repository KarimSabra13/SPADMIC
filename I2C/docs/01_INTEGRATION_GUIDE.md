# SPADMIC I2C — Integration Guide

## Scope

This document explains how the active I2C block participates in the SPADMIC top-level control plane.

It is intentionally integration-focused. It does not try to turn the checked-in I2C logic into a generic reusable IP manual.

## 1. Active hierarchy

```text
spadmic_top_v1
  |- spadmic_i2c_slave
  |- spadmic_i2c_csr_bridge
  `- spadmic_csr_decoder
       |- spadmic_global_csr
       |- X-axis mptdc_top_asic CSR
       |- Y-axis mptdc_top_asic CSR
       |- Z-axis mptdc_top_asic CSR
       `- spadmic_position_block CSR
```

## 2. Transaction flow

### 2.1 Write

```text
START
device address + write
pointer high byte
pointer low byte
data byte 3
data byte 2
data byte 1
data byte 0
STOP
```

The slave emits one local transaction:

- `txn_valid_o = 1`
- `txn_write_o = 1`
- `txn_addr_o = pointer`
- `txn_wdata_o = packed 32-bit data`

### 2.2 Read

```text
START
device address + write
pointer high byte
pointer low byte
REPEATED START
device address + read
data byte 3
data byte 2
data byte 1
data byte 0
NACK
STOP
```

The slave first captures the pointer, then issues one local read transaction and waits for the CSR response before shifting the 32-bit payload back out.

## 3. Internal handshakes

### 3.1 Slave <-> bridge

The I2C slave uses:

- `txn_valid_o`
- `txn_write_o`
- `txn_addr_o`
- `txn_wdata_o`
- `txn_ready_i`
- `txn_rsp_valid_i`
- `txn_rsp_rdata_i`
- `txn_rsp_err_i`
- `txn_rsp_ready_o`

### 3.2 Bridge <-> top CSR fabric

The bridge maps those signals directly onto the local CSR bus:

```text
csr_req_valid / csr_req_write / csr_req_addr / csr_req_wdata / csr_req_ready
csr_rsp_valid / csr_rsp_rdata / csr_rsp_err / csr_rsp_ready
```

The bridge allows only one in-flight request, which keeps the control plane simple and deterministic.

## 4. Error behavior

### 4.1 Invalid region

If the CSR address selects no valid region, `spadmic_csr_decoder` returns:

- `csr_rsp_valid = 1`
- `csr_rsp_err = 1`
- `csr_rsp_rdata = 0`

### 4.2 Read timeout

If a valid region is selected but no read response arrives, the decoder waits until `WAIT_TIMEOUT_MAX` is reached and then returns:

- `csr_rsp_valid = 1`
- `csr_rsp_err = 1`
- `csr_rsp_rdata = 0`

In the active RTL, `WAIT_TIMEOUT_MAX = 15`, so the timeout fires after at most 16 `clk_sys` cycles in the read-wait state.

### 4.3 Write response

Writes complete immediately from the decoder side once the request has been accepted, because the target register blocks are simple ready/valid CSR endpoints.

## 5. Software-visible implications

1. I2C is a management path, not a runtime packet arbiter.
2. Register writes that request source or mode changes may still be rejected by the top-level global CSR if the datapath is not idle.
3. Software should inspect the global status/fault registers after control writes when it needs to know whether a requested image was accepted and then committed.

## 6. Address ownership

For the detailed register fields, use:

- [`../../TOP/docs/02_CSR_MAP.md`](../../TOP/docs/02_CSR_MAP.md) for `GLOBAL` and `POSITION`
- [`../../MPTDC/docs/03_CSR_MAP.md`](../../MPTDC/docs/03_CSR_MAP.md) for each per-axis TDC window
