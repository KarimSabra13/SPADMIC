# Final CSR Map Proposal

Status: CSR16 implementation proposal plus active matrix-top CSR subset.

## Control-Plane Rules

- I2C remains 100 kHz.
- Slave address remains `7'h42` unless a board/system reason changes it.
- External register pointer is documented as 16 bits.
- Data payload is 32 bits.
- No burst and no clock stretching are required in v1.
- Long operations use command/status registers.
- All registers reset to defaults on global chip reset.
- Dangerous writes while busy are rejected, set `LAST_CMD_ERROR`, and increment a saturating reject counter.
- Safe reads while busy are allowed.
- Fault bits are W1C. Fault counters saturate. Normal event counters may wrap.

Current RTL status:

- `TOP/rtl/spadmic_pkg.sv` now defines `SPADMIC_CSR_ADDR_W = 16`.
- `I2C/rtl/spadmic_i2c_slave.sv` now preserves the complete 16-bit external register pointer.
- `TOP/rtl/spadmic_matrix_top_csr.sv` decodes the active matrix-top CSR subset using full 16-bit addresses.
- `TOP/rtl/spadmic_top_matrix_v1.sv` is the active target for this CSR16 migration.
- `TOP/rtl/spadmic_top_v1.sv` remains protected and is not the matrix-top implementation target.
- `TOP/rtl/spadmic_csr_decoder.sv` is still the legacy top decoder and still has local legacy assumptions. Any legacy-top CSR migration must be a separate approved change.

## Implemented Matrix-Top CSR16 Subset

This table is the implemented subset for the new matrix top shell. Registers not listed here remain planned or reserved.

| Address | Name | Access | Reset | Implemented behavior |
| --- | --- | --- | --- | --- |
| `0x0000` | `GLOBAL_ID` | RO | `0x5350_4D54` | matrix-top ID `"SPMT"` |
| `0x0004` | `GLOBAL_VERSION` | RO | `0x0005_0000` | matrix-top shell version |
| `0x0008` | `MTOP_CTRL_REQUEST` | RW | disabled, axes `111`, auto-reset `1` | global enable, requested/active mode, normal axis mask, auto reset; writes accepted only when safe idle |
| `0x000C` | `MTOP_CTRL_ACTIVE` | RO | disabled | active mode/control image |
| `0x0010` | `MTOP_STATUS` | RO | `0` | safe idle, event/config/snapshot/reset/DDR status, current event ID |
| `0x0014` | `MTOP_FAULT` | W1C/RO | `0` | sticky faults and last CSR error code |
| `0x0018` | `MTOP_FAULT_COUNT` | RO | `0` | saturating global fault count and config reject count |
| `0x0020` | `SHARED_TDC_MAX_HITS` | RW | `15` | shared programmable MPTDC max-hits value broadcast to all three wrappers |
| `0x0024` | `SHARED_TDC_RO_SLOW_CODE` | RW | `0` | shared slow RO code broadcast to all three wrappers |
| `0x0028` | `SHARED_TDC_RO_FAST_CODE` | RW | `0` | shared fast RO code broadcast to all three wrappers |
| `0x002C` | `SHARED_TDC_CTRL` | WO/command | `0` | bit 0 soft reset pulse, bit 1 FIFO clear pulse; command accepted only at safe idle |
| `0x0030` | `CALIB_AXIS_MASK` | RW | `3'b111` | nonzero calibration-only required axis mask |
| `0x4000` | `POSITION_MODE` | RW | raw | raw/cluster mode request placeholder; final cluster integration is Phase 4 work |
| `0x5000` | `MATRIX_EVENT_STATUS` | RW/RO | `0` | read masks/event ID; write bit 0 pulses snapshot clear |
| `0x5004` | `MATRIX_SNAPSHOT_CFG` | RW | settle `2`, watchdog `64` | settle cycles `[15:0]`, watchdog cycles `[31:16]`; safe-idle write only |
| `0x5008` | `MATRIX_RESET_CTRL` | RW | width `0`, auto-reset `1` | reset width `[15:0]`, auto-reset bit 16; rejected while event/reset busy |
| `0x500C` | `MATRIX_RESET_STATUS` | RO | `0` | reset/snapshot status and disabled-reset counter |
| `0x5010-0x5024` | `MATRIX_*_SNAP_*` | RO | `0` | last raw R/Y/B snapshots |
| `0x6000` | `MATRIX_CFG_CMD` | RW/command | op `WRITE_COLUMN_64` | bit 0 START, bits `[3:1]` opcode; busy/invalid ops rejected in CSR |
| `0x6004` | `MATRIX_CFG_STATUS` | RO | `0` | busy, done, error, last error, readback valid, cfg valid |
| `0x6008` | `MATRIX_CFG_COL` | RW | `0` | selected column 0..43; invalid column rejected |
| `0x600C` | `MATRIX_CFG_WDATA_LO` | RW | `0` | write data `[31:0]`; rejected while config busy |
| `0x6010` | `MATRIX_CFG_WDATA_HI` | RW | `0` | write data `[63:32]`; rejected while config busy |
| `0x6014` | `MATRIX_CFG_RDATA_LO` | RO | `0` | config readback `[31:0]`; true Cout-based readback remains Phase 5 work |
| `0x6018` | `MATRIX_CFG_RDATA_HI` | RO | `0` | config readback `[63:32]`; true Cout-based readback remains Phase 5 work |
| `0x601C` | `MATRIX_CFG_LAST_ERROR` | RO | `0` | matrix config last error, CSR last error, event reject count |
| `0x7000` | `TX_STATUS` | RO | `empty` | DDR16 pairer empty/busy/pair/padded status |
| `0x7004` | `OUTPUT_FIFO_STATUS` | RO | `empty` | placeholder until the Phase 6 FIFO is inserted |
| `0x7008` | `OUTPUT_FIFO_WATERMARKS` | RO | depth/reservation | `MAX_EVENT_BUNDLE_WORDS=128`, `OUTPUT_FIFO_DEPTH=512` |

