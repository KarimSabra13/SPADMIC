`timescale 1ps/1ps
`default_nettype none

module tb_johnson_decode_unit;
  import mptdc_pkg::*;

  int pass_cnt;
  int fail_cnt;

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
    logic [SLOW_EPOCH_STAGES-1:0] state;
    pass_cnt = 0;
    fail_cnt = 0;
    state = '0;

    for (int i = 0; i < SLOW_EPOCH_STATES; i++) begin
      check(slow_johnson_valid(state), $sformatf("valid Johnson state %0d", i));
      check(slow_johnson_to_count(state) == i[NSLOW_W-1:0],
            $sformatf("decode state %0d", i));
      state = slow_johnson_next(state);
    end
    check(state == '0, "decode sequence wraps after 128 states");

    state = '0;
    state[0] = 1'b1;
    state[3] = 1'b1;
    check(!slow_johnson_valid(state), "invalid non-contiguous state is flagged");

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_johnson_decode_unit failed");
    $display("TEST PASSED");
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_johnson_decode_unit timeout");
  end
endmodule

`default_nettype wire
