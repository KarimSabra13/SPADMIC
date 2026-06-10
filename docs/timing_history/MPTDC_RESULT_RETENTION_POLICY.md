# MPTDC Result Retention Policy

Author: Karim Sabra

## Git Keeps

- RTL, testbenches, VIP, filelists, scripts, constraints, macro abstracts, and
  XLIBD references.
- Concise architecture, flow, timing, and calibration documentation.
- Curated evidence summaries and indexes.
- Small manifests only when they are needed to explain a decision.

## Git Does Not Keep

- Genus run directories.
- Innovus run directories.
- Xcelium campaign outputs.
- Verilator build outputs.
- Waveforms.
- Logs and console transcripts.
- Huge CSV datasets.
- Routed databases and checkpoints.
- Tarball snapshots.
- Generated plots unless explicitly curated.
- Duplicate result mirrors.

## Standard Output Root

New generated output goes under `work/`:

```text
work/genus/
work/innovus/
work/xcelium/
work/verilator/
work/characterization/
work/calibration/
work/plots/
work/logs/
work/evidence/
work/scratch/
```

`work/README.md` is the only tracked file under `work/`.

## Cleanup Rule

Before raw generated artifacts are removed from git:

1. A compact evidence summary must exist.
2. A reference scan must be captured under `docs/cleanup/generated/`.
3. A removal preview must list paths, file counts, sizes, removal mode, and keep
   exceptions.
4. Protected source inputs must be checked explicitly.

Use `git rm -r --cached` for paths that may remain locally but must stop being
tracked.  Use future `work/` runs for regenerated evidence.
