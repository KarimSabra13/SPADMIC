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
  spadmic_runtime_state        state;

  // Reconstructed TX stream plus real reset BFM
  virtual spadmic_narrow_tx_if tx_if;
  virtual spadmic_reset_if     reset_if;

  // Scoreboard notification mailbox
  mailbox #(spadmic_base_txn)  sb_mb;

  logic                        active_global_enable;
  spadmic_tx_sel_e             active_tx_sel;
  logic                        active_position_enable;
  input_sel_e                  active_input_sel;
  out_mode_e                   active_out_mode;
  logic [MAX_HITS_W-1:0]       active_max_hits;

`ifdef SPADMIC_ENABLE_FUNC_COV
  spadmic_stim_cov             stim_cov;
  spadmic_ctrl_cov             ctrl_cov;
  spadmic_fault_cov            fault_cov;
`endif

  bit done;

  function new(
    mailbox #(spadmic_base_txn) drv_mb,
    mailbox #(spadmic_base_txn) sb_mb,
    spadmic_env_cfg             cfg,
    spadmic_runtime_state       state,
    virtual spadmic_reset_if    reset_if,
    spadmic_csr_driver          csr_drv,
    spadmic_i2c_driver          i2c_drv,
    spadmic_event_driver        ev_drv,
    spadmic_pos_driver          pos_drv,
    spadmic_bp_driver           bp_drv
`ifdef SPADMIC_ENABLE_FUNC_COV
    ,
    spadmic_stim_cov            stim_cov,
    spadmic_ctrl_cov            ctrl_cov,
    spadmic_fault_cov           fault_cov
`endif
  );
    this.drv_mb  = drv_mb;
    this.sb_mb   = sb_mb;
    this.cfg     = cfg;
    this.state   = state;
    this.reset_if = reset_if;
    this.csr_drv = csr_drv;
    this.i2c_drv = i2c_drv;
    this.ev_drv  = ev_drv;
    this.pos_drv = pos_drv;
    this.bp_drv  = bp_drv;
`ifdef SPADMIC_ENABLE_FUNC_COV
    this.stim_cov = stim_cov;
    this.ctrl_cov = ctrl_cov;
    this.fault_cov = fault_cov;
`endif
    this.done    = 1'b0;
    this.active_global_enable = 1'b0;
    this.active_tx_sel = SPADMIC_TX_TDC;
    this.active_position_enable = 1'b1;
    this.active_input_sel = INPUT_SPAD;
    this.active_out_mode = OUT_MODE_RAW_FEATURES;
    this.active_max_hits = 4'd15;
  endfunction

  function automatic void apply_reset_defaults();
    active_global_enable   = 1'b0;
    active_tx_sel          = SPADMIC_TX_TDC;
    active_position_enable = 1'b1;
    active_input_sel       = INPUT_SPAD;
    active_out_mode        = OUT_MODE_RAW_FEATURES;
    active_max_hits        = 4'd15;
    state.apply_reset_defaults();
  endfunction

  function automatic int delay_bin(input int unsigned delay_ps);
    if (delay_ps <= 5_000)
      return 0;
    else if (delay_ps <= 12_000)
      return 1;
    else if (delay_ps <= 20_000)
      return 2;
    return 3;
  endfunction

`ifdef SPADMIC_ENABLE_FUNC_COV
  task automatic sample_stimulus_cov(
    input spadmic_stim_kind_e stim_kind,
    input logic [2:0]         axis_mask,
    input logic               pos_present,
    input int unsigned        delay_ps
  );
    stim_cov.sample(
      spadmic_export_mode_from_ctrl(active_tx_sel, active_position_enable),
      cfg.drv_mode,
      active_input_sel,
      active_out_mode,
      active_max_hits,
      axis_mask,
      pos_present,
      delay_bin(delay_ps),
      stim_kind
    );
  endtask

  task automatic sample_ctrl_fault_cov(input logic reset_during_traffic);
    logic [SPADMIC_CSR_DATA_W-1:0] status;
    logic [SPADMIC_CSR_DATA_W-1:0] fault;
    logic status_err;
    logic fault_err;
    logic [1:0] seq_state_derived;

    if (cfg.drv_mode == DRV_MODE_DIRECT_CSR) begin
      csr_drv.read_global_status(status);
      status_err = 1'b0;
      csr_drv.read_global_fault(fault, fault_err);
    end else begin
      i2c_drv.read_global_status(status, status_err);
      i2c_drv.read_global_fault(fault, fault_err);
    end

    if (status[21] && status[6])
      seq_state_derived = 2'd1;
    else if (status[14])
      seq_state_derived = 2'd2;
    else
      seq_state_derived = 2'd0;

    ctrl_cov.sample(status[21], status[14], status[15], fault[0], status[6], seq_state_derived);
    fault_cov.sample(fault[1], fault[2], fault[0], status[13:11], reset_during_traffic, status_err | fault_err);
  endtask
`endif

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
`ifdef SPADMIC_ENABLE_FUNC_COV
          sample_stimulus_cov(STIM_KIND_TDC, (3'b001 << et.axis), 1'b0, et.start_stop_delay_ps);
`endif
          sb_mb.put(txn);
          ev_drv.inject_tdc_events(et);
          if (!cfg.enable_reset_test) begin
            // Keep a short guard in normal sequencing so an immediate follow-on
            // control write does not cut off data that has only just entered the
            // shared export path.
            #(et.num_conversions * 500_000);  // 500 ns per conversion
          end
        end

        TXN_POS_EVENT: begin
          spadmic_pos_event_txn pt;
          $cast(pt, txn);
