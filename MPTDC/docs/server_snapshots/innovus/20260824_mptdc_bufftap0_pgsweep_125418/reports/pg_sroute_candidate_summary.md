# MPTDC PG Isolated SRoute Candidate Sweep

- date: 2026-08-24T12:54:18+02:00
- repo: /home/validmgr/ksabra/2026_SPAD/SPADMIC
- branch: SPADMIC_test
- head: 1d150b887fc25a1d093321cd1e1b83d397477b18
- source_checkpoint: /sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_simplepg_pgproof_112900/checkpoints/03_cts.enc.dat
- innovus_work: /sim/ksabra/SPADMIC_work/innovus

Each candidate restores the same clean checkpoint. Results are not cumulative.
Acceptance is intentionally strict: strict_pg_clean=PASS requires
special_raw_bad=0, special_bad=0, and shorts=0. A filtered RO-only result
is not accepted as clean unless the raw special report is also clean.

## corepin_ring

- run_id: `20260824_mptdc_bufftap0_pgsweep_125418_corepin_ring`
- rc: `0`
- strict_pg_clean: `FAIL`
- strict_pg_reasons: `shorts_46+special_raw_1+special_bad_1+drc_144`
- final_drc/shorts: `144/46`
- regular_bad: `1`
- special_bad/raw/filter/ro/non_ro: `1/1/FAIL/4/34`
- unrouted: `UNKNOWN`
- route_gate_pass: `0`
- status_report: `/sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_pgsweep_125418_corepin_ring/reports/checkpoint_repair_status.rpt`

## corepin_first_after_row_end

- run_id: `20260824_mptdc_bufftap0_pgsweep_125418_corepin_first_after_row_end`
- rc: `0`
- strict_pg_clean: `FAIL`
- strict_pg_reasons: `shorts_46+special_raw_1+special_bad_1+drc_144`
- final_drc/shorts: `144/46`
- regular_bad: `1`
- special_bad/raw/filter/ro/non_ro: `1/1/FAIL/4/34`
- unrouted: `UNKNOWN`
- route_gate_pass: `0`
- status_report: `/sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_pgsweep_125418_corepin_first_after_row_end/reports/checkpoint_repair_status.rpt`

## core_block_ring

- run_id: `20260824_mptdc_bufftap0_pgsweep_125418_core_block_ring`
- rc: `0`
- strict_pg_clean: `FAIL`
- strict_pg_reasons: `shorts_46+special_raw_1+special_bad_1+drc_144`
- final_drc/shorts: `144/46`
- regular_bad: `1`
- special_bad/raw/filter/ro/non_ro: `1/1/FAIL/0/34`
- unrouted: `UNKNOWN`
- route_gate_pass: `0`
- status_report: `/sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_pgsweep_125418_core_block_ring/reports/checkpoint_repair_status.rpt`

## core_block_pad_ring

- run_id: `20260824_mptdc_bufftap0_pgsweep_125418_core_block_pad_ring`
- rc: `0`
- strict_pg_clean: `FAIL`
- strict_pg_reasons: `shorts_46+special_raw_1+special_bad_1+drc_144`
- final_drc/shorts: `144/46`
- regular_bad: `1`
- special_bad/raw/filter/ro/non_ro: `1/1/FAIL/0/34`
- unrouted: `UNKNOWN`
- route_gate_pass: `0`
- status_report: `/sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_pgsweep_125418_core_block_pad_ring/reports/checkpoint_repair_status.rpt`

## core_block_via_closest

- run_id: `20260824_mptdc_bufftap0_pgsweep_125418_core_block_via_closest`
- rc: `0`
- strict_pg_clean: `FAIL`
- strict_pg_reasons: `shorts_46+special_raw_1+special_bad_1+drc_144`
- final_drc/shorts: `144/46`
- regular_bad: `1`
- special_bad/raw/filter/ro/non_ro: `1/1/FAIL/0/34`
- unrouted: `UNKNOWN`
- route_gate_pass: `0`
- status_report: `/sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_pgsweep_125418_core_block_via_closest/reports/checkpoint_repair_status.rpt`

## core_block_connect_broken

- run_id: `20260824_mptdc_bufftap0_pgsweep_125418_core_block_connect_broken`
- rc: `0`
- strict_pg_clean: `FAIL`
- strict_pg_reasons: `shorts_46+special_raw_1+special_bad_1+drc_144`
- final_drc/shorts: `144/46`
- regular_bad: `1`
- special_bad/raw/filter/ro/non_ro: `1/1/FAIL/0/34`
- unrouted: `UNKNOWN`
- route_gate_pass: `0`
- status_report: `/sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_pgsweep_125418_core_block_connect_broken/reports/checkpoint_repair_status.rpt`

## core_block_pin_width

- run_id: `20260824_mptdc_bufftap0_pgsweep_125418_core_block_pin_width`
- rc: `0`
- strict_pg_clean: `FAIL`
- strict_pg_reasons: `shorts_46+special_raw_1+special_bad_1+drc_144`
- final_drc/shorts: `144/46`
- regular_bad: `1`
- special_bad/raw/filter/ro/non_ro: `1/1/FAIL/0/34`
- unrouted: `UNKNOWN`
- route_gate_pass: `0`
- status_report: `/sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_pgsweep_125418_core_block_pin_width/reports/checkpoint_repair_status.rpt`

## core_block_pin_corners

- run_id: `20260824_mptdc_bufftap0_pgsweep_125418_core_block_pin_corners`
- rc: `0`
- strict_pg_clean: `FAIL`
- strict_pg_reasons: `shorts_46+special_raw_1+special_bad_1+drc_144`
- final_drc/shorts: `144/46`
- regular_bad: `1`
- special_bad/raw/filter/ro/non_ro: `1/1/FAIL/0/34`
- unrouted: `UNKNOWN`
- route_gate_pass: `0`
- status_report: `/sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_pgsweep_125418_core_block_pin_corners/reports/checkpoint_repair_status.rpt`

## core_block_target_80

- run_id: `20260824_mptdc_bufftap0_pgsweep_125418_core_block_target_80`
- rc: `0`
- strict_pg_clean: `FAIL`
- strict_pg_reasons: `shorts_46+special_raw_1+special_bad_1+drc_144`
- final_drc/shorts: `144/46`
- regular_bad: `1`
- special_bad/raw/filter/ro/non_ro: `1/1/FAIL/0/34`
- unrouted: `UNKNOWN`
- route_gate_pass: `0`
- status_report: `/sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_pgsweep_125418_core_block_target_80/reports/checkpoint_repair_status.rpt`

## core_block_target_250

- run_id: `20260824_mptdc_bufftap0_pgsweep_125418_core_block_target_250`
- rc: `0`
- strict_pg_clean: `FAIL`
- strict_pg_reasons: `shorts_46+special_raw_1+special_bad_1+drc_144`
- final_drc/shorts: `144/46`
- regular_bad: `1`
- special_bad/raw/filter/ro/non_ro: `1/1/FAIL/0/34`
- unrouted: `UNKNOWN`
- route_gate_pass: `0`
- status_report: `/sim/ksabra/SPADMIC_work/innovus/20260824_mptdc_bufftap0_pgsweep_125418_core_block_target_250/reports/checkpoint_repair_status.rpt`

