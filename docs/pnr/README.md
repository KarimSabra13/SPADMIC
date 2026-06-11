# MPTDC Typical-Only Innovus Planning Package

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

This directory is the reviewed planning package for the next MPTDC Innovus
prototype step. It is a controlled physical prototype plus near-signoff
reporting plan. It is not an MMMC signoff plan and not a final silicon signoff
claim.

## Scope

- Use the accepted JIHD typical Genus closure as the only approved P&R input.
- Keep the flow single typical view unless the scope is explicitly changed.
- Preserve the O13 topology:
  `RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric`.
- Use `VDD/VSS` as the MPTDC 1.8 V digital supply.
- Connect `RO_tune4` `VDD` and `vdd!` to digital `VDD`; connect `VSS` to
  ground, unless the LEF or analog handoff contradicts this.
- Do not raise Liberty RO output max capacitance limits as a fix.
- Do not run CTS on raw RO clocks or buffered phase clocks.

## Documents

- [Signoff Plan](MPTDC_TYPICAL_ONLY_SIGNOFF_PLAN.md)
- [Decision Log](MPTDC_PNR_DECISION_LOG.md)
- [Open Questions](MPTDC_PNR_OPEN_QUESTIONS.md)
- [Floorplan And Placement](MPTDC_FLOORPLAN_AND_PLACEMENT.md)
- [Routing Plan](MPTDC_ROUTING_PLAN.md)
- [Power Plan](MPTDC_POWER_PLAN.md)
- [IO Constraint Plan](MPTDC_IO_CONSTRAINT_PLAN.md)
- [CTS Policy](MPTDC_CTS_POLICY.md)
- [Physical Verification](MPTDC_PHYSICAL_VERIFICATION_PLAN.md)
- [DRC LVS Extraction](MPTDC_DRC_LVS_EXTRACTION_PLAN.md)
- [Tap Endcap Filler](MPTDC_TAP_ENDCAP_FILLER_PLAN.md)
- [RO Code CSR Requirement](MPTDC_RO_CODE_CSR_REQUIREMENT.md)
- [RTL Physical Interpretation](MPTDC_RTL_PHYSICAL_INTERPRETATION.md)
