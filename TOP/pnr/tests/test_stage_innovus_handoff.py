#!/usr/bin/env python3

from __future__ import annotations

import json
import hashlib
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
STAGE = REPO / "TOP" / "pnr" / "scripts" / "stage_innovus_handoff.py"
AUDIT = REPO / "TOP" / "pnr" / "scripts" / "audit_innovus_handoff.py"


class StageInnovusHandoffTest(unittest.TestCase):
    def test_stage_and_audit_exact_cumulative_assembly_package(self) -> None:
        top = "spadmic_digital_assembly_v1_p03_matrix_interface"
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source_root = root / "innovus"
            source_root.mkdir()
            gds = source_root / f"{top}.gds"
            gds.write_bytes(b"exact-p03-gds")
            netlist = source_root / f"{top}.pg.v"
            netlist.write_text(
                f"module {top} (VDD, VSS, a, y);\n"
                "  inout VDD, VSS; input a; output y;\n"
                "endmodule\n",
                encoding="utf-8",
            )
            lef = source_root / f"{top}.lef"
            lef.write_text(
                f"MACRO {top}\n"
                "  PIN VDD\n  END VDD\n"
                "  PIN VSS\n  END VSS\n"
                "  PIN a\n  END a\n"
                "  PIN y\n  END y\n"
                f"END {top}\n",
                encoding="utf-8",
            )
            def_file = source_root / f"{top}.def"
            def_file.write_text(f"DESIGN {top} ;\n", encoding="utf-8")
            cdl = root / "xh018_D_CELLS_JIHD.cdl"
            cdl.write_text(".SUBCKT FILL1JIHDX0 vddi gndi\n.ENDS\n", encoding="utf-8")
            gate = source_root / "digital_assembly_innovus_gate.rpt"
            gate_values = {
                "STATUS": "PASS", "RESULT": "INNOVUS_HANDOFF_READY",
                "PHASE": "p03_matrix_interface", "TOP_MODULE": top,
                "SOURCE_TOP": top, "LAYOUT_TOP": top,
                "IMPLEMENTATION": "CUMULATIVE_SOFT_LOGIC",
                "HARD_MACRO_COUNT": "0", "CHILD_GDS_MERGE_COUNT": "0",
                "FLOORPLAN_GEOMETRY_STATUS": "PASS", "TC_SETUP_STATUS": "PASS",
                "TC_HOLD_STATUS": "PASS", "POSTROUTE_DESIGN_RULE_STATUS": "PASS",
                "INNOVUS_DRC_STATUS": "PASS", "REGULAR_CONNECTIVITY_STATUS": "PASS",
                "PG_CONNECTIVITY_STATUS": "PASS", "GDS_EXPORT_AUDIT_STATUS": "PASS",
                "GDS_SHA256": hashlib.sha256(gds.read_bytes()).hexdigest(),
                "PVS_BASE_DRC_STATUS": "NOT_RUN", "PVS_DENSITY_DRC_STATUS": "NOT_RUN",
                "PVS_LVS_STATUS": "NOT_RUN", "SIGNOFF_READY": "NO",
            }
            gate.write_text(
                "".join(f"{key}={value}\n" for key, value in gate_values.items()),
                encoding="utf-8",
            )
            gds_audit = source_root / "gds_export_audit.rpt"
            gds_audit.write_text(
                "STATUS=PASS\nGDS_FILE_STATUS=PASS\nGDS_LAYER_MAP_STATUS=PASS\n"
                "GDS_MERGE_STATUS=PASS\nERROR_COUNT=0\n",
                encoding="utf-8",
            )
            handoff = root / "handoff"
            result = subprocess.run(
                [
                    "python3", str(STAGE), "--kind", "assembly", "--name", top,
                    "--version", "p03_unit", "--source-root", str(source_root),
                    "--gds", str(gds), "--layout-top", top,
                    "--netlist", str(netlist), "--source-top", top,
                    "--lef", str(lef), "--def-file", str(def_file),
                    "--handoff-root", str(handoff), "--repo-root", str(REPO),
                    "--stdcell-cdl", str(cdl), "--report", str(gate),
                    "--report", str(gds_audit),
                    "--qualification-profile", "digital_assembly_tc",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            package = handoff / "assemblies" / top / "p03_unit"
            manifest = json.loads((package / "manifests/package.json").read_text())
            self.assertEqual(manifest["kind"], "assembly")
            self.assertEqual(manifest["name"], top)
            self.assertEqual(manifest["digital_assembly_tc_gate"]["phase"], "p03_matrix_interface")
            self.assertEqual(manifest["digital_assembly_tc_gate"]["hard_macro_count"], 0)

            audit = subprocess.run(
                ["python3", str(AUDIT), str(package)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(audit.returncode, 0, audit.stdout + audit.stderr)
            self.assertIn("DIGITAL_ASSEMBLY_TC_GATE_STATUS=PASS", audit.stdout)
            self.assertIn("QUALIFICATION_PROFILE=digital_assembly_tc", audit.stdout)

    def test_stage_preserves_raw_source_and_builds_cdl_filtered_source(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source_root = root / "innovus"
            source_root.mkdir()
            gds = source_root / "packet.gds"
            gds.write_bytes(b"canonical-gds")
            netlist = source_root / "packet.routed.pg.v"
            netlist.write_text(
                "module spadmic_tx_packet_core (VDD, VSS, a, y);\n"
                "  inout VDD, VSS; input a; output y;\n"
                "  AND2JIHDX1 u0 (.A(a), .B(VDD), .Y(y), .vddi(VDD), .gndi(VSS));\n"
                "endmodule\n"
                "module AND2JIHDX1 (A, B, Y, vddi, gndi);\n"
                "  input A, B, vddi, gndi; output Y;\n"
                "endmodule\n"
            )
            lef = source_root / "packet.abstract.lef"
            lef.write_text(
                "MACRO spadmic_tx_packet_core\n"
                "  PIN VDD\n  END VDD\n"
                "  PIN VSS\n  END VSS\n"
                "  PIN a\n  END a\n"
                "  PIN y\n  END y\n"
                "END spadmic_tx_packet_core\n"
            )
            cdl = root / "xh018_D_CELLS_JIHD.cdl"
            cdl.write_text(".SUBCKT AND2JIHDX1 A B Y vddi gndi\n.ENDS\n")
            tx_gate = source_root / "canonical_tx_ooc_gate.rpt"
            tx_gate.write_text(
                "STATUS=PASS\n"
                "RESULT=READY_FOR_PVS_CANDIDATE\n"
                "BLOCK=tx_packet_core\n"
                "MACRO=spadmic_tx_packet_core\n"
                "FINAL_HANDOFF_READY=NO\n"
            )
            handoff = root / "handoff"
            command = [
                "python3", str(STAGE),
                "--kind", "block",
                "--name", "spadmic_tx_packet_core",
                "--version", "unit_v1",
                "--source-root", str(source_root),
                "--gds", str(gds),
                "--layout-top", "spadmic_tx_packet_core",
                "--netlist", str(netlist),
                "--source-top", "spadmic_tx_packet_core",
                "--lef", str(lef),
                "--handoff-root", str(handoff),
                "--repo-root", str(REPO),
                "--stdcell-cdl", str(cdl),
                "--report", str(tx_gate),
                "--qualification-profile", "canonical_tx",
            ]
            result = subprocess.run(command, text=True, capture_output=True, check=False)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            package = handoff / "blocks" / "spadmic_tx_packet_core" / "unit_v1"
            raw = package / "netlist" / "spadmic_tx_packet_core.innovus.pg.v"
            canonical = package / "netlist" / "spadmic_tx_packet_core.lvs.pg.v"
            self.assertIn("module AND2JIHDX1", raw.read_text())
            self.assertNotIn("module AND2JIHDX1", canonical.read_text())
            self.assertTrue((package / "pdk" / "xh018_D_CELLS_JIHD.cdl").is_file())
            self.assertIn("STATUS=PASS", (package / "reports" / "lvs_source_preparation.rpt").read_text())
            manifest = json.loads((package / "manifests" / "package.json").read_text())
            self.assertEqual(manifest["source_top"], "spadmic_tx_packet_core")
            self.assertEqual(manifest["qualification_profile"], "canonical_tx")
            self.assertEqual(
                manifest["lvs_source_sha256"],
                hashlib.sha256(canonical.read_bytes()).hexdigest(),
            )
            self.assertEqual(
                manifest["stdcell_cdl_sha256"],
                hashlib.sha256((package / "pdk" / "xh018_D_CELLS_JIHD.cdl").read_bytes()).hexdigest(),
            )

            audit = subprocess.run(
                ["python3", str(AUDIT), str(package)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(audit.returncode, 0, audit.stdout + audit.stderr)
            self.assertIn("PIN_PARITY_STATUS=PASS", audit.stdout)

    def test_stage_preserves_exact_provisional_waiver_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source_root = root / "innovus"
            source_root.mkdir()
            gds = source_root / "spadmic_tx_packet_core.gds"
            gds.write_bytes(b"provisional-waiver-gds")
            netlist = source_root / "spadmic_tx_packet_core.routed.pg.v"
            netlist.write_text(
                "module spadmic_tx_packet_core (VDD, VSS, a, y);\n"
                "  inout VDD, VSS; input a; output y;\n"
                "  AND2JIHDX1 u0 (.A(a), .B(VDD), .Y(y), .vddi(VDD), .gndi(VSS));\n"
                "endmodule\n"
            )
            lef = source_root / "spadmic_tx_packet_core.abstract.lef"
            lef.write_text(
                "MACRO spadmic_tx_packet_core\n"
                "  PIN VDD\n  END VDD\n"
                "  PIN VSS\n  END VSS\n"
                "  PIN a\n  END a\n"
                "  PIN y\n  END y\n"
                "END spadmic_tx_packet_core\n"
            )
            cdl = root / "xh018_D_CELLS_JIHD.cdl"
            cdl.write_text(".SUBCKT AND2JIHDX1 A B Y vddi gndi\n.ENDS\n")
            waiver_gate = source_root / "canonical_tx_lvs_waiver_gate.rpt"
            waiver_gate.write_text(
                "STATUS=PASS\n"
                "RESULT=READY_FOR_PROVISIONAL_PVS_DRC_LVS\n"
                "MACRO=spadmic_tx_packet_core\n"
                "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY\n"
                "WAIVER_MARKER_COUNT=4\n"
                "WAIVER_NETS=n_9677 n_9693 n_9696 n_9697\n"
                "PVS_DRC_WAIVER=NO\n"
                "LVS_DIAGNOSTIC_ONLY=YES\n"
                "MANUAL_FIX_REQUIRED=YES\n"
                "BLOCK_PROMOTION_AUTHORIZED=NO\n"
                "FINAL_SIGNOFF_READY=NO\n"
            )
            waiver = source_root / "temporary_drc_waiver.rpt"
            waiver.write_text(
                "STATUS=PASS\n"
                "RESULT=EXACT_FOUR_MARKERS_RECORDED\n"
                "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY\n"
                "WAIVER_MARKER_COUNT=4\n"
                "WAIVER_NETS=n_9677 n_9693 n_9696 n_9697\n"
                "ALLOWED_LAYER=MET1\n"
                "ALLOWED_TYPE=Geometry\n"
                "ALLOWED_SUBTYPE=Minimal_Area\n"
                "PVS_DRC_WAIVER=NO\n"
                "LVS_DIAGNOSTIC_ONLY=YES\n"
                "MANUAL_FIX_REQUIRED=YES\n"
                "BLOCK_PROMOTION_AUTHORIZED=NO\n"
                "FINAL_SIGNOFF_READY=NO\n"
            )
            gds_audit = source_root / "gds_export_audit.rpt"
            gds_audit.write_text("STATUS=PASS\n")
            handoff = root / "handoff"
            command = [
                "python3", str(STAGE),
                "--kind", "block",
                "--name", "spadmic_tx_packet_core",
                "--version", "waiver_v1",
                "--source-root", str(source_root),
                "--gds", str(gds),
                "--layout-top", "spadmic_tx_packet_core",
                "--netlist", str(netlist),
                "--source-top", "spadmic_tx_packet_core",
                "--lef", str(lef),
                "--handoff-root", str(handoff),
                "--repo-root", str(REPO),
                "--stdcell-cdl", str(cdl),
                "--report", str(waiver_gate),
                "--report", str(waiver),
                "--report", str(gds_audit),
                "--qualification-profile", "canonical_tx_lvs_waiver",
            ]
            result = subprocess.run(command, text=True, capture_output=True, check=False)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            package = handoff / "blocks" / "spadmic_tx_packet_core" / "waiver_v1"
            manifest = json.loads((package / "manifests" / "package.json").read_text())
            waiver_manifest = manifest["temporary_drc_waiver"]
            self.assertEqual(manifest["qualification_profile"], "canonical_tx_lvs_waiver")
            self.assertEqual(waiver_manifest["marker_count"], 4)
            self.assertFalse(waiver_manifest["pvs_drc_waiver"])
            self.assertTrue(waiver_manifest["lvs_diagnostic_only"])
            self.assertFalse(waiver_manifest["final_signoff_ready"])
            qualification = (package / "status" / "qualification.rpt").read_text()
            self.assertIn("TEMPORARY_DRC_WAIVER_STATUS=PASS", qualification)
            self.assertIn("PVS_DRC_WAIVER=NO", qualification)
            self.assertIn("GDS_LAYER_MAP_STATUS=PASS", qualification)
            self.assertIn("GDS_MERGE_STATUS=PASS", qualification)
            self.assertIn("PVS_BASE_DRC_STATUS=NOT_RUN", qualification)
            self.assertIn("PVS_DENSITY_DRC_STATUS=NOT_RUN", qualification)
            self.assertIn("SIGNOFF_READY=NO", qualification)

            audit = subprocess.run(
                ["python3", str(AUDIT), str(package)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(audit.returncode, 0, audit.stdout + audit.stderr)
            self.assertIn("TEMPORARY_DRC_WAIVER_STATUS=PASS", audit.stdout)
            self.assertIn("PVS_DRC_WAIVER=NO", audit.stdout)

    def test_stage_rejects_attempt_to_turn_waiver_into_pvs_drc_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source_root = root / "innovus"
            source_root.mkdir()
            gds = source_root / "packet.gds"
            gds.write_bytes(b"gds")
            netlist = source_root / "packet.routed.pg.v"
            netlist.write_text("module spadmic_tx_packet_core (VDD, VSS); inout VDD, VSS; endmodule\n")
            lef = source_root / "packet.abstract.lef"
            lef.write_text(
                "MACRO spadmic_tx_packet_core\n"
                "  PIN VDD\n  END VDD\n"
                "  PIN VSS\n  END VSS\n"
                "END spadmic_tx_packet_core\n"
            )
            cdl = root / "xh018_D_CELLS_JIHD.cdl"
            cdl.write_text(".SUBCKT FILL1JIHDX0 vddi gndi\n.ENDS\n")
            gate = source_root / "canonical_tx_lvs_waiver_gate.rpt"
            gate.write_text(
                "STATUS=PASS\n"
                "RESULT=READY_FOR_PROVISIONAL_PVS_DRC_LVS\n"
                "MACRO=spadmic_tx_packet_core\n"
                "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY\n"
                "WAIVER_MARKER_COUNT=4\n"
                "WAIVER_NETS=n_9677 n_9693 n_9696 n_9697\n"
                "PVS_DRC_WAIVER=YES\n"
                "LVS_DIAGNOSTIC_ONLY=YES\n"
                "MANUAL_FIX_REQUIRED=YES\n"
                "BLOCK_PROMOTION_AUTHORIZED=NO\n"
                "FINAL_SIGNOFF_READY=NO\n"
            )
            waiver = source_root / "temporary_drc_waiver.rpt"
            waiver.write_text("STATUS=PASS\n")
            audit = source_root / "gds_export_audit.rpt"
            audit.write_text("STATUS=PASS\n")
            result = subprocess.run(
                [
                    "python3", str(STAGE),
                    "--kind", "block",
                    "--name", "spadmic_tx_packet_core",
                    "--version", "invalid",
                    "--source-root", str(source_root),
                    "--gds", str(gds),
                    "--layout-top", "spadmic_tx_packet_core",
                    "--netlist", str(netlist),
                    "--source-top", "spadmic_tx_packet_core",
                    "--lef", str(lef),
                    "--handoff-root", str(root / "handoff"),
                    "--repo-root", str(REPO),
                    "--stdcell-cdl", str(cdl),
                    "--report", str(gate),
                    "--report", str(waiver),
                    "--report", str(audit),
                    "--qualification-profile", "canonical_tx_lvs_waiver",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("PVS_DRC_WAIVER=YES expected=NO", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
