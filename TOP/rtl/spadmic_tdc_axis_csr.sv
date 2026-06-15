`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_tdc_axis_csr.sv
// Purpose  : TOP-owned product CSR block for one TDC axis.
// =============================================================================
module spadmic_tdc_axis_csr (
  input  wire                               clk_sys,
  input  wire                               rst_n,

  input  wire                               csr_valid_i,
  input  wire                               csr_write_i,
  input  wire [mptdc_pkg::CSR_ADDR_W-1:0]  csr_addr_i,
  input  wire [mptdc_pkg::CSR_DATA_W-1:0]  csr_wdata_i,
  output wire                               csr_ready_o,
  output logic                              csr_rvalid_o,
  output logic [mptdc_pkg::CSR_DATA_W-1:0] csr_rdata_o,

  input  wire                               ready_i,
  input  wire                               busy_i,
  input  wire                               fifo_full_i,
  input  wire                               packet_active_i,
  input  wire                               packet_pending_i,
  input  wire                               stop_armed_i,

  input  wire [mptdc_pkg::MAX_HITS_W-1:0]  max_hits_i,
  output logic                              max_hits_we_o,
  output logic [mptdc_pkg::MAX_HITS_W-1:0] max_hits_wdata_o,

  output logic                              conv_arm_o,
  output logic                              fifo_clr_pulse_o,
  output logic                              soft_rst_pulse_o
);
  import mptdc_pkg::*;

  wire wr_en = csr_valid_i & csr_write_i;
  wire rd_en = csr_valid_i & ~csr_write_i;

  assign csr_ready_o = 1'b1;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      conv_arm_o          <= 1'b0;
      fifo_clr_pulse_o    <= 1'b0;
      soft_rst_pulse_o    <= 1'b0;
      max_hits_we_o       <= 1'b0;
      max_hits_wdata_o    <= MAX_HITS_W'(MAX_HITS);
    end else begin
      fifo_clr_pulse_o <= 1'b0;
      soft_rst_pulse_o <= 1'b0;
      max_hits_we_o    <= 1'b0;

      if (wr_en) begin
        unique case (csr_addr_i)
          CSR_CTRL: begin
            conv_arm_o       <= csr_wdata_i[0];
            fifo_clr_pulse_o <= csr_wdata_i[1];
            soft_rst_pulse_o <= csr_wdata_i[2];
          end

          CSR_MAX_HITS: begin
            max_hits_we_o    <= 1'b1;
            max_hits_wdata_o <= csr_wdata_i[MAX_HITS_W-1:0];
          end

          default: ;
        endcase
      end

      if (soft_rst_pulse_o)
        conv_arm_o <= 1'b0;
    end
  end

  logic [CSR_DATA_W-1:0] rd_data_next;

  always_comb begin
    rd_data_next = '0;

    unique case (csr_addr_i)
      CSR_CTRL: begin
        rd_data_next[0] = conv_arm_o;
      end

      CSR_MAX_HITS: begin
        rd_data_next[MAX_HITS_W-1:0] = max_hits_i;
      end

      CSR_STATUS: begin
        rd_data_next[0] = ready_i;
        rd_data_next[1] = busy_i;
        rd_data_next[2] = fifo_full_i;
        rd_data_next[3] = packet_active_i;
        rd_data_next[4] = packet_pending_i;
        rd_data_next[5] = stop_armed_i;
      end

      CSR_FIFO_STATUS: begin
        rd_data_next[0] = fifo_full_i;
        rd_data_next[1] = packet_active_i;
        rd_data_next[2] = packet_pending_i;
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

endmodule : spadmic_tdc_axis_csr

`default_nettype wire
