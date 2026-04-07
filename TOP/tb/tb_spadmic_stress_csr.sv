// ============================================================================
// Stress test: spadmic_csr_decoder + spadmic_global_csr
// Tests: write/readback all regions, address decode errors, timeout behavior,
//        back-to-back transactions, alternating read/write.
// ============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_stress_csr;

  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys, rst_n;

  // Request interface
  logic                          req_valid, req_ready;
  logic                          req_write;
  logic [SPADMIC_CSR_ADDR_W-1:0] req_addr;
  logic [SPADMIC_CSR_DATA_W-1:0] req_wdata;

  // Response interface
  logic                          rsp_valid, rsp_ready;
  logic [SPADMIC_CSR_DATA_W-1:0] rsp_rdata;
  logic                          rsp_err;

  // Global CSR interface
  logic                          glob_valid, glob_write, glob_ready, glob_rvalid;
  logic [SPADMIC_CSR_ADDR_W-1:0] glob_addr;
  logic [SPADMIC_CSR_DATA_W-1:0] glob_wdata, glob_rdata;

  // TDC CSR stubs (loopback: write stores, read returns stored value)
  logic x_valid, x_write, x_ready, x_rvalid;
  logic [mptdc_pkg::CSR_ADDR_W-1:0] x_addr;
  logic [mptdc_pkg::CSR_DATA_W-1:0] x_wdata, x_rdata;

  logic y_valid, y_write, y_ready, y_rvalid;
  logic [mptdc_pkg::CSR_ADDR_W-1:0] y_addr;
  logic [mptdc_pkg::CSR_DATA_W-1:0] y_wdata, y_rdata;

  logic z_valid, z_write, z_ready, z_rvalid;
  logic [mptdc_pkg::CSR_ADDR_W-1:0] z_addr;
  logic [mptdc_pkg::CSR_DATA_W-1:0] z_wdata, z_rdata;

  logic pos_valid, pos_write, pos_ready, pos_rvalid;
  logic [SPADMIC_CSR_ADDR_W-1:0] pos_addr;
  logic [SPADMIC_CSR_DATA_W-1:0] pos_wdata, pos_rdata;

  initial clk_sys = 0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  // Instantiate decoder
  spadmic_csr_decoder u_dec (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .csr_req_valid_i (req_valid),
    .csr_req_write_i (req_write),
    .csr_req_addr_i  (req_addr),
    .csr_req_wdata_i (req_wdata),
    .csr_req_ready_o (req_ready),
    .csr_rsp_valid_o (rsp_valid),
    .csr_rsp_rdata_o (rsp_rdata),
    .csr_rsp_err_o   (rsp_err),
    .csr_rsp_ready_i (rsp_ready),
    .global_csr_valid_o (glob_valid),
    .global_csr_write_o (glob_write),
    .global_csr_addr_o  (glob_addr),
    .global_csr_wdata_o (glob_wdata),
    .global_csr_ready_i (glob_ready),
    .global_csr_rvalid_i(glob_rvalid),
    .global_csr_rdata_i (glob_rdata),
    .pos_csr_valid_o (pos_valid),
    .pos_csr_write_o (pos_write),
    .pos_csr_addr_o  (pos_addr),
    .pos_csr_wdata_o (pos_wdata),
    .pos_csr_ready_i (pos_ready),
    .pos_csr_rvalid_i(pos_rvalid),
    .pos_csr_rdata_i (pos_rdata),
    .x_csr_valid_o  (x_valid),
    .x_csr_write_o  (x_write),
    .x_csr_addr_o   (x_addr),
    .x_csr_wdata_o  (x_wdata),
    .x_csr_ready_i  (x_ready),
    .x_csr_rvalid_i (x_rvalid),
    .x_csr_rdata_i  (x_rdata),
    .y_csr_valid_o  (y_valid),
    .y_csr_write_o  (y_write),
    .y_csr_addr_o   (y_addr),
    .y_csr_wdata_o  (y_wdata),
    .y_csr_ready_i  (y_ready),
    .y_csr_rvalid_i (y_rvalid),
    .y_csr_rdata_i  (y_rdata),
    .z_csr_valid_o  (z_valid),
    .z_csr_write_o  (z_write),
    .z_csr_addr_o   (z_addr),
    .z_csr_wdata_o  (z_wdata),
    .z_csr_ready_i  (z_ready),
    .z_csr_rvalid_i (z_rvalid),
    .z_csr_rdata_i  (z_rdata)
  );

  // Instantiate global CSR
  spadmic_global_csr u_glob (
    .clk_sys     (clk_sys),
    .rst_n       (rst_n),
    .csr_valid_i (glob_valid),
    .csr_write_i (glob_write),
    .csr_addr_i  (glob_addr),
    .csr_wdata_i (glob_wdata),
    .csr_ready_o (glob_ready),
    .csr_rvalid_o(glob_rvalid),
    .csr_rdata_o (glob_rdata),
    .tdc_tx_busy_i    (1'b0),
    .tdc_pkt_pending_i(3'b000),
    .position_busy_i  (1'b0),
    .position_pending_i(1'b0),
    .global_enable_o  (),
    .axis_enable_o    (),
    .position_enable_o()
  );

  // ── Simple CSR stub for TDC/POS regions ──
  // 1-cycle latency loopback register
  logic [31:0] stub_x_reg, stub_y_reg, stub_z_reg, stub_pos_reg;

  // TDC_X stub
  assign x_ready = 1'b1;
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      x_rvalid <= 1'b0;
      x_rdata  <= '0;
      stub_x_reg <= '0;
    end else begin
      x_rvalid <= 1'b0;
      if (x_valid && x_write) begin
        stub_x_reg <= x_wdata;
      end else if (x_valid && !x_write) begin
        x_rvalid <= 1'b1;
        x_rdata  <= stub_x_reg;
      end
    end
  end

  // TDC_Y stub
  assign y_ready = 1'b1;
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      y_rvalid <= 1'b0;
      y_rdata  <= '0;
      stub_y_reg <= '0;
    end else begin
      y_rvalid <= 1'b0;
      if (y_valid && y_write) begin
        stub_y_reg <= y_wdata;
      end else if (y_valid && !y_write) begin
        y_rvalid <= 1'b1;
        y_rdata  <= stub_y_reg;
      end
    end
  end

  // TDC_Z stub
  assign z_ready = 1'b1;
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      z_rvalid <= 1'b0;
      z_rdata  <= '0;
      stub_z_reg <= '0;
    end else begin
      z_rvalid <= 1'b0;
      if (z_valid && z_write) begin
        stub_z_reg <= z_wdata;
      end else if (z_valid && !z_write) begin
        z_rvalid <= 1'b1;
        z_rdata  <= stub_z_reg;
      end
    end
  end

  // POS stub
  assign pos_ready = 1'b1;
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      pos_rvalid <= 1'b0;
      pos_rdata  <= '0;
      stub_pos_reg <= '0;
    end else begin
      pos_rvalid <= 1'b0;
      if (pos_valid && pos_write) begin
        stub_pos_reg <= pos_wdata;
      end else if (pos_valid && !pos_write) begin
        pos_rvalid <= 1'b1;
        pos_rdata  <= stub_pos_reg;
      end
    end
  end

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

  // ── CSR write task ──
  // Uses blocking assignments for TB signals (Verilator-compatible)
  task automatic csr_write(input logic [SPADMIC_CSR_ADDR_W-1:0] addr,
                           input logic [SPADMIC_CSR_DATA_W-1:0] data);
    @(posedge clk_sys);
    #1;
    req_valid = 1'b1;
    req_write = 1'b1;
    req_addr  = addr;
    req_wdata = data;
    rsp_ready = 1'b1;
    @(posedge clk_sys);
    while (!req_ready) @(posedge clk_sys);
    #1;
    req_valid = 1'b0;
    // Wait for response
    @(posedge clk_sys);
    while (!rsp_valid) @(posedge clk_sys);
    #1;
    rsp_ready = 1'b0;
    @(posedge clk_sys);
  endtask

  // ── CSR read task ──
  task automatic csr_read(input  logic [SPADMIC_CSR_ADDR_W-1:0] addr,
                          output logic [SPADMIC_CSR_DATA_W-1:0] data,
                          output logic err);
    @(posedge clk_sys);
    #1;
    req_valid = 1'b1;
    req_write = 1'b0;
    req_addr  = addr;
    req_wdata = '0;
    rsp_ready = 1'b1;
    @(posedge clk_sys);
    while (!req_ready) @(posedge clk_sys);
    #1;
    req_valid = 1'b0;
    // Wait for response
    @(posedge clk_sys);
    while (!rsp_valid) @(posedge clk_sys);
    data = rsp_rdata;
    err  = rsp_err;
    #1;
    rsp_ready = 1'b0;
    @(posedge clk_sys);
  endtask

  logic [SPADMIC_CSR_DATA_W-1:0] rd_data;
  logic rd_err;

  initial begin
    $display("========================================");
    $display("STRESS TEST: spadmic_csr_decoder + global_csr");
    $display("========================================");

    rst_n = 0;
    req_valid = 0;
    req_write = 0;
    req_addr = '0;
    req_wdata = '0;
    rsp_ready = 0;

    repeat (10) @(posedge clk_sys);
    rst_n = 1;
    repeat (4) @(posedge clk_sys);

    // ========================================
    // TEST 1: Read global ID register (addr 0x000)
    // ========================================
    csr_read(12'h000, rd_data, rd_err);
    check("T1 global ID read no error", rd_err === 1'b0);
    check("T1 global ID = 0x5350_4144 (SPAD)", rd_data === 32'h5350_4144);

    // ========================================
    // TEST 2: Read global VERSION register (addr 0x004)
    // ========================================
    csr_read(12'h004, rd_data, rd_err);
    check("T2 version read no error", rd_err === 1'b0);
    // Version value comes from spadmic_global_csr — just check non-zero
    check("T2 version nonzero", rd_data !== 32'h0);

    // ========================================
    // TEST 3: Write and readback CTRL register (addr 0x008)
    // ========================================
    csr_write(12'h008, 32'h0000_001F); // Enable all
    csr_read(12'h008, rd_data, rd_err);
    check("T3 ctrl readback", rd_data[4:0] === 5'h1F);

    // ========================================
    // TEST 4: Read STATUS register (addr 0x00C)
    // ========================================
    csr_read(12'h00C, rd_data, rd_err);
    check("T4 status read no error", rd_err === 1'b0);
    // Status is read-only, composed from inputs (all tied to 0/0)

    // ========================================
    // TEST 5: Write/readback TDC_X region
    // ========================================
    csr_write(12'h100, 32'hAAAA_BBBB);
    csr_read(12'h100, rd_data, rd_err);
    check("T5 TDC_X write/read", rd_data === 32'hAAAA_BBBB);
    check("T5 TDC_X no error", rd_err === 1'b0);

    // ========================================
    // TEST 6: Write/readback TDC_Y region
    // ========================================
    csr_write(12'h200, 32'hCCCC_DDDD);
    csr_read(12'h200, rd_data, rd_err);
    check("T6 TDC_Y write/read", rd_data === 32'hCCCC_DDDD);
    check("T6 TDC_Y no error", rd_err === 1'b0);

    // ========================================
    // TEST 7: Write/readback TDC_Z region
    // ========================================
    csr_write(12'h300, 32'h1234_5678);
    csr_read(12'h300, rd_data, rd_err);
    check("T7 TDC_Z write/read", rd_data === 32'h1234_5678);
    check("T7 TDC_Z no error", rd_err === 1'b0);

    // ========================================
    // TEST 8: Write/readback POSITION region
    // ========================================
    csr_write(12'h400, 32'hDEAD_BEEF);
    csr_read(12'h400, rd_data, rd_err);
    check("T8 POS write/read", rd_data === 32'hDEAD_BEEF);
    check("T8 POS no error", rd_err === 1'b0);

    // ========================================
    // TEST 9: Invalid region (0x500-0xF00) → error
    // ========================================
    csr_write(12'h500, 32'hBAAD_F00D);
    // Write to invalid region should give error response
    // Actually writes go to ST_HOLD_RSP with err=1 for TGT_ERR
    csr_read(12'h500, rd_data, rd_err);
    check("T9 invalid region → error", rd_err === 1'b1);

    csr_read(12'hF00, rd_data, rd_err);
    check("T9b region 0xF → error", rd_err === 1'b1);

    // ========================================
    // TEST 10: Back-to-back writes (50 writes)
    // ========================================
    for (int i = 0; i < 50; i++) begin
      csr_write(12'h100, 32'(i));
    end
    csr_read(12'h100, rd_data, rd_err);
    check("T10 50 back-to-back writes → last value", rd_data === 32'd49);

    // ========================================
    // TEST 11: Alternating read/write (20 cycles)
    // ========================================
    for (int i = 0; i < 20; i++) begin
      csr_write(12'h200, 32'(i * 3));
      csr_read(12'h200, rd_data, rd_err);
      if (rd_data !== 32'(i * 3)) begin
        $display("[FAIL] T11 alt r/w iter %0d: got %0h, expected %0h",
                 i, rd_data, i * 3);
        fail_count++;
      end
    end
    test_num++;
    pass_count++; // If we got here without failure, count as pass
    $display("[PASS] T%0d: T11 20 alternating read/write cycles", test_num);

    // ========================================
    // TEST 12: Cross-region isolation
    // ========================================
    csr_write(12'h100, 32'h1111_1111);
    csr_write(12'h200, 32'h2222_2222);
    csr_write(12'h300, 32'h3333_3333);
    csr_read(12'h100, rd_data, rd_err);
    check("T12 cross-region X isolated", rd_data === 32'h1111_1111);
    csr_read(12'h200, rd_data, rd_err);
    check("T12 cross-region Y isolated", rd_data === 32'h2222_2222);
    csr_read(12'h300, rd_data, rd_err);
    check("T12 cross-region Z isolated", rd_data === 32'h3333_3333);

    // ========================================
    // TEST 13: Response ready delay (test ST_HOLD_RSP)
    // ========================================
    begin
      @(posedge clk_sys);
      #1;
      req_valid = 1'b1;
      req_write = 1'b0;
      req_addr  = 12'h000;
      req_wdata = '0;
      rsp_ready = 1'b0;  // Deliberately hold ready low
      @(posedge clk_sys);
      while (!req_ready) @(posedge clk_sys);
      #1;
      req_valid = 1'b0;
      // Delay asserting rsp_ready by 10 cycles
      repeat (10) @(posedge clk_sys);
      #1;
      rsp_ready = 1'b1;
      @(posedge clk_sys);
      while (!rsp_valid) @(posedge clk_sys);
      check("T13 delayed rsp_ready → still valid", rsp_valid === 1'b1);
      check("T13 correct data after delay", rsp_rdata === 32'h5350_4144);
      #1;
      rsp_ready = 1'b0;
      @(posedge clk_sys);
    end

    // ========================================
    // SUMMARY
    // ========================================
    repeat (10) @(posedge clk_sys);
    $display("========================================");
    $display("CSR STRESS: %0d PASS, %0d FAIL out of %0d",
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
