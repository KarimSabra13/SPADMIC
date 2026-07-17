# Position PVS DRC Rule-Setup Discovery Snapshot

- Diagnostic ID: `position_pvs_drc_rule_setup_discovery_20260717_150856`
- Diagnostic root:
  `/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_rule_setup_discovery_20260717_150856`
- Repository branch: `SPADMIC_test`
- Repository commit: `329950f10f42d8ddc50a4ada8d626a3cdebf04ea`
- Accepted Position GDS SHA-256:
  `ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`
- Collection method: foreground, read-only rule-setup discovery
- PVS execution: not attempted

## Accepted Evidence

The complete preprocessor diagnostic, immutable package, source `pvtech.lib`,
and primary seed control reproduced their pinned hashes. Package manifests
passed before and after discovery.

```text
RULE_SETUP_RC=0
STATUS=PASS
RULE_SETUP_COLLECTOR_RC=0
RULE_SETUP_COLLECTOR_GATE_RC=0
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=0
PACKAGE_MODIFIED=NO
PVS_EXECUTED=NO
```

The raw technology mapping was resolved without the earlier substring error:

```text
PVTECH_MAPPING_RAW=.pvsSetup/PVS
MAPPING_LEXICAL=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.pvsSetup/PVS
MAPPING_CANONICAL=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.pvsSetup/PVS
MAPPING_CANONICAL_EXISTS=YES
```

The bounded scan also found the canonical PDK root at
`/data/pdk/xfab/xh018/cadence/v10_1/pvs/v10_1_1/PVS`. It recorded 59
inventory entries, 35 readable text files, and seven files containing at
least one reviewed directive.

## Selector Evidence

The normal `pvs.cfg` defaults `DENSITY`, `POPPING`, `PIMIDE`, `DUMMY_FILL`,
and `VAR_ANT_RATIO` to `0`. Only three of the 114 discovered controls define
`VAR_ANT_RATIO`: `SPADMIC2`, `TXRX4TDC2_HV`, and
`spadmic_tx_packet_core`.

The deck evidence establishes that:

- `DENSITY` gates the separate density rule family.
- `POPPING` gates a section labeled `IMD Popping Checks`.
- `PIMIDE` selects a pad-marker rule branch.
- `DUMMY_FILL` controls dummy pattern generation and output behavior.
- `VAR_ANT_RATIO` selects an additional variable-ratio antenna family.

These meanings do not establish that every optional process branch applies to
the internal Position block. The prior reference excerpt also omitted the
surrounding rule-set names, so it did not yet bind the source
`-ruleSet "default"` selector to one exact `DrcRules` entry.

## Remaining Gate

```text
PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED
TEMPLATE_SELECTION_AUTHORIZED=NO
CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO
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
`TOP/ci/server_review_position_core_pvs_drc_rule_semantics.sh`. It records
full numbered rule-set metadata and hashes complete conditional blocks in
place. It does not select a template, create controls, copy a deck, or execute
PVS.
