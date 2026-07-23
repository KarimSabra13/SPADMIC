#!/usr/bin/env python3

from __future__ import annotations

import csv
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
GENERATOR = REPO / "TOP" / "pnr" / "scripts" / "gen_spadmic_digital_assembly_v1.py"
CONTRACT = REPO / "TOP" / "pnr" / "assembly" / "spadmic_digital_assembly_contract.json"
RTL = REPO / "TOP" / "pnr" / "assembly" / "spadmic_digital_assembly_v1.sv"

OOC_MODULE_PATH = REPO / "TOP" / "pnr" / "scripts" / "gen_ooc_block_harden_plan.py"
OOC_SPEC = importlib.util.spec_from_file_location("ooc_harden_plan", OOC_MODULE_PATH)
assert OOC_SPEC and OOC_SPEC.loader
ooc = importlib.util.module_from_spec(OOC_SPEC)
sys.modules[OOC_SPEC.name] = ooc
OOC_SPEC.loader.exec_module(ooc)


class DigitalAssemblyPlanTest(unittest.TestCase):
    @staticmethod
    def _write_tsv(path: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
        with path.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames, delimiter="\t", lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)

    def _make_audit(self, root: Path) -> Path:
        audit = root / "audit"
        audit.mkdir()
        (audit / "assembly_audit_status.rpt").write_text(
            "STATUS=PASS\n"
            "P00_P02_IMPLEMENTATION_AUTHORIZED=YES\n"
            "P03_IMPLEMENTATION_AUTHORIZED=YES\n"
            "SPADMIC2_DIE_BBOX_UM=0.000 0.000 400.000 400.000\n",
            encoding="utf-8",
        )
        self._write_tsv(
            audit / "fixed_obstacles.tsv",
            ["instance", "llx", "lly", "urx", "ury"],
            [{"instance": "analog_fixed", "llx": "300", "lly": "0", "urx": "400", "ury": "400"}],
        )
        groups = [
            "tx_packet", "tx_ddr_strip", "position", "event", "matrix_or",
            "matrix_snapshot_reset", "matrix_cfg",
        ]
        self._write_tsv(
            audit / "soft_group_guides.tsv",
            ["group", "llx", "lly", "urx", "ury"],
            [
                {"group": group, "llx": str(index * 10), "lly": "10", "urx": str(index * 10 + 8), "ury": "80"}
                for index, group in enumerate(groups)
            ],
        )
        self._write_tsv(
            audit / "pg_overlap_anchors.tsv",
            ["net", "layer", "llx", "lly", "urx", "ury"],
            [
                {"net": "VDD", "layer": "METTP", "llx": "20", "lly": "0", "urx": "24", "ury": "400"},
                {"net": "VSS", "layer": "METTP", "llx": "40", "lly": "0", "urx": "44", "ury": "400"},
            ],
        )
        self._write_tsv(
            audit / "matrice5_proxy_pin_access.tsv",
            ["terminal", "family", "index", "direction", "layer", "purpose", "llx", "lly", "urx", "ury"],
            [
                {"terminal": "R<0>", "family": "R", "index": "0", "direction": "OUTPUT", "layer": "MET3", "purpose": "drawing", "llx": "1", "lly": "2", "urx": "3", "ury": "4"},
                {"terminal": "Din<0>", "family": "Din", "index": "0", "direction": "INPUT", "layer": "MET2", "purpose": "drawing", "llx": "5", "lly": "6", "urx": "7", "ury": "8"},
            ],
        )
        return audit

    def test_contract_defines_exact_cumulative_soft_phase_order(self) -> None:
        contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        self.assertEqual(contract["schema"], "spadmic.digital_assembly.contract.v2")
        self.assertEqual(list(contract["phases"]), ["p00_tx", "p01_position", "p02_event_control", "p03_matrix_interface"])
        self.assertEqual(
            [contract["phases"][phase]["top"] for phase in contract["phases"]],
            [
                "spadmic_digital_assembly_v1_p00_tx",
                "spadmic_digital_assembly_v1_p01_position",
                "spadmic_digital_assembly_v1_p02_event_control",
                "spadmic_digital_assembly_v1_p03_matrix_interface",
            ],
        )
        self.assertEqual(contract["physical_policy"]["implementation"], "CUMULATIVE_SOFT_LOGIC")
        self.assertEqual(contract["physical_policy"]["ordinary_signal_layers"], ["MET1", "MET2", "MET3"])
        self.assertEqual(contract["physical_policy"]["target_utilization"], 0.60)
        self.assertEqual(contract["physical_policy"]["max_local_density"], 0.70)
        self.assertEqual(contract["phases"]["p03_matrix_interface"]["allowed_density_rules"], ["R1M1", "R1M2", "R1M3", "R1MT"])
        self.assertEqual(contract["source_layouts"]["matrice5"]["library"], "SPADMIC")
        self.assertEqual(
            contract["source_layouts"]["matrice5"]["filesystem_path"],
            "/group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL/matrice5",
        )
        for phase in ("p00_tx", "p01_position", "p02_event_control"):
            self.assertEqual(contract["phases"][phase]["density_gate"], "NOT_RUN")
        self.assertIn("BLOCKED", contract["deferred"]["p04_mptdc_frontend"])
        self.assertEqual(contract["deferred"]["p05_csr_i2c"], "DEFERRED")

    def test_rtl_contains_exact_cumulative_tops_and_matrix_boundary(self) -> None:
        rtl = RTL.read_text(encoding="utf-8")
        for top in json.loads(CONTRACT.read_text(encoding="utf-8"))["phases"].values():
            self.assertEqual(rtl.count(f"module {top['top']} ("), 1)
        self.assertIn("spadmic_digital_assembly_v1_p01_position u_phase_p01", rtl)
        self.assertIn("spadmic_digital_assembly_v1_p02_event_control u_phase_p02", rtl)
        self.assertIn("spadmic_matrix_or_tree u_matrix_or_r", rtl)
        self.assertIn("spadmic_matrix_snapshot_frontend u_matrix_snapshot", rtl)
        self.assertIn("spadmic_matrix_reset_ctrl u_matrix_reset", rtl)
        self.assertIn("spadmic_matrix_cfg_ctrl u_matrix_cfg", rtl)
        self.assertIn("input  logic [2:0]                                  mptdc_ready_i", rtl)
        self.assertIn("input  logic                                        matrix_cfg_cmd_start_i", rtl)
        self.assertNotIn("spadmic_digital_assembly_v1_sequencer", rtl)

    def test_phase_generator_is_audit_bound_and_has_no_child_macros(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            audit = self._make_audit(root)
            for phase, expected_proxy_rows in (("p00_tx", 0), ("p03_matrix_interface", 2)):
                output = root / phase
                result = subprocess.run(
                    [sys.executable, str(GENERATOR), "--phase", phase, "--audit-root", str(audit), "--out", str(output)],
                    cwd=REPO,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stdout)
                status = (output / "assembly_phase_contract_status.rpt").read_text()
                config = (output / "assembly_phase_config.tcl").read_text()
                self.assertIn("IMPLEMENTATION=CUMULATIVE_SOFT_LOGIC", status)
                self.assertIn("HARD_MACRO_COUNT=0", status)
                self.assertIn("CHILD_GDS_MERGE_COUNT=0", status)
                self.assertIn("SIGNAL_ROUTE_LAYERS=MET1-MET3", status)
                self.assertIn("variable hard_macro_count 0", config)
                self.assertIn("variable child_gds_merge_count 0", config)
                self.assertIn("set pg_anchors(VDD)", config)
                self.assertIn("set pg_anchors(VSS)", config)
                with (output / "matrix_proxy_pin_plan.tsv").open(newline="") as handle:
                    proxy_rows = list(csv.DictReader(handle, delimiter="\t"))
                self.assertEqual(len(proxy_rows), expected_proxy_rows)
                manifest = subprocess.run(
                    ["sha256sum", "-c", "SHA256SUMS"], cwd=output, text=True,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
                )
                self.assertEqual(manifest.returncode, 0, manifest.stdout)
            p03_proxy = (root / "p03_matrix_interface" / "matrix_proxy_pin_plan.tsv").read_text()
            self.assertIn("R_i[0]\tR<0>", p03_proxy)
            self.assertIn("matrix_din_o[0]\tDin<0>", p03_proxy)

    def test_server_flow_keeps_one_eda_action_per_review_gate(self) -> None:
        genus = (REPO / "TOP" / "ci" / "server_run_digital_assembly_phase_genus.sh").read_text()
        innovus = (REPO / "TOP" / "pnr" / "scripts" / "run_innovus_digital_assembly.sh").read_text()
        pvs = (REPO / "TOP" / "ci" / "server_run_digital_assembly_phase_pvs.sh").read_text()
        self.assertEqual(genus.count("genus -files TOP/syn/scripts/run_genus_matrix_block.tcl"), 1)
        self.assertEqual(innovus.count("innovus -nowin -init"), 1)
        self.assertEqual(pvs.count("bash TOP/pnr/scripts/run_pvs_drc_handoff.sh"), 1)
        self.assertEqual(pvs.count("bash TOP/pnr/scripts/run_pvs_lvs_handoff.sh"), 1)
        self.assertIn("density is authorized only for p03_matrix_interface", pvs)
        self.assertIn("DO_NOT_START_NEXT_PVS_MODE_UNTIL_REVIEWED", pvs)

    def test_oa_audit_avoids_unneeded_matrice5_internal_traversal(self) -> None:
        audit = (REPO / "TOP" / "pnr" / "scripts" / "audit_spadmic2_assembly_contract.il").read_text()
        self.assertIn(
            "procedure(spadmicAuditWriteInstancePins(cv path targetLib targetCell targetView)",
            audit,
        )
        self.assertIn("master~>libName == targetLib", audit)
        self.assertIn("master~>cellName == targetCell", audit)
        self.assertIn('if(role == "spadmic2" then', audit)
        self.assertIn("SPADMIC_OA_AUDIT_PROGRESS=WRITE_SPADMIC2_TOP_CONTRACT", audit)
        self.assertIn("SPADMIC_OA_AUDIT_PROGRESS=WRITE_MATRICE5_TOP_TERMINALS", audit)

    def test_oa_audit_uses_xfab_project_launch_context_and_completion_gate(self) -> None:
        wrapper = (
            REPO / "TOP" / "ci" / "server_audit_spadmic2_assembly_contract.sh"
        ).read_text()
        audit = (
            REPO / "TOP" / "pnr" / "scripts" / "audit_spadmic2_assembly_contract.il"
        ).read_text()
        self.assertIn(
            "SPADMIC_CADENCE_LAUNCH_DIR:-/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0",
            wrapper,
        )
        self.assertIn('ENTRY_HEAD="$(git rev-parse HEAD 2>/dev/null)"', wrapper)
        self.assertIn('[ "$ENTRY_HEAD" != "$ACTUAL_HEAD" ]', wrapper)
        self.assertIn("export SPADMIC_AUDIT_REEXECUTED=1", wrapper)
        self.assertIn(
            'exec bash "$REPO/TOP/ci/server_audit_spadmic2_assembly_contract.sh"',
            wrapper,
        )
        self.assertIn('CADENCE_CDS_LIB="$CADENCE_LAUNCH_DIR/cds.lib"', wrapper)
        self.assertIn(
            'SPADMIC2_SESSION_CDS_LIB="$DIAGNOSTIC_ROOT/spadmic2_session.cds.lib"',
            wrapper,
        )
        self.assertIn(
            'MATRICE5_SESSION_CDS_LIB="$DIAGNOSTIC_ROOT/matrice5_session.cds.lib"',
            wrapper,
        )
        self.assertIn('echo "INCLUDE $CADENCE_CDS_LIB"', wrapper)
        self.assertIn('echo "UNDEFINE SPADMIC"', wrapper)
        self.assertIn('echo "DEFINE SPADMIC $MATRIX_OA_LIBRARY_PATH"', wrapper)
        self.assertIn('cd "$CADENCE_LAUNCH_DIR"', wrapper)
        self.assertIn('-cdslib "$session_cds_lib"', wrapper)
        self.assertIn('SPADMIC_OA_AUDIT_ROLE="$role"', wrapper)
        self.assertIn(
            'run_oa_role \\\n        matrice5 \\\n        "$MATRICE5_SESSION_CDS_LIB"',
            wrapper,
        )
        self.assertIn(
            'run_oa_role \\\n        spadmic2 \\\n        "$SPADMIC2_SESSION_CDS_LIB"',
            wrapper,
        )
        self.assertIn(
            '-restore "$REPO/TOP/pnr/scripts/audit_spadmic2_assembly_contract.il"',
            wrapper,
        )
        self.assertIn("</dev/null", wrapper)
        self.assertIn(
            "EXPECTED_XFAB_COMMAND=xfab -p Prj_xh018 -t xh018 -m 1131 -y 2023 -v",
            wrapper,
        )
        self.assertIn('"$RAW_ROOT/virtuoso_export_status.rpt"', wrapper)
        self.assertIn('"$RAW_ROOT/matrice5_virtuoso_export_status.rpt"', wrapper)
        self.assertIn('"$RAW_ROOT/spadmic2_virtuoso_export_status.rpt"', wrapper)
        self.assertIn('export SPADMIC_OA_MATRIX_LIBRARY=SPADMIC', wrapper)
        self.assertIn("OA_EXTRACTION_PROCESS_COUNT=2", wrapper)
        self.assertIn("OA_EXTRACTION_PROCESS_ORDER=matrice5,spadmic2", wrapper)
        self.assertIn("SOURCE_IDENTITY_COMBINE_RC", wrapper)
        self.assertIn("grep -Fxq 'STATUS=PASS'", wrapper)
        self.assertIn(
            "CADENCE_SESSION_CDS_LIB_MODE=PROCESS_ISOLATED_SOURCE_BINDINGS",
            wrapper,
        )
        self.assertIn("SOURCE_CDS_LIB_MUTATION_AUTHORIZED=NO", wrapper)
        self.assertIn('role = getShellEnvVar("SPADMIC_OA_AUDIT_ROLE")', audit)
        self.assertIn(
            'unless(role == "spadmic2" || role == "matrice5"',
            audit,
        )
        self.assertIn(
            'identityPath = strcat(outRoot "/" role "_source_identity.tsv")',
            audit,
        )
        self.assertNotIn('identityPath = strcat(outRoot "/source_identity.tsv")', audit)
        self.assertIn("runResult = errset(spadmicAuditAssemblyMain() t)", audit)
        self.assertIn('fprintf(statusFp "STATUS=FAIL\\n")', audit)
        self.assertIn("SPADMIC_OA_AUDIT_COMPLETION_STATUS=PASS", audit)
        self.assertNotIn("dbSave(", audit)
        self.assertNotIn("dbCreate", audit)
        self.assertNotIn("dbDelete", audit)

    def test_oa_skill_text_sanitizers_use_ic23_rex_contract(self) -> None:
        for relative_path in (
            "audit_spadmic2_assembly_contract.il",
            "insert_digital_assembly_p03_into_spadmic2.il",
        ):
            skill = (REPO / "TOP" / "pnr" / "scripts" / relative_path).read_text()
            self.assertIn('rexCompile("[\\t\\n\\r]")', skill)
            self.assertIn('rexReplace(text " " 0)', skill)
            self.assertNotIn('rexReplace(text "[\\t\\n\\r]" " " 0)', skill)

    def test_oa_audit_preserves_exact_source_stability_deltas(self) -> None:
        wrapper = (
            REPO / "TOP" / "ci" / "server_audit_spadmic2_assembly_contract.sh"
        ).read_text()
        self.assertIn("! -name '.nfs*'", wrapper)
        self.assertIn("! -name '*.cdslck'", wrapper)
        self.assertIn("! -name '*.cdslck.*'", wrapper)
        self.assertIn("! -name '*.oa.*.oacache'", wrapper)
        self.assertNotIn("! -name '*.oacache'", wrapper)
        self.assertIn("POLICY=CANONICAL_OA_CONTENT_V2", wrapper)
        self.assertIn(
            'echo "EXCLUDED_BASENAME_PATTERN=*.oa.*.oacache"',
            wrapper,
        )
        self.assertIn('source_inventory_policy.rpt"', wrapper)
        self.assertIn('> "$DIAGNOSTIC_ROOT/spadmic2_source_delta.rpt"', wrapper)
        self.assertIn('> "$DIAGNOSTIC_ROOT/matrice5_source_delta.rpt"', wrapper)
        self.assertIn("SPADMIC2_SOURCE_DELTA_REPORT=", wrapper)
        self.assertIn("MATRICE5_SOURCE_DELTA_REPORT=", wrapper)

    def test_innovus_flow_rejects_child_macro_implementation(self) -> None:
        tcl = (REPO / "TOP" / "pnr" / "scripts" / "run_innovus_digital_assembly.tcl").read_text()
        wrapper = (REPO / "TOP" / "pnr" / "scripts" / "run_innovus_digital_assembly.sh").read_text()
        self.assertIn("SPADMIC_DA_HARD_MACRO_GATE_FAILED", tcl)
        self.assertIn("HARD_MACRO_COUNT", tcl)
        self.assertIn("CHILD_GDS_MERGE_COUNT=0", wrapper)
        self.assertIn("setNanoRouteMode -routeBottomRoutingLayer 1", tcl)
        self.assertIn("setNanoRouteMode -routeTopRoutingLayer 3", tcl)
        self.assertIn("METTP_POLICY PG_AND_BOUNDED_PIN_ACCESS_ONLY", tcl)

    def test_clean_ooc_pg_uses_exact_geometry_before_signal_route(self) -> None:
        tcl = (REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_harden_block.tcl").read_text()
        wrapper = (REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_harden_block.sh").read_text()
        self.assertIn("$vdd_cx - $core_margin - $strap_width / 2.0", tcl)
        self.assertIn("$vss_cx - $core_margin - $strap_width / 2.0", tcl)
        self.assertIn("add_shape -net $net -layer $layer -shape STRIPE", tcl)
        self.assertIn("-corePinCheckStdcellGeoms", tcl)
        self.assertIn("SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS", tcl)
        self.assertIn("SPADMIC_OOC_PG_DIRECT_VIA_AREAS", tcl)
        self.assertIn("-via_rows 1 -via_columns 1", tcl)
        self.assertIn("setViaGenMode -area_only 0", tcl)
        self.assertIn("PG_DIRECT_VIA_PRE_CTS_CONNECTIVITY_STATUS", tcl)
        self.assertIn("PG_DIRECT_VIA_PRE_CTS_DRC_STATUS", tcl)
        self.assertIn("SPADMIC_OOC_PRE_CTS_EXPECTED_DANGLING_COUNT", tcl)
        self.assertIn("SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH", tcl)
        self.assertIn("EXPECTED_DANGLING_ONLY", tcl)
        self.assertIn("SROUTE_PG_POST_FILLER", tcl)
        self.assertIn("PG_POST_FILLER_CONNECTIVITY_STATUS", tcl)
        self.assertIn("PG_POST_FILLER_DRC_STATUS", tcl)
        self.assertLess(
            tcl.index("        spadmic_ooc_route_pg\n"),
            tcl.index("    spadmic_ooc_cts_design\n"),
        )
        self.assertLess(
            tcl.index("    spadmic_ooc_route_pg\n"),
            tcl.index("    spadmic_ooc_route_design\n"),
        )
        self.assertLess(
            tcl.index("    spadmic_ooc_add_fillers\n"),
            tcl.index("        spadmic_ooc_post_filler_pg_restitch\n"),
        )
        self.assertLess(
            tcl.index("        spadmic_ooc_post_filler_pg_restitch\n"),
            tcl.index("    spadmic_ooc_route_design\n"),
        )
        self.assertIn("--required-merge \"$SPADMIC_STDCELL_GDS\"", wrapper)
        self.assertIn('[[ "$gds_audit_rc" -eq 0 ]]', wrapper)
        self.assertIn("</dev/null", wrapper)
        self.assertIn('summary_route_profile="$(status_value ROUTE_PROFILE)"', wrapper)
        self.assertIn('summary_signal_route_layers="$(status_value SIGNAL_ROUTE_LAYERS)"', wrapper)
        self.assertIn('summary_pg_local_route_mode="$(status_value PG_LOCAL_ROUTE_MODE)"', wrapper)
        self.assertIn('summary_pg_route_strategy="$(status_value PG_ROUTE_STRATEGY)"', wrapper)
        self.assertIn('echo "- OOC route profile: \\`$summary_route_profile\\`"', wrapper)
        self.assertIn('echo "- Local PG route mode: \\`$summary_pg_local_route_mode\\`"', wrapper)
        self.assertNotIn('echo "- OOC route profile: \\`${SPADMIC_OOC_ROUTE_PROFILE:-default}\\`"', wrapper)

    def test_pg_geometry_fix_preserves_signal_implementation(self) -> None:
        script = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.tcl"
        ).read_text()
        self.assertIn("add_shape -net VDD -layer METTP -shape STRIPE", script)
        self.assertIn("add_shape -net VSS -layer METTP -shape STRIPE", script)
        self.assertIn("sroute -connect {corePin}", script)
        self.assertNotIn("blockPin", script)
        for forbidden in ("routeDesign", "placeDesign", "ccopt_design", "clockDesign"):
            self.assertNotIn(forbidden, script)

    def test_pg_geometry_fix_uses_marker_derived_extents(self) -> None:
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        ).read_text()
        self.assertIn("SPADMIC_PG_FIX_VDD_X_FALLBACK_UM:-858.480", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VSS_X_FALLBACK_UM:-2574.880", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VDD_Y0_UM:-10.080", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VSS_Y0_UM:-14.560", wrapper)
        self.assertIn("SPADMIC_PG_FIX_Y1_UM:-180.880", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VDD_HELPER_Y0_UM:-126.560", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VDD_HELPER_Y1_UM:-153.440", wrapper)

    def test_pg_helper_candidates_use_fresh_innovus_processes(self) -> None:
        script = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.tcl"
        ).read_text()
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        ).read_text()
        self.assertEqual(script.count("restoreDesign"), 1)
        self.assertNotIn("restore_db_stop_at_design_in_memory", script + wrapper)
        self.assertIn("for CANDIDATE_X in", wrapper)
        self.assertIn("SPADMIC_PG_FIX_TRIAL_MODE=1", wrapper)
        self.assertIn("SPADMIC_PG_FIX_TRIAL_MODE=0", wrapper)
        self.assertIn("ACCEPT_FOR_CANONICAL_REPLAY", wrapper)
        self.assertIn("ONE_INNOVUS_PROCESS_PER_CANDIDATE", script)

    def test_pg_helper_candidates_are_fail_closed(self) -> None:
        script = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.tcl"
        ).read_text()
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        ).read_text()
        self.assertIn("PG_HELPER_CANDIDATE_REJECTED", script)
        self.assertIn("NOT_RUN_CANDIDATE_TRIAL", script)
        self.assertIn('status(PG_CONNECTIVITY_STATUS) ne "PASS"', script)
        self.assertIn('status(PG_MARKER_COUNT) != 0', script)
        self.assertIn('status(REGULAR_CONNECTIVITY_STATUS) ne "PASS"', script)
        self.assertIn('status(INNOVUS_DRC_STATUS) ne "PASS"', script)
        self.assertIn('TRIAL_PG" == "0"', wrapper)
        self.assertIn('TRIAL_MARKERS" == "0"', wrapper)
        self.assertIn('TRIAL_REGULAR" == "0"', wrapper)
        self.assertIn('TRIAL_DRC" == "0"', wrapper)
        self.assertIn("FAIL_NO_CLEAN_CANDIDATE", wrapper)

    def test_pg_wrapper_replays_clean_trial_in_fresh_process(self) -> None:
        wrapper = REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            checkpoint = root / "source" / "checkpoints" / "05_postroute_export.enc.dat"
            checkpoint.mkdir(parents=True)
            stream_map = root / "stream.map"
            stdcell_gds = root / "stdcells.gds"
            stream_map.write_text("map\n")
            stdcell_gds.write_text("gds\n")

            calls = root / "innovus_calls.tsv"
            fake_bin = root / "bin"
            fake_bin.mkdir()
            fake_innovus = fake_bin / "innovus"
            fake_innovus.write_text(
                "#!/usr/bin/env bash\n"
                "set -u\n"
                "printf '%s\\t%s\\n' \"$SPADMIC_PG_FIX_TRIAL_MODE\" "
                "\"$SPADMIC_PG_FIX_RUN_ROOT\" >>\"$FAKE_INNOVUS_CALLS\"\n"
                "mkdir -p \"$SPADMIC_PG_FIX_RUN_ROOT/reports\"\n"
                "if [[ \"$SPADMIC_PG_FIX_TRIAL_MODE\" == 1 ]]; then\n"
                "  {\n"
                "    echo STATUS=PASS\n"
                "    echo RESULT=PG_HELPER_CANDIDATE_CLEAN\n"
                "    echo PG_CONNECTIVITY_VIOLATION_COUNT=0\n"
                "    echo PG_MARKER_COUNT=0\n"
                "    echo REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
                "    echo DRC_MARKER_TOTAL=0\n"
                "  } >\"$SPADMIC_PG_FIX_RUN_ROOT/reports/pg_geometry_fix_status.rpt\"\n"
                "  exit 0\n"
                "fi\n"
                "{\n"
                "  echo STATUS=FAIL\n"
                "  echo RESULT=CANONICAL_REPLAY_TEST_STOP\n"
                "} >\"$SPADMIC_PG_FIX_RUN_ROOT/reports/pg_geometry_fix_status.rpt\"\n"
                "exit 8\n"
            )
            fake_innovus.chmod(0o755)

            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{fake_bin}:{env.get('PATH', '')}",
                    "FAKE_INNOVUS_CALLS": str(calls),
                    "SPADMIC_WORK_ROOT": str(root / "work"),
                    "SPADMIC_STREAMOUT_MAP_FILE": str(stream_map),
                    "SPADMIC_STDCELL_GDS": str(stdcell_gds),
                    "SPADMIC_PG_FIX_VDD_HELPER_CANDIDATES_UM": "970.480 746.480",
                }
            )
            result = subprocess.run(
                [str(wrapper), str(root / "source"), "tx_ddr_strip", "pg_process_test"],
                cwd=REPO,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )

            self.assertEqual(result.returncode, 8, result.stdout)
            invocation_rows = [line.split("\t") for line in calls.read_text().splitlines()]
            self.assertEqual([row[0] for row in invocation_rows], ["1", "0"])
            self.assertNotEqual(invocation_rows[0][1], invocation_rows[1][1])
            self.assertIn("/trials/trial_01_x_970p480", invocation_rows[0][1])
            self.assertTrue(invocation_rows[1][1].endswith("/innovus/pg_process_test"))

            run_root = root / "work" / "innovus" / "pg_process_test"
            candidate_summary = (run_root / "reports" / "vdd_helper_candidate_summary.tsv").read_text()
            self.assertIn("ACCEPT_FOR_CANONICAL_REPLAY", candidate_summary)
            self.assertEqual(list((run_root / "trials" / "trial_01_x_970p480" / "outputs").iterdir()), [])
            wrapper_status = (run_root / "reports" / "pg_geometry_fix_wrapper_status.rpt").read_text()
            self.assertIn("CANONICAL_REPLAY=RUN", wrapper_status)
            self.assertIn("CANONICAL_INNOVUS_RC=8", wrapper_status)


if __name__ == "__main__":
    unittest.main()
