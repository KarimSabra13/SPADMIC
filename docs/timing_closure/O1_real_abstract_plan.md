# O1A Real RO_tune4 Abstract Plan

Work package: `O1_real_abstract_and_R800_derate`
Sub-experiment: `O1A_real_abstract_nominal`

Status target after this run: `REAL_PHYSICAL_ABSTRACT, NOT FINAL SIGNOFF`

## Purpose

O1A replaces the O0 provisional oscillator physical geometry with the real analog abstract source for `SPADMIC/RO_tune4/abstract`, while keeping nominal oscillator timing. The goal is to prove whether the real abstract can become a LEF-style macro view and whether the current RTL/netlist can bind to it.

O1A must not change oscillator frequency. O1B handles R800 separately after O1A is analyzed.

## Real Abstract Source

Virtuoso property viewer data:

- Library: `SPADMIC`
- Cell: `RO_tune4`
- View: `abstract`
- OA path: `/group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL/RO_tune4/abstract`
- Expected files: `layout.oa`, `master.tag`, `thumbnail_800x800.png`

This is OpenAccess data, not a LEF file. The O1A locator/export scripts must prove on the lab server that it exists, is readable, and can be exported or replaced by an existing LEF.

## Required Evidence

The lab run must produce:

- abstract path existence and permissions;
- `layout.oa` and `master.tag` existence;
- nearby LEF/GDS/Liberty search results;
- exported or copied LEF;
- LEF macro name, size, pin list, and obstruction summary;
- proof whether Genus/Innovus loaded the real LEF;
- proof whether the netlist master actually binds to `RO_tune4`;
- O1A timing and physical reports only if binding succeeds.

## Binding Policy

Do not treat `layout.oa` as LEF.

Do not silently fall back to O0 provisional LEF in O1A.

Use the provisional Liberty shell only as an electrical/timing placeholder if no real Liberty exists. That status remains non-signoff.

If the LEF macro name or pins do not match the netlist oscillator master, stop and request a macro-binding fix. Preferred order:

1. align the blackbox/macro module name and pins with the real LEF;
2. generate controlled LEF aliases only if geometry/pins are identical;
3. use Innovus-supported cell mapping only if documented;
4. do not change oscillator measurement semantics to solve a naming issue.

## Expected Current Blocker

Current RTL instantiates `mptdc_osc_wrapper`, which instantiates `mptdc_osc_stub` for synthesis. O0 Genus area reports show masters `mptdc_osc_stub_NE8` and `mptdc_osc_stub_NE8_1252`, not `RO_tune4`.

Therefore O1A may stop at `REAL_ABSTRACT_FOUND` / `LEF_EXPORTED` with `MACRO_BINDING_NOT_READY`. That is a useful result and should be committed.

## Acceptance for O1A

O1A is useful if it answers these questions:

- Can the lab server read the OA abstract path?
- Does an existing LEF already exist?
- If no existing LEF exists, can the server export one automatically?
- What macro name and pins does the LEF expose?
- Does current netlist binding match the LEF?
- If binding succeeds, do phase tap routes and PD grid reports become non-empty and meaningful?

O1A is not closed if:

- only provisional geometry is used;
- no real LEF exists or can be exported;
- real LEF is loaded but the netlist does not instantiate a matching macro;
- real Liberty/timing/electrical data is still missing.
