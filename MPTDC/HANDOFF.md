# MPTDC Handoff

Author: Karim Sabra
Status: active owner handoff for the SPADMIC product-axis MPTDC

This is the starting point for a new RTL, verification, synthesis, or physical
implementation owner. The active product boundary is `mptdc_axis_core`; the
current source tree contains the slow/fast RO-code interface needed for physical
implementation. Any Genus handoff created before that RTL change is reference
evidence only until a fresh canonical Genus run is produced.

## How to read this repository

Use this file as the entrypoint, then follow the source-of-truth documents in
the ownership map below. Legacy MPTDC planning notes, numbered handoff drafts,
and O-stage narrative documents were removed from the active documentation set
because they described retired `mptdc_top_asic`, standalone CSR/VIP, or
pre-closure synthesis assumptions. Historical sequence names remain only where
required for backend report correlation or generated evidence.

The implementation intentionally contains nonstandard mixed-clock structures:
oscillator phases are measurement clocks, the Vernier q1 relation is an intended
measurement crossing, async frontend storage is not accidental latch inference,
and the context bridge is a static held-bus protocol. Treat these as design
contracts that need explicit verification/timing evidence, not as cleanup noise.

## Current Physical-Closure Checkpoint

The accepted recovery checkpoint is the V13 canonical Tie1 minimum-area replay
`20260831_175532_mptdc_tie1_minarea_clearance_v13_replay`. Its evidence commit
is `b61dfd1a6c476aa41cab43735a28199fa164bc05`, and its candidate checkpoint
SHA-256 is
`35fec60377b4fc7c08b83bf550ef457f7bdb3aa69580d8a749feb7a66fa4a7bf`.

Fresh Innovus geometry DRC, shorts, regular connectivity, and route completeness
pass. Fifteen raw special-PG dangling endpoints remain, the prior PVS base DRC
contains 136 antenna-only results, and the prior attributable PVS LVS result is
an explicit mismatch. No antenna repair was attempted, and this state is not
timing-qualified or signoff-eligible.

Continue with the read-only PG endpoint analysis command in
`MPTDC/docs/pnr/MPTDC_TIE1_DRC_LVS_CLOSURE_HANDOFF.md`. That document is the
active source for evidence lineage, accepted geometry, prior failed experiments,
PVS triage, stop conditions, and the next server command.

## Reference TC-Only Provisional Baseline

| Item | Value |
| --- | --- |
| RTL product top | `MPTDC/rtl/top/mptdc_axis_core.sv` |
| Integration core | `MPTDC/rtl/top/mptdc_core.sv` |
| Active handoff branch | `SPADMIC_test` |
| Frequency mode | `R750_delta5` |
| Phase distribution | `BUJIHDX4 -> BUJIHDX12` per slow/fast tap |
| RO code interface | TOP-owned slow/fast CSR values captured into local idle-only shadow registers |
| PD fabric | intentional `8 x 8` Vernier matrix |
| Source commit | `010285dc` |
| Genus handoff run | `20260623_1207_mptdc_axis_core_typical_closed_ba2b2932` |
| Innovus baseline run | `20260625_mptdc_tc_fullclosure_010285dc_postfiller1` |
| Extracted TC setup | WNS `0.000 ns`, TNS `0.000 ns`, violating paths `0` |
| Extracted TC hold | WNS `+0.048 ns`, TNS `0.000 ns`, violating paths `0` |
| Route status | `PROVISIONAL`: independent `verify_drc` has `2` non-short `MET1 Mar` violations |
| Backend readiness | `TC_ONLY_PROVISIONAL_BASELINE` |
| Signoff boundary | TC-only; not MMMC, foundry DRC/LVS, row DRC/LVS, IR/EM, or tapeout signoff |

The June 25 baseline is reference evidence for the closure recipe. The active
next rerun replaces the old RO abstract with the layout-backed `RO_tune6`
master from OA cell `SPADMIC/RO_tune6/layout`. The expected exported LEF is:

```text
/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
```

The RTL intentionally keeps the RO instance name `u_ro_tune4` so existing
`u_core/u_osc_*/u_ro_tune4/S[n]` SDC/report paths stay stable. The macro master
and LEF/Liberty collateral are `RO_tune6`. The OA-to-LEF export contract,
required pins, target file name, and pre-run audit commands are documented in
`MPTDC/analog_handoff/RO_TUNE6_LAYOUT_EXPORT.md`.

The server result path is external generated evidence and is not a repository
source path:

