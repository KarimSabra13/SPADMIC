# SPADMIC Matrix TOP Server Snapshots

This directory is for small, tracked summaries from server-side Xcelium, Genus,
and Innovus runs. It is intentionally not a raw artifact store.

Use:

```bash
TOP/ci/collect_matrix_top_server_snapshot.sh <xcelium|genus|innovus> <RUN_ID>
```

Allowed content:

- `SUMMARY.md`
- run manifests
- pass/fail summaries
- failure tails
- selected lightweight report excerpts
- generated matrix floorplan summaries

Do not commit raw `xcelium.d`, Genus/Innovus databases, full raw logs, waveform
files, netlists, SPEF/SDF, or tarballs.
