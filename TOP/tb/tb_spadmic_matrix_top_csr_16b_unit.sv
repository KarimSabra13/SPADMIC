`timescale 1ps/1ps
`default_nettype none

// Explicit CSR16-named entry point for the matrix-top CSR regression.
//
// The original unit test remains `tb_spadmic_matrix_top_csr_unit` because it
// grew from the Phase 2/3 CSR endpoint work.  This wrapper preserves that
// implementation while providing the artifact name requested by the final
// matrix-top verification plan.
`include "TOP/tb/tb_spadmic_matrix_top_csr_unit.sv"

module tb_spadmic_matrix_top_csr_16b_unit;
  tb_spadmic_matrix_top_csr_unit u_csr16();
endmodule

`default_nettype wire