`ifdef SPADMIC_ENABLE_FUNC_COV
          sample_stimulus_cov(
            STIM_KIND_POSITION, 3'b000,
            (pt.x_pattern != '0) || (pt.y_pattern != '0) || (pt.z_pattern != '0),
            pt.hold_time_ns * 1000
          );
`endif
          sb_mb.put(txn);
          pos_drv.drive_position_event(pt);
        end

        TXN_CORRELATED_EVENT: begin
          spadmic_correlated_event_txn ct;
          $cast(ct, txn);
`ifdef SPADMIC_ENABLE_FUNC_COV
          sample_stimulus_cov(STIM_KIND_CORRELATED, ct.axis_mask, ct.position_present,
                              ct.start_stop_delay_ps);
`endif
          sb_mb.put(txn);
          fork
            begin : tdc_family
              for (int ax = 0; ax < 3; ax++) begin
                if (ct.axis_mask[ax]) begin
                  automatic int axis_idx = ax;
                  fork
                    begin
                      spadmic_tdc_event_txn et = new();
                      et.axis                = axis_idx;
                      et.num_conversions     = 1;
                      et.start_stop_delay_ps = ct.start_stop_delay_ps;
                      et.inter_conv_gap_ps   = 0;
                      et.use_spad            = ct.use_spad;
                      et.cal_start_width_ps  = ct.cal_start_width_ps;
                      et.cal_stop_width_ps   = ct.cal_stop_width_ps;
                      #(axis_idx * ct.axis_skew_ps);
                      ev_drv.inject_tdc_events(et);
                    end
                  join_none
                end
              end
              wait fork;
            end
            begin : pos_family
              if (ct.position_present) begin
                spadmic_pos_event_txn pt = new();
                pt.x_pattern    = ct.x_pattern;
                pt.y_pattern    = ct.y_pattern;
                pt.z_pattern    = ct.z_pattern;
                pt.hold_time_ns = ct.hold_time_ns;
                #(ct.position_offset_ps);
                pos_drv.drive_position_event(pt);
              end
            end
          join
          #(ct.post_family_idle_ps);
        end

        TXN_BP: begin
          spadmic_bp_txn bt;
          $cast(bt, txn);
          bp_drv.set_mode(bt.mode);
        end

        TXN_RESET: begin
          spadmic_reset_txn rt;
          $cast(rt, txn);
`ifdef SPADMIC_ENABLE_FUNC_COV
          sample_stimulus_cov(STIM_KIND_RESET, 3'b000, 1'b0, rt.reset_duration_ns * 1000);
`endif
          ev_drv.clear_all();
          pos_drv.clear_all();
          bp_drv.stop();
          reset_if.pulse_reset_ns(rt.reset_duration_ns);
          bp_drv.set_mode(BP_ALWAYS_READY);
          apply_reset_defaults();
`ifdef SPADMIC_ENABLE_FUNC_COV
          sample_ctrl_fault_cov(rt.during_traffic);
`endif
          sb_mb.put(txn);
        end

        TXN_EOT: begin
          spadmic_eot_txn eot;
          $cast(eot, txn);
          // Wait for pipeline drain before signalling completion
          #(64'd1000 * eot.drain_timeout_ns);
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
    end else if (ct.raw_csr_write) begin
      if (ct.drv_mode == DRV_MODE_DIRECT_CSR)
        csr_drv.write_csr(ct.addr, ct.wdata);
      else
        i2c_drv.write_csr(ct.addr, ct.wdata);

`ifdef SPADMIC_ENABLE_FUNC_COV
      sample_ctrl_fault_cov(1'b0);
`endif
      state.note_ctrl_txn(ct);
    end else begin
      // Full chip config sequence
      if (ct.drv_mode == DRV_MODE_DIRECT_CSR) begin
        for (int ax = 0; ax < 3; ax++) begin
          csr_drv.program_tdc_max_hits(ax, ct.max_hits);
          csr_drv.program_tdc_conv_arm(ax, 1'b1);
        end
        csr_drv.program_global_ctrl(ct);
        // Wait for sequencer to commit the new active config
        csr_drv.wait_cfg_accept(500);
      end else begin
        for (int ax = 0; ax < 3; ax++) begin
          i2c_drv.program_tdc_max_hits(ax, ct.max_hits);
          i2c_drv.program_tdc_conv_arm(ax, 1'b1);
        end
        i2c_drv.program_global_ctrl(ct);
        i2c_drv.wait_cfg_accept(500);
      end

      active_global_enable   = ct.global_enable;
      active_tx_sel          = ct.shared_tx_sel;
      active_position_enable = ct.position_enable;
      active_input_sel       = ct.tdc_input_sel;
      active_out_mode        = ct.tdc_out_mode;
      active_max_hits        = ct.max_hits;
      state.note_ctrl_txn(ct);

`ifdef SPADMIC_ENABLE_FUNC_COV
      sample_ctrl_fault_cov(1'b0);
`endif
    end
  endtask

endclass
