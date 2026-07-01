deselectAll
selectNet {u_core_ro_fast_code_q[0]} {u_core_ro_fast_code_q[6]} {u_core_ro_fast_code_q[7]} {CTS_6} {u_core_n_64592} {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/q1} {u_core_n_57562}
setNanoRouteMode -route_selected_net_only true
setNanoRouteMode -route_with_via_in_pin true
setNanoRouteMode -route_with_via_only_for_block_cell_pin true
setNanoRouteMode -route_detail_check_mar_on_cell_pin true
globalDetailRoute -select
detailRoute -select
ecoRoute -fix_drc
setNanoRouteMode -route_selected_net_only false
