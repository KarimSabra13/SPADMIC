#!/usr/bin/env python3

from __future__ import annotations

import csv
import importlib.util
import os
import subprocess
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

    def test_pg_geometry_fix_preserves_signal_implementation(self) -> None:
        script = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.tcl"
        ).read_text()
        self.assertIn("add_shape -net VDD -layer METTP -shape STRIPE", script)
        self.assertIn("add_shape -net VSS -layer METTP -shape STRIPE", script)
        self.assertIn("sroute -connect {corePin}", script)
        self.assertNotIn("blockPin", script)
        for forbidden in ("routeDesign", "placeDesign", "ccopt_design", "clockDesign"):
            self.assertNotIn(forbidden, script)

    def test_pg_geometry_fix_uses_marker_derived_extents(self) -> None:
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        ).read_text()
        self.assertIn("SPADMIC_PG_FIX_VDD_X_FALLBACK_UM:-858.480", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VSS_X_FALLBACK_UM:-2574.880", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VDD_Y0_UM:-10.080", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VSS_Y0_UM:-14.560", wrapper)
        self.assertIn("SPADMIC_PG_FIX_Y1_UM:-180.880", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VDD_HELPER_Y0_UM:-126.560", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VDD_HELPER_Y1_UM:-153.440", wrapper)

    def test_pg_helper_candidates_use_fresh_innovus_processes(self) -> None:
        script = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.tcl"
        ).read_text()
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        ).read_text()
        self.assertEqual(script.count("restoreDesign"), 1)
        self.assertNotIn("restore_db_stop_at_design_in_memory", script + wrapper)
        self.assertIn("for CANDIDATE_X in", wrapper)
        self.assertIn("SPADMIC_PG_FIX_TRIAL_MODE=1", wrapper)
        self.assertIn("SPADMIC_PG_FIX_TRIAL_MODE=0", wrapper)
        self.assertIn("ACCEPT_FOR_CANONICAL_REPLAY", wrapper)
        self.assertIn("ONE_INNOVUS_PROCESS_PER_CANDIDATE", script)

    def test_pg_helper_candidates_are_fail_closed(self) -> None:
        script = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.tcl"
        ).read_text()
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        ).read_text()
        self.assertIn("PG_HELPER_CANDIDATE_REJECTED", script)
        self.assertIn("NOT_RUN_CANDIDATE_TRIAL", script)
        self.assertIn('status(PG_CONNECTIVITY_STATUS) ne "PASS"', script)
        self.assertIn('status(PG_MARKER_COUNT) != 0', script)
        self.assertIn('status(REGULAR_CONNECTIVITY_STATUS) ne "PASS"', script)
        self.assertIn('status(INNOVUS_DRC_STATUS) ne "PASS"', script)
        self.assertIn('TRIAL_PG" == "0"', wrapper)
        self.assertIn('TRIAL_MARKERS" == "0"', wrapper)
        self.assertIn('TRIAL_REGULAR" == "0"', wrapper)
        self.assertIn('TRIAL_DRC" == "0"', wrapper)
        self.assertIn("FAIL_NO_CLEAN_CANDIDATE", wrapper)

    def test_pg_wrapper_replays_clean_trial_in_fresh_process(self) -> None:
        wrapper = REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            checkpoint = root / "source" / "checkpoints" / "05_postroute_export.enc.dat"
            checkpoint.mkdir(parents=True)
            stream_map = root / "stream.map"
            stdcell_gds = root / "stdcells.gds"
            stream_map.write_text("map\n")
            stdcell_gds.write_text("gds\n")

            calls = root / "innovus_calls.tsv"
            fake_bin = root / "bin"
            fake_bin.mkdir()
            fake_innovus = fake_bin / "innovus"
            fake_innovus.write_text(
                "#!/usr/bin/env bash\n"
                "set -u\n"
                "printf '%s\\t%s\\n' \"$SPADMIC_PG_FIX_TRIAL_MODE\" "
                "\"$SPADMIC_PG_FIX_RUN_ROOT\" >>\"$FAKE_INNOVUS_CALLS\"\n"
                "mkdir -p \"$SPADMIC_PG_FIX_RUN_ROOT/reports\"\n"
                "if [[ \"$SPADMIC_PG_FIX_TRIAL_MODE\" == 1 ]]; then\n"
                "  {\n"
                "    echo STATUS=PASS\n"
                "    echo RESULT=PG_HELPER_CANDIDATE_CLEAN\n"
                "    echo PG_CONNECTIVITY_VIOLATION_COUNT=0\n"
                "    echo PG_MARKER_COUNT=0\n"
                "    echo REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
                "    echo DRC_MARKER_TOTAL=0\n"
                "  } >\"$SPADMIC_PG_FIX_RUN_ROOT/reports/pg_geometry_fix_status.rpt\"\n"
                "  exit 0\n"
                "fi\n"
                "{\n"
                "  echo STATUS=FAIL\n"
                "  echo RESULT=CANONICAL_REPLAY_TEST_STOP\n"
                "} >\"$SPADMIC_PG_FIX_RUN_ROOT/reports/pg_geometry_fix_status.rpt\"\n"
                "exit 8\n"
            )
            fake_innovus.chmod(0o755)

            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{fake_bin}:{env.get('PATH', '')}",
                    "FAKE_INNOVUS_CALLS": str(calls),
                    "SPADMIC_WORK_ROOT": str(root / "work"),
                    "SPADMIC_STREAMOUT_MAP_FILE": str(stream_map),
                    "SPADMIC_STDCELL_GDS": str(stdcell_gds),
                    "SPADMIC_PG_FIX_VDD_HELPER_CANDIDATES_UM": "970.480 746.480",
                }
            )
            result = subprocess.run(
                [str(wrapper), str(root / "source"), "tx_ddr_strip", "pg_process_test"],
                cwd=REPO,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )

            self.assertEqual(result.returncode, 8, result.stdout)
            invocation_rows = [line.split("\t") for line in calls.read_text().splitlines()]
            self.assertEqual([row[0] for row in invocation_rows], ["1", "0"])
            self.assertNotEqual(invocation_rows[0][1], invocation_rows[1][1])
            self.assertIn("/trials/trial_01_x_970p480", invocation_rows[0][1])
            self.assertTrue(invocation_rows[1][1].endswith("/innovus/pg_process_test"))

            run_root = root / "work" / "innovus" / "pg_process_test"
            candidate_summary = (run_root / "reports" / "vdd_helper_candidate_summary.tsv").read_text()
            self.assertIn("ACCEPT_FOR_CANONICAL_REPLAY", candidate_summary)
            self.assertEqual(list((run_root / "trials" / "trial_01_x_970p480" / "outputs").iterdir()), [])
            wrapper_status = (run_root / "reports" / "pg_geometry_fix_wrapper_status.rpt").read_text()
            self.assertIn("CANONICAL_REPLAY=RUN", wrapper_status)
            self.assertIn("CANONICAL_INNOVUS_RC=8", wrapper_status)


if __name__ == "__main__":
    unittest.main()
