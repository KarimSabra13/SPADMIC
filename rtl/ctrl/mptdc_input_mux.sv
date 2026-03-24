`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.0 — Vernier Time-to-Digital Converter
// File     : mptdc_input_mux.sv
// Purpose  : Route SPAD matrix or calibration injection signals to TDC core
// Author   : Karim Sabra
// =============================================================================
// Pure combinational mux — no registers.  The selected signals are
// asynchronous pulses; any pipeline stage would add unwanted latency.
// input_sel_i is driven from a CSR and is guaranteed stable during
// measurement, so glitch-free switching is ensured by design.
// =============================================================================

module mptdc_input_mux
  import mptdc_pkg::*;
(
    // -- System (unused — kept for uniform port conventions) ----------------
    input  wire         clk_sys,
    input  wire         rst_n,

    // -- SPAD matrix async inputs ------------------------------------------
    input  wire         start_spad_async_i,
    input  wire         stop_spad_async_i,

    // -- Calibration injection async inputs ---------------------------------
    input  wire         cal_start_async_i,
    input  wire         cal_stop_async_i,

    // -- Mux control (from CSR, stable during operation) --------------------
    input  input_sel_e  input_sel_i,

    // -- Selected async outputs to TDC core ---------------------------------
    output wire         start_async_o,
    output wire         stop_async_o
);

    assign start_async_o = (input_sel_i == INPUT_CAL) ? cal_start_async_i
                                                      : start_spad_async_i;

    assign stop_async_o  = (input_sel_i == INPUT_CAL) ? cal_stop_async_i
                                                      : stop_spad_async_i;

endmodule

`default_nettype wire
