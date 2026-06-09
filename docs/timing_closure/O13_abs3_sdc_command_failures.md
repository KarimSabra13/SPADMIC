# O13 abs3 SDC Command Failures

Status: `REPAIRED_AND_AUDITED`

## Abs2 Failures

The abs2 log showed `SDC-202` failures from helper procedures that passed Tcl object handles such as `0x79` into SDC commands. The failing areas were:

- false paths for async clear/control pins
- max-delay helper for STOP metadata static bus
- reset net max-transition helper

## Fixes

- `mptdc_try_false_path_pins` now converts matched pins to object names and applies false paths per pin.
- `mptdc_try_set_max_delay_pins` now converts matched pins to names and falls back to per-pin pairs if aggregate syntax fails.
- Reset net-specific max transition is no longer applied directly to net objects in Genus SDC mode because this tool rejects that object type. The design-level max transition still applies, and reset slew remains a DRV review item.

## Remaining Risk

Abs3 must confirm the SDC log no longer contains failed false-path, max-delay, generated-clock, or clock-group commands. The wrapper emits `sdc_command_failures.md` for this review.
