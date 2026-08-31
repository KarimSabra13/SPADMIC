# Matrix-Top VIP Guide

## Scope

`TOP/tb/vip/` is the maintained lightweight SystemVerilog class-based
environment for `spadmic_top_matrix_v1`. It is intentionally not UVM.

## Structure

| Directory | Role |
| --- | --- |
| `agent/` | generators and direct/I2C/event/position drivers |
| `env/` | environment configuration, runtime state, test factory |
| `interfaces/` | DUT-facing virtual interfaces |
| `monitor/` | physical TX and reset observation |
| `scoreboard/` | packet/event/config reference checking |
| `coverage/` | ABI, fault, reset, packet functional covergroups |
| `sva/` | active-top assertions and bind |
| `tests/` | named scenario classes |

## Control entry

The environment supports:

1. real I2C transactions at the fixed `0x42`, 100 kHz ABI
2. direct internal CSR requests for fast focused scenarios

Both use the same 16-bit address/32-bit data transaction model. The generator
uses read/modify/write helpers so reserved or unrelated fields are preserved.
Its runtime mirror tracks global mode, R/Y/B masks, position mode/gap/minimum,
snapshot timing, and reset width.

## Event generation

Normal TDC and BOTH scenarios drive coordinated R/Y/B activity and axis mask
`111`. Calibration scenarios program a nonzero partial mask first. Position
scenarios drive R/Y/B projection data for cluster or raw packet expectations.

Normal acquisition is event-coordinator driven; VIP tests do not synthesize a
manual conversion-start path that the product interface does not expose.

## TX observation

The DUT emits low/high 16-bit word pairs qualified by `ddr_pair_valid_o`.
`spadmic_narrow_tx_if` forwards those words in logical order, including the
protocol-aware handling needed for an odd padded bundle. `spadmic_tx_monitor`
then parses packet boundaries, source, kind, payload, and shared event ID.

The scoreboard checks:

- expected versus observed R/Y/B TDC packets
- cluster/raw position payload and length
- one shared event ID across correlated sources
- mode/config state reflected in generated expectations
- coordinated matrix-reset pulse count and width
- no unexpected packet after rejected control operations

## Assertions and coverage

`spadmic_ctrl_sva` is bound to the active matrix top. Covergroups sample
functional behavior only; code coverage is intentionally outside this phase.

Mandatory functional areas are mode/mask policy, access causes, fault W1C,
position mode/filter values, event/reset lifecycle, packet grammar, source/event
correlation, and overflow/drop behavior.

## Running

Local compile/lint:

```bash
bash TOP/scripts/sim/run_vip_test.sh smoke_tdc --sim verilator
```

Xcelium runtime:

```bash
bash TOP/ci/run_vip_smoke.sh
bash TOP/ci/run_vip_coverage.sh
```

See `04_TEST_CATALOG.md` for maintained scenarios and
`05_XCELIUM_RUNBOOK.md` for evidence requirements.
