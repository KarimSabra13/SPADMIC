# I2C Block Guide

## `spadmic_i2c_slave`

This module owns the electrical protocol state:

- START, repeated START, and STOP recognition
- fixed-address match for `0x42`
- byte receive/transmit and ACK/NACK sequencing
- 16-bit pointer assembly
- 32-bit write assembly and read serialization
- current-pointer reads
- partial-write and reset-abort provenance

It does not decode CSR pages or decide whether a write is operationally safe.

## `spadmic_i2c_csr_bridge`

The bridge converts one completed I2C register operation into the internal
single-request CSR channel. It holds read data until the slave serializes all
four bytes and forwards the CSR error result to transport diagnostics.

## TOP-owned routing

`spadmic_matrix_top_csr` assembles:

- `spadmic_csr_router` for alignment, mapping, and access validation
- `spadmic_csr_system_bank`
- three `spadmic_csr_tdc_axis_bank` instances for R/Y/B
- position, event, matrix, TX, PLL, and analog banks

The router returns one bounded response for every request. An unmapped,
misaligned, or prohibited access cannot stall software and cannot modify a
block.

## Diagnostic ownership

The system bank records:

- sticky cause bits in `ACCESS_FAULT`
- last failing address, cause, and operation in `ACCESS_LAST_INFO`
- last failing write payload in `ACCESS_LAST_WDATA`
- a saturating count in `ACCESS_ERROR_COUNT`

Causes include misalignment, unmapped address, write to read-only register,
invalid value, unsafe write, incomplete write, and I2C reset abort.

`ACCESS_FAULT` is W1C. The counter can be cleared only by
`MAINT_CMD.CLEAR_ERROR_COUNTERS` while global acquisition is disabled and idle.

## Verification ownership

| Bench | Evidence |
| --- | --- |
| `tb_spadmic_i2c_control_plane_unit` | byte protocol, pointer/read/write, partial and reset aborts |
| `tb_spadmic_i2c_matrix_top_16b_unit` | I2C through router and banks |
| `tb_spadmic_matrix_top_csr_unit` | direct bank/access-policy behavior |
| VIP `i2c_end_to_end` | full active top and physical TX path |
