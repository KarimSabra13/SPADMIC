// =============================================================================
// SPADMIC VIP — I2C End-to-End Test
// Full I2C programming: write + readback across all 5 CSR regions.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

class spadmic_i2c_end_to_end extends spadmic_base_test;
  import spadmic_vip_pkg::*;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  function new();
    super.new("i2c_end_to_end");
  endfunction

  function void configure();
    cfg.drv_mode   = DRV_MODE_I2C;
    cfg.profile    = PROFILE_TDC_CHAR;
    cfg.timeout_ns = 5_000_000;  // I2C is slow
  endfunction

  task body();
    // Full chip configuration via I2C
    env.gen.gen_initial_config();

    // Read back ID register
    begin
      spadmic_ctrl_txn rd = new();
      rd.is_read  = 1'b1;
      rd.addr     = SPADMIC_CSR_GLOBAL_ID;
      rd.drv_mode = DRV_MODE_I2C;
      env.gen.drv_mb.put(rd);
    end

    // Read back VERSION register
    begin
      spadmic_ctrl_txn rd = new();
      rd.is_read  = 1'b1;
      rd.addr     = SPADMIC_CSR_GLOBAL_VERSION;
      rd.drv_mode = DRV_MODE_I2C;
      env.gen.drv_mb.put(rd);
    end

    // Read back STATUS
    begin
      spadmic_ctrl_txn rd = new();
      rd.is_read  = 1'b1;
      rd.addr     = SPADMIC_CSR_GLOBAL_STATUS;
      rd.drv_mode = DRV_MODE_I2C;
      env.gen.drv_mb.put(rd);
    end

    // TDC conversion via I2C path
    env.gen.gen_tdc_conversions(0, 2, 10000);

    env.gen.gen_eot();
  endtask
endclass

`default_nettype wire
