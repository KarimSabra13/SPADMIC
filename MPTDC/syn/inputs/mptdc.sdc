# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : mptdc.sdc
# Purpose  : Synopsys Design Constraints for Cadence Genus synthesis
# Author   : Karim Sabra
# =============================================================================
# Target   : XFAB XH018 (180 nm)
# Clocks   : clk_sys 160 MHz, osc_slow ~1 GHz, osc_fast ~1.11 GHz
#
# This SDC uses variables from mptdc.defines (loaded before this file).
# All numeric values come from the design() array for single-source-of-truth.
# =============================================================================

# Genus/DC compatibility helpers. Some SDC subcommands/options used for
# exploratory synthesis are not uniformly supported across tool versions.
proc mptdc_try_dont_touch {pattern} {
    set cells [get_cells -quiet -hierarchical $pattern]
    if {[llength $cells] > 0} {
        catch {set_dont_touch $cells true}
    }
}

proc mptdc_try_async_max_delay {delay from_obj to_obj} {
    # Genus 22.13 on the lab server rejects -datapath_only in SDC mode.
    set_max_delay $delay -from $from_obj -to $to_obj
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. PRIMARY CLOCK
# ─────────────────────────────────────────────────────────────────────────────
# System clock: 160 MHz, 6.25 ns period, 50% duty cycle
foreach cname $design(clock_list) cport $design(clock_port_list) cperiod $design(clock_period_list) {
    create_clock -period $cperiod -name $cname [get_ports $cport]
    set_clock_uncertainty $design(CLOCK_UNCERTAINTY) $cname
    set_clock_transition  $design(CLOCK_TRANSITION)  [get_clocks $cname]
}

# During synthesis, treat clock and reset networks as ideal
# (CTS will add real buffers later)
if {$runtype == "synthesis"} {
    set_ideal_network [get_ports $design(clock_port_list)]
    set_ideal_network [get_ports $design(RST_PORT)]
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. OSCILLATOR CLOCKS (VIRTUAL)
# ─────────────────────────────────────────────────────────────────────────────
# Analog oscillator macros provide these clocks in the real chip.  Until the
# macro LEFs are available, the implementation stub exposes non-constant phase
# pins so oscillator-domain structure stays present for physical planning.

create_clock -name $design(OSC_SLOW_NAME) -period $design(OSC_SLOW_PERIOD) \
    [get_pins $design(OSC_SLOW_PIN)] -add

create_clock -name $design(OSC_FAST_NAME) -period $design(OSC_FAST_PERIOD) \
    [get_pins $design(OSC_FAST_PIN)] -add

set_clock_uncertainty $design(OSC_CLOCK_UNCERTAINTY) [get_clocks $design(OSC_SLOW_NAME)]
set_clock_uncertainty $design(OSC_CLOCK_UNCERTAINTY) [get_clocks $design(OSC_FAST_NAME)]

# ─────────────────────────────────────────────────────────────────────────────
# 3. CLOCK DOMAIN CROSSING — ASYNC GROUPS
# ─────────────────────────────────────────────────────────────────────────────
# All three clocks are asynchronous. CDC is handled structurally by
# gray_cnt_sync, pulse_sync, and reset_sync modules.

set_clock_groups -asynchronous \
    -group [get_clocks $design(CLK_NAME)] \
    -group [get_clocks $design(OSC_SLOW_NAME)] \
    -group [get_clocks $design(OSC_FAST_NAME)]

# ─────────────────────────────────────────────────────────────────────────────
# 4. ASYNCHRONOUS INPUTS — FALSE PATHS
# ─────────────────────────────────────────────────────────────────────────────
# START/STOP are truly async pulses from SPAD detectors or calibration.
# The async_frontend captures them with SR latches — no setup/hold.

foreach port $design(ASYNC_INPUTS) {
    set_false_path -from [get_ports $port]
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. ASYNCHRONOUS RESET — FALSE PATH
# ─────────────────────────────────────────────────────────────────────────────
# async_rst_n asserts immediately (gate delay) and deasserts through
# reset synchronizers in each clock domain.

set_false_path -from [get_ports $design(RST_PORT)]

# ─────────────────────────────────────────────────────────────────────────────
# 6. CDC SYNCHRONIZER PROTECTION
# ─────────────────────────────────────────────────────────────────────────────
# Protect 2-FF synchronizer chains from optimization.
# These flops are metastability barriers — must not be merged or retimed.

mptdc_try_dont_touch *u_rst_sync*/sync_q_reg*
mptdc_try_dont_touch *u_rst_*_sync*/sync_q_reg*
mptdc_try_dont_touch *u_rst*sync*sync_q*
mptdc_try_dont_touch *u_rst*sync*sync_q_reg*
mptdc_try_dont_touch *gray_cont_ff1*
mptdc_try_dont_touch *gray_cont_ff2*
mptdc_try_dont_touch *gray_snap_ff1*
mptdc_try_dont_touch *gray_snap_ff2*
mptdc_try_dont_touch *u_pulse_sync*/sync_ff1*
mptdc_try_dont_touch *u_pulse_sync*/sync_ff2*
mptdc_try_dont_touch *ctx_drain_sync_ff*
mptdc_try_dont_touch *gen_pd_row*gen_pd_col*u_pd*

# ─────────────────────────────────────────────────────────────────────────────
# 7. CDC MAX DELAY
# ─────────────────────────────────────────────────────────────────────────────
# Limit combinational delay between source flop and first synchronizer flop
# to one destination clock period, ensuring metastability resolution.

# osc → sys (max 1 sys_clk period)
mptdc_try_async_max_delay \
    $design(CLK_PERIOD) \
    [get_clocks $design(OSC_SLOW_NAME)] \
    [get_clocks $design(CLK_NAME)]

mptdc_try_async_max_delay \
    $design(CLK_PERIOD) \
    [get_clocks $design(OSC_FAST_NAME)] \
    [get_clocks $design(CLK_NAME)]

# sys → osc_fast (max 1 fast period)
mptdc_try_async_max_delay \
    $design(OSC_FAST_PERIOD) \
    [get_clocks $design(CLK_NAME)] \
    [get_clocks $design(OSC_FAST_NAME)]

# ─────────────────────────────────────────────────────────────────────────────
# 8. INPUT DELAYS
# ─────────────────────────────────────────────────────────────────────────────
# CSR / ready / override inputs are synchronous to clk_sys.
set timed_inputs [remove_from_collection \
    [all_inputs] \
    [get_ports [concat $design(clock_port_list) $design(ASYNC_INPUTS) [list $design(RST_PORT)]]]]
set async_inputs_and_reset [get_ports [concat $design(ASYNC_INPUTS) [list $design(RST_PORT)]]]

if {$design(FULLCHIP_OR_MACRO) == "FULLCHIP"} {
    set_input_delay -clock $design(CLK_NAME) $design(INPUT_DELAY_FULLCHIP) $timed_inputs
} else {
    set_input_delay -clock $design(CLK_NAME) $design(INPUT_DELAY_MACRO) $timed_inputs
}

# ─────────────────────────────────────────────────────────────────────────────
# 9. OUTPUT DELAYS
# ─────────────────────────────────────────────────────────────────────────────
if {$design(FULLCHIP_OR_MACRO) == "FULLCHIP"} {
    set_output_delay -clock $design(CLK_NAME) $design(OUTPUT_DELAY_FULLCHIP) [all_outputs]
} else {
    set_output_delay -clock $design(CLK_NAME) $design(OUTPUT_DELAY_MACRO) [all_outputs]
}

# ─────────────────────────────────────────────────────────────────────────────
# 10. LOAD AND DRIVE
# ─────────────────────────────────────────────────────────────────────────────
if {$design(FULLCHIP_OR_MACRO) == "FULLCHIP"} {
    set_load $design(OUTPUT_LOAD_FULLCHIP) [all_outputs]
} else {
    set_load $design(OUTPUT_LOAD_MACRO) [all_outputs]
}
set_input_transition $design(INPUT_TRANSITION) $timed_inputs
# Async inputs are false-pathed, but still model a non-zero source slew so
# check_timing_intent does not assume ideal zero-transition sources.
set_input_transition $design(INPUT_TRANSITION) $async_inputs_and_reset

# Use library driving cell if available (otherwise generic transition)
# Uncomment when SDC_DRIVING_CELL is set to an actual cell name:
# set_driving_cell -lib_cell $tech(SDC_DRIVING_CELL) [all_inputs]

# ─────────────────────────────────────────────────────────────────────────────
# 11. DESIGN RULES
# ─────────────────────────────────────────────────────────────────────────────
set_max_fanout     $design(MAX_FANOUT)     [current_design]
set_max_transition $design(MAX_TRANSITION) [current_design]

# Reset leaf nets are intentionally distributed hierarchically in RTL. Normal
# clk_sys consumers use these as synchronous reset controls; keep their
# implementation bounded so PnR does not recreate one slow high-fanout spine.
foreach reset_pattern {
    *rst_*_n*
    *rst_n_o*
    *rst_sys_*_n*
} {
    set reset_nets [get_nets -quiet -hierarchical $reset_pattern]
    if {[llength $reset_nets] > 0} {
        catch {set_max_fanout $design(RESET_MAX_FANOUT) $reset_nets}
        catch {set_max_transition $design(RESET_MAX_TRANSITION) $reset_nets}
    }
}
