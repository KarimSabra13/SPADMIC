`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_tx_src_data_flat_mapping_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic clk_sys;
  logic rst_n;
  logic [NARROW_W-1:0] src_data [SPADMIC_SRC_COUNT];
  wire [SPADMIC_SRC_COUNT-1:0] src_ready;
  wire [NARROW_W-1:0] word_data;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #3125 clk_sys = ~clk_sys;

  spadmic_event_bundle_tx dut (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .bundle_start_i(1'b0),
    .required_packet_mask_i('0),
    .source_pending_mask_i('0),
    .event_id_i('0),
    .src_valid_i('0),
    .src_ready_o(src_ready),
    // SPADMIC_TX_SRC_DATA_GENERATED_BEGIN ARRAY_CONNECTIONS src_data
    .src_data_i_s0_b0      (src_data[0][0]),
    .src_data_i_s0_b1      (src_data[0][1]),
    .src_data_i_s0_b2      (src_data[0][2]),
    .src_data_i_s0_b3      (src_data[0][3]),
    .src_data_i_s0_b4      (src_data[0][4]),
    .src_data_i_s0_b5      (src_data[0][5]),
    .src_data_i_s0_b6      (src_data[0][6]),
    .src_data_i_s0_b7      (src_data[0][7]),
    .src_data_i_s0_b8      (src_data[0][8]),
    .src_data_i_s0_b9      (src_data[0][9]),
    .src_data_i_s0_b10     (src_data[0][10]),
    .src_data_i_s0_b11     (src_data[0][11]),
    .src_data_i_s0_b12     (src_data[0][12]),
    .src_data_i_s0_b13     (src_data[0][13]),
    .src_data_i_s0_b14     (src_data[0][14]),
    .src_data_i_s0_b15     (src_data[0][15]),
    .src_data_i_s1_b0      (src_data[1][0]),
    .src_data_i_s1_b1      (src_data[1][1]),
    .src_data_i_s1_b2      (src_data[1][2]),
    .src_data_i_s1_b3      (src_data[1][3]),
    .src_data_i_s1_b4      (src_data[1][4]),
    .src_data_i_s1_b5      (src_data[1][5]),
    .src_data_i_s1_b6      (src_data[1][6]),
    .src_data_i_s1_b7      (src_data[1][7]),
    .src_data_i_s1_b8      (src_data[1][8]),
    .src_data_i_s1_b9      (src_data[1][9]),
    .src_data_i_s1_b10     (src_data[1][10]),
    .src_data_i_s1_b11     (src_data[1][11]),
    .src_data_i_s1_b12     (src_data[1][12]),
    .src_data_i_s1_b13     (src_data[1][13]),
    .src_data_i_s1_b14     (src_data[1][14]),
    .src_data_i_s1_b15     (src_data[1][15]),
    .src_data_i_s2_b0      (src_data[2][0]),
    .src_data_i_s2_b1      (src_data[2][1]),
    .src_data_i_s2_b2      (src_data[2][2]),
    .src_data_i_s2_b3      (src_data[2][3]),
    .src_data_i_s2_b4      (src_data[2][4]),
    .src_data_i_s2_b5      (src_data[2][5]),
    .src_data_i_s2_b6      (src_data[2][6]),
    .src_data_i_s2_b7      (src_data[2][7]),
    .src_data_i_s2_b8      (src_data[2][8]),
    .src_data_i_s2_b9      (src_data[2][9]),
    .src_data_i_s2_b10     (src_data[2][10]),
    .src_data_i_s2_b11     (src_data[2][11]),
    .src_data_i_s2_b12     (src_data[2][12]),
    .src_data_i_s2_b13     (src_data[2][13]),
    .src_data_i_s2_b14     (src_data[2][14]),
    .src_data_i_s2_b15     (src_data[2][15]),
    .src_data_i_s3_b0      (src_data[3][0]),
    .src_data_i_s3_b1      (src_data[3][1]),
    .src_data_i_s3_b2      (src_data[3][2]),
    .src_data_i_s3_b3      (src_data[3][3]),
    .src_data_i_s3_b4      (src_data[3][4]),
    .src_data_i_s3_b5      (src_data[3][5]),
    .src_data_i_s3_b6      (src_data[3][6]),
    .src_data_i_s3_b7      (src_data[3][7]),
    .src_data_i_s3_b8      (src_data[3][8]),
    .src_data_i_s3_b9      (src_data[3][9]),
    .src_data_i_s3_b10     (src_data[3][10]),
    .src_data_i_s3_b11     (src_data[3][11]),
    .src_data_i_s3_b12     (src_data[3][12]),
    .src_data_i_s3_b13     (src_data[3][13]),
    .src_data_i_s3_b14     (src_data[3][14]),
    .src_data_i_s3_b15     (src_data[3][15]),
    // SPADMIC_TX_SRC_DATA_GENERATED_END ARRAY_CONNECTIONS
    .src_sop_i('0),
    .src_eop_i('0),
    .word_valid_o(),
    .word_ready_i(1'b0),
    .word_data_o(word_data),
    .flush_o(),
    .completed_packet_mask_o(),
    .done_o(),
    .busy_o(),
    .idle_o(),
    .missing_source_error_o()
  );

  task automatic check(input string label, input logic condition);
    if (condition) begin
      $display("[PASS] %s", label);
      pass_count++;
    end else begin
      $display("[FAIL] %s", label);
      fail_count++;
    end
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    for (int source = 0; source < SPADMIC_SRC_COUNT; source++)
      src_data[source] = '0;

    for (int source = 0; source < SPADMIC_SRC_COUNT; source++) begin
      for (int bit_index = 0; bit_index < NARROW_W; bit_index++) begin
        for (int clear_source = 0; clear_source < SPADMIC_SRC_COUNT; clear_source++)
          src_data[clear_source] = '0;
        src_data[source][bit_index] = 1'b1;
        #1;
        for (int observed_source = 0;
             observed_source < SPADMIC_SRC_COUNT;
             observed_source++) begin
          check(
              $sformatf("s%0d_b%0d observed source %0d",
                        source, bit_index, observed_source),
              dut.src_data_i[observed_source] === src_data[observed_source]
          );
        end
      end
    end

    check("manifest source count", SPADMIC_SRC_COUNT == 4);
    check("manifest data width", NARROW_W == 16);
    $display("TX_SRC_DATA_MAPPING_RESULT pass=%0d fail=%0d", pass_count, fail_count);
    if (fail_count != 0)
      $fatal(1, "TX source-data scalar mapping failed");
    $display("All tests passed");
    $finish;
  end
endmodule

`default_nettype wire
