# MPTDC Rename Candidates

These are naming candidates only. Active Oxx names are traceability anchors and
must remain valid until a later phase proves all references have moved.

## Rename Strategy

- Add stable names first as wrappers, aliases, or README mappings.
- Keep Oxx names until current docs, server commands, and result paths no longer
  depend on them.
- Preserve the original Oxx run ID in comments, docs, or wrapper output.
- Validate both old and new names during the transition.

## Candidate Stable Names

| Current name | Candidate stable name | Initial action | Traceability note |
| --- | --- | --- | --- |
| `server_run_genus_o13_abs5_pd_q1_exception_exact.sh` | `server_run_genus_pd_vernier_q1_exception.sh` | Add alias only | Keep O13 abs5 in wrapper comments/output |
| `server_run_genus_o13_phase_distribution.sh` | `server_run_genus_phase_distribution.sh` | Add alias only | Preserve O13 path for current server handoff |
| `server_run_genus_o12_phase_isolation.sh` | `server_run_genus_phase_isolation.sh` | Add alias only | Preserve O12 trace |
| `mptdc_osc_typical_r750_delta5_o13_abs5.sdc` | `mptdc_osc_typical_r750_delta5_pd_vernier_q1_exception.sdc` | Add documented alias/copy only if needed | Do not break exact O13 abs5 wrapper |
| `mptdc_osc_typical_r750_delta5_o13_phase_distribution.sdc` | `mptdc_osc_typical_r750_delta5_phase_distribution.sdc` | Add alias/copy only if needed | Keep O13-specific overlay available |
| `server_run_innovus_o10_2_pnr_repair.sh` | `server_run_innovus_typical_pnr_repair.sh` | Add alias only | Preserve O10.2 result path references |
| `server_run_innovus_o11_ro_load_analysis.sh` | `server_run_innovus_ro_load_analysis.sh` | Add alias only | Preserve O11 RO-load evidence trace |
| `server_run_innovus_o12_phase_buffer_analysis.sh` | `server_run_innovus_phase_buffer_analysis.sh` | Add alias only | Preserve O12 trace |
| `server_run_innovus_o12b_phase_buffer_balance.sh` | `server_run_innovus_phase_buffer_balance.sh` | Add alias only | Preserve O12B trace |
| `server_run_innovus_o12c_phase_buffer_topology.sh` | `server_run_innovus_phase_buffer_topology.sh` | Add alias only | Preserve O12C trace |
| `server_run_innovus_o13_phase_distribution.sh` | `server_run_innovus_phase_distribution.sh` | Add alias only | Preserve O13 trace |
| `mptdc_osc_typical_r750_delta5_o12_phase_buffers*.sdc` | `mptdc_osc_typical_r750_delta5_phase_buffers*.sdc` | Add alias/copy only after wrapper review | Keep O12 reference in history |
| `mptdc_osc_typical_r750_delta5_o13_phase_distribution_innovus.sdc` | `mptdc_osc_typical_r750_delta5_phase_distribution_innovus.sdc` | Add alias/copy only after wrapper review | Keep O13 Innovus reference |

## Names Not To Change In Early Cleanup

- `MPTDC/rtl/filelist.f`
- `MPTDC/sim/verilator/filelist_verilator.f`
- `MPTDC/tb/vip/filelist.f`
- Public RTL module filenames under `MPTDC/rtl/`
- Current macro abstract names under `MPTDC/syn/macros/`
- XLIBD reference filenames under `MPTDC/tech/xlibd/`

## Required Checks

- `rg -n "<old name>" .`
- `bash -n` for shell wrappers where applicable.
- Tcl parse/review for wrapper-target Tcl where applicable.
- Confirm server handoff commands still work with old Oxx names.
- Only after aliases are validated should direct references move to stable names.
