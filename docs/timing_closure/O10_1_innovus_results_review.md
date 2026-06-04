# O10.1 Innovus Results Review

Status: pending server run.

Expected run:

- `results/innovus/202606xx_o10_1_innovus_repair`
- `MPTDC/lab_snapshots/innovus_o10_1_innovus_repair_202606xx_o10_1_innovus_repair`

## Review Checklist

- Wrapper exit code and required-output status.
- SDC read status, especially absence of `design(...)` variable errors.
- CTS status: `CLK_SYS_ONLY_COMPLETE` or `CTS_SKIPPED_FOR_FIRST_FEASIBILITY`.
- RO CTS attempted: must be `no`.
- Screenshot status: nonempty PNGs or explicit GUI fallback file.
- PD report: 64/64 cells found.
- Phase-net and fast-tag load CSVs generated.
- Timing split: core internal, IO output, and RO-domain paths reviewed separately.
- DRV, route, congestion, and checkpoint reports present.

## Decision

Do not use this template to claim signoff. The only acceptable conclusion after a clean O10.1 run is readiness for the next typical-feasibility review step.
