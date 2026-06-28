// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_matrix_reset_ctrl.sv
// Purpose  : Exact-width active-low selective reset controller for R/Y/B matrix.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_matrix_reset_ctrl #(
  parameter int unsigned LINE_W = 64
) (
  input  logic              clk_sys,
  input  logic              rst_n,
  input  logic              enable_i,
  input  logic              start_i,
  input  logic [15:0]       reset_width_i,
  input  logic [LINE_W-1:0] snapshot_R_i,
  input  logic [LINE_W-1:0] snapshot_Y_i,
  input  logic [LINE_W-1:0] snapshot_B_i,
  output logic [LINE_W-1:0] Rz_o,
  output logic [LINE_W-1:0] Yz_o,
  output logic [LINE_W-1:0] Bz_o,
  output logic              busy_o,
  output logic              done_o,
  output logic              disabled_o
);

  typedef enum logic {
    RST_IDLE   = 1'b0,
    RST_ASSERT = 1'b1
  } rst_state_e;

  rst_state_e state_q;
  logic [LINE_W-1:0] r_reset_mask_q;
  logic [LINE_W-1:0] y_reset_mask_q;
  logic [LINE_W-1:0] b_reset_mask_q;
  logic [15:0]       count_q;

  assign Rz_o = ~r_reset_mask_q;
  assign Yz_o = ~y_reset_mask_q;
  assign Bz_o = ~b_reset_mask_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q        <= RST_IDLE;
      r_reset_mask_q <= '0;
      y_reset_mask_q <= '0;
      b_reset_mask_q <= '0;
      count_q        <= '0;
      busy_o         <= 1'b0;
      done_o         <= 1'b0;
      disabled_o     <= 1'b0;
    end else begin
      done_o     <= 1'b0;
      disabled_o <= 1'b0;

      case (state_q)
        RST_IDLE: begin
          busy_o         <= 1'b0;
          r_reset_mask_q <= '0;
          y_reset_mask_q <= '0;
          b_reset_mask_q <= '0;
          count_q        <= '0;

          if (start_i) begin
            if (!enable_i || (reset_width_i == 16'd0)) begin
              disabled_o <= 1'b1;
              done_o     <= 1'b1;
            end else begin
              r_reset_mask_q <= snapshot_R_i;
              y_reset_mask_q <= snapshot_Y_i;
              b_reset_mask_q <= snapshot_B_i;
              count_q        <= reset_width_i;
              busy_o         <= 1'b1;
              state_q        <= RST_ASSERT;
            end
          end
        end

        RST_ASSERT: begin
          busy_o <= 1'b1;
          if (count_q <= 16'd1) begin
            r_reset_mask_q <= '0;
            y_reset_mask_q <= '0;
            b_reset_mask_q <= '0;
            count_q        <= '0;
            busy_o         <= 1'b0;
            done_o         <= 1'b1;
            state_q        <= RST_IDLE;
          end else begin
            count_q <= count_q - 16'd1;
          end
        end

        default: begin
          state_q        <= RST_IDLE;
          r_reset_mask_q <= '0;
          y_reset_mask_q <= '0;
          b_reset_mask_q <= '0;
          busy_o         <= 1'b0;
        end
      endcase
    end
  end

endmodule

`default_nettype wire
