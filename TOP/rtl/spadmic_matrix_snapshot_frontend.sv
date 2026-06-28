// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_matrix_snapshot_frontend.sv
// Purpose  : clk_sys-domain raw R/Y/B snapshot service for reset/position.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_matrix_snapshot_frontend #(
  parameter int unsigned LINE_W = 64
) (
  input  logic              clk_sys,
  input  logic              rst_n,
  input  logic              enable_i,
  input  logic              clear_i,
  input  logic [2:0]        required_direction_mask_i,
  input  logic [LINE_W-1:0] R_i,
  input  logic [LINE_W-1:0] Y_i,
  input  logic [LINE_W-1:0] B_i,
  input  logic [15:0]       settle_cycles_i,
  input  logic [15:0]       watchdog_cycles_i,
  output logic              snapshot_valid_o,
  output logic [LINE_W-1:0] snapshot_R_o,
  output logic [LINE_W-1:0] snapshot_Y_o,
  output logic [LINE_W-1:0] snapshot_B_o,
  output logic              busy_o,
  output logic              timeout_o,
  output logic              overlap_o,
  output logic              reject_o,
  output logic              rearm_ready_o
);

  typedef enum logic [1:0] {
    SNAP_IDLE   = 2'd0,
    SNAP_SETTLE = 2'd1,
    SNAP_VALID  = 2'd2,
    SNAP_REARM  = 2'd3
  } snap_state_e;

  (* ASYNC_REG = "TRUE" *) logic [LINE_W-1:0] r_sync1, r_sync2, r_sync3;
  (* ASYNC_REG = "TRUE" *) logic [LINE_W-1:0] y_sync1, y_sync2, y_sync3;
  (* ASYNC_REG = "TRUE" *) logic [LINE_W-1:0] b_sync1, b_sync2, b_sync3;

  snap_state_e state_q;
  logic [LINE_W-1:0] sample_R_q, sample_Y_q, sample_B_q;
  logic [LINE_W-1:0] accum_R_q, accum_Y_q, accum_B_q;
  logic [15:0] stable_count_q;
  logic [15:0] watchdog_count_q;
  logic [1:0]  zero_count_q;

  wire r_required = required_direction_mask_i[0];
  wire y_required = required_direction_mask_i[1];
  wire b_required = required_direction_mask_i[2];
  wire any_required_activity =
      (r_required && (|r_sync3)) ||
      (y_required && (|y_sync3)) ||
      (b_required && (|b_sync3));
  wire required_nonzero =
      (!r_required || (|r_sync3)) &&
      (!y_required || (|y_sync3)) &&
      (!b_required || (|b_sync3)) &&
      (required_direction_mask_i != 3'b000);
  wire required_zero =
      (!r_required || !(|r_sync3)) &&
      (!y_required || !(|y_sync3)) &&
      (!b_required || !(|b_sync3));
  wire sample_changed =
      (r_required && (r_sync3 != sample_R_q)) ||
      (y_required && (y_sync3 != sample_Y_q)) ||
      (b_required && (b_sync3 != sample_B_q));
  wire stable_ready =
      (settle_cycles_i == 16'd0) ||
      (stable_count_q >= (settle_cycles_i - 16'd1));
  wire watchdog_expired =
      (watchdog_cycles_i != 16'd0) &&
      (watchdog_count_q >= (watchdog_cycles_i - 16'd1));

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      r_sync1 <= '0;
      r_sync2 <= '0;
      r_sync3 <= '0;
      y_sync1 <= '0;
      y_sync2 <= '0;
      y_sync3 <= '0;
      b_sync1 <= '0;
      b_sync2 <= '0;
      b_sync3 <= '0;
    end else begin
      r_sync1 <= R_i;
      r_sync2 <= r_sync1;
      r_sync3 <= r_sync2;
      y_sync1 <= Y_i;
      y_sync2 <= y_sync1;
      y_sync3 <= y_sync2;
      b_sync1 <= B_i;
      b_sync2 <= b_sync1;
      b_sync3 <= b_sync2;
    end
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q          <= SNAP_IDLE;
      sample_R_q       <= '0;
      sample_Y_q       <= '0;
      sample_B_q       <= '0;
      accum_R_q        <= '0;
      accum_Y_q        <= '0;
      accum_B_q        <= '0;
      stable_count_q   <= '0;
      watchdog_count_q <= '0;
      zero_count_q     <= '0;
      snapshot_valid_o <= 1'b0;
      snapshot_R_o     <= '0;
      snapshot_Y_o     <= '0;
      snapshot_B_o     <= '0;
      timeout_o        <= 1'b0;
      overlap_o        <= 1'b0;
      reject_o         <= 1'b0;
      rearm_ready_o    <= 1'b0;
    end else begin
      if (!enable_i) begin
        state_q          <= SNAP_IDLE;
        sample_R_q       <= '0;
        sample_Y_q       <= '0;
        sample_B_q       <= '0;
        accum_R_q        <= '0;
        accum_Y_q        <= '0;
        accum_B_q        <= '0;
        stable_count_q   <= '0;
        watchdog_count_q <= '0;
        zero_count_q     <= '0;
        snapshot_valid_o <= 1'b0;
        snapshot_R_o     <= '0;
        snapshot_Y_o     <= '0;
        snapshot_B_o     <= '0;
        timeout_o        <= 1'b0;
        overlap_o        <= 1'b0;
        reject_o         <= 1'b0;
        rearm_ready_o    <= 1'b0;
      end else begin
        case (state_q)
          SNAP_IDLE: begin
            snapshot_valid_o <= 1'b0;
            timeout_o        <= 1'b0;
            overlap_o        <= 1'b0;
            reject_o         <= 1'b0;
            if (required_zero) begin
              if (zero_count_q != 2'd2)
                zero_count_q <= zero_count_q + 2'd1;
              rearm_ready_o <= (zero_count_q >= 2'd1);
            end else begin
              zero_count_q  <= '0;
              rearm_ready_o <= 1'b0;
            end

            if (any_required_activity) begin
              state_q          <= SNAP_SETTLE;
              sample_R_q       <= r_sync3;
              sample_Y_q       <= y_sync3;
              sample_B_q       <= b_sync3;
              accum_R_q        <= r_sync3;
              accum_Y_q        <= y_sync3;
              accum_B_q        <= b_sync3;
              stable_count_q   <= '0;
              watchdog_count_q <= '0;
              zero_count_q     <= '0;
              rearm_ready_o    <= 1'b0;
            end
          end

          SNAP_SETTLE: begin
            accum_R_q <= accum_R_q | r_sync3;
            accum_Y_q <= accum_Y_q | y_sync3;
            accum_B_q <= accum_B_q | b_sync3;

            if (sample_changed) begin
              sample_R_q     <= r_sync3;
              sample_Y_q     <= y_sync3;
              sample_B_q     <= b_sync3;
              stable_count_q <= '0;
              overlap_o      <= overlap_o | any_required_activity;
            end else if (!stable_ready) begin
              stable_count_q <= stable_count_q + 16'd1;
            end

            if (required_nonzero && !sample_changed && stable_ready) begin
              snapshot_R_o     <= r_sync3;
              snapshot_Y_o     <= y_sync3;
              snapshot_B_o     <= b_sync3;
              snapshot_valid_o <= 1'b1;
              reject_o         <= 1'b0;
              timeout_o        <= 1'b0;
              state_q          <= SNAP_VALID;
            end else if (watchdog_expired) begin
              snapshot_R_o     <= accum_R_q | r_sync3;
              snapshot_Y_o     <= accum_Y_q | y_sync3;
              snapshot_B_o     <= accum_B_q | b_sync3;
              snapshot_valid_o <= 1'b1;
              reject_o         <= 1'b1;
              timeout_o        <= 1'b1;
              state_q          <= SNAP_VALID;
            end else begin
              watchdog_count_q <= watchdog_count_q + 16'd1;
            end
          end

          SNAP_VALID: begin
            if (clear_i) begin
              snapshot_valid_o <= 1'b0;
              state_q          <= SNAP_REARM;
              zero_count_q     <= '0;
              rearm_ready_o    <= 1'b0;
            end
          end

          SNAP_REARM: begin
            if (required_zero) begin
              if (zero_count_q != 2'd2)
                zero_count_q <= zero_count_q + 2'd1;
              if (zero_count_q >= 2'd1) begin
                state_q       <= SNAP_IDLE;
                rearm_ready_o <= 1'b1;
              end
            end else begin
              zero_count_q  <= '0;
              rearm_ready_o <= 1'b0;
            end
          end

          default: state_q <= SNAP_IDLE;
        endcase
      end
    end
  end

  assign busy_o = (state_q == SNAP_SETTLE) ||
                  (state_q == SNAP_VALID)  ||
                  (state_q == SNAP_REARM);

endmodule

`default_nettype wire
