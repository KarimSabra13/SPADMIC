# Event Coordinator Exact-GDS LVS Match Snapshot

This compact snapshot records the attributable foreground PVS LVS execution
completed on 2026-07-21 from exact commit
`624ae1e2967eb66a63e3b33139c66f483e14886f`.

The immutable diagnostic and package-local run are:

```text
DIAGNOSTIC_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/event_pvs_lvs_execution_20260721_121034
RUN_DIR=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_event_coordinator/innovus_ooc_harden_event_coordinator_20260720_173527/pvs/lvs/event_exact_gds_lvs_20260721_121034
```

## Accepted LVS Result

The repository, source density diagnostic, package identities, template
controls, external references, replay contract, output isolation, executable
run control, run manifest, post-execution source/package checks, and 23-file
diagnostic manifest all passed. PVS produced explicit positive match evidence
and no negative match evidence:

```text
STATUS=PASS
RESULT=EVENT_PVS_EXACT_GDS_LVS_MATCH_RECORDED
OUTCOME_CLASS=ATTRIBUTABLE_MATCH
PVS_WRAPPER_RC=0
PVS_TOOL_RC=0
PVS_LVS_STATUS=MATCH
LVS_NEGATIVE_MATCH_COUNT=0
LVS_POSITIVE_MATCH_COUNT=3
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
RUN_CONTROL_AUDIT_RC=0
DIAGNOSTIC_MANIFEST_RC=0
```

The comparison bound the exact package inputs:

```text
LAYOUT_TOP=spadmic_event_coordinator
SOURCE_TOP=spadmic_event_coordinator
GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857
LVS_SOURCE_SHA256=f9ec957b23b1a229c7c2ff19309fb7463dfc5cac7e570ad1ca68ad8b08089b27
STDCELL_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
```

The run-control audit found exactly one executable GDS, Verilog source, CDL,
and run-local SVDB path. Output isolation records the expected normalization
`SVDB_ACTION=ADDED_MISSING` with `SVDB_REWRITE_COUNT=0`. The PVS comparison
reported `2660 insts vs 2660 insts` and `Run Result : MATCH`; ERC results were
empty.

## Warning Disposition

The completed matched run also emitted the known CDL unsupported-directive
warnings (`NVN-13002`), the Verilog case-sensitivity warning (`NVN-15191`),
the leading-backslash truncation warning (`NVN-13259`), and
`joinNets - cell 'output_fifo_free_words_o' is not found`. These warnings did
not create negative match evidence or prevent the explicit top-cell match.
They are retained as observed warnings, not silently promoted to closure
failures or discarded.

## Independent Gates

Event base DRC remains `PASS` with `0 (0)`. Density DRC remains `FAIL` with
four OOC whole-extent minimum-coverage rules (`R1M1`, `R1M2`, `R1M3`, and
`R1MT`). This snapshot accepts only exact-GDS LVS. It does not authorize local
density repair, PVS rerun, block promotion, assembly insertion, full-top PnR,
or signoff. Density still requires assembled-fill disposition or an exact
formal waiver, and `p02_event_control` remains blocked by `p00_tx` and
`p01_position`.
