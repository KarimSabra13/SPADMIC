`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_arb_stress;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;
  localparam int TDC_PACKET_WORDS = SPADMIC_MAX_TDC_PACKET_WORDS;
  localparam int EXPECTED_WORDS = (3 * SPADMIC_MAX_TDC_PACKET_WORDS) + SPADMIC_POS_RAW_PKT_WORDS;

  logic clk_sys;
  logic rst_n;
  logic [2:0] axis_enable;
  logic position_enable;
  logic [2:0] tdc_valid;
  logic [NARROW_W-1:0] tdc_data [SPADMIC_AXIS_COUNT];
  logic [2:0] tdc_sop;
  logic [2:0] tdc_eop;
  wire  [2:0] tdc_ready;
  logic [2:0] tdc_packet_active;
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
  int stress_tdc_idx [0:SPADMIC_AXIS_COUNT-1];
  bit stress_tdc_done [0:SPADMIC_AXIS_COUNT-1];
  int stress_pos_idx;
  bit stress_pos_done;
  bit stress_all_done;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_correlated_tx dut (
    .clk_sys            (clk_sys),
    .rst_n              (rst_n),
    .tx_sel_i           (SPADMIC_TX_TDC),
    .axis_enable_i      (axis_enable),
    .position_enable_i  (position_enable),
    .tdc_valid_i        (tdc_valid),
    .tdc_data_i         (tdc_data),
    .tdc_sop_i          (tdc_sop),
    .tdc_eop_i          (tdc_eop),
    .tdc_ready_o        (tdc_ready),
    .tdc_packet_active_i(tdc_packet_active),
    .pos_valid_i        (pos_valid),
    .pos_data_i         (pos_data),
    .pos_ready_o        (pos_ready),
    .shared_ready_i     (shared_ready),
    .shared_valid_o     (shared_valid),
    .shared_data_o      (shared_data),
    .tdc_busy_o         (tdc_busy),
    .arb_busy_o         (arb_busy),
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

  function automatic logic [NARROW_W-1:0] tdc_header_word(input int axis);
    tdc_conv_flags_t flags;
    flags = '0;
    return {2'b10,
            PACKET_CTX_W'(ctx_id_t'(axis[0])),
            logic'(axis[0]),
            MAX_HITS_W'(MAX_HITS),
            flags,
            logic'(axis[1]),
            2'b00};
  endfunction

  function automatic logic [NARROW_W-1:0] tdc_hit_w0(input int hit_idx, input int axis);
    logic [NSLOW_W-1:0] nslow;
    logic [NFAST_W-1:0] nfast;
    nslow = NSLOW_W'(20 + axis);
    nfast = NFAST_W'(30 + hit_idx + axis);
    return {1'b0, nslow[6:0], nfast[6:0], 1'b0};
  endfunction

  function automatic logic [NARROW_W-1:0] tdc_hit_w1(input int hit_idx, input int axis);
    return {1'b0, 4'(hit_idx & 7), 4'((hit_idx + axis) & 7), 4'b0,
            stop_phase_disc_t'(axis[2:0])};
  endfunction

  function automatic logic [NARROW_W-1:0] tdc_packet_word(input int axis, input int word_idx);
    int hit_idx;
    if (word_idx == 0)
      return tdc_header_word(axis);
    if (word_idx == (TDC_PACKET_WORDS - 1))
      return {2'b11, 14'h2aa};

    hit_idx = (word_idx - 1) / 2;
    if (((word_idx - 1) & 1) == 0)
      return tdc_hit_w0(hit_idx, axis);
    return tdc_hit_w1(hit_idx, axis);
  endfunction

  function automatic logic [NARROW_W-1:0] pos_packet_word(input int word_idx);
    if (word_idx == 0)
      return spadmic_pos_raw_header_word(3'b111);
    if (word_idx == (SPADMIC_POS_RAW_PKT_WORDS - 1))
      return spadmic_pos_eoc_word(4'hA);
    if (word_idx == 2)
      return 16'hC123;
    if (word_idx == 7)
      return 16'hFFFF;
    return 16'h4000 + 16'(word_idx);
  endfunction

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
    tdc_valid = '0;
    tdc_sop = '0;
    tdc_eop = '0;
    tdc_packet_active = '0;
    pos_valid = 1'b0;
    pos_data = '0;
    for (int i = 0; i < SPADMIC_AXIS_COUNT; i++)
      tdc_data[i] = '0;

    repeat (8) @(posedge clk_sys);
    #1;
    rst_n = 1'b1;
    repeat (4) @(posedge clk_sys);
    #1;

    for (int i = 0; i < SPADMIC_AXIS_COUNT; i++) begin
      stress_tdc_idx[i] = 0;
      stress_tdc_done[i] = 1'b0;
      tdc_valid[i] = 1'b1;
      tdc_packet_active[i] = 1'b1;
      tdc_data[i] = tdc_packet_word(i, 0);
      tdc_sop[i] = 1'b1;
      tdc_eop[i] = 1'b0;
    end
    stress_pos_idx = 0;
    stress_pos_done = 1'b0;
    pos_valid = 1'b1;
    pos_data = pos_packet_word(0);

    stress_all_done = 1'b0;
    while (!stress_all_done) begin
      @(posedge clk_sys);
      for (int i = 0; i < SPADMIC_AXIS_COUNT; i++) begin
        if (!stress_tdc_done[i] && tdc_valid[i] && tdc_ready[i]) begin
          if (stress_tdc_idx[i] == (TDC_PACKET_WORDS - 1)) begin
            stress_tdc_done[i] = 1'b1;
          end else begin
            stress_tdc_idx[i]++;
          end
        end
      end
      if (!stress_pos_done && pos_valid && pos_ready) begin
        if (stress_pos_idx == (SPADMIC_POS_RAW_PKT_WORDS - 1)) begin
          stress_pos_done = 1'b1;
        end else begin
          stress_pos_idx++;
        end
      end

      #1;
      stress_all_done = stress_pos_done;
      for (int i = 0; i < SPADMIC_AXIS_COUNT; i++) begin
        stress_all_done = stress_all_done & stress_tdc_done[i];
        if (stress_tdc_done[i]) begin
          tdc_valid[i] = 1'b0;
          tdc_packet_active[i] = 1'b0;
          tdc_data[i] = '0;
          tdc_sop[i] = 1'b0;
          tdc_eop[i] = 1'b0;
        end else begin
          tdc_valid[i] = 1'b1;
          tdc_packet_active[i] = 1'b1;
          tdc_data[i] = tdc_packet_word(i, stress_tdc_idx[i]);
          tdc_sop[i] = (stress_tdc_idx[i] == 0);
          tdc_eop[i] = (stress_tdc_idx[i] == (TDC_PACKET_WORDS - 1));
        end
      end

      if (stress_pos_done) begin
        pos_valid = 1'b0;
        pos_data = '0;
      end else begin
        pos_valid = 1'b1;
        pos_data = pos_packet_word(stress_pos_idx);
      end
    end

    while (packet_count < 4)
      @(posedge clk_sys);
    repeat (20) @(posedge clk_sys);
    #1;

    check("Stress emits exactly four max-burst packets", packet_count == 4);
    check("Stress drains expected max-burst words", word_count == EXPECTED_WORDS);
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
