`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_tdc_arbiter3_unit;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;
  import spadmic_pkg::*;

  logic clk_sys;
  logic rst_n;

  logic [2:0] src_valid;
  logic [15:0] src_data [3];
  wire [2:0] src_ready;

  wire [2:0] pkt_valid;
  wire [2:0] pkt_sop;
  wire [2:0] pkt_eop;
  wire [15:0] pkt_data [3];
  wire [2:0] pkt_ready;
  wire [2:0] pkt_available;
  wire [2:0] fifo_full;

  logic shared_ready;
  wire shared_valid;
  wire [15:0] shared_data;
  wire shared_sop;
  wire shared_eop;
  wire arb_busy;

  logic [15:0] out_words [$];
  int pass_cnt;
  int fail_cnt;

  initial clk_sys = 1'b0;
  always #3_125 clk_sys = ~clk_sys;

  spadmic_tdc_packet_fifo #(.DEPTH(16), .TDC_ID(TDC_ID_X)) u_fifo_x (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .narrow_valid_i  (src_valid[0]),
    .narrow_data_i   (src_data[0]),
    .narrow_ready_o  (src_ready[0]),
    .pkt_valid_o     (pkt_valid[0]),
    .pkt_data_o      (pkt_data[0]),
    .pkt_sop_o       (pkt_sop[0]),
    .pkt_eop_o       (pkt_eop[0]),
    .pkt_ready_i     (pkt_ready[0]),
    .pkt_available_o (pkt_available[0]),
    .fifo_full_o     (fifo_full[0])
  );

  spadmic_tdc_packet_fifo #(.DEPTH(16), .TDC_ID(TDC_ID_Y)) u_fifo_y (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .narrow_valid_i  (src_valid[1]),
    .narrow_data_i   (src_data[1]),
    .narrow_ready_o  (src_ready[1]),
    .pkt_valid_o     (pkt_valid[1]),
    .pkt_data_o      (pkt_data[1]),
    .pkt_sop_o       (pkt_sop[1]),
    .pkt_eop_o       (pkt_eop[1]),
    .pkt_ready_i     (pkt_ready[1]),
    .pkt_available_o (pkt_available[1]),
    .fifo_full_o     (fifo_full[1])
  );

  spadmic_tdc_packet_fifo #(.DEPTH(16), .TDC_ID(TDC_ID_Z)) u_fifo_z (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .narrow_valid_i  (src_valid[2]),
    .narrow_data_i   (src_data[2]),
    .narrow_ready_o  (src_ready[2]),
    .pkt_valid_o     (pkt_valid[2]),
    .pkt_data_o      (pkt_data[2]),
    .pkt_sop_o       (pkt_sop[2]),
    .pkt_eop_o       (pkt_eop[2]),
    .pkt_ready_i     (pkt_ready[2]),
    .pkt_available_o (pkt_available[2]),
    .fifo_full_o     (fifo_full[2])
  );

  spadmic_tdc_arbiter3 u_dut (
    .clk_sys        (clk_sys),
    .rst_n          (rst_n),
    .pkt_valid_i    (pkt_valid),
    .pkt_sop_i      (pkt_sop),
    .pkt_eop_i      (pkt_eop),
    .pkt_data_i     (pkt_data),
    .pkt_ready_o    (pkt_ready),
    .shared_ready_i (shared_ready),
    .shared_valid_o (shared_valid),
    .shared_data_o  (shared_data),
    .shared_sop_o   (shared_sop),
    .shared_eop_o   (shared_eop),
    .arb_busy_o     (arb_busy),
    .grant_idx_o    (/* unused */)
  );

  always @(posedge clk_sys) begin
    if (shared_valid && shared_ready)
      $display("[ARB] t=%0t word=0x%04h sop=%0b eop=%0b", $time, shared_data, shared_sop, shared_eop);
  end

  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s", label);
      fail_cnt++;
    end
  endtask

  task automatic drive_word(input int idx, input logic [15:0] word);
    @(posedge clk_sys);
    src_valid[idx] = 1'b1;
    src_data[idx]  = word;
    while (!src_ready[idx]) @(posedge clk_sys);
    @(posedge clk_sys);
    src_valid[idx] = 1'b0;
    src_data[idx]  = '0;
  endtask

  task automatic push_packet_x();
    drive_word(0, 16'h8001);
    drive_word(0, 16'hA000);
    drive_word(0, 16'h0101);
    drive_word(0, 16'hC001);
  endtask

  task automatic push_packet_y();
    drive_word(1, 16'h8002);
    drive_word(1, 16'hA000);
    drive_word(1, 16'h0202);
    drive_word(1, 16'hC002);
  endtask

  task automatic push_packet_z();
    drive_word(2, 16'h8003);
    drive_word(2, 16'hA000);
    drive_word(2, 16'h0303);
    drive_word(2, 16'hC003);
  endtask

  initial begin
    pass_cnt = 0;
    fail_cnt = 0;
    rst_n = 1'b0;
    shared_ready = 1'b0;
    src_valid = '0;
    src_data[0] = '0;
    src_data[1] = '0;
    src_data[2] = '0;
    repeat (5) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);

    fork
      push_packet_x();
      push_packet_y();
      push_packet_z();
    join

    check("all three packets available before arbitration", pkt_available == 3'b111);
    shared_ready = 1'b1;

    while (out_words.size() < 12) begin
      @(posedge clk_sys);
      if (shared_valid && shared_ready)
        out_words.push_back(shared_data);
    end

    check("exactly three 4-word packets emitted", out_words.size() == 12);
    check("packet 0 starts with header", is_header(out_words[0]));
    check("packet 0 subheader patched with X id", out_words[1][5:4] == TDC_ID_X);
    check("packet 0 payload preserved", out_words[2] == 16'h0101);
    check("packet 0 ends on eoc", is_eoc(out_words[3]));

    check("packet 1 starts after packet 0 eoc", is_header(out_words[4]));
    check("packet 1 subheader patched with Y id", out_words[5][5:4] == TDC_ID_Y);
    check("packet 1 payload preserved", out_words[6] == 16'h0202);
    check("packet 1 ends on eoc", is_eoc(out_words[7]));

    check("packet 2 starts after packet 1 eoc", is_header(out_words[8]));
    check("packet 2 subheader patched with Z id", out_words[9][5:4] == TDC_ID_Z);
    check("packet 2 payload preserved", out_words[10] == 16'h0303);
    check("packet 2 ends on eoc", is_eoc(out_words[11]));
    check("arbiter idle after all packets", arb_busy == 1'b0);

    if (fail_cnt != 0)
      $fatal(1, "tb_spadmic_tdc_arbiter3_unit: %0d failures", fail_cnt);

    $display("tb_spadmic_tdc_arbiter3_unit: %0d pass / %0d fail", pass_cnt, fail_cnt);
    $finish;
  end

  initial begin
    #2_000_000;
    $fatal(1, "tb_spadmic_tdc_arbiter3_unit: TIMEOUT");
  end

endmodule

`default_nettype wire
