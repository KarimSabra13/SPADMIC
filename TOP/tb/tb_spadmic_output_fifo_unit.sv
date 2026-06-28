`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_output_fifo_unit;
  localparam int CLK_PERIOD = 6250;
  localparam int DATA_W = 16;
  localparam int DEPTH = 8;
  localparam int RESERVE_WORDS = 3;
  localparam int LEVEL_W = $clog2(DEPTH + 1);

  logic clk_sys;
  logic rst_n;
  logic push_valid;
  wire push_ready;
  logic [DATA_W-1:0] push_data;
  wire pop_valid;
  logic pop_ready;
  wire [DATA_W-1:0] pop_data;
  wire [LEVEL_W-1:0] level;
  wire [LEVEL_W-1:0] free_words;
  wire empty;
  wire full;
  wire almost_full;
  wire overflow;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_output_fifo #(
    .DATA_W(DATA_W),
    .DEPTH(DEPTH),
    .RESERVE_WORDS(RESERVE_WORDS),
    .LEVEL_W(LEVEL_W)
  ) dut (
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
    .empty_o(empty),
    .full_o(full),
    .almost_full_o(almost_full),
    .overflow_o(overflow)
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

  task automatic push_word(input logic [DATA_W-1:0] data);
    begin
      @(negedge clk_sys);
      push_valid = 1'b1;
      push_data = data;
      pop_ready = 1'b0;
      @(negedge clk_sys);
      push_valid = 1'b0;
      push_data = '0;
    end
  endtask

  task automatic pop_word(output logic [DATA_W-1:0] data);
    begin
      @(negedge clk_sys);
      push_valid = 1'b0;
      pop_ready = 1'b1;
      #1;
      data = pop_data;
      @(negedge clk_sys);
      pop_ready = 1'b0;
    end
  endtask

  initial begin
    logic [DATA_W-1:0] data;

    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    push_valid = 1'b0;
    push_data = '0;
    pop_ready = 1'b0;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);
    #1;
    check("reset leaves FIFO empty", empty && pop_valid == 1'b0);
    check("reset leaves push ready", push_ready);
    check("reset reports full free space", free_words == LEVEL_W'(DEPTH));

    push_word(16'h1001);
    push_word(16'h1002);
    push_word(16'h1003);
    #1;
    check("three pushes update level", level == LEVEL_W'(3));
    check("free words update after pushes", free_words == LEVEL_W'(5));
    check("reserve threshold not yet almost full", !almost_full);

    pop_word(data);
    #1;
    check("first popped word preserves order", data == 16'h1001);
    pop_word(data);
    #1;
    check("second popped word preserves order", data == 16'h1002);

    for (int idx = 0; idx < DEPTH; idx++)
      push_word(16'h2000 + DATA_W'(idx));
    #1;
    check("FIFO reaches full", full && !push_ready);
    check("FIFO reports zero free words", free_words == '0);
    check("FIFO almost_full asserted when reserved free space missing", almost_full);

    @(negedge clk_sys);
    push_valid = 1'b1;
    push_data = 16'hDEAD;
    pop_ready = 1'b0;
    @(negedge clk_sys);
    push_valid = 1'b0;
    push_data = '0;
    #1;
    check("overflow pulse on push while full", overflow);
    check("overflow does not change full level", level == LEVEL_W'(DEPTH));

    @(negedge clk_sys);
    push_valid = 1'b1;
    push_data = 16'h3000;
    pop_ready = 1'b1;
    #1;
    data = pop_data;
    @(negedge clk_sys);
    push_valid = 1'b0;
    push_data = '0;
    pop_ready = 1'b0;
    #1;
    check("simultaneous full pop returns oldest word", data == 16'h1003);
    check("simultaneous full push/pop keeps FIFO full", full && level == LEVEL_W'(DEPTH));

    for (int idx = 0; idx < DEPTH; idx++) begin
      pop_word(data);
      if (idx == DEPTH-1)
        check("simultaneous replacement exits last", data == 16'h3000);
    end
    #1;
    check("FIFO drains empty", empty && level == '0);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_output_fifo_unit: %0d failures", fail_count);

    $display("tb_spadmic_output_fifo_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #2_000_000;
    $fatal(1, "tb_spadmic_output_fifo_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
