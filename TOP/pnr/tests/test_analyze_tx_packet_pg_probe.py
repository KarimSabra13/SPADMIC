#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
ANALYZER = REPO / "TOP" / "pnr" / "scripts" / "analyze_tx_packet_pg_probe.py"


class AnalyzeTxPacketPgProbeTest(unittest.TestCase):
    def write_probe(
        self,
        root: Path,
        *,
        include_third_rail: bool = True,
        vss_row: bool = False,
        count_format: str = "verification",
    ) -> None:
        reports = root / "reports"
        reports.mkdir(parents=True)
        opens = [
            "Net VDD: has special routes with opens at (10.080, 9.680) (2056.880, 366.240)",
            "Net VDD: has special routes with opens at (10.080, 125.000) (2056.880, 128.120)",
            "Net VDD: has special routes with opens at (10.080, 133.960) (2056.880, 137.080)",
            "Net VDD: has special routes with opens at (10.080, 277.320) (2056.880, 280.440)",
        ]
        if vss_row:
            opens.append("Net VSS: has special routes with opens at (10.080, 200.000) (2056.880, 203.120)")
        if count_format == "verification":
            count_text = f"Verification Complete : {len(opens)} Viols.  0 Wrngs."
        elif count_format == "problem_summary":
            count_text = (
                "Begin Summary\n"
                f"    {len(opens)} Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.\n"
                "End Summary"
            )
        elif count_format == "disagree":
            count_text = (
                f"Verification Complete : {len(opens)} Viols.  0 Wrngs.\n"
                "Begin Summary\n"
                f"    {len(opens) + 1} Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.\n"
                "End Summary"
            )
        else:
            raise ValueError(f"unsupported count format: {count_format}")
        (reports / "verify_connectivity_special_detail.rpt").write_text(
            "\n".join(opens) + "\n" + count_text + "\n"
        )

        swires = [
            "VDD\t1\tFOLLOWPIN\tMET1\tROUTED\t0.8\tWIRE\t{10.08 125.00 2056.88 128.12}\tUNKNOWN",
            "VDD\t2\tFOLLOWPIN\tMET1\tROUTED\t0.8\tWIRE\t{10.08 133.96 2056.88 137.08}\tUNKNOWN",
            "VDD\t4\tSTRIPE\tMETTP\tROUTED\t3.36\tWIRE\t{515.20 10.08 518.56 366.24}\tUNKNOWN",
            "VSS\t1\tSTRIPE\tMETTP\tROUTED\t3.36\tWIRE\t{1548.40 14.56 1551.76 366.24}\tUNKNOWN",
        ]
        if include_third_rail:
            swires.insert(
                2,
                "VDD\t3\tFOLLOWPIN\tMET1\tROUTED\t0.8\tWIRE\t{10.08 277.32 2056.88 280.44}\tUNKNOWN",
            )
        (reports / "pg_topology.rpt").write_text(
            "LABEL=SPADMIC_OOC_PG_TOPOLOGY\n"
            "SWIRE_TABLE_BEGIN\n"
            "net\tidx\tshape\tlayer\tstatus\twidth\tgeomType\tbox\tpts\n"
            + "\n".join(swires)
            + "\nSWIRE_TABLE_END\n"
        )

        marker_lines = ["idx\tmarker_handle\tbox\tlayer\ttype\tsubType\tmessage"]
        for index in range(1, 8):
            marker_lines.append(f"{index}\th{index}\t{{0 0 1 1}}\tMET1\tGeometry\tMinimal_Area\tn_{index}")
        for index in range(8, 37):
            marker_lines.append(f"{index}\th{index}\t{{0 0 1 1}}\tMET3\tAntenna\tAntenna_Side_Area_Ratio\tn_{index}")
        for index, (net, box) in enumerate(
            [("VDD", "{10 10 20 20}")] * 4 + ([("VSS", "{10 10 20 20}")] if vss_row else []),
            start=37,
        ):
            marker_lines.append(f"{index}\th{index}\t{box}\tPOLY1\tConnectivity\tOpen\tNet {net}")
        (reports / "pg_connectivity_markers.tsv").write_text("\n".join(marker_lines) + "\n")

    def run_analyzer(self, root: Path) -> tuple[subprocess.CompletedProcess[str], str]:
        report = root / "analysis.rpt"
        result = subprocess.run(
            ["python3", str(ANALYZER), "--probe-root", str(root), "--report", str(report)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return result, report.read_text()

    def test_classifies_three_vdd_rows_and_authorizes_one_trial(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_probe(root)
            result, report = self.run_analyzer(root)
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("VDD_HORIZONTAL_ROW_COMPONENT_COUNT=3", report)
            self.assertIn("VSS_HORIZONTAL_ROW_COMPONENT_COUNT=0", report)
            self.assertIn("VDD_AGGREGATE_COMPONENT_COUNT=1", report)
            self.assertIn("DRC_MINIMUM_AREA_MARKER_COUNT=7", report)
            self.assertIn("DRC_ANTENNA_MARKER_COUNT=29", report)
            self.assertIn("SPECIAL_CONNECTIVITY_COUNT_SOURCE=VERIFICATION_COMPLETE", report)
            self.assertIn("SPECIAL_CONNECTIVITY_COUNT_CONSISTENCY=PASS", report)
            self.assertIn("EDIT_POWER_VIA_TRIAL_DECISION=READY_FOR_ONE_ISOLATED_TRIAL", report)
            self.assertIn("VDD_ROW_1_VIA_SEARCH_AREA={515.200 125.000 518.560 128.120}", report)

    def test_accepts_impvfc_200_problem_summary_count(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_probe(root, count_format="problem_summary")
            result, report = self.run_analyzer(root)
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("SPECIAL_CONNECTIVITY_VIOLATION_COUNT=4", report)
            self.assertIn("SPECIAL_CONNECTIVITY_COUNT_SOURCE=IMPVFC_200_PROBLEM_SUMMARY", report)
            self.assertIn("SPECIAL_CONNECTIVITY_COUNT_CONSISTENCY=PASS", report)
            self.assertIn("EDIT_POWER_VIA_TRIAL_DECISION=READY_FOR_ONE_ISOLATED_TRIAL", report)

    def test_blocks_trial_when_count_sources_disagree(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_probe(root, count_format="disagree")
            result, report = self.run_analyzer(root)
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("SPECIAL_CONNECTIVITY_COUNT_CONSISTENCY=FAIL", report)
            self.assertIn("SPECIAL_CONNECTIVITY_VERIFICATION_COUNT=4", report)
            self.assertIn("SPECIAL_CONNECTIVITY_PROBLEM_SUMMARY_COUNT=5", report)
            self.assertIn("EDIT_POWER_VIA_TRIAL_DECISION=BLOCKED_NEEDS_TOPOLOGY_REVIEW", report)

    def test_blocks_trial_when_a_row_has_no_met1_swire_overlap(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_probe(root, include_third_rail=False)
            result, report = self.run_analyzer(root)
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("EDIT_POWER_VIA_TRIAL_DECISION=BLOCKED_NEEDS_TOPOLOGY_REVIEW", report)
            self.assertIn("VDD_ROW_3_VIA_SEARCH_AREA=NONE", report)

    def test_blocks_trial_when_vss_has_a_row_open(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_probe(root, vss_row=True)
            result, report = self.run_analyzer(root)
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("VSS_HORIZONTAL_ROW_COMPONENT_COUNT=1", report)
            self.assertIn("EDIT_POWER_VIA_TRIAL_DECISION=BLOCKED_NEEDS_TOPOLOGY_REVIEW", report)


if __name__ == "__main__":
    unittest.main()
