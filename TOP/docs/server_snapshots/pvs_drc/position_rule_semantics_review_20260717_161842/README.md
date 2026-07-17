# Position PVS DRC Rule-Semantics Review Snapshot

- Diagnostic ID: `position_pvs_drc_rule_semantics_review_20260717_161842`
- Diagnostic root:
  `/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_rule_semantics_review_20260717_161842`
- Repository branch: `SPADMIC_test`
- Repository commit: `8f4154d658c7fd9d6cb8deca98c6f5bf04807705`
- Accepted Position GDS SHA-256:
  `ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`
- Collection method: foreground, read-only rule-semantics review
- PVS execution: not attempted

## Accepted Evidence

All source R08 reports, the immutable package, the exact DRC deck and GUI
configuration, both named rule-set files, the metal switch, and the user guide
reproduced their pinned identities. Package manifests passed before and after
review, and every inspected source remained unchanged.

```text
REVIEW_RC=0
STATUS=PASS
SEMANTICS_COLLECTOR_RC=0
SEMANTICS_COLLECTOR_GATE_RC=0
SOURCE_REFERENCE_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=0
PACKAGE_MODIFIED=NO
PVS_EXECUTED=NO
```

## Rule-Set Contract

The project and PDK metadata agree that named rule set `default` uses
`metalswitch.pvl` plus `xh018_DRC.rul`, with `pvs.cfg` as the DRC GUI
configuration. The other named sets either add dummy-output generation or
BlackBox/LEF antenna support and are not the selected default.

The selected metal switch is XH018 v10.1.1 `MET3 / METMID`:

```text
METAL3=DEFINED
MIDMET=DEFINED
METAL4=UNDEFINED
METAL5=UNDEFINED
METAL6=UNDEFINED
THKMET=UNDEFINED
XFAB_IP_BBOX_ANTENNA=UNDEFINED
```

The normal `pvs.cfg` default for every reviewed selector is zero. All
conditional families are balanced and fully attributable: one `DENSITY`
block with 34 rules, one `POPPING` block with six rules, one `PIMIDE` branch,
two `DUMMY_FILL` branches, and 78 `VAR_ANT_RATIO` blocks. There are no
unmatched conditionals.

## Policy Evidence

- `DENSITY` adds a separate density family and remains a separate run.
- `POPPING` adds W5M* checks described for post-fill, mostly chip-level use.
- `DUMMY_FILL` generates virtual dummy geometry and is off by default.
- `VAR_ANT_RATIO` adds `ADD_*` antenna checks; it does not replace the normal
  antenna rules.
- `PIMIDE` enables the PAD-without-PIMIDE marker branch, but neither the guide
  nor the deck alone proves whether the accepted Position hierarchy contains
  PAD or PIMIDE geometry.

## Remaining Gate

```text
DEFAULT_RULE_SET_EVIDENCE_STATUS=PASS
DEFAULT_RULE_SET_SELECTION_STATUS=REVIEW_REQUIRED
PIMIDE_APPLICABILITY_STATUS=REVIEW_REQUIRED
STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
PVS_BASE_DRC_STATUS=NOT_RUN
PVS_DENSITY_DRC_STATUS=NOT_RUN
PVS_LVS_STATUS=NOT_RUN
BLOCK_PROMOTION_AUTHORIZED=NO
SIGNOFF_READY=NO
```

The next transaction is
`TOP/ci/server_review_position_core_pvs_drc_gds_layer_applicability.sh`. It
resolves the deck's exact PAD/PIMIDE stream tuples and inventories only the
GDS structures reachable from `spadmic_position_core`. It does not create a
template, copy a deck, or execute PVS.
