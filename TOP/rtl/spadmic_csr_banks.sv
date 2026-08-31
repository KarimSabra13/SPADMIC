// =============================================================================
// SPADMIC CSR ABI 1.0 block-owned register banks.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_csr_system_bank (
  input  logic clk_sys,
  input  logic rst_n,
  input  logic req_valid_i,
  input  logic req_write_i,
  input  logic [15:0] req_addr_i,
  input  logic [31:0] req_wdata_i,
  input  logic safe_idle_i,
  input  logic [15:0] reset_width_i,
  input  logic [6:0] page_fault_summary_i,
  input  logic access_error_event_i,
  input  logic access_error_write_i,
  input  logic [15:0] access_error_addr_i,
  input  logic [31:0] access_error_wdata_i,
  input  logic [7:0] access_error_cause_i,
  output logic global_enable_o,
  output spadmic_pkg::spadmic_operating_mode_e requested_mode_o,
  output spadmic_pkg::spadmic_operating_mode_e active_mode_o,
  output logic [2:0] requested_axis_mask_o,
  output logic [2:0] active_axis_mask_o,
  output logic auto_reset_enable_o,
  output logic [mptdc_pkg::MAX_HITS_W-1:0] tdc_max_hits_o,
  output logic [7:0] tdc_ro_slow_code_o,
  output logic [7:0] tdc_ro_fast_code_o,
  output logic tdc_soft_reset_o,
  output logic tdc_fifo_clr_o,
  output logic [2:0] calib_axis_mask_o,
  output logic clear_error_counters_o,
  output logic cfg_accept_o,
  output logic fault_summary_o,
  output logic rsp_valid_o,
  output logic [31:0] rsp_rdata_o,
  output logic rsp_err_o,
  output logic [7:0] rsp_cause_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;
  import spadmic_csr_map_pkg::*;

  logic [7:0] access_fault_q;
  logic [15:0] access_last_addr_q;
  logic [31:0] access_last_wdata_q;
  logic [7:0] access_last_cause_q;
  logic access_last_write_q;
  logic [31:0] access_error_count_q;
  wire config_safe = safe_idle_i && !global_enable_o;
  wire [6:0] global_faults = page_fault_summary_i | {6'b0, fault_summary_o};

  function automatic logic valid_mode(input logic [2:0] mode);
    return (mode <= SPADMIC_MODE_CALIBRATION);
  endfunction

  assign fault_summary_o = |access_fault_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      global_enable_o <= 1'b0;
      requested_mode_o <= SPADMIC_MODE_DISABLED;
      active_mode_o <= SPADMIC_MODE_DISABLED;
      requested_axis_mask_o <= 3'b111;
      active_axis_mask_o <= 3'b111;
      auto_reset_enable_o <= 1'b1;
      tdc_max_hits_o <= MAX_HITS_W'(MAX_HITS);
      tdc_ro_slow_code_o <= 8'h00;
      tdc_ro_fast_code_o <= 8'h00;
      tdc_soft_reset_o <= 1'b0;
      tdc_fifo_clr_o <= 1'b0;
      calib_axis_mask_o <= 3'b111;
      clear_error_counters_o <= 1'b0;
      cfg_accept_o <= 1'b0;
      access_fault_q <= '0;
      access_last_addr_q <= '0;
      access_last_wdata_q <= '0;
      access_last_cause_q <= CSR_CAUSE_NONE;
      access_last_write_q <= 1'b0;
      access_error_count_q <= '0;
      rsp_valid_o <= 1'b0;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
    end else begin
      spadmic_operating_mode_e next_mode;
      logic [2:0] next_axis_mask;
      logic ctrl_value_valid;

      next_mode = spadmic_operating_mode_e'(req_wdata_i[3:1]);
      next_axis_mask = req_wdata_i[6:4];
      ctrl_value_valid = valid_mode(req_wdata_i[3:1]) &&
                         ((!req_wdata_i[0] && (next_mode == SPADMIC_MODE_DISABLED)) ||
                          (req_wdata_i[0] && (next_mode != SPADMIC_MODE_DISABLED))) &&
                         (((next_mode != SPADMIC_MODE_TDC_ONLY) &&
                           (next_mode != SPADMIC_MODE_BOTH)) ||
                          (next_axis_mask == 3'b111)) &&
                         ((next_mode != SPADMIC_MODE_CALIBRATION) ||
                          (calib_axis_mask_o != 3'b000)) &&
                         (!req_wdata_i[0] ||
                          (next_mode == SPADMIC_MODE_CALIBRATION) ||
                          (reset_width_i != 16'd0));

      rsp_valid_o <= req_valid_i;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
      tdc_soft_reset_o <= 1'b0;
      tdc_fifo_clr_o <= 1'b0;
      clear_error_counters_o <= 1'b0;
      cfg_accept_o <= 1'b0;

      if (req_valid_i) begin
        unique case (req_addr_i)
          CSR_CHIP_ID: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else rsp_rdata_o <= SPADMIC_CHIP_ID_VALUE;
          end
          CSR_ABI_VERSION: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else rsp_rdata_o <= SPADMIC_CSR_ABI_VERSION_VALUE;
          end
          CSR_GLOBAL_CTRL: begin
            if (req_write_i) begin
              if (!safe_idle_i) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
              end else if (!ctrl_value_valid) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_INVALID_VALUE;
              end else begin
                global_enable_o <= req_wdata_i[0];
                requested_mode_o <= next_mode;
                active_mode_o <= next_mode;
                requested_axis_mask_o <= (next_mode == SPADMIC_MODE_CALIBRATION)
                                        ? calib_axis_mask_o : next_axis_mask;
                active_axis_mask_o <= (next_mode == SPADMIC_MODE_CALIBRATION)
                                     ? calib_axis_mask_o : next_axis_mask;
                auto_reset_enable_o <= req_wdata_i[7];
                cfg_accept_o <= 1'b1;
              end
            end else begin
              rsp_rdata_o[0] <= global_enable_o;
              rsp_rdata_o[3:1] <= requested_mode_o;
              rsp_rdata_o[6:4] <= requested_axis_mask_o;
              rsp_rdata_o[7] <= auto_reset_enable_o;
            end
          end
          CSR_GLOBAL_STATUS: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else begin
              rsp_rdata_o[0] <= global_enable_o;
              rsp_rdata_o[3:1] <= active_mode_o;
              rsp_rdata_o[6:4] <= active_axis_mask_o;
              rsp_rdata_o[7] <= safe_idle_i;
            end
          end
          CSR_GLOBAL_FAULT: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else rsp_rdata_o[6:0] <= global_faults;
          end
          CSR_MAINT_CMD: begin
            if (req_write_i) begin
              if (req_wdata_i[0] && !config_safe) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
              end else if (req_wdata_i[0]) begin
                clear_error_counters_o <= 1'b1;
                access_error_count_q <= '0;
                cfg_accept_o <= 1'b1;
              end
            end
          end
          CSR_TDC_SHARED_CFG: begin
            if (req_write_i) begin
              if (!config_safe) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
              end else if (req_wdata_i[MAX_HITS_W-1:0] == '0) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_INVALID_VALUE;
              end else begin
                tdc_max_hits_o <= req_wdata_i[MAX_HITS_W-1:0];
                tdc_ro_slow_code_o <= req_wdata_i[15:8];
                tdc_ro_fast_code_o <= req_wdata_i[23:16];
                cfg_accept_o <= 1'b1;
              end
            end else begin
              rsp_rdata_o[MAX_HITS_W-1:0] <= tdc_max_hits_o;
              rsp_rdata_o[15:8] <= tdc_ro_slow_code_o;
              rsp_rdata_o[23:16] <= tdc_ro_fast_code_o;
            end
          end
          CSR_TDC_SHARED_CMD: begin
            if (req_write_i) begin
              if (!config_safe) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
              end else begin
                tdc_soft_reset_o <= req_wdata_i[0];
                tdc_fifo_clr_o <= req_wdata_i[1];
                cfg_accept_o <= |req_wdata_i[1:0];
              end
            end
          end
          CSR_CALIB_AXIS_MASK: begin
            if (req_write_i) begin
              if (!config_safe) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
              end else if (req_wdata_i[2:0] == 3'b000) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_INVALID_VALUE;
              end else begin
                calib_axis_mask_o <= req_wdata_i[2:0];
                cfg_accept_o <= 1'b1;
              end
            end else rsp_rdata_o[2:0] <= calib_axis_mask_o;
          end
          CSR_ACCESS_STATUS: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else begin
              rsp_rdata_o[0] <= |access_fault_q;
              rsp_rdata_o[1] <= access_last_write_q;
              rsp_rdata_o[15:8] <= access_last_cause_q;
            end
          end
          CSR_ACCESS_FAULT: begin
            if (req_write_i)
              access_fault_q <= access_fault_q & ~req_wdata_i[7:0];
            else rsp_rdata_o[7:0] <= access_fault_q;
          end
          CSR_ACCESS_LAST_INFO: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else begin
              rsp_rdata_o[15:0] <= access_last_addr_q;
              rsp_rdata_o[23:16] <= access_last_cause_q;
              rsp_rdata_o[24] <= access_last_write_q;
            end
          end
          CSR_ACCESS_LAST_WDATA: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else rsp_rdata_o <= access_last_wdata_q;
          end
          CSR_ACCESS_ERROR_COUNT: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else rsp_rdata_o <= access_error_count_q;
          end
          default: begin
            rsp_err_o <= 1'b1;
            rsp_cause_o <= CSR_CAUSE_UNMAPPED;
          end
        endcase
      end

      if (access_error_event_i) begin
        if ((access_error_cause_i >= CSR_CAUSE_MISALIGNED) &&
            (access_error_cause_i <= CSR_CAUSE_I2C_RESET_ABORT))
          access_fault_q[access_error_cause_i-1'b1] <= 1'b1;
        access_last_addr_q <= access_error_addr_i;
        access_last_wdata_q <= access_error_wdata_i;
        access_last_cause_q <= access_error_cause_i;
        access_last_write_q <= access_error_write_i;
        access_error_count_q <= csr_sat_inc32(access_error_count_q);
      end
    end
  end
endmodule

module spadmic_csr_tdc_bank #(
  parameter logic [3:0] PAGE = 4'h1
) (
  input logic clk_sys,
  input logic rst_n,
  input logic req_valid_i,
  input logic req_write_i,
  input logic [15:0] req_addr_i,
  input logic [31:0] req_wdata_i,
  input logic clear_error_counters_i,
  input logic ready_i,
  input logic busy_i,
  input logic fifo_full_i,
  input logic stop_armed_i,
  input logic packet_active_i,
  input logic packet_pending_i,
  output logic fault_summary_o,
  output logic rsp_valid_o,
  output logic [31:0] rsp_rdata_o,
  output logic rsp_err_o,
  output logic [7:0] rsp_cause_o
);
  import spadmic_csr_map_pkg::*;
  logic fifo_full_q;
  logic fifo_full_sticky_q;
  logic [31:0] error_count_q;
  wire [11:0] local_addr = req_addr_i[11:0];
  assign fault_summary_o = fifo_full_sticky_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      fifo_full_q <= 1'b0;
      fifo_full_sticky_q <= 1'b0;
      error_count_q <= '0;
      rsp_valid_o <= 1'b0;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
    end else begin
      fifo_full_q <= fifo_full_i;
      rsp_valid_o <= req_valid_i;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
      if (clear_error_counters_i)
        error_count_q <= '0;
      if (fifo_full_i && !fifo_full_q) begin
        fifo_full_sticky_q <= 1'b1;
        error_count_q <= csr_sat_inc32(error_count_q);
      end
      if (req_valid_i) begin
        unique case (local_addr)
          12'h000: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else begin
              rsp_rdata_o[0] <= ready_i;
              rsp_rdata_o[1] <= busy_i;
              rsp_rdata_o[2] <= fifo_full_i;
              rsp_rdata_o[3] <= stop_armed_i;
              rsp_rdata_o[4] <= packet_active_i;
              rsp_rdata_o[5] <= packet_pending_i;
              rsp_rdata_o[11:8] <= PAGE;
            end
          end
          12'h004: begin
            if (req_write_i)
              fifo_full_sticky_q <= fifo_full_sticky_q & ~req_wdata_i[0];
            else rsp_rdata_o[0] <= fifo_full_sticky_q;
          end
          12'h008: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else rsp_rdata_o <= error_count_q;
          end
          default: begin
            rsp_err_o <= 1'b1;
            rsp_cause_o <= CSR_CAUSE_UNMAPPED;
          end
        endcase
      end
    end
  end
endmodule

module spadmic_csr_position_bank (
  input logic clk_sys,
  input logic rst_n,
  input logic req_valid_i,
  input logic req_write_i,
  input logic [15:0] req_addr_i,
  input logic [31:0] req_wdata_i,
  input logic config_safe_i,
  input logic clear_error_counters_i,
  input logic packet_pending_i,
  input logic packet_busy_i,
  input logic snapshot_captured_i,
  input logic packet_drop_i,
  output spadmic_pkg::spadmic_pos_mode_e position_mode_o,
  output logic [spadmic_pkg::SPADMIC_LINE_COUNT_W-1:0] gap_threshold_o,
  output logic [spadmic_pkg::SPADMIC_LINE_COUNT_W-1:0] min_cluster_span_o,
  output logic fault_summary_o,
  output logic rsp_valid_o,
  output logic [31:0] rsp_rdata_o,
  output logic rsp_err_o,
  output logic [7:0] rsp_cause_o
);
  import spadmic_pkg::*;
  import spadmic_csr_map_pkg::*;
  logic drop_q;
  logic drop_sticky_q;
  logic [31:0] drop_count_q;
  assign fault_summary_o = drop_sticky_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      position_mode_o <= SPADMIC_POS_MODE_CLUSTER;
      gap_threshold_o <= SPADMIC_LINE_COUNT_W'(2);
      min_cluster_span_o <= SPADMIC_LINE_COUNT_W'(1);
      drop_q <= 1'b0;
      drop_sticky_q <= 1'b0;
      drop_count_q <= '0;
      rsp_valid_o <= 1'b0;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
    end else begin
      drop_q <= packet_drop_i;
      rsp_valid_o <= req_valid_i;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
      if (clear_error_counters_i)
        drop_count_q <= '0;
      if (packet_drop_i && !drop_q) begin
        drop_sticky_q <= 1'b1;
        drop_count_q <= csr_sat_inc32(drop_count_q);
      end
      if (req_valid_i) begin
        unique case (req_addr_i)
          CSR_POSITION_CFG: begin
            if (req_write_i) begin
              if (!config_safe_i) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
              end else if ((req_wdata_i[14:8] == 7'd0) ||
                           (req_wdata_i[14:8] > SPADMIC_LINE_W) ||
                           (req_wdata_i[7:1] > SPADMIC_LINE_W)) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_INVALID_VALUE;
              end else begin
                position_mode_o <= spadmic_pos_mode_e'(req_wdata_i[0]);
                gap_threshold_o <= SPADMIC_LINE_COUNT_W'(req_wdata_i[7:1]);
                min_cluster_span_o <= SPADMIC_LINE_COUNT_W'(req_wdata_i[14:8]);
              end
            end else begin
              rsp_rdata_o[0] <= position_mode_o;
              rsp_rdata_o[7:1] <= 7'(gap_threshold_o);
              rsp_rdata_o[14:8] <= 7'(min_cluster_span_o);
            end
          end
          CSR_POSITION_STATUS: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else begin
              rsp_rdata_o[0] <= packet_pending_i;
              rsp_rdata_o[1] <= packet_busy_i;
              rsp_rdata_o[2] <= snapshot_captured_i;
            end
          end
          CSR_POSITION_FAULT: begin
            if (req_write_i)
              drop_sticky_q <= drop_sticky_q & ~req_wdata_i[0];
            else rsp_rdata_o[0] <= drop_sticky_q;
          end
          CSR_POSITION_DROP_COUNT: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else rsp_rdata_o <= drop_count_q;
          end
          default: begin
            rsp_err_o <= 1'b1;
            rsp_cause_o <= CSR_CAUSE_UNMAPPED;
          end
        endcase
      end
    end
  end
endmodule

module spadmic_csr_event_bank (
  input logic clk_sys,
  input logic rst_n,
  input logic req_valid_i,
  input logic req_write_i,
  input logic [15:0] req_addr_i,
  input logic [31:0] req_wdata_i,
  input logic config_safe_i,
  input logic clear_error_counters_i,
  input logic event_busy_i,
  input logic [13:0] event_id_i,
  input logic [3:0] required_packet_mask_i,
  input logic [3:0] completed_packet_mask_i,
  input logic [3:0] required_reset_ack_mask_i,
  input logic [3:0] observed_reset_ack_mask_i,
  input logic event_reject_i,
  input logic snapshot_valid_i,
  input logic snapshot_busy_i,
  input logic snapshot_timeout_i,
  input logic snapshot_overlap_i,
  input logic snapshot_reject_i,
  input logic snapshot_rearm_ready_i,
  input logic [63:0] snapshot_R_i,
  input logic [63:0] snapshot_Y_i,
  input logic [63:0] snapshot_B_i,
  input logic reset_busy_i,
  input logic reset_done_i,
  input logic reset_disabled_i,
  output logic [15:0] settle_cycles_o,
  output logic [15:0] watchdog_cycles_o,
  output logic [15:0] reset_width_o,
  output logic snapshot_clear_o,
  output logic fault_summary_o,
  output logic rsp_valid_o,
  output logic [31:0] rsp_rdata_o,
  output logic rsp_err_o,
  output logic [7:0] rsp_cause_o
);
  import spadmic_csr_map_pkg::*;
  logic [3:0] fault_q;
  logic event_reject_q;
  logic snapshot_timeout_q;
  logic snapshot_overlap_q;
  logic snapshot_reject_q;
  logic reset_done_q;
  logic [31:0] event_reject_count_q;
  logic [31:0] snapshot_timeout_count_q;
  logic [31:0] snapshot_overlap_count_q;
  logic [31:0] snapshot_reject_count_q;
  logic [31:0] reset_disabled_count_q;
  assign fault_summary_o = |fault_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      settle_cycles_o <= 16'd2;
      watchdog_cycles_o <= 16'd64;
      reset_width_o <= 16'd0;
      snapshot_clear_o <= 1'b0;
      fault_q <= '0;
      event_reject_q <= 1'b0;
      snapshot_timeout_q <= 1'b0;
      snapshot_overlap_q <= 1'b0;
      snapshot_reject_q <= 1'b0;
      reset_done_q <= 1'b0;
      event_reject_count_q <= '0;
      snapshot_timeout_count_q <= '0;
      snapshot_overlap_count_q <= '0;
      snapshot_reject_count_q <= '0;
      reset_disabled_count_q <= '0;
      rsp_valid_o <= 1'b0;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
    end else begin
      event_reject_q <= event_reject_i;
      snapshot_timeout_q <= snapshot_timeout_i;
      snapshot_overlap_q <= snapshot_overlap_i;
      snapshot_reject_q <= snapshot_reject_i;
      reset_done_q <= reset_done_i;
      snapshot_clear_o <= 1'b0;
      rsp_valid_o <= req_valid_i;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;

      if (clear_error_counters_i) begin
        event_reject_count_q <= '0;
        snapshot_timeout_count_q <= '0;
        snapshot_overlap_count_q <= '0;
        snapshot_reject_count_q <= '0;
        reset_disabled_count_q <= '0;
      end
      if (event_reject_i && !event_reject_q) begin
        fault_q[0] <= 1'b1;
        event_reject_count_q <= csr_sat_inc32(event_reject_count_q);
      end
      if (snapshot_timeout_i && !snapshot_timeout_q) begin
        fault_q[1] <= 1'b1;
        snapshot_timeout_count_q <= csr_sat_inc32(snapshot_timeout_count_q);
      end
      if (snapshot_overlap_i && !snapshot_overlap_q) begin
        fault_q[2] <= 1'b1;
        snapshot_overlap_count_q <= csr_sat_inc32(snapshot_overlap_count_q);
      end
      if (snapshot_reject_i && !snapshot_reject_q) begin
        fault_q[2] <= 1'b1;
        snapshot_reject_count_q <= csr_sat_inc32(snapshot_reject_count_q);
      end
      if (reset_done_i && !reset_done_q && reset_disabled_i) begin
        fault_q[3] <= 1'b1;
        reset_disabled_count_q <= csr_sat_inc32(reset_disabled_count_q);
      end

      if (req_valid_i) begin
        unique case (req_addr_i)
          CSR_EVENT_STATUS: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else begin
              rsp_rdata_o[13:0] <= event_id_i;
              rsp_rdata_o[14] <= event_busy_i;
            end
          end
          CSR_EVENT_MASK_STATUS: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else begin
              rsp_rdata_o[3:0] <= required_packet_mask_i;
              rsp_rdata_o[7:4] <= completed_packet_mask_i;
              rsp_rdata_o[11:8] <= required_reset_ack_mask_i;
              rsp_rdata_o[15:12] <= observed_reset_ack_mask_i;
            end
          end
          CSR_SNAPSHOT_CFG: begin
            if (req_write_i) begin
              if (!config_safe_i) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
              end else if (req_wdata_i[31:16] == 16'd0) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_INVALID_VALUE;
              end else begin
                settle_cycles_o <= req_wdata_i[15:0];
                watchdog_cycles_o <= req_wdata_i[31:16];
              end
            end else begin
              rsp_rdata_o[15:0] <= settle_cycles_o;
              rsp_rdata_o[31:16] <= watchdog_cycles_o;
            end
          end
          CSR_RESET_CFG: begin
            if (req_write_i) begin
              if (!config_safe_i) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
              end else reset_width_o <= req_wdata_i[15:0];
            end else rsp_rdata_o[15:0] <= reset_width_o;
          end
          CSR_SNAPSHOT_RESET_STATUS: begin
            if (req_write_i) begin
              rsp_err_o <= 1'b1;
              rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE;
            end else begin
              rsp_rdata_o[0] <= snapshot_valid_i;
              rsp_rdata_o[1] <= snapshot_busy_i;
              rsp_rdata_o[2] <= snapshot_rearm_ready_i;
              rsp_rdata_o[3] <= reset_busy_i;
              rsp_rdata_o[4] <= reset_done_i;
              rsp_rdata_o[5] <= reset_disabled_i;
            end
          end
          CSR_EVENT_FAULT: begin
            if (req_write_i)
              fault_q <= fault_q & ~req_wdata_i[3:0];
            else rsp_rdata_o[3:0] <= fault_q;
          end
          CSR_EVENT_REJECT_COUNT: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= event_reject_count_q;
          end
          CSR_SNAPSHOT_TIMEOUT_COUNT: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= snapshot_timeout_count_q;
          end
          CSR_SNAPSHOT_OVERLAP_COUNT: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= snapshot_overlap_count_q;
          end
          CSR_SNAPSHOT_REJECT_COUNT: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= snapshot_reject_count_q;
          end
          CSR_RESET_DISABLED_COUNT: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= reset_disabled_count_q;
          end
          CSR_EVENT_CMD: begin
            if (req_write_i)
              snapshot_clear_o <= req_wdata_i[0];
          end
          CSR_SNAPSHOT_R_LO: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= snapshot_R_i[31:0];
          end
          CSR_SNAPSHOT_R_HI: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= snapshot_R_i[63:32];
          end
          CSR_SNAPSHOT_Y_LO: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= snapshot_Y_i[31:0];
          end
          CSR_SNAPSHOT_Y_HI: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= snapshot_Y_i[63:32];
          end
          CSR_SNAPSHOT_B_LO: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= snapshot_B_i[31:0];
          end
          CSR_SNAPSHOT_B_HI: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= snapshot_B_i[63:32];
          end
          default: begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_UNMAPPED; end
        endcase
      end
    end
  end
endmodule

module spadmic_csr_matrix_bank (
  input logic clk_sys,
  input logic rst_n,
  input logic req_valid_i,
  input logic req_write_i,
  input logic [15:0] req_addr_i,
  input logic [31:0] req_wdata_i,
  input logic config_safe_i,
  input logic clear_error_counters_i,
  input logic cfg_busy_i,
  input logic cfg_done_i,
  input logic cfg_error_i,
  input logic [3:0] cfg_last_error_i,
  input logic [63:0] cfg_rdata_i,
  input logic cfg_readback_valid_i,
  input logic cfg_valid_i,
  output logic cfg_cmd_start_o,
  output logic [2:0] cfg_cmd_op_o,
  output logic [5:0] cfg_col_idx_o,
  output logic [63:0] cfg_wdata_o,
  output logic fault_summary_o,
  output logic rsp_valid_o,
  output logic [31:0] rsp_rdata_o,
  output logic rsp_err_o,
  output logic [7:0] rsp_cause_o
);
  import spadmic_csr_map_pkg::*;
  localparam logic [2:0] OP_WRITE_COLUMN_64 = 3'd1;
  localparam logic [2:0] OP_READ_COLUMN_64  = 3'd2;
  localparam logic [2:0] OP_GLOBAL_FILL_0   = 3'd3;
  localparam logic [2:0] OP_GLOBAL_FILL_1   = 3'd4;
  logic [1:0] fault_q;
  logic cfg_error_q;
  logic [31:0] reject_count_q;
  logic [31:0] error_count_q;
  assign fault_summary_o = |fault_q;

  function automatic logic valid_op(input logic [2:0] op);
    return (op == OP_WRITE_COLUMN_64) || (op == OP_READ_COLUMN_64) ||
           (op == OP_GLOBAL_FILL_0) || (op == OP_GLOBAL_FILL_1);
  endfunction

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      cfg_cmd_start_o <= 1'b0;
      cfg_cmd_op_o <= OP_WRITE_COLUMN_64;
      cfg_col_idx_o <= '0;
      cfg_wdata_o <= '0;
      fault_q <= '0;
      cfg_error_q <= 1'b0;
      reject_count_q <= '0;
      error_count_q <= '0;
      rsp_valid_o <= 1'b0;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
    end else begin
      cfg_error_q <= cfg_error_i;
      cfg_cmd_start_o <= 1'b0;
      rsp_valid_o <= req_valid_i;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
      if (clear_error_counters_i) begin
        reject_count_q <= '0;
        error_count_q <= '0;
      end
      if (cfg_error_i && !cfg_error_q) begin
        fault_q[1] <= 1'b1;
        error_count_q <= csr_sat_inc32(error_count_q);
      end
      if (req_valid_i) begin
        unique case (req_addr_i)
          CSR_MATRIX_CMD: begin
            if (req_write_i) begin
              if (!config_safe_i || cfg_busy_i) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
                fault_q[0] <= 1'b1;
                reject_count_q <= csr_sat_inc32(reject_count_q);
              end else if (!valid_op(req_wdata_i[3:1])) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_INVALID_VALUE;
                fault_q[0] <= 1'b1;
                reject_count_q <= csr_sat_inc32(reject_count_q);
              end else begin
                cfg_cmd_op_o <= req_wdata_i[3:1];
                cfg_cmd_start_o <= req_wdata_i[0];
              end
            end else rsp_rdata_o[3:1] <= cfg_cmd_op_o;
          end
          CSR_MATRIX_STATUS: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else begin
              rsp_rdata_o[0] <= cfg_busy_i;
              rsp_rdata_o[1] <= cfg_done_i;
              rsp_rdata_o[2] <= cfg_error_i;
              rsp_rdata_o[6:3] <= cfg_last_error_i;
              rsp_rdata_o[7] <= cfg_readback_valid_i;
              rsp_rdata_o[8] <= cfg_valid_i;
            end
          end
          CSR_MATRIX_COLUMN: begin
            if (req_write_i) begin
              if (!config_safe_i || cfg_busy_i) begin
                rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
                fault_q[0] <= 1'b1; reject_count_q <= csr_sat_inc32(reject_count_q);
              end else if (req_wdata_i[5:0] >= 6'd44) begin
                rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_INVALID_VALUE;
                fault_q[0] <= 1'b1; reject_count_q <= csr_sat_inc32(reject_count_q);
              end else cfg_col_idx_o <= req_wdata_i[5:0];
            end else rsp_rdata_o[5:0] <= cfg_col_idx_o;
          end
          CSR_MATRIX_WDATA_LO: begin
            if (req_write_i) begin
              if (!config_safe_i || cfg_busy_i) begin
                rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
                fault_q[0] <= 1'b1; reject_count_q <= csr_sat_inc32(reject_count_q);
              end else cfg_wdata_o[31:0] <= req_wdata_i;
            end else rsp_rdata_o <= cfg_wdata_o[31:0];
          end
          CSR_MATRIX_WDATA_HI: begin
            if (req_write_i) begin
              if (!config_safe_i || cfg_busy_i) begin
                rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
                fault_q[0] <= 1'b1; reject_count_q <= csr_sat_inc32(reject_count_q);
              end else cfg_wdata_o[63:32] <= req_wdata_i;
            end else rsp_rdata_o <= cfg_wdata_o[63:32];
          end
          CSR_MATRIX_RDATA_LO: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= cfg_rdata_i[31:0];
          end
          CSR_MATRIX_RDATA_HI: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= cfg_rdata_i[63:32];
          end
          CSR_MATRIX_FAULT: begin
            if (req_write_i) fault_q <= fault_q & ~req_wdata_i[1:0];
            else begin rsp_rdata_o[1:0] <= fault_q; rsp_rdata_o[7:4] <= cfg_last_error_i; end
          end
          CSR_MATRIX_REJECT_COUNT: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= reject_count_q;
          end
          CSR_MATRIX_ERROR_COUNT: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= error_count_q;
          end
          default: begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_UNMAPPED; end
        endcase
      end
    end
  end
endmodule

module spadmic_csr_tx_bank (
  input logic clk_sys,
  input logic rst_n,
  input logic req_valid_i,
  input logic req_write_i,
  input logic [15:0] req_addr_i,
  input logic [31:0] req_wdata_i,
  input logic clear_error_counters_i,
  input logic bundle_busy_i,
  input logic bundle_idle_i,
  input logic bundle_missing_source_i,
  input logic ddr_empty_i,
  input logic ddr_busy_i,
  input logic ddr_pair_valid_i,
  input logic ddr_padded_i,
  input logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] fifo_level_i,
  input logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] fifo_free_i,
  input logic fifo_empty_i,
  input logic fifo_full_i,
  input logic fifo_almost_full_i,
  input logic fifo_overflow_i,
  output logic fault_summary_o,
  output logic rsp_valid_o,
  output logic [31:0] rsp_rdata_o,
  output logic rsp_err_o,
  output logic [7:0] rsp_cause_o
);
  import spadmic_pkg::*;
  import spadmic_csr_map_pkg::*;
  logic [1:0] fault_q;
  logic missing_q;
  logic overflow_q;
  logic [31:0] missing_count_q;
  logic [31:0] overflow_count_q;
  assign fault_summary_o = |fault_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      fault_q <= '0;
      missing_q <= 1'b0;
      overflow_q <= 1'b0;
      missing_count_q <= '0;
      overflow_count_q <= '0;
      rsp_valid_o <= 1'b0;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
    end else begin
      missing_q <= bundle_missing_source_i;
      overflow_q <= fifo_overflow_i;
      rsp_valid_o <= req_valid_i;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
      if (clear_error_counters_i) begin missing_count_q <= '0; overflow_count_q <= '0; end
      if (bundle_missing_source_i && !missing_q) begin
        fault_q[0] <= 1'b1;
        missing_count_q <= csr_sat_inc32(missing_count_q);
      end
      if (fifo_overflow_i && !overflow_q) begin
        fault_q[1] <= 1'b1;
        overflow_count_q <= csr_sat_inc32(overflow_count_q);
      end
      if (req_valid_i) begin
        unique case (req_addr_i)
          CSR_TX_BUNDLE_STATUS: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else begin
              rsp_rdata_o[0] <= bundle_busy_i;
              rsp_rdata_o[1] <= bundle_idle_i;
              rsp_rdata_o[2] <= bundle_missing_source_i;
            end
          end
          CSR_TX_FIFO_STATUS: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else begin
              rsp_rdata_o[0] <= fifo_empty_i;
              rsp_rdata_o[1] <= fifo_full_i;
              rsp_rdata_o[2] <= fifo_almost_full_i;
              rsp_rdata_o[15:4] <= 12'(fifo_level_i);
              rsp_rdata_o[31:16] <= 16'(fifo_free_i);
            end
          end
          CSR_TX_FIFO_GEOMETRY: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else begin
              rsp_rdata_o[15:0] <= 16'(SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES);
              rsp_rdata_o[31:16] <= 16'(SPADMIC_OUTPUT_FIFO_DEPTH);
            end
          end
          CSR_TX_DDR_STATUS: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else begin
              rsp_rdata_o[0] <= ddr_empty_i;
              rsp_rdata_o[1] <= ddr_busy_i;
              rsp_rdata_o[2] <= ddr_pair_valid_i;
              rsp_rdata_o[3] <= ddr_padded_i;
            end
          end
          CSR_TX_FAULT: begin
            if (req_write_i) fault_q <= fault_q & ~req_wdata_i[1:0];
            else rsp_rdata_o[1:0] <= fault_q;
          end
          CSR_TX_MISSING_SOURCE_COUNT: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= missing_count_q;
          end
          CSR_TX_FIFO_OVERFLOW_COUNT: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= overflow_count_q;
          end
          default: begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_UNMAPPED; end
        endcase
      end
    end
  end
endmodule

module spadmic_csr_pll_bank (
  input logic clk_sys,
  input logic rst_n,
  input logic req_valid_i,
  input logic req_write_i,
  input logic [15:0] req_addr_i,
  input logic [31:0] req_wdata_i,
  input logic config_safe_i,
  input logic clear_error_counters_i,
  input logic pll_lock_i,
  output logic [7:0] pll_fint_sel_o,
  output logic [4:0] pll_ro_sw_o,
  output logic pll_sel_pulse_pfd_o,
  output logic pll_enable_div_o,
  output logic pll_sel_40m_o,
  output logic clk_160m_ext_select_o,
  output logic fault_summary_o,
  output logic rsp_valid_o,
  output logic [31:0] rsp_rdata_o,
  output logic rsp_err_o,
  output logic [7:0] rsp_cause_o
);
  import spadmic_csr_map_pkg::*;
  logic lock_q;
  logic lock_history_valid_q;
  logic lock_loss_sticky_q;
  logic [31:0] lock_loss_count_q;
  assign fault_summary_o = lock_loss_sticky_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      pll_fint_sel_o <= '0;
      pll_ro_sw_o <= '0;
      pll_sel_pulse_pfd_o <= 1'b0;
      pll_enable_div_o <= 1'b1;
      pll_sel_40m_o <= 1'b0;
      clk_160m_ext_select_o <= 1'b0;
      lock_q <= 1'b0;
      lock_history_valid_q <= 1'b0;
      lock_loss_sticky_q <= 1'b0;
      lock_loss_count_q <= '0;
      rsp_valid_o <= 1'b0;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
    end else begin
      lock_q <= pll_lock_i;
      lock_history_valid_q <= 1'b1;
      rsp_valid_o <= req_valid_i;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
      if (clear_error_counters_i) lock_loss_count_q <= '0;
      if (lock_history_valid_q && lock_q && !pll_lock_i) begin
        lock_loss_sticky_q <= 1'b1;
        lock_loss_count_q <= csr_sat_inc32(lock_loss_count_q);
      end
      if (req_valid_i) begin
        unique case (req_addr_i)
          CSR_PLL_CTRL: begin
            if (req_write_i) begin
              if (!config_safe_i) begin
                rsp_err_o <= 1'b1;
                rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE;
              end else begin
                pll_fint_sel_o <= req_wdata_i[7:0];
                pll_ro_sw_o <= req_wdata_i[12:8];
                pll_sel_pulse_pfd_o <= req_wdata_i[13];
                pll_enable_div_o <= req_wdata_i[14];
                pll_sel_40m_o <= req_wdata_i[15];
                clk_160m_ext_select_o <= req_wdata_i[16];
              end
            end else begin
              rsp_rdata_o[7:0] <= pll_fint_sel_o;
              rsp_rdata_o[12:8] <= pll_ro_sw_o;
              rsp_rdata_o[13] <= pll_sel_pulse_pfd_o;
              rsp_rdata_o[14] <= pll_enable_div_o;
              rsp_rdata_o[15] <= pll_sel_40m_o;
              rsp_rdata_o[16] <= clk_160m_ext_select_o;
            end
          end
          CSR_PLL_STATUS: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else begin
              rsp_rdata_o[0] <= pll_lock_i;
              rsp_rdata_o[1] <= clk_160m_ext_select_o;
              rsp_rdata_o[2] <= pll_enable_div_o;
            end
          end
          CSR_PLL_FAULT: begin
            if (req_write_i) lock_loss_sticky_q <= lock_loss_sticky_q & ~req_wdata_i[0];
            else rsp_rdata_o[0] <= lock_loss_sticky_q;
          end
          CSR_PLL_LOCK_LOSS_COUNT: begin
            if (req_write_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_READ_ONLY_WRITE; end
            else rsp_rdata_o <= lock_loss_count_q;
          end
          default: begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_UNMAPPED; end
        endcase
      end
    end
  end
endmodule

module spadmic_csr_analog_bank (
  input logic clk_sys,
  input logic rst_n,
  input logic req_valid_i,
  input logic req_write_i,
  input logic [15:0] req_addr_i,
  input logic [31:0] req_wdata_i,
  input logic config_safe_i,
  output logic [3:0] slvs_s_drv_o,
  output logic slvs_en_vref_ext_o,
  output logic slvs_en_drv_o,
  output logic slvs_vref_adj_b_o,
  output logic slvs_en_vref_400mv_o,
  output logic slvs_en_ref_drv_b_o,
  output logic [3:0] rx_s_rx_o,
  output logic rx_en_rx_o,
  output logic rx_en_term_o,
  output logic rsp_valid_o,
  output logic [31:0] rsp_rdata_o,
  output logic rsp_err_o,
  output logic [7:0] rsp_cause_o
);
  import spadmic_csr_map_pkg::*;
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      slvs_s_drv_o <= '0;
      slvs_en_vref_ext_o <= 1'b0;
      slvs_en_drv_o <= 1'b0;
      slvs_vref_adj_b_o <= 1'b1;
      slvs_en_vref_400mv_o <= 1'b0;
      slvs_en_ref_drv_b_o <= 1'b1;
      rx_s_rx_o <= '0;
      rx_en_rx_o <= 1'b0;
      rx_en_term_o <= 1'b0;
      rsp_valid_o <= 1'b0;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
    end else begin
      rsp_valid_o <= req_valid_i;
      rsp_rdata_o <= '0;
      rsp_err_o <= 1'b0;
      rsp_cause_o <= CSR_CAUSE_NONE;
      if (req_valid_i) begin
        unique case (req_addr_i)
          CSR_SLVS_CTRL: begin
            if (req_write_i) begin
              if (!config_safe_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE; end
              else begin
                slvs_s_drv_o <= req_wdata_i[3:0];
                slvs_en_vref_ext_o <= req_wdata_i[4];
                slvs_en_drv_o <= req_wdata_i[5];
                slvs_vref_adj_b_o <= req_wdata_i[6];
                slvs_en_vref_400mv_o <= req_wdata_i[7];
                slvs_en_ref_drv_b_o <= req_wdata_i[8];
              end
            end else begin
              rsp_rdata_o[3:0] <= slvs_s_drv_o;
              rsp_rdata_o[4] <= slvs_en_vref_ext_o;
              rsp_rdata_o[5] <= slvs_en_drv_o;
              rsp_rdata_o[6] <= slvs_vref_adj_b_o;
              rsp_rdata_o[7] <= slvs_en_vref_400mv_o;
              rsp_rdata_o[8] <= slvs_en_ref_drv_b_o;
            end
          end
          CSR_RX_CTRL: begin
            if (req_write_i) begin
              if (!config_safe_i) begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_UNSAFE_WRITE; end
              else begin
                rx_s_rx_o <= req_wdata_i[3:0];
                rx_en_rx_o <= req_wdata_i[4];
                rx_en_term_o <= req_wdata_i[5];
              end
            end else begin
              rsp_rdata_o[3:0] <= rx_s_rx_o;
              rsp_rdata_o[4] <= rx_en_rx_o;
              rsp_rdata_o[5] <= rx_en_term_o;
            end
          end
          default: begin rsp_err_o <= 1'b1; rsp_cause_o <= CSR_CAUSE_UNMAPPED; end
        endcase
      end
    end
  end
endmodule

`default_nettype wire
