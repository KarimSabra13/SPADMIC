`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_ref_stop_qualifier_unit;
  logic clk_ref_40m;
  logic rst_n;
  logic start_async;
  logic stop_async;
  logic armed;
  int pass_cnt;
  int fail_cnt;
  int stop_rise_cnt;

  initial clk_ref_40m = 1'b0;
  always #12_500 clk_ref_40m = ~clk_ref_40m;

  spadmic_ref_stop_qualifier u_dut (
    .rst_n         (rst_n),
    .start_async_i (start_async),
    .clk_ref_40m   (clk_ref_40m),
    .stop_async_o  (stop_async),
    .armed_o       (armed)
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

  task automatic pulse_start(input time delay_ps);
    #(delay_ps);
    start_async = 1'b1;
    #1_000;
    start_async = 1'b0;
  endtask

  initial begin
    pass_cnt     = 0;
    fail_cnt     = 0;
    stop_rise_cnt = 0;
    rst_n        = 1'b0;
    start_async  = 1'b0;

    #20_000;
    rst_n = 1'b1;

    // Test 1: low-phase START -> next ref edge only.
    @(negedge clk_ref_40m);
    fork
      pulse_start(5_000);
    join_none
    @(posedge stop_async);
    #1;
    check("stop occurs while ref clock high", clk_ref_40m);
    @(posedge clk_ref_40m);
    #1;
    check("single stop pulse after one start", stop_rise_cnt == 1);

    // Test 2: high-phase START waits for following rising edge.
    wait (clk_ref_40m == 1'b1);
    #5_000;
    start_async = 1'b1;
    #1_000;
    start_async = 1'b0;
    check("no immediate stop during current high phase", stop_async == 1'b0);
    @(posedge stop_async);
    #1;
    check("second stop pulse eventually arrives", stop_rise_cnt == 2);

    // Test 3: multiple starts before the same ref edge still consume once.
    @(negedge clk_ref_40m);
    fork
      pulse_start(2_000);
      pulse_start(8_000);
    join
    @(posedge stop_async);
    @(posedge clk_ref_40m);
    #1;
    check("coalesced starts still produce one additional stop", stop_rise_cnt == 3);

    // Test 4: stop never asserts without a new start.
    repeat (2) @(posedge clk_ref_40m);
    check("no extra stop without start", stop_rise_cnt == 3);
    check("armed deasserts after stop consumption", armed == 1'b0);

    if (fail_cnt != 0)
      $fatal(1, "tb_spadmic_ref_stop_qualifier_unit: %0d failures", fail_cnt);

    $display("tb_spadmic_ref_stop_qualifier_unit: %0d pass / %0d fail", pass_cnt, fail_cnt);
    $finish;
  end

  initial begin
    #500_000;
    $fatal(1, "tb_spadmic_ref_stop_qualifier_unit: TIMEOUT");
  end

endmodule

`default_nettype wire
