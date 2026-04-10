// =============================================================================
// SPADMIC VIP — Control Reject Test
// Writes GLOBAL_CTRL while NOT idle → expects reject sticky + count.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_ctrl_reject extends spadmic_base_test;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  function new();
    super.new("ctrl_reject");
  endfunction

  function void configure();
    cfg.drv_mode   = DRV_MODE_DIRECT_CSR;
    cfg.profile    = PROFILE_TDC_CHAR;
    cfg.timeout_ns = 500_000;
  endfunction

  task body();
    // Start TDC traffic
    env.gen.gen_initial_config();
    env.gen.gen_tdc_conversions(0, 10, 10000);

    // While traffic is in-flight, attempt to change mode (should be rejected)
    begin
      spadmic_ctrl_txn ct = new();
      ct.global_enable  = 1'b1;
      ct.axis_enable    = 3'b111;
      ct.shared_tx_sel  = SPADMIC_TX_POSITION;  // try switching
      ct.drv_mode       = cfg.drv_mode;
      env.gen.drv_mb.put(ct);
    end

    // Read fault register to check reject
    begin
      spadmic_ctrl_txn rd = new();
      rd.is_read = 1'b1;
      rd.addr    = SPADMIC_CSR_GLOBAL_FAULT;
      rd.drv_mode = cfg.drv_mode;
      env.gen.drv_mb.put(rd);
    end

    env.gen.gen_eot();
  endtask
endclass

`default_nettype wire
