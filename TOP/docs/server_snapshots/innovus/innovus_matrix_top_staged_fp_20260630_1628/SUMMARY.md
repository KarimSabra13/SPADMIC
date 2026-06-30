# SPADMIC Matrix TOP Staged Innovus Floorplan Run

- Run ID: `innovus_matrix_top_staged_fp_20260630_1628`
- Run directory: `/sim/ksabra/SPADMIC_work/innovus/innovus_matrix_top_staged_fp_20260630_1628`
- Matrix CSV: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv`
- Matrix LEF: `/group/validmgr/PROJET/Prj_xh018/ksabra/lef/matrice3.lef`
- Pad policy: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/TOP/pnr/inputs/matrix_top_pad_policy_template.csv`
- XH018 stack: `xx31`
- Standard-cell family: `JIHD`
- Route layers: `MET1 MET2 MET3 METTP`
- Ordinary signal top layer: `MET3`
- Effective top floor layer: `METTP`
- Branch: `SPADMIC_test`
- Commit: `e79f96bc05cb1aff6f1eb384188d1a592a538a90`
- Generated top plan: `generated/top_floorplan_summary.md`
- Signoff: non-signoff staged floorplan feasibility

## Result

- Result: STOPPED_BEFORE_INNOVUS
- Plan status: `FAIL`
- Plan issues: `MPTDC_VERTICAL_STACK_EXCEEDS_CORE_HEIGHT`

The staged flow intentionally stops here. Do not run placement until the floorplan geometry is resolved.
