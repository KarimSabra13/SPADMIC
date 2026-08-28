##############################################################################################################
#####  
#####                                         PVS LVS COMPARISON
#####  
#####  Version                       :   22.22-s005
#####  NVN Run Start                 :   Fri Aug 28 09:03:47 2026
#####  ERC Summary File              :   result.sum
#####  Extraction Report File        :   mptdc_axis_core_lvs.sum
#####  Comparison Report File        :   mptdc_axis_core_lvs.sum.cls
#####  Top Cell                      :   mptdc_axis_core  <vs>  mptdc_axis_core
#####  
#####                                :      @     @
#####                                :       @   @ 
#####                                :        @ @  
#####  Run Result                    :     MISMATCH
#####                                :        @ @  
#####                                :       @   @ 
#####                                :      @     @
#####  
#####  Run Summary                   :   [ERROR] Connectivity Mismatches
#####                                :   [INFO]  ERC Results: Empty
#####                                :   [INFO]  Extraction Clean
#####                                :   [INFO]  Cells Have Been Blackboxed
#####  
#####  Layout Design                 :   /sim/ksabra/SPADMIC_work/innovus/20260828_mptdc_bufftap0_ro6_boundary_fillernorm_controlfix_090320/outputs/mptdc_axis_core_merged_stdcell_ro6.gds (gdsii)
#####  Layout File                   :   /sim/ksabra/SPADMIC_work/innovus/20260828_mptdc_bufftap0_ro6_boundary_fillernorm_controlfix_090320/pvs_lvs/mptdc_axis_core_ro6_boundary_blackbox_script/mptdc_axis_core.spi (cdl)
#####  Schematic File                :   /sim/ksabra/SPADMIC_work/innovus/20260828_mptdc_bufftap0_ro6_boundary_fillernorm_controlfix_090320/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v (verilog)
#####  Schematic File                :   /data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl (cdl)
#####  Rules File                    :   /sim/ksabra/SPADMIC_work/innovus/20260828_mptdc_bufftap0_ro6_boundary_fillernorm_controlfix_090320/pvs_lvs/mptdc_axis_core_ro6_boundary_blackbox_script/.config.rul
#####                                :   /sim/ksabra/SPADMIC_work/innovus/20260828_mptdc_bufftap0_ro6_boundary_fillernorm_controlfix_090320/pvs_lvs/mptdc_axis_core_ro6_boundary_blackbox_script/.technology.rul
#####  HCell File                    :   /sim/ksabra/SPADMIC_work/innovus/20260828_mptdc_bufftap0_ro6_boundary_fillernorm_controlfix_090320/outputs/pvs_hcell_ro6.txt
#####  Pin Swap File                 :   mptdc_axis_core_lvs.sum.cps
#####  
#####  Extraction CPU Time           :   0h 0m 18s - (18s)
#####  Extraction Exec Time          :   0h 0m 18s - (18s)
#####  Extraction Peak Memory Usage  :   85.00MB
#####  NVN CPU Time                  :   0h 0m 9s - (9s)                 
#####  NVN Exec Time                 :   0h 0m 11s - (11s)               
#####  NVN Peak Memory Usage         :   855.72MB
#####  LVS Total CPU Time            :   0h 0m 27s - (27s)               
#####  LVS Total Exec Time           :   0h 0m 29s - (29s)               
#####  LVS Total Peak Memory Usage   :   855.72MB
#####  
##############################################################################################################


##############################################################################################################
#
#                                            CELL MATCH STATISTICS                                            
#
##############################################################################################################

Cell Statistic Descriptions                  | Count
---------------------------------------------+----------
Cells matched                                |         1
Cells expanded                               |         0
Cells not run                                |         0
Cells which mismatch                         |         1
---------------------------------------------+----------
Total                                        |         2


Cell Statistic Detail                        | Count
---------------------------------------------+----------
Cells with parameter mismatches              |         0
Cells with mismatched instance subtypes      |         0
Cells that have been blackboxed              |         1


##############################################################################################################
#
#                                             CELL MATCH SUMMARY                                              
#
##############################################################################################################

                    |     Initial Pins     |     Compare Pins     |              | 
Cell                |   lay    :    sch    |   lay    :    sch    | Status       | Detail
--------------------+----------+-----------+----------+-----------+--------------+--------------
RO_tune6            |       19 :        19 |       19 :        19 | match        | black box
mptdc_axis_core     |       59 :        59 |       59 :        59 | mismatch     | 


##############################################################################################################
#
#                                                  LVS RULES                                                  
#
##############################################################################################################

Command Line LVS Rule Values
----------------------------

    layout_primary                          mptdc_axis_core {-top_cell mptdc_axis_core}
    schematic_primary                       mptdc_axis_core {-source_top_cell mptdc_axis_core}

