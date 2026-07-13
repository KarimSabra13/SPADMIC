#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
VALIDATOR_PATH = REPO / "TOP" / "syn" / "scripts" / "validate_tx_packet_genus_ooc.py"
SPEC = importlib.util.spec_from_file_location("tx_packet_genus_gate", VALIDATOR_PATH)
assert SPEC and SPEC.loader
validator = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = validator
SPEC.loader.exec_module(validator)


class TxPacketGenusGateTest(unittest.TestCase):
    def make_fixture(self, root: Path) -> Path:
        block_root = root / "tx_packet_core"
        outputs = block_root / "outputs"
        reports = block_root / "reports"
        outputs.mkdir(parents=True)
        (reports / "elaboration").mkdir(parents=True)
        (reports / "timing").mkdir()
        (reports / "qor").mkdir()
        (reports / "messages").mkdir()

        scalar_ports = [f"src_data_i_s{source}_b{bit}" for source in range(4) for bit in range(16)]
        declarations = ",\n  ".join(["input clk_sys", *(f"input {name}" for name in scalar_ports)])
        (outputs / "tx_packet_core.postsyn.v").write_text(
            f"module spadmic_tx_packet_core(\n  {declarations}\n);\nendmodule\n"
        )
        (outputs / "tx_packet_core.postsyn.sdc").write_text("create_clock -period 6250 clk_sys\n")
        (reports / "elaboration" / "check_design_post_elab.rpt").write_text(
            "No unresolved references in design 'spadmic_tx_packet_core'\n"
            "Unresolved References                        0\n"
        )

        intent_lines = [f"{label} 0" for label in validator.REQUIRED_TIMING_INTENT_ZERO]
        intent_lines.extend(
            [
                "Inputs without external driver/transition 101",
                "Outputs without external load 52",
            ]
        )
        (reports / "timing" / "check_timing_intent.rpt").write_text("\n".join(intent_lines) + "\n")
        (reports / "timing" / "report_clocks.rpt").write_text(
            "clk_sys 6250.0 0.0 3125.0 domain_1 clk_sys 4407\n"
        )
        (reports / "qor" / "report_qor.rpt").write_text(
            "clk_sys 845.1 0.0 0\n"
            "default No paths 0.0\n"
            "Total 0.0 0\n"
            "Sequential Instance Count 4407\n"
        )
        warning_lines = [f"{key} count=0" for key in validator.REQUIRED_WARNING_ZERO]
        warning_lines.extend(["tool_warning count=2", "undriven count=8"])
        (reports / "messages" / "warning_classification.rpt").write_text(
            "\n".join(warning_lines) + "\n"
        )
        return block_root

    def test_valid_typical_ooc_result_is_ready_for_innovus_feasibility(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.make_fixture(Path(tmp))
            report = block_root / "reports" / "gate.rpt"
            values = validator.validate(block_root, report)
            self.assertEqual(values["STATUS"], "PASS")
            self.assertEqual(values["RESULT"], "READY_FOR_PACKET_INNOVUS_FEASIBILITY")
            self.assertEqual(values["SCALAR_SOURCE_PORT_COUNT"], "64")
            self.assertEqual(values["NESTED_TOP_PORT_COUNT"], "0")
            self.assertEqual(values["WNS_PS"], "845.1")
            self.assertEqual(values["TNS_PS"], "0.0")
            self.assertEqual(values["CLOCK_REGISTER_COUNT"], "4407")
            self.assertEqual(values["SEQUENTIAL_INSTANCE_COUNT"], "4407")
            self.assertEqual(values["INNOVUS_FEASIBILITY_READY"], "YES")
            self.assertEqual(values["SIGNOFF_READY"], "NO")
            self.assertEqual(values["LEGACY_UNDRIVEN_CLASSIFIER_COUNT"], "8")

    def test_negative_slack_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.make_fixture(Path(tmp))
            qor = block_root / "reports" / "qor" / "report_qor.rpt"
            qor.write_text(qor.read_text().replace("845.1", "-1.0"))
            report = block_root / "reports" / "gate.rpt"
            values = validator.validate(block_root, report)
            self.assertEqual(values["STATUS"], "FAIL")
            self.assertIn("ERROR=wns_ps=-1.0 expected_nonnegative", report.read_text())

    def test_missing_scalar_port_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.make_fixture(Path(tmp))
            netlist = block_root / "outputs" / "tx_packet_core.postsyn.v"
            netlist.write_text(netlist.read_text().replace("input src_data_i_s3_b15", "input wrong_port"))
            report = block_root / "reports" / "gate.rpt"
            values = validator.validate(block_root, report)
            self.assertEqual(values["STATUS"], "FAIL")
            self.assertIn("missing_scalar_ports=src_data_i_s3_b15", report.read_text())

    def test_clocked_register_count_must_cover_all_sequential_instances(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.make_fixture(Path(tmp))
            qor = block_root / "reports" / "qor" / "report_qor.rpt"
            qor.write_text(
                qor.read_text().replace(
                    "Sequential Instance Count 4407",
                    "Sequential Instance Count 4408",
                )
            )
            report = block_root / "reports" / "gate.rpt"
            values = validator.validate(block_root, report)
            self.assertEqual(values["STATUS"], "FAIL")
            self.assertIn("clocked_register_coverage=4407/4408 expected_equal", report.read_text())

    def test_external_drive_and_load_limitations_must_be_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.make_fixture(Path(tmp))
            intent = block_root / "reports" / "timing" / "check_timing_intent.rpt"
            intent.write_text(
                intent.read_text().replace("Inputs without external driver/transition 101\n", "")
            )
            report = block_root / "reports" / "gate.rpt"
            values = validator.validate(block_root, report)
            self.assertEqual(values["STATUS"], "FAIL")
            self.assertIn(
                "timing_intent_missing=Inputs without external driver/transition",
                report.read_text(),
            )

    def test_future_warning_classifier_ignores_zero_value_summary_rows(self) -> None:
        tcl = (REPO / "TOP" / "syn" / "scripts" / "run_genus_matrix_block.tcl").read_text()
        self.assertIn(
            "(Undriven|Unconnected|Multidriven|Multiply driven|Unloaded)[^:]*[[:space:]]0",
            tcl,
        )


if __name__ == "__main__":
    unittest.main()
