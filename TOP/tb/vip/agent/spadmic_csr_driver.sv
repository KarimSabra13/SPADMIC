// =============================================================================
// SPADMIC VIP — Direct CSR Driver
// Drives CSR request/response interface for fast targeted regressions.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_csr_driver;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  virtual spadmic_csr_req_if csr_if;

  function new(virtual spadmic_csr_req_if csr_if);
    this.csr_if = csr_if;
  endfunction

  task automatic write_csr(
    input logic [SPADMIC_CSR_ADDR_W-1:0] addr,
    input logic [SPADMIC_CSR_DATA_W-1:0] data
  );
    csr_if.csr_write(addr, data);
  endtask

  task automatic read_csr(
    input  logic [SPADMIC_CSR_ADDR_W-1:0] addr,
    output logic [SPADMIC_CSR_DATA_W-1:0] data,
    output logic                          err
  );
    csr_if.csr_read(addr, data, err);
  endtask

  // Program global control register from semantic fields
  task automatic program_global_ctrl(spadmic_ctrl_txn t);
    logic [SPADMIC_CSR_DATA_W-1:0] ctrl_word;
    ctrl_word = '0;
    ctrl_word[0]   = t.global_enable;
    ctrl_word[3:1] = t.axis_enable;
    ctrl_word[4]   = t.position_enable;
    ctrl_word[5]   = t.shared_tx_sel;
    ctrl_word[6]   = t.tdc_input_sel;
    ctrl_word[8:7] = t.tdc_out_mode;
    write_csr(SPADMIC_CSR_GLOBAL_CTRL, ctrl_word);
  endtask

  // Program TDC axis max_hits register
  task automatic program_tdc_max_hits(int unsigned axis, logic [MAX_HITS_W-1:0] max_hits);
    logic [SPADMIC_CSR_ADDR_W-1:0] base_addr;
    case (axis)
      0: base_addr = {SPADMIC_REGION_TDC_X, 8'h08};
      1: base_addr = {SPADMIC_REGION_TDC_Y, 8'h08};
      2: base_addr = {SPADMIC_REGION_TDC_Z, 8'h08};
      default: base_addr = {SPADMIC_REGION_TDC_X, 8'h08};
    endcase
    write_csr(base_addr, {28'b0, max_hits});
  endtask

  // Program position gap/filter config
  task automatic program_position_config(
    logic [6:0] gap_threshold,
    logic [6:0] min_cluster_span,
    logic [3:0] settle_cycles
  );
    write_csr(SPADMIC_CSR_POS_GAP_CFG, {25'b0, gap_threshold});
    write_csr(SPADMIC_CSR_POS_FILTER_CFG, {21'b0, min_cluster_span, settle_cycles});
  endtask

  // Read and return global status register
  task automatic read_global_status(
    output logic [SPADMIC_CSR_DATA_W-1:0] status
  );
    logic err;
    read_csr(SPADMIC_CSR_GLOBAL_STATUS, status, err);
  endtask

  // Poll for cfg_accept (bit 0 of STATUS)
  task automatic wait_cfg_accept(int unsigned timeout_cycles);
    logic [SPADMIC_CSR_DATA_W-1:0] status;
    logic err;
    int unsigned count = 0;
    forever begin
      read_csr(SPADMIC_CSR_GLOBAL_STATUS, status, err);
      if (status[0]) return;  // cfg_accept
      count++;
      if (count >= timeout_cycles) begin
        $display("[CSR_DRV] WARN: cfg_accept timeout after %0d polls", count);
        return;
      end
      repeat (10) @(posedge csr_if.clk_sys);
    end
  endtask

endclass

`default_nettype wire
