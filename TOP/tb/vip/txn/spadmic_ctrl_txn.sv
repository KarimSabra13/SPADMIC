// =============================================================================
// SPADMIC VIP — Control/Config Transaction
// Programs global CSR fields: enable, axis mask, tx_sel, TDC mode, etc.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_ctrl_txn extends spadmic_base_txn;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  // Target CSR address and data (for raw CSR writes)
  logic [SPADMIC_CSR_ADDR_W-1:0] addr;
  logic [SPADMIC_CSR_DATA_W-1:0] wdata;
  logic                          is_read;

  // Semantic fields for high-level config (used by generator)
  logic                  global_enable;
  rand logic [2:0]            axis_enable;
  logic                  position_enable;
  spadmic_tx_sel_e       shared_tx_sel;
  input_sel_e            tdc_input_sel;
  rand out_mode_e             tdc_out_mode;
  rand logic [MAX_HITS_W-1:0] max_hits;

  // Response capture (for reads)
  logic [SPADMIC_CSR_DATA_W-1:0] rdata;
  logic                          rsp_err;

  // Driver mode: I2C or direct CSR
  spadmic_drv_mode_e     drv_mode;

  // Randomization constraints
  constraint c_legal_max_hits {
    max_hits inside {4'd1, 4'd5, 4'd10, 4'd15};
  }

  constraint c_legal_axis_enable {
    axis_enable == 3'b111;
  }

  constraint c_legal_out_mode {
    tdc_out_mode inside {OUT_MODE_RAW_FEATURES, OUT_MODE_RAW_TIMESTAMP, OUT_MODE_FULL};
  }

  function new();
    super.new(TXN_CTRL);
    this.addr            = '0;
    this.wdata           = '0;
    this.is_read         = 1'b0;
    this.global_enable   = 1'b1;
    this.axis_enable     = 3'b111;
    this.position_enable = 1'b0;
    this.shared_tx_sel   = SPADMIC_TX_TDC;
    this.tdc_input_sel   = INPUT_CAL;
    this.tdc_out_mode    = OUT_MODE_RAW_FEATURES;
    this.max_hits        = 4'd15;
    this.drv_mode        = DRV_MODE_DIRECT_CSR;
  endfunction

  function string to_string();
    if (is_read)
      return $sformatf("[CTRL_TXN #%0d] READ addr=0x%03h rdata=0x%08h err=%0b",
                        txn_id, addr, rdata, rsp_err);
    else
      return $sformatf("[CTRL_TXN #%0d] en=%0b axis=%03b pos=%0b tx_sel=%s in=%s mode=%s hits=%0d",
                        txn_id, global_enable, axis_enable, position_enable,
                        shared_tx_sel.name(), tdc_input_sel.name(),
                        tdc_out_mode.name(), max_hits);
  endfunction
endclass

`default_nettype wire
