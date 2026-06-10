# O13 abs4 SDC Command Failure Review

Status: `ABS4_HELPER_REPAIR_PREPARED`

## abs3 Failure Pattern

The committed abs3 `sdc_command_failures.md` still showed base-SDC failures even though the abs3 overlay itself created clocks and async groups correctly.

The common failure form was:

```text
set_false_path -to {263 263}
set_false_path -through {263 263}
set_max_delay ... -from {{367 367} ...}
```

Genus reported these as `TUI-61` / `SDC-202`. The root problem is Tcl collection handles being stringified and passed back into SDC commands as object names.

## Intended Effects

The affected base-SDC helpers cover:

- PD conversion clear pins
- START watchdog async clear pins
- STOP metadata async capture data pins
- STOP metadata static-bus max delay into the `clk_sys` snapshot bridge

These constraints are still relevant, but they must be applied without invalid object-handle interpolation.

## abs4 Fix

`MPTDC/syn/inputs/mptdc.sdc` now applies false-path and max-delay helper commands with `get_pins` directly inside the SDC command, instead of converting a collection into a string and reusing that string later.

Expected abs4 behavior:

- no `set_false_path` commands with numeric object names such as `{263 263}`
- no `set_max_delay` commands with nested numeric handle lists
- no unresolved `TUI-61`, `SDC-202`, or safety-critical `SDC-209` errors
- `sdc_command_failures.md` should either report `NO_UNRESOLVED_SDC_COMMAND_FAILURES` or list only explicitly reviewed harmless warnings

## Remaining Risk

This cannot be fully proven locally without Genus because the failure is Genus SDC-mode collection handling. The server abs4 run is the validation point.

If abs4 still reports failed false-path, max-delay, generated-clock, clock-group, or Vernier exception commands, do not proceed to Innovus.
