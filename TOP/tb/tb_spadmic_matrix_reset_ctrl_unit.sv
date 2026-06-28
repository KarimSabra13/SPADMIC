`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_matrix_reset_ctrl_unit;
  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic enable;
  logic start;
  logic [15:0] width;
  logic [63:0] snap_R;
  logic [63:0] snap_Y;
  logic [63:0] snap_B;
  wire [63:0] Rz;
  wire [63:0] Yz;
  wire [63:0] Bz;
  wire busy;
  wire done;
  wire disabled;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_matrix_reset_ctrl dut (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .enable_i(enable),
    .start_i(start),
    .reset_width_i(width),
    .snapshot_R_i(snap_R),
    .snapshot_Y_i(snap_Y),
    .snapshot_B_i(snap_B),
    .Rz_o(Rz),
    .Yz_o(Yz),
    .Bz_o(Bz),
    .busy_o(busy),
    .done_o(done),
    .disabled_o(disabled)
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

  task automatic pulse_start(input int unsigned w);
    begin
      width = w[15:0];
      @(negedge clk_sys);
      start = 1'b1;
      @(posedge clk_sys);
      #1;
      start = 1'b0;
    end
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n      = 1'b0;
    enable     = 1'b1;
    start      = 1'b0;
    width      = 16'd0;
    snap_R     = '0;
    snap_Y     = '0;
    snap_B     = '0;
    snap_R[1]  = 1'b1;
    snap_R[7]  = 1'b1;
    snap_Y[2]  = 1'b1;
    snap_B[3]  = 1'b1;

    repeat (3) @(posedge clk_sys);
    #1;
    check("async reset drives Rz inactive high", Rz == {64{1'b1}});
    check("async reset drives Yz inactive high", Yz == {64{1'b1}});
    check("async reset drives Bz inactive high", Bz == {64{1'b1}});
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);

    pulse_start(0);
    check("width zero reports disabled", disabled);
    check("width zero does not assert reset", Rz == {64{1'b1}});

    pulse_start(1);
    check("width one asserts selected R bits", !Rz[1] && !Rz[7]);
    check("width one asserts selected Y/B bits", !Yz[2] && !Bz[3]);
    @(posedge clk_sys);
    #1;
    check("width one releases after one cycle", Rz == {64{1'b1}});
    check("width one done asserted", done);

    pulse_start(3);
    for (int i = 0; i < 3; i++) begin
      @(negedge clk_sys);
      check($sformatf("width three active cycle %0d", i), !Rz[1] && !Yz[2] && !Bz[3]);
    end
    @(posedge clk_sys);
    #1;
    check("width three releases after exact count", Rz == {64{1'b1}});

    pulse_start(4);
    snap_R = '0;
    snap_Y = '0;
    snap_B = '0;
    repeat (2) @(negedge clk_sys);
    check("mask remains stable while active", !Rz[1] && !Rz[7] && !Yz[2] && !Bz[3]);

    rst_n = 1'b0;
    #1;
    check("async reset releases outputs immediately", Rz == {64{1'b1}} && Yz == {64{1'b1}} && Bz == {64{1'b1}});

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_matrix_reset_ctrl_unit: %0d failures", fail_count);

    $display("tb_spadmic_matrix_reset_ctrl_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #2_000_000;
    $fatal(1, "tb_spadmic_matrix_reset_ctrl_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
