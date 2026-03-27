# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : genus_elaborate.tcl
# Purpose  : Cadence Genus — read HDL, elaborate, and lint check
# Author   : Karim Sabra
# =============================================================================
# Prerequisites: genus_setup.tcl must be sourced first.
#
# This script:
#   1. Reads all RTL files (SystemVerilog) from the synthesis filelist
#   2. Elaborates the top-level design (mptdc_top_asic)
#   3. Runs design lint checks to catch issues before synthesis
#   4. Reports any latches, loops, or unresolved references
# =============================================================================

puts "================================================================"
puts " MPTDC Synthesis — Step 2: Elaborate & Lint"
puts "================================================================"

# ─────────────────────────────────────────────────────────────────────────────
# 1. READ HDL SOURCES
# ─────────────────────────────────────────────────────────────────────────────
# Read from the synthesis-specific filelist which:
#   - Excludes mptdc_osc_model.sv (non-synthesizable behavioural oscillator)
#   - Includes +define+SYNTHESIS to activate synthesis guards
#   - Lists files in correct compile order (package first, top last)
puts "  Reading RTL from filelist_synth.f ..."
read_hdl -sv -f "${SYN_ROOT}/filelist_synth.f"

# ─────────────────────────────────────────────────────────────────────────────
# 2. ELABORATE
# ─────────────────────────────────────────────────────────────────────────────
# Elaborate resolves all parameters, generates generate blocks, and builds
# the internal design representation. This is where parameter-check $fatal
# statements fire if any parameter is invalid.
puts "  Elaborating ${DESIGN_NAME} ..."
elaborate $DESIGN_NAME

# Set the elaborated design as current
set_top_module $DESIGN_NAME

# ─────────────────────────────────────────────────────────────────────────────
# 3. FORCE REGISTER-BASED MEMORY (NO SRAM)
# ─────────────────────────────────────────────────────────────────────────────
# The sync_fifo uses a 57-bit × 64-entry array. Without an SRAM IP,
# we force Genus to implement it as flip-flops instead of trying to
# infer an SRAM macro.
set_db [get_db insts -if {.base_cell.name == "mptdc_sync_fifo"}] .force_mem_impl registers
# Fallback: set globally if the above doesn't match
set_db syn_ramstyle registers

puts "  Memory inference set to REGISTERS (no SRAM IP available)"

# ─────────────────────────────────────────────────────────────────────────────
# 4. READ TIMING CONSTRAINTS
# ─────────────────────────────────────────────────────────────────────────────
puts "  Reading SDC constraints ..."
read_sdc "${CONSTR_DIR}/mptdc.sdc"

# ─────────────────────────────────────────────────────────────────────────────
# 5. DESIGN CHECKS (LINT)
# ─────────────────────────────────────────────────────────────────────────────
# check_design identifies common issues:
#   - Undriven / unloaded ports
#   - Combinational loops
#   - Multi-driven nets
#   - Missing constraints
#   - Unexpected latch inferences

puts "  Running design checks ..."
check_design -all > "${REPORT_DIR}/check_design.rpt"
puts "  Design check report: ${REPORT_DIR}/check_design.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 6. LATCH REPORT
# ─────────────────────────────────────────────────────────────────────────────
# We expect exactly 4+ intentional latches from mptdc_async_frontend_v2:
#   - start_latched_q     (SR latch: START capture)
#   - stop_latched_q      (SR latch: STOP capture)
#   - active_ctx_q        (transparent latch: context ID)
#   - ctx_drain_q[0:1]    (SR latches: per-context drain, N_CTX=2)
#
# Any additional latches are bugs and must be investigated.

puts "  Reporting inferred latches ..."
report_gates -type latch > "${REPORT_DIR}/latch_report.rpt"
puts "  Latch report: ${REPORT_DIR}/latch_report.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 7. HIERARCHY REPORT
# ─────────────────────────────────────────────────────────────────────────────
puts "  Reporting design hierarchy ..."
report_hierarchy > "${REPORT_DIR}/hierarchy.rpt"
puts "  Hierarchy report: ${REPORT_DIR}/hierarchy.rpt"

puts "================================================================"
puts " Elaboration complete."
puts " Review reports in: ${REPORT_DIR}/"
puts " Expected: 5+ latches (async_frontend), 0 combinational loops"
puts "================================================================"
puts " Next step: source genus_synthesize.tcl"
puts "================================================================"
