# PVS Canonical Source And Replay Contract

Status: `IMPLEMENTED_WITH_PROVISIONAL_PACKET_LVS_MATCH`

This document records the reproducible PVS DRC/LVS contract created after the
historical `spadmic_tx_packet_core_HV` mismatch was classified. It applies to
the fresh canonical `spadmic_tx_packet_core` rebuild and then to
`spadmic_tx_ddr_strip`.

## 1. Package Source Model

Each immutable package contains both source forms:

```text
netlist/<source_top>.innovus.pg.v  raw saveNetlist -includePowerGround output
netlist/<source_top>.lvs.pg.v      canonical filtered PVS source
pdk/xh018_D_CELLS_JIHD.cdl        exact official CDL copy used by replay
reports/lvs_source_preparation.rpt input, pin, module, and hash gates
```

The raw source is evidence and is never silently overwritten. The canonical
source keeps the top and every design-owned/non-JIHD module. It removes a
module definition only when its case-folded name matches an official CDL
`.SUBCKT`. Cell instances remain in the design netlist and resolve through the
package-local CDL during PVS.

This is deliberate abstraction matching. Layout contains merged JIHD device
geometry; source uses JIHD CDL device definitions. Retaining duplicate Verilog
cell definitions would return to the historical incompatible abstraction.

## 2. Source Preparation Gates

`TOP/pnr/scripts/prepare_pvs_lvs_source.py` refuses output unless all gates
pass:

1. Input PG netlist, block LEF, and CDL are non-empty files.
2. Verilog module/end-module structure is balanced.
3. The canonical source top has exactly one definition.
4. Source top does not collide with a CDL subcircuit name.
5. VDD and VSS are explicit top ports.
6. No top port contains an adjacent nested dimension `][`.
7. Exactly one supplied LEF has a macro matching the source top.
8. Expanded Verilog top ports and LEF pins have exact set parity.
9. No retained module overlaps the official CDL cell-name set.
10. Every instantiated master resolves to a retained design module, a CDL
    subcircuit, or a recognized Verilog primitive.
11. The output hash is recorded only after every gate passes.

One-dimensional vectors are expanded for parity. Escaped bit names such as
`\foo[3]` normalize to LEF name `foo[3]`. The active TX source-data boundary
uses scalar `src_data_i_s<source>_b<bit>` names, so a reintroduced
`src_data_i[i][j]` top pin fails before PVS.

Negative rules:

- Do not delete every module except the top; custom hierarchy may be required.
- Do not classify a module as JIHD from a name prefix or suffix. CDL membership
  is the authority.
- Do not assume an undefined cell will be resolved later. Missing design/CDL
  masters stop staging before PVS.
- Do not edit the routed netlist in place. Preserve raw and derived sources.
- Do not waive missing VDD/VSS or LEF/source pin differences.
- Do not treat source parsing as LVS success; it is only a pre-run gate.

## 3. Immutable Staging

`stage_innovus_handoff.py` now performs source preparation while creating a
new package. It copies the CDL into the package even when the broader shared
PDK bundle is not requested. `package.json` records canonical source and CDL
paths and SHA256 hashes. `audit_innovus_handoff.py` independently requires:

- raw and canonical netlists;
- package-local CDL;
- source-preparation `STATUS=PASS`;
- `PIN_PARITY_STATUS=PASS`;
- matching source top and canonical source hash;
- matching CDL manifest hash;
- all original package SHA256 entries.

For packet and strip, use `--qualification-profile canonical_tx` and include
the Innovus `canonical_tx_ooc_gate.rpt`. Staging refuses a missing gate, a
non-PASS gate, a result other than `READY_FOR_PVS_CANDIDATE`, or a macro name
that differs from the package name.

A failed preparation leaves an immutable failed package for diagnosis. Use a
new version ID after correcting the input; do not overwrite the failed one.

## 4. Strict Template Replay

`replay_pvs_handoff_template.py` copies only the executable/control portion of
a GUI-generated template. Every explicit `OLD=NEW` replacement is counted in
the original copied text. If an old GDS, source, CDL, or top value is absent,
replay stops with `REPLACEMENT_SOURCE_NOT_FOUND`.

