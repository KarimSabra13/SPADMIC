# O1C LEF Parser Fix

Date: 2026-05-28
Branch: SPADMIC_TOP

## Problem

The O1A LEF export script parsed this line inside the LEF `PROPERTYDEFINITIONS`
section as if it were a real macro:

```lef
MACRO CatenaDesignType STRING ;
```

That made the O1A summary report a source macro of `CatenaDesignType` and
created an unnecessary alias rewrite. The real LEF macro block is:

```lef
MACRO RO_tune4
...
END RO_tune4
```

## Fix

- Added `tools/timing/parse_lef_macros.py`.
- Added `tools/timing/test_parse_ro_tune4_lef.py`.
- Updated `MPTDC/pnr/scripts/server_export_ro_tune4_lef.sh` so its shell parser
  ignores `PROPERTYDEFINITIONS` and only edits real `MACRO ... END ...` blocks.

## Required RO_tune4 Parse Result

- Macro: `RO_tune4`
- Size: `176.675 BY 67.17`
- OBS: present
- Phase outputs: `S[0]` through `S[7]`
- Tune inputs: `code[0]` through `code[7]`
- Run/start control: `rstb`
- Power pins: `VDD`, `VSS`, `vdd!`

## Local Evidence

Run locally:

```bash
python3 -m py_compile tools/timing/parse_lef_macros.py
python3 -m py_compile tools/timing/test_parse_ro_tune4_lef.py
python3 tools/timing/test_parse_ro_tune4_lef.py
```

Expected test result:

```text
PASS: RO_tune4 LEF parser ignores PROPERTYDEFINITIONS and finds real pins
```
