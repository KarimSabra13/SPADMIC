// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_shared_tx_mux.sv
// Purpose  : Final one-of-two packet-source mux onto the physical chip TX bus.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_shared_tx_mux (
  input  spadmic_pkg::spadmic_tx_sel_e        tx_sel_i,

  input  wire                                 tdc_valid_i,
  input  wire [mptdc_pkg::NARROW_W-1:0]       tdc_data_i,
  output logic                                tdc_ready_o,

  input  wire                                 pos_valid_i,
  input  wire [mptdc_pkg::NARROW_W-1:0]       pos_data_i,
  output logic                                pos_ready_o,

  input  wire                                 shared_ready_i,
  output logic                                shared_valid_o,
  output logic [mptdc_pkg::NARROW_W-1:0]      shared_data_o
);
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  // The sequencer guarantees tx_sel_i only changes while both sources are idle,
  // so this mux can stay purely combinational.
  always_comb begin
    shared_valid_o = 1'b0;
    shared_data_o  = '0;
    tdc_ready_o    = 1'b0;
    pos_ready_o    = 1'b0;

    unique case (tx_sel_i)
      SPADMIC_TX_POSITION: begin
        shared_valid_o = pos_valid_i;
        shared_data_o  = pos_data_i;
        pos_ready_o    = shared_ready_i;
      end

      default: begin
        shared_valid_o = tdc_valid_i;
        shared_data_o  = tdc_data_i;
        tdc_ready_o    = shared_ready_i;
      end
    endcase
  end

endmodule

`default_nettype wire
