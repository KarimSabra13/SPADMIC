# Event Coordinator Immutable Handoff Snapshot

- Package version: `innovus_ooc_harden_event_coordinator_20260720_173527`
- Package root: `/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_event_coordinator/innovus_ooc_harden_event_coordinator_20260720_173527`
- Physical source run: `innovus_ooc_harden_event_coordinator_20260720_173527`
- Physical source commit: `1b922f0723112e5916107775069c767388ec500e`
- Staging repository commit: `0fff3d2afb447f746c69ea946450ff6f5cdd7400`
- Staging diagnostic: `/sim/ksabra/SPADMIC_work/diagnostics/event_handoff_staging_20260721_101249`
- Package creation UTC: `2026-07-21T08:12:51.461144+00:00`
- Collection method: compact reports transcribed from the operator's
  foreground staging and audit output on 2026-07-21
- Full package collateral: retained under the package root and not copied to
  Git

## Accepted Gates

```text
EVENT_STAGE_RC=0
DIAGNOSTIC_MANIFEST_RC=0
STATUS_CONTRACT_RC=0
PACKAGE_MANIFEST_RC=0
EVENT_HANDOFF_STAGING_TRANSACTION_STATUS=PASS
EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS
```

## Artifact Identity

```text
GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857
ABSTRACT_LEF_SHA256=56345986a887317f0374984b1ea8b3442ea482aeec0572614e9fd2c0b6732a14
DEF_SHA256=f9d6a927c7cecad40916cac67b8142f6fb6c6b013e3d57ab779889fd0ab21a68
RAW_PG_NETLIST_SHA256=0ecc571317f6beaa13c7f006ac3ecc4f1ff2a72b9655a176c0fa21e3c0a07398
CANONICAL_LVS_SOURCE_SHA256=f9ec957b23b1a229c7c2ff19309fb7463dfc5cac7e570ad1ca68ad8b08089b27
STDCELL_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf
```

## Classification

```text
PACKAGE_STATUS=CANDIDATE
EVENT_PVS_BASE_DRC_STATUS=NOT_RUN
EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN
EVENT_PVS_LVS_STATUS=NOT_RUN
PVS_EXECUTED=NO
EVENT_PVS_PREFLIGHT_AUTHORIZED=YES
ASSEMBLY_INSERTION_AUTHORIZED=NO
ASSEMBLY_BLOCKED_BY=p00_tx,p01_position
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=PREPARE_EVENT_PVS_BASE_DRC_STRICT_PREFLIGHT
```

The basic qualification report's `UNKNOWN` bbox, map, merge, and internal-PG
fields are generic promotion placeholders. They do not override the separately
hashed Event floorplan, mapped/merged GDS, regular connectivity, PG
connectivity, Innovus DRC, and timing reports, all of which passed. No PVS
result is inferred from staging.
