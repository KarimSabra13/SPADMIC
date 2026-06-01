`timescale 1ps/1ps
`default_nettype none

module tb_stop_epoch_capture_async_unit;
  import mptdc_pkg::*;

  logic rst_n;
  logic async_clr;
  logic stop_async;
  logic [SLOW_EPOCH_STAGES-1:0] epoch_in;
  logic [SLOW_EPOCH_STAGES-1:0] epoch_stop;

  int pass_cnt;
  int fail_cnt;

  mptdc_stop_epoch_capture_async u_dut (
    .rst_n                     (rst_n),
    .async_clr_i               (async_clr),
    .stop_async_i              (stop_async),
    .slow_epoch_johnson_i      (epoch_in),
    .slow_epoch_johnson_stop_o (epoch_stop)
  );

  task automatic pulse_stop();
    stop_async = 1'b1;
    #2;
    stop_async = 1'b0;
    #2;
  endtask

  task automatic check(input bit cond, input string label);
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
    rst_n = 1'b0;
    async_clr = 1'b0;
    stop_async = 1'b0;
    epoch_in = '0;
    #10;
    rst_n = 1'b1;
    #1;
    check(epoch_stop == '0, "reset clears stop epoch");

    epoch_in = slow_johnson_next('0);
    pulse_stop();
    check(epoch_stop == epoch_in, "STOP captures current Johnson state");

    epoch_in = slow_johnson_next(epoch_in);
    #20;
    check(epoch_stop != epoch_in, "held state does not change without STOP");

    pulse_stop();
    check(epoch_stop == epoch_in, "second STOP recaptures state");

    async_clr = 1'b1;
    #1;
    check(epoch_stop == '0, "async clear resets held state");
    async_clr = 1'b0;

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_stop_epoch_capture_async_unit failed");
    $display("TEST PASSED");
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_stop_epoch_capture_async_unit timeout");
  end
endmodule

`default_nettype wire
