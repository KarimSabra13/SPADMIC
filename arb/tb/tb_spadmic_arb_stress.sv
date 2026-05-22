`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_arb_stress;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;
  localparam int EXPECTED_WORDS = (3 * SPADMIC_MAX_TDC_PACKET_WORDS) + SPADMIC_POS_RAW_PKT_WORDS;

  logic clk_sys;
  logic rst_n;
  logic [2:0] axis_enable;
  logic position_enable;
  logic [2:0] acq_valid;
  logic [ACQ_REC_W-1:0] acq_data [3];
  wire  [2:0] acq_ready;
  logic pos_valid;
  logic [NARROW_W-1:0] pos_data;
  wire  pos_ready;
  logic shared_ready;
  wire  shared_valid;
  wire [NARROW_W-1:0] shared_data;
  wire  correlation_overflow;
  wire  tdc_busy;
  wire  arb_busy;

  int pass_count;
  int fail_count;
  int packet_count;
  int word_count;
  int tag_errors;
  int framing_errors;
  int packets_by_source [SPADMIC_SRC_COUNT];
  bit in_packet;
  bit raw_packet;
  int raw_word_idx;
  spadmic_source_id_e current_source;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_correlated_tx dut (
    .clk_sys        (clk_sys),
    .rst_n          (rst_n),
    .tx_sel_i       (SPADMIC_TX_TDC),
    .axis_enable_i  (axis_enable),
    .position_enable_i(position_enable),
    .tdc_out_mode_i (OUT_MODE_FULL),
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

  function automatic mptdc_acq_rec_t make_meta(input int axis);
    mptdc_acq_rec_t rec;
    rec = '0;
    rec.kind = ACQ_REC_META;
    rec.meta.hit_count = MAX_HITS_W'(MAX_HITS);
    rec.meta.nslow = NSLOW_W'(20 + axis);
    rec.meta.nfast = NFAST_W'(8 + axis);
    rec.meta.nfast_stop = NFAST_W'(4 + axis);
    rec.meta.ctx_id = ctx_id_t'(axis[0]);
    rec.meta.phase0_snap = axis[0];
    rec.meta.stop_slow_phase_disc = stop_phase_disc_t'(axis);
    rec.meta.slow_boundary_inc = axis[1];
    return rec;
  endfunction

  function automatic mptdc_acq_rec_t make_hit(input int hit_idx, input int axis);
    mptdc_acq_rec_t rec;
    rec = '0;
    rec.kind = ACQ_REC_HIT;
    rec.hit.ns = ph_idx_t'(hit_idx & 7);
    rec.hit.nf = ph_idx_t'((hit_idx + axis) & 7);
    rec.hit.nfast = NFAST_W'(30 + hit_idx + axis);
    rec.hit.event_seq = EVENT_SEQ_W'(hit_idx);
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

  task automatic drive_full_tdc(input int axis);
    drive_acq(axis, make_meta(axis));
    for (int i = 0; i < MAX_HITS; i++)
      drive_acq(axis, make_hit(i, axis));
  endtask

  task automatic drive_pos_raw();
    logic [NARROW_W-1:0] words [0:SPADMIC_POS_RAW_PKT_WORDS-1];
    words[0] = spadmic_pos_raw_header_word(3'b111);
    for (int i = 1; i < SPADMIC_POS_RAW_PKT_WORDS - 1; i++)
      words[i] = 16'h4000 + 16'(i);
    words[2] = 16'hC123;
    words[7] = 16'hFFFF;
    words[SPADMIC_POS_RAW_PKT_WORDS-1] = spadmic_pos_eoc_word(4'hA);

    for (int i = 0; i < SPADMIC_POS_RAW_PKT_WORDS; i++) begin
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

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      shared_ready <= 1'b0;
    end else begin
      shared_ready <= (($time / CLK_PERIOD) % 5) != 0;
    end
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      packet_count <= 0;
      word_count <= 0;
      tag_errors <= 0;
      framing_errors <= 0;
      in_packet <= 1'b0;
      raw_packet <= 1'b0;
      raw_word_idx <= 0;
      current_source <= TDC_ID_X;
      for (int i = 0; i < SPADMIC_SRC_COUNT; i++)
        packets_by_source[i] <= 0;
    end else if (shared_valid && shared_ready) begin
      word_count <= word_count + 1;
      if (!in_packet) begin
        raw_packet <= is_spadmic_pos_raw_header(shared_data);
        raw_word_idx <= 0;
        if (is_spadmic_pos_cluster_header(shared_data) || is_spadmic_pos_raw_header(shared_data)) begin
          current_source <= SPADMIC_SRC_POSITION;
          in_packet <= 1'b1;
        end else if (is_tdc_header(shared_data)) begin
          current_source <= tdc_header_source_id(shared_data);
          in_packet <= 1'b1;
        end else begin
          framing_errors <= framing_errors + 1;
        end
      end else begin
        raw_word_idx <= raw_word_idx + 1;
        if ((!raw_packet && is_tdc_eoc(shared_data)) ||
            (raw_packet && (raw_word_idx == (SPADMIC_POS_RAW_PKT_WORDS - 2)))) begin
          if (shared_data[SPADMIC_EVENT_ID_W-1:0] != SPADMIC_EVENT_ID_W'(packet_count))
            tag_errors <= tag_errors + 1;
          packets_by_source[current_source] <= packets_by_source[current_source] + 1;
          packet_count <= packet_count + 1;
          in_packet <= 1'b0;
          raw_packet <= 1'b0;
        end
      end
    end
  end

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    axis_enable = 3'b111;
    position_enable = 1'b1;
    acq_valid = '0;
    pos_valid = 1'b0;
    pos_data = '0;
    for (int i = 0; i < 3; i++)
      acq_data[i] = '0;

    repeat (8) @(posedge clk_sys);
    #1;
    rst_n = 1'b1;
    repeat (4) @(posedge clk_sys);

    fork
      drive_full_tdc(0);
      drive_full_tdc(1);
      drive_full_tdc(2);
      drive_pos_raw();
    join

    while (packet_count < 4)
      @(posedge clk_sys);
    repeat (20) @(posedge clk_sys);
    #1;

    check("Stress emits exactly four max-burst packets", packet_count == 4);
    check("Stress drains expected 155-word burst", word_count == EXPECTED_WORDS);
    check("Stress includes all four sources", packets_by_source[0] == 1 && packets_by_source[1] == 1 &&
                                           packets_by_source[2] == 1 && packets_by_source[3] == 1);
    check("Stress preserves unified tag sequence", tag_errors == 0);
    check("Stress has no packet framing errors", framing_errors == 0);
    check("Stress leaves no ARB busy state", arb_busy == 1'b0 && tdc_busy == 1'b0);
    check("Stress has no event-ID overflow", correlation_overflow == 1'b0);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_arb_stress: %0d failures", fail_count);
    $display("tb_spadmic_arb_stress: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #2_000_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
