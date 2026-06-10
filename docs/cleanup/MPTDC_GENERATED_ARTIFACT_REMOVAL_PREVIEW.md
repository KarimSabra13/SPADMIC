# MPTDC Generated Artifact Removal Preview

Author: Karim Sabra

This preview was created before removing generated run artifacts from git.
Evidence summaries already exist in:

- `docs/timing_history/MPTDC_TIMING_CLOSURE_HISTORY.md`
- `docs/timing_history/MPTDC_EVIDENCE_INDEX.md`
- `docs/timing_history/MPTDC_RESULT_RETENTION_POLICY.md`
- `docs/timing_history/archive/`

## Removal Mode

Generated run trees will be removed from the git index with:

```bash
git rm -r --cached results MPTDC/lab_snapshots MPTDC/results MPTDC/artifacts MPTDC/report_artifacts
```

This is cached-only removal for generated trees.  Local files may remain in the
working copy, but they are ignored by the updated `.gitignore` rules and future
generated output must use `work/`.

Root accidental clutter will be handled separately:

- `local_file_inventory.txt` moves to
  `docs/cleanup/generated/legacy_local_file_inventory.txt`.
- `tatus --short package-lock.json` is removed as an accidental diff artifact.
- Root `package-lock.json` is removed because no root `package.json` exists.
- `tools/mptdc_gui/frontend/package-lock.json` is kept.

## Paths To Remove From Git

| Path | Tracked files | Tracked blob bytes | Mode |
| --- | ---: | ---: | --- |
| `results/` | 6163 | 1547760911 | cached-only |
| `MPTDC/lab_snapshots/` | 3557 | 973859457 | cached-only |
| `MPTDC/results/` | 4497 | 254010921 | cached-only |
| `MPTDC/artifacts/` + `MPTDC/report_artifacts/` | 12314 | 117470660 | cached-only |
| Total generated set | 26531 | 2893101949 | cached-only |

Total tracked generated blob size: about 2759.08 MiB / 2.69 GiB.

## Biggest Removed Paths

| Bytes | Path |
| ---: | --- |
| 25466096 | `results/innovus/20260604_o10_2_pnr_repair/logs/innovus_o10_2.logv` |
| 20789137 | `results/innovus/20260604_o10_2_pnr_repair/logs/innovus_o10_2.log` |
| 20535018 | `results/innovus/20260604_o10_2_pnr_repair/reports/route_summary.rpt` |
| 20535018 | `MPTDC/lab_snapshots/innovus_o10_2_pnr_repair_20260604_o10_2_pnr_repair/reports/route_summary.rpt` |
| 12592552 | `results/local_verilator/20260601_o2_raw_tag_smoke/ccache/9/9/11049sbcohgend2lj7u50l76ou0vm9eR` |
| 11853838 | `results/local_verilator/20260601_o2_raw_tag_smoke/ccache/f/8/a7a85ein8u173j7f4ufn5tm386g923gR` |
| 10871529 | `results/local_verilator/20260601_o2_raw_tag_smoke/ccache/3/c/78grc9oon429fpi5j87spabfat3f74aR` |
| 10708143 | `results/local_verilator/20260601_o2_raw_tag_smoke/ccache/a/8/17rlvl4qmbd5eemt9sfri0mtluq1cu4R` |
| 9695364 | `results/genus_osc_pd/20260602_o4_muxless_tags_r600_o4_r600_closure/mptdc_top_asic.postsyn.sdf` |
| 9695364 | `MPTDC/lab_snapshots/genus_osc_pd_20260602_o4_muxless_tags_r600_o4_r600_closure/mptdc_top_asic.postsyn.sdf` |

## Reference Scan Result

Generated scan:

```text
docs/cleanup/generated/post_cleanup_reference_scan.txt
```

Line count: 53723.

Interpretation:

- The scan intentionally includes archived history docs and Phase 0 generated
  inventory files, so old result paths and historical labels remain present for
  traceability.
- The active README and active flow docs under `MPTDC/docs/{architecture,
  verification,synthesis,pnr,calibration,timing_closure,signoff_notes}` have no
  matches for the generated result paths or old timing labels scanned here.

## Keep Exceptions

Do not remove:

- `MPTDC/syn/macros/`
- `MPTDC/analog_handoff/`
- `MPTDC/tech/xlibd/`
- `MPTDC/pnr/config/xlibd_spadmic_typical_cell_values.tcl`
- RTL, testbenches, VIP, filelists, scripts, and constraints
- `docs/timing_history/`
- `docs/tech/`
- `tools/mptdc_gui/frontend/package-lock.json`

Protected macro/analog/XLIBD tracked input count before removal: 20.

## Safety Decision

The removal is safe to proceed because compact evidence summaries exist, active
flow docs use stable names, protected macro/analog/XLIBD inputs are outside the
removal paths, and generated outputs are now ignored under the standard `work/`
policy.
