`timescale 1ps/1ps
`default_nettype none

module spadmic_tdc_arbiter3 (
  input  wire        clk_sys,
  input  wire        rst_n,

  input  wire [2:0]  pkt_valid_i,
  input  wire [2:0]  pkt_sop_i,
  input  wire [2:0]  pkt_eop_i,
  input  wire [15:0] pkt_data_i [3],
  output logic [2:0] pkt_ready_o,

  input  wire        shared_ready_i,
  output wire        shared_valid_o,
  output wire [15:0] shared_data_o,
  output wire        shared_sop_o,
  output wire        shared_eop_o,

  output wire        arb_busy_o,
  output wire [1:0]  grant_idx_o
);
  logic       grant_active_q;
  logic [1:0] grant_idx_q;
  logic [1:0] rr_ptr_q;

  logic       choice_valid;
  logic [1:0] choice_idx;
  logic [1:0] active_idx;
  logic       active_valid;
  logic       active_sop;
  logic       active_eop;
  logic [15:0] active_data;
  wire        shared_xfer;

  always_comb begin
    choice_valid = 1'b0;
    choice_idx   = 2'd0;

    case (rr_ptr_q)
      2'd0: begin
        if (pkt_valid_i[0] && pkt_sop_i[0]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd0;
        end else if (pkt_valid_i[1] && pkt_sop_i[1]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd1;
        end else if (pkt_valid_i[2] && pkt_sop_i[2]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd2;
        end
      end
      2'd1: begin
        if (pkt_valid_i[1] && pkt_sop_i[1]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd1;
        end else if (pkt_valid_i[2] && pkt_sop_i[2]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd2;
        end else if (pkt_valid_i[0] && pkt_sop_i[0]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd0;
        end
      end
      default: begin
        if (pkt_valid_i[2] && pkt_sop_i[2]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd2;
        end else if (pkt_valid_i[0] && pkt_sop_i[0]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd0;
        end else if (pkt_valid_i[1] && pkt_sop_i[1]) begin
          choice_valid = 1'b1;
          choice_idx   = 2'd1;
        end
      end
    endcase
  end

  always_comb begin
    active_idx   = grant_active_q ? grant_idx_q : choice_idx;
    active_valid = grant_active_q ? pkt_valid_i[grant_idx_q] : choice_valid;
    active_sop   = grant_active_q ? pkt_sop_i[grant_idx_q]   : pkt_sop_i[choice_idx];
    active_eop   = grant_active_q ? pkt_eop_i[grant_idx_q]   : pkt_eop_i[choice_idx];
    active_data  = grant_active_q ? pkt_data_i[grant_idx_q]  : pkt_data_i[choice_idx];

    pkt_ready_o = 3'b000;
    if (active_valid)
      pkt_ready_o[active_idx] = shared_ready_i;
  end

  assign shared_valid_o = active_valid;
  assign shared_data_o  = active_data;
  assign shared_sop_o   = active_sop;
  assign shared_eop_o   = active_eop;
  assign shared_xfer    = shared_valid_o & shared_ready_i;
  assign arb_busy_o     = grant_active_q;
  assign grant_idx_o    = grant_idx_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      grant_active_q <= 1'b0;
      grant_idx_q    <= 2'd0;
      rr_ptr_q       <= 2'd0;
    end else if (!grant_active_q) begin
      if (choice_valid) begin
        grant_idx_q <= choice_idx;
        if (shared_xfer && active_eop) begin
          grant_active_q <= 1'b0;
          rr_ptr_q       <= (choice_idx == 2'd2) ? 2'd0 : (choice_idx + 2'd1);
        end else begin
          grant_active_q <= 1'b1;
        end
      end
    end else if (shared_xfer && active_eop) begin
      grant_active_q <= 1'b0;
      rr_ptr_q       <= (grant_idx_q == 2'd2) ? 2'd0 : (grant_idx_q + 2'd1);
    end
  end

endmodule

`default_nettype wire
