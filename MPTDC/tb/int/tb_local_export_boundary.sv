// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
`timescale 1ps/1ps
`default_nettype none

module tb_local_export_boundary;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  logic clk_sys;
  logic rst_n;
  logic fifo_clr;
  logic wr_en;
  mptdc_acq_rec_t wr_data;
  logic wr_full;

  out_mode_e out_mode;
  logic shared_readout_en;
  logic acq_ready;
  logic acq_valid;
  mptdc_acq_rec_t acq_data;

  logic narrow_ready;
  logic narrow_valid;
  logic [NARROW_W-1:0] narrow_data;

  logic fifo_rd_en;
  logic fifo_rd_valid;
  mptdc_acq_rec_t fifo_rd_data;
  logic fifo_rd_en_narrow;
  logic [$clog2(FIFO_DEPTH+1)-1:0] fifo_level;

  initial clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  mptdc_sync_fifo #(
    .WIDTH (ACQ_REC_W),
    .DEPTH (FIFO_DEPTH)
  ) u_fifo (
    .clk       (clk_sys),
    .rst_n     (rst_n),
    .clr_i     (fifo_clr),
    .wr_en_i   (wr_en),
    .wr_data_i (wr_data),
    .wr_full_o (wr_full),
    .rd_en_i   (fifo_rd_en),
    .rd_data_o (fifo_rd_data),
    .rd_valid_o(fifo_rd_valid),
    .level_o   (fifo_level)
  );

  assign fifo_rd_en = shared_readout_en
                    ? (fifo_rd_valid & acq_ready)
                    : fifo_rd_en_narrow;
  assign acq_valid = shared_readout_en & fifo_rd_valid;
  assign acq_data  = fifo_rd_data;

  mptdc_narrow16_tx_v2 u_narrow_tx (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .out_mode_i      (out_mode),
    .fifo_rd_valid_i (shared_readout_en ? 1'b0 : fifo_rd_valid),
    .fifo_rd_data_i  (fifo_rd_data),
    .fifo_rd_en_o    (fifo_rd_en_narrow),
    .narrow_ready_i  (narrow_ready),
    .narrow_valid_o  (narrow_valid),
    .narrow_data_o   (narrow_data)
  );

  task automatic must(input bit cond, input string msg);
    if (!cond)
      $fatal(1, "[TB] %s", msg);
  endtask

  function automatic mptdc_conv_meta_t make_meta(
    input logic [NSLOW_W-1:0]    nslow,
    input logic [NFAST_W-1:0]    nfast_snap,
    input logic [NFAST_W-1:0]    nfast_stop,
    input logic [MAX_HITS_W-1:0] hit_count,
    input ctx_id_t               ctx_id,
    input logic                  phase0_snap,
    input tdc_conv_flags_t       flags,
    input logic                  slow_boundary_inc
  );
    mptdc_conv_meta_t meta;
    meta                    = '0;
    meta.nslow              = nslow;
    meta.nfast              = nfast_snap;
    meta.nfast_stop         = nfast_stop;
    meta.hit_count          = hit_count;
    meta.flags              = flags;
    meta.phase0_snap        = phase0_snap;
    meta.slow_boundary_inc  = slow_boundary_inc;
    meta.ctx_id             = ctx_id;
    return meta;
  endfunction

  function automatic mptdc_hit_raw_t make_hit(
    input ph_idx_t                ns,
    input ph_idx_t                nf,
    input logic [NFAST_W-1:0]     nfast,
    input logic [EVENT_SEQ_W-1:0] event_seq
  );
    mptdc_hit_raw_t hit;
    hit           = '0;
    hit.ns        = ns;
    hit.nf        = nf;
    hit.nfast     = nfast;
    hit.event_seq = event_seq;
    return hit;
  endfunction

  function automatic mptdc_acq_rec_t make_meta_rec(input mptdc_conv_meta_t meta);
    mptdc_acq_rec_t rec;
    rec      = '0;
    rec.kind = ACQ_REC_META;
    rec.meta = meta;
    return rec;
  endfunction

  function automatic mptdc_acq_rec_t make_hit_rec(input mptdc_hit_raw_t hit);
    mptdc_acq_rec_t rec;
    rec      = '0;
    rec.kind = ACQ_REC_HIT;
    rec.hit  = hit;
    return rec;
  endfunction

  task automatic do_reset();
    rst_n              = 1'b0;
    fifo_clr           = 1'b0;
    wr_en              = 1'b0;
    wr_data            = '0;
    out_mode           = OUT_MODE_RAW_FEATURES;
    shared_readout_en  = 1'b0;
    acq_ready          = 1'b0;
    narrow_ready       = 1'b0;
    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);
  endtask

  task automatic wait_quiescent(input string label);
    repeat (2) @(posedge clk_sys);
    must(!fifo_rd_valid, $sformatf("%s: FIFO not empty", label));
    must(fifo_level == '0, $sformatf("%s: FIFO level not zero", label));
    must(!narrow_valid, $sformatf("%s: narrow_valid still asserted", label));
    must(!acq_valid, $sformatf("%s: acq_valid still asserted", label));
  endtask

  task automatic push_rec(input mptdc_acq_rec_t rec);
    while (wr_full)
      @(posedge clk_sys);
    wr_data = rec;
    wr_en   = 1'b1;
    @(posedge clk_sys);
    wr_en   = 1'b0;
    wr_data = '0;
  endtask

  task automatic queue_packet(
    input mptdc_conv_meta_t meta,
    input mptdc_hit_raw_t   hits[$]
  );
    push_rec(make_meta_rec(meta));
    for (int i = 0; i < hits.size(); i++)
      push_rec(make_hit_rec(hits[i]));
  endtask

  task automatic collect_local_packet(
    output logic [NARROW_W-1:0] words[$],
    input  int                  timeout_cycles = 2000
  );
    int cyc;
    logic [NARROW_W-1:0] w;

    words        = {};
    cyc          = 0;
    narrow_ready = 1'b1;

    while (1) begin
      @(posedge clk_sys);
      cyc++;
      must(!acq_valid, "local mode: acq_valid asserted");
      if (cyc > timeout_cycles) begin
        $display("[TB][DBG] local header timeout shared=%0b fifo_valid=%0b fifo_level=%0d narrow_valid=%0b tx_state=%0d rd_en_narrow=%0b",
                 shared_readout_en, fifo_rd_valid, fifo_level, narrow_valid,
                 u_narrow_tx.state_q, fifo_rd_en_narrow);
        $fatal(1, "[TB] local mode: timeout waiting for header");
      end
      if (narrow_valid && narrow_ready) begin
        w = narrow_data;
        words.push_back(w);
        if (is_header(w))
          break;
      end
    end

    while (1) begin
      @(posedge clk_sys);
      cyc++;
      must(!acq_valid, "local mode: acq_valid asserted while draining");
      if (cyc > timeout_cycles) begin
        $display("[TB][DBG] local EOC timeout shared=%0b fifo_valid=%0b fifo_level=%0d narrow_valid=%0b tx_state=%0d rd_en_narrow=%0b",
                 shared_readout_en, fifo_rd_valid, fifo_level, narrow_valid,
                 u_narrow_tx.state_q, fifo_rd_en_narrow);
        $fatal(1, "[TB] local mode: timeout waiting for EOC");
      end
      if (narrow_valid && narrow_ready) begin
        w = narrow_data;
        words.push_back(w);
        if (is_eoc(w))
          break;
      end
    end

  endtask

  task automatic collect_export_packet(
    output mptdc_acq_rec_t recs[$],
    input  int             timeout_cycles = 2000
  );
    int cyc;
    int expected;

    recs      = {};
    cyc       = 0;
    expected  = -1;
    acq_ready = 1'b1;

    while ((expected < 0) || (recs.size() < expected)) begin
      @(posedge clk_sys);
      cyc++;
      must(!narrow_valid, "shared mode: narrow_valid asserted");
      must(cyc <= timeout_cycles, "shared mode: timeout collecting export packet");
      if (acq_valid && acq_ready) begin
        recs.push_back(acq_data);
        if (expected < 0)
          expected = 1 + int'(acq_data.meta.hit_count);
      end
    end

  endtask

  task automatic collect_export_packet_with_stalls(
    output mptdc_acq_rec_t recs[$],
    input  int             stall_cycles = 4,
    input  int             timeout_cycles = 4000
  );
    int cyc;
    int expected;
    mptdc_acq_rec_t held_rec;

    recs      = {};
    cyc       = 0;
    expected  = -1;
    acq_ready = 1'b0;

    while ((expected < 0) || (recs.size() < expected)) begin
      while (!acq_valid) begin
        @(posedge clk_sys);
        cyc++;
        must(!narrow_valid, "shared mode stalled: narrow_valid asserted");
        must(cyc <= timeout_cycles, "shared mode stalled: timeout waiting for valid");
      end

      held_rec = acq_data;
      repeat (stall_cycles) begin
        @(posedge clk_sys);
        cyc++;
        must(!narrow_valid, "shared mode stalled: narrow_valid asserted during hold");
        must(acq_valid, "shared mode stalled: acq_valid dropped during hold");
        must(acq_data === held_rec, "shared mode stalled: acq_data changed during hold");
        must(cyc <= timeout_cycles, "shared mode stalled: timeout during hold");
      end

      @(negedge clk_sys);
      acq_ready = 1'b1;
      @(posedge clk_sys);
      cyc++;
      must(!narrow_valid, "shared mode stalled: narrow_valid asserted on release");
      must(acq_valid, "shared mode stalled: acq_valid missing on release");
      recs.push_back(acq_data);
      if (expected < 0)
        expected = 1 + int'(acq_data.meta.hit_count);
      @(negedge clk_sys);
      acq_ready = 1'b0;
    end
  endtask

  task automatic decode_local_raw_features_packet(
    input  logic [NARROW_W-1:0] words[$],
    output mptdc_conv_meta_t    meta,
    output tb_hit_features_t    hits[$],
    output logic [13:0]         conv_id
  );
    int idx;
    tb_hit_features_t hf;

    meta    = '0;
    hits    = {};
    conv_id = '0;

    must(words.size() >= 2, "local packet too short");
    must(is_header(words[0]), "local packet first word is not a header");
    must(is_eoc(words[words.size()-1]), "local packet missing EOC");

    meta.ctx_id            = header_ctx_id(words[0]);
    meta.phase0_snap       = header_phase0(words[0]);
    meta.hit_count         = header_hit_count(words[0]);
    meta.flags             = header_flags(words[0]);
    meta.slow_boundary_inc = header_boundary_inc(words[0]);
    conv_id                = eoc_conv_id(words[words.size()-1]);

    idx = 1;
    while (idx + 1 < words.size()-1) begin
      hf = parse_hit_features(words[idx], words[idx+1]);
      hits.push_back(hf);
      idx += 2;
    end

    must(hits.size() == int'(meta.hit_count),
           $sformatf("local packet hit count mismatch hdr=%0d parsed=%0d",
                     meta.hit_count, hits.size()));

    if (hits.size() > 0) begin
      meta.nslow = hits[0].nslow;
      for (int i = 0; i < hits.size(); i++) begin
        must(hits[i].nslow == meta.nslow,
               $sformatf("local packet hit %0d changed nslow within packet", i));
      end
    end
  endtask

  task automatic check_local_packet_against_expected(
    input logic [NARROW_W-1:0] words[$],
    input mptdc_conv_meta_t    exp_meta,
    input mptdc_hit_raw_t      exp_hits[$],
    input logic [13:0]         exp_conv_id,
    input string               label
  );
    mptdc_conv_meta_t local_meta;
    tb_hit_features_t local_hits[$];
    logic [13:0] local_conv_id;

    decode_local_raw_features_packet(words, local_meta, local_hits, local_conv_id);

    must(words.size() == (2 + (2 * exp_hits.size())),
           $sformatf("%s: local packet word count mismatch got=%0d exp=%0d",
                     label, words.size(), 2 + (2 * exp_hits.size())));
    must(header_out_mode(words[0]) == OUT_MODE_RAW_FEATURES,
           $sformatf("%s: local packet out_mode mismatch", label));
    must(local_conv_id == exp_conv_id,
           $sformatf("%s: local conv_id mismatch got=%0d exp=%0d",
                     label, local_conv_id, exp_conv_id));
    must(local_meta.ctx_id == exp_meta.ctx_id,
           $sformatf("%s: ctx_id mismatch", label));
    must(local_meta.phase0_snap == exp_meta.phase0_snap,
           $sformatf("%s: phase0 mismatch", label));
    must(local_meta.hit_count == exp_meta.hit_count,
           $sformatf("%s: hit_count mismatch", label));
    must(local_meta.flags == exp_meta.flags,
           $sformatf("%s: flags mismatch", label));
    must(local_meta.slow_boundary_inc == exp_meta.slow_boundary_inc,
           $sformatf("%s: slow_boundary_inc mismatch", label));
    if (exp_hits.size() > 0) begin
      must(local_meta.nslow == exp_meta.nslow,
             $sformatf("%s: nslow mismatch got=%0d exp=%0d",
                        label, local_meta.nslow, exp_meta.nslow));
    end

    for (int i = 0; i < exp_hits.size(); i++) begin
      must(local_hits[i].nslow == exp_meta.nslow,
             $sformatf("%s: hit %0d nslow mismatch", label, i));
      must(local_hits[i].nfast == exp_hits[i].nfast,
             $sformatf("%s: hit %0d nfast_hit mismatch got=%0d exp=%0d",
                       label, i, local_hits[i].nfast, exp_hits[i].nfast));
      must(local_hits[i].ns == exp_hits[i].ns,
             $sformatf("%s: hit %0d ns mismatch", label, i));
      must(local_hits[i].nf == exp_hits[i].nf,
             $sformatf("%s: hit %0d nf mismatch", label, i));
    end
  endtask

  task automatic check_export_packet_against_expected(
    input mptdc_acq_rec_t   recs[$],
    input mptdc_conv_meta_t exp_meta,
    input mptdc_hit_raw_t   exp_hits[$],
    input string            label
  );
    must(recs.size() == (1 + exp_hits.size()),
           $sformatf("%s: export record count mismatch got=%0d exp=%0d",
                     label, recs.size(), 1 + exp_hits.size()));
    must(recs[0].kind == ACQ_REC_META,
           $sformatf("%s: first export record is not META", label));
    must(recs[0].meta === exp_meta,
           $sformatf("%s: META payload mismatch", label));

    for (int i = 0; i < exp_hits.size(); i++) begin
      must(recs[i+1].kind == ACQ_REC_HIT,
             $sformatf("%s: record %0d is not HIT", label, i+1));
      must(recs[i+1].hit === exp_hits[i],
             $sformatf("%s: HIT payload mismatch at index %0d", label, i));
      must(recs[i+1].hit.event_seq == EVENT_SEQ_W'(i),
             $sformatf("%s: HIT %0d event_seq mismatch", label, i));
    end
  endtask

  task automatic compare_export_sequences(
    input mptdc_acq_rec_t ref_recs[$],
    input mptdc_acq_rec_t got_recs[$],
    input string          label
  );
    must(ref_recs.size() == got_recs.size(),
           $sformatf("%s: export sequence size mismatch", label));
    for (int i = 0; i < ref_recs.size(); i++) begin
      must(ref_recs[i] === got_recs[i],
             $sformatf("%s: export sequence mismatch at record %0d", label, i));
    end
  endtask

  task automatic compare_local_packets(
    input logic [NARROW_W-1:0] ref_words[$],
    input logic [NARROW_W-1:0] got_words[$],
    input string               label
  );
    int last_idx;

    must(ref_words.size() == got_words.size(),
           $sformatf("%s: local packet size mismatch", label));
    last_idx = ref_words.size() - 1;
    for (int i = 0; i < last_idx; i++) begin
      must(ref_words[i] == got_words[i],
             $sformatf("%s: local packet mismatch at word %0d", label, i));
    end
    must(is_eoc(ref_words[last_idx]) && is_eoc(got_words[last_idx]),
           $sformatf("%s: local packet missing EOC", label));
    must(eoc_conv_id(got_words[last_idx]) == (eoc_conv_id(ref_words[last_idx]) + 14'd1),
           $sformatf("%s: local conv_id did not advance by one", label));
  endtask

  task automatic build_zero_hit_case(
    output mptdc_conv_meta_t meta,
    output mptdc_hit_raw_t   hits[$]
  );
    meta = make_meta(7'd12, 7'd21, 7'd37, 4'd0, ctx_id_t'(1'b1),
                     1'b1, tdc_conv_flags_t'(4'b0101), 1'b1);
    hits = {};
  endtask

  task automatic build_three_hit_case(
    output mptdc_conv_meta_t meta,
    output mptdc_hit_raw_t   hits[$]
  );
    meta = make_meta(7'd66, 7'd17, 7'd33, 4'd3, ctx_id_t'(1'b0),
                     1'b0, tdc_conv_flags_t'(4'b0011), 1'b1);
    hits = {};
    hits.push_back(make_hit(ph_idx_t'(4'd1), ph_idx_t'(4'd7), 7'd9,  EVENT_SEQ_W'(0)));
    hits.push_back(make_hit(ph_idx_t'(4'd3), ph_idx_t'(4'd2), 7'd11, EVENT_SEQ_W'(1)));
    hits.push_back(make_hit(ph_idx_t'(4'd8), ph_idx_t'(4'd0), 7'd13, EVENT_SEQ_W'(2)));
  endtask

  initial begin
    mptdc_conv_meta_t zero_meta;
    mptdc_conv_meta_t data_meta;
    mptdc_hit_raw_t zero_hits[$];
    mptdc_hit_raw_t data_hits[$];
    logic [NARROW_W-1:0] local_zero_words[$];
    logic [NARROW_W-1:0] local_ref_words[$];
    logic [NARROW_W-1:0] local_after_words[$];
    mptdc_acq_rec_t export_zero_recs[$];
    mptdc_acq_rec_t export_ref_recs[$];
    mptdc_acq_rec_t export_stall_recs[$];

    $display("[TB] === tb_local_export_boundary ===");
    do_reset();

    build_zero_hit_case(zero_meta, zero_hits);
    build_three_hit_case(data_meta, data_hits);

    $display("[TB] Scenario 1: local zero-hit packet");
    narrow_ready = 1'b0;
    acq_ready    = 1'b0;
    fork
      collect_local_packet(local_zero_words);
      queue_packet(zero_meta, zero_hits);
    join
    check_local_packet_against_expected(local_zero_words, zero_meta, zero_hits, 14'd0,
                                        "zero-hit local");
    wait_quiescent("zero-hit local");

    $display("[TB] Scenario 2: shared zero-hit export with stalls");
    shared_readout_en = 1'b1;
    narrow_ready      = 1'b0;
    acq_ready         = 1'b0;
    fork
      collect_export_packet_with_stalls(export_zero_recs, 4);
      queue_packet(zero_meta, zero_hits);
    join
    check_export_packet_against_expected(export_zero_recs, zero_meta, zero_hits,
                                         "zero-hit export");
    wait_quiescent("zero-hit export");

    $display("[TB] Scenario 3: local multi-hit reference packet");
    shared_readout_en = 1'b0;
    narrow_ready      = 1'b0;
    acq_ready         = 1'b0;
    fork
      collect_local_packet(local_ref_words);
      queue_packet(data_meta, data_hits);
    join
    check_local_packet_against_expected(local_ref_words, data_meta, data_hits, 14'd1,
                                        "multi-hit local reference");
    wait_quiescent("multi-hit local reference");

    $display("[TB] Scenario 4: shared multi-hit export reference");
    shared_readout_en = 1'b1;
    narrow_ready      = 1'b0;
    acq_ready         = 1'b0;
    fork
      collect_export_packet(export_ref_recs);
      queue_packet(data_meta, data_hits);
    join
    check_export_packet_against_expected(export_ref_recs, data_meta, data_hits,
                                         "multi-hit export reference");
    wait_quiescent("multi-hit export reference");

    $display("[TB] Scenario 5: shared multi-hit export with stalls");
    narrow_ready = 1'b0;
    acq_ready    = 1'b0;
    fork
      collect_export_packet_with_stalls(export_stall_recs, 3);
      queue_packet(data_meta, data_hits);
    join
    compare_export_sequences(export_ref_recs, export_stall_recs, "export backpressure");
    wait_quiescent("export backpressure");

    $display("[TB] Scenario 6: local multi-hit packet after shared export");
    shared_readout_en = 1'b0;
    narrow_ready      = 1'b0;
    acq_ready         = 1'b0;
    fork
      collect_local_packet(local_after_words);
      queue_packet(data_meta, data_hits);
    join
    check_local_packet_against_expected(local_after_words, data_meta, data_hits, 14'd2,
                                        "multi-hit local after export");
    compare_local_packets(local_ref_words, local_after_words, "local after export");
    wait_quiescent("multi-hit local after export");

    $display("[TB] PASS: local/export boundary ordering, zero-hit, backpressure, and field coherence");
    $finish;
  end

  initial begin
    #10ms;
    $fatal(1, "[TB] global timeout");
  end
endmodule

`default_nettype wire