Implemented command error codes in `MTOP_FAULT[7:4]`:

| Code | Meaning |
| --- | --- |
| `0` | none |
| `1` | matrix config busy |
| `2` | invalid matrix config opcode |
| `3` | invalid matrix config column |
| `4` | path not safe/idle for requested write |
| `5` | unsupported address |
| `6` | invalid mode or illegal axis mask |
| `7` | invalid value |

Phase 4/5 additions in the active implementation:

- `MTOP_CTRL_REQUEST` rejects partial axis masks for normal `TDC_ONLY` and `BOTH` modes. Those modes require `axis_mask=3'b111`.
- Partial axis masks remain legal only through `CALIB_AXIS_MASK` in `CALIBRATION` mode.
- `TX_STATUS[4]` exposes bundle missing-source error.
- `TX_STATUS[5]` exposes raw position packetizer drop.
- `MATRIX_EVENT_STATUS[7:4]` reports the union of currently pending sources and bundle-completed sources.

Shared TDC configuration notes:

- One shared `max_hits`, one shared slow RO code, and one shared fast RO code feed all three MPTDC wrappers in `TOP/rtl/spadmic_top_matrix_v1.sv`.
- `max_hits` defaults to 15 and remains programmable through CSR/I2C.
- RO code `8'h00` is the reset/default value and may be used by software as the simplest clear policy.
- The exact RO code to frequency transfer function is not known in this repository state. The architectural target is approximately 700 MHz based on MPTDC documentation/evidence, but this CSR map does not claim any exact code-frequency equation.

Implemented tests:

- `TOP/tb/tb_spadmic_matrix_top_csr_unit.sv`
- `TOP/tb/tb_spadmic_i2c_control_plane_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`

## Address Regions

| Region | Purpose |
| --- | --- |
| `0x0000-0x0FFF` | GLOBAL, mode, event, shared TDC config, discovery |
| `0x1000-0x1FFF` | R TDC, legacy X |
| `0x2000-0x2FFF` | Y TDC |
| `0x3000-0x3FFF` | B TDC, legacy Z |
| `0x4000-0x4FFF` | POSITION |
| `0x5000-0x5FFF` | MATRIX EVENT, SNAPSHOT, RESET |
| `0x6000-0x6FFF` | MATRIX CONFIGURATION |
| `0x7000-0x7FFF` | TX, OUTPUT, DEBUG STATUS |

Unsupported addresses should return a clean target error if simple. They should not silently appear as implemented zero registers.

## Global Registers

| Address | Name | Access | Reset | Fields |
| --- | --- | --- | --- | --- |
| `0x0000` | `GLOBAL_ID` | RO | `0x5350_4D54` | matrix-top project/magic ID |
| `0x0004` | `GLOBAL_VERSION` | RO | `0x0005_0000` | matrix-top shell version |
| `0x0008` | `MTOP_CTRL_REQUEST` | RW | disabled, axes `111`, auto-reset `1` | global enable, requested mode, requested normal axis mask, auto-reset enable |
| `0x000C` | `MTOP_CTRL_ACTIVE` | RO | disabled, axes `111`, auto-reset `1` | active mode/control image |
| `0x0010` | `MTOP_STATUS` | RO | `0` | safe idle, event/snapshot/reset/config/output busy, current event ID |
| `0x0014` | `MTOP_FAULT` | W1C/RO | `0` | sticky faults `[3:0]`, last command error `[7:4]` |
| `0x0018` | `MTOP_FAULT_COUNT` | RO | `0` | global fault count `[15:0]`, config/event reject count `[31:16]` |
| `0x001C` | reserved discovery | RO | `0` | planned geometry/feature discovery expansion |

