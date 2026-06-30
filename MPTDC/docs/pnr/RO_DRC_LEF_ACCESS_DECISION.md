# RO DRC / LEF Access Decision

Date: 2026-06-30

Scope: TC-only Innovus PnR closure for `mptdc_axis_core`.

## Current Decision

Do not patch `RO_tune6.lef` yet.

The latest no-filler diagnostic route reached the route gate and localized the
remaining route DRCs at the two `RO_tune6` macro edges.  That strongly points to
macro signal escape or LEF abstract access, but the first LEF comparison used an
incorrect coordinate transform:

```text
lef_box = marker_local_box + LEF_ORIGIN
```

For the current `RO_tune6` abstract this is wrong.  The LEF declares:

```text
ORIGIN 68.695 88.51 ;
SIZE 168.935 BY 70.49 ;
```

The macro pins use negative LEF coordinates.  A marker box reported relative to
the placed macro bounding box must be transformed back to LEF coordinates as:

```text
R0:   lef = local - ORIGIN
MX:   lef_x = local_x - origin_x
      lef_y = SIZE_Y - local_y - origin_y
MY:   lef_x = SIZE_X - local_x - origin_x
      lef_y = local_y - origin_y
R180: lef_x = SIZE_X - local_x - origin_x
      lef_y = SIZE_Y - local_y - origin_y
```

The previous `local+ORIGIN` output produced marker LEF boxes around positive
`y ~= 88..90`, hundreds of microns from the real `S[*]` pin rectangles.  That is
not physically credible and must not be used to trim OBS.

## Required Corrected Audit

Run the checked-in audit script on the server:

```bash
RUN=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_mesh_bypass_broken_ro_probe_route_v1
LOC=$RUN/local_route_drc_probe
RO_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef

python3 MPTDC/pnr/scripts/audit_ro_marker_vs_lef.py \
  --markers "$LOC/ro_marker_to_inst_audit.tsv" \
  --instances "$LOC/ro_instance_boxes.tsv" \
  --lef "$RO_LEF" \
  --macro RO_tune6 \
  --out-tsv "$LOC/ro_marker_vs_lef_oriented.tsv" \
  --summary "$LOC/ro_marker_vs_lef_oriented_summary.txt"
```

Required outputs:

```text
$LOC/ro_marker_vs_lef_oriented.tsv
$LOC/ro_marker_vs_lef_oriented_summary.txt
```

## Interpretation

Use the `classification` column in `ro_marker_vs_lef_oriented.tsv`:

```text
OBS_OVERLAP_NO_PIN
```

The abstract OBS blocks the marker region without a legal same-layer pin.  A
generated PnR-only LEF with narrowly trimmed/split OBS windows is appropriate.

```text
PIN_AND_OBS_OVERLAP
```

A pin-access window is likely covered by OBS.  Generate a PnR-only LEF and trim
only the implicated OBS rectangles around the legal pin windows.

```text
NO_OBS_OR_PIN_OVERLAP
```

Do not patch OBS blindly.  The next patch should be bounded local route guidance
or blockage around the two RO escape bands, not a global METTP strategy.

```text
PIN_OVERLAP_NO_OBS
```

The marker reaches legal pin geometry.  Investigate via/access spacing or local
escape routing, not OBS trimming.

## Constraints

- Do not modify the golden LEF under `/group/...`.
- If a LEF patch is required, generate a PnR-only copy under `/sim/...`.
- Preserve macro name `RO_tune6`, macro size, pin names, pin directions, and
  `VDD`/`vdd!`/`VSS` power semantics.
- Do not change RTL for this issue.
- Do not add broad false paths or multicycle exceptions on
  `FAST_TAG_TO_PD_TS_PHYSICAL`.
- Do not solve this by globally promoting more routing to `METTP`; the stable
  route DRC plateau already has `METTP=0`.
