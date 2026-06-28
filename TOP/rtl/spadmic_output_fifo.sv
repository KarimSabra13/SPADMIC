// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_output_fifo.sv
// Purpose  : Synchronous logical-word FIFO for matrix-top output buffering.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_output_fifo #(
  parameter int unsigned DATA_W = 16,
  parameter int unsigned DEPTH = 512,
  parameter int unsigned RESERVE_WORDS = 128,
  parameter int unsigned LEVEL_W = $clog2(DEPTH + 1)
) (
  input  logic                  clk_sys,
  input  logic                  rst_n,

  input  logic                  push_valid_i,
  output logic                  push_ready_o,
  input  logic [DATA_W-1:0]     push_data_i,

  output logic                  pop_valid_o,
  input  logic                  pop_ready_i,
  output logic [DATA_W-1:0]     pop_data_o,

  output logic [LEVEL_W-1:0]    level_o,
  output logic [LEVEL_W-1:0]    free_words_o,
  output logic                  empty_o,
  output logic                  full_o,
  output logic                  almost_full_o,
  output logic                  overflow_o
);
  localparam int unsigned ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

  logic [DATA_W-1:0] mem_q [DEPTH];
  logic [ADDR_W-1:0] wr_ptr_q;
  logic [ADDR_W-1:0] rd_ptr_q;
  logic [LEVEL_W-1:0] level_q;

  wire pop_fire;
  wire push_fire;
  wire [LEVEL_W-1:0] free_words_next;

  function automatic logic [ADDR_W-1:0] ptr_inc(input logic [ADDR_W-1:0] ptr);
    if (ptr == ADDR_W'(DEPTH - 1))
      return '0;
    return ptr + ADDR_W'(1);
  endfunction

  assign empty_o = (level_q == '0);
  assign full_o = (level_q == LEVEL_W'(DEPTH));
  assign pop_valid_o = !empty_o;
  assign pop_data_o = empty_o ? '0 : mem_q[rd_ptr_q];
  assign pop_fire = pop_valid_o && pop_ready_i;
  assign push_ready_o = !full_o || pop_fire;
  assign push_fire = push_valid_i && push_ready_o;
  assign free_words_o = LEVEL_W'(DEPTH) - level_q;
  assign free_words_next = LEVEL_W'(DEPTH) - level_q;
  assign almost_full_o = (free_words_next < LEVEL_W'(RESERVE_WORDS));
  assign level_o = level_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_q   <= '0;
      rd_ptr_q   <= '0;
      level_q    <= '0;
      overflow_o <= 1'b0;
    end else begin
      overflow_o <= push_valid_i && !push_ready_o;

      if (push_fire)
        mem_q[wr_ptr_q] <= push_data_i;

      unique case ({push_fire, pop_fire})
        2'b10: begin
          wr_ptr_q <= ptr_inc(wr_ptr_q);
          level_q  <= level_q + LEVEL_W'(1);
        end
        2'b01: begin
          rd_ptr_q <= ptr_inc(rd_ptr_q);
          level_q  <= level_q - LEVEL_W'(1);
        end
        2'b11: begin
          wr_ptr_q <= ptr_inc(wr_ptr_q);
          rd_ptr_q <= ptr_inc(rd_ptr_q);
        end
        default: begin
        end
      endcase
    end
  end

endmodule

`default_nettype wire
