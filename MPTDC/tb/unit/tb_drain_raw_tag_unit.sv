`timescale 1ps/1ps
`default_nettype none

module tb_drain_raw_tag_unit;
  import mptdc_pkg::*;

  logic clk_sys;
  initial clk_sys = 1'b0;
  always #3125 clk_sys = ~clk_sys;

  logic [N_CTX-1:0]       ctx_drain_sync;
  ctx_id_t                read_ctx;
  mptdc_ctx_snapshot_t    snapshot;
  logic                   fifo_wr_en;
  mptdc_acq_rec_t         fifo_wr_data;
  logic                   fifo_wr_full;
  logic [N_CTX-1:0]       ctx_release;
  logic                   conv_done;
  drain_state_e           state;
  logic                   rst_n;

  int pass_cnt;
  int fail_cnt;

  mptdc_drain_ctrl u_dut (
    .clk_sys          (clk_sys),
    .rst_n            (rst_n),
    .ctx_drain_sync_i (ctx_drain_sync),
    .read_ctx_o       (read_ctx),
    .snapshot_i       (snapshot),
    .fifo_wr_en_o     (fifo_wr_en),
    .fifo_wr_data_o   (fifo_wr_data),
    .fifo_wr_full_i   (fifo_wr_full),
    .ctx_release_o    (ctx_release),
    .conv_done_o      (conv_done),
    .state_o          (state)
  );

  function automatic logic [NFAST_W-1:0] tag_at_count(input int unsigned count);
    logic [NFAST_W-1:0] state;
    begin
      state = FAST_TAG_SEED;
      for (int unsigned i = 0; i < count; i++)
        state = fast_tag_next(state);
      tag_at_count = state;
    end
  endfunction

  task automatic tick();
    @(posedge clk_sys);
    #1;
  endtask

  task automatic check(input bit cond, input string label);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s", label);
      fail_cnt++;
    end
  endtask

  task automatic wait_write(output mptdc_acq_rec_t rec, input string label);
    int cycles;
    cycles = 0;
    while (1) begin
      @(negedge clk_sys);
      #1;
      if (fifo_wr_en) begin
        rec = fifo_wr_data;
        $display("[INFO] captured write %s after %0d cycles", label, cycles);
        tick();
        return;
      end
      cycles++;
      if (cycles > 100)
        $fatal(1, "timeout waiting for FIFO write: %s", label);
    end
  endtask

  initial begin
    mptdc_acq_rec_t rec;
    logic [NFAST_W-1:0] raw_phase0_tag;
    logic [NFAST_W-1:0] raw_hit_tag;

    pass_cnt = 0;
    fail_cnt = 0;
    rst_n = 1'b0;
    ctx_drain_sync = '0;
    fifo_wr_full = 1'b0;
    snapshot = '0;

    raw_phase0_tag = tag_at_count(9);   // raw tag 12, not decoded count 9
    raw_hit_tag    = tag_at_count(5);   // raw tag 32, not decoded count 5

    snapshot.hit_count = 4'd1;
    snapshot.hit_level[5] = 1'b1;
    snapshot.nfast_snap = raw_phase0_tag;
    snapshot.nfast_hit_packed[5*NFAST_W +: NFAST_W] = raw_hit_tag;
    snapshot.nslow_snap = 7'd21;
    snapshot.flags = '0;

    repeat (3) tick();
    rst_n = 1'b1;
    repeat (2) tick();

    ctx_drain_sync = 2'b01;
    wait_write(rec, "META");
    check(rec.kind == ACQ_REC_META, "first record is META");
    check(rec.meta.nfast == raw_phase0_tag, "META nfast emits raw phase0 tag");
    check(rec.meta.nfast != 7'd9, "META nfast is not RTL-decoded");

    wait_write(rec, "HIT5");
    check(rec.kind == ACQ_REC_HIT, "second record is HIT");
    check(rec.hit.ns == ph_idx_t'(0), "HIT ns");
    check(rec.hit.nf == ph_idx_t'(5), "HIT nf");
    check(rec.hit.nfast == raw_hit_tag, "HIT nfast emits raw tag");
    check(rec.hit.nfast != 7'd5, "HIT nfast is not RTL-decoded");

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_drain_raw_tag_unit failed");
    $display("TEST PASSED");
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_drain_raw_tag_unit timeout");
  end
endmodule

`default_nettype wire
