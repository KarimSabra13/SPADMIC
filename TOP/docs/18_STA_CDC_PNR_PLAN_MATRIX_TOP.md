# Matrix TOP STA, CDC, RDC, And PnR Plan

Status: Phase 0 implementation intent. This is not final signoff.

## Clock Domains

| Domain | Frequency | Function |
| --- | --- | --- |
| `clk_sys` | 160 MHz | CSR, I2C bridge, event coordinator, snapshot, reset, output control |
| `clk_ref_40m` | 40 MHz | MPTDC STOP qualifier reference |
| `clk_cfg_40m` | 40 MHz | matrix configuration Din/Cin sequencing and Dout/Cout capture |
| MPTDC internal oscillator phases | local | protected MPTDC measurement internals |
| async matrix R/Y/B | asynchronous | START and snapshot inputs |
| DDR macro clock | 160 MHz provisional | final DDR16 macro boundary |

Even if `clk_sys` and `clk_cfg_40m` are PLL-related, RTL treats them as separate domains until final STA constraints prove a synchronous relationship.

## Reset Domains

- Global chip reset asserts asynchronously.
- Local reset release is synchronized per domain:
  - `rst_sys_n` for `clk_sys`;
  - `rst_cfg_n` for `clk_cfg_40m`.
- Matrix reset-select outputs must go inactive high immediately on global reset.
- Matrix configuration outputs must go idle on reset or abort.
- TX data and valid must go idle on reset.

## CDC Strategy

### Matrix Configuration

Use stable-bus plus toggle handshake:

- command-hold bus stable in `clk_sys`;
- request toggle synchronized into `clk_cfg_40m`;
- config side samples stable bus after toggle detect;
- return-hold bus stable in `clk_cfg_40m`;
- done toggle synchronized into `clk_sys`;
- system side samples stable return bus after done detect.

Verifier must reject any implementation that samples independently synchronized changing multi-bit command or readback buses.

### Matrix Snapshot

R/Y/B matrix event lines are asynchronous. The snapshot frontend uses simple multi-stage synchronizers with `ASYNC_REG` attributes for control/reset/position use. This synchronized path is not the timing path to MPTDC START.

### MPTDC START

The independent R/Y/B START paths remain asynchronous by design. They should be classified and reported, not hidden only by broad false paths.

### I2C

I2C remains externally asynchronous to `clk_sys` and is handled by the existing I2C/CSR bridge strategy. Integration must preserve one outstanding access.

## OR64 START Tree STA/PnR Intent

Requirements:

- no logic sharing between R/Y/B axes;
- balanced tree with the same logical depth inside each axis;
- comparable cell types and output load;
- final local buffer near each MPTDC START input;
- physical grouping based on `matrice3_pin_coordinates.csv` normalized coordinates;
- line-to-line delay and slew reports;
- no final max-delay number invented before library/floorplan evidence.

Suggested first implementation topology:

```text
64 inputs -> 16 OR4 -> 4 OR4 -> 1 OR4 -> local output buffer
```

The implementation may use generic RTL OR reductions only if synthesis constraints/hierarchy keep the tree reviewable. Otherwise, use explicit grouped OR logic.

## Matrix Reset Output Intent

- Place reset-mask registers and final buffers close to Rz/Yz/Bz pin banks/corridors.
- Avoid deep logic from register to matrix pin.
- Constrain output transition/fanout with placeholders until macro loads are known.
- Review simultaneous switching across selected Rz/Yz/Bz lines.

## Matrix Configuration Intent

- `clk_cfg_40m` is a real clock domain.
- No combinational clock gating copied from reference RTL.
- Din/Cin timing is non-signoff until macro provides timing.
- Dout/Cout capture timing is non-signoff until macro provides timing and Cout meaning.
- Use generated clock/clock group constraints only after PLL relationship is finalized.

## DDR16 Macro Intent

- Use a macro wrapper with single-edge digital inputs.
- Do not use dual-edge procedural final RTL.
- Create placeholder output timing constraints only.
- No final board timing claim.
- Pairer empty/busy contributes to TOP path idle.

## Floorplan Intent

- `matrice3` on left side, centered vertically.
- MPTDCs to the right of matrix and close together.
- Position front-end partly distributed near matrix pins; main packet/cluster logic grouped.
- Arbiter/FIFO/TX toward north-east/north.
- Control/reset/supervision toward bottom of matrix.
- PLL bottom-right.
- Reserve `INTERNAL_NEAREST_RIGHT` access corridors.

## Signoff Limitations

Current stage is typical-only planning and early RTL feasibility. Do not claim:

- final MMMC;
- extracted timing;
- DRC/LVS;
- PEX;
- final DDR board timing;
- final SPAD macro timing closure;
- final matrix configuration timing closure.

Final matrix and DDR abstracts may invalidate placeholder constraints and require SDC, CDC waiver, and floorplan updates.
