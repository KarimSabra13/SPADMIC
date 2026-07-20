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
            "RULECHECK R1M3P1 ..................... Total Result      1 (       1)\n"
            "RULECHECK R2M3P1 ..................... Total Result      1 (       1)\n"
            "RULECHECK RATIO1 ..................... Total Result      1 (       1)\n"
            "RULECHECK ZERO ....................... Total Result      0 (       0)\n"
            "Total DRC RuleChecks              : 6\n"
            "Total DRC Results                 : 6 (6)\n"
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
            "R1M3P1\n"
            "1 1 3 Jul 16 12:00:00 2026\n"
            "Rule File Pathname: /deck/config.rul\n"
            "Rule File Title: \" Example Foundry Deck \"\n"
            "\"Maximum ratio of MET3 area to connected GATE area ... 400\"\n"
            "p 1 4\n"
            "32500 32500\n"
            "32600 32500\n"
            "32600 32600\n"
            "32500 32600\n"
            "R2M3P1\n"
            "1 1 3 Jul 16 12:00:00 2026\n"
            "Rule File Pathname: /deck/config.rul\n"
            "Rule File Title: \" Example Foundry Deck \"\n"
            "\"Maximum ratio of MET3 area to connected GATE area ... 400\"\n"
            "p 1 4\n"
            "35000 35000\n"
            "35100 35000\n"
            "35100 35100\n"
            "35000 35100\n"
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
            "DRC_TOTAL_PRIMARY=6\n"
            "DRC_TOTAL_EXPANDED=6\n"
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
        expected: int = 6,
        variant: str = "base",
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
                "--expected-variant",
                variant,
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
            self.assertIn("DRC_TOTAL_PRIMARY=6", status)
            self.assertIn("ANTENNA_PRIMARY_RESULT_COUNT=3", status)
            self.assertIn("NON_ANTENNA_PRIMARY_RESULT_COUNT=3", status)
            self.assertIn("ANTENNA_GATE_AREA_RATIO_RULE_COUNT=2", status)
            self.assertIn("ANTENNA_RESULT_STATUS=NONZERO", status)
            self.assertIn("NON_ANTENNA_RESULT_STATUS=NONZERO", status)
            self.assertIn("VAR_ANT_RATIO_STATE=UNDEFINED", status)
            self.assertIn(
                "VAR_ANT_RATIO_SCOPE=ADDITIONAL_OPTIONAL_RULE_FAMILY_ONLY",
                status,
            )
            self.assertIn("PVS_RESULTS_OVERLAPPING_WAIVER_BOXES=1", status)
            self.assertIn("PVS_DRC_VARIANT=BASE", status)
            self.assertIn("PVS_BASE_DRC_STATUS=FAIL", status)

            non_antenna = (output / "pvs_drc_non_antenna_rules.tsv").read_text()
            self.assertIn("S1M1", non_antenna)
            self.assertIn("RATIO1", non_antenna)
            self.assertNotIn("ANT_GATE", non_antenna)
            self.assertNotIn("R2M3P1", non_antenna)

            antenna = (output / "pvs_drc_antenna_rules.tsv").read_text()
            self.assertIn("ANT_GATE", antenna)
            self.assertIn("R1M3P1", antenna)
            self.assertIn("R2M3P1", antenna)
            self.assertIn(
                "CONDUCTOR_AREA_TO_CONNECTED_GATE_AREA_RATIO",
                antenna,
            )
            self.assertIn("\tANTENNA\tMET3\t", antenna)

            geometry = (output / "pvs_drc_marker_geometry.tsv").read_text()
            self.assertEqual(len(geometry.splitlines()), 7)
            self.assertIn("1.000000", geometry)

            correlation = (
                output / "pvs_innovus_marker_correlation.tsv"
            ).read_text()
            self.assertIn("n_test", correlation)
            self.assertIn("S1M1", correlation)

            markdown = (output / "pvs_drc_non_antenna_analysis.md").read_text()
            self.assertIn("## Antenna Rule Inventory", markdown)
            self.assertIn("## Non-Antenna Per-Rule Evidence", markdown)
            self.assertIn("Minimum MET1 spacing/notch", markdown)
            self.assertIn("fixed metal-to-connected-gate antenna checks", markdown)
            self.assertIn("explicit `MATCH`", markdown)

    def test_density_variant_requires_defined_selector_and_stays_separate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run, waiver = self.make_run(root)
            status_path = run / "pvs_drc_status.rpt"
            status_path.write_text(
                status_path.read_text().replace(
                    "PVS_DRC_VARIANT=BASE",
                    "PVS_DRC_VARIANT=DENSITY",
                )
            )
            control_path = run / "pvsdrcctl"
            control_path.write_text(
                control_path.read_text().replace(
                    "#UNDEFINE DENSITY",
                    "#DEFINE DENSITY",
                )
            )

            output = root / "density_analysis"
            result = self.run_analyzer(
                run,
                output,
                waiver,
                variant="density",
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            status = (output / "pvs_drc_analysis_status.rpt").read_text()
            self.assertIn("PVS_DRC_VARIANT=DENSITY", status)
            self.assertIn("DENSITY_STATE=DEFINED", status)
            self.assertIn(
                "PVS_BASE_DRC_STATUS=UNCHANGED_SEPARATE_GATE",
                status,
            )
            self.assertIn("PVS_DENSITY_DRC_STATUS=FAIL", status)

            markdown = (output / "pvs_drc_non_antenna_analysis.md").read_text()
            self.assertIn("# PVS Density DRC Rule Classification", markdown)
            self.assertIn("separate accepted base-DRC evidence", markdown)

    def test_extent_area_ratio_is_whole_window_density_not_local_area(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run, waiver = self.make_run(root)
            error = run / "canonical_top_drc.err"
            error.write_text(
                error.read_text().replace(
                    "Maximum MET2 width ratio",
                    "Minimum ratio of METTP area to EXTENT area ... 30.0%",
                )
            )

            output = root / "analysis"
            result = self.run_analyzer(run, output, waiver)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            inventory = (output / "pvs_drc_rule_inventory.tsv").read_text()
            row = next(
                line for line in inventory.splitlines() if line.startswith("5\tRATIO1\t")
            )
            self.assertIn("\tDENSITY\tMETTP\t", row)
            self.assertIn("whole-window coverage debt", row)
            self.assertIn("do not apply a localized minimum-area repair", row)
            self.assertNotIn("known Innovus MET1", row)

    def test_expected_total_mismatch_fails_without_creating_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run, waiver = self.make_run(root)
            output = root / "analysis"
            result = self.run_analyzer(run, output, waiver, expected=135)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("unexpected primary DRC total", result.stderr)
            self.assertFalse(output.exists())

    def test_all_antenna_partition_writes_header_only_non_antenna_table(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run, waiver = self.make_run(root)
            error = run / "canonical_top_drc.err"
            text = error.read_text()
            text = text.replace(
                "Minimum MET1 spacing/notch ... 0.23",
                "Maximum gate antenna ratio",
            )
            text = text.replace(
                "Maximum MET2 width ratio",
                "Maximum ratio of MET2 area to connected GATE area ... 400",
            )
            error.write_text(text)

            output = root / "analysis"
            result = self.run_analyzer(run, output, waiver)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            status = (output / "pvs_drc_analysis_status.rpt").read_text()
            self.assertIn("ANTENNA_PRIMARY_RESULT_COUNT=6", status)
            self.assertIn("NON_ANTENNA_PRIMARY_RESULT_COUNT=0", status)
            self.assertIn("NON_ANTENNA_RESULT_STATUS=ZERO", status)

            non_antenna = (output / "pvs_drc_non_antenna_rules.tsv").read_text()
            self.assertEqual(len(non_antenna.splitlines()), 1)

            markdown = (output / "pvs_drc_non_antenna_analysis.md").read_text()
            self.assertIn(
                "No non-antenna PVS base-DRC rule remains",
                markdown,
            )

    def test_analysis_without_waiver_does_not_claim_tx_lvs_or_markers(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run, _ = self.make_run(root)
            (run / "pvsdrcctl").write_text(
                "#UNDEFINE DENSITY\n"
                "#DEFINE VAR_ANT_RATIO\n"
            )
            output = root / "position_analysis"
            result = subprocess.run(
                [
                    "python3",
                    str(SCRIPT),
                    "--run-dir",
                    str(run),
                    "--output-dir",
                    str(output),
                    "--expected-primary",
                    "6",
                    "--expected-expanded",
                    "6",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            markdown = (output / "pvs_drc_non_antenna_analysis.md").read_text()
            self.assertIn(
                "this DRC analysis does not infer an LVS result",
                markdown,
            )
            self.assertIn(
                "`VAR_ANT_RATIO=DEFINED` enables the supplemental",
                markdown,
            )
            self.assertNotIn("four Innovus MET1", markdown)
            self.assertNotIn("separate explicit `MATCH`", markdown)

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
