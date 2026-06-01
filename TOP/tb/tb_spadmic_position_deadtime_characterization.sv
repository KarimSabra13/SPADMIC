`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_position_deadtime_characterization;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD_PS = 6250;
  localparam int ACTIVE_CYCLES = 6;
  localparam int HELD_ACTIVE_CYCLES = 20;
  localparam int MIN_GAP_CYCLES = 1;
  localparam int MAX_GAP_CYCLES = 48;
  localparam int BURST_EVENTS = 12;

  logic clk_sys;
  logic rst_n;

  logic [SPADMIC_LINE_W-1:0] x_lines;
  logic [SPADMIC_LINE_W-1:0] y_lines;
  logic [SPADMIC_LINE_W-1:0] z_lines;

  logic pos_csr_valid;
  logic pos_csr_write;
  logic [SPADMIC_CSR_ADDR_W-1:0] pos_csr_addr;
  logic [SPADMIC_CSR_DATA_W-1:0] pos_csr_wdata;
  wire pos_csr_ready;
  wire pos_csr_rvalid;
  wire [SPADMIC_CSR_DATA_W-1:0] pos_csr_rdata;

  wire pos_valid;
  wire [NARROW_W-1:0] pos_data;
  wire pos_ready;
  wire position_busy;
  wire position_pending;
  wire position_drop_sticky;
  wire position_glitch_sticky;
  wire spad_matrix_rst;

  logic [SPADMIC_AXIS_COUNT-1:0] acq_valid;
  logic [ACQ_REC_W-1:0] acq_data [SPADMIC_AXIS_COUNT];
  wire [SPADMIC_AXIS_COUNT-1:0] acq_ready;

  wire shared_valid;
  wire [NARROW_W-1:0] shared_data;
  wire shared_ready;
  wire tdc_busy;
  wire arb_busy;
  wire corr_overflow;

  wire chip_tx_clk;
  wire chip_tx_valid;
  wire [SPADMIC_TX_PHY_W-1:0] chip_tx_data;

  int cycle_q;
  int pass_count;
  int fail_count;
  bit trial_active;
  int trial_frame_writes;
  int trial_packets;
  int trial_words;
  int trial_first_frame_cycle;
  int trial_first_word_cycle;
  int trial_pos_fifo_peak;
  int trial_out_fifo_peak;
  int trial_busy_cycles;
  int trial_reset_pulses;
  int trial_bad_reset_pulses;
  bit trial_reset_after_capture;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD_PS/2) clk_sys = ~clk_sys;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      cycle_q <= 0;
    end else begin
      cycle_q <= cycle_q + 1;
    end
  end

  spadmic_position_block u_position (
    .clk_sys                (clk_sys),
    .rst_n                  (rst_n),
    .global_enable_i        (1'b1),
    .x_lines_i              (x_lines),
    .y_lines_i              (y_lines),
    .z_lines_i              (z_lines),
    .csr_valid_i            (pos_csr_valid),
    .csr_write_i            (pos_csr_write),
    .csr_addr_i             (pos_csr_addr),
    .csr_wdata_i            (pos_csr_wdata),
    .csr_ready_o            (pos_csr_ready),
    .csr_rvalid_o           (pos_csr_rvalid),
    .csr_rdata_o            (pos_csr_rdata),
    .pos_ready_i            (pos_ready),
    .pos_valid_o            (pos_valid),
    .pos_data_o             (pos_data),
    .busy_o                 (position_busy),
    .packet_pending_o       (position_pending),
    .drop_sticky_o          (position_drop_sticky),
    .glitch_reject_sticky_o (position_glitch_sticky),
    .spad_matrix_rst_o      (spad_matrix_rst)
  );

  spadmic_correlated_tx u_correlated_tx (
    .clk_sys                (clk_sys),
    .rst_n                  (rst_n),
    .tx_sel_i               (SPADMIC_TX_POSITION),
    .axis_enable_i          ('0),
    .position_enable_i      (1'b1),
    .tdc_out_mode_i         (OUT_MODE_RAW_FEATURES),
    .acq_valid_i            (acq_valid),
    .acq_data_i             (acq_data),
    .acq_ready_o            (acq_ready),
    .pos_valid_i            (pos_valid),
    .pos_data_i             (pos_data),
    .pos_ready_o            (pos_ready),
    .shared_ready_i         (shared_ready),
    .shared_valid_o         (shared_valid),
    .shared_data_o          (shared_data),
    .tdc_busy_o             (tdc_busy),
    .arb_busy_o             (arb_busy),
    .correlation_overflow_o (corr_overflow)
  );

  spadmic_ddr_tx u_ddr_tx (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .word_valid_i    (shared_valid),
    .word_data_i     (shared_data),
    .word_ready_o    (shared_ready),
    .chip_tx_clk_o   (chip_tx_clk),
    .chip_tx_valid_o (chip_tx_valid),
    .chip_tx_data_o  (chip_tx_data)
  );

  task automatic check(input string label, input bit cond);
    if (cond) begin
      pass_count++;
      $display("[PASS] %s", label);
    end else begin
      fail_count++;
      $display("[FAIL] %s", label);
    end
  endtask

  task automatic reset_trial_state();
    trial_frame_writes = 0;
    trial_packets = 0;
    trial_words = 0;
    trial_first_frame_cycle = -1;
    trial_first_word_cycle = -1;
    trial_pos_fifo_peak = 0;
    trial_out_fifo_peak = 0;
    trial_busy_cycles = 0;
    trial_reset_pulses = 0;
    trial_bad_reset_pulses = 0;
    trial_reset_after_capture = 1'b0;
  endtask

  task automatic write_pos_csr(
    input logic [SPADMIC_CSR_ADDR_W-1:0] addr,
    input logic [SPADMIC_CSR_DATA_W-1:0] data
  );
    @(posedge clk_sys);
    #1;
    pos_csr_valid = 1'b1;
    pos_csr_write = 1'b1;
    pos_csr_addr  = addr;
    pos_csr_wdata = data;
    @(posedge clk_sys);
    #1;
    pos_csr_valid = 1'b0;
    pos_csr_write = 1'b0;
    pos_csr_addr  = '0;
    pos_csr_wdata = '0;
  endtask

  task automatic reset_dut(input bit reset_after_capture);
    trial_active = 1'b0;
    rst_n = 1'b0;
    x_lines = '0;
    y_lines = '0;
    z_lines = '0;
    pos_csr_valid = 1'b0;
    pos_csr_write = 1'b0;
    pos_csr_addr = '0;
    pos_csr_wdata = '0;
    acq_valid = '0;
    for (int axis = 0; axis < SPADMIC_AXIS_COUNT; axis++) begin
      acq_data[axis] = '0;
    end
    repeat (5) @(posedge clk_sys);
    #1;
    rst_n = 1'b1;
    repeat (5) @(posedge clk_sys);
    #1;
    write_pos_csr(SPADMIC_CSR_POS_FILTER_CFG, 32'h0000_0101); // min span 1, settle 1
    write_pos_csr(SPADMIC_CSR_POS_GAP_CFG, 32'd2);
    write_pos_csr(SPADMIC_CSR_POS_CTRL,
                  reset_after_capture ? 32'h0000_0021 : 32'h0000_0001);
    repeat (2) @(posedge clk_sys);
    #1;
  endtask

  task automatic drive_event_lines(input bit event0_active, input bit event1_active);
    x_lines = '0;
    y_lines = '0;
    z_lines = '0;

    if (event0_active) begin
      x_lines[5] = 1'b1;
      x_lines[6] = 1'b1;
      y_lines[21] = 1'b1;
      y_lines[22] = 1'b1;
      z_lines[41] = 1'b1;
      z_lines[42] = 1'b1;
    end

    if (event1_active) begin
      x_lines[25] = 1'b1;
      x_lines[26] = 1'b1;
      y_lines[45] = 1'b1;
      y_lines[46] = 1'b1;
      z_lines[61] = 1'b1;
      z_lines[62] = 1'b1;
    end
  endtask

  function automatic bit event_active_at(
    input int rel_cycle,
    input int start_cycle,
    input int active_cycles
  );
    return (rel_cycle >= start_cycle) && (rel_cycle < (start_cycle + active_cycles));
  endfunction

  task automatic wait_drained(input int max_cycles);
    int waited;
    waited = 0;
    while ((position_busy || position_pending || arb_busy || shared_valid
        || (u_position.u_frame_fifo.level_o != '0)
        || (u_correlated_tx.u_out_fifo.level_o != '0)) && (waited < max_cycles)) begin
      @(posedge clk_sys);
      #1;
      waited++;
    end

    check("drain completed before watchdog", waited < max_cycles);
  endtask

  task automatic run_pair_trial(
    input string label,
    input int gap_cycles,
    input int active_cycles,
    input bit reset_after_capture,
    output bit safe
  );
    int total_drive_cycles;
    int start_cycle;
    int frame_latency;
    int first_word_latency;
    int zero_idle_cycles;
    bit event0_cleared;
    bit event1_cleared;
    bit event0_active;
    bit event1_active;

    reset_dut(reset_after_capture);
    reset_trial_state();
    trial_active = 1'b1;
    trial_reset_after_capture = reset_after_capture;
    event0_cleared = 1'b0;
    event1_cleared = 1'b0;

    total_drive_cycles = gap_cycles + active_cycles + 2;
    start_cycle = cycle_q;
    for (int rel = 0; rel < total_drive_cycles; rel++) begin
      event0_active = event_active_at(rel, 0, active_cycles) && !event0_cleared;
      event1_active = event_active_at(rel, gap_cycles, active_cycles) && !event1_cleared;
      drive_event_lines(event0_active, event1_active);
      @(posedge clk_sys);
      #1;
      if (reset_after_capture && spad_matrix_rst) begin
        if (event0_active)
          event0_cleared = 1'b1;
        if (event1_active)
          event1_cleared = 1'b1;
      end
    end

    drive_event_lines(1'b0, 1'b0);
    wait_drained(240);
    trial_active = 1'b0;

    safe = (trial_frame_writes == 2)
        && (trial_packets == 2)
        && !position_drop_sticky
        && !position_glitch_sticky
        && !corr_overflow
        && (trial_bad_reset_pulses == 0);

    frame_latency = (trial_first_frame_cycle >= 0) ? (trial_first_frame_cycle - start_cycle) : -1;
    first_word_latency = (trial_first_word_cycle >= 0) ? (trial_first_word_cycle - start_cycle) : -1;
    zero_idle_cycles = (gap_cycles > active_cycles) ? (gap_cycles - active_cycles) : 0;

    $display("[CHAR] pair.label=%s reset_after_capture=%0d gap_cycles=%0d active_cycles=%0d zero_idle_cycles=%0d safe=%0d frames=%0d packets=%0d words=%0d first_frame_latency_cycles=%0d first_word_latency_cycles=%0d pos_fifo_peak=%0d out_fifo_peak=%0d busy_cycles=%0d reset_pulses=%0d bad_reset_pulses=%0d drop=%0b glitch=%0b corr_overflow=%0b",
             label, reset_after_capture, gap_cycles, active_cycles, zero_idle_cycles, safe, trial_frame_writes,
             trial_packets, trial_words, frame_latency, first_word_latency,
             trial_pos_fifo_peak, trial_out_fifo_peak, trial_busy_cycles,
             trial_reset_pulses, trial_bad_reset_pulses,
             position_drop_sticky, position_glitch_sticky, corr_overflow);
  endtask

  task automatic run_sweep(
    input string label,
    input bit reset_after_capture,
    input int active_cycles,
    output int min_safe_gap
  );
    bit trial_safe;

    min_safe_gap = -1;
    $display("[CHAR] sweep.label=%s reset_after_capture=%0d active_cycles=%0d",
             label, reset_after_capture, active_cycles);
    for (int gap = MIN_GAP_CYCLES; gap <= MAX_GAP_CYCLES; gap++) begin
      run_pair_trial(label, gap, active_cycles, reset_after_capture, trial_safe);
      if ((min_safe_gap < 0) && trial_safe)
        min_safe_gap = gap;
    end

    check($sformatf("found lossless two-event gap for %s", label), min_safe_gap >= 0);
    if (min_safe_gap >= 0) begin
      int min_zero_idle;

      min_zero_idle = (min_safe_gap > active_cycles) ? (min_safe_gap - active_cycles) : 0;
      $display("[CHAR] result.%s.min_safe_gap_cycles=%0d", label, min_safe_gap);
      $display("[CHAR] result.%s.min_safe_gap_ns=%.3f", label, real'(min_safe_gap * CLK_PERIOD_PS) / 1000.0);
      $display("[CHAR] result.%s.min_zero_idle_cycles=%0d", label, min_zero_idle);
      $display("[CHAR] result.%s.min_zero_idle_ns=%.3f", label, real'(min_zero_idle * CLK_PERIOD_PS) / 1000.0);
    end
  endtask

  task automatic run_burst_trial(
    input string label,
    input int gap_cycles,
    input int active_cycles,
    input bit reset_after_capture,
    input int events
  );
    int total_drive_cycles;
    bit any_event0;
    bit any_event1;
    int expected_words;
    bit event_cleared [BURST_EVENTS];

    reset_dut(reset_after_capture);
    reset_trial_state();
    trial_active = 1'b1;
    trial_reset_after_capture = reset_after_capture;
    for (int event_idx = 0; event_idx < BURST_EVENTS; event_idx++)
      event_cleared[event_idx] = 1'b0;

    total_drive_cycles = ((events - 1) * gap_cycles) + active_cycles + 2;
    for (int rel = 0; rel < total_drive_cycles; rel++) begin
      any_event0 = 1'b0;
      any_event1 = 1'b0;
      for (int event_idx = 0; event_idx < events; event_idx++) begin
        if (event_active_at(rel, event_idx * gap_cycles, active_cycles) && !event_cleared[event_idx]) begin
          if (event_idx[0])
            any_event1 = 1'b1;
          else
            any_event0 = 1'b1;
        end
      end
      drive_event_lines(any_event0, any_event1);
      @(posedge clk_sys);
      #1;
      if (reset_after_capture && spad_matrix_rst) begin
        for (int event_idx = 0; event_idx < events; event_idx++) begin
          if (event_active_at(rel, event_idx * gap_cycles, active_cycles))
            event_cleared[event_idx] = 1'b1;
        end
      end
    end

    drive_event_lines(1'b0, 1'b0);
    wait_drained(600);
    trial_active = 1'b0;

    expected_words = events * SPADMIC_POS_PKT_WORDS;
    $display("[CHAR] burst.label=%s reset_after_capture=%0d events=%0d gap_cycles=%0d active_cycles=%0d frames=%0d packets=%0d words=%0d expected_words=%0d pos_fifo_peak=%0d out_fifo_peak=%0d busy_cycles=%0d reset_pulses=%0d bad_reset_pulses=%0d drop=%0b glitch=%0b corr_overflow=%0b",
             label, reset_after_capture, events, gap_cycles, active_cycles, trial_frame_writes,
             trial_packets, trial_words, expected_words, trial_pos_fifo_peak,
             trial_out_fifo_peak, trial_busy_cycles, trial_reset_pulses,
             trial_bad_reset_pulses, position_drop_sticky,
             position_glitch_sticky, corr_overflow);

    check("burst accepted every position event", trial_frame_writes == events);
    check("burst emitted every position packet", trial_packets == events);
    check("burst emitted expected position words", trial_words == expected_words);
    check("burst has no position drop", !position_drop_sticky);
    check("burst has no position glitch reject", !position_glitch_sticky);
    check("burst has no correlated tag overflow", !corr_overflow);
    check("burst has no early reset-after-capture pulse", trial_bad_reset_pulses == 0);
  endtask

  always_ff @(posedge clk_sys) begin
    if (rst_n && trial_active) begin
      int pos_level;
      int out_level;

      pos_level = int'(u_position.u_frame_fifo.level_o);
      out_level = int'(u_correlated_tx.u_out_fifo.level_o);

      if (pos_level > trial_pos_fifo_peak)
        trial_pos_fifo_peak <= pos_level;
      if (out_level > trial_out_fifo_peak)
        trial_out_fifo_peak <= out_level;
      if (position_busy || position_pending)
        trial_busy_cycles <= trial_busy_cycles + 1;
      if (spad_matrix_rst) begin
        trial_reset_pulses <= trial_reset_pulses + 1;
        if (trial_reset_after_capture && (u_position.det_state_q != 2'd2))
          trial_bad_reset_pulses <= trial_bad_reset_pulses + 1;
      end

      if (u_position.frame_fifo_wr_en) begin
        trial_frame_writes <= trial_frame_writes + 1;
        if (trial_first_frame_cycle < 0)
          trial_first_frame_cycle <= cycle_q;
      end

      if (shared_valid && shared_ready) begin
        trial_words <= trial_words + 1;
        if (trial_first_word_cycle < 0)
          trial_first_word_cycle <= cycle_q;
        if (shared_data[15:14] == 2'b11)
          trial_packets <= trial_packets + 1;
      end
    end
  end

  initial begin
    int min_baseline_gap;
    int min_held_no_reset_gap;
    int min_held_reset_gap;

    pass_count = 0;
    fail_count = 0;
    trial_active = 1'b0;
    min_baseline_gap = -1;
    min_held_no_reset_gap = -1;
    min_held_reset_gap = -1;

    $display("[CHAR] ===== SPADMIC POSITION DEADTIME CHARACTERIZATION =====");
    $display("[CHAR] scenario=position_only_cluster_tdc_disabled");
    $display("[CHAR] clk_sys_period_ps=%0d", CLK_PERIOD_PS);
    $display("[CHAR] active_cycles=%0d", ACTIVE_CYCLES);
    $display("[CHAR] held_active_cycles=%0d", HELD_ACTIVE_CYCLES);
    $display("[CHAR] cluster_packet_words=%0d", SPADMIC_POS_PKT_WORDS);
    $display("[CHAR] pos_queue_depth_frames=%0d", SPADMIC_POS_QUEUE_DEPTH);
    $display("[CHAR] output_fifo_depth_words=%0d", SPADMIC_OUTPUT_FIFO_DEPTH);

    run_sweep("baseline_min_hold", 1'b0, ACTIVE_CYCLES, min_baseline_gap);
    if (min_baseline_gap >= 0)
      run_burst_trial("baseline_min_hold", min_baseline_gap, ACTIVE_CYCLES, 1'b0, BURST_EVENTS);

    run_sweep("held_no_reset", 1'b0, HELD_ACTIVE_CYCLES, min_held_no_reset_gap);
    run_sweep("held_reset_after_capture", 1'b1, HELD_ACTIVE_CYCLES, min_held_reset_gap);
    if ((min_held_no_reset_gap >= 0) && (min_held_reset_gap >= 0)) begin
      $display("[CHAR] result.reset_after_capture_improvement_cycles=%0d",
               min_held_no_reset_gap - min_held_reset_gap);
      $display("[CHAR] result.reset_after_capture_improvement_ns=%.3f",
               real'((min_held_no_reset_gap - min_held_reset_gap) * CLK_PERIOD_PS) / 1000.0);
      check("reset-after-capture improves held-matrix gap", min_held_reset_gap < min_held_no_reset_gap);
      run_burst_trial("held_reset_after_capture", min_held_reset_gap, HELD_ACTIVE_CYCLES,
                      1'b1, BURST_EVENTS);
    end

    $display("[CHAR] result.pass_count=%0d", pass_count);
    $display("[CHAR] result.fail_count=%0d", fail_count);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_position_deadtime_characterization: %0d failures", fail_count);

    $display("PASS tb_spadmic_position_deadtime_characterization");
    $finish;
  end

  initial begin
    #500_000_000;
    $fatal(1, "TIMEOUT");
  end
endmodule

`default_nettype wire
