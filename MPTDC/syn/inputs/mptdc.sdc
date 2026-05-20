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

proc mptdc_try_false_path_pins {label patterns} {
    set matched [list]
    foreach pattern $patterns {
        set pins [get_pins -quiet -hierarchical $pattern]
        if {[llength $pins] > 0} {
            set matched [concat $matched $pins]
        }
    }

    if {[llength $matched] == 0} {
        puts "MPTDC_SDC_WARN: no pins matched for $label"
        return
    }

    puts "MPTDC_SDC_INFO: false-pathing $label ([llength $matched] pins)"
    if {[catch {set_false_path -to $matched} err]} {
        puts "MPTDC_SDC_WARN: set_false_path -to failed for $label: $err"
    }
    if {[catch {set_false_path -through $matched} err]} {
        puts "MPTDC_SDC_WARN: set_false_path -through failed for $label: $err"
    }
}

proc mptdc_try_set_max_delay_pins {label delay from_patterns to_patterns} {
    set from_pins [list]
    set to_pins [list]
    foreach pattern $from_patterns {
        set pins [get_pins -quiet -hierarchical $pattern]
        if {[llength $pins] > 0} {
            set from_pins [concat $from_pins $pins]
        }
    }
    foreach pattern $to_patterns {
        set pins [get_pins -quiet -hierarchical $pattern]
        if {[llength $pins] > 0} {
            set to_pins [concat $to_pins $pins]
        }
    }

    if {[llength $from_pins] == 0 || [llength $to_pins] == 0} {
        puts "MPTDC_SDC_WARN: max-delay pins not found for $label"
        return
    }

    puts "MPTDC_SDC_INFO: max-delaying $label from [llength $from_pins] pin(s) to [llength $to_pins] pin(s)"
    if {[catch {set_max_delay $delay -from $from_pins -to $to_pins} err]} {
        puts "MPTDC_SDC_WARN: set_max_delay failed for $label: $err"
    }
}

