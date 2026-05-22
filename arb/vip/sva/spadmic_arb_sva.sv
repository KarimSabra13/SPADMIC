// =============================================================================
// SPADMIC ARB SVA — packet atomicity and source handshake assertions.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_arb_sva
  import spadmic_pkg::*;
  import mptdc_pkg::*;
(
  input wire        clk_sys,
  input wire        rst_n,
  input wire [2:0]  acq_valid,
  input wire [2:0]  acq_ready,
  input wire        arb_valid,
  input wire        arb_ready,
  input wire        arb_sop,
  input wire        arb_eop,
  input spadmic_source_id_e arb_source
);

  property p_one_acq_grant;
    @(posedge clk_sys) disable iff (!rst_n)
    $onehot0(acq_ready);
  endproperty
  a_one_acq_grant: assert property (p_one_acq_grant)
    else $error("[ARB_SVA] Multiple TDC acq_ready grants simultaneously");

  property p_acq_grant_requires_valid;
    @(posedge clk_sys) disable iff (!rst_n)
    (acq_ready != 3'b000) |-> ((acq_ready & acq_valid) == acq_ready);
  endproperty
  a_acq_grant_requires_valid: assert property (p_acq_grant_requires_valid)
    else $error("[ARB_SVA] acq_ready asserted to an invalid TDC source");

  logic packet_open_q;
  spadmic_source_id_e packet_source_q;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      packet_open_q   <= 1'b0;
      packet_source_q <= TDC_ID_X;
    end else if (arb_valid && arb_ready) begin
      if (arb_sop) begin
        assert (!packet_open_q)
          else $error("[ARB_SVA] SOP before previous packet EOP");
        packet_source_q <= arb_source;
        packet_open_q   <= !arb_eop;
      end else begin
        assert (packet_open_q)
          else $error("[ARB_SVA] packet payload without open packet");
        assert (arb_source == packet_source_q)
          else $error("[ARB_SVA] source changed inside an active packet");
        if (arb_eop)
          packet_open_q <= 1'b0;
      end
    end
  end

endmodule

`default_nettype wire
