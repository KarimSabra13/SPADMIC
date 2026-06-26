# RO_tune6 Layout Export Contract

Author: Karim Sabra

This file defines the exact analog-to-digital handoff needed before rerunning
the canonical Genus and Innovus TC closure flow with the new `RO_tune6` layout.

## Source OA Cell

Use the server-side OA layout supplied by the analog owner:

```text
library: SPADMIC
cell:    RO_tune6
view:    layout
path:    /group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL/RO_tune6/layout/layout.oa
```

For later PVS/LVS, the matching schematic should remain in the same logical
library/cell namespace as `SPADMIC/RO_tune6/schematic`. The Genus/Innovus flow
does not read the schematic; it is required for downstream physical
verification.

## Required LEF Output

Export the physical abstract LEF from the OA layout and put it here:

```text
/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
```

The file name and LEF macro name must both be exactly `RO_tune6`. Do not name
the file `RO_tune4.lef`, `RO_tune6_real_abstract.lef`, or use a LEF macro alias.
The active flow has `O1_ALLOW_LEF_MACRO_ALIAS=0` and will fail if the LEF
contains a different real macro name.

If an OA abstract view is created as part of the Cadence abstract-generation
flow, keep it as:

```text
library: SPADMIC
cell:    RO_tune6
view:    abstract
```

The repository flow consumes the exported LEF file above, not the OA abstract
view directly. The OA abstract view is useful only as source evidence or for
regenerating the LEF.

## LEF Content Requirements

The exported LEF must contain:

- `MACRO RO_tune6`;
- valid `SIZE`, `ORIGIN`, `SYMMETRY`, and site-compatible geometry;
- pins `rstb`, `code[0]` through `code[7]`, `S[0]` through `S[7]`;
- power pins `VDD`, `VSS`, and `vdd!`;
- physical `PORT`/`LAYER`/`RECT` geometry for every required pin;
- obstruction or blockage geometry that protects layout-internal metals;
- routing layers consistent with the XH018 JIHD Innovus stack.

The logical pin contract is the same as the old RO wrapper contract, but the
macro master is now `RO_tune6`. The RTL instance path intentionally remains
`u_ro_tune4` so existing timing and report paths stay stable.

## Local Sanity Commands

After exporting the LEF, run these commands from the repository root on the
server before launching Genus:

```bash
export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work
source MPTDC/analog_handoff/real_ro_tune6_layout.env

test -f "$O1_RO_LEF_PATH"
awk '
  /^[[:space:]]*PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=1; next}
  inprop && /^[[:space:]]*END[[:space:]]+PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=0; next}
  inprop {next}
  /^[[:space:]]*MACRO[[:space:]]+/ {print; exit}
' "$O1_RO_LEF_PATH"

python3 MPTDC/analog_handoff/audit_ro_tune6_layout.py \
  --macro RO_tune6 \
  --source-lef "$O1_RO_LEF_PATH" \
  --copied-lef "$O1_RO_LEF_PATH" \
  --liberty MPTDC/syn/macros/RO_tune6_real_layout_shell.lib \
  --report /tmp/ro_tune6_lef_audit.rpt

grep -E 'EXPECTED_MACRO|SOURCE_MACRO_NAME|COPIED_MACRO_NAME|REQUIRED_PINS_FOUND|PIN_GEOMETRY_PRESENT|AUDIT_STATUS' \
  /tmp/ro_tune6_lef_audit.rpt
```

Expected result:

```text
EXPECTED_MACRO=RO_tune6
SOURCE_MACRO_NAME=RO_tune6
COPIED_MACRO_NAME=RO_tune6
REQUIRED_PINS_FOUND=YES
PIN_GEOMETRY_PRESENT=YES
AUDIT_STATUS=PASS
```

## Canonical Rerun Commands

After the LEF audit passes:

```bash
bash MPTDC/syn/scripts/check_genus_axis_core_typical_closed_profile.sh
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh

bash MPTDC/pnr/scripts/prepare_mptdc_genus_typical_handoff.sh \
  MPTDC_TC_Closure_Genus

export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  --mode validate_only \
  --genus-run-id MPTDC_TC_Closure_Genus

export MPTDC_DIGITAL_SIGNOFF_APPROVED=1
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh \
  --mode full_signoff \
  --genus-run-id MPTDC_TC_Closure_Genus
```

Do not claim tapeout readiness from this rerun until independent DRC/LVS, row
qualification, antenna, IR/EM, and the remaining TC-only exception review are
closed or explicitly approved by the appropriate owner.
