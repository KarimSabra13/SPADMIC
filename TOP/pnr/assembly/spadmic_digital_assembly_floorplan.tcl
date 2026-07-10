# Phase-A floorplan application. The generated assembly_config.tcl is the only
# source of dimensions, origins, and orientations.

proc spadmic_da_place_fixed_instance {record} {
    lassign $record instance cell x y orient
    set found [dbGet -p top.insts.name $instance]
    if {$found eq "0x0" || $found eq ""} {
        error "SPADMIC_DA_INSTANCE_NOT_FOUND: $instance cell=$cell"
    }
    if {[catch {placeInstance $instance $x $y $orient -fixed} err]} {
        if {[catch {placeInstance $instance $x $y $orient} fallback_err]} {
            error "SPADMIC_DA_PLACE_FAILED: $instance primary=$err fallback=$fallback_err"
        }
        dbSet [dbGet -p top.insts.name $instance].pStatus fixed
    }
    set object [dbGet -p top.insts.name $instance]
    set actual_cell [dbGet $object.cell.name]
    if {$actual_cell ne $cell} {
        error "SPADMIC_DA_CELL_MISMATCH: $instance actual=$actual_cell expected=$cell"
    }
}

proc spadmic_da_apply_floorplan {} {
    if {![info exists ::SPADMIC_DA_DIE] || ![info exists ::SPADMIC_DA_INSTANCES]} {
        error "SPADMIC_DA_CONFIG_NOT_SOURCED"
    }
    lassign $::SPADMIC_DA_DIE llx lly urx ury
    set width [expr {$urx - $llx}]
    set height [expr {$ury - $lly}]
    set site core
    if {[info exists ::tech(STANDARD_CELL_SITE)]} {
        set site $::tech(STANDARD_CELL_SITE)
    }
    if {[catch {floorPlan -site $site -s $width $height 0 0 0 0} err]} {
        if {[catch {floorPlan -s $width $height 0 0 0 0} fallback_err]} {
            error "SPADMIC_DA_FLOORPLAN_FAILED: primary=$err fallback=$fallback_err"
        }
    }
    foreach record $::SPADMIC_DA_INSTANCES {
        spadmic_da_place_fixed_instance $record
    }
}
