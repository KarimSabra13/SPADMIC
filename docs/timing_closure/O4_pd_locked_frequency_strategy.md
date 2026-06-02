# O4 PD Locked Frequency Strategy

Designer constraint:

- Do not redesign the PD cell behavior.
- Do not change the PD detection principle.
- Do not introduce opposite-edge or two-phase PD capture.
- Do not turn the PD into a custom macro in O4.
- Do not modify fundamental Vernier/PD measurement behavior.

## Locked PD Behavior

O4 preserves the current localtag PD behavior:

- PD samples raw `slow_phase[ns]` on `fast_phase[nf]`.
- `detect_en_i` prevents false detection without forcing `slow_phase` low.
- `hit_latched` is set by the existing falling-edge condition.
- `nfast_hit_latched` shadows the local raw fast tag before hit.
- `nfast_hit_latched` freezes after hit.

The local timestamp-freeze path is real measurement logic. It must not be false-pathed simply because it is difficult.

## Timing Strategy

If nominal Genus still shows PD-local timestamp-freeze paths failing, O4 evaluates R600 as the acceptable architectural lever.

R600 in this patch is a timing what-if only:

- It changes only SDC clock periods/tap steps for Genus.
- It does not change RTL constants.
- It does not change packet layout.
- It does not prove analog tune-code feasibility.
- It does not prove Vernier delta preservation.

If R600 improves the PD-local paths enough, the next action is an analog request for:

- slow and fast R600 tune codes
- slow and fast tap delays
- Vernier delta at R600
- output slew and max load
- jitter
- startup behavior and valid-edge timing

If R600 still fails badly, then with PD behavior locked and no PD macro option, standard-cell closure is not demonstrated and the project needs a frequency/performance/design-rule decision.
