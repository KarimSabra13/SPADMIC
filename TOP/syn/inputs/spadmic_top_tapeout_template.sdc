# =============================================================================
# Project  : SPADMIC TOP
# File     : spadmic_top_tapeout_template.sdc
# Purpose  : Tapeout-readiness SDC template for the active chip-level RTL.
# =============================================================================
#
# This is a signoff-intent template, not a final foundry-deliverable SDC.
# Replace the TODO values with PLL, SPAD-matrix, oscillator, package, and board
# numbers before signoff.  Keep every exception tied to the CDC/STA map in
# TOP/docs/10_TAPEOUT_READINESS.md.
# =============================================================================

# -----------------------------------------------------------------------------
# 0. User-owned timing budgets
# -----------------------------------------------------------------------------
set TOP_CLK_SYS_PERIOD_NS       6.250
set TOP_CLK_REF_PERIOD_NS       25.000
set TOP_CLK_UNCERTAINTY_NS      0.100
set TOP_INPUT_DELAY_NS          1.000
set TOP_OUTPUT_DELAY_NS         1.000
set TOP_DDR_OUTPUT_MAX_NS       1.000
set TOP_DDR_OUTPUT_MIN_NS      -0.250
set TOP_INPUT_TRANSITION_NS     0.100
set TOP_OUTPUT_LOAD_PF          0.050

# TODO: Replace these with PLL/macro-derived names once the final PLL is known.
set TOP_CLK_SYS_PORT            clk_sys
set TOP_CLK_REF_PORT            clk_ref_40m
set TOP_RST_PORT                async_rst_n

# -----------------------------------------------------------------------------
# 1. Primary clocks
# -----------------------------------------------------------------------------
create_clock -name clk_sys -period $TOP_CLK_SYS_PERIOD_NS \
  [get_ports $TOP_CLK_SYS_PORT]

create_clock -name clk_ref_40m -period $TOP_CLK_REF_PERIOD_NS \
  [get_ports $TOP_CLK_REF_PORT]

set_clock_uncertainty $TOP_CLK_UNCERTAINTY_NS [get_clocks clk_sys]
set_clock_uncertainty $TOP_CLK_UNCERTAINTY_NS [get_clocks clk_ref_40m]

# -----------------------------------------------------------------------------
# 2. Source-synchronous DDR TX contract
# -----------------------------------------------------------------------------
# chip_tx_clk_o is a forwarded copy of clk_sys.  The receiver samples
# chip_tx_valid_o and chip_tx_data_o[7:0] against this forwarded clock.
create_generated_clock -name chip_tx_clk \
  -source [get_ports $TOP_CLK_SYS_PORT] \
  -divide_by 1 \
  [get_ports chip_tx_clk_o]

set_output_delay -clock [get_clocks chip_tx_clk] -max $TOP_DDR_OUTPUT_MAX_NS \
  [get_ports {chip_tx_valid_o chip_tx_data_o[*]}]
set_output_delay -clock [get_clocks chip_tx_clk] -min $TOP_DDR_OUTPUT_MIN_NS \
  [get_ports {chip_tx_valid_o chip_tx_data_o[*]}]

# -----------------------------------------------------------------------------
# 3. Synchronous input/output budgets
# -----------------------------------------------------------------------------
set TOP_ASYNC_INPUTS [get_ports {
  async_rst_n
  i2c_scl_i
  i2c_sda_i
  spad_x_event_async_i
  spad_y_event_async_i
  spad_z_event_async_i
  cal_x_start_async_i
  cal_x_stop_async_i
  cal_y_start_async_i
  cal_y_stop_async_i
  cal_z_start_async_i
  cal_z_stop_async_i
  x_lines_i[*]
  y_lines_i[*]
  z_lines_i[*]
}]

set TOP_CLOCK_PORTS [get_ports [list $TOP_CLK_SYS_PORT $TOP_CLK_REF_PORT]]
set TOP_SYNC_INPUTS [remove_from_collection [all_inputs] \
  [add_to_collection $TOP_CLOCK_PORTS $TOP_ASYNC_INPUTS]]

set_input_delay -clock [get_clocks clk_sys] $TOP_INPUT_DELAY_NS $TOP_SYNC_INPUTS
set_output_delay -clock [get_clocks clk_sys] $TOP_OUTPUT_DELAY_NS \
  [remove_from_collection [all_outputs] [get_ports {chip_tx_clk_o chip_tx_valid_o chip_tx_data_o[*]}]]

set_input_transition $TOP_INPUT_TRANSITION_NS $TOP_SYNC_INPUTS
set_load $TOP_OUTPUT_LOAD_PF [all_outputs]

# -----------------------------------------------------------------------------
# 4. Async sources and reset
# -----------------------------------------------------------------------------
# These paths enter explicit synchronizers, async frontends, latch-based
# measurement structures, or settle filters.  Do not use this section to hide
# normal synchronous timing.
set_false_path -from $TOP_ASYNC_INPUTS
set_false_path -from [get_ports $TOP_RST_PORT]

# clk_ref_40m is used only by the STOP qualifier.  If the final PLL makes
# clk_sys and clk_ref_40m phase-related and the implementation wants to time that
# logic synchronously, replace this async grouping with explicit constraints.
set_clock_groups -asynchronous \
  -group [get_clocks clk_sys] \
  -group [get_clocks clk_ref_40m]

# -----------------------------------------------------------------------------
# 5. Synchronizer and CDC structure preservation
# -----------------------------------------------------------------------------
# Tool syntax varies between Genus/DC versions; keep these as best-effort guards
# and check the synthesis log for missed patterns.
foreach pattern {
  *u_rst_sync*sync_q*
  *x_sync_ff1_q*
  *x_sync_ff2_q*
  *y_sync_ff1_q*
  *y_sync_ff2_q*
  *z_sync_ff1_q*
  *z_sync_ff2_q*
  *ctx_drain_sync_ff*
  *rejected_sync_pipe*
  *start_sync_pipe*
} {
  set cells [get_cells -quiet -hierarchical $pattern]
  if {[llength $cells] > 0} {
    catch {set_dont_touch $cells true}
  }
}

# -----------------------------------------------------------------------------
# 6. Placeholder macro signoff hooks
# -----------------------------------------------------------------------------
# TODO: After PLL integration:
# - replace primary input clocks with PLL generated clocks if clk_sys/clk_ref_40m
#   are no longer top-level timing sources.
# - add PLL lock/reset constraints and generated clock uncertainty.
#
# TODO: After SPAD matrix integration:
# - replace broad async line false paths with the final SPAD output contract.
# - time/load spad_matrix_rst_o against the matrix reset input and verify the
#   one-clk_sys pulse width meets the analog/matrix recovery requirement.
# - add max event rate / settle requirements to the verification plan.
#
# TODO: After MPTDC oscillator macro integration:
# - add generated clocks for slow/fast oscillator tap 0 and phase taps inside
#   each axis-local mptdc_top_asic.
# - bind PD matrix exceptions to the physical symmetry/matching constraints.
# - review all MPTDC async/static CDC waivers against the final macro netlist.
