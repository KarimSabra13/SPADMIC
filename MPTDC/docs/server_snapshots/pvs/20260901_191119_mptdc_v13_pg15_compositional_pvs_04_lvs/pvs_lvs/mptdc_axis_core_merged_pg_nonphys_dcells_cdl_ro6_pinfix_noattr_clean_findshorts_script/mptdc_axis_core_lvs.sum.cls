##############################################################################################################
#####  
#####                                         PVS LVS COMPARISON
#####  
#####  Version                       :   22.22-s005
#####  NVN Run Start                 :   Tue Sep  1 19:15:42 2026
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
#####  
#####  Layout Design                 :   /sim/ksabra/SPADMIC_work/innovus/20260901_191119_mptdc_v13_pg15_compositional_pvs/outputs/mptdc_axis_core_merged_stdcell_ro6.gds (gdsii)
#####  Layout File                   :   /sim/ksabra/SPADMIC_work/innovus/20260901_191119_mptdc_v13_pg15_compositional_pvs/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script/mptdc_axis_core.spi (cdl)
#####  Schematic File                :   /sim/ksabra/SPADMIC_work/innovus/20260901_191119_mptdc_v13_pg15_compositional_pvs/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v (verilog)
#####  Schematic File                :   /data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl (cdl)
#####  Rules File                    :   /sim/ksabra/SPADMIC_work/innovus/20260901_191119_mptdc_v13_pg15_compositional_pvs/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script/.config.rul
#####                                :   /sim/ksabra/SPADMIC_work/innovus/20260901_191119_mptdc_v13_pg15_compositional_pvs/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script/.technology.rul
#####  HCell File                    :   /sim/ksabra/SPADMIC_work/innovus/20260901_191119_mptdc_v13_pg15_compositional_pvs/outputs/pvs_hcell_ro6.txt
#####  Pin Swap File                 :   mptdc_axis_core_lvs.sum.cps
#####  
#####  Extraction CPU Time           :   0h 0m 18s - (18s)
#####  Extraction Exec Time          :   0h 0m 19s - (19s)
#####  Extraction Peak Memory Usage  :   85.00MB
#####  NVN CPU Time                  :   0h 0m 9s - (9s)                 
#####  NVN Exec Time                 :   0h 0m 9s - (9s)                 
#####  NVN Peak Memory Usage         :   857.88MB
#####  LVS Total CPU Time            :   0h 0m 27s - (27s)               
#####  LVS Total Exec Time           :   0h 0m 28s - (28s)               
#####  LVS Total Peak Memory Usage   :   857.88MB
#####  
##############################################################################################################


##############################################################################################################
#
#                                            CELL MATCH STATISTICS                                            
#
##############################################################################################################

Cell Statistic Descriptions                  | Count
---------------------------------------------+----------
Cells matched                                |         0
Cells expanded                               |         0
Cells not run                                |         0
Cells which mismatch                         |         1
---------------------------------------------+----------
Total                                        |         1


Cell Statistic Detail                        | Count
---------------------------------------------+----------
Cells with parameter mismatches              |         0
Cells with mismatched instance subtypes      |         0
Cells that have been blackboxed              |         0


##############################################################################################################
#
#                                             CELL MATCH SUMMARY                                              
#
##############################################################################################################

                    |     Initial Pins     |     Compare Pins     |              | 
Cell                |   lay    :    sch    |   lay    :    sch    | Status       | Detail
--------------------+----------+-----------+----------+-----------+--------------+-----------
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
    layout_path                             /sim/ksabra/SPADMIC_work/innovus/20260901_191119_mptdc_v13_pg15_compositional_pvs/outputs/mptdc_axis_core_merged_stdcell_ro6.gds
    layout_format                           gdsii
    schematic_path                          /sim/ksabra/SPADMIC_work/innovus/20260901_191119_mptdc_v13_pg15_compositional_pvs/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v
                                            verilog -keep_backslash
    schematic_path                          /data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl
                                            cdl
    schematic_format                        SPICE
    lvs_write_netlist                       -layout netlistLAYOUT
    lvs_write_netlist                       -schematic netlistSOURCE
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
    // lvs_black_box                         
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
    lvs_global_sigs_are_ports               yes
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


                         |       Original       |       Filtered       |       Reduced        |   Unmatched   
