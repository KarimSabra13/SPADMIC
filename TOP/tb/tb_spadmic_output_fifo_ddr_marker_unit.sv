`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_output_fifo_ddr_marker_unit;
  localparam int CLK_PERIOD = 6250;
  localparam int DATA_W = 17;
  localparam int DEPTH = 8;
  localparam int LEVEL_W = $clog2(DEPTH + 1);

  logic clk_sys;
  logic rst_n;
  logic push_valid;
  logic [DATA_W-1:0] push_data;
  wire push_ready;
  wire pop_valid;
  logic pop_ready;
  wire [DATA_W-1:0] pop_data;
  wire pop_fire;
  wire [LEVEL_W-1:0] level;
  wire [LEVEL_W-1:0] free_words;
  wire fifo_empty;
  wire fifo_full;
  wire fifo_almost_full;
  wire fifo_overflow;
  logic drain_enable;

  wire pop_is_flush = pop_data[16];
  wire ddr_word_valid = pop_fire && !pop_is_flush;
  wire [15:0] ddr_word_data = pop_data[15:0];
  wire ddr_flush = pop_fire && pop_is_flush;
  wire ddr_word_ready;
  wire [15:0] ddr_data_l;
  wire [15:0] ddr_data_h;
  wire ddr_pair_valid;
  wire ddr_padded;
  wire ddr_clk;
  wire ddr_busy;
  wire ddr_empty;

  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  assign pop_ready = drain_enable && (pop_is_flush ? 1'b1 : ddr_word_ready);
  assign pop_fire = pop_valid && pop_ready;

  spadmic_output_fifo #(
    .DATA_W(DATA_W),
    .DEPTH(DEPTH),
    .RESERVE_WORDS(3),
    .LEVEL_W(LEVEL_W)
  ) u_fifo (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .push_valid_i(push_valid),
    .push_ready_o(push_ready),
    .push_data_i(push_data),
    .pop_valid_o(pop_valid),
    .pop_ready_i(pop_ready),
    .pop_data_o(pop_data),
    .level_o(level),
    .free_words_o(free_words),
    .empty_o(fifo_empty),
    .full_o(fifo_full),
    .almost_full_o(fifo_almost_full),
    .overflow_o(fifo_overflow)
  );

  spadmic_ddr16_tx_pairer u_pairer (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .word_valid_i(ddr_word_valid),
    .word_data_i(ddr_word_data),
    .flush_i(ddr_flush),
    .word_ready_o(ddr_word_ready),
    .ddr_data_l_o(ddr_data_l),
    .ddr_data_h_o(ddr_data_h),
    .ddr_pair_valid_o(ddr_pair_valid),
    .ddr_padded_o(ddr_padded),
    .ddr_clk_o(ddr_clk),
    .busy_o(ddr_busy),
    .empty_o(ddr_empty)
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

  task automatic push_entry(input logic is_flush, input logic [15:0] data);
    begin
      @(negedge clk_sys);
      push_valid = 1'b1;
      push_data = {is_flush, data};
      @(posedge clk_sys);
      #1;
      check("FIFO accepts queued entry", push_ready);
      @(negedge clk_sys);
      push_valid = 1'b0;
      push_data = '0;
    end
  endtask

  task automatic wait_pair(
    output logic [15:0] data_l,
    output logic [15:0] data_h,
    output logic padded
  );
    int timeout;
    begin
      data_l = '0;
      data_h = '0;
      padded = 1'b0;
      for (timeout = 0; timeout < 16; timeout++) begin
        @(posedge clk_sys);
        #1;
        if (ddr_pair_valid) begin
          data_l = ddr_data_l;
          data_h = ddr_data_h;
          padded = ddr_padded;
          return;
        end
      end
      check("timed out waiting for DDR pair", 1'b0);
    end
  endtask

  initial begin
    logic [15:0] pair_l;
    logic [15:0] pair_h;
    logic pair_padded;

    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    push_valid = 1'b0;
    push_data = '0;
    drain_enable = 1'b0;

    repeat (3) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);
    #1;
    check("reset leaves FIFO empty", fifo_empty);
    check("reset leaves pairer empty", ddr_empty);

    push_entry(1'b0, 16'hAAAA);
    push_entry(1'b1, 16'h0000);
    push_entry(1'b0, 16'hBBBB);
    push_entry(1'b1, 16'h0000);
    #1;
    check("two odd bundles queued with markers", level == LEVEL_W'(4));
    check("pairer remains empty while FIFO drain is blocked", ddr_empty);

    drain_enable = 1'b1;
    wait_pair(pair_l, pair_h, pair_padded);
    check("first odd bundle keeps DATA_L", pair_l == 16'hAAAA);
    check("first odd bundle pads DATA_H", pair_h == 16'h0000);
    check("first odd bundle reports padded", pair_padded);

    wait_pair(pair_l, pair_h, pair_padded);
    check("second odd bundle keeps DATA_L", pair_l == 16'hBBBB);
    check("second odd bundle pads DATA_H", pair_h == 16'h0000);
    check("second odd bundle reports padded", pair_padded);

    repeat (4) @(posedge clk_sys);
    #1;
    check("FIFO drains after ordered markers", fifo_empty);
    check("pairer returns empty after ordered markers", ddr_empty);
    check("no FIFO overflow during marker test", !fifo_overflow);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_output_fifo_ddr_marker_unit: %0d failures", fail_count);

    $display("tb_spadmic_output_fifo_ddr_marker_unit: %0d pass / %0d fail",
             pass_count, fail_count);
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_spadmic_output_fifo_ddr_marker_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
