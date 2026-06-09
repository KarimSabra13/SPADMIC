# O13 Abs5 Review of Abs4 Failure

Status: `ABS4_INTERPRETABLE_BUT_NOT_INNOVUS_READY`

## Abs4 Result

O13 abs4 fixed the clock-model problem from abs2/abs3:

- raw RO clocks found: 16
- final buffered phase clocks found: 16
- buffer clocks async to `clk_sys`: YES
- `clk_sys` async to buffer phase clocks: YES
- `UNKNOWN_REVIEW_REQUIRED`: 0
- BUHDX4 -> BUHDX12 topology report: all 16 chains `OK_CHAIN_FOUND`
- packet format: unchanged
- `raw_lfsr_tag`: unchanged
- DRV: clean

This means O13 must not be rejected on the abs4 result.

## Abs4 Failure

The PD Vernier SDC exception did not match the full PD matrix:

- expected q1 endpoints: 64
- found q1 endpoints: 8
- expected slow sources: 8
- exception applied: NO
- overmatch/undermatch review required: YES

The post-synthesis timing-intent report listed all 64 q1 pins:

```text
u_core_gen_pd_row[0].gen_pd_col[0].u_pd/q1_reg/D
...
u_core_gen_pd_row[7].gen_pd_col[7].u_pd/q1_reg/D
```

Therefore the RTL and synthesized hierarchy are not missing the endpoints. The abs4 bug is the Tcl discovery pattern. Patterns such as:

```tcl
*gen_pd_row[0].gen_pd_col*.u_pd/q1_reg*/D
```

use square brackets in a Tcl glob. They do not reliably mean literal generated hierarchy indices. Abs4 accidentally found one endpoint per row instead of all eight columns.

## RTL Contract

The intended measurement crossing is in `mptdc_pd_cell`:

- [mptdc_pd_cell.sv](/home/karim/SPADMIC/MPTDC/rtl/pd/mptdc_pd_cell.sv:49): `slow_phase` is the sampled signal.
- [mptdc_pd_cell.sv](/home/karim/SPADMIC/MPTDC/rtl/pd/mptdc_pd_cell.sv:50): `fast_phase` is the sampler clock.
- [mptdc_pd_cell.sv](/home/karim/SPADMIC/MPTDC/rtl/pd/mptdc_pd_cell.sv:86): the sampler runs on `posedge fast_phase`.
- [mptdc_pd_cell.sv](/home/karim/SPADMIC/MPTDC/rtl/pd/mptdc_pd_cell.sv:92): `q1 <= slow_phase`.
- [mptdc_pd_cell.sv](/home/karim/SPADMIC/MPTDC/rtl/pd/mptdc_pd_cell.sv:93): `q2 <= q1` remains real local fast-domain timing.

The 8x8 matrix is instantiated in `mptdc_core`:

- [mptdc_core.sv](/home/karim/SPADMIC/MPTDC/rtl/top/mptdc_core.sv:492): `gen_pd_row`
- [mptdc_core.sv](/home/karim/SPADMIC/MPTDC/rtl/top/mptdc_core.sv:493): `gen_pd_col`
- [mptdc_core.sv](/home/karim/SPADMIC/MPTDC/rtl/top/mptdc_core.sv:499): row `ns` drives `slow_phase[ns]`
- [mptdc_core.sv](/home/karim/SPADMIC/MPTDC/rtl/top/mptdc_core.sv:500): column `nf` drives `fast_phase[nf]`

This produces exactly 8 slow rows x 8 fast columns = 64 intentional q1 sampling crossings.

## O13 Topology Contract

The O13 phase-buffer topology remains:

- [mptdc_phase_buffer_bank.sv](/home/karim/SPADMIC/MPTDC/rtl/osc/mptdc_phase_buffer_bank.sv:21): O13 topology define.
- [mptdc_phase_buffer_bank.sv](/home/karim/SPADMIC/MPTDC/rtl/osc/mptdc_phase_buffer_bank.sv:75): BUHDX4 first-stage isolation buffer.
- [mptdc_phase_buffer_bank.sv](/home/karim/SPADMIC/MPTDC/rtl/osc/mptdc_phase_buffer_bank.sv:81): BUHDX12 final digital driver.

Abs4 reported all 16 chains as `OK_CHAIN_FOUND`, so the abs5 work does not alter topology.

## Why This Blocks Innovus

Abs4 still timed the slow buffered phase into `q1_reg/D` as ordinary setup timing. Those paths had WNS around -422 ps and dominated timing, but they are the Vernier measurement itself, not synchronous logic to close.

Until the exact exception is applied and audited, Innovus would optimize or report against a misleading timing objective. The correct next step is abs5 endpoint/source discovery repair, not physical implementation.

## Abs5 Fix Direction

Abs5 replaces fragile glob matching with:

1. broad candidate collection such as `*q1_reg*/D`
2. conversion to plain object names
3. regexp matching of literal generated hierarchy:
   `gen_pd_row\[([0-7])\].*gen_pd_col\[([0-7])\].*u_pd.*q1_reg.*/D`
4. 2D matrix validation
5. fail-closed exception application only when exactly 64 endpoints and 8 slow sources are present

The intended exception is narrow:

```text
slow buffered final-driver output for row ns
  -> q1_reg/D endpoints for row ns, columns 0..7
```

It must not cut `q1_reg -> q2_reg`, `hit_latched`, `nfast_hit_latched`, fast tags, clk_sys, reset/recovery, or the phase-buffer chain.
