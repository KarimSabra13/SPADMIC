##############################################################################################################
#####  
#####                                         PVS LVS COMPARISON
#####  
#####  Version                       :   22.22-s005
#####  NVN Run Start                 :   Wed Aug 26 21:27:18 2026
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
#####  Layout Design                 :   /sim/ksabra/SPADMIC_work/innovus/20260826_mptdc_bufftap0_v6r_diagnostic_base_lvs_212334/outputs/mptdc_axis_core_merged_stdcell_ro6.gds (gdsii)
#####  Layout File                   :   /sim/ksabra/SPADMIC_work/innovus/20260826_mptdc_bufftap0_v6r_diagnostic_base_lvs_212334/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script/mptdc_axis_core.spi (cdl)
#####  Schematic File                :   /sim/ksabra/SPADMIC_work/innovus/20260826_mptdc_bufftap0_v6r_diagnostic_base_lvs_212334/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v (verilog)
#####  Schematic File                :   /data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl (cdl)
#####  Rules File                    :   /sim/ksabra/SPADMIC_work/innovus/20260826_mptdc_bufftap0_v6r_diagnostic_base_lvs_212334/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script/.config.rul
#####                                :   /sim/ksabra/SPADMIC_work/innovus/20260826_mptdc_bufftap0_v6r_diagnostic_base_lvs_212334/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script/.technology.rul
#####  HCell File                    :   /sim/ksabra/SPADMIC_work/innovus/20260826_mptdc_bufftap0_v6r_diagnostic_base_lvs_212334/outputs/pvs_hcell_ro6.txt
#####  Pin Swap File                 :   mptdc_axis_core_lvs.sum.cps
#####  
#####  Extraction CPU Time           :   0h 0m 17s - (17s)
#####  Extraction Exec Time          :   0h 0m 18s - (18s)
#####  Extraction Peak Memory Usage  :   85.00MB
#####  NVN CPU Time                  :   0h 0m 9s - (9s)                 
#####  NVN Exec Time                 :   0h 0m 10s - (10s)               
#####  NVN Peak Memory Usage         :   859.33MB
#####  LVS Total CPU Time            :   0h 0m 26s - (26s)               
#####  LVS Total Exec Time           :   0h 0m 28s - (28s)               
#####  LVS Total Peak Memory Usage   :   859.33MB
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
mptdc_axis_core     |       59 :        59 |      *59 :        60 | mismatch     | 


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
    layout_path                             /sim/ksabra/SPADMIC_work/innovus/20260826_mptdc_bufftap0_v6r_diagnostic_base_lvs_212334/outputs/mptdc_axis_core_merged_stdcell_ro6.gds
    layout_format                           gdsii
    schematic_path                          /sim/ksabra/SPADMIC_work/innovus/20260826_mptdc_bufftap0_v6r_diagnostic_base_lvs_212334/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v
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
 MP(PEI)                 |  *109,158 :  106,852 |  *109,158 :  106,852 |  *106,716 :  106,698 |    *18 :     0
 MP(PELI)                |    *1,240 :        0 |    *1,240 :        0 |      *108 :        0 |   *108 :     0
MN [4 pins] .  .  .  .  .|.  .  .  . :.  .  .   |.  .  .  . :.  .  .   |.  .  .  . :.  .  .   |.  .  . :.  .  
 MN(NEI)                 |  *108,642 :  106,852 |  *108,642 :  106,852 |  *106,746 :  106,712 |    *34 :     0
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
Total                    |   220,185 :  213,706 |   220,056 :  213,706 |   213,790 :  213,412 |    380 :     2
=========================+===========+==========+===========+==========+===========+==========+========+======
Pins                     |           :          |           :          |       *59 :       60 |      0 :     0
Nets                     |           :          |           :          |  *119,916 :  119,733 |    *90 :     0
=========================+===========+==========+===========+==========+===========+==========+========+======

+===[mptdc_axis_core]=========================================================================================
|                                      DEVICES REMOVED DURING REDUCTION                                       
+=============================================================================================================


                |      Parallel       |      Series       |     Deleted Nets     
