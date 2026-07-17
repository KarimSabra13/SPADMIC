# Position Core Innovus Evidence Snapshot

- Run ID: `innovus_ooc_harden_position_core_20260717_111443`
- Source root: `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_position_core_20260717_111443`
- Genus run: `genus_ooc_position_core_20260717_101642`
- Branch: `SPADMIC_test`
- Source commit: `64a1a29846f42b382aea4d1afbed8455963fbbec`
- Collection method: compact reports transcribed from the operator's
  foreground `cat` output on 2026-07-17
- Raw Innovus database, complete reports, logs, and physical outputs: retained
  under the source root and not copied to Git

## Classification

```text
INNOVUS_PROCESS_STATUS=PASS
OOC_ROUTE_STATUS=CLEAN
INNOVUS_DRC_STATUS=PASS
REGULAR_CONNECTIVITY_STATUS=PASS
PG_CONNECTIVITY_STATUS=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
TOP_RESERVATION_FIT_STATUS=FAIL_DERIVED_FROM_REPORTED_BOUNDARY
IMMUTABLE_PACKAGE_AUTHORIZED=NO
PVS_AUTHORIZED=NO
SIGNOFF_READY=NO
```

The physical route is clean, but the reported `952.000 x 660.240 um` design
boundary exceeds the fixed `951.695 x 660.000 um` Position reservation. This
GDS is retained as feasibility evidence and must not be staged for PVS. The
next attributable artifact is one grid-safe replay using the unchanged
accepted Genus netlist and SDC.

The original run summary's `default` route profile and deferred-PG text are
known reporting errors. The authoritative status report records
`met1_effort`, `MET1-MET3`, and `EXPLICIT_EXACT`.
