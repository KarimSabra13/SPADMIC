`timescale 1ps/1ps
`default_nettype none

module spadmic_top_v1 (
  input  wire                                clk_sys,
  input  wire                                clk_ref_40m,
  input  wire                                async_rst_n,

  input  wire                                i2c_scl_i,
  input  wire                                i2c_sda_i,
  output wire                                i2c_sda_oe_o,

  input  wire                                spad_x_event_async_i,
  input  wire                                spad_y_event_async_i,
  input  wire                                spad_z_event_async_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] x_lines_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] y_lines_i,
  input  wire [spadmic_pkg::SPADMIC_LINE_W-1:0] z_lines_i,

  input  wire                                tdc_tx_ready_i,
  output wire                                tdc_tx_valid_o,
  output wire [mptdc_pkg::NARROW_W-1:0]      tdc_tx_data_o,

  input  wire                                pos_tx_ready_i,
  output wire                                pos_tx_valid_o,
  output wire [mptdc_pkg::NARROW_W-1:0]      pos_tx_data_o,

  output wire [2:0]                          tdc_stop_armed_o,
  output wire                                tdc_shared_busy_o,
  output wire                                position_busy_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  wire rst_sys_n;

  wire i2c_cmd_valid;
  wire i2c_cmd_write;
  wire [SPADMIC_CSR_ADDR_W-1:0] i2c_cmd_addr;
  wire [SPADMIC_CSR_DATA_W-1:0] i2c_cmd_wdata;
  wire i2c_cmd_ready;
  wire i2c_rsp_valid;
  wire [SPADMIC_CSR_DATA_W-1:0] i2c_rsp_rdata;
  wire i2c_rsp_err;
  wire i2c_rsp_ready;

  wire csr_req_valid;
  wire csr_req_write;
  wire [SPADMIC_CSR_ADDR_W-1:0] csr_req_addr;
  wire [SPADMIC_CSR_DATA_W-1:0] csr_req_wdata;
  wire csr_req_ready;
  wire csr_rsp_valid;
  wire [SPADMIC_CSR_DATA_W-1:0] csr_rsp_rdata;
  wire csr_rsp_err;
  wire csr_rsp_ready;

  wire global_csr_valid;
  wire global_csr_write;
  wire [SPADMIC_CSR_ADDR_W-1:0] global_csr_addr;
  wire [SPADMIC_CSR_DATA_W-1:0] global_csr_wdata;
  wire global_csr_ready;
  wire global_csr_rvalid;
  wire [SPADMIC_CSR_DATA_W-1:0] global_csr_rdata;

  wire pos_csr_valid;
  wire pos_csr_write;
  wire [SPADMIC_CSR_ADDR_W-1:0] pos_csr_addr;
  wire [SPADMIC_CSR_DATA_W-1:0] pos_csr_wdata;
  wire pos_csr_ready;
  wire pos_csr_rvalid;
  wire [SPADMIC_CSR_DATA_W-1:0] pos_csr_rdata;

  wire x_csr_valid, x_csr_write, x_csr_ready, x_csr_rvalid;
  wire y_csr_valid, y_csr_write, y_csr_ready, y_csr_rvalid;
  wire z_csr_valid, z_csr_write, z_csr_ready, z_csr_rvalid;
  wire [CSR_ADDR_W-1:0] x_csr_addr, y_csr_addr, z_csr_addr;
  wire [CSR_DATA_W-1:0] x_csr_wdata, y_csr_wdata, z_csr_wdata;
  wire [CSR_DATA_W-1:0] x_csr_rdata, y_csr_rdata, z_csr_rdata;

  wire global_enable;
  wire [2:0] axis_enable;
  wire position_enable;

  wire [2:0] axis_narrow_valid;
  wire [NARROW_W-1:0] axis_narrow_data [3];
  wire [2:0] axis_narrow_ready;

  wire [2:0] pkt_valid;
  wire [2:0] pkt_sop;
  wire [2:0] pkt_eop;
  wire [15:0] pkt_data [3];
  wire [2:0] pkt_ready;
  wire [2:0] pkt_available;
  wire [2:0] pkt_fifo_full;

  wire shared_sop;
  wire shared_eop;

  mptdc_reset_sync #(.STAGES(2)) u_rst_sync (
    .clk         (clk_sys),
    .async_rst_n (async_rst_n),
    .rst_n_o     (rst_sys_n)
  );

  spadmic_i2c_slave u_i2c_slave (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_n),
    .i2c_scl_i       (i2c_scl_i),
    .i2c_sda_i       (i2c_sda_i),
    .i2c_sda_oe_o    (i2c_sda_oe_o),
    .txn_valid_o     (i2c_cmd_valid),
    .txn_write_o     (i2c_cmd_write),
    .txn_addr_o      (i2c_cmd_addr),
    .txn_wdata_o     (i2c_cmd_wdata),
    .txn_ready_i     (i2c_cmd_ready),
    .txn_rsp_valid_i (i2c_rsp_valid),
    .txn_rsp_rdata_i (i2c_rsp_rdata),
    .txn_rsp_err_i   (i2c_rsp_err),
    .txn_rsp_ready_o (i2c_rsp_ready)
  );

  spadmic_i2c_csr_bridge u_i2c_bridge (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_n),
    .i2c_cmd_valid_i (i2c_cmd_valid),
    .i2c_cmd_write_i (i2c_cmd_write),
    .i2c_cmd_addr_i  (i2c_cmd_addr),
    .i2c_cmd_wdata_i (i2c_cmd_wdata),
    .i2c_cmd_ready_o (i2c_cmd_ready),
    .i2c_rsp_valid_o (i2c_rsp_valid),
    .i2c_rsp_rdata_o (i2c_rsp_rdata),
    .i2c_rsp_err_o   (i2c_rsp_err),
    .i2c_rsp_ready_i (i2c_rsp_ready),
    .csr_req_valid_o (csr_req_valid),
    .csr_req_write_o (csr_req_write),
    .csr_req_addr_o  (csr_req_addr),
    .csr_req_wdata_o (csr_req_wdata),
    .csr_req_ready_i (csr_req_ready),
    .csr_rsp_valid_i (csr_rsp_valid),
    .csr_rsp_rdata_i (csr_rsp_rdata),
    .csr_rsp_err_i   (csr_rsp_err),
    .csr_rsp_ready_o (csr_rsp_ready)
  );

  spadmic_csr_decoder u_csr_decoder (
    .clk_sys            (clk_sys),
    .rst_n              (rst_sys_n),
    .csr_req_valid_i    (csr_req_valid),
    .csr_req_write_i    (csr_req_write),
    .csr_req_addr_i     (csr_req_addr),
    .csr_req_wdata_i    (csr_req_wdata),
    .csr_req_ready_o    (csr_req_ready),
    .csr_rsp_valid_o    (csr_rsp_valid),
    .csr_rsp_rdata_o    (csr_rsp_rdata),
    .csr_rsp_err_o      (csr_rsp_err),
    .csr_rsp_ready_i    (csr_rsp_ready),
    .global_csr_valid_o (global_csr_valid),
    .global_csr_write_o (global_csr_write),
    .global_csr_addr_o  (global_csr_addr),
    .global_csr_wdata_o (global_csr_wdata),
    .global_csr_ready_i (global_csr_ready),
    .global_csr_rvalid_i(global_csr_rvalid),
    .global_csr_rdata_i (global_csr_rdata),
    .pos_csr_valid_o    (pos_csr_valid),
    .pos_csr_write_o    (pos_csr_write),
    .pos_csr_addr_o     (pos_csr_addr),
    .pos_csr_wdata_o    (pos_csr_wdata),
    .pos_csr_ready_i    (pos_csr_ready),
    .pos_csr_rvalid_i   (pos_csr_rvalid),
    .pos_csr_rdata_i    (pos_csr_rdata),
    .x_csr_valid_o      (x_csr_valid),
    .x_csr_write_o      (x_csr_write),
    .x_csr_addr_o       (x_csr_addr),
    .x_csr_wdata_o      (x_csr_wdata),
    .x_csr_ready_i      (x_csr_ready),
    .x_csr_rvalid_i     (x_csr_rvalid),
    .x_csr_rdata_i      (x_csr_rdata),
    .y_csr_valid_o      (y_csr_valid),
    .y_csr_write_o      (y_csr_write),
    .y_csr_addr_o       (y_csr_addr),
    .y_csr_wdata_o      (y_csr_wdata),
    .y_csr_ready_i      (y_csr_ready),
    .y_csr_rvalid_i     (y_csr_rvalid),
    .y_csr_rdata_i      (y_csr_rdata),
    .z_csr_valid_o      (z_csr_valid),
    .z_csr_write_o      (z_csr_write),
    .z_csr_addr_o       (z_csr_addr),
    .z_csr_wdata_o      (z_csr_wdata),
    .z_csr_ready_i      (z_csr_ready),
    .z_csr_rvalid_i     (z_csr_rvalid),
    .z_csr_rdata_i      (z_csr_rdata)
  );

  spadmic_global_csr u_global_csr (
    .clk_sys           (clk_sys),
    .rst_n             (rst_sys_n),
    .csr_valid_i       (global_csr_valid),
    .csr_write_i       (global_csr_write),
    .csr_addr_i        (global_csr_addr),
    .csr_wdata_i       (global_csr_wdata),
    .csr_ready_o       (global_csr_ready),
    .csr_rvalid_o      (global_csr_rvalid),
    .csr_rdata_o       (global_csr_rdata),
    .tdc_tx_busy_i     (tdc_shared_busy_o),
    .tdc_pkt_pending_i (pkt_available),
    .position_busy_i   (position_busy_o),
    .position_pending_i(position_busy_o),
    .global_enable_o   (global_enable),
    .axis_enable_o     (axis_enable),
    .position_enable_o (position_enable)
  );

  spadmic_tdc_axis_wrapper u_tdc_x (
    .clk_sys          (clk_sys),
    .clk_ref_40m      (clk_ref_40m),
    .async_rst_n      (async_rst_n),
    .global_enable_i  (global_enable),
    .axis_enable_i    (axis_enable[0]),
    .spad_event_async_i(spad_x_event_async_i),
    .csr_valid_i      (x_csr_valid),
    .csr_write_i      (x_csr_write),
    .csr_addr_i       (x_csr_addr),
    .csr_wdata_i      (x_csr_wdata),
    .csr_ready_o      (x_csr_ready),
    .csr_rvalid_o     (x_csr_rvalid),
    .csr_rdata_o      (x_csr_rdata),
    .narrow_ready_i   (axis_narrow_ready[0]),
    .narrow_valid_o   (axis_narrow_valid[0]),
    .narrow_data_o    (axis_narrow_data[0]),
    .stop_armed_o     (tdc_stop_armed_o[0])
  );

  spadmic_tdc_axis_wrapper u_tdc_y (
    .clk_sys          (clk_sys),
    .clk_ref_40m      (clk_ref_40m),
    .async_rst_n      (async_rst_n),
    .global_enable_i  (global_enable),
    .axis_enable_i    (axis_enable[1]),
    .spad_event_async_i(spad_y_event_async_i),
    .csr_valid_i      (y_csr_valid),
    .csr_write_i      (y_csr_write),
    .csr_addr_i       (y_csr_addr),
    .csr_wdata_i      (y_csr_wdata),
    .csr_ready_o      (y_csr_ready),
    .csr_rvalid_o     (y_csr_rvalid),
    .csr_rdata_o      (y_csr_rdata),
    .narrow_ready_i   (axis_narrow_ready[1]),
    .narrow_valid_o   (axis_narrow_valid[1]),
    .narrow_data_o    (axis_narrow_data[1]),
    .stop_armed_o     (tdc_stop_armed_o[1])
  );

  spadmic_tdc_axis_wrapper u_tdc_z (
    .clk_sys          (clk_sys),
    .clk_ref_40m      (clk_ref_40m),
    .async_rst_n      (async_rst_n),
    .global_enable_i  (global_enable),
    .axis_enable_i    (axis_enable[2]),
    .spad_event_async_i(spad_z_event_async_i),
    .csr_valid_i      (z_csr_valid),
    .csr_write_i      (z_csr_write),
    .csr_addr_i       (z_csr_addr),
    .csr_wdata_i      (z_csr_wdata),
    .csr_ready_o      (z_csr_ready),
    .csr_rvalid_o     (z_csr_rvalid),
    .csr_rdata_o      (z_csr_rdata),
    .narrow_ready_i   (axis_narrow_ready[2]),
    .narrow_valid_o   (axis_narrow_valid[2]),
    .narrow_data_o    (axis_narrow_data[2]),
    .stop_armed_o     (tdc_stop_armed_o[2])
  );

  spadmic_tdc_packet_fifo #(
    .DEPTH  (64),
    .TDC_ID (TDC_ID_X)
  ) u_pkt_fifo_x (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_n),
    .narrow_valid_i  (axis_narrow_valid[0]),
    .narrow_data_i   (axis_narrow_data[0]),
    .narrow_ready_o  (axis_narrow_ready[0]),
    .pkt_valid_o     (pkt_valid[0]),
    .pkt_data_o      (pkt_data[0]),
    .pkt_sop_o       (pkt_sop[0]),
    .pkt_eop_o       (pkt_eop[0]),
    .pkt_ready_i     (pkt_ready[0]),
    .pkt_available_o (pkt_available[0]),
    .fifo_full_o     (pkt_fifo_full[0])
  );

  spadmic_tdc_packet_fifo #(
    .DEPTH  (64),
    .TDC_ID (TDC_ID_Y)
  ) u_pkt_fifo_y (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_n),
    .narrow_valid_i  (axis_narrow_valid[1]),
    .narrow_data_i   (axis_narrow_data[1]),
    .narrow_ready_o  (axis_narrow_ready[1]),
    .pkt_valid_o     (pkt_valid[1]),
    .pkt_data_o      (pkt_data[1]),
    .pkt_sop_o       (pkt_sop[1]),
    .pkt_eop_o       (pkt_eop[1]),
    .pkt_ready_i     (pkt_ready[1]),
    .pkt_available_o (pkt_available[1]),
    .fifo_full_o     (pkt_fifo_full[1])
  );

  spadmic_tdc_packet_fifo #(
    .DEPTH  (64),
    .TDC_ID (TDC_ID_Z)
  ) u_pkt_fifo_z (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_n),
    .narrow_valid_i  (axis_narrow_valid[2]),
    .narrow_data_i   (axis_narrow_data[2]),
    .narrow_ready_o  (axis_narrow_ready[2]),
    .pkt_valid_o     (pkt_valid[2]),
    .pkt_data_o      (pkt_data[2]),
    .pkt_sop_o       (pkt_sop[2]),
    .pkt_eop_o       (pkt_eop[2]),
    .pkt_ready_i     (pkt_ready[2]),
    .pkt_available_o (pkt_available[2]),
    .fifo_full_o     (pkt_fifo_full[2])
  );

  spadmic_tdc_arbiter3 u_tdc_arbiter (
    .clk_sys       (clk_sys),
    .rst_n         (rst_sys_n),
    .pkt_valid_i   (pkt_valid),
    .pkt_sop_i     (pkt_sop),
    .pkt_eop_i     (pkt_eop),
    .pkt_data_i    (pkt_data),
    .pkt_ready_o   (pkt_ready),
    .shared_ready_i(tdc_tx_ready_i),
    .shared_valid_o(tdc_tx_valid_o),
    .shared_data_o (tdc_tx_data_o),
    .shared_sop_o  (shared_sop),
    .shared_eop_o  (shared_eop),
    .arb_busy_o    (tdc_shared_busy_o),
    .grant_idx_o   (/* unused */)
  );

  spadmic_position_block u_position (
    .clk_sys        (clk_sys),
    .rst_n          (rst_sys_n),
    .global_enable_i(global_enable & position_enable),
    .x_lines_i      (x_lines_i),
    .y_lines_i      (y_lines_i),
    .z_lines_i      (z_lines_i),
    .csr_valid_i    (pos_csr_valid),
    .csr_write_i    (pos_csr_write),
    .csr_addr_i     (pos_csr_addr),
    .csr_wdata_i    (pos_csr_wdata),
    .csr_ready_o    (pos_csr_ready),
    .csr_rvalid_o   (pos_csr_rvalid),
    .csr_rdata_o    (pos_csr_rdata),
    .pos_ready_i    (pos_tx_ready_i),
    .pos_valid_o    (pos_tx_valid_o),
    .pos_data_o     (pos_tx_data_o),
    .busy_o         (position_busy_o),
    .packet_pending_o(/* unused */)
  );

endmodule

`default_nettype wire
