# TX Packet Core HV PVS LVS Triage

Status: `REGISTERED_PENDING_READ_ONLY_INVENTORY`

This track is independent of the `spadmic_tx_ddr_strip` P02 PG patch. It must
not block or alter P02.

## Source Candidate

The latest known PVS LVS directory candidate is:

```text
/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PvsLVS/spadmic_tx_packet_core_HV
```

It appears to contain an LVS run for the DIFFCON-corrected
`spadmic_tx_packet_core_HV` layout. Until the controls, timestamps, input
paths, hashes, and comparison reports are inventoried, it is only a candidate
run directory. A mismatch is possible but is not yet classified.

No layout correction, OA edit, GDS rewrite, source-netlist edit, or PVS rerun
is authorized from this observation alone.

## Phase Mapping

- P03-LVS-A: read-only source inventory and immutable raw evidence capture.
- P03-LVS-B: reconstruct the exact layout/source contract used by the run.
- P04-LVS-A: classify the comparison result or mismatch from evidence.
- P04-LVS-B: prepare and execute a reproducible Cadence-server rerun.
- P04-LVS-C: promote only an explicit PVS LVS match into the block handoff.

The earlier PVS DRC result remains a separate gate. DRC clean does not imply
LVS match, and an LVS mismatch does not invalidate the DRC result.

## Read-Only Intake Policy

The original directory is never modified. Inventory must record:

- every regular file, relative path, size, modification time, and SHA256;
- every symlink and its target without following it for writes;
- PVS version and explicit executable path;
- generated run command and working directory;
- layout path, layout format, layout top, and layout hash;
- source netlist paths, source top, include/CDL paths, and hashes;
- control files, configuration wrappers, technology references, and hashes;
- report, summary, comparison, extraction, and log files;
- result databases by name and size only unless a later review needs them.

Only the following file classes are copied into the immutable raw bundle:

- reports and summaries;
- run/control/configuration files;
- text logs and PIPO translation logs;
- the exact source netlist used by the comparison;
- compact cell-map, hierarchy, and input-manifest files;
- generated inventories and SHA256 manifests.

Do not copy GDS, OA, PDK installations, full rule-deck installations, density
databases, or PVS result databases in this intake phase. Record their absolute
paths, sizes, and hashes instead. External foundry decks and standard-cell
collateral are references plus hashes unless redistribution is explicitly
approved.

## Immutable Raw Bundle

Use a unique destination below:

```text
/sim/ksabra/SPADMIC_work/handoff/innovus/
  blocks/spadmic_tx_packet_core/<handoff-version>/
    pvs/lvs/raw/<inventory-id>/
      source_inventory.tsv
      selected_file_manifest.tsv
      external_reference_manifest.tsv
      hashes.sha256
      controls/
      logs/
      reports/
      netlist/
      status/
```

The destination must not exist before staging and must never be overwritten.
The manifests retain the original absolute and relative source paths.

## Git Evidence Policy

Git receives only small review artifacts after the raw bundle exists:

- a sanitized input-contract summary;
- the explicit PVS comparison verdict and key counts;
- a mismatch-classification report with evidence references;
- hashes and immutable handoff paths;
- the reproducible rerun recipe and final gate status.

Do not commit GDS, OA, routed/source netlists, standard-cell CDL, full PDK rule
files, PVS databases, or large raw logs. Short report excerpts must identify
their source file and line or section without replacing the raw evidence.

## Mismatch Classification

Classify only after reconstructing both compared inputs. Use one primary class
and any proven secondary classes:

1. `RUN_OR_INPUT_IDENTITY`: stale run, wrong GDS/OA view, or unexpected source.
2. `TOP_NAME_OR_HIERARCHY`: `_HV` layout top versus canonical source top,
   hierarchy expansion, cell mapping, or black-box mismatch.
3. `SOURCE_PARSE_OR_LIBRARY`: missing include, wrong standard-cell CDL,
   unresolved cells, or parse failure.
4. `PG_OR_GLOBAL_NET`: VDD/VSS/global-net naming, missing PG pins, or virtual
   connection mismatch.
5. `BOUNDARY_PORT`: missing, extra, renamed, reordered, or shorted top ports.
6. `CONNECTIVITY_OPEN_SHORT`: explicit extracted opens, shorts, or net splits.
7. `DEVICE_COUNT_OR_TYPE`: missing/extra devices or device-type disagreement.
8. `DEVICE_PROPERTY`: width, length, multiplicity, model, or parameter mismatch.
9. `MANUAL_DIFFCON_EXTRACTION`: a proven extraction change caused by the
   manual DIFFCON geometry.
10. `TOOL_OR_REPORT_INCOMPLETE`: comparison did not finish or evidence is
    insufficient to classify.

Do not assign `MANUAL_DIFFCON_EXTRACTION` merely because DIFFCON was added.
That class requires a report-level device or connectivity delta at the edited
location.

## Reproducible Rerun Gate

The rerun is prepared locally from the inventoried controls but executed only
on the Cadence server. It requires:

- a new immutable working directory;
- the explicit Cadence PVS binary, never bare `/usr/sbin/pvs`;
- frozen layout/source tops and input hashes;
- frozen PDK/CDL/rule references and hashes;
- copied controls with path substitutions recorded in a manifest;
- complete stdout/stderr and generated report capture;
- explicit result parsing that accepts only a stated LVS match;
- no layout or source correction during the diagnostic rerun.

Any correction is a later, separately reviewed phase after the mismatch class
has been proven.