LVS Rules Given in the Rules File
---------------------------------

    lvs_abort                               -softchk                               no  
    lvs_abort                               -supply_error                          no  
    lvs_abort                               -check_device_for_property_rule        no  
    layout_path                             /sim/ksabra/SPADMIC_work/innovus/20260828_mptdc_bufftap0_ro6_boundary_fillernorm_controlfix_090320/outputs/mptdc_axis_core_merged_stdcell_ro6.gds
    layout_format                           gdsii
    schematic_path                          /sim/ksabra/SPADMIC_work/innovus/20260828_mptdc_bufftap0_ro6_boundary_fillernorm_controlfix_090320/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v
                                            verilog -keep_backslash
    schematic_path                          /data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl
                                            cdl
    schematic_format                        SPICE
    lvs_write_netlist                       -layout netlistLAYOUT
    lvs_write_netlist                       -schematic netlistSOURCE
    lvs_black_box                           RO_tune6
    lvs_spice                               yes -replicate_devices
    lvs_spice                               yes -allow_unquoted_strings
    lvs_spice_multiplier_name               M 
                                             
    lvs_power_name                          VDD VDD_LEFT VDD_RIGHT VDD! vdd vdd! vddi vddi! 
    lvs_power_name                          VDD? DVDD VCC VDDA VDDB ADVDD VDDM 
    lvs_ground_name                         VSS VSS_LEFT VSS_RIGHT VSS! vss vss! gndi gndi! 
    lvs_ground_name                         GND? DVSS VSS GROUND AGND DGND VSSM 
    lvs_device_type                         NMOS NEI_6
    lvs_device_type                         NMOS NEI_A_6
    lvs_device_type                         NMOS NEI_M_6
    lvs_device_type                         NMOS NELI_6
    lvs_device_type                         NMOS NELI_M_6
    lvs_device_type                         NMOS NELNAI_6
    lvs_device_type                         NMOS NELNAI_M_6
    lvs_device_type                         NMOS NESVTI_6
    lvs_device_type                         NMOS NESVTI_M_6
    lvs_device_type                         PMOS PE_5
    lvs_device_type                         PMOS PEL_5
    lvs_device_type                         PMOS PEI_5
    lvs_device_type                         PMOS PEI_A_5
    lvs_device_type                         PMOS PEI_M_5
    lvs_device_type                         PMOS PELI_5
    lvs_device_type                         PMOS PELI_M_5
    lvs_device_type                         PMOS PESVT_5
    lvs_device_type                         PMOS PESVTI_5
    lvs_device_type                         PMOS PESVTI_M_5
    lvs_device_type                         PMOS PMMA_BJT
    lvs_device_type                         PMOS PMA_BJT
    lvs_device_type                         PMOS PMMC_BJT
    lvs_device_type                         PMOS PHHV_BJT
    lvs_device_type                         LDDPMOS PMC_BJT
    lvs_device_type                         LDDPMOS PHV_BJT
    lvs_device_type                         NMOS NE3I_6
    lvs_device_type                         NMOS NE3I_A_6
    lvs_device_type                         NMOS NE3I_M_6
    lvs_device_type                         NMOS ND3I_6
    lvs_device_type                         NMOS ND3I_M_6
    lvs_device_type                         NMOS NE3LNAI_6
    lvs_device_type                         NMOS NE3LNAI_M_6
    lvs_device_type                         PMOS PE3_5
    lvs_device_type                         PMOS PE3LN_5
    lvs_device_type                         PMOS PE3I_5
    lvs_device_type                         PMOS PE3I_A_5
    lvs_device_type                         PMOS PE3I_M_5
    lvs_device_type                         PMOS PE3LNI_5
    lvs_device_type                         PMOS PE3LNI_M_5
    lvs_device_type                         PMOS PE3LNA_5
    lvs_device_type                         PMOS PE3LNAI_5
    lvs_device_type                         PMOS PE3LNAI_M_5
    lvs_all_cap_pins_swappable              no  
    lvs_ignore_ports                        no  
    lvs_compare_port_names                  yes 
    lvs_find_shorts                         yes 
    lvs_global_sigs_are_ports               no  
    lvs_break_ambig_max                     32
    lvs_filter                              no  -bipolar
    lvs_filter                              no  -mos
    lvs_filter                              no  -resistors
    lvs_filter                              no  -diodes
    lvs_filter                              no  -capacitors
    lvs_filter_device                       D ( p_dn ) -open
    lvs_filter_device                       D ( p_dbn ) -open
    lvs_filter_device                       D ( p_dp ) -open
    lvs_filter_device                       D ( p_dpndf ) -open
    lvs_filter_device                       D ( p_dnw ) -open
    lvs_filter_device                       D ( p_dhnw ) -open
    lvs_filter_device                       D ( p_dhpw ) -open
    lvs_filter_device                       D ( p_ddnw ) -open
    lvs_filter_device                       D ( p_ddnwa ) -open
    lvs_filter_device                       D ( p_ddnwmv ) -open
    lvs_filter_device                       D ( p_dipdnw ) -open
    lvs_filter_device                       D ( p_dipdnwmv ) -open
    lvs_filter_device                       D ( p_ddpldnw ) -open
    lvs_filter_device                       D ( p_dndf ) -open
    lvs_filter_device                       D ( p_dpdwhn ) -open
    lvs_filter_device                       D ( p_dwhn ) -open
    lvs_filter_device                       D ( p_dpdddnw ) -open
    lvs_filter_device                       D ( p_dnhpw ) -open
    lvs_filter_device                       D ( p_dphnw ) -open
    lvs_filter_device                       D ( p_dpdnwmv ) -open
    lvs_filter_device                       D ( p_dpdnw ) -open
    lvs_filter_device                       D ( p_dpwhn ) -open
    lvs_filter_device                       D ( p_dn3 ) -open
    lvs_filter_device                       D ( p_dnn3 ) -open
    lvs_filter_device                       D ( p_dn3dpl ) -open
    lvs_filter_device                       D ( p_dp3 ) -open
    lvs_filter_device                       D ( p_dnw3 ) -open
    lvs_reduce_split_gates                  no  
    lvs_recognize_gates                     -none
    lvs_reduce                              no  -parallel_bipolar
    lvs_reduce                              no  -parallel_caps
    lvs_reduce                              yes -parallel_diodes ...
    lvs_reduce                              yes -parallel_mos ...
    lvs_reduce                              no  -series_mos
    lvs_reduce                              no  -parallel_resistors
    lvs_reduce                              no  -series_caps
    lvs_reduce                              no  -series_resistors
    lvs_reduce_device                       MOSVC -parallel yes ...
    lvs_reduce_device                       MOSVCI -parallel yes ...
    lvs_reduce_device                       MOSVCI_M -parallel yes ...
    lvs_reduce_device                       MOSVC3 -parallel yes ...
    lvs_reduce_device                       MOSVC3I -parallel yes ...
    lvs_reduce_device                       MOSVC3I_M -parallel yes ...
    lvs_reduce_device                       tag_25v -parallel yes 
    lvs_reduce_device                       tag_60v -parallel yes 
    lvs_expand_cell_on_error                no  
    lvs_check_property                      MN W W -tolerance 1
    lvs_check_property                      MN L L -tolerance 1
    lvs_check_property                      MP W W -tolerance 1
    lvs_check_property                      MP L L -tolerance 1
    lvs_check_property                      NEI_6 W W -tolerance 1
    lvs_check_property                      NEI_6 L L -tolerance 1
    lvs_check_property                      NEI_A_6 W W -tolerance 1
    lvs_check_property                      NEI_A_6 L L -tolerance 1
    lvs_check_property                      NEI_M_6 W W -tolerance 1
    lvs_check_property                      NEI_M_6 L L -tolerance 1
    lvs_check_property                      NELI_6 W W -tolerance 1
    lvs_check_property                      NELI_6 L L -tolerance 1
    lvs_check_property                      NELI_M_6 W W -tolerance 1
    lvs_check_property                      NELI_M_6 L L -tolerance 1
    lvs_check_property                      NELNAI_6 W W -tolerance 1
    lvs_check_property                      NELNAI_6 L L -tolerance 1
    lvs_check_property                      NELNAI_M_6 W W -tolerance 1
    lvs_check_property                      NELNAI_M_6 L L -tolerance 1
    lvs_check_property                      NESVTI_6 W W -tolerance 1
    lvs_check_property                      NESVTI_6 L L -tolerance 1
    lvs_check_property                      NESVTI_M_6 W W -tolerance 1
    lvs_check_property                      NESVTI_M_6 L L -tolerance 1
    lvs_check_property                      NE3I_6 W W -tolerance 1
    lvs_check_property                      NE3I_6 L L -tolerance 1
    lvs_check_property                      NE3I_A_6 W W -tolerance 1
    lvs_check_property                      NE3I_A_6 L L -tolerance 1
    lvs_check_property                      NE3I_M_6 W W -tolerance 1
    lvs_check_property                      NE3I_M_6 L L -tolerance 1
    lvs_check_property                      ND3I_6 W W -tolerance 1
    lvs_check_property                      ND3I_6 L L -tolerance 1
    lvs_check_property                      ND3I_M_6 W W -tolerance 1
    lvs_check_property                      ND3I_M_6 L L -tolerance 1
    lvs_check_property                      NE3LNAI_6 W W -tolerance 1
    lvs_check_property                      NE3LNAI_6 L L -tolerance 1
    lvs_check_property                      NE3LNAI_M_6 W W -tolerance 1
    lvs_check_property                      NE3LNAI_M_6 L L -tolerance 1
    lvs_check_property                      PE_5 W W -tolerance 1
    lvs_check_property                      PE_5 L L -tolerance 1
    lvs_check_property                      PEL_5 W W -tolerance 1
    lvs_check_property                      PEL_5 L L -tolerance 1
    lvs_check_property                      PE3_5 W W -tolerance 1
    lvs_check_property                      PE3_5 L L -tolerance 1
    lvs_check_property                      PE3LN_5 W W -tolerance 1
    lvs_check_property                      PE3LN_5 L L -tolerance 1
    lvs_check_property                      PEI_5 W W -tolerance 1
    lvs_check_property                      PEI_5 L L -tolerance 1
    lvs_check_property                      PEI_A_5 W W -tolerance 1
    lvs_check_property                      PEI_A_5 L L -tolerance 1
    lvs_check_property                      PEI_M_5 W W -tolerance 1
    lvs_check_property                      PEI_M_5 L L -tolerance 1
    lvs_check_property                      PELI_5 W W -tolerance 1
    lvs_check_property                      PELI_5 L L -tolerance 1
    lvs_check_property                      PELI_M_5 W W -tolerance 1
    lvs_check_property                      PELI_M_5 L L -tolerance 1
    lvs_check_property                      PESVT_5 W W -tolerance 1
    lvs_check_property                      PESVT_5 L L -tolerance 1
    lvs_check_property                      PESVTI_5 W W -tolerance 1
    lvs_check_property                      PESVTI_5 L L -tolerance 1
    lvs_check_property                      PESVTI_M_5 W W -tolerance 1
    lvs_check_property                      PESVTI_M_5 L L -tolerance 1
    lvs_check_property                      PE3I_5 W W -tolerance 1
    lvs_check_property                      PE3I_5 L L -tolerance 1
    lvs_check_property                      PE3I_A_5 W W -tolerance 1
    lvs_check_property                      PE3I_A_5 L L -tolerance 1
    lvs_check_property                      PE3I_M_5 W W -tolerance 1
    lvs_check_property                      PE3I_M_5 L L -tolerance 1
    lvs_check_property                      PE3LNI_5 W W -tolerance 1
    lvs_check_property                      PE3LNI_5 L L -tolerance 1
    lvs_check_property                      PE3LNI_M_5 W W -tolerance 1
    lvs_check_property                      PE3LNI_M_5 L L -tolerance 1
    lvs_check_property                      PE3LNA_5 W W -tolerance 1
    lvs_check_property                      PE3LNA_5 L L -tolerance 1
    lvs_check_property                      PE3LNAI_5 W W -tolerance 1
    lvs_check_property                      PE3LNAI_5 L L -tolerance 1
    lvs_check_property                      PE3LNAI_M_5 W W -tolerance 1
    lvs_check_property                      PE3LNAI_M_5 L L -tolerance 1
    lvs_check_property                      PMC_BJT W W -tolerance 1
    lvs_check_property                      PMC_BJT L L -tolerance 1
    lvs_check_property                      PHV_BJT W W -tolerance 1
    lvs_check_property                      PHV_BJT L L -tolerance 1
    lvs_check_property                      PMA_BJT W W -tolerance 1
    lvs_check_property                      PMA_BJT L L -tolerance 1
    lvs_check_property                      PMMA_BJT W W -tolerance 1
    lvs_check_property                      PMMA_BJT L L -tolerance 1
    lvs_check_property                      PMMC_BJT W W -tolerance 1
    lvs_check_property                      PMMC_BJT L L -tolerance 1
    lvs_check_property                      PHHV_BJT W W -tolerance 1
    lvs_check_property                      PHHV_BJT L L -tolerance 1
    lvs_check_property                      MOSVC W W -tolerance 1
    lvs_check_property                      MOSVC L L -tolerance 1
    lvs_check_property                      MOSVCI W W -tolerance 1
    lvs_check_property                      MOSVCI L L -tolerance 1
    lvs_check_property                      MOSVCI_M W W -tolerance 1
    lvs_check_property                      MOSVCI_M L L -tolerance 1
    lvs_check_property                      MOSVC3 W W -tolerance 1
    lvs_check_property                      MOSVC3 L L -tolerance 1
    lvs_check_property                      MOSVC3I W W -tolerance 1
    lvs_check_property                      MOSVC3I L L -tolerance 1
    lvs_check_property                      MOSVC3I_M W W -tolerance 1
    lvs_check_property                      MOSVC3I_M L L -tolerance 1
    lvs_check_property                      LDDN W W -tolerance 1
    lvs_check_property                      LDDN L L -tolerance 1
    lvs_check_property                      LDDP W W -tolerance 1
    lvs_check_property                      LDDP L L -tolerance 1
    lvs_check_property                      Q ( qnva ) LE LE -tolerance 0
    lvs_check_property                      Q ( qnvb ) LE LE -tolerance 0
    lvs_check_property                      Q ( qnvba ) LE LE -tolerance 0
    lvs_check_property                      Q ( qnvbb ) LE LE -tolerance 0
    lvs_check_property                      Q ( qnvc ) LE LE -tolerance 0
    lvs_check_property                      Q ( qnvca ) LE LE -tolerance 0
    lvs_check_property                      Q ( qnvcb ) LE LE -tolerance 0
    lvs_check_property                      Q ( qnvz ) LE LE -tolerance 0
    lvs_check_property                      Q ( qpvascr ) LE LE -tolerance 0
    lvs_check_property                      Q ( qpvhscr ) LE LE -tolerance 0
    lvs_check_property                      Q ( qpvhbscr ) LE LE -tolerance 0
    lvs_check_property                      R ( s_res ) R R -tolerance 0
    lvs_check_property                      R W W -tolerance 1
    lvs_check_property                      R L L -tolerance 1
    lvs_check_property                      C AREA AREA -tolerance 1
    lvs_check_property                      C PERIMETER PERIMETER -tolerance 1
    lvs_check_property                      D A A -tolerance 5
    lvs_check_property                      D P P -tolerance 5
    lvs_check_property                      DPHOC area area -tolerance 1
    lvs_check_property                      DPHOC perimeter perimeter -tolerance 1
    lvs_check_property                      DPHOCFP area area -tolerance 1
    lvs_check_property                      DPHOCFP perimeter perimeter -tolerance 1
    lvs_check_property                      DPHOC0 area area -tolerance 1
    lvs_check_property                      DPHOC0 perimeter perimeter -tolerance 1
    lvs_check_property                      DPHOD area area -tolerance 1
    lvs_check_property                      DPHOD perimeter perimeter -tolerance 1
    lvs_check_property                      DPHODFP area area -tolerance 1
    lvs_check_property                      DPHODFP perimeter perimeter -tolerance 1
    lvs_check_property                      DPHOD0 area area -tolerance 1
    lvs_check_property                      DPHOD0 perimeter perimeter -tolerance 1
    lvs_check_property                      DAPB area area -tolerance 1
    lvs_check_property                      DAPB perimeter perimeter -tolerance 1
    lvs_check_property                      DAPB0 area area -tolerance 1
    lvs_check_property                      DAPB0 perimeter perimeter -tolerance 1
    lvs_check_property                      DSPB area area -tolerance 1
    lvs_check_property                      DSPB perimeter perimeter -tolerance 1
    lvs_check_property                      DSPB0 area area -tolerance 1
    lvs_check_property                      DSPB0 perimeter perimeter -tolerance 1
    lvs_check_property                      DSPBFEP area area -tolerance 1
    lvs_check_property                      DSPBFEP perimeter perimeter -tolerance 1
    lvs_report_file                         mptdc_axis_core_lvs.sum
    lvs_report_max                          1000 -mismatched_net_limit 100 
    unit                                    -length u
    unit                                    -capacitance ff
    unit                                    -resistance ohm
    input_scale                             1000
    virtual_connect                         no  -colon
    virtual_connect                         yes -semicolon_as_colon
    virtual_connect                         no  -report
    virtual_connect                         -depth primary
    text_depth                              -primary

