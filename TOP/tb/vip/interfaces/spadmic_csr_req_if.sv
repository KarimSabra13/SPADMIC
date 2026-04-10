// =============================================================================
// SPADMIC VIP — Direct CSR Request/Response Interface
// Bypasses I2C for fast targeted regressions and block-level debug.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface spadmic_csr_req_if (
  input wire clk_sys,
  input wire rst_n
);
  import spadmic_pkg::*;

  // Request channel
  logic                          req_valid;
  logic                          req_write;
  logic [SPADMIC_CSR_ADDR_W-1:0] req_addr;
  logic [SPADMIC_CSR_DATA_W-1:0] req_wdata;
  logic                          req_ready;

  // Response channel
  logic                          rsp_valid;
  logic [SPADMIC_CSR_DATA_W-1:0] rsp_rdata;
  logic                          rsp_err;
  logic                          rsp_ready;

  // ── Clocking blocks ───────────────────────────────────────────
  clocking drv_cb @(posedge clk_sys);
    output req_valid, req_write, req_addr, req_wdata, rsp_ready;
    input  req_ready, rsp_valid, rsp_rdata, rsp_err;
  endclocking

  clocking mon_cb @(posedge clk_sys);
    input req_valid, req_write, req_addr, req_wdata, req_ready;
    input rsp_valid, rsp_rdata, rsp_err, rsp_ready;
  endclocking

  // ── BFM tasks ─────────────────────────────────────────────────
  task automatic csr_write(
    input logic [SPADMIC_CSR_ADDR_W-1:0] addr,
    input logic [SPADMIC_CSR_DATA_W-1:0] data
  );
    @(posedge clk_sys);
    req_valid = 1'b1;
    req_write = 1'b1;
    req_addr  = addr;
    req_wdata = data;
    #1;
    @(posedge clk_sys);
    while (!req_ready) @(posedge clk_sys);
    req_valid = 1'b0;
    #1;
  endtask

  task automatic csr_read(
    input  logic [SPADMIC_CSR_ADDR_W-1:0] addr,
    output logic [SPADMIC_CSR_DATA_W-1:0] data,
    output logic                          err
  );
    @(posedge clk_sys);
    req_valid = 1'b1;
    req_write = 1'b0;
    req_addr  = addr;
    req_wdata = '0;
    #1;
    @(posedge clk_sys);
    while (!req_ready) @(posedge clk_sys);
    req_valid = 1'b0;
    #1;

    // Wait for response
    rsp_ready = 1'b1;
    @(posedge clk_sys);
    while (!rsp_valid) @(posedge clk_sys);
    data = rsp_rdata;
    err  = rsp_err;
    rsp_ready = 1'b0;
    #1;
  endtask

  // ── Initial state ─────────────────────────────────────────────
  initial begin
    req_valid = 1'b0;
    req_write = 1'b0;
    req_addr  = '0;
    req_wdata = '0;
    rsp_ready = 1'b0;
  end

endinterface

`default_nettype wire
