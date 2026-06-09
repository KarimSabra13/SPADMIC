# O13 abs5e Result Review

Run reviewed:

- `results/github_snapshots/20260609_o13_abs5e_pd_q1_constraint_mode_fix_snapshot/`
- Run ID: `20260609_o13_abs5e_pd_q1_constraint_mode_fix`
- Run mode: `O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH`
- Genus run HEAD: `5836c9f85c640c134905aa31714577ecd29abd89`
- Signoff status: typical-only feasibility, not MMMC and not final signoff

## Main Conclusion

O13 abs5e fixes the blocking O13 timing-model issue.

The final buffered phase clocks are real, async grouped against `clk_sys`, and
the intentional slow-phase-to-PD-q1 Vernier crossings are now discovered and
excepted with exact endpoint/source counts.

Do not reject O13 based on the earlier abs2/abs3/abs5 failures. Those failures
were constraint/reporting integration bugs, not proof that the BUHDX4 -> BUHDX12
topology is bad.

## Constraint And Clock Status

Abs5e reports:

- raw RO clocks found: 16
- buffered phase clocks found: 16
- buffered phase clocks expected: 16
- buffered phase clocks in async group: yes
- `clk_sys` async to buffered phase clocks: yes
- unresolved SDC command failures: 0
- unknown timing classifications: 0

The previous impossible `clk_sys` to oscillator-buffer timing failures are gone.

## PD Vernier Exception Status

The intended measurement crossing is:

```text
slow_phase[ns] -> mptdc_pd_cell.q1_reg/D
sampled by fast_phase[nf]
```

There are 8 slow rows and 8 fast columns, so the expected count is 64.

Abs5e reports:

- q1 endpoints discovered: 64
- slow buffered source pins discovered: 8
- intentional Vernier paths matched: 64
- exception applied endpoints: 64
- overmatch: no
- undermatch: no

The exception is scoped to the slow buffered final-driver outputs feeding the
same-row `q1_reg/D` pins. It does not cut `q1_reg -> q2_reg`, `q1/q2 ->
hit_latched`, fast tag capture, slow Johnson logic, `clk_sys`, reset/recovery,
or the phase buffer topology.

## RTL Interpretation

The relevant RTL is in:

- `MPTDC/rtl/osc/mptdc_phase_buffer_bank.sv`
- `MPTDC/rtl/top/mptdc_core.sv`
- `MPTDC/rtl/pd/mptdc_pd_cell.sv`

The phase buffer bank implements the O13 topology:

```text
RO_tune4/S[n] -> BUHDX4 isolation -> BUHDX12 final driver -> phase fabric
```

`mptdc_core` instantiates the slow and fast phase buffer banks, then builds the
8x8 PD matrix. Each PD row receives one buffered slow phase tap, and each PD
column receives one buffered fast phase tap.

`mptdc_pd_cell` samples `slow_phase` into `q1` on `posedge fast_phase`. That is
the Vernier measurement operation and is not ordinary synchronous setup timing.
The same cell also captures `nfast_tag_i` into `nfast_hit_latched` while the hit
has not yet latched. That latter path is a real same-fast-clock timing path and
must remain timed.

## Real Remaining Timing

After removing the intentional Vernier crossings from normal setup closure, the
remaining timing is small and real:

- `OSC_FAST_REAL`: WNS about -4 ps, TNS about -178 ps
- dominant family: `FAST_TAG_TO_PD_TS`
- `LOCAL_FAST_TAG_SELF`: WNS about -2 ps
- `CLK_SYS_REAL`: WNS positive, no clk_sys violations

The worst shown path is a fast tag register to a PD `nfast_hit_latched_reg[D]`
on the same buffered fast tap. This is real local fast-domain timing. It is not
a CDC artifact and should not be waived. The residual margin is small enough
that Innovus placement/buffering may recover it, but it must be tracked in O13
physical feasibility.

## DRV Status

Abs5e has no max-capacitance or max-fanout violations, but it does report many
max-transition pins near 511 ps against a 500 ps limit.

This appears dominated by the matrix-wide PD detect enable net, not by the O13
phase buffer chain. The violation is small, but the summary should not call DRV
perfectly clean. Innovus should explicitly report and fix/buffer this enable
net if it persists after placement.

## Report Quality Issue Fixed After Abs5e

The abs5e evidence still contains report-wrapper noise:

- this Genus build does not support native `report_exceptions`
- this Genus build does not support native `report_constraints`
- some generic hotspot report paths could feed non-pin objects to
  `report_timing -to`, causing TIM-234 failures

`MPTDC/syn/scripts/procedures.tcl` has been patched after this run so the next
evidence package writes explicit substitute reports for unsupported native
commands and refuses to call `report_timing` with cell names or raw strings.

## Go/No-Go

O13 abs5e is Genus-interpretable.

Recommended next step:

1. Either run one quick report-clean Genus rerun to remove wrapper noise from
   the evidence package, or proceed to O13 Innovus feasibility if schedule
   pressure is higher than report cleanliness.
2. Do not change RTL for abs5e.
3. Do not reject O13.
4. In Innovus, track:
   - fast tag to PD timestamp timing
   - local fast tag self timing
   - PD detect enable transition
   - phase buffer load and balance
   - raw RO load at the BUHDX4 isolation inputs

