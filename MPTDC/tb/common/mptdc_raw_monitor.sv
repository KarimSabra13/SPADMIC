// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : mptdc_raw_monitor.sv
// Purpose : Passive monitor for the 16-bit narrow output stream.
// Author  : Karim Sabra
// Notes   : Checks header/EOC framing and hit-count-driven word counts without
//           driving narrow_ready.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module mptdc_raw_monitor
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;
(
  input wire                   clk_sys,
  input wire                   rst_n,

  // Narrow bus (observe only)
  input wire                   narrow_valid_i,
  input wire                   narrow_ready_i,
  input wire [NARROW_W-1:0]   narrow_data_i
);

  // ── Internal state ────────────────────────────────────────────────
  typedef enum logic [1:0] {
    MON_IDLE     = 2'd0,
    MON_HITS     = 2'd1,
    MON_WAIT_EOC = 2'd2
  } mon_state_e;

  mon_state_e  mon_state;
  int unsigned expected_words;
  int unsigned word_idx;
  int unsigned pkt_count;
  int unsigned total_hits;

  logic [NARROW_W-1:0] header_latch;

  // ── Monitor logic ─────────────────────────────────────────────────
  // ── Combinational pre-decode ────────────────────────────────────
  logic [NARROW_W-1:0] mon_w;
  int unsigned          mon_hc;
  out_mode_e            mon_mode;
  int unsigned          mon_wph;

  assign mon_w = narrow_data_i;
  always_comb begin
    mon_hc   = header_hit_count(mon_w);
    mon_mode = header_out_mode(mon_w);
    mon_wph  = 2;
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      mon_state      <= MON_IDLE;
      expected_words <= 0;
      word_idx       <= 0;
      pkt_count      <= 0;
      total_hits     <= 0;
      header_latch   <= '0;
    end else if (narrow_valid_i && narrow_ready_i) begin
      case (mon_state)
        MON_IDLE: begin
          if (is_header(mon_w)) begin
            header_latch   <= mon_w;
            expected_words <= mon_hc * mon_wph;
            word_idx       <= 0;
            total_hits     <= total_hits + mon_hc;
            mon_state <= (mon_hc == 0) ? MON_WAIT_EOC : MON_HITS;
            $display("[MON] t=%0t PKT#%0d HEADER: ctx=%0d phase0=%b hits=%0d flags=%04b mode=%0d",
                     $time, pkt_count, header_ctx_id(mon_w), header_phase0(mon_w),
                     mon_hc, header_flags(mon_w), mon_mode);
          end else if (is_eoc(mon_w)) begin
            $error("[MON] t=%0t Unexpected EOC without header!", $time);
          end
        end

        MON_HITS: begin
          word_idx <= word_idx + 1;
          if ((word_idx + 1) >= expected_words)
            mon_state <= MON_WAIT_EOC;
        end

        MON_WAIT_EOC: begin
          if (is_eoc(mon_w)) begin
            pkt_count <= pkt_count + 1;
            mon_state <= MON_IDLE;
            $display("[MON] t=%0t PKT#%0d EOC: conv_id=%0d",
                     $time, pkt_count, eoc_conv_id(mon_w));
          end else begin
            $error("[MON] t=%0t Expected EOC but got 0x%04h", $time, mon_w);
          end
        end

        default: mon_state <= MON_IDLE;
      endcase
    end
  end

  // ── Final summary ─────────────────────────────────────────────────
  final begin
    $display("[MON] SUMMARY: %0d packets, %0d total hits", pkt_count, total_hits);
  end

endmodule

`default_nettype wire
