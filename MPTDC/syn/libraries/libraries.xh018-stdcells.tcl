# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : libraries.xh018-stdcells.tcl
# Purpose  : XFAB XH018 standard cell library definitions (Liberty, LEF, Verilog)
# Author   : Karim Sabra
# =============================================================================
# INSTRUCTIONS:
#   1. Defaults below target the verified lab-server D_CELLS_HD v6.0 install
#   2. Override with environment variables when needed:
#        MPTDC_STDCELL_FAMILY -> HD or JIHD
#        SC_ROOT              -> full standard-cell library root
#        MPTDC_STDCELL_LEF    -> explicit standard-cell LEF
#        MPTDC_STDCELL_*_LIB  -> explicit BC/TC/WC Liberty files
#   3. Verify the .lib file names if your PDK revision differs
#   4. Update SDC driving/load pin details only when enabling set_driving_cell
#
# This file defines the standard cell library paths for all PVT corners
# (BC/TC/WC). The technology-level settings (process, metal stack) are
# in libraries.xh018.tcl.
# =============================================================================

#############################################
#       Standard Cell Root
#############################################
set mptdc_stdcell_family "HD"
if {[info exists ::env(MPTDC_STDCELL_FAMILY)] && $::env(MPTDC_STDCELL_FAMILY) ne ""} {
    set mptdc_stdcell_family [string toupper $::env(MPTDC_STDCELL_FAMILY)]
} elseif {[info exists ::env(SC_ROOT)] && [string match -nocase "*D_CELLS_JIHD*" $::env(SC_ROOT)]} {
    set mptdc_stdcell_family "JIHD"
}

switch -- $mptdc_stdcell_family {
    HD {
        set mptdc_stdcell_lib_name "D_CELLS_HD"
        set mptdc_stdcell_default_lef_rel "LEF/v6_0_0/xh018_D_CELLS_HD.lef"
        set mptdc_stdcell_default_site "core_hd"
    }
    JIHD {
        set mptdc_stdcell_lib_name "D_CELLS_JIHD"
        set mptdc_stdcell_default_lef_rel "LEF/v6_0_0/xh018/xh018_D_CELLS_JIHD.lef"
        set mptdc_stdcell_default_site "core_jihd"
    }
    default {
        error "Unsupported MPTDC_STDCELL_FAMILY=$mptdc_stdcell_family; expected HD or JIHD"
    }
}

if {[info exists ::env(SC_ROOT)] && $::env(SC_ROOT) ne ""} {
    set paths(SC_ROOT) $::env(SC_ROOT)
} else {
    set paths(SC_ROOT) "$paths(PDK_ROOT)/diglibs/$mptdc_stdcell_lib_name/v6_0"
}
set paths(STDCELL_FAMILY) $mptdc_stdcell_family
set tech(STANDARD_CELL_FAMILY) $mptdc_stdcell_family
set tech(STANDARD_CELL_LIBRARY) $mptdc_stdcell_lib_name

#############################################
#       LEF (Library Exchange Format)
#############################################
if {[info exists ::env(MPTDC_STDCELL_LEF)] && $::env(MPTDC_STDCELL_LEF) ne ""} {
    set tech_files(STDCELLS_LEF) $::env(MPTDC_STDCELL_LEF)
} else {
    set tech_files(STDCELLS_LEF) "$paths(SC_ROOT)/$mptdc_stdcell_default_lef_rel"
}
lappend tech_files(ALL_LEFS) $tech_files(STDCELLS_LEF)

#############################################
#       Standard Cell Site
#############################################
if {[info exists ::env(MPTDC_STDCELL_SITE)] && $::env(MPTDC_STDCELL_SITE) ne ""} {
    set tech(STANDARD_CELL_SITE) $::env(MPTDC_STDCELL_SITE)
} else {
    set tech(STANDARD_CELL_SITE) $mptdc_stdcell_default_site
}
set tech(STANDARD_CELL_VDD)  "VDD"
set tech(STANDARD_CELL_GND)  "VSS"
# Lab Innovus/Voltus reports power-level names as lower-case for this library,
# while top-level rails remain VDD/VSS. Use the LEF-visible lower-case PG pin
# names so globalNetConnect does not emit false errors for absent VDD/VSS pins.
set tech(STANDARD_CELL_VDD_PINS) [list vdd]
set tech(STANDARD_CELL_GND_PINS) [list gnd]

