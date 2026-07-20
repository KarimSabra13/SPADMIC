# Position PVS DRC GDS Layer Applicability Snapshot

- Diagnostic ID: `position_pvs_drc_gds_layer_applicability_20260720_105724`
- Diagnostic root:
  `/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_gds_layer_applicability_20260720_105724`
- Repository branch: `SPADMIC_test`
- Repository commit: `a622dd0bf88478ecf124a448296c7390702d2d1f`
- Accepted Position GDS SHA-256:
  `ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`
- Collection method: foreground, read-only binary GDS hierarchy inventory
- PVS execution: not attempted

## Accepted Evidence

The complete 11,523,506-byte GDS parsed successfully. The declared top was
found, all 218 structures were reachable, all 129,097 serialized element
records were accounted for, and there were no unresolved reachable references
or hierarchy-cycle edges. The package GDS, official stream map, and exact DRC
deck retained their pinned hashes before and after review.

```text
REVIEW_RC=0
STATUS=PASS
GDS_PARSE_STATUS=PASS
GDS_TOP_STRUCTURE_STATUS=PASS
GDS_HIERARCHY_STATUS=PASS
TARGET_LAYER_MAPPING_STATUS=PASS
SOURCE_RECHECK_STATUS=PASS
ERROR_COUNT=0
PACKAGE_MODIFIED=NO
PVS_EXECUTED=NO
```

## Applicability Decision

The deck mappings are exact and the accepted hierarchy contains no geometry or
text on any target tuple:

```text
PAD=GDS 19/0; REACHABLE_GEOMETRY=0; REACHABLE_TEXT=0
PIMIDE=GDS 221/5; REACHABLE_GEOMETRY=0; REACHABLE_TEXT=0
NOPIM=GDS 46/0; REACHABLE_GEOMETRY=0; REACHABLE_TEXT=0
PIMIDE_POSITION_APPLICABILITY_STATUS=NOT_APPLICABLE_NO_REACHABLE_PAD_OR_PIMIDE_GEOMETRY
```

`PIMIDE` therefore remains undefined for Position out-of-context DRC. The
accepted option policy is:

```text
DEFAULT_RULE_SET=default
DENSITY=UNDEFINED for base; separate DENSITY=DEFINED run required
POPPING=UNDEFINED; defer to post-fill chip-level context
DUMMY_FILL=UNDEFINED; no virtual fill in Position OOC DRC
VAR_ANT_RATIO=DEFINED; retain supplemental ADD_* antenna checks
PIMIDE=UNDEFINED; branch is not applicable to this hierarchy
```

## Manual Review Decision

The R10 collector recommended `READY_FOR_MANUAL_AUTHORIZATION`. This repository
review accepts that recommendation for strict dry-run preflight only. It
authorizes use of the pinned packet-core controls as a control scaffold, with
the Position GDS/top and all run outputs rewritten into isolated run-local
paths. It does not authorize PVS execution or promote any DRC/LVS gate.

The next transaction is
`TOP/ci/server_preflight_position_core_pvs_drc.sh`. It materializes and audits
both base and density controls with `--dry-run` in one foreground transaction.
If both contracts pass, the next expensive gate is one attributable base DRC
run followed by report-level classification.
