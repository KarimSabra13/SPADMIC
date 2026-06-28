`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_matrix_or_tree_unit;
  localparam int LINE_W = 64;

  logic [LINE_W-1:0] lines;
  wire event_o;
  int pass_count;
  int fail_count;

  spadmic_matrix_or_tree #(.LINE_W(LINE_W)) dut (
    .lines_i(lines),
    .event_o(event_o)
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
    lines      = '0;
    #1;
    check("all-zero input clears event", event_o == 1'b0);

    for (int i = 0; i < LINE_W; i++) begin
      lines = '0;
      lines[i] = 1'b1;
      #1;
      check($sformatf("input bit %0d reaches output", i), event_o == 1'b1);
    end

    lines = '0;
    #1;
    check("event returns low after all bits clear", event_o == 1'b0);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_matrix_or_tree_unit: %0d failures", fail_count);

    $display("tb_spadmic_matrix_or_tree_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end
endmodule

`default_nettype wire