#############################################
#       Liberty Timing Libraries (.lib)
#############################################
# Verified XFAB XH018 naming convention:
#   D_CELLS_<family>_LPMOS_typ_1_80V_25C.lib   (typical: 1.8V, 25°C)
#   D_CELLS_<family>_LPMOS_slow_1_62V_125C.lib (worst case: 1.62V, 125°C)
#   D_CELLS_<family>_LPMOS_fast_1_98V_m40C.lib (best case: 1.98V, -40°C)

set paths(LIB_DIR) "$paths(SC_ROOT)/liberty_LPMOS/v6_0_0/PVT_1_80V_range"
set mptdc_stdcell_lib_prefix "${mptdc_stdcell_lib_name}_LPMOS"

# ── Typical Corner (TT, 1.80V, 25°C) ──────────────────────────────
if {[info exists ::env(MPTDC_STDCELL_TC_LIB)] && $::env(MPTDC_STDCELL_TC_LIB) ne ""} {
    set tech_files(STDCELLS_TC_LIB) $::env(MPTDC_STDCELL_TC_LIB)
} else {
    set tech_files(STDCELLS_TC_LIB) "$paths(LIB_DIR)/${mptdc_stdcell_lib_prefix}_typ_1_80V_25C.lib"
}
set tech_files(ALL_TC_LIBS) [list $tech_files(STDCELLS_TC_LIB)]

# ── Worst Case (SS, 1.62V, 125°C) ─────────────────────────────────
if {[info exists ::env(MPTDC_STDCELL_WC_LIB)] && $::env(MPTDC_STDCELL_WC_LIB) ne ""} {
    set tech_files(STDCELLS_WC_LIB) $::env(MPTDC_STDCELL_WC_LIB)
} else {
    set tech_files(STDCELLS_WC_LIB) "$paths(LIB_DIR)/${mptdc_stdcell_lib_prefix}_slow_1_62V_125C.lib"
}
set tech_files(ALL_WC_LIBS) [list $tech_files(STDCELLS_WC_LIB)]

# ── Best Case (FF, 1.98V, −40°C) ──────────────────────────────────
if {[info exists ::env(MPTDC_STDCELL_BC_LIB)] && $::env(MPTDC_STDCELL_BC_LIB) ne ""} {
    set tech_files(STDCELLS_BC_LIB) $::env(MPTDC_STDCELL_BC_LIB)
} else {
    set tech_files(STDCELLS_BC_LIB) "$paths(LIB_DIR)/${mptdc_stdcell_lib_prefix}_fast_1_98V_m40C.lib"
}
set tech_files(ALL_BC_LIBS) [list $tech_files(STDCELLS_BC_LIB)]

puts "MPTDC_LIB_INFO: standard-cell family=$tech(STANDARD_CELL_FAMILY) library=$tech(STANDARD_CELL_LIBRARY)"
puts "MPTDC_LIB_INFO: standard-cell root=$paths(SC_ROOT)"
puts "MPTDC_LIB_INFO: standard-cell LEF=$tech_files(STDCELLS_LEF)"
puts "MPTDC_LIB_INFO: standard-cell TC Liberty=$tech_files(STDCELLS_TC_LIB)"

