// =============================================================================
// SPADMIC VIP — CSR Response Monitor
// Watches CSR reads/writes for status polling and fault tracking.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_csr_monitor;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  virtual spadmic_csr_req_if csr_if;
  mailbox #(int)             cov_mb;

  // Tracked CSR state
  logic [SPADMIC_CSR_DATA_W-1:0] last_status;
  logic [SPADMIC_CSR_DATA_W-1:0] last_fault;
  logic [SPADMIC_CSR_DATA_W-1:0] last_fault_count;
  int unsigned                   total_writes;
  int unsigned                   total_reads;
  int unsigned                   total_errors;
  bit                            running;

  function new(
    virtual spadmic_csr_req_if csr_if,
    mailbox #(int)             cov_mb
  );
    this.csr_if      = csr_if;
    this.cov_mb      = cov_mb;
    this.total_writes = 0;
    this.total_reads  = 0;
    this.total_errors = 0;
    this.running      = 1'b0;
  endfunction

  task automatic run();
    running = 1'b1;
    forever begin
      @(posedge csr_if.clk_sys);
      if (!csr_if.rst_n) continue;

      // Monitor request channel
      if (csr_if.req_valid && csr_if.req_ready) begin
        if (csr_if.req_write) begin
          total_writes++;
          $display("[CSR_MON] WRITE addr=0x%03h data=0x%08h (#%0d)",
                   csr_if.req_addr, csr_if.req_wdata, total_writes);
        end else begin
          total_reads++;
        end
      end

      // Monitor response channel
      if (csr_if.rsp_valid && csr_if.rsp_ready) begin
        if (csr_if.rsp_err) begin
          total_errors++;
          $display("[CSR_MON] ERROR rsp for read #%0d", total_reads);
        end
      end
    end
  endtask

endclass

`default_nettype wire