Writes to `MTOP_CTRL_REQUEST` are accepted only when the requested value is valid and the matrix-top path is safe idle. For v1, rejected writes do not mutate command or mode state.

## Event Registers

| Address | Name | Access | Reset | Fields |
| --- | --- | --- | --- | --- |
| `0x5000` | `MATRIX_EVENT_STATUS` | RW/RO | `0` | required packet mask, completed/pending packet mask, event ID; write bit 0 clears snapshot status |
| `0x5010-0x5024` | `LAST_*_SNAP_*` | RO | `0` | last raw R/Y/B snapshot words |
| planned | expanded event status | RO/W1C | `0` | coordinator state, reset-ack masks, accept/reject counters |

## Shared TDC Configuration

| Address | Name | Access | Reset | Fields |
| --- | --- | --- | --- | --- |
| `0x0020` | `SHARED_TDC_MAX_HITS` | RW | `15` | shared max-hits value to all R/Y/B wrappers |
| `0x0024` | `SHARED_TDC_RO_SLOW_CODE` | RW | `0` | shared slow RO code to all R/Y/B wrappers |
| `0x0028` | `SHARED_TDC_RO_FAST_CODE` | RW | `0` | shared fast RO code to all R/Y/B wrappers |
| `0x002C` | `SHARED_TDC_CTRL` | WO/command | `0` | bit 0 shared soft-reset pulse, bit 1 shared FIFO-clear pulse |
| `0x0030` | `CALIB_AXIS_MASK` | RW | `3'b111` | selected axes used only in calibration mode |

Final TOP presents one shared slow RO code and one shared fast RO code. Per-axis local idle shadows may remain inside wrappers close to MPTDC macros.

## Per-Axis TDC Registers

Each axis region uses the same offsets from its base:

| Offset | Name | Access | Fields |
| --- | --- | --- | --- |
| `0x000` | `TDC_AXIS_CTRL_DIAG` | RW | diagnostic enable, calibration control, soft clear if allowed |
| `0x004` | `TDC_AXIS_STATUS` | RO | ready, busy, armed, stop_armed, start_seen_last |
| `0x008` | `TDC_AXIS_FIFO_STATUS` | RO | packet_pending, fifo_full, fifo_empty |
| `0x00C` | `TDC_AXIS_WATCHDOG_STATUS` | W1C/RO | watchdog flag and recovery status |
| `0x010` | `TDC_AXIS_COUNTERS` | RO | conversions, rejects, watchdog trips |
| `0x014` | `TDC_AXIS_LAST_FLAGS` | RO | last packet/status flags |

Normal SPAD modes use all three axes. Per-axis enable writes are diagnostic/calibration only and must not create partial normal SPAD events.

## Position Registers

| Address | Name | Access | Reset | Fields |
| --- | --- | --- | --- | --- |
| `0x4000` | `POSITION_CTRL_REQUEST` | RW | cluster defaults | cluster/raw mode, packet enable request |
| `0x4004` | `POSITION_STATUS` | RO | `0` | busy, queue level, queue full, raw valid |
| `0x4008` | `POSITION_SETTLE_WATCHDOG_CFG` | RW | settle default and watchdog 64 | settle cycles, watchdog cycles |
| `0x400C` | `POSITION_QUEUE_STATUS` | RO | `0` | queue occupancy/drop pending |
| `0x4010` | `POSITION_COUNTERS` | RO | `0` | accepted, dropped, invalid, timeout |
| `0x4020-0x4034` | `POSITION_LAST_RAW_*` | RO | `0` | optional last raw R/Y/B snapshot |

The RTL/documentation event-count width mismatch must be corrected during position integration. Final physical event ID is 14 bits and is owned by the event coordinator.

## Matrix Reset And Snapshot Registers

