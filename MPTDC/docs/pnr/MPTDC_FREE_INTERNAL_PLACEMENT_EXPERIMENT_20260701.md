# MPTDC Free Internal Placement Experiment - 2026-07-01

## Intent

This experiment is for a fast fresh Innovus candidate after the route-checkpoint
repair probes showed that hand-routing individual residual nets was not closing
the block cleanly enough.  The goal is to give `placeDesign`, pre-CTS
optimization, CTS, routing, and post-route optimization much more freedom:

- keep IO pins fixed by the normal IO placement flow,
- keep the real `RO_tune6` abstract and Liberty in use,
- do not fix the two RO macros,
- do not create RO placement halos,
- do not preplace or fix the RO phase buffers,
- do not preplace or fix PD tile leaves,
- do not force the fast-tag column placement,
- keep PD physical audit in relaxed/soft-region mode.

This is a closure-candidate experiment, not a tapeout signoff waiver.  Any final
GDS candidate still needs clean independent route DRC/connectivity, foundry
DRC/LVS, antenna, row-infrastructure DRC/LVS, and the remaining MMMC signoff
gates.

## Implemented Knobs

`MPTDC_PNR_FREE_INTERNAL_PLACEMENT=1` is now understood by the digital signoff
Tcl and wrapper.

When enabled, it:

- forces RO macros to be placed as movable/unfixed even if another default would
  fix them,
- defaults `MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE=1`, leaving phase-buffer cells
  for normal placement,
- records `PHASE_BUFFER_PLACEMENT_APPLIED=SKIPPED_FREE_INTERNAL_PLACEMENT`,
- skips the pre-place RO/phase-buffer clearance audit because the phase buffers
  intentionally have no pre-placement origin,
- defaults `MPTDC_RO_PHASE_POSTPLACE_AUDIT_FATAL=0`, so the post-place
  RO/phase geometry report is still generated but does not block CTS/timing in
  this exploratory run,
- defaults `MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=0` in the wrapper unless the
  caller explicitly overrides it.

The real Innovus placement legality gate still runs and can still fail the run.

`MPTDC_PNR_FREE_ALL_INTERNAL_PLACEMENT=1` is the more aggressive mode for a
fresh automatic placement candidate.  It implies
`MPTDC_PNR_FREE_INTERNAL_PLACEMENT=1` and additionally skips PD-grid group/region
creation and fast-tag column placement.  The PD physical matrix audit is still
written after placement, but it is report-only
(`PD_PHYSICAL_AUDIT_MODE=free_internal`) so it cannot block CTS/route/timing
while the optimizer is allowed to move internal logic freely.  This mode keeps
pins fixed through the normal IO flow; it does not make the run GDS-ready by
itself.

`MPTDC_ALLOW_DIRTY_ROUTE_TIMING_CONTINUE=1` is also available as an explicit
timing-candidate escape hatch.  It keeps `ROUTE_STATUS=FAIL` and saves the
failure DEF/checkpoint/marker reports, but continues to extraction/STA so timing
optimization evidence can be generated from a dirty route candidate.  It must
not be used to label a route-clean or GDS-ready result.

## Validation

Local validation performed before server handoff:

```sh
bash -n MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh

MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY=1 \
MPTDC_PNR_FREE_INTERNAL_PLACEMENT=1 \
MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1 \
O1_RO_LEF_PATH=debug_artifacts/innovus/20260701_mptdc_tc_ro6_pnrlef_v2_base_route_150609/lef/RO_tune6_pnr_pin_access_20260701_mptdc_tc_ro6_cleanlef_localbridge_base_route_143726_v2.lef \
O1_RO_LIBERTY_PATH=MPTDC/syn/macros/RO_tune6_real_layout_shell.lib \
tclsh MPTDC/pnr/scripts/innovus_mptdc_digital_signoff.tcl
```

Result: `MPTDC_DIGITAL_SIGNOFF_SOURCE_CHECK=PASS`.

## Server Run Contract

Use `server_run_mptdc_tc_ro6_cleanlef.sh --free-all-internal` for the corrected
RO_tune6 VDD/VSS-only path with full internal placement freedom.  The wrapper
now records the free-placement controls explicitly and overrides the older
RO-focused fixed-placement defaults.  The run should show:

- `MPTDC_PNR_FREE_ALL_INTERNAL_PLACEMENT=1`
- `MPTDC_PNR_FREE_INTERNAL_PLACEMENT=1`
- `MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE=1`
- `MPTDC_PNR_FIX_RO_MACROS=0`
- `MPTDC_PNR_CREATE_RO_HALOS=0`
- `MPTDC_PNR_PD_TILE_CONSTRAINT_MODE=none`
- `MPTDC_PNR_PD_TILE_PREPLACE_LEAVES=0`
- `MPTDC_PNR_PD_TILE_FIX_LEAVES=0`
- `MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=0`
- `MPTDC_PD_PHYSICAL_AUDIT_MODE=free_internal`
- `MPTDC_ALLOW_DIRTY_ROUTE_TIMING_CONTINUE=1` only when timing evidence is more
  urgent than route cleanliness for this exploratory candidate.

For the fastest strict final-candidate attempt after the 2026-07-01 free-all
golden-LEF route failure, use `--aggressive-postroute` with `--stage
final_candidate`, `--enable-route-recovery`, and the generated PnR-only
`RO_tune6` pin-access LEF.  This keeps the route DRC/connectivity gates strict
while raising post-route setup optimization to the Tcl hard cap and expanding
the bounded fast-tag ECO upsize/search budget.
