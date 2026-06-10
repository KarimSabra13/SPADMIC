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

## What Current Results Can Support

Current typical-only results can support architecture debugging, flow
stabilization, load analysis, and feasibility decisions.  They cannot be used as
the final tapeout release criterion.

## Protected Scope

Cleanup work must not modify:

- RTL behavior.
- Packet format.
- Calibration semantics.
- `RO_tune4` macro abstracts.
- XLIBD references.
- Intentional PD Vernier timing logic.