#############################################
#       Provisional MPTDC Analog Macros
#############################################
# These black-box Liberty views provide only cell/pin shells for early Genus and
# Innovus planning. Final characterized oscillator macro Liberty must replace or
# augment this file before signoff timing is claimed on macro internals.
set tech_files(MPTDC_OSC_BB_LIB) "$design(project_root)/syn/macros/mptdc_osc_blackbox.lib"
if {[file exists $tech_files(MPTDC_OSC_BB_LIB)]} {
    lappend tech_files(ALL_TC_LIBS) $tech_files(MPTDC_OSC_BB_LIB)
    lappend tech_files(ALL_WC_LIBS) $tech_files(MPTDC_OSC_BB_LIB)
    lappend tech_files(ALL_BC_LIBS) $tech_files(MPTDC_OSC_BB_LIB)
}

set mptdc_enable_provisional_osc_liberty 0
if {[info exists ::env(MPTDC_OSC_PD_USE_PROVISIONAL)] && $::env(MPTDC_OSC_PD_USE_PROVISIONAL)} {
    set mptdc_enable_provisional_osc_liberty 1
}
if {[info exists ::env(MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY)] && $::env(MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY)} {
    set mptdc_enable_provisional_osc_liberty 1
}

if {$mptdc_enable_provisional_osc_liberty} {
    foreach key_file [list \
        [list MPTDC_OSC_SLOW_PROVISIONAL_LIB "$design(project_root)/syn/macros/mptdc_osc_slow_provisional.lib"] \
        [list MPTDC_OSC_FAST_PROVISIONAL_LIB "$design(project_root)/syn/macros/mptdc_osc_fast_provisional.lib"] \
    ] {
        set key [lindex $key_file 0]
        set lib_file [lindex $key_file 1]
        set tech_files($key) $lib_file
        if {[file exists $lib_file]} {
            lappend tech_files(ALL_TC_LIBS) $lib_file
            lappend tech_files(ALL_WC_LIBS) $lib_file
            lappend tech_files(ALL_BC_LIBS) $lib_file
            puts "MPTDC_LIB_INFO: enabling provisional oscillator Liberty $lib_file"
        } else {
            puts "MPTDC_LIB_WARN: requested provisional oscillator Liberty missing: $lib_file"
        }
    }
}

# Optional real/characterized oscillator Liberty.  O1 normally uses the
# provisional Liberty shell with real LEF until analog timing/electrical views
# are delivered; this hook lets the lab server select a real Liberty without
# editing the flow scripts.
if {[info exists ::env(O1_RO_LIBERTY_PATH)] && $::env(O1_RO_LIBERTY_PATH) ne ""} {
    set tech_files(O1_RO_TUNE4_REAL_LIB) $::env(O1_RO_LIBERTY_PATH)
    if {[file exists $tech_files(O1_RO_TUNE4_REAL_LIB)]} {
        lappend tech_files(ALL_TC_LIBS) $tech_files(O1_RO_TUNE4_REAL_LIB)
        lappend tech_files(ALL_WC_LIBS) $tech_files(O1_RO_TUNE4_REAL_LIB)
        lappend tech_files(ALL_BC_LIBS) $tech_files(O1_RO_TUNE4_REAL_LIB)
        puts "MPTDC_LIB_INFO: enabling O1 real RO_tune4 Liberty $tech_files(O1_RO_TUNE4_REAL_LIB)"
    } else {
        puts "MPTDC_LIB_WARN: O1_RO_LIBERTY_PATH does not exist: $tech_files(O1_RO_TUNE4_REAL_LIB)"
    }
}

#############################################
#       Behavioural Verilog (for GLS)
#############################################
# set tech_files(STDCELLS_VERILOG) "$paths(SC_ROOT)/verilog/D_CELLS_HD.v"

#############################################
#       SDC Driving / Load Cells
#############################################
# For set_driving_cell and set_load in SDC constraints.
# Use a mid-sized buffer from your standard cell library.
# Verified lab-server buffer cell: BUHDX4
# SDC_LOAD_PIN is not currently consumed because set_driving_cell remains
# commented out in syn/inputs/mptdc.sdc.
set tech(SDC_DRIVING_CELL)  "BUHDX4"     ;# Cell name for set_driving_cell
set tech(SDC_LOAD_PIN)      ""           ;# Fill in when enabling set_driving_cell
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
