#!/usr/bin/env python3

from __future__ import annotations

import csv
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
MODULE_PATH = REPO / "TOP" / "pnr" / "scripts" / "validate_tx_canonical_ooc.py"
SPEC = importlib.util.spec_from_file_location("validate_tx_canonical_ooc", MODULE_PATH)
assert SPEC and SPEC.loader
gate = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = gate
SPEC.loader.exec_module(gate)


class ValidateTxCanonicalOocTest(unittest.TestCase):
    def make_packet_root(self, root: Path, antenna_count: int = 4) -> Path:
        block_root = root / "packet"
        outputs = block_root / "outputs"
        reports = block_root / "reports"
        outputs.mkdir(parents=True)
        reports.mkdir()
        (outputs / "tx_packet_core.gds").write_bytes(b"mapped-merged-gds")
        (outputs / "tx_packet_core.def").write_text("VERSION 5.8 ;\n")
        (outputs / "tx_packet_core.routed.pg.v").write_text(
            "module spadmic_tx_packet_core (VDD, VSS); inout VDD, VSS; endmodule\n"
        )

        lef_lines = [
            "MACRO spadmic_tx_packet_core",
            "  SIZE 2066.960 BY 366.800 ;",
            "  SYMMETRY X Y R90 ;",
        ]
        with gate.TX_PIN_CONTRACT.open(newline="") as fh:
            for row in csv.DictReader(fh):
                name = row["packet_pin"]
                x = float(row["packet_local_x_um"])
                lef_lines.extend([
                    f"  PIN {name}",
                    "    DIRECTION OUTPUT ;",
                    "    USE SIGNAL ;",
                    "    PORT",
                    "      LAYER MET3 ;",
                    f"      RECT {x - 0.2:.3f} 366.000 {x + 0.2:.3f} 366.800 ;",
                    "    END",
                    f"  END {name}",
                ])
        with gate.TX_SOURCE_MANIFEST.open(newline="") as fh:
            for row in csv.DictReader(fh):
                name = row["name"]
                lef_lines.extend([
                    f"  PIN {name}",
                    "    DIRECTION INPUT ;",
                    "    USE SIGNAL ;",
                    "    PORT",
                    "      LAYER MET3 ;",
                    "      RECT 0.000 0.000 0.400 0.800 ;",
                    "    END",
                    f"  END {name}",
                ])
        for name, use, llx, urx in [
            ("VDD", "POWER", 480.0, 520.0),
            ("VSS", "GROUND", 1540.0, 1580.0),
        ]:
            lef_lines.extend([
                f"  PIN {name}",
                "    DIRECTION INOUT ;",
                f"    USE {use} ;",
                "    PORT",
                "      LAYER METTP ;",
                f"      RECT {llx:.3f} 363.440 {urx:.3f} 366.800 ;",
                "    END",
                f"  END {name}",
            ])
        lef_lines.append("END spadmic_tx_packet_core")
        (outputs / "tx_packet_core.abstract.lef").write_text("\n".join(lef_lines) + "\n")

        required = {
            "RESULT": "ABSTRACT_READY_FOR_TOP_REVIEW",
            "INNOVUS_DRC_STATUS": "PASS",
            "REGULAR_CONNECTIVITY_STATUS": "PASS",
            "PG_CONNECTIVITY_STATUS": "PASS",
            "CREATE_PG_STRAPS": "PASS",
            "CREATE_PG_STRAP_VDD": "PASS",
            "CREATE_PG_STRAP_VSS": "PASS",
            "SROUTE_PG": "PASS",
            "POSTROUTE_SETUP_TIMING": "PASS",
            "POSTROUTE_HOLD_TIMING": "PASS",
            "EXPORT_GDS_FILE": "PASS",
            "EXPORT_ABSTRACT_LEF_FILE": "PASS",
            "EXPORT_NETLIST_PG": "PASS",
            "ANTENNA_MARKER_COUNT": str(antenna_count),
        }
        (reports / "ooc_harden_status.rpt").write_text(
            "\n".join(f"{key}={value}" for key, value in required.items()) + "\n"
        )
        (reports / "gds_export_audit.rpt").write_text(
            "STATUS=PASS\n"
            "GDS_FILE_STATUS=PASS\n"
            "GDS_LAYER_MAP_STATUS=PASS\n"
            "GDS_MERGE_STATUS=PASS\n"
        )
        return block_root

    def test_candidate_gate_allows_but_records_deferred_antenna(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = self.make_packet_root(Path(tmp))
            report = root / "reports" / "canonical_tx_ooc_gate.rpt"
            values = gate.validate(root, "tx_packet_core", report, True)
            self.assertEqual(values["STATUS"], "PASS")
            self.assertEqual(values["RESULT"], "READY_FOR_PVS_CANDIDATE")
            self.assertEqual(values["ANTENNA_MILESTONE_STATUS"], "DEFERRED_FINAL_HANDOFF_BLOCKED")
            self.assertEqual(values["FINAL_HANDOFF_READY"], "NO")

    def test_final_candidate_gate_rejects_nonzero_antenna_without_defer(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = self.make_packet_root(Path(tmp))
            values = gate.validate(
                root,
                "tx_packet_core",
                root / "reports" / "canonical_tx_ooc_gate.rpt",
                False,
            )
            self.assertEqual(values["STATUS"], "FAIL")
            self.assertIn("antenna_markers_not_allowed", (root / "reports" / "canonical_tx_ooc_gate.rpt").read_text())

    def test_stream_coordinate_drift_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = self.make_packet_root(Path(tmp), antenna_count=0)
            lef = root / "outputs" / "tx_packet_core.abstract.lef"
            lef.write_text(lef.read_text().replace("RECT 100.600", "RECT 101.600", 1))
            values = gate.validate(
                root,
                "tx_packet_core",
                root / "reports" / "canonical_tx_ooc_gate.rpt",
                False,
            )
            self.assertEqual(values["STATUS"], "FAIL")
            self.assertIn("stream_pin_x=tx_valid_o", (root / "reports" / "canonical_tx_ooc_gate.rpt").read_text())


if __name__ == "__main__":
    unittest.main()
