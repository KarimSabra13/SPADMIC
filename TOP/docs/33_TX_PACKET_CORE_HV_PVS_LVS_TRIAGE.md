# TX Packet Core HV PVS LVS Triage

Status: `READ_ONLY_INTAKE_COMPLETE_MISMATCH_CLASSIFIED_REBUILD_REQUIRED`

This track is independent of the `spadmic_tx_ddr_strip` P02 PG patch. It must
not block or alter P02.

## Source Candidate

The latest known PVS LVS directory candidate is:

```text
/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PvsLVS/spadmic_tx_packet_core_HV
```

It contains a completed historical LVS run for
`spadmic_tx_packet_core_HV`. The controls, timestamps, input paths, hashes, and
comparison reports are now inventoried. The run is classified below and is not
the qualification run for the final DIFFCON-corrected handoff.

No layout correction, OA edit, GDS rewrite, source-netlist edit, or PVS rerun
was authorized from the observation alone. The immutable intake is now
available and supports the classification below. The historical directory
remains read-only.

The implemented collector is:

```text
TOP/pnr/scripts/collect_pvs_lvs_readonly.py
```

It never invokes PVS or executes a file from the historical run. It hashes and
reads the source, writes only to a new immutable bundle, does not follow
symlinks, and compares source type/size/mtime/symlink metadata before and after
collection. An existing destination is refused.

## Completed Intake And Proven Diagnosis

The server collection completed with `STATUS=PASS`, `ERROR_COUNT=0`, and
`SOURCE_STABILITY_STATUS=PASS`. The compact Git evidence is under:

```text
TOP/docs/pvs_lvs_intake/spadmic_tx_packet_core_HV/
  tx_packet_core_hv_lvs_inventory_20260710_165038/
```

The historical run completed comparison and reported an explicit `MISMATCH`.
It is not a valid verdict on the final DIFFCON-corrected handoff because the
compared inputs and abstraction contract are wrong in several independent
ways:

| Gate | Evidence | Classification |
| --- | --- | --- |
| Input identity | Compared GDS SHA256 is `6d29b541...badf`; the separately reported fixed-DIFFCON handoff SHA256 is `aaa3f7b8...1026` | `RUN_OR_INPUT_IDENTITY` |
| Top contract | Layout top is `spadmic_tx_packet_core_HV`; source top is `spadmic_tx_packet_core` | `TOP_NAME_OR_HIERARCHY` |
| Pin extraction | Comparison has layout pins `0`, source pins `156` initially and `154` after supply handling | `BOUNDARY_PORT` |
| Library abstraction | Source is only the routed PG Verilog and keeps JIHD module definitions; no official JIHD CDL is included | `SOURCE_PARSE_OR_LIBRARY` |
| Concrete layout connectivity | Extracted net 44 carries both `output_fifo_free_words_o[0]` and `output_fifo_level_o[0]` labels | `CONNECTIVITY_OPEN_SHORT` |

The missing-pin report includes clocks, reset, VDD/VSS, scalar controls,
ordinary 1D buses, and every `src_data_i[i][j]` bit. Therefore adjacent bracket
dimensions are not the primary cause of this run: the layout side recognized
no top pins at all. PVS also finished loading the Verilog source. Flattening the
active TX interface is a deliberate new physical-contract decision, not a
retroactive explanation of this historical mismatch.

The OA-to-GDS conversion log reports ignored pin/label layer-purpose pairs,
including MET3 and METTP pin/label purposes. Combined with `text_depth
-primary`, the `_HV` wrapper hierarchy, and the zero layout-pin count, this
invalidates the old boundary comparison before any device-level conclusion.

The source contains thousands of high-level JIHD instances while the layout
extracts transistor devices. Without the official
`xh018_D_CELLS_JIHD.cdl`, PVS is comparing incompatible abstraction levels.
The next source must remove only Verilog definitions covered by that CDL and
must prove that every used master is present in the CDL before PVS starts.

### Do Not Retry

- Do not rerun the historical controls unchanged; they reproduce the same
  invalid contract.
- Do not use `i+j` to flatten two indices; it aliases distinct source/bit pairs.
- Do not call `[][]` the root cause when all non-array pins are missing too.
- Do not attribute the mismatch to DIFFCON when the compared GDS hash differs
  from the fixed handoff and no localized device delta proves that class.
