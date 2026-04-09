// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_top_sequencer.sv
// Purpose  : Drain-aware requested-to-active control sequencer for the shared
//            top-level datapath.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_top_sequencer (
  input  wire                                clk_sys,
  input  wire                                rst_n,

  input  wire                                cfg_update_i,
  input  wire                                req_global_enable_i,
  input  wire [2:0]                          req_axis_enable_i,
  input  wire                                req_position_enable_i,
  input  wire spadmic_pkg::spadmic_tx_sel_e  req_shared_tx_sel_i,
  input  wire mptdc_pkg::input_sel_e         req_tdc_input_sel_i,
  input  wire mptdc_pkg::out_mode_e          req_tdc_out_mode_i,

  input  wire                                tdc_tx_busy_i,
  input  wire [2:0]                          tdc_pkt_pending_i,
  input  wire                                position_busy_i,
  input  wire                                position_pending_i,

  output wire                                cfg_accept_o,
  output wire                                transition_busy_o,
  output logic                               active_global_enable_o,
  output logic [2:0]                         active_axis_enable_o,
  output logic                               active_position_enable_o,
  output spadmic_pkg::spadmic_tx_sel_e       active_shared_tx_sel_o,
  output mptdc_pkg::input_sel_e              active_tdc_input_sel_o,
  output mptdc_pkg::out_mode_e               active_tdc_out_mode_o
);
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  typedef enum logic [1:0] {
    SEQ_RESET = 2'd0,
    SEQ_IDLE  = 2'd1,
    SEQ_DRAIN = 2'd2
  } seq_state_e;

  seq_state_e state_q;

  logic          active_global_enable_q;
  logic [2:0]    active_axis_enable_q;
  logic          active_position_enable_q;
  spadmic_tx_sel_e active_shared_tx_sel_q;
  input_sel_e      active_tdc_input_sel_q;
  out_mode_e       active_tdc_out_mode_q;

  wire path_idle = ~tdc_tx_busy_i
                 & ~(|tdc_pkt_pending_i)
                 & ~position_busy_i
                 & ~position_pending_i;

  // cfg_accept_o tells software whether a new control image may be requested now.
  // transition_busy_o tells software that the sequencer is still draining or
  // committing a previously accepted request.
  assign cfg_accept_o      = (state_q == SEQ_IDLE) & path_idle;
  assign transition_busy_o = (state_q != SEQ_IDLE);

  // The active image is forced disabled during transitions so producers stop
  // issuing new traffic while the old path drains.
  always_comb begin
    active_global_enable_o   = active_global_enable_q;
    active_axis_enable_o     = active_axis_enable_q;
    active_position_enable_o = active_position_enable_q;
    active_shared_tx_sel_o   = active_shared_tx_sel_q;
    active_tdc_input_sel_o   = active_tdc_input_sel_q;
    active_tdc_out_mode_o    = active_tdc_out_mode_q;

    if (state_q != SEQ_IDLE)
      active_global_enable_o = 1'b0;
  end

  // Reset enters a drain-wait state so the first active image is only exposed
  // after the datapath is known idle.
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q                  <= SEQ_RESET;
      active_global_enable_q   <= 1'b0;
      active_axis_enable_q     <= 3'b111;
      active_position_enable_q <= 1'b1;
      active_shared_tx_sel_q   <= SPADMIC_TX_TDC;
      active_tdc_input_sel_q   <= INPUT_SPAD;
      active_tdc_out_mode_q    <= OUT_MODE_RAW_FEATURES;
    end else begin
      case (state_q)
        SEQ_RESET: begin
          if (path_idle)
            state_q <= SEQ_IDLE;
        end

        SEQ_IDLE: begin
          if (cfg_update_i)
            state_q <= SEQ_DRAIN;
        end

        default: begin
          if (path_idle) begin
            active_global_enable_q   <= req_global_enable_i;
            active_axis_enable_q     <= req_axis_enable_i;
            active_position_enable_q <= req_position_enable_i;
            active_shared_tx_sel_q   <= req_shared_tx_sel_i;
            active_tdc_input_sel_q   <= req_tdc_input_sel_i;
            active_tdc_out_mode_q    <= req_tdc_out_mode_i;
            state_q                  <= SEQ_IDLE;
          end
        end
      endcase
    end
  end

endmodule

`default_nettype wire
