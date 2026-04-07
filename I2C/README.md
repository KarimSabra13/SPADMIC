# I2C — SPADMIC Configuration Interface

Low-speed configuration path from I2C into the SPADMIC `clk_sys` CSR domain.

## Modules

| Module | File | Purpose |
|--------|------|---------|
| `spadmic_i2c_slave` | `rtl/spadmic_i2c_slave.sv` | I2C slave FSM (7-bit addr, 16-bit reg addr, 32-bit data) |
| `spadmic_i2c_csr_bridge` | `rtl/spadmic_i2c_csr_bridge.sv` | I2C-to-CSR transaction bridge |

## I2C slave features

- 7-bit slave address (configurable via parameter)
- 16-bit register address (2-byte pointer)
- 32-bit data (4-byte read/write)
- 2-stage SCL/SDA synchronization into `clk_sys`
- ACK/NACK handling
- Operates entirely in the `clk_sys` (160 MHz) domain

## CSR interface contract

The bridge produces a clean request/response CSR bus:

```text
Request:  csr_req_valid, csr_req_write, csr_req_addr[15:0], csr_req_wdata[31:0], csr_req_ready
Response: csr_rsp_valid, csr_rsp_rdata[31:0], csr_rsp_err, csr_rsp_ready
```

## CSR address map

The address decoder (`spadmic_csr_decoder` in `TOP/rtl/`) uses bits `[11:8]` for region selection:

| Region | Bits [11:8] | Description |
|--------|-------------|-------------|
| GLOBAL | `4'h0` | Chip ID, version, global enable, status |
| TDC_X  | `4'h1` | TDC X-axis CSR registers |
| TDC_Y  | `4'h2` | TDC Y-axis CSR registers |
| TDC_Z  | `4'h3` | TDC Z-axis CSR registers |
| POSITION | `4'h4` | Position scanner CSR registers |

## Known limitations (v1)

- No burst mode
- Readback path is structured but not yet fully exercised
- Clock stretching not implemented
