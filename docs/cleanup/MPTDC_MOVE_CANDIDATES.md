# MPTDC Move Candidates

These moves are candidates only. No `git mv` is approved in Phase 0.

## Candidate Moves

| Current location | Possible target | Reason | Required checks |
| --- | --- | --- | --- |
| `local_file_inventory.txt` | `docs/cleanup/generated/legacy_local_file_inventory.txt` or delete after review | Root generated inventory clutter | Compare against Phase 0 generated inventories and search references |
| Current O10-O13 timing docs in `docs/timing_closure/` | Keep in place, or later group under `docs/timing_closure/o10_o13/` | Timing docs are numerous but currently reference each other by location | Reference search and link update plan |
| Old timing docs in `docs/timing_closure/` | `docs/timing_closure/archive/` | Reduce active-doc noise | Identify active vs historical docs first |
| `MPTDC/lab_snapshots/` selected old runs | External artifact store or `docs/evidence/` summaries | Keep curated evidence, reduce raw run bulk | Preserve manifests, summaries, and path breadcrumbs |
| Top-level `results/` selected current runs | Canonical `MPTDC/lab_snapshots/` or external artifact store | Eliminate duplicate result locations | Check all current O10/O11/O12/O13 references first |
| `MPTDC/report_artifacts/final_protocol_v27_boundaryfix/` | Report/evidence archive | Generated report evidence should have a clear owner | Confirm thesis/report references |
| `MPTDC/artifacts/overnight/vip/` summaries | Curated VIP evidence directory | Preserve high-level evidence without every seed artifact | Build or identify summary files first |
| Root `package-lock.json` if valid | Relevant JS project directory | Root location looks accidental unless root package metadata exists | Check npm project ownership |

## Move Rules

- Moves that affect active scripts, constraints, RTL, or filelists must start
  with additive compatibility wrappers or docs.
- Result/evidence moves must leave a README or manifest mapping old run IDs to
  new locations.
- Large generated output should not be moved inside git just to make paths neat;
  prefer external artifact storage once evidence is curated.
- Do not move `MPTDC/rtl/` subtrees in this cleanup. The existing split already
  matches the active architecture well enough, including `cdc/`.

## Phase 0 Status

All moves are pending review. This file records candidates only.
