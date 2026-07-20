#!/usr/bin/env python3
"""Regression checks for the Position base+density strict dry-run driver."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_preflight_position_core_pvs_drc.sh"
HANDOFF = REPO / "TOP" / "pnr" / "scripts" / "run_pvs_drc_handoff.sh"


class PositionPvsStrictPreflightDriverTests(unittest.TestCase):
    def test_driver_is_interactive_safe_and_never_executes_pvs(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotIn("set -e", text)
        self.assertNotIn("nohup", text)
        self.assertNotIn("tail -f", text)
        self.assertNotIn("watch ", text)
        self.assertNotIn("bash ./run.pvs", text)
        self.assertNotIn("pvs.stdout.log\" 2>&1", text)
        self.assertEqual(text.count("run_pvs_drc_handoff.sh"), 2)
        self.assertEqual(text.count("--dry-run"), 2)

    def test_driver_binds_exact_r10_and_seed_evidence(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "934744cb9a2e524c3d5e2e4aa2c8a057117fcddfcf45aaae52e2a7e5873dc717",
            "17b311a2548894233e24d623933ccbe5344fdc85b5f466fecdebd642ea1e3eae",
            "ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1",
            "b9a8451c6cc43647ec606ae706e450893e3673e22215dc5a64edeeb383b902ef",
            "11ae3fc935041b8a4e0f3b406941c699c769ed1d50a504e8df36fcb544c7255a",
            "PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT=0",
            "PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=0",
            "NOPIM_REACHABLE_GEOMETRY_ELEMENT_COUNT=0",
            "STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=READY_FOR_MANUAL_AUTHORIZATION",
        ):
            self.assertIn(token, text)

    def test_driver_materializes_and_audits_both_variants(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "--variant base",
            "--variant density",
            "--allow-cross-block-control-scaffold",
            "#UNDEFINE DENSITY",
            "#DEFINE DENSITY",
            "#UNDEFINE POPPING",
            "#UNDEFINE PIMIDE",
            "#UNDEFINE DUMMY_FILL",
            "#DEFINE VAR_ANT_RATIO",
            "PVS_DRC_STATUS=DRY_RUN_READY",
            "CROSS_BLOCK_CONTROL_SCAFFOLD_AUTHORIZED=YES",
            "PVS_EXECUTED=NO",
        ):
            self.assertIn(token, text)

    def test_driver_reports_partial_failure_without_requiring_unrun_artifacts(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("FINAL_RESULT=STRICT_DRY_RUN_PREFLIGHT_INCOMPLETE", text)
        self.assertIn('echo "RESULT=$FINAL_RESULT"', text)
        self.assertIn(
            '"$DENSITY_RUN_DIR|$DIAGNOSTIC_ROOT/density|$DENSITY_DRY_RUN_RC"',
            text,
        )
        self.assertIn('elif [ "$VARIANT_DRY_RUN_RC" = "0" ]; then', text)

    def test_shell_syntax(self) -> None:
        for script in (DRIVER, HANDOFF):
            result = subprocess.run(
                ["bash", "-n", str(script)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
