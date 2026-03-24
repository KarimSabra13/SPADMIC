`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_reset_sync.sv
// Purpose  : Async-assert / sync-deassert reset synchroniser
// Author   : Karim Sabra
// =============================================================================
// Reset strategy:
//   - ASSERT path (async):  When async_rst_n goes low the entire FF chain
//     is cleared immediately through the asynchronous active-low reset port
//     of every flop.  rst_n_o therefore falls within one gate delay of the
//     external reset assertion, independent of clk activity.
//   - DEASSERT path (sync):  When async_rst_n returns high the signal must
//     propagate through STAGES synchroniser flops before rst_n_o rises,
//     guaranteeing the release is synchronous to clk and free of metastable
//     artefacts.  The first flop's D input is tied to 1'b1 so the chain
//     fills with ones at each rising clk edge once the async reset is gone.
//
// The ASYNC_REG attribute instructs the placer to co-locate the flops and
// the mapper to use high-gain / metastability-hardened cells where available.
//
// Typical usage:
//   mptdc_reset_sync u_rst_sync (
//       .clk         (clk_sys),
//       .async_rst_n (por_n),
//       .rst_n_o     (rst_sys_n)
//   );
// =============================================================================
module mptdc_reset_sync #(
    parameter int unsigned STAGES = 2    // number of synchroniser flops (≥ 2)
) (
    input  wire  clk,            // destination-domain clock
    input  wire  async_rst_n,    // asynchronous reset, active-low
    output wire  rst_n_o         // synchronised reset, active-low
);

    // -------------------------------------------------------------------------
    // Elaboration-time guard
    // -------------------------------------------------------------------------
    initial begin
        if (STAGES < 2) begin
            $fatal(1, "mptdc_reset_sync: STAGES must be >= 2 (got %0d)", STAGES);
        end
    end

    // -------------------------------------------------------------------------
    // Synchroniser chain
    // -------------------------------------------------------------------------
    (* ASYNC_REG = "TRUE" *) logic [STAGES-1:0] sync_q;

    always_ff @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            sync_q <= '0;                         // async assert — immediate
        else
            sync_q <= {sync_q[STAGES-2:0], 1'b1}; // sync deassert — shift in 1
    end

    assign rst_n_o = sync_q[STAGES-1];

endmodule

`default_nettype wire
