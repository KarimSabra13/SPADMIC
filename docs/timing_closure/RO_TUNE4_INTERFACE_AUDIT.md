# RO_tune4 Interface Audit

Author: Karim Sabra

This note records the required interface contract for the real `RO_tune4`
macro used by the MPTDC typical-only Genus and Innovus flows.

## Scope

The audit compares:

- RTL black-box declaration: `MPTDC/rtl/osc/mptdc_osc_wrapper.sv`.
- Liberty shell: `MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib`.
- Source LEF from `MPTDC/analog_handoff/real_ro_tune4_abstract.env`.
- Copied flow LEF, normally `work/macros/ro_tune4/RO_tune4_real_abstract.lef`
  or the path passed through `O1_RO_LEF_PATH`.

The active parser must ignore the LEF `PROPERTYDEFINITIONS` section.  A line
such as `MACRO CatenaDesignType STRING ;` is a property declaration, not the
real physical macro.

## Required Interface

The real macro name must be `RO_tune4` in RTL, Liberty, and LEF.

Required logical/control pins:

- `rstb`
- `code[0]` through `code[7]`
- `S[0]` through `S[7]`

Required physical supply pins:

- `VDD`
- `VSS`
- `vdd!`

The Liberty shell represents supplies as `pg_pin`s.  The current RTL black-box
uses only the logical/control ports `rstb`, `code[7:0]`, and `S[7:0]`; the
physical supply pins are checked through Liberty and LEF, not by adding RTL
power ports in this cleanup step.

## Current Consistency

| View | Expected | Current policy |
|---|---|---|
| RTL module | `RO_tune4` | Logical ports `rstb`, `code[7:0]`, `S[7:0]` |
| Liberty cell | `RO_tune4` | Logical pins plus `pg_pin` supplies |
| LEF macro | `RO_tune4` | Physical pins and routing geometry required |

LEF may enumerate bus pins as `code[0]` ... `code[7]` and `S[0]` ... `S[7]`.
That is acceptable with the Liberty bus declarations if the EDA tool maps the
pin names consistently.

## `rstb` Interpretation

`rstb` is not a normal digital reset for the MPTDC logic.

For the `RO_tune4` macro:

- `rstb = 1` means the oscillator runs.
- `rstb = 0` means the oscillator is stopped.

In RTL, `osc_slow_en` and `osc_fast_en` drive `rstb` through
`mptdc_osc_wrapper`.  Therefore `rstb` must be present in RTL, Liberty, and
LEF, must remain routable in Innovus, and must not be accidentally tied off or
optimized away.

## `code[7:0]` Interpretation

`code[7:0]` is the RO tuning code.  It must remain present in RTL, Liberty, and
LEF even when a particular timing experiment uses fixed or default tuning.

Do not remove `code[7:0]` and do not tie it off without an explicit integration
decision.

## RO_tune3 Versus RO_tune4

Some historical screenshot evidence has used the label `RO_tune3`.  The active
digital flow expects `RO_tune4`.

Current status:

- Checked LEF path: `/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune4.lef`.
- Checked macro name: `RO_tune4`.
- Active RTL/Liberty/flow name: `RO_tune4`.
- `ANALOG_MACRO_VERSION_REVIEW_REQUIRED=YES_FOR_SCREENSHOT_PROVENANCE`.

Do not silently substitute `RO_tune3` for `RO_tune4`.  If the screenshot is
claimed as current implementation evidence, the analog owner must confirm that
the layout/LEF corresponds to the intended `RO_tune4` macro.

## Audit Command

Run from the repository root:

```bash
source MPTDC/analog_handoff/real_ro_tune4_abstract.env
python3 MPTDC/analog_handoff/audit_ro_tune4_abstract.py \
  --copied-lef "$O1_RO_LEF_PATH" \
  --report reports/ro_tune4_lef_audit.rpt
```

For the current server flow where the copied LEF is under `work/`:

```bash
source MPTDC/analog_handoff/real_ro_tune4_abstract.env
python3 MPTDC/analog_handoff/audit_ro_tune4_abstract.py \
  --copied-lef "$PWD/work/macros/ro_tune4/RO_tune4_real_abstract.lef" \
  --report reports/ro_tune4_lef_audit.rpt
```

Expected status:

```text
SOURCE_MACRO_NAME=RO_tune4
COPIED_MACRO_NAME=RO_tune4
PROPERTYDEFINITIONS_MACRO_ENTRIES_IGNORED=YES
REQUIRED_PINS_FOUND=YES
PIN_GEOMETRY_PRESENT=YES
AUDIT_STATUS=PASS
```
