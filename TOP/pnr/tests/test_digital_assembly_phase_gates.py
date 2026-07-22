#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
INNOVUS_VALIDATOR = REPO / "TOP/pnr/scripts/validate_innovus_digital_assembly_phase.py"
PVS_VALIDATOR = REPO / "TOP/pnr/scripts/validate_digital_assembly_pvs_phase.py"
OA_VALIDATOR = REPO / "TOP/pnr/scripts/validate_digital_assembly_oa_candidate.py"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_kv(path: Path, values: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "".join(f"{key}={value}\n" for key, value in values.items()),
        encoding="utf-8",
    )


def write_manifest(root: Path, manifest: Path, files: list[Path]) -> None:
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text(
        "".join(f"{sha256(path)}  {path.relative_to(root)}\n" for path in sorted(files)),
        encoding="utf-8",
    )


class DigitalAssemblyPhaseGateTest(unittest.TestCase):
    top = "spadmic_digital_assembly_v1_p03_matrix_interface"

    def run_script(self, script: Path, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(script), *args],
            cwd=REPO,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def test_innovus_validator_requires_independent_physical_gates(self) -> None:
        phase = "p00_tx"
        top = "spadmic_digital_assembly_v1_p00_tx"
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run = root / "run"
            reports = run / "reports"
            outputs = run / "outputs"
            genus = root / "genus"
            phase_contract = root / "phase_contract"
            reports.mkdir(parents=True)
            outputs.mkdir()
            (genus / "reports/timing").mkdir(parents=True)
            phase_contract.mkdir()

            implementation = {
                "STATUS": "PASS", "PHASE": phase, "TOP_MODULE": top,
                "SOURCE_TOP": top, "LAYOUT_TOP": top,
                "IMPLEMENTATION": "CUMULATIVE_SOFT_LOGIC",
                "HARD_MACRO_COUNT": 0, "HARD_MACRO_STATUS": "PASS",
                "CHILD_GDS_MERGE_COUNT": 0,
                "FLOORPLAN_GEOMETRY_STATUS": "PASS",
                "FIXED_OBSTACLE_STATUS": "PASS", "SOFT_GUIDE_STATUS": "PASS",
                "SOFT_GUIDE_COUNT": 2, "SIGNAL_PIN_PLACEMENT_STATUS": "PASS",
                "EXACT_PROXY_PIN_STATUS": "NOT_APPLICABLE", "EXACT_PROXY_PIN_COUNT": 0,
                "PG_ANCHOR_STATUS": "PASS", "PG_CONNECTIVITY_STATUS": "PASS",
                "REGULAR_CONNECTIVITY_STATUS": "PASS", "INNOVUS_DRC_STATUS": "PASS",
                "TC_TIMING_CAPTURE_STATUS": "PASS", "STANDARD_CELL_FILL_STATUS": "PASS",
                "SIGNAL_ROUTE_LAYERS": "MET1-MET3",
                "METTP_POLICY": "PG_AND_BOUNDED_PIN_ACCESS_ONLY",
                "EXPORT_DEF_STATUS": "PASS", "EXPORT_LEF_STATUS": "PASS",
                "EXPORT_GDS_STATUS": "PASS", "EXPORT_NETLIST_STATUS": "PASS",
                "EXPORT_PG_NETLIST_STATUS": "PASS", "PVS_EXECUTED": "NO",
                "PLACE_DESIGN": "PASS", "CTS_DESIGN": "PASS", "ADD_FILLER": "PASS",
                "ROUTE_DESIGN": "PASS", "POSTROUTE_SETUP_TIMING": "PASS",
                "POSTROUTE_HOLD_TIMING": "PASS",
                "INNOVUS_DRC_VIOLATION_COUNT": 0,
                "REGULAR_CONNECTIVITY_VIOLATION_COUNT": 0,
                "PG_CONNECTIVITY_VIOLATION_COUNT": 0,
                "ACTUAL_DIE_BBOX_UM": "0 0 400 400",
                "TARGET_UTILIZATION": "0.6", "MAX_LOCAL_DENSITY": "0.7",
            }
            implementation_path = reports / "digital_assembly_innovus_status.rpt"
            write_kv(implementation_path, implementation)
            write_kv(
                phase_contract / "assembly_phase_contract_status.rpt",
                {
                    "STATUS": "PASS", "PHASE": phase, "SOURCE_TOP": top,
                    "LAYOUT_TOP": top, "IMPLEMENTATION": "CUMULATIVE_SOFT_LOGIC",
                    "HARD_MACRO_COUNT": 0, "CHILD_GDS_MERGE_COUNT": 0,
                    "SPADMIC2_DIE_BBOX_UM": "0 0 400 400",
                    "GROUPS": "tx_packet,tx_ddr_strip",
                },
            )
            (phase_contract / "matrix_proxy_pin_plan.tsv").write_text(
                "port\tmatrix_terminal\n", encoding="utf-8"
            )
            write_kv(
                genus / "reports/timing/digital_assembly_genus_tc_gate.rpt",
                {
                    "STATUS": "PASS", "PHASE": phase, "TOP_MODULE": top,
                    "BOUNDARY_STATUS": "PASS", "SETUP_STATUS": "PASS",
                    "HOLD_STATUS": "PASS", "TYPICAL_CLOSED": "YES",
                    "INNOVUS_HANDOFF_READY": "YES",
                },
            )
            gds_audit = reports / "gds_export_audit.rpt"
            write_kv(
                gds_audit,
                {
                    "STATUS": "PASS", "GDS_FILE_STATUS": "PASS",
                    "GDS_LAYER_MAP_STATUS": "PASS", "GDS_MERGE_STATUS": "PASS",
                    "ERROR_COUNT": 0,
                },
            )
            (outputs / f"{top}.def").write_text(f"DESIGN {top} ;\n", encoding="utf-8")
            (outputs / f"{top}.lef").write_text(f"MACRO {top}\nEND {top}\n", encoding="utf-8")
            (outputs / f"{top}.gds").write_bytes(b"synthetic-gds")
            (outputs / f"{top}.v").write_text(f"module {top}; endmodule\n", encoding="utf-8")
            (outputs / f"{top}.pg.v").write_text(f"module {top}; endmodule\n", encoding="utf-8")
            (reports / "report_timing_post_route_setup.rpt").write_text("slack 0.125\n", encoding="utf-8")
            (reports / "report_timing_post_route_hold.rpt").write_text("slack 0.075\n", encoding="utf-8")
            for name, text in (
                ("report_constraint_post_route.rpt", "All constraints met\n"),
                ("floorplan_geometry.rpt", "STATUS=PASS\n"),
                ("soft_group_guide_application.rpt", "STATUS=PASS\n"),
                ("fixed_obstacle_application.rpt", "STATUS=PASS\n"),
            ):
                (reports / name).write_text(text, encoding="utf-8")

            status = root / "innovus_gate.rpt"
            args = (
                "--phase", phase, "--run-root", str(run), "--genus-root", str(genus),
                "--phase-contract-root", str(phase_contract), "--gds-audit", str(gds_audit),
                "--status", str(status),
            )
            accepted = self.run_script(INNOVUS_VALIDATOR, *args)
            self.assertEqual(accepted.returncode, 0, accepted.stdout)
            self.assertIn("RESULT=INNOVUS_HANDOFF_READY", status.read_text())

            implementation["PG_CONNECTIVITY_VIOLATION_COUNT"] = 1
            write_kv(implementation_path, implementation)
            rejected = self.run_script(INNOVUS_VALIDATOR, *args)
            self.assertEqual(rejected.returncode, 8, rejected.stdout)
            self.assertIn("STATUS=FAIL", status.read_text())
            self.assertIn("pg_connectivity_violation_count=1 expected=0", status.read_text())

    def test_oa_insertion_is_allowlisted_and_stops_before_full_top_signoff(self) -> None:
        insertion = (REPO / "TOP/pnr/scripts/insert_digital_assembly_p03_into_spadmic2.il").read_text()
        preparation = (REPO / "TOP/ci/server_prepare_digital_assembly_p03_oa_insertion.sh").read_text()
        execution = (REPO / "TOP/ci/server_insert_digital_assembly_p03_into_spadmic2.sh").read_text()
        for phase_top in (
            "spadmic_digital_assembly_v1_p00_tx",
            "spadmic_digital_assembly_v1_p01_position",
            "spadmic_digital_assembly_v1_p02_event_control",
            "spadmic_digital_assembly_v1_p03_matrix_interface",
        ):
            self.assertIn(f'"{phase_top}"', insertion)
        self.assertEqual(insertion.count("dbDeleteObject(inst)"), 1)
        self.assertIn("spadmicAssemblyCellAllowed(inst~>master~>cellName)", insertion)
        self.assertIn("SPADMIC_OA_INSERT_MULTIPLE_EXISTING_ASSEMBLIES", insertion)
        self.assertIn('dbCreateInst(cv master instanceName list(0.0 0.0) "R0")', insertion)
        self.assertIn("NONALLOWLIST_INSTANCE_REMOVAL_COUNT=0", insertion)
        self.assertIn("FULL_TOP_PVS_LVS_STATUS=NOT_RUN", insertion)
        self.assertIn("BACKUP_MANIFEST_RC", preparation)
        self.assertIn("OA_MUTATION_EXECUTED=NO", preparation)
        self.assertIn("EXACT_P03_BACKUP_REVIEWED", execution)
        self.assertIn("OA_MUTATION_ATTEMPTED=NO", execution)
        self.assertIn('if [ "$OA_MUTATION_ATTEMPTED" = "YES" ]; then', execution)
        self.assertIn("CANDIDATE_NOT_SIGNOFF", execution)

    def make_p03_package(self, root: Path) -> tuple[Path, Path, Path, Path]:
        return self.make_phase_package(root, "p03_matrix_interface", self.top)

    def make_phase_package(
        self, root: Path, phase: str, top: str
    ) -> tuple[Path, Path, Path, Path]:
        package = root / "package"
        gds = package / f"gds/{top}.gds"
        source = package / f"netlist/{top}.lvs.pg.v"
        cdl = package / "pdk/xh018_D_CELLS_JIHD.cdl"
        gate = package / "reports/digital_assembly_innovus_gate.rpt"
        for path, content in (
            (gds, b"p03-gds"), (source, b"module p03; endmodule\n"),
            (cdl, b".SUBCKT cell VDD VSS\n.ENDS\n"),
        ):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
        write_kv(gate, {"ACTUAL_DIE_BBOX_UM": "0 0 400 400"})
        package_json = package / "manifests/package.json"
        package_json.parent.mkdir(parents=True)
        package_json.write_text(
            json.dumps(
                {
                    "kind": "assembly", "name": top,
                    "layout_top": top, "source_top": top,
                    "qualification_profile": "digital_assembly_tc",
                    "lvs_source_sha256": sha256(source),
                    "stdcell_cdl_sha256": sha256(cdl),
                    "digital_assembly_tc_gate": {"phase": phase},
                },
                indent=2,
            ) + "\n",
            encoding="utf-8",
        )
        write_manifest(package, package / "manifests/SHA256SUMS", [gds, source, cdl, gate, package_json])
        return package, gds, source, cdl

    def make_drc_run(
        self, package: Path, gds: Path, name: str, variant: str,
        status: str, primary: int, expanded: int, top: str | None = None,
    ) -> Path:
        top = top or self.top
        run = package / "pvs/drc" / name
        run.mkdir(parents=True)
        write_kv(
            run / "pvs_drc_status.rpt",
            {
                "MODE": "DRC", "PVS_RC": 0, "PVS_DRC_STATUS": status,
                "PVS_DRC_VARIANT": variant, "PACKAGE": package.resolve(),
                "GDS": gds.resolve(), "GDS_SHA256": sha256(gds),
                "DRC_TOTAL_PRIMARY": primary, "DRC_TOTAL_EXPANDED": expanded,
            },
        )
        write_kv(
            run / "replay_contract_status.rpt",
            {
                "STATUS": "PASS", "LAYOUT_TOP": top, "GDS": gds.resolve(),
                "OUTPUT_ISOLATION_STATUS": "PASS",
            },
        )
        write_kv(
            run / "output_isolation.rpt",
            {"STATUS": "PASS", "RUN_DIR": run.resolve(), "LAYOUT_GDS_INPUT": gds.resolve()},
        )
        write_kv(
            run / "preprocessor_defines.rpt",
            {"DEFINE" if variant == "DENSITY" else "UNDEFINE": "DENSITY|OCCURRENCES=1"},
        )
        files = [path for path in run.iterdir() if path.name != "SHA256SUMS"]
        write_manifest(run, run / "SHA256SUMS", files)
        return run

    def validate_pvs(
        self, package: Path, run: Path, mode: str, status: Path,
        prior: Path | None = None, analysis: Path | None = None,
        actual_head: str = "head123", phase: str = "p03_matrix_interface",
    ) -> subprocess.CompletedProcess[str]:
        args = [
            "--phase", phase, "--mode", mode,
            "--package", str(package), "--run-dir", str(run), "--status", str(status),
            "--expected-head", "head123", "--actual-head", actual_head,
        ]
        if prior is not None:
            args.extend(("--prior-status", str(prior)))
        if analysis is not None:
            args.extend(("--analysis-root", str(analysis)))
        return self.run_script(PVS_VALIDATOR, *args)

    def test_p00_lvs_records_density_as_not_run_by_policy(self) -> None:
        phase = "p00_tx"
        top = "spadmic_digital_assembly_v1_p00_tx"
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            package, gds, source, cdl = self.make_phase_package(root, phase, top)
            base_run = self.make_drc_run(
                package, gds, "base", "BASE", "PASS", 0, 0, top=top
            )
            base_status = root / "base_gate.rpt"
            base = self.validate_pvs(
                package, base_run, "base", base_status, phase=phase
            )
            self.assertEqual(base.returncode, 0, base.stdout)

            lvs_run = package / "pvs/lvs/lvs"
            lvs_run.mkdir(parents=True)
            write_kv(
                lvs_run / "pvs_lvs_status.rpt",
                {
                    "MODE": "LVS", "PVS_RC": 0, "PVS_LVS_STATUS": "MATCH",
                    "PACKAGE": package.resolve(), "LAYOUT_TOP": top,
                    "SOURCE_TOP": top, "GDS": gds.resolve(),
                    "GDS_SHA256": sha256(gds), "LVS_SOURCE": source.resolve(),
                    "LVS_SOURCE_SHA256": sha256(source), "STDCELL_CDL": cdl.resolve(),
                    "STDCELL_CDL_SHA256": sha256(cdl),
                    "LVS_NEGATIVE_MATCH_COUNT": 0, "LVS_POSITIVE_MATCH_COUNT": 3,
                },
            )
            write_kv(
                lvs_run / "replay_contract_status.rpt",
                {
                    "STATUS": "PASS", "LAYOUT_TOP": top, "SOURCE_TOP": top,
                    "GDS": gds.resolve(), "SOURCE": source.resolve(),
                    "CDL": cdl.resolve(), "OUTPUT_ISOLATION_STATUS": "PASS",
                },
            )
            write_kv(
                lvs_run / "output_isolation.rpt",
                {
                    "STATUS": "PASS", "RUN_DIR": lvs_run.resolve(),
                    "LAYOUT_GDS_INPUT": gds.resolve(),
                    "SCHEMATIC_VERILOG_INPUT": source.resolve(),
                    "SCHEMATIC_CDL_INPUT": cdl.resolve(),
                },
            )
            write_manifest(
                lvs_run, lvs_run / "SHA256SUMS",
                [path for path in lvs_run.iterdir() if path.name != "SHA256SUMS"],
            )
            lvs_status = root / "lvs_gate.rpt"
            lvs = self.validate_pvs(
                package, lvs_run, "lvs", lvs_status, base_status, phase=phase
            )
            self.assertEqual(lvs.returncode, 0, lvs.stdout)
            text = lvs_status.read_text()
            self.assertIn("PVS_DENSITY_DRC_STATUS=NOT_RUN_BY_POLICY", text)
            self.assertIn("ASSEMBLY_PHASE_ACCEPTED=YES", text)
            self.assertIn("OA_INSERTION_AUTHORIZED=NO", text)

    def test_p03_pvs_sequence_and_oa_candidate_gate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            package, gds, source, cdl = self.make_p03_package(root)
            base_run = self.make_drc_run(package, gds, "base", "BASE", "PASS", 0, 0)
            base_status = root / "base_gate.rpt"
            base = self.validate_pvs(package, base_run, "base", base_status)
            self.assertEqual(base.returncode, 0, base.stdout)
            self.assertIn("PVS_BASE_DRC_STATUS=PASS", base_status.read_text())

            density_run = self.make_drc_run(package, gds, "density", "DENSITY", "PASS", 0, 0)
            density_status = root / "density_gate.rpt"
            density = self.validate_pvs(package, density_run, "density", density_status, base_status)
            self.assertEqual(density.returncode, 0, density.stdout)
            self.assertIn("PVS_DENSITY_DRC_STATUS=PASS", density_status.read_text())

            lvs_run = package / "pvs/lvs/lvs"
            lvs_run.mkdir(parents=True)
            write_kv(
                lvs_run / "pvs_lvs_status.rpt",
                {
                    "MODE": "LVS", "PVS_RC": 0, "PVS_LVS_STATUS": "MATCH",
                    "PACKAGE": package.resolve(), "LAYOUT_TOP": self.top,
                    "SOURCE_TOP": self.top, "GDS": gds.resolve(),
                    "GDS_SHA256": sha256(gds), "LVS_SOURCE": source.resolve(),
                    "LVS_SOURCE_SHA256": sha256(source), "STDCELL_CDL": cdl.resolve(),
                    "STDCELL_CDL_SHA256": sha256(cdl),
                    "LVS_NEGATIVE_MATCH_COUNT": 0, "LVS_POSITIVE_MATCH_COUNT": 3,
                },
            )
            write_kv(
                lvs_run / "replay_contract_status.rpt",
                {
                    "STATUS": "PASS", "LAYOUT_TOP": self.top, "SOURCE_TOP": self.top,
                    "GDS": gds.resolve(), "SOURCE": source.resolve(), "CDL": cdl.resolve(),
                    "OUTPUT_ISOLATION_STATUS": "PASS",
                },
            )
            write_kv(
                lvs_run / "output_isolation.rpt",
                {
                    "STATUS": "PASS", "RUN_DIR": lvs_run.resolve(),
                    "LAYOUT_GDS_INPUT": gds.resolve(),
                    "SCHEMATIC_VERILOG_INPUT": source.resolve(),
                    "SCHEMATIC_CDL_INPUT": cdl.resolve(),
                },
            )
            write_manifest(
                lvs_run, lvs_run / "SHA256SUMS",
                [path for path in lvs_run.iterdir() if path.name != "SHA256SUMS"],
            )
            lvs_status = root / "lvs_gate.rpt"
            lvs = self.validate_pvs(package, lvs_run, "lvs", lvs_status, density_status)
            self.assertEqual(lvs.returncode, 0, lvs.stdout)
            lvs_text = lvs_status.read_text()
            self.assertIn("PVS_LVS_STATUS=MATCH", lvs_text)
            self.assertIn("OA_INSERTION_AUTHORIZED=YES", lvs_text)

            audit_status = root / "assembly_audit_status.rpt"
            write_kv(
                audit_status,
                {
                    "STATUS": "PASS", "SOURCE_IDENTITY_GATE_STATUS": "PASS",
                    "EXACT_MATRICE5_INSTANCE_GATE_STATUS": "PASS",
                    "MATRIX_TERMINAL_PARITY_STATUS": "PASS",
                    "UNKNOWN_FAMILY_GATE_STATUS": "PASS",
                    "MATRIX_PROXY_PIN_ACCESS_STATUS": "PASS",
                    "PG_ANCHOR_GATE_STATUS": "PASS",
                    "P03_IMPLEMENTATION_AUTHORIZED": "YES",
                },
            )
            candidate = root / "candidate_oa.rpt"
            target = root / "target_oa.rpt"
            candidate.write_text("BBOX=0 0 400 400\nPIN=VDD|signal\nPIN=data<0>|signal\n", encoding="utf-8")
            target.write_text("BBOX=0 0 400 400\n", encoding="utf-8")
            lef = root / "p03.lef"
            lef.write_text(
                f"MACRO {self.top}\n  SIZE 400 BY 400 ;\n  PIN VDD\n  END VDD\n"
                "  PIN data[0]\n  END data[0]\nEND " + self.top + "\n",
                encoding="utf-8",
            )
            oa_status = root / "oa_gate.rpt"
            oa = self.run_script(
                OA_VALIDATOR,
                "--pvs-status", str(lvs_status), "--source-audit-status", str(audit_status),
                "--candidate-oa-report", str(candidate), "--target-oa-report", str(target),
                "--lef", str(lef), "--status", str(oa_status),
            )
            self.assertEqual(oa.returncode, 0, oa.stdout)
            self.assertIn("OA_EQUIVALENCE_SCOPE=BBOX_AND_BOUNDARY_PIN_CONTRACT_ONLY", oa_status.read_text())
            self.assertIn("FULL_TOP_LVS_REQUIRED=YES", oa_status.read_text())

            candidate.write_text(
                "BBOX=0 0 400 400\nPIN=VDD|signal\nPIN=data<0>|signal\nPIN=extra|signal\n",
                encoding="utf-8",
            )
            rejected = self.run_script(
                OA_VALIDATOR,
                "--pvs-status", str(lvs_status), "--source-audit-status", str(audit_status),
                "--candidate-oa-report", str(candidate), "--target-oa-report", str(target),
                "--lef", str(lef), "--status", str(oa_status),
            )
            self.assertEqual(rejected.returncode, 8, rejected.stdout)
            self.assertIn("candidate_lef_pin_parity_failed", oa_status.read_text())

    def test_p03_whole_extent_density_debt_is_classified_without_oa_promotion(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            package, gds, _, _ = self.make_p03_package(root)
            base_run = self.make_drc_run(package, gds, "base", "BASE", "PASS", 0, 0)
            base_status = root / "base_gate.rpt"
            self.assertEqual(self.validate_pvs(package, base_run, "base", base_status).returncode, 0)
            density_run = self.make_drc_run(package, gds, "density_debt", "DENSITY", "FAIL", 4, 4)
            analysis = root / "analysis"
            write_kv(
                analysis / "pvs_drc_analysis_status.rpt",
                {
                    "STATUS": "PASS", "RESULT": "PVS_DRC_RULE_DEBT_CLASSIFIED",
                    "PVS_DRC_VARIANT": "DENSITY", "LAYOUT_TOP": self.top,
                    "DENSITY_STATE": "DEFINED",
                },
            )
            (analysis / "pvs_drc_rule_inventory.tsv").write_text(
                "rule\tcategory\taggregate_bbox_um\n"
                + "".join(f"{rule}\tDENSITY\t0 0 400 400\n" for rule in ("R1M1", "R1M2", "R1M3", "R1MT")),
                encoding="utf-8",
            )
            density_status = root / "density_debt_gate.rpt"
            result = self.validate_pvs(
                package, density_run, "density", density_status, base_status, analysis
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            text = density_status.read_text()
            self.assertIn("PVS_DENSITY_DRC_STATUS=CLASSIFIED_RULE_DEBT", text)
            self.assertIn("DENSITY_DISPOSITION_STATUS=ASSEMBLED_FILL_OR_FORMAL_WAIVER_REQUIRED", text)
            self.assertIn("OA_INSERTION_AUTHORIZED=NO", text)

            wrong_head = self.validate_pvs(
                package, density_run, "density", root / "wrong_head.rpt",
                base_status, analysis, actual_head="different",
            )
            self.assertEqual(wrong_head.returncode, 8, wrong_head.stdout)


if __name__ == "__main__":
    unittest.main()
