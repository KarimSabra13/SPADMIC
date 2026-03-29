# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : libraries.xh018-stdcells.tcl
# Purpose  : XFAB XH018 standard cell library definitions (Liberty, LEF, Verilog)
# Author   : Karim Sabra
# =============================================================================
# INSTRUCTIONS:
#   1. Set paths(SC_ROOT) to your XFAB standard cell installation
#   2. Update the .lib file names for each PVT corner
#   3. Update the LEF file name
#   4. Set SDC driving cell and load pin names
#
# This file defines the standard cell library paths for all PVT corners
# (BC/TC/WC). The technology-level settings (process, metal stack) are
# in libraries.xh018.tcl.
# =============================================================================

#############################################
#       Standard Cell Root (EDIT THIS)
#############################################
set paths(SC_ROOT) "$paths(PDK_ROOT)/diglibs/D_CELLS_HD/v3_0"

#############################################
#       LEF (Library Exchange Format)
#############################################
set tech_files(STDCELLS_LEF) "$paths(SC_ROOT)/lef/v3_0_0/xh018_D_CELLS_HD.lef"
lappend tech_files(ALL_LEFS) $tech_files(STDCELLS_LEF)

#############################################
#       Standard Cell Site
#############################################
set tech(STANDARD_CELL_SITE) "xh018_HD"   ;# LEF SITE name (check your LEF)
set tech(STANDARD_CELL_VDD)  "VDD"
set tech(STANDARD_CELL_GND)  "VSS"

#############################################
#       Liberty Timing Libraries (.lib)
#############################################
# XFAB XH018 D_CELLS_HD naming convention (typical example):
#   D_CELLS_HD_LPMOS_typ_1_80V_25C.lib   (typical: 1.8V, 25°C)
#   D_CELLS_HD_LPMOS_slow_1_62V_125C.lib (worst case: 1.62V, 125°C)
#   D_CELLS_HD_LPMOS_fast_1_98V_m40C.lib (best case: 1.98V, -40°C)

set paths(LIB_DIR) "$paths(SC_ROOT)/liberty_LPMOS/v3_0_0/PVT_1_80V_range"

# ── Typical Corner (TT, 1.80V, 25°C) ──────────────────────────────
set tech_files(STDCELLS_TC_LIB) "$paths(LIB_DIR)/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib"
set tech_files(ALL_TC_LIBS) [list $tech_files(STDCELLS_TC_LIB)]

# ── Worst Case (SS, 1.62V, 125°C) ─────────────────────────────────
set tech_files(STDCELLS_WC_LIB) "$paths(LIB_DIR)/D_CELLS_HD_LPMOS_slow_1_62V_125C.lib"
set tech_files(ALL_WC_LIBS) [list $tech_files(STDCELLS_WC_LIB)]

# ── Best Case (FF, 1.98V, −40°C) ──────────────────────────────────
set tech_files(STDCELLS_BC_LIB) "$paths(LIB_DIR)/D_CELLS_HD_LPMOS_fast_1_98V_m40C.lib"
set tech_files(ALL_BC_LIBS) [list $tech_files(STDCELLS_BC_LIB)]

#############################################
#       Behavioural Verilog (for GLS)
#############################################
# set tech_files(STDCELLS_VERILOG) "$paths(SC_ROOT)/verilog/D_CELLS_HD.v"

#############################################
#       SDC Driving / Load Cells
#############################################
# For set_driving_cell and set_load in SDC constraints.
# Use a mid-sized buffer from your standard cell library.
# Example: BUFX4 (4× drive strength buffer)
set tech(SDC_DRIVING_CELL)  "BUFX4"      ;# Cell name for set_driving_cell
set tech(SDC_LOAD_PIN)      "BUFX4/A"    ;# Pin for capacitance-based load
set tech(EXTERNAL_SDC_LOAD) 0.05         ;# pF — external load if FULLCHIP

#############################################
#       Clock Cells (for CTS / CCOpt)
#############################################
# Fill from your XFAB standard cell documentation
set tech(CLOCK_BUFFERS)   ""   ;# e.g., "CLKBUFX2 CLKBUFX4 CLKBUFX8"
set tech(CLOCK_INVERTERS) ""   ;# e.g., "CLKINVX2 CLKINVX4 CLKINVX8"
set tech(CLOCK_GATES)     ""   ;# e.g., "TLATNCAX2"
set tech(CLOCK_LOGIC)     ""
set tech(CLOCK_DELAYS)    ""

#############################################
#       Message Suppression
#############################################
# Add library-specific messages to suppress after reviewing them
# lappend tech(LIB_SUPPRESS_MESSAGES_GENUS) "WSDF-196"
# lappend tech(LEF_SUPPRESS_MESSAGES_GENUS) "LEFPARS-2001"
