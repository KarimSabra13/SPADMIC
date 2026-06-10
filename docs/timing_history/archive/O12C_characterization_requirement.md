# O12C Characterization Requirement

REPORT_STATUS=REVIEW_REQUIRED

O12/O12C does not change the packet format, but it changes analog-to-digital phase delay.

Unchanged:

- Packet layout.
- `raw_lfsr_tag` semantics.
- `nslow` / `nfast` widths.
- `R750_delta5` frequency mode.
- PD RTL behavior.

Changed:

- A phase buffer delay is inserted between `RO_tune4/S[n]` and the digital phase fabric.
- Per-tap route delay and buffer output transition may change.
- Tap-to-tap mismatch may change.

If the added delay is common and stable, calibration should absorb it.  If mismatch is large, linearity may degrade.

Final O12C adoption requires Xcelium characterization after the buffer topology and placement are chosen.  Do not run characterization before choosing the topology.
