#!/usr/bin/env python3
"""Focused tests for strict monolithic RO6 PVS LVS preparation and gating."""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


PVS_DIR = Path(__file__).resolve().parents[1]
PREP = PVS_DIR / "13_prepare_ro6_monolithic_lvs.py"
GATE = PVS_DIR / "14_gate_ro6_monolithic_lvs.py"


MATCH_CLS = """\
#####  Run Result                    :     MATCH
Cells matched                                |         2
Cells which mismatch                         |         0
Cells that have been blackboxed              |         0
mptdc_axis_core     |       59 :        59 |       59 :        59 | match        |
RO_tune6            |       19 :        19 |       19 :        19 | match        |
"""


class Ro6MonolithicLvsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="mptdc_ro6_monolithic.")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.template = self.root / "template"
        self.run_dir = self.root / "run"
        self.template.mkdir()
        (self.template / "run.pvs").write_text(
            "#!/bin/sh -f\npvs \\\n+  -lvs \\\n+  -hcell /stale/pvs_hcell_ro6.txt\n"
        )
        (self.template / "pvslvsctl").write_text(
            "lvs_report_file \"old.sum\";\n"
            "schematic_path \"/stale/source.v\" verilog;\n"
            "schematic_path \"/stale/cells.cdl\" cdl;\n"
            "lvs_black_box \"RO_tune6\";\n"
            "lvs_verilog_bus_map_by_position yes;\n"
            "lvs_global_sigs_are_ports yes;\n"
            "layout_format gdsii;\n"
            "layout_path \"/stale/layout.gds\";\n"
        )
        (self.template / ".config.rul").write_text("")
        (self.template / ".technology.rul").write_text("technology\n")
        self.gds = self.root / "top.gds"
        self.source = self.root / "source.v"
        self.dcell_cdl = self.root / "dcells.cdl"
        self.ro_cdl = self.root / "RO_tune6.cdl"
        self.gds.write_text("gds\n")
        self.source.write_text("module mptdc_axis_core; endmodule\n")
        self.dcell_cdl.write_text(".SUBCKT CELL A Y\n.ENDS CELL\n")
        self.ro_cdl.write_text(".SUBCKT RO_tune6 VDD VSS rstb\n.ENDS RO_tune6\n")

    def prepare(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                str(PREP),
                "--template-run", str(self.template),
                "--run-dir", str(self.run_dir),
                "--gds", str(self.gds),
                "--source", str(self.source),
                "--dcell-cdl", str(self.dcell_cdl),
                "--ro-cdl", str(self.ro_cdl),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def gate(self, pvs_rc: int = 0) -> tuple[subprocess.CompletedProcess[str], Path]:
        report = self.root / f"gate_{pvs_rc}.rpt"
        result = subprocess.run(
            [
                str(GATE),
                "--run-dir", str(self.run_dir),
                "--pvs-rc", str(pvs_rc),
                "--gds", str(self.gds),
                "--source", str(self.source),
                "--dcell-cdl", str(self.dcell_cdl),
                "--ro-cdl", str(self.ro_cdl),
                "--out", str(report),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return result, report

    def write_match_evidence(self) -> None:
        (self.run_dir / "result.cls").write_text(MATCH_CLS)
        (self.run_dir / "result.shorts").write_text("")
        (self.run_dir / "svdb").mkdir()
        (self.run_dir / "svdb" / "matched").write_text("match\n")

    def test_prepare_uses_exact_three_sources_without_hcell_or_blackbox(self) -> None:
        result = self.prepare()
        self.assertEqual(result.returncode, 0, result.stdout)
        control = (self.run_dir / "pvslvsctl").read_text()
        run = (self.run_dir / "run.pvs").read_text()
        self.assertEqual(control.count("schematic_path"), 3)
        self.assertEqual(control.count("layout_path"), 1)
        self.assertIn(f'schematic_path "{self.source.resolve()}" verilog', control)
        self.assertIn(f'schematic_path "{self.dcell_cdl.resolve()}" cdl', control)
        self.assertIn(f'schematic_path "{self.ro_cdl.resolve()}" cdl', control)
        self.assertNotIn("lvs_black_box", control)
        self.assertNotIn("lvs_verilog_bus_map_by_position", control)
        self.assertNotIn("lvs_global_sigs_are_ports", control)
        self.assertNotIn("-hcell", run)

    def test_prepare_rejects_nonempty_config_rule(self) -> None:
        (self.template / ".config.rul").write_text("lvs_black_box RO_tune6;\n")
        result = self.prepare()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires an empty template .config.rul", result.stdout)
        self.assertFalse(self.run_dir.exists())

    def test_explicit_match_passes_signoff_level_lvs_gate(self) -> None:
        self.assertEqual(self.prepare().returncode, 0)
        self.write_match_evidence()
        result, report = self.gate()
        self.assertEqual(result.returncode, 0, result.stdout)
        text = report.read_text()
        self.assertIn("MONOLITHIC_LVS_STATUS=MATCH", text)
        self.assertIn("LVS_BLACKBOXED_CELL_COUNT=0", text)
        self.assertIn("LVS_HCELL_STATUS=NOT_USED", text)
        self.assertIn("TOP_59_PIN_MATCH_STATUS=PASS", text)
        self.assertIn("RO6_19_PIN_MATCH_STATUS=PASS", text)
        self.assertIn("SHORT_OPEN_EVIDENCE_STATUS=PASS", text)
        self.assertIn("LVS_SIGNOFF_ELIGIBLE=YES", text)

    def test_rc_zero_with_mismatch_fails(self) -> None:
        self.assertEqual(self.prepare().returncode, 0)
        self.write_match_evidence()
        cls = self.run_dir / "result.cls"
        cls.write_text(MATCH_CLS.replace("Run Result                    :     MATCH", "Run Result                    :     MISMATCH"))
        result, report = self.gate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("MONOLITHIC_LVS_STATUS=NOT_PROVEN", report.read_text())

    def test_hcell_or_blackbox_use_fails(self) -> None:
        self.assertEqual(self.prepare().returncode, 0)
        self.write_match_evidence()
        run = self.run_dir / "run.pvs"
        run.write_text(run.read_text() + " -hcell stale.hcell\n")
        control = self.run_dir / "pvslvsctl"
        control.write_text(control.read_text() + 'lvs_black_box "RO_tune6";\n')
        result, report = self.gate()
        self.assertNotEqual(result.returncode, 0)
        text = report.read_text()
        self.assertIn("LVS_HCELL_STATUS=FAIL_USED", text)
        self.assertIn("LVS_BLACKBOX_STATUS=FAIL_USED", text)


if __name__ == "__main__":
    unittest.main()
