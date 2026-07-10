`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_tx_egress_cluster_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic clk_160m;
  logic rst_n;
  logic ddrs2_enable;
  logic bundle_start;
  logic [SPADMIC_SRC_MASK_W-1:0] required_packet_mask;
  logic [SPADMIC_SRC_MASK_W-1:0] source_pending_mask;
  logic [SPADMIC_EVENT_ID_W-1:0] event_id;
  logic [SPADMIC_SRC_COUNT-1:0] src_valid;
  wire [SPADMIC_SRC_COUNT-1:0] src_ready;
  logic [NARROW_W-1:0] src_data [SPADMIC_SRC_COUNT];
  logic [SPADMIC_SRC_COUNT-1:0] src_sop;
  logic [SPADMIC_SRC_COUNT-1:0] src_eop;
  wire [SPADMIC_SRC_MASK_W-1:0] completed_packet_mask;
  wire bundle_done;
  wire bundle_idle;
  wire bundle_missing_source_error;
  wire [SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level;
  wire output_fifo_empty;
  wire [SPADMIC_DDR16_PHY_W-1:0] ddr_data_l;
  wire [SPADMIC_DDR16_PHY_W-1:0] ddr_data_h;
  wire ddr_pair_valid;
  wire ddr_padded;
  wire ddr_empty;
  wire [SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l;
  wire [SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h;
  wire ddrs2_clk_160m;

  int pass_count;
  int fail_count;
  int src_idx [SPADMIC_SRC_COUNT];
  int pair_count;
  logic [SPADMIC_DDR16_PHY_W-1:0] pair_l [0:3];
  logic [SPADMIC_DDR16_PHY_W-1:0] pair_h [0:3];
  logic [SPADMIC_DDRS2_LANE_W-1:0] lanes_l [0:3];
  logic [SPADMIC_DDRS2_LANE_W-1:0] lanes_h [0:3];

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  initial clk_160m = 1'b0;
  always #(CLK_PERIOD/2) clk_160m = ~clk_160m;

  spadmic_tx_egress_cluster dut (
    .clk_sys                       (clk_sys),
    .clk_160m_i                    (clk_160m),
    .rst_n                         (rst_n),
    .ddrs2_enable_i                (ddrs2_enable),
    .bundle_start_i                (bundle_start),
    .required_packet_mask_i        (required_packet_mask),
    .source_pending_mask_i         (source_pending_mask),
    .event_id_i                    (event_id),
    .src_valid_i                   (src_valid),
    .src_ready_o                   (src_ready),
    // SPADMIC_TX_SRC_DATA_GENERATED_BEGIN ARRAY_CONNECTIONS src_data
    .src_data_i_s0_b0      (src_data[0][0]),
    .src_data_i_s0_b1      (src_data[0][1]),
    .src_data_i_s0_b2      (src_data[0][2]),
    .src_data_i_s0_b3      (src_data[0][3]),
    .src_data_i_s0_b4      (src_data[0][4]),
    .src_data_i_s0_b5      (src_data[0][5]),
    .src_data_i_s0_b6      (src_data[0][6]),
    .src_data_i_s0_b7      (src_data[0][7]),
    .src_data_i_s0_b8      (src_data[0][8]),
    .src_data_i_s0_b9      (src_data[0][9]),
    .src_data_i_s0_b10     (src_data[0][10]),
    .src_data_i_s0_b11     (src_data[0][11]),
    .src_data_i_s0_b12     (src_data[0][12]),
    .src_data_i_s0_b13     (src_data[0][13]),
    .src_data_i_s0_b14     (src_data[0][14]),
    .src_data_i_s0_b15     (src_data[0][15]),
    .src_data_i_s1_b0      (src_data[1][0]),
    .src_data_i_s1_b1      (src_data[1][1]),
    .src_data_i_s1_b2      (src_data[1][2]),
    .src_data_i_s1_b3      (src_data[1][3]),
    .src_data_i_s1_b4      (src_data[1][4]),
    .src_data_i_s1_b5      (src_data[1][5]),
    .src_data_i_s1_b6      (src_data[1][6]),
    .src_data_i_s1_b7      (src_data[1][7]),
    .src_data_i_s1_b8      (src_data[1][8]),
    .src_data_i_s1_b9      (src_data[1][9]),
    .src_data_i_s1_b10     (src_data[1][10]),
    .src_data_i_s1_b11     (src_data[1][11]),
    .src_data_i_s1_b12     (src_data[1][12]),
    .src_data_i_s1_b13     (src_data[1][13]),
    .src_data_i_s1_b14     (src_data[1][14]),
    .src_data_i_s1_b15     (src_data[1][15]),
    .src_data_i_s2_b0      (src_data[2][0]),
    .src_data_i_s2_b1      (src_data[2][1]),
    .src_data_i_s2_b2      (src_data[2][2]),
    .src_data_i_s2_b3      (src_data[2][3]),
    .src_data_i_s2_b4      (src_data[2][4]),
    .src_data_i_s2_b5      (src_data[2][5]),
    .src_data_i_s2_b6      (src_data[2][6]),
    .src_data_i_s2_b7      (src_data[2][7]),
    .src_data_i_s2_b8      (src_data[2][8]),
    .src_data_i_s2_b9      (src_data[2][9]),
    .src_data_i_s2_b10     (src_data[2][10]),
    .src_data_i_s2_b11     (src_data[2][11]),
    .src_data_i_s2_b12     (src_data[2][12]),
    .src_data_i_s2_b13     (src_data[2][13]),
    .src_data_i_s2_b14     (src_data[2][14]),
    .src_data_i_s2_b15     (src_data[2][15]),
    .src_data_i_s3_b0      (src_data[3][0]),
    .src_data_i_s3_b1      (src_data[3][1]),
    .src_data_i_s3_b2      (src_data[3][2]),
    .src_data_i_s3_b3      (src_data[3][3]),
    .src_data_i_s3_b4      (src_data[3][4]),
    .src_data_i_s3_b5      (src_data[3][5]),
    .src_data_i_s3_b6      (src_data[3][6]),
    .src_data_i_s3_b7      (src_data[3][7]),
    .src_data_i_s3_b8      (src_data[3][8]),
    .src_data_i_s3_b9      (src_data[3][9]),
    .src_data_i_s3_b10     (src_data[3][10]),
    .src_data_i_s3_b11     (src_data[3][11]),
    .src_data_i_s3_b12     (src_data[3][12]),
    .src_data_i_s3_b13     (src_data[3][13]),
    .src_data_i_s3_b14     (src_data[3][14]),
    .src_data_i_s3_b15     (src_data[3][15]),
    // SPADMIC_TX_SRC_DATA_GENERATED_END ARRAY_CONNECTIONS
    .src_sop_i                     (src_sop),
    .src_eop_i                     (src_eop),
    .completed_packet_mask_o       (completed_packet_mask),
    .bundle_done_o                 (bundle_done),
    .bundle_busy_o                 (),
    .bundle_idle_o                 (bundle_idle),
    .bundle_missing_source_error_o (bundle_missing_source_error),
    .output_fifo_level_o           (output_fifo_level),
    .output_fifo_free_words_o      (),
    .output_fifo_empty_o           (output_fifo_empty),
    .output_fifo_full_o            (),
    .output_fifo_almost_full_o     (),
    .output_fifo_overflow_o        (),
    .ddr_data_l_o                  (ddr_data_l),
    .ddr_data_h_o                  (ddr_data_h),
    .ddr_pair_valid_o              (ddr_pair_valid),
    .ddr_padded_o                  (ddr_padded),
    .ddr_clk_o                     (),
    .ddr_busy_o                    (),
    .ddr_empty_o                   (ddr_empty),
    .ddrs2_data_l_o                (ddrs2_data_l),
    .ddrs2_data_h_o                (ddrs2_data_h),
    .ddrs2_clk_160m_o              (ddrs2_clk_160m)
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

  function automatic logic [NARROW_W-1:0] tdc_header(input int seed);
    tdc_conv_flags_t flags;
    flags = '0;
    return {2'b10, PACKET_CTX_W'(ctx_id_t'(seed[0])), 1'b0,
            MAX_HITS_W'(0), flags, 1'b0, 2'b00};
  endfunction

  always_comb begin
    for (int i = 0; i < SPADMIC_SRC_COUNT; i++) begin
      src_valid[i] = (src_idx[i] < 2);
      src_sop[i] = (src_idx[i] == 0);
      src_eop[i] = (src_idx[i] == 1);
      src_data[i] = (src_idx[i] == 0) ? tdc_header(i) : {2'b11, event_id};
    end
    src_data[SPADMIC_SRC_POSITION] =
        (src_idx[SPADMIC_SRC_POSITION] == 0)
          ? spadmic_pos_raw_header_word(3'b111)
          : {2'b11, event_id};
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < SPADMIC_SRC_COUNT; i++)
        src_idx[i] <= 0;
      pair_count <= 0;
      for (int i = 0; i < 4; i++) begin
        pair_l[i] <= '0;
        pair_h[i] <= '0;
        lanes_l[i] <= '0;
        lanes_h[i] <= '0;
      end
    end else begin
      for (int i = 0; i < SPADMIC_SRC_COUNT; i++) begin
        if (src_valid[i] && src_ready[i])
          src_idx[i] <= src_idx[i] + 1;
      end

      if (ddr_pair_valid && pair_count < 4) begin
        pair_l[pair_count] <= ddr_data_l;
        pair_h[pair_count] <= ddr_data_h;
        lanes_l[pair_count] <= ddrs2_data_l;
        lanes_h[pair_count] <= ddrs2_data_h;
        pair_count <= pair_count + 1;
      end
    end
  end

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    ddrs2_enable = 1'b1;
    bundle_start = 1'b0;
    required_packet_mask = 4'b1111;
    source_pending_mask = 4'b1111;
    event_id = 14'h123;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);
    #1;
    check("cluster starts idle", bundle_idle && output_fifo_empty && ddr_empty);
    check("DDRs2 forwarded clock follows input", ddrs2_clk_160m == clk_160m);

    @(negedge clk_sys);
    bundle_start = 1'b1;
    @(negedge clk_sys);
    bundle_start = 1'b0;

    wait (bundle_done);
    wait (pair_count == 4);
    repeat (4) @(posedge clk_sys);
    #1;

    check("cluster completed all source packets", completed_packet_mask == 4'b1111);
    check("cluster emitted four DDR pairs", pair_count == 4);
    check("first pair low word is R header", tdc_header_source_id(pair_l[0]) == TDC_ID_X);
    check("first pair high word is common EOC", pair_h[0] == {2'b11, event_id});
    check("position pair low word is position header", pair_l[3] == spadmic_pos_raw_header_word(3'b111));
    check("DDRs2 low data lanes mirror DDR low word", lanes_l[0][15:0] == pair_l[0]);
    check("DDRs2 high data lanes mirror DDR high word", lanes_h[0][15:0] == pair_h[0]);
    check("DDRs2 valid lane marks low phase", lanes_l[0][SPADMIC_DDRS2_VALID_LANE]);
    check("DDRs2 valid lane marks high phase", lanes_h[0][SPADMIC_DDRS2_VALID_LANE]);
    check("cluster does not pad even bundle", !ddr_padded);

    source_pending_mask = 4'b0111;
    required_packet_mask = 4'b1111;
    @(negedge clk_sys);
    bundle_start = 1'b1;
    @(posedge clk_sys);
    #1;
    check("missing source propagates error", bundle_missing_source_error);
    bundle_start = 1'b0;

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_tx_egress_cluster_unit: %0d failures", fail_count);

    $display("tb_spadmic_tx_egress_cluster_unit: %0d pass / %0d fail",
             pass_count, fail_count);
    $finish;
  end

  initial begin
    #2_000_000;
    $fatal(1, "tb_spadmic_tx_egress_cluster_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
