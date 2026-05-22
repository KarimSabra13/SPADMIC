`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_top_stress;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_SYS_PS = 6250;
  localparam int CLK_REF_PS = 25000;

  logic clk_sys;
  logic clk_ref_40m;
  logic rst_n;

  logic [2:0] spad_event;
  logic [SPADMIC_LINE_W-1:0] x_lines;
  logic [SPADMIC_LINE_W-1:0] y_lines;
  logic [SPADMIC_LINE_W-1:0] z_lines;

  logic x_csr_valid, y_csr_valid, z_csr_valid;
  logic x_csr_write, y_csr_write, z_csr_write;
  logic [CSR_ADDR_W-1:0] x_csr_addr, y_csr_addr, z_csr_addr;
  logic [CSR_DATA_W-1:0] x_csr_wdata, y_csr_wdata, z_csr_wdata;
  wire x_csr_ready, y_csr_ready, z_csr_ready;
  wire x_csr_rvalid, y_csr_rvalid, z_csr_rvalid;
  wire [CSR_DATA_W-1:0] x_csr_rdata, y_csr_rdata, z_csr_rdata;

  logic pos_csr_valid;
  logic pos_csr_write;
  logic [SPADMIC_CSR_ADDR_W-1:0] pos_csr_addr;
  logic [SPADMIC_CSR_DATA_W-1:0] pos_csr_wdata;
  wire pos_csr_ready;
  wire pos_csr_rvalid;
  wire [SPADMIC_CSR_DATA_W-1:0] pos_csr_rdata;

  wire [2:0] axis_acq_valid;
  wire [ACQ_REC_W-1:0] axis_acq_data [3];
  wire [2:0] axis_acq_ready;
  wire [2:0] axis_fifo_full;
  wire [2:0] stop_armed;

  wire pos_valid;
  wire [NARROW_W-1:0] pos_data;
  wire pos_ready;
  wire position_busy;
  wire position_pending;
  wire position_drop_sticky;
  wire position_glitch_sticky;
  wire spad_matrix_rst;

  wire shared_valid;
  wire [NARROW_W-1:0] shared_data;
  wire shared_ready;
  wire tdc_busy;
  wire arb_busy;
  wire corr_overflow;
  wire chip_tx_clk;
  wire chip_tx_valid;
  wire [SPADMIC_TX_PHY_W-1:0] chip_tx_data;

  int cycle_q;
  int trace_words;
  int ddr_bytes;
  int output_fifo_peak;
  int pos_fifo_peak;
  int tdc_fifo_peak [3];
  int errors;

  initial clk_sys = 1'b0;
  always #(CLK_SYS_PS/2) clk_sys = ~clk_sys;

  initial clk_ref_40m = 1'b0;
  always #(CLK_REF_PS/2) clk_ref_40m = ~clk_ref_40m;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n)
      cycle_q <= 0;
    else
      cycle_q <= cycle_q + 1;
  end

  spadmic_tdc_axis_wrapper u_tdc_x (
    .clk_sys(clk_sys), .clk_ref_40m(clk_ref_40m), .async_rst_n(rst_n),
    .global_enable_i(1'b1), .axis_enable_i(1'b1),
    .spad_event_async_i(spad_event[0]),
    .cal_start_async_i(1'b0), .cal_stop_async_i(1'b0),
    .input_sel_override_i(INPUT_SPAD), .out_mode_override_i(OUT_MODE_FULL),
    .csr_valid_i(x_csr_valid), .csr_write_i(x_csr_write),
    .csr_addr_i(x_csr_addr), .csr_wdata_i(x_csr_wdata),
    .csr_ready_o(x_csr_ready), .csr_rvalid_o(x_csr_rvalid),
    .csr_rdata_o(x_csr_rdata), .acq_ready_i(axis_acq_ready[0]),
    .acq_valid_o(axis_acq_valid[0]), .acq_data_o(axis_acq_data[0]),
    .fifo_full_o(axis_fifo_full[0]), .stop_armed_o(stop_armed[0])
  );

  spadmic_tdc_axis_wrapper u_tdc_y (
    .clk_sys(clk_sys), .clk_ref_40m(clk_ref_40m), .async_rst_n(rst_n),
    .global_enable_i(1'b1), .axis_enable_i(1'b1),
    .spad_event_async_i(spad_event[1]),
    .cal_start_async_i(1'b0), .cal_stop_async_i(1'b0),
    .input_sel_override_i(INPUT_SPAD), .out_mode_override_i(OUT_MODE_FULL),
    .csr_valid_i(y_csr_valid), .csr_write_i(y_csr_write),
    .csr_addr_i(y_csr_addr), .csr_wdata_i(y_csr_wdata),
    .csr_ready_o(y_csr_ready), .csr_rvalid_o(y_csr_rvalid),
    .csr_rdata_o(y_csr_rdata), .acq_ready_i(axis_acq_ready[1]),
    .acq_valid_o(axis_acq_valid[1]), .acq_data_o(axis_acq_data[1]),
    .fifo_full_o(axis_fifo_full[1]), .stop_armed_o(stop_armed[1])
  );

  spadmic_tdc_axis_wrapper u_tdc_z (
    .clk_sys(clk_sys), .clk_ref_40m(clk_ref_40m), .async_rst_n(rst_n),
    .global_enable_i(1'b1), .axis_enable_i(1'b1),
    .spad_event_async_i(spad_event[2]),
    .cal_start_async_i(1'b0), .cal_stop_async_i(1'b0),
    .input_sel_override_i(INPUT_SPAD), .out_mode_override_i(OUT_MODE_FULL),
    .csr_valid_i(z_csr_valid), .csr_write_i(z_csr_write),
    .csr_addr_i(z_csr_addr), .csr_wdata_i(z_csr_wdata),
    .csr_ready_o(z_csr_ready), .csr_rvalid_o(z_csr_rvalid),
    .csr_rdata_o(z_csr_rdata), .acq_ready_i(axis_acq_ready[2]),
    .acq_valid_o(axis_acq_valid[2]), .acq_data_o(axis_acq_data[2]),
    .fifo_full_o(axis_fifo_full[2]), .stop_armed_o(stop_armed[2])
  );

  spadmic_position_block u_position (
    .clk_sys(clk_sys), .rst_n(rst_n), .global_enable_i(1'b1),
    .x_lines_i(x_lines), .y_lines_i(y_lines), .z_lines_i(z_lines),
    .csr_valid_i(pos_csr_valid), .csr_write_i(pos_csr_write),
    .csr_addr_i(pos_csr_addr), .csr_wdata_i(pos_csr_wdata),
    .csr_ready_o(pos_csr_ready), .csr_rvalid_o(pos_csr_rvalid),
    .csr_rdata_o(pos_csr_rdata), .pos_ready_i(pos_ready),
    .pos_valid_o(pos_valid), .pos_data_o(pos_data), .busy_o(position_busy),
    .packet_pending_o(position_pending), .drop_sticky_o(position_drop_sticky),
    .glitch_reject_sticky_o(position_glitch_sticky),
    .spad_matrix_rst_o(spad_matrix_rst)
  );

  spadmic_correlated_tx u_correlated_tx (
    .clk_sys(clk_sys), .rst_n(rst_n), .tx_sel_i(SPADMIC_TX_TDC),
    .axis_enable_i(3'b111), .position_enable_i(1'b1),
    .tdc_out_mode_i(OUT_MODE_FULL),
    .acq_valid_i(axis_acq_valid), .acq_data_i(axis_acq_data),
    .acq_ready_o(axis_acq_ready),
    .pos_valid_i(pos_valid), .pos_data_i(pos_data), .pos_ready_o(pos_ready),
    .shared_ready_i(shared_ready), .shared_valid_o(shared_valid),
    .shared_data_o(shared_data), .tdc_busy_o(tdc_busy),
    .arb_busy_o(arb_busy), .correlation_overflow_o(corr_overflow)
  );

  spadmic_ddr_tx u_ddr_tx (
    .clk_sys(clk_sys), .rst_n(rst_n),
    .word_valid_i(shared_valid), .word_data_i(shared_data),
    .word_ready_o(shared_ready), .chip_tx_clk_o(chip_tx_clk),
    .chip_tx_valid_o(chip_tx_valid), .chip_tx_data_o(chip_tx_data)
  );

  function automatic string src_name(input spadmic_source_id_e src);
    case (src)
      TDC_ID_X:              return "TDC_X";
      TDC_ID_Y:              return "TDC_Y";
      TDC_ID_Z:              return "TDC_Z";
      SPADMIC_SRC_POSITION:  return "POSITION";
      default:               return "UNKNOWN";
    endcase
  endfunction

  task automatic fail(input string msg);
    errors++;
    $display("[FAIL] %s", msg);
  endtask

  task automatic tdc_csr_write_all(input logic [CSR_ADDR_W-1:0] addr,
                                   input logic [CSR_DATA_W-1:0] data);
    @(posedge clk_sys);
    #1;
    x_csr_valid = 1'b1; y_csr_valid = 1'b1; z_csr_valid = 1'b1;
    x_csr_write = 1'b1; y_csr_write = 1'b1; z_csr_write = 1'b1;
    x_csr_addr = addr;  y_csr_addr = addr;  z_csr_addr = addr;
    x_csr_wdata = data; y_csr_wdata = data; z_csr_wdata = data;
    @(posedge clk_sys);
    #1;
    x_csr_valid = 1'b0; y_csr_valid = 1'b0; z_csr_valid = 1'b0;
    x_csr_write = 1'b0; y_csr_write = 1'b0; z_csr_write = 1'b0;
    x_csr_addr = '0;    y_csr_addr = '0;    z_csr_addr = '0;
    x_csr_wdata = '0;   y_csr_wdata = '0;   z_csr_wdata = '0;
  endtask

  task automatic position_csr_write(input logic [SPADMIC_CSR_ADDR_W-1:0] addr,
                                    input logic [SPADMIC_CSR_DATA_W-1:0] data);
    @(posedge clk_sys);
    #1;
    pos_csr_valid = 1'b1;
    pos_csr_write = 1'b1;
    pos_csr_addr = addr;
    pos_csr_wdata = data;
    @(posedge clk_sys);
    #1;
    pos_csr_valid = 1'b0;
    pos_csr_write = 1'b0;
    pos_csr_addr = '0;
    pos_csr_wdata = '0;
  endtask

  task automatic fire_event(input int idx);
    $display("[TRACE] cyc=%0d event%0d physical_hit", cycle_q, idx);
    spad_event = 3'b111;
    x_lines = 64'h0000_0000_0000_00ff ^ (64'(idx) << 8);
    y_lines = 64'h0000_0000_00ff_0000 ^ (64'(idx) << 24);
    z_lines = 64'h0000_00ff_0000_0000 ^ (64'(idx) << 40);
    #8000;
    spad_event = 3'b000;
    #10000;
    x_lines = '0;
    y_lines = '0;
    z_lines = '0;
  endtask

  always_ff @(posedge clk_sys) begin
    if (rst_n) begin
      int out_level;
      int pos_level;
      int tx;
      int ty;
      int tz;

      out_level = int'(u_correlated_tx.u_out_fifo.level_o);
      pos_level = int'(u_position.u_frame_fifo.level_o);
      tx = int'(u_tdc_x.u_tdc.u_core.fifo_level);
      ty = int'(u_tdc_y.u_tdc.u_core.fifo_level);
      tz = int'(u_tdc_z.u_tdc.u_core.fifo_level);

      if (out_level > output_fifo_peak) output_fifo_peak <= out_level;
      if (pos_level > pos_fifo_peak) pos_fifo_peak <= pos_level;
      if (tx > tdc_fifo_peak[0]) tdc_fifo_peak[0] <= tx;
      if (ty > tdc_fifo_peak[1]) tdc_fifo_peak[1] <= ty;
      if (tz > tdc_fifo_peak[2]) tdc_fifo_peak[2] <= tz;

      if (u_tdc_x.u_tdc.u_core.meas_snapshot_en) $display("[TRACE] cyc=%0d TDC_X analog_to_digital_snapshot", cycle_q);
      if (u_tdc_y.u_tdc.u_core.meas_snapshot_en) $display("[TRACE] cyc=%0d TDC_Y analog_to_digital_snapshot", cycle_q);
      if (u_tdc_z.u_tdc.u_core.meas_snapshot_en) $display("[TRACE] cyc=%0d TDC_Z analog_to_digital_snapshot", cycle_q);

      if (u_tdc_x.u_tdc.u_core.drain_fifo_wr_en) $display("[TRACE] cyc=%0d TDC_X internal_fifo_write kind=%0d level=%0d", cycle_q, u_tdc_x.u_tdc.u_core.drain_fifo_wr_data.kind, tx);
      if (u_tdc_y.u_tdc.u_core.drain_fifo_wr_en) $display("[TRACE] cyc=%0d TDC_Y internal_fifo_write kind=%0d level=%0d", cycle_q, u_tdc_y.u_tdc.u_core.drain_fifo_wr_data.kind, ty);
      if (u_tdc_z.u_tdc.u_core.drain_fifo_wr_en) $display("[TRACE] cyc=%0d TDC_Z internal_fifo_write kind=%0d level=%0d", cycle_q, u_tdc_z.u_tdc.u_core.drain_fifo_wr_data.kind, tz);

      if (u_position.frame_fifo_wr_en) $display("[TRACE] cyc=%0d POSITION frame_fifo_write level=%0d", cycle_q, pos_level);

      for (int i = 0; i < 3; i++) begin
        if (axis_acq_valid[i] || axis_acq_ready[i])
          $display("[TRACE] cyc=%0d TDC%0d adapter_boundary valid=%0b ready=%0b", cycle_q, i, axis_acq_valid[i], axis_acq_ready[i]);
      end

      if (u_correlated_tx.arb_pkt_valid && u_correlated_tx.arb_pkt_ready)
        $display("[TRACE] cyc=%0d ARB grant=%s data=%04h sop=%0b eop=%0b",
                 cycle_q, src_name(u_correlated_tx.arb_pkt_source),
                 u_correlated_tx.arb_pkt_data,
                 u_correlated_tx.arb_pkt_sop,
                 u_correlated_tx.arb_pkt_eop);

      if (u_correlated_tx.fifo_wr_en) begin
        trace_words <= trace_words + 1;
        $display("[TRACE] cyc=%0d OUTPUT_FIFO write word=%04h source=%s level=%0d",
                 cycle_q, u_correlated_tx.fifo_wr_data,
                 src_name(u_correlated_tx.arb_pkt_source), out_level);
      end

      if (chip_tx_valid) begin
        ddr_bytes <= ddr_bytes + 1;
        $display("[TRACE] cyc=%0d DDR_TX byte=%02h", cycle_q, chip_tx_data);
      end
    end
  end

  initial begin
    rst_n = 1'b0;
    spad_event = '0;
    x_lines = '0;
    y_lines = '0;
    z_lines = '0;
    x_csr_valid = 1'b0; y_csr_valid = 1'b0; z_csr_valid = 1'b0;
    x_csr_write = 1'b0; y_csr_write = 1'b0; z_csr_write = 1'b0;
    x_csr_addr = '0; y_csr_addr = '0; z_csr_addr = '0;
    x_csr_wdata = '0; y_csr_wdata = '0; z_csr_wdata = '0;
    pos_csr_valid = 1'b0;
    pos_csr_write = 1'b0;
    pos_csr_addr = '0;
    pos_csr_wdata = '0;
    trace_words = 0;
    ddr_bytes = 0;
    output_fifo_peak = 0;
    pos_fifo_peak = 0;
    tdc_fifo_peak[0] = 0;
    tdc_fifo_peak[1] = 0;
    tdc_fifo_peak[2] = 0;
    errors = 0;

    repeat (6) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (12) @(posedge clk_sys);

    tdc_csr_write_all(CSR_MAX_HITS, CSR_DATA_W'(MAX_HITS));
    tdc_csr_write_all(CSR_MODE, CSR_DATA_W'(OUT_MODE_FULL) << 2);
    tdc_csr_write_all(CSR_CTRL, CSR_DATA_W'(1));
    position_csr_write(SPADMIC_CSR_POS_CTRL, SPADMIC_CSR_DATA_W'(3));

    wait (clk_ref_40m == 1'b0);
    #1000;
    fork
      begin
        fire_event(1);
        #(25000 - 18000);
        fire_event(2);
        #(25000 - 18000);
        fire_event(3);
      end
    join

    repeat (900) @(posedge clk_sys);

    $display("[WATERMARK] tdc_x_internal_fifo_peak=%0d depth=64", tdc_fifo_peak[0]);
    $display("[WATERMARK] tdc_y_internal_fifo_peak=%0d depth=64", tdc_fifo_peak[1]);
    $display("[WATERMARK] tdc_z_internal_fifo_peak=%0d depth=64", tdc_fifo_peak[2]);
    $display("[WATERMARK] position_frame_fifo_peak=%0d depth=%0d", pos_fifo_peak, SPADMIC_POS_QUEUE_DEPTH);
    $display("[WATERMARK] arb_output_fifo_peak=%0d depth=%0d", output_fifo_peak, SPADMIC_OUTPUT_FIFO_DEPTH);
    $display("[SUMMARY] output_fifo_words=%0d ddr_bytes=%0d", trace_words, ddr_bytes);
    $display("[SUMMARY] tdc_conv_count x=%0d y=%0d z=%0d",
             u_tdc_x.u_tdc.u_core.conv_count_r,
             u_tdc_y.u_tdc.u_core.conv_count_r,
             u_tdc_z.u_tdc.u_core.conv_count_r);
    $display("[SUMMARY] tdc_rejected_start x=%0d y=%0d z=%0d",
             u_tdc_x.u_tdc.u_core.ovf_count_r,
             u_tdc_y.u_tdc.u_core.ovf_count_r,
             u_tdc_z.u_tdc.u_core.ovf_count_r);
    $display("[SUMMARY] position_drop=%0b position_glitch=%0b corr_overflow=%0b",
             position_drop_sticky, position_glitch_sticky, corr_overflow);

    if (axis_fifo_full != 3'b000) fail("TDC internal FIFO reported full");
    if (position_drop_sticky) fail("position frame dropped");
    if (corr_overflow) fail("correlation event tag overflow");
    if (u_tdc_x.u_tdc.u_core.ovf_count_r != 0) fail("TDC_X rejected at least one START");
    if (u_tdc_y.u_tdc.u_core.ovf_count_r != 0) fail("TDC_Y rejected at least one START");
    if (u_tdc_z.u_tdc.u_core.ovf_count_r != 0) fail("TDC_Z rejected at least one START");

    if (errors == 0) begin
      $display("PASS tb_spadmic_top_stress");
      $finish;
    end

    $display("FAIL tb_spadmic_top_stress errors=%0d", errors);
    $fatal(1);
  end
endmodule

`default_nettype wire
