`timescale 1ps/1ps
`default_nettype none

module spadmic_i2c_csr_bridge (
  input  wire                                clk_sys,
  input  wire                                rst_n,

  input  wire                                i2c_cmd_valid_i,
  input  wire                                i2c_cmd_write_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] i2c_cmd_addr_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] i2c_cmd_wdata_i,
  output wire                                i2c_cmd_ready_o,

  output logic                               i2c_rsp_valid_o,
  output logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] i2c_rsp_rdata_o,
  output logic                               i2c_rsp_err_o,
  input  wire                                i2c_rsp_ready_i,

  output wire                                csr_req_valid_o,
  output wire                                csr_req_write_o,
  output wire [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] csr_req_addr_o,
  output wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_req_wdata_o,
  input  wire                                csr_req_ready_i,

  input  wire                                csr_rsp_valid_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_rsp_rdata_i,
  input  wire                                csr_rsp_err_i,
  output wire                                csr_rsp_ready_o
);
  typedef enum logic [1:0] {
    ST_IDLE,
    ST_WAIT_RSP,
    ST_HOLD_RSP
  } bridge_state_e;

  bridge_state_e state_q;

  assign csr_req_valid_o = i2c_cmd_valid_i & (state_q == ST_IDLE);
  assign csr_req_write_o = i2c_cmd_write_i;
  assign csr_req_addr_o  = i2c_cmd_addr_i;
  assign csr_req_wdata_o = i2c_cmd_wdata_i;
  assign i2c_cmd_ready_o = (state_q == ST_IDLE) & csr_req_ready_i;
  assign csr_rsp_ready_o = (state_q == ST_WAIT_RSP);

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      state_q          <= ST_IDLE;
      i2c_rsp_valid_o  <= 1'b0;
      i2c_rsp_rdata_o  <= '0;
      i2c_rsp_err_o    <= 1'b0;
    end else begin
      case (state_q)
        ST_IDLE: begin
          i2c_rsp_valid_o <= 1'b0;
          if (i2c_cmd_valid_i && csr_req_ready_i)
            state_q <= ST_WAIT_RSP;
        end

        ST_WAIT_RSP: begin
          if (csr_rsp_valid_i) begin
            i2c_rsp_valid_o <= 1'b1;
            i2c_rsp_rdata_o <= csr_rsp_rdata_i;
            i2c_rsp_err_o   <= csr_rsp_err_i;
            state_q         <= ST_HOLD_RSP;
          end
        end

        ST_HOLD_RSP: begin
          if (i2c_rsp_valid_o && i2c_rsp_ready_i) begin
            i2c_rsp_valid_o <= 1'b0;
            state_q         <= ST_IDLE;
          end
        end

        default: state_q <= ST_IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire
