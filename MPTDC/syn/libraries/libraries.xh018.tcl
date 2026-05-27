# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : libraries.xh018.tcl
# Purpose  : XFAB XH018 (180 nm) PDK technology definitions
# Author   : Karim Sabra
# =============================================================================
# INSTRUCTIONS:
#   1. Defaults below target the verified lab-server XFAB XH018 install
#      under /data/pdk/xfab/xh018
#   2. Override with environment variables when needed:
#        PDK_ROOT       -> full XH018 root
#        TECHNOLOGY_LEF -> explicit technology LEF file
#   3. Update METAL_STACK / routing layers only if your metal option differs
#   4. Set QRC tech file paths if available
#
# This file defines technology-level settings (process node, metal stack,
# parasitic extraction, routing layers). Standard cell library definitions
# are in a separate file (libraries.xh018-stdcells.tcl).
# =============================================================================

#############################################
#       Process / Metal Stack
#############################################
set METAL_STACK "1P4M"                ;# Verified lab flow: 4-metal HD option
set TRACKS      "12T"                 ;# Metadata only; not consumed by current Genus flow
set_db design_process_node 180        ;# 180 nm process node

#############################################
#       PDK Root Path
#############################################
if {[info exists ::env(PDK_ROOT)]} {
    set paths(PDK_ROOT) $::env(PDK_ROOT)
} else {
    set paths(PDK_ROOT) "/data/pdk/xfab/xh018"
}

#############################################
#       Technology Files
#############################################
set paths(TECH_LEF_DIR) "$paths(PDK_ROOT)/cadence/v9_0/techLEF/v9_0_1"

# Technology LEF (layer and via definitions). The current checked-in default
# matches the 4-metal HD lab flow. Override TECHNOLOGY_LEF for another option.
if {[info exists ::env(TECHNOLOGY_LEF)]} {
    set tech_files(TECHNOLOGY_LEF) $::env(TECHNOLOGY_LEF)
} else {
    set tech_files(TECHNOLOGY_LEF) \
        "$paths(TECH_LEF_DIR)/xh018_xx41_HD_MET4_METMID.lef"
}
set tech_files(ALL_LEFS) [list $tech_files(TECHNOLOGY_LEF)]

# Provisional MPTDC oscillator black-box abstracts. These are intentionally
# checked-in placeholders for early Genus/Innovus planning until the custom
# analog oscillator team delivers final LEF/Liberty views.
set tech_files(MPTDC_OSC_LEF) "$design(project_root)/syn/macros/mptdc_osc_blackbox.lef"
if {[file exists $tech_files(MPTDC_OSC_LEF)]} {
    lappend tech_files(ALL_LEFS) $tech_files(MPTDC_OSC_LEF)
}

# O0 oscillator/PD signoff track: optional provisional macro abstracts generated
# from MPTDC/analog_handoff/*.  These are not enabled by default because the
# current RTL still uses a synthesizable oscillator stub; O0 server scripts opt
# in so the tool logs show exactly which non-final views were loaded.
if {[info exists ::env(MPTDC_OSC_PD_USE_PROVISIONAL)] && $::env(MPTDC_OSC_PD_USE_PROVISIONAL)} {
    foreach key_file [list \
        [list MPTDC_OSC_SLOW_PROVISIONAL_LEF "$design(project_root)/syn/macros/mptdc_osc_slow_provisional.lef"] \
        [list MPTDC_OSC_FAST_PROVISIONAL_LEF "$design(project_root)/syn/macros/mptdc_osc_fast_provisional.lef"] \
    ] {
        set key [lindex $key_file 0]
        set lef_file [lindex $key_file 1]
        set tech_files($key) $lef_file
        if {[file exists $lef_file]} {
            lappend tech_files(ALL_LEFS) $lef_file
            puts "MPTDC_LIB_INFO: enabling provisional oscillator LEF $lef_file"
        } else {
            puts "MPTDC_LIB_WARN: requested provisional oscillator LEF missing: $lef_file"
        }
    }
}

#############################################
#       Parasitic Extraction (QRC)
#############################################
# Defaults target the verified lab-server XH018 deck matching:
#   xh018_xx41_HD_MET4_METMID.lef  ->  XH018_1141 QRC family
if {[info exists ::env(QRC_ROOT)]} {
    set paths(QRC_ROOT) $::env(QRC_ROOT)
} else {
    set paths(QRC_ROOT) \
        "$paths(PDK_ROOT)/cadence/v10_1/QRC_pvs/v10_1_1/XH018_1141"
}

if {[info exists ::env(CAPTABLE_DIR)]} {
    set paths(CAPTABLE_DIR) $::env(CAPTABLE_DIR)
} else {
    set paths(CAPTABLE_DIR) "$paths(PDK_ROOT)/cadence/v9_0/capTbl/v9_0_1"
}

if {[info exists ::env(QRCTECH_BC)]} {
    set tech_files(QRCTECH_BC) $::env(QRCTECH_BC)
} else {
    set tech_files(QRCTECH_BC) "$paths(QRC_ROOT)/QRC-Min/qrcTechFile"
}
if {[info exists ::env(QRCTECH_TC)]} {
    set tech_files(QRCTECH_TC) $::env(QRCTECH_TC)
} else {
    set tech_files(QRCTECH_TC) "$paths(QRC_ROOT)/QRC-Typ/qrcTechFile"
}
if {[info exists ::env(QRCTECH_WC)]} {
    set tech_files(QRCTECH_WC) $::env(QRCTECH_WC)
} else {
    set tech_files(QRCTECH_WC) "$paths(QRC_ROOT)/QRC-Max/qrcTechFile"
}

