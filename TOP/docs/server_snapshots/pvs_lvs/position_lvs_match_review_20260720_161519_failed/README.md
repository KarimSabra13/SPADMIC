# Position LVS Match Read-Only Review Control-Gate Stop

This snapshot records the read-only acceptance review launched on 2026-07-20
from exact commit `597d8f3e457b71b05bfdded450ebc8f91d4bc9e9`. It reviewed, but did not rerun,
the immutable Position LVS evidence rooted at:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_execution_20260720_155406
/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810/pvs/lvs/position_exact_gds_lvs_20260720_155406
```

The review revalidated all pinned report and package hashes, both manifests,
diagnostic-to-run copy identity, explicit positive match evidence, zero negative
match patterns, replay identity, output isolation, and external references:

```text
SOURCE_FILE_GATE_RC=0
SOURCE_HASH_GATE_RC=0
SOURCE_DIAGNOSTIC_MANIFEST_RC=0
SOURCE_STATUS_GATE_RC=0
RUN_COPY_IDENTITY_GATE_RC=0
RUN_MANIFEST_RC=0
PACKAGE_SHA_MANIFEST_RC=0
RUN_MATCH_GATE_RC=0
RUN_REPLAY_GATE_RC=0
RUN_ISOLATION_GATE_RC=0
RUN_REFERENCE_GATE_RC=0
```

The sole failed review gate was:

```text
RUN_CONTROL_GATE_RC=1
```

That gate counted unscoped full-path text lines in `pvslvsctl`. The returned
transaction did not emit the four individual counts, so the specific literal
whose count differed from one is unknown. This check duplicated stronger
directive-aware replay and isolation proofs and could reject harmless metadata
or repeated non-executable text.

The replacement audit parses only executable `layout_path`, Verilog and Spice
`schematic_path`, and `mask_svdb_dir` directives. It requires exactly one of
each with the accepted Position GDS, canonical source, package CDL, and
run-local SVDB path. It is read-only and records the control SHA-256 and every
parsed value in the review diagnostic.

No PVS process was launched by this review, and Event Genus correctly remained
`NOT_RUN`. Position base DRC remains `PASS`; density remains `FAIL` with four
whole-extent coverage rules; promotion and signoff remain forbidden. Retry only
the read-only acceptance review. On attributable `MATCH`, start Event TC Genus.
