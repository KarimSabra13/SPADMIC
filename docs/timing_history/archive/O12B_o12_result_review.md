# O12B O12 Result Review

Status: `O12B_PHASE_BUFFER_BALANCE_AND_CLEAN_PNR`

This is a feasibility/debug review, not signoff.

## Input Evidence

Latest server-side O12 evidence provided for this review:

- O12 Genus implemented phase isolation on branch `SPADMIC_localtag`.
- O12 PNR feasibility source run: `20260608_o12_phase_buffer_pnr_abs1`.
- O12 report-only load run: `20260608_o12_phase_buffer_analysis_abs2`.
- Report-only wrapper status: `REPORT_COMPLETE=YES`.
- Innovus O12 analysis exit code: `0`.
- O12 PNR feasibility wrapper had Innovus exit code `139`.

The full `20260608_o12_phase_buffer_pnr_abs1` and
`20260608_o12_phase_buffer_analysis_abs2` result trees are lab-server inputs for
O12B.  They are not assumed to be present in the local checkout.

## Raw RO Load Review

O12 changed the physical connection from:

```text
RO_tune4/S[n] -> slow_phase[n] / fast_phase[n] -> digital fabric
```

to:

```text
RO_tune4/S[n] -> *_phase_raw[n] -> BUHDX4 -> *_phase[n] -> digital fabric
```

Known O12 result:

- Raw RO rows: `16`.
- Matched raw RO rows: `16`.
- Missing raw RO rows: `0`.
- Raw rows bounded by no max-cap violation: `16`.
- Raw labels: `16 OK_STRICT`.
- Each raw RO pin fanout is `1`.
- Each raw RO pin drives only the corresponding phase-buffer input pin.

Analog load budget:

- Strict D-input load: `58.72 fF`.
- CN/clock-like estimate: `75.59 fF`.
- Existing RO shell bound: `50.00 fF`.

Because the raw RO nets no longer appear in `drv_max_cap.rpt`, and the RO shell
still uses the 50 fF `S` max-cap, the raw load is bounded as:

- raw RO load `<= 50.00 fF`;
- strict ratio `<= 0.85x`;
- CN ratio `<= 0.66x`.

`RAW_RO_LOAD_FIXED=YES` for the current O12 feasibility evidence.

## Remaining Unknowns

The large digital fanout moved to BUHDX4 outputs, which is expected.  The open
question is whether the buffer output load, delay, transition, placement, route
length, and tap-to-tap mismatch are acceptable and calibratable.

The first O12B run, `20260608_o12b_phase_buffer_balance_abs1`, did not answer
that question.  It crashed during detailed report generation after unsupported
Innovus DB net-attribute probes, before the required O12B CSVs were written.
Treat that run as debug evidence only:

- `RAW_RO_LOAD_FIXED` remains supported by the prior O12 analysis evidence.
- `BUFFER_OUTPUT_LOAD_QUANTIFIED=NO` for abs1.
- `INNOVUS_RUN_CLEAN=NO` for abs1.
- `TIMING_DECISION_QUALITY=NO` for abs1.

O12B must quantify:

- `BUFFER_OUTPUT_LOAD_QUANTIFIED`;
- `INNOVUS_RUN_CLEAN`;
- `TIMING_DECISION_QUALITY`;
- buffer topology and placement symmetry.

## Required O12B Labels

O12B should report:

- `RAW_RO_LOAD_FIXED=YES` only when all 16 raw RO pins match, fanout is 1, and no
  raw RO max-cap violation remains.
- `BUFFER_OUTPUT_LOAD_QUANTIFIED=YES` only when all 16 BUHDX4 output nets have
  numeric total capacitance.
- `INNOVUS_RUN_CLEAN=YES` only when the wrapper exits cleanly and required
  reports pass validation.
- `TIMING_DECISION_QUALITY=YES` only when topology, load, placement, timing, and
  DRV data are all complete enough for a backend decision.

## Conclusion

The direct analog RO load blocker is fixed by the O12 feasibility result.  O12B
must not revisit RTL load reduction unless the buffer-output balance, timing,
placement, power, or analog review rejects the phase-isolation approach.
