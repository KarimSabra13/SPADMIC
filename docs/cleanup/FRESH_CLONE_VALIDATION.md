# Fresh Clone Validation

Author: Karim Sabra

Date: 2026-06-10

This note records the cleanup-branch fresh-clone validation for
`SPADMIC_FINAL`.  The clone source was the local repository at
`/home/karim/SPADMIC`; no network fetch was required.

## Fresh Clone Commands

```bash
cd /tmp
rm -rf SPADMIC_cleancheck
git clone /home/karim/SPADMIC SPADMIC_cleancheck
cd SPADMIC_cleancheck
git checkout SPADMIC_FINAL
git status --short
bash -n MPTDC/syn/scripts/server_run_genus_mptdc_typical.sh
bash -n MPTDC/pnr/scripts/server_run_innovus_mptdc_feasibility.sh
bash -n MPTDC/scripts/sim/run_mptdc_verilator_smoke.sh
bash -n MPTDC/scripts/sim/run_mptdc_characterization.sh
```

## Result

| Check | Result |
| --- | --- |
| Local clone from `/home/karim/SPADMIC` | PASS |
| `git checkout SPADMIC_FINAL` | PASS |
| `git status --short` in clone | PASS, clean output |
| Stable Genus wrapper `bash -n` | PASS |
| Stable Innovus wrapper `bash -n` | PASS |
| Stable Verilator wrapper `bash -n` | PASS |
| Stable characterization wrapper `bash -n` | PASS |

## Additional Local Validation

| Check | Result |
| --- | --- |
| `git diff --check` | PASS |
| `find MPTDC -name "*.sh" -print0 \| xargs -0 -n1 bash -n` | PASS |
| `python3 -m py_compile $(find MPTDC tools -name "*.py")` | PASS |
| RTL filelist format-aware existence check | PASS |
| Verilator filelist format-aware existence check | PASS |
| Active README/flow docs old-reference scan | PASS, no matches |

## Filelist Checker Note

The literal filelist snippets from the cleanup request were also run.  They
reported false `MISSING` lines because the protected filelists contain existing
Verilog-style `//` comments, `rtl/...` paths relative to `MPTDC`, and a
Verilator `+define+...` directive.  The active flow expects that format, so the
filelists were not rewritten.  Format-aware checks that strip `//` comments,
skip tool directives, and resolve paths relative to their intended root passed.

## Scope

This is a repository hygiene validation only.  It is not a Verilator simulation
run, Genus run, Innovus run, MMMC signoff, DRC/LVS signoff, or tapeout signoff.
