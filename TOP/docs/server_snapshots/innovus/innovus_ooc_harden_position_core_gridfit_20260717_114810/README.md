# Position Core Grid-Safe Innovus Evidence Snapshot

- Run ID: `innovus_ooc_harden_position_core_gridfit_20260717_114810`
- Source root: `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_position_core_gridfit_20260717_114810`
- Genus run: `genus_ooc_position_core_20260717_101642`
- Branch: `SPADMIC_test`
- Source commit: `179baaf3fc35c931d95d47d70f84c760ccfd17ed`
- Collection method: compact reports transcribed from the operator's
  foreground report output on 2026-07-17
- Raw Innovus database, complete reports, logs, and physical outputs: retained
  under the source root and not copied to Git

## Classification

```text
INNOVUS_PROCESS_STATUS=PASS
POSITION_GRID_SAFE_REPLAY_STATUS=PASS
OOC_ROUTE_STATUS=CLEAN
TOP_RESERVATION_FIT_STATUS=PASS
INNOVUS_DRC_STATUS=PASS
REGULAR_CONNECTIVITY_STATUS=PASS
PG_CONNECTIVITY_STATUS=PASS
TC_POSTROUTE_TIMING_STATUS=PASS
GDS_LAYER_MAP_STATUS=PASS
GDS_MERGE_STATUS=PASS
IMMUTABLE_HANDOFF_STAGING_AUTHORIZED=YES
IMMUTABLE_PACKAGE_STATUS=NOT_STAGED
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
SIGNOFF_READY=NO
```

The actual `951.440 x 659.680 um` die fits inside the fixed
`951.695 x 660.000 um` Position reservation, leaving `0.255 um` width and
`0.320 um` height margin. The abstract LEF records the same macro size.

This run supersedes the overflowed `49a7a030...` GDS as the Position
candidate for immutable staging. Its accepted output identity is:

```text
GDS_SHA256=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
ABSTRACT_LEF_SHA256=1eb91d021edccd4806a5516ef1f2aa0a2718607ee84c248d2d0e12cd8e698683
ROUTED_PG_NETLIST_SHA256=4078d8b5f277923948371898663ea2b0093fae205bad09e2f91c5f502f251cfd
```

This remains typical-only Innovus OOC evidence. Immutable package audit,
package-local source preparation and pin parity, PVS base and density DRC,
and exact-GDS LVS `MATCH` remain separate gates.
