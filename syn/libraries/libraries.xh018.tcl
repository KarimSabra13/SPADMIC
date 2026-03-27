# =============================================================================
# Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
# File     : libraries.xh018.tcl
# Purpose  : XFAB XH018 (180 nm) PDK technology definitions
# Author   : Karim Sabra
# =============================================================================
# INSTRUCTIONS:
#   1. Set paths(PDK_ROOT) to your XFAB XH018 installation
#   2. Update METAL_STACK and TRACKS for your specific variant
#   3. Set QRC tech file paths if available
#
# This file defines technology-level settings (process node, metal stack,
# parasitic extraction, routing layers). Standard cell library definitions
# are in a separate file (libraries.xh018-stdcells.tcl).
# =============================================================================

#############################################
#       Process / Metal Stack
#############################################
set METAL_STACK "1P6M"                ;# XFAB XH018 — 1 poly, 6 metal layers
set TRACKS      "12T"                 ;# Standard cell track height
set_db design_process_node 180        ;# 180 nm process node

#############################################
#       PDK Root Path (EDIT THIS)
#############################################
set paths(PDK_ROOT) "/path/to/xfab/XH018"

#############################################
#       Technology Files
#############################################
set paths(TECHNOLOGY_FILES) "$paths(PDK_ROOT)/techdata"

# Technology LEF (layer and via definitions)
set tech_files(TECHNOLOGY_LEF) "$paths(TECHNOLOGY_FILES)/xh018_xx.tlef"
    set tech_files(ALL_LEFS) [list $tech_files(TECHNOLOGY_LEF)]

#############################################
#       Parasitic Extraction (QRC)
#############################################
# Uncomment and set when QRC tech files are available
# set paths(QRC_ROOT)          "$paths(PDK_ROOT)/qrc"
# set tech_files(QRCTECH_BC)   "$paths(QRC_ROOT)/rcbest/qrcTechFile"
# set tech_files(QRCTECH_TC)   "$paths(QRC_ROOT)/typical/qrcTechFile"
# set tech_files(QRCTECH_WC)   "$paths(QRC_ROOT)/rcworst/qrcTechFile"

#############################################
#       PVT Corners (Temperature)
#############################################
set tech(TEMPERATURE_BC)  -40    ;# Best case (fast)
set tech(TEMPERATURE_TC)   25    ;# Typical
set tech(TEMPERATURE_WC)  125    ;# Worst case (slow)

#############################################
#       Physical Design Constants
#############################################
# Layer names (XFAB XH018 1P6M stack)
set tech(layer_names) "M1 M2 M3 M4 M5 M6"

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
set tech(cts_top_routing_layer_top)   "M6"
set tech(cts_bottom_routing_layer_top) "M5"
set tech(cts_top_routing_layer_trunk)  "M6"
set tech(cts_bottom_routing_layer_trunk) "M5"
set tech(cts_top_routing_layer_leaf)   "M4"
set tech(cts_bottom_routing_layer_leaf) "M3"

#############################################
#       Message Suppression
#############################################
set tech(LEF_SUPPRESS_MESSAGES_GENUS)   [list]
set tech(LIB_SUPPRESS_MESSAGES_GENUS)   [list]
set tech(LEF_SUPPRESS_MESSAGES_INNOVUS) [list]
set tech(LIB_SUPPRESS_MESSAGES_INNOVUS) [list]
