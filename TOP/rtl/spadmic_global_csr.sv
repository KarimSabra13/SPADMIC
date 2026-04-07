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
  input  wire                                position_busy_i,
  input  wire                                position_pending_i,

  output logic                               global_enable_o,
  output logic [2:0]                         axis_enable_o,
  output logic                               position_enable_o
);
  import spadmic_pkg::*;

  logic [SPADMIC_CSR_DATA_W-1:0] rd_data_next;
  wire wr_en = csr_valid_i & csr_write_i;
  wire rd_en = csr_valid_i & ~csr_write_i;

  assign csr_ready_o = 1'b1;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      global_enable_o   <= 1'b0;
      axis_enable_o     <= 3'b111;
      position_enable_o <= 1'b1;
    end else if (wr_en) begin
      if (csr_addr_i == SPADMIC_CSR_GLOBAL_CTRL) begin
        global_enable_o   <= csr_wdata_i[0];
        axis_enable_o     <= csr_wdata_i[3:1];
        position_enable_o <= csr_wdata_i[4];
      end
    end
  end

  always_comb begin
    rd_data_next = '0;
    case (csr_addr_i)
      SPADMIC_CSR_GLOBAL_ID: begin
        rd_data_next = 32'h5350_4144;  // "SPAD"
      end
      SPADMIC_CSR_GLOBAL_VERSION: begin
        rd_data_next = 32'h0001_0000;
      end
      SPADMIC_CSR_GLOBAL_CTRL: begin
        rd_data_next[0]   = global_enable_o;
        rd_data_next[3:1] = axis_enable_o;
        rd_data_next[4]   = position_enable_o;
      end
      SPADMIC_CSR_GLOBAL_STATUS: begin
        rd_data_next[0]   = tdc_tx_busy_i;
        rd_data_next[3:1] = tdc_pkt_pending_i;
        rd_data_next[4]   = position_busy_i;
        rd_data_next[5]   = position_pending_i;
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