Cell            |    lay    :   sch   |   lay   :   sch   |    lay    :   sch
----------------+-----------+---------+---------+---------+-----------+----------
MP [4 pins]     |           :         |         :         |           :          
 MP(PEI)        |     2,442 :     154 |       - :       - |         0 :         0
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
|                                               MISMATCHED NETS                                               
+=============================================================================================================
                                                                                                               
                                                                                                               
Layout Net: X1/1083       | Schematic Pin: tie1
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
                                                                                                               
                                                                                                               
Layout Net: X2/3890       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 2)
                                                                                                               
                                                                                                               
Layout Net: X2/3802       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 3)
                                                                                                               
                                                                                                               
Layout Net: X2/3889       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 4)
                                                                                                               
                                                                                                               
Layout Net: X1/1081       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 5)
                                                                                                               
                                                                                                               
Layout Net: X1/1052       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 6)
                                                                                                               
                                                                                                               
Layout Net: X2/3784       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 7)
                                                                                                               
                                                                                                               
Layout Net: X2/3820       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 8)
                                                                                                               
                                                                                                               
Layout Net: X3/2355       | Schematic Net: ** missing net **
==========================+==============================================================================(mn 9)
                                                                                                               
                                                                                                               
Layout Net: X1/1090       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 10)
                                                                                                               
                                                                                                               
Layout Net: X3/2353       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 11)
                                                                                                               
                                                                                                               
Layout Net: X2/3814       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 12)
                                                                                                               
                                                                                                               
Layout Net: X3/2351       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 13)
                                                                                                               
                                                                                                               
Layout Net: X2/3780       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 14)
                                                                                                               
                                                                                                               
Layout Net: X3/2349       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 15)
                                                                                                               
                                                                                                               
Layout Net: X2/3811       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 16)
                                                                                                               
                                                                                                               
Layout Net: X3/2343       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 17)
                                                                                                               
                                                                                                               
Layout Net: X2/3887       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 18)
                                                                                                               
                                                                                                               
Layout Net: X2/3801       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 19)
                                                                                                               
                                                                                                               
Layout Net: X1/1053       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 20)
                                                                                                               
                                                                                                               
Layout Net: X2/3809       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 21)
                                                                                                               
                                                                                                               
Layout Net: X3/2335       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 22)
                                                                                                               
                                                                                                               
Layout Net: X2/3886       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 23)
                                                                                                               
                                                                                                               
Layout Net: X3/2332       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 24)
                                                                                                               
                                                                                                               
Layout Net: X2/3807       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 25)
                                                                                                               
                                                                                                               
Layout Net: X3/2330       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 26)
                                                                                                               
                                                                                                               
Layout Net: X1/1082       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 27)
                                                                                                               
                                                                                                               
Layout Net: X2/3805       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 28)
                                                                                                               
                                                                                                               
Layout Net: X3/2319       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 29)
                                                                                                               
                                                                                                               
Layout Net: X2/3885       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 30)
                                                                                                               
                                                                                                               
Layout Net: X2/3794       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 31)
                                                                                                               
                                                                                                               
Layout Net: X2/3884       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 32)
                                                                                                               
                                                                                                               
Layout Net: X2/3842       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 33)
                                                                                                               
                                                                                                               
Layout Net: X2/3791       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 34)
                                                                                                               
                                                                                                               
Layout Net: X2/3840       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 35)
                                                                                                               
                                                                                                               
Layout Net: X2/3839       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 36)
                                                                                                               
                                                                                                               
Layout Net: X2/3789       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 37)
                                                                                                               
                                                                                                               
Layout Net: X2/3838       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 38)
                                                                                                               
                                                                                                               
Layout Net: X1/1058       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 39)
                                                                                                               
                                                                                                               
Layout Net: X2/3837       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 40)
                                                                                                               
                                                                                                               
Layout Net: X2/3788       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 41)
                                                                                                               
                                                                                                               
Layout Net: X2/3836       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 42)
                                                                                                               
                                                                                                               
Layout Net: X2/3835       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 43)
                                                                                                               
                                                                                                               
Layout Net: X2/3787       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 44)
                                                                                                               
                                                                                                               
Layout Net: X2/3834       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 45)
                                                                                                               
                                                                                                               
Layout Net: X2/3832       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 46)
                                                                                                               
                                                                                                               
Layout Net: X2/3786       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 47)
                                                                                                               
                                                                                                               
Layout Net: X2/3829       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 48)
                                                                                                               
                                                                                                               
Layout Net: X1/1051       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 49)
                                                                                                               
                                                                                                               
Layout Net: X2/3823       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 50)
                                                                                                               
                                                                                                               
Layout Net: X2/3822       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 51)
                                                                                                               
                                                                                                               
Layout Net: X3/2356       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 52)
                                                                                                               
                                                                                                               
Layout Net: X2/3783       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 53)
                                                                                                               
                                                                                                               
Layout Net: X3/2352       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 54)
                                                                                                               
                                                                                                               
Layout Net: X2/3812       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 55)
                                                                                                               
                                                                                                               
Layout Net: X3/2348       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 56)
                                                                                                               
                                                                                                               
Layout Net: X1/1089       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 57)
                                                                                                               
                                                                                                               
Layout Net: X3/2338       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 58)
                                                                                                               
                                                                                                               
Layout Net: X2/3808       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 59)
                                                                                                               
                                                                                                               
Layout Net: X3/2331       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 60)
                                                                                                               
                                                                                                               
Layout Net: X3/2322       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 61)
                                                                                                               
                                                                                                               
Layout Net: X3/2320       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 62)
                                                                                                               
                                                                                                               
Layout Net: X2/3803       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 63)
                                                                                                               
                                                                                                               
Layout Net: X2/3826       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 64)
                                                                                                               
                                                                                                               
Layout Net: X2/3785       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 65)
                                                                                                               
                                                                                                               
Layout Net: X1/1091       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 66)
                                                                                                               
                                                                                                               
Layout Net: X1/1055       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 67)
                                                                                                               
                                                                                                               
Layout Net: X3/2357       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 68)
                                                                                                               
                                                                                                               
Layout Net: X3/2354       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 69)
                                                                                                               
                                                                                                               
Layout Net: X2/3817       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 70)
                                                                                                               
                                                                                                               
Layout Net: X3/2350       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 71)
                                                                                                               
                                                                                                               
Layout Net: X3/2341       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 72)
                                                                                                               
                                                                                                               
Layout Net: X2/3810       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 73)
                                                                                                               
                                                                                                               
Layout Net: X3/2340       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 74)
                                                                                                               
                                                                                                               
Layout Net: X3/2333       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 75)
                                                                                                               
                                                                                                               
Layout Net: X3/2325       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 76)
                                                                                                               
                                                                                                               
Layout Net: X2/3806       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 77)
                                                                                                               
                                                                                                               
Layout Net: X2/3804       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 78)
                                                                                                               
                                                                                                               
Layout Net: X2/3230       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 79)
                                                                                                               
                                                                                                               
Layout Net: X2/3309       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 80)
                                                                                                               
                                                                                                               
Layout Net: X2/3225       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 81)
                                                                                                               
                                                                                                               
Layout Net: X3/1999       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 82)
                                                                                                               
                                                                                                               
Layout Net: X2/3244       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 83)
                                                                                                               
                                                                                                               
Layout Net: X2/3277       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 84)
                                                                                                               
                                                                                                               
Layout Net: X1/924        | Schematic Net: ** missing net **
==========================+=============================================================================(mn 85)
                                                                                                               
                                                                                                               
Layout Net: X3/2037       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 86)
                                                                                                               
                                                                                                               
Layout Net: X2/3210       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 87)
                                                                                                               
                                                                                                               
Layout Net: X3/2007       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 88)
                                                                                                               
                                                                                                               
Layout Net: X3/1987       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 89)
                                                                                                               
                                                                                                               
Layout Net: X2/3197       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 90)
                                                                                                               
                                                                                                               
Layout Net: X2/3253       | Schematic Net: ** missing net **
==========================+=============================================================================(mn 91)


++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++ Truncated to 100 entries, to adjust this use the -mismatched_net_limit option in the lvs_report_max rule 
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


