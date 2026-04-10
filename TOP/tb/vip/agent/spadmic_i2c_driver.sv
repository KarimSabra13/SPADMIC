// =============================================================================
// SPADMIC VIP — I2C Driver
// Drives I2C interface for chip-realistic end-to-end control.
// =============================================================================

class spadmic_i2c_driver;

  virtual spadmic_i2c_if i2c_if;

  function new(virtual spadmic_i2c_if i2c_if);
    this.i2c_if = i2c_if;
  endfunction

  task automatic write_csr(
    input logic [SPADMIC_CSR_ADDR_W-1:0] addr,
    input logic [SPADMIC_CSR_DATA_W-1:0] data
  );
    logic success;
    i2c_if.i2c_write(addr[11:0], data, success);
    if (!success)
      $display("[I2C_DRV] WARN: write to 0x%03h NACKed", addr);
  endtask

  task automatic read_csr(
    input  logic [SPADMIC_CSR_ADDR_W-1:0] addr,
    output logic [SPADMIC_CSR_DATA_W-1:0] data,
    output logic                          err
  );
    logic success;
    i2c_if.i2c_read(addr[11:0], data, success);
    err = ~success;
    if (!success)
      $display("[I2C_DRV] WARN: read from 0x%03h NACKed", addr);
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

  // Arm TDC conversion on specified axis (writes MPTDC CSR_CTRL.conv_arm)
  task automatic program_tdc_conv_arm(int unsigned axis, logic arm);
    logic [SPADMIC_CSR_ADDR_W-1:0] base_addr;
    case (axis)
      0: base_addr = {SPADMIC_REGION_TDC_X, 8'h00};
      1: base_addr = {SPADMIC_REGION_TDC_Y, 8'h00};
      2: base_addr = {SPADMIC_REGION_TDC_Z, 8'h00};
      default: base_addr = {SPADMIC_REGION_TDC_X, 8'h00};
    endcase
    write_csr(base_addr, {31'b0, arm});
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

  // Poll for cfg_accept (bit 21 of STATUS)
  task automatic wait_cfg_accept(int unsigned timeout_cycles);
    logic [SPADMIC_CSR_DATA_W-1:0] status;
    logic err;
    int unsigned count = 0;
    forever begin
      read_csr(SPADMIC_CSR_GLOBAL_STATUS, status, err);
      if (status[21]) return;
      count++;
      if (count >= timeout_cycles) begin
        $display("[I2C_DRV] WARN: cfg_accept timeout after %0d polls", count);
        return;
      end
      // I2C is slow, no need for extra wait between polls
    end
  endtask

endclass

