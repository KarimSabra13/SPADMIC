#!/usr/bin/env python3

from __future__ import annotations

import csv
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
VALIDATOR_PATH = REPO / "TOP" / "pnr" / "scripts" / "validate_digital_subblock_portfolio.py"
VALIDATOR_SPEC = importlib.util.spec_from_file_location("subblock_portfolio", VALIDATOR_PATH)
assert VALIDATOR_SPEC and VALIDATOR_SPEC.loader
portfolio = importlib.util.module_from_spec(VALIDATOR_SPEC)
sys.modules[VALIDATOR_SPEC.name] = portfolio
VALIDATOR_SPEC.loader.exec_module(portfolio)

OOC_PATH = REPO / "TOP" / "pnr" / "scripts" / "gen_ooc_block_harden_plan.py"
OOC_SPEC = importlib.util.spec_from_file_location("subblock_ooc", OOC_PATH)
assert OOC_SPEC and OOC_SPEC.loader
ooc = importlib.util.module_from_spec(OOC_SPEC)
sys.modules[OOC_SPEC.name] = ooc
OOC_SPEC.loader.exec_module(ooc)


class DigitalSubblockPortfolioTest(unittest.TestCase):
    def test_portfolio_and_floorplan_validate_against_audit(self) -> None:
        errors = portfolio.validate(
            portfolio.DEFAULT_PORTFOLIO,
            portfolio.DEFAULT_REGIONS,
            portfolio.DEFAULT_AUDIT,
        )
        self.assertEqual(errors, [])

    def test_hard_macro_order_and_blocked_mptdc_policy(self) -> None:
        with portfolio.DEFAULT_PORTFOLIO.open(newline="") as handle:
            rows = list(csv.DictReader(handle))
        hard = [row["block"] for row in rows if row["implementation"] == "HARD_MACRO"]
        self.assertEqual(
            hard,
            ["tx_packet_core", "tx_ddr_strip", "position_core", "event_coordinator"],
        )
        mptdc = next(row for row in rows if row["block"] == "mptdc_frontend")
        self.assertEqual(mptdc["current_gate"], "BLOCKED_ABSTRACT_MISSING")
        self.assertEqual(mptdc["promotion_policy"], "NO_PROMOTION_WHILE_BLOCKED")

    def test_position_and_event_ooc_plans_use_reserved_geometry_and_exact_pg(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ooc.generate_position_core(portfolio.DEFAULT_AUDIT, root / "position")
            ooc.generate_event_coordinator(portfolio.DEFAULT_AUDIT, root / "event")
            position = (root / "position" / "ooc_block_harden_config.tcl").read_text()
            event = (root / "event" / "ooc_block_harden_config.tcl").read_text()
            self.assertIn("variable core_width_um {931.695}", position)
            self.assertIn("variable core_height_um {640.000}", position)
            self.assertIn("variable pins_east", position)
            self.assertIn("{pkt_valid_o}", position)
            self.assertIn("variable core_width_um {217.460}", event)
            self.assertIn("variable core_height_um {200.000}", event)
            for config in (position, event):
                self.assertIn("variable enable_pg_sroute {1}", config)
                self.assertIn("variable pg_route_strategy {explicit_exact}", config)
                self.assertIn("variable route_profile {met1_effort}", config)

    def test_position_wrapper_is_transparent_and_used_by_matrix_top(self) -> None:
        wrapper = (REPO / "TOP" / "rtl" / "spadmic_position_core.sv").read_text()
        top = (REPO / "TOP" / "rtl" / "spadmic_top_matrix_v1.sv").read_text()
        self.assertIn("module spadmic_position_core", wrapper)
        self.assertEqual(wrapper.count("spadmic_position_snapshot_packetizer"), 1)
        self.assertNotIn("always_ff", wrapper)
        self.assertNotIn("always_comb", wrapper)
        self.assertIn("spadmic_position_core #(.LINE_W(SPADMIC_LINE_W)) u_pos_packetizer", top)

    def test_event_and_position_sdc_model_external_io(self) -> None:
        event = (
            REPO / "TOP" / "syn" / "constraints" / "ooc" / "spadmic_event_coordinator.sdc"
        ).read_text()
        position = (
            REPO / "TOP" / "syn" / "constraints" / "ooc" / "spadmic_position_core.sdc"
        ).read_text()
        for sdc in (event, position):
            self.assertIn("create_clock -name clk_sys", sdc)
            self.assertIn("set_input_delay", sdc)
            self.assertIn("set_input_transition", sdc)
            self.assertIn("set_output_delay", sdc)
            self.assertIn("set_load", sdc)
            self.assertNotIn("matrix_top_ooc_common.sdc", sdc)

    def test_ooc_tcl_places_east_only_when_configured(self) -> None:
        tcl = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_harden_block.tcl"
        ).read_text()
        self.assertIn(
            "spadmic_ooc_place_side_pins EAST [spadmic_ooc_cfg_default pins_east [list]]",
            tcl,
        )
        self.assertIn("EAST pins_east", tcl)


if __name__ == "__main__":
    unittest.main()