set tech_files(CAPTABLE_BC) "$paths(CAPTABLE_DIR)/xh018_xx41_MET4_METMID_min.capTbl"
set tech_files(CAPTABLE_TC) "$paths(CAPTABLE_DIR)/xh018_xx41_MET4_METMID_typ.capTbl"
set tech_files(CAPTABLE_WC) "$paths(CAPTABLE_DIR)/xh018_xx41_MET4_METMID_max.capTbl"

set tech(HAS_QRC_TECH) 1
foreach qrc_file [list \
    $tech_files(QRCTECH_BC) \
    $tech_files(QRCTECH_TC) \
    $tech_files(QRCTECH_WC)] {
    if {![file exists $qrc_file]} {
        set tech(HAS_QRC_TECH) 0
    }
}

#############################################
#       PVT Corners (Temperature)
#############################################
set tech(TEMPERATURE_BC)  -40    ;# Best case (fast)
set tech(TEMPERATURE_TC)   25    ;# Typical
set tech(TEMPERATURE_WC)  125    ;# Worst case (slow)

#############################################
#       Physical Design Constants
#############################################
# Layer names (default XH018 4-metal HD stack). The lab LEF names the usable
# metals MET1/MET2/MET3/METTP; METTP is the top/thick metal reserved primarily
# for power distribution in the estimation flow.
set tech(layer_names) "MET1 MET2 MET3 METTP"

# Standard cell dimensions
set tech(row_height)  7.56        ;# µm — XH018 standard cell height
set tech(grid_unit)   0.18        ;# µm — placement grid (half-pitch)

#############################################
#       Physical Cells (EDIT FOR YOUR LIB)
#############################################
# These are placeholders unless explicitly filled from XFAB documentation.
set tech(WELLTAP)          ""     ;# Well-tap cell name
set tech(WELLTAP_RULE)     30.0   ;# µm — max distance between well taps
set tech(TIEHI)            ""     ;# Tie-high cell
set tech(TIELO)            ""     ;# Tie-low cell
set tech(TIE_MAX_FANOUT)   20
set tech(TIE_MAX_DISTANCE) 30.0   ;# µm
set tech(FILLERS)          "FEED2HD FEED1HD" ;# Filler cells (widest to narrowest)
set tech(DECAP)            "DECAP25HD DECAP15HD DECAP10HD DECAP7HD DECAP5HD DECAP3HD"
set tech(PD_DECAP)         "DECAP25HD DECAP15HD"
set tech(ANTENNA_DIODE)    ""     ;# Antenna diode cell
set tech(ENDCAPS_right)    ""     ;# Right endcap cell
set tech(ENDCAPS_left)     ""     ;# Left endcap cell

#############################################
#       MPTDC Analog Oscillator Macro Pins
#############################################
set tech(OSC_SLOW_MACRO)      "MPTDC_OSC_SLOW_BB"
set tech(OSC_FAST_MACRO)      "MPTDC_OSC_FAST_BB"
if {[info exists ::env(MPTDC_OSC_PD_USE_PROVISIONAL)] && $::env(MPTDC_OSC_PD_USE_PROVISIONAL)} {
    set tech(OSC_SLOW_MACRO_PROVISIONAL) "MPTDC_OSC_SLOW_PROVISIONAL"
    set tech(OSC_FAST_MACRO_PROVISIONAL) "MPTDC_OSC_FAST_PROVISIONAL"
}
set tech(OSC_VDD)             "VDDA"
set tech(OSC_GND)             "VSSA"
set tech(OSC_VDD_PINS)        [list VDDA]
set tech(OSC_GND_PINS)        [list VSSA]
set tech(OSC_CTRL_PINS)       [list {ctrl_i[0]} {ctrl_i[1]} {ctrl_i[2]} {ctrl_i[3]} {ctrl_i[4]} {ctrl_i[5]} {ctrl_i[6]} {ctrl_i[7]}]
set tech(OSC_PHASE_PINS)      [list {phase_o[0]} {phase_o[1]} {phase_o[2]} {phase_o[3]} {phase_o[4]} {phase_o[5]} {phase_o[6]} {phase_o[7]}]
set tech(OSC_SLOW_ENABLE_PIN) "start_i"
set tech(OSC_FAST_ENABLE_PIN) "stop_i"

#############################################
#       CTS Routing Layers
#############################################
set tech(cts_top_routing_layer_top)     "METTP"
set tech(cts_bottom_routing_layer_top)  "MET3"
set tech(cts_top_routing_layer_trunk)   "METTP"
set tech(cts_bottom_routing_layer_trunk) "MET3"
set tech(cts_top_routing_layer_leaf)    "MET3"
set tech(cts_bottom_routing_layer_leaf) "MET2"

#############################################
#       Message Suppression
#############################################
set tech(LEF_SUPPRESS_MESSAGES_GENUS)   [list]
set tech(LIB_SUPPRESS_MESSAGES_GENUS)   [list]
set tech(LEF_SUPPRESS_MESSAGES_INNOVUS) [list]
set tech(LIB_SUPPRESS_MESSAGES_INNOVUS) [list]
