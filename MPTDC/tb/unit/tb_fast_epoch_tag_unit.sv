`timescale 1ps/1ps
`default_nettype none

module tb_fast_epoch_tag_unit;
  import mptdc_pkg::*;

  logic clk_fast;
  logic rst_n;
  logic clear_window;
  logic enable_i;
  logic [NFAST_W-1:0] tag_lfsr;
  logic [NFAST_W-1:0] tag_galois;

  int pass_cnt;
  int fail_cnt;

  mptdc_fast_epoch_tag #(
    .TAG_ENCODING_SEL(TAG_ENC_LFSR_FIBONACCI)
  ) u_lfsr (
    .clk_fast     (clk_fast),
    .rst_n        (rst_n),
    .clear_window (clear_window),
    .enable_i     (enable_i),
    .tag_o        (tag_lfsr)
  );

  mptdc_fast_epoch_tag #(
    .TAG_ENCODING_SEL(TAG_ENC_GALOIS)
  ) u_galois (
    .clk_fast     (clk_fast),
    .rst_n        (rst_n),
    .clear_window (clear_window),
    .enable_i     (enable_i),
    .tag_o        (tag_galois)
  );

  task automatic tick();
    begin
      #5 clk_fast = 1'b1;
      #5 clk_fast = 1'b0;
      #1;
    end
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

  function automatic logic [NFAST_W-1:0] expected_next(
    input logic [NFAST_W-1:0] state_i,
    input int unsigned        tag_encoding_sel_i
  );
    expected_next = fast_tag_next_sel(state_i, tag_encoding_sel_i);
  endfunction

  task automatic check_full_sequence(
    input string       label,
    input int unsigned tag_encoding_sel_i
  );
    logic [NFAST_W-1:0] expected;
    logic [127:0] seen;
    begin
      seen = '0;
      expected = FAST_TAG_SEED;
      for (int i = 0; i < FAST_TAG_SEQUENCE_LEN; i++) begin
        check(expected != '0, $sformatf("%s state %0d is non-zero", label, i));
        check(!seen[int'(expected)], $sformatf("%s state %0d not repeated early", label, i));
        seen[int'(expected)] = 1'b1;
        expected = expected_next(expected, tag_encoding_sel_i);
      end
      check(expected == FAST_TAG_SEED,
            $sformatf("%s maximal 127-state sequence returns to seed", label));
    end
  endtask

  initial begin
    logic [NFAST_W-1:0] expected_lfsr;
    logic [NFAST_W-1:0] expected_galois;

    pass_cnt = 0;
    fail_cnt = 0;
    clk_fast = 1'b0;
    rst_n = 1'b0;
    clear_window = 1'b0;
    enable_i = 1'b0;

    tick();
    #20 rst_n = 1'b1;
    #1;
    check(tag_lfsr == FAST_TAG_SEED, "LFSR reset loads non-zero seed");
    check(tag_galois == FAST_TAG_SEED, "Galois reset loads non-zero seed");

    expected_lfsr = fast_tag_next(FAST_TAG_SEED);
    expected_galois = fast_tag_galois_next(FAST_TAG_SEED);
    tick();
    check(tag_lfsr == expected_lfsr, "LFSR tag advances every clock edge with enable=0 ignored");
    check(tag_galois == expected_galois, "Galois tag advances every clock edge with enable=0 ignored");

    enable_i = 1'b1;
    expected_lfsr = fast_tag_next(expected_lfsr);
    expected_galois = fast_tag_galois_next(expected_galois);
    tick();
    check(tag_lfsr == expected_lfsr, "LFSR tag also advances with enable=1");
    check(tag_galois == expected_galois, "Galois tag also advances with enable=1");

    enable_i = 1'b0;
    expected_lfsr = fast_tag_next(expected_lfsr);
    expected_galois = fast_tag_galois_next(expected_galois);
    tick();
    check(tag_lfsr == expected_lfsr, "LFSR enable input does not gate the muxless tag");
    check(tag_galois == expected_galois, "Galois enable input does not gate the muxless tag");

    check(fast_tag_galois_next(7'd64) == 7'd3,
          "Galois prefix matches software mask 0x03 after state 64");

    clear_window = 1'b1;
    #1;
    check(tag_lfsr == FAST_TAG_SEED, "LFSR clear_window asynchronously reloads seed");
    check(tag_galois == FAST_TAG_SEED, "Galois clear_window asynchronously reloads seed");
    clear_window = 1'b0;
    #1;

    check_full_sequence("LFSR", TAG_ENC_LFSR_FIBONACCI);
    check_full_sequence("Galois", TAG_ENC_GALOIS);

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_fast_epoch_tag_unit failed");
    $display("TEST PASSED");
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_fast_epoch_tag_unit timeout");
  end
endmodule

`default_nettype wire
