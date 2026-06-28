# Final CSR Map Proposal

Status: Phase 3 proposal plus first implemented matrix-top CSR subset.

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

Current RTL warning:

- Active RTL still uses a 12-bit CSR address width in `TOP/rtl/spadmic_pkg.sv`, `TOP/rtl/spadmic_csr_decoder.sv`, and the I2C slave pointer storage.
- The 16-bit map below is the final target.
- Phase 3 has implemented a new matrix-top CSR endpoint at `TOP/rtl/spadmic_matrix_top_csr.sv`, but it deliberately keeps the current active 12-bit internal CSR width to avoid destabilizing the old top.
- Therefore the new matrix top currently decodes `0x0xx`, `0x5xx`, `0x6xx`, and `0x7xx` offsets. The final external `0x0000-0x7FFF` map still requires a later CSR/I2C address-width migration.
- `TOP/rtl/spadmic_top_v1.sv` still uses the legacy decoder path. The new implementation is scoped to `TOP/rtl/spadmic_top_matrix_v1.sv`.

## Phase 3 Implemented 12-Bit Matrix-Top CSR Subset

This table is the implemented subset for the new matrix top shell. It uses the low 12 address bits visible today through `spadmic_i2c_slave`.

| Address | Name | Access | Reset | Implemented behavior |
| --- | --- | --- | --- | --- |
| `0x000` | `GLOBAL_ID` | RO | `0x5350_4D54` | matrix-top ID `"SPMT"` |
| `0x004` | `GLOBAL_VERSION` | RO | `0x0005_0000` | matrix-top shell version |
| `0x020` | `MTOP_CTRL_REQUEST` | RW | disabled, axes `111`, auto-reset `1` | global enable, requested/active mode, axis mask, auto reset; writes accepted only when safe idle |
| `0x024` | `MTOP_CTRL_ACTIVE` | RO | disabled | active mode/control image |
| `0x028` | `MTOP_STATUS` | RO | `0` | safe idle, event/config/snapshot/reset/DDR status, current event ID |
| `0x02C` | `MTOP_FAULT` | W1C/RO | `0` | sticky faults and last CSR error code |
| `0x030` | `MTOP_FAULT_COUNT` | RO | `0` | saturating global fault count and config reject count |
| `0x500` | `MATRIX_EVENT_STATUS` | RW/RO | `0` | read masks/event ID; write bit 0 pulses snapshot clear |
| `0x504` | `MATRIX_SNAPSHOT_CFG` | RW | settle `2`, watchdog `64` | settle cycles `[15:0]`, watchdog cycles `[31:16]`; safe-idle write only |
| `0x508` | `MATRIX_RESET_CTRL` | RW | width `0`, auto-reset `1` | reset width `[15:0]`, auto-reset bit 16; rejected while event/reset busy |
| `0x50C` | `MATRIX_RESET_STATUS` | RO | `0` | reset/snapshot status and disabled-reset counter |
| `0x510-0x524` | `MATRIX_*_SNAP_*` | RO | `0` | last raw R/Y/B snapshots |
| `0x600` | `MATRIX_CFG_CMD` | RW/command | op `WRITE_COLUMN_64` | bit 0 START, bits `[3:1]` opcode; busy/invalid ops rejected in CSR |
| `0x604` | `MATRIX_CFG_STATUS` | RO | `0` | busy, done, error, last error, readback valid, cfg valid |
| `0x608` | `MATRIX_CFG_COL` | RW | `0` | selected column 0..43; invalid column rejected |
| `0x60C` | `MATRIX_CFG_WDATA_LO` | RW | `0` | write data `[31:0]`; rejected while config busy |
| `0x610` | `MATRIX_CFG_WDATA_HI` | RW | `0` | write data `[63:32]`; rejected while config busy |
| `0x614` | `MATRIX_CFG_RDATA_LO` | RO | `0` | config readback `[31:0]` |
| `0x618` | `MATRIX_CFG_RDATA_HI` | RO | `0` | config readback `[63:32]` |
| `0x61C` | `MATRIX_CFG_LAST_ERROR` | RO | `0` | matrix config last error, CSR last error, event reject count |
| `0x700` | `TX_STATUS` | RO | `empty` | DDR16 pairer empty/busy/pair/padded status |

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

Phase 4/5 additions in the active 12-bit implementation:

- `MTOP_CTRL_REQUEST` rejects partial axis masks for normal `TDC_ONLY` and `BOTH` modes. Those modes require `axis_mask=3'b111`.
- Partial axis masks remain legal in `CALIBRATION` mode.
- `TX_STATUS[4]` exposes bundle missing-source error.
- `TX_STATUS[5]` exposes raw position packetizer drop.
- `MATRIX_EVENT_STATUS[7:4]` reports the union of currently pending sources and bundle-completed sources.

Implemented tests:

