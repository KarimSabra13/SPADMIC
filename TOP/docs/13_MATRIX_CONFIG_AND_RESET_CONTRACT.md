# Matrix Configuration And Selective Reset Contract

Status: Phase 5 contract. Returned-Cout readback is implemented in RTL, but matrix macro timing fields marked TBD are not signoff constraints.

## Physical Matrix Interface

Final matrix event buses:

```systemverilog
input  logic [63:0] R_i;
input  logic [63:0] Y_i;
input  logic [63:0] B_i;
```

Final selective reset buses:

```systemverilog
output logic [63:0] Rz_o;
output logic [63:0] Yz_o;
output logic [63:0] Bz_o;
```

Final configuration buses:

```systemverilog
output logic [43:0] matrix_din_o;
output logic [43:0] matrix_cin_o;
input  logic [43:0] matrix_dout_i;
input  logic [43:0] matrix_cout_i;
```

## Selective Reset Contract

- Reset-select outputs are active low and level-sensitive for v1.
- Internal reset masks are active high.
- Physical outputs are inverted masks.
- Global chip reset clears masks to zero so physical reset-select outputs are all ones.
- Reset target is all asserted raw R/Y/B snapshot bits.
- Multiple asserted bits are reset in parallel. Cartesian over-reset is accepted.
- The mask is captured before assertion and remains stable through the whole pulse.
- Width is measured in `clk_sys` cycles:
  - `0`: no automatic selective reset;
  - `1`: exactly one full `clk_sys` cycle;
  - `N`: exactly `N` full `clk_sys` cycles.
- No pre-reset delay.
- No post-reset guard delay.
- No retry.
- No per-bit clear verification.
- No pulse-width escalation.

`spadmic_matrix_reset_ctrl` states:

| State | Function |
| --- | --- |
| `IDLE` | outputs inactive high, wait for start |
| `LOAD_MASK` | latch snapshot masks |
| `ASSERT_RESET` | drive selected masks active for exact configured count |
| `RELEASE_RESET` | clear masks and produce done pulse |
| `DONE` | wait for coordinator to observe completion |

If reset width is zero, the block sets `disabled_o`, does not pulse `Rz/Yz/Bz`, and returns completion status to the coordinator. Matrix modes with reset disabled are diagnostic/single-shot unless lines clear externally.

## Snapshot Contract

`spadmic_matrix_snapshot_frontend` is a `clk_sys` service. It does not sit on the MPTDC START timing path.

Responsibilities:

- synchronize asynchronous R/Y/B inputs for control/reset/position use;
- detect first matrix activity;
- require all three directions nonzero for a normal matrix event;
- restart settle counter on input changes before capture;
- capture and freeze raw R/Y/B snapshots;
- expose timeout, overlap, invalid image, and rearm status;
- support capture-only operation for TDC-only mode.

Recommended rearm rule:

- after reset release, observe two consecutive synchronized all-zero R/Y/B samples before rearming.

The reset masks always derive from raw snapshots, never from filtered clusters.

## Matrix Configuration Contract

Configuration dimensions:

- columns: 44, indices `0..43`;
- lines per column: 32;
- config bits per line: 2;
- bits per column: 64;
- total payload: 2816 bits.

Default v1 bit order:

| Shift/data bit | Logical target |
| --- | --- |
| `bit[2*line+0]` | `cfg0(line)` |
| `bit[2*line+1]` | `cfg1(line)` |

This mapping is accepted for v1 and remains marked for matrix-designer confirmation.

Required operations:

- `WRITE_COLUMN_64`;
- `READ_COLUMN_64`;
- `GLOBAL_FILL_0`;
- `GLOBAL_FILL_1`.

Command behavior:

1. `clk_sys` CSR writes parameters.
2. `clk_sys` CSR writes START.
3. Hardware snapshots opcode, column, and 64-bit write data.
4. `clk_sys` marks BUSY.
5. CDC transfers one command into `clk_cfg_40m`.
6. `clk_cfg_40m` controller runs the command.
7. Return CDC transfers done/error/readback.
8. `clk_sys` updates CSR-visible status and clears BUSY.

Command while BUSY is rejected. Reset aborts the operation, drives safe idle outputs, and clears `matrix_cfg_valid`.

Implemented Phase 5 readback behavior:

- `WRITE_COLUMN_64` drives one selected `Din[col]` bit per `clk_cfg_40m` bit step, pulses `Cin[col]`, waits for the returned `Cout[col]` strobe, samples `Dout[col]`, and stores the sampled bit into the CSR-visible 64-bit readback shift register.
- `READ_COLUMN_64` clocks the selected column and samples `Dout[col]` on the returned `Cout[col]` strobe.
- `GLOBAL_FILL_0` and `GLOBAL_FILL_1` drive all 44 `Din/Cin` columns in parallel for each bit step and use column 0 returned `Cout[0]/Dout[0]` as the reference readback path.
- Missing returned `Cout` raises `ERR_COUT_TIMEOUT`, clears `readback_valid`, clears `matrix_cfg_valid`, and returns the physical outputs to idle.
- The previous write-data mirror readback model is obsolete and must not be used as evidence of physical matrix readback.

## `clk_sys` To `clk_cfg_40m` CDC

The matrix configuration controller must not double-flop changing multi-bit buses independently.

Required request protocol:

- `clk_sys` copies opcode, column, and data into command-hold registers.
- The command-hold bus remains stable until the config side acknowledges completion.
- `clk_sys` toggles `cmd_req_tgl`.
- `clk_cfg_40m` synchronizes the toggle through two flops.
- `clk_cfg_40m` detects the toggle and samples the stable command-hold bus.

Required return protocol:

- `clk_cfg_40m` stores error/status/readback in return-hold registers.
- The return-hold bus remains stable.
- `clk_cfg_40m` toggles `cmd_done_tgl`.
- `clk_sys` synchronizes the done toggle through two flops.
- `clk_sys` samples the stable return bus and clears BUSY.

This interface is non-signoff until analog handoff provides setup, hold, min high, min low, and Dout/Cout delay.

The returned-`Cout` sampler is a real CDC/RDC boundary. The current RTL captures `Dout[col]` in a per-column returned-`Cout` event domain, synchronizes a capture toggle/data back into `clk_cfg_40m`, and then returns a stable readback bus to `clk_sys` through the existing done-toggle handshake. This is functionally tested locally, but it still requires Cadence CDC/RDC review, STA classification, and final matrix macro timing.

## `clk_cfg_40m` Sequencing Defaults

- `Cin` active edge: rising edge.
- `Din` stable before the rising edge and held after the edge.
- `Cout` is treated as the returned `Cin` strobe after matrix propagation/RC delay.
- `Dout` is sampled only when the selected/readback column's returned `Cout` is observed.
- Outputs idle low after reset or abort.
- No combinational clock gates from the old reference RTL.
- Global fill may clock multiple columns if the matrix contract allows it; otherwise implementation may iterate columns.

## Open Matrix Designer Items

- Meaning of `cfg0` and `cfg1`.
- Exact Dout/Cout timing, including setup/hold of `Dout` around returned `Cout` and maximum returned-Cout latency.
- Whether returned `Cout` needs dedicated clock-tree or generated-clock treatment in signoff.
- Minimum and maximum reset low time.
- Reset-select skew and overlap requirements.
- Whether a separate global matrix reset exists.
- Whether global matrix reset clears configuration.
- Whether configuration survives selective reset. Current frozen assumption: yes.
