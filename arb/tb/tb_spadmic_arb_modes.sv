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
  wire  tdc_busy;
  wire  arb_busy;
  wire  correlation_overflow;

  int pass_count;
  int fail_count;
  int packet_count;
  int word_count;
  int framing_errors;
  int tag_errors;
  int hit_patch_errors;
  int packets_by_source [SPADMIC_SRC_COUNT];
  bit in_packet;
  int packet_word_idx;
  spadmic_source_id_e current_source;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_correlated_tx dut (
    .clk_sys            (clk_sys),
    .rst_n              (rst_n),
    .tx_sel_i           (tx_sel),
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

  function automatic logic [NARROW_W-1:0] tdc_header_word(input int hits, input int seed);
    tdc_conv_flags_t flags;
    flags = '0;
    return {2'b10,
            PACKET_CTX_W'(ctx_id_t'(seed[0])),
            logic'(seed[0]),
            MAX_HITS_W'(hits),
            flags,
            logic'(seed[1]),
            2'b00};
  endfunction

  function automatic logic [NARROW_W-1:0] tdc_hit_w0(input int idx, input int seed);
    logic [NSLOW_W-1:0] nslow;
    logic [NFAST_W-1:0] nfast;
    nslow = NSLOW_W'(10 + seed);
    nfast = NFAST_W'(20 + idx + seed);
    return {1'b0, nslow[6:0], nfast[6:0], 1'b0};
  endfunction

  function automatic logic [NARROW_W-1:0] tdc_hit_w1(input int idx, input int seed);
    return {1'b0, 4'(idx & 7), 4'((idx + seed) & 7), 4'b0, stop_phase_disc_t'(seed[2:0])};
  endfunction

  task automatic drive_tdc_word(
    input int axis,
    input logic [NARROW_W-1:0] data,
    input logic sop,
    input logic eop
  );
    @(posedge clk_sys);
    #1;
    tdc_data[axis] = data;
    tdc_sop[axis] = sop;
    tdc_eop[axis] = eop;
    tdc_valid[axis] = 1'b1;
    do begin
      @(negedge clk_sys);
      #1;
    end while (!tdc_ready[axis]);
    @(posedge clk_sys);
    #1;
    tdc_valid[axis] = 1'b0;
    tdc_sop[axis] = 1'b0;
    tdc_eop[axis] = 1'b0;
    tdc_data[axis] = '0;
  endtask

  task automatic drive_tdc_packet(input int axis, input int hits, input int seed);
    tdc_packet_active[axis] = 1'b1;
    drive_tdc_word(axis, tdc_header_word(hits, seed), 1'b1, 1'b0);
    for (int i = 0; i < hits; i++) begin
      drive_tdc_word(axis, tdc_hit_w0(i, seed), 1'b0, 1'b0);
      drive_tdc_word(axis, tdc_hit_w1(i, seed), 1'b0, 1'b0);
    end
    drive_tdc_word(axis, {2'b11, 14'h155}, 1'b0, 1'b1);
    tdc_packet_active[axis] = 1'b0;
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
    tdc_valid = '0;
    tdc_sop = '0;
    tdc_eop = '0;
    tdc_packet_active = '0;
    pos_valid = 1'b0;
    pos_data = '0;
    for (int i = 0; i < SPADMIC_AXIS_COUNT; i++)
      tdc_data[i] = '0;
  endtask

  task automatic apply_reset();
    rst_n = 1'b0;
    clear_drivers();
    repeat (5) @(posedge clk_sys);
    #1;
    rst_n = 1'b1;
    repeat (3) @(posedge clk_sys);
  endtask

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      packet_count <= 0;
      word_count <= 0;
      framing_errors <= 0;
      tag_errors <= 0;
      hit_patch_errors <= 0;
      in_packet <= 1'b0;
      packet_word_idx <= 0;
      current_source <= TDC_ID_X;
      for (int i = 0; i < SPADMIC_SRC_COUNT; i++)
        packets_by_source[i] <= 0;
    end else if (shared_valid && shared_ready) begin
      word_count <= word_count + 1;
      if (!in_packet) begin
        packet_word_idx <= 0;
        if (is_tdc_header(shared_data)) begin
          current_source <= tdc_header_source_id(shared_data);
          in_packet <= 1'b1;
        end else if (is_spadmic_pos_cluster_header(shared_data)) begin
          current_source <= SPADMIC_SRC_POSITION;
          in_packet <= 1'b1;
        end else begin
          framing_errors <= framing_errors + 1;
        end
      end else begin
        packet_word_idx <= packet_word_idx + 1;
        if ((current_source != SPADMIC_SRC_POSITION) && !is_tdc_eoc(shared_data) &&
            (packet_word_idx == 2) && (shared_data[1:0] == current_source)) begin
          hit_patch_errors <= hit_patch_errors + 1;
        end
        if (is_tdc_eoc(shared_data)) begin
          if (shared_data[SPADMIC_EVENT_ID_W-1:0] != SPADMIC_EVENT_ID_W'(packet_count))
            tag_errors <= tag_errors + 1;
          packets_by_source[current_source] <= packets_by_source[current_source] + 1;
          packet_count <= packet_count + 1;
          in_packet <= 1'b0;
        end
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
    shared_ready = 1'b1;
    clear_drivers();

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
    check("TDC source patch does not rewrite HIT payload", hit_patch_errors == 0);

    tx_sel = SPADMIC_TX_TDC;
    axis_enable = 3'b001;
    position_enable = 1'b0;
    apply_reset();
    tdc_valid[1] = 1'b1;
    tdc_sop[1] = 1'b1;
    tdc_data[1] = tdc_header_word(1, 9);
    fork
      drive_tdc_packet(0, 0, 5);
    join
    repeat (10) @(posedge clk_sys);
    wait_packets(1);
    check("TDC-X-only emits one X packet", packets_by_source[TDC_ID_X] == 1 && packet_count == 1);
    check("Disabled Y source is not accepted", tdc_ready[1] == 1'b0 && tdc_valid[1] == 1'b1);
    clear_drivers();

    tx_sel = SPADMIC_TX_POSITION;
    axis_enable = 3'b111;
    position_enable = 1'b1;
    apply_reset();
    tdc_valid[0] = 1'b1;
    tdc_sop[0] = 1'b1;
    tdc_data[0] = tdc_header_word(1, 11);
    drive_pos_cluster(6);
    wait_packets(1);
    check("Position-only emits one position packet", packets_by_source[SPADMIC_SRC_POSITION] == 1 &&
                                            packet_count == 1);
    check("Position-only blocks inactive TDC source", tdc_ready[0] == 1'b0 && tdc_valid[0] == 1'b1);
    clear_drivers();

    tx_sel = SPADMIC_TX_TDC;
    axis_enable = 3'b110;
    position_enable = 1'b0;
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