The replacement order matters. Specific GDS/source/CDL paths are replaced
before the template root is relocated. The previous order relocated the root
first, changing `/template/old.gds` to `/run/old.gds`; the later exact
replacement could no longer match. That behavior could report patch success
while retaining the wrong artifact path. Do not restore that order.

The GUI directory selected as the template is not necessarily the directory
that `run.pvs` executes. PVS UI files can contain an absolute `cd`, control
path, cell-tree path, or result-database path pointing to a sibling historical
run. Therefore replay also discovers the actual GUI execution root and
relocates it to the immutable run directory. It then forces:

- the shell working directory to the immutable run directory;
- `-control`, `-cell_tree`, `.config.rul`, and `.technology.rul` to copied
  run-local files;
- DRC summary and result-database paths to the immutable run directory;
- LVS report, ERC summary/database, SVDB, and extracted-layout SPICE paths to
  the immutable run directory.

If `run.pvs` names an external `cell_tree.txt`, replay copies and hashes it
before patching. Missing execution dependencies fail the replay contract.
PVS return code or reports written outside the immutable run are not
attributable evidence.

After patching, replay independently proves:

- selected absolute Cadence PVS binary is in `run.pvs`;
- execution and generated result paths are run-local;
- expected layout top is the `-top_cell` value;
- expected LVS source top is the `-source_top_cell` value;
- canonical GDS path occurs in copied controls;
- canonical source path occurs in LVS controls;
- package-local CDL path occurs in LVS controls;
- no replaced template value remains;
- all external files/directories are inventoried and hashed when regular
  files.

Generated evidence:

```text
template_replacements.rpt
preprocessor_defines.rpt
replay_contract_status.rpt
output_isolation.rpt
external_references.rpt
SHA256SUMS
```

## 5. Base And Density DRC

`run_pvs_drc_handoff.sh --variant base` forces:

```text
#UNDEFINE DENSITY
```

`--variant density` forces:

```text
#DEFINE DENSITY
```

The requested symbol must already exist as a DEFINE/UNDEFINE control in the
GUI template. A missing symbol is an error because silently appending a define
would not prove that the foundry wrapper consumes it. Base and density use
separate immutable run IDs and status files. Base DRC zero does not transfer to
density DRC, and neither result transfers across GDS hashes.

## 6. LVS Acceptance

`run_pvs_lvs_handoff.sh` audits the package before cloning the template. It
requires the canonical source-preparation and pin-parity reports, replaces the
template GDS/source/CDL/top values, and requires the strict replay contract.

PVS process return code alone is not accepted. The result parser passes only
an explicit report-level `MATCH`. `MISMATCH`, `UNKNOWN`, missing report, stale
path, or missing CDL all remain failures.

The parser also writes `pvs_result_evidence_inventory.rpt`. An unknown DRC
run records every scanned run-local text artifact and the number of matching
summary lines. Conflicting `Total DRC Results` totals remain `UNKNOWN`.
Nonzero DRC is accepted as classified debt only when both the underlying PVS
tool return code is zero and a unique report-level total exists.

## 7. GUI Template Requirements

Prefer one fresh canonical packet template on the Cadence server after the
new package exists. The GUI run must visibly contain:

- layout GDS: package `gds/spadmic_tx_packet_core.gds`;
- layout top: `spadmic_tx_packet_core`;
- Verilog source: package `netlist/spadmic_tx_packet_core.lvs.pg.v`;
- source top: `spadmic_tx_packet_core`;
- CDL source: package `pdk/xh018_D_CELLS_JIHD.cdl`;
- explicit VDD/VSS handling;
- same XH018_1131 technology/rule-set used by the approved DRC template;
- DENSITY configurator symbol present for deterministic base/density replay.

Preserve the first GUI run. Replays clone it; they never edit it. Record the
exact embedded old paths from its controls rather than guessing them from GUI
labels.

For the urgent provisional diagnostic, Section 11 permits the immutable
historical same-block template only after executable input and output
enforcement. That exception does not relax any canonical input requirement.

## 8. Commands Not To Retry

- Do not rerun the `_HV` template unchanged.
- Do not use the old compared GDS or source hash as the new package input.
- Do not omit the JIHD CDL because the GDS already merged JIHD geometry.
- Do not keep JIHD Verilog definitions and provide JIHD CDL simultaneously.
- Do not pass a guessed `--template-cdl`; strict occurrence checking will and
  should reject it.