Default LVS Rule Values
-----------------------

    lvs_abort                               -missing_hcell no
    lvs_abort                               -erc_error yes
    lvs_abort                               -inconsistent_reduction yes
    layout_case_sensitive                   no
    // layout_cpf_file                       
    // schematic_cpf_file                    
    schematic_case_sensitive                no
    // hcell_file                            
    // hcell                                 
    // lvs_exclude_hcell                     
    // lvs_delete_cell                       
    lvs_push_devices                        yes
    lvs_push_devices_properties             no
    lvs_netlist                             yes -substrate_comment
    lvs_netlist                             yes -box_contents
    lvs_netlist                             yes -unnamed_box_pins
    lvs_netlist                             no -allow_inconsistent_model
    lvs_netlist                             yes -properties_comment
    // lvs_write_netlist_reduced             
    // lvs_delete_cell_pin                   
    // lvs_interposer                        
    lvs_spice                               yes -allow_floating_pins
    lvs_spice                               yes -allow_duplicate_subcircuit_names
    lvs_spice                               no  -conditional_ldd
    lvs_spice                               no  -prefer_pins
    lvs_spice                               no  -override_globals
    lvs_spice                               no  -redefine_param
    lvs_spice                               no  -replicate_devices_enhanced
    lvs_spice                               yes -slash_is_space
    lvs_spice                               yes -keep_back_slash
    lvs_spice                               no  -allow_inline_parameters
    lvs_spice                               no  -calculate_mos_area
    lvs_spice                               no  -strict_wl
    lvs_spice                               no  -cull_primitive_subcircuits
    lvs_spice                               no  -ignore_option_scale
    lvs_spice                               no  -show_neg_param_warning
    lvs_spice                               no  -scale_x_parameters
    lvs_spice                               yes -strict_subckts_order
    // lvs_spice_option                      
    lvs_reverse_wl                          no
                                             
    lvs_compare_case                        no
    lvs_cname                               no  -cell
    lvs_cname                               yes -pin
    lvs_cname                               yes -net
    lvs_cname                               no  -instance
    lvs_non_user_name                       -port "^[0-9]+$"
    lvs_non_user_name                       -net  "^[0-9]+$"
    // lvs_non_user_name                    -instance 
    lvs_out_of_range_exclude_zero           no
    // lvs_group_models                      
    lvs_strict_subtypes                     no
    lvs_exact_subtypes                      no
    lvs_preserve_box_ports                  no
    // lvs_cpoint                            
    // lvs_cell_list                         
    lvs_auto_pin_swap                       yes -swap_threshold 4000000
    lvs_swap_non_cpoint_pins                yes
    // lvs_swap_pins                         
    lvs_builtin_device_pin_swap             yes
    // lvs_join_nets                         
    lvs_discard_pins                        no
    // lvs_filter_option                     
    // lvs_filter_device_keep_net            
    lvs_reduction_priority                  -parallel
    lvs_derive_logic                        yes -sram
    lvs_derive_logic                        no  -dram
    lvs_derive_logic                        no  -rom
    // lvs_recognize_gates_tolerance         
    lvs_reduce                              no  -series_diodes
    // lvs_reduce_do_not_merge               
    lvs_expand_on_device_climbing           no
    lvs_expand_unbalanced_cells             yes
    // lvs_check_all_properties_by_name      
    // lvs_property_map                      
    // lvs_transfer_property                 
    lvs_warn_max                            50
    lvs_inconsistent_reduction_threshold    1000000
    // lvs_report_opt                        
    lvs_report_units                        yes
    lvs_keep_data                           no
    lvs_keep_source_cells                   no
    lvs_create_match_db                     no
    // lvs_map_device                        
    lvs_verilog_bus_map_by_position         no
    lvs_verilog_keep_backslash              no
    lvs_verilog_detect_buses                no
    lvs_do_not_normalize                    no
    // lvs_generic_device                    
    virtual_connect                         no  -colon
    virtual_connect                         yes -semicolon_as_colon
    // virtual_connect                      -name 
    virtual_connect                         no -report
    virtual_connect                         no -incremental
    lvs_preserve_parameterized_cells        no
    lvs_check_color                         no
    // lvs_schematic_color_path              
    // lvs_assign_conflict_layer             
    // lvs_conflict_layer_check             
    lvs_check_color_label                   no
    // lvs_preserve_cells                    
    port                                    -depth -primary

Effective LVS Rule Values
-------------------------

    lvs_swap_non_cpoint_pins                yes -unbound_pin_threshold 10000
    lvs_derive_logic                        no   -sram
    virtual_connect                         no  -report