proc mptdc_create_osc_tap_clocks {base_name period tap_step tap_pins} {
    set created [list]
    set tap_idx 0

    foreach tap_pin $tap_pins {
        set pins [get_pins -quiet $tap_pin]
        if {[llength $pins] == 0} {
            puts "MPTDC_SDC_WARN: oscillator tap pin not found: $tap_pin"
            incr tap_idx
            continue
        }

        if {$tap_idx == 0} {
            set clk_name $base_name
        } else {
            set clk_name "${base_name}_tap${tap_idx}"
        }

        set rise [expr {$tap_idx * $tap_step}]
        set fall [expr {$rise + ($period / 2.0)}]
        if {$fall >= $period} {
            set fall [expr {$fall - $period}]
        }

        create_clock -name $clk_name -period $period \
            -waveform [list $rise $fall] $pins
        lappend created $clk_name
        incr tap_idx
    }

    return $created
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
# 2. OSCILLATOR TAP CLOCKS (PRE-LIBERTY BLACK-BOX CONTRACT)
# ─────────────────────────────────────────────────────────────────────────────
# The final analog macros are planned as:
#   slow/north: start_i, ctrl_i[7:0], phase_o[7:0], vdd/gnd
#   fast/south: stop_i,  ctrl_i[7:0], phase_o[7:0], vdd/gnd
# Until LEF/Liberty are available, the implementation stub pins are the clock
# boundary contract.  Model every tap explicitly so PD sampling clock coverage is
# reviewable and phase-mesh timing does not collapse to phase[0] only.

set design(OSC_SLOW_CLOCKS) [mptdc_create_osc_tap_clocks \
    $design(OSC_SLOW_NAME) \
    $design(OSC_SLOW_PERIOD) \
    $design(OSC_SLOW_TAP_STEP) \
    $design(OSC_SLOW_TAP_PINS)]

set design(OSC_FAST_CLOCKS) [mptdc_create_osc_tap_clocks \
    $design(OSC_FAST_NAME) \
    $design(OSC_FAST_PERIOD) \
    $design(OSC_FAST_TAP_STEP) \
    $design(OSC_FAST_TAP_PINS)]

set design(OSC_ALL_CLOCKS) [concat $design(OSC_SLOW_CLOCKS) $design(OSC_FAST_CLOCKS)]

if {[llength $design(OSC_SLOW_CLOCKS)] == 0 || [llength $design(OSC_FAST_CLOCKS)] == 0} {
    puts "MPTDC_SDC_WARN: one or both oscillator tap-clock groups are empty"
}

foreach osc_clk $design(OSC_ALL_CLOCKS) {
    set_clock_uncertainty -setup $design(OSC_CLOCK_UNCERTAINTY_SETUP) [get_clocks $osc_clk]
    set_clock_uncertainty -hold  $design(OSC_CLOCK_UNCERTAINTY_HOLD)  [get_clocks $osc_clk]
    set_clock_transition  $design(CLOCK_TRANSITION) [get_clocks $osc_clk]
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. CLOCK DOMAIN CROSSING — ASYNC GROUPS
# ─────────────────────────────────────────────────────────────────────────────
# All three clocks are asynchronous. CDC is handled structurally by
# gray_cnt_sync, pulse_sync, and reset_sync modules.
# The oscillator enable pins are asynchronous macro controls, not synchronous
# clock-gate paths. This clock grouping is therefore intentional, but every
# functional crossing between these groups must remain covered by the CDC audit.

set_clock_groups -asynchronous \
    -group [get_clocks $design(CLK_NAME)] \
    -group [get_clocks $design(OSC_SLOW_CLOCKS)] \
    -group [get_clocks $design(OSC_FAST_CLOCKS)]

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

# PD cell conversion clear is an intentional asynchronous clear. It is asserted
# only during conversion teardown/oscillator idle, so recovery/removal checks
# against active fast tap clocks are not a valid synchronous timing objective.
mptdc_try_false_path_pins "PD conversion clear pins" {
    *gen_pd_row*gen_pd_col*u_pd*/clear_window
    *gen_pd_row*gen_pd_col*u_pd*/clear_window_i
    *u_pd*/clear_window
    *u_pd*/clear_window_i
}

# Gray-counter async clears are intentional hard clears for source-domain
# counter state when oscillator clocks may be stopped. The protocol clears only
# after the held image has been sampled/committed, so recovery/removal on these
# async clear pins is not a meaningful synchronous timing objective.
mptdc_try_false_path_pins "Gray counter async clear pins" {
    *u_slow_cnt*/src_async_clr
    *u_fast_cnt*/src_async_clr
    *gray_cnt_sync*/src_async_clr
}

# START-watchdog state lives in the slow oscillator domain and is intentionally
# hard-cleared by sys-domain teardown so the counter can reset even if the
# oscillator stops. Match both common RTL flop names and likely library clear pin
# names as a best-effort SDC-mode guard; review matched pins in the Genus log.
mptdc_try_false_path_pins "START watchdog async clear pins" {
    *start_wdt_cnt*/*CLR*
    *start_wdt_cnt*/*clr*
    *start_wdt_cnt*/*CD*
    *start_wdt_cnt*/*RN*
    *start_timeout_latched*/*CLR*
    *start_timeout_latched*/*clr*
    *start_timeout_latched*/*CD*
    *start_timeout_latched*/*RN*
}

# STOP metadata capture flops are intentionally clocked by the asynchronous STOP
# event and sample the held slow-ring phase image.  These are source-side event
# flops, not synchronous slow-clock endpoints; do not time setup from oscillator
# tap clocks into their data pins.  The sampled levels are later consumed through
# the clk_sys static-bus handshake in mptdc_hit_capture_bridge.
mptdc_try_false_path_pins "STOP metadata async capture data pins" {
    *u_stop_capture*/phase0_snap_o_reg*/D
    *u_stop_capture*/phase7d_snap_o_reg*/D
    *u_stop_capture*/slow_boundary_inc_o_reg*/D
    *u_stop_capture*/stop_slow_phase_disc_o_reg*/D
    *u_stop_capture*/stop_slow_phase_disc_o_reg*/*D*
}

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
mptdc_try_dont_touch *start_sync_pipe*
mptdc_try_dont_touch *stop_sync_pipe*
mptdc_try_dont_touch *start_timeout_sync_pipe*
mptdc_try_dont_touch *start_timeout_latched*
mptdc_try_dont_touch *start_rejected_pending*
mptdc_try_dont_touch *rejected_sync_pipe*
mptdc_try_dont_touch *u_stop_capture*phase0_snap_o*
mptdc_try_dont_touch *u_stop_capture*phase7d_snap_o*
mptdc_try_dont_touch *u_stop_capture*slow_boundary_inc_o*
mptdc_try_dont_touch *u_stop_capture*stop_slow_phase_disc_o*
# PD hierarchy preservation is handled by the Genus flow procedure, where the
# tool can distinguish elaborated hierarchy from leaf timing objects.  Avoid a
# broad SDC-level dont_touch on partially mapped hierarchy because Genus logs it
# as an SDC failure and makes constraint health ambiguous.

# ─────────────────────────────────────────────────────────────────────────────
# 7. CDC MAX DELAY
# ─────────────────────────────────────────────────────────────────────────────
# Limit combinational delay between source flop and first synchronizer flop
# to one destination clock period, ensuring metastability resolution.

# osc → sys (max 1 sys_clk period)
mptdc_try_async_max_delay \
    $design(CLK_PERIOD) \
    [get_clocks $design(OSC_SLOW_CLOCKS)] \
    [get_clocks $design(CLK_NAME)]

mptdc_try_async_max_delay \
    $design(CLK_PERIOD) \
    [get_clocks $design(OSC_FAST_CLOCKS)] \
    [get_clocks $design(CLK_NAME)]

# sys → osc_fast (max 1 fast period)
mptdc_try_async_max_delay \
    $design(OSC_FAST_PERIOD) \
    [get_clocks $design(CLK_NAME)] \
    [get_clocks $design(OSC_FAST_CLOCKS)]

# STOP metadata static bus: after STOP capture, these level outputs remain held
# until pd_clear. Bound route delay into the clk_sys snapshot flops so physical
# implementation keeps all STOP metadata bits co-located with the existing
# phase0/slow-boundary path. This is not a new independent CDC synchronizer.
mptdc_try_set_max_delay_pins \
    "STOP metadata static bus into clk_sys snapshot" \
    $design(CLK_PERIOD) \
    {
        *u_stop_capture*/phase0_snap_o_reg*/Q
        *u_stop_capture*/slow_boundary_inc_o_reg*/Q
        *u_stop_capture*/stop_slow_phase_disc_o_reg*/Q
        *u_stop_capture*/stop_slow_phase_disc_o_reg*/*Q*
    } \
    {
        *u_hit_capture_bridge*/snapshot_q_reg*/D
        *u_hit_capture_bridge*/snapshot_q_reg*/*D*
    }

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
if {[catch {set_max_fanout $design(MAX_FANOUT) [current_design]} err]} {
    puts "MPTDC_SDC_WARN: set_max_fanout current_design failed: $err"
}
if {[catch {set_max_transition $design(MAX_TRANSITION) [current_design]} err]} {
    puts "MPTDC_SDC_WARN: set_max_transition current_design failed: $err"
}

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
