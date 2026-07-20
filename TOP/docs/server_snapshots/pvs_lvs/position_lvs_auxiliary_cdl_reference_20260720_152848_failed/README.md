# Position Exact-GDS LVS Auxiliary-CDL Reference Stop

This snapshot records the foreground attempt launched on 2026-07-20 from
commit `98a616c30246f457f0f105e91868a9213825dc96`. The server diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_execution_20260720_152848
```

The density source diagnostic, exact Position GDS, canonical LVS source,
package-local JIHD CDL, package manifest, six scaffold hashes, scaffold
semantics, and foundry references all passed. Replay then materialized a
package-local run with the canonical Position comparison inputs and tops:

```text
TEMPLATE_IDENTITY_GATE_RC=0
TEMPLATE_SEMANTIC_GATE_RC=0
PATCH_RC=0
REPLAY_CONTRACT_STATUS=PASS
OUTPUT_ISOLATION_STATUS=PASS
SCHEMATIC_CDL_ACTION=ADDED_MISSING
SVDB_ACTION=ADDED_MISSING
```

The final external-reference gate found one stale auxiliary CDL path:

```text
MISSING=/sim/ksabra/SPADMIC_work/handoff/innovus/blocks/spadmic_position_core/tx_packet_pvs_waiver_20260716_130442/pdk/xh018_D_CELLS_JIHD.cdl
ERROR: patched PVS template has missing external references
```

The executable `pvslvsctl` had no incoming Spice/CDL directive, so replay
correctly added the hash-pinned package CDL. The remaining path came from the
copied auxiliary control metadata. Its mixed Position block and TX run name
show that the scalar top rewrite reached a historical same-basename CDL path
before that auxiliary path was canonicalized.

The wrapper stopped before launching PVS:

```text
PVS_WRAPPER_RC=1
PVS_TOOL_RC=UNKNOWN
PVS_LVS_STATUS=UNKNOWN
PVS_EXECUTED=NO
SOURCE_POST_RECHECK_RC=0
PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=0
```

This is neither an LVS match nor mismatch. The correction does not infer a
comparison library from GUI metadata. The canonical CDL remains selected from
the immutable Position package and hash-gated by the driver. Replay now
rewrites only absolute auxiliary references with that exact CDL basename to
the canonical package path before scalar top rewrites. Any unrelated missing
path remains visible and continues to stop execution.

No base or density DRC rerun is authorized. The next action is one foreground
exact-GDS LVS retry on the unchanged Position GDS, source, and CDL.
