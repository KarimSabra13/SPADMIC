# Review: Matrix TOP Genus OOC Attempt genus_matrix_ooc_20260630_0953

## Metadata

- Branch: `SPADMIC_test`
- Server run ID: `genus_matrix_ooc_20260630_0953`
- Evidence source: live server console excerpt provided by the user
- Review status: failed input-selection issue analyzed; wrapper fix prepared
- Signoff status: not signoff, not timing closure

## Result

The first Genus OOC block, `position_snapshot`, failed during HDL read before
block elaboration.

Primary fatal message:

```text
Error : Unsupported style of sensitivity list in Verilog. [VLOGPT-437] [read_hdl]
      : in file 'TOP/rtl/spadmic_ddr_tx.sv' on line 31
      : Both posedge and negedge of the same signal are not allowed in an always block.
```

## Verifier Finding

| ID | Severity | Finding | Impact | Builder Response | Status |
| --- | --- | --- | --- | --- | --- |
| GENUS-001 | BLOCKER | The matrix-top Genus OOC wrapper read the shared TOP simulation filelist directly. That filelist includes `TOP/rtl/spadmic_ddr_tx.sv`, the obsolete 8-bit generic dual-edge DDR RTL, and `TOP/rtl/spadmic_top_v1.sv`, the legacy top that instantiates it. | Genus fails before reaching the final matrix-top DDR16 path. This is an input-selection problem and not a failure of the new DDR16 pairer or protected MPTDC internals. | Generate a Genus-only matrix-top filelist under the run directory. Preserve `TOP/filelist.f` for simulation, but exclude `spadmic_ddr_tx.sv` and `spadmic_top_v1.sv` from Genus OOC. | FIXED LOCALLY, NEEDS SERVER RERUN |
| GENUS-002 | MEDIUM | Genus emits many `VLOGPT-43` warnings on SystemVerilog ANSI ports with ``default_nettype none``. | No fatal impact yet, but warning volume can hide real issues. Needs classification after the DDR8 blocker is removed. | Keep warnings visible in the next server snapshot and classify from `report_messages`/warning classification. Do not rewrite RTL ports until the next Genus result proves it is necessary. | OPEN |
| GENUS-003 | NOTE | Shell monitor commands were entered after Genus dropped to an interactive prompt. | This can confuse the terminal transcript but does not change the root cause. | Use a second terminal for monitoring, and let the wrapper exit naturally when possible. | OPEN NOTE |

## Files Changed By Builder

- `TOP/syn/scripts/run_genus_all_matrix_ooc.sh`
- `TOP/syn/README.md`
- `TOP/docs/21_MATRIX_TOP_GENUS_OOC_PLAN.md`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`

## Required Rerun

Run a fresh Genus OOC run with a new run ID after the fix commit is pushed.

The next run must confirm:

- `filelists/top_genus_excluded.f` lists the obsolete DDR8 and legacy top files;
- no `VLOGPT-437` fatal from `spadmic_ddr_tx.sv`;
- the flow proceeds to the next real elaboration/synthesis issue, or all blocks pass.

## Limitations

This is a source/snapshot triage review only. It does not claim:

- Genus pass;
- timing closure;
- CDC/RDC signoff;
- Innovus feasibility;
- final DDR or matrix macro timing signoff.
