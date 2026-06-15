# MPTDC Keep List

Everything in this document is protected by default. A future cleanup phase can
still change these files, but only with an explicit technical reason, dependency
searches, and validation.

## RTL And Filelists

| Path | Why protected | Required check before modification |
| --- | --- | --- |
| `MPTDC/rtl/filelist.f` | Primary RTL closure | Prove every simulator/synthesis consumer still compiles |
| `MPTDC/rtl/pkg/mptdc_pkg.sv` | Shared package/types/geometry | Compile all RTL consumers |
| `MPTDC/rtl/top/mptdc_axis_core.sv` | Product ASIC axis boundary | Re-run top-level compile/synthesis checks |
| `MPTDC/rtl/top/mptdc_core.sv` | Core datapath/control integration | Re-run RTL compile and relevant unit/integration tests |
| `MPTDC/rtl/pd/mptdc_pd_cell.sv` | PD-cell behavior and recent simulator-portability work | Verilator and Xcelium compile/elaboration checks |
| `MPTDC/rtl/pd/` | Fast/slow epoch and PD capture logic | RTL compile, unit tests, current Genus flow |
| `MPTDC/rtl/cdc/` | Active CDC synchronization primitives | CDC/filelist checks and simulator compile |
| `MPTDC/rtl/osc/` | Oscillator wrapper, stub/model, phase buffers | Genus/Innovus wrapper dependency checks |
| `MPTDC/rtl/async/` | Async frontend/capture/context modules | Unit/integration tests and compile |
| `MPTDC/rtl/ctrl/` | Measurement/drain/control/watchdog logic | Unit/integration tests and compile |
| `MPTDC/rtl/readout/` | Product packet output path | Unit/integration tests and compile |
| `MPTDC/sim/verilator/filelist_verilator.f` | Local Verilator closure | Verilator compile with current top/test targets |
| `MPTDC/tb/vip/filelist.f` | VIP compile closure | VIP compile/smoke target |

## Tests And Verification Assets

| Path | Why protected | Required check before modification |
| --- | --- | --- |
| `MPTDC/tb/common/` | Shared TB packages and monitors | Compile all TB families |
| `MPTDC/tb/unit/` | RTL unit coverage | Run or compile representative unit tests |
| `MPTDC/tb/int/` | Integration coverage and characterization TBs | Compile affected tests |
| `MPTDC/tb/vip/` | VIP interfaces, package, and README | VIP compile/smoke target |
| `MPTDC/tb/tests/mptdc_vip_tb.sv` | VIP top testbench | VIP compile/smoke target |
| `MPTDC/sim/xcelium/` | Server-side Xcelium wrappers | Shell syntax plus server-side elaboration plan |
| `MPTDC/scripts/` | Analysis/calibration/characterization tooling | Script reference search and representative report generation |

## Active Wrappers And Procedures

| Path | Why protected | Required check before modification |
| --- | --- | --- |
| `MPTDC/syn/scripts/procedures.tcl` | Shared Genus helper procedures and recent O13 report fix | `tclsh` parse where possible plus Genus wrapper dry review |
| `MPTDC/syn/scripts/genus.tcl` | Main Genus entrypoint | Genus wrapper validation |
| `MPTDC/syn/scripts/server_run_genus_o12_phase_isolation.sh` | Active O12 flow context | Shell syntax and reference search |
| `MPTDC/syn/scripts/server_run_genus_o13_abs3_clock_cdc_repair.sh` | O13 clock/CDC repair history | Shell syntax and reference search |
| `MPTDC/syn/scripts/server_run_genus_o13_abs4_pd_vernier_classification.sh` | O13 PD Vernier classification history | Shell syntax and reference search |
| `MPTDC/syn/scripts/server_run_genus_o13_abs5_pd_q1_exception_exact.sh` | Current exact q1 exception flow | Shell syntax, SDC reference check, report-helper validation |
| `MPTDC/syn/scripts/server_run_genus_o13_phase_distribution.sh` | Current phase-distribution flow | Shell syntax and SDC reference check |
| `MPTDC/pnr/scripts/server_run_innovus_o10_2_pnr_repair.sh` | Current useful routed checkpoint flow | Shell syntax and Innovus script reference check |
| `MPTDC/pnr/scripts/server_run_innovus_o11_ro_load_analysis.sh` | Current RO-load evidence flow | Shell syntax and report script reference check |
| `MPTDC/pnr/scripts/server_run_innovus_o12_phase_buffer_analysis.sh` | Current O12 phase-buffer analysis | Shell syntax and Tcl reference check |
| `MPTDC/pnr/scripts/server_run_innovus_o12b_phase_buffer_balance.sh` | O12B balance flow | Shell syntax and Tcl reference check |
| `MPTDC/pnr/scripts/server_run_innovus_o12c_phase_buffer_topology.sh` | O12C topology flow | Shell syntax and Tcl reference check |
| `MPTDC/pnr/scripts/server_run_innovus_o13_phase_distribution.sh` | Current O13 phase-distribution PnR flow | Shell syntax and Tcl/SDC reference check |

