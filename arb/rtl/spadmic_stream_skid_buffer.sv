// =============================================================================
// Project  : SPADMIC ARB
// File     : spadmic_stream_skid_buffer.sv
// Purpose  : Registered two-entry packet stream slice for STA-safe handshakes.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_stream_skid_buffer (
  input  wire                             clk_sys,
  input  wire                             rst_n,

  input  wire                             in_valid_i,
  output logic                            in_ready_o,
  input  wire [mptdc_pkg::NARROW_W-1:0]   in_data_i,
  input  wire                             in_sop_i,
  input  wire                             in_eop_i,
  input  spadmic_pkg::spadmic_source_id_e in_source_i,

  output logic                            out_valid_o,
  input  wire                             out_ready_i,
  output logic [mptdc_pkg::NARROW_W-1:0]  out_data_o,
  output logic                            out_sop_o,
  output logic                            out_eop_o,
  output spadmic_pkg::spadmic_source_id_e out_source_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic [1:0]            count_q;
  logic [NARROW_W-1:0]   data0_q;
  logic [NARROW_W-1:0]   data1_q;
  logic                  sop0_q;
  logic                  sop1_q;
  logic                  eop0_q;
  logic                  eop1_q;
  spadmic_source_id_e    source0_q;
  spadmic_source_id_e    source1_q;

  wire push = in_valid_i & in_ready_o;
  wire pop  = out_valid_o & out_ready_i;

  assign in_ready_o  = (count_q != 2'd2);
  assign out_valid_o = (count_q != 2'd0);
  assign out_data_o  = data0_q;
  assign out_sop_o   = sop0_q;
  assign out_eop_o   = eop0_q;
  assign out_source_o = source0_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      count_q   <= 2'd0;
      data0_q   <= '0;
      data1_q   <= '0;
      sop0_q    <= 1'b0;
      sop1_q    <= 1'b0;
      eop0_q    <= 1'b0;
      eop1_q    <= 1'b0;
      source0_q <= TDC_ID_X;
      source1_q <= TDC_ID_X;
    end else begin
      unique case ({push, pop})
        2'b10: begin
          if (count_q == 2'd0) begin
            data0_q   <= in_data_i;
            sop0_q    <= in_sop_i;
            eop0_q    <= in_eop_i;
            source0_q <= in_source_i;
          end else begin
            data1_q   <= in_data_i;
            sop1_q    <= in_sop_i;
            eop1_q    <= in_eop_i;
            source1_q <= in_source_i;
          end
          count_q <= count_q + 2'd1;
        end

        2'b01: begin
          if (count_q == 2'd2) begin
            data0_q   <= data1_q;
            sop0_q    <= sop1_q;
            eop0_q    <= eop1_q;
            source0_q <= source1_q;
            count_q   <= 2'd1;
          end else begin
            count_q <= 2'd0;
          end
        end

        2'b11: begin
          if (count_q == 2'd2) begin
            data0_q   <= data1_q;
            sop0_q    <= sop1_q;
            eop0_q    <= eop1_q;
            source0_q <= source1_q;
            data1_q   <= in_data_i;
            sop1_q    <= in_sop_i;
            eop1_q    <= in_eop_i;
            source1_q <= in_source_i;
            count_q   <= 2'd2;
          end else begin
            data0_q   <= in_data_i;
            sop0_q    <= in_sop_i;
            eop0_q    <= in_eop_i;
            source0_q <= in_source_i;
            count_q   <= 2'd1;
          end
        end

        default: ;
      endcase
    end
  end

  // synthesis translate_off
  logic [NARROW_W-1:0] hold_data_q;
  logic                hold_sop_q;
  logic                hold_eop_q;
  spadmic_source_id_e  hold_source_q;
  logic                hold_valid_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      hold_valid_q <= 1'b0;
      hold_data_q  <= '0;
      hold_sop_q   <= 1'b0;
      hold_eop_q   <= 1'b0;
      hold_source_q <= TDC_ID_X;
    end else begin
      assert (count_q <= 2'd2)
        else $error("spadmic_stream_skid_buffer: illegal occupancy");

      if (out_valid_o && !out_ready_i) begin
        if (hold_valid_q) begin
          assert (out_data_o == hold_data_q)
            else $error("spadmic_stream_skid_buffer: data changed under stall");
          assert (out_sop_o == hold_sop_q)
            else $error("spadmic_stream_skid_buffer: SOP changed under stall");
          assert (out_eop_o == hold_eop_q)
            else $error("spadmic_stream_skid_buffer: EOP changed under stall");
          assert (out_source_o == hold_source_q)
            else $error("spadmic_stream_skid_buffer: source changed under stall");
        end
        hold_valid_q <= 1'b1;
        hold_data_q  <= out_data_o;
        hold_sop_q   <= out_sop_o;
        hold_eop_q   <= out_eop_o;
        hold_source_q <= out_source_o;
      end else begin
        hold_valid_q <= 1'b0;
      end
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
