// =============================================================================
// Project  : SPADMIC I2C Control Plane
// File     : spadmic_i2c_slave.sv
// Purpose  : Synchronized I2C slave that converts register-pointer reads/writes
//            into local CSR-style transactions in the clk_sys domain.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_i2c_slave #(
  parameter logic [6:0] I2C_ADDR = spadmic_pkg::SPADMIC_I2C_ADDR
) (
  input  wire                                clk_sys,
  input  wire                                rst_n,
  input  wire                                i2c_scl_i,
  input  wire                                i2c_sda_i,
  output logic                               i2c_sda_oe_o,

  output wire                                txn_valid_o,
  output wire                                txn_write_o,
  output wire [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] txn_addr_o,
  output wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] txn_wdata_o,
  input  wire                                txn_ready_i,

  input  wire                                txn_rsp_valid_i,
  input  wire [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] txn_rsp_rdata_i,
  input  wire                                txn_rsp_err_i,
  output wire                                txn_rsp_ready_o
);
  import spadmic_pkg::*;

  typedef enum logic [4:0] {
    ST_IDLE,
    ST_DEV_ADDR,
    ST_ACK_ADDR,
    ST_PTR_HI,
    ST_ACK_PTR_HI,
    ST_PTR_LO,
    ST_ACK_PTR_LO,
    ST_WAIT_RW_RESTART,
    ST_WRITE_D0,
    ST_ACK_WRITE_D0,
    ST_WRITE_D1,
    ST_ACK_WRITE_D1,
    ST_WRITE_D2,
    ST_ACK_WRITE_D2,
    ST_WRITE_D3,
    ST_ACK_WRITE_D3,
    ST_READ_WAIT_RSP,
    ST_READ_D0,
    ST_READ_ACK_D0,
    ST_READ_D1,
    ST_READ_ACK_D1,
    ST_READ_D2,
    ST_READ_ACK_D2,
    ST_READ_D3,
    ST_READ_ACK_D3
  } i2c_state_e;

  i2c_state_e state_q;
  logic [1:0] scl_sync_q;
  logic [1:0] sda_sync_q;
  logic       scl_q;
  logic       sda_q;
  logic [2:0] bit_idx_q;
  logic [7:0] rx_shift_q;
  logic [7:0] tx_shift_q;
  logic       addr_match_q;
  logic       rw_q;
  // ACK bits must remain driven through the full SCL-high phase and only release
  // on the following SCL-low phase, otherwise the slave can self-generate STOPs.
  logic       ack_seen_high_q;
  logic       pointer_valid_q;
  logic [SPADMIC_CSR_ADDR_W-1:0] pointer_addr_q;
  logic [SPADMIC_CSR_DATA_W-1:0] write_data_q;
  logic [SPADMIC_CSR_DATA_W-1:0] read_data_q;
  logic       cmd_valid_q;
  logic       cmd_write_q;
  logic [SPADMIC_CSR_ADDR_W-1:0] cmd_addr_q;
  logic [SPADMIC_CSR_DATA_W-1:0] cmd_wdata_q;

  wire scl_sync  = scl_sync_q[1];
  wire sda_sync  = sda_sync_q[1];
  wire scl_rise  = ~scl_q &  scl_sync;
  wire scl_fall  =  scl_q & ~scl_sync;
  wire sda_rise  = ~sda_q &  sda_sync;
  wire sda_fall  =  sda_q & ~sda_sync;
  wire start_cond = sda_fall & scl_sync;
  wire stop_cond  = sda_rise & scl_sync;

  assign txn_valid_o     = cmd_valid_q;
  assign txn_write_o     = cmd_write_q;
  assign txn_addr_o      = cmd_addr_q;
  assign txn_wdata_o     = cmd_wdata_q;
  assign txn_rsp_ready_o = 1'b1;

  // SCL/SDA are double-synchronized into clk_sys before the slave FSM decodes
  // START/STOP conditions and bit transfers.
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      scl_sync_q      <= 2'b11;
      sda_sync_q      <= 2'b11;
      scl_q           <= 1'b1;
      sda_q           <= 1'b1;
      state_q         <= ST_IDLE;
      i2c_sda_oe_o    <= 1'b0;
      bit_idx_q       <= 3'd7;
      rx_shift_q      <= 8'h00;
      tx_shift_q      <= 8'h00;
      addr_match_q    <= 1'b0;
      rw_q            <= 1'b0;
      ack_seen_high_q <= 1'b0;
      pointer_valid_q <= 1'b0;
      pointer_addr_q  <= '0;
      write_data_q    <= '0;
      read_data_q     <= '0;
      cmd_valid_q     <= 1'b0;
      cmd_write_q     <= 1'b0;
      cmd_addr_q      <= '0;
      cmd_wdata_q     <= '0;
    end else begin
      logic [7:0] rx_byte;

      scl_sync_q <= {scl_sync_q[0], i2c_scl_i};
      sda_sync_q <= {sda_sync_q[0], i2c_sda_i};
      scl_q      <= scl_sync;
      sda_q      <= sda_sync;

      if (cmd_valid_q && txn_ready_i)
        cmd_valid_q <= 1'b0;

      if (start_cond) begin
        state_q      <= ST_DEV_ADDR;
        bit_idx_q    <= 3'd7;
        rx_shift_q   <= 8'h00;
        ack_seen_high_q <= 1'b0;
        i2c_sda_oe_o <= 1'b0;
      end else if (stop_cond) begin
        state_q      <= ST_IDLE;
        ack_seen_high_q <= 1'b0;
        i2c_sda_oe_o <= 1'b0;
      end else begin
        case (state_q)
          ST_IDLE: begin
            i2c_sda_oe_o <= 1'b0;
          end

          ST_DEV_ADDR: if (scl_rise) begin
            rx_byte = {rx_shift_q[6:0], sda_sync};
            rx_shift_q <= rx_byte;
            if (bit_idx_q == 3'd0) begin
              addr_match_q <= (rx_byte[7:1] == I2C_ADDR);
              rw_q         <= rx_byte[0];
              state_q      <= ST_ACK_ADDR;
            end else begin
              bit_idx_q <= bit_idx_q - 3'd1;
            end
          end

          ST_ACK_ADDR: begin
            if (scl_fall) begin
              if (!ack_seen_high_q) begin
                i2c_sda_oe_o <= addr_match_q
                              & (~rw_q | (rw_q & pointer_valid_q));
              end else begin
                ack_seen_high_q <= 1'b0;
                i2c_sda_oe_o    <= 1'b0;
                if (!addr_match_q || (rw_q && !pointer_valid_q)) begin
                  state_q <= ST_IDLE;
                end else if (!rw_q) begin
                  state_q    <= ST_PTR_HI;
                  bit_idx_q  <= 3'd7;
                  rx_shift_q <= 8'h00;
                end else begin
                  cmd_valid_q <= 1'b1;
                  cmd_write_q <= 1'b0;
                  cmd_addr_q  <= pointer_addr_q;
                  cmd_wdata_q <= '0;
                  state_q     <= ST_READ_WAIT_RSP;
                end
              end
            end else if (scl_rise) begin
              ack_seen_high_q <= 1'b1;
            end
          end

          ST_PTR_HI: if (scl_rise) begin
            rx_byte = {rx_shift_q[6:0], sda_sync};
            rx_shift_q <= rx_byte;
            if (bit_idx_q == 3'd0) begin
              pointer_addr_q <= {rx_byte[3:0], 8'h00};
              state_q <= ST_ACK_PTR_HI;
            end else begin
              bit_idx_q <= bit_idx_q - 3'd1;
            end
          end

          ST_ACK_PTR_HI: begin
            if (scl_fall) begin
              if (!ack_seen_high_q) begin
                i2c_sda_oe_o <= 1'b1;
              end else begin
                ack_seen_high_q <= 1'b0;
                i2c_sda_oe_o    <= 1'b0;
                state_q         <= ST_PTR_LO;
                bit_idx_q       <= 3'd7;
                rx_shift_q      <= 8'h00;
              end
            end else if (scl_rise) begin
              ack_seen_high_q <= 1'b1;
            end
          end

          ST_PTR_LO: if (scl_rise) begin
            rx_byte = {rx_shift_q[6:0], sda_sync};
            rx_shift_q <= rx_byte;
            if (bit_idx_q == 3'd0) begin
              pointer_addr_q[7:0] <= rx_byte;
              pointer_valid_q     <= 1'b1;
              state_q             <= ST_ACK_PTR_LO;
            end else begin
              bit_idx_q <= bit_idx_q - 3'd1;
            end
          end

          ST_ACK_PTR_LO: begin
            if (scl_fall) begin
              if (!ack_seen_high_q) begin
                i2c_sda_oe_o <= 1'b1;
              end else begin
                ack_seen_high_q <= 1'b0;
                i2c_sda_oe_o    <= 1'b0;
                state_q         <= ST_WAIT_RW_RESTART;
                bit_idx_q       <= 3'd7;
                rx_shift_q      <= 8'h00;
              end
            end else if (scl_rise) begin
              ack_seen_high_q <= 1'b1;
            end
          end

          ST_WAIT_RW_RESTART: if (scl_rise) begin
            rx_shift_q <= {rx_shift_q[6:0], sda_sync};
            if (bit_idx_q == 3'd7)
              state_q <= ST_WRITE_D0;
            if (bit_idx_q == 3'd0) begin
              write_data_q[31:24] <= {rx_shift_q[6:0], sda_sync};
              state_q             <= ST_ACK_WRITE_D0;
            end else begin
              bit_idx_q <= bit_idx_q - 3'd1;
            end
          end

          ST_WRITE_D0: if (scl_rise) begin
            rx_byte = {rx_shift_q[6:0], sda_sync};
            rx_shift_q <= rx_byte;
            if (bit_idx_q == 3'd0) begin
              write_data_q[31:24] <= rx_byte;
              state_q             <= ST_ACK_WRITE_D0;
            end else begin
              bit_idx_q <= bit_idx_q - 3'd1;
            end
          end

          ST_ACK_WRITE_D0: begin
            if (scl_fall) begin
              if (!ack_seen_high_q) begin
                i2c_sda_oe_o <= 1'b1;
              end else begin
                ack_seen_high_q <= 1'b0;
                i2c_sda_oe_o    <= 1'b0;
                state_q         <= ST_WRITE_D1;
                bit_idx_q       <= 3'd7;
                rx_shift_q      <= 8'h00;
              end
            end else if (scl_rise) begin
              ack_seen_high_q <= 1'b1;
            end
          end

          ST_WRITE_D1: if (scl_rise) begin
            rx_byte = {rx_shift_q[6:0], sda_sync};
            rx_shift_q <= rx_byte;
            if (bit_idx_q == 3'd0) begin
              write_data_q[23:16] <= rx_byte;
              state_q             <= ST_ACK_WRITE_D1;
            end else begin
              bit_idx_q <= bit_idx_q - 3'd1;
            end
          end

          ST_ACK_WRITE_D1: begin
            if (scl_fall) begin
              if (!ack_seen_high_q) begin
                i2c_sda_oe_o <= 1'b1;
              end else begin
                ack_seen_high_q <= 1'b0;
                i2c_sda_oe_o    <= 1'b0;
                state_q         <= ST_WRITE_D2;
                bit_idx_q       <= 3'd7;
                rx_shift_q      <= 8'h00;
              end
            end else if (scl_rise) begin
              ack_seen_high_q <= 1'b1;
            end
          end

          ST_WRITE_D2: if (scl_rise) begin
            rx_byte = {rx_shift_q[6:0], sda_sync};
            rx_shift_q <= rx_byte;
            if (bit_idx_q == 3'd0) begin
              write_data_q[15:8] <= rx_byte;
              state_q            <= ST_ACK_WRITE_D2;
            end else begin
              bit_idx_q <= bit_idx_q - 3'd1;
            end
          end

          ST_ACK_WRITE_D2: begin
            if (scl_fall) begin
              if (!ack_seen_high_q) begin
                i2c_sda_oe_o <= 1'b1;
              end else begin
                ack_seen_high_q <= 1'b0;
                i2c_sda_oe_o    <= 1'b0;
                state_q         <= ST_WRITE_D3;
                bit_idx_q       <= 3'd7;
                rx_shift_q      <= 8'h00;
              end
            end else if (scl_rise) begin
              ack_seen_high_q <= 1'b1;
            end
          end

          ST_WRITE_D3: if (scl_rise) begin
            rx_byte = {rx_shift_q[6:0], sda_sync};
            rx_shift_q <= rx_byte;
            if (bit_idx_q == 3'd0) begin
              write_data_q[7:0] <= rx_byte;
              state_q           <= ST_ACK_WRITE_D3;
            end else begin
              bit_idx_q <= bit_idx_q - 3'd1;
            end
          end

          ST_ACK_WRITE_D3: begin
            if (scl_fall) begin
              if (!ack_seen_high_q) begin
                i2c_sda_oe_o <= 1'b1;
              end else begin
                ack_seen_high_q <= 1'b0;
                i2c_sda_oe_o    <= 1'b0;
                cmd_valid_q     <= 1'b1;
                cmd_write_q     <= 1'b1;
                cmd_addr_q      <= pointer_addr_q;
                cmd_wdata_q     <= write_data_q;
                state_q         <= ST_IDLE;
              end
            end else if (scl_rise) begin
              ack_seen_high_q <= 1'b1;
            end
          end

          ST_READ_WAIT_RSP: begin
            if (txn_rsp_valid_i) begin
              read_data_q  <= txn_rsp_err_i ? '0 : txn_rsp_rdata_i;
              tx_shift_q   <= txn_rsp_err_i ? 8'h00 : txn_rsp_rdata_i[31:24];
              bit_idx_q    <= 3'd7;
              i2c_sda_oe_o <= txn_rsp_err_i ? 1'b1 : ~txn_rsp_rdata_i[31];
              state_q      <= ST_READ_D0;
            end
          end

          ST_READ_D0, ST_READ_D1, ST_READ_D2, ST_READ_D3: begin
            if (scl_fall) begin
              i2c_sda_oe_o <= ~tx_shift_q[bit_idx_q];
            end else if (scl_rise) begin
              if (bit_idx_q == 3'd0) begin
                case (state_q)
                  ST_READ_D0: state_q <= ST_READ_ACK_D0;
                  ST_READ_D1: state_q <= ST_READ_ACK_D1;
                  ST_READ_D2: state_q <= ST_READ_ACK_D2;
                  default:    state_q <= ST_READ_ACK_D3;
                endcase
              end else begin
                bit_idx_q <= bit_idx_q - 3'd1;
              end
            end
          end

          ST_READ_ACK_D0, ST_READ_ACK_D1, ST_READ_ACK_D2, ST_READ_ACK_D3: begin
            if (scl_fall) begin
              i2c_sda_oe_o <= 1'b0;
            end else if (scl_rise) begin
              if (sda_sync) begin
                state_q <= ST_IDLE;
              end else begin
                case (state_q)
                  ST_READ_ACK_D0: begin
                    tx_shift_q <= read_data_q[23:16];
                    bit_idx_q  <= 3'd7;
                    state_q    <= ST_READ_D1;
                  end
                  ST_READ_ACK_D1: begin
                    tx_shift_q <= read_data_q[15:8];
                    bit_idx_q  <= 3'd7;
                    state_q    <= ST_READ_D2;
                  end
                  ST_READ_ACK_D2: begin
                    tx_shift_q <= read_data_q[7:0];
                    bit_idx_q  <= 3'd7;
                    state_q    <= ST_READ_D3;
                  end
                  default: begin
                    state_q <= ST_IDLE;
                  end
                endcase
              end
            end
          end

          default: state_q <= ST_IDLE;
        endcase
      end
    end
  end

endmodule

`default_nettype wire
