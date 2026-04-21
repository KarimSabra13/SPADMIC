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
# Layer names (default 4-metal HD stack)
set tech(layer_names) "M1 M2 M3 M4"

# Standard cell dimensions
set tech(row_height)  7.56        ;# µm — XH018 standard cell height
set tech(grid_unit)   0.18        ;# µm — placement grid (half-pitch)

#############################################
#       Physical Cells (EDIT FOR YOUR LIB)
#############################################
# These are placeholders — fill in from your XFAB standard cell documentation
set tech(WELLTAP)          ""     ;# Well-tap cell name
set tech(WELLTAP_RULE)     30.0   ;# µm — max distance between well taps
set tech(TIEHI)            ""     ;# Tie-high cell
set tech(TIELO)            ""     ;# Tie-low cell
set tech(TIE_MAX_FANOUT)   20
set tech(TIE_MAX_DISTANCE) 30.0   ;# µm
set tech(FILLERS)          ""     ;# Filler cells (widest to narrowest)
set tech(DECAP)            ""     ;# Decap cells (widest to narrowest)
set tech(ANTENNA_DIODE)    ""     ;# Antenna diode cell
set tech(ENDCAPS_right)    ""     ;# Right endcap cell
set tech(ENDCAPS_left)     ""     ;# Left endcap cell

#############################################
#       CTS Routing Layers
#############################################
set tech(cts_top_routing_layer_top)     "M4"
set tech(cts_bottom_routing_layer_top)  "M3"
set tech(cts_top_routing_layer_trunk)   "M4"
set tech(cts_bottom_routing_layer_trunk) "M3"
set tech(cts_top_routing_layer_leaf)    "M3"
set tech(cts_bottom_routing_layer_leaf) "M2"

#############################################
#       Message Suppression
#############################################
set tech(LEF_SUPPRESS_MESSAGES_GENUS)   [list]
set tech(LIB_SUPPRESS_MESSAGES_GENUS)   [list]
set tech(LEF_SUPPRESS_MESSAGES_INNOVUS) [list]
set tech(LIB_SUPPRESS_MESSAGES_INNOVUS) [list]