- `TOP/tb/tb_spadmic_matrix_top_csr_unit.sv`
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
| `0x0000` | `GLOBAL_ID` | RO | implementation-defined | project/magic ID |
| `0x0004` | `GLOBAL_VERSION` | RO | implementation-defined | major/minor/patch/build |
| `0x0008` | `FEATURE_DISCOVERY` | RO | implementation-defined | mode bits, DDR16 present, matrix cfg present, CSR-only errors |
| `0x000C` | `GEOMETRY` | RO | `44/64` encoded | columns=44, lines=64, cfg_bits_per_col=64 |
| `0x0010` | `GLOBAL_CTRL_REQUEST` | RW | `0` | requested mode, requested enable, calibration axis mask, diagnostic axis mask |
| `0x0014` | `GLOBAL_CTRL_ACTIVE` | RO | `0` | active mode, active enable, active masks |
| `0x0018` | `GLOBAL_STATUS` | RO | `0` | safe_idle, cfg_accept, transition_busy, path_idle |
| `0x001C` | `GLOBAL_FAULT_STICKY` | W1C/RO | `0` | sticky global faults |
| `0x0020` | `LAST_CMD_ERROR` | W1C/RO | `0` | last rejected command/error code |
| `0x0024` | `GLOBAL_FAULT_COUNT` | RO | `0` | saturating fault count |

Writes to `GLOBAL_CTRL_REQUEST` are accepted only when the requested value is valid. Active image updates happen only through the mode-safe transition sequencer.

## Event Registers

| Address | Name | Access | Reset | Fields |
| --- | --- | --- | --- | --- |
| `0x0030` | `EVENT_STATE` | RO | IDLE | coordinator state |
| `0x0034` | `CURRENT_EVENT_ID` | RO | `0` | bits `[13:0]` current/last event ID |
| `0x0038` | `REQUIRED_PACKET_MASK` | RO | `0` | `{POSITION,B,Y,R}` |
| `0x003C` | `COMPLETED_PACKET_MASK` | RO | `0` | completed packet sources |
| `0x0040` | `REQUIRED_RESET_ACK_MASK` | RO | `0` | `{SNAPSHOT,B,Y,R}` |
| `0x0044` | `OBSERVED_RESET_ACK_MASK` | RO | `0` | observed reset prerequisites |
| `0x0048` | `EVENT_REJECT_COUNT` | RO | `0` | saturating rejected/not-ready count |
| `0x004C` | `EVENT_ACCEPT_COUNT` | RO | `0` | normal accepted event count |
| `0x0050` | `EVENT_ERROR_STATUS` | W1C/RO | `0` | missing source, incomplete bundle, invalid mode |

## Shared TDC Configuration

| Address | Name | Access | Reset | Fields |
| --- | --- | --- | --- | --- |
| `0x0060` | `TDC_SHARED_CFG_REQUEST` | RW | implementation-defined | shared max_hits and normal-axis policy |
| `0x0064` | `TDC_RO_SLOW_CODE_REQUEST` | RW | implementation-defined | shared slow RO code |
| `0x0068` | `TDC_RO_FAST_CODE_REQUEST` | RW | implementation-defined | shared fast RO code |
| `0x006C` | `TDC_SHARED_CFG_ACTIVE` | RO | reset default | committed active values |

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
| `0x5000` | `MATRIX_RESET_CTRL` | RW | `0` | auto reset enable, status clear |
| `0x5004` | `MATRIX_RESET_WIDTH` | RW | `0` | 16-bit width in `clk_sys` cycles |
| `0x5008` | `MATRIX_RESET_STATUS` | W1C/RO | `0` | busy, done, disabled, timeout, invalid image |
| `0x500C` | `MATRIX_RESET_COUNT` | RO | `0` | completed reset pulse count |
| `0x5010` | `LAST_R_SNAPSHOT_LO` | RO | `0` | R bits `[31:0]` |
| `0x5014` | `LAST_R_SNAPSHOT_HI` | RO | `0` | R bits `[63:32]` |
| `0x5018` | `LAST_Y_SNAPSHOT_LO` | RO | `0` | Y bits `[31:0]` |
| `0x501C` | `LAST_Y_SNAPSHOT_HI` | RO | `0` | Y bits `[63:32]` |
| `0x5020` | `LAST_B_SNAPSHOT_LO` | RO | `0` | B bits `[31:0]` |
| `0x5024` | `LAST_B_SNAPSHOT_HI` | RO | `0` | B bits `[63:32]` |
| `0x5028` | `SNAPSHOT_STATUS` | W1C/RO | `0` | valid, busy, timeout, overlap, rearm_ready |
| `0x502C` | `SNAPSHOT_COUNTERS` | RO | `0` | snapshot accepted/rejected/timeouts |

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
| `0x7004` | `TX_FIFO_LEVEL` | RO | `0` | logical 16-bit words in output FIFO |
| `0x7008` | `DDR16_PAIR_STATUS` | RO | `0` | pair valid, half full, empty, busy |
| `0x700C` | `TX_FAULT_STICKY` | W1C/RO | `0` | pressure, malformed packet, unsupported odd packet |
| `0x7010` | `TX_COUNTERS` | RO | `0` | transmitted words/pairs, pressure rejects |

Active Phase 4/5 12-bit `TX_STATUS` layout at `0x700`:

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
