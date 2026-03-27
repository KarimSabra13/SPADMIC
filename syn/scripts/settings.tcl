# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : settings.tcl
# Purpose  : General Genus synthesis settings
# Author   : Karim Sabra
# =============================================================================
# This file contains tool-level configuration that is NOT design-specific.
# Design-specific settings belong in inputs/mptdc.defines.
# =============================================================================

#############################################
#       Genus HDL Settings
#############################################
set_db source_verbose true                ;# Report sourced files in log

# SystemVerilog support
set_db hdl_language sv                    ;# Default language: SystemVerilog

# Latch handling — allow intentional latches (async frontend)
set_db hdl_error_on_latch false

# Undriven signals default to 0 (safe for synthesis)
set_db hdl_undriven_signal_value 0

# Detailed SDC parsing messages (helps debug constraint issues)
set_db detailed_sdc_messages true

#############################################
#       Memory Inference
#############################################
# Force ALL memories to flip-flop implementation.
# No SRAM IP is available for this design — the sync FIFO
# (57-bit × 64-entry) will be implemented entirely as registers.
set_db syn_ramstyle registers

#############################################
#       Clock Gating
#############################################
# Enable clock gating insertion for power reduction.
# Minimum 8 flip-flops to justify a clock gate cell.
set_db lp_insert_clock_gating true

#############################################
#       Synthesis Effort
#############################################
# Trial synthesis — use medium effort for reasonable runtime.
# For final tapeout, increase to high/extreme.
set_db syn_generic_effort  medium         ;# low|medium|high|express
set_db syn_map_effort      medium         ;# low|medium|high
set_db syn_opt_effort      medium         ;# low|medium|high|extreme
set_db design_power_effort high           ;# none|low|high

#############################################
#       Verbosity
#############################################
set_db information_level 7                ;# 1 (quiet) to 9 (verbose)

mptdc_message "Genus settings loaded (medium effort, ramstyle=registers)"
