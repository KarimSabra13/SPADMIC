`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_output_characterization;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD_PS = 6250;
  localparam int CLK_HZ        = 160_000_000;

  logic clk_sys;
  logic rst_n;

  logic direct_valid;
  logic [NARROW_W-1:0] direct_word;
  wire direct_ready;
  wire chip_tx_clk;
  wire chip_tx_valid;
  wire [SPADMIC_TX_PHY_W-1:0] chip_tx_data;

  logic global_enable;
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
  logic pos_ready;
  wire pos_valid;
  wire [NARROW_W-1:0] pos_data;
  wire pos_busy;
  wire pos_pending;
  wire pos_drop_sticky;
  wire pos_glitch_sticky;
  wire spad_matrix_rst;

  int cycle_count;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD_PS/2) clk_sys = ~clk_sys;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n)
      cycle_count <= 0;
    else
      cycle_count <= cycle_count + 1;
  end

  spadmic_ddr_tx u_ddr_tx (
    .clk_sys        (clk_sys),
    .rst_n          (rst_n),
    .word_valid_i   (direct_valid),
    .word_data_i    (direct_word),
    .word_ready_o   (direct_ready),
    .chip_tx_clk_o  (chip_tx_clk),
    .chip_tx_valid_o(chip_tx_valid),
    .chip_tx_data_o (chip_tx_data)
  );

  spadmic_position_block u_position (
    .clk_sys                 (clk_sys),
    .rst_n                   (rst_n),
    .global_enable_i         (global_enable),
    .x_lines_i               (x_lines),
    .y_lines_i               (y_lines),
    .z_lines_i               (z_lines),
    .csr_valid_i             (pos_csr_valid),
    .csr_write_i             (pos_csr_write),
    .csr_addr_i              (pos_csr_addr),
    .csr_wdata_i             (pos_csr_wdata),
    .csr_ready_o             (pos_csr_ready),
    .csr_rvalid_o            (pos_csr_rvalid),
    .csr_rdata_o             (pos_csr_rdata),
    .pos_ready_i             (pos_ready),
    .pos_valid_o             (pos_valid),
    .pos_data_o              (pos_data),
    .busy_o                  (pos_busy),
    .packet_pending_o        (pos_pending),
    .drop_sticky_o           (pos_drop_sticky),
    .glitch_reject_sticky_o  (pos_glitch_sticky),
    .spad_matrix_rst_o       (spad_matrix_rst)
  );

  task automatic check(input string label, input logic cond);
    if (cond) begin
      pass_count++;
      $display("[PASS] %s", label);
    end else begin
      fail_count++;
      $display("[FAIL] %s", label);
    end
  endtask

  task automatic pos_csr_w(input logic [SPADMIC_CSR_ADDR_W-1:0] addr,
                           input logic [SPADMIC_CSR_DATA_W-1:0] data);
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

  function automatic real event_rate_meps(input int words_per_event);
    return real'(CLK_HZ) / real'(words_per_event) / 1.0e6;
  endfunction

  function automatic real packet_time_ns(input int words_per_event);
    return real'(words_per_event * CLK_PERIOD_PS) / 1000.0;
  endfunction

  task automatic emit_arch_metrics();
    int tdc_raw_15_words;
    int tdc_full_15_words;
    int tdc_full_1hit_words;
    int pos_cluster_words;
    int pos_raw_words;
    int nominal_bundle_words;
    int max_bundle_words;
    int raw_bundle_words;
    real tx_raw_gbps;
    real tx_raw_mbs;

    tdc_raw_15_words   = 1 + (2 * MAX_HITS) + 1;
    tdc_full_15_words  = 1 + (3 * MAX_HITS) + 1;
    tdc_full_1hit_words = 1 + 3 + 1;
    pos_cluster_words  = SPADMIC_POS_PKT_WORDS;
    pos_raw_words      = SPADMIC_POS_RAW_PKT_WORDS;
    nominal_bundle_words = (3 * tdc_full_1hit_words) + pos_cluster_words;
    max_bundle_words     = (3 * tdc_full_15_words) + pos_cluster_words;
    raw_bundle_words     = (3 * tdc_full_15_words) + pos_raw_words;
    tx_raw_gbps = (real'(CLK_HZ) * 16.0) / 1.0e9;
    tx_raw_mbs  = (real'(CLK_HZ) * 2.0) / 1.0e6;

    $display("[CHAR] tx.clk_sys_mhz=160.000");
    $display("[CHAR] tx.logical_word_rate_mword_s=160.000");
    $display("[CHAR] tx.raw_payload_gbps=%.3f", tx_raw_gbps);
    $display("[CHAR] tx.raw_payload_MB_s=%.1f", tx_raw_mbs);
    $display("[CHAR] tdc.packet_words.raw_features_15hit=%0d", tdc_raw_15_words);
    $display("[CHAR] tdc.packet_words.full_15hit=%0d", tdc_full_15_words);
    $display("[CHAR] tdc.packet_words.full_1hit=%0d", tdc_full_1hit_words);
    $display("[CHAR] position.packet_words.cluster=%0d", pos_cluster_words);
    $display("[CHAR] position.packet_words.raw=%0d", pos_raw_words);
    $display("[CHAR] bundle.words.3tdc_1hit_plus_cluster=%0d", nominal_bundle_words);
    $display("[CHAR] bundle.words.3tdc_15hit_plus_cluster=%0d", max_bundle_words);
    $display("[CHAR] bundle.words.3tdc_15hit_plus_raw=%0d", raw_bundle_words);
    $display("[CHAR] rate.max_mevent_s.tdc_full_1hit_single_axis=%.3f", event_rate_meps(tdc_full_1hit_words));
    $display("[CHAR] rate.max_mevent_s.tdc_full_15hit_single_axis=%.3f", event_rate_meps(tdc_full_15_words));
    $display("[CHAR] rate.max_mevent_s.position_cluster=%.3f", event_rate_meps(pos_cluster_words));
    $display("[CHAR] rate.max_mevent_s.position_raw=%.3f", event_rate_meps(pos_raw_words));
    $display("[CHAR] rate.max_mevent_s.3tdc_1hit_plus_cluster=%.3f", event_rate_meps(nominal_bundle_words));
    $display("[CHAR] rate.max_mevent_s.3tdc_15hit_plus_cluster=%.3f", event_rate_meps(max_bundle_words));
    $display("[CHAR] rate.max_mevent_s.3tdc_15hit_plus_raw=%.3f", event_rate_meps(raw_bundle_words));
    $display("[CHAR] deadtime_ns.egress_3tdc_1hit_plus_cluster=%.2f", packet_time_ns(nominal_bundle_words));
    $display("[CHAR] deadtime_ns.egress_3tdc_15hit_plus_cluster=%.2f", packet_time_ns(max_bundle_words));
    $display("[CHAR] deadtime_ns.egress_3tdc_15hit_plus_raw=%.2f", packet_time_ns(raw_bundle_words));
    $display("[CHAR] datarate.avg_mbps_at_1Mevent_s.3tdc_1hit_plus_cluster=%.1f", real'(nominal_bundle_words * 16));
    $display("[CHAR] datarate.avg_mbps_at_1Mevent_s.3tdc_15hit_plus_cluster=%.1f", real'(max_bundle_words * 16));
    $display("[CHAR] datarate.avg_mbps_at_100kevent_s.3tdc_15hit_plus_cluster=%.1f", real'(max_bundle_words * 16) / 10.0);
  endtask

  task automatic measure_direct_tx_burst(input int n_words);
    int start_cycle;
    int accepted_words;
    int valid_cycles;

    accepted_words = 0;
    valid_cycles = 0;
    @(posedge clk_sys);
    #1;
    start_cycle = cycle_count;
    direct_valid = 1'b1;
    direct_word = 16'h5000;
    while (accepted_words < n_words) begin
      @(posedge clk_sys);
      #1;
      if (direct_ready) begin
        accepted_words++;
        direct_word = direct_word + 16'h0001;
      end
      if (chip_tx_valid)
        valid_cycles++;
    end
    direct_valid = 1'b0;
    direct_word = '0;
    repeat (3) @(posedge clk_sys);

    $display("[CHAR] tx.direct_burst_words=%0d", n_words);
    $display("[CHAR] tx.direct_burst_accept_cycles=%0d", cycle_count - start_cycle);
    $display("[CHAR] tx.direct_burst_valid_cycles=%0d", valid_cycles);
    check("DDR TX ready is always asserted", direct_ready == 1'b1);
    check("DDR TX emits one valid cycle per word", valid_cycles == n_words);
  endtask

  task automatic measure_position_packet(input bit raw_mode,
                                         input bit compact_mode,
                                         output int first_valid_latency_cycles,
                                         output int packet_words);
    int start_cycle;

    x_lines = '0;
    y_lines = '0;
    z_lines = '0;
    pos_ready = 1'b0;

    pos_csr_w(SPADMIC_CSR_POS_FILTER_CFG, 32'h0000_0101); // min span 1, settle 1
    pos_csr_w(
      SPADMIC_CSR_POS_CTRL,
      raw_mode ? 32'h0000_0003 : (compact_mode ? 32'h0000_0041 : 32'h0000_0001)
    );

    repeat (4) @(posedge clk_sys);
    #1;
    start_cycle = cycle_count;
    x_lines[5]  = 1'b1;
    x_lines[6]  = 1'b1;
    y_lines[31] = 1'b1;
    z_lines[SPADMIC_LINE_W-1] = 1'b1;

    while (!pos_valid)
      @(posedge clk_sys);
    #1;
    first_valid_latency_cycles = cycle_count - start_cycle;

    packet_words = 0;
    pos_ready = 1'b1;
    while (pos_valid) begin
      packet_words++;
      @(posedge clk_sys);
      #1;
    end

    x_lines = '0;
    y_lines = '0;
    z_lines = '0;
    while (pos_busy)
      @(posedge clk_sys);
    repeat (2) @(posedge clk_sys);
  endtask

  task automatic measure_position_metrics();
    int cluster_latency;
    int cluster_words;
    int compact_latency;
    int compact_words;
    int raw_latency;
    int raw_words;

    measure_position_packet(1'b0, 1'b0, cluster_latency, cluster_words);
    measure_position_packet(1'b0, 1'b1, compact_latency, compact_words);
    measure_position_packet(1'b1, 1'b0, raw_latency, raw_words);

    $display("[CHAR] position.cluster_first_valid_latency_cycles=%0d", cluster_latency);
    $display("[CHAR] position.cluster_first_valid_latency_ns=%.2f",
             real'(cluster_latency * CLK_PERIOD_PS) / 1000.0);
    $display("[CHAR] position.cluster_packet_words_measured=%0d", cluster_words);
    $display("[CHAR] position.compact_cluster_first_valid_latency_cycles=%0d", compact_latency);
    $display("[CHAR] position.compact_cluster_first_valid_latency_ns=%.2f",
             real'(compact_latency * CLK_PERIOD_PS) / 1000.0);
    $display("[CHAR] position.compact_cluster_packet_words_measured=%0d", compact_words);
    $display("[CHAR] position.raw_first_valid_latency_cycles=%0d", raw_latency);
    $display("[CHAR] position.raw_first_valid_latency_ns=%.2f",
             real'(raw_latency * CLK_PERIOD_PS) / 1000.0);
    $display("[CHAR] position.raw_packet_words_measured=%0d", raw_words);
    check("Position cluster packet is 8 words", cluster_words == SPADMIC_POS_PKT_WORDS);
    check("Position compact cluster packet is 5 words for XYZ single-cluster event", compact_words == 5);
    check("Position raw packet is 14 words", raw_words == SPADMIC_POS_RAW_PKT_WORDS);
  endtask

  task automatic measure_reset_pulse();
    int pulse_cycles;

    pulse_cycles = 0;
    @(posedge clk_sys);
    #1;
    pos_csr_valid = 1'b1;
    pos_csr_write = 1'b1;
    pos_csr_addr  = SPADMIC_CSR_POS_CTRL;
    pos_csr_wdata = 32'h0000_0013; // local enable + raw + manual pulse
    @(posedge clk_sys);
    #1;
    if (spad_matrix_rst)
      pulse_cycles++;
    pos_csr_valid = 1'b0;
    pos_csr_write = 1'b0;
    pos_csr_addr  = '0;
    pos_csr_wdata = '0;
    repeat (4) begin
      @(posedge clk_sys);
      #1;
      if (spad_matrix_rst)
        pulse_cycles++;
    end
    $display("[CHAR] position.spad_reset_pulse_cycles=%0d", pulse_cycles);
    $display("[CHAR] position.spad_reset_pulse_ns=%.2f", real'(pulse_cycles * CLK_PERIOD_PS) / 1000.0);
    check("SPAD matrix reset pulse is one clk_sys cycle", pulse_cycles == 1);
  endtask

  initial begin
    rst_n = 1'b0;
    direct_valid = 1'b0;
    direct_word = '0;
    global_enable = 1'b1;
    x_lines = '0;
    y_lines = '0;
    z_lines = '0;
    pos_csr_valid = 1'b0;
    pos_csr_write = 1'b0;
    pos_csr_addr = '0;
    pos_csr_wdata = '0;
    pos_ready = 1'b1;
    pass_count = 0;
    fail_count = 0;

    repeat (6) @(posedge clk_sys);
    #1;
    rst_n = 1'b1;
    repeat (4) @(posedge clk_sys);

    $display("[CHAR] ===== SPADMIC OUTPUT CHARACTERIZATION =====");
    emit_arch_metrics();
    measure_direct_tx_burst(256);
    measure_position_metrics();
    measure_reset_pulse();

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_output_characterization: %0d failures", fail_count);

    $display("[CHAR] result.pass_count=%0d", pass_count);
    $display("[CHAR] result.fail_count=%0d", fail_count);
    $display("tb_spadmic_output_characterization: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #50_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
