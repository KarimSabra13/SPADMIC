// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_event_coordinator.sv
// Purpose  : Mode-aware one-event coordinator with frozen required masks.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_event_coordinator (
  input  logic                         clk_sys,
  input  logic                         rst_n,
  input  spadmic_pkg::spadmic_operating_mode_e active_mode_i,
  input  logic                         global_enable_i,
  input  logic [2:0]                   active_axis_mask_i,
  input  logic                         matrix_activity_i,
  input  logic                         cal_activity_i,
  input  logic                         pre_event_resources_ready_i,
  input  logic                         raw_snapshot_required_i,
  input  logic                         auto_reset_enable_i,
  input  logic                         snapshot_valid_i,
  input  logic [2:0]                   tdc_start_seen_i,
  input  logic [3:0]                   packet_pending_mask_i,
  input  logic                         reset_done_i,
  input  logic                         bundle_done_i,
  input  logic                         rearm_ready_i,
  output logic                         event_open_o,
  output logic [13:0]                  event_id_o,
  output logic [3:0]                   required_packet_mask_o,
  output logic [2:0]                   required_tdc_mask_o,
  output logic [3:0]                   required_reset_ack_mask_o,
  output logic [3:0]                   observed_reset_ack_mask_o,
  output logic                         reset_start_o,
  output logic                         bundle_start_o,
  output logic                         accept_enable_o,
  output logic                         rejected_not_ready_o,
  output logic                         busy_o,
  output logic                         idle_o
);
  import spadmic_pkg::*;

  typedef enum logic [2:0] {
    EVT_IDLE            = 3'd0,
    EVT_WAIT_RESET_ACK  = 3'd1,
    EVT_WAIT_RESET_DONE = 3'd2,
    EVT_WAIT_PACKETS    = 3'd3,
    EVT_TRANSMIT        = 3'd4,
    EVT_REARM           = 3'd5
  } evt_state_e;

  evt_state_e state_q;
  spadmic_operating_mode_e event_mode_q;
  logic [13:0] next_event_id_q;
  logic        event_id_valid_q;
  logic        event_uses_matrix_q;

  wire mode_uses_matrix =
      (active_mode_i == SPADMIC_MODE_TDC_ONLY) ||
      (active_mode_i == SPADMIC_MODE_POSITION_ONLY) ||
      (active_mode_i == SPADMIC_MODE_BOTH);

  wire mode_has_position_packet =
      (active_mode_i == SPADMIC_MODE_POSITION_ONLY) ||
      (active_mode_i == SPADMIC_MODE_BOTH);

  wire mode_has_tdc =
      (active_mode_i == SPADMIC_MODE_TDC_ONLY) ||
      (active_mode_i == SPADMIC_MODE_BOTH) ||
      (active_mode_i == SPADMIC_MODE_CALIBRATION);

  wire [2:0] calc_required_tdc_mask =
      mode_has_tdc ? active_axis_mask_i : 3'b000;

  wire [3:0] calc_required_packet_mask = {
      mode_has_position_packet,
      calc_required_tdc_mask
  };

  wire [3:0] calc_required_reset_ack_mask = {
      mode_uses_matrix && raw_snapshot_required_i,
      mode_uses_matrix ? calc_required_tdc_mask : 3'b000
  };

  wire matrix_event_trigger =
      mode_uses_matrix && matrix_activity_i;
  wire calibration_event_trigger =
      (active_mode_i == SPADMIC_MODE_CALIBRATION) && cal_activity_i;
  wire event_trigger =
      global_enable_i && (matrix_event_trigger || calibration_event_trigger);

  wire reset_prerequisites_met =
      ((observed_reset_ack_mask_o & required_reset_ack_mask_o) ==
       required_reset_ack_mask_o);
  wire bundle_ready =
      ((packet_pending_mask_i & required_packet_mask_o) ==
       required_packet_mask_o);

  assign event_open_o = (state_q != EVT_IDLE);
  assign busy_o       = event_open_o;
  assign idle_o       = (state_q == EVT_IDLE);
  assign accept_enable_o =
      (state_q == EVT_IDLE) &&
      global_enable_i &&
      (active_mode_i != SPADMIC_MODE_DISABLED) &&
      pre_event_resources_ready_i;
  assign observed_reset_ack_mask_o = {
      snapshot_valid_i,
      tdc_start_seen_i
  };

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q                   <= EVT_IDLE;
      event_mode_q              <= SPADMIC_MODE_DISABLED;
      next_event_id_q           <= '0;
      event_id_o                <= '0;
      event_id_valid_q          <= 1'b0;
      event_uses_matrix_q       <= 1'b0;
      required_packet_mask_o    <= '0;
      required_tdc_mask_o       <= '0;
      required_reset_ack_mask_o <= '0;
      reset_start_o             <= 1'b0;
      bundle_start_o            <= 1'b0;
      rejected_not_ready_o      <= 1'b0;
    end else begin
      reset_start_o        <= 1'b0;
      bundle_start_o       <= 1'b0;
      rejected_not_ready_o <= 1'b0;

      case (state_q)
        EVT_IDLE: begin
          event_mode_q              <= SPADMIC_MODE_DISABLED;
          event_id_valid_q          <= 1'b0;
          event_uses_matrix_q       <= 1'b0;
          required_packet_mask_o    <= '0;
          required_tdc_mask_o       <= '0;
          required_reset_ack_mask_o <= '0;

          if (event_trigger) begin
            if (!pre_event_resources_ready_i ||
                (calc_required_packet_mask == 4'b0000)) begin
              rejected_not_ready_o <= 1'b1;
            end else begin
              event_mode_q              <= active_mode_i;
              event_uses_matrix_q       <= mode_uses_matrix;
              required_packet_mask_o    <= calc_required_packet_mask;
              required_tdc_mask_o       <= calc_required_tdc_mask;
              required_reset_ack_mask_o <= calc_required_reset_ack_mask;
              state_q                   <= EVT_WAIT_RESET_ACK;

              if (active_mode_i != SPADMIC_MODE_POSITION_ONLY) begin
                event_id_o       <= next_event_id_q;
                next_event_id_q  <= next_event_id_q + 14'd1;
                event_id_valid_q <= 1'b1;
              end
            end
          end
        end

        EVT_WAIT_RESET_ACK: begin
          if ((event_mode_q == SPADMIC_MODE_POSITION_ONLY) &&
              snapshot_valid_i && !event_id_valid_q) begin
            event_id_o       <= next_event_id_q;
            next_event_id_q  <= next_event_id_q + 14'd1;
            event_id_valid_q <= 1'b1;
          end

          if (reset_prerequisites_met &&
              ((event_mode_q != SPADMIC_MODE_POSITION_ONLY) ||
               snapshot_valid_i || event_id_valid_q)) begin
            if (auto_reset_enable_i &&
                (required_reset_ack_mask_o != 4'b0000)) begin
              reset_start_o <= 1'b1;
              state_q       <= EVT_WAIT_RESET_DONE;
            end else begin
              state_q <= EVT_WAIT_PACKETS;
            end
          end
        end

        EVT_WAIT_RESET_DONE: begin
          if (reset_done_i)
            state_q <= EVT_WAIT_PACKETS;
        end

        EVT_WAIT_PACKETS: begin
          if (bundle_ready && event_id_valid_q) begin
            bundle_start_o <= 1'b1;
            state_q        <= EVT_TRANSMIT;
          end
        end

        EVT_TRANSMIT: begin
          if (bundle_done_i)
            state_q <= EVT_REARM;
        end

        EVT_REARM: begin
          if (!event_uses_matrix_q || rearm_ready_i)
            state_q <= EVT_IDLE;
        end

        default: state_q <= EVT_IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire
