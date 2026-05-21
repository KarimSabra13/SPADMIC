// =============================================================================
// SPADMIC VIP — Raw Position Smoke Test
// Verifies fixed-length raw bitmap packets through the physical TX path.
// =============================================================================

class spadmic_smoke_position_raw extends spadmic_base_test;

  function new();
    super.new("smoke_position_raw");
  endfunction

  function void configure();
    cfg.drv_mode   = DRV_MODE_DIRECT_CSR;
    cfg.profile    = PROFILE_POSITION;
    cfg.timeout_ns = 300_000;
  endfunction

  task body();
    logic [SPADMIC_LINE_W-1:0] xp;
    logic [SPADMIC_LINE_W-1:0] yp;
    logic [SPADMIC_LINE_W-1:0] zp;

    env.gen.gen_initial_config();
    env.gen.gen_csr_write(SPADMIC_CSR_POS_CTRL, 32'h0000_0003); // enable + raw mode

    xp = '0;
    yp = '0;
    zp = '0;

    // Deliberately create marker-looking raw payload words. The raw packet
    // monitor and correlator must not terminate early on these data words.
    xp[15:0] = 16'hFFFF;
    xp[SPADMIC_LINE_W-1] = 1'b1;
    yp[31:16] = 16'h8123;
    zp[47:32] = 16'hC123;
    zp[SPADMIC_LINE_W-2] = 1'b1;

    env.gen.gen_position_event(xp, yp, zp, 300);
    env.gen.gen_eot();
  endtask

endclass
