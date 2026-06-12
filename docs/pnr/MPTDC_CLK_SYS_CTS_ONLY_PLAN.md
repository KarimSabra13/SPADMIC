# MPTDC clk_sys-Only CTS Plan

Status: `CTS_NOT_CLOSED`, `GENERIC_CCOPT_FORBIDDEN`,
`CLK_SYS_ONLY_VALIDATE_FIRST`, `NOT_SIGNOFF_READY`

## Problem

The density65 clean run requested clk_sys CTS, but CTS was skipped:

```text
CTS_STATUS=CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY
spec_safety=ambiguous_or_ro_clock_reference
allow_generic_ccopt=0
```

That skip is correct. A generic CCOpt run could treat raw RO clocks or buffered
phase clocks as clock-tree targets and modify the measurement fabric. That
would invalidate the O13 physical evidence.

## Rule

Run CTS only if the flow can prove the target is exactly:

```text
clk_sys
```

Never run CTS over:

- raw RO clocks;
- `clk_osc_slow`;
- `clk_osc_fast`;
- `clk_osc_*_tap*`;
- buffered phase clocks;
- RO_tune4 `S[n]` pins;
- `BUHDX4 -> BUHDX12` phase-buffer tree roots or sinks.

## New Validate-Only Script

The debug script is:

```text
MPTDC/pnr/scripts/innovus_mptdc_cts_clk_sys_only_debug.tcl
```

Default behavior:

- restore a routed checkpoint if provided;
- list all clocks;
- list RO/phase guard objects;
- generate a CCOpt spec if Innovus supports the command;
- scan the spec for `clk_sys`;
- reject the spec if any RO/phase token appears;
- do not run `ccopt_design`.

Accepted statuses:

```text
SPEC_AUDIT_CLK_SYS_ONLY
CTS_SKIPPED_NO_SAFE_CLK_SYS_ONLY_COMMAND
CLK_SYS_ONLY_CTS_COMPLETE
```

Rejected statuses:

```text
GENERIC_CCOPT_USED
RO_CLOCKS_IN_CTS
PHASE_CLOCKS_IN_CTS
CTS_AMBIGUOUS_BUT_RAN_ANYWAY
```

## Validate-Only Command

Run this only after the log-clean density65 rerun has produced a routed
checkpoint:

```bash
R=work/innovus/$RUN
[ -d "$R" ] || R=results/innovus/$RUN

CTSDBG=${RUN}_clk_sys_cts_validate

MPTDC_CTS_DEBUG_RESULT_DIR="$PWD/results/innovus/$CTSDBG" \
MPTDC_CTS_DEBUG_CHECKPOINT_DAT="$R/checkpoints/04_route.enc.dat" \
MPTDC_CTS_DEBUG_RESTORE_TCL="$R/checkpoints/restore_latest.tcl" \
MPTDC_CTS_DEBUG_RUN_CCOPT=0 \
innovus -nowin \
  -init MPTDC/pnr/scripts/innovus_mptdc_cts_clk_sys_only_debug.tcl \
  -log "$PWD/results/innovus/$CTSDBG/logs/innovus_cts_clk_sys_only_debug.log"
```

Inspect:

```bash
cat "results/innovus/$CTSDBG/reports/cts_status.rpt"
cat "results/innovus/$CTSDBG/reports/cts_clock_inventory.rpt"
cat "results/innovus/$CTSDBG/reports/cts_object_guard.rpt"
cat "results/innovus/$CTSDBG/reports/cts_clk_sys_only_spec_audit.rpt"
```

If the result is `CTS_SKIPPED_NO_SAFE_CLK_SYS_ONLY_COMMAND`, do not run CCOpt.
That means the Innovus command set still has not provided a provably safe
clk_sys-only spec.

If the result is `RO_CLOCKS_IN_CTS` or `PHASE_CLOCKS_IN_CTS`, reject the spec.
Do not try to force the generic command.

## CTS Run Command

Only after validate-only reports `SPEC_AUDIT_CLK_SYS_ONLY`, a controlled CTS
experiment may be run with:

```bash
CTSRUN=${RUN}_clk_sys_cts_only_experiment

MPTDC_CTS_DEBUG_RESULT_DIR="$PWD/results/innovus/$CTSRUN" \
MPTDC_CTS_DEBUG_CHECKPOINT_DAT="$R/checkpoints/04_route.enc.dat" \
MPTDC_CTS_DEBUG_RESTORE_TCL="$R/checkpoints/restore_latest.tcl" \
MPTDC_CTS_DEBUG_RUN_CCOPT=1 \
innovus -nowin \
  -init MPTDC/pnr/scripts/innovus_mptdc_cts_clk_sys_only_debug.tcl \
  -log "$PWD/results/innovus/$CTSRUN/logs/innovus_cts_clk_sys_only_run.log"
```

This experiment is still not signoff by itself. After it runs, compare:

- `report_clocks` before and after CTS;
- clock-tree summary;
- O13 raw RO load;
- O13 phase-buffer output load;
- phase-buffer topology;
- phase-buffer placement;
- route/timing;
- any inserted buffers on RO or phase nets.

Reject the experiment if any RO/phase clock is touched.

## Generic Override Policy

A future explicit override may be prepared under a separate label:

```text
DANGEROUS_CTS_EXPERIMENT
NOT_SIGNOFF
```

It must save a pre-CTS checkpoint and prove after the fact that no RO/phase
clock or phase-buffer topology was modified. It must not be used as the default
closure path.
