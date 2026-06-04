# O10.2 RO Phase Load Analysis Plan

## Current Observation

O10.1 `drv_max_cap.rpt` showed RO phase output max-cap violations against the RO_tune4 shell limit of 0.050. Example: fast S[4] actual was around 0.718.

## Possible Causes

- The RO_tune4 Liberty shell max-cap value may be a placeholder.
- The routed phase loads may be too high for analog oscillator behavior.
- The current floorplan/route may have created excessive phase wire load.
- Units or extraction assumptions may need analog review.

## O10.2 Reports

- `reports/phase_net_loads.csv`
- `reports/phase_net_balance_summary.md`
- `reports/drv_max_cap.rpt`

Each phase row must report:

- family and tap
- net name
- fanout
- total cap, wire cap, pin cap
- transition
- route length
- sink counts by PD/tag/RO/other
- sink names when available

## Policy

- Do not add buffers to RO phase outputs without analog/timing review.
- Do not add dummy load.
- Do not silently relax the RO shell max-cap.
- If analog confirms the shell max-cap is a placeholder, create a separate documented provisional shell later and still report actual cap.

## Blocking Analog Question

What is the maximum allowed load per RO_tune4 S output for the R750 delta5 mode?