Cell                     |    lay    :   sch    |    lay    :   sch    |    lay    :   sch    |  lay   : sch
-------------------------+-----------+----------+-----------+----------+-----------+----------+--------+------
MP [4 pins]              |           :          |           :          |           :          |        :      
 MP(PEI)                 |  *109,328 :  107,022 |  *109,328 :  107,022 |  *106,801 :  106,783 |    *18 :     0
 MP(PELI)                |    *1,240 :        0 |    *1,240 :        0 |      *108 :        0 |   *108 :     0
MN [4 pins] .  .  .  .  .|.  .  .  . :.  .  .   |.  .  .  . :.  .  .   |.  .  .  . :.  .  .   |.  .  . :.  .  
 MN(NEI)                 |  *108,727 :  106,937 |  *108,727 :  106,937 |  *106,831 :  106,797 |    *34 :     0
 MN(NELI)   .  .  .  .  .|.  .  *918 :.  .  . 0 |.  .  *918 :.  .  . 0 |.  .  *122 :.  .  . 0 |.  *122 :.  . 0
(R [3 pins], -)          |           :          |           :          |           :          |        :      
 (R(RNP1_3), -)   .  .  .|.  .  . *2 :.  .  . 0 |.  .  . *2 :.  .  . 0 |.  .  . *2 :.  .  . 0 |.  . *2 :.  . 0
(D [2 pins], -)          |           :          |           :          |           :          |        :      
 (D(P_DIPDNWMV), -)  .  .|.  .  *126 :.  .  . 0 |.  .  .  0 :.  .  . 0 |.  .  .  - :.  .  . - |.  .  - :.  . -
 (D(P_DDNWMV), -)        |        *3 :        0 |         0 :        0 |         - :        - |      - :     -
(C [2 pins], -)   .  .  .|.  .  .  . :.  .  .   |.  .  .  . :.  .  .   |.  .  .  . :.  .  .   |.  .  . :.  .  
 (C(CSF3), -)            |       *96 :        0 |       *96 :        0 |       *96 :        0 |    *96 :     0
(-, RO_tune6 [19 pins])  |           :          |           :          |           :          |        :      
 (-, RO_tune6())         |        *0 :        2 |        *0 :        2 |        *0 :        2 |     *0 :     2
-------------------------+-----------+----------+-----------+----------+-----------+----------+--------+------
Total                    |   220,440 :  213,961 |   220,311 :  213,961 |   213,960 :  213,582 |    380 :     2
=========================+===========+==========+===========+==========+===========+==========+========+======
Pins                     |           :          |           :          |        59 :       59 |      0 :     0
Nets                     |           :          |           :          |  *119,993 :  119,903 |      0 :     0
=========================+===========+==========+===========+==========+===========+==========+========+======

+===[mptdc_axis_core]=========================================================================================
|                                      DEVICES REMOVED DURING REDUCTION                                       
+=============================================================================================================


                |      Parallel       |      Series       |     Deleted Nets     
Cell            |    lay    :   sch   |   lay   :   sch   |    lay    :   sch
----------------+-----------+---------+---------+---------+-----------+----------
MP [4 pins]     |           :         |         :         |           :          
 MP(PEI)        |     2,527 :     239 |       - :       - |         0 :         0
 MP(PELI)       |     1,132 :       - |       - :       - |         0 :         0