##############################################################################################################
#
#                                               CELL COMPARISON                                               
#
##############################################################################################################

                              ##################################################
                              #                                                #
                              #       ------->>> $ MISMATCH $ <<<-------       #
                              #                                                #
                              #     mptdc_axis_core  <vs>  mptdc_axis_core     #
                              #                                                #
                              #            CONNECTIVITY MISMATCHES             #
                              #                                                #
                              ##################################################

+===[mptdc_axis_core]=========================================================================================
|                                                 STATISTICS                                                  
+=============================================================================================================


                     |       Original       |        Filtered        |        Reduced         |   Unmatched   
Cell                 |    lay    :   sch    |    lay     :    sch    |    lay     :    sch    |  lay  :  sch
---------------------+-----------+----------+------------+-----------+------------+-----------+-------+-------
MP [4 pins]          |           :          |            :           |            :           |       :       
 MP(PEI)             |  *109,038 :  106,852 |   *109,038 :   106,852 |    106,698 :   106,698 |     0 :      0
MN [4 pins]          |           :          |            :           |            :           |       :       
 MN(NEI)   .  .  .  .|. *108,594 :. 106,852 |.  *108,594 :.  106,852 |.   106,712 :.  106,712 |.  . 0 :.  .  0
(D [2 pins], -)      |           :          |            :           |            :           |       :       
 (D(P_DIPDNWMV), -) .|.  .  *116 :.  .  . 0 |.  .  .   0 :.  .  .  0 |.  .  .   - :.  .  .  - |.  . - :.  .  -
 (D(P_DDNWMV), -)    |        *3 :        0 |          0 :         0 |          - :         - |     - :      -
RO_tune6             |         2 :        2 |          2 :         2 |          2 :         2 |     0 :      0
---------------------+-----------+----------+------------+-----------+------------+-----------+-------+-------
Total                |   217,753 :  213,706 |    217,634 :   213,706 |    213,412 :   213,412 |     0 :      0
=====================+===========+==========+============+===========+============+===========+=======+=======
Pins                 |           :          |            :           |         59 :        59 |     0 :      0
Nets                 |           :          |            :           |   *119,826 :   119,734 |   *92 :      0
=====================+===========+==========+============+===========+============+===========+=======+=======

+===[mptdc_axis_core]=========================================================================================
|                                      DEVICES REMOVED DURING REDUCTION                                       
+=============================================================================================================


                |      Parallel       |      Series       |     Deleted Nets     
Cell            |    lay    :   sch   |   lay   :   sch   |    lay    :   sch
----------------+-----------+---------+---------+---------+-----------+----------
MP [4 pins]     |           :         |         :         |           :          
 MP(PEI)        |     2,340 :     154 |       - :       - |         0 :         0
MN [4 pins]     |           :         |         :         |           :          
 MN(NEI)        |     1,882 :     140 |       - :       - |         0 :         0
----------------+-----------+---------+---------+---------+-----------+----------

+===[mptdc_axis_core]=========================================================================================
|                                           INITIAL CORRESPONDENCES                                           
+=============================================================================================================

Type | Name
-----+--------------------------------------------------------------------------------------------------------
Pin  | async_rst_n busy_o cal_start_async_i cal_stop_async_i clk_sys conv_arm_i fifo_clr_i fifo_full_o
     | input_sel_i[0] max_hits_i[0] max_hits_i[1] max_hits_i[2] max_hits_i[3] packet_active_o packet_pending_o
     | pkt_data_o[0] pkt_data_o[10] pkt_data_o[11] pkt_data_o[12] pkt_data_o[13] pkt_data_o[14] pkt_data_o[15]
     | pkt_data_o[1] pkt_data_o[2] pkt_data_o[3] pkt_data_o[4] pkt_data_o[5] pkt_data_o[6] pkt_data_o[7]
     | pkt_data_o[8] pkt_data_o[9] pkt_eop_o pkt_ready_i pkt_sop_o pkt_valid_o ready_o ro_fast_code_i[0]
     | ro_fast_code_i[1] ro_fast_code_i[2] ro_fast_code_i[3] ro_fast_code_i[4] ro_fast_code_i[5]
     | ro_fast_code_i[6] ro_fast_code_i[7] ro_fast_tap0_o ro_slow_code_i[0] ro_slow_code_i[1]
     | ro_slow_code_i[2] ro_slow_code_i[3] ro_slow_code_i[4] ro_slow_code_i[5] ro_slow_code_i[6]
     | ro_slow_code_i[7] ro_slow_tap0_o soft_reset_i start_spad_async_i stop_spad_async_i VDD VSS


+===[mptdc_axis_core]=========================================================================================
|                                              SHORTS AND OPENS                                               
+=============================================================================================================
                                                
                                                
Layout Pin: VSS         | Schematic Pin: VSS
========================+================(sao 1)
Layout Net: X3/6086     |         OPEN
========================+=======================
Layout Net: X0/21       |         OPEN
========================+=======================


