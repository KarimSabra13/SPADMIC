# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : genus_setup.tcl
# Purpose  : Cadence Genus — library setup and design configuration
# Author   : Karim Sabra
# =============================================================================
# Target   : XFAB XH018 (180 nm), typical corner (1.8V, 25°C)
#
# INSTRUCTIONS:
#   1. Set XFAB_PDK_ROOT to your XFAB installation path
#   2. Set the library names to match your specific XH018 kit
#   3. Run from syn/scripts/ directory:
#      $ cd syn/scripts && genus -files genus_setup.tcl
#   Or source interactively in Genus shell:
#      genus> source genus_setup.tcl
# =============================================================================

puts "================================================================"
puts " MPTDC Synthesis — Step 1: Library & Design Setup"
puts "================================================================"

# ─────────────────────────────────────────────────────────────────────────────
# 1. XFAB PDK PATHS (PLACEHOLDER — EDIT THESE)
# ─────────────────────────────────────────────────────────────────────────────
# Set this to the root of your XFAB XH018 PDK installation
set XFAB_PDK_ROOT "/path/to/xfab/XH018"

# Liberty timing libraries (.lib) — typical corner
# Common XFAB XH018 library names:
#   D_CELLS_HD  — High-density standard cells
#   D_CELLS_LP  — Low-power standard cells
#   IO_CELLS    — I/O pad cells
set LIB_TYPICAL "${XFAB_PDK_ROOT}/diglibs/D_CELLS_HD/v3_0/liberty_LPMOS/v3_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib"

# LEF (Library Exchange Format) for physical info
set LEF_FILE "${XFAB_PDK_ROOT}/diglibs/D_CELLS_HD/v3_0/lef/v3_0_0/xh018_D_CELLS_HD.lef"

# Technology LEF (layer definitions)
set TECH_LEF "${XFAB_PDK_ROOT}/techdata/xh018_xx.tlef"

# ─────────────────────────────────────────────────────────────────────────────
# 2. PROJECT PATHS
# ─────────────────────────────────────────────────────────────────────────────
set PROJ_ROOT    [file normalize [file join [pwd] "../.."]]
set SYN_ROOT     [file normalize [file join [pwd] ".."]]
set RTL_ROOT     "${PROJ_ROOT}/rtl"
set WORK_DIR     "${SYN_ROOT}/work"
set OUTPUT_DIR   "${SYN_ROOT}/outputs"
set REPORT_DIR   "${SYN_ROOT}/reports"
set LOG_DIR      "${SYN_ROOT}/logs"
set CONSTR_DIR   "${SYN_ROOT}/constraints"

# Create output directories if they don't exist
file mkdir $WORK_DIR
file mkdir $OUTPUT_DIR
file mkdir $REPORT_DIR
file mkdir $LOG_DIR

# ─────────────────────────────────────────────────────────────────────────────
# 3. GENUS CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
# Design name
set DESIGN_NAME "mptdc_top_asic"

# Set working directory for Genus internal files
set_db init_lib_search_path [list \
    [file dirname $LIB_TYPICAL] \
    [file dirname $LEF_FILE] \
    [file dirname $TECH_LEF] \
]

# ─────────────────────────────────────────────────────────────────────────────
# 4. READ LIBERTY LIBRARIES
# ─────────────────────────────────────────────────────────────────────────────
puts "  Reading Liberty library: [file tail $LIB_TYPICAL]"
read_libs $LIB_TYPICAL

# Read LEF for physical info (optional for logic synthesis, needed for PnR)
# Uncomment when LEF files are available:
# read_physical -lef [list $TECH_LEF $LEF_FILE]

# ─────────────────────────────────────────────────────────────────────────────
# 5. GENUS GLOBAL SETTINGS
# ─────────────────────────────────────────────────────────────────────────────
# Allow latch inference (required for async frontend SR latches)
set_db hdl_error_on_latch false

# Treat all undriven signals as 0 (safe for synthesis)
set_db hdl_undriven_signal_value 0

# Enable SystemVerilog support
set_db hdl_sv_packages true

# Auto-ungroup small hierarchies for better optimization
set_db auto_ungroup_min_num_instances 4

# Prevent SRAM inference — force all memories to flip-flops
# (No SRAM IP available for this design)
set_db syn_global_effort medium

puts "  Library setup complete."
puts "  Design: $DESIGN_NAME"
puts "  Technology: XFAB XH018 (180 nm)"
puts "================================================================"
puts " Next step: source genus_elaborate.tcl"
puts "================================================================"