- Do not use OA XStream output as the new physical authority. The replacement
  flow qualifies the mapped Innovus GDS directly and imports OA only as a
  versioned review copy.
- Do not accept a PVS return code as LVS success. Only an explicit report-level
  `MATCH` passes.

The compact machine-readable decision is
`mismatch_classification.rpt` in the intake directory.

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

Collector usage:

```bash
python3 TOP/pnr/scripts/collect_pvs_lvs_readonly.py \
  --source-run <historical-PVS-LVS-directory> \
  --bundle-root <new-immutable-raw-bundle>
```

Generated evidence includes:

- `source_inventory.tsv`, `inventory_by_date.tsv`, and
  `inventory_by_size.tsv`;
- `selected_file_manifest.tsv`, exact copied controls/reports/logs, and local
  or referenced project source netlists;
- `external_reference_manifest.tsv` with type, size, mtime, and SHA256 for GDS,
  PDK, CDL, rule, tool, and other references;
- `input_contract_extract.rpt`, `pvs_tool_version_extract.rpt`,
  `lvs_status_extract.rpt`, and `netlist_port_extract.rpt`;
- `pin_name_audit.rpt`, including adjacent bracket dimensions and empty bracket
  groups;
- `hashes.sha256` and `collection_status.rpt`;
- `git_text_candidate/`, which excludes GDS, OA, full netlists, PDK collateral,
  installed rule decks, and PVS result databases, and includes its own
  `MANIFEST.sha256` transfer manifest.

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

## Multi-Dimensional Pin-Name Hypothesis

Names such as `foo[3][2]`, `foo<3><2>`, escaped Verilog identifiers, and truly
empty forms such as `foo[][]` must be inventoried, but their presence alone is
not an LVS root cause.

The hypothesis becomes proven only when the evidence shows one of these:

- source parsing changed or rejected the name;
- layout and source normalized the same bit differently, for example
  `foo[3][2]` versus `foo<3><2>` without an accepted equivalence rule;
- an unmatched/extra/missing top-port report names those exact terminals;
- two distinct scalar pins collapsed onto one canonical name;
- hierarchy flattening changed array dimensions or bit order.

If both compared sides preserve and match the same scalar terminal names, the
double dimension is not the mismatch cause.

Do not reroute merely to replace `[][]`. Routing geometry does not repair a
source-parser or boundary-label naming contract. If a naming mismatch is
proven, choose one reviewed canonical convention and change every affected
contract together: RTL/source netlist, OA terminals and labels, LEF pins,
Verilog escapes, constraints, testbench mappings, and LVS controls. A flattened
index such as `k=i*NJ+j` or a physical name such as `foo_i_j` is possible only
after dimensions and ordering are frozen; using `i+j` is not unique and can
alias different pairs.

## PG, Routing, and Antenna Scope

- Improve packet-core PG only if LVS evidence proves VDD/VSS opens, shorts,
  missing globals, or boundary-PG disagreement. Do not mix a speculative PG
  redesign into a port-name investigation.
- Improve signal routing only after an extracted open/short identifies the net
  and location. A top-name, library, hierarchy, or label mismatch is not fixed
  by rerouting.
- Antenna is a separate DRC/manufacturability gate, not an LVS comparison gate.
  It may remain deferred during this read-only LVS diagnosis, but it cannot be
  ignored for final handoff or signoff. Preserve its marker count and repair it
  in a separately reviewed step.

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

## Canonical Rerun Implementation

The later correction phase is now implemented without modifying the historical
run. Fresh immutable packages preserve the raw Innovus PG netlist, derive a
CDL-filtered canonical source, require exact LEF/source top-pin parity, and copy
the official JIHD CDL into the package. Template replay now requires every old
GDS/source/CDL/top value to exist before replacement and verifies the patched
semantic contract afterward.

Base and density DRC are distinct replay variants. LVS accepts only an explicit
report-level `MATCH`. The complete positive and negative contract is in
`TOP/docs/37_PVS_CANONICAL_SOURCE_AND_REPLAY_CONTRACT.md`.