| Address | Name | Access | Reset | Fields |
| --- | --- | --- | --- | --- |
| `0x5004` | `MATRIX_SNAPSHOT_CFG` | RW | settle `2`, watchdog `64` | settle cycles `[15:0]`, watchdog cycles `[31:16]` |
| `0x5008` | `MATRIX_RESET_CTRL` | RW | width `0`, auto-reset `1` | 16-bit width in `clk_sys` cycles and auto-reset enable |
| `0x500C` | `MATRIX_RESET_STATUS` | RO | `0` | snapshot/reset status and disabled-reset count |
| `0x5010` | `LAST_R_SNAPSHOT_LO` | RO | `0` | R bits `[31:0]` |
| `0x5014` | `LAST_R_SNAPSHOT_HI` | RO | `0` | R bits `[63:32]` |
| `0x5018` | `LAST_Y_SNAPSHOT_LO` | RO | `0` | Y bits `[31:0]` |
| `0x501C` | `LAST_Y_SNAPSHOT_HI` | RO | `0` | Y bits `[63:32]` |
| `0x5020` | `LAST_B_SNAPSHOT_LO` | RO | `0` | B bits `[31:0]` |
| `0x5024` | `LAST_B_SNAPSHOT_HI` | RO | `0` | B bits `[63:32]` |
| planned | `SNAPSHOT_COUNTERS` | RO | `0` | snapshot accepted/rejected/timeouts |

If `MATRIX_RESET_WIDTH=0`, automatic selective reset is disabled. In matrix modes this is diagnostic/single-shot behavior unless external/global recovery clears the matrix.

## Matrix Configuration Registers

| Address | Name | Access | Reset | Fields |
| --- | --- | --- | --- | --- |
| `0x6000` | `MATRIX_CFG_CMD` | WO/command | `0` | START and opcode |
| `0x6004` | `MATRIX_CFG_STATUS` | W1C/RO | `0` | busy, done, error, readback_valid, cfg_valid |
| `0x6008` | `MATRIX_CFG_COLUMN` | RW | `0` | selected column `0..43` |
| `0x600C` | `MATRIX_CFG_WDATA_LO` | RW | `0` | write data `[31:0]` |
| `0x6010` | `MATRIX_CFG_WDATA_HI` | RW | `0` | write data `[63:32]` |
| `0x6014` | `MATRIX_CFG_RDATA_LO` | RO | `0` | readback `[31:0]` |
| `0x6018` | `MATRIX_CFG_RDATA_HI` | RO | `0` | readback `[63:32]` |
| `0x601C` | `MATRIX_CFG_LAST_ERROR` | W1C/RO | `0` | busy, invalid op, invalid column, CDC fault |
| `0x6020` | `MATRIX_CFG_REJECT_COUNT` | RO | `0` | saturating rejected command count |

Command opcodes:

- `0`: NOP
- `1`: `WRITE_COLUMN_64`
- `2`: `READ_COLUMN_64`
- `3`: `GLOBAL_FILL_0`
- `4`: `GLOBAL_FILL_1`

The `clk_sys` side snapshots parameters before toggling the CDC request. The `clk_cfg_40m` side samples the stable command-hold bus only after synchronizing the request toggle. Return data is held stable until consumed.

## TX Registers

| Address | Name | Access | Reset | Fields |
| --- | --- | --- | --- | --- |
| `0x7000` | `TX_STATUS` | RO | `0` | output idle, fifo empty/full, ddr pairer empty |
| `0x7004` | `OUTPUT_FIFO_STATUS` | RO | `0` | placeholder until Phase 6 FIFO insertion |
| `0x7008` | `OUTPUT_FIFO_WATERMARKS` | RO | depth/reservation | event reservation and FIFO depth |
| `0x700C` | `TX_FAULT_STICKY` | W1C/RO | `0` | pressure, malformed packet, unsupported odd packet |
| `0x7010` | `TX_COUNTERS` | RO | `0` | transmitted words/pairs, pressure rejects |

Active `TX_STATUS` layout at `0x7000`:

| Bits | Field |
| --- | --- |
| `[0]` | DDR16 pairer empty |
| `[1]` | DDR16 pairer busy |
| `[2]` | DDR16 pair valid |
| `[3]` | DDR16 padded odd bundle word |
| `[4]` | bundle missing source |
| `[5]` | position packetizer drop |

## Software Sequences

### Power-Up

1. Release chip reset after clocks are stable.
2. Read ID/version/geometry.
3. Program `MATRIX_RESET_WIDTH`.
4. Program shared TDC settings.
5. Program position settings.
6. Program matrix configuration using command/status.
7. Confirm `matrix_cfg_valid`.
8. Write requested mode and global enable.
9. Poll active mode and safe-idle/status as needed.

### Matrix Configuration Command

1. Write column and WDATA registers.
2. Write `MATRIX_CFG_CMD.START` with opcode.
3. Poll `MATRIX_CFG_STATUS.busy`.
4. Read status/error.
5. Read RDATA registers when readback is valid.

### Fault Handling

1. Read sticky fault registers.
2. Read counters and last error.
3. Write ones to clear W1C sticky bits.
4. Use global reset only for unrecoverable stream/malformed state.
