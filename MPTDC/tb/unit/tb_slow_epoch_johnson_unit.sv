`timescale 1ps/1ps
`default_nettype none

module tb_slow_epoch_johnson_unit;
  import mptdc_pkg::*;

  logic clk_slow;
  logic rst_n;
  logic clear_window;
  logic enable;
  logic [SLOW_EPOCH_STAGES-1:0] johnson;

  int pass_cnt;
  int fail_cnt;

  mptdc_slow_epoch_johnson u_dut (
    .clk_slow     (clk_slow),
    .rst_n        (rst_n),
    .clear_window (clear_window),
    .enable_i     (enable),
    .johnson_o    (johnson)
  );

  initial clk_slow = 1'b0;
  always #5 clk_slow = ~clk_slow;

  task automatic tick();
    @(posedge clk_slow);
    #1;
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

  function automatic int unsigned popcount64(input logic [SLOW_EPOCH_STAGES-1:0] value);
    automatic int unsigned count;
    count = 0;
    for (int i = 0; i < SLOW_EPOCH_STAGES; i++)
      if (value[i]) count++;
    popcount64 = count;
  endfunction

  initial begin
    logic [SLOW_EPOCH_STAGES-1:0] prev;
    logic [SLOW_EPOCH_STATES-1:0] seen;
    int unsigned decoded;
    pass_cnt = 0;
    fail_cnt = 0;
    rst_n = 1'b0;
    clear_window = 1'b0;
    enable = 1'b0;
    seen = '0;

    repeat (2) tick();
    rst_n = 1'b1;
    tick();
    check(johnson == '0, "reset gives all-zero Johnson state");

    enable = 1'b0;
    repeat (4) tick();
    check(johnson == '0, "enable=0 holds state");

    enable = 1'b1;
    for (int i = 0; i < SLOW_EPOCH_STATES; i++) begin
      decoded = slow_johnson_to_count(johnson);
      check(slow_johnson_valid(johnson), $sformatf("state %0d is valid", i));
      check(decoded == i[NSLOW_W-1:0], $sformatf("state %0d decodes to %0d", i, i));
      check(!seen[decoded], $sformatf("state %0d is unique", i));
      seen[decoded] = 1'b1;
      prev = johnson;
      tick();
      check(popcount64(prev ^ johnson) == 1, $sformatf("step %0d changes one bit", i));
    end
    check(johnson == '0, "sequence returns to zero after 128 states");

    clear_window = 1'b1;
    #1;
    check(johnson == '0, "async clear resets state");
    clear_window = 1'b0;

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_slow_epoch_johnson_unit failed");
    $display("TEST PASSED");
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_slow_epoch_johnson_unit timeout");
  end
endmodule

`default_nettype wire
