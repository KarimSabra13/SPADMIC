# Position Core Immutable Handoff Snapshot

- Package version: `innovus_ooc_harden_position_core_gridfit_20260717_114810`
- Package root: `/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810`
- Physical source run: `innovus_ooc_harden_position_core_gridfit_20260717_114810`
- Physical source commit: `179baaf3fc35c931d95d47d70f84c760ccfd17ed`
- Staging repository commit: `8a617c9f8049340cebc777783255acffd55212d6`
- Package creation UTC: `2026-07-17T10:18:24.257509+00:00`
- Collection method: compact reports transcribed from the operator's
  foreground staging and audit output on 2026-07-17
- Full package collateral: retained under the package root and not copied to
  Git

## Accepted Gates

```text
HANDOFF_STAGE_STATUS=PASS
HANDOFF_AUDIT_STATUS=PASS
CANONICAL_NAME_STATUS=PASS
LVS_SOURCE_PREPARATION_STATUS=PASS
PIN_PARITY_STATUS=PASS
STDCELL_CDL_STATUS=PASS
PACKAGE_HASH_GATE_STATUS=PASS
MANIFEST_GATE_STATUS=PASS
PACKAGE_EVIDENCE_GATE_STATUS=PASS
POSITION_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS
```

## Artifact Identity

```text
GDS_SHA256=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
ABSTRACT_LEF_SHA256=1eb91d021edccd4806a5516ef1f2aa0a2718607ee84c248d2d0e12cd8e698683
RAW_PG_NETLIST_SHA256=4078d8b5f277923948371898663ea2b0093fae205bad09e2f91c5f502f251cfd
CANONICAL_LVS_SOURCE_SHA256=a5e81c21e633ae1b55d8da5c8e971997f890d9cee42dff2f6cf9f9f43cad9ffb
STDCELL_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
```

## Classification

```text
PACKAGE_STATUS=CANDIDATE
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=POSITION_PVS_BASE_DRC_TEMPLATE_PREFLIGHT
```

The basic qualification report's `UNKNOWN` map, merge, PG, and bbox fields are
promotion placeholders, not evidence that the corresponding Innovus reports
failed. The package separately contains and hashes the accepted floorplan,
connectivity, Innovus DRC, timing, and mapped/merged GDS reports. No PVS result
is inferred from staging.
