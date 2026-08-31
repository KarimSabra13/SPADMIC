# RTL Verification Results Template

## Provenance

| Field | Value |
| --- | --- |
| Date/time | |
| Host | |
| Branch | |
| Full commit | |
| Worktree status | |
| Simulator/version | |
| Command | |
| Result directory | |

## Generated map

| Check | Result | Evidence |
| --- | --- | --- |
| `TOP/ci/check_csr_map_generated.sh` | | |
| Register count | | |
| ABI version | | |

## Directed results

| Bench | Result | Log/report |
| --- | --- | --- |
| `tb_spadmic_matrix_top_csr_unit` | | |
| `tb_spadmic_i2c_control_plane_unit` | | |
| `tb_spadmic_i2c_matrix_top_16b_unit` | | |
| active directed regression total | | |

List every failed or skipped bench explicitly:

| Bench | Classification | Follow-up |
| --- | --- | --- |
| | | |

## VIP results

| Test | Result | Assertions | Scoreboard | Evidence |
| --- | --- | --- | --- | --- |
| `smoke_tdc` | | | | |
| `smoke_position` | | | | |
| `smoke_position_raw` | | | | |
| `smoke_switching` | | | | |
| `spad_reset_modes` | | | | |
| `i2c_end_to_end` | | | | |
| `ctrl_reject` | | | | |
| `coverage_walk` | | | | |

## Functional coverage

| Covergroup/area | Covered | Total | Percent | Mandatory holes |
| --- | ---: | ---: | ---: | --- |
| modes and R/Y/B masks | | | | |
| CSR access causes | | | | |
| position configuration | | | | |
| faults and W1C | | | | |
| event/reset lifecycle | | | | |
| packet source/kind/event ID | | | | |

Attach the Xcelium coverage database/report path. Code coverage is not a target
for this phase.

## Gate classification

| Gate | Status | Rationale/evidence |
| --- | --- | --- |
| ABI/map consistency | | |
| directed RTL | | |
| end-to-end VIP | | |
| assertions | | |
| functional coverage | | |
| server exact-commit attribution | | |

Overall RTL control-plane status: `PASS`, `FAIL`, or `INCOMPLETE`.

Do not convert this report into a synthesis, timing, physical, DRC, LVS, or
tapeout verdict.
