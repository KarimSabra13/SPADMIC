# O7 Expected Genus Interpretation

O7 asks one narrow question: does the standard-cell PD/localtag fabric look
plausible when Genus uses typical cells and guarded screenshot-based oscillator
uncertainty?

It does not prove oscillator signoff, PVT closure, or tapeout readiness.

## If WNS Improves Strongly

Interpretation:

- Previous Genus results were likely dominated by slow/worst standard-cell view
  pessimism and/or overly large generic oscillator uncertainty.
- The architecture may still be viable under realistic typical conditions.
- The next required data is real analog CSV/Ocean/corner extraction for RO_tune4.

Do not claim final closure.  Do not move to Innovus unless the O7 result is
near-clean and the remaining paths are physically meaningful.

## If WNS Is Still Worse Than About -1 ns

Interpretation:

- Typical standard-cell timing and reduced uncertainty are not enough.
- The standard-cell PD/localtag fabric remains structurally too slow.
- The design likely needs an architecture change, lower frequency, custom event
  capture, or a different local timestamp methodology.

Do not spend Innovus time on this path.

## If WNS Is Better Than About -300 ps

Interpretation:

- Run a higher-effort typical closure pass before backend work.
- Review whether the dominant paths are local, realistic, and not artifacts of
  the Liberty shell or incomplete macro loading.
- Request real oscillator data before any signoff conclusion.

## Required Report Fields

Review:

- `OSC_FAST_REAL`
- `OSC_SLOW_REAL`
- `CLK_SYS_REAL`
- design-rule violations, especially transition violations
- dominant path family
- `RO_tune4` instance count
- `RO_tune4/S[0:7]` clock attachment count
- residue of `mptdc_osc_stub`, old fast counter, or old slow counter

Compare O7 against O5/O4 using the timing classes and family summaries, not only
the global WNS line.
