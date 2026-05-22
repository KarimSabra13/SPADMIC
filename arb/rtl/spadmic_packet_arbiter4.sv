// =============================================================================
// Project  : SPADMIC ARB
// File     : spadmic_packet_arbiter4.sv
// Purpose  : STA-safe four-source packet arbiter with per-source skid buffers.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_packet_arbiter4 (
  input  wire                                           clk_sys,
  input  wire                                           rst_n,
  input  wire [spadmic_pkg::SPADMIC_SRC_MASK_W-1:0]     source_mask_i,

  input  wire [spadmic_pkg::SPADMIC_SRC_COUNT-1:0]      src_valid_i,
  output logic [spadmic_pkg::SPADMIC_SRC_COUNT-1:0]     src_ready_o,
  input  wire [mptdc_pkg::NARROW_W-1:0]                 src_data_i [spadmic_pkg::SPADMIC_SRC_COUNT],
  input  wire [spadmic_pkg::SPADMIC_SRC_COUNT-1:0]      src_sop_i,
  input  wire [spadmic_pkg::SPADMIC_SRC_COUNT-1:0]      src_eop_i,
  input  spadmic_pkg::spadmic_source_id_e               src_source_i [spadmic_pkg::SPADMIC_SRC_COUNT],

  output wire                                           arb_valid_o,
  input  wire                                           arb_ready_i,
  output wire [mptdc_pkg::NARROW_W-1:0]                 arb_data_o,
  output wire                                           arb_sop_o,
  output wire                                           arb_eop_o,
  output spadmic_pkg::spadmic_source_id_e               arb_source_o,
  output wire [spadmic_pkg::SPADMIC_SRC_COUNT-1:0]      source_pending_o,
  output wire                                           arb_busy_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic [SPADMIC_SRC_COUNT-1:0] skid_valid_q;
  logic [NARROW_W-1:0]          skid_data_q [SPADMIC_SRC_COUNT];
  logic [SPADMIC_SRC_COUNT-1:0] skid_sop_q;
  logic [SPADMIC_SRC_COUNT-1:0] skid_eop_q;
  spadmic_source_id_e           skid_source_q [SPADMIC_SRC_COUNT];

  logic                         grant_active_q;
  logic [SPADMIC_AXIS_ID_W-1:0] grant_idx_q;
  logic [SPADMIC_AXIS_ID_W-1:0] rr_ptr_q;
  logic                         choice_valid;
  logic [SPADMIC_AXIS_ID_W-1:0] choice_idx;
  logic [SPADMIC_SRC_COUNT-1:0] eligible;
  logic [SPADMIC_SRC_COUNT-1:0] consume_skid;

  assign eligible = skid_valid_q & source_mask_i;
  assign arb_valid_o = grant_active_q & skid_valid_q[grant_idx_q];
  assign arb_data_o  = skid_data_q[grant_idx_q];
  assign arb_sop_o   = skid_sop_q[grant_idx_q];
  assign arb_eop_o   = skid_eop_q[grant_idx_q];
  assign arb_source_o = skid_source_q[grant_idx_q];
  assign source_pending_o = skid_valid_q;
  assign arb_busy_o = grant_active_q | (|skid_valid_q);

  always_comb begin
    choice_valid = 1'b0;
    choice_idx   = '0;

    unique case (rr_ptr_q)
      2'd0: begin
        if (eligible[0]) begin choice_valid = 1'b1; choice_idx = 2'd0; end
        else if (eligible[1]) begin choice_valid = 1'b1; choice_idx = 2'd1; end
        else if (eligible[2]) begin choice_valid = 1'b1; choice_idx = 2'd2; end
        else if (eligible[3]) begin choice_valid = 1'b1; choice_idx = 2'd3; end
      end

      2'd1: begin
        if (eligible[1]) begin choice_valid = 1'b1; choice_idx = 2'd1; end
        else if (eligible[2]) begin choice_valid = 1'b1; choice_idx = 2'd2; end
        else if (eligible[3]) begin choice_valid = 1'b1; choice_idx = 2'd3; end
        else if (eligible[0]) begin choice_valid = 1'b1; choice_idx = 2'd0; end
      end

      2'd2: begin
        if (eligible[2]) begin choice_valid = 1'b1; choice_idx = 2'd2; end
        else if (eligible[3]) begin choice_valid = 1'b1; choice_idx = 2'd3; end
        else if (eligible[0]) begin choice_valid = 1'b1; choice_idx = 2'd0; end
        else if (eligible[1]) begin choice_valid = 1'b1; choice_idx = 2'd1; end
      end

      default: begin
        if (eligible[3]) begin choice_valid = 1'b1; choice_idx = 2'd3; end
        else if (eligible[0]) begin choice_valid = 1'b1; choice_idx = 2'd0; end
        else if (eligible[1]) begin choice_valid = 1'b1; choice_idx = 2'd1; end
        else if (eligible[2]) begin choice_valid = 1'b1; choice_idx = 2'd2; end
      end
    endcase
  end

  always_comb begin
    consume_skid = '0;
    if (arb_valid_o && arb_ready_i)
      consume_skid[grant_idx_q] = 1'b1;

    for (int i = 0; i < SPADMIC_SRC_COUNT; i++)
      src_ready_o[i] = !skid_valid_q[i];
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      skid_valid_q  <= '0;
      skid_sop_q    <= '0;
      skid_eop_q    <= '0;
      grant_active_q <= 1'b0;
      grant_idx_q    <= '0;
      rr_ptr_q       <= '0;

      for (int i = 0; i < SPADMIC_SRC_COUNT; i++) begin
        skid_data_q[i]   <= '0;
        skid_source_q[i] <= spadmic_source_id_e'(i[SPADMIC_AXIS_ID_W-1:0]);
      end
    end else begin
      for (int i = 0; i < SPADMIC_SRC_COUNT; i++) begin
        unique case ({src_valid_i[i] & src_ready_o[i], consume_skid[i]})
          2'b10: begin
            skid_valid_q[i]  <= 1'b1;
            skid_data_q[i]   <= src_data_i[i];
            skid_sop_q[i]    <= src_sop_i[i];
            skid_eop_q[i]    <= src_eop_i[i];
            skid_source_q[i] <= src_source_i[i];
          end

          2'b01: begin
            skid_valid_q[i] <= 1'b0;
          end

          2'b11: begin
            skid_valid_q[i]  <= 1'b1;
            skid_data_q[i]   <= src_data_i[i];
            skid_sop_q[i]    <= src_sop_i[i];
            skid_eop_q[i]    <= src_eop_i[i];
            skid_source_q[i] <= src_source_i[i];
          end

          default: ;
        endcase
      end

      if (!grant_active_q) begin
        if (choice_valid) begin
          grant_active_q <= 1'b1;
          grant_idx_q    <= choice_idx;
        end
      end else if (arb_valid_o && arb_ready_i && arb_eop_o) begin
        grant_active_q <= 1'b0;
        rr_ptr_q       <= grant_idx_q + SPADMIC_AXIS_ID_W'(1);
      end
    end
  end

  // synthesis translate_off
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (rst_n) begin
      if (arb_valid_o && !arb_ready_i)
        assert ($stable(arb_data_o))
          else $error("spadmic_packet_arbiter4: output data changed while stalled");
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