- Do not invoke bare `pvs`; use the explicit Cadence binary selected by the
  wrapper.
- Do not infer MATCH from return code, an empty `.err`, DRC zero, or a summary
  generated for another GDS hash.
- Do not run density by manually editing a completed base run. Clone the same
  template into a new immutable density run.

## 9. Local Verification

The local tests cover module filtering by CDL membership, raw-source
preservation, VDD/VSS and nested-name guards, vector-to-LEF expansion, pin
parity failure, package hashes, strict replacement occurrence, canonical
artifact presence, base DENSITY undefine, and density define. Cadence PVS is
not available locally; the GUI template, extraction, DRC, and comparison
remain server gates.

## 10. Provisional Packet-Core Waiver Profile

Qualification profile `canonical_tx_lvs_waiver` is a diagnostic extension of
this contract for one exact `spadmic_tx_packet_core` state. It requires a
mapped/merged GDS audit and hashes the exact four-marker waiver reports into
the immutable package.

The profile deliberately records:

```text
PVS_DRC_WAIVER=NO
LVS_DIAGNOSTIC_ONLY=YES
MANUAL_DRC_FIX_REQUIRED=YES
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

PVS DRC remains an honest independent result. LVS does not require DRC zero,
but it still requires the same canonical source preparation, package-local
JIHD CDL, strict template replay, and explicit report-level `MATCH` described
above. A provisional `MATCH` must be rerun after the four physical violations
are fixed because acceptance never transfers across GDS hashes.

The waiver inventory, export method, execution gates, and retirement
requirements are defined in
`38_TX_PACKET_CORE_PROVISIONAL_DRC_WAIVER_AND_PVS_LVS_EXECUTION.md`.

## 11. Executable LVS Input Enforcement

Template-wide string presence is not enough to prove the LVS source contract.
The historical packet `_HV` GUI preset names an OA-generated CDL file, while
its executable `pvslvsctl` contains only the routed Verilog
`schematic_path`. A replay could therefore pass a naive CDL path check without
actually loading the package-local official JIHD CDL.

The strict replay now enforces these executable control invariants:

```text
layout_path = exactly the staged canonical GDS
schematic_path <canonical filtered source> verilog = exactly one
schematic_path <package official JIHD CDL> spice = exactly one
```

The Verilog directive must already exist and is rewritten. The Spice/CDL
directive is rewritten when present or inserted immediately after the
existing schematic input when absent. Multiple directives of either format
are rejected because silently choosing among source decks would make the
comparison ambiguous.

`output_isolation.rpt` records:

```text
LAYOUT_GDS_INPUT
LAYOUT_GDS_REWRITE_COUNT
SCHEMATIC_VERILOG_INPUT
SCHEMATIC_VERILOG_ACTION
SCHEMATIC_CDL_INPUT
SCHEMATIC_CDL_ACTION
```

The final replay gate reparses `pvslvsctl` and requires exact canonical path
equality. A path that appears only in `.preset.autosave`, a comment, or a
nonexecuted copied file cannot satisfy this gate.

## 12. Provisional Packet Match And GUI Review Contract

The executable-input repair was validated by immutable run:

```text
tx_packet_pvs_waiver_20260716_130442_pvs_lvs_execinputs_5bcaaf7d
```

Its result is an explicit report-level match:

```text
PVS_RC=0
PVS_LVS_STATUS=MATCH
LVS_NEGATIVE_MATCH_COUNT=0
LVS_POSITIVE_MATCH_COUNT=3
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
```

This proves the canonical GDS, filtered Verilog source, package-local JIHD
CDL, and canonical top names were the executable comparison inputs. The
historical `_HV` directory supplied the foundry launch/rule scaffold only.

GUI review must preserve the immutable run. Use
`open_pvs_lvs_gui_review.sh`, which refuses a non-match, missing evidence,
failed replay contract, failed output isolation, or missing external
reference. It copies the complete result to a fresh `/tmp` directory and
relocates copied run-path metadata before starting:

```text
lvsbrowser  result and comparison review
pvsgui      copied setup/preset review
```

The original run is never opened directly. A shell-launched browser is not a
substitute for Virtuoso-integrated cross-probing, and a GUI rerun in the
disposable copy is not attributable signoff evidence.
