# MPTDC Cleanup Risk Register

Phase 0 records risks only. It does not accept destructive risk.

| Risk | Trigger | Consequence | Controls | Status |
| --- | --- | --- | --- | --- |
| RTL filelist breakage | Moving/renaming RTL or filelists | Verilator, Xcelium, Genus, or Innovus compile closure breaks | Protect filelists; run compile/reference checks before changes | Open |
| O13 Genus wrapper breakage | Renaming O13 abs5/phase-distribution wrappers or SDCs | Server handoff no longer reproduces current timing/debug state | Additive aliases first; keep O13 names until references move | Open |
| O12/O13 Innovus wrapper breakage | Renaming O12/O13 PnR Tcl, SDC, or shell wrappers | Phase-buffer or phase-distribution PnR flows lose known entrypoints | Shell syntax and Tcl/SDC reference checks | Open |
| Result evidence loss | Deleting `results/`, `MPTDC/results/`, or `MPTDC/lab_snapshots/` too early | Timing docs and debug conclusions lose backing reports | Reference search, summary preservation, explicit review | Open |
| False cleanup from generated summary files | Trusting wrapper summaries over raw timing/DRV/route reports | Cleanup preserves misleading files and deletes useful evidence | Inspect raw reports/manifests before deleting run trees | Open |
| Xcelium compatibility regression | Changing RTL or TB constructs based only on Verilator success | Server-side Xcelium elaboration can fail | Keep recent portability fixes protected; validate with Xcelium when touched | Open |
| Genus helper regression | Editing `procedures.tcl` or collection handling | O13 report generation can fail after constraints apply | Parse checks plus Genus report-helper review | Open |
| Innovus restore/report regression | Moving O10.2/O11 scripts or result paths | Useful routed checkpoint/report flow becomes hard to restore | Keep current wrappers; document old-to-new path mapping before moves | Open |
| RO abstract/load evidence loss | Deleting macro shell variants or RO load reports | Analog load comparison and O11/O13 decisions become unauditable | Protect `MPTDC/syn/macros/`, `analog_handoff/`, and O11 docs | Open |
| XLIBD reference loss | Moving/deleting XLIBD notes or extracted values | O13 IO/reset/scan timing assumptions lose traceability | Protect `MPTDC/tech/xlibd/` and `docs/tech/` | Open |
| Fresh clone mismatch | Cleanup tested only in current dirty/local workspace | Hidden ignored files or local excludes mask missing tracked inputs | Fresh clone validation before final review | Open |
| Local ignored dependency confusion | `OpenROAD/`, `.venv/`, or `MPTDC/build/` exists locally but not in git | Cleanup appears to pass locally while missing dependencies elsewhere | Document local-only paths and avoid relying on them | Open |
| Accidental root artifact mishandling | Deleting odd root files without reference search | A real but poorly named evidence file could be lost | Search references and inspect file content before delete | Open |
| Scope creep into other blocks | Cleaning `TOP/`, `I2C/`, `position/`, `arb/`, or report projects | Non-MPTDC functionality changes unexpectedly | Keep Phase 0 MPTDC-scoped; require separate approval | Open |

## Approval Gates

Before any destructive cleanup:

- Delete candidates must be reviewed and explicitly approved.
- Move candidates must include a reference-update plan.
- Rename candidates must be implemented additively first.
- Validation commands must be selected based on touched file categories.
- Current O10-O13 evidence must remain auditable.
