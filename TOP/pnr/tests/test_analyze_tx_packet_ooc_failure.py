#!/usr/bin/env python3

from __future__ import annotations

import csv
import hashlib
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
MODULE_PATH = REPO / "TOP" / "pnr" / "scripts" / "analyze_tx_packet_ooc_failure.py"
SPEC = importlib.util.spec_from_file_location("analyze_tx_packet_ooc_failure", MODULE_PATH)
assert SPEC and SPEC.loader
analyzer = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = analyzer
SPEC.loader.exec_module(analyzer)


class AnalyzeTxPacketOocFailureTest(unittest.TestCase):
    def make_block(self, root: Path) -> Path:
        block = root / "block"
        outputs = block / "outputs"
        reports = block / "reports"
        generated = block / "generated"
        outputs.mkdir(parents=True)
        reports.mkdir()
        generated.mkdir()

        (reports / "ooc_harden_status.rpt").write_text(
            "REGULAR_CONNECTIVITY_STATUS=PASS\n"
            "PG_CONNECTIVITY_STATUS=FAIL\n"
            "SROUTE_PG=PASS\n"
            "POSTROUTE_MIN_AREA_REPAIR=REVIEW_REQUIRED\n"
        )
        (reports / "canonical_tx_ooc_gate.rpt").write_text(
            "STATUS=FAIL\n"
            "ANTENNA_MILESTONE_STATUS=DEFERRED_FINAL_HANDOFF_BLOCKED\n"
        )
        (reports / "SROUTE_PG.rpt").write_text("STATUS=PASS\nCOMMAND=sroute -connect corePin\n")
        (reports / "verify_connectivity_pg.rpt").write_text(
            "Net VDD: has special routes with opens.\n"
            "Begin Summary\n"
            "    3 Problem(s): Special Wires are not connected together.\n"
            "End Summary\n"
            "Verification Complete : 3 Viols. 0 Wrngs.\n"
        )
        (reports / "POSTROUTE_MIN_AREA_REPAIR.rpt").write_text(
            "PRE_MARKER_COUNT=31\n"
            "MIN_AREA_MARKER_COUNT=2\n"
            "MIN_AREA_NET_COUNT=2\n"
            "MIN_AREA_NETS=n_1 n_2\n"
            "SELECTED_NET_MODE_STATUS=PASS\n"
            "SELECTED_NET_COUNT=2\n"
            "SELECTED_NETS=n_1 n_2\n"
            "AREA_DELETE_COUNT=2\n"
            "AREA_DELETE_FAILURES=\n"
            "DRC_WIRE_DELETE_FAILURES=\n"
            "ROUTE_COMMANDS={globalDetailRoute -select}\n"
            "ROUTE_FAILURES=\n"
            "POST_MARKER_COUNT=30\n"
            "POST_DRC_STATUS=FAIL\n"
            "STATUS=REVIEW_REQUIRED\n"
        )

        header = [
            "idx",
            "marker_handle",
            "box",
            "llx",
            "lly",
            "urx",
            "ury",
            "cx",
            "cy",
            "layer",
            "type",
            "subType",
            "message",
        ]
        min_rows = [
            ["1", "m1", "{1 2 3 4}", "1", "2", "3", "4", "2", "3", "MET1", "Geometry", "Minimal_Area", "Regular Wire of Net n_1"],
            ["2", "m2", "{5 6 7 8}", "5", "6", "7", "8", "6", "7", "MET1", "Geometry", "Minimal_Area", "Regular Wire of Net n_2"],
        ]
        antenna = ["3", "m3", "{9 10 11 12}", "9", "10", "11", "12", "10", "11", "MET1", "Antenna", "Antenna", "Net src_data_i_s0_b0"]
        for name, rows in (
            ("postroute_min_area_repair_pre_markers.tsv", min_rows + [antenna]),
            ("postroute_min_area_repair_post_markers.tsv", [min_rows[0], antenna]),
            ("verify_drc_post_route_markers.tsv", [min_rows[0], antenna]),
        ):
            with (reports / name).open("w", newline="") as handle:
                writer = csv.writer(handle, delimiter="\t")
                writer.writerow(header)
                writer.writerows(rows)

        lef = ["MACRO spadmic_tx_packet_core", "  SIZE 2066.960 BY 366.800 ;"]
        plan_rows: list[list[str]] = []
        with analyzer.validator.TX_PIN_CONTRACT.open(newline="") as handle:
            for order, row in enumerate(csv.DictReader(handle)):
                pin = row["packet_pin"]
                expected = float(row["packet_local_x_um"])
                actual = expected + 0.280
                lef.extend(
                    [
                        f"  PIN {pin}",
                        "    DIRECTION OUTPUT ;",
                        "    USE SIGNAL ;",
                        "    PORT",
                        "      LAYER MET3 ;",
                        f"      RECT {actual - 0.200:.3f} 366.000 {actual + 0.200:.3f} 366.800 ;",
                        "    END",
                        f"  END {pin}",
                    ]
                )
                plan_rows.append(
                    [pin, "NORTH", "MET3", str(order), "paired", f"{expected:.3f}", "366.400", "", "", "", ""]
                )
        lef.append("END spadmic_tx_packet_core")
        (outputs / "tx_packet_core.abstract.lef").write_text("\n".join(lef) + "\n")

        with (generated / "ooc_block_pin_plan.csv").open("w", newline="") as handle:
            writer = csv.writer(handle)
            writer.writerow(
                [
                    "port",
                    "side",
                    "layer",
                    "order",
                    "reason",
                    "target_x_um",
                    "target_y_um",
                    "source_inst",
                    "source_term",
                    "source_x_um",
                    "source_y_um",
                ]
            )
            writer.writerows(plan_rows)
        (generated / "ooc_block_harden_config.tcl").write_text(
            "namespace eval spadmic_ooc {\n    variable pg_grid_um {0.56}\n}\n"
        )
        return block

    def test_classifies_uniform_half_grid_shift_and_separate_physical_blockers(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            block = self.make_block(root)
            report = root / "diagnosis.rpt"
            before = hashlib.sha256(
                (block / "outputs" / "tx_packet_core.abstract.lef").read_bytes()
            ).hexdigest()

            values = analyzer.diagnose(block, report)

            self.assertEqual(values["STATUS"], "PASS")
            self.assertEqual(values["DIAGNOSIS_STATUS"], "PASS")
            self.assertEqual(values["PG_COMMAND_STATUS"], "PASS")
            self.assertEqual(values["PG_CONNECTIVITY_STATUS"], "FAIL")
            self.assertEqual(values["PG_PROBLEM_COUNT"], "3")
            self.assertEqual(values["MIN_AREA_PRE_MARKER_COUNT"], "2")
            self.assertEqual(values["MIN_AREA_POST_MARKER_COUNT"], "1")
            self.assertEqual(values["MIN_AREA_FINAL_MARKER_COUNT"], "1")
            self.assertEqual(values["MIN_AREA_FINAL_NETS"], "n_1")
            self.assertEqual(values["ANTENNA_FINAL_MARKER_COUNT"], "1")
            self.assertEqual(values["STREAM_PIN_UNIQUE_DELTA_UM"], "0.280000")
            self.assertEqual(
                values["STREAM_PIN_GRID_RELATION"],
                "CONSISTENT_WITH_HALF_GRID_ASSIGNMENT_REFERENCE_SHIFT",
            )
            self.assertEqual(values["PVS_DECISION"], "DO_NOT_RUN")
            self.assertIn("STREAM_PIN_TABLE_BEGIN", report.read_text())
            report_text = report.read_text()
            self.assertIn("MIN_AREA_FINAL_TABLE_BEGIN", report_text)
            self.assertIn("REPAIR_STATUS=REVIEW_REQUIRED", report_text)
            self.assertEqual(
                [line for line in report_text.splitlines() if line.startswith("STATUS=")],
                ["STATUS=PASS"],
            )
            after = hashlib.sha256(
                (block / "outputs" / "tx_packet_core.abstract.lef").read_bytes()
            ).hexdigest()
            self.assertEqual(after, before)

    def test_missing_required_artifacts_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            block = self.make_block(root)
            (block / "reports" / "verify_connectivity_pg.rpt").unlink()
            values = analyzer.diagnose(block, root / "diagnosis.rpt")
            self.assertEqual(values["STATUS"], "FAIL")
            self.assertIn("verify_connectivity_pg.rpt", values["MISSING_REQUIRED_ARTIFACTS"])


if __name__ == "__main__":
    unittest.main()
