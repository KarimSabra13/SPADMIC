`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_tdc_shared_readout_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;
  localparam int TOTAL_WORDS = 18;

  logic clk_sys;
  logic rst_n;

  logic [2:0] acq_valid;
  logic [ACQ_REC_W-1:0] acq_data [3];
  wire [2:0] acq_ready;
  out_mode_e out_mode;
  logic shared_ready;
  wire shared_valid;
  wire [NARROW_W-1:0] shared_data;
  wire busy;
  wire [1:0] packet_src;

  mptdc_acq_rec_t axis0_recs [0:1];
  mptdc_acq_rec_t axis1_recs [0:2];
  mptdc_acq_rec_t axis2_recs [0:0];

  int idx0, idx1, idx2;
  int accepted_words;
  int pass_count;
  int fail_count;
  int stall_count;
  int src_change_during_busy_count;
  int wrong_ready_owner_count;
  logic [NARROW_W-1:0] words [0:TOTAL_WORDS-1];
  logic busy_q;
  logic [1:0] busy_src_q;
  logic stalled_pkt0_subhdr;
  logic stalled_pkt1_midhit;
  logic stalled_pkt2_eoc;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_tdc_shared_readout dut (
    .clk_sys       (clk_sys),
    .rst_n         (rst_n),
    .acq_valid_i   (acq_valid),
    .acq_data_i    (acq_data),
    .acq_ready_o   (acq_ready),
    .out_mode_i    (out_mode),
    .shared_ready_i(shared_ready),
    .shared_valid_o(shared_valid),
    .shared_data_o (shared_data),
    .busy_o        (busy),
    .packet_src_o  (packet_src)
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

  function automatic logic [2:0] axis_ready_mask(input logic [1:0] src);
    unique case (spadmic_tdc_id_e'(src))
      TDC_ID_X: axis_ready_mask = 3'b001;
      TDC_ID_Y: axis_ready_mask = 3'b010;
      default:  axis_ready_mask = 3'b100;
    endcase
  endfunction

  task automatic stall_and_check(
    input string               label,
    input logic [NARROW_W-1:0] expected_word
  );
    int stall_cycle;
    shared_ready = 1'b0;
    for (stall_cycle = 0; stall_cycle < 2; stall_cycle++) begin
      @(negedge clk_sys);
      #1;
      check($sformatf("%s keeps valid asserted", label), shared_valid === 1'b1);
      check($sformatf("%s keeps data stable", label), shared_data === expected_word);
      check($sformatf("%s keeps busy asserted", label), busy === 1'b1);
    end
    stall_count  = stall_count + 1;
    shared_ready = 1'b1;
  endtask

  always_comb begin
    acq_valid   = '0;
    acq_data[0] = '0;
    acq_data[1] = '0;
    acq_data[2] = '0;

    if (idx0 <= 1) begin
      acq_valid[0] = 1'b1;
      acq_data[0]  = axis0_recs[idx0];
    end

    if (idx1 <= 2) begin
      acq_valid[1] = 1'b1;
      acq_data[1]  = axis1_recs[idx1];
    end

    if (idx2 == 0) begin
      acq_valid[2] = 1'b1;
      acq_data[2]  = axis2_recs[idx2];
    end
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      idx0 <= 0;
      idx1 <= 0;
      idx2 <= 0;
    end else begin
      if (acq_valid[0] && acq_ready[0])
        idx0 <= idx0 + 1;
      if (acq_valid[1] && acq_ready[1])
        idx1 <= idx1 + 1;
      if (acq_valid[2] && acq_ready[2])
        idx2 <= idx2 + 1;
    end
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      busy_q                       <= 1'b0;
      busy_src_q                   <= TDC_ID_X;
      src_change_during_busy_count <= 0;
      wrong_ready_owner_count      <= 0;
    end else begin
      if (!busy_q && busy)
        busy_src_q <= packet_src;
      else if (busy_q && busy && (packet_src != busy_src_q))
        src_change_during_busy_count <= src_change_during_busy_count + 1;

      if (busy && (acq_ready != '0) && (acq_ready != axis_ready_mask(packet_src)))
        wrong_ready_owner_count <= wrong_ready_owner_count + 1;

      busy_q <= busy;
    end
  end

  initial begin
    axis0_recs[0] = '0;
    axis0_recs[0].kind = ACQ_REC_META;
    axis0_recs[0].meta.hit_count = MAX_HITS_W'(1);
    axis0_recs[0].meta.nslow = NSLOW_W'(7'd11);
    axis0_recs[0].meta.nfast = NFAST_W'(7'd5);
    axis0_recs[0].meta.nfast_stop = NFAST_W'(7'd1);
    axis0_recs[0].meta.ctx_id = ctx_id_t'(0);

    axis0_recs[1] = '0;
    axis0_recs[1].kind = ACQ_REC_HIT;
    axis0_recs[1].hit.ns = ph_idx_t'(1);
    axis0_recs[1].hit.nf = ph_idx_t'(2);
    axis0_recs[1].hit.nfast = NFAST_W'(7'd9);
    axis0_recs[1].hit.event_seq = EVENT_SEQ_W'(0);

    axis1_recs[0] = '0;
    axis1_recs[0].kind = ACQ_REC_META;
    axis1_recs[0].meta.hit_count = MAX_HITS_W'(2);
    axis1_recs[0].meta.nslow = NSLOW_W'(7'd21);
    axis1_recs[0].meta.nfast = NFAST_W'(7'd8);
    axis1_recs[0].meta.nfast_stop = NFAST_W'(7'd2);
    axis1_recs[0].meta.ctx_id = ctx_id_t'(1);

    axis1_recs[1] = '0;
    axis1_recs[1].kind = ACQ_REC_HIT;
    axis1_recs[1].hit.ns = ph_idx_t'(3);
    axis1_recs[1].hit.nf = ph_idx_t'(4);
    axis1_recs[1].hit.nfast = NFAST_W'(7'd12);
    axis1_recs[1].hit.event_seq = EVENT_SEQ_W'(0);

    axis1_recs[2] = '0;
    axis1_recs[2].kind = ACQ_REC_HIT;
    axis1_recs[2].hit.ns = ph_idx_t'(5);
    axis1_recs[2].hit.nf = ph_idx_t'(6);
    axis1_recs[2].hit.nfast = NFAST_W'(7'd14);
    axis1_recs[2].hit.event_seq = EVENT_SEQ_W'(1);

    axis2_recs[0] = '0;
    axis2_recs[0].kind = ACQ_REC_META;
    axis2_recs[0].meta.hit_count = '0;
    axis2_recs[0].meta.nslow = NSLOW_W'(7'd31);
    axis2_recs[0].meta.nfast = NFAST_W'(7'd4);
    axis2_recs[0].meta.nfast_stop = NFAST_W'(7'd3);
    axis2_recs[0].meta.ctx_id = ctx_id_t'(0);
  end

  initial begin
    rst_n = 1'b0;
    out_mode = OUT_MODE_RAW_FEATURES;
    shared_ready = 1'b1;
    accepted_words = 0;
    pass_count = 0;
    fail_count = 0;
    stall_count = 0;
    stalled_pkt0_subhdr = 1'b0;
    stalled_pkt1_midhit = 1'b0;
    stalled_pkt2_eoc = 1'b0;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    shared_ready = 1'b1;

    while (accepted_words < TOTAL_WORDS) begin
      @(negedge clk_sys);
      #1;

      if (!stalled_pkt0_subhdr && (accepted_words == 1) && shared_valid) begin
        stalled_pkt0_subhdr = 1'b1;
        stall_and_check("Packet 0 subheader backpressure", shared_data);
      end else if (!stalled_pkt1_midhit && (accepted_words == 9) && shared_valid) begin
        stalled_pkt1_midhit = 1'b1;
        stall_and_check("Packet 1 mid-hit backpressure", shared_data);
      end else if (!stalled_pkt2_eoc && (accepted_words == 17) && shared_valid) begin
        stalled_pkt2_eoc = 1'b1;
        stall_and_check("Packet 2 EOC backpressure", shared_data);
      end

      if (shared_valid && shared_ready) begin
        words[accepted_words] = shared_data;
        accepted_words++;
      end
    end

    repeat (2) @(posedge clk_sys);
    #1;

    check("Shared readout drains all axis0 records", idx0 == 2);
    check("Shared readout drains all axis1 records", idx1 == 3);
    check("Shared readout drains all axis2 records", idx2 == 1);
    check("Readout returns idle after final EOC", busy === 1'b0);
    check("Packet 0 subheader tagged as X", words[1][5:4] == TDC_ID_X);
    check("Packet 1 subheader tagged as Y", words[7][5:4] == TDC_ID_Y);
    check("Packet 2 subheader tagged as Z", words[16][5:4] == TDC_ID_Z);
    check("Packet 0 ends with EOC", is_tdc_eoc(words[5]));
    check("Packet 1 ends with EOC", is_tdc_eoc(words[14]));
    check("Packet 2 ends with EOC", is_tdc_eoc(words[17]));
    check("Zero-hit packet stays compact", words[15][15:14] == 2'b10 && words[16][15:13] == 3'b101);
    check("Shared readout exercised three stall points", stall_count == 3);
    check("Packet source stays stable while busy", src_change_during_busy_count == 0);
    check("Ready returns only to the packet owner", wrong_ready_owner_count == 0);
    check("Round-robin source ends on Z", packet_src == TDC_ID_Z);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_tdc_shared_readout_unit: %0d failures", fail_count);

    $display("tb_spadmic_tdc_shared_readout_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #200_000_000;
    $fatal(1, "TIMEOUT");
  end
endmodule

`default_nettype wire
