# Matrix Interface Pin Guide Plan

Status: planning guide for matrix-side pin and region constraints. This is not
a final Innovus pin assignment.

## Goal

The matrix macro stays on the left side of the chip. Digital logic that touches
matrix pins must expose pins in the correct direction and should not force long
routes through hard macros. The first target is a guide for top/manual routing,
not automatic final route into the analog macro.

## Matrix Pin Groups

| Group | Width | Direction from digital view | Physical planning note |
| --- | ---: | --- | --- |
| `R[63:0]` | 64 | matrix to digital | Activity inputs; keep reduction/snapshot leaves near matching matrix side. |
| `Y[63:0]` | 64 | matrix to digital | Activity inputs; align with matrix pin centroid and MPTDC Y region. |
| `B[63:0]` | 64 | matrix to digital | Activity inputs; align with matrix pin centroid and MPTDC B region. |
| `Rz[63:0]` | 64 | digital to matrix | Reset outputs; boundary flops/buffers may need distributed placement. |
| `Yz[63:0]` | 64 | digital to matrix | Reset outputs; keep local to matrix pins when possible. |
| `Bz[63:0]` | 64 | digital to matrix | Reset outputs; keep local to matrix pins when possible. |
| `Din[43:0]` | 44 | digital to matrix | Config serial/data drive; boundary drivers likely matrix-adjacent. |
| `Cin[43:0]` | 44 | digital to matrix | Config/control drive; boundary drivers likely matrix-adjacent. |
| `Dout[43:0]` | 44 | matrix to digital | Config readback input; capture close to matrix pins if needed. |
| `Cout[43:0]` | 44 | matrix to digital | Readback strobes; capture/sampler logic is matrix-sensitive. |

## Guide Rules

- OR leaves, snapshot flops, and matrix boundary flops should be soft or
  region-guided first.
- Hardened blocks should not hide hundreds of matrix pins behind the wrong
  edge of a macro.
- Pin guides should follow the real extracted matrix pin map and normalized
  `ll_*` coordinates.
- Digital OOC blocks should expose matrix-facing pins west/left when their
  final placement is right of the matrix.
- Reset/config central FSMs can be hardened separately from final boundary
  flops if top routing demands it.

## First Region Concepts

| Region | Contents | Relative location |
| --- | --- | --- |
| `matrix_activity_guides` | OR leaves, snapshot input flops | Along matrix R/Y/B pin access. |
| `matrix_reset_boundary_guides` | Rz/Yz/Bz final flops/buffers | Along matrix reset pin access. |
| `matrix_cfg_boundary_guides` | Din/Cin drivers and Dout/Cout capture | Along matrix config pin access. |
| `position_frontend_guides` | snapshot-to-position frontend | Right or upper-right of matrix, before packet core. |
| `matrix_control_core_region` | reset/config/event central control | Bottom or bottom-right of matrix. |

## Required Inputs Before Final Pin Assignment

- latest matrix LEF/pin coordinate CSV;
- final MPTDC macro boundary and halo;
- DDRs2 macro pin order and physical location;
- final pad ring blockage and `BOX_RING` constraints;
- analog designer preference for manual route channels near matrix.
