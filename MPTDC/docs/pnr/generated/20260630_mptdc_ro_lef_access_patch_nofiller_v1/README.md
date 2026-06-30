# 20260630 MPTDC RO LEF Access Patch No-Filler Run

Source run:
`/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_ro_lef_access_patch_nofiller_v1`

Important: this run did not actually use the generated PnR LEF. The manifest shows:
`O1_RO_LEF_PATH: /group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef`

Route result:
- ROUTE_STATUS=FAIL
- GEOMETRY_DRC_VIOLATIONS=20
- SHORTS=18
- regular connectivity clean
- special PG connectivity dirty because sroute/RO-PG hookup were disabled
