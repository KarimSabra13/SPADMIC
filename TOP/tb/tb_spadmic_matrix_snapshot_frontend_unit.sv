`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_matrix_snapshot_frontend_unit;
  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic enable;
  logic clear;
  logic [2:0] required_direction_mask;
  logic [63:0] R;
  logic [63:0] Y;
  logic [63:0] B;
  wire snapshot_valid;
  wire [63:0] snapshot_R;
  wire [63:0] snapshot_Y;
  wire [63:0] snapshot_B;
  wire busy;
  wire timeout;
  wire overlap;
  wire reject;
  wire rearm_ready;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_matrix_snapshot_frontend dut (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .enable_i(enable),
    .clear_i(clear),
    .required_direction_mask_i(required_direction_mask),
    .R_i(R),
    .Y_i(Y),
    .B_i(B),
    .settle_cycles_i(16'd2),
    .watchdog_cycles_i(16'd12),
    .snapshot_valid_o(snapshot_valid),
    .snapshot_R_o(snapshot_R),
    .snapshot_Y_o(snapshot_Y),
    .snapshot_B_o(snapshot_B),
    .busy_o(busy),
    .timeout_o(timeout),
    .overlap_o(overlap),
    .reject_o(reject),
    .rearm_ready_o(rearm_ready)
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

  task automatic wait_valid;
    int guard;
    begin
      guard = 0;
      while (!snapshot_valid && guard < 40) begin
        @(posedge clk_sys);
        guard++;
      end
      #1;
      check("snapshot_valid asserted before timeout guard", snapshot_valid);
    end
  endtask

  task automatic clear_and_rearm;
    begin
      @(negedge clk_sys);
      clear = 1'b1;
      @(negedge clk_sys);
      clear = 1'b0;
      R = '0;
      Y = '0;
      B = '0;
      repeat (8) @(posedge clk_sys);
      #1;
      check("frontend rearms after two zero samples", rearm_ready);
    end
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n      = 1'b0;
    enable     = 1'b1;
    clear      = 1'b0;
    required_direction_mask = 3'b111;
    R          = '0;
    Y          = '0;
    B          = '0;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (6) @(posedge clk_sys);
    #1;
    check("reset starts with no valid snapshot", !snapshot_valid);
    check("zero matrix reaches rearm ready", rearm_ready);

    @(negedge clk_sys);
    R[3] = 1'b1;
    @(negedge clk_sys);
    Y[4] = 1'b1;
    @(negedge clk_sys);
    B[5] = 1'b1;
    @(negedge clk_sys);
    R[9] = 1'b1;
    wait_valid();
    check("late R bit included in frozen snapshot", snapshot_R[9] && snapshot_R[3]);
    check("Y snapshot captured", snapshot_Y[4]);
    check("B snapshot captured", snapshot_B[5]);
    check("late change flagged overlap", overlap);

    R[10] = 1'b1;
    repeat (3) @(posedge clk_sys);
    #1;
    check("snapshot remains frozen after capture", !snapshot_R[10]);
    clear_and_rearm();

    @(negedge clk_sys);
    R[1] = 1'b1;
    wait_valid();
    check("incomplete image causes reject", reject);
    check("incomplete image causes timeout", timeout);
    check("timeout snapshot keeps accumulated asserted R", snapshot_R[1]);
    clear_and_rearm();

    required_direction_mask = 3'b101;
    @(negedge clk_sys);
    R[7] = 1'b1;
    B[8] = 1'b1;
    wait_valid();
    check("mask-aware snapshot does not require inactive Y", snapshot_valid && !reject);
    check("mask-aware snapshot captures required R/B", snapshot_R[7] && snapshot_B[8]);
    check("mask-aware snapshot leaves absent Y zero", snapshot_Y == 64'h0);
    @(negedge clk_sys);
    clear = 1'b1;
    @(negedge clk_sys);
    clear = 1'b0;
    R = '0;
    B = '0;
    Y[12] = 1'b1;
    repeat (8) @(posedge clk_sys);
    #1;
    check("unrequired Y does not block masked rearm", rearm_ready);
    Y = '0;

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_matrix_snapshot_frontend_unit: %0d failures", fail_count);

    $display("tb_spadmic_matrix_snapshot_frontend_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #2_000_000;
    $fatal(1, "tb_spadmic_matrix_snapshot_frontend_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
