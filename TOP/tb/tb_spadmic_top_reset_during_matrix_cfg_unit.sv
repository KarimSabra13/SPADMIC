`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_top_reset_during_matrix_cfg_unit;
  localparam int SYS_PERIOD = 6250;
  localparam int CFG_PERIOD = 25000;
  localparam logic [2:0] OP_WRITE_COLUMN_64 = 3'd1;
  localparam logic [3:0] ERR_CFG_RESET = 4'd4;

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
  logic saw_reset_error;
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

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n)
      saw_reset_error <= 1'b0;
    else if (done && error && last_error == ERR_CFG_RESET)
      saw_reset_error <= 1'b1;
  end

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_sys_n = 1'b0;
    rst_cfg_n = 1'b0;
    cmd_start = 1'b0;
    cmd_op = OP_WRITE_COLUMN_64;
    col_idx = 6'd3;
    wdata = 64'h0123_4567_89AB_CDEF;
    matrix_dout = '0;
    matrix_cout = '0;
    saw_reset_error = 1'b0;

    repeat (4) @(posedge clk_sys);
    rst_sys_n = 1'b1;
    rst_cfg_n = 1'b1;
    repeat (4) @(posedge clk_sys);

    @(negedge clk_sys);
    cmd_start = 1'b1;
    @(negedge clk_sys);
    cmd_start = 1'b0;
    check("matrix cfg command enters busy before reset", busy);

    repeat (4) @(posedge clk_cfg_40m);
    rst_cfg_n = 1'b0;
    repeat (6) @(posedge clk_sys);
    #1;
    check("cfg-domain reset idles physical config outputs",
          matrix_din == '0 && matrix_cin == '0);
    check("reset abort reports error", saw_reset_error);
    rst_cfg_n = 1'b1;
    repeat (12) @(posedge clk_sys);
    #1;
    check("reset abort clears readback valid", !readback_valid && rdata == 64'h0);
    check("reset abort clears matrix_cfg_valid", !matrix_cfg_valid);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_top_reset_during_matrix_cfg_unit: %0d failures", fail_count);

    $display("tb_spadmic_top_reset_during_matrix_cfg_unit: %0d pass / %0d fail",
             pass_count, fail_count);
    $finish;
  end

  initial begin
    #5_000_000;
    $fatal(1, "tb_spadmic_top_reset_during_matrix_cfg_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
