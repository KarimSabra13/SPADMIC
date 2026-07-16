#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
MODULE_PATH = REPO / "TOP" / "pnr" / "scripts" / "prepare_pvs_lvs_source.py"
SPEC = importlib.util.spec_from_file_location("prepare_pvs_lvs_source", MODULE_PATH)
assert SPEC and SPEC.loader
source_prep = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = source_prep
SPEC.loader.exec_module(source_prep)


class PreparePvsLvsSourceTest(unittest.TestCase):
    def write_inputs(self, root: Path, *, nested: bool = False, lef_extra: str = "") -> tuple[Path, Path, Path]:
        source_pin = r"\src_data_i[0][0] " if nested else "src_data_i_s0_b0"
        netlist = root / "input.pg.v"
        netlist.write_text(
            "// module COMMENT_ONLY; endmodule\n"
            f"module spadmic_tx_packet_core (VDD, VSS, {source_pin}, tx_data_o);\n"
            "  inout VDD, VSS;\n"
            f"  input {source_pin};\n"
            "  output tx_data_o;\n"
            f"  AND2JIHDX1 u_cell (.A({source_pin}), .B(VDD), .Y(tx_data_o), .vddi(VDD), .gndi(VSS));\n"
            "endmodule\n\n"
            "module AND2JIHDX1 (A, B, Y, vddi, gndi);\n"
            "  input A, B, vddi, gndi; output Y;\n"
            "endmodule\n\n"
            "module retained_custom (input a, output y); assign y = a; endmodule\n"
        )
        cdl = root / "xh018_D_CELLS_JIHD.cdl"
        cdl.write_text(".SUBCKT AND2JIHDX1 A B Y vddi gndi\n.ENDS AND2JIHDX1\n")
        lef = root / "packet.lef"
        lef_source_pin = source_pin.strip().lstrip("\\")
        lef.write_text(
            "MACRO spadmic_tx_packet_core\n"
            "  PIN VDD\n  END VDD\n"
            "  PIN VSS\n  END VSS\n"
            f"  PIN {lef_source_pin}\n  END {lef_source_pin}\n"
            "  PIN tx_data_o\n  END tx_data_o\n"
            f"{lef_extra}"
            "END spadmic_tx_packet_core\n"
        )
        return netlist, cdl, lef

    def test_filters_only_modules_present_in_official_cdl(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            netlist, cdl, lef = self.write_inputs(root)
            output = root / "canonical.lvs.pg.v"
            status = root / "status.rpt"
            details = source_prep.prepare_lvs_source(
                input_netlist=netlist,
                output_netlist=output,
                source_top="spadmic_tx_packet_core",
                stdcell_cdl=cdl,
                lefs=[lef],
                status_path=status,
            )

            text = output.read_text()
            self.assertIn("module spadmic_tx_packet_core", text)
            self.assertIn("AND2JIHDX1 u_cell", text)
            self.assertNotIn("module AND2JIHDX1", text)
            self.assertIn("module retained_custom", text)
            self.assertEqual(details["REMOVED_STDCELL_MODULE_COUNT"], 1)
            self.assertIn("STATUS=PASS", status.read_text())
            self.assertIn("PIN_PARITY_STATUS=PASS", status.read_text())

    def test_lef_pin_mismatch_fails_without_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            netlist, cdl, lef = self.write_inputs(root, lef_extra="  PIN unexpected_pin\n  END unexpected_pin\n")
            output = root / "canonical.lvs.pg.v"
            status = root / "status.rpt"
            with self.assertRaisesRegex(ValueError, "pins_missing_in_source"):
                source_prep.prepare_lvs_source(
                    input_netlist=netlist,
                    output_netlist=output,
                    source_top="spadmic_tx_packet_core",
                    stdcell_cdl=cdl,
                    lefs=[lef],
                    status_path=status,
                )
            self.assertFalse(output.exists())
            self.assertIn("STATUS=FAIL", status.read_text())
            self.assertIn("PIN_PARITY_STATUS=FAIL", status.read_text())

    def test_nested_top_port_is_rejected_even_when_lef_matches(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            netlist, cdl, lef = self.write_inputs(root, nested=True)
            output = root / "canonical.lvs.pg.v"
            status = root / "status.rpt"
            with self.assertRaisesRegex(ValueError, "nested_top_ports"):
                source_prep.prepare_lvs_source(
                    input_netlist=netlist,
                    output_netlist=output,
                    source_top="spadmic_tx_packet_core",
                    stdcell_cdl=cdl,
                    lefs=[lef],
                    status_path=status,
                )
            self.assertFalse(output.exists())
            self.assertIn("NESTED_TOP_PORT_COUNT=1", status.read_text())

    def test_nonansi_vector_declaration_expands_to_lef_bits(self) -> None:
        module = source_prep.parse_modules(
            "module top (VDD, VSS, data); inout VDD, VSS; input [1:0] data; endmodule\n"
        )[0]
        self.assertEqual(set(source_prep.declaration_ports(module)), {"VDD", "VSS", "data[0]", "data[1]"})

    def test_ansi_range_is_reset_by_each_new_direction(self) -> None:
        module = source_prep.parse_modules(
            "module top (\n"
            "  input logic [2:0] vector_i,\n"
            "  input logic scalar_i,\n"
            "  output logic [1:0] vector_o,\n"
            "  output logic scalar_o\n"
            "); endmodule\n"
        )[0]
        specs = source_prep.declaration_port_specs(module)
        self.assertEqual(
            [(port.name, port.direction) for port in specs],
            [
                ("vector_i[2]", "input"),
                ("vector_i[1]", "input"),
                ("vector_i[0]", "input"),
                ("scalar_i", "input"),
                ("vector_o[1]", "output"),
                ("vector_o[0]", "output"),
                ("scalar_o", "output"),
            ],
        )

    def test_ansi_range_is_inherited_within_one_declaration_group(self) -> None:
        module = source_prep.parse_modules(
            "module top (input logic [1:0] first_i, second_i, output logic done_o); "
            "endmodule\n"
        )[0]
        self.assertEqual(
            source_prep.declaration_ports(module),
            ["first_i[1]", "first_i[0]", "second_i[1]", "second_i[0]", "done_o"],
        )

    def test_real_event_boundary_does_not_expand_following_scalars(self) -> None:
        source = (REPO / "TOP" / "rtl" / "spadmic_event_coordinator.sv").read_text()
        module = next(
            item
            for item in source_prep.parse_modules(source)
            if item.name == "spadmic_event_coordinator"
        )
        ports = source_prep.declaration_ports(module)
        self.assertEqual(len({port.split("[", 1)[0] for port in ports}), 30)
        self.assertEqual(len(ports), 61)
        self.assertIn("active_axis_mask_i[2]", ports)
        self.assertIn("active_mode_i", ports)
        self.assertIn("matrix_activity_i", ports)
        self.assertNotIn("matrix_activity_i[2]", ports)
        self.assertIn("event_open_o", ports)
        self.assertNotIn("event_open_o[3]", ports)

    def test_unresolved_instance_master_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            netlist, cdl, lef = self.write_inputs(root)
            netlist.write_text(
                netlist.read_text().replace(
                    "AND2JIHDX1 u_cell",
                    "MISSING_LIBRARY_CELL u_cell",
                    1,
                )
            )
            output = root / "canonical.lvs.pg.v"
            status = root / "status.rpt"
            with self.assertRaisesRegex(ValueError, "unresolved_master_not_in_source_or_cdl"):
                source_prep.prepare_lvs_source(
                    input_netlist=netlist,
                    output_netlist=output,
                    source_top="spadmic_tx_packet_core",
                    stdcell_cdl=cdl,
                    lefs=[lef],
                    status_path=status,
                )
            self.assertFalse(output.exists())
            self.assertIn("UNRESOLVED_MASTER_COUNT=1", status.read_text())


if __name__ == "__main__":
    unittest.main()