+===[mptdc_axis_core]=========================================================================================
|                                               MISMATCHED NETS                                               
+=============================================================================================================
                                                                                                               
                                                                                                               
Layout Net: X1/1090       | Schematic Net: tie1
==========================+==============================================================================(mn 1)
Terminal: Layout Instance | Terminal: Schematic Instance
--------------------------+------------------------------------------------------------------------------------
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60  MP(PEI)
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57  MP(PEI)
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20  MN(NEI)
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57  MP(PEI)
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20  MN(NEI)
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57  MP(PEI)
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20  MN(NEI)
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57  MP(PEI)
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20  MN(NEI)
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57  MP(PEI)
** missing connection **  | G: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20  MN(NEI)
** missing connection **  | G: \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: u_core_u_rst_drain_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: u_core_u_rst_drain_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: u_core_u_rst_fifo_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: u_core_u_rst_fifo_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: u_core_u_rst_status_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: u_core_u_rst_status_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: u_core_u_rst_tx_sync/\sync_q_reg[0]/MM23  MP(PEI)
** missing connection ** .| G: u_core_u_rst_tx_sync/\sync_q_reg[0]/MM15  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM25  MP(PEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM58  MP(PEI)
** missing connection **  | G: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM48  MN(NEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM44  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_fifo_count_q_reg[5]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_fifo_count_q_reg[5]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_fifo_count_q_reg[5]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_fifo_count_q_reg[5]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_fifo_rd_ptr_q_reg[2]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_fifo_rd_ptr_q_reg[2]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_fifo_rd_ptr_q_reg[2]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_fifo_rd_ptr_q_reg[2]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_fifo_rd_ptr_q_reg[3]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_fifo_rd_ptr_q_reg[3]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_fifo_rd_ptr_q_reg[3]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_fifo_rd_ptr_q_reg[3]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_meas_ctrl_state_q_reg[0]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_meas_ctrl_state_q_reg[0]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_meas_ctrl_state_q_reg[0]/MM52  MN(NEI)
** missing connection ** .| G: \u_core_u_meas_ctrl_state_q_reg[0]/MM20  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM60  MP(PEI)
** missing connection ** .| G: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM57  MP(PEI)
** missing connection **  | G: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM52  MN(NEI)
** missing connection **  | G: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM20  MN(NEI)
--------------------------+----------------------------------------------------------------(truncated next 234)
                                                                                                               
                                                                                                               
Layout Net: X2/3886       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 2)
                                                                                                               
                                                                                                               
Layout Net: X2/3793       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 3)
                                                                                                               
                                                                                                               
Layout Net: X2/3885       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 4)
                                                                                                               
                                                                                                               
Layout Net: X1/1054       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 5)
                                                                                                               
                                                                                                               
Layout Net: X2/3779       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 6)
                                                                                                               
                                                                                                               
Layout Net: X3/2355       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 7)
                                                                                                               
                                                                                                               
Layout Net: X2/3813       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 8)
                                                                                                               
                                                                                                               
Layout Net: X3/2353       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 9)
                                                                                                               
                                                                                                               
Layout Net: X2/3884       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 10)
                                                                                                               
                                                                                                               
Layout Net: X2/3790       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 11)
                                                                                                               
                                                                                                               
Layout Net: X1/1081       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 12)
                                                                                                               
                                                                                                               
Layout Net: X2/3810       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 13)
                                                                                                               
                                                                                                               
Layout Net: X3/2349       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 14)
                                                                                                               
                                                                                                               
Layout Net: X2/3883       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 15)
                                                                                                               
                                                                                                               
Layout Net: X3/2343       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 16)
                                                                                                               
                                                                                                               
Layout Net: X2/3808       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 17)
                                                                                                               
                                                                                                               
Layout Net: X3/2340       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 18)
                                                                                                               
                                                                                                               
Layout Net: X1/1050       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 19)
                                                                                                               
                                                                                                               
Layout Net: X2/3806       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 20)
                                                                                                               
                                                                                                               
Layout Net: X3/2332       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 21)
                                                                                                               
                                                                                                               
Layout Net: X3/2330       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 22)
                                                                                                               
                                                                                                               
Layout Net: X2/3804       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 23)
                                                                                                               
                                                                                                               
Layout Net: X3/2322       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 24)
                                                                                                               
                                                                                                               
Layout Net: X2/3841       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 25)
                                                                                                               
                                                                                                               
Layout Net: X2/3788       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 26)
                                                                                                               
                                                                                                               
Layout Net: X2/3839       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 27)
                                                                                                               
                                                                                                               
Layout Net: X1/1057       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 28)
                                                                                                               
                                                                                                               
Layout Net: X2/3838       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 29)
                                                                                                               
                                                                                                               
Layout Net: X2/3787       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 30)
                                                                                                               
                                                                                                               
Layout Net: X2/3837       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 31)
                                                                                                               
                                                                                                               
Layout Net: X2/3800       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 32)
                                                                                                               
                                                                                                               
Layout Net: X2/3888       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 33)
                                                                                                               
                                                                                                               
Layout Net: X2/3836       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 34)
                                                                                                               
                                                                                                               
Layout Net: X2/3786       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 35)
                                                                                                               
                                                                                                               
Layout Net: X1/1089       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 36)
                                                                                                               
                                                                                                               
Layout Net: X1/1052       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 37)
                                                                                                               
                                                                                                               
Layout Net: X2/3835       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 38)
                                                                                                               
                                                                                                               
Layout Net: X2/3834       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 39)
                                                                                                               
                                                                                                               
Layout Net: X2/3785       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 40)
                                                                                                               
                                                                                                               
Layout Net: X2/3833       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 41)
                                                                                                               
                                                                                                               
Layout Net: X2/3831       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 42)
                                                                                                               
                                                                                                               
Layout Net: X2/3784       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 43)
                                                                                                               
                                                                                                               
Layout Net: X1/1088       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 44)
                                                                                                               
                                                                                                               
Layout Net: X2/3828       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 45)
                                                                                                               
                                                                                                               
Layout Net: X2/3825       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 46)
                                                                                                               
                                                                                                               
Layout Net: X2/3783       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 47)
                                                                                                               
                                                                                                               
Layout Net: X2/3822       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 48)
                                                                                                               
                                                                                                               
Layout Net: X3/2357       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 49)
                                                                                                               
                                                                                                               
Layout Net: X2/3819       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 50)
                                                                                                               
                                                                                                               
Layout Net: X2/3816       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 51)
                                                                                                               
                                                                                                               
Layout Net: X3/2354       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 52)
                                                                                                               
                                                                                                               
Layout Net: X3/2351       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 53)
                                                                                                               
                                                                                                               
Layout Net: X3/2350       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 54)
                                                                                                               
                                                                                                               
Layout Net: X2/3809       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 55)
                                                                                                               
                                                                                                               
Layout Net: X3/2341       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 56)
                                                                                                               
                                                                                                               
Layout Net: X1/1080       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 57)
                                                                                                               
                                                                                                               
Layout Net: X3/2333       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 58)
                                                                                                               
                                                                                                               
Layout Net: X2/3805       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 59)
                                                                                                               
                                                                                                               
Layout Net: X3/2325       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 60)
                                                                                                               
                                                                                                               
Layout Net: X3/2319       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 61)
                                                                                                               
                                                                                                               
Layout Net: X2/3802       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 62)
                                                                                                               
                                                                                                               
Layout Net: X2/3889       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 63)
                                                                                                               
                                                                                                               
Layout Net: X2/3821       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 64)
                                                                                                               
                                                                                                               
Layout Net: X1/1082       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 65)
                                                                                                               
                                                                                                               
Layout Net: X1/1051       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 66)
                                                                                                               
                                                                                                               
Layout Net: X2/3782       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 67)
                                                                                                               
                                                                                                               
Layout Net: X3/2356       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 68)
                                                                                                               
                                                                                                               
Layout Net: X3/2352       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 69)
                                                                                                               
                                                                                                               
Layout Net: X2/3811       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 70)
                                                                                                               
                                                                                                               
Layout Net: X3/2348       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 71)
                                                                                                               
                                                                                                               
Layout Net: X3/2338       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 72)
                                                                                                               
                                                                                                               
Layout Net: X2/3807       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 73)
                                                                                                               
                                                                                                               
Layout Net: X3/2335       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 74)
                                                                                                               
                                                                                                               
Layout Net: X3/2331       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 75)
                                                                                                               
                                                                                                               
Layout Net: X3/2320       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 76)
                                                                                                               
                                                                                                               
Layout Net: X2/3803       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 77)
                                                                                                               
                                                                                                               
Layout Net: X2/3801       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 78)
                                                                                                               
                                                                                                               
Layout Net: X2/3209       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 79)
                                                                                                               
                                                                                                               
Layout Net: X2/3308       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 80)
                                                                                                               
                                                                                                               
Layout Net: X2/3196       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 81)
                                                                                                               
                                                                                                               
Layout Net: X1/923        | Schematic Net: ** missing net **
==========================+=============================================================================(mn 82)
                                                                                                               
                                                                                                               
Layout Net: X3/1987       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 83)
                                                                                                               
                                                                                                               
Layout Net: X2/3276       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 84)
                                                                                                               
                                                                                                               
Layout Net: X2/3229       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 85)
                                                                                                               
                                                                                                               
Layout Net: X3/1999       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 86)
                                                                                                               
                                                                                                               
Layout Net: X2/3252       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 87)
                                                                                                               
                                                                                                               
Layout Net: X2/3224       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 88)
                                                                                                               
                                                                                                               
Layout Net: X3/2007       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 89)
                                                                                                               
                                                                                                               
Layout Net: X3/2037       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 90)
                                                                                                               
                                                                                                               
Layout Net: X2/3243       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 91)


++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++ Truncated to 100 entries, to adjust this use the -mismatched_net_limit option in the lvs_report_max rule 
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


