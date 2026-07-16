#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
SCRIPT = REPO / "TOP" / "pnr" / "scripts" / "analyze_pvs_drc_run.py"


class AnalyzePvsDrcRunTest(unittest.TestCase):
    def make_run(self, root: Path) -> tuple[Path, Path]:
        run = root / "immutable_drc_run"
        run.mkdir()
        summary = run / "canonical_top_drc.sum"
        error = run / "canonical_top_drc.err"
        summary.write_text(
            "Rule Deck Title         : \" Example Foundry Deck \"\n"
            "Layout System           : GDSII\n"
            "Layout Primary Cell     : canonical_top\n"
            "Layout Depth            : ALL\n"
            "Text Depth              : 0\n"
            "--- RULECHECK RESULTS STATISTICS\n"
            "RULECHECK S1M1 ....................... Total Result      2 (       2)\n"
            "RULECHECK ANT_GATE ................... Total Result      1 (       1)\n"
            "RULECHECK RATIO1 ..................... Total Result      1 (       1)\n"
            "RULECHECK ZERO ....................... Total Result      0 (       0)\n"
            "Total DRC RuleChecks              : 4\n"
            "Total DRC Results                 : 4 (4)\n"
        )
        error.write_text(
            "canonical_top 1000\n"
            "S1M1\n"
            "2 2 3 Jul 16 12:00:00 2026\n"
            "Rule File Pathname: /deck/config.rul\n"
            "Rule File Title: \" Example Foundry Deck \"\n"
            "\"Minimum MET1 spacing/notch ... 0.23\"\n"
            "p 1 4\n"
            "1000 1000\n"
            "1200 1000\n"
            "1200 1200\n"
            "1000 1200\n"
            "p 2 4\n"
            "20000 20000\n"
            "20200 20000\n"
            "20200 20200\n"
            "20000 20200\n"
            "ANT_GATE\n"
            "1 1 3 Jul 16 12:00:00 2026\n"
            "Rule File Pathname: /deck/config.rul\n"
            "Rule File Title: \" Example Foundry Deck \"\n"
            "\"Maximum gate antenna ratio\"\n"
            "p 1 4\n"
            "30000 30000\n"
            "30100 30000\n"
            "30100 30100\n"
            "30000 30100\n"
            "RATIO1\n"
            "1 1 3 Jul 16 12:00:00 2026\n"
            "Rule File Pathname: /deck/config.rul\n"
            "Rule File Title: \" Example Foundry Deck \"\n"
            "\"Maximum MET2 width ratio\"\n"
            "p 1 4\n"
            "40000 40000\n"
            "40100 40000\n"
            "40100 40100\n"
            "40000 40100\n"
        )
        (run / "pvs_drc_status.rpt").write_text(
            "LABEL=SPADMIC_PVS_HANDOFF_RESULT\n"
            "MODE=DRC\n"
            "PVS_RC=0\n"
            "PVS_DRC_STATUS=FAIL\n"
            "PVS_DRC_VARIANT=BASE\n"
            "DRC_TOTAL_PRIMARY=4\n"
            "DRC_TOTAL_EXPANDED=4\n"
        )
        (run / "replay_contract_status.rpt").write_text(
            "LABEL=SPADMIC_PVS_REPLAY_CONTRACT\n"
            "STATUS=PASS\n"
            "MODE=DRC\n"
            "LAYOUT_TOP=canonical_top\n"
        )
        (run / "output_isolation.rpt").write_text(
            "LABEL=SPADMIC_PVS_OUTPUT_ISOLATION\n"
            "STATUS=PASS\n"
            "MODE=DRC\n"
            f"DRC_SUMMARY={summary}\n"
            f"DRC_RESULTS_DB={error}\n"
        )
        (run / "external_references.rpt").write_text(
            "LABEL=SPADMIC_PVS_EXTERNAL_REFERENCES\n"
            f"FILE={summary}|1|hash\n"
        )
        (run / "pvsdrcctl").write_text(
            "#UNDEFINE DENSITY\n"
            "#UNDEFINE VAR_ANT_RATIO\n"
        )
        waiver = root / "temporary_drc_waiver.tsv"
        waiver.write_text(
            "waiver_id\tnet\tmarker_box\n"
            "W1\tn_test\t0.9 0.9 1.3 1.3\n"
        )
        return run, waiver

    def run_analyzer(
        self,
        run: Path,
        output: Path,
        waiver: Path,
        expected: int = 4,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                "python3",
                str(SCRIPT),
                "--run-dir",
                str(run),
                "--output-dir",
                str(output),
                "--expected-primary",
                str(expected),
                "--expected-expanded",
                str(expected),
                "--innovus-waiver-tsv",
                str(waiver),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_classifies_rules_geometry_and_innovus_overlap(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run, waiver = self.make_run(root)
            output = root / "analysis"
            result = self.run_analyzer(run, output, waiver)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            status = (output / "pvs_drc_analysis_status.rpt").read_text()
            self.assertIn("STATUS=PASS", status)
            self.assertIn("DRC_TOTAL_PRIMARY=4", status)
            self.assertIn("EXPLICIT_ANTENNA_PRIMARY_RESULT_COUNT=1", status)
            self.assertIn("NON_ANTENNA_PRIMARY_RESULT_COUNT=3", status)
            self.assertIn("VAR_ANT_RATIO_STATE=UNDEFINED", status)
            self.assertIn("PVS_RESULTS_OVERLAPPING_WAIVER_BOXES=1", status)

            non_antenna = (output / "pvs_drc_non_antenna_rules.tsv").read_text()
            self.assertIn("S1M1", non_antenna)
            self.assertIn("RATIO1", non_antenna)
            self.assertNotIn("ANT_GATE", non_antenna)

            geometry = (output / "pvs_drc_marker_geometry.tsv").read_text()
            self.assertEqual(len(geometry.splitlines()), 5)
            self.assertIn("1.000000", geometry)

            correlation = (
                output / "pvs_innovus_marker_correlation.tsv"
            ).read_text()
            self.assertIn("n_test", correlation)
            self.assertIn("S1M1", correlation)

            markdown = (output / "pvs_drc_non_antenna_analysis.md").read_text()
            self.assertIn("## Per-Rule Evidence", markdown)
            self.assertIn("Minimum MET1 spacing/notch", markdown)
            self.assertIn("explicit `MATCH`", markdown)

    def test_expected_total_mismatch_fails_without_creating_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run, waiver = self.make_run(root)
            output = root / "analysis"
            result = self.run_analyzer(run, output, waiver, expected=135)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("unexpected primary DRC total", result.stderr)
            self.assertFalse(output.exists())

    def test_output_inside_immutable_run_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run, waiver = self.make_run(root)
            output = run / "analysis"
            result = self.run_analyzer(run, output, waiver)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("outside the immutable PVS run", result.stderr)
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
