#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
GATE_PATH = REPO / "TOP" / "syn" / "scripts" / "validate_genus_tc_ooc.py"
SPEC = importlib.util.spec_from_file_location("genus_tc_ooc_test", GATE_PATH)
assert SPEC and SPEC.loader
gate = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = gate
SPEC.loader.exec_module(gate)


class GenusTcOocGateTest(unittest.TestCase):
    @staticmethod
    def contract_netlist(top_module: str) -> str:
        declarations = []
        for name, contract in gate.EXPECTED_BOUNDARIES[top_module].items():
            range_text = f"[{contract.width - 1}:0] " if contract.width > 1 else ""
            declarations.append(
                f"  {contract.direction} wire {range_text}{name}"
            )
        return (
            f"module {top_module}(\n"
            + ",\n".join(declarations)
            + "\n);\nendmodule\n"
        )

    def make_block(
        self,
        root: Path,
        *,
        external_delay_count: int = 0,
        omit_port: str | None = None,
        wrong_direction_port: str | None = None,
        wrong_width_port: str | None = None,
    ) -> Path:
        block_root = root / "event_coordinator"
        outputs = block_root / "outputs"
        reports = block_root / "reports"
        for directory in (
            outputs,
            reports / "elaboration",
            reports / "timing",
            reports / "qor",
            reports / "messages",
        ):
            directory.mkdir(parents=True, exist_ok=True)

        declarations = []
        for name, contract in gate.EXPECTED_BOUNDARIES["spadmic_event_coordinator"].items():
            if name == omit_port:
                continue
            direction = (
                "output"
                if name == wrong_direction_port and contract.direction == "input"
                else "input"
                if name == wrong_direction_port
                else contract.direction
            )
            width = contract.width + 1 if name == wrong_width_port else contract.width
            range_text = f"[{width - 1}:0] " if width > 1 else ""
            declarations.append(f"  {direction} wire {range_text}{name}")
        (outputs / "event_coordinator.postsyn.v").write_text(
            "module spadmic_event_coordinator(\n"
            + ",\n".join(declarations)
            + "\n);\nendmodule\n"
        )
        (outputs / "event_coordinator.postsyn.sdc").write_text(
            "create_clock -name clk_sys -period 6.25 [get_ports clk_sys]\n"
        )
        (reports / "elaboration" / "check_design_post_elab.rpt").write_text(
            "No unresolved references in design 'spadmic_event_coordinator'\n"
            " Summary\n"
            " -------\n"
            "Unresolved References                        0\n"
        )

        intent_lines = [
            "Lint summary",
            " Unconnected/logic driven clocks                                  0",
            " Sequential data pins driven by a clock signal                    0",
            " Sequential clock pins without clock waveform                     0",
            " Sequential clock pins with multiple clock waveforms              0",
            " Generated clocks without clock waveform                          0",
            " Paths constrained with different clocks                          0",
            " Nets with multiple drivers                                       0",
            " Timing exceptions with no effect                                 0",
            f" Inputs without clocked external delays                          {external_delay_count}",
            " Outputs without clocked external delays                          0",
            " Inputs without external driver/transition                        0",
            " Outputs without external load                                    0",
        ]
        (reports / "timing" / "check_timing_intent.rpt").write_text(
            "\n".join(intent_lines) + "\n"
        )
        (reports / "timing" / "report_clocks.rpt").write_text(
            " Clock Description\n"
            " Clock                             Clock     Source     No of\n"
            " Name     Period  Rise    Fall     Domain   Pin/Port  Registers\n"
            "-----------------------------------------------------------------\n"
            " clk_sys   6250.0   0.0   3125.0   domain_1   clk_sys         51\n"
        )
        (reports / "qor" / "report_qor.rpt").write_text(
            "  Cost    Critical         Violating\n"
            " Group   Path Slack  TNS     Paths\n"
            "-------------------------------------\n"
            "clk_sys      1969.1   0.0          0\n"
            "default    No paths   0.0\n"
        )
        (reports / "messages" / "warning_classification.rpt").write_text(
            "design_rule count=0\n"
            "inferred_latch count=0\n"
            "missing_external_delay count=0\n"
            "no_clock_waveform count=0\n"
            "tool_error count=0\n"
            "tool_warning count=0\n"
            "undriven count=0\n"
            "unresolved count=0\n"
        )
        return block_root

    def test_real_genus_table_shapes_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.make_block(Path(tmp))
            status = block_root / "reports" / "timing" / "tc_ooc_gate.rpt"
            result = gate.validate(
                block_root,
                "event_coordinator",
                "spadmic_event_coordinator",
                "clk_sys",
                6250.0,
                status,
            )
            self.assertEqual(result["STATUS"], "PASS", status.read_text())
            self.assertEqual(result["BOUNDARY_PORT_STATUS"], "PASS")
            self.assertEqual(result["EXPECTED_BASE_PORT_COUNT"], "30")
            self.assertEqual(result["ACTUAL_BASE_PORT_COUNT"], "30")
            self.assertEqual(result["EXPECTED_BIT_PORT_COUNT"], "63")
            self.assertEqual(result["ACTUAL_BIT_PORT_COUNT"], "63")
            self.assertEqual(result["TOP_PORT_COUNT"], "63")
            self.assertEqual(result["CLOCK_REGISTER_COUNT"], "51")
            self.assertEqual(result["WNS_PS"], "1969.1")

    def test_external_delay_debt_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.make_block(Path(tmp), external_delay_count=1)
            status = block_root / "reports" / "timing" / "tc_ooc_gate.rpt"
            result = gate.validate(
                block_root,
                "event_coordinator",
                "spadmic_event_coordinator",
                "clk_sys",
                6250.0,
                status,
            )
            self.assertEqual(result["STATUS"], "FAIL")
            self.assertIn(
                "timing_intent_nonzero=Inputs without clocked external delays:1",
                status.read_text(),
            )

    def test_missing_boundary_port_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.make_block(Path(tmp), omit_port="idle_o")
            status = block_root / "reports" / "timing" / "tc_ooc_gate.rpt"
            result = gate.validate(
                block_root,
                "event_coordinator",
                "spadmic_event_coordinator",
                "clk_sys",
                6250.0,
                status,
            )
            self.assertEqual(result["STATUS"], "FAIL")
            self.assertEqual(result["BOUNDARY_PORT_STATUS"], "FAIL")
            self.assertIn("boundary_missing_ports=idle_o", status.read_text())

    def test_wrong_boundary_direction_and_width_fail(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.make_block(
                Path(tmp),
                wrong_direction_port="busy_o",
                wrong_width_port="active_axis_mask_i",
            )
            status = block_root / "reports" / "timing" / "tc_ooc_gate.rpt"
            result = gate.validate(
                block_root,
                "event_coordinator",
                "spadmic_event_coordinator",
                "clk_sys",
                6250.0,
                status,
            )
            text = status.read_text()
            self.assertEqual(result["STATUS"], "FAIL")
            self.assertEqual(result["BOUNDARY_PORT_STATUS"], "FAIL")
            self.assertIn("boundary_direction=busy_o:input expected=output", text)
            self.assertIn("boundary_width=active_axis_mask_i:0,1,2,3 expected=0..2", text)

    def test_position_contract_is_20_base_ports_and_249_bits(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            netlist = Path(tmp) / "position.postsyn.v"
            netlist.write_text(self.contract_netlist("spadmic_position_core"))
            errors: list[str] = []
            bit_count, base_count, status = gate.parse_top(
                netlist,
                "spadmic_position_core",
                errors,
            )
            self.assertEqual(errors, [])
            self.assertEqual(status, "PASS")
            self.assertEqual(base_count, 20)
            self.assertEqual(bit_count, 249)

    def test_contract_names_and_directions_match_live_rtl(self) -> None:
        for top_module, rtl_name in (
            ("spadmic_position_core", "spadmic_position_core.sv"),
            ("spadmic_event_coordinator", "spadmic_event_coordinator.sv"),
        ):
            source = (REPO / "TOP" / "rtl" / rtl_name).read_text()
            module = next(
                item
                for item in gate.source_parser.parse_modules(source)
                if item.name == top_module
            )
            actual: dict[str, set[str]] = {}
            for spec in gate.source_parser.declaration_port_specs(module):
                base, _ = gate.split_port_bit(spec.name)
                actual.setdefault(base, set()).add(spec.direction)
            expected = gate.EXPECTED_BOUNDARIES[top_module]
            self.assertEqual(set(actual), set(expected))
            for name, contract in expected.items():
                self.assertEqual(actual[name], {contract.direction})


if __name__ == "__main__":
    unittest.main()
