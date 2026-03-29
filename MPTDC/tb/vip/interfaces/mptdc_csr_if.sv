// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : mptdc_csr_if.sv
// Purpose : VIP interface for CSR valid/write/addr/data handshakes.
// Author  : Karim Sabra
// Notes   : Tasks implement the simple one-request-at-a-time timing contract used
//           by the VIP BFM and smoke scripts.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface mptdc_csr_if #(parameter int ADDR_W = mptdc_pkg::CSR_ADDR_W,
                         parameter int DATA_W = mptdc_pkg::CSR_DATA_W)
(
  input logic clk_sys
);
  import mptdc_pkg::*;

  logic              csr_valid;
  logic              csr_write;
  logic [ADDR_W-1:0] csr_addr;
  logic [DATA_W-1:0] csr_wdata;
  logic              csr_ready;
  logic              csr_rvalid;
  logic [DATA_W-1:0] csr_rdata;

  // Return the CSR request channel to an idle state between transactions.
  task automatic reset_bus();
    csr_valid = 1'b0;
    csr_write = 1'b0;
    csr_addr  = '0;
    csr_wdata = '0;
  endtask

  // Drive one CSR write request and hold it long enough for the simple
  // DUT-side valid/ready handshake used by the VIP harness.
  task automatic write_reg(input logic [ADDR_W-1:0] addr,
                           input logic [DATA_W-1:0] data);
    #1;
    csr_valid = 1'b1;
    csr_write = 1'b1;
    csr_addr  = addr;
    csr_wdata = data;
    @(posedge clk_sys);
    @(posedge clk_sys);
    @(posedge clk_sys);
    csr_valid = 1'b0;
    csr_write = 1'b0;
  endtask

  // Drive one CSR read request, then wait for csr_rvalid before returning
  // data to the caller so tests see the architectural read contract.
  task automatic read_reg(input logic [ADDR_W-1:0] addr,
                          output logic [DATA_W-1:0] data);
    #1;
    csr_valid = 1'b1;
    csr_write = 1'b0;
    csr_addr  = addr;
    csr_wdata = '0;
    @(posedge clk_sys);
    @(posedge clk_sys);
    @(posedge clk_sys);
    csr_valid = 1'b0;
    while (!csr_rvalid)
      @(posedge clk_sys);
    data = csr_rdata;
  endtask

endinterface

`default_nettype wire
