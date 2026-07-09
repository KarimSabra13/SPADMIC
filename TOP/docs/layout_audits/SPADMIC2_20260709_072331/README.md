# SPADMIC2 Layout Audit CSV Handoff

Source OA:
`SPADMIC/SPADMIC2/layout`

This handoff contains read-only extracted CSV data for top-level floorplan and Innovus planning.

Use:
- instance bboxes for macro/blockage planning;
- top-coordinate pins for pin guides and routing corridors;
- top terms for pad-ring understanding;
- top shapes for route/place blockages;
- net names for connectivity classification.

Important:
The MPTDC abstract is currently missing in OA, so MPTDC pin extraction is incomplete.
For current top planning, treat each MPTDC instance as a physical blockage using its bbox plus halo.
Do not route inside the MPTDC areas.
Replace these blockages later with final MPTDC LEF/DEF/abstract when available.

This data is extracted read-only. No OA layout modification was performed.
