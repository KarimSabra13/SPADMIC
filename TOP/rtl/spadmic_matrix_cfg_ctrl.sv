// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_matrix_cfg_ctrl.sv
// Purpose  : Matrix configuration controller with clk_sys <-> clk_cfg_40m CDC.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_matrix_cfg_ctrl (
  input  logic        clk_sys,
  input  logic        clk_cfg_40m,
  input  logic        rst_sys_n,
  input  logic        rst_cfg_n,
  input  logic        cmd_start_i,
  input  logic [2:0]  cmd_op_i,
  input  logic [5:0]  col_idx_i,
  input  logic [63:0] wdata_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o,
  output logic [3:0]  last_error_o,
  output logic [63:0] rdata_o,
  output logic        readback_valid_o,
  output logic        matrix_cfg_valid_o,
  output logic [43:0] matrix_din_o,
  output logic [43:0] matrix_cin_o,
  input  logic [43:0] matrix_dout_i,
  input  logic [43:0] matrix_cout_i
);

  localparam logic [2:0] OP_NOP             = 3'd0;
  localparam logic [2:0] OP_WRITE_COLUMN_64 = 3'd1;
  localparam logic [2:0] OP_READ_COLUMN_64  = 3'd2;
  localparam logic [2:0] OP_GLOBAL_FILL_0   = 3'd3;
  localparam logic [2:0] OP_GLOBAL_FILL_1   = 3'd4;

  localparam logic [3:0] ERR_NONE        = 4'd0;
  localparam logic [3:0] ERR_BUSY        = 4'd1;
  localparam logic [3:0] ERR_INVALID_OP  = 4'd2;
  localparam logic [3:0] ERR_INVALID_COL = 4'd3;
  localparam logic [3:0] ERR_CFG_RESET   = 4'd4;
  localparam logic [3:0] ERR_COUT_TIMEOUT = 4'd5;
  localparam int unsigned COUT_TIMEOUT_CYCLES = 16;

  typedef enum logic [2:0] {
    CFG_IDLE       = 3'd0,
    CFG_SETUP      = 3'd1,
    CFG_PULSE_HIGH = 3'd2,
    CFG_WAIT_COUT  = 3'd3
  } cfg_state_e;

  logic [2:0]  cmd_op_hold_sys;
  logic [5:0]  col_hold_sys;
  logic [63:0] wdata_hold_sys;
  logic        cmd_req_tgl_sys;
  logic        cmd_done_tgl_cfg;
  logic        cmd_done_meta_sys, cmd_done_sync_sys, cmd_done_sync_sys_q;
  logic        cfg_rst_meta_sys, cfg_rst_sync_sys;

  logic        cmd_req_meta_cfg, cmd_req_sync_cfg, cmd_req_sync_cfg_q;
  logic [2:0]  op_cfg;
  logic [5:0]  col_cfg;
  logic [63:0] wdata_cfg;
  logic        cmd_pending_cfg;
  logic [2:0]  pending_op_cfg;
  logic [5:0]  pending_col_cfg;
  logic [63:0] pending_wdata_cfg;
  logic [63:0] rdata_shift_cfg;
  logic [6:0]  bit_idx_cfg;
  logic [4:0]  cout_timeout_ctr_cfg;
  cfg_state_e  cfg_state_q;
  logic        ret_error_cfg;
  logic [3:0]  ret_last_error_cfg;
  logic [63:0] ret_rdata_cfg;
  logic        ret_readback_valid_cfg;
  logic        ret_matrix_cfg_valid_cfg;
  logic [43:0] cout_capture_arm_cfg;
  logic [43:0] cout_capture_tgl_async_vec;
  logic [43:0] cout_capture_data_async_vec;
  logic [43:0] cout_tgl_meta_cfg;
  logic [43:0] cout_tgl_sync_cfg;
  logic [43:0] cout_tgl_seen_cfg;
  logic [43:0] cout_data_meta_cfg;
  logic [43:0] cout_data_sync_cfg;
  logic [43:0] active_cout_mask_cfg;
  logic [5:0]  readback_col_cfg;
  logic        selected_cout_seen;
  logic        selected_cout_data;
  logic [63:0] rdata_with_cout_sample;

  wire op_valid_sys =
      (cmd_op_i == OP_WRITE_COLUMN_64) ||
      (cmd_op_i == OP_READ_COLUMN_64)  ||
      (cmd_op_i == OP_GLOBAL_FILL_0)   ||
      (cmd_op_i == OP_GLOBAL_FILL_1);
  wire col_valid_sys = (col_idx_i < 6'd44);

  wire cfg_cmd_seen = (cmd_req_sync_cfg != cmd_req_sync_cfg_q);
  wire sys_done_seen = (cmd_done_sync_sys != cmd_done_sync_sys_q);

  always_comb begin
    active_cout_mask_cfg = '0;
    readback_col_cfg = (op_cfg == OP_GLOBAL_FILL_0 ||
                        op_cfg == OP_GLOBAL_FILL_1) ? 6'd0 : col_cfg;

    unique case (op_cfg)
      OP_WRITE_COLUMN_64,
      OP_READ_COLUMN_64: begin
        if (col_cfg < 6'd44)
          active_cout_mask_cfg[col_cfg] = 1'b1;
      end
      OP_GLOBAL_FILL_0,
      OP_GLOBAL_FILL_1: begin
        active_cout_mask_cfg = {44{1'b1}};
      end
      default: active_cout_mask_cfg = '0;
    endcase

    selected_cout_seen = 1'b0;
    selected_cout_data = 1'b0;
    if (readback_col_cfg < 6'd44) begin
      selected_cout_seen =
          (cout_tgl_sync_cfg[readback_col_cfg] !=
           cout_tgl_seen_cfg[readback_col_cfg]);
      selected_cout_data = cout_data_sync_cfg[readback_col_cfg];
    end

    rdata_with_cout_sample = rdata_shift_cfg;
    if (bit_idx_cfg < 7'd64)
      rdata_with_cout_sample[bit_idx_cfg[5:0]] = selected_cout_data;
  end

  genvar cout_col;
  generate
    for (cout_col = 0; cout_col < 44; cout_col++) begin : g_cout_sampler
      spadmic_matrix_cout_bit_sampler u_cout_bit_sampler (
        .rst_n          (rst_cfg_n),
        .cout_i         (matrix_cout_i[cout_col]),
        .arm_i          (cout_capture_arm_cfg[cout_col]),
        .dout_i         (matrix_dout_i[cout_col]),
        .capture_tgl_o  (cout_capture_tgl_async_vec[cout_col]),
        .capture_data_o (cout_capture_data_async_vec[cout_col])
      );
    end
  endgenerate

  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      cmd_op_hold_sys       <= OP_NOP;
      col_hold_sys          <= '0;
      wdata_hold_sys        <= '0;
      cmd_req_tgl_sys       <= 1'b0;
      cmd_done_meta_sys     <= 1'b0;
      cmd_done_sync_sys     <= 1'b0;
      cmd_done_sync_sys_q   <= 1'b0;
      cfg_rst_meta_sys      <= 1'b0;
      cfg_rst_sync_sys      <= 1'b0;
      busy_o                <= 1'b0;
      done_o                <= 1'b0;
      error_o               <= 1'b0;
      last_error_o          <= ERR_NONE;
      rdata_o               <= '0;
      readback_valid_o      <= 1'b0;
      matrix_cfg_valid_o    <= 1'b0;
    end else begin
      done_o <= 1'b0;

      cmd_done_meta_sys   <= cmd_done_tgl_cfg;
      cmd_done_sync_sys   <= cmd_done_meta_sys;
      cmd_done_sync_sys_q <= cmd_done_sync_sys;
      cfg_rst_meta_sys    <= rst_cfg_n;
      cfg_rst_sync_sys    <= cfg_rst_meta_sys;

      if (!cfg_rst_sync_sys) begin
        cmd_req_tgl_sys    <= 1'b0;
        cmd_op_hold_sys    <= OP_NOP;
        col_hold_sys       <= '0;
        wdata_hold_sys     <= '0;
        if (busy_o) begin
          busy_o             <= 1'b0;
          done_o             <= 1'b1;
          error_o            <= 1'b1;
          last_error_o       <= ERR_CFG_RESET;
          rdata_o            <= '0;
          readback_valid_o   <= 1'b0;
          matrix_cfg_valid_o <= 1'b0;
        end
      end

      if (cmd_start_i && cfg_rst_sync_sys) begin
        if (busy_o) begin
          done_o       <= 1'b1;
          error_o      <= 1'b1;
          last_error_o <= ERR_BUSY;
          rdata_o      <= '0;
          readback_valid_o   <= 1'b0;
          matrix_cfg_valid_o <= 1'b0;
        end else if (!op_valid_sys) begin
          done_o       <= 1'b1;
          error_o      <= 1'b1;
          last_error_o <= ERR_INVALID_OP;
          rdata_o      <= '0;
          readback_valid_o   <= 1'b0;
          matrix_cfg_valid_o <= 1'b0;
        end else if (((cmd_op_i == OP_WRITE_COLUMN_64) ||
                      (cmd_op_i == OP_READ_COLUMN_64)) &&
                     !col_valid_sys) begin
          done_o       <= 1'b1;
          error_o      <= 1'b1;
          last_error_o <= ERR_INVALID_COL;
          rdata_o      <= '0;
          readback_valid_o   <= 1'b0;
          matrix_cfg_valid_o <= 1'b0;
        end else begin
          cmd_op_hold_sys    <= cmd_op_i;
          col_hold_sys       <= col_idx_i;
          wdata_hold_sys     <= wdata_i;
          cmd_req_tgl_sys    <= ~cmd_req_tgl_sys;
          busy_o             <= 1'b1;
          error_o            <= 1'b0;
          last_error_o       <= ERR_NONE;
          readback_valid_o   <= 1'b0;
          matrix_cfg_valid_o <= 1'b0;
        end
      end

      // Completion has final priority over a same-cycle direct command pulse.
      // The CSR front-end only starts commands when busy is low; this protects
      // the standalone controller from corrupting returned status/readback if a
      // lower-level testbench or future wrapper violates that rule.
      if (sys_done_seen && cfg_rst_sync_sys) begin
        busy_o             <= 1'b0;
        done_o             <= 1'b1;
        error_o            <= ret_error_cfg;
        last_error_o       <= ret_last_error_cfg;
        rdata_o            <= ret_rdata_cfg;
        readback_valid_o   <= ret_readback_valid_cfg;
        matrix_cfg_valid_o <= ret_matrix_cfg_valid_cfg;
      end
    end
  end

  always_ff @(posedge clk_cfg_40m or negedge rst_cfg_n) begin
    if (!rst_cfg_n) begin
      cmd_req_meta_cfg          <= 1'b0;
      cmd_req_sync_cfg          <= 1'b0;
      cmd_req_sync_cfg_q        <= 1'b0;
      cmd_done_tgl_cfg          <= 1'b0;
      op_cfg                    <= OP_NOP;
      col_cfg                   <= '0;
      wdata_cfg                 <= '0;
      cmd_pending_cfg           <= 1'b0;
      pending_op_cfg            <= OP_NOP;
      pending_col_cfg           <= '0;
      pending_wdata_cfg         <= '0;
      rdata_shift_cfg           <= '0;
      bit_idx_cfg               <= '0;
      cout_timeout_ctr_cfg      <= '0;
      cfg_state_q               <= CFG_IDLE;
      ret_error_cfg             <= 1'b0;
      ret_last_error_cfg        <= ERR_NONE;
      ret_rdata_cfg             <= '0;
      ret_readback_valid_cfg    <= 1'b0;
      ret_matrix_cfg_valid_cfg  <= 1'b0;
      cout_capture_arm_cfg      <= '0;
      cout_tgl_meta_cfg         <= '0;
      cout_tgl_sync_cfg         <= '0;
      cout_tgl_seen_cfg         <= '0;
      cout_data_meta_cfg        <= '0;
      cout_data_sync_cfg        <= '0;
      matrix_din_o              <= '0;
      matrix_cin_o              <= '0;
    end else begin
      cmd_req_meta_cfg   <= cmd_req_tgl_sys;
      cmd_req_sync_cfg   <= cmd_req_meta_cfg;
      cmd_req_sync_cfg_q <= cmd_req_sync_cfg;
      cout_tgl_meta_cfg  <= cout_capture_tgl_async_vec;
      cout_tgl_sync_cfg  <= cout_tgl_meta_cfg;
      cout_data_meta_cfg <= cout_capture_data_async_vec;
      cout_data_sync_cfg <= cout_data_meta_cfg;

      if (cfg_cmd_seen && (cfg_state_q != CFG_IDLE)) begin
        cmd_pending_cfg   <= 1'b1;
        pending_op_cfg    <= cmd_op_hold_sys;
        pending_col_cfg   <= col_hold_sys;
        pending_wdata_cfg <= wdata_hold_sys;
      end

      case (cfg_state_q)
        CFG_IDLE: begin
          matrix_din_o <= '0;
          matrix_cin_o <= '0;
          if (cfg_cmd_seen) begin
            op_cfg          <= cmd_op_hold_sys;
            col_cfg         <= col_hold_sys;
            wdata_cfg       <= wdata_hold_sys;
            rdata_shift_cfg <= '0;
            bit_idx_cfg     <= '0;
            cout_timeout_ctr_cfg <= '0;
            cout_capture_arm_cfg <= '0;
            cfg_state_q     <= CFG_SETUP;
          end else if (cmd_pending_cfg) begin
            op_cfg          <= pending_op_cfg;
            col_cfg         <= pending_col_cfg;
            wdata_cfg       <= pending_wdata_cfg;
            cmd_pending_cfg <= 1'b0;
            rdata_shift_cfg <= '0;
            bit_idx_cfg     <= '0;
            cout_timeout_ctr_cfg <= '0;
            cout_capture_arm_cfg <= '0;
            cfg_state_q     <= CFG_SETUP;
          end
        end

        CFG_SETUP: begin
          matrix_cin_o <= '0;
          matrix_din_o <= '0;
          cout_capture_arm_cfg <= active_cout_mask_cfg;
          cout_tgl_seen_cfg <= cout_tgl_sync_cfg;
          cout_timeout_ctr_cfg <= '0;
          unique case (op_cfg)
            OP_WRITE_COLUMN_64: matrix_din_o[col_cfg] <= wdata_cfg[bit_idx_cfg[5:0]];
            OP_GLOBAL_FILL_0:   matrix_din_o          <= '0;
            OP_GLOBAL_FILL_1:   matrix_din_o          <= {44{1'b1}};
            default:            matrix_din_o          <= '0;
          endcase
          cfg_state_q <= CFG_PULSE_HIGH;
        end

        CFG_PULSE_HIGH: begin
          matrix_cin_o <= '0;
          unique case (op_cfg)
            OP_WRITE_COLUMN_64,
            OP_READ_COLUMN_64:  matrix_cin_o[col_cfg] <= 1'b1;
            OP_GLOBAL_FILL_0,
            OP_GLOBAL_FILL_1:   matrix_cin_o          <= {44{1'b1}};
            default:            matrix_cin_o          <= '0;
          endcase
          cfg_state_q <= CFG_WAIT_COUT;
        end

        CFG_WAIT_COUT: begin
          matrix_cin_o <= '0;
          if (selected_cout_seen) begin
            cout_tgl_seen_cfg[readback_col_cfg] <=
                cout_tgl_sync_cfg[readback_col_cfg];
            rdata_shift_cfg <= rdata_with_cout_sample;
            if (bit_idx_cfg == 7'd63) begin
              matrix_din_o <= '0;
              cout_capture_arm_cfg <= '0;
              ret_error_cfg          <= 1'b0;
              ret_last_error_cfg     <= ERR_NONE;
              ret_readback_valid_cfg <= 1'b1;
              ret_rdata_cfg          <= rdata_with_cout_sample;
              ret_matrix_cfg_valid_cfg <= 1'b1;
              cmd_done_tgl_cfg       <= ~cmd_done_tgl_cfg;
              cfg_state_q            <= CFG_IDLE;
            end else begin
              bit_idx_cfg <= bit_idx_cfg + 7'd1;
              cfg_state_q <= CFG_SETUP;
            end
          end else if (cout_timeout_ctr_cfg >=
                       5'(COUT_TIMEOUT_CYCLES - 1)) begin
            matrix_din_o <= '0;
            cout_capture_arm_cfg <= '0;
            ret_error_cfg          <= 1'b1;
            ret_last_error_cfg     <= ERR_COUT_TIMEOUT;
            ret_readback_valid_cfg <= 1'b0;
            ret_rdata_cfg          <= '0;
            ret_matrix_cfg_valid_cfg <= 1'b0;
            cmd_done_tgl_cfg       <= ~cmd_done_tgl_cfg;
            cfg_state_q            <= CFG_IDLE;
          end else begin
            cout_timeout_ctr_cfg <= cout_timeout_ctr_cfg + 5'd1;
          end
        end

        default: begin
          matrix_din_o <= '0;
          matrix_cin_o <= '0;
          cout_capture_arm_cfg <= '0;
          cfg_state_q  <= CFG_IDLE;
        end
      endcase
    end
  end

endmodule

module spadmic_matrix_cout_bit_sampler (
  input  logic rst_n,
  input  logic cout_i,
  input  logic arm_i,
  input  logic dout_i,
  output logic capture_tgl_o,
  output logic capture_data_o
);
  always_ff @(posedge cout_i or negedge rst_n) begin
    if (!rst_n) begin
      capture_tgl_o  <= 1'b0;
      capture_data_o <= 1'b0;
    end else if (arm_i) begin
      capture_data_o <= dout_i;
      capture_tgl_o  <= ~capture_tgl_o;
    end
  end
endmodule

`default_nettype wire
