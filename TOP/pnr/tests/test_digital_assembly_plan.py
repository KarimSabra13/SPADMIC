#!/usr/bin/env python3

from __future__ import annotations

import csv
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
MODULE_PATH = REPO / "TOP" / "pnr" / "scripts" / "gen_spadmic_digital_assembly_v1.py"
SPEC = importlib.util.spec_from_file_location("digital_assembly_plan", MODULE_PATH)
assert SPEC and SPEC.loader
plan = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = plan
SPEC.loader.exec_module(plan)


class DigitalAssemblyPlanTest(unittest.TestCase):
    def test_my_mirrors_packet_north_pin(self) -> None:
        macro = plan.Macro("m", 100.0, 20.0, {"Y"}, {}, Path("m.lef"))
        original = plan.Rect("MET3", 9.0, 19.0, 11.0, 20.0)
        mirrored = plan.transform_rect(original, macro, (50.0, 200.0), "MY")
        self.assertEqual((mirrored.llx, mirrored.urx), (139.0, 141.0))
        self.assertEqual((mirrored.lly, mirrored.ury), (219.0, 220.0))

    def test_approved_strip_overlaps_txrx4tdc2(self) -> None:
        audit = REPO / "TOP" / "docs" / "layout_audits" / "SPADMIC2_20260709_072331"
        obstacles = plan.load_obstacles(audit)
        packet_box = (61.980, 2689.624, 2128.940, 3056.424)
        strip_box = (61.980, 3061.110, 3584.940, 3241.990)
        with tempfile.TemporaryDirectory() as tmp:
            report = Path(tmp) / "conflicts.csv"
            rows = plan.write_geometry_conflicts(report, packet_box, strip_box, obstacles)
            txrx = [row for row in rows if row["obstacle"].endswith("TXRX4TDC2")]
            self.assertEqual(len(txrx), 1)
            self.assertEqual(txrx[0]["digital_instance"], "u_tx_ddr_strip")
            self.assertEqual(txrx[0]["overlap_bbox_um"], "3505.519 3061.110 3584.940 3241.990")
            self.assertEqual(txrx[0]["overlap_width_um"], "79.421")
            self.assertEqual(txrx[0]["overlap_height_um"], "180.880")
            with report.open(newline="") as fh:
                self.assertGreaterEqual(len(list(csv.DictReader(fh))), 1)

    def test_tx_contract_is_exactly_nineteen_nets(self) -> None:
        self.assertEqual(len(plan.TX_CONNECTIONS), 19)
        self.assertEqual(sum(name.startswith("tx_data_") for name, _, _ in plan.TX_CONNECTIONS), 16)

    def test_narrow_strip_clears_txrx_with_ten_um_margin(self) -> None:
        txrx = (3505.519, 464.920, 3638.910, 3265.795)
        narrow_strip = (61.980, 3061.110, 61.980 + 3433.000, 3241.990)
        self.assertFalse(plan.intersects(narrow_strip, txrx))
        self.assertAlmostEqual(txrx[0] - narrow_strip[2], 10.539, places=3)

    def test_strip_width_contract_accepts_narrow_candidate(self) -> None:
        macro = plan.Macro(
            plan.STRIP_MACRO,
            plan.MIN_STRIP_WIDTH_UM,
            plan.EXPECTED_STRIP_SIZE[1],
            set(),
            {},
            Path("strip.lef"),
        )
        plan.validate_strip_macro(macro)


if __name__ == "__main__":
    unittest.main()
