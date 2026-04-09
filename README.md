# SPADMIC — SPAD Matrix Digital IC

> **Author:** Karim Sabra  
> **Affiliation:** IP2I Lyon / Universite Claude Bernard Lyon 1  
> **License:** Copyright © 2025 Karim Sabra. All rights reserved.

## Repository overview

This repository contains the active digital implementation of the SPADMIC readout IC and the supporting MPTDC core it integrates.

The current active first-silicon digital baseline is:

- one physical `chip_tx_*` output bus
- three preserved `mptdc_top_asic` TDC axes
- one shared TDC serializer fed by per-axis acquisition-record exports
- one async-qualified position path with explicit drop/reject reporting
- one top-level sequencer that commits requested control only after the old datapath drains
- one I2C control plane bridged into the shared CSR fabric

## Repository guide

| Directory | Role | Main entrypoint |
|-----------|------|-----------------|
| [`MPTDC/`](MPTDC/) | Vernier multi-phase TDC core, verification, calibration, synthesis collateral | [`MPTDC/README.md`](MPTDC/README.md) |
| [`TOP/`](TOP/) | SPADMIC chip-level integration around three MPTDC axes | [`TOP/README.md`](TOP/README.md) |
| [`I2C/`](I2C/) | I2C slave and CSR bridge used by the active top-level | [`I2C/README.md`](I2C/README.md) |
| [`Rapport_5PSM_KS/`](Rapport_5PSM_KS/) | Report project kept in the repo but excluded from the current cleanup/documentation pass | — |

## Documentation map

| Area | Quick reference | Deep reference |
|------|-----------------|----------------|
| Full chip / integration | [`TOP/README.md`](TOP/README.md) | [`TOP/docs/01_ACTIVE_ARCHITECTURE.md`](TOP/docs/01_ACTIVE_ARCHITECTURE.md), [`TOP/docs/02_CSR_MAP.md`](TOP/docs/02_CSR_MAP.md) |
| TDC core | [`MPTDC/README.md`](MPTDC/README.md) | [`MPTDC/docs/01_ARCHITECTURE.md`](MPTDC/docs/01_ARCHITECTURE.md), [`MPTDC/docs/10_SHARED_READOUT_EXPORT.md`](MPTDC/docs/10_SHARED_READOUT_EXPORT.md) |
| I2C control plane | [`I2C/README.md`](I2C/README.md) | [`I2C/docs/01_INTEGRATION_GUIDE.md`](I2C/docs/01_INTEGRATION_GUIDE.md) |

## Active system dataflow

1. **Control path:** `i2c_scl_i/i2c_sda_i` -> `spadmic_i2c_slave` -> `spadmic_i2c_csr_bridge` -> `spadmic_csr_decoder` -> global, per-axis TDC, or position CSR blocks.
2. **TDC path:** one `spadmic_tdc_axis_wrapper` per axis -> local `mptdc_top_asic` -> exported acquisition records -> `spadmic_tdc_shared_readout` -> shared `mptdc_narrow16_tx_v2`.
3. **Position path:** asynchronous `x/y/z_lines_i` -> synchronizers -> cluster scan and qualification in `spadmic_position_block` -> fixed 12-word position packet.
4. **Final egress:** `spadmic_shared_tx_mux` selects either the packetized TDC stream or the packetized position stream onto the one physical `chip_tx_*` interface.

## Current top-level control model

- `spadmic_global_csr` stores the **requested** control image visible to software.
- `spadmic_top_sequencer` owns the **active** control image that drives the live datapath.
- Source and mode changes are accepted only when the datapath is idle and are committed only after the previous path drains.
- Fault counters and sticky bits report rejected mode writes and position-side capture issues.

## Quick start

### Lint the active full-chip top

```bash
cd /home/karim/SPADMIC
MPTDC_FILES=$(sed -e 's,//.*$,,' -e '/^[[:space:]]*$/d' MPTDC/rtl/filelist.f | sed 's,^,MPTDC/,')
TOP_FILES=$(sed -e 's,//.*$,,' -e '/^[[:space:]]*$/d' TOP/filelist.f | sed 's,^,TOP/,')
verilator --lint-only --timing +define+MPTDC_USE_OSC_MODEL \
  $MPTDC_FILES $TOP_FILES \
  --top-module spadmic_top_v1
```

### Run the maintained MPTDC smoke regression

```bash
cd /home/karim/SPADMIC/MPTDC
bash ci/run_smoke.sh
```

### Run a representative TOP-level unit bench

```bash
cd /home/karim/SPADMIC
verilator --binary --timing -Wall \
  -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN -Wno-DECLFILENAME -Wno-WIDTHEXPAND \
  -Wno-WIDTHTRUNC -Wno-UNUSEDPARAM -Wno-PINMISSING -Wno-UNUSEDGENVAR \
  -Wno-CASEINCOMPLETE -Wno-LATCH -Wno-REALCVT -Wno-INITIALDLY -Wno-COMBDLY \
  -Wno-PINCONNECTEMPTY -Wno-SYNCASYNCNET -Wno-UNOPTFLAT \
  MPTDC/rtl/pkg/mptdc_pkg.sv \
  TOP/rtl/spadmic_pkg.sv \
  MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv \
  TOP/rtl/spadmic_tdc_shared_readout.sv \
  TOP/tb/tb_spadmic_tdc_shared_readout_unit.sv \
  --top-module tb_spadmic_tdc_shared_readout_unit
```
