`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_ref_stop_qualifier_hold_unit;
  logic clk_ref_40m;
  logic rst_n;
  logic start_async;
  wire stop_async;
  wire armed;
  int pass_cnt;
  int fail_cnt;
  int stop_rise_cnt;

  initial clk_ref_40m = 1'b0;
  always #12_500 clk_ref_40m = ~clk_ref_40m;

  spadmic_ref_stop_qualifier dut (
    .rst_n(rst_n),
    .start_async_i(start_async),
    .clk_ref_40m(clk_ref_40m),
    .stop_async_o(stop_async),
    .armed_o(armed)
  );

  always @(posedge stop_async)
    stop_rise_cnt <= stop_rise_cnt + 1;

  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s", label);
      fail_cnt++;
    end
  endtask

  initial begin
    pass_cnt = 0;
    fail_cnt = 0;
    stop_rise_cnt = 0;
    rst_n = 0;
    start_async = 0;
    #20_000;
    rst_n = 1;
    @(negedge clk_ref_40m);
    #1_000;
    start_async = 1'b1;
    repeat (3) @(posedge clk_ref_40m);
    #1;
    check("Held-high request emits only one stop", stop_rise_cnt == 1);
    check("Qualifier stays disarmed until release", armed == 1'b0);
    start_async = 1'b0;
    @(negedge clk_ref_40m);
    #1_000;
    start_async = 1'b1;
    @(posedge stop_async);
    #1;
    check("Qualifier rearms only after source drops low", stop_rise_cnt == 2);

    if (fail_cnt != 0)
      $fatal(1, "tb_spadmic_ref_stop_qualifier_hold_unit: %0d failures", fail_cnt);

    $display("tb_spadmic_ref_stop_qualifier_hold_unit: %0d pass / %0d fail", pass_cnt, fail_cnt);
    $finish;
  end

  initial begin
    #500_000;
    $fatal(1, "tb_spadmic_ref_stop_qualifier_hold_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
