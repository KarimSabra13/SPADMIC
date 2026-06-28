`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_top_output_fifo_pressure_integration_unit;
  import spadmic_pkg::*;

  localparam int CLK_SYS_PERIOD   = 6250;
  localparam int CLK_40M_PERIOD   = 25000;
  localparam int I2C_HALF_PERIOD  = 200_000;
  localparam int I2C_SAMPLE_DELAY = I2C_HALF_PERIOD/2;
  localparam int POS_RAW_WORDS    = SPADMIC_POS_RAW_PKT_WORDS;
  localparam int FIFO_ENTRIES_PER_RAW_EVENT = SPADMIC_POS_RAW_PKT_WORDS + 1;

  logic clk_sys;
  logic clk_ref_40m;
  logic clk_cfg_40m;
  logic async_rst_n;
  logic i2c_scl_drv;
  logic i2c_sda_master_low;
  wire i2c_scl = i2c_scl_drv;
  wire i2c_sda;
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
  int ddr_word_count;
  logic [15:0] ddr_words [0:255];

  assign i2c_sda = (i2c_sda_master_low | i2c_sda_oe) ? 1'b0 : 1'b1;

  initial clk_sys = 1'b0;
  always #(CLK_SYS_PERIOD/2) clk_sys = ~clk_sys;

  initial clk_ref_40m = 1'b0;
  always #(CLK_40M_PERIOD/2) clk_ref_40m = ~clk_ref_40m;

  initial clk_cfg_40m = 1'b0;
  always #(CLK_40M_PERIOD/2) clk_cfg_40m = ~clk_cfg_40m;

  spadmic_top_matrix_v1 dut (
    .clk_sys(clk_sys),
    .clk_ref_40m(clk_ref_40m),
    .clk_cfg_40m(clk_cfg_40m),
    .async_rst_n(async_rst_n),
    .i2c_scl_i(i2c_scl),
    .i2c_sda_i(i2c_sda),
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

  `include "TOP/tb/spadmic_top_matrix_v1_i2c_tasks.svh"

  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_count++;
    end else begin
      $display("[FAIL] %s", label);
      fail_count++;
    end
  endtask

  always_ff @(posedge clk_sys or negedge async_rst_n) begin
    if (!async_rst_n) begin
      ddr_word_count <= 0;
      for (int i = 0; i < 256; i++)
        ddr_words[i] <= '0;
    end else if (ddr_pair_valid) begin
      if (ddr_word_count < 255) begin
        ddr_words[ddr_word_count] <= ddr_data_l;
        ddr_words[ddr_word_count + 1] <= ddr_data_h;
        ddr_word_count <= ddr_word_count + 2;
      end
    end
  end

  function automatic int find_eoc_index(input logic [13:0] event_id);
    int result;
    result = -1;
    for (int i = 0; i < 256; i++) begin
      if ((i < ddr_word_count) && (ddr_words[i] == {2'b11, event_id}) &&
          (result < 0))
        result = i;
    end
    return result;
  endfunction

  task automatic wait_pre_event_ready(input string label);
    int guard;
    begin
      guard = 0;
      while (!dut.pre_event_resources_ready && guard < 20_000) begin
        guard++;
        @(posedge clk_sys);
      end
      check(label, dut.pre_event_resources_ready);
    end
  endtask

  task automatic wait_event_idle(input string label);
    int guard;
    begin
      guard = 0;
      while (!dut.event_idle && guard < 50_000) begin
        guard++;
        @(posedge clk_sys);
      end
      check(label, dut.event_idle);
    end
  endtask

  task automatic inject_position_event(input int idx);
    int base_bit;
    begin
      base_bit = idx * 2;
      wait_pre_event_ready($sformatf("event %0d has FIFO capacity before acceptance", idx));
      R[base_bit]     = 1'b1;
      Y[base_bit + 1] = 1'b1;
      B[base_bit + 2] = 1'b1;
      wait (Rz != {64{1'b1}});
      repeat (4) @(posedge clk_sys);
      R = '0;
      Y = '0;
      B = '0;
      wait_event_idle($sformatf("event %0d closes while DDR is stalled", idx));
    end
  endtask

  initial begin
    logic [31:0] rd;
    int wait_cycles;
    int eoc0;
    int eoc1;
    int eoc2;

    pass_count = 0;
    fail_count = 0;
    async_rst_n = 1'b0;
    i2c_scl_drv = 1'b1;
    i2c_sda_master_low = 1'b0;
    R = '0;
    Y = '0;
    B = '0;
    matrix_dout = '0;
    matrix_cout = '0;

    repeat (8) @(posedge clk_sys);
    async_rst_n = 1'b1;
    repeat (12) @(posedge clk_sys);

    i2c_write_csr(SPADMIC_CSR_MATRIX_RESET_CTRL, 32'h0001_0003);
    i2c_write_csr(SPADMIC_CSR_POSITION_MODE, 32'h0000_0001);
    i2c_write_csr(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_POSITION_ONLY, 1'b1});
    i2c_read_csr(SPADMIC_CSR_MTOP_CTRL_ACTIVE, rd);
    check("I2C commits position-only active mode", rd[3:1] == SPADMIC_MODE_POSITION_ONLY);

    // Fault-injection: model a temporarily stalled downstream DDR macro input.
    // This does not modify admission equations; it only prevents FIFO pop into
    // the pairer while real top-level events are accepted and bundled.
    force dut.ddr_word_ready = 1'b0;

    inject_position_event(0);
    check("one real raw-position bundle is queued in FIFO",
          dut.output_fifo_level >=
          SPADMIC_OUTPUT_FIFO_LEVEL_W'(FIFO_ENTRIES_PER_RAW_EVENT));
    check("DDR receives no words while forced stalled", ddr_word_count == 0);

    inject_position_event(1);
    check("two real bundles are queued in FIFO",
          dut.output_fifo_level >=
          SPADMIC_OUTPUT_FIFO_LEVEL_W'(2 * FIFO_ENTRIES_PER_RAW_EVENT));
    check("admission remains available with two queued events",
          dut.output_capacity_available);

    inject_position_event(2);
    check("three real bundles are queued in FIFO",
          dut.output_fifo_level >=
          SPADMIC_OUTPUT_FIFO_LEVEL_W'(3 * FIFO_ENTRIES_PER_RAW_EVENT));
    check("FIFO pressure makes safe_idle false while data is queued",
          !dut.safe_idle);

    release dut.ddr_word_ready;

    wait_cycles = 0;
    while (!dut.safe_idle && wait_cycles < 100_000) begin
      wait_cycles++;
      @(posedge clk_sys);
    end
    check("FIFO drains to safe idle after DDR stall releases", dut.safe_idle);
    check("drained stream contains at least three raw position packets",
          ddr_word_count >= (3 * POS_RAW_WORDS));

    eoc0 = find_eoc_index(14'h0000);
    eoc1 = find_eoc_index(14'h0001);
    eoc2 = find_eoc_index(14'h0002);
    check("event ID 0 EOC exits FIFO", eoc0 >= 0);
    check("event ID 1 EOC exits FIFO", eoc1 >= 0);
    check("event ID 2 EOC exits FIFO", eoc2 >= 0);
    check("EOC event IDs preserve FIFO order", (eoc0 >= 0) && (eoc0 < eoc1) && (eoc1 < eoc2));

    i2c_read_csr(SPADMIC_CSR_OUTPUT_FIFO_STATUS, rd);
    check("CSR reports FIFO empty after drain", rd[0]);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_top_output_fifo_pressure_integration_unit: %0d failures", fail_count);

    $display("tb_spadmic_top_output_fifo_pressure_integration_unit: %0d pass / %0d fail",
             pass_count, fail_count);
    $finish;
  end

  initial begin
    #6_000_000_000;
    $fatal(1, "tb_spadmic_top_output_fifo_pressure_integration_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
