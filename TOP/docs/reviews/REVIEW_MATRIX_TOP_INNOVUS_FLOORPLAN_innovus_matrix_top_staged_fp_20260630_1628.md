# Review: Matrix TOP staged Innovus floorplan run

- Branch: `SPADMIC_test`
- Source commit reviewed: `e79f96bc05cb1aff6f1eb384188d1a592a538a90`
- Snapshot commit observed locally: `c72e620b7e33fa04adbe806168e224473bb77974`
- Run ID: `innovus_matrix_top_staged_fp_20260630_1628`
- Snapshot: `TOP/docs/server_snapshots/innovus/innovus_matrix_top_staged_fp_20260630_1628/`
- Tool stack: XH018 `xx31`, JIHD, `MET1 MET2 MET3 METTP`
- Signoff status: planning only; Innovus was intentionally not launched

## Result

The wrapper returned `FP_RC=5`, which is the expected stop code for a failed
planning geometry gate:

- status: `FAIL`
- issue: `MPTDC_VERTICAL_STACK_EXCEEDS_CORE_HEIGHT`
- die: `3800 um x 2700 um`
- die area: `10.260 mm2`
- pad/core keepout: `120 um`
- matrix area: `3.450925 mm2`
- MPTDC placeholder area: `1.0 mm2` per axis
- MPTDC placeholder aspect: `4:3`
- MPTDC placeholder width/height: `1154.701 um x 866.025 um`
- stack height including gaps: `2678.076 um`
- height excess: `109.038 um`
- max MPTDC area that fits with this aspect/stack: `0.839170 mm2`

## Checks

- The generator used normalized matrix `ll_*` coordinates.
- The plan found `184` `INTERNAL_NEAREST_RIGHT` pins and kept the internal-right corridor visible.
- `VTUNE` remains analog-owned and is not treated as an unknown digital matrix pin.
- The staged wrapper stopped before Innovus because `STATUS=FAIL`.

## Findings

| Severity | Finding | Status |
| --- | --- | --- |
| BLOCKER | The default 1.0 mm2, 4:3 MPTDC placeholder vertical stack does not fit the current core height. Do not proceed to real top placement with this geometry. | OPEN |
| MEDIUM | The failure is aspect/height-driven, not width-driven. A local explicit candidate with aspect `1.8` and the same 1.0 mm2 per MPTDC passes the generator in the same die. This must be rerun on the server and later checked against real MPTDC handoff dimensions. | OPEN |
| MEDIUM | Pad-ring keepout is still a `120 um` planning assumption. Real pad-ring LEF/DEF may change the available core box. | DEFERRED |
| NOTE | DDR16 north-side policy is present but remains low priority and not a placement blocker for the next TOP physical step. | DEFERRED |

## Verifier Conclusion

The run did exactly what the staged flow was designed to do: stop before running Innovus when the current geometry is not viable. The next action is an explicit aspect/die scenario run, not placement.
