# MPTDC PNR Open Questions

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

These questions must be closed before internal signoff. They do not block the
controlled typical-only prototype unless a contradiction is found in the input
LEF, Liberty, or Genus handoff.

| Question | Owner | Current Policy |
|---|---|---|
| Does `RO_tune4` require a dedicated analog supply? | analog/physical | Assume no; hard stop if LEF or analog handoff contradicts it. |
| Are `VDD` and `vdd!` both intended to connect to digital `VDD`? | analog/physical | Connect both to `VDD` for prototype, audit explicitly. |
| What is the final raw RO output load acceptance rule? | analog/digital | Prefer `58.72 fF`; warn at `75.59 fF`; do not relax Liberty as a fix. |
| How will the three SPADMIC MPTDC instances be delivered? | integration | Treat this as a block prototype until hard-macro delivery is decided. |
| Are final boundary pin sides approved? | integration | Use west async inputs, east control/readout/status; review after floorplan. |
| How is RO code CSR timing closed? | RTL/integration | Add a CSR requirement and report timing before signoff. |
| Is `narrow_*` waived or still top-visible? | integration | Low priority legacy output until top-level TX decision. |
| Which physical verification deck is authoritative? | physical | Decide Pegasus vs Assura before signoff. |
| What are the antenna requirements? | physical | Produce reports in prototype; signoff threshold still open. |
| Is `60%` utilization approved for the first closure attempt? | project | Use `60%` by default, fall back to `58%` on congestion, consider `62%` only if 60% routes are long and congestion is clean. |
