// =============================================================================
// SPADMIC CSR ABI 1.0 page router. One request may be outstanding.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_csr_router (
  input  logic         clk_sys,
  input  logic         rst_n,
  input  logic         csr_valid_i,
  input  logic         csr_write_i,
  input  logic [15:0]  csr_addr_i,
  input  logic [31:0]  csr_wdata_i,
  output logic         csr_ready_o,
  output logic         csr_rvalid_o,
  output logic [31:0]  csr_rdata_o,
  output logic         csr_err_o,
  output logic [9:0]   bank_req_valid_o,
  input  logic [9:0]   bank_rsp_valid_i,
  input  logic [9:0][31:0] bank_rsp_rdata_i,
  input  logic [9:0]   bank_rsp_err_i,
  input  logic [9:0][7:0] bank_rsp_cause_i,
  output logic         access_error_event_o,
  output logic         access_error_write_o,
  output logic [15:0]  access_error_addr_o,
  output logic [31:0]  access_error_wdata_o,
  output logic [7:0]   access_error_cause_o
);
  import spadmic_csr_map_pkg::*;

  logic busy_q;
  logic invalid_rsp_valid_q;
  logic [7:0] invalid_rsp_cause_q;
  logic request_write_q;
  logic [15:0] request_addr_q;
  logic [31:0] request_wdata_q;
  logic selected_rsp_valid;
  logic [31:0] selected_rsp_rdata;
  logic selected_rsp_err;
  logic [7:0] selected_rsp_cause;

  assign csr_ready_o = !busy_q;

  always_comb begin
    bank_req_valid_o = '0;
    if (csr_valid_i && csr_ready_o && csr_word_aligned(csr_addr_i) &&
        (csr_addr_i[15:12] <= 4'h9))
      bank_req_valid_o[csr_addr_i[15:12]] = 1'b1;
  end

  always_comb begin
    selected_rsp_valid = invalid_rsp_valid_q;
    selected_rsp_rdata = '0;
    selected_rsp_err = invalid_rsp_valid_q;
    selected_rsp_cause = invalid_rsp_cause_q;
    for (int page = 0; page < 10; page++) begin
      if (bank_rsp_valid_i[page]) begin
        selected_rsp_valid = 1'b1;
        selected_rsp_rdata = bank_rsp_rdata_i[page];
        selected_rsp_err = bank_rsp_err_i[page];
        selected_rsp_cause = bank_rsp_cause_i[page];
      end
    end
  end

  assign csr_rvalid_o = selected_rsp_valid;
  assign csr_rdata_o = selected_rsp_err ? 32'h0000_0000 : selected_rsp_rdata;
  assign csr_err_o = selected_rsp_err;
  assign access_error_event_o = selected_rsp_valid && selected_rsp_err;
  assign access_error_write_o = request_write_q;
  assign access_error_addr_o = request_addr_q;
  assign access_error_wdata_o = request_wdata_q;
  assign access_error_cause_o = selected_rsp_cause;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      busy_q <= 1'b0;
      invalid_rsp_valid_q <= 1'b0;
      invalid_rsp_cause_q <= CSR_CAUSE_NONE;
      request_write_q <= 1'b0;
      request_addr_q <= '0;
      request_wdata_q <= '0;
    end else begin
      invalid_rsp_valid_q <= 1'b0;

      if (selected_rsp_valid)
        busy_q <= 1'b0;

      if (csr_valid_i && csr_ready_o) begin
        busy_q <= 1'b1;
        request_write_q <= csr_write_i;
        request_addr_q <= csr_addr_i;
        request_wdata_q <= csr_wdata_i;
        if (!csr_word_aligned(csr_addr_i)) begin
          invalid_rsp_valid_q <= 1'b1;
          invalid_rsp_cause_q <= CSR_CAUSE_MISALIGNED;
        end else if (csr_addr_i[15:12] > 4'h9) begin
          invalid_rsp_valid_q <= 1'b1;
          invalid_rsp_cause_q <= CSR_CAUSE_UNMAPPED;
        end
      end
    end
  end
endmodule

`default_nettype wire
