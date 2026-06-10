# O13 Reset Recovery XLIBD Reference

Status: `REFERENCE_ONLY_NOT_WAIVER`

The XLIBD extraction confirms that reset recovery, removal, and min-pulse checks are real Liberty checks for the reset flops used in SPADMIC.

## Reset Flop Reference Values

### DFRRQHDX1

Pin caps:

| Pin | Cap fF |
|---|---:|
| `D` | 3.19 |
| `C` | 3.62 |
| `RN` | 7.32 |

Maximum extracted constraints:

| Constraint | Value ns |
|---|---:|
| `RECOVERY_RN_TO_C_RISE` | 1.3272 |
| `REMOVAL_RN_TO_C_RISE` | 0.2048 |
| `MIN_WIDTH_RN_LOW` | 0.4705 |

### DFRRQHDX2

Pin caps:

| Pin | Cap fF |
|---|---:|
| `D` | 3.20 |
| `C` | 3.45 |
| `RN` | 6.51 |

Maximum extracted constraints:

| Constraint | Value ns |
|---|---:|
| `RECOVERY_RN_TO_C_RISE` | 2.5845 |
| `REMOVAL_RN_TO_C_RISE` | 0.2017 |
| `MIN_WIDTH_RN_LOW` | 0.5535 |
| `MIN_WIDTH_C_HIGH` | 0.4684 |
| `MIN_WIDTH_C_LOW` | 0.5096 |

### DFRRQHDX4

Maximum extracted constraints:

| Constraint | Value ns |
|---|---:|
| `RECOVERY_RN_TO_C_RISE` | 2.9060 |
| `REMOVAL_RN_TO_C_RISE` | 0.2062 |
| `MIN_WIDTH_RN_LOW` | 0.7096 |
| `MIN_WIDTH_C_HIGH` | 0.6335 |
| `MIN_WIDTH_C_LOW` | 0.4978 |

## Set Flop Reference

`DFRSHDX1` is a set flop, not a reset flop.

Pin caps:

| Pin | Cap fF |
|---|---:|
| `D` | 2.70 |
| `C` | 3.64 |
| `SN` | 8.61 |

Maximum extracted set constraints:

| Constraint | Value ns |
|---|---:|
| `RECOVERY_SN_TO_C_RISE` | 0.0599 |
| `REMOVAL_SN_TO_C_RISE` | 0.9625 |
| `MIN_WIDTH_SN_LOW` | 0.2236 |

Use `DFRSHDX1` only when set behavior is required. Do not interpret `SN` as a reset pin.

## Interpretation

- Recovery checks are real Liberty checks.
- Removal checks are real Liberty checks.
- Reset and set min pulse width checks are real.
- These checks should be classified separately from setup timing.
- Do not broad false-path reset without protocol documentation.

If oscillators are stopped during clear/release, any waiver must cite that protocol behavior and the report should classify the affected paths as reset protocol evidence, not setup closure.
