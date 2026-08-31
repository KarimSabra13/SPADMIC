# SPADMIC I2C Control Transport

The I2C block transports CSR ABI 1.0 requests for
`TOP/rtl/spadmic_top_matrix_v1.sv`. Register ownership remains in TOP; I2C does
not implement configuration policy.

## Wire contract

| Property | Value |
| --- | --- |
| 7-bit address | `0x42` |
| Bus rate | 100 kHz standard mode |
| Register pointer | 16-bit, MSB first, 4-byte aligned |
| Register data | 32-bit, MSB first |
| Read forms | pointer plus repeated START, or current pointer |
| Write form | pointer plus exactly four data bytes |
| Unsupported | stretch, IRQ, straps, burst, auto-increment |

A pointer-only write is valid and updates the current pointer. A STOP, repeated
START, or transport reset after only one to three data bytes discards the
partial value atomically and logs the incomplete access. No CSR side effect is
allowed from a partial write.

Invalid reads return zero and record the failing address/cause. Invalid writes
have no side effect and record the failure. The system access registers provide
the sticky fault, last failing operation, payload, and saturating count.

## Reset contract

`i2c_rst_i` resets only I2C protocol state. It does not clear CSR
configuration, sticky faults, block counters, or acquisition state. If reset
interrupts a partial data write, the discarded write is recorded after the
transport returns.

## RTL

| File | Role |
| --- | --- |
| `rtl/spadmic_i2c_slave.sv` | START/STOP/address/byte protocol engine |
| `rtl/spadmic_i2c_csr_bridge.sv` | transaction to local CSR request bridge |
| `../TOP/rtl/spadmic_csr_router.sv` | address and access validation |
| `../TOP/rtl/spadmic_csr_banks.sv` | software-visible register ownership |

## Verification

```bash
bash TOP/scripts/sim/run_tb.sh tb_spadmic_i2c_control_plane_unit --sim verilator
bash TOP/scripts/sim/run_tb.sh tb_spadmic_i2c_matrix_top_16b_unit --sim verilator
bash TOP/scripts/sim/run_vip_test.sh i2c_end_to_end --sim xrun
```

The full generated register map is `TOP/docs/csr/CSR_MAP.md`.
