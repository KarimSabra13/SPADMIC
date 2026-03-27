# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : genus_reports.tcl
# Purpose  : Cadence Genus — comprehensive post-synthesis reports
# Author   : Karim Sabra
# =============================================================================
# Prerequisites: genus_synthesize.tcl must be sourced first.
#
# Generates all reports needed to evaluate synthesis quality:
#   - Timing (setup, hold, critical paths)
#   - Area (total, per-module breakdown)
#   - Power (dynamic, leakage, per-module)
#   - Gate count and cell usage statistics
#   - Latch audit (verify only intentional latches)
#   - Clock tree summary
#   - Design rule violations
# =============================================================================

puts "================================================================"
puts " MPTDC Synthesis — Step 4: Post-Synthesis Reports"
puts "================================================================"

# ─────────────────────────────────────────────────────────────────────────────
# 1. TIMING REPORTS
# ─────────────────────────────────────────────────────────────────────────────

# Setup timing — worst 20 paths across all clock domains
puts "  Generating timing reports ..."
report_timing -max_paths 20 -late > "${REPORT_DIR}/timing_setup.rpt"

# Hold timing — worst 20 paths
report_timing -max_paths 20 -early > "${REPORT_DIR}/timing_hold.rpt"

# Per-clock-domain timing summary
report_timing -summary > "${REPORT_DIR}/timing_summary.rpt"

# Timing histogram (distribution of path slack)
report_timing -slack_lesser_than 0.0 > "${REPORT_DIR}/timing_violations.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 2. AREA REPORTS
# ─────────────────────────────────────────────────────────────────────────────
puts "  Generating area reports ..."

# Total area summary
report_area > "${REPORT_DIR}/area_summary.rpt"

# Per-module area breakdown
report_area -detail > "${REPORT_DIR}/area_detail.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 3. POWER REPORTS
# ─────────────────────────────────────────────────────────────────────────────
puts "  Generating power reports ..."

# Total power (dynamic + leakage)
report_power > "${REPORT_DIR}/power_summary.rpt"

# Per-module power breakdown
report_power -detail > "${REPORT_DIR}/power_detail.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 4. GATE COUNT AND CELL USAGE
# ─────────────────────────────────────────────────────────────────────────────
puts "  Generating gate reports ..."

# Total gate count and cell statistics
report_gates > "${REPORT_DIR}/gates_summary.rpt"

# Cell usage by type (which std cells are used and how many)
report_gates -type all > "${REPORT_DIR}/gates_by_type.rpt"

# Sequential elements (FFs, latches)
report_gates -type seq > "${REPORT_DIR}/gates_sequential.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 5. LATCH AUDIT
# ─────────────────────────────────────────────────────────────────────────────
# CRITICAL CHECK: The design should have ONLY intentional latches from
# mptdc_async_frontend_v2. Any additional latches indicate RTL issues.
#
# Expected latches (5 total for N_CTX=2):
#   1. start_latched_q      — START capture SR latch
#   2. stop_latched_q       — STOP capture SR latch
#   3. active_ctx_q[1:0]    — Context ID transparent latch
#   4. ctx_drain_q[0]       — Context 0 drain SR latch
#   5. ctx_drain_q[1]       — Context 1 drain SR latch

puts "  Latch audit ..."
report_gates -type latch > "${REPORT_DIR}/latch_audit.rpt"
puts "  *** REVIEW latch_audit.rpt — expect exactly 5 latches ***"

# ─────────────────────────────────────────────────────────────────────────────
# 6. CLOCK REPORT
# ─────────────────────────────────────────────────────────────────────────────
puts "  Generating clock reports ..."
report_clocks > "${REPORT_DIR}/clock_summary.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 7. DESIGN RULE VIOLATIONS
# ─────────────────────────────────────────────────────────────────────────────
puts "  Checking design rule violations ..."
report_design_rules > "${REPORT_DIR}/drv_summary.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 8. CONSTRAINT COVERAGE
# ─────────────────────────────────────────────────────────────────────────────
puts "  Checking constraint coverage ..."
report_constraints > "${REPORT_DIR}/constraint_coverage.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# 9. QOR SUMMARY (QUALITY OF RESULTS)
# ─────────────────────────────────────────────────────────────────────────────
puts "  Generating QoR summary ..."
report_qor > "${REPORT_DIR}/qor_summary.rpt"

# ─────────────────────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
puts ""
puts "================================================================"
puts " ALL REPORTS GENERATED"
puts "================================================================"
puts " Reports directory: ${REPORT_DIR}/"
puts ""
puts " KEY REPORTS TO REVIEW:"
puts "   1. timing_violations.rpt  — Any negative slack? (MUST be empty)"
puts "   2. latch_audit.rpt        — Expect exactly 5 latches"
puts "   3. area_summary.rpt       — Total area estimate"
puts "   4. power_summary.rpt      — Power budget check"
puts "   5. qor_summary.rpt        — Overall quality metrics"
puts "   6. drv_summary.rpt        — Design rule violations"
puts ""
puts " TRIAL SYNTHESIS CHECKLIST:"
puts "   [ ] No timing violations in timing_violations.rpt"
puts "   [ ] Only 5 intentional latches in latch_audit.rpt"
puts "   [ ] Area fits within budget"
puts "   [ ] No critical DRV violations"
puts "   [ ] Gate count reasonable for 180 nm"
puts "================================================================"
