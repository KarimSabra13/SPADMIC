`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_matrix_cfg_ctrl_unit;
  localparam int SYS_PERIOD = 6250;
  localparam int CFG_PERIOD = 25000;
  localparam logic [2:0] OP_WRITE_COLUMN_64 = 3'd1;
  localparam logic [2:0] OP_READ_COLUMN_64  = 3'd2;
  localparam logic [2:0] OP_GLOBAL_FILL_0   = 3'd3;
  localparam logic [2:0] OP_GLOBAL_FILL_1   = 3'd4;
  localparam logic [3:0] ERR_BUSY        = 4'd1;
  localparam logic [3:0] ERR_INVALID_COL = 4'd3;
  localparam logic [3:0] ERR_CFG_RESET   = 4'd4;

  logic clk_sys;
  logic clk_cfg_40m;
  logic rst_sys_n;
  logic rst_cfg_n;
  logic cmd_start;
  logic [2:0] cmd_op;
  logic [5:0] col_idx;
  logic [63:0] wdata;
  wire busy;
  wire done;
  wire error;
  wire [3:0] last_error;
  wire [63:0] rdata;
  wire readback_valid;
  wire matrix_cfg_valid;
  wire [43:0] matrix_din;
  wire [43:0] matrix_cin;
  logic [43:0] matrix_dout;
  logic [43:0] matrix_cout;
  logic [63:0] read_pattern;
  int read_idx;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(SYS_PERIOD/2) clk_sys = ~clk_sys;

  initial clk_cfg_40m = 1'b0;
  always #(CFG_PERIOD/2) clk_cfg_40m = ~clk_cfg_40m;

  spadmic_matrix_cfg_ctrl dut (
    .clk_sys(clk_sys),
    .clk_cfg_40m(clk_cfg_40m),
    .rst_sys_n(rst_sys_n),
    .rst_cfg_n(rst_cfg_n),
    .cmd_start_i(cmd_start),
    .cmd_op_i(cmd_op),
    .col_idx_i(col_idx),
    .wdata_i(wdata),
    .busy_o(busy),
    .done_o(done),
    .error_o(error),
    .last_error_o(last_error),
    .rdata_o(rdata),
    .readback_valid_o(readback_valid),
    .matrix_cfg_valid_o(matrix_cfg_valid),
    .matrix_din_o(matrix_din),
    .matrix_cin_o(matrix_cin),
    .matrix_dout_i(matrix_dout),
    .matrix_cout_i(matrix_cout)
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

  task automatic start_cmd(
    input logic [2:0] op,
    input logic [5:0] col,
    input logic [63:0] data
  );
    begin
      @(negedge clk_sys);
      cmd_op    = op;
      col_idx   = col;
      wdata     = data;
      cmd_start = 1'b1;
      @(negedge clk_sys);
      cmd_start = 1'b0;
    end
  endtask

  task automatic wait_done;
    int guard;
    begin
      guard = 0;
      while (done && guard < 20) begin
        @(posedge clk_sys);
        #1;
        guard++;
      end
      guard = 0;
      while (guard < 2000) begin
        @(posedge clk_sys);
        #1;
        if (done)
          break;
        guard++;
      end
      check("command done before timeout", done);
    end
  endtask

  always @(negedge clk_cfg_40m) begin
    if (matrix_cin[7]) begin
      matrix_dout[7] <= read_pattern[read_idx[5:0]];
      read_idx <= read_idx + 1;
    end
  end

  initial begin
    pass_count  = 0;
    fail_count  = 0;
    rst_sys_n   = 1'b0;
    rst_cfg_n   = 1'b0;
    cmd_start   = 1'b0;
    cmd_op      = 3'd0;
    col_idx     = 6'd0;
    wdata       = '0;
    matrix_dout = '0;
    matrix_cout = '0;
    read_pattern = 64'hA55A_0123_4567_89EF;
    read_idx = 0;

    repeat (4) @(posedge clk_sys);
    rst_cfg_n = 1'b1;
    rst_sys_n = 1'b1;
    repeat (5) @(posedge clk_sys);
    #1;
    check("reset leaves controller idle", !busy && !done);
    check("reset drives matrix config outputs idle", matrix_din == '0 && matrix_cin == '0);

    start_cmd(OP_WRITE_COLUMN_64, 6'd0, 64'h0123_4567_89AB_CDEF);
    check("write command enters busy", busy);
    wait_done();
    check("write column reports no error", !error);
    check("write column readback mirrors written data", readback_valid && rdata == 64'h0123_4567_89AB_CDEF);
    check("matrix cfg valid after write", matrix_cfg_valid);

    start_cmd(OP_WRITE_COLUMN_64, 6'd43, 64'hFEDC_BA98_7654_3210);
    wait_done();
    check("write column 43 accepted", !error && rdata == 64'hFEDC_BA98_7654_3210);

    read_idx = 0;
    start_cmd(OP_READ_COLUMN_64, 6'd7, 64'h0);
    wait_done();
    check("read column reports no error", !error);
    check("readback valid after read", readback_valid);
    check("read command captures Dout serial data", rdata == read_pattern);

    start_cmd(OP_GLOBAL_FILL_0, 6'd0, 64'h0);
    wait_done();
    check("global fill 0 readback is zero", !error && rdata == 64'h0);

    start_cmd(OP_GLOBAL_FILL_1, 6'd0, 64'h0);
    wait_done();
    check("global fill 1 readback is all ones", !error && rdata == 64'hFFFF_FFFF_FFFF_FFFF);

    start_cmd(OP_WRITE_COLUMN_64, 6'd44, 64'h0);
    check("invalid column rejected", done && error && last_error == ERR_INVALID_COL && !busy);
    check("invalid column clears stale readback", !readback_valid && rdata == 64'h0);
    check("invalid column clears cfg valid conservatively", !matrix_cfg_valid);

    start_cmd(OP_WRITE_COLUMN_64, 6'd1, 64'h1234);
    @(negedge clk_sys);
    cmd_op = OP_READ_COLUMN_64;
    col_idx = 6'd2;
    cmd_start = 1'b1;
    @(posedge clk_sys);
    #1;
    check("command while busy rejected", done && error && last_error == ERR_BUSY && busy);
    check("busy reject clears stale readback", !readback_valid && rdata == 64'h0);
    check("busy reject clears cfg valid while command runs", !matrix_cfg_valid);
    cmd_start = 1'b0;
    wait_done();
    check("original command still completes", !busy);
    check("original command restores cfg valid", matrix_cfg_valid);

    start_cmd(OP_WRITE_COLUMN_64, 6'd3, 64'h5555);
    repeat (4) @(posedge clk_cfg_40m);
    rst_cfg_n = 1'b0;
    wait_done();
    check("reset abort drives outputs idle", matrix_din == '0 && matrix_cin == '0);
    check("cfg reset alone clears sys busy", !busy && error && last_error == ERR_CFG_RESET);
    check("cfg reset alone clears cfg valid", !matrix_cfg_valid);
    rst_cfg_n = 1'b1;
    repeat (5) @(posedge clk_sys);
    #1;

    start_cmd(OP_WRITE_COLUMN_64, 6'd4, 64'hAAAA);
    repeat (3) @(posedge clk_cfg_40m);
    rst_cfg_n = 1'b0;
    rst_sys_n = 1'b0;
    #1;
    check("global reset abort drives outputs idle", matrix_din == '0 && matrix_cin == '0);
    rst_cfg_n = 1'b1;
    rst_sys_n = 1'b1;
    repeat (5) @(posedge clk_sys);
    #1;
    check("reset abort clears busy", !busy);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_matrix_cfg_ctrl_unit: %0d failures", fail_count);

    $display("tb_spadmic_matrix_cfg_ctrl_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #100_000_000;
    $fatal(1, "tb_spadmic_matrix_cfg_ctrl_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
