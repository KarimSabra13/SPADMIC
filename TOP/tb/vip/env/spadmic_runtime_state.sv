// =============================================================================
// SPADMIC VIP — Shared Runtime State
// Tracks the active config seen by the driver so monitors can decode packets
// using the same control context.
// =============================================================================

class spadmic_runtime_state;

  logic                     active_global_enable;
  spadmic_tx_sel_e          active_tx_sel;
  logic                     active_position_enable;
  input_sel_e               active_input_sel;
  out_mode_e                active_out_mode;
  logic [MAX_HITS_W-1:0]    active_max_hits;
  spadmic_pos_mode_e        active_pos_mode;

  function new();
    apply_reset_defaults();
  endfunction

  function automatic void apply_reset_defaults();
    active_global_enable   = 1'b0;
    active_tx_sel          = SPADMIC_TX_TDC;
    active_position_enable = 1'b1;
    active_input_sel       = INPUT_SPAD;
    active_out_mode        = OUT_MODE_RAW_FEATURES;
    active_max_hits        = 4'd15;
    active_pos_mode        = SPADMIC_POS_MODE_CLUSTER;
  endfunction

  function automatic void note_ctrl_txn(spadmic_ctrl_txn ct);
    if (ct.is_read)
      return;

    if (ct.raw_csr_write) begin
      case (ct.addr)
        SPADMIC_CSR_POS_CTRL: active_pos_mode = spadmic_pos_mode_e'(ct.wdata[1]);
        default: ;
      endcase
      return;
    end

    active_global_enable   = ct.global_enable;
    active_tx_sel          = ct.shared_tx_sel;
    active_position_enable = ct.position_enable;
    active_input_sel       = ct.tdc_input_sel;
    active_out_mode        = ct.tdc_out_mode;
    active_max_hits        = ct.max_hits;
  endfunction

  function automatic bit raw_pos_allowed();
    return ((active_tx_sel == SPADMIC_TX_POSITION) || active_position_enable)
           && (active_pos_mode == SPADMIC_POS_MODE_RAW);
  endfunction

endclass

