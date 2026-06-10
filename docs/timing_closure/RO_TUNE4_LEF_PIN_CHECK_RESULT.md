# RO_tune4 LEF Pin Check Result

Author: Karim Sabra

The current checked `RO_tune4` LEF is not missing the control pins.

Source LEF:

```text
/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune4.lef
```

Copied flow LEF:

```text
work/macros/ro_tune4/RO_tune4_real_abstract.lef
```

The checked LEF contains:

```text
code[0]
code[1]
code[2]
code[3]
code[4]
code[5]
code[6]
code[7]
rstb
S[0]
S[1]
S[2]
S[3]
S[4]
S[5]
S[6]
S[7]
VDD
VSS
vdd!
```

Therefore `code[7:0]` and `rstb` are physically present in the current LEF.

The earlier failure was a parser/reporting bug caused by this line inside
`PROPERTYDEFINITIONS`:

```lef
MACRO CatenaDesignType STRING ;
```

That line is not the real macro declaration and must be ignored.  The real
macro declaration is:

```lef
MACRO RO_tune4
```

Do not manually invent LEF pins, do not edit pin geometries by hand, and do not
regenerate the analog abstract unless a later physical audit proves a real pin
is missing.

The active audit is:

```text
MPTDC/analog_handoff/audit_ro_tune4_abstract.py
```

It is integrated into the active Genus wrapper and must pass before a final
typical Genus run is accepted.
