#!/usr/bin/env python3

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
COLLECTOR = REPO / "TOP" / "pnr" / "scripts" / "collect_pvs_lvs_readonly.py"


class CollectPvsLvsReadonlyTest(unittest.TestCase):
    def test_collects_text_evidence_without_modifying_source(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "historical_lvs"
            source.mkdir()
            external = root / "external"
            external.mkdir()

            layout = external / "corrected.gds"
            layout.write_bytes(b"GDS\x00DATA")
            netlist = external / "packet_source.v"
            netlist.write_text(
                "module spadmic_tx_packet_core(foo[1][2], foo[][], VDD, VSS);\n"
                "  input foo[1][2];\n"
                "  inout VDD, VSS;\n"
                "endmodule\n"
            )
            stdcell_cdl = external / "xh018_D_CELLS_JIHD.cdl"
            stdcell_cdl.write_text(".SUBCKT AND2JIHDX1 A B Q vddi gndi\n.ENDS\n")

            (source / "run.pvs").write_text(
                "#!/bin/sh\n"
                "/eda/cadence/PVS/bin/pvs -lvs "
                "-top_cell spadmic_tx_packet_core_HV "
                "-source_top_cell spadmic_tx_packet_core "
                f"-control {source / 'pvslvsctl'}\n"
            )
            (source / "pvslvsctl").write_text(
                f'layout_path "{layout}";\n'
                'layout_primary "spadmic_tx_packet_core_HV";\n'
                f'source_path "{netlist}";\n'
                'source_primary "spadmic_tx_packet_core";\n'
                f'include "{stdcell_cdl}";\n'
                "virtual_connect -noname;\n"
            )
            (source / ".config.rul").write_text("# LVS config\n")
            (source / ".technology.rul").write_text("technology XH018_1131;\n")
            (source / "packet.lvs.sum").write_text(
                "LVS MISMATCH\n"
                "Unmatched layout port foo<1><2>\n"
                "Unmatched source port foo[1][2]\n"
            )
            (source / "pvslvs.log").write_text(
                "Comparing layout and source\nERROR: ports do not match\n"
            )
            (source / "result.pvstdb").write_bytes(b"\x00\x01binary database")
            (source / "layout.gds").write_bytes(b"\x00historical gds")
            (source / "source_link").symlink_to(netlist)

            before = {
                str(path.relative_to(source)): (
                    path.lstat().st_size,
                    path.lstat().st_mtime_ns,
                    os.readlink(path) if path.is_symlink() else "",
                )
                for path in source.iterdir()
            }
            bundle = root / "bundle"
            result = subprocess.run(
                [
                    str(COLLECTOR),
                    "--source-run",
                    str(source),
                    "--bundle-root",
                    str(bundle),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)

            after = {
                str(path.relative_to(source)): (
                    path.lstat().st_size,
                    path.lstat().st_mtime_ns,
                    os.readlink(path) if path.is_symlink() else "",
                )
                for path in source.iterdir()
            }
            self.assertEqual(before, after)

            status = (bundle / "collection_status.rpt").read_text()
            self.assertIn("POLICY=READ_ONLY_NO_PVS_NO_SOURCE_WRITES", status)
            self.assertIn("SOURCE_STABILITY_STATUS=PASS", status)
            self.assertIn("RUN_PVS_COUNT=1", status)
            self.assertIn("PVSLVSCTL_COUNT=1", status)
            self.assertGreaterEqual(
                int(
                    next(
                        line.split("=", 1)[1]
                        for line in status.splitlines()
                        if line.startswith("PVS_TOOL_VERSION_LINE_COUNT=")
                    )
                ),
                1,
            )
            self.assertIn("STATUS=PASS", status)

            self.assertTrue((bundle / "controls" / "run.pvs").is_file())
            self.assertTrue((bundle / "controls" / "pvslvsctl").is_file())
            self.assertTrue((bundle / "reports" / "packet.lvs.sum").is_file())
            self.assertTrue((bundle / "logs" / "pvslvs.log").is_file())
            self.assertTrue((bundle / "netlist" / "external" / netlist.name).is_file())
            self.assertFalse((bundle / "netlist" / "external" / stdcell_cdl.name).exists())
            self.assertFalse(any(path.suffix == ".gds" for path in bundle.rglob("*.gds")))
            self.assertFalse(any("pvstdb" in path.name for path in bundle.rglob("*")))

            pin_audit = (bundle / "pin_name_audit.rpt").read_text()
            self.assertIn("DOUBLE_BRACKET", pin_audit)
            self.assertIn("EMPTY_DOUBLE_BRACKET", pin_audit)
            lvs_extract = (bundle / "lvs_status_extract.rpt").read_text()
            self.assertIn("LVS MISMATCH", lvs_extract)
            self.assertIn("Unmatched source port", lvs_extract)

            external_manifest = (bundle / "external_reference_manifest.tsv").read_text()
            self.assertIn(str(layout), external_manifest)
            self.assertIn(str(netlist), external_manifest)
            self.assertIn(str(stdcell_cdl), external_manifest)

            git_root = bundle / "git_text_candidate"
            self.assertTrue((git_root / "controls" / "run.pvs").is_file())
            self.assertTrue((git_root / "reports" / "packet.lvs.sum").is_file())
            self.assertIn("controls/run.pvs", (git_root / "MANIFEST.sha256").read_text())
            self.assertFalse(any(path.suffix in {".v", ".gds", ".cdl"} for path in git_root.rglob("*")))

            second = subprocess.run(
                [
                    str(COLLECTOR),
                    "--source-run",
                    str(source),
                    "--bundle-root",
                    str(bundle),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertNotEqual(second.returncode, 0)
            self.assertIn("IMMUTABLE_BUNDLE_EXISTS", second.stdout)


if __name__ == "__main__":
    unittest.main()
