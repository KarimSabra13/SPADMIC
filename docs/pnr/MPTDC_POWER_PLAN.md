# MPTDC Power Plan

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

## Supply Nets

- Digital supply: `VDD`
- Ground: `VSS`
- Nominal voltage: `1.8 V`

## RO_tune4 Connection Policy

For the prototype, connect:

- `RO_tune4/VDD` to digital `VDD`
- `RO_tune4/vdd!` to digital `VDD`
- `RO_tune4/VSS` to ground `VSS`

Hard stop if the LEF, Liberty, schematic, or analog handoff says these pins are
not compatible with the digital `VDD/VSS` plan.

## Required Checks

- global net connection report
- standard-cell rail continuity report
- macro power pin connection report for both RO macros
- unconnected PG pin report
- preliminary vectorless or annotated power report
- explicit note that EM/IR signoff is not complete
