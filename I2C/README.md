# I2C — SPADMIC Configuration Interface

Author: Karim Sabra

Low-speed configuration path from the I2C pins into the `clk_sys` CSR fabric used by the SPADMIC top.

## Active role

The I2C block is an integration-facing control plane, not a standalone data-path IP. In the active top:

1. `spadmic_i2c_slave` decodes pointer-based 32-bit register reads and writes.
2. `spadmic_i2c_csr_bridge` converts those transactions into the local CSR request/response channel.
3. `spadmic_csr_decoder` in `TOP/rtl/` routes the request to the global, per-axis TDC, or position CSR region.

## Modules

| Module | File | Purpose |
|--------|------|---------|
| `spadmic_i2c_slave` | `rtl/spadmic_i2c_slave.sv` | Synchronized 7-bit-address I2C slave with 16-bit register pointer and 32-bit data payload |
| `spadmic_i2c_csr_bridge` | `rtl/spadmic_i2c_csr_bridge.sv` | One-outstanding-transaction bridge from the I2C transaction channel to the local CSR handshake |

## Bus model

### I2C side

- 7-bit slave address, parameterized by `SPADMIC_I2C_ADDR`
- 16-bit register pointer
- 32-bit write payloads
- 32-bit read payloads
- repeated-start read support
- no burst mode
- no clock stretching

### Local CSR side

```text
Request : csr_req_valid, csr_req_write, csr_req_addr[11:0], csr_req_wdata[31:0], csr_req_ready
Response: csr_rsp_valid, csr_rsp_rdata[31:0], csr_rsp_err, csr_rsp_ready
```

The bridge allows only one outstanding request at a time. The transaction is complete only after the CSR response has been captured and handed back to the I2C slave.

## End-to-end response behavior

- writes receive an immediate empty success response from the CSR fabric once the target region accepts the request
- reads wait for the selected region to return `csr_rvalid`
- invalid regions return `csr_rsp_err = 1`
- the shared CSR decoder times out stalled reads after `16` `clk_sys` cycles (`WAIT_TIMEOUT_MAX = 15`) and returns `csr_rsp_err = 1`

That timeout behavior lives in `TOP/rtl/spadmic_csr_decoder.sv`, but it is part of the end-to-end software-visible I2C contract.

## Address regions

The shared SPADMIC decoder uses bits `[11:8]` of the 12-bit CSR address:

| Region | Bits `[11:8]` | Description |
|--------|---------------|-------------|
| `GLOBAL` | `4'h0` | Chip ID, version, requested control image, active status, fault counters |
| `TDC_X` | `4'h1` | X-axis TOP-owned `mptdc_axis_core` CSR window |
| `TDC_Y` | `4'h2` | Y-axis TOP-owned `mptdc_axis_core` CSR window |
| `TDC_Z` | `4'h3` | Z-axis TOP-owned `mptdc_axis_core` CSR window |
| `POSITION` | `4'h4` | Position-block configuration and status registers |

See [`TOP/docs/02_CSR_MAP.md`](../TOP/docs/02_CSR_MAP.md) for the detailed global and position register fields.

## Documentation map

| Document | Purpose |
|----------|---------|
| [`README.md`](README.md) | Quick integration-facing contract |
| [`docs/01_INTEGRATION_GUIDE.md`](docs/01_INTEGRATION_GUIDE.md) | Detailed transaction flow, error handling, and top-level integration notes |
| [`docs/02_BLOCK_GUIDE.md`](docs/02_BLOCK_GUIDE.md) | Block-by-block guide to the I2C slave, CSR bridge, and end-to-end control-plane contract |

## Known limits

- no burst transfers
- no clock stretching
- one outstanding CSR transaction at a time
- no attempt to arbitrate live datapath control in hardware from I2C; I2C is a management/configuration path only
