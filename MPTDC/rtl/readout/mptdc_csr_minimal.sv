`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.2 — Design Review Enhanced Vernier TDC
// File     : mptdc_csr_minimal.sv
// Purpose  : Minimal CSR register file — offline calibration, no LUTs
// Author   : Karim Sabra
// =============================================================================
// Register map (v2.2):
//   0x00  CSR_CTRL        RW  conv_arm[0], fifo_clr[1](SC), soft_rst[2](SC)
//   0x04  CSR_MODE        RW  mode_cfg[0], input_sel[1], out_mode[3:2]
//   0x08  CSR_MAX_HITS    RW  max_hits[3:0]
//   0x0C  CSR_WDT_CTX     RW  per-context watchdog timeout[15:0]
//   0x10  CSR_WDT_GLOBAL  RW  global watchdog timeout[15:0]
//   0x20  CSR_STATUS      R   ready[0], busy[1], ctx_state{0,1}[5:2],
//                              drain_state[7:6]
//   0x24  CSR_HIT_COUNT   R   last_hit_count[3:0], last_flags[7:4]
//   0x28  CSR_FIFO_STATUS R   fifo_level[6:0], fifo_full[7], fifo_empty[8]
//   0x2C  CSR_WDT_STATUS  R   wdt_global_trip_cnt[7:0]
//   0x30  CSR_CONV_COUNT  R   conv_count[31:0]
//   0x34  CSR_OVF_COUNT   R   ovf_count[15:0]
//
// v2.2 changes:
//   - CSR_WDT_CTX restored (was hardwired to 0 in v2.1)
// =============================================================================

module mptdc_csr_minimal
  import mptdc_pkg::*;
(
  // Clock / reset
  input  wire                       clk_sys,
  input  wire                       rst_n,          // async-assert, sync-deassert

  // CSR bus (simple valid/ready)
  input  wire                       csr_valid_i,
  input  wire                       csr_write_i,
  input  wire  [CSR_ADDR_W-1:0]    csr_addr_i,
  input  wire  [CSR_DATA_W-1:0]    csr_wdata_i,
  output logic                      csr_ready_o,
  output logic                      csr_rvalid_o,
  output logic [CSR_DATA_W-1:0]    csr_rdata_o,

  // Status from datapath (read-only registers)
  input  mptdc_pkg::mptdc_status_t  status_i,

  // Configuration to datapath
  output mptdc_pkg::mptdc_cfg_t     cfg_o,

  // Conv_arm: latched level (RW), cleared by soft_rst or explicit write
  output logic                      conv_arm_o,

  // Self-clearing command pulses
  output logic                      fifo_clr_pulse_o,
  output logic                      soft_rst_pulse_o
);

  // ===========================================================================
  // Always ready — single-cycle access
  // ===========================================================================
  assign csr_ready_o = 1'b1;

  // ===========================================================================
  // Configuration registers (reset defaults)
  // ===========================================================================
  mode_e                      r_mode_cfg;
  input_sel_e                 r_input_sel;
  out_mode_e                  r_out_mode;
  logic [MAX_HITS_W-1:0]     r_max_hits;
  logic [15:0]               r_wdt_ctx_timeout;    // v2.2: restored
  logic [15:0]               r_wdt_global_timeout;

  // Pack cfg output
  always_comb begin
    cfg_o.mode_cfg           = r_mode_cfg;
    cfg_o.input_sel          = r_input_sel;
    cfg_o.out_mode           = r_out_mode;
    cfg_o.max_hits           = r_max_hits;
    cfg_o.wdt_ctx_timeout    = r_wdt_ctx_timeout;   // v2.2: restored
    cfg_o.wdt_global_timeout = r_wdt_global_timeout;
  end

  // ===========================================================================
  // Write logic — conv_arm latched, fifo_clr/soft_rst self-clearing
  // ===========================================================================
  logic wr_en;
  assign wr_en = csr_valid_i & csr_write_i & csr_ready_o;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      conv_arm_o             <= 1'b0;
      fifo_clr_pulse_o       <= 1'b0;
      soft_rst_pulse_o       <= 1'b0;
      r_mode_cfg             <= MODE_MULTI_HIT;
      r_input_sel            <= INPUT_SPAD;
      r_out_mode             <= OUT_MODE_RAW_FEATURES;
      r_max_hits             <= MAX_HITS_W'(MAX_HITS);
      r_wdt_ctx_timeout      <= 16'd0;            // v2.2
      r_wdt_global_timeout   <= 16'd0;
    end else begin
      // Self-clearing pulses default to zero
      fifo_clr_pulse_o <= 1'b0;
      soft_rst_pulse_o <= 1'b0;

      if (wr_en) begin
        case (csr_addr_i)
          CSR_CTRL: begin
            conv_arm_o       <= csr_wdata_i[0];     // latched level
            fifo_clr_pulse_o <= csr_wdata_i[1];     // self-clearing
            soft_rst_pulse_o <= csr_wdata_i[2];     // self-clearing
          end

          CSR_MODE: begin
            r_mode_cfg  <= mode_e'(csr_wdata_i[0]);
            r_input_sel <= input_sel_e'(csr_wdata_i[1]);
            r_out_mode  <= out_mode_e'(csr_wdata_i[3:2]);
          end

          CSR_MAX_HITS: begin
            r_max_hits <= csr_wdata_i[MAX_HITS_W-1:0];
          end

          CSR_WDT_CTX: begin                        // v2.2: restored
            r_wdt_ctx_timeout <= csr_wdata_i[15:0];
          end

          CSR_WDT_GLOBAL: begin
            r_wdt_global_timeout <= csr_wdata_i[15:0];
          end

          default: ; // writes to read-only addresses are ignored
        endcase
      end

      // Soft reset clears conv_arm
      if (soft_rst_pulse_o)
        conv_arm_o <= 1'b0;
    end
  end

  // ===========================================================================
  // Read logic — combinational mux, registered rvalid + rdata
  // ===========================================================================
  logic                    rd_en;
  logic [CSR_DATA_W-1:0]  rd_data_next;

  assign rd_en = csr_valid_i & ~csr_write_i & csr_ready_o;

  always_comb begin
    rd_data_next = {CSR_DATA_W{1'b0}};

    case (csr_addr_i)
      // --- Writable registers (read-back) ---
      CSR_CTRL: begin
        rd_data_next[0] = conv_arm_o;    // conv_arm is readable
      end

      CSR_MODE: begin
        rd_data_next[0]   = r_mode_cfg;
        rd_data_next[1]   = r_input_sel;
        rd_data_next[3:2] = r_out_mode;
      end

      CSR_MAX_HITS: begin
        rd_data_next[MAX_HITS_W-1:0] = r_max_hits;
      end

      CSR_WDT_CTX: begin                              // v2.2: restored
        rd_data_next[15:0] = r_wdt_ctx_timeout;
      end

      CSR_WDT_GLOBAL: begin
        rd_data_next[15:0] = r_wdt_global_timeout;
      end

      // --- Read-only status registers ---
      CSR_STATUS: begin
        rd_data_next[0]   = status_i.ready;
        rd_data_next[1]   = status_i.busy;
        rd_data_next[3:2] = status_i.ctx_state_packed[1:0];
        rd_data_next[5:4] = status_i.ctx_state_packed[3:2];
        rd_data_next[7:6] = status_i.drain_state;
      end

      CSR_HIT_COUNT: begin
        rd_data_next[MAX_HITS_W-1:0]              = status_i.last_hit_count;
        rd_data_next[MAX_HITS_W+CONV_FLAGS_W-1 -: CONV_FLAGS_W] = status_i.last_flags;
      end

      CSR_FIFO_STATUS: begin
        rd_data_next[FIFO_LVL_W-1:0] = status_i.fifo_level;
        rd_data_next[FIFO_LVL_W]     = status_i.fifo_full;
        rd_data_next[FIFO_LVL_W+1]   = status_i.fifo_empty;
      end

      CSR_WDT_STATUS: begin
        rd_data_next[7:0]  = status_i.wdt_global_trip_cnt;
      end

      CSR_CONV_COUNT: begin
        rd_data_next = status_i.conv_count;
      end

      CSR_OVF_COUNT: begin
        rd_data_next[15:0] = status_i.ovf_count;
      end

      default: begin
        rd_data_next = '0;
      end
    endcase
  end

  // Register read response
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      csr_rvalid_o <= 1'b0;
      csr_rdata_o  <= '0;
    end else begin
      csr_rvalid_o <= rd_en;
      if (rd_en)
        csr_rdata_o <= rd_data_next;
      else
        csr_rdata_o <= '0;
    end
  end

endmodule

`default_nettype wire
