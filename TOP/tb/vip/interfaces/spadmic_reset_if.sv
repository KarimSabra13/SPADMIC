// =============================================================================
// SPADMIC VIP — Reset Interface
// Owns the DUT async reset line so reset tests can drive a real chip-level
// reset pulse instead of only notifying the scoreboard.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface spadmic_reset_if (
  input wire clk_sys
);

  logic rst_n;

  task automatic apply_startup_reset(input int unsigned cycles_low);
    rst_n = 1'b0;
    repeat (cycles_low) @(posedge clk_sys);
    rst_n = 1'b1;
    @(posedge clk_sys);
  endtask

  task automatic pulse_reset_ns(input int unsigned duration_ns);
    rst_n = 1'b0;
    #(64'd1000 * duration_ns);
    rst_n = 1'b1;
    repeat (4) @(posedge clk_sys);
  endtask

  initial begin
    rst_n = 1'b0;
  end

endinterface

`default_nettype wire
