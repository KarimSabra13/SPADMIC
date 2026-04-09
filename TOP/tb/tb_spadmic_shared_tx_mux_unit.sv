`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_shared_tx_mux_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic shared_ready;
  logic tdc_valid;
  logic [NARROW_W-1:0] tdc_data;
  logic pos_valid;
  logic [NARROW_W-1:0] pos_data;
  spadmic_tx_sel_e tx_sel;

  wire tdc_ready;
  wire pos_ready;
  wire shared_valid;
  wire [NARROW_W-1:0] shared_data;

  int pass_count;
  int fail_count;

  spadmic_shared_tx_mux dut (
    .tx_sel_i      (tx_sel),
    .tdc_valid_i   (tdc_valid),
    .tdc_data_i    (tdc_data),
    .tdc_ready_o   (tdc_ready),
    .pos_valid_i   (pos_valid),
    .pos_data_i    (pos_data),
    .pos_ready_o   (pos_ready),
    .shared_ready_i(shared_ready),
    .shared_valid_o(shared_valid),
    .shared_data_o (shared_data)
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
    pass_count   = 0;
    fail_count   = 0;
    shared_ready = 1'b0;
    tdc_valid    = 1'b0;
    tdc_data     = '0;
    pos_valid    = 1'b0;
    pos_data     = '0;
    tx_sel       = SPADMIC_TX_TDC;

    #1;
    tdc_valid    = 1'b1;
    tdc_data     = 16'h8123;
    pos_valid    = 1'b1;
    pos_data     = 16'hCAFE;
    #1;
    check("TDC select holds valid high under backpressure", shared_valid === 1'b1);
    check("TDC select keeps TDC data under backpressure", shared_data === 16'h8123);
    check("TDC select blocks ready while shared stalls", tdc_ready === 1'b0);
    check("TDC select still blocks position ready", pos_ready === 1'b0);

    shared_ready = 1'b1;
    #1;
    check("TDC path selected drives shared valid", shared_valid === 1'b1);
    check("TDC path selected drives shared data", shared_data === 16'h8123);
    check("TDC path selected returns ready", tdc_ready === 1'b1);
    check("TDC path selected blocks position ready", pos_ready === 1'b0);

    tdc_valid = 1'b0;
    #1;
    check("Position data stays hidden before boundary switch", shared_valid === 1'b0);
    check("TDC ownership still blocks position ready before switch", pos_ready === 1'b0);

    tx_sel   = SPADMIC_TX_POSITION;
    pos_data = 16'hA5A5;
    #1;
    check("POS path selected drives shared valid", shared_valid === 1'b1);
    check("POS path selected drives shared data", shared_data === 16'hA5A5);
    check("POS path selected returns ready", pos_ready === 1'b1);
    check("POS path selected blocks TDC ready", tdc_ready === 1'b0);

    shared_ready = 1'b0;
    #1;
    check("POS path keeps valid high under backpressure", shared_valid === 1'b1);
    check("POS path keeps data stable under backpressure", shared_data === 16'hA5A5);
    check("POS path drops ready while shared stalls", pos_ready === 1'b0);
    check("Backpressured POS path still blocks TDC ready", tdc_ready === 1'b0);

    shared_ready = 1'b1;
    pos_valid    = 1'b0;
    tdc_valid    = 1'b1;
    tdc_data     = 16'h55AA;
    #1;
    check("TDC data stays hidden before switch-back", shared_valid === 1'b0);
    check("Position select still blocks TDC ready before switch-back", tdc_ready === 1'b0);

    tx_sel = SPADMIC_TX_TDC;
    #1;
    check("TDC path resumes cleanly after idle-boundary switch", shared_valid === 1'b1);
    check("TDC path restores shared data after switch-back", shared_data === 16'h55AA);
    check("TDC path regains ready after switch-back", tdc_ready === 1'b1);
    check("Switch-back keeps position ready low", pos_ready === 1'b0);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_shared_tx_mux_unit: %0d failures", fail_count);

    $display("tb_spadmic_shared_tx_mux_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end
endmodule

`default_nettype wire
