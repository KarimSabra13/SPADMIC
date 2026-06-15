// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_global_csr.sv
// Purpose  : Requested-control register block plus global status and fault
//            reporting for the shared top-level datapath.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_global_csr (
  input  wire                                clk_sys,
  input  wire                                rst_n,
  input  wire                                csr_valid_i,
  input  wire                                csr_write_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] csr_addr_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_wdata_i,
  output wire                                csr_ready_o,
  output logic                               csr_rvalid_o,
  output logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_rdata_o,

  input  wire                                tdc_tx_busy_i,
  input  wire [2:0]                          tdc_pkt_pending_i,
  input  wire [2:0]                          tdc_pkt_full_i,
  input  wire                                position_busy_i,
  input  wire                                position_pending_i,
  input  wire                                position_drop_sticky_i,
  input  wire                                position_glitch_sticky_i,
  input  wire                                correlation_overflow_i,

  input  wire                                cfg_accept_i,
  input  wire                                transition_busy_i,
  input  wire                                active_global_enable_i,
  input  wire [2:0]                          active_axis_enable_i,
  input  wire                                active_position_enable_i,
  input  wire spadmic_pkg::spadmic_tx_sel_e  active_shared_tx_sel_i,
  input  wire mptdc_pkg::input_sel_e         active_tdc_input_sel_i,
  input  wire mptdc_pkg::out_mode_e          active_tdc_out_mode_i,

  output logic                               req_global_enable_o,
  output logic [2:0]                         req_axis_enable_o,
  output logic                               req_position_enable_o,
  output spadmic_pkg::spadmic_tx_sel_e       req_shared_tx_sel_o,
  output mptdc_pkg::input_sel_e              req_tdc_input_sel_o,
  output mptdc_pkg::out_mode_e               req_tdc_out_mode_o,
  output logic                               cfg_update_o
);
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  logic [SPADMIC_CSR_DATA_W-1:0] rd_data_next;
  logic [15:0] mode_reject_count_q;
  logic        mode_reject_sticky_q;
  wire         ctrl_global_enable_next = csr_wdata_i[0];
  wire [2:0]   ctrl_axis_enable_next   = csr_wdata_i[3:1];
  wire         ctrl_position_enable_next = csr_wdata_i[4];
  wire spadmic_tx_sel_e ctrl_shared_tx_sel_next = spadmic_tx_sel_e'(csr_wdata_i[5]);
  wire input_sel_e      ctrl_tdc_input_sel_next = input_sel_e'(csr_wdata_i[6]);
  wire out_mode_e       ctrl_tdc_out_mode_next  = OUT_MODE_RAW_FEATURES;
  wire                  unused_csr_out_mode_bits = |csr_wdata_i[8:7];

  wire wr_en = csr_valid_i & csr_write_i;
  wire rd_en = csr_valid_i & ~csr_write_i;
  wire path_idle = ~tdc_tx_busy_i
                 & ~( |tdc_pkt_pending_i )
                 & ~position_busy_i
                 & ~position_pending_i;

  wire ctrl_change_req = (ctrl_global_enable_next   != req_global_enable_o)
                      || (ctrl_axis_enable_next     != req_axis_enable_o)
                      || (ctrl_position_enable_next != req_position_enable_o)
                      || (ctrl_shared_tx_sel_next   != req_shared_tx_sel_o)
                      || (ctrl_tdc_input_sel_next   != req_tdc_input_sel_o);

  wire ctrl_apply_pending = (req_global_enable_o   != active_global_enable_i)
                         || (req_axis_enable_o     != active_axis_enable_i)
                         || (req_position_enable_o != active_position_enable_i)
                         || (req_shared_tx_sel_o   != active_shared_tx_sel_i)
                         || (req_tdc_input_sel_o    != active_tdc_input_sel_i);

  assign csr_ready_o = 1'b1;

  // Writes only update the requested image. The sequencer later commits the
  // active image when the datapath is idle and ready for a transition.
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      req_global_enable_o   <= 1'b0;
      req_axis_enable_o     <= 3'b111;
      req_position_enable_o <= 1'b1;
      req_shared_tx_sel_o   <= SPADMIC_TX_TDC;
      req_tdc_input_sel_o   <= INPUT_SPAD;
      req_tdc_out_mode_o    <= OUT_MODE_RAW_FEATURES;
      cfg_update_o          <= 1'b0;
      mode_reject_count_q  <= '0;
      mode_reject_sticky_q <= 1'b0;
    end else begin
      cfg_update_o <= 1'b0;
      if (wr_en) begin
        case (csr_addr_i)
          SPADMIC_CSR_GLOBAL_CTRL: begin
            if (ctrl_change_req) begin
              if (!cfg_accept_i) begin
                mode_reject_count_q  <= mode_reject_count_q + 16'd1;
                mode_reject_sticky_q <= 1'b1;
              end else begin
                req_global_enable_o   <= ctrl_global_enable_next;
                req_axis_enable_o     <= ctrl_axis_enable_next;
                req_position_enable_o <= ctrl_position_enable_next;
                req_shared_tx_sel_o   <= ctrl_shared_tx_sel_next;
                req_tdc_input_sel_o   <= ctrl_tdc_input_sel_next;
                req_tdc_out_mode_o    <= OUT_MODE_RAW_FEATURES;
                cfg_update_o          <= 1'b1;
              end
            end
          end

          SPADMIC_CSR_GLOBAL_FAULT: begin
            if (csr_wdata_i[0])
              mode_reject_sticky_q <= 1'b0;
          end

          default: ;
        endcase
      end
    end
  end

  // Readback exposes both requested control and live active-state/health bits so
  // software can tell whether a change was accepted, applied, or rejected.
  always_comb begin
    rd_data_next = '0;
    case (csr_addr_i)
      SPADMIC_CSR_GLOBAL_ID: begin
        rd_data_next = 32'h5350_4144;  // "SPAD"
      end

      SPADMIC_CSR_GLOBAL_VERSION: begin
        rd_data_next = 32'h0004_0000;
      end

      SPADMIC_CSR_GLOBAL_CTRL: begin
        rd_data_next[0]   = req_global_enable_o;
        rd_data_next[3:1] = req_axis_enable_o;
        rd_data_next[4]   = req_position_enable_o;
        rd_data_next[5]   = req_shared_tx_sel_o;
        rd_data_next[6]   = req_tdc_input_sel_o;
        rd_data_next[8:7] = OUT_MODE_RAW_FEATURES;
      end

      SPADMIC_CSR_GLOBAL_STATUS: begin
        rd_data_next[0]    = tdc_tx_busy_i;
        rd_data_next[3:1]  = tdc_pkt_pending_i;
        rd_data_next[4]    = position_busy_i;
        rd_data_next[5]    = position_pending_i;
        rd_data_next[6]    = path_idle;
        rd_data_next[7]    = active_shared_tx_sel_i;
        rd_data_next[8]    = active_tdc_input_sel_i;
        rd_data_next[10:9] = OUT_MODE_RAW_FEATURES;
        rd_data_next[13:11] = tdc_pkt_full_i;
        rd_data_next[14]   = transition_busy_i;
        rd_data_next[15]   = ctrl_apply_pending;
        rd_data_next[16]   = active_global_enable_i;
        rd_data_next[19:17] = active_axis_enable_i;
        rd_data_next[20]   = active_position_enable_i;
        rd_data_next[21]   = cfg_accept_i;
      end

      SPADMIC_CSR_GLOBAL_FAULT: begin
        rd_data_next[0] = mode_reject_sticky_q;
        rd_data_next[1] = position_drop_sticky_i;
        rd_data_next[2] = position_glitch_sticky_i;
        rd_data_next[3] = correlation_overflow_i;
      end

      SPADMIC_CSR_GLOBAL_FAULT_COUNT: begin
        rd_data_next[15:0] = mode_reject_count_q;
      end

      default: ;
    endcase
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      csr_rvalid_o <= 1'b0;
      csr_rdata_o  <= '0;
    end else begin
      csr_rvalid_o <= rd_en;
      csr_rdata_o  <= rd_en ? rd_data_next : '0;
    end
  end

endmodule

`default_nettype wire
