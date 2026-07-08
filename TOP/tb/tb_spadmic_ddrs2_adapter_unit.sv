`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_ddrs2_adapter_unit;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_160m;
  logic rst_n;
  logic enable;
  logic [15:0] data_l;
  logic [15:0] data_h;
  logic pair_valid;
  wire [SPADMIC_DDRS2_LANE_W-1:0] macro_l;
  wire [SPADMIC_DDRS2_LANE_W-1:0] macro_h;
  wire clk_out;
  wire [SPADMIC_DDRS2_LANE_W-1:0] macro_l_inv;
  wire [SPADMIC_DDRS2_LANE_W-1:0] macro_h_inv;
  wire clk_out_inv;
  int pass_count;
  int fail_count;

  initial clk_160m = 1'b0;
  always #(CLK_PERIOD/2) clk_160m = ~clk_160m;

  spadmic_ddrs2_adapter dut (
    .clk_160m_i       (clk_160m),
    .rst_n            (rst_n),
    .enable_i         (enable),
    .ddr_data_l_i     (data_l),
    .ddr_data_h_i     (data_h),
    .ddr_pair_valid_i (pair_valid),
    .ddrs2_data_l_o   (macro_l),
    .ddrs2_data_h_o   (macro_h),
    .ddrs2_clk_160m_o (clk_out)
  );

  spadmic_ddrs2_adapter #(
    .FORWARDED_CLK_INVERT(1'b1)
  ) dut_inverted (
    .clk_160m_i       (clk_160m),
    .rst_n            (rst_n),
    .enable_i         (enable),
    .ddr_data_l_i     (data_l),
    .ddr_data_h_i     (data_h),
    .ddr_pair_valid_i (pair_valid),
    .ddrs2_data_l_o   (macro_l_inv),
    .ddrs2_data_h_o   (macro_h_inv),
    .ddrs2_clk_160m_o (clk_out_inv)
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
    rst_n      = 1'b0;
    enable     = 1'b1;
    data_l     = 16'hA55A;
    data_h     = 16'h5AA5;
    pair_valid = 1'b1;

    repeat (2) @(posedge clk_160m);
    #1;
    check("reset drives all DDRs2 DATA_L lanes low", macro_l == '0);
    check("reset drives all DDRs2 DATA_H lanes low", macro_h == '0);
    check("macro clock follows 160 MHz input during reset", clk_out == clk_160m);

    rst_n = 1'b1;
    repeat (1) @(posedge clk_160m);
    #1;
    check("lanes 0..15 map DATA_L", macro_l[15:0] == 16'hA55A);
    check("lanes 0..15 map DATA_H", macro_h[15:0] == 16'h5AA5);
    check("lane 16 carries valid on low phase", macro_l[SPADMIC_DDRS2_VALID_LANE]);
    check("lane 16 carries valid on high phase", macro_h[SPADMIC_DDRS2_VALID_LANE]);
    check("lane 17 default forwarded clock polarity is 0/1",
          macro_l[SPADMIC_DDRS2_FWD_CLK_LANE] == 1'b0 &&
          macro_h[SPADMIC_DDRS2_FWD_CLK_LANE] == 1'b1);
    check("lane 18 spare is tied low",
          macro_l[SPADMIC_DDRS2_SPARE_LANE] == 1'b0 &&
          macro_h[SPADMIC_DDRS2_SPARE_LANE] == 1'b0);

    pair_valid = 1'b0;
    data_l     = 16'h0000;
    data_h     = 16'h0000;
    #1;
    check("idle valid lane is low",
          macro_l[SPADMIC_DDRS2_VALID_LANE] == 1'b0 &&
          macro_h[SPADMIC_DDRS2_VALID_LANE] == 1'b0);
    check("idle data lanes are quiet", macro_l[15:0] == 16'h0000 && macro_h[15:0] == 16'h0000);
    check("forwarded clock lane remains available while enabled",
          macro_l[SPADMIC_DDRS2_FWD_CLK_LANE] == 1'b0 &&
          macro_h[SPADMIC_DDRS2_FWD_CLK_LANE] == 1'b1);

    pair_valid = 1'b1;
    enable     = 1'b0;
    #1;
    check("disabled adapter drives DATA_L lanes low", macro_l == '0);
    check("disabled adapter drives DATA_H lanes low", macro_h == '0);
    check("macro clock still follows 160 MHz input when disabled", clk_out == clk_160m);

    enable = 1'b1;
    #1;
    check("forwarded clock polarity can be swapped by parameter",
          macro_l_inv[SPADMIC_DDRS2_FWD_CLK_LANE] == 1'b1 &&
          macro_h_inv[SPADMIC_DDRS2_FWD_CLK_LANE] == 1'b0);
    check("inverted instance clock also follows 160 MHz input", clk_out_inv == clk_160m);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_ddrs2_adapter_unit: %0d failures", fail_count);

    $display("tb_spadmic_ddrs2_adapter_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_spadmic_ddrs2_adapter_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
