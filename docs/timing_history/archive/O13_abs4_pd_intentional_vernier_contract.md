# O13 abs4 PD Intentional Vernier Contract

Status: `ACTIVE_ABS4_CONSTRAINT_CONTRACT`

## RTL Contract

The phase detector intentionally samples slow phase with fast phase.

`MPTDC/rtl/pd/mptdc_pd_cell.sv:10-14` describes the cell behavior: the slow oscillator phase is sampled on the rising edge of the fast oscillator phase. The implemented two-stage sampler in `MPTDC/rtl/pd/mptdc_pd_cell.sv:86-99` assigns:

```systemverilog
q1 <= slow_phase;
q2 <= q1;
if (!hit_latched && !q1 && q2) begin
  hit_latched <= 1'b1;
end
```

`MPTDC/rtl/top/mptdc_core.sv:492-505` instantiates the 8 x 8 PD matrix:

```text
gen_pd_row[ns].gen_pd_col[nf].u_pd
  slow_phase = slow_phase[ns]
  fast_phase = fast_phase[nf]
```

Therefore the expected measurement crossings are:

```text
slow_phase[0] -> q1_reg/D in row 0, columns 0..7
slow_phase[1] -> q1_reg/D in row 1, columns 0..7
...
slow_phase[7] -> q1_reg/D in row 7, columns 0..7
```

Expected count: `8 slow taps x 8 fast taps = 64`.

## Timing Classification

These 64 paths are classified as:

- class: `PD_INTENTIONAL_VERNIER`
- family: `PD_SLOW_PHASE_SAMPLED_BY_FAST_PD`
- review status: `INTENTIONAL_MEASUREMENT_CROSSING`

They are not:

- `UNKNOWN_REVIEW_REQUIRED`
- `PHASE_BUFFER_CHAIN`
- `OSC_FAST_REAL`
- `CLK_SYS_REAL`

## Exact Constraint Scope

The abs4 SDC applies an exact exception:

```text
-from clk_osc_slow_buf_tap<ns>
-to   gen_pd_row[ns].gen_pd_col[*].u_pd/q1_reg/D
```

This means each slow buffered tap is cut only into the corresponding row's q1 sampler D pins. This is intentionally narrower than grouping all slow and fast clocks together.

## What Must Remain Timed

The abs4 exception must not cut these real local paths:

- `q1_reg -> q2_reg` local fast sampler pipeline
- `q1/q2 -> hit_latched`
- `fast_tag_col[nf] -> nfast_hit_latched`
- local fast tag LFSR self paths
- slow Johnson self path
- BUHDX4 -> BUHDX12 topology visibility
- `clk_sys` internal timing
- reset/recovery checks except separately documented reset protocol checks

## Required Checks

The abs4 run must emit:

```text
PD_VERNIER_EXCEPTION_ENDPOINTS_FOUND=64
PD_VERNIER_EXCEPTION_EXPECTED=64
PD_VERNIER_SOURCE_CLOCKS_FOUND=8
PD_VERNIER_EXCEPTION_APPLIED=YES
PD_VERNIER_EXCEPTION_OVERMATCH=NO
```

If the endpoint count is not exactly 64, abs4 must be treated as review-required and Innovus must not run.
