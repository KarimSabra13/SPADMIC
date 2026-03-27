# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : genus_synthesize.tcl
# Purpose  : Cadence Genus — synthesis, mapping, and optimization
# Author   : Karim Sabra
# =============================================================================
# Prerequisites: genus_setup.tcl and genus_elaborate.tcl must be sourced.
#
# This script performs the three-phase Genus synthesis flow:
#   Phase 1 (syn_generic)   — Technology-independent optimization
#   Phase 2 (syn_map)       — Map to XFAB XH018 standard cells
#   Phase 3 (syn_opt)       — Incremental timing/area optimization
#
# After synthesis, writes out:
#   - Gate-level netlist (Verilog)
#   - Updated SDC constraints
#   - SDF timing annotation (for gate-level simulation)
# =============================================================================

puts "================================================================"
puts " MPTDC Synthesis — Step 3: Synthesize & Optimize"
puts "================================================================"

# ─────────────────────────────────────────────────────────────────────────────
# 1. SYNTHESIS — PHASE 1: GENERIC (TECHNOLOGY-INDEPENDENT)
# ─────────────────────────────────────────────────────────────────────────────
# syn_generic performs:
#   - Boolean optimization (constant propagation, dead logic removal)
#   - Resource sharing (shared adders, muxes)
#   - FSM encoding optimization
#   - Arithmetic optimization
# This phase works with generic gates (AND, OR, MUX, FF, LATCH) before
# mapping to any specific technology library.

puts "  Phase 1: Generic optimization ..."
syn_generic
puts "  Generic optimization complete."

# Intermediate timing check (optional — catch gross violations early)
report_timing -max_paths 5 > "${REPORT_DIR}/timing_post_generic.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 2. SYNTHESIS — PHASE 2: TECHNOLOGY MAPPING
# ─────────────────────────────────────────────────────────────────────────────
# syn_map performs:
#   - Maps generic gates to XFAB XH018 standard cells
#   - Selects cell variants (drive strength, threshold voltage)
#   - Considers timing, area, and power objectives
#   - Handles special cells (clock buffers, scan flops if DFT enabled)

puts "  Phase 2: Technology mapping to XFAB XH018 ..."
syn_map
puts "  Technology mapping complete."

# Intermediate timing check
report_timing -max_paths 5 > "${REPORT_DIR}/timing_post_map.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 3. SYNTHESIS — PHASE 3: INCREMENTAL OPTIMIZATION
# ─────────────────────────────────────────────────────────────────────────────
# syn_opt performs:
#   - Gate sizing (upsizing critical path cells, downsizing non-critical)
#   - Buffer insertion / removal
#   - Logic restructuring on critical paths
#   - Hold time fixing (insert delay buffers)
#   - Power optimization (clock gating, Vt swapping if multi-Vt library)

puts "  Phase 3: Incremental optimization ..."
syn_opt
puts "  Optimization complete."

# ─────────────────────────────────────────────────────────────────────────────
# 4. WRITE OUTPUTS
# ─────────────────────────────────────────────────────────────────────────────

# Gate-level netlist (Verilog)
puts "  Writing gate-level netlist ..."
write_hdl > "${OUTPUT_DIR}/${DESIGN_NAME}_synth.v"
puts "  Netlist: ${OUTPUT_DIR}/${DESIGN_NAME}_synth.v"

# Mapped SDC (constraints with actual cell names)
puts "  Writing mapped SDC ..."
write_sdc > "${OUTPUT_DIR}/${DESIGN_NAME}_synth.sdc"
puts "  SDC: ${OUTPUT_DIR}/${DESIGN_NAME}_synth.sdc"

# SDF (Standard Delay Format) for gate-level simulation
puts "  Writing SDF ..."
write_sdf > "${OUTPUT_DIR}/${DESIGN_NAME}_synth.sdf"
puts "  SDF: ${OUTPUT_DIR}/${DESIGN_NAME}_synth.sdf"

# Design database (Genus binary format for incremental runs)
puts "  Writing design database ..."
write_db -to_file "${OUTPUT_DIR}/${DESIGN_NAME}.genus_db"
puts "  DB: ${OUTPUT_DIR}/${DESIGN_NAME}.genus_db"

puts "================================================================"
puts " Synthesis complete."
puts " Outputs written to: ${OUTPUT_DIR}/"
puts "================================================================"
puts " Next step: source genus_reports.tcl"
puts "================================================================"
