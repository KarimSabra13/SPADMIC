#!/usr/bin/env python3

from __future__ import annotations

import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_tx_packet_canonical_phase2.sh"


class TxPacketCanonicalPhase2DriverTest(unittest.TestCase):
    def test_driver_is_staged_and_interactive_shell_safe(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotRegex(text, re.compile(r"^\s*set\s+-e", re.MULTILINE))
        self.assertNotRegex(text, re.compile(r"^\s*exit(?:\s|$)", re.MULTILINE))
        self.assertIn("ONE_OPERATOR_COMMAND_PER_GATE_NO_AUTO_ADVANCE", text)
        for subcommand in (
            "init",
            "sync",
            "preflight",
            "innovus",
            "innovus-report",
            "diagnose",
            "pg-probe",
            "pg-analyze",
            "pg-help",
            "pg-via-trial",
            "pg-via-drc-probe",
            "pg-via-1x1-trial",
            "preroute-pg-rerun",
            "preroute-pg-postfiller-rerun",
            "postfiller-stage-probe",
            "postcts-via1-analyze",
            "preroute-pg-no-restitch-rerun",
            "final-closure-analyze",
            "min-area-second-pass-trial",
            "min-area-second-pass-trial-r2",
            "min-area-geometry-probe",
            "min-area-landing-patch-trial",
            "min-area-landing-patch-trial-r2",
            "min-area-landing-patch-trial-r3",
            "min-area-landing-patch-trial-r4",
            "package",
            "status",
        ):
            self.assertIn(f"  {subcommand})", text)

    def test_driver_runs_only_packet_innovus_with_explicit_policies(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("run_innovus_ooc_harden_block.sh", text)
        self.assertIn("SPADMIC_OOC_ROUTE_PROFILE=met1_effort", text)
        self.assertIn("SPADMIC_OOC_SIGNAL_TOP_LAYER=MET3", text)
        self.assertIn("SPADMIC_OOC_ENABLE_PG_SROUTE=1", text)
        self.assertIn("SPADMIC_OOC_CORE_WIDTH_UM=2046.969", text)
        self.assertIn("SPADMIC_OOC_CORE_HEIGHT_UM=346.486", text)
        self.assertIn("SPADMIC_OOC_PLACE_MAX_DENSITY=0.64", text)
        self.assertIn("SPADMIC_OOC_SIGNAL_BOTTOM_LAYER_IDX=1", text)
        self.assertIn("SPADMIC_OOC_SIGNAL_TOP_LAYER_IDX=3", text)
        self.assertIn("SPADMIC_OOC_ENABLE_MIN_AREA_REPAIR=1", text)
        self.assertIn("SPADMIC_OOC_ENABLE_ANTENNA_REPAIR=0", text)
        self.assertIn("SPADMIC_OOC_FILLER_ADD_FILLERS_WITH_DRC=0", text)
        self.assertIn("SPADMIC_OOC_REQUIRE_DRC_SAFE_FILLER=1", text)
        self.assertIn("SPADMIC_TX_ALLOW_ANTENNA_DEFERRED=1", text)
        self.assertIn("variable core_width_um {2046.969}", text)
        self.assertIn("variable core_height_um {346.486}", text)
        self.assertIn("DEFER_MANUAL_REPAIR_FINAL_HANDOFF_BLOCKED", text)
        self.assertNotIn("run_pvs", text)
        self.assertIn("PVS_POLICY=NOT_RUN_IN_THIS_PHASE", text)

    def test_driver_requires_measured_timing_and_canonical_gate_results(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("SETUP_WNS_NS", text)
        self.assertIn("SETUP_VIOLATING_PATH_COUNT", text)
        self.assertIn("HOLD_WNS_NS", text)
        self.assertIn("HOLD_VIOLATING_PATH_COUNT", text)
        self.assertIn("POST_REPAIR_TIMING_REQUIRED", text)
        self.assertIn("ANTENNA_MILESTONE_ACCEPTED", text)
        self.assertIn("READY_FOR_PVS_CANDIDATE", text)
        self.assertIn("--exclude='reports/06_package_details.rpt'", text)
        self.assertIn("READ_ONLY_EXISTING_ARTIFACTS_NO_DESIGN_MODIFICATION", (
            REPO / "TOP" / "pnr" / "scripts" / "analyze_tx_packet_ooc_failure.py"
        ).read_text())
        self.assertIn("DESIGN_MODIFICATION", text)
        self.assertIn('kv_field "$report" DIAGNOSIS_STATUS', text)

    def test_pg_probe_is_fresh_process_restore_only_and_supports_packet_checkpoint(self) -> None:
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_probe.sh"
        ).read_text()
        probe = (
            REPO / "TOP" / "pnr" / "scripts" / "probe_innovus_ooc_pg_connectivity.tcl"
        ).read_text()
        self.assertIn("05_postroute_export.enc.dat", wrapper)
        self.assertIn('SPADMIC_PG_PROBE_TOP="$top"', wrapper)
        self.assertIn("POLICY=READ_ONLY_RESTORE_AND_REPORT", wrapper)
        self.assertIn("restoreDesign $checkpoint $top", probe)
        self.assertIn("DESIGN_MODIFICATION NOT_RUN", probe)
        self.assertNotIn("add_shape", probe)
        self.assertNotIn("sroute", probe)

    def test_pg_repair_isolated_trial_is_fail_closed(self) -> None:
        driver = DRIVER.read_text()
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_via_trial.sh"
        ).read_text()
        trial = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_via_trial.tcl"
        ).read_text()
        command_help = (
            REPO / "TOP" / "pnr" / "scripts" / "capture_innovus_pg_command_help.tcl"
        ).read_text()
        self.assertIn("require_step_pass 05_pg_probe", driver)
        self.assertIn("require_step_pass 06_pg_analyze", driver)
        self.assertIn("require_step_pass 07_pg_help", driver)
        self.assertIn("SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD", driver)
        self.assertIn("REPORT_DRIVER_HEAD=", driver)
        self.assertIn("READY_FOR_ONE_ISOLATED_TRIAL", driver)
        self.assertIn("editPowerVia", command_help)
        self.assertIn("setViaGenMode", command_help)
        self.assertIn('grep -Fq "setViaGenMode -area_only 1"', driver)
        self.assertIn('grep -Fq -- "-exclude_stack_vias"', driver)
        self.assertIn("ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL", wrapper)
        self.assertIn("</dev/null", wrapper)
        self.assertIn("restoreDesign $checkpoint $top", trial)
        self.assertIn("editPowerVia -add_vias 1", trial)
        self.assertIn("setViaGenMode -area_only 1", trial)
        self.assertIn("-bottom_layer MET1 -top_layer METTP -exclude_stack_vias 0", trial)
        self.assertIn("Problem\\(s\\)", trial)
        self.assertIn("return CONFLICT", trial)
        self.assertIn("string is integer -strict $post_special_count", trial)
        self.assertIn("POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", trial)
        self.assertIn("POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT", trial)
        self.assertIn("POST_DRC_VIOLATION_COUNT", trial)
        self.assertIn("drc_markers_pre_trial.tsv", trial)
        self.assertIn("drc_markers_post_trial.tsv", trial)
        self.assertIn("trial_write_marker_dump", trial)
        self.assertIn("excluded_antenna_count", trial)
        self.assertIn("excluded_connectivity_count", trial)
        self.assertIn("PRE_MARKER_DATABASE_TOTAL", trial)
        self.assertIn("SPADMIC_PG_VIA_TRIAL_ABORT", trial)
        self.assertIn("pg_via_drc_probe", driver)
        self.assertIn("pg_via_via-only_drc_probe_r2", driver)
        self.assertIn("DIRECT_STACK_DRC_MARKERS_CLASSIFIED_NO_SAVE_EXPORT", driver)
        self.assertIn("analyze_tx_packet_pg_via_drc.py", driver)
        self.assertIn("POST_DRC_VIOLATION_COUNT)\" != \"25\"", driver)
        self.assertIn("via-1x1", wrapper)
        self.assertIn("$mode ni {via-only via-1x1 patch-stack}", trial)
        self.assertIn("lappend command -via_rows 1 -via_columns 1", trial)
        self.assertIn("require_step_pass 10_pg_via_drc_probe_r2", driver)
        self.assertIn('grep -Fq -- "-via_rows"', driver)
        self.assertIn('grep -Fq -- "-via_columns"', driver)
        self.assertIn("pg_via_1x1_trial", driver)
        self.assertIn("analyze_tx_packet_pg_via_candidate.py", driver)
        self.assertIn("PG_VIA_1X1_CANDIDATE_CLASSIFIED_NO_SAVE_EXPORT", driver)
        self.assertIn("CANONICAL_RERUN=NOT_RUN", driver)
        self.assertIn("PVS=NOT_RUN", driver)
        self.assertIn("require_step_pass 12_preroute_pg_rerun", driver)
        self.assertIn("preroute-pg-postfiller-rerun <expected-report-driver-head>", driver)
        self.assertIn("SPADMIC_OOC_PRE_CTS_EXPECTED_DANGLING_COUNT=156", driver)
        self.assertIn("SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH=1", driver)
        self.assertIn("PRE_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)\" != \"156\"", driver)
        self.assertIn("PREROUTE_PG_POSTFILLER_CANDIDATE_CLASSIFIED_NO_AUTOMATIC_PVS_STAGING_OR_PVS", driver)
        self.assertIn("POST_FILLER_PG_RESTITCH=ENABLED_STRICT_ZERO_CONNECTIVITY_AND_DRC", driver)
        self.assertIn("require_step_pass 13_preroute_pg_postfiller_rerun", driver)
        self.assertIn("postfiller-stage-probe <expected-report-driver-head>", driver)
        self.assertIn("POST_FILLER_DRC_VIOLATION_COUNT)\" != \"165\"", driver)
        self.assertIn("run_innovus_ooc_postfiller_stage_probe.sh", driver)
        self.assertIn("analyze_tx_packet_postfiller_stage_probe.py", driver)
        self.assertIn("POSTFILLER_STAGE_ATTRIBUTION_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS", driver)
        self.assertIn("require_step_pass 14_postfiller_stage_probe", driver)
        self.assertIn("postcts-via1-analyze <expected-report-driver-head>", driver)
        self.assertIn("analyze_tx_packet_postcts_via1_markers.py", driver)
        self.assertIn("READ_ONLY_TEXT_ARTIFACTS_NO_INNOVUS", driver)
        self.assertIn("POSTCTS_VIA1_CAPTURE_CLASSIFIED_NO_DESIGN_MODIFICATION", driver)
        self.assertIn("POST_CTS_DRC_VIOLATION_COUNT)\" != \"1000\"", driver)
        self.assertIn("FILLER_SPECIAL_CONNECTIVITY_EFFECT", driver)
        self.assertIn("NOT_REQUIRED_FOR_SPECIAL_CONNECTIVITY", driver)
        self.assertIn("require_step_pass 15_postcts_via1_analyze", driver)
        self.assertIn("preroute-pg-no-restitch-rerun <expected-report-driver-head>", driver)
        self.assertIn("POST_CTS_MARKER_LAYER_SUBTYPE_COUNTS", driver)
        self.assertIn("VIA1/Cut_Enclosure:1000", driver)
        self.assertIn("SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH=0", driver)
        self.assertIn("PRE_ROUTE_DRC_GATE=NOT_RUN_INCOMPLETE_SIGNAL_GEOMETRY", driver)
        self.assertIn("ORDINARY_SIGNAL_ROUTE=RUN_CANONICAL_ROUTE_DESIGN", driver)
        self.assertIn("PREROUTE_PG_NO_RESTITCH_CANDIDATE_CLASSIFIED_NO_AUTOMATIC_PVS_STAGING_OR_PVS", driver)
        self.assertIn("require_step_pass 16_preroute_pg_no_restitch_rerun", driver)
        self.assertIn("final-closure-analyze <expected-report-driver-head>", driver)
        self.assertIn("17_final_closure_analysis.rpt", driver)
        self.assertIn("analyze_tx_packet_ooc_failure.py", driver)
        self.assertIn("FINAL_CLOSURE_BLOCKERS_CLASSIFIED_NO_DESIGN_MODIFICATION", driver)
        self.assertIn("REMOVE_NEGATIVE_COMPENSATION_KEEP_CANONICAL_CENTERS", driver)
        self.assertIn("READ_ONLY_TEXT_ARTIFACTS_NO_INNOVUS", driver)
        self.assertIn("require_step_pass 17_final_closure_analyze", driver)
        self.assertIn("min-area-second-pass-trial-r2 <expected-report-driver-head>", driver)
        self.assertIn("run_innovus_ooc_min_area_second_pass_trial.sh", driver)
        self.assertIn("analyze_tx_packet_min_area_second_pass_trial.py", driver)
        self.assertIn("MIN_AREA_SECOND_PASS_R2_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS", driver)
        self.assertIn("Step 18 R1 is immutable failed evidence", driver)
        self.assertIn("PRE_EXCLUDED_ANTENNA_MARKER_COUNT)\" != \"21\"", driver)
        self.assertIn("PRE_MARKER_DATABASE_TOTAL)\" != \"27\"", driver)
        self.assertIn("19_min_area_second_pass_trial_r2", driver)
        self.assertIn("require_step_pass 19_min_area_second_pass_trial_r2", driver)
        self.assertIn("min-area-geometry-probe <expected-report-driver-head>", driver)
        self.assertIn("run_innovus_ooc_min_area_geometry_probe.sh", driver)
        self.assertIn("analyze_tx_packet_min_area_geometry_probe.py", driver)
        self.assertIn("MIN_AREA_GEOMETRY_PROBE_CLASSIFIED_NO_DESIGN_MODIFICATION", driver)
        self.assertIn("20_min_area_geometry_probe", driver)
        self.assertIn("require_step_pass 20_min_area_geometry_probe", driver)
        self.assertIn("min-area-landing-patch-trial <expected-report-driver-head>", driver)
        self.assertIn("run_innovus_ooc_min_area_landing_patch_trial.sh", driver)
        self.assertIn("analyze_tx_packet_min_area_landing_patch_trial.py", driver)
        self.assertIn("MIN_AREA_LANDING_PATCH_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS", driver)
        self.assertIn("21_min_area_landing_patch_trial", driver)
        self.assertIn("require_step_pass 21_min_area_landing_patch_trial", driver)
        self.assertIn("min-area-landing-patch-trial-r2 <expected-report-driver-head>", driver)
        self.assertIn("SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R2", driver)
        self.assertIn("MIN_AREA_LANDING_PATCH_R2_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS", driver)
        self.assertIn("22_min_area_landing_patch_trial_r2", driver)
        self.assertIn("require_step_pass 22_min_area_landing_patch_trial_r2", driver)
        self.assertIn("min-area-landing-patch-trial-r3 <expected-report-driver-head>", driver)
        self.assertIn("SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R3", driver)
        self.assertIn("SOURCE_SATURATION_SIGNATURE_STATUS=", driver)
        self.assertIn("normalized_marker_signature_sha256", driver)
        self.assertIn('kv_field "$step22_status" HEAD_EXPECTED', driver)
        self.assertIn('kv_field "$step22_driver" EXPECTED_REPORT_DRIVER_HEAD', driver)
        self.assertIn('kv_field "$step22_analysis" TRIAL_ROOT', driver)
        self.assertIn("MIN_AREA_LANDING_PATCH_R3_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS", driver)
        self.assertIn("23_min_area_landing_patch_trial_r3", driver)
        self.assertIn("require_step_pass 23_min_area_landing_patch_trial_r3", driver)
        self.assertIn("min-area-landing-patch-trial-r4 <expected-report-driver-head>", driver)
        self.assertIn("SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R4", driver)
        self.assertIn("SOURCE_WIDTH_PRECONDITION_STATUS=", driver)
        self.assertIn("STEP23_PRE_SURVIVOR_SIGNATURE_SHA256=", driver)
        self.assertIn("STEP23_0P1064_MARKER_COUNT=", driver)
        self.assertIn("MIN_AREA_LANDING_PATCH_R4_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS", driver)
        self.assertIn("24_min_area_landing_patch_trial_r4", driver)
        landing_trial = (
            REPO
            / "TOP"
            / "pnr"
            / "scripts"
            / "run_innovus_ooc_min_area_landing_patch_trial.tcl"
        ).read_text()
        self.assertIn("FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28", landing_trial)
        self.assertIn("set half_width [expr {$patch_width / 2.0}]", landing_trial)
        self.assertIn("-width_horizontal $patch_width", landing_trial)
        self.assertIn("require_step_pass 11_pg_via_1x1_trial", driver)
        self.assertIn("preroute-pg-rerun <expected-report-driver-head>", driver)
        self.assertIn('actual_head" != "$expected_report_driver_head', driver)
        self.assertIn("SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS=1", driver)
        self.assertIn("SPADMIC_OOC_PG_DIRECT_VIA_AREAS=", driver)
        self.assertIn("analyze_tx_packet_preroute_pg_candidate.py", driver)
        self.assertIn("PREROUTE_PG_CANDIDATE_CLASSIFIED_NO_AUTOMATIC_PVS_STAGING_OR_PVS", driver)
        self.assertIn("CANDIDATE_EXPORT=RUN_LOCAL_AND_RUN_ID_HANDOFF_ONLY", driver)
        self.assertIn("IMMUTABLE_PVS_STAGING=NOT_RUN", driver)
        for forbidden in ("saveDesign", "defOut", "streamOut", "saveNetlist"):
            self.assertNotIn(forbidden, trial)

        stage_wrapper = (
            REPO
            / "TOP"
            / "pnr"
            / "scripts"
            / "run_innovus_ooc_postfiller_stage_probe.sh"
        ).read_text()
        stage_probe = (
            REPO
            / "TOP"
            / "pnr"
            / "scripts"
            / "run_innovus_ooc_postfiller_stage_probe.tcl"
        ).read_text()
        self.assertIn("03_cts.enc.dat", stage_wrapper)
        self.assertIn("</dev/null", stage_wrapper)
        self.assertIn("restoreDesign $checkpoint $top", stage_probe)
        self.assertIn("addFiller -cell $fillers -prefix FILL", stage_probe)
        self.assertIn("pf_capture_stage POST_CTS", stage_probe)
        self.assertIn("pf_capture_stage POST_FILLER_PRE_RESTITCH", stage_probe)
        self.assertNotRegex(stage_probe, re.compile(r"(?i)\bsroute\s+-"))
        for forbidden in ("saveDesign", "defOut", "streamOut", "saveNetlist"):
            self.assertNotIn(forbidden, stage_probe)

        min_area_wrapper = (
            REPO
            / "TOP"
            / "pnr"
            / "scripts"
            / "run_innovus_ooc_min_area_second_pass_trial.sh"
        ).read_text()
        min_area_trial = (
            REPO
            / "TOP"
            / "pnr"
            / "scripts"
            / "run_innovus_ooc_min_area_second_pass_trial.tcl"
        ).read_text()
        self.assertIn("ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL", min_area_wrapper)
        self.assertIn("05_postroute_export.enc.dat", min_area_wrapper)
        self.assertIn("</dev/null", min_area_wrapper)
        self.assertEqual(min_area_trial.count("restoreDesign $checkpoint $top"), 1)
        self.assertIn("SPADMIC_MIN_AREA_TRIAL_ITERATION_LIMIT", min_area_trial)
        self.assertIn("SPADMIC_MIN_AREA_TRIAL_REVISION", min_area_trial)
        self.assertIn("SOURCE_RUN_ANTENNA_MARKER_COUNT", min_area_trial)
        self.assertIn("RESTORED_BASELINE_ANTENNA_MARKER_COUNT", min_area_trial)
        self.assertIn(
            "RESTORED_MARKER_DB_REPRESENTATION_NOT_DIRECTLY_COMPARABLE_TO_SOURCE_RUN",
            min_area_trial,
        )
        self.assertIn("$iter_antenna_count != $pre_antenna_count", min_area_trial)
        self.assertIn("$pre_database_total != 27", min_area_trial)
        self.assertIn("$pre_antenna_count != 21", min_area_trial)
        self.assertLess(
            min_area_trial.index("set commands_fh [open $command_report w]"),
            min_area_trial.index("ma_abort BASELINE_PRECONDITION_FAILED"),
        )
        self.assertIn("globalDetailRoute -select", min_area_trial)
        self.assertIn("detailRoute -select", min_area_trial)
        self.assertIn("ecoRoute -fix_drc", min_area_trial)
        self.assertIn("FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT", min_area_trial)
        self.assertIn("FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", min_area_trial)
        self.assertIn("ITERATIVE_MIN_AREA_REPAIR_NO_IMPROVEMENT", min_area_trial)
        self.assertIn("ITERATIVE_MIN_AREA_REPAIR_VALIDATED", min_area_trial)
        for forbidden in ("saveDesign", "defOut", "streamOut", "saveNetlist"):
            self.assertNotIn(forbidden, min_area_trial)

        geometry_wrapper = (
            REPO
            / "TOP"
            / "pnr"
            / "scripts"
            / "run_innovus_ooc_min_area_geometry_probe.sh"
        ).read_text()
        geometry_probe = (
            REPO
            / "TOP"
            / "pnr"
            / "scripts"
            / "run_innovus_ooc_min_area_geometry_probe.tcl"
        ).read_text()
        self.assertIn(
            "ONE_FRESH_PROCESS_ONE_RESTORE_READ_ONLY_LOCAL_GEOMETRY_PROBE",
            geometry_wrapper,
        )
        self.assertIn("05_postroute_export.enc.dat", geometry_wrapper)
        self.assertIn("</dev/null", geometry_wrapper)
        self.assertEqual(geometry_probe.count("restoreDesign $checkpoint $top"), 1)
        self.assertIn("foreach object {net wire instTerm inst term pin pinShape", geometry_probe)
        self.assertIn("dbGet top.insts.instTerms.net.name $net -p2", geometry_probe)
        self.assertIn("MASTER_LOCAL_REQUIRES_INSTANCE_TRANSFORM", geometry_probe)
        self.assertIn("min_area_local_vias.tsv", geometry_probe)
        self.assertIn("verify_drc_pre_probe.rpt", geometry_probe)
        self.assertIn("verify_drc_post_probe.rpt", geometry_probe)
        self.assertIn("DESIGN_MODIFICATION NOT_RUN", geometry_probe)
        self.assertNotIn("editDelete", geometry_probe)
        self.assertNotIn("globalDetailRoute", geometry_probe)
        self.assertNotIn("detailRoute -select", geometry_probe)
        self.assertNotIn("ecoRoute", geometry_probe)
        self.assertNotIn("selectNet", geometry_probe)
        for forbidden in ("saveDesign", "defOut", "streamOut", "saveNetlist"):
            self.assertNotIn(forbidden, geometry_probe)

        landing_wrapper = (
            REPO
            / "TOP"
            / "pnr"
            / "scripts"
            / "run_innovus_ooc_min_area_landing_patch_trial.sh"
        ).read_text()
        landing_trial = (
            REPO
            / "TOP"
            / "pnr"
            / "scripts"
            / "run_innovus_ooc_min_area_landing_patch_trial.tcl"
        ).read_text()
        self.assertIn(
            "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MET1_LANDING_EXTENSIONS",
            landing_wrapper,
        )
        self.assertIn("05_postroute_export.enc.dat", landing_wrapper)
        self.assertIn("</dev/null", landing_wrapper)
        self.assertEqual(landing_trial.count("restoreDesign $checkpoint $top"), 1)
        self.assertIn("VIA1_o", landing_trial)
        self.assertIn("MET2", landing_trial)
        self.assertIn("PATCH_CONTRACT_PRECONDITION_FAILED", landing_trial)
        self.assertIn("setEditMode", landing_trial)
        self.assertIn("uiSetTool addWire", landing_trial)
        self.assertIn("editAddRoute", landing_trial)
        self.assertIn("editCommitRoute", landing_trial)
        self.assertIn("SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION", landing_wrapper)
        self.assertIn("SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION", landing_trial)
        self.assertIn("FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56", landing_trial)
        self.assertIn(
            "FOUR_SURVIVORS_AWAY_FROM_SOURCE_TWO_CLOSED_TOWARD_SOURCE",
            landing_trial,
        )
        self.assertIn("719.04 0.84", landing_trial)
        self.assertIn("1667.12 0.84", landing_trial)
        self.assertIn("720.72 0.84", landing_trial)
        self.assertIn("1665.44 0.84", landing_trial)
        self.assertIn("1792.28 0.56", landing_trial)
        self.assertIn("-width_horizontal $patch_width", landing_trial)
        self.assertIn("-width_vertical $patch_width", landing_trial)
        self.assertIn("verify_drc_pre_trial.rpt", landing_trial)
        self.assertIn("verify_drc_post_trial.rpt", landing_trial)
        self.assertIn("FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT", landing_trial)
        self.assertIn("FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", landing_trial)
        self.assertIn("SIX_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED", landing_trial)
        self.assertIn("MIXED_LENGTH_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED", landing_trial)
        self.assertIn("MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED", landing_trial)
        self.assertIn("MIXED_WIDTH_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED", landing_trial)
        for forbidden in ("saveDesign", "defOut", "streamOut", "saveNetlist"):
            self.assertNotIn(forbidden, landing_trial)

    def test_init_inherits_an_accepted_phase1_gate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            work_root = root / "work"
            phase1 = work_root / "diagnostics" / "phase1"
            genus_block = work_root / "genus" / "genus_unit" / "tx_packet_core"
            (phase1 / "reports").mkdir(parents=True)
            genus_block.mkdir(parents=True)
            (phase1 / "reports" / "07_genus_gate.rpt").write_text(
                "STATUS=PASS\n"
                "RESULT=READY_FOR_PACKET_INNOVUS_FEASIBILITY\n"
                f"BLOCK_ROOT={genus_block}\n"
                "ERROR_COUNT=0\n"
                "INNOVUS_FEASIBILITY_READY=YES\n"
                "SIGNOFF_READY=NO\n"
                "MMMC_STATUS=NOT_RUN_TYPICAL_ONLY\n"
            )
            active_env = root / "phase2_active.env"
            env = os.environ.copy()
            env.update(
                {
                    "SPADMIC_WORK_ROOT": str(work_root),
                    "SPADMIC_TX_PACKET_PHASE2_ACTIVE_ENV": str(active_env),
                    "SPADMIC_TX_REPO": str(REPO),
                }
            )
            result = subprocess.run(
                ["bash", str(DRIVER), "init", "deadbeef", str(phase1)],
                cwd=REPO,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertTrue(active_env.is_file())
            active_text = active_env.read_text()
            self.assertIn("TX2_EXPECTED_HEAD=deadbeef", active_text)
            self.assertIn("TX2_GENUS_RUN=genus_unit", active_text)
            self.assertIn(f"TX2_PHASE1_ROOT={phase1}", active_text)

            sessions = list((work_root / "diagnostics").glob("tx_packet_canonical_phase2_*"))
            self.assertEqual(len(sessions), 1)
            session = sessions[0]
            objective = (session / "00_objective_and_policy.rpt").read_text()
            self.assertIn("PG_POLICY=EXPLICIT_EXACT_METTP_STRIPES_COREPIN_SROUTE", objective)
            self.assertIn("PVS_POLICY=NOT_RUN_IN_THIS_PHASE", objective)
            status = (session / "status" / "00_init.rpt").read_text()
            self.assertIn("STATUS=PASS", status)
            self.assertIn("RESULT=SESSION_INITIALIZED", status)


if __name__ == "__main__":
    unittest.main()
