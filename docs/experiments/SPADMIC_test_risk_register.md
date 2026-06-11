# SPADMIC_test Risk Register

| Risk | Area | Status | Mitigation |
| --- | --- | --- | --- |
| START accepted during PD clear teardown | Async frontend | Patched in `SAFE_TEARDOWN` | `frontend_teardown_busy_i` blocks START and reports rejection |
| `ready` high while teardown is active | Core status | Patched in `SAFE_TEARDOWN` | `ready` requires arm, free context, no start, FSM idle, and no teardown |
| Fast-tag reset release is not synchronous to all fast phases | Fast tags | Open | Kept as `RESET_RECOVERY_NOT_SIGNOFF_READY`; do not globally waive |
| Row-skip metadata mismatch | Snapshot/drain | Test required | Row metadata stored with the snapshot; local tests cover H0 and H1 each row |
| Stride-2 drops adjacent hit | Drain | Test required | Second adjacent hit stored in local pending record |
| Stride-2 duplicates event sequence | Drain | Test required | `event_seq_q` advances by actual emitted hit count in scanned pair |
| Drain mux timing worsens | `clk_sys` | Open until Genus | Review `mptdc_drain_ctrl` and context-to-drain paths |
| Clear fanout transition worsens | Reset/clear | Open until Genus/P&R | Review `meas_pd_clear` fanout, transition, and recovery reports |
| Packet format changes accidentally | Readout/top | Guarded | No packet field or width changed; run packet tests |
| Precision changes | Measurement | Low expected risk | Optimizations are after snapshot; characterize against baseline |
