# Server Run Request: O12C Phase Buffer Topology

Run on the lab server from the SPADMIC checkout on `SPADMIC_localtag`.

Start with report-only parser validation:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only

RUN_ID=20260608_o12c_phase_buffer_topology_abs1
EXPECTED_HEAD="$(git rev-parse HEAD)"

EXPECTED_HEAD="$EXPECTED_HEAD" \
MPTDC_O12C_MODE=report_only \
MPTDC_O12C_SOURCE_RUN_ID=20260608_o12_phase_buffer_pnr_abs1 \
bash MPTDC/pnr/scripts/server_run_innovus_o12c_phase_buffer_topology.sh "$RUN_ID"
```

Expected outputs:

- `reports/phase_buffer_output_loads.csv`
- `reports/phase_buffer_balance_summary.md`
- `reports/phase_buffer_topology.csv`
- `reports/phase_buffer_topology_summary.md`
- `reports/phase_buffer_placement.csv`
- `reports/phase_buffer_placement_summary.md`
- `reports/phase_buffer_route_summary.csv`
- `reports/drv_max_cap.rpt`
- `reports/drv_max_transition.rpt`
- `reports/timing_post_route_ro_osc_domain.rpt`

Run the buffer input-cap audit on the same Liberty:

```bash
python3 tools/pdk/audit_buffer_input_caps.py \
  /data/pdk/xfab/xh018/diglibs/D_CELLS_HD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib \
  --output "results/innovus/$RUN_ID/reports/buffer_input_cap_audit.md"
```

Archive the O12B abs4 evidence if it is still present on the server:

```bash
O12B_RUN=20260608_o12b_phase_buffer_balance_abs4
O12B_TGZ=results/innovus/${O12B_RUN}_evidence.tgz
tar -czf "$O12B_TGZ" \
  "results/innovus/$O12B_RUN/SUMMARY.md" \
  "results/innovus/$O12B_RUN/reports/phase_buffer_balance_summary.md" \
  "results/innovus/$O12B_RUN/reports/phase_buffer_output_loads.csv" \
  "results/innovus/$O12B_RUN/reports/phase_buffer_topology.csv" \
  "results/innovus/$O12B_RUN/reports/phase_buffer_placement.csv" \
  "results/innovus/$O12B_RUN/reports/net_debug_slow_0_buf.rpt" \
  "results/innovus/$O12B_RUN/reports/net_debug_fast_0_buf.rpt" \
  "results/innovus/$O12B_RUN/logs" \
  "results/innovus/$O12B_RUN/manifests"
```

Do not run characterization.  Do not call this signoff.
