`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_event_coordinator_modes_unit;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  spadmic_operating_mode_e mode;
  logic global_enable;
  logic [2:0] active_axis_mask;
  logic matrix_activity;
  logic cal_activity;
  logic resources_ready;
  logic raw_snapshot_required;
  logic auto_reset_enable;
  logic snapshot_valid;
  logic [2:0] tdc_start_seen;
  logic [3:0] packet_pending_mask;
  logic reset_done;
  logic bundle_done;
  logic rearm_ready;
  wire event_open;
  wire [13:0] event_id;
  wire [3:0] required_packet_mask;
  wire [2:0] required_tdc_mask;
  wire [3:0] required_reset_ack_mask;
  wire [3:0] observed_reset_ack_mask;
  wire reset_start;
  wire bundle_start;
  wire accept_enable;
  wire rejected_not_ready;
  wire busy;
  wire idle;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_event_coordinator dut (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .active_mode_i(mode),
    .global_enable_i(global_enable),
    .active_axis_mask_i(active_axis_mask),
    .matrix_activity_i(matrix_activity),
    .cal_activity_i(cal_activity),
    .pre_event_resources_ready_i(resources_ready),
    .raw_snapshot_required_i(raw_snapshot_required),
    .auto_reset_enable_i(auto_reset_enable),
    .snapshot_valid_i(snapshot_valid),
    .tdc_start_seen_i(tdc_start_seen),
    .packet_pending_mask_i(packet_pending_mask),
    .reset_done_i(reset_done),
    .bundle_done_i(bundle_done),
    .rearm_ready_i(rearm_ready),
    .event_open_o(event_open),
    .event_id_o(event_id),
    .required_packet_mask_o(required_packet_mask),
    .required_tdc_mask_o(required_tdc_mask),
    .required_reset_ack_mask_o(required_reset_ack_mask),
    .observed_reset_ack_mask_o(observed_reset_ack_mask),
    .reset_start_o(reset_start),
    .bundle_start_o(bundle_start),
    .accept_enable_o(accept_enable),
    .rejected_not_ready_o(rejected_not_ready),
    .busy_o(busy),
    .idle_o(idle)
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

  task automatic reset_inputs;
    begin
      matrix_activity       = 1'b0;
      cal_activity          = 1'b0;
      snapshot_valid        = 1'b0;
      tdc_start_seen        = 3'b000;
      packet_pending_mask   = 4'b0000;
      reset_done            = 1'b0;
      bundle_done           = 1'b0;
      rearm_ready           = 1'b0;
      resources_ready       = 1'b1;
      raw_snapshot_required = 1'b1;
      auto_reset_enable     = 1'b1;
      active_axis_mask      = 3'b111;
    end
  endtask

  task automatic finish_event;
    begin
      @(negedge clk_sys);
      bundle_done = 1'b1;
      @(posedge clk_sys);
      #1;
      bundle_done = 1'b0;
      rearm_ready = 1'b1;
      repeat (2) @(posedge clk_sys);
      #1;
      check("event returns idle", idle);
      reset_inputs();
    end
  endtask

  task automatic pulse_reset_done;
    begin
      @(negedge clk_sys);
      reset_done = 1'b1;
      @(posedge clk_sys);
      #1;
      reset_done = 1'b0;
    end
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    global_enable = 1'b1;
    mode = SPADMIC_MODE_DISABLED;
    reset_inputs();

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);

    mode = SPADMIC_MODE_TDC_ONLY;
    @(negedge clk_sys);
    matrix_activity = 1'b1;
    @(negedge clk_sys);
    matrix_activity = 1'b0;
    resources_ready = 1'b0;
    tdc_start_seen  = 3'b111;
    snapshot_valid  = 1'b1;
    @(posedge clk_sys);
    #1;
    check("TDC-only mask excludes position", required_packet_mask == 4'b0111);
    check("frozen grant survives live resource drop", reset_start);
    pulse_reset_done();
    packet_pending_mask = 4'b0111;
    @(posedge clk_sys);
    #1;
    check("TDC-only bundles without position packet", bundle_start);
    finish_event();

    mode = SPADMIC_MODE_POSITION_ONLY;
    @(negedge clk_sys);
    matrix_activity = 1'b1;
    @(negedge clk_sys);
    matrix_activity = 1'b0;
    snapshot_valid  = 1'b1;
    tdc_start_seen  = 3'b000;
    @(posedge clk_sys);
    #1;
    check("Position-only reset does not wait for TDC", reset_start);
    check("Position-only expected packet mask", required_packet_mask == 4'b1000);
    pulse_reset_done();
    packet_pending_mask = 4'b1000;
    @(posedge clk_sys);
    #1;
    check("Position-only bundles without TDC packets", bundle_start);
    finish_event();

    mode = SPADMIC_MODE_BOTH;
    @(negedge clk_sys);
    matrix_activity = 1'b1;
    @(negedge clk_sys);
    matrix_activity = 1'b0;
    snapshot_valid  = 1'b1;
    tdc_start_seen  = 3'b111;
    @(posedge clk_sys);
    #1;
    pulse_reset_done();
    packet_pending_mask = 4'b0111;
    @(posedge clk_sys);
    #1;
    check("BOTH does not bundle before position packet", !bundle_start);
    packet_pending_mask = 4'b1111;
    @(posedge clk_sys);
    #1;
    check("BOTH bundles when all four sources pending", bundle_start);
    finish_event();

    mode = SPADMIC_MODE_CALIBRATION;
    active_axis_mask = 3'b101;
    auto_reset_enable = 1'b0;
    raw_snapshot_required = 1'b0;
    @(negedge clk_sys);
    matrix_activity = 1'b1;
    repeat (2) @(posedge clk_sys);
    #1;
    check("Calibration ignores matrix activity", idle);
    matrix_activity = 1'b0;
    @(negedge clk_sys);
    cal_activity = 1'b1;
    @(posedge clk_sys);
    #1;
    cal_activity = 1'b0;
    packet_pending_mask = 4'b0101;
    repeat (2) @(posedge clk_sys);
    #1;
    check("Calibration required packet mask uses selected axes", required_packet_mask == 4'b0101);
    check("Calibration does not start matrix reset", !reset_start);
    check("Calibration bundles selected axes only", bundle_start);
    finish_event();

    mode = SPADMIC_MODE_TDC_ONLY;
    resources_ready = 1'b0;
    @(negedge clk_sys);
    matrix_activity = 1'b1;
    @(posedge clk_sys);
    #1;
    check("not-ready event is rejected", rejected_not_ready);
    check("not-ready event does not open", !event_open);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_event_coordinator_modes_unit: %0d failures", fail_count);

    $display("tb_spadmic_event_coordinator_modes_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #3_000_000;
    $fatal(1, "tb_spadmic_event_coordinator_modes_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
