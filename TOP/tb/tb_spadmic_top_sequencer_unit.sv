`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_top_sequencer_unit;
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;

  logic              cfg_update;
  logic              req_global_enable;
  logic [2:0]        req_axis_enable;
  logic              req_position_enable;
  spadmic_tx_sel_e   req_shared_tx_sel;
  input_sel_e        req_tdc_input_sel;
  out_mode_e         req_tdc_out_mode;

  logic              tdc_tx_busy;
  logic [2:0]        tdc_pkt_pending;
  logic              position_busy;
  logic              position_pending;

  wire               cfg_accept;
  wire               transition_busy;
  wire               active_global_enable;
  wire [2:0]         active_axis_enable;
  wire               active_position_enable;
  spadmic_tx_sel_e   active_shared_tx_sel;
  input_sel_e        active_tdc_input_sel;
  out_mode_e         active_tdc_out_mode;

  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_top_sequencer dut (
    .clk_sys               (clk_sys),
    .rst_n                 (rst_n),
    .cfg_update_i          (cfg_update),
    .req_global_enable_i   (req_global_enable),
    .req_axis_enable_i     (req_axis_enable),
    .req_position_enable_i (req_position_enable),
    .req_shared_tx_sel_i   (req_shared_tx_sel),
    .req_tdc_input_sel_i   (req_tdc_input_sel),
    .req_tdc_out_mode_i    (req_tdc_out_mode),
    .tdc_tx_busy_i         (tdc_tx_busy),
    .tdc_pkt_pending_i     (tdc_pkt_pending),
    .position_busy_i       (position_busy),
    .position_pending_i    (position_pending),
    .cfg_accept_o          (cfg_accept),
    .transition_busy_o     (transition_busy),
    .active_global_enable_o(active_global_enable),
    .active_axis_enable_o  (active_axis_enable),
    .active_position_enable_o(active_position_enable),
    .active_shared_tx_sel_o(active_shared_tx_sel),
    .active_tdc_input_sel_o(active_tdc_input_sel),
    .active_tdc_out_mode_o (active_tdc_out_mode)
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

  initial begin
    pass_count          = 0;
    fail_count          = 0;
    rst_n               = 1'b0;
    cfg_update          = 1'b0;
    req_global_enable   = 1'b0;
    req_axis_enable     = 3'b111;
    req_position_enable = 1'b1;
    req_shared_tx_sel   = SPADMIC_TX_TDC;
    req_tdc_input_sel   = INPUT_SPAD;
    req_tdc_out_mode    = OUT_MODE_RAW_FEATURES;
    tdc_tx_busy         = 1'b0;
    tdc_pkt_pending     = '0;
    position_busy       = 1'b0;
    position_pending    = 1'b0;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (3) @(posedge clk_sys);
    #1;

    check("Reset defaults global enable low", active_global_enable === 1'b0);
    check("Reset defaults axis enable all on", active_axis_enable === 3'b111);
    check("Reset defaults position enable on", active_position_enable === 1'b1);
    check("Reset defaults shared tx TDC", active_shared_tx_sel === SPADMIC_TX_TDC);
    check("Reset defaults input select SPAD", active_tdc_input_sel === INPUT_SPAD);
    check("Reset defaults output mode raw-features", active_tdc_out_mode === OUT_MODE_RAW_FEATURES);
    check("Reset settles to accepting state", cfg_accept === 1'b1);
    check("Reset settles with no transition busy", transition_busy === 1'b0);

    req_global_enable   = 1'b1;
    req_axis_enable     = 3'b101;
    req_position_enable = 1'b1;
    req_shared_tx_sel   = SPADMIC_TX_POSITION;
    req_tdc_input_sel   = INPUT_CAL;
    req_tdc_out_mode    = OUT_MODE_FULL;
    cfg_update          = 1'b1;
    @(posedge clk_sys);
    #1;
    cfg_update = 1'b0;

    check("Accepted request enters transition", transition_busy === 1'b1);
    check("Transition forces global enable low", active_global_enable === 1'b0);
    check("Old source held until commit", active_shared_tx_sel === SPADMIC_TX_TDC);
    check("Accept gate closes during transition", cfg_accept === 1'b0);

    @(posedge clk_sys);
    #1;
    check("Committed request re-enables global enable", active_global_enable === 1'b1);
    check("Committed request updates axis enables", active_axis_enable === 3'b101);
    check("Committed request updates shared source", active_shared_tx_sel === SPADMIC_TX_POSITION);
    check("Committed request updates input select", active_tdc_input_sel === INPUT_CAL);
    check("Committed request keeps output mode fixed", active_tdc_out_mode === OUT_MODE_RAW_FEATURES);
    check("Transition completes after idle commit", transition_busy === 1'b0);
    check("Accept gate reopens after commit", cfg_accept === 1'b1);

    req_global_enable   = 1'b1;
    req_axis_enable     = 3'b111;
    req_position_enable = 1'b1;
    req_shared_tx_sel   = SPADMIC_TX_TDC;
    req_tdc_input_sel   = INPUT_SPAD;
    req_tdc_out_mode    = OUT_MODE_RAW_TIMESTAMP;
    cfg_update          = 1'b1;
    @(posedge clk_sys);
    #1;
    cfg_update      = 1'b0;
    tdc_pkt_pending = 3'b001;

    check("Drain transition starts busy", transition_busy === 1'b1);
    check("Drain transition keeps global enable low", active_global_enable === 1'b0);
    check("Drain transition keeps prior source active", active_shared_tx_sel === SPADMIC_TX_POSITION);

    repeat (2) begin
      @(posedge clk_sys);
      #1;
      check("Pending packet holds transition busy", transition_busy === 1'b1);
      check("Pending packet holds prior source", active_shared_tx_sel === SPADMIC_TX_POSITION);
    end

    tdc_pkt_pending = '0;
    @(posedge clk_sys);
    #1;
    check("Clearing pending commits requested source", active_shared_tx_sel === SPADMIC_TX_TDC);
    check("Clearing pending keeps output mode fixed", active_tdc_out_mode === OUT_MODE_RAW_FEATURES);
    check("Transition busy clears after drain", transition_busy === 1'b0);
    check("Accept gate restores after drain", cfg_accept === 1'b1);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_top_sequencer_unit: %0d failures", fail_count);

    $display("tb_spadmic_top_sequencer_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #100_000_000;
    $fatal(1, "TIMEOUT");
  end
endmodule

`default_nettype wire
