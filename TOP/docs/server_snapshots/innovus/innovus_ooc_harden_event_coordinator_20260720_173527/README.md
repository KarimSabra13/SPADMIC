# Event Coordinator Innovus OOC Evidence Snapshot

- Run ID: `innovus_ooc_harden_event_coordinator_20260720_173527`
- Source root: `/sim/ksabra/SPADMIC_work/innovus/innovus_ooc_harden_event_coordinator_20260720_173527`
- Diagnostic root: `/sim/ksabra/SPADMIC_work/diagnostics/event_innovus_execution_20260720_173527`
- Genus run: `genus_ooc_event_coordinator_20260720_163038`
- Genus source commit: `b53b1fade963c6c57c6b0629ae9a4b21fdac06db`
- Innovus transaction commit: `1b922f0723112e5916107775069c767388ec500e`
- Collection method: compact reports transcribed from the operator's
  foreground transaction output on 2026-07-20
- Raw database, complete reports, logs, outputs, and diagnostic manifest:
  retained under the source and diagnostic roots and not copied to Git

## Accepted Gates

```text
EVENT_DRIVER_RC=0
DIAGNOSTIC_MANIFEST_RC=0
STATUS_CONTRACT_RC=0
STATUS=PASS
OUTCOME_CLASS=ATTRIBUTABLE_ABSTRACT_READY
EVENT_INNOVUS_OOC_STATUS=PASS
SOURCE_POST_RECHECK_RC=0
EVENT_INNOVUS_TRANSACTION_STATUS=PASS
```

The Event die is `237.440 x 219.520 um` and fits the reserved
`237.460 x 220.000 um` region with `0.020 um` width and `0.480 um` height
margin. Innovus DRC has zero markers, regular and VDD/VSS special
connectivity each have zero violations and zero warnings, and typical-only
post-route setup and hold pass. The mapped and standard-cell-merged GDS audit
also passes.

## Artifact Identity

```text
POSTSYN_NETLIST_SHA256=b28454211dc5eeda84f17cc5864adcd1c15cd761a9d825e3f5a78182fe0b0ccb
POSTSYN_SDC_SHA256=c32e0a54b392017256a790ec73352d7161093c73a4360fe933083c88f7d1cb6a
GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857
ABSTRACT_LEF_SHA256=56345986a887317f0374984b1ea8b3442ea482aeec0572614e9fd2c0b6732a14
DEF_SHA256=f9d6a927c7cecad40916cac67b8142f6fb6c6b013e3d57ab779889fd0ab21a68
ROUTED_PG_NETLIST_SHA256=0ecc571317f6beaa13c7f006ac3ecc4f1ff2a72b9655a176c0fa21e3c0a07398
```

## Classification

```text
RESULT=EVENT_INNOVUS_OOC_ABSTRACT_READY_FOR_TOP_REVIEW
EVENT_HANDOFF_STAGE_AUTHORIZED=YES
EVENT_PVS_BASE_DRC_STATUS=NOT_RUN
EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN
EVENT_PVS_LVS_STATUS=NOT_RUN
ASSEMBLY_INSERTION_AUTHORIZED=NO
ASSEMBLY_BLOCKED_BY=p00_tx,p01_position
FULL_TOP_PNR_AUTHORIZED=NO
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
NEXT_GATE=REVIEW_AND_STAGE_IMMUTABLE_EVENT_HANDOFF
```

This evidence authorizes immutable candidate-package staging only. It is not
PVS, MMMC, promotion, signoff, or permission to bypass the ordered digital
assembly phases.
