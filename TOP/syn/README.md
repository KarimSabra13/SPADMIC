# SPADMIC Matrix TOP Synthesis Infrastructure

Status: server-facing Genus OOC infrastructure. No local Genus run is claimed.

## Scope

This directory contains early typical-only Genus scripts for matrix-top blocks.
The scripts are intended to catch elaboration, synthesis, timing-intent, and
basic QoR/design-rule issues before top-level physical planning. They are not
MMMC closure and are not final signoff.

## Server Command

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test
source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
bash TOP/syn/scripts/run_genus_all_matrix_ooc.sh matrix_top_genus_<run_id>
```

Generated results go under:

```text
/sim/ksabra/SPADMIC_work/genus/<RUN_ID>/<BLOCK>/
```

Do not commit generated Genus databases, logs, reports, or netlists.

## Blocks

The server wrapper currently runs OOC feasibility for:

- `spadmic_position_snapshot_packetizer`
- `spadmic_output_fifo`
- `spadmic_event_bundle_tx`
- `spadmic_matrix_or_tree`
- `spadmic_matrix_reset_ctrl`
- `spadmic_matrix_cfg_ctrl`
- `spadmic_ddr16_tx_pairer`
- `spadmic_event_coordinator`
- `spadmic_matrix_top_csr`
- `spadmic_i2c_csr_bridge`
- `spadmic_i2c_slave`
- `spadmic_top_matrix_v1`

MPTDC internal synthesis remains governed by the existing MPTDC handoff flow.
These TOP scripts do not modify or replace that product boundary.

## Constraints

`constraints/matrix_top_ooc_common.sdc` defines:

- `clk_sys` = 6.25 ns;
- `clk_cfg_40m` = 25 ns;
- `clk_ref_40m` = 25 ns;
- provisional asynchronous clock grouping between `clk_sys`, `clk_cfg_40m`,
  and `clk_ref_40m`;
- placeholder I/O delays;
- basic max transition/fanout limits.

The SDC deliberately does not blanket false-path all matrix inputs. START-tree
delay/slew/skew must be reported and reviewed in the server results.

## Limitations

- Typical-only feasibility.
- No local Cadence execution in Codex.
- No CDC/RDC signoff.
- No MMMC, extracted timing, DRC/LVS, PEX, or tapeout-readiness claim.
- Matrix macro and DDR macro timing remain placeholders until handoff.