+===[mptdc_axis_core]=========================================================================================
|                                            MISMATCHED INSTANCES                                             
+=============================================================================================================
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X404/M15 @(825.940,111.105)  | Schematic Inst : u_rst_core_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+===================================================================================(mi 1)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/923                                     | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X404/23  .  .  .  .  .  .  .  .  .  .  .| D: u_rst_core_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X404/M0 @(825.940,113.580)   | Schematic Inst : u_rst_core_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+===================================================================================(mi 2)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/923                                     | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X404/19  .  .  .  .  .  .  .  .  .  .  .| D: u_rst_core_sync/\sync_q_reg[0]/net64
S: X1/X404/17                                 | S: u_rst_core_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X562/M30 @(342.100,75.960)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+===================================================================================(mi 3)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1050                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X562/13  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X562/M22 @(335.720,75.730)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+===================================================================================(mi 4)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1050                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X562/11  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X562/M12 @(342.095,77.740)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+===================================================================================(mi 5)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1050                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X562/15  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X562/M4 @(335.280,77.740)    | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+===================================================================================(mi 6)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1050                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X562/18  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X587/M28 @(308.500,161.480)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+===================================================================================(mi 7)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1080                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X587/12  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X587/M20 @(302.120,161.710)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+===================================================================================(mi 8)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1080                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X587/11  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X587/M12 @(308.550,159.700)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+===================================================================================(mi 9)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1080                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X587/15  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X587/M4 @(301.680,159.700)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 10)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1080                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X587/18  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X590/M27 @(541.580,84.885)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 11)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1082                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X590/12  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X590/M19 @(547.960,84.690)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 12)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1082                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X590/10  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X590/M12 @(541.770,86.280)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 13)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1082                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X590/14  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X590/M4 @(548.400,86.700)    | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 14)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1082                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X590/17  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X566/M30 @(582.460,147.640)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 15)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1057                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X566/13  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X566/M22 @(588.840,147.410)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 16)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1057                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X566/11  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X566/M12 @(582.465,149.420)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 17)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1057                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X566/15  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X566/M4 @(589.280,149.420)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 18)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1057                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X566/18  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X600/M30 @(435.880,99.225)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 19)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1089                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X600/11  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X600/M22 @(429.240,98.990)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 20)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1089                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X600/10  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X600/M12 @(435.510,97.450)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 21)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1089                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X600/14  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X600/M4 @(428.800,96.980)    | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 22)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1089                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X600/17  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X564/M30 @(517.500,179.400)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 23)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1052                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X564/13  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X564/M22 @(523.880,179.630)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 24)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1052                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X564/11  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X564/M12 @(517.505,177.620)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 25)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1052                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X564/15  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X564/M4 @(524.320,177.620)   | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 26)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1052                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X564/18  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2398/M28 @(165.560,245.735) | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 27)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3889                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2398/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2398/M20 @(159.320,245.970) | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 28)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3889                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2398/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2398/M12 @(165.350,247.545) | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 29)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3889                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2398/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2398/M4 @(158.880,247.980)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 30)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3889                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2398/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2296/M28 @(254.740,251.080) | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 31)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3807                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2296/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2296/M20 @(248.360,251.310) | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 32)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3807                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2296/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2296/M12 @(254.790,249.300) | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 33)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3807                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2296/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2296/M4 @(247.920,249.300)  | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 34)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3807                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2296/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X588/M28 @(314.660,75.960)   | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 35)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1081                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X588/12  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X588/M20 @(308.280,75.730)   | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 36)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1081                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X588/11  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X588/M12 @(314.710,77.740)   | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 37)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1081                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X588/15  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X588/M4 @(307.840,77.740)    | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 38)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1081                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X588/18  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X599/M30 @(279.800,129.255)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 39)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1088                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X599/11  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X599/M22 @(286.440,129.490)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 40)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1088                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X599/10  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X599/M12 @(280.170,131.030)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 41)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1088                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X599/14  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X599/M4 @(286.880,131.500)   | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 42)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1088                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X599/17  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X565/M30 @(555.020,161.480)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 43)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1054                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X565/13  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X565/M22 @(561.400,161.710)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 44)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1054                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X565/11  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X565/M12 @(555.025,159.700)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 45)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1054                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X565/15  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X565/M4 @(561.840,159.700)   | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 46)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1054                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X565/18  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X563/M30 @(432.380,174.520)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 47)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1051                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X563/13  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X563/M22 @(438.760,174.290)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 48)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1051                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X563/11  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X563/M12 @(432.385,176.300)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 49)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1051                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X563/15  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X1/X563/M4 @(439.200,176.300)   | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 50)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1051                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X1/X563/18  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2272/M30 @(493.980,192.440) | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 51)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3788                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2272/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2272/M22 @(500.360,192.210) | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 52)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3788                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2272/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2272/M12 @(493.985,194.220) | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 53)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3788                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2272/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2272/M4 @(500.800,194.220)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 54)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3788                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2272/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2291/M28 @(137.140,286.920) | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 55)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3802                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2291/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2291/M20 @(130.760,287.150) | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 56)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3802                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2291/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2291/M12 @(137.190,285.140) | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 57)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3802                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2291/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2291/M4 @(130.320,285.140)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 58)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3802                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2291/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2323/M27 @(205.580,286.955) | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 59)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3835                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2323/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2323/M19 @(211.960,287.150) | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 60)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3835                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2323/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2323/M12 @(205.770,285.560) | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 61)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3835                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2323/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2323/M4 @(212.400,285.140)  | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 62)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3835                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2323/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2300/M28 @(344.340,210.360) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 63)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3811                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2300/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2300/M20 @(337.960,210.130) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 64)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3811                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2300/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2300/M12 @(344.390,212.140) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 65)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3811                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2300/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2300/M4 @(337.520,212.140)  | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 66)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3811                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2300/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2268/M30 @(292.820,269.000) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 67)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3784                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2268/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2268/M22 @(286.440,269.230) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 68)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3784                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2268/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2268/M12 @(292.815,267.220) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 69)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3784                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2268/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2268/M4 @(286.000,267.220)  | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 70)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3784                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2268/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2386/M30 @(524.920,242.585) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 71)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3888                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2386/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2386/M22 @(518.280,242.350) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 72)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3888                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2386/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2386/M12 @(524.550,240.810) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 73)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3888                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2386/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2386/M4 @(517.840,240.340)  | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 74)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3888                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2386/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2273/M30 @(515.260,260.040) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 75)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3790                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2273/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2273/M22 @(521.640,260.270) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 76)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3790                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2273/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2273/M12 @(515.265,258.260) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 77)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3790                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2273/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2273/M4 @(522.080,258.260)  | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 78)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3790                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2273/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2384/M30 @(414.760,227.815) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 79)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3885                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2384/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2384/M22 @(421.400,228.050) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 80)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3885                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2384/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2384/M12 @(415.130,229.590) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 81)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3885                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2384/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2384/M4 @(421.840,230.060)  | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 82)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3885                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2384/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2270/M30 @(468.780,304.840) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 83)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3786                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2270/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2270/M22 @(475.160,305.070) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 84)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3786                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2270/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2270/M12 @(468.785,303.060) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 85)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3786                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2270/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2270/M4 @(475.600,303.060)  | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 86)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3786                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2270/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2382/M30 @(141.320,326.375) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 87)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3883                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2382/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2382/M22 @(134.680,326.610) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 88)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3883                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2382/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2382/M12 @(140.950,328.150) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 89)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3883                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2382/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2382/M4 @(134.240,328.620)  | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 90)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3883                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2382/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2293/M28 @(213.860,349.640) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 91)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3804                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2293/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2293/M20 @(207.480,349.870) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 92)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3804                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2293/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2293/M12 @(213.910,347.860) | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 93)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3804                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2293/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2293/M4 @(207.040,347.860)  | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 94)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3804                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2293/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2299/M28 @(327.660,407.480) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 95)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3810                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2299/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2299/M20 @(334.040,407.250) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 96)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3810                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2299/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2299/M12 @(327.610,409.260) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 97)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3810                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2299/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2299/M4 @(334.480,409.260)  | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+==================================================================================(mi 98)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3810                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2299/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2267/M30 @(284.540,358.600) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+==================================================================================(mi 99)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3783                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2267/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2267/M22 @(290.920,358.830) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 100)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3783                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2267/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2267/M12 @(284.545,356.820) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 101)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3783                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2267/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2267/M4 @(291.360,356.820)  | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 102)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3783                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2267/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2385/M30 @(493.720,380.135) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 103)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3886                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2385/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2385/M22 @(500.360,380.370) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 104)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3886                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2385/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2385/M12 @(494.090,381.910) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 105)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3886                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2385/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2385/M4 @(500.800,382.380)  | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 106)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3886                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2385/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2301/M28 @(525.900,367.560) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 107)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3813                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2301/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2301/M20 @(532.280,367.790) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 108)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3813                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2301/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2301/M12 @(525.850,365.780) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 109)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3813                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2301/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2301/M4 @(532.720,365.780)  | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 110)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3813                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2301/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2383/M30 @(412.920,439.705) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 111)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3884                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2383/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2383/M22 @(406.280,439.470) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 112)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3884                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2383/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2383/M12 @(412.550,437.930) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 113)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3884                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2383/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2383/M4 @(405.840,437.460)  | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 114)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3884                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2383/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2271/M30 @(476.060,430.280) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 115)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3787                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2271/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2271/M22 @(482.440,430.510) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 116)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3787                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2271/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2271/M12 @(476.065,428.500) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 117)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3787                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2271/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2271/M4 @(482.880,428.500)  | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 118)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3787                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2271/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2322/M27 @(147.780,385.515) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 119)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3834                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2322/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2322/M19 @(141.400,385.710) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 120)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3834                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2322/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2322/M12 @(147.590,384.120) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 121)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3834                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2322/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2322/M4 @(140.960,383.700)  | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 122)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3834                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2322/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2297/M28 @(264.260,407.480) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 123)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3808                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2297/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2297/M20 @(257.880,407.250) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 124)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3808                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2297/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2297/M12 @(264.310,409.260) | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 125)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3808                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2297/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2297/M4 @(257.440,409.260)  | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 126)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3808                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2297/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1246/M30 @(311.160,717.465) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 127)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2351                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1246/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1246/M22 @(317.800,717.230) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 128)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2351                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1246/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1246/M12 @(311.530,715.690) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 129)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2351                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1246/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1246/M4 @(318.240,715.220)  | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 130)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2351                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1246/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1243/M30 @(242.840,618.905) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 131)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2348                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1243/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1243/M22 @(249.480,618.670) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 132)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2348                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1243/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1243/M12 @(243.210,617.130) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 133)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2348                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1243/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1243/M4 @(249.920,616.660)  | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 134)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2348                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1243/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1250/M30 @(495.960,538.265) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 135)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2355                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1250/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1250/M22 @(502.600,538.030) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 136)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2355                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1250/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1250/M12 @(496.330,536.490) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 137)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2355                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1250/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1250/M4 @(503.040,536.020)  | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 138)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2355                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1250/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1205/M30 @(565.660,559.800) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 139)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2325                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1205/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1205/M22 @(572.040,559.570) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 140)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2325                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1205/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1205/M12 @(565.665,561.580) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 141)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2325                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1205/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1205/M4 @(572.480,561.580)  | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 142)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2325                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1205/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1249/M30 @(425.400,744.345) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 143)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2354                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1249/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1249/M22 @(432.040,744.110) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 144)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2354                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1249/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1249/M12 @(425.770,742.570) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 145)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2354                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1249/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1249/M4 @(432.480,742.100)  | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 146)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2354                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1249/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1227/M27 @(526.460,654.315) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 147)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2343                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1227/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1227/M19 @(532.840,654.510) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 148)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2343                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1227/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1227/M12 @(526.650,652.920) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 149)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2343                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1227/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1227/M4 @(533.280,652.500)  | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 150)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2343                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1227/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2292/M28 @(193.700,501.960) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 151)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3803                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2292/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2292/M20 @(187.320,502.190) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 152)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3803                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2292/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2292/M12 @(193.750,500.180) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 153)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3803                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2292/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2292/M4 @(186.880,500.180)  | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 154)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3803                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2292/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2298/M28 @(264.260,501.960) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 155)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3809                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2298/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2298/M20 @(257.880,502.190) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 156)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3809                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2298/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2298/M12 @(264.310,500.180) | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 157)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3809                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2298/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2298/M4 @(257.440,500.180)  | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 158)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3809                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2298/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1247/M30 @(332.840,708.505) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 159)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2352                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1247/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1247/M22 @(326.200,708.270) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 160)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2352                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1247/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1247/M12 @(332.470,706.730) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 161)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2352                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1247/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1247/M4 @(325.760,706.260)  | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 162)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2352                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1247/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1214/M28 @(294.500,631.480) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 163)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2331                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1214/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1214/M20 @(288.120,631.250) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 164)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2331                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1214/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1214/M12 @(294.550,633.260) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 165)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2331                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1214/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1214/M4 @(287.680,633.260)  | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 166)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2331                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1214/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1251/M30 @(575.320,532.455) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 167)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2356                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1251/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1251/M22 @(568.680,532.690) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 168)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2356                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1251/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1251/M12 @(574.950,534.230) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 169)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2356                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1251/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1251/M4 @(568.240,534.700)  | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 170)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2356                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1251/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1217/M28 @(595.900,577.720) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 171)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2335                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1217/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1217/M20 @(602.280,577.490) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 172)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2335                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1217/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1217/M12 @(595.850,579.500) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 173)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2335                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1217/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1217/M4 @(602.720,579.500)  | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 174)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2335                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1217/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1255/M28 @(469.080,720.615) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 175)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2357                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1255/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1255/M20 @(462.840,720.850) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 176)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2357                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1255/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1255/M12 @(468.870,722.425) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 177)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2357                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1255/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1255/M4 @(462.400,722.860)  | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 178)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2357                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1255/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1216/M28 @(544.260,690.120) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 179)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2333                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1216/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1216/M20 @(537.880,690.350) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 180)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2333                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1216/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1216/M12 @(544.310,688.340) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 181)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2333                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1216/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1216/M4 @(537.440,688.340)  | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 182)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2333                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1216/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2266/M30 @(151.700,497.080) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 183)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3782                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2266/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2266/M22 @(145.320,496.850) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 184)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3782                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2266/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2266/M12 @(151.695,498.860) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 185)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3782                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2266/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2266/M4 @(144.880,498.860)  | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 186)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3782                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2266/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2294/M28 @(219.020,497.080) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 187)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3805                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2294/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2294/M20 @(225.400,496.850) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 188)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3805                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2294/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2294/M12 @(218.970,498.860) | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 189)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3805                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2294/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2294/M4 @(225.840,498.860)  | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 190)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3805                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2294/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1245/M30 @(296.600,702.695) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 191)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2350                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1245/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1245/M22 @(303.240,702.930) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 192)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2350                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1245/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1245/M12 @(296.970,704.470) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 193)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2350                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1245/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1245/M4 @(303.680,704.940)  | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 194)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2350                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1245/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1213/M28 @(255.860,604.600) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 195)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2330                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1213/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1213/M20 @(249.480,604.370) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 196)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2330                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1213/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1213/M12 @(255.910,606.380) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 197)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2330                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1213/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1213/M4 @(249.040,606.380)  | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 198)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2330                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1213/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2329/M27 @(500.140,475.115) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 199)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3838                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2329/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2329/M19 @(506.520,475.310) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 200)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3838                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2329/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2329/M12 @(500.330,473.720) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 201)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3838                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2329/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2329/M4 @(506.960,473.300)  | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 202)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3838                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2329/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1204/M30 @(524.220,528.840) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 203)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2322                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1204/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1204/M22 @(530.600,529.070) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 204)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2322                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1204/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1204/M12 @(524.225,527.060) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 205)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2322                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1204/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1204/M4 @(531.040,527.060)  | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 206)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2322                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1204/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1248/M30 @(419.800,738.535) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 207)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2353                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1248/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1248/M22 @(426.440,738.770) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 208)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2353                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1248/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1248/M12 @(420.170,740.310) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 209)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2353                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1248/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1248/M4 @(426.880,740.780)  | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 210)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2353                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1248/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1215/M28 @(461.500,631.480) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 211)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2332                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1215/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1215/M20 @(467.880,631.250) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 212)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2332                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1215/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1215/M12 @(461.450,633.260) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 213)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2332                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1215/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1215/M4 @(468.320,633.260)  | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 214)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2332                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1215/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2289/M28 @(123.700,497.080) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 215)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3800                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2289/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2289/M20 @(117.320,496.850) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 216)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3800                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2289/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2289/M12 @(123.750,498.860) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 217)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3800                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2289/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2289/M4 @(116.880,498.860)  | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 218)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3800                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2289/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2295/M28 @(226.180,488.120) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 219)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3806                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2295/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2295/M20 @(219.800,487.890) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 220)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3806                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2295/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2295/M12 @(226.230,489.900) | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 221)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3806                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2295/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2295/M4 @(219.360,489.900)  | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 222)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3806                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2295/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2269/M30 @(321.500,466.120) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 223)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3785                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2269/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2269/M22 @(327.880,466.350) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 224)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3785                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2269/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2269/M12 @(321.505,464.340) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 225)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3785                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2269/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2269/M4 @(328.320,464.340)  | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 226)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3785                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2269/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1244/M30 @(266.200,550.375) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 227)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2349                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1244/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1244/M22 @(259.560,550.610) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 228)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2349                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1244/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1244/M12 @(265.830,552.150) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 229)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2349                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1244/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1244/M4 @(259.120,552.620)  | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 230)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2349                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1244/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2328/M27 @(491.740,430.315) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 231)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3837                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2328/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2328/M19 @(498.120,430.510) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 232)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3837                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2328/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2328/M12 @(491.930,428.920) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 233)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3837                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2328/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2328/M4 @(498.560,428.500)  | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 234)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3837                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2328/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2302/M28 @(528.140,470.200) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 235)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3816                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2302/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2302/M20 @(534.520,469.970) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 236)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3816                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2302/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2302/M12 @(528.090,471.980) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 237)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3816                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2302/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2302/M4 @(534.960,471.980)  | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 238)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3816                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2302/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1202/M30 @(402.700,667.320) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 239)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2319                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1202/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1202/M22 @(409.080,667.090) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 240)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2319                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1202/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1202/M12 @(402.705,669.100) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 241)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2319                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1202/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1202/M4 @(409.520,669.100)  | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 242)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2319                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1202/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1203/M30 @(469.900,586.680) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 243)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2320                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1203/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1203/M22 @(476.280,586.450) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 244)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2320                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1203/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1203/M12 @(469.905,588.460) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 245)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2320                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1203/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1203/M4 @(476.720,588.460)  | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 246)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2320                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1203/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2290/M28 @(132.660,461.240) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 247)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3801                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2290/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2290/M20 @(126.280,461.010) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 248)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3801                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2290/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2290/M12 @(132.710,463.020) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 249)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3801                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2290/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2290/M4 @(125.840,463.020)  | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 250)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3801                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2290/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2324/M27 @(211.740,439.275) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 251)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3836                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2324/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2324/M19 @(218.120,439.470) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 252)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3836                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2324/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2324/M12 @(211.930,437.880) | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 253)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3836                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2324/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2324/M4 @(218.560,437.460)  | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 254)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3836                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2324/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1605/M15 @(297.300,209.665) | Schematic Inst : \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 255)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3229                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1605/23 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1605/M0 @(297.300,212.140)  | Schematic Inst : \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 256)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3229                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1605/19 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1605/17                                | S: \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1596/M15 @(276.580,395.135) | Schematic Inst : \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 257)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3224                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1596/23 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1596/M0 @(276.580,392.660)  | Schematic Inst : \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 258)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3224                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1596/19 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1596/17                                | S: \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1628/M15 @(533.740,224.895) | Schematic Inst : \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 259)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3243                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1628/23 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1628/M0 @(533.740,222.420)  | Schematic Inst : \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 260)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3243                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1628/19 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1628/17                                | S: \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1636/M15 @(569.460,218.625) | Schematic Inst : \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 261)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3252                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1636/23 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1636/M0 @(569.460,221.100)  | Schematic Inst : \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 262)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3252                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1636/19 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1636/17                                | S: \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X850/M15 @(426.780,684.545)  | Schematic Inst : \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 263)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/1987                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X850/23  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X850/M0 @(426.780,687.020)   | Schematic Inst : \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 264)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/1987                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X850/19  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X3/X850/17                                 | S: \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X871/M15 @(556.140,672.895)  | Schematic Inst : \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 265)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/1999                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X871/23  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X871/M0 @(556.140,670.420)   | Schematic Inst : \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 266)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/1999                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X871/19  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X3/X871/17                                 | S: \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1571/M15 @(136.700,368.255) | Schematic Inst : \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 267)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3196                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1571/23 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1571/M0 @(136.700,365.780)  | Schematic Inst : \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 268)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3196                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1571/19 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1571/17                                | S: \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1581/M15 @(203.340,379.905) | Schematic Inst : \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 269)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3209                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1581/23 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1581/M0 @(203.340,382.380)  | Schematic Inst : \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 270)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3209                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1581/19 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1581/17                                | S: \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1669/M15 @(695.460,236.545) | Schematic Inst : u_core_u_rst_drain_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 271)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3276                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1669/23 .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_drain_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1669/M0 @(695.460,239.020)  | Schematic Inst : u_core_u_rst_drain_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 272)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3276                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1669/19 .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_drain_sync/\sync_q_reg[0]/net64
S: X2/X1669/17                                | S: u_core_u_rst_drain_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X895/M15 @(766.580,529.535)  | Schematic Inst : u_core_u_rst_fifo_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 273)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2037                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X895/23  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_fifo_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X895/M0 @(766.580,527.060)   | Schematic Inst : u_core_u_rst_fifo_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 274)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2037                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X895/19  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_fifo_sync/\sync_q_reg[0]/net64
S: X3/X895/17                                 | S: u_core_u_rst_fifo_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1697/M15 @(733.540,478.465) | Schematic Inst : u_core_u_rst_status_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 275)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3308                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1697/23 .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_status_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X1697/M0 @(733.540,480.940)  | Schematic Inst : u_core_u_rst_status_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 276)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3308                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X1697/19 .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_status_sync/\sync_q_reg[0]/net64
S: X2/X1697/17                                | S: u_core_u_rst_status_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X878/M15 @(614.820,699.775)  | Schematic Inst : u_core_u_rst_tx_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 277)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2007                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X878/23  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_tx_sync/\sync_q_reg[0]/net65
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X878/M0 @(614.820,697.300)   | Schematic Inst : u_core_u_rst_tx_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 278)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2007                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X878/19  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_tx_sync/\sync_q_reg[0]/net64
S: X3/X878/17                                 | S: u_core_u_rst_tx_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2176/M20 @(609.390,376.870) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM25
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 279)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3779                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2176/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MQIB
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2176/M28 @(615.870,377.480) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM58
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 280)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3779                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2176/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/SQIB
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2176/M12 @(616.250,374.740) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM48
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 281)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3779                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
S: X2/X2176/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/net55
D: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2176/M4 @(609.260,374.970)  | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM44
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 282)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3779                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
S: X2/X2176/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/net064
D: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2309/M28 @(717.860,367.560) | Schematic Inst : \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 283)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3833                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2309/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2309/M20 @(711.480,367.790) | Schematic Inst : \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 284)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3833                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2309/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2309/M12 @(717.910,365.780) | Schematic Inst : \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 285)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3833                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2309/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2309/M4 @(711.040,365.780)  | Schematic Inst : \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 286)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3833                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2309/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2304/M28 @(612.140,358.600) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 287)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3821                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2304/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2304/M20 @(618.520,358.830) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 288)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3821                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2304/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2304/M12 @(612.090,356.820) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 289)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3821                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2304/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2304/M4 @(618.960,356.820)  | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 290)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3821                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2304/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2303/M28 @(607.660,362.680) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 291)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3819                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2303/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2303/M20 @(614.040,362.450) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 292)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3819                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2303/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2303/M12 @(607.610,364.460) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 293)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3819                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2303/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2303/M4 @(614.480,364.460)  | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 294)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3819                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2303/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1218/M28 @(682.020,537.800) | Schematic Inst : \u_core_u_fifo_count_q_reg[5]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 295)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2338                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1218/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_count_q_reg[5]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1218/M20 @(675.640,538.030) | Schematic Inst : \u_core_u_fifo_count_q_reg[5]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 296)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2338                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1218/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_count_q_reg[5]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1218/M12 @(682.070,536.020) | Schematic Inst : \u_core_u_fifo_count_q_reg[5]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 297)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2338                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1218/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_count_q_reg[5]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1218/M4 @(675.200,536.020)  | Schematic Inst : \u_core_u_fifo_count_q_reg[5]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 298)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2338                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1218/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_count_q_reg[5]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2308/M28 @(690.980,362.680) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 299)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3831                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2308/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[0]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2308/M20 @(684.600,362.450) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 300)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3831                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2308/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2308/M12 @(691.030,364.460) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 301)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3831                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2308/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2308/M4 @(684.160,364.460)  | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 302)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3831                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2308/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2305/M28 @(666.900,362.680) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 303)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3822                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2305/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[1]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2305/M20 @(660.520,362.450) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 304)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3822                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2305/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[1]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2305/M12 @(666.950,364.460) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 305)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3822                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2305/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[1]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2305/M4 @(660.080,364.460)  | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 306)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3822                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2305/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[1]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2306/M28 @(668.580,389.560) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 307)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3825                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2306/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[2]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2306/M20 @(662.200,389.330) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 308)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3825                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2306/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[2]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2306/M12 @(668.630,391.340) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 309)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3825                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2306/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[2]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2306/M4 @(661.760,391.340)  | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 310)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3825                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2306/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[2]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2307/M28 @(676.980,394.440) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 311)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3828                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2307/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[3]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2307/M20 @(670.600,394.670) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 312)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3828                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2307/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[3]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2307/M12 @(677.030,392.660) | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 313)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3828                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2307/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[3]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2307/M4 @(670.160,392.660)  | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 314)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3828                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2307/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[3]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1220/M28 @(847.340,546.760) | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[2]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 315)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2341                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1220/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[2]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1220/M20 @(853.720,546.990) | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[2]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 316)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2341                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1220/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[2]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1220/M12 @(847.290,544.980) | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[2]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 317)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2341                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1220/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[2]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1220/M4 @(854.160,544.980)  | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[2]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 318)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2341                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1220/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[2]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1219/M28 @(839.940,528.840) | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[3]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 319)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2340                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1219/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[3]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1219/M20 @(833.560,529.070) | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[3]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 320)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2340                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1219/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[3]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1219/M12 @(839.990,527.060) | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[3]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 321)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2340                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1219/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[3]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X3/X1219/M4 @(833.120,527.060)  | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[3]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 322)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2340                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X3/X1219/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[3]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2274/M30 @(655.820,340.680) | Schematic Inst : \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 323)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3793                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2274/13 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/SQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2274/M22 @(662.200,340.910) | Schematic Inst : \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 324)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3793                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2274/11 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2274/M12 @(655.825,338.900) | Schematic Inst : \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 325)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3793                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2274/15 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2274/M4 @(662.640,338.900)  | Schematic Inst : \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 326)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3793                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2274/18 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2332/M27 @(678.220,452.245) | Schematic Inst : \u_core_u_meas_ctrl_state_q_reg[0]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 327)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3841                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2332/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_meas_ctrl_state_q_reg[0]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2332/M19 @(684.600,452.050) | Schematic Inst : \u_core_u_meas_ctrl_state_q_reg[0]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 328)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3841                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2332/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_meas_ctrl_state_q_reg[0]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2332/M12 @(678.410,453.640) | Schematic Inst : \u_core_u_meas_ctrl_state_q_reg[0]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 329)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3841                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2332/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_meas_ctrl_state_q_reg[0]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2332/M4 @(685.040,454.060)  | Schematic Inst : \u_core_u_meas_ctrl_state_q_reg[0]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 330)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3841                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2332/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_meas_ctrl_state_q_reg[0]/net61
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2331/M27 @(651.340,335.765) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM60
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 331)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3839                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2331/12 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/net032
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2331/M19 @(657.720,335.570) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM57
Layout Model: MP(PEI)                         | Schematic Model: MP(PEI)
==============================================+=================================================================================(mi 332)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3839                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2331/10 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MQI
S: VDD                                        | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2331/M12 @(651.530,337.160) | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM52
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 333)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3839                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2331/14 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/net59
S: VSS                                        | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                        
                                                                                                                                        
Layout Inst : X2/X2331/M4 @(658.160,337.580)  | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM20
Layout Model: MN(NEI)                         | Schematic Model: MN(NEI)
==============================================+=================================================================================(mi 334)
Terminal: Layout Net                          | Terminal: Schematic Net
----------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3839                                    | ** missing net **
** X1/1090 **                                 | G: tie1
                                              | 
D: X2/X2331/17 .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/net61
S: VSS                                        | S: VSS
B: VSS                                        | B: VSS


##############################################################################################################
#
#                                                END OF REPORT                                                
#
##############################################################################################################

