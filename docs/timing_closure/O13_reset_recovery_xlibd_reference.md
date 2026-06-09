# O13 Reset Recovery XLIBD Reference

Status: `REFERENCE_ONLY_NOT_WAIVER`

The XLIBD extraction confirms that reset recovery, removal, and min-pulse checks are real Liberty checks for the reset flops used in SPADMIC.

## DFRRQHDX2 Reference Values

Maximum extracted constraints:

| Constraint | Value ns |
|---|---:|
| `RECOVERY_RN_TO_C_RISE` | 2.5845 |
| `REMOVAL_RN_TO_C_RISE` | 0.2017 |
| `MIN_WIDTH_RN_LOW` | 0.5535 |
| `MIN_WIDTH_C_HIGH` | 0.4684 |
| `MIN_WIDTH_C_LOW` | 0.5096 |

## DFRRQHDX4 Reference Values

Maximum extracted constraints:

| Constraint | Value ns |
|---|---:|
| `RECOVERY_RN_TO_C_RISE` | 2.9060 |
| `REMOVAL_RN_TO_C_RISE` | 0.2062 |
| `MIN_WIDTH_RN_LOW` | 0.7096 |
| `MIN_WIDTH_C_HIGH` | 0.6335 |
| `MIN_WIDTH_C_LOW` | 0.4978 |

## Interpretation

- Recovery checks are real Liberty checks.
- Removal checks are real Liberty checks.
- Reset min pulse width is real.
- These checks should be classified separately from setup timing.
- Do not broad false-path reset without protocol documentation.

If oscillators are stopped during clear/release, any waiver must cite that protocol behavior and the report should classify the affected paths as reset protocol evidence, not setup closure.