+===[mptdc_axis_core]=========================================================================================
|                                            MISMATCHED INSTANCES                                             
+=============================================================================================================
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : ** missing inst **                       | Schematic Inst : u_core_u_osc_fast_u_ro_tune4
Layout Model:                                          | Schematic Model: RO_tune6
=======================================================+===================================================================================(mi 1)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : ** missing inst **                       | Schematic Inst : u_core_u_osc_slow_u_ro_tune4
Layout Model:                                          | Schematic Model: RO_tune6
=======================================================+===================================================================================(mi 2)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M12 @(126.595,225.175)             | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+===================================================================================(mi 3)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M13 @(130.640,224.115)             | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+===================================================================================(mi 4)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M14 @(133.770,223.395)             | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+===================================================================================(mi 5)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M15 @(134.490,223.395)             | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+===================================================================================(mi 6)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M16 @(135.210,223.395)             | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+===================================================================================(mi 7)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M17 @(136.400,223.395)             | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+===================================================================================(mi 8)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M20 @(185.440,225.175)             | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+===================================================================================(mi 9)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M21 @(206.015,225.175)             | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 10)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/X203/M7 @(168.620,167.780)     | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 11)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/X221/M8 @(171.780,173.470)     | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 12)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C16 @(120.555,209.875)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 13)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C17 @(120.555,199.075)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 14)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C18 @(120.555,188.275)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 15)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C19 @(120.555,177.475)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 16)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C20 @(125.035,209.875)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 17)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C21 @(125.035,199.075)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 18)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C22 @(125.035,188.275)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 19)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C23 @(125.035,177.475)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 20)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C24 @(129.515,209.875)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 21)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C25 @(129.515,199.075)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 22)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C26 @(129.515,188.275)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 23)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C27 @(129.515,177.475)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 24)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C28 @(133.995,209.875)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 25)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C29 @(133.995,199.075)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 26)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C30 @(133.995,188.275)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 27)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C31 @(133.995,177.475)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 28)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C32 @(183.515,209.870)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 29)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C33 @(183.515,199.070)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 30)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C34 @(183.515,188.270)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 31)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C35 @(183.515,177.470)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 32)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C36 @(187.995,209.870)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 33)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C37 @(187.995,199.070)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 34)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C38 @(187.995,188.270)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 35)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C39 @(187.995,177.470)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 36)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C40 @(192.475,209.870)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 37)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C41 @(192.475,199.070)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 38)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C42 @(192.475,188.270)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 39)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C43 @(192.475,177.470)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 40)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C44 @(196.955,209.870)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 41)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C45 @(196.955,199.070)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 42)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C46 @(196.955,188.270)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 43)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C47 @(196.955,177.470)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 44)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C48 @(201.435,209.870)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 45)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C49 @(201.435,199.070)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 46)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C50 @(201.435,188.270)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 47)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C51 @(201.435,177.470)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 48)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C52 @(205.915,209.870)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 49)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C53 @(205.915,199.070)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 50)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C54 @(205.915,188.270)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 51)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C55 @(205.915,177.470)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 52)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C56 @(210.395,209.870)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 53)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C57 @(210.395,199.070)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 54)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C58 @(210.395,188.270)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 55)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C59 @(210.395,177.470)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 56)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C60 @(214.875,209.870)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 57)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C61 @(214.875,199.070)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 58)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C62 @(214.875,188.270)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 59)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X22/C63 @(214.875,177.470)         | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+==================================================================================(mi 60)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M3 @(126.595,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 61)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M4 @(130.505,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 62)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M5 @(144.290,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 63)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M6 @(164.865,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 64)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/M7 @(185.440,227.235)              | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 65)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X13/M3 @(61.490,176.275)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 66)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X13/M4 @(58.940,178.325)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 67)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X13/M0 @(61.490,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 68)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X13/M1 @(59.285,175.220)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 69)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X13/M2 @(59.045,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 70)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X14/M3 @(66.280,176.275)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 71)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X14/M4 @(63.730,178.325)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 72)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X14/M0 @(66.280,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 73)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X14/M1 @(64.075,175.220)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 74)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X14/M2 @(63.835,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 75)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X15/M3 @(71.070,176.275)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 76)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X15/M4 @(68.520,178.325)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 77)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X15/M0 @(71.070,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 78)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X15/M1 @(68.865,175.220)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 79)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X15/M2 @(68.625,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 80)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X16/M3 @(75.860,176.275)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 81)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X16/M4 @(73.310,178.325)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 82)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X16/M0 @(75.860,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 83)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X16/M1 @(73.655,175.220)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 84)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X16/M2 @(73.415,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 85)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X17/M3 @(80.650,176.275)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 86)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X17/M4 @(78.100,178.325)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 87)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X17/M0 @(80.650,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 88)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X17/M1 @(78.445,175.220)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 89)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X17/M2 @(78.205,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 90)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X18/M3 @(85.440,176.275)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 91)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X18/M4 @(82.890,178.325)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 92)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X18/M0 @(85.440,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 93)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X18/M1 @(83.235,175.220)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 94)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X18/M2 @(82.995,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 95)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X19/M3 @(90.230,176.275)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 96)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X19/M4 @(87.680,178.325)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 97)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X19/M0 @(90.230,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 98)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X19/M1 @(88.025,175.220)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+==================================================================================(mi 99)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X19/M2 @(87.785,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 100)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X20/M3 @(95.020,176.275)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 101)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X20/M4 @(92.470,178.325)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 102)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X20/M0 @(95.020,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 103)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X20/M1 @(92.815,175.220)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 104)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X20/M2 @(92.575,171.040)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 105)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/M53 @(78.180,188.415)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 106)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/M91 @(94.140,188.415)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 107)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/M111 @(102.540,188.415)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 108)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/M113 @(103.380,188.415)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 109)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/M123 @(107.580,188.415)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 110)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/M125 @(108.420,188.415)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 111)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/M126 @(109.260,195.610)        | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 112)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X22/M43 @(92.460,197.470)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 113)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/X23/M1 @(57.180,208.770)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 114)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X33/R130 @(59.500,216.150)         | Schematic Inst : ** missing inst **
Layout Model: R(RNP1_3)                                | Schematic Model: 
=======================================================+=================================================================================(mi 115)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X59/M7 @(150.390,206.940)          | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 116)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X59/M13 @(152.230,206.940)         | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 117)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X59/M0 @(150.640,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 118)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X59/M1 @(151.360,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 119)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X59/M2 @(152.080,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 120)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X59/M3 @(152.800,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 121)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X60/M6 @(157.030,207.660)          | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 122)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X60/M11 @(158.870,208.380)         | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 123)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X60/M0 @(157.280,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 124)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X60/M1 @(158.000,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 125)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X60/M2 @(158.720,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 126)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X60/M3 @(159.440,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 127)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X61/M4 @(163.670,209.100)          | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 128)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X61/M11 @(165.510,208.380)         | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 129)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X61/M0 @(163.920,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 130)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X61/M1 @(164.640,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 131)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X61/M2 @(165.360,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 132)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X61/M3 @(166.080,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 133)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X62/M4 @(170.310,209.100)          | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 134)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X62/M10 @(172.150,209.100)         | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 135)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X62/M0 @(170.560,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 136)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X62/M1 @(171.280,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 137)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X62/M2 @(172.000,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 138)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X62/M3 @(172.720,213.960)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 139)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X67/M1 @(128.435,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 140)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X67/M0 @(128.435,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 141)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X68/M1 @(139.730,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 142)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X68/M0 @(139.730,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 143)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X69/M0 @(133.770,227.135)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 144)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X70/M0 @(136.390,227.135)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 145)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X71/M4 @(142.850,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 146)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/M3 @(151.215,224.115)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 147)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/M4 @(154.345,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 148)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/M5 @(155.065,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 149)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/M6 @(155.785,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 150)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/M7 @(156.975,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 151)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/M1 @(151.080,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 152)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/X19/M1 @(149.010,225.175)      | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 153)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/X19/M0 @(149.010,227.235)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 154)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/X20/M1 @(160.305,225.175)      | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 155)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/X20/M0 @(160.305,227.235)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 156)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/X21/M0 @(154.345,227.135)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 157)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/X22/M0 @(156.965,227.135)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 158)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/X23/M5 @(145.910,225.175)      | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 159)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/X23/M1 @(146.630,227.235)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 160)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X72/X24/M3 @(162.705,225.175)      | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 161)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/M2 @(165.585,225.175)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 162)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/M3 @(171.790,224.115)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 163)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/M4 @(174.920,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 164)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/M5 @(175.640,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 165)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/M6 @(176.360,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 166)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/M7 @(177.550,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 167)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/M1 @(171.655,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 168)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/X19/M1 @(169.585,225.175)      | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 169)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/X19/M0 @(169.585,227.235)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 170)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/X20/M1 @(180.880,225.175)      | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 171)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/X20/M0 @(180.880,227.235)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 172)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/X21/M0 @(174.920,227.135)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 173)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/X22/M0 @(177.540,227.135)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 174)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X73/X23/M0 @(167.925,227.235)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 175)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/M3 @(192.365,224.115)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 176)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/M4 @(195.495,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 177)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/M5 @(196.215,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 178)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/M6 @(196.935,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 179)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/M7 @(198.125,223.395)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 180)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/M1 @(192.230,227.235)          | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 181)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/X19/M1 @(190.160,225.175)      | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 182)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/X19/M0 @(190.160,227.235)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 183)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/X20/M1 @(201.455,225.175)      | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 184)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/X20/M0 @(201.455,227.235)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 185)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/X21/M0 @(195.495,227.135)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 186)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/X22/M0 @(198.115,227.135)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 187)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/X23/M3 @(188.500,225.175)      | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 188)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/X23/M0 @(188.500,227.235)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 189)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X74/X24/M1 @(204.575,227.235)      | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 190)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X75/M13 @(118.600,225.175)         | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 191)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X0/X0/X75/M0 @(115.855,226.925)          | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 192)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/M10 @(125.155,656.765)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 193)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/M13 @(130.640,657.825)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 194)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/M14 @(133.770,658.545)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 195)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/M15 @(134.490,658.545)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 196)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/M16 @(135.210,658.545)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 197)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/M17 @(136.400,658.545)          | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 198)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/X203/M12 @(173.820,714.160) | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 199)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/X212/M2 @(165.540,694.170)  | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 200)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C16 @(120.555,672.065)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 201)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C17 @(120.555,682.865)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 202)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C18 @(120.555,693.665)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 203)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C19 @(120.555,704.465)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 204)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C20 @(125.035,672.065)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 205)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C21 @(125.035,682.865)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 206)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C22 @(125.035,693.665)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 207)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C23 @(125.035,704.465)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 208)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C24 @(129.515,672.065)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 209)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C25 @(129.515,682.865)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 210)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C26 @(129.515,693.665)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 211)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C27 @(129.515,704.465)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 212)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C28 @(133.995,672.065)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 213)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C29 @(133.995,682.865)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 214)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C30 @(133.995,693.665)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 215)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C31 @(133.995,704.465)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 216)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C32 @(183.515,672.070)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 217)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C33 @(183.515,682.870)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 218)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C34 @(183.515,693.670)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 219)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C35 @(183.515,704.470)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 220)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C36 @(187.995,672.070)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 221)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C37 @(187.995,682.870)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 222)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C38 @(187.995,693.670)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 223)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C39 @(187.995,704.470)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 224)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C40 @(192.475,672.070)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 225)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C41 @(192.475,682.870)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 226)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C42 @(192.475,693.670)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 227)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C43 @(192.475,704.470)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 228)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C44 @(196.955,672.070)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 229)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C45 @(196.955,682.870)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 230)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C46 @(196.955,693.670)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 231)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C47 @(196.955,704.470)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 232)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C48 @(201.435,672.070)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 233)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C49 @(201.435,682.870)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 234)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C50 @(201.435,693.670)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 235)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C51 @(201.435,704.470)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 236)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C52 @(205.915,672.070)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 237)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C53 @(205.915,682.870)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 238)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C54 @(205.915,693.670)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 239)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C55 @(205.915,704.470)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 240)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C56 @(210.395,672.070)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 241)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C57 @(210.395,682.870)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 242)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C58 @(210.395,693.670)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 243)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C59 @(210.395,704.470)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 244)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C60 @(214.875,672.070)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 245)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C61 @(214.875,682.870)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 246)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C62 @(214.875,693.670)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 247)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X22/C63 @(214.875,704.470)      | Schematic Inst : ** missing inst **
Layout Model: C(CSF3)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 248)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/M0 @(124.435,654.705)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 249)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/M4 @(130.505,654.705)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 250)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/M7 @(185.440,654.705)           | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 251)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X13/M3 @(61.490,705.665)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 252)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X13/M4 @(58.940,703.615)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 253)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X13/M0 @(61.490,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 254)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X13/M1 @(59.285,706.720)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 255)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X13/M2 @(59.045,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 256)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X14/M3 @(66.280,705.665)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 257)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X14/M4 @(63.730,703.615)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 258)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X14/M0 @(66.280,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 259)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X14/M1 @(64.075,706.720)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 260)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X14/M2 @(63.835,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 261)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X15/M3 @(71.070,705.665)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 262)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X15/M4 @(68.520,703.615)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 263)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X15/M0 @(71.070,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 264)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X15/M1 @(68.865,706.720)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 265)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X15/M2 @(68.625,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 266)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X16/M3 @(75.860,705.665)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 267)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X16/M4 @(73.310,703.615)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 268)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X16/M0 @(75.860,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 269)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X16/M1 @(73.655,706.720)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 270)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X16/M2 @(73.415,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 271)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X17/M3 @(80.650,705.665)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 272)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X17/M4 @(78.100,703.615)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 273)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X17/M0 @(80.650,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 274)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X17/M1 @(78.445,706.720)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 275)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X17/M2 @(78.205,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 276)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X18/M3 @(85.440,705.665)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 277)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X18/M4 @(82.890,703.615)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 278)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X18/M0 @(85.440,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 279)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X18/M1 @(83.235,706.720)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 280)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X18/M2 @(82.995,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 281)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X19/M3 @(90.230,705.665)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 282)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X19/M4 @(87.680,703.615)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 283)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X19/M0 @(90.230,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 284)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X19/M1 @(88.025,706.720)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 285)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X19/M2 @(87.785,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 286)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X20/M3 @(95.020,705.665)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 287)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X20/M4 @(92.470,703.615)    | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 288)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X20/M0 @(95.020,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 289)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X20/M1 @(92.815,706.720)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 290)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X20/M2 @(92.575,710.900)    | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 291)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/M14 @(62.220,686.330)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 292)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/M43 @(73.980,693.525)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 293)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/M77 @(88.260,693.525)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 294)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/M111 @(102.540,693.525)     | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 295)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/M117 @(105.060,693.525)     | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 296)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/M123 @(107.580,693.525)     | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 297)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/M125 @(108.420,693.525)     | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 298)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X23/M30 @(81.540,673.170)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 299)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/X24/M24 @(76.500,679.750)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 300)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X33/R130 @(59.500,665.790)      | Schematic Inst : ** missing inst **
Layout Model: R(RNP1_3)                                | Schematic Model: 
=======================================================+=================================================================================(mi 301)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X59/M6 @(150.390,674.280)       | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 302)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X59/M10 @(152.230,672.840)      | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 303)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X59/M0 @(150.640,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 304)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X59/M1 @(151.360,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 305)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X59/M2 @(152.080,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 306)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X59/M3 @(152.800,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 307)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X60/M9 @(157.030,676.440)       | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 308)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X60/M10 @(158.870,672.840)      | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 309)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X60/M0 @(157.280,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 310)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X60/M1 @(158.000,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 311)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X60/M2 @(158.720,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 312)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X60/M3 @(159.440,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 313)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X61/M9 @(163.670,676.440)       | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 314)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X61/M10 @(165.510,672.840)      | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 315)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X61/M0 @(163.920,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 316)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X61/M1 @(164.640,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 317)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X61/M2 @(165.360,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 318)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X61/M3 @(166.080,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 319)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X62/M9 @(170.310,676.440)       | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 320)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X62/M11 @(172.150,673.560)      | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 321)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X62/M0 @(170.560,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 322)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X62/M1 @(171.280,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 323)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X62/M2 @(172.000,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 324)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X62/M3 @(172.720,667.980)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 325)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X67/M1 @(128.435,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 326)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X67/M0 @(128.435,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 327)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X68/M1 @(139.730,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 328)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X68/M0 @(139.730,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 329)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X69/M0 @(133.770,654.805)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 330)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X70/M0 @(136.390,654.805)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 331)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X71/M5 @(143.570,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 332)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X71/M1 @(142.850,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 333)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/M2 @(145.010,656.765)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 334)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/M3 @(151.215,657.825)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 335)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/M4 @(154.345,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 336)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/M5 @(155.065,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 337)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/M6 @(155.785,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 338)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/M7 @(156.975,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 339)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/M1 @(151.080,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 340)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/X19/M1 @(149.010,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 341)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/X19/M0 @(149.010,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 342)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/X20/M1 @(160.305,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 343)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/X20/M0 @(160.305,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 344)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/X21/M0 @(154.345,654.805)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 345)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/X22/M0 @(156.965,654.805)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 346)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/X23/M2 @(145.910,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 347)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/X24/M4 @(163.425,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 348)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X72/X24/M0 @(162.705,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 349)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/M3 @(171.790,657.825)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 350)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/M4 @(174.920,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 351)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/M5 @(175.640,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 352)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/M6 @(176.360,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 353)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/M7 @(177.550,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 354)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/M1 @(171.655,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 355)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/X19/M1 @(169.585,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 356)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/X19/M0 @(169.585,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 357)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/X20/M1 @(180.880,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 358)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/X20/M0 @(180.880,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 359)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/X21/M0 @(174.920,654.805)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 360)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/X22/M0 @(177.540,654.805)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 361)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/X23/M3 @(167.925,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 362)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/X23/M1 @(167.205,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 363)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X73/X24/M4 @(184.000,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 364)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/M3 @(192.365,657.825)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 365)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/M4 @(195.495,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 366)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/M5 @(196.215,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 367)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/M6 @(196.935,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 368)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/M7 @(198.125,658.545)       | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 369)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/M1 @(192.230,654.705)       | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 370)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/X19/M1 @(190.160,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 371)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/X19/M0 @(190.160,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 372)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/X20/M1 @(201.455,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 373)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/X20/M0 @(201.455,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 374)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/X21/M0 @(195.495,654.805)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 375)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/X22/M0 @(198.115,654.805)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 376)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/X23/M5 @(187.060,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 377)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/X23/M0 @(188.500,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 378)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/X24/M3 @(203.855,656.765)   | Schematic Inst : ** missing inst **
Layout Model: MP(PELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 379)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X74/X24/M0 @(203.855,654.705)   | Schematic Inst : ** missing inst **
Layout Model: MN(NELI)                                 | Schematic Model: 
=======================================================+=================================================================================(mi 380)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X75/M14 @(119.070,656.765)      | Schematic Inst : ** missing inst **
Layout Model: MP(PEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 381)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X5104/X75/M5 @(119.615,655.015)       | Schematic Inst : ** missing inst **
Layout Model: MN(NEI)                                  | Schematic Model: 
=======================================================+=================================================================================(mi 382)
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X404/M15 @(825.940,111.105)           | Schematic Inst : u_rst_core_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 383)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/924                                              | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X404/23  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: u_rst_core_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X404/M0 @(825.940,113.580)            | Schematic Inst : u_rst_core_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 384)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/924                                              | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X404/19  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: u_rst_core_sync/\sync_q_reg[0]/net64
S: X1/X404/17                                          | S: u_rst_core_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X562/M30 @(342.100,75.960)            | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 385)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1051                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X562/13  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X562/M22 @(335.720,75.730)            | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 386)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1051                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X562/11  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X562/M12 @(342.095,77.740)            | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 387)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1051                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X562/15  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X562/M4 @(335.280,77.740)             | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 388)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1051                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X562/18  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X587/M28 @(308.500,161.480)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 389)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1081                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X587/12  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X587/M20 @(302.120,161.710)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 390)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1081                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X587/11  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X587/M12 @(308.550,159.700)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 391)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1081                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X587/15  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X587/M4 @(301.680,159.700)            | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 392)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1081                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X587/18  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X566/M30 @(582.460,147.640)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 393)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1058                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X566/13  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X566/M22 @(588.840,147.410)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 394)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1058                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X566/11  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X566/M12 @(582.465,149.420)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 395)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1058                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X566/15  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X566/M4 @(589.280,149.420)            | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 396)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1058                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X566/18  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X600/M30 @(435.880,99.225)            | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 397)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1090                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X600/11  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X600/M22 @(429.240,98.990)            | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 398)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1090                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X600/10  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X600/M12 @(435.510,97.450)            | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 399)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1090                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X600/14  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X600/M4 @(428.800,96.980)             | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 400)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1090                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X600/17  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X564/M30 @(517.500,179.400)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 401)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1053                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X564/13  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X564/M22 @(523.880,179.630)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 402)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1053                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X564/11  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X564/M12 @(517.505,177.620)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 403)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1053                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X564/15  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X564/M4 @(524.320,177.620)            | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 404)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1053                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X564/18  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2398/M28 @(165.560,245.735)          | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 405)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3890                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2398/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2398/M20 @(159.320,245.970)          | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 406)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3890                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2398/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2398/M12 @(165.350,247.545)          | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 407)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3890                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2398/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2398/M4 @(158.880,247.980)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 408)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3890                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2398/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2296/M28 @(254.740,251.080)          | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 409)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3808                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2296/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2296/M20 @(248.360,251.310)          | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 410)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3808                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2296/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2296/M12 @(254.790,249.300)          | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 411)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3808                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2296/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2296/M4 @(247.920,249.300)           | Schematic Inst : \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 412)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3808                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2296/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[0].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X588/M28 @(314.660,75.960)            | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 413)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1082                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X588/12  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X588/M20 @(308.280,75.730)            | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 414)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1082                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X588/11  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X588/M12 @(314.710,77.740)            | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 415)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1082                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X588/15  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X588/M4 @(307.840,77.740)             | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 416)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1082                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X588/18  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X599/M30 @(279.800,129.255)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 417)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1089                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X599/11  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X599/M22 @(286.440,129.490)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 418)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1089                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X599/10  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X599/M12 @(280.170,131.030)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 419)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1089                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X599/14  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X599/M4 @(286.880,131.500)            | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 420)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1089                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X599/17  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X601/M30 @(488.120,81.305)            | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 421)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1091                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X601/11  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X601/M22 @(494.760,81.070)            | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 422)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1091                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X601/10  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X601/M12 @(488.490,79.530)            | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 423)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1091                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X601/14  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X601/M4 @(495.200,79.060)             | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 424)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1091                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X601/17  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X565/M30 @(555.020,161.480)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 425)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1055                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X565/13  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X565/M22 @(561.400,161.710)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 426)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1055                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X565/11  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X565/M12 @(555.025,159.700)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 427)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1055                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X565/15  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X565/M4 @(561.840,159.700)            | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 428)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1055                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X565/18  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X563/M30 @(432.380,174.520)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 429)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1052                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X563/13  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X563/M22 @(438.760,174.290)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 430)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1052                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X563/11  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X563/M12 @(432.385,176.300)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 431)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1052                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X563/15  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X1/X563/M4 @(439.200,176.300)            | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 432)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X1/1052                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X1/X563/18  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2272/M30 @(493.980,192.440)          | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 433)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3789                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2272/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2272/M22 @(500.360,192.210)          | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 434)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3789                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2272/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2272/M12 @(493.985,194.220)          | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 435)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3789                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2272/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2272/M4 @(500.800,194.220)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 436)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3789                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2272/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2291/M28 @(137.140,286.920)          | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 437)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3803                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2291/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2291/M20 @(130.760,287.150)          | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 438)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3803                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2291/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2291/M12 @(137.190,285.140)          | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 439)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3803                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2291/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2291/M4 @(130.320,285.140)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 440)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3803                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2291/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2323/M27 @(205.580,286.955)          | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 441)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3836                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2323/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2323/M19 @(211.960,287.150)          | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 442)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3836                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2323/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2323/M12 @(205.770,285.560)          | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 443)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3836                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2323/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2323/M4 @(212.400,285.140)           | Schematic Inst : \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 444)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3836                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2323/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[1].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2300/M28 @(344.340,210.360)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 445)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3812                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2300/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2300/M20 @(337.960,210.130)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 446)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3812                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2300/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2300/M12 @(344.390,212.140)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 447)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3812                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2300/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2300/M4 @(337.520,212.140)           | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 448)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3812                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2300/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2268/M30 @(292.820,269.000)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 449)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3785                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2268/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2268/M22 @(286.440,269.230)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 450)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3785                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2268/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2268/M12 @(292.815,267.220)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 451)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3785                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2268/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2268/M4 @(286.000,267.220)           | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 452)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3785                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2268/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2386/M30 @(524.920,242.585)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 453)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3889                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2386/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2386/M22 @(518.280,242.350)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 454)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3889                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2386/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2386/M12 @(524.550,240.810)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 455)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3889                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2386/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2386/M4 @(517.840,240.340)           | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 456)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3889                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2386/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2273/M30 @(515.260,260.040)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 457)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3791                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2273/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2273/M22 @(521.640,260.270)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 458)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3791                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2273/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2273/M12 @(515.265,258.260)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 459)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3791                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2273/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2273/M4 @(522.080,258.260)           | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 460)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3791                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2273/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2384/M30 @(414.760,227.815)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 461)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3886                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2384/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2384/M22 @(421.400,228.050)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 462)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3886                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2384/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2384/M12 @(415.130,229.590)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 463)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3886                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2384/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2384/M4 @(421.840,230.060)           | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 464)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3886                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2384/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2270/M30 @(468.780,304.840)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 465)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3787                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2270/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2270/M22 @(475.160,305.070)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 466)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3787                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2270/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2270/M12 @(468.785,303.060)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 467)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3787                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2270/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2270/M4 @(475.600,303.060)           | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 468)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3787                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2270/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2382/M30 @(141.320,326.375)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 469)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3884                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2382/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2382/M22 @(134.680,326.610)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 470)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3884                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2382/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2382/M12 @(140.950,328.150)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 471)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3884                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2382/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2382/M4 @(134.240,328.620)           | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 472)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3884                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2382/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2293/M28 @(213.860,349.640)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 473)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3805                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2293/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2293/M20 @(207.480,349.870)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 474)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3805                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2293/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2293/M12 @(213.910,347.860)          | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 475)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3805                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2293/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2293/M4 @(207.040,347.860)           | Schematic Inst : \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 476)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3805                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2293/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[2].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2299/M28 @(327.660,407.480)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 477)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3811                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2299/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2299/M20 @(334.040,407.250)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 478)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3811                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2299/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2299/M12 @(327.610,409.260)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 479)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3811                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2299/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2299/M4 @(334.480,409.260)           | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 480)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3811                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2299/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2267/M30 @(284.540,358.600)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 481)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3784                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2267/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2267/M22 @(290.920,358.830)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 482)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3784                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2267/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2267/M12 @(284.545,356.820)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 483)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3784                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2267/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2267/M4 @(291.360,356.820)           | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 484)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3784                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2267/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2385/M30 @(493.720,380.135)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 485)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3887                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2385/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2385/M22 @(500.360,380.370)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 486)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3887                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2385/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2385/M12 @(494.090,381.910)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 487)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3887                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2385/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2385/M4 @(500.800,382.380)           | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 488)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3887                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2385/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2301/M28 @(525.900,367.560)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 489)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3814                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2301/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2301/M20 @(532.280,367.790)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 490)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3814                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2301/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2301/M12 @(525.850,365.780)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 491)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3814                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2301/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2301/M4 @(532.720,365.780)           | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 492)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3814                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2301/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2383/M30 @(412.920,439.705)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 493)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3885                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2383/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2383/M22 @(406.280,439.470)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 494)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3885                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2383/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2383/M12 @(412.550,437.930)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 495)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3885                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2383/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2383/M4 @(405.840,437.460)           | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 496)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3885                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2383/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2271/M30 @(476.060,430.280)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 497)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3788                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2271/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2271/M22 @(482.440,430.510)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 498)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3788                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2271/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2271/M12 @(476.065,428.500)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 499)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3788                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2271/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2271/M4 @(482.880,428.500)           | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 500)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3788                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2271/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2322/M27 @(147.780,385.515)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 501)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3835                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2322/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2322/M19 @(141.400,385.710)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 502)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3835                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2322/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2322/M12 @(147.590,384.120)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 503)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3835                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2322/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2322/M4 @(140.960,383.700)           | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 504)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3835                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2322/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2297/M28 @(264.260,407.480)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 505)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3809                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2297/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2297/M20 @(257.880,407.250)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 506)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3809                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2297/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2297/M12 @(264.310,409.260)          | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 507)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3809                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2297/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2297/M4 @(257.440,409.260)           | Schematic Inst : \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 508)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3809                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2297/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[3].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1246/M30 @(311.160,717.465)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 509)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2351                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1246/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1246/M22 @(317.800,717.230)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 510)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2351                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1246/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1246/M12 @(311.530,715.690)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 511)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2351                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1246/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1246/M4 @(318.240,715.220)           | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 512)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2351                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1246/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1243/M30 @(242.840,618.905)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 513)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2348                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1243/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1243/M22 @(249.480,618.670)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 514)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2348                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1243/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1243/M12 @(243.210,617.130)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 515)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2348                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1243/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1243/M4 @(249.920,616.660)           | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 516)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2348                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1243/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1250/M30 @(495.960,538.265)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 517)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2355                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1250/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1250/M22 @(502.600,538.030)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 518)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2355                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1250/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1250/M12 @(496.330,536.490)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 519)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2355                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1250/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1250/M4 @(503.040,536.020)           | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 520)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2355                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1250/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1205/M30 @(565.660,559.800)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 521)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2325                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1205/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1205/M22 @(572.040,559.570)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 522)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2325                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1205/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1205/M12 @(565.665,561.580)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 523)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2325                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1205/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1205/M4 @(572.480,561.580)           | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 524)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2325                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1205/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1249/M30 @(425.400,744.345)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 525)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2354                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1249/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1249/M22 @(432.040,744.110)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 526)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2354                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1249/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1249/M12 @(425.770,742.570)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 527)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2354                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1249/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1249/M4 @(432.480,742.100)           | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 528)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2354                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1249/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1227/M27 @(526.460,654.315)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 529)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2343                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1227/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1227/M19 @(532.840,654.510)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 530)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2343                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1227/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1227/M12 @(526.650,652.920)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 531)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2343                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1227/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1227/M4 @(533.280,652.500)           | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 532)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2343                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1227/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2292/M28 @(193.700,501.960)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 533)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3804                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2292/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2292/M20 @(187.320,502.190)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 534)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3804                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2292/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2292/M12 @(193.750,500.180)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 535)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3804                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2292/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2292/M4 @(186.880,500.180)           | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 536)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3804                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2292/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2298/M28 @(264.260,501.960)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 537)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3810                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2298/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2298/M20 @(257.880,502.190)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 538)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3810                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2298/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2298/M12 @(264.310,500.180)          | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 539)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3810                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2298/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2298/M4 @(257.440,500.180)           | Schematic Inst : \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 540)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3810                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2298/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[4].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1247/M30 @(332.840,708.505)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 541)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2352                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1247/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1247/M22 @(326.200,708.270)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 542)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2352                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1247/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1247/M12 @(332.470,706.730)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 543)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2352                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1247/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1247/M4 @(325.760,706.260)           | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 544)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2352                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1247/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1214/M28 @(294.500,631.480)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 545)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2331                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1214/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1214/M20 @(288.120,631.250)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 546)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2331                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1214/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1214/M12 @(294.550,633.260)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 547)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2331                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1214/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1214/M4 @(287.680,633.260)           | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 548)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2331                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1214/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1251/M30 @(575.320,532.455)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 549)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2356                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1251/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1251/M22 @(568.680,532.690)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 550)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2356                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1251/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1251/M12 @(574.950,534.230)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 551)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2356                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1251/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1251/M4 @(568.240,534.700)           | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 552)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2356                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1251/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1217/M28 @(595.900,577.720)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 553)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2335                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1217/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1217/M20 @(602.280,577.490)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 554)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2335                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1217/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1217/M12 @(595.850,579.500)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 555)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2335                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1217/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1217/M4 @(602.720,579.500)           | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 556)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2335                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1217/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1255/M28 @(469.080,720.615)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 557)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2357                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1255/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1255/M20 @(462.840,720.850)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 558)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2357                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1255/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1255/M12 @(468.870,722.425)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 559)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2357                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1255/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1255/M4 @(462.400,722.860)           | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 560)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2357                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1255/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1216/M28 @(544.260,690.120)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 561)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2333                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1216/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1216/M20 @(537.880,690.350)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 562)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2333                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1216/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1216/M12 @(544.310,688.340)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 563)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2333                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1216/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1216/M4 @(537.440,688.340)           | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 564)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2333                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1216/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2266/M30 @(151.700,497.080)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 565)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3783                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2266/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2266/M22 @(145.320,496.850)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 566)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3783                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2266/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2266/M12 @(151.695,498.860)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 567)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3783                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2266/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2266/M4 @(144.880,498.860)           | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 568)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3783                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2266/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2294/M28 @(219.020,497.080)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 569)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3806                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2294/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2294/M20 @(225.400,496.850)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 570)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3806                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2294/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2294/M12 @(218.970,498.860)          | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 571)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3806                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2294/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2294/M4 @(225.840,498.860)           | Schematic Inst : \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 572)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3806                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2294/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[5].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1245/M30 @(296.600,702.695)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 573)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2350                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1245/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1245/M22 @(303.240,702.930)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 574)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2350                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1245/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1245/M12 @(296.970,704.470)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 575)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2350                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1245/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1245/M4 @(303.680,704.940)           | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 576)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2350                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1245/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1213/M28 @(255.860,604.600)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 577)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2330                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1213/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1213/M20 @(249.480,604.370)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 578)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2330                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1213/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1213/M12 @(255.910,606.380)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 579)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2330                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1213/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1213/M4 @(249.040,606.380)           | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 580)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2330                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1213/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2329/M27 @(500.140,475.115)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 581)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3839                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2329/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2329/M19 @(506.520,475.310)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 582)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3839                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2329/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2329/M12 @(500.330,473.720)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 583)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3839                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2329/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2329/M4 @(506.960,473.300)           | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 584)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3839                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2329/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1204/M30 @(524.220,528.840)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 585)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2322                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1204/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1204/M22 @(530.600,529.070)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 586)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2322                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1204/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1204/M12 @(524.225,527.060)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 587)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2322                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1204/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1204/M4 @(531.040,527.060)           | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 588)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2322                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1204/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1248/M30 @(419.800,738.535)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 589)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2353                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1248/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1248/M22 @(426.440,738.770)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 590)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2353                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1248/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1248/M12 @(420.170,740.310)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 591)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2353                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1248/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1248/M4 @(426.880,740.780)           | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 592)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2353                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1248/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1215/M28 @(461.500,631.480)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 593)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2332                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1215/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1215/M20 @(467.880,631.250)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 594)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2332                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1215/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1215/M12 @(461.450,633.260)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 595)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2332                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1215/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1215/M4 @(468.320,633.260)           | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 596)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2332                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1215/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2289/M28 @(123.700,497.080)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 597)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3801                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2289/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2289/M20 @(117.320,496.850)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 598)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3801                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2289/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2289/M12 @(123.750,498.860)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 599)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3801                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2289/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2289/M4 @(116.880,498.860)           | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 600)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3801                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2289/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2295/M28 @(226.180,488.120)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 601)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3807                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2295/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2295/M20 @(219.800,487.890)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 602)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3807                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2295/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2295/M12 @(226.230,489.900)          | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 603)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3807                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2295/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2295/M4 @(219.360,489.900)           | Schematic Inst : \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 604)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3807                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2295/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[6].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2269/M30 @(321.500,466.120)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 605)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3786                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2269/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2269/M22 @(327.880,466.350)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 606)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3786                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2269/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2269/M12 @(321.505,464.340)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 607)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3786                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2269/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2269/M4 @(328.320,464.340)           | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 608)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3786                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2269/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[0].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1244/M30 @(266.200,550.375)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 609)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2349                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1244/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1244/M22 @(259.560,550.610)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 610)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2349                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1244/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1244/M12 @(265.830,552.150)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 611)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2349                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1244/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1244/M4 @(259.120,552.620)           | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 612)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2349                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1244/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[1].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2328/M27 @(491.740,430.315)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 613)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3838                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2328/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2328/M19 @(498.120,430.510)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 614)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3838                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2328/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2328/M12 @(491.930,428.920)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 615)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3838                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2328/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2328/M4 @(498.560,428.500)           | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 616)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3838                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2328/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[2].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2302/M28 @(528.140,470.200)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 617)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3817                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2302/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2302/M20 @(534.520,469.970)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 618)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3817                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2302/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2302/M12 @(528.090,471.980)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 619)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3817                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2302/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2302/M4 @(534.960,471.980)           | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 620)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3817                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2302/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[3].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1202/M30 @(402.700,667.320)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 621)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2319                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1202/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1202/M22 @(409.080,667.090)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 622)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2319                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1202/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1202/M12 @(402.705,669.100)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 623)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2319                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1202/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1202/M4 @(409.520,669.100)           | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 624)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2319                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1202/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[4].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1203/M30 @(469.900,586.680)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 625)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2320                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1203/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1203/M22 @(476.280,586.450)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 626)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2320                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1203/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1203/M12 @(469.905,588.460)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 627)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2320                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1203/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1203/M4 @(476.720,588.460)           | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 628)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2320                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1203/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[5].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2290/M28 @(132.660,461.240)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 629)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3802                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2290/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2290/M20 @(126.280,461.010)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 630)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3802                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2290/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2290/M12 @(132.710,463.020)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 631)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3802                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2290/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2290/M4 @(125.840,463.020)           | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 632)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3802                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2290/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[6].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2324/M27 @(211.740,439.275)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 633)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3837                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2324/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2324/M19 @(218.120,439.470)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 634)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3837                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2324/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2324/M12 @(211.930,437.880)          | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 635)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3837                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2324/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2324/M4 @(218.560,437.460)           | Schematic Inst : \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 636)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3837                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2324/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_pd_row[7].gen_pd_col[7].u_pd/\nfast_hit_latched_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1605/M15 @(297.300,209.665)          | Schematic Inst : \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 637)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3230                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1605/23 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1605/M0 @(297.300,212.140)           | Schematic Inst : \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 638)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3230                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1605/19 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1605/17                                         | S: \u_core_gen_rst_fast_tap[0].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1596/M15 @(276.580,395.135)          | Schematic Inst : \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 639)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3225                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1596/23 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1596/M0 @(276.580,392.660)           | Schematic Inst : \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 640)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3225                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1596/19 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1596/17                                         | S: \u_core_gen_rst_fast_tap[1].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1628/M15 @(533.740,224.895)          | Schematic Inst : \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 641)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3244                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1628/23 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1628/M0 @(533.740,222.420)           | Schematic Inst : \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 642)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3244                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1628/19 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1628/17                                         | S: \u_core_gen_rst_fast_tap[2].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1636/M15 @(569.460,218.625)          | Schematic Inst : \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 643)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3253                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1636/23 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1636/M0 @(569.460,221.100)           | Schematic Inst : \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 644)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3253                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1636/19 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1636/17                                         | S: \u_core_gen_rst_fast_tap[3].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X850/M15 @(426.780,684.545)           | Schematic Inst : \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 645)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/1987                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X850/23  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X850/M0 @(426.780,687.020)            | Schematic Inst : \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 646)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/1987                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X850/19  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X3/X850/17                                          | S: \u_core_gen_rst_fast_tap[4].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X871/M15 @(556.140,672.895)           | Schematic Inst : \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 647)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/1999                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X871/23  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X871/M0 @(556.140,670.420)            | Schematic Inst : \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 648)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/1999                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X871/19  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X3/X871/17                                          | S: \u_core_gen_rst_fast_tap[5].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1571/M15 @(136.700,368.255)          | Schematic Inst : \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 649)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3197                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1571/23 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1571/M0 @(136.700,365.780)           | Schematic Inst : \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 650)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3197                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1571/19 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1571/17                                         | S: \u_core_gen_rst_fast_tap[6].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1581/M15 @(203.340,379.905)          | Schematic Inst : \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 651)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3210                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1581/23 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1581/M0 @(203.340,382.380)           | Schematic Inst : \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 652)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3210                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1581/19 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/net64
S: X2/X1581/17                                         | S: \u_core_gen_rst_fast_tap[7].u_rst_fast_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1669/M15 @(695.460,236.545)          | Schematic Inst : u_core_u_rst_drain_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 653)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3277                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1669/23 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_drain_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1669/M0 @(695.460,239.020)           | Schematic Inst : u_core_u_rst_drain_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 654)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3277                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1669/19 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_drain_sync/\sync_q_reg[0]/net64
S: X2/X1669/17                                         | S: u_core_u_rst_drain_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X895/M15 @(766.580,529.535)           | Schematic Inst : u_core_u_rst_fifo_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 655)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2037                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X895/23  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_fifo_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X895/M0 @(766.580,527.060)            | Schematic Inst : u_core_u_rst_fifo_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 656)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2037                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X895/19  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_fifo_sync/\sync_q_reg[0]/net64
S: X3/X895/17                                          | S: u_core_u_rst_fifo_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1697/M15 @(733.540,478.465)          | Schematic Inst : u_core_u_rst_status_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 657)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3309                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1697/23 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_status_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X1697/M0 @(733.540,480.940)           | Schematic Inst : u_core_u_rst_status_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 658)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3309                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X1697/19 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_status_sync/\sync_q_reg[0]/net64
S: X2/X1697/17                                         | S: u_core_u_rst_status_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X878/M15 @(614.820,699.775)           | Schematic Inst : u_core_u_rst_tx_sync/\sync_q_reg[0]/MM23
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 659)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2007                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X878/23  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_tx_sync/\sync_q_reg[0]/net65
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X878/M0 @(614.820,697.300)            | Schematic Inst : u_core_u_rst_tx_sync/\sync_q_reg[0]/MM15
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 660)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2007                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X878/19  .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: u_core_u_rst_tx_sync/\sync_q_reg[0]/net64
S: X3/X878/17                                          | S: u_core_u_rst_tx_sync/\sync_q_reg[0]/net064
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2176/M20 @(609.390,376.870)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM25
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 661)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3780                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2176/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MQIB
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2176/M28 @(615.870,377.480)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM58
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 662)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3780                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2176/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/SQIB
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2176/M12 @(616.250,374.740)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM48
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 663)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3780                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
S: X2/X2176/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/net55
D: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2176/M4 @(609.260,374.970)           | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[2]/MM44
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 664)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3780                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
S: X2/X2176/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[2]/net064
D: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2309/M28 @(717.860,367.560)          | Schematic Inst : \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 665)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3834                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2309/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2309/M20 @(711.480,367.790)          | Schematic Inst : \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 666)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3834                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2309/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2309/M12 @(717.910,365.780)          | Schematic Inst : \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 667)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3834                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2309/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2309/M4 @(711.040,365.780)           | Schematic Inst : \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 668)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3834                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2309/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_drain_ctx_q_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2304/M28 @(612.140,358.600)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 669)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3822                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2304/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2304/M20 @(618.520,358.830)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 670)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3822                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2304/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2304/M12 @(612.090,356.820)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 671)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3822                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2304/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2304/M4 @(618.960,356.820)           | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[3]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 672)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3822                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2304/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[3]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2303/M28 @(607.660,362.680)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 673)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3820                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2303/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2303/M20 @(614.040,362.450)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 674)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3820                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2303/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2303/M12 @(607.610,364.460)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 675)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3820                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2303/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2303/M4 @(614.480,364.460)           | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[4]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 676)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3820                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2303/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[4]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1218/M28 @(682.020,537.800)          | Schematic Inst : \u_core_u_fifo_count_q_reg[5]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 677)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2338                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1218/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_count_q_reg[5]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1218/M20 @(675.640,538.030)          | Schematic Inst : \u_core_u_fifo_count_q_reg[5]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 678)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2338                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1218/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_count_q_reg[5]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1218/M12 @(682.070,536.020)          | Schematic Inst : \u_core_u_fifo_count_q_reg[5]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 679)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2338                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1218/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_count_q_reg[5]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1218/M4 @(675.200,536.020)           | Schematic Inst : \u_core_u_fifo_count_q_reg[5]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 680)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2338                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1218/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_count_q_reg[5]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2308/M28 @(690.980,362.680)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 681)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3832                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2308/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[0]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2308/M20 @(684.600,362.450)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 682)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3832                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2308/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2308/M12 @(691.030,364.460)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 683)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3832                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2308/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2308/M4 @(684.160,364.460)           | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 684)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3832                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2308/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2305/M28 @(666.900,362.680)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 685)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3823                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2305/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[1]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2305/M20 @(660.520,362.450)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 686)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3823                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2305/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[1]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2305/M12 @(666.950,364.460)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 687)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3823                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2305/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[1]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2305/M4 @(660.080,364.460)           | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[1]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 688)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3823                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2305/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[1]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2306/M28 @(668.580,389.560)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 689)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3826                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2306/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[2]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2306/M20 @(662.200,389.330)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 690)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3826                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2306/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[2]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2306/M12 @(668.630,391.340)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 691)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3826                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2306/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[2]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2306/M4 @(661.760,391.340)           | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[2]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 692)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3826                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2306/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[2]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2307/M28 @(676.980,394.440)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 693)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3829                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2307/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[3]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2307/M20 @(670.600,394.670)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 694)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3829                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2307/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[3]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2307/M12 @(677.030,392.660)          | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 695)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3829                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2307/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[3]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2307/M4 @(670.160,392.660)           | Schematic Inst : \u_core_u_drain_ctrl_event_seq_q_reg[3]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 696)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3829                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2307/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_event_seq_q_reg[3]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1220/M28 @(847.340,546.760)          | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[2]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 697)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2341                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1220/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[2]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1220/M20 @(853.720,546.990)          | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[2]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 698)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2341                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1220/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[2]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1220/M12 @(847.290,544.980)          | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[2]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 699)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2341                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1220/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[2]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1220/M4 @(854.160,544.980)           | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[2]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 700)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2341                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1220/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[2]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1219/M28 @(839.940,528.840)          | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[3]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 701)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2340                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1219/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[3]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1219/M20 @(833.560,529.070)          | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[3]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 702)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2340                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1219/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[3]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1219/M12 @(839.990,527.060)          | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[3]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 703)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2340                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1219/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[3]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X3/X1219/M4 @(833.120,527.060)           | Schematic Inst : \u_core_u_fifo_rd_ptr_q_reg[3]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 704)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X3/2340                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X3/X1219/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_fifo_rd_ptr_q_reg[3]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2274/M30 @(655.820,340.680)          | Schematic Inst : \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 705)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3794                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2274/13 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/SQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2274/M22 @(662.200,340.910)          | Schematic Inst : \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 706)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3794                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2274/11 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2274/M12 @(655.825,338.900)          | Schematic Inst : \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 707)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3794                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2274/15 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2274/M4 @(662.640,338.900)           | Schematic Inst : \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 708)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3794                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2274/18 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_ns_cnt_q_reg[2]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2332/M27 @(678.220,452.245)          | Schematic Inst : \u_core_u_meas_ctrl_state_q_reg[0]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 709)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3842                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2332/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_meas_ctrl_state_q_reg[0]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2332/M19 @(684.600,452.050)          | Schematic Inst : \u_core_u_meas_ctrl_state_q_reg[0]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 710)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3842                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2332/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_meas_ctrl_state_q_reg[0]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2332/M12 @(678.410,453.640)          | Schematic Inst : \u_core_u_meas_ctrl_state_q_reg[0]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 711)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3842                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2332/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_meas_ctrl_state_q_reg[0]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2332/M4 @(685.040,454.060)           | Schematic Inst : \u_core_u_meas_ctrl_state_q_reg[0]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 712)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3842                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2332/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_meas_ctrl_state_q_reg[0]/net61
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2331/M27 @(651.340,335.765)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM60
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 713)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3840                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2331/12 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/net032
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2331/M19 @(657.720,335.570)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM57
Layout Model: MP(PEI)                                  | Schematic Model: MP(PEI)
=======================================================+=================================================================================(mi 714)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3840                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2331/10 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MQI
S: VDD                                                 | S: VDD
B: VDD   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VDD
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2331/M12 @(651.530,337.160)          | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM52
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 715)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3840                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2331/14 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/net59
S: VSS                                                 | S: VSS
B: VSS   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .| B: VSS
                                                                                                                                                 
                                                                                                                                                 
Layout Inst : X2/X2331/M4 @(658.160,337.580)           | Schematic Inst : \u_core_u_drain_ctrl_pd_scan_q_reg[1]/MM20
Layout Model: MN(NEI)                                  | Schematic Model: MN(NEI)
=======================================================+=================================================================================(mi 716)
Terminal: Layout Net                                   | Terminal: Schematic Net
-------------------------------------------------------+-----------------------------------------------------------------------------------------
G: X2/3840                                             | ** missing net **
** X1/1083 **                                          | G: tie1
                                                       | 
D: X2/X2331/17 .  .  .  .  .  .  .  .  .  .  .  .  .  .| D: \u_core_u_drain_ctrl_pd_scan_q_reg[1]/net61
S: VSS                                                 | S: VSS
B: VSS                                                 | B: VSS


+===[mptdc_axis_core]=========================================================================================
|                                       UNMATCHED SCHEMATIC PIN LABELS                                        
+=============================================================================================================

Labeled Schematic Pin     | Matched Layout Pin     | Matched Layout Net
--------------------------+------------------------+-----------------------
tie1                      | ** missing pin **      | X1/1083


##############################################################################################################
#
#                                                END OF REPORT                                                
#
##############################################################################################################

