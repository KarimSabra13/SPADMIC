`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_arb_modes;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  spadmic_tx_sel_e tx_sel;
  logic [2:0] axis_enable;
  logic position_enable;
  out_mode_e tdc_out_mode;

  logic [2:0] acq_valid;
  logic [ACQ_REC_W-1:0] acq_data [3];
  wire  [2:0] acq_ready;

  logic pos_valid;
  logic [NARROW_W-1:0] pos_data;
  wire  pos_ready;

  logic shared_ready;
  wire  shared_valid;
  wire [NARROW_W-1:0] shared_data;
  wire  tdc_busy;
  wire  arb_busy;
  wire  correlation_overflow;

  int pass_count;
  int fail_count;
  int packet_count;
  int word_count;
  int framing_errors;
  int tag_errors;
  int packets_by_source [SPADMIC_SRC_COUNT];
  bit in_packet;
  spadmic_source_id_e current_source;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_correlated_tx dut (
    .clk_sys        (clk_sys),
    .rst_n          (rst_n),
    .tx_sel_i       (tx_sel),
    .axis_enable_i  (axis_enable),
    .position_enable_i(position_enable),
    .tdc_out_mode_i (tdc_out_mode),
    .acq_valid_i    (acq_valid),
    .acq_data_i     (acq_data),
    .acq_ready_o    (acq_ready),
    .pos_valid_i    (pos_valid),
    .pos_data_i     (pos_data),
    .pos_ready_o    (pos_ready),
    .shared_ready_i (shared_ready),
    .shared_valid_o (shared_valid),
    .shared_data_o  (shared_data),
    .tdc_busy_o     (tdc_busy),
    .arb_busy_o     (arb_busy),
    .correlation_overflow_o(correlation_overflow)
  );

  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_count++;
    end else begin
      $display("[FAIL] %s", label);
      fail_count++;
    end
  endtask

  function automatic mptdc_acq_rec_t make_meta(input int hits, input int seed);
    mptdc_acq_rec_t rec;
    rec = '0;
    rec.kind = ACQ_REC_META;
    rec.meta.hit_count = MAX_HITS_W'(hits);
    rec.meta.nslow = NSLOW_W'(10 + seed);
    rec.meta.nfast = NFAST_W'(5 + seed);
    rec.meta.nfast_stop = NFAST_W'(3 + seed);
    rec.meta.ctx_id = ctx_id_t'(seed[0]);
    rec.meta.phase0_snap = seed[0];
    rec.meta.stop_slow_phase_disc = stop_phase_disc_t'(seed[2:0]);
    rec.meta.slow_boundary_inc = seed[1];
    return rec;
  endfunction

  function automatic mptdc_acq_rec_t make_hit(input int idx, input int seed);
    mptdc_acq_rec_t rec;
    rec = '0;
    rec.kind = ACQ_REC_HIT;
    rec.hit.ns = ph_idx_t'(idx & 7);
    rec.hit.nf = ph_idx_t'((idx + seed) & 7);
    rec.hit.nfast = NFAST_W'(20 + idx + seed);
    rec.hit.event_seq = EVENT_SEQ_W'(idx);
    return rec;
  endfunction

  task automatic drive_acq(input int axis, input mptdc_acq_rec_t rec);
    @(posedge clk_sys);
    #1;
    acq_data[axis] = rec;
    acq_valid[axis] = 1'b1;
    do begin
      @(negedge clk_sys);
      #1;
    end while (!acq_ready[axis]);
    @(posedge clk_sys);
    #1;
    acq_valid[axis] = 1'b0;
    acq_data[axis] = '0;
  endtask

  task automatic drive_tdc_packet(input int axis, input int hits, input int seed);
    drive_acq(axis, make_meta(hits, seed));
    for (int i = 0; i < hits; i++)
      drive_acq(axis, make_hit(i, seed));
  endtask

  task automatic drive_pos_cluster(input int seed);
    logic [NARROW_W-1:0] words [0:SPADMIC_POS_PKT_WORDS-1];
    words[0] = spadmic_pos_header_word(1'b0, 3'b001, 3'b000);
    for (int i = 1; i < SPADMIC_POS_PKT_WORDS - 1; i++)
      words[i] = 16'(seed + i);
    words[SPADMIC_POS_PKT_WORDS-1] = spadmic_pos_eoc_word(4'(seed));

    for (int i = 0; i < SPADMIC_POS_PKT_WORDS; i++) begin
      @(posedge clk_sys);
      #1;
      pos_data = words[i];
      pos_valid = 1'b1;
      do begin
        @(negedge clk_sys);
        #1;
      end while (!pos_ready);
      @(posedge clk_sys);
      #1;
    end
    pos_valid = 1'b0;
    pos_data = '0;
  endtask

  task automatic clear_drivers();
    acq_valid = '0;
    pos_valid = 1'b0;
    pos_data = '0;
    for (int i = 0; i < 3; i++)
      acq_data[i] = '0;
  endtask

  task automatic apply_reset();
    rst_n = 1'b0;
    clear_drivers();
    repeat (5) @(posedge clk_sys);
    #1;
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);
  endtask

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      packet_count <= 0;
      word_count <= 0;
      framing_errors <= 0;
      tag_errors <= 0;
      in_packet <= 1'b0;
      current_source <= TDC_ID_X;
      for (int i = 0; i < SPADMIC_SRC_COUNT; i++)
        packets_by_source[i] <= 0;
    end else if (shared_valid && shared_ready) begin
      word_count <= word_count + 1;
      if (!in_packet) begin
        if (is_tdc_header(shared_data)) begin
          current_source <= tdc_header_source_id(shared_data);
          in_packet <= 1'b1;
        end else if (is_spadmic_pos_cluster_header(shared_data)) begin
          current_source <= SPADMIC_SRC_POSITION;
          in_packet <= 1'b1;
        end else begin
          framing_errors <= framing_errors + 1;
        end
      end else if (is_tdc_eoc(shared_data)) begin
        if (shared_data[SPADMIC_EVENT_ID_W-1:0] != SPADMIC_EVENT_ID_W'(packet_count))
          tag_errors <= tag_errors + 1;
        packets_by_source[current_source] <= packets_by_source[current_source] + 1;
        packet_count <= packet_count + 1;
        in_packet <= 1'b0;
      end
    end
  end

  task automatic wait_packets(input int expected);
    while (packet_count < expected)
      @(posedge clk_sys);
    repeat (5) @(posedge clk_sys);
    #1;
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;
    tx_sel = SPADMIC_TX_TDC;
    axis_enable = 3'b111;
    position_enable = 1'b1;
    tdc_out_mode = OUT_MODE_RAW_FEATURES;
    shared_ready = 1'b1;
    clear_drivers();

    tx_sel = SPADMIC_TX_TDC;
    axis_enable = 3'b111;
    position_enable = 1'b1;
    tdc_out_mode = OUT_MODE_RAW_FEATURES;
    apply_reset();
    fork
      drive_tdc_packet(0, 1, 1);
      drive_tdc_packet(1, 1, 2);
      drive_tdc_packet(2, 1, 3);
      drive_pos_cluster(4);
    join
    wait_packets(4);
    check("Both-active emits four packets", packet_count == 4);
    check("Both-active includes X/Y/Z/POS", packets_by_source[0] == 1 && packets_by_source[1] == 1 &&
                                      packets_by_source[2] == 1 && packets_by_source[3] == 1);
    check("Both-active tags are unified and monotonic", tag_errors == 0);
    check("Both-active has no framing errors", framing_errors == 0);

    tx_sel = SPADMIC_TX_TDC;
    axis_enable = 3'b001;
    position_enable = 1'b0;
    tdc_out_mode = OUT_MODE_RAW_FEATURES;
    apply_reset();
    acq_valid[1] = 1'b1;
    acq_data[1] = make_meta(1, 9);
    fork
      drive_tdc_packet(0, 0, 5);
    join
    repeat (10) @(posedge clk_sys);
    wait_packets(1);
    check("TDC-X-only emits one X packet", packets_by_source[TDC_ID_X] == 1 && packet_count == 1);
    check("Disabled Y source is not drained", acq_ready[1] == 1'b0 && acq_valid[1] == 1'b1);
    clear_drivers();

    tx_sel = SPADMIC_TX_POSITION;
    axis_enable = 3'b111;
    position_enable = 1'b1;
    tdc_out_mode = OUT_MODE_RAW_FEATURES;
    apply_reset();
    acq_valid[0] = 1'b1;
    acq_data[0] = make_meta(1, 11);
    drive_pos_cluster(6);
    wait_packets(1);
    check("Position-only emits one position packet", packets_by_source[SPADMIC_SRC_POSITION] == 1 &&
                                            packet_count == 1);
    check("Position-only blocks TDC drain", acq_ready[0] == 1'b0 && acq_valid[0] == 1'b1);
    clear_drivers();

    tx_sel = SPADMIC_TX_TDC;
    axis_enable = 3'b110;
    position_enable = 1'b0;
    tdc_out_mode = OUT_MODE_RAW_FEATURES;
    apply_reset();
    fork
      drive_tdc_packet(1, 1, 12);
      drive_tdc_packet(2, 1, 13);
    join
    wait_packets(2);
    check("Y+Z mode emits only Y and Z", packets_by_source[TDC_ID_Y] == 1 &&
                                      packets_by_source[TDC_ID_Z] == 1 &&
                                      packets_by_source[TDC_ID_X] == 0 &&
                                      packet_count == 2);

    tx_sel = SPADMIC_TX_TDC;
    axis_enable = 3'b111;
    position_enable = 1'b0;
    tdc_out_mode = OUT_MODE_RAW_TIMESTAMP;
    apply_reset();
    acq_valid[0] = 1'b1;
    acq_data[0] = make_meta(1, 21);
    repeat (20) @(posedge clk_sys);
    #1;
    check("RAW_TIMESTAMP mode is masked from active ARB", acq_ready[0] == 1'b0 && packet_count == 0);
    clear_drivers();

    check("No event-tag overflow in mode test", correlation_overflow == 1'b0);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_arb_modes: %0d failures", fail_count);
    $display("tb_spadmic_arb_modes: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #500_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
