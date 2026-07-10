# Digital Assembly V1 Execution Journal

This journal records measured execution evidence for the progressive SPADMIC2
digital assembly. A phase is marked `PASS` only from the reports produced by
that phase. Planned commands, tool return codes, and estimates are not physical
signoff evidence by themselves.

The flow remains restricted to `SPADMIC_test`. It must not launch full-top
Genus or Innovus and must not modify MPTDC internals.

## Evidence Rules

- Preserve every run under a unique timestamped directory.
- Record the repository HEAD, input hashes, run ID, return code, and report
  paths for every phase.
- Keep Innovus DRC, PVS DRC, PVS LVS, PG connectivity, geometry, pin parity,
  and layer-map status as separate gates.
- Treat an Innovus or PVS process return code of zero as execution evidence,
  not as proof that DRC or LVS passed.
- Do not promote a handoff package when any required gate is `FAIL`, `UNKNOWN`,
  or `PENDING`.
- Never overwrite an existing package under
  `/sim/ksabra/SPADMIC_work/handoff/innovus`.

## Phase Ledger

| Phase | Scope | Current status | Required evidence |
| --- | --- | --- | --- |
| P00 | Local flow implementation and static validation | PASS | Unit tests, syntax checks, RTL compile, geometry regression |
| P01 | Narrow `spadmic_tx_ddr_strip` signal PnR | PENDING_SERVER | OOC status, LEF size, DRC, markers, regular connectivity |
| P02 | Restore-only internal PG for the narrow strip | BLOCKED_BY_P01 | PG patch status, PG connectivity, post-PG DRC, merged GDS audit |
| P03 | Canonical corrected `spadmic_tx_packet_core` OA handoff | PENDING_SERVER | OA backup, bbox/pin parity, canonical GDS export, layer-map audit |
| P04 | Per-block PVS closure and immutable handoff promotion | BLOCKED_BY_P02_P03 | PVS DRC zero, LVS explicit match, hashes, promotion gate |
| P05 | Phase-A TX assembly generation and geometry gate | BLOCKED_BY_P04 | No obstacle overlap, exact placements, exact 19-net contract |
| P06 | Phase-A TX assembly route | BLOCKED_BY_P05 | Checkpoints 00/01/02, selected-net connectivity, DRC, timing |
| P07 | Assembly PVS and promoted handoff | BLOCKED_BY_P06 | GDS audit, PVS DRC zero, LVS match or approved source contract |

Later position, event/control, matrix-interface, MPTDC-frontend, and CSR/I2C
phases remain outside this initial TX gate.

## P00 - Local Implementation

Status: `PASS`

Implemented artifacts:

- Phase-A RTL/black-box/filelist/connectivity contracts under
  `TOP/pnr/assembly/`.
- Top-coordinate floorplan, hard obstacle blockages, and pin-guide Tcl.
- Assembly generator with geometry rejection before Innovus starts.
- Innovus assembly runner with restoreable `00_import`, `01_tx_placed`, and
  `02_tx_routed` checkpoints.
- Restore-only strip PG patch flow.
- Immutable per-block and per-assembly handoff staging.
- OA/LEF contract, XStream GDS, Innovus GDS, PG, and promotion audits.
- PVS DRC/LVS template replay and explicit result parsing.

Validated locally:

- 8 focused unit tests passed.
- Python compilation passed.
- Bash syntax checks passed.
- Tcl files were syntactically complete.
- Icarus assembly compilation passed.
- Verilator passed with only the pre-existing `mptdc_pkg.sv` width warning.
- `git diff --check` passed.
- Handoff staging/audit and promotion-gate smoke tests passed.

Server EDA was not run locally because `/sim` and the Cadence server
environment are not available in this checkout.

## P01 - Narrow TX DDR Strip Signal PnR

Status: `PENDING_SERVER`

Reason for this phase:

```text
old strip bbox = 61.980,3061.110 -> 3584.940,3241.990
TXRX4TDC2      = 3505.519,464.920 -> 3638.910,3265.795
overlap        = 79.421 x 180.880 um
```

The old strip cannot enter the assembly. The first server run reuses the
accepted Genus netlist and changes only the OOC strip core width to
`3413.000 um`. PG remains deferred during P01 by design.

Acceptance gates:

- `STRIP_SIGNAL_RC=0`
- `RESULT=ABSTRACT_READY_FOR_TOP_REVIEW`
- `INNOVUS_DRC_STATUS=PASS`
- `DRC_MARKER_TOTAL=0`
- `REGULAR_CONNECTIVITY_STATUS=PASS`
- abstract LEF total width near `3433 um`, subject to the generator's exact
  SPADMIC2 obstacle check;
- no full-top or unrelated block run.

Evidence to append after execution:

```text
REPO_HEAD=PENDING
RUN_ID=PENDING
RUN_ROOT=PENDING
RETURN_CODE=PENDING
STATUS_REPORT=PENDING
DRC_REPORT=PENDING
MARKER_REPORT=PENDING
CONNECTIVITY_REPORT=PENDING
ABSTRACT_LEF=PENDING
VERDICT=PENDING
```

## Update Procedure

After each server phase:

1. Return the complete status report and the focused gate reports listed in
   the phase.
2. Review the reports independently of the wrapper return code.
3. Update this journal with immutable paths and measured values.
4. Commit and push the evidence update on `SPADMIC_test`.
5. Issue only the next unblocked phase command.

The complete flow contract and server command reference are maintained in
`TOP/docs/31_DIGITAL_ASSEMBLY_V1_HANDOFF_AND_PVS_FLOW.md`.
