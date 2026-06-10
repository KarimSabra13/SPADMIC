`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC - Fixed-Packet Vernier TDC
// File     : mptdc_input_mux.sv
// Purpose  : Route either the SPAD async pair or the calibration async pair
//            into the active TDC core
// Author   : Karim Sabra
// =============================================================================
// This block is intentionally a pure combinational mux.
//
// Why no registering:
//   - START and STOP are asynchronous edge events, not synchronous payloads
//   - adding a pipeline stage here would distort the very timing relationship
//     the TDC is trying to measure
//
// Safe-usage assumption:
//   - input_sel_i is configured through CSR and kept stable while a conversion
//     is active; switching it mid-conversion would deliberately violate the
//     intended operating model
// =============================================================================

module mptdc_input_mux
  import mptdc_pkg::*;
(
    // -- System (unused — kept for uniform instantiation style) -------------
    input  wire         clk_sys,
    input  wire         rst_n,

    // -- SPAD matrix async inputs ------------------------------------------
    input  wire         start_spad_async_i,
    input  wire         stop_spad_async_i,

    // -- Calibration injection async inputs ---------------------------------
    input  wire         cal_start_async_i,
    input  wire         cal_stop_async_i,

    // -- Mux control (from CSR, stable during operation) --------------------
    input  mptdc_pkg::input_sel_e  input_sel_i,

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