```text
/sim/ksabra/SPADMIC_work/innovus/20260625_mptdc_tc_fullclosure_010285dc_postfiller1
```

The detailed baseline and inspection commands are in
`MPTDC/docs/pnr/MPTDC_TC_CLOSURE_20260625_BASELINE.md`. Do not call this final
signoff until the route DRC markers, foundry DRC/LVS, row qualification, antenna
evidence, IR/EM, and non-TC-only timing scope are closed or explicitly waived by
the proper owner.

## Canonical commands

Run from the repository root:

```bash
bash MPTDC/ci/run_smoke.sh
bash MPTDC/ci/run_full_regression.sh
bash MPTDC/scripts/sim/run_mptdc_xcelium_smoke.sh
bash MPTDC/scripts/sim/run_mptdc_characterization.sh
bash MPTDC/scripts/calibration/run_mptdc_calibration.sh
bash MPTDC/syn/scripts/check_genus_axis_core_typical_closed_profile.sh
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_feasibility.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh --mode discover_only
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh --mode validate_only
```

Without an explicit argument, the Genus wrapper writes
`work/genus/MPTDC_TC_Closure_Genus`, and the Innovus wrapper writes
`work/innovus/MPTDC_TC_Closure_Innovus`. The Genus command accepts only an
optional run ID. The closure policy is stored in
`MPTDC/syn/scripts/profiles/genus_axis_core_typical_closed.sh` so an inherited
shell environment cannot silently change the handoff baseline.

If Verilator is unavailable on the Cadence server, record that as a tool
availability gap and use the Xcelium smoke as the Cadence portability gate. Do
not mark the Verilator-based smoke or full regression as passed unless the
`verilator` executable is actually available and the wrapper exits cleanly.

## Ownership map

| Area | Source of truth | Handoff contract |
| --- | --- | --- |
| RTL | `rtl/README.md`, `docs/architecture/MPTDC_ARCHITECTURE.md` | Preserve packet format, CDC contracts, oscillator/PD intent, and product top. |
| Verification | `tb/README.md`, `docs/verification/MPTDC_VERIFICATION.md` | Product-axis smoke is maintained; old standalone VIP is archival. |
| Synthesis | `syn/README.md`, `docs/synthesis/MPTDC_SYNTHESIS_FLOW.md` | Use the canonical profile and stable SDC/filelist aliases. |
| Timing status | `docs/timing_closure/MPTDC_TIMING_CLOSURE_STATUS.md` | Typical closure is clean; physical/MMMC signoff remains open. |
| PnR | `docs/pnr/MPTDC_PNR_FLOW.md` | Separate typical helpers from real digital signoff; preserve oscillator/phase-clock intent. |
| Signoff limits | `docs/signoff_notes/MPTDC_SIGNOFF_LIMITATIONS.md` | Do not convert feasibility labels into final signoff claims. |

## Change rules

1. Keep generated results under `work/`; commit only concise evidence summaries.
2. Do not rename or repurpose packet fields without a coordinated RTL,
   verification, calibration, and software change.
3. Treat async frontend storage, the static held-bus bridge, oscillator clocks,
   and the PD Vernier relation as explicit design intent, not lint cleanup.
4. Give experiments hypothesis-based names. Do not make sequence labels such as
   `O13` or `REPAIR8` the public command.
5. A synthesis profile change requires before/after WNS, TNS, violation count,
   DRV count, path-family classification, and exact exception-count evidence.
6. Merge the handoff cleanup only after the local smoke, profile check, and a
   server-side Genus rerun have passed from a clean tracked tree.
7. Separate reference evidence from active checkout state. A later docs/script
   cleanup commit may sit above the timing-reference commit, but it needs its
   own clean wrapper rerun before becoming the accepted PnR handoff head.
8. A PnR signoff run needs confirmed physical-cell names, MMMC views, real
   `clk_sys` CTS, extracted timing, antenna/DRC/LVS evidence, and separate
   status keys. Do not convert the typical feasibility result into signoff by
   changing labels.

## Naming and cleanup policy

Public entrypoints use purpose-based names: product boundary, timing view,
closure profile, or physical intent. Internal backend names that still contain
`O13`, `ABS`, or `REPAIR` are compatibility labels for reproducing the proven
Genus run; do not rename them in a documentation-only cleanup because that would
change the validated command path.

RTL signal and parameter names should describe ownership and meaning, but broad
renaming is a functional-risk change in this block. Rename RTL only with
matching simulation, synthesis, timing, and calibration evidence. For this
cleanup, use documentation to explain existing names and reserve RTL/script
renames for a separate validated refactor.
