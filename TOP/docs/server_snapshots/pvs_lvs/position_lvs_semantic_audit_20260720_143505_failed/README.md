# Position Exact-GDS LVS Semantic-Audit Stop

This snapshot records the corrected foreground attempt launched on 2026-07-20
from commit `0a0220a5c5d3914ffcd408432394e73c9b4a0f55`. The server diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_execution_20260720_143505
```

All six observed scaffold hashes matched, and all accepted density, package,
GDS, canonical source, CDL, and source-reference gates passed. The read-only
semantic audit correctly extracted the historical layout/source tops, GDS,
and Verilog source. It then failed only because the current `pvslvsctl` has no
explicit `mask_svdb_dir` directive:

```text
TEMPLATE_IDENTITY_GATE_RC=0
SVDB_DIRECTORY_COUNT=0
ERROR_COUNT=1
ERROR=svdb_directory_count=0
TEMPLATE_SEMANTIC_GATE_RC=1
```

This was an over-strict intake rule. `mask_svdb_dir` controls an output
location, not an LVS comparison input. The existing replay normalizer already
treated it as optional, and the unique run working directory prevents default
outputs from landing in the immutable source scaffold. The corrected contract
is stronger and explicit: zero or one incoming SVDB directive is accepted;
replay adds or rewrites exactly one run-local directive; more than one fails as
ambiguous.

No replay directory was materialized and no PVS process ran:

```text
PVS_WRAPPER_RC=NOT_RUN
PVS_TOOL_RC=UNKNOWN
PVS_LVS_STATUS=UNKNOWN
PVS_EXECUTED=NO
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=0
```

This is neither a match nor mismatch and changes no physical gate. Base DRC
remains attributable zero; density remains four attributable whole-extent
rules; exact-GDS LVS remains open. The next action is one foreground retry on
the unchanged inputs. Base and density DRC must not be rerun.