## Constraints, Macro Inputs, And XLIBD References

| Path | Why protected | Required check before modification |
| --- | --- | --- |
| `MPTDC/syn/inputs/mptdc.defines` | Macro binding and frequency mode hooks | Genus wrapper reference check |
| `MPTDC/syn/inputs/mptdc.mmmc` | Existing MMMC source | Genus timing setup review |
| `MPTDC/syn/inputs/mptdc.sdc` | Base SDC | Genus timing setup review |
| `MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5*.sdc` | Active O9-O13 typical overlays | O13/O12 wrapper reference check |
| `MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib` | Real RO abstract shell and max-cap evidence | Genus/Innovus/analog load review |
| `MPTDC/syn/macros/RO_tune4_shell_load58ff.lib` | RO load scenario evidence | Reference search before changes |
| `MPTDC/syn/macros/RO_tune4_shell_load76ff.lib` | RO load scenario evidence | Reference search before changes |
| `MPTDC/syn/macros/*.lef` | PnR macro abstracts | Innovus wrapper validation |
| `MPTDC/pnr/inputs/mptdc_innovus.mmmc` | Innovus timing setup | Innovus init validation |
| `MPTDC/pnr/inputs/mptdc_pnr_config.tcl` | Innovus config | Innovus init validation |
| `MPTDC/pnr/constraints/mptdc_osc_typical_r750_delta5*.sdc` | O10-O13 Innovus overlays | Innovus wrapper reference check |
| `MPTDC/analog_handoff/` | Analog/RO contracts, pin lists, and mode evidence | Reference search and analog-budget review |
| `MPTDC/tech/xlibd/` | XLIBD cell value references used by timing docs | Reference search and timing-doc review |
| `docs/tech/xlibd_cell_values_spadmic_*.md` | Human-readable XLIBD decisions/usage | Timing-doc reference review |

## Curated Evidence And Docs

| Path | Why protected | Required check before modification |
| --- | --- | --- |
| `docs/timing_closure/O10_2_ro_phase_load_analysis.md` | RO load evidence and blocker framing | Check O10/O11 docs and result references |
| `docs/timing_closure/O11_ro_*` | RO-load policy and analog budget evidence | Check current O11/O13 references |
| `docs/timing_closure/O12*` | Phase-buffer evidence and plans | Check O12/O13 references |
| `docs/timing_closure/O13*` | Current O13 repair and timing model context | Check current O13 scripts/results references |
| `MPTDC/lab_snapshots/README.md` | Snapshot index policy | Preserve or update before snapshot moves |
| Current O10.2/O11/O12/O13 result summaries | Recent evidence for active timing/debug work | Explicit review before delete/move |

## Out Of Phase 0 Scope

`TOP/`, `I2C/`, `position/`, `arb/`, `Rapport_5PSM_KS/`, `tools/`, and
`OpenROAD/` are not MPTDC Phase 0 cleanup targets unless a later review expands
scope.