MN [4 pins]     |           :         |         :         |           :          
 MN(NEI)        |     1,896 :     140 |       - :       - |         0 :         0
 MN(NELI)       |       796 :       - |       - :       - |         0 :         0
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
|                                            MISMATCHED INSTANCES                                             
+=============================================================================================================
                                                                                                              
                                                                                                              
Layout Inst : ** missing inst **                           | Schematic Inst : u_core_u_osc_fast_u_ro_tune4
Layout Model:                                              | Schematic Model: RO_tune6
===========================================================+============================================(mi 1)
                                                                                                              
                                                                                                              
Layout Inst : ** missing inst **                           | Schematic Inst : u_core_u_osc_slow_u_ro_tune4
Layout Model:                                              | Schematic Model: RO_tune6
===========================================================+============================================(mi 2)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/M10 @(125.155,225.175)                 | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+============================================(mi 3)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/M13 @(130.640,224.115)                 | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+============================================(mi 4)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/M14 @(133.770,223.395)                 | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+============================================(mi 5)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/M15 @(134.490,223.395)                 | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+============================================(mi 6)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/M16 @(135.210,223.395)                 | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+============================================(mi 7)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/M17 @(136.400,223.395)                 | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+============================================(mi 8)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/M19 @(164.865,225.175)                 | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+============================================(mi 9)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/X202/M6 @(149.060,167.770)         | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 10)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/X218/M9 @(172.820,178.230)         | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 11)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C16 @(120.555,209.875)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 12)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C17 @(120.555,199.075)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 13)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C18 @(120.555,188.275)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 14)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C19 @(120.555,177.475)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 15)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C20 @(125.035,209.875)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 16)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C21 @(125.035,199.075)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 17)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C22 @(125.035,188.275)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 18)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C23 @(125.035,177.475)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 19)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C24 @(129.515,209.875)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 20)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C25 @(129.515,199.075)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 21)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C26 @(129.515,188.275)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 22)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C27 @(129.515,177.475)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 23)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C28 @(133.995,209.875)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 24)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C29 @(133.995,199.075)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 25)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C30 @(133.995,188.275)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 26)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C31 @(133.995,177.475)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 27)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C32 @(183.515,209.870)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 28)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C33 @(183.515,199.070)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 29)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C34 @(183.515,188.270)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 30)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C35 @(183.515,177.470)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 31)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C36 @(187.995,209.870)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 32)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C37 @(187.995,199.070)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 33)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C38 @(187.995,188.270)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 34)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C39 @(187.995,177.470)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 35)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C40 @(192.475,209.870)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 36)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C41 @(192.475,199.070)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 37)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C42 @(192.475,188.270)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 38)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C43 @(192.475,177.470)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 39)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C44 @(196.955,209.870)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 40)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C45 @(196.955,199.070)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 41)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C46 @(196.955,188.270)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 42)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C47 @(196.955,177.470)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 43)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C48 @(201.435,209.870)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 44)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C49 @(201.435,199.070)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 45)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C50 @(201.435,188.270)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 46)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C51 @(201.435,177.470)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 47)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C52 @(205.915,209.870)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 48)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C53 @(205.915,199.070)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 49)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C54 @(205.915,188.270)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 50)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C55 @(205.915,177.470)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 51)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C56 @(210.395,209.870)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 52)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C57 @(210.395,199.070)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 53)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C58 @(210.395,188.270)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 54)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C59 @(210.395,177.470)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 55)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C60 @(214.875,209.870)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 56)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C61 @(214.875,199.070)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 57)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C62 @(214.875,188.270)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 58)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X22/C63 @(214.875,177.470)             | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+===========================================(mi 59)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/M3 @(126.595,227.235)                  | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 60)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/M4 @(130.505,227.235)                  | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 61)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/M5 @(144.290,227.235)                  | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 62)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X13/M3 @(61.490,176.275)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 63)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X13/M4 @(58.940,178.325)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 64)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X13/M0 @(61.490,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 65)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X13/M1 @(59.285,175.220)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 66)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X13/M2 @(59.045,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 67)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X14/M3 @(66.280,176.275)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 68)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X14/M4 @(63.730,178.325)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 69)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X14/M0 @(66.280,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 70)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X14/M1 @(64.075,175.220)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 71)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X14/M2 @(63.835,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 72)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X15/M3 @(71.070,176.275)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 73)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X15/M4 @(68.520,178.325)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 74)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X15/M0 @(71.070,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 75)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X15/M1 @(68.865,175.220)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 76)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X15/M2 @(68.625,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 77)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X16/M3 @(75.860,176.275)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 78)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X16/M4 @(73.310,178.325)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 79)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X16/M0 @(75.860,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 80)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X16/M1 @(73.655,175.220)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 81)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X16/M2 @(73.415,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 82)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X17/M3 @(80.650,176.275)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 83)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X17/M4 @(78.100,178.325)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 84)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X17/M0 @(80.650,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 85)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X17/M1 @(78.445,175.220)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 86)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X17/M2 @(78.205,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 87)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X18/M3 @(85.440,176.275)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 88)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X18/M4 @(82.890,178.325)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 89)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X18/M0 @(85.440,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 90)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X18/M1 @(83.235,175.220)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 91)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X18/M2 @(82.995,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 92)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X19/M3 @(90.230,176.275)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 93)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X19/M4 @(87.680,178.325)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 94)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X19/M0 @(90.230,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 95)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X19/M1 @(88.025,175.220)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 96)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X19/M2 @(87.785,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 97)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X20/M3 @(95.020,176.275)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 98)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X20/M4 @(92.470,178.325)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+===========================================(mi 99)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X20/M0 @(95.020,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 100)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X20/M1 @(92.815,175.220)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 101)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X20/M2 @(92.575,171.040)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 102)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/M57 @(79.860,188.415)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 103)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/M87 @(92.460,188.415)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 104)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/M99 @(97.500,188.415)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 105)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/M113 @(103.380,188.415)            | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 106)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/M120 @(106.740,195.610)            | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 107)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/M123 @(107.580,188.415)            | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 108)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/M125 @(108.420,188.415)            | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 109)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X21/M16 @(69.780,204.050)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 110)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/X24/M60 @(106.740,202.190)         | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 111)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X33/R130 @(59.500,216.150)             | Schematic Inst : ** missing inst **
Layout Model: R(RNP1_3)                                    | Schematic Model: 
===========================================================+==========================================(mi 112)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X59/M8 @(150.390,206.220)              | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 113)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X59/M10 @(152.230,209.100)             | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 114)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X59/M0 @(150.640,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 115)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X59/M1 @(151.360,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 116)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X59/M2 @(152.080,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 117)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X59/M3 @(152.800,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 118)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X60/M9 @(157.030,205.500)              | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 119)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X60/M12 @(158.870,207.660)             | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 120)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X60/M0 @(157.280,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 121)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X60/M1 @(158.000,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 122)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X60/M2 @(158.720,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 123)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X60/M3 @(159.440,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 124)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X61/M9 @(163.670,205.500)              | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 125)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X61/M10 @(165.510,209.100)             | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 126)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X61/M0 @(163.920,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 127)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X61/M1 @(164.640,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 128)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X61/M2 @(165.360,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 129)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X61/M3 @(166.080,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 130)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X62/M4 @(170.310,209.100)              | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 131)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X62/M10 @(172.150,209.100)             | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 132)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X62/M0 @(170.560,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 133)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X62/M1 @(171.280,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 134)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X62/M2 @(172.000,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 135)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X62/M3 @(172.720,213.960)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 136)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X67/M1 @(128.435,225.175)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 137)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X67/M0 @(128.435,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 138)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X68/M1 @(139.730,225.175)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 139)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X68/M0 @(139.730,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 140)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X69/M0 @(133.770,227.135)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 141)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X70/M0 @(136.390,227.135)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 142)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X71/M3 @(142.130,225.175)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 143)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/M2 @(145.010,225.175)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 144)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/M3 @(151.215,224.115)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 145)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/M4 @(154.345,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 146)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/M5 @(155.065,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 147)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/M6 @(155.785,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 148)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/M7 @(156.975,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 149)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/M0 @(145.010,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 150)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/M1 @(151.080,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 151)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/X19/M1 @(149.010,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 152)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/X19/M0 @(149.010,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 153)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/X20/M1 @(160.305,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 154)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/X20/M0 @(160.305,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 155)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/X21/M0 @(154.345,227.135)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 156)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/X22/M0 @(156.965,227.135)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 157)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X72/X24/M2 @(164.145,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 158)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/M3 @(171.790,224.115)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 159)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/M4 @(174.920,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 160)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/M5 @(175.640,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 161)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/M6 @(176.360,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 162)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/M7 @(177.550,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 163)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/M1 @(171.655,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 164)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/X19/M1 @(169.585,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 165)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/X19/M0 @(169.585,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 166)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/X20/M1 @(180.880,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 167)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/X20/M0 @(180.880,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 168)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/X21/M0 @(174.920,227.135)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 169)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/X22/M0 @(177.540,227.135)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 170)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/X23/M5 @(166.485,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 171)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/X23/M0 @(167.925,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 172)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/X24/M3 @(183.280,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 173)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X73/X24/M2 @(184.720,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 174)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/M2 @(186.160,225.175)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 175)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/M3 @(192.365,224.115)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 176)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/M4 @(195.495,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 177)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/M5 @(196.215,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 178)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/M6 @(196.935,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 179)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/M7 @(198.125,223.395)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 180)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/M1 @(192.230,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 181)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/X19/M1 @(190.160,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 182)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/X19/M0 @(190.160,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 183)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/X20/M1 @(201.455,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 184)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/X20/M0 @(201.455,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 185)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/X21/M0 @(195.495,227.135)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 186)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/X22/M0 @(198.115,227.135)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 187)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/X23/M0 @(188.500,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 188)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/X24/M3 @(203.855,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 189)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X74/X24/M2 @(205.295,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 190)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X75/M10 @(116.650,225.175)             | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 191)
                                                                                                              
                                                                                                              
Layout Inst : X0/X0/X75/M2 @(117.375,226.925)              | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 192)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M10 @(125.155,656.765)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 193)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M13 @(130.640,657.825)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 194)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M14 @(133.770,658.545)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 195)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M15 @(134.490,658.545)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 196)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M16 @(135.210,658.545)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 197)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M17 @(136.400,658.545)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 198)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M18 @(144.290,656.765)              | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 199)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/X194/M12 @(155.130,692.470)     | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 200)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/X203/M15 @(176.940,714.160)     | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 201)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C16 @(120.555,672.065)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 202)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C17 @(120.555,682.865)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 203)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C18 @(120.555,693.665)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 204)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C19 @(120.555,704.465)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 205)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C20 @(125.035,672.065)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 206)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C21 @(125.035,682.865)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 207)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C22 @(125.035,693.665)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 208)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C23 @(125.035,704.465)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 209)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C24 @(129.515,672.065)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 210)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C25 @(129.515,682.865)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 211)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C26 @(129.515,693.665)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 212)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C27 @(129.515,704.465)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 213)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C28 @(133.995,672.065)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 214)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C29 @(133.995,682.865)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 215)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C30 @(133.995,693.665)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 216)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C31 @(133.995,704.465)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 217)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C32 @(183.515,672.070)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 218)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C33 @(183.515,682.870)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 219)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C34 @(183.515,693.670)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 220)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C35 @(183.515,704.470)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 221)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C36 @(187.995,672.070)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 222)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C37 @(187.995,682.870)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 223)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C38 @(187.995,693.670)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 224)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C39 @(187.995,704.470)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 225)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C40 @(192.475,672.070)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 226)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C41 @(192.475,682.870)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 227)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C42 @(192.475,693.670)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 228)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C43 @(192.475,704.470)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 229)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C44 @(196.955,672.070)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 230)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C45 @(196.955,682.870)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 231)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C46 @(196.955,693.670)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 232)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C47 @(196.955,704.470)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 233)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C48 @(201.435,672.070)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 234)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C49 @(201.435,682.870)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 235)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C50 @(201.435,693.670)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 236)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C51 @(201.435,704.470)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 237)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C52 @(205.915,672.070)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 238)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C53 @(205.915,682.870)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 239)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C54 @(205.915,693.670)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 240)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C55 @(205.915,704.470)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 241)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C56 @(210.395,672.070)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 242)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C57 @(210.395,682.870)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 243)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C58 @(210.395,693.670)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 244)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C59 @(210.395,704.470)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 245)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C60 @(214.875,672.070)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 246)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C61 @(214.875,682.870)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 247)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C62 @(214.875,693.670)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 248)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X22/C63 @(214.875,704.470)          | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                      | Schematic Model: 
===========================================================+==========================================(mi 249)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M3 @(126.595,654.705)               | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 250)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M4 @(130.505,654.705)               | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 251)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M5 @(144.290,654.705)               | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 252)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/M7 @(185.440,654.705)               | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 253)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X13/M3 @(61.490,705.665)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 254)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X13/M4 @(58.940,703.615)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 255)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X13/M0 @(61.490,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 256)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X13/M1 @(59.285,706.720)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 257)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X13/M2 @(59.045,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 258)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X14/M3 @(66.280,705.665)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 259)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X14/M4 @(63.730,703.615)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 260)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X14/M0 @(66.280,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 261)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X14/M1 @(64.075,706.720)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 262)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X14/M2 @(63.835,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 263)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X15/M3 @(71.070,705.665)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 264)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X15/M4 @(68.520,703.615)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 265)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X15/M0 @(71.070,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 266)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X15/M1 @(68.865,706.720)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 267)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X15/M2 @(68.625,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 268)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X16/M3 @(75.860,705.665)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 269)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X16/M4 @(73.310,703.615)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 270)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X16/M0 @(75.860,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 271)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X16/M1 @(73.655,706.720)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 272)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X16/M2 @(73.415,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 273)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X17/M3 @(80.650,705.665)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 274)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X17/M4 @(78.100,703.615)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 275)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X17/M0 @(80.650,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 276)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X17/M1 @(78.445,706.720)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 277)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X17/M2 @(78.205,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 278)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X18/M3 @(85.440,705.665)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 279)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X18/M4 @(82.890,703.615)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 280)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X18/M0 @(85.440,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 281)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X18/M1 @(83.235,706.720)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 282)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X18/M2 @(82.995,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 283)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X19/M3 @(90.230,705.665)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 284)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X19/M4 @(87.680,703.615)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 285)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X19/M0 @(90.230,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 286)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X19/M1 @(88.025,706.720)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 287)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X19/M2 @(87.785,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 288)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X20/M3 @(95.020,705.665)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 289)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X20/M4 @(92.470,703.615)        | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 290)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X20/M0 @(95.020,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 291)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X20/M1 @(92.815,706.720)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 292)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X20/M2 @(92.575,710.900)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 293)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/M21 @(64.740,693.525)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 294)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/M77 @(88.260,693.525)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 295)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/M107 @(100.860,693.525)         | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 296)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/M110 @(102.540,686.330)         | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 297)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/M113 @(103.380,693.525)         | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 298)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/M123 @(107.580,693.525)         | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 299)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/M125 @(108.420,693.525)         | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 300)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X22/M47 @(95.820,684.470)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 301)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/X23/M20 @(73.140,673.170)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 302)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X33/R130 @(59.500,665.790)          | Schematic Inst : ** missing inst **
Layout Model: R(RNP1_3)                                    | Schematic Model: 
===========================================================+==========================================(mi 303)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X59/M6 @(150.390,674.280)           | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 304)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X59/M12 @(152.230,674.280)          | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 305)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X59/M0 @(150.640,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 306)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X59/M1 @(151.360,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 307)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X59/M2 @(152.080,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 308)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X59/M3 @(152.800,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 309)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X60/M5 @(157.030,673.560)           | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 310)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X60/M12 @(158.870,674.280)          | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 311)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X60/M0 @(157.280,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 312)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X60/M1 @(158.000,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 313)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X60/M2 @(158.720,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 314)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X60/M3 @(159.440,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 315)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X61/M7 @(163.670,675.000)           | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 316)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X61/M10 @(165.510,672.840)          | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 317)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X61/M0 @(163.920,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 318)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X61/M1 @(164.640,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 319)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X61/M2 @(165.360,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 320)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X61/M3 @(166.080,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 321)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X62/M7 @(170.310,675.000)           | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 322)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X62/M15 @(172.150,676.440)          | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 323)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X62/M0 @(170.560,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 324)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X62/M1 @(171.280,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 325)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X62/M2 @(172.000,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 326)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X62/M3 @(172.720,667.980)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 327)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X67/M1 @(128.435,656.765)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 328)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X67/M0 @(128.435,654.705)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 329)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X68/M1 @(139.730,656.765)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 330)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X68/M0 @(139.730,654.705)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 331)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X69/M0 @(133.770,654.805)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 332)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X70/M0 @(136.390,654.805)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 333)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/M3 @(151.215,657.825)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 334)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/M4 @(154.345,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 335)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/M5 @(155.065,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 336)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/M6 @(155.785,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 337)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/M7 @(156.975,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 338)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/M1 @(151.080,654.705)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 339)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/X19/M1 @(149.010,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 340)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/X19/M0 @(149.010,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 341)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/X20/M1 @(160.305,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 342)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/X20/M0 @(160.305,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 343)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/X21/M0 @(154.345,654.805)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 344)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/X22/M0 @(156.965,654.805)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 345)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/X23/M5 @(145.910,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 346)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/X23/M1 @(146.630,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 347)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/X24/M3 @(162.705,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 348)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X72/X24/M0 @(162.705,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 349)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/M2 @(165.585,656.765)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 350)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/M3 @(171.790,657.825)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 351)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/M4 @(174.920,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 352)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/M5 @(175.640,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 353)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/M6 @(176.360,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 354)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/M7 @(177.550,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 355)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/M0 @(165.585,654.705)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 356)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/M1 @(171.655,654.705)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 357)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/X19/M1 @(169.585,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 358)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/X19/M0 @(169.585,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 359)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/X20/M1 @(180.880,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 360)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/X20/M0 @(180.880,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 361)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/X21/M0 @(174.920,654.805)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 362)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/X22/M0 @(177.540,654.805)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 363)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X73/X24/M3 @(183.280,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 364)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/M2 @(186.160,656.765)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 365)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/M3 @(192.365,657.825)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 366)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/M4 @(195.495,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 367)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/M5 @(196.215,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 368)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/M6 @(196.935,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 369)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/M7 @(198.125,658.545)           | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 370)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/M1 @(192.230,654.705)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 371)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/X19/M1 @(190.160,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 372)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/X19/M0 @(190.160,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 373)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/X20/M1 @(201.455,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 374)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/X20/M0 @(201.455,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 375)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/X21/M0 @(195.495,654.805)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 376)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/X22/M0 @(198.115,654.805)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 377)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/X23/M0 @(188.500,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 378)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/X24/M3 @(203.855,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 379)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X74/X24/M1 @(204.575,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                     | Schematic Model: 
===========================================================+==========================================(mi 380)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X75/M13 @(118.600,656.765)          | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 381)
                                                                                                              
                                                                                                              
Layout Inst : X3/X5127/X75/M5 @(119.615,655.015)           | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                      | Schematic Model: 
===========================================================+==========================================(mi 382)


##############################################################################################################
#
#                                                END OF REPORT                                                
#
##############################################################################################################

