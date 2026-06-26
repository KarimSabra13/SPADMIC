# MPTDC Signoff Limitations

Author: Karim Sabra

This repository state does not claim final tapeout signoff.

## Current Limitations

- Timing closure is typical-only.
- MMMC closure has not been completed.
- Final extracted post-layout timing is not complete.
- Analog phase behavior still needs final confirmation.
- Characterization must be rerun after the final physical topology.
- Calibration must be regenerated from the final characterization dataset.
- No final LVS signoff is claimed.
- No final DRC signoff is claimed.
- No final PEX signoff is claimed.
- No final tapeout-ready signoff package is claimed.
- The pre-RO-code Genus/Innovus evidence is invalid as an active netlist handoff
  after the slow/fast RO-code RTL interface change.

## What Current Results Can Support

Current typical-only results can support architecture debugging, flow
stabilization, load analysis, and feasibility decisions. They cannot be used as
the final tapeout release criterion, and they cannot be reused after RTL/netlist
changes without rerunning the canonical Genus flow.

## Protected Scope

Cleanup work must not silently modify:

- Packet format.
- Calibration semantics.
- `RO_tune6` layout/OA/LEF macro collateral.
- XLIBD references.
- Intentional PD Vernier timing logic.

Approved RTL changes, such as the slow/fast RO-code local shadow-register
interface, must be treated as new functional baselines and require fresh
simulation, Genus, and physical-flow evidence before signoff.
