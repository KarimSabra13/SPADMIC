# Final Typical Genus JIHD Tap0 Micro V3 DRV Clean

Run:

`final_typical_genus_jihd_tap0_micro_v3_drvclean_20260610_175527`

Branch:

`SPADMIC_FINAL`

HEAD:

`1d14e3b470c239c1d836c16548b1d7e984933b57`

## Scope

This is the accepted typical-only Genus package for O13 Innovus feasibility.
It is not MMMC signoff and not final tapeout signoff.

## Result

- `FINAL_DECISION=GENUS_TYPICAL_CLOSED`
- `GENUS_TYPICAL_STATUS=GENUS_TYPICAL_CLOSED`
- `INNOVUS_READY=READY_FOR_O13_INNOVUS_FEASIBILITY`
- Genus exit code: `0`
- Snapshot exit code: `0`
- Setup WNS: `1.0 ps`
- Setup TNS: `-0.0 ps`
- Setup violating paths: `0`
- Real timed violating paths: `0`
- Max transition/capacitance/fanout violations: `0 / 0 / 0`
- Report helpers: `PASS`
- Summary/raw agreement: `PASS`
- Fast-tag mapping: `PASS`
- Fast-tag top violating paths: `0`

## O13 Contract Checks

- `RO_tune4` instance count: `2`
- `mptdc_osc_stub` residue count: `0`
- `BUHDX4` instance count: `8`
- `BUHDX12` instance count: `8`
- Raw RO clocks found: `16`
- Buffer phase clocks found/expected: `16 / 16`
- Buffer phase clocks in async group: `YES`
- `clk_sys` async to buffer phase clocks: `YES`
- PD intentional Vernier paths matched: `64`
- PD intentional Vernier sources matched: `8`
- PD intentional Vernier exception applied: `YES`
- PD intentional Vernier overmatch/undermatch: `NO / NO`
- SDC command failure count: `0`
- Unknown review-required count: `0`

## Repair Interpretation

The v2 run proved that strict exact tap0 bit 5/6 pressure closed setup but
created artificial transition-review noise by using a 0.30 ns exact transition
target. The v3 run kept the real timing pressure and restored the exact
transition target to 0.50 ns:

- `FAST_TAG_EXACT_DATA_PATHS=1`
- `FAST_TAG_EXACT_TAPS=0`
- `FAST_TAG_EXACT_BITS=5,6`
- `FAST_TAG_EXACT_MAX_FANOUT=2`
- `FAST_TAG_EXACT_MAX_TRANSITION_NS=0.50`
- `FAST_TAG_EXACT_MAX_DELAY_NS=1.04`
- `FAST_TAG_EXACT_SOURCE_Q_PINS=2`
- `FAST_TAG_EXACT_SOURCE_C_PINS=2`
- `FAST_TAG_EXACT_ENDPOINT_D_PINS=16`
- `FAST_TAG_EXACT_Q_SET_MAX_FANOUT=OK`
- `FAST_TAG_EXACT_Q_SET_MAX_TRANSITION=OK`
- `FAST_TAG_EXACT_D_SET_MAX_TRANSITION=OK`
- `FAST_TAG_EXACT_Q_TO_D_SET_MAX_DELAY_RESULT=OK`

No false path, multicycle relaxation, or broad design-wide DRV pressure was
used to close `FAST_TAG_TO_PD_TS`.

## Handoff Packaging

Run this on the lab checkout after the Genus run completes:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

RUN_ID=final_typical_genus_jihd_tap0_micro_v3_drvclean_20260610_175527

bash MPTDC/syn/scripts/package_genus_typical_handoff.sh "$RUN_ID" --tar

HANDOFF_DIR="work/handoff/genus_typical/$RUN_ID"
sed -n '1,220p' "$HANDOFF_DIR/00_decision/DECISION_RECORD.md"
cat "$HANDOFF_DIR/00_decision/PACKAGE_CHECKS.tsv"
find "$HANDOFF_DIR" -maxdepth 2 -type f | sort
```

The package script is intentionally non-destructive. It copies curated evidence
from `work/genus/$RUN_ID/` into:

`work/handoff/genus_typical/$RUN_ID/`

It refuses to package unless the run is `GENUS_TYPICAL_CLOSED`, typical-only,
not-MMMC, not-final-signoff, clean for real setup timing, clean for DRV, clean
for O13 PD Vernier matching, and clean for report-helper/summary parsing.

## Next Gate

Move to O13 Innovus feasibility using the packaged netlist, SDC, and Genus
Innovus export:

- `work/handoff/genus_typical/$RUN_ID/05_outputs/mptdc_top_asic.postsyn.v`
- `work/handoff/genus_typical/$RUN_ID/05_outputs/mptdc_top_asic.postsyn.sdc`
- `work/handoff/genus_typical/$RUN_ID/06_innovus_import/post_synth/mptdc_top_asic.invs_setup.tcl`

Keep the next stage labeled as Innovus feasibility until post-layout timing,
route, extraction, DRC/LVS, power, and analog phase confirmation are reviewed.
