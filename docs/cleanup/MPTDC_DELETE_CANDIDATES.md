# MPTDC Delete Candidates

These are candidates only. Do not run `git rm` for any item here without
explicit review and approval.

## Candidate Classes

| Candidate | Why it is a candidate | Required dependency checks before delete | Current status |
| --- | --- | --- | --- |
| `MPTDC/artifacts/overnight/vip/` | Large tracked overnight seed artifacts and transcript tails | Search docs/scripts for seed/log references; preserve summary evidence if needed | Candidate only |
| Old subsets of `MPTDC/results/` | Generated characterization/campaign output already covered by summaries in some cases | Check report scripts, thesis/report data, calibration docs, and result manifests | Candidate only |
| Old subsets of `MPTDC/lab_snapshots/` | Historical Genus/Innovus reports, netlists, SDF, and logs | Check `docs/timing_closure/`, current O10-O13 reviews, and snapshot README | Candidate only |
| Top-level old `results/` runs | Generated local/server run outputs, many already ignored for new output | Check all timing docs and recent O10/O11/O12/O13 references | Candidate only |
| Duplicate result mirrors between `results/` and `MPTDC/lab_snapshots/` | Some run artifacts appear mirrored in both places | Confirm byte/path equivalence and decide one canonical evidence location | Candidate only |
| `results/local_verilator/*/ccache/` tracked entries | Tool cache artifacts, not source | Confirm no scripts expect committed cache paths | Candidate only |
| `Rapport_5PSM_KS/dist/` | Built report output, not source | Confirm report deliverable policy; preserve release copy if needed | Candidate only, out of default MPTDC scope |
| `local_file_inventory.txt` | Prior root inventory likely superseded by Phase 0 generated inventory | Compare with new generated listings; check docs for references | Candidate only |
| `tatus --short package-lock.json` | Accidental/mistyped root artifact by filename | Confirm not referenced anywhere and not intentionally preserved | Candidate only |
| Root `package-lock.json` | Root npm lock with no root package context observed in Phase 0 | Confirm whether root JS project exists; do not confuse with `tools/mptdc_gui/frontend/package-lock.json` | Candidate only |

## Local-Ignored Cleanup Candidates

These are not tracked cleanup candidates, but they are large local workspace
bulk:

| Path | Evidence | Cleanup mode |
| --- | --- | --- |
| `.venv/` | Ignored by top-level `.gitignore` | Local removal only, not git cleanup |
| `MPTDC/build/` | Ignored by `MPTDC/.gitignore`, no tracked files found | Local removal only, not git cleanup |
| `OpenROAD/` | Ignored by `.git/info/exclude`, nested checkout with large `.git` pack | Local/tooling decision only |
| Top-level ignored `results/` additions | Top-level `.gitignore` ignores new `results/`, but historical files are already tracked | Git cleanup only after review of tracked history |

## Required Checks Before Any `git rm`

- `rg -n "<candidate path or run id>" docs MPTDC README.md`
- `rg -n "<candidate path or run id>" MPTDC/scripts MPTDC/syn MPTDC/pnr`
- For result trees: inspect manifests and summaries before removing raw logs.
- For O10-O13 evidence: confirm the latest timing/debug docs do not still need
  the raw report.
- For thesis/report artifacts: confirm the report can rebuild or the deliverable
  is stored outside git.

## Explicit Phase 0 Block

Phase 0 creates this candidate list only. It does not approve any deletion.
