  task automatic i2c_start;
    begin
      i2c_sda_master_low = 1'b0;
      i2c_scl_drv        = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_sda_master_low = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_restart;
    begin
      i2c_sda_master_low = 1'b0;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_sda_master_low = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_stop;
    begin
      i2c_scl_drv        = 1'b0;
      i2c_sda_master_low = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_sda_master_low = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_write_bit(input logic bit_value);
    begin
      i2c_scl_drv        = 1'b0;
      i2c_sda_master_low = ~bit_value;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_read_bit(output logic bit_value);
    begin
      i2c_scl_drv        = 1'b0;
      i2c_sda_master_low = 1'b0;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b1;
      #(I2C_SAMPLE_DELAY);
      bit_value = i2c_sda;
      #(I2C_HALF_PERIOD-I2C_SAMPLE_DELAY);
      i2c_scl_drv        = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_write_byte(
    input logic [7:0] byte_value,
    output logic ack_ok
  );
    logic ack_bit;
    begin
      for (int bit_idx = 7; bit_idx >= 0; bit_idx--)
        i2c_write_bit(byte_value[bit_idx]);
      i2c_read_bit(ack_bit);
      ack_ok = (ack_bit == 1'b0);
    end
  endtask

  task automatic i2c_read_byte(
    output logic [7:0] byte_value,
    input logic send_ack
  );
    logic bit_value;
    begin
      byte_value = '0;
      for (int bit_idx = 7; bit_idx >= 0; bit_idx--) begin
        i2c_read_bit(bit_value);
        byte_value[bit_idx] = bit_value;
      end

      i2c_scl_drv        = 1'b0;
      i2c_sda_master_low = send_ack;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b0;
      i2c_sda_master_low = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_expect_ack(input logic ack_ok, input string label);
    if (!ack_ok)
      $fatal(1, "Missing I2C ACK during %s", label);
  endtask

  task automatic i2c_write_csr(
    input logic [15:0] addr,
    input logic [31:0] data
  );
    logic ack_ok;
    begin
      i2c_start();
      i2c_write_byte({spadmic_pkg::SPADMIC_I2C_ADDR, 1'b0}, ack_ok);
      i2c_expect_ack(ack_ok, "device-address write");
      i2c_write_byte(addr[15:8], ack_ok);
      i2c_expect_ack(ack_ok, "pointer high");
      i2c_write_byte(addr[7:0], ack_ok);
      i2c_expect_ack(ack_ok, "pointer low");
      i2c_write_byte(data[31:24], ack_ok);
      i2c_expect_ack(ack_ok, "data byte 3");
      i2c_write_byte(data[23:16], ack_ok);
      i2c_expect_ack(ack_ok, "data byte 2");
      i2c_write_byte(data[15:8], ack_ok);
      i2c_expect_ack(ack_ok, "data byte 1");
      i2c_write_byte(data[7:0], ack_ok);
      i2c_expect_ack(ack_ok, "data byte 0");
      i2c_stop();
      repeat (12) @(posedge clk_sys);
    end
  endtask

  task automatic i2c_read_csr(
    input logic [15:0] addr,
    output logic [31:0] data
  );
    logic ack_ok;
    logic [7:0] b3;
    logic [7:0] b2;
    logic [7:0] b1;
    logic [7:0] b0;
    begin
      i2c_start();
      i2c_write_byte({spadmic_pkg::SPADMIC_I2C_ADDR, 1'b0}, ack_ok);
      i2c_expect_ack(ack_ok, "device-address pointer");
      i2c_write_byte(addr[15:8], ack_ok);
      i2c_expect_ack(ack_ok, "pointer high");
      i2c_write_byte(addr[7:0], ack_ok);
      i2c_expect_ack(ack_ok, "pointer low");
      i2c_restart();
      i2c_write_byte({spadmic_pkg::SPADMIC_I2C_ADDR, 1'b1}, ack_ok);
      i2c_expect_ack(ack_ok, "device-address read");
      repeat (4) @(posedge clk_sys);
      i2c_read_byte(b3, 1'b1);
      i2c_read_byte(b2, 1'b1);
      i2c_read_byte(b1, 1'b1);
      i2c_read_byte(b0, 1'b0);
      data = {b3, b2, b1, b0};
      i2c_stop();
      repeat (6) @(posedge clk_sys);
    end
  endtask
