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


if __name__ == "__main__":
    unittest.main()
