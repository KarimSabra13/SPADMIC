// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_ref_stop_qualifier.sv
// Purpose  : Generate exactly one qualified STOP pulse on the next ref-clock
//            edge after an asynchronous START request.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

// The gate enable is latched only while clk_ref_40m is low, so the qualified
// pulse is glitch-free and self-disarms after the first consumed rising edge.
// A held-high async request must return low before a fresh STOP can be armed.
module spadmic_ref_stop_qualifier (
  input  wire rst_n,
  input  wire start_async_i,
  input  wire clk_ref_40m,
  output wire stop_async_o,
  output wire armed_o
);

  logic arm_req_q;
  logic gate_en_q;
  logic pulse_seen_q;
  logic rearm_block_q;

  always_latch begin
    if (!rst_n || pulse_seen_q)
      arm_req_q = 1'b0;
    else if (start_async_i && !rearm_block_q)
      arm_req_q = 1'b1;
  end

  always_latch begin
    if (!rst_n || !start_async_i)
      rearm_block_q = 1'b0;
    else if (pulse_seen_q)
      rearm_block_q = 1'b1;
  end

  always_latch begin
    if (!rst_n)
      gate_en_q = 1'b0;
    else if (!clk_ref_40m)
      gate_en_q = arm_req_q;
  end

  always_latch begin
    if (!rst_n || !clk_ref_40m)
      pulse_seen_q = 1'b0;
    else if (gate_en_q)
      pulse_seen_q = 1'b1;
  end

  assign stop_async_o = clk_ref_40m & gate_en_q;
  assign armed_o      = arm_req_q | gate_en_q | pulse_seen_q;

endmodule

`default_nettype wire
