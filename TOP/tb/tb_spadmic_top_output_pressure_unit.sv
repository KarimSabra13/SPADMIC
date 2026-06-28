`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_top_output_pressure_unit;
  import spadmic_pkg::*;

  localparam int CLK_SYS_PERIOD = 6250;
  localparam int CLK_CFG_PERIOD = 25000;

  logic clk_sys;
  logic clk_ref_40m;
  logic clk_cfg_40m;
  logic async_rst_n;
  wire i2c_sda_oe;
  logic [63:0] R;
  logic [63:0] Y;
  logic [63:0] B;
  wire [63:0] Rz;
  wire [63:0] Yz;
  wire [63:0] Bz;
  wire [43:0] matrix_din;
  wire [43:0] matrix_cin;
  logic [43:0] matrix_dout;
  logic [43:0] matrix_cout;
  wire [15:0] ddr_data_l;
  wire [15:0] ddr_data_h;
  wire ddr_pair_valid;
  wire ddr_clk;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_SYS_PERIOD/2) clk_sys = ~clk_sys;

  initial clk_ref_40m = 1'b0;
  always #(CLK_CFG_PERIOD/2) clk_ref_40m = ~clk_ref_40m;

  initial clk_cfg_40m = 1'b0;
  always #(CLK_CFG_PERIOD/2) clk_cfg_40m = ~clk_cfg_40m;

  spadmic_top_matrix_v1 dut (
    .clk_sys(clk_sys),
    .clk_ref_40m(clk_ref_40m),
    .clk_cfg_40m(clk_cfg_40m),
    .async_rst_n(async_rst_n),
    .i2c_scl_i(1'b1),
    .i2c_sda_i(1'b1),
    .i2c_sda_oe_o(i2c_sda_oe),
    .R_i(R),
    .Y_i(Y),
    .B_i(B),
    .Rz_o(Rz),
    .Yz_o(Yz),
    .Bz_o(Bz),
    .matrix_din_o(matrix_din),
    .matrix_cin_o(matrix_cin),
    .matrix_dout_i(matrix_dout),
    .matrix_cout_i(matrix_cout),
    .cal_r_start_async_i(1'b0),
    .cal_r_stop_async_i(1'b0),
    .cal_y_start_async_i(1'b0),
    .cal_y_stop_async_i(1'b0),
    .cal_b_start_async_i(1'b0),
    .cal_b_stop_async_i(1'b0),
    .ddr_data_l_o(ddr_data_l),
    .ddr_data_h_o(ddr_data_h),
    .ddr_pair_valid_o(ddr_pair_valid),
    .ddr_clk_o(ddr_clk)
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

  initial begin
    pass_count = 0;
    fail_count = 0;
    async_rst_n = 1'b0;
    R = '0;
    Y = '0;
    B = '0;
    matrix_dout = '0;
    matrix_cout = '0;

    repeat (8) @(posedge clk_sys);
    async_rst_n = 1'b1;
    repeat (12) @(posedge clk_sys);
    #1;

    // White-box pressure injection: keep all non-output resources ready and
    // vary only the FIFO free-space/status wires that feed admission control.
    force dut.active_mode = SPADMIC_MODE_POSITION_ONLY;
    force dut.global_enable = 1'b1;
    force dut.active_axis_mask = 3'b111;
    force dut.event_idle = 1'b1;
    force dut.snapshot_busy = 1'b0;
    force dut.reset_busy = 1'b0;
    force dut.matrix_cfg_busy = 1'b0;
    force dut.pos_packet_busy = 1'b0;
    force dut.pos_packet_pending = 1'b0;
    force dut.output_fifo_free_words =
        SPADMIC_OUTPUT_FIFO_LEVEL_W'(SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES - 1);
    force dut.output_fifo_empty = 1'b1;
    force dut.bundle_flush_pending_q = 1'b0;
    #1;
    check("free words below reservation blocks output capacity",
          !dut.output_capacity_available);
    check("free words below reservation blocks pre-event resources",
          !dut.pre_event_resources_ready);

    force dut.output_fifo_free_words =
        SPADMIC_OUTPUT_FIFO_LEVEL_W'(SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES);
    #1;
    check("reservation boundary is sufficient", dut.output_capacity_available);
    check("pre-event resources recover at reservation boundary",
          dut.pre_event_resources_ready);

    force dut.output_fifo_empty = 1'b0;
    #1;
    check("nonempty output FIFO prevents safe idle", !dut.safe_idle);

    force dut.output_fifo_empty = 1'b1;
    force dut.bundle_flush_pending_q = 1'b1;
    #1;
    check("pending DDR flush prevents safe idle", !dut.safe_idle);

    release dut.active_mode;
    release dut.global_enable;
    release dut.active_axis_mask;
    release dut.event_idle;
    release dut.snapshot_busy;
    release dut.reset_busy;
    release dut.matrix_cfg_busy;
    release dut.pos_packet_busy;
    release dut.pos_packet_pending;
    release dut.output_fifo_free_words;
    release dut.output_fifo_empty;
    release dut.bundle_flush_pending_q;

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_top_output_pressure_unit: %0d failures", fail_count);

    $display("tb_spadmic_top_output_pressure_unit: %0d pass / %0d fail",
             pass_count, fail_count);
    $finish;
  end

  initial begin
    #1_000_000_000;
    $fatal(1, "tb_spadmic_top_output_pressure_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
