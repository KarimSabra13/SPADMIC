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
    i2c_if.i2c_write(addr, data, success);
    if (!success)
      $display("[I2C_DRV] WARN: write to 0x%03h NACKed", addr);
  endtask

  task automatic read_csr(
    input  logic [SPADMIC_CSR_ADDR_W-1:0] addr,
    output logic [SPADMIC_CSR_DATA_W-1:0] data,
    output logic                          err
  );
    logic success;
    i2c_if.i2c_read(addr, data, success);
    err = ~success;
    if (!success)
      $display("[I2C_DRV] WARN: read from 0x%03h NACKed", addr);
  endtask

  function automatic spadmic_operating_mode_e operating_mode(spadmic_ctrl_txn t);
    spadmic_export_mode_e export_mode;
    if (!t.global_enable)
      return SPADMIC_MODE_DISABLED;
    export_mode = spadmic_export_mode_from_ctrl(t.shared_tx_sel, t.position_enable);
    case (export_mode)
      SPADMIC_EXPORT_POSITION_ONLY: return SPADMIC_MODE_POSITION_ONLY;
      SPADMIC_EXPORT_BOTH_ACTIVE:   return SPADMIC_MODE_BOTH;
      default:                      return SPADMIC_MODE_TDC_ONLY;
    endcase
  endfunction

  task automatic program_global_ctrl(spadmic_ctrl_txn t);
    logic [SPADMIC_CSR_DATA_W-1:0] ctrl_word;
    spadmic_operating_mode_e mode;
    mode = operating_mode(t);
    ctrl_word = '0;
    ctrl_word[0]   = t.global_enable;
    ctrl_word[3:1] = mode;
    ctrl_word[6:4] = 3'b111;
    ctrl_word[7]   = 1'b1;
    write_csr(CSR_GLOBAL_CTRL, ctrl_word);
  endtask

  task automatic program_disabled();
    write_csr(CSR_GLOBAL_CTRL, 32'h0000_00F0);
  endtask

  task automatic program_tdc_shared(logic [MAX_HITS_W-1:0] max_hits);
    write_csr(CSR_TDC_SHARED_CFG, {{(32-MAX_HITS_W){1'b0}}, max_hits});
  endtask

  task automatic program_position_config(
    spadmic_pos_mode_e mode,
    logic [6:0] gap_threshold,
    logic [SPADMIC_LINE_COUNT_W-1:0] min_cluster_span
  );
    logic [31:0] cfg_word;
    cfg_word = '0;
    cfg_word[0] = mode;
    cfg_word[7:1] = gap_threshold;
    cfg_word[14:8] = 7'(min_cluster_span);
    write_csr(CSR_POSITION_CFG, cfg_word);
  endtask

  task automatic program_reset_width(logic [15:0] width_cycles);
    write_csr(CSR_RESET_CFG, {16'b0, width_cycles});
  endtask

  task automatic program_snapshot_config(
    logic [15:0] settle_cycles,
    logic [15:0] watchdog_cycles
  );
    write_csr(CSR_SNAPSHOT_CFG, {watchdog_cycles, settle_cycles});
  endtask

  task automatic read_global_status(
    output logic [SPADMIC_CSR_DATA_W-1:0] status,
    output logic                          err
  );
    read_csr(CSR_GLOBAL_STATUS, status, err);
  endtask

  task automatic read_global_fault(
    output logic [SPADMIC_CSR_DATA_W-1:0] fault,
    output logic                          err
  );
    read_csr(CSR_GLOBAL_FAULT, fault, err);
  endtask

  task automatic wait_safe_idle(int unsigned timeout_cycles);
    logic [SPADMIC_CSR_DATA_W-1:0] status;
    logic err;
    int unsigned count = 0;
    forever begin
      read_csr(CSR_GLOBAL_STATUS, status, err);
      if (!err && status[7]) return;
      count++;
      if (count >= timeout_cycles) begin
        $display("[I2C_DRV] WARN: safe-idle timeout after %0d polls", count);
        return;
      end
      // I2C is slow, no need for extra wait between polls
    end
  endtask

endclass
