# O5 PDK Clock-Gating Cell Audit

Branch: `SPADMIC_localtag`

Local limitation:

The lab-server PDK Liberty path shown in Genus logs is not available in this local checkout under `/data/pdk`, so this audit uses committed Genus logs plus synthesis settings. The next server run must report the final ICG netlist count.

## Evidence From O4 Genus Logs

O4 R600 closure log reports:

- `lp_insert_clock_gating = false`
- clock-gating insertion disabled by settings
- Genus found integrated clock-gating cells but marked them unusable because Liberty `dont_use` is true

Reported candidate integrated clock-gating cells include:

- `LGCNHDX0`
- `LGCNHDX1`
- `LGCNHDX2`
- `LGCNHDX4`
- `LGCPHDX0`
- `LGCPHDX1`
- `LGCPHDX2`
- `LGCPHDX4`
- `LSGCNHDX0/X1/X2/X4`
- `LSGCPHDX0/X1/X2/X4`
- `LSOGCNHDX0/X1/X2/X4`

Genus warning:

`Unusable clock gating integrated cell found ... because ... dont_use attribute is defined as true`.

## Current Flow Status

`MPTDC/syn/scripts/settings.tcl` disabled automatic clock gating by default because those ICG cells are `dont_use`.

`MPTDC/syn/scripts/genus.tcl` had clock-gating style hooks, but they were inactive because `mptdc_enable_clock_gating` was false.

O5 adds explicit experimental control:

- `MPTDC_ENABLE_CLOCK_GATING=1`
- `MPTDC_CLOCK_GATING_MIN_FLOPS=2`
- `MPTDC_ALLOW_ICG_DONT_USE_OVERRIDE=1`
- `MPTDC_ALLOW_DISCRETE_CLOCK_GATING=1` for the follow-up feasibility run

The lower min-flop threshold matters because each PD cell has seven timestamp flops; the previous default min-flop value of 8 would likely miss one-PD-cell gating.

## O5 First Run Result

The first O5 clock-gated timestamp run did not test the timestamp-freeze concept. Genus stopped in `syn_generic` with:

`Cannot find any usable integrated clock-gating cell. [POPT-78]`

The O5 audit printed:

- `O5 ICG audit: matched 0 candidate clock-gating lib cells`
- no post-synthesis netlist
- no timing reports
- no ICG instances inserted

Therefore the first `o5_clock_gated_ts_fast` directory is a flow/library-enablement failure, not a timing result.

The follow-up O5b script now enables `lp_insert_discrete_clock_gating_logic` only when `MPTDC_ALLOW_DISCRETE_CLOCK_GATING=1`. This is a feasibility experiment, not final signoff. If it inserts discrete gating and materially improves the PD timestamp path, the project still needs a proper integrated-cell or physical implementation decision before Innovus/signoff.

## Why Clock Gating Is The Right Experiment

The PD timestamp freeze function is a clock-enable function:

- update timestamp while `hit_latched=0`
- hold timestamp after `hit_latched=1`

If implemented as data muxing, `hit_latched` is timed through the timestamp D path. That is the dominant O4 violation.

If implemented with a local ICG:

- D path becomes `nfast_tag_i -> timestamp flop D`
- freeze control becomes an ICG enable check
- one ICG can gate the seven timestamp flops in one PD cell
- all 64 PD cells can keep a symmetric structure

## Risks

Clock gating is not automatically safe:

- It adds load to fast phase taps.
- It introduces clock-gating setup/hold checks.
- It needs matching Liberty and LEF views.
- The cells are currently marked `dont_use`, so overriding that must be treated as an experiment.
- Physical matching must later verify that every PD cell receives identical gating structure.

## O5 Required Report Checks

The O5 server script reports:

- whether clock gating was requested
- whether `dont_use` override was requested
- `clock-gating cell netlist count`
- timestamp flop reference count
- resettable timestamp flop reference count
- PD timing family WNS/TNS

If clock-gated mode does not insert ICG cells, then it is not a valid test of the O5C concept and the result should be interpreted as another data-mux implementation.

If discrete clock-gating logic inserts, treat the result as structural evidence only:

- it can prove whether moving the freeze control off the timestamp D path helps;
- it does not prove phase-tap load, glitch safety, clock-gating checks, or physical matching are signoff-ready;
- it must not be used as final oscillator/PD signoff without a real ICG or project-approved implementation.

If ICG cells insert but the phase tap load/DRV explodes, O5 must not proceed to Innovus without a physical review.
