// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_matrix_top_csr.sv
// Purpose  : Phase 3 CSR endpoint for the matrix-top shell.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_matrix_top_csr (
  input  logic                                clk_sys,
  input  logic                                rst_n,

  input  logic                                csr_valid_i,
  input  logic                                csr_write_i,
  input  logic [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] csr_addr_i,
  input  logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_wdata_i,
  output logic                                csr_ready_o,
  output logic                                csr_rvalid_o,
  output logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_rdata_o,
  output logic                                csr_err_o,

  input  logic                                safe_idle_i,
  input  logic                                transition_busy_i,
  input  logic                                event_busy_i,
  input  logic [13:0]                         event_id_i,
  input  logic [3:0]                          required_packet_mask_i,
  input  logic [3:0]                          completed_packet_mask_i,
  input  logic [3:0]                          required_reset_ack_mask_i,
  input  logic [3:0]                          observed_reset_ack_mask_i,
  input  logic                                event_rejected_not_ready_i,

  input  logic                                snapshot_valid_i,
  input  logic                                snapshot_busy_i,
  input  logic                                snapshot_timeout_i,
  input  logic                                snapshot_overlap_i,
  input  logic                                snapshot_reject_i,
  input  logic                                snapshot_rearm_ready_i,
  input  logic [63:0]                         snapshot_R_i,
  input  logic [63:0]                         snapshot_Y_i,
  input  logic [63:0]                         snapshot_B_i,

  input  logic                                reset_busy_i,
  input  logic                                reset_done_i,
  input  logic                                reset_disabled_i,

  input  logic                                matrix_cfg_busy_i,
  input  logic                                matrix_cfg_done_i,
  input  logic                                matrix_cfg_error_i,
  input  logic [3:0]                          matrix_cfg_last_error_i,
  input  logic [63:0]                         matrix_cfg_rdata_i,
  input  logic                                matrix_cfg_readback_valid_i,
  input  logic                                matrix_cfg_valid_i,

  input  logic                                ddr_empty_i,
  input  logic                                ddr_busy_i,
  input  logic                                ddr_pair_valid_i,
  input  logic                                ddr_padded_i,
  input  logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level_i,
  input  logic [spadmic_pkg::SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words_i,
  input  logic                                output_fifo_empty_i,
  input  logic                                output_fifo_full_i,
  input  logic                                output_fifo_almost_full_i,
  input  logic                                output_fifo_overflow_i,
  input  logic                                bundle_missing_source_i,
  input  logic                                position_packet_drop_i,
  input  logic                                pll_lock_i,

  output logic                                global_enable_o,
  output spadmic_pkg::spadmic_operating_mode_e requested_mode_o,
  output spadmic_pkg::spadmic_operating_mode_e active_mode_o,
  output logic [2:0]                          requested_axis_mask_o,
  output logic [2:0]                          active_axis_mask_o,
  output logic                                auto_reset_enable_o,
  output logic [15:0]                         settle_cycles_o,
  output logic [15:0]                         watchdog_cycles_o,
  output logic [15:0]                         reset_width_o,
  output logic                                snapshot_clear_o,
  output logic [mptdc_pkg::MAX_HITS_W-1:0]    tdc_max_hits_o,
  output logic [7:0]                          tdc_ro_slow_code_o,
  output logic [7:0]                          tdc_ro_fast_code_o,
  output logic                                tdc_soft_reset_o,
  output logic                                tdc_fifo_clr_o,
  output logic [2:0]                          calib_axis_mask_o,
  output spadmic_pkg::spadmic_pos_mode_e      position_mode_o,
  output logic [7:0]                          pll_fint_sel_o,
  output logic [4:0]                          pll_ro_sw_o,
  output logic                                pll_sel_pulse_pfd_o,
  output logic                                pll_enable_div_o,
  output logic                                pll_sel_40m_o,
  output logic                                clk_160m_ext_select_o,

  output logic                                matrix_cfg_cmd_start_o,
  output logic [2:0]                          matrix_cfg_cmd_op_o,
  output logic [5:0]                          matrix_cfg_col_idx_o,
  output logic [63:0]                         matrix_cfg_wdata_o,

  output logic                                cfg_accept_o
);
  import spadmic_pkg::*;
  import mptdc_pkg::*;

  localparam logic [2:0] OP_WRITE_COLUMN_64 = 3'd1;
  localparam logic [2:0] OP_READ_COLUMN_64  = 3'd2;
  localparam logic [2:0] OP_GLOBAL_FILL_0   = 3'd3;
  localparam logic [2:0] OP_GLOBAL_FILL_1   = 3'd4;

  localparam logic [3:0] CMD_ERR_NONE        = 4'd0;
  localparam logic [3:0] CMD_ERR_BUSY        = 4'd1;
  localparam logic [3:0] CMD_ERR_INVALID_OP  = 4'd2;
  localparam logic [3:0] CMD_ERR_INVALID_COL = 4'd3;
  localparam logic [3:0] CMD_ERR_PATH_BUSY   = 4'd4;
  localparam logic [3:0] CMD_ERR_BAD_ADDR    = 4'd5;
  localparam logic [3:0] CMD_ERR_BAD_MODE    = 4'd6;
  localparam logic [3:0] CMD_ERR_BAD_VALUE   = 4'd7;

  logic [15:0] fault_count_q;
  logic [15:0] cfg_reject_count_q;
  logic [15:0] event_reject_count_q;
  logic [15:0] reset_disabled_count_q;
  logic [15:0] snapshot_timeout_count_q;
  logic [3:0]  csr_last_error_q;
  logic [3:0]  fault_sticky_q;
  logic [2:0]  matrix_cfg_cmd_op_q;
  logic        event_reject_q;
  logic        reset_done_q;
  logic        snapshot_timeout_q;
  logic        output_fifo_overflow_sticky_q;
  logic [15:0] output_fifo_overflow_count_q;

  wire csr_accept = csr_valid_i & csr_ready_o;
  wire ctrl_safe_to_commit = safe_idle_i && !transition_busy_i && !matrix_cfg_busy_i;
  wire cfg_path_safe = safe_idle_i && !transition_busy_i &&
                       !event_busy_i && !snapshot_busy_i && !reset_busy_i;
  wire cfg_params_writable = cfg_path_safe && !matrix_cfg_busy_i;
  wire matrix_cfg_op_valid =
      (csr_wdata_i[3:1] == OP_WRITE_COLUMN_64) ||
      (csr_wdata_i[3:1] == OP_READ_COLUMN_64)  ||
      (csr_wdata_i[3:1] == OP_GLOBAL_FILL_0)   ||
      (csr_wdata_i[3:1] == OP_GLOBAL_FILL_1);
  wire matrix_cfg_col_valid = (csr_wdata_i[5:0] < 6'd44);

  function automatic logic mode_value_valid(input logic [2:0] mode_value);
    return (mode_value <= SPADMIC_MODE_CALIBRATION);
  endfunction

  function automatic logic mode_axis_valid(
    input spadmic_operating_mode_e mode_value,
    input logic [2:0] axis_mask,
    input logic [2:0] calib_mask
  );
    if ((mode_value == SPADMIC_MODE_TDC_ONLY) ||
        (mode_value == SPADMIC_MODE_BOTH))
      return (axis_mask == 3'b111);
    if (mode_value == SPADMIC_MODE_CALIBRATION)
      return (calib_mask != 3'b000);
    return 1'b1;
  endfunction

  function automatic logic [15:0] sat16_inc(input logic [15:0] value);
    return (value == 16'hFFFF) ? value : (value + 16'd1);
  endfunction

  function automatic logic is_known_addr(
    input logic [SPADMIC_CSR_ADDR_W-1:0] addr
  );
    case (addr)
      SPADMIC_CSR_GLOBAL_ID,
      SPADMIC_CSR_GLOBAL_VERSION,
      SPADMIC_CSR_MTOP_CTRL_REQUEST,
      SPADMIC_CSR_MTOP_CTRL_ACTIVE,
      SPADMIC_CSR_MTOP_STATUS,
      SPADMIC_CSR_MTOP_FAULT,
      SPADMIC_CSR_MTOP_FAULT_COUNT,
      SPADMIC_CSR_MATRIX_EVENT_STATUS,
      SPADMIC_CSR_MATRIX_SNAPSHOT_CFG,
      SPADMIC_CSR_MATRIX_RESET_CTRL,
      SPADMIC_CSR_MATRIX_RESET_STATUS,
      SPADMIC_CSR_MATRIX_R_SNAP_LO,
      SPADMIC_CSR_MATRIX_R_SNAP_HI,
      SPADMIC_CSR_MATRIX_Y_SNAP_LO,
      SPADMIC_CSR_MATRIX_Y_SNAP_HI,
      SPADMIC_CSR_MATRIX_B_SNAP_LO,
      SPADMIC_CSR_MATRIX_B_SNAP_HI,
      SPADMIC_CSR_MATRIX_CFG_CMD,
      SPADMIC_CSR_MATRIX_CFG_STATUS,
      SPADMIC_CSR_MATRIX_CFG_COL,
      SPADMIC_CSR_MATRIX_CFG_WDATA_LO,
      SPADMIC_CSR_MATRIX_CFG_WDATA_HI,
      SPADMIC_CSR_MATRIX_CFG_RDATA_LO,
      SPADMIC_CSR_MATRIX_CFG_RDATA_HI,
      SPADMIC_CSR_MATRIX_CFG_LAST_ERROR,
      SPADMIC_CSR_SHARED_TDC_MAX_HITS,
      SPADMIC_CSR_SHARED_TDC_RO_SLOW,
      SPADMIC_CSR_SHARED_TDC_RO_FAST,
      SPADMIC_CSR_SHARED_TDC_CTRL,
      SPADMIC_CSR_CALIB_AXIS_MASK,
      SPADMIC_CSR_PLL_CTRL,
      SPADMIC_CSR_PLL_STATUS,
      SPADMIC_CSR_POSITION_MODE,
      SPADMIC_CSR_TX_STATUS,
      SPADMIC_CSR_OUTPUT_FIFO_STATUS,
      SPADMIC_CSR_OUTPUT_FIFO_WATERMARKS: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  function automatic logic [SPADMIC_CSR_DATA_W-1:0] read_data_for_addr(
    input logic [SPADMIC_CSR_ADDR_W-1:0] addr
  );
    logic [SPADMIC_CSR_DATA_W-1:0] rd;
    rd = '0;

    case (addr)
      SPADMIC_CSR_GLOBAL_ID: begin
        rd = 32'h5350_4D54;  // "SPMT" = SPADMIC matrix top.
      end

      SPADMIC_CSR_GLOBAL_VERSION: begin
        rd = 32'h0005_0000;
      end

      SPADMIC_CSR_MTOP_CTRL_REQUEST: begin
        rd[0]   = global_enable_o;
        rd[3:1] = requested_mode_o;
        rd[6:4] = requested_axis_mask_o;
        rd[7]   = auto_reset_enable_o;
      end

      SPADMIC_CSR_MTOP_CTRL_ACTIVE: begin
        rd[0]   = global_enable_o;
        rd[3:1] = active_mode_o;
        rd[6:4] = active_axis_mask_o;
        rd[7]   = auto_reset_enable_o;
      end

      SPADMIC_CSR_MTOP_STATUS: begin
        rd[0]    = safe_idle_i;
        rd[1]    = transition_busy_i;
        rd[2]    = event_busy_i;
        rd[3]    = matrix_cfg_busy_i;
        rd[4]    = snapshot_busy_i;
        rd[5]    = reset_busy_i;
        rd[6]    = ddr_empty_i;
        rd[7]    = cfg_accept_o;
        rd[21:8] = event_id_i;
      end

      SPADMIC_CSR_MTOP_FAULT: begin
        rd[3:0] = fault_sticky_q;
        rd[4]   = output_fifo_overflow_sticky_q;
        rd[11:8] = csr_last_error_q;
      end

      SPADMIC_CSR_MTOP_FAULT_COUNT: begin
        rd[15:0]  = fault_count_q;
        rd[31:16] = cfg_reject_count_q;
      end

      SPADMIC_CSR_SHARED_TDC_MAX_HITS: begin
        rd[MAX_HITS_W-1:0] = tdc_max_hits_o;
      end

      SPADMIC_CSR_SHARED_TDC_RO_SLOW: begin
        rd[7:0] = tdc_ro_slow_code_o;
      end

      SPADMIC_CSR_SHARED_TDC_RO_FAST: begin
        rd[7:0] = tdc_ro_fast_code_o;
      end

      SPADMIC_CSR_SHARED_TDC_CTRL: begin
        rd[0] = 1'b0;  // soft_reset is a command pulse, not a sticky state.
        rd[1] = 1'b0;  // fifo_clr is a command pulse, not a sticky state.
      end

      SPADMIC_CSR_CALIB_AXIS_MASK: begin
        rd[2:0] = calib_axis_mask_o;
      end

      SPADMIC_CSR_PLL_CTRL: begin
        rd[7:0]   = pll_fint_sel_o;
        rd[12:8]  = pll_ro_sw_o;
        rd[13]    = pll_sel_pulse_pfd_o;
        rd[14]    = pll_enable_div_o;
        rd[15]    = pll_sel_40m_o;
        rd[16]    = clk_160m_ext_select_o;
      end

      SPADMIC_CSR_PLL_STATUS: begin
        rd[0] = pll_lock_i;
        rd[1] = clk_160m_ext_select_o;
        rd[2] = pll_enable_div_o;
      end

      SPADMIC_CSR_POSITION_MODE: begin
        rd[0] = position_mode_o;
      end

      SPADMIC_CSR_MATRIX_EVENT_STATUS: begin
        rd[3:0]   = required_packet_mask_i;
        rd[7:4]   = completed_packet_mask_i;
        rd[11:8]  = required_reset_ack_mask_i;
        rd[15:12] = observed_reset_ack_mask_i;
        rd[29:16] = event_id_i;
        rd[30]    = event_busy_i;
      end

      SPADMIC_CSR_MATRIX_SNAPSHOT_CFG: begin
        rd[15:0]  = settle_cycles_o;
        rd[31:16] = watchdog_cycles_o;
      end

      SPADMIC_CSR_MATRIX_RESET_CTRL: begin
        rd[15:0] = reset_width_o;
        rd[16]   = auto_reset_enable_o;
      end

      SPADMIC_CSR_MATRIX_RESET_STATUS: begin
        rd[0]     = reset_busy_i;
        rd[1]     = reset_done_i;
        rd[2]     = reset_disabled_i;
        rd[3]     = snapshot_valid_i;
        rd[4]     = snapshot_timeout_i;
        rd[5]     = snapshot_overlap_i;
        rd[6]     = snapshot_reject_i;
        rd[7]     = snapshot_rearm_ready_i;
        rd[23:8]  = reset_disabled_count_q;
      end

      SPADMIC_CSR_MATRIX_R_SNAP_LO: rd = snapshot_R_i[31:0];
      SPADMIC_CSR_MATRIX_R_SNAP_HI: rd = snapshot_R_i[63:32];
      SPADMIC_CSR_MATRIX_Y_SNAP_LO: rd = snapshot_Y_i[31:0];
      SPADMIC_CSR_MATRIX_Y_SNAP_HI: rd = snapshot_Y_i[63:32];
      SPADMIC_CSR_MATRIX_B_SNAP_LO: rd = snapshot_B_i[31:0];
      SPADMIC_CSR_MATRIX_B_SNAP_HI: rd = snapshot_B_i[63:32];

      SPADMIC_CSR_MATRIX_CFG_CMD: begin
        rd[3:1] = matrix_cfg_cmd_op_q;
      end

      SPADMIC_CSR_MATRIX_CFG_STATUS: begin
        rd[0]    = matrix_cfg_busy_i;
        rd[1]    = matrix_cfg_done_i;
        rd[2]    = matrix_cfg_error_i;
        rd[6:3]  = matrix_cfg_last_error_i;
        rd[7]    = matrix_cfg_readback_valid_i;
        rd[8]    = matrix_cfg_valid_i;
        rd[24:9] = snapshot_timeout_count_q;
      end

      SPADMIC_CSR_MATRIX_CFG_COL: begin
        rd[5:0] = matrix_cfg_col_idx_o;
      end

      SPADMIC_CSR_MATRIX_CFG_WDATA_LO: rd = matrix_cfg_wdata_o[31:0];
      SPADMIC_CSR_MATRIX_CFG_WDATA_HI: rd = matrix_cfg_wdata_o[63:32];
      SPADMIC_CSR_MATRIX_CFG_RDATA_LO: rd = matrix_cfg_rdata_i[31:0];
      SPADMIC_CSR_MATRIX_CFG_RDATA_HI: rd = matrix_cfg_rdata_i[63:32];

      SPADMIC_CSR_MATRIX_CFG_LAST_ERROR: begin
        rd[3:0]   = matrix_cfg_last_error_i;
        rd[7:4]   = csr_last_error_q;
        rd[23:8]  = event_reject_count_q;
      end

      SPADMIC_CSR_TX_STATUS: begin
        rd[0] = ddr_empty_i && output_fifo_empty_i && !ddr_pair_valid_i;
        rd[1] = ddr_busy_i;
        rd[2] = ddr_pair_valid_i;
        rd[3] = ddr_padded_i;
        rd[4] = bundle_missing_source_i;
        rd[5] = position_packet_drop_i;
        rd[6] = output_fifo_empty_i;
        rd[7] = output_fifo_full_i;
        rd[8] = output_fifo_almost_full_i;
        rd[9] = output_fifo_overflow_sticky_q;
        rd[31:16] = output_fifo_overflow_count_q;
      end

      SPADMIC_CSR_OUTPUT_FIFO_STATUS: begin
        rd[0] = output_fifo_empty_i;
        rd[1] = output_fifo_full_i;
        rd[2] = output_fifo_almost_full_i;
        rd[3] = output_fifo_overflow_sticky_q;
        rd[15:4] = 12'(output_fifo_level_i);
        rd[31:16] = 16'(output_fifo_free_words_i);
      end

      SPADMIC_CSR_OUTPUT_FIFO_WATERMARKS: begin
        rd[15:0]  = 16'(SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES);
        rd[31:16] = 16'(SPADMIC_OUTPUT_FIFO_DEPTH);
      end

      default: rd = '0;
    endcase

    return rd;
  endfunction

  assign csr_ready_o = 1'b1;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      csr_rvalid_o            <= 1'b0;
      csr_rdata_o             <= '0;
      csr_err_o               <= 1'b0;
      global_enable_o         <= 1'b0;
      requested_mode_o        <= SPADMIC_MODE_DISABLED;
      active_mode_o           <= SPADMIC_MODE_DISABLED;
      requested_axis_mask_o   <= 3'b111;
      active_axis_mask_o      <= 3'b111;
      auto_reset_enable_o     <= 1'b1;
      settle_cycles_o         <= 16'd2;
      watchdog_cycles_o       <= 16'd64;
      reset_width_o           <= 16'd0;
      snapshot_clear_o        <= 1'b0;
      tdc_max_hits_o          <= MAX_HITS_W'(MAX_HITS);
      tdc_ro_slow_code_o      <= 8'h00;
      tdc_ro_fast_code_o      <= 8'h00;
      tdc_soft_reset_o        <= 1'b0;
      tdc_fifo_clr_o          <= 1'b0;
      calib_axis_mask_o       <= 3'b111;
      position_mode_o         <= SPADMIC_POS_MODE_RAW;
      pll_fint_sel_o          <= '0;
      pll_ro_sw_o             <= '0;
      pll_sel_pulse_pfd_o     <= 1'b0;
      pll_enable_div_o        <= 1'b1;
      pll_sel_40m_o           <= 1'b0;
      clk_160m_ext_select_o   <= 1'b0;
      matrix_cfg_cmd_start_o  <= 1'b0;
      matrix_cfg_cmd_op_o     <= OP_WRITE_COLUMN_64;
      matrix_cfg_cmd_op_q     <= OP_WRITE_COLUMN_64;
      matrix_cfg_col_idx_o    <= '0;
      matrix_cfg_wdata_o      <= '0;
      cfg_accept_o            <= 1'b0;
      fault_count_q           <= '0;
      cfg_reject_count_q      <= '0;
      event_reject_count_q    <= '0;
      reset_disabled_count_q  <= '0;
      snapshot_timeout_count_q <= '0;
      csr_last_error_q        <= CMD_ERR_NONE;
      fault_sticky_q          <= '0;
      event_reject_q          <= 1'b0;
      reset_done_q            <= 1'b0;
      snapshot_timeout_q      <= 1'b0;
      output_fifo_overflow_sticky_q <= 1'b0;
      output_fifo_overflow_count_q  <= '0;
    end else begin
      logic [SPADMIC_CSR_DATA_W-1:0] rd_next;
      logic write_error;
      logic addr_valid;
      logic fault_this_cycle;
      logic [3:0] write_error_code;
      spadmic_operating_mode_e next_mode;
      logic [2:0] next_axis_mask;

      csr_rvalid_o           <= 1'b0;
      csr_rdata_o            <= '0;
      csr_err_o              <= 1'b0;
      snapshot_clear_o       <= 1'b0;
      tdc_soft_reset_o       <= 1'b0;
      tdc_fifo_clr_o         <= 1'b0;
      matrix_cfg_cmd_start_o <= 1'b0;
      cfg_accept_o           <= 1'b0;
      fault_this_cycle       = 1'b0;
      write_error            = 1'b0;
      write_error_code       = CMD_ERR_NONE;
      addr_valid             = is_known_addr(csr_addr_i);
      rd_next                = read_data_for_addr(csr_addr_i);
      next_mode              = spadmic_operating_mode_e'(csr_wdata_i[3:1]);
      next_axis_mask         = csr_wdata_i[6:4];

      event_reject_q     <= event_rejected_not_ready_i;
      reset_done_q       <= reset_done_i;
      snapshot_timeout_q <= snapshot_timeout_i;

      if (event_rejected_not_ready_i && !event_reject_q)
        event_reject_count_q <= sat16_inc(event_reject_count_q);
      if (reset_done_i && !reset_done_q && reset_disabled_i)
        reset_disabled_count_q <= sat16_inc(reset_disabled_count_q);
      if (snapshot_timeout_i && !snapshot_timeout_q)
        snapshot_timeout_count_q <= sat16_inc(snapshot_timeout_count_q);
      if (output_fifo_overflow_i) begin
        output_fifo_overflow_sticky_q <= 1'b1;
        output_fifo_overflow_count_q <= sat16_inc(output_fifo_overflow_count_q);
      end

      if (csr_accept) begin
        if (!addr_valid) begin
          write_error      = 1'b1;
          write_error_code = CMD_ERR_BAD_ADDR;
        end else if (csr_write_i) begin
          case (csr_addr_i)
            SPADMIC_CSR_MTOP_CTRL_REQUEST: begin
              if (!mode_value_valid(csr_wdata_i[3:1]) ||
                  !mode_axis_valid(next_mode, next_axis_mask, calib_axis_mask_o)) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_BAD_MODE;
              end else if (!ctrl_safe_to_commit) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_PATH_BUSY;
              end else begin
                global_enable_o       <= csr_wdata_i[0];
                requested_mode_o      <= next_mode;
                active_mode_o         <= next_mode;
                requested_axis_mask_o <= (next_mode == SPADMIC_MODE_CALIBRATION)
                                       ? calib_axis_mask_o : next_axis_mask;
                active_axis_mask_o    <= (next_mode == SPADMIC_MODE_CALIBRATION)
                                       ? calib_axis_mask_o : next_axis_mask;
                auto_reset_enable_o   <= csr_wdata_i[7];
                cfg_accept_o          <= 1'b1;
              end
            end

            SPADMIC_CSR_SHARED_TDC_MAX_HITS: begin
              if (!ctrl_safe_to_commit) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_PATH_BUSY;
              end else begin
                tdc_max_hits_o <= MAX_HITS_W'(csr_wdata_i[MAX_HITS_W-1:0]);
                cfg_accept_o   <= 1'b1;
              end
            end

            SPADMIC_CSR_SHARED_TDC_RO_SLOW: begin
              if (!ctrl_safe_to_commit) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_PATH_BUSY;
              end else begin
                tdc_ro_slow_code_o <= csr_wdata_i[7:0];
                cfg_accept_o       <= 1'b1;
              end
            end

            SPADMIC_CSR_SHARED_TDC_RO_FAST: begin
              if (!ctrl_safe_to_commit) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_PATH_BUSY;
              end else begin
                tdc_ro_fast_code_o <= csr_wdata_i[7:0];
                cfg_accept_o       <= 1'b1;
              end
            end

            SPADMIC_CSR_SHARED_TDC_CTRL: begin
              if (!ctrl_safe_to_commit) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_PATH_BUSY;
              end else begin
                tdc_soft_reset_o <= csr_wdata_i[0];
                tdc_fifo_clr_o   <= csr_wdata_i[1];
                cfg_accept_o     <= |csr_wdata_i[1:0];
              end
            end

            SPADMIC_CSR_CALIB_AXIS_MASK: begin
              if (!ctrl_safe_to_commit) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_PATH_BUSY;
              end else if (csr_wdata_i[2:0] == 3'b000) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_BAD_VALUE;
              end else begin
                calib_axis_mask_o <= csr_wdata_i[2:0];
                if (active_mode_o == SPADMIC_MODE_CALIBRATION) begin
                  requested_axis_mask_o <= csr_wdata_i[2:0];
                  active_axis_mask_o    <= csr_wdata_i[2:0];
                end
                cfg_accept_o <= 1'b1;
              end
            end

            SPADMIC_CSR_PLL_CTRL: begin
              if (!ctrl_safe_to_commit) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_PATH_BUSY;
              end else begin
                pll_fint_sel_o        <= csr_wdata_i[7:0];
                pll_ro_sw_o           <= csr_wdata_i[12:8];
                pll_sel_pulse_pfd_o   <= csr_wdata_i[13];
                pll_enable_div_o      <= csr_wdata_i[14];
                pll_sel_40m_o         <= csr_wdata_i[15];
                clk_160m_ext_select_o <= csr_wdata_i[16];
                cfg_accept_o          <= 1'b1;
              end
            end

            SPADMIC_CSR_POSITION_MODE: begin
              if (!ctrl_safe_to_commit) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_PATH_BUSY;
              end else begin
                position_mode_o <= spadmic_pos_mode_e'(csr_wdata_i[0]);
                cfg_accept_o    <= 1'b1;
              end
            end

            SPADMIC_CSR_MTOP_FAULT: begin
              fault_sticky_q <= fault_sticky_q & ~csr_wdata_i[3:0];
              if (csr_wdata_i[4] && !output_fifo_overflow_i)
                output_fifo_overflow_sticky_q <= 1'b0;
              if (csr_wdata_i[11:8] != 4'h0)
                csr_last_error_q <= CMD_ERR_NONE;
            end

            SPADMIC_CSR_MATRIX_EVENT_STATUS: begin
              snapshot_clear_o <= csr_wdata_i[0];
            end

            SPADMIC_CSR_MATRIX_SNAPSHOT_CFG: begin
              if (!ctrl_safe_to_commit) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_PATH_BUSY;
              end else begin
                settle_cycles_o   <= csr_wdata_i[15:0];
                watchdog_cycles_o <= csr_wdata_i[31:16];
              end
            end

            SPADMIC_CSR_MATRIX_RESET_CTRL: begin
              if (event_busy_i || reset_busy_i) begin
                write_error      = 1'b1;
                write_error_code = CMD_ERR_PATH_BUSY;
              end else begin
                reset_width_o       <= csr_wdata_i[15:0];
                auto_reset_enable_o <= csr_wdata_i[16];
              end
            end

            SPADMIC_CSR_MATRIX_CFG_CMD: begin
              if (matrix_cfg_busy_i) begin
                write_error        = 1'b1;
                write_error_code   = CMD_ERR_BUSY;
                cfg_reject_count_q <= sat16_inc(cfg_reject_count_q);
              end else if (!cfg_path_safe) begin
                write_error        = 1'b1;
                write_error_code   = CMD_ERR_PATH_BUSY;
                cfg_reject_count_q <= sat16_inc(cfg_reject_count_q);
              end else if (!matrix_cfg_op_valid) begin
                write_error        = 1'b1;
                write_error_code   = CMD_ERR_INVALID_OP;
                cfg_reject_count_q <= sat16_inc(cfg_reject_count_q);
              end else begin
                matrix_cfg_cmd_op_q <= csr_wdata_i[3:1];
                if (csr_wdata_i[0]) begin
                  matrix_cfg_cmd_op_o    <= csr_wdata_i[3:1];
                  matrix_cfg_cmd_start_o <= 1'b1;
                end
              end
            end

            SPADMIC_CSR_MATRIX_CFG_COL: begin
              if (!cfg_params_writable) begin
                write_error = 1'b1;
                write_error_code = matrix_cfg_busy_i ? CMD_ERR_BUSY : CMD_ERR_PATH_BUSY;
                cfg_reject_count_q <= sat16_inc(cfg_reject_count_q);
              end else if (!matrix_cfg_col_valid) begin
                write_error        = 1'b1;
                write_error_code   = CMD_ERR_INVALID_COL;
                cfg_reject_count_q <= sat16_inc(cfg_reject_count_q);
              end else begin
                matrix_cfg_col_idx_o <= csr_wdata_i[5:0];
              end
            end

            SPADMIC_CSR_MATRIX_CFG_WDATA_LO: begin
              if (!cfg_params_writable) begin
                write_error = 1'b1;
                write_error_code = matrix_cfg_busy_i ? CMD_ERR_BUSY : CMD_ERR_PATH_BUSY;
                cfg_reject_count_q <= sat16_inc(cfg_reject_count_q);
              end else begin
                matrix_cfg_wdata_o[31:0] <= csr_wdata_i;
              end
            end

            SPADMIC_CSR_MATRIX_CFG_WDATA_HI: begin
              if (!cfg_params_writable) begin
                write_error = 1'b1;
                write_error_code = matrix_cfg_busy_i ? CMD_ERR_BUSY : CMD_ERR_PATH_BUSY;
                cfg_reject_count_q <= sat16_inc(cfg_reject_count_q);
              end else begin
                matrix_cfg_wdata_o[63:32] <= csr_wdata_i;
              end
            end

            default: begin
              write_error      = 1'b1;
              write_error_code = CMD_ERR_BAD_ADDR;
            end
          endcase
        end

        if (write_error) begin
          fault_this_cycle = 1'b1;
          csr_last_error_q <= write_error_code;
          fault_sticky_q[0] <= 1'b1;
          fault_count_q <= sat16_inc(fault_count_q);
        end

        csr_rvalid_o <= 1'b1;
        csr_rdata_o  <= (!csr_write_i && addr_valid) ? rd_next : '0;
        csr_err_o    <= write_error || !addr_valid;
      end

      if (matrix_cfg_error_i) begin
        fault_sticky_q[1] <= 1'b1;
        if (!fault_this_cycle)
          csr_last_error_q <= matrix_cfg_last_error_i;
      end
      if (event_rejected_not_ready_i)
        fault_sticky_q[2] <= 1'b1;
      if (snapshot_timeout_i)
        fault_sticky_q[3] <= 1'b1;
    end
  end

endmodule

`default_nettype wire
