# MPTDC Free-All Route Salvage And Final Candidate Plan - 2026-07-01

## Objective

Produce the cleanest possible TC-only MPTDC digital handoff candidate quickly,
without masking route DRC/connectivity failures as signoff-clean.

The active direction is:

- keep the conservative RO PG hookup/blockPin probe strategy,
- keep full internal placement freedom,
- use the PnR-only `RO_tune6` pin-access LEF for Innovus routing,
- enable guarded route recovery,
- run `final_candidate` so the flow attempts route, post-route optimization,
  filler, extraction/STA, and physical-verification package stages when route
  gates allow it,
- keep route DRC/connectivity gates strict.

## Latest Free-All Golden-LEF Run

Run:

```text
/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_cleanlef_freeall_route_timing_pgfix_191721
```

Wrapper head:

```text
d6720030e246644aa71ce523fc3bb8990578da92
```

Timeline from `manifests/stage_trace.csv`:

```text
2026-07-01 19:17:48 CEST source/import start
2026-07-01 19:22:29 CEST placement done
2026-07-01 19:29:02 CEST CTS done, route start
2026-07-01 19:51:22 CEST route fail
```

Important status:

```text
free_all_internal_placement=1
free_internal_placement=1
skip_phase_buffer_preplace=1
fix_ro_macros=0
place_fast_tags_by_column=0
O1_RO_LEF_PATH=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
ROUTE_STATUS=FAIL
GEOMETRY_DRC_VIOLATIONS=26
SHORTS=21
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=1
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
POSTROUTE_OPT_SETUP_FINAL_WNS_NS=-0.063
POSTROUTE_OPT_SETUP_FINAL_TNS_NS=-1.686
```

Interpretation:

- The earlier large VDD std-cell terminal failure is gone.
- Remaining PG special connectivity is VDD/VSS dangling-wire evidence, not
  non-RO PG terminal failures.
- The route blocker is geometry: 26 DRC / 21 shorts.
- Marker evidence is concentrated at the two `RO_tune6` macro access/blockage
  regions, especially phase raw/code/control nets near the fast and slow RO
  instances.
- This is consistent with using the golden macro LEF as the routing abstract.

## Checkpoint Salvage Attempt

Run:

```text
/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_freeall_failed_route_salvage_205951
```

Wrapper head:

```text
500a5f97b2b3a367321a2665cd42f6a65f772564
```

Source checkpoint:

```text
/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_cleanlef_freeall_route_timing_pgfix_191721/checkpoints/04_route_failed.enc.dat
```

Timeline from terminal transcript:

```text
2026-07-01 21:00:08 CEST checkpoint repair wrapper start
2026-07-01 21:00:32 CEST load design begins
2026-07-01 21:04:30 CEST repaired_route.def write begins
2026-07-01 21:04:33 CEST save design completes
```

Commands attempted:

- delete regular DRC wires on aggressive RO-local phase/code/control net list,
- delete two local special VDD MET1 shapes at the fast/slow RO blockage shorts,
- selected-net reroute,
- `ecoRoute -fix_drc`,
- `ecoRoute -target`,
- `ecoRoute -fix_drc`,
- strict geometry/regular-connectivity assertion.

Final result:

```text
FINAL_DRC=26
FINAL_SHORTS=21
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
FINAL_ROUTE_GATE_PASS=0
CHECKPOINT_REPAIR_STATUS=REVIEW_REQUIRED
```

Conclusion:

The failed-route checkpoint is not a fast in-place salvage candidate. The
signature did not improve, so the next fastest credible signoff attempt should
be a fresh `final_candidate` run using the PnR-only RO pin-access LEF rather
than the golden LEF.

## Wrapper Fixes For Next Run

Head `500a5f97b2b3a367321a2665cd42f6a65f772564` fixed the malformed default
route-recovery command list. The old manifest rendered:

```text
route_repair_commands: {ecoRoute -target {ecoRoute -fix_drc}}
```

The intended route-recovery list is:

```text
{ecoRoute -target} {ecoRoute -fix_drc}
```

The next head also adds:

```text
--aggressive-postroute
```

This enables the Tcl hard cap of ten setup optimization passes, disables
post-route plateau early-stop, keeps two hold passes, and expands the bounded
fast-tag ECO upsize/search budget.

## Next Candidate Policy

Use a fresh run, not checkpoint salvage:

- `--stage final_candidate`
- `--free-all-internal`
- `--pnr-lef <RO_tune6_pnr_pin_access_..._v2.lef>`
- `--enable-route-recovery`
- `--aggressive-postroute`

This is the best fast candidate for a manager handoff. If it still fails on
RO-local macro-access DRC, the honest fallback is a documented TC-only dirty
candidate plus explicit waiver/manually-fix-later notes for the RO access DRCs;
it should not be labeled route-signoff clean.
