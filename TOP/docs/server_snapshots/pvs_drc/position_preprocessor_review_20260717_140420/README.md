# Position PVS DRC Preprocessor Review Snapshot

- Diagnostic ID: `position_pvs_drc_preprocessor_review_20260717_140420`
- Diagnostic root:
  `/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_drc_preprocessor_review_20260717_140420`
- Repository branch: `SPADMIC_test`
- Repository commit: `0d549dc248b9e315113cee1a7af68887c6fcb487`
- Accepted Position GDS SHA-256:
  `ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1`
- Collection method: foreground, read-only PDK/preprocessor evidence collection
- PVS execution: not attempted

## Accepted Evidence

The R06b diagnostic, candidate matrix, source controls, technology-library
file, and immutable package all reproduced their pinned hashes. The package
manifest passed before and after collection.

```text
COLLECT_RC=0
STATUS=PASS
MATRIX_CANDIDATE_COUNT=114
MATRIX_INCOMPLETE_COUNT=0
UNIQUE_DIRECTIVE_TUPLE_COUNT=2
MATRIX_COMPLETENESS_STATUS=PASS
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=0
PACKAGE_MODIFIED=NO
PVS_EXECUTED=NO
```

All 114 controls use the same state for four selectors:

```text
DENSITY=UNDEFINED
POPPING=UNDEFINED
PIMIDE=UNDEFINED
DUMMY_FILL=UNDEFINED
```

Only `VAR_ANT_RATIO` varies: 111 candidates undefine it and three define it.
The candidate names remain in the full server-side matrix and are collected
explicitly by the next transaction.

## Relative Mapping Correction

The exact `pvtech.lib` is 52 bytes and contains:

```text
UNDEFINE XH018_1131
DEFINE XH018_1131 .pvsSetup/PVS
```

The generated `pvtech_reference_candidates.rpt` rendered this as `/PVS`.
That is a parser artifact caused by extracting only slash-prefixed substrings;
it is not evidence for an absolute `/PVS` path. The checked-in follow-up
preserves `.pvsSetup/PVS`, resolves it relative to the directory containing
`pvtech.lib`, and inventories the bounded rule setup without copying a deck.

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
`TOP/ci/server_discover_position_core_pvs_rule_setup.sh`. It is another
read-only discovery gate, not permission to create controls or execute PVS.
