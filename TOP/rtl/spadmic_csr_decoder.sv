`timescale 1ps/1ps
`default_nettype none

module spadmic_csr_decoder (
  input  wire                                clk_sys,
  input  wire                                rst_n,
  input  wire                                csr_req_valid_i,
  input  wire                                csr_req_write_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] csr_req_addr_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_req_wdata_i,
  output wire                                csr_req_ready_o,

  output logic                               csr_rsp_valid_o,
  output logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_rsp_rdata_o,
  output logic                               csr_rsp_err_o,
  input  wire                                csr_rsp_ready_i,

  output wire                                global_csr_valid_o,
  output wire                                global_csr_write_o,
  output wire [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] global_csr_addr_o,
  output wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] global_csr_wdata_o,
  input  wire                                global_csr_ready_i,
  input  wire                                global_csr_rvalid_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] global_csr_rdata_i,

  output wire                                pos_csr_valid_o,
  output wire                                pos_csr_write_o,
  output wire [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] pos_csr_addr_o,
  output wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] pos_csr_wdata_o,
  input  wire                                pos_csr_ready_i,
  input  wire                                pos_csr_rvalid_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] pos_csr_rdata_i,

  output wire                                x_csr_valid_o,
  output wire                                x_csr_write_o,
  output wire [mptdc_pkg::CSR_ADDR_W-1:0]    x_csr_addr_o,
  output wire [mptdc_pkg::CSR_DATA_W-1:0]    x_csr_wdata_o,
  input  wire                                x_csr_ready_i,
  input  wire                                x_csr_rvalid_i,
  input  wire [mptdc_pkg::CSR_DATA_W-1:0]    x_csr_rdata_i,

  output wire                                y_csr_valid_o,
  output wire                                y_csr_write_o,
  output wire [mptdc_pkg::CSR_ADDR_W-1:0]    y_csr_addr_o,
  output wire [mptdc_pkg::CSR_DATA_W-1:0]    y_csr_wdata_o,
  input  wire                                y_csr_ready_i,
  input  wire                                y_csr_rvalid_i,
  input  wire [mptdc_pkg::CSR_DATA_W-1:0]    y_csr_rdata_i,

  output wire                                z_csr_valid_o,
  output wire                                z_csr_write_o,
  output wire [mptdc_pkg::CSR_ADDR_W-1:0]    z_csr_addr_o,
  output wire [mptdc_pkg::CSR_DATA_W-1:0]    z_csr_wdata_o,
  input  wire                                z_csr_ready_i,
  input  wire                                z_csr_rvalid_i,
  input  wire [mptdc_pkg::CSR_DATA_W-1:0]    z_csr_rdata_i
);
  import spadmic_pkg::*;

  // Safety timeout for downstream CSR read responses (in clk_sys cycles).
  // Prevents bus hang if a downstream slave never responds.
  localparam int unsigned WAIT_TIMEOUT_MAX = 15;

  typedef enum logic [2:0] {
    TGT_NONE   = 3'd0,
    TGT_GLOBAL = 3'd1,
    TGT_X      = 3'd2,
    TGT_Y      = 3'd3,
    TGT_Z      = 3'd4,
    TGT_POS    = 3'd5,
    TGT_ERR    = 3'd6
  } csr_target_e;

  typedef enum logic [1:0] {
    ST_IDLE,
    ST_WAIT_READ,
    ST_HOLD_RSP
  } dec_state_e;

  dec_state_e state_q;
  csr_target_e target_sel;
  csr_target_e pending_target_q;
  logic pending_write_q;
  logic [$clog2(WAIT_TIMEOUT_MAX+1)-1:0] wait_timeout_q;

  wire accept_req = csr_req_valid_i & csr_req_ready_o;

  always_comb begin
    case (csr_req_addr_i[11:8])
      SPADMIC_REGION_GLOBAL:   target_sel = TGT_GLOBAL;
      SPADMIC_REGION_TDC_X:    target_sel = TGT_X;
      SPADMIC_REGION_TDC_Y:    target_sel = TGT_Y;
      SPADMIC_REGION_TDC_Z:    target_sel = TGT_Z;
      SPADMIC_REGION_POSITION: target_sel = TGT_POS;
      default:                 target_sel = TGT_ERR;
    endcase
  end

  assign csr_req_ready_o   = (state_q == ST_IDLE);
  assign global_csr_addr_o = csr_req_addr_i;
  assign global_csr_wdata_o = csr_req_wdata_i;
  assign pos_csr_addr_o    = csr_req_addr_i;
  assign pos_csr_wdata_o   = csr_req_wdata_i;
  assign x_csr_addr_o      = csr_req_addr_i[mptdc_pkg::CSR_ADDR_W-1:0];
  assign y_csr_addr_o      = csr_req_addr_i[mptdc_pkg::CSR_ADDR_W-1:0];
  assign z_csr_addr_o      = csr_req_addr_i[mptdc_pkg::CSR_ADDR_W-1:0];
  assign x_csr_wdata_o     = csr_req_wdata_i;
  assign y_csr_wdata_o     = csr_req_wdata_i;
  assign z_csr_wdata_o     = csr_req_wdata_i;

  assign global_csr_valid_o = accept_req & (target_sel == TGT_GLOBAL);
  assign global_csr_write_o = csr_req_write_i;
  assign pos_csr_valid_o    = accept_req & (target_sel == TGT_POS);
  assign pos_csr_write_o    = csr_req_write_i;
  assign x_csr_valid_o      = accept_req & (target_sel == TGT_X);
  assign x_csr_write_o      = csr_req_write_i;
  assign y_csr_valid_o      = accept_req & (target_sel == TGT_Y);
  assign y_csr_write_o      = csr_req_write_i;
  assign z_csr_valid_o      = accept_req & (target_sel == TGT_Z);
  assign z_csr_write_o      = csr_req_write_i;

  // Downstream response mux (combinational, module-level)
  logic downstream_rvalid;
  logic [SPADMIC_CSR_DATA_W-1:0] downstream_rdata;

  always_comb begin
    downstream_rvalid = 1'b0;
    downstream_rdata  = '0;
    case (pending_target_q)
      TGT_GLOBAL: begin
        downstream_rvalid = global_csr_rvalid_i;
        downstream_rdata  = global_csr_rdata_i;
      end
      TGT_X: begin
        downstream_rvalid = x_csr_rvalid_i;
        downstream_rdata  = {x_csr_rdata_i};
      end
      TGT_Y: begin
        downstream_rvalid = y_csr_rvalid_i;
        downstream_rdata  = {y_csr_rdata_i};
      end
      TGT_Z: begin
        downstream_rvalid = z_csr_rvalid_i;
        downstream_rdata  = {z_csr_rdata_i};
      end
      TGT_POS: begin
        downstream_rvalid = pos_csr_rvalid_i;
        downstream_rdata  = pos_csr_rdata_i;
      end
      default: begin
        downstream_rvalid = 1'b1;
      end
    endcase
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q          <= ST_IDLE;
      pending_target_q <= TGT_NONE;
      pending_write_q  <= 1'b0;
      wait_timeout_q   <= '0;
      csr_rsp_valid_o  <= 1'b0;
      csr_rsp_rdata_o  <= '0;
      csr_rsp_err_o    <= 1'b0;
    end else begin
      case (state_q)
        ST_IDLE: begin
          csr_rsp_valid_o <= 1'b0;
          if (accept_req) begin
            pending_target_q <= target_sel;
            pending_write_q  <= csr_req_write_i;
            if (target_sel == TGT_ERR) begin
              csr_rsp_valid_o <= 1'b1;
              csr_rsp_rdata_o <= '0;
              csr_rsp_err_o   <= 1'b1;
              state_q         <= ST_HOLD_RSP;
            end else if (csr_req_write_i) begin
              csr_rsp_valid_o <= 1'b1;
              csr_rsp_rdata_o <= '0;
              csr_rsp_err_o   <= 1'b0;
              state_q         <= ST_HOLD_RSP;
            end else begin
              state_q <= ST_WAIT_READ;
              wait_timeout_q <= '0;
            end
          end
        end

        ST_WAIT_READ: begin
          if (downstream_rvalid) begin
            csr_rsp_valid_o <= 1'b1;
            csr_rsp_rdata_o <= downstream_rdata;
            csr_rsp_err_o   <= (pending_target_q == TGT_ERR) || (pending_target_q == TGT_NONE);
            state_q         <= ST_HOLD_RSP;
          end else if (wait_timeout_q == WAIT_TIMEOUT_MAX[$bits(wait_timeout_q)-1:0]) begin
            csr_rsp_valid_o <= 1'b1;
            csr_rsp_rdata_o <= '0;
            csr_rsp_err_o   <= 1'b1;
            state_q         <= ST_HOLD_RSP;
          end else begin
            wait_timeout_q <= wait_timeout_q + 1'b1;
          end
        end

        ST_HOLD_RSP: begin
          if (csr_rsp_valid_o && csr_rsp_ready_i) begin
            csr_rsp_valid_o <= 1'b0;
            state_q         <= ST_IDLE;
          end
        end

        default: state_q <= ST_IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire
