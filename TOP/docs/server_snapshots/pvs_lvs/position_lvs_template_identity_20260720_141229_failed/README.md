# Position Exact-GDS LVS Template-Identity Stop

This snapshot records the failed foreground transaction launched on
2026-07-20 from commit `285dfc53b6bcf544bb5a42545edb17f3edc6b2c1`.
The server diagnostic is:

```text
/sim/ksabra/SPADMIC_work/diagnostics/position_pvs_lvs_execution_20260720_141229
```

This is a no-execution infrastructure stop, not an LVS mismatch. The accepted
Position density diagnostic, exact GDS, canonical LVS source, JIHD CDL, and
package manifest all passed their identity gates. The transaction stopped
because four GUI-managed files in the historical cross-block LVS scaffold no
longer matched the hashes captured on 2026-07-10:

| Control | July 10 SHA-256 | Observed SHA-256 | Result |
| --- | --- | --- | --- |
| `.preset.autosave` | `24a96996d39f98e12c1b1bbc7dc7af74ff2ba5b1152dd0afe462b7ffb3cf2687` | `43d19579b0569863b1c5fcc317206cc5f3f70611b22f9bdea932d757ff902dfe` | drift |
| `pipo1.setup` | `449148fe96167a6d0787861c3575a6f31f4c9598e972ee8a7026e9fb3383dc85` | `ed8c1a13ab8ec90af3f367b4d408e5f9c767f1e99736e31f02c54be9fa91abbc` | drift |
| `pvslvsctl` | `7fc5ffd6115ee9ab9aa78a3964f01a43941a0926e2c1d1c53c5b7ede3f25767d` | `8e53876734717f4c0857f1310d08e3a4c8fb18aeaa7694800b7d0cdcd511c5e6` | drift |
| `run.pvs` | `8c0c4e925cf7e595be64685bf01e5bc3e9059ea655a4da0980e67d04dfc113a9` | `dfe5394bd98c828e868a7a3f18acda2f56f993ba58dcf8343f097858f77b0c27` | drift |

`.config.rul` and `.technology.rul` remained unchanged. No replay directory
was materialized, no PVS console log or result report exists, and no physical
status can be inferred:

```text
TEMPLATE_IDENTITY_GATE_RC=1
PVS_WRAPPER_RC=NOT_RUN
PVS_TOOL_RC=UNKNOWN
PVS_LVS_STATUS=UNKNOWN
PVS_EXECUTED=NO
```

The correction pins the exact observed six-file baseline and adds a read-only
semantic audit before replay. The audit requires one LVS launcher, one layout
and source top, one GDS and Verilog input, safe port-comparison settings,
`DUMMY_FILL` undefined, and isolated LVS/ERC output directives. The historical
directory remains immutable. Replay still clones it, forces the accepted
Position GDS/source/top and package-local CDL, and rejects stale executable
inputs or unresolved external references before PVS starts.

The next action is one corrected foreground exact-GDS LVS transaction. Base
and density DRC must not be rerun.
