// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_csr_map_pkg.sv
// Purpose  : Authoritative SPADMIC CSR ABI 1.0 address and access contract.
//
// The CSR_MAP records below are parsed by TOP/scripts/generate_csr_map.py.
// Keep the record and matching localparam on adjacent lines.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

package spadmic_csr_map_pkg;
  localparam logic [31:0] SPADMIC_CHIP_ID_VALUE = 32'h5350_4D54;
  localparam logic [31:0] SPADMIC_CSR_ABI_VERSION_VALUE = 32'h0001_0000;

  typedef enum logic [7:0] {
    CSR_CAUSE_NONE             = 8'h00,
    CSR_CAUSE_MISALIGNED       = 8'h01,
    CSR_CAUSE_UNMAPPED         = 8'h02,
    CSR_CAUSE_READ_ONLY_WRITE  = 8'h03,
    CSR_CAUSE_INVALID_VALUE    = 8'h04,
    CSR_CAUSE_UNSAFE_WRITE     = 8'h05,
    CSR_CAUSE_INCOMPLETE_WRITE = 8'h06,
    CSR_CAUSE_I2C_RESET_ABORT  = 8'h07
  } spadmic_csr_cause_e;

  // CSR_MAP: CHIP_ID|0x0000|RO|0x53504D54|System|SPADMIC matrix-top identity
  localparam logic [15:0] CSR_CHIP_ID = 16'h0000;
  // CSR_FIELD: CHIP_ID|IDENTITY|0|32|RO|ASCII identity value 0x53504D54
  // CSR_MAP: ABI_VERSION|0x0004|RO|0x00010000|System|CSR ABI major and minor version
  localparam logic [15:0] CSR_ABI_VERSION = 16'h0004;
  // CSR_FIELD: ABI_VERSION|MINOR|0|16|RO|ABI minor version
  // CSR_FIELD: ABI_VERSION|MAJOR|16|16|RO|ABI major version
  // CSR_MAP: GLOBAL_CTRL|0x0008|RW|0x000000F0|System|Atomic enable mode normal-axis-mask and auto-reset control
  localparam logic [15:0] CSR_GLOBAL_CTRL = 16'h0008;
  // CSR_FIELD: GLOBAL_CTRL|ENABLE|0|1|RW|Global acquisition enable; must agree with MODE
  // CSR_FIELD: GLOBAL_CTRL|MODE|1|3|RW|0 disabled, 1 TDC, 2 position, 3 both, 4 calibration
  // CSR_FIELD: GLOBAL_CTRL|AXIS_MASK|4|3|RW|Normal R Y B enable mask; TDC and both require 0x7
  // CSR_FIELD: GLOBAL_CTRL|AUTO_RESET_ENABLE|7|1|RW|Enable automatic matrix reset after an event
  // CSR_MAP: GLOBAL_STATUS|0x000C|RO|0x00000000|System|Active mode axis and global idle status
  localparam logic [15:0] CSR_GLOBAL_STATUS = 16'h000C;
  // CSR_FIELD: GLOBAL_STATUS|ENABLE|0|1|RO|Active global acquisition enable
  // CSR_FIELD: GLOBAL_STATUS|MODE|1|3|RO|Active operating mode encoding
  // CSR_FIELD: GLOBAL_STATUS|AXIS_MASK|4|3|RO|Active R Y B axis mask
  // CSR_FIELD: GLOBAL_STATUS|SAFE_IDLE|7|1|RO|All controlled datapaths are idle and configuration-safe
  // CSR_MAP: GLOBAL_FAULT|0x0010|RO|0x00000000|System|OR summary of sticky page faults
  localparam logic [15:0] CSR_GLOBAL_FAULT = 16'h0010;
  // CSR_FIELD: GLOBAL_FAULT|ACCESS|0|1|RO|System access-protocol fault summary
  // CSR_FIELD: GLOBAL_FAULT|TDC|1|1|RO|OR of R Y and B TDC fault summaries
  // CSR_FIELD: GLOBAL_FAULT|POSITION|2|1|RO|Position page fault summary
  // CSR_FIELD: GLOBAL_FAULT|EVENT|3|1|RO|Event page fault summary
  // CSR_FIELD: GLOBAL_FAULT|MATRIX|4|1|RO|Matrix page fault summary
  // CSR_FIELD: GLOBAL_FAULT|TX|5|1|RO|TX page fault summary
  // CSR_FIELD: GLOBAL_FAULT|PLL|6|1|RO|PLL page fault summary
  // CSR_MAP: MAINT_CMD|0x0014|WO|0x00000000|System|Disabled-idle maintenance commands
  localparam logic [15:0] CSR_MAINT_CMD = 16'h0014;
  // CSR_FIELD: MAINT_CMD|CLEAR_ERROR_COUNTERS|0|1|WO|Clear all saturating error counters while disabled and idle
  // CSR_MAP: TDC_SHARED_CFG|0x0018|RW|0x0000000F|System|Shared max-hits and RO tuning codes
  localparam logic [15:0] CSR_TDC_SHARED_CFG = 16'h0018;
  // CSR_FIELD: TDC_SHARED_CFG|MAX_HITS|0|4|RW|Shared nonzero maximum hit count from 1 through 15
  // CSR_FIELD: TDC_SHARED_CFG|RO_SLOW_CODE|8|8|RW|Shared slow-ring oscillator tuning code
  // CSR_FIELD: TDC_SHARED_CFG|RO_FAST_CODE|16|8|RW|Shared fast-ring oscillator tuning code
  // CSR_MAP: TDC_SHARED_CMD|0x001C|WO|0x00000000|System|Shared soft-reset and FIFO-clear pulses
  localparam logic [15:0] CSR_TDC_SHARED_CMD = 16'h001C;
  // CSR_FIELD: TDC_SHARED_CMD|SOFT_RESET|0|1|WO|Pulse soft reset to all three TDC axes
  // CSR_FIELD: TDC_SHARED_CMD|FIFO_CLEAR|1|1|WO|Pulse FIFO clear to all three TDC axes
  // CSR_MAP: CALIB_AXIS_MASK|0x0020|RW|0x00000007|System|Nonzero calibration-only axis mask
  localparam logic [15:0] CSR_CALIB_AXIS_MASK = 16'h0020;
  // CSR_FIELD: CALIB_AXIS_MASK|AXIS_MASK|0|3|RW|Nonzero calibration mask; bit 0 R, bit 1 Y, bit 2 B
  // CSR_MAP: ACCESS_STATUS|0x0024|RO|0x00000000|System|Last access validity and operation summary
  localparam logic [15:0] CSR_ACCESS_STATUS = 16'h0024;
  // CSR_FIELD: ACCESS_STATUS|FAULT_PENDING|0|1|RO|At least one ACCESS_FAULT bit is set
  // CSR_FIELD: ACCESS_STATUS|LAST_OPERATION_WRITE|1|1|RO|Last failing access was a write
  // CSR_FIELD: ACCESS_STATUS|LAST_CAUSE|8|8|RO|Cause code for the last failing access
  // CSR_MAP: ACCESS_FAULT|0x0028|W1C|0x00000000|System|Sticky access-protocol fault bits
  localparam logic [15:0] CSR_ACCESS_FAULT = 16'h0028;
  // CSR_FIELD: ACCESS_FAULT|MISALIGNED|0|1|W1C|Misaligned 16-bit register pointer
  // CSR_FIELD: ACCESS_FAULT|UNMAPPED|1|1|W1C|Unmapped register address
  // CSR_FIELD: ACCESS_FAULT|READ_ONLY_WRITE|2|1|W1C|Write attempted to a read-only register
  // CSR_FIELD: ACCESS_FAULT|INVALID_VALUE|3|1|W1C|Field encoding or value violated its contract
  // CSR_FIELD: ACCESS_FAULT|UNSAFE_WRITE|4|1|W1C|Write attempted outside its disabled-idle window
  // CSR_FIELD: ACCESS_FAULT|INCOMPLETE_WRITE|5|1|W1C|I2C STOP or repeated START discarded a partial data word
  // CSR_FIELD: ACCESS_FAULT|I2C_RESET_ABORT|6|1|W1C|I2C transport reset discarded a partial data word
  // CSR_MAP: ACCESS_LAST_INFO|0x002C|RO|0x00000000|System|Last failing address cause and operation
  localparam logic [15:0] CSR_ACCESS_LAST_INFO = 16'h002C;
  // CSR_FIELD: ACCESS_LAST_INFO|ADDRESS|0|16|RO|Register pointer for the last failing access
  // CSR_FIELD: ACCESS_LAST_INFO|CAUSE|16|8|RO|Cause code for the last failing access
  // CSR_FIELD: ACCESS_LAST_INFO|WRITE|24|1|RO|One for a failed write and zero for a failed read
  // CSR_MAP: ACCESS_LAST_WDATA|0x0030|RO|0x00000000|System|Last failing write payload
  localparam logic [15:0] CSR_ACCESS_LAST_WDATA = 16'h0030;
  // CSR_FIELD: ACCESS_LAST_WDATA|WRITE_DATA|0|32|RO|Payload assembled for the last failing write
  // CSR_MAP: ACCESS_ERROR_COUNT|0x0034|RO|0x00000000|System|Saturating invalid-access counter
  localparam logic [15:0] CSR_ACCESS_ERROR_COUNT = 16'h0034;
  // CSR_FIELD: ACCESS_ERROR_COUNT|COUNT|0|32|RO|Saturating count of invalid CSR and I2C accesses

  // CSR_MAP: TDC_R_STATUS|0x1000|RO|0x00000000|TDC R|R-axis readiness activity and FIFO status
  localparam logic [15:0] CSR_TDC_R_STATUS = 16'h1000;
  // CSR_FIELD: TDC_R_STATUS|READY|0|1|RO|R-axis accepts a new event
  // CSR_FIELD: TDC_R_STATUS|BUSY|1|1|RO|R-axis conversion is active
  // CSR_FIELD: TDC_R_STATUS|FIFO_FULL|2|1|RO|R-axis local FIFO is full
  // CSR_FIELD: TDC_R_STATUS|STOP_ARMED|3|1|RO|R-axis stop capture is armed
  // CSR_FIELD: TDC_R_STATUS|PACKET_ACTIVE|4|1|RO|R-axis packet emission is active
  // CSR_FIELD: TDC_R_STATUS|PACKET_PENDING|5|1|RO|R-axis packet is pending
  // CSR_FIELD: TDC_R_STATUS|PAGE_ID|8|4|RO|Page discriminator value 1
  // CSR_MAP: TDC_R_FAULT|0x1004|W1C|0x00000000|TDC R|R-axis sticky FIFO-full fault
  localparam logic [15:0] CSR_TDC_R_FAULT = 16'h1004;
  // CSR_FIELD: TDC_R_FAULT|FIFO_FULL|0|1|W1C|Sticky R-axis FIFO-full edge
  // CSR_MAP: TDC_R_ERROR_COUNT|0x1008|RO|0x00000000|TDC R|R-axis saturating FIFO-full counter
  localparam logic [15:0] CSR_TDC_R_ERROR_COUNT = 16'h1008;
  // CSR_FIELD: TDC_R_ERROR_COUNT|COUNT|0|32|RO|Saturating R-axis FIFO-full edge count
  // CSR_MAP: TDC_Y_STATUS|0x2000|RO|0x00000000|TDC Y|Y-axis readiness activity and FIFO status
  localparam logic [15:0] CSR_TDC_Y_STATUS = 16'h2000;
  // CSR_FIELD: TDC_Y_STATUS|READY|0|1|RO|Y-axis accepts a new event
  // CSR_FIELD: TDC_Y_STATUS|BUSY|1|1|RO|Y-axis conversion is active
  // CSR_FIELD: TDC_Y_STATUS|FIFO_FULL|2|1|RO|Y-axis local FIFO is full
  // CSR_FIELD: TDC_Y_STATUS|STOP_ARMED|3|1|RO|Y-axis stop capture is armed
  // CSR_FIELD: TDC_Y_STATUS|PACKET_ACTIVE|4|1|RO|Y-axis packet emission is active
  // CSR_FIELD: TDC_Y_STATUS|PACKET_PENDING|5|1|RO|Y-axis packet is pending
  // CSR_FIELD: TDC_Y_STATUS|PAGE_ID|8|4|RO|Page discriminator value 2
  // CSR_MAP: TDC_Y_FAULT|0x2004|W1C|0x00000000|TDC Y|Y-axis sticky FIFO-full fault
  localparam logic [15:0] CSR_TDC_Y_FAULT = 16'h2004;
  // CSR_FIELD: TDC_Y_FAULT|FIFO_FULL|0|1|W1C|Sticky Y-axis FIFO-full edge
  // CSR_MAP: TDC_Y_ERROR_COUNT|0x2008|RO|0x00000000|TDC Y|Y-axis saturating FIFO-full counter
  localparam logic [15:0] CSR_TDC_Y_ERROR_COUNT = 16'h2008;
  // CSR_FIELD: TDC_Y_ERROR_COUNT|COUNT|0|32|RO|Saturating Y-axis FIFO-full edge count
  // CSR_MAP: TDC_B_STATUS|0x3000|RO|0x00000000|TDC B|B-axis readiness activity and FIFO status
  localparam logic [15:0] CSR_TDC_B_STATUS = 16'h3000;
  // CSR_FIELD: TDC_B_STATUS|READY|0|1|RO|B-axis accepts a new event
  // CSR_FIELD: TDC_B_STATUS|BUSY|1|1|RO|B-axis conversion is active
  // CSR_FIELD: TDC_B_STATUS|FIFO_FULL|2|1|RO|B-axis local FIFO is full
  // CSR_FIELD: TDC_B_STATUS|STOP_ARMED|3|1|RO|B-axis stop capture is armed
  // CSR_FIELD: TDC_B_STATUS|PACKET_ACTIVE|4|1|RO|B-axis packet emission is active
  // CSR_FIELD: TDC_B_STATUS|PACKET_PENDING|5|1|RO|B-axis packet is pending
  // CSR_FIELD: TDC_B_STATUS|PAGE_ID|8|4|RO|Page discriminator value 3
  // CSR_MAP: TDC_B_FAULT|0x3004|W1C|0x00000000|TDC B|B-axis sticky FIFO-full fault
  localparam logic [15:0] CSR_TDC_B_FAULT = 16'h3004;
  // CSR_FIELD: TDC_B_FAULT|FIFO_FULL|0|1|W1C|Sticky B-axis FIFO-full edge
  // CSR_MAP: TDC_B_ERROR_COUNT|0x3008|RO|0x00000000|TDC B|B-axis saturating FIFO-full counter
  localparam logic [15:0] CSR_TDC_B_ERROR_COUNT = 16'h3008;
  // CSR_FIELD: TDC_B_ERROR_COUNT|COUNT|0|32|RO|Saturating B-axis FIFO-full edge count

  // CSR_MAP: POSITION_CFG|0x4000|RW|0x00000104|Position|Cluster/raw mode gap and minimum-span controls
  localparam logic [15:0] CSR_POSITION_CFG = 16'h4000;
  // CSR_FIELD: POSITION_CFG|MODE|0|1|RW|0 cluster mode and 1 raw mode
  // CSR_FIELD: POSITION_CFG|GAP_THRESHOLD|1|7|RW|Maximum zero-run retained within one cluster; range 0 through 64
  // CSR_FIELD: POSITION_CFG|MIN_CLUSTER_SPAN|8|7|RW|Minimum accepted cluster span; range 1 through 64
  // CSR_MAP: POSITION_STATUS|0x4004|RO|0x00000000|Position|Packet pending busy and snapshot-captured status
  localparam logic [15:0] CSR_POSITION_STATUS = 16'h4004;
  // CSR_FIELD: POSITION_STATUS|PACKET_PENDING|0|1|RO|A position packet is queued
  // CSR_FIELD: POSITION_STATUS|PACKET_BUSY|1|1|RO|Position packet emission is active
  // CSR_FIELD: POSITION_STATUS|SNAPSHOT_CAPTURED|2|1|RO|The current position snapshot was captured
  // CSR_MAP: POSITION_FAULT|0x4008|W1C|0x00000000|Position|Sticky packet-drop fault
  localparam logic [15:0] CSR_POSITION_FAULT = 16'h4008;
  // CSR_FIELD: POSITION_FAULT|PACKET_DROP|0|1|W1C|Sticky position packet-drop edge
  // CSR_MAP: POSITION_DROP_COUNT|0x400C|RO|0x00000000|Position|Saturating packet-drop counter
  localparam logic [15:0] CSR_POSITION_DROP_COUNT = 16'h400C;
  // CSR_FIELD: POSITION_DROP_COUNT|COUNT|0|32|RO|Saturating position packet-drop edge count

  // CSR_MAP: EVENT_STATUS|0x5000|RO|0x00000000|Event|Event identifier and lifecycle status
  localparam logic [15:0] CSR_EVENT_STATUS = 16'h5000;
  // CSR_FIELD: EVENT_STATUS|EVENT_ID|0|14|RO|Identifier assigned to the active or most recent event
  // CSR_FIELD: EVENT_STATUS|BUSY|14|1|RO|Event coordinator is processing an event
  // CSR_MAP: EVENT_MASK_STATUS|0x5004|RO|0x00000000|Event|Required completed and reset-ack masks
  localparam logic [15:0] CSR_EVENT_MASK_STATUS = 16'h5004;
  // CSR_FIELD: EVENT_MASK_STATUS|REQUIRED_PACKET_MASK|0|4|RO|Sources required for the current event bundle
  // CSR_FIELD: EVENT_MASK_STATUS|COMPLETED_PACKET_MASK|4|4|RO|Sources that completed the current event bundle
  // CSR_FIELD: EVENT_MASK_STATUS|REQUIRED_RESET_ACK_MASK|8|4|RO|Sources required to acknowledge matrix reset
  // CSR_FIELD: EVENT_MASK_STATUS|OBSERVED_RESET_ACK_MASK|12|4|RO|Sources that acknowledged matrix reset
  // CSR_MAP: SNAPSHOT_CFG|0x5008|RW|0x00400002|Event|Snapshot settle and watchdog cycles
  localparam logic [15:0] CSR_SNAPSHOT_CFG = 16'h5008;
  // CSR_FIELD: SNAPSHOT_CFG|SETTLE_CYCLES|0|16|RW|Cycles between event acceptance and position snapshot
  // CSR_FIELD: SNAPSHOT_CFG|WATCHDOG_CYCLES|16|16|RW|Nonzero event-completion watchdog limit
  // CSR_MAP: RESET_CFG|0x500C|RW|0x00000000|Event|Automatic matrix-reset pulse width
  localparam logic [15:0] CSR_RESET_CFG = 16'h500C;
  // CSR_FIELD: RESET_CFG|PULSE_WIDTH_CYCLES|0|16|RW|Automatic matrix-reset pulse width; zero disables the pulse
  // CSR_MAP: SNAPSHOT_RESET_STATUS|0x5010|RO|0x00000000|Event|Snapshot and reset controller status
  localparam logic [15:0] CSR_SNAPSHOT_RESET_STATUS = 16'h5010;
  // CSR_FIELD: SNAPSHOT_RESET_STATUS|SNAPSHOT_VALID|0|1|RO|A completed snapshot is available
  // CSR_FIELD: SNAPSHOT_RESET_STATUS|SNAPSHOT_BUSY|1|1|RO|Snapshot controller is active
  // CSR_FIELD: SNAPSHOT_RESET_STATUS|SNAPSHOT_REARM_READY|2|1|RO|Snapshot controller can accept the next event
  // CSR_FIELD: SNAPSHOT_RESET_STATUS|RESET_BUSY|3|1|RO|Automatic matrix-reset pulse is active
  // CSR_FIELD: SNAPSHOT_RESET_STATUS|RESET_DONE|4|1|RO|Automatic matrix reset completed
  // CSR_FIELD: SNAPSHOT_RESET_STATUS|RESET_DISABLED|5|1|RO|The completed event did not request automatic reset
  // CSR_MAP: EVENT_FAULT|0x5014|W1C|0x00000000|Event|Sticky reject timeout overlap and disabled-reset faults
  localparam logic [15:0] CSR_EVENT_FAULT = 16'h5014;
  // CSR_FIELD: EVENT_FAULT|EVENT_REJECT|0|1|W1C|Sticky event-not-ready rejection
  // CSR_FIELD: EVENT_FAULT|SNAPSHOT_TIMEOUT|1|1|W1C|Sticky snapshot watchdog timeout
  // CSR_FIELD: EVENT_FAULT|SNAPSHOT_PROTOCOL|2|1|W1C|Sticky snapshot overlap or rejection
  // CSR_FIELD: EVENT_FAULT|RESET_DISABLED|3|1|W1C|Sticky event completion without automatic reset
  // CSR_MAP: EVENT_REJECT_COUNT|0x5018|RO|0x00000000|Event|Saturating event-not-ready reject counter
  localparam logic [15:0] CSR_EVENT_REJECT_COUNT = 16'h5018;
  // CSR_FIELD: EVENT_REJECT_COUNT|COUNT|0|32|RO|Saturating event-not-ready rejection count
  // CSR_MAP: SNAPSHOT_TIMEOUT_COUNT|0x501C|RO|0x00000000|Event|Saturating snapshot-timeout counter
  localparam logic [15:0] CSR_SNAPSHOT_TIMEOUT_COUNT = 16'h501C;
  // CSR_FIELD: SNAPSHOT_TIMEOUT_COUNT|COUNT|0|32|RO|Saturating snapshot watchdog-timeout count
  // CSR_MAP: SNAPSHOT_OVERLAP_COUNT|0x5020|RO|0x00000000|Event|Saturating snapshot-overlap counter
  localparam logic [15:0] CSR_SNAPSHOT_OVERLAP_COUNT = 16'h5020;
  // CSR_FIELD: SNAPSHOT_OVERLAP_COUNT|COUNT|0|32|RO|Saturating overlapping snapshot-request count
  // CSR_MAP: SNAPSHOT_REJECT_COUNT|0x5024|RO|0x00000000|Event|Saturating snapshot-reject counter
  localparam logic [15:0] CSR_SNAPSHOT_REJECT_COUNT = 16'h5024;
  // CSR_FIELD: SNAPSHOT_REJECT_COUNT|COUNT|0|32|RO|Saturating rejected snapshot-request count
  // CSR_MAP: RESET_DISABLED_COUNT|0x5028|RO|0x00000000|Event|Saturating disabled-reset counter
  localparam logic [15:0] CSR_RESET_DISABLED_COUNT = 16'h5028;
  // CSR_FIELD: RESET_DISABLED_COUNT|COUNT|0|32|RO|Saturating event completions without automatic reset
  // CSR_MAP: EVENT_CMD|0x502C|WO|0x00000000|Event|Snapshot clear command pulse
  localparam logic [15:0] CSR_EVENT_CMD = 16'h502C;
  // CSR_FIELD: EVENT_CMD|SNAPSHOT_CLEAR|0|1|WO|Pulse snapshot clear
  // CSR_MAP: SNAPSHOT_R_LO|0x5040|RO|0x00000000|Event|R snapshot bits 31 to 0
  localparam logic [15:0] CSR_SNAPSHOT_R_LO = 16'h5040;
  // CSR_FIELD: SNAPSHOT_R_LO|DATA|0|32|RO|R snapshot bits 31 through 0
  // CSR_MAP: SNAPSHOT_R_HI|0x5044|RO|0x00000000|Event|R snapshot bits 63 to 32
  localparam logic [15:0] CSR_SNAPSHOT_R_HI = 16'h5044;
  // CSR_FIELD: SNAPSHOT_R_HI|DATA|0|32|RO|R snapshot bits 63 through 32
  // CSR_MAP: SNAPSHOT_Y_LO|0x5048|RO|0x00000000|Event|Y snapshot bits 31 to 0
  localparam logic [15:0] CSR_SNAPSHOT_Y_LO = 16'h5048;
  // CSR_FIELD: SNAPSHOT_Y_LO|DATA|0|32|RO|Y snapshot bits 31 through 0
  // CSR_MAP: SNAPSHOT_Y_HI|0x504C|RO|0x00000000|Event|Y snapshot bits 63 to 32
  localparam logic [15:0] CSR_SNAPSHOT_Y_HI = 16'h504C;
  // CSR_FIELD: SNAPSHOT_Y_HI|DATA|0|32|RO|Y snapshot bits 63 through 32
  // CSR_MAP: SNAPSHOT_B_LO|0x5050|RO|0x00000000|Event|B snapshot bits 31 to 0
  localparam logic [15:0] CSR_SNAPSHOT_B_LO = 16'h5050;
  // CSR_FIELD: SNAPSHOT_B_LO|DATA|0|32|RO|B snapshot bits 31 through 0
  // CSR_MAP: SNAPSHOT_B_HI|0x5054|RO|0x00000000|Event|B snapshot bits 63 to 32
  localparam logic [15:0] CSR_SNAPSHOT_B_HI = 16'h5054;
  // CSR_FIELD: SNAPSHOT_B_HI|DATA|0|32|RO|B snapshot bits 63 through 32

  // CSR_MAP: MATRIX_CMD|0x6000|RW|0x00000002|Matrix|Matrix configuration operation and start pulse
  localparam logic [15:0] CSR_MATRIX_CMD = 16'h6000;
  // CSR_FIELD: MATRIX_CMD|START|0|1|WO|Pulse the selected matrix configuration operation
  // CSR_FIELD: MATRIX_CMD|OPERATION|1|3|RW|1 write column, 2 read column, 3 fill zero, 4 fill one
  // CSR_MAP: MATRIX_STATUS|0x6004|RO|0x00000000|Matrix|Matrix configuration and readback status
  localparam logic [15:0] CSR_MATRIX_STATUS = 16'h6004;
  // CSR_FIELD: MATRIX_STATUS|BUSY|0|1|RO|Matrix configuration controller is active
  // CSR_FIELD: MATRIX_STATUS|DONE|1|1|RO|Most recent matrix command completed
  // CSR_FIELD: MATRIX_STATUS|ERROR|2|1|RO|Matrix configuration controller reports an error
  // CSR_FIELD: MATRIX_STATUS|LAST_ERROR|3|4|RO|Most recent matrix controller error code
  // CSR_FIELD: MATRIX_STATUS|READBACK_VALID|7|1|RO|MATRIX_RDATA contains valid readback data
  // CSR_FIELD: MATRIX_STATUS|CONFIG_VALID|8|1|RO|Matrix configuration state is valid
  // CSR_MAP: MATRIX_COLUMN|0x6008|RW|0x00000000|Matrix|Matrix column index
  localparam logic [15:0] CSR_MATRIX_COLUMN = 16'h6008;
  // CSR_FIELD: MATRIX_COLUMN|INDEX|0|6|RW|Matrix column index from 0 through 43
  // CSR_MAP: MATRIX_WDATA_LO|0x600C|RW|0x00000000|Matrix|Matrix command payload bits 31 to 0
  localparam logic [15:0] CSR_MATRIX_WDATA_LO = 16'h600C;
  // CSR_FIELD: MATRIX_WDATA_LO|DATA|0|32|RW|Matrix write payload bits 31 through 0
  // CSR_MAP: MATRIX_WDATA_HI|0x6010|RW|0x00000000|Matrix|Matrix command payload bits 63 to 32
  localparam logic [15:0] CSR_MATRIX_WDATA_HI = 16'h6010;
  // CSR_FIELD: MATRIX_WDATA_HI|DATA|0|32|RW|Matrix write payload bits 63 through 32
  // CSR_MAP: MATRIX_RDATA_LO|0x6014|RO|0x00000000|Matrix|Matrix readback bits 31 to 0
  localparam logic [15:0] CSR_MATRIX_RDATA_LO = 16'h6014;
  // CSR_FIELD: MATRIX_RDATA_LO|DATA|0|32|RO|Matrix readback bits 31 through 0
  // CSR_MAP: MATRIX_RDATA_HI|0x6018|RO|0x00000000|Matrix|Matrix readback bits 63 to 32
  localparam logic [15:0] CSR_MATRIX_RDATA_HI = 16'h6018;
  // CSR_FIELD: MATRIX_RDATA_HI|DATA|0|32|RO|Matrix readback bits 63 through 32
  // CSR_MAP: MATRIX_FAULT|0x601C|W1C|0x00000000|Matrix|Sticky command-reject and controller-error faults
  localparam logic [15:0] CSR_MATRIX_FAULT = 16'h601C;
  // CSR_FIELD: MATRIX_FAULT|COMMAND_REJECT|0|1|W1C|Sticky unsafe or invalid matrix command
  // CSR_FIELD: MATRIX_FAULT|CONTROLLER_ERROR|1|1|W1C|Sticky matrix controller error edge
  // CSR_FIELD: MATRIX_FAULT|LAST_ERROR|4|4|RO|Live most recent matrix controller error code
  // CSR_MAP: MATRIX_REJECT_COUNT|0x6020|RO|0x00000000|Matrix|Saturating rejected-command counter
  localparam logic [15:0] CSR_MATRIX_REJECT_COUNT = 16'h6020;
  // CSR_FIELD: MATRIX_REJECT_COUNT|COUNT|0|32|RO|Saturating rejected matrix-command count
  // CSR_MAP: MATRIX_ERROR_COUNT|0x6024|RO|0x00000000|Matrix|Saturating controller-error counter
  localparam logic [15:0] CSR_MATRIX_ERROR_COUNT = 16'h6024;
  // CSR_FIELD: MATRIX_ERROR_COUNT|COUNT|0|32|RO|Saturating matrix controller-error edge count

  // CSR_MAP: TX_BUNDLE_STATUS|0x7000|RO|0x00000000|TX|Bundle and output-path status
  localparam logic [15:0] CSR_TX_BUNDLE_STATUS = 16'h7000;
  // CSR_FIELD: TX_BUNDLE_STATUS|BUSY|0|1|RO|Event-bundle transmitter is active
  // CSR_FIELD: TX_BUNDLE_STATUS|IDLE|1|1|RO|Event-bundle transmitter is idle
  // CSR_FIELD: TX_BUNDLE_STATUS|MISSING_SOURCE|2|1|RO|Current bundle completed without every required source
  // CSR_MAP: TX_FIFO_STATUS|0x7004|RO|0x00000000|TX|Output FIFO level and flags
  localparam logic [15:0] CSR_TX_FIFO_STATUS = 16'h7004;
  // CSR_FIELD: TX_FIFO_STATUS|EMPTY|0|1|RO|Output FIFO is empty
  // CSR_FIELD: TX_FIFO_STATUS|FULL|1|1|RO|Output FIFO is full
  // CSR_FIELD: TX_FIFO_STATUS|ALMOST_FULL|2|1|RO|Output FIFO reached the fixed reserve threshold
  // CSR_FIELD: TX_FIFO_STATUS|LEVEL|4|12|RO|Number of occupied output FIFO words
  // CSR_FIELD: TX_FIFO_STATUS|FREE_WORDS|16|16|RO|Number of free output FIFO words
  // CSR_MAP: TX_FIFO_GEOMETRY|0x7008|RO|0x01000081|TX|Fixed FIFO reserve threshold and depth
  localparam logic [15:0] CSR_TX_FIFO_GEOMETRY = 16'h7008;
  // CSR_FIELD: TX_FIFO_GEOMETRY|RESERVE_ENTRIES|0|16|RO|Fixed event-bundle reserve threshold in words
  // CSR_FIELD: TX_FIFO_GEOMETRY|DEPTH|16|16|RO|Physical output FIFO depth in words
  // CSR_MAP: TX_DDR_STATUS|0x700C|RO|0x00000000|TX|DDR pairer status
  localparam logic [15:0] CSR_TX_DDR_STATUS = 16'h700C;
  // CSR_FIELD: TX_DDR_STATUS|EMPTY|0|1|RO|DDR pairer has no pending word
  // CSR_FIELD: TX_DDR_STATUS|BUSY|1|1|RO|DDR pairer contains or emits a word pair
  // CSR_FIELD: TX_DDR_STATUS|PAIR_VALID|2|1|RO|DDR low and high words are valid
  // CSR_FIELD: TX_DDR_STATUS|PADDED|3|1|RO|Most recent pair used deterministic odd-word padding
  // CSR_MAP: TX_FAULT|0x7010|W1C|0x00000000|TX|Sticky missing-source and FIFO-overflow faults
  localparam logic [15:0] CSR_TX_FAULT = 16'h7010;
  // CSR_FIELD: TX_FAULT|MISSING_SOURCE|0|1|W1C|Sticky event-bundle missing-source edge
  // CSR_FIELD: TX_FAULT|FIFO_OVERFLOW|1|1|W1C|Sticky output FIFO overflow edge
  // CSR_MAP: TX_MISSING_SOURCE_COUNT|0x7014|RO|0x00000000|TX|Saturating missing-source counter
  localparam logic [15:0] CSR_TX_MISSING_SOURCE_COUNT = 16'h7014;
  // CSR_FIELD: TX_MISSING_SOURCE_COUNT|COUNT|0|32|RO|Saturating missing-source edge count
  // CSR_MAP: TX_FIFO_OVERFLOW_COUNT|0x7018|RO|0x00000000|TX|Saturating output-FIFO overflow counter
  localparam logic [15:0] CSR_TX_FIFO_OVERFLOW_COUNT = 16'h7018;
  // CSR_FIELD: TX_FIFO_OVERFLOW_COUNT|COUNT|0|32|RO|Saturating output FIFO overflow edge count

  // CSR_MAP: PLL_CTRL|0x8000|RW|0x00004000|PLL|PLL and clock-source controls
  localparam logic [15:0] CSR_PLL_CTRL = 16'h8000;
  // CSR_FIELD: PLL_CTRL|FINT_SELECT|0|8|RW|PLL fractional or integer selection code
  // CSR_FIELD: PLL_CTRL|RO_SWITCH|8|5|RW|PLL ring-oscillator switch code
  // CSR_FIELD: PLL_CTRL|SELECT_PULSE_PFD|13|1|RW|Select pulse input for the phase-frequency detector
  // CSR_FIELD: PLL_CTRL|ENABLE_DIVIDER|14|1|RW|Enable PLL output divider
  // CSR_FIELD: PLL_CTRL|SELECT_40M|15|1|RW|Select the 40 MHz PLL path
  // CSR_FIELD: PLL_CTRL|SELECT_EXTERNAL_160M|16|1|RW|Select the external 160 MHz system clock
  // CSR_MAP: PLL_STATUS|0x8004|RO|0x00000000|PLL|PLL lock and active clock controls
  localparam logic [15:0] CSR_PLL_STATUS = 16'h8004;
  // CSR_FIELD: PLL_STATUS|LOCKED|0|1|RO|PLL lock indication
  // CSR_FIELD: PLL_STATUS|EXTERNAL_160M_SELECTED|1|1|RO|External 160 MHz system clock is selected
  // CSR_FIELD: PLL_STATUS|DIVIDER_ENABLED|2|1|RO|PLL output divider is enabled
  // CSR_MAP: PLL_FAULT|0x8008|W1C|0x00000000|PLL|Sticky lock-loss fault
  localparam logic [15:0] CSR_PLL_FAULT = 16'h8008;
  // CSR_FIELD: PLL_FAULT|LOCK_LOSS|0|1|W1C|Sticky falling edge of PLL lock
  // CSR_MAP: PLL_LOCK_LOSS_COUNT|0x800C|RO|0x00000000|PLL|Saturating lock-loss counter
  localparam logic [15:0] CSR_PLL_LOCK_LOSS_COUNT = 16'h800C;
  // CSR_FIELD: PLL_LOCK_LOSS_COUNT|COUNT|0|32|RO|Saturating PLL lock-loss edge count

  // CSR_MAP: SLVS_CTRL|0x9000|RW|0x00000140|Analog|SLVS driver and active-low reference controls
  localparam logic [15:0] CSR_SLVS_CTRL = 16'h9000;
  // CSR_FIELD: SLVS_CTRL|DRIVE_STRENGTH|0|4|RW|SLVS output-driver strength selection
  // CSR_FIELD: SLVS_CTRL|EXTERNAL_VREF_ENABLE|4|1|RW|Enable external SLVS reference input
  // CSR_FIELD: SLVS_CTRL|DRIVER_ENABLE|5|1|RW|Enable SLVS output driver
  // CSR_FIELD: SLVS_CTRL|VREF_ADJUST_B|6|1|RW|Active-low SLVS reference adjustment control
  // CSR_FIELD: SLVS_CTRL|VREF_400MV_ENABLE|7|1|RW|Enable internal 400 mV SLVS reference
  // CSR_FIELD: SLVS_CTRL|REFERENCE_DRIVER_ENABLE_B|8|1|RW|Active-low SLVS reference-driver enable
  // CSR_MAP: RX_CTRL|0x9004|RW|0x00000000|Analog|Receiver select enable and termination controls
  localparam logic [15:0] CSR_RX_CTRL = 16'h9004;
  // CSR_FIELD: RX_CTRL|SELECT|0|4|RW|Receiver input selection code
  // CSR_FIELD: RX_CTRL|ENABLE|4|1|RW|Enable receiver
  // CSR_FIELD: RX_CTRL|TERMINATION_ENABLE|5|1|RW|Enable receiver termination

  function automatic logic csr_word_aligned(input logic [15:0] addr);
    return (addr[1:0] == 2'b00);
  endfunction

  function automatic logic [31:0] csr_sat_inc32(input logic [31:0] value);
    return (value == 32'hFFFF_FFFF) ? value : (value + 32'd1);
  endfunction
endpackage

`default_nettype wire
