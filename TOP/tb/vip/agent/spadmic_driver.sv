// =============================================================================
// SPADMIC VIP — Top-Level Orchestrating Driver
// Consumes transactions from the generator mailbox and dispatches to
// the appropriate sub-drivers (CSR/I2C, event, position, BP, reset).
// =============================================================================

class spadmic_driver;

  mailbox #(spadmic_base_txn)  drv_mb;
  spadmic_csr_driver           csr_drv;
  spadmic_i2c_driver           i2c_drv;
  spadmic_event_driver         ev_drv;
  spadmic_pos_driver           pos_drv;
  spadmic_bp_driver            bp_drv;
  spadmic_env_cfg              cfg;

  // Reset control wire (directly driven by harness)
  virtual spadmic_narrow_tx_if tx_if;
  logic async_rst_n_ref;

  // Scoreboard notification mailbox
  mailbox #(spadmic_base_txn)  sb_mb;

  bit done;

  function new(
    mailbox #(spadmic_base_txn) drv_mb,
    mailbox #(spadmic_base_txn) sb_mb,
    spadmic_env_cfg             cfg,
    spadmic_csr_driver          csr_drv,
    spadmic_i2c_driver          i2c_drv,
    spadmic_event_driver        ev_drv,
    spadmic_pos_driver          pos_drv,
    spadmic_bp_driver           bp_drv
  );
    this.drv_mb  = drv_mb;
    this.sb_mb   = sb_mb;
    this.cfg     = cfg;
    this.csr_drv = csr_drv;
    this.i2c_drv = i2c_drv;
    this.ev_drv  = ev_drv;
    this.pos_drv = pos_drv;
    this.bp_drv  = bp_drv;
    this.done    = 1'b0;
  endfunction

  task automatic run();
    spadmic_base_txn txn;
    done = 1'b0;

    forever begin
      drv_mb.get(txn);
      $display("[DRV] %s", txn.to_string());

      case (txn.kind)
        TXN_CTRL: begin
          spadmic_ctrl_txn ct;
          $cast(ct, txn);
          drive_ctrl(ct);
          sb_mb.put(txn);
        end

        TXN_TDC_EVENT: begin
          spadmic_tdc_event_txn et;
          $cast(et, txn);
          ev_drv.inject_tdc_events(et);
          sb_mb.put(txn);
        end

        TXN_POS_EVENT: begin
          spadmic_pos_event_txn pt;
          $cast(pt, txn);
          pos_drv.drive_position_event(pt);
          sb_mb.put(txn);
        end

        TXN_BP: begin
          spadmic_bp_txn bt;
          $cast(bt, txn);
          bp_drv.set_mode(bt.mode);
        end

        TXN_RESET: begin
          spadmic_reset_txn rt;
          $cast(rt, txn);
          // Reset is driven at the harness level — signal via sb_mb
          sb_mb.put(txn);
        end

        TXN_EOT: begin
          spadmic_eot_txn eot;
          $cast(eot, txn);
          // Wait for pipeline drain before signalling completion
          #(int'(eot.drain_timeout_ns) * 1000);
          sb_mb.put(txn);
          done = 1'b1;
          return;
        end
      endcase
    end
  endtask

  // Drive a control transaction via the appropriate interface
  task automatic drive_ctrl(spadmic_ctrl_txn ct);
    if (ct.is_read) begin
      // CSR read
      if (ct.drv_mode == DRV_MODE_DIRECT_CSR)
        csr_drv.read_csr(ct.addr, ct.rdata, ct.rsp_err);
      else
        i2c_drv.read_csr(ct.addr, ct.rdata, ct.rsp_err);
    end else begin
      // Full chip config sequence
      if (ct.drv_mode == DRV_MODE_DIRECT_CSR) begin
        csr_drv.wait_cfg_accept(500);
        for (int ax = 0; ax < 3; ax++) begin
          csr_drv.program_tdc_max_hits(ax, ct.max_hits);
          csr_drv.program_tdc_conv_arm(ax, 1'b1);
        end
        csr_drv.program_global_ctrl(ct);
        // Wait for sequencer to commit the new active config
        csr_drv.wait_cfg_accept(500);
      end else begin
        i2c_drv.wait_cfg_accept(500);
        for (int ax = 0; ax < 3; ax++) begin
          i2c_drv.program_tdc_max_hits(ax, ct.max_hits);
          i2c_drv.program_tdc_conv_arm(ax, 1'b1);
        end
        i2c_drv.program_global_ctrl(ct);
        i2c_drv.wait_cfg_accept(500);
      end
    end
  endtask

endclass

