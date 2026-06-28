`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_event_bundle_tx_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic bundle_start;
  logic [3:0] required_packet_mask;
  logic [3:0] source_pending_mask;
  logic [13:0] event_id;
  logic [SPADMIC_SRC_COUNT-1:0] src_valid;
  wire [SPADMIC_SRC_COUNT-1:0] src_ready;
  logic [NARROW_W-1:0] src_data [SPADMIC_SRC_COUNT];
  logic [SPADMIC_SRC_COUNT-1:0] src_sop;
  logic [SPADMIC_SRC_COUNT-1:0] src_eop;
  wire word_valid;
  logic word_ready;
  wire [NARROW_W-1:0] word_data;
  wire flush;
  wire [3:0] completed_packet_mask;
  wire done;
  wire busy;
  wire idle;
  wire missing_source_error;

  int pass_count;
  int fail_count;
  int out_count;
  int src_idx [SPADMIC_SRC_COUNT];
  logic flush_seen;
  logic [NARROW_W-1:0] out_words [0:7];

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_event_bundle_tx dut (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .bundle_start_i(bundle_start),
    .required_packet_mask_i(required_packet_mask),
    .source_pending_mask_i(source_pending_mask),
    .event_id_i(event_id),
    .src_valid_i(src_valid),
    .src_ready_o(src_ready),
    .src_data_i(src_data),
    .src_sop_i(src_sop),
    .src_eop_i(src_eop),
    .word_valid_o(word_valid),
    .word_ready_i(word_ready),
    .word_data_o(word_data),
    .flush_o(flush),
    .completed_packet_mask_o(completed_packet_mask),
    .done_o(done),
    .busy_o(busy),
    .idle_o(idle),
    .missing_source_error_o(missing_source_error)
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
      src_data[i] = (src_idx[i] == 0) ? tdc_header(i) : {2'b11, 14'h001};
    end
    src_data[SPADMIC_SRC_POSITION] =
        (src_idx[SPADMIC_SRC_POSITION] == 0)
          ? spadmic_pos_raw_header_word(3'b111)
          : {2'b11, 14'h002};
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      out_count <= 0;
      for (int i = 0; i < 8; i++)
        out_words[i] <= '0;
      for (int i = 0; i < SPADMIC_SRC_COUNT; i++)
        src_idx[i] <= 0;
      flush_seen <= 1'b0;
    end else begin
      for (int i = 0; i < SPADMIC_SRC_COUNT; i++) begin
        if (src_valid[i] && src_ready[i])
          src_idx[i] <= src_idx[i] + 1;
      end

      if (word_valid && word_ready) begin
        out_words[out_count] <= word_data;
        out_count <= out_count + 1;
      end

      if (flush)
        flush_seen <= 1'b1;
    end
  end

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    bundle_start = 1'b0;
    required_packet_mask = 4'b1111;
    source_pending_mask = 4'b1111;
    event_id = 14'h123;
    word_ready = 1'b1;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);
    #1;
    check("bundle transmitter starts idle", idle);

    @(negedge clk_sys);
    bundle_start = 1'b1;
    @(negedge clk_sys);
    bundle_start = 1'b0;
    wait (done);
    @(posedge clk_sys);
    #1;

    check("bundle emitted eight words", out_count == 8);
    check("R header keeps source R", tdc_header_source_id(out_words[0]) == TDC_ID_X);
    check("Y header patched to source Y", tdc_header_source_id(out_words[2]) == TDC_ID_Y);
    check("B header patched to source B", tdc_header_source_id(out_words[4]) == TDC_ID_Z);
    check("position header passes through", out_words[6] == spadmic_pos_raw_header_word(3'b111));
    check("R EOC uses common event ID", out_words[1] == {2'b11, event_id});
    check("Y EOC uses common event ID", out_words[3] == {2'b11, event_id});
    check("B EOC uses common event ID", out_words[5] == {2'b11, event_id});
    check("position EOC uses common event ID", out_words[7] == {2'b11, event_id});
    check("bundle completed all masks", completed_packet_mask == 4'b1111);
    check("bundle flushes DDR pairer after final word", flush_seen);
    check("bundle returns idle", idle);

    source_pending_mask = 4'b0111;
    required_packet_mask = 4'b1111;
    @(negedge clk_sys);
    bundle_start = 1'b1;
    @(posedge clk_sys);
    #1;
    check("missing source reports error", missing_source_error);
    bundle_start = 1'b0;

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_event_bundle_tx_unit: %0d failures", fail_count);

    $display("tb_spadmic_event_bundle_tx_unit: %0d pass / %0d fail",
             pass_count, fail_count);
    $finish;
  end

  initial begin
    #2_000_000;
    $fatal(1, "tb_spadmic_event_bundle_tx_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
