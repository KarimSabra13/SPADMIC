// ============================================================================
// Stress test: spadmic_ref_stop_qualifier
// Tests rapid back-to-back starts, reset mid-armed, edge-aligned corner cases,
// burst-after-idle, and no double-stop contract.
// ============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_stress_stop_qualifier;

  logic clk_sys;
  logic rst_n;
  logic clk_ref_40m;
  logic start_async;
  logic stop_async;
  logic armed;

  spadmic_ref_stop_qualifier dut (
    .rst_n          (rst_n),
    .start_async_i  (start_async),
    .clk_ref_40m    (clk_ref_40m),
    .stop_async_o   (stop_async),
    .armed_o        (armed)
  );

  // ── Clocks ──
  initial clk_sys = 0;
  always #3125 clk_sys = ~clk_sys;  // 160 MHz

  initial clk_ref_40m = 0;
  always #12500 clk_ref_40m = ~clk_ref_40m;  // 40 MHz

  // ── Scoreboard ──
  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  task automatic check(string name, logic cond);
    test_num++;
    if (cond) begin
      $display("[PASS] T%0d: %s", test_num, name);
      pass_count++;
    end else begin
      $display("[FAIL] T%0d: %s", test_num, name);
      fail_count++;
    end
  endtask

  task automatic pulse_start_async;
    @(posedge clk_sys);
    start_async <= 1'b1;
    @(posedge clk_sys);
    start_async <= 1'b0;
  endtask

  task automatic wait_clks(int n);
    repeat (n) @(posedge clk_sys);
  endtask

  // ── Detect stop edges ──
  logic stop_prev;
  int stop_edge_count;
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      stop_prev       <= 1'b0;
      stop_edge_count <= 0;
    end else begin
      stop_prev <= stop_async;
      if (stop_async && !stop_prev)
        stop_edge_count <= stop_edge_count + 1;
    end
  end

  initial begin
    $display("========================================");
    $display("STRESS TEST: spadmic_ref_stop_qualifier");
    $display("========================================");

    rst_n = 0;
    start_async = 0;

    // ── Reset ──
    repeat (10) @(posedge clk_sys);
    rst_n = 1;
    repeat (4) @(posedge clk_sys);

    // ========================================
    // TEST 1: Single normal start → stop cycle
    // ========================================
    fork
      pulse_start_async();
    join
    wait (armed);
    check("T1 armed after start_async", armed === 1'b1);
    @(posedge clk_ref_40m);
    // stop_async should go high during this ref high phase
    repeat (2) @(posedge clk_sys);
    check("T1 stop_async asserted", stop_async === 1'b1);
    @(negedge clk_ref_40m);
    repeat (2) @(posedge clk_sys);
    check("T1 stop deasserted after ref falls", stop_async === 1'b0);
    check("T1 disarmed after stop consumed", armed === 1'b0);

    // ========================================
    // TEST 2: No stop without start_async
    // ========================================
    stop_edge_count = 0;
    repeat (3) @(posedge clk_ref_40m);
    repeat (4) @(posedge clk_sys);
    check("T2 no stop without start (count==0)", stop_edge_count === 0);

    // ========================================
    // TEST 3: No double-stop on consecutive ref edges
    // ========================================
    stop_edge_count = 0;
    pulse_start_async();
    // Wait for 3 ref edges
    repeat (3) begin
      @(posedge clk_ref_40m);
      @(negedge clk_ref_40m);
    end
    repeat (4) @(posedge clk_sys);
    check("T3 exactly one stop per start (count==1)", stop_edge_count === 1);

    // ========================================
    // TEST 4: Rapid back-to-back starts (10 cycles)
    // Each start should produce exactly one stop
    // ========================================
    begin
      int total_stops_before;
      total_stops_before = stop_edge_count;
      stop_edge_count = 0;

      for (int i = 0; i < 10; i++) begin
        pulse_start_async();
        // Wait for stop to be consumed
        @(posedge clk_ref_40m);
        @(negedge clk_ref_40m);
        repeat (4) @(posedge clk_sys);
      end
      // Should have 10 stops
      check("T4 back-to-back 10 starts → 10 stops", stop_edge_count === 10);
    end

    // ========================================
    // TEST 5: Reset while armed
    // ========================================
    pulse_start_async();
    wait (armed);
    check("T5 armed before reset", armed === 1'b1);
    rst_n = 0;
    repeat (4) @(posedge clk_sys);
    check("T5 disarmed during reset", armed === 1'b0);
    check("T5 no stop during reset", stop_async === 1'b0);
    rst_n = 1;
    repeat (4) @(posedge clk_sys);
    @(posedge clk_ref_40m);
    @(negedge clk_ref_40m);
    repeat (2) @(posedge clk_sys);
    check("T5 no spurious stop after reset recovery", armed === 1'b0);

    // ========================================
    // TEST 6: Start accepted exactly at ref rising edge
    // ========================================
    // Align start_async to coincide with clk_ref_40m rising edge
    @(negedge clk_ref_40m);
    // Wait until just before the next rising edge
    repeat (3) @(posedge clk_sys);
    // Now fire start_async near the ref edge
    stop_edge_count = 0;
    fork
      pulse_start_async();
    join
    // The stop should happen on the NEXT ref edge (not the current one if already past)
    @(posedge clk_ref_40m);
    @(negedge clk_ref_40m);
    repeat (4) @(posedge clk_sys);
    check("T6 edge-aligned start → exactly 1 stop", stop_edge_count === 1);

    // ========================================
    // TEST 7: Long idle (100 ref cycles) then burst
    // ========================================
    repeat (100) @(posedge clk_ref_40m);
    stop_edge_count = 0;
    // Burst of 5 rapid starts
    for (int i = 0; i < 5; i++) begin
      pulse_start_async();
      @(posedge clk_ref_40m);
      @(negedge clk_ref_40m);
      repeat (4) @(posedge clk_sys);
    end
    check("T7 burst after idle → 5 stops", stop_edge_count === 5);

    // ========================================
    // TEST 8: After stop consumed, no more stops without new start
    // ========================================
    stop_edge_count = 0;
    // Fire a start, wait for stop, then wait 3 more ref edges
    pulse_start_async();
    @(posedge clk_ref_40m);
    @(negedge clk_ref_40m);
    repeat (4) @(posedge clk_sys);
    // stop_edge_count should be 1
    check("T8 one stop after start", stop_edge_count === 1);
    // Now wait 3 more ref cycles without new start
    repeat (3) begin
      @(posedge clk_ref_40m);
      @(negedge clk_ref_40m);
    end
    repeat (4) @(posedge clk_sys);
    check("T8 no extra stops (still 1)", stop_edge_count === 1);

    // ========================================
    // TEST 9: Multiple resets in sequence
    // ========================================
    for (int i = 0; i < 3; i++) begin
      rst_n = 0;
      repeat (2) @(posedge clk_sys);
      rst_n = 1;
      repeat (2) @(posedge clk_sys);
    end
    stop_edge_count = 0;
    pulse_start_async();
    @(posedge clk_ref_40m);
    @(negedge clk_ref_40m);
    repeat (4) @(posedge clk_sys);
    check("T9 functional after multiple resets", stop_edge_count === 1);

    // ========================================
    // SUMMARY
    // ========================================
    repeat (10) @(posedge clk_sys);
    $display("========================================");
    $display("STOP QUALIFIER STRESS: %0d PASS, %0d FAIL out of %0d",
             pass_count, fail_count, test_num);
    $display("========================================");
    if (fail_count > 0) $fatal(1, "STRESS TEST FAILED");
    $finish;
  end

  // Timeout watchdog
  initial begin
    #100_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
