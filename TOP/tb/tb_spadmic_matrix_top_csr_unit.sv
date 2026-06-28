`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_matrix_top_csr_unit;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;
  localparam logic [2:0] OP_WRITE_COLUMN_64 = 3'd1;
  localparam logic [2:0] OP_READ_COLUMN_64  = 3'd2;
  localparam logic [3:0] CMD_ERR_BUSY        = 4'd1;
  localparam logic [3:0] CMD_ERR_INVALID_COL = 4'd3;
  localparam logic [3:0] CMD_ERR_PATH_BUSY   = 4'd4;
  localparam logic [3:0] CMD_ERR_BAD_MODE    = 4'd6;

  logic clk_sys;
  logic rst_n;
  logic csr_valid;
  logic csr_write;
  logic [SPADMIC_CSR_ADDR_W-1:0] csr_addr;
  logic [SPADMIC_CSR_DATA_W-1:0] csr_wdata;
  wire csr_ready;
  wire csr_rvalid;
  wire [SPADMIC_CSR_DATA_W-1:0] csr_rdata;
  wire csr_err;

  logic safe_idle;
  logic transition_busy;
  logic event_busy;
  logic [13:0] event_id;
  logic [3:0] required_packet_mask;
  logic [3:0] completed_packet_mask;
  logic [3:0] required_reset_ack_mask;
  logic [3:0] observed_reset_ack_mask;
  logic event_rejected_not_ready;
  logic snapshot_valid;
  logic snapshot_busy;
  logic snapshot_timeout;
  logic snapshot_overlap;
  logic snapshot_reject;
  logic snapshot_rearm_ready;
  logic [63:0] snapshot_R;
  logic [63:0] snapshot_Y;
  logic [63:0] snapshot_B;
  logic reset_busy;
  logic reset_done;
  logic reset_disabled;
  logic matrix_cfg_busy;
  logic matrix_cfg_done;
  logic matrix_cfg_error;
  logic [3:0] matrix_cfg_last_error;
  logic [63:0] matrix_cfg_rdata;
  logic matrix_cfg_readback_valid;
  logic matrix_cfg_valid;
  logic ddr_empty;
  logic ddr_busy;
  logic ddr_pair_valid;
  logic ddr_padded;
  logic [SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level;
  logic [SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words;
  logic output_fifo_empty;
  logic output_fifo_full;
  logic output_fifo_almost_full;
  logic output_fifo_overflow;
  logic bundle_missing_source;
  logic position_packet_drop;
  wire global_enable;
  spadmic_operating_mode_e requested_mode;
  spadmic_operating_mode_e active_mode;
  wire [2:0] requested_axis_mask;
  wire [2:0] active_axis_mask;
  wire auto_reset_enable;
  wire [15:0] settle_cycles;
  wire [15:0] watchdog_cycles;
  wire [15:0] reset_width;
  wire snapshot_clear;
  wire [mptdc_pkg::MAX_HITS_W-1:0] tdc_max_hits;
  wire [7:0] tdc_ro_slow_code;
  wire [7:0] tdc_ro_fast_code;
  wire tdc_soft_reset;
  wire tdc_fifo_clr;
  wire [2:0] calib_axis_mask;
  spadmic_pos_mode_e position_mode;
  wire matrix_cfg_cmd_start;
  wire [2:0] matrix_cfg_cmd_op;
  wire [5:0] matrix_cfg_col_idx;
  wire [63:0] matrix_cfg_wdata;
  wire cfg_accept;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_matrix_top_csr dut (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .csr_valid_i(csr_valid),
    .csr_write_i(csr_write),
    .csr_addr_i(csr_addr),
    .csr_wdata_i(csr_wdata),
    .csr_ready_o(csr_ready),
    .csr_rvalid_o(csr_rvalid),
    .csr_rdata_o(csr_rdata),
    .csr_err_o(csr_err),
    .safe_idle_i(safe_idle),
    .transition_busy_i(transition_busy),
    .event_busy_i(event_busy),
    .event_id_i(event_id),
    .required_packet_mask_i(required_packet_mask),
    .completed_packet_mask_i(completed_packet_mask),
    .required_reset_ack_mask_i(required_reset_ack_mask),
    .observed_reset_ack_mask_i(observed_reset_ack_mask),
    .event_rejected_not_ready_i(event_rejected_not_ready),
    .snapshot_valid_i(snapshot_valid),
    .snapshot_busy_i(snapshot_busy),
    .snapshot_timeout_i(snapshot_timeout),
    .snapshot_overlap_i(snapshot_overlap),
    .snapshot_reject_i(snapshot_reject),
    .snapshot_rearm_ready_i(snapshot_rearm_ready),
    .snapshot_R_i(snapshot_R),
    .snapshot_Y_i(snapshot_Y),
    .snapshot_B_i(snapshot_B),
    .reset_busy_i(reset_busy),
    .reset_done_i(reset_done),
    .reset_disabled_i(reset_disabled),
    .matrix_cfg_busy_i(matrix_cfg_busy),
    .matrix_cfg_done_i(matrix_cfg_done),
    .matrix_cfg_error_i(matrix_cfg_error),
    .matrix_cfg_last_error_i(matrix_cfg_last_error),
    .matrix_cfg_rdata_i(matrix_cfg_rdata),
    .matrix_cfg_readback_valid_i(matrix_cfg_readback_valid),
    .matrix_cfg_valid_i(matrix_cfg_valid),
    .ddr_empty_i(ddr_empty),
    .ddr_busy_i(ddr_busy),
    .ddr_pair_valid_i(ddr_pair_valid),
    .ddr_padded_i(ddr_padded),
    .output_fifo_level_i(output_fifo_level),
    .output_fifo_free_words_i(output_fifo_free_words),
    .output_fifo_empty_i(output_fifo_empty),
    .output_fifo_full_i(output_fifo_full),
    .output_fifo_almost_full_i(output_fifo_almost_full),
    .output_fifo_overflow_i(output_fifo_overflow),
    .bundle_missing_source_i(bundle_missing_source),
    .position_packet_drop_i(position_packet_drop),
    .global_enable_o(global_enable),
    .requested_mode_o(requested_mode),
    .active_mode_o(active_mode),
    .requested_axis_mask_o(requested_axis_mask),
    .active_axis_mask_o(active_axis_mask),
    .auto_reset_enable_o(auto_reset_enable),
    .settle_cycles_o(settle_cycles),
    .watchdog_cycles_o(watchdog_cycles),
    .reset_width_o(reset_width),
    .snapshot_clear_o(snapshot_clear),
    .tdc_max_hits_o(tdc_max_hits),
    .tdc_ro_slow_code_o(tdc_ro_slow_code),
    .tdc_ro_fast_code_o(tdc_ro_fast_code),
    .tdc_soft_reset_o(tdc_soft_reset),
    .tdc_fifo_clr_o(tdc_fifo_clr),
    .calib_axis_mask_o(calib_axis_mask),
    .position_mode_o(position_mode),
    .matrix_cfg_cmd_start_o(matrix_cfg_cmd_start),
    .matrix_cfg_cmd_op_o(matrix_cfg_cmd_op),
    .matrix_cfg_col_idx_o(matrix_cfg_col_idx),
    .matrix_cfg_wdata_o(matrix_cfg_wdata),
    .cfg_accept_o(cfg_accept)
  );

  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_count++;
    end else begin
      $display("[FAIL] %s", label);
      fail_count++;
    end
  endtask

  task automatic csr_write_cmd(
    input logic [SPADMIC_CSR_ADDR_W-1:0] addr,
    input logic [31:0] data,
    input logic expect_err
  );
    begin
      @(negedge clk_sys);
      csr_addr   = addr;
      csr_wdata  = data;
      csr_write  = 1'b1;
      csr_valid  = 1'b1;
      @(posedge clk_sys);
      #1;
      check("write response valid", csr_rvalid);
      check("write response error expectation", csr_err == expect_err);
      @(negedge clk_sys);
      csr_valid = 1'b0;
      csr_write = 1'b0;
      csr_wdata = '0;
    end
  endtask

  task automatic csr_read_cmd(
    input logic [SPADMIC_CSR_ADDR_W-1:0] addr,
    output logic [31:0] data,
    input logic expect_err
  );
    begin
      @(negedge clk_sys);
      csr_addr  = addr;
      csr_write = 1'b0;
      csr_valid = 1'b1;
      @(posedge clk_sys);
      #1;
      data = csr_rdata;
      check("read response valid", csr_rvalid);
      check("read response error expectation", csr_err == expect_err);
      @(negedge clk_sys);
      csr_valid = 1'b0;
    end
  endtask

  initial begin
    logic [31:0] rd;
    logic [15:0] overflow_count_before;

    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    csr_valid = 1'b0;
    csr_write = 1'b0;
    csr_addr = '0;
    csr_wdata = '0;
    safe_idle = 1'b1;
    transition_busy = 1'b0;
    event_busy = 1'b0;
    event_id = 14'h0123;
    required_packet_mask = 4'b1111;
    completed_packet_mask = 4'b0011;
    required_reset_ack_mask = 4'b1111;
    observed_reset_ack_mask = 4'b0111;
    event_rejected_not_ready = 1'b0;
    snapshot_valid = 1'b0;
    snapshot_busy = 1'b0;
    snapshot_timeout = 1'b0;
    snapshot_overlap = 1'b0;
    snapshot_reject = 1'b0;
    snapshot_rearm_ready = 1'b1;
    snapshot_R = 64'h0000_0001_0000_0002;
    snapshot_Y = 64'h0000_0004_0000_0008;
    snapshot_B = 64'h0000_0010_0000_0020;
    reset_busy = 1'b0;
    reset_done = 1'b0;
    reset_disabled = 1'b0;
    matrix_cfg_busy = 1'b0;
    matrix_cfg_done = 1'b0;
    matrix_cfg_error = 1'b0;
    matrix_cfg_last_error = 4'h0;
    matrix_cfg_rdata = 64'hA5A5_5A5A_0123_4567;
    matrix_cfg_readback_valid = 1'b1;
    matrix_cfg_valid = 1'b1;
    ddr_empty = 1'b1;
    ddr_busy = 1'b0;
    ddr_pair_valid = 1'b0;
    ddr_padded = 1'b0;
    output_fifo_level = '0;
    output_fifo_free_words = SPADMIC_OUTPUT_FIFO_LEVEL_W'(SPADMIC_OUTPUT_FIFO_DEPTH);
    output_fifo_empty = 1'b1;
    output_fifo_full = 1'b0;
    output_fifo_almost_full = 1'b0;
    output_fifo_overflow = 1'b0;
    bundle_missing_source = 1'b0;
    position_packet_drop = 1'b0;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);
    #1;

    csr_read_cmd(SPADMIC_CSR_MTOP_CTRL_ACTIVE, rd, 1'b0);
    check("reset active mode disabled", rd[3:1] == SPADMIC_MODE_DISABLED);
    check("reset axis mask defaults all axes", rd[6:4] == 3'b111);
    check("reset auto reset enabled", rd[7]);
    csr_read_cmd(SPADMIC_CSR_SHARED_TDC_MAX_HITS, rd, 1'b0);
    check("reset shared max_hits defaults 15", rd[3:0] == 4'd15);
    csr_read_cmd(SPADMIC_CSR_CALIB_AXIS_MASK, rd, 1'b0);
    check("reset calibration axis mask defaults all axes", rd[2:0] == 3'b111);

    csr_write_cmd(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_POSITION_ONLY, 1'b1},
                  1'b0);
    check("mode write accepted pulse", cfg_accept);
    check("position-only active", active_mode == SPADMIC_MODE_POSITION_ONLY);
    check("global enable active", global_enable);

    safe_idle = 1'b0;
    csr_write_cmd(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_TDC_ONLY, 1'b1},
                  1'b1);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("busy mode reject sets PATH_BUSY code", rd[11:8] == CMD_ERR_PATH_BUSY);
    check("busy mode reject does not change active mode", active_mode == SPADMIC_MODE_POSITION_ONLY);
    safe_idle = 1'b1;

    csr_write_cmd(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b000, SPADMIC_MODE_TDC_ONLY, 1'b1},
                  1'b1);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("bad TDC axis mask rejected", rd[11:8] == CMD_ERR_BAD_MODE);

    csr_write_cmd(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b001, SPADMIC_MODE_BOTH, 1'b1},
                  1'b1);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("partial BOTH axis mask rejected", rd[11:8] == CMD_ERR_BAD_MODE);

    csr_write_cmd(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b001, SPADMIC_MODE_CALIBRATION, 1'b1},
                  1'b0);
    check("calibration accepts diagnostic partial axis mask", cfg_accept);

    csr_write_cmd(SPADMIC_CSR_CALIB_AXIS_MASK, 32'h0000_0005, 1'b0);
    check("calibration axis mask write accepted", cfg_accept);
    check("calibration axis mask updates register", calib_axis_mask == 3'b101);
    csr_read_cmd(SPADMIC_CSR_CALIB_AXIS_MASK, rd, 1'b0);
    check("calibration axis mask readback", rd[2:0] == 3'b101);
    csr_write_cmd(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_CALIBRATION, 1'b1},
                  1'b0);
    check("calibration mode uses calibration mask", active_axis_mask == 3'b101);

    csr_write_cmd(SPADMIC_CSR_SHARED_TDC_MAX_HITS, 32'h0000_0009, 1'b0);
    check("shared max_hits write accepted", cfg_accept);
    check("shared max_hits output updates", tdc_max_hits == 4'd9);
    csr_read_cmd(SPADMIC_CSR_SHARED_TDC_MAX_HITS, rd, 1'b0);
    check("shared max_hits readback", rd[3:0] == 4'd9);

    csr_write_cmd(SPADMIC_CSR_SHARED_TDC_RO_SLOW, 32'h0000_005A, 1'b0);
    check("shared slow RO code updates", tdc_ro_slow_code == 8'h5A);
    csr_write_cmd(SPADMIC_CSR_SHARED_TDC_RO_FAST, 32'h0000_00C3, 1'b0);
    check("shared fast RO code updates", tdc_ro_fast_code == 8'hC3);
    csr_read_cmd(SPADMIC_CSR_SHARED_TDC_RO_SLOW, rd, 1'b0);
    check("shared slow RO readback", rd[7:0] == 8'h5A);
    csr_read_cmd(SPADMIC_CSR_SHARED_TDC_RO_FAST, rd, 1'b0);
    check("shared fast RO readback", rd[7:0] == 8'hC3);
    csr_write_cmd(SPADMIC_CSR_SHARED_TDC_RO_FAST, 32'h0000_0000, 1'b0);
    check("shared fast RO zero clear/default policy", tdc_ro_fast_code == 8'h00);

    csr_write_cmd(SPADMIC_CSR_SHARED_TDC_CTRL, 32'h0000_0003, 1'b0);
    check("shared TDC soft reset pulse", tdc_soft_reset);
    check("shared TDC fifo clear pulse", tdc_fifo_clr);
    @(posedge clk_sys);
    #1;
    check("shared TDC soft reset pulse clears", !tdc_soft_reset);
    check("shared TDC fifo clear pulse clears", !tdc_fifo_clr);

    csr_write_cmd(SPADMIC_CSR_POSITION_MODE, 32'h0000_0000, 1'b0);
    check("position mode cluster write accepted", position_mode == SPADMIC_POS_MODE_CLUSTER);
    csr_write_cmd(SPADMIC_CSR_POSITION_MODE, 32'h0000_0001, 1'b0);
    check("position mode raw write accepted", position_mode == SPADMIC_POS_MODE_RAW);

    csr_write_cmd(SPADMIC_CSR_MATRIX_SNAPSHOT_CFG, 32'h0040_0003, 1'b0);
    check("snapshot settle updated", settle_cycles == 16'd3);
    check("snapshot watchdog updated", watchdog_cycles == 16'd64);

    csr_write_cmd(SPADMIC_CSR_MATRIX_RESET_CTRL, 32'h0001_0005, 1'b0);
    check("reset width updated", reset_width == 16'd5);
    check("auto reset from reset ctrl", auto_reset_enable);

    csr_read_cmd(SPADMIC_CSR_MATRIX_R_SNAP_HI, rd, 1'b0);
    check("R snapshot high CSR", rd == snapshot_R[63:32]);

    csr_write_cmd(SPADMIC_CSR_MATRIX_EVENT_STATUS, 32'h1, 1'b0);
    check("snapshot clear pulse generated", snapshot_clear);

    csr_write_cmd(SPADMIC_CSR_MATRIX_CFG_COL, 32'd43, 1'b0);
    check("matrix cfg column set", matrix_cfg_col_idx == 6'd43);
    csr_write_cmd(SPADMIC_CSR_MATRIX_CFG_WDATA_LO, 32'h89AB_CDEF, 1'b0);
    csr_write_cmd(SPADMIC_CSR_MATRIX_CFG_WDATA_HI, 32'h0123_4567, 1'b0);
    check("matrix cfg write data assembled", matrix_cfg_wdata == 64'h0123_4567_89AB_CDEF);

    csr_write_cmd(SPADMIC_CSR_MATRIX_CFG_CMD, {28'h0, OP_WRITE_COLUMN_64, 1'b1}, 1'b0);
    check("matrix cfg command start pulse", matrix_cfg_cmd_start);
    check("matrix cfg command op propagated", matrix_cfg_cmd_op == OP_WRITE_COLUMN_64);

    matrix_cfg_busy = 1'b1;
    csr_write_cmd(SPADMIC_CSR_MATRIX_CFG_CMD, {28'h0, OP_READ_COLUMN_64, 1'b1}, 1'b1);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("busy cfg command reports busy", rd[11:8] == CMD_ERR_BUSY);
    csr_read_cmd(SPADMIC_CSR_MATRIX_CFG_CMD, rd, 1'b0);
    check("busy rejected command leaves opcode readback unchanged", rd[3:1] == OP_WRITE_COLUMN_64);
    matrix_cfg_busy = 1'b0;

    event_busy = 1'b1;
    safe_idle  = 1'b0;
    csr_write_cmd(SPADMIC_CSR_MATRIX_CFG_WDATA_LO, 32'hCAFE_BABE, 1'b1);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("path-busy cfg parameter write reports PATH_BUSY", rd[11:8] == CMD_ERR_PATH_BUSY);
    check("path-busy cfg parameter write leaves data unchanged",
          matrix_cfg_wdata == 64'h0123_4567_89AB_CDEF);
    csr_write_cmd(SPADMIC_CSR_MATRIX_CFG_CMD, {28'h0, OP_READ_COLUMN_64, 1'b1}, 1'b1);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("path-busy cfg command reports PATH_BUSY", rd[11:8] == CMD_ERR_PATH_BUSY);
    csr_read_cmd(SPADMIC_CSR_MATRIX_CFG_CMD, rd, 1'b0);
    check("path-busy rejected command leaves opcode readback unchanged",
          rd[3:1] == OP_WRITE_COLUMN_64);
    event_busy = 1'b0;
    safe_idle  = 1'b1;

    csr_write_cmd(SPADMIC_CSR_MATRIX_CFG_COL, 32'd44, 1'b1);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("invalid cfg column reports invalid col", rd[11:8] == CMD_ERR_INVALID_COL);

    event_rejected_not_ready = 1'b1;
    @(posedge clk_sys);
    #1;
    event_rejected_not_ready = 1'b0;
    csr_read_cmd(SPADMIC_CSR_MATRIX_CFG_LAST_ERROR, rd, 1'b0);
    check("event reject counter increments", rd[23:8] == 16'd1);

    csr_read_cmd(16'h1000, rd, 1'b1);
    check("R TDC 0x1000 does not alias global ID", rd != 32'h5350_4D54);
    csr_read_cmd(16'h2000, rd, 1'b1);
    check("Y TDC 0x2000 does not alias global ID", rd != 32'h5350_4D54);
    csr_read_cmd(16'h3000, rd, 1'b1);
    check("B TDC 0x3000 does not alias global ID", rd != 32'h5350_4D54);
    csr_read_cmd(SPADMIC_CSR_TX_STATUS, rd, 1'b0);
    check("TX status valid at full 16-bit 0x7000", rd[1:0] == 2'b01);
    output_fifo_empty = 1'b0;
    output_fifo_level = SPADMIC_OUTPUT_FIFO_LEVEL_W'(500);
    output_fifo_free_words = SPADMIC_OUTPUT_FIFO_LEVEL_W'(12);
    output_fifo_almost_full = 1'b1;
    csr_read_cmd(SPADMIC_CSR_OUTPUT_FIFO_STATUS, rd, 1'b0);
    check("output FIFO status reports not empty", !rd[0]);
    check("output FIFO status reports almost full", rd[2]);
    check("output FIFO status reports level", rd[15:4] == 12'd500);
    check("output FIFO status reports free words", rd[31:16] == 16'd12);
    output_fifo_overflow = 1'b1;
    @(posedge clk_sys);
    #1;
    output_fifo_overflow = 1'b0;
    csr_read_cmd(SPADMIC_CSR_TX_STATUS, rd, 1'b0);
    check("TX status reports FIFO overflow sticky", rd[9]);
    check("TX status reports FIFO overflow count", rd[31:16] == 16'd1);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("MTOP fault reports FIFO overflow sticky", rd[4]);
    output_fifo_empty = 1'b1;
    output_fifo_level = '0;
    output_fifo_free_words = SPADMIC_OUTPUT_FIFO_LEVEL_W'(SPADMIC_OUTPUT_FIFO_DEPTH);
    output_fifo_almost_full = 1'b0;
    csr_read_cmd(16'h700C, rd, 1'b1);
    check("unsupported TX 0x700C reports error instead of aliasing", rd == 32'h0);
    csr_write_cmd(16'h2A00, 32'hDEAD_BEEF, 1'b1);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("bad 16-bit address reports bad addr", rd[11:8] == 4'd5);

    csr_write_cmd(SPADMIC_CSR_MTOP_FAULT, 32'h0000_0F1F, 1'b0);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("W1C fault clear works", rd[3:0] == 4'h0);
    check("W1C FIFO overflow clear works", !rd[4]);
    check("W1C last error clear works", rd[11:8] == 4'd0);

    csr_read_cmd(SPADMIC_CSR_TX_STATUS, rd, 1'b0);
    overflow_count_before = rd[31:16];
    output_fifo_overflow = 1'b1;
    csr_write_cmd(SPADMIC_CSR_MTOP_FAULT, 32'h0000_0010, 1'b0);
    output_fifo_overflow = 1'b0;
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("same-cycle FIFO overflow dominates W1C clear", rd[4]);
    csr_read_cmd(SPADMIC_CSR_TX_STATUS, rd, 1'b0);
    check("same-cycle FIFO overflow increments count",
          rd[31:16] > overflow_count_before);
    csr_write_cmd(SPADMIC_CSR_MTOP_FAULT, 32'h0000_0010, 1'b0);
    csr_read_cmd(SPADMIC_CSR_MTOP_FAULT, rd, 1'b0);
    check("FIFO overflow clears after overflow is gone", !rd[4]);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_matrix_top_csr_unit: %0d failures", fail_count);

    $display("tb_spadmic_matrix_top_csr_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #10_000_000;
    $fatal(1, "tb_spadmic_matrix_top_csr_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
