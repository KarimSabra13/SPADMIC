# O10.1 Pre-run Assumptions

- Branch: `SPADMIC_localtag`
- Flow label: `O10_1_INNOVUS_FLOW_REPAIR`
- Timing label: typical feasibility only
- MMMC: disabled
- RTL: unchanged
- Genus: unchanged
- Architecture: unchanged
- Frequency mode: O9 R750_delta5
- SDC: Innovus-safe O10.1 overlay plus O9 post-synth SDC
- CTS: `clk_sys` only if supported; otherwise skipped for first feasibility
- RO phase clocks: protected from CTS
- Screenshots: automatic if GUI mode supports export; otherwise explicit restore instructions
- IO timing: reported separately as provisional block-level assumption
- Power nets: keep O10 defaults `VDD` / `VSS`
- Floorplan: reuse O10 sandwich defaults
