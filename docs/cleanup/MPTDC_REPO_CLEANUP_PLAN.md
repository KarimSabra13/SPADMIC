# MPTDC Repository Cleanup Plan

This plan preserves the six-phase cleanup model. Phase 0 is complete when the
inventory docs and generated listings exist. No destructive cleanup is approved
by Phase 0.

## Guardrails

- Do not delete, move, or rename RTL in Phase 0.
- Do not rewrite filelists, wrappers, SDC/MMMC files, macro abstracts, or XLIBD
  references in Phase 0.
- Do not use `git rm` until delete candidates are reviewed and approved.
- Stable names must be additive first: add aliases or docs before renaming active
  Oxx wrappers or constraints.
- Treat results and lab snapshots as evidence until dependency checks prove they
  are not referenced by docs, scripts, reports, or current debug tasks.
- A fresh-clone validation must pass before any cleanup branch is considered
  ready to merge.

## Phase 0: Inventory Only

Actions:

- Create `SPADMIC_FINAL` from updated `SPADMIC_localtag`.
- Capture raw file/status/size listings in `docs/cleanup/generated/`.
- Create inventory, keep, delete-candidate, move-candidate, rename-candidate,
  plan, and risk-register docs.

Blocked in Phase 0:

- `git rm`
- RTL relocation
- filelist rewrites
- constraint rewrites
- wrapper rewrites
- result/lab snapshot pruning

## Phase 1: Review And Freeze Protected Scope

Actions:

- Review `MPTDC_KEEP_LIST.md` and mark any missing protected inputs.
- Review current O13/O12/O11/O10 wrapper dependencies.
- Search for references to every proposed delete/move/rename candidate.
- Define the minimum local validation commands for later phases.

Exit criteria:

- Approved keep list.
- Approved candidate list or explicit removals from candidate list.
- No destructive command run yet.

## Phase 2: Additive Stable Names And Documentation

Actions:

- Add stable wrapper names only as aliases or thin delegating wrappers.
- Add stable constraint/doc names only with compatibility references.
- Keep Oxx names alive until all scripts/docs are updated and validated.

Exit criteria:

- Old names still work.
- New stable names are documented.
- Genus/Innovus wrapper shell syntax checks pass.

## Phase 3: Generated Artifact Policy

Actions:

- Decide which generated outputs remain in git as curated evidence.
- Decide which outputs move to external artifact storage, release attachments, or
  local-only ignored directories.
- Update ignore policy only after preserving required curated evidence.

Exit criteria:

- Approved artifact retention table.
- No current report, thesis source, or timing-closure doc loses required inputs.

## Phase 4: Reviewed Moves And Deletes

Actions:

- Apply only approved `git mv` and `git rm` changes.
- Keep compatibility links or README breadcrumbs where path history matters.
- Update docs that intentionally reference moved evidence.

Exit criteria:

- `git status --short` contains only expected cleanup changes.
- Reference searches show no stale active paths.

## Phase 5: Fresh Clone Validation And Final Review

Actions:

- Validate from a fresh checkout, not only the dirty developer workspace.
- Run selected local checks for RTL/testbench closure.
- Run selected wrapper syntax checks.
- If server tools are required, use exact server checkout/run commands from the
  current workflow documentation.

Exit criteria:

- Fresh clone can find protected RTL, filelists, wrappers, constraints, macro
  abstracts, XLIBD references, and curated evidence.
- Cleanup branch has a reviewable diff and no unapproved destructive changes.

## Required Validation By Phase

Phase 0 validation is documentation-only:

- `git status --short`
- `git diff --check`

Later phases must add validation proportional to the files touched. Any change
to RTL, filelists, wrappers, SDC/MMMC, macro abstracts, XLIBD data, or current
results references requires targeted compile/script/reference validation before
merge.
