#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "07_classify_mptdc_free_trial_drc.py"


class FreeTrialDrcClassifierTest(unittest.TestCase):
    def run_case(
        self,
        rows: list[tuple[str, int, int]],
        expected_class: str,
        expected_rc: int,
        corrupt_hash: bool = False,
    ) -> tuple[str, Path, tempfile.TemporaryDirectory[str]]:
        tmp = tempfile.TemporaryDirectory(prefix="mptdc_free_drc_")
        root = Path(tmp.name)
        rules = root / "rules.tsv"
        rules.write_text(
            "rule\tprimary\texpanded\n"
            + "".join(f"{name}\t{primary}\t{expanded}\n" for name, primary, expanded in rows)
        )
        digest = hashlib.sha256(rules.read_bytes()).hexdigest()
        if corrupt_hash:
            digest = "0" * 64
        primary = sum(row[1] for row in rows)
        expanded = sum(row[2] for row in rows)
        gate = "PASS" if not rows else "FAIL"
        status = root / "status.rpt"
        status.write_text(
            f"STATUS={gate}\n"
            f"PVS_DRC_STATUS={gate}\n"
            "PVS_DRC_VARIANT=BASE\n"
            "PVS_RC=0\n"
            f"DRC_TOTAL_PRIMARY={primary}\n"
            f"DRC_TOTAL_EXPANDED={expanded}\n"
            f"NONZERO_RULE_COUNT={len(rows)}\n"
            f"NONZERO_RULE_REPORT={rules.resolve()}\n"
            f"NONZERO_RULE_REPORT_SHA256={digest}\n"
            "LAYOUT_INPUT_SHA256=abc123\n"
        )
        out = root / "classification.rpt"
        scope = root / "scope.rpt"
        completed = subprocess.run(
            [
                "python3",
                str(SCRIPT),
                "--status-report",
                str(status),
                "--rule-report",
                str(rules),
                "--out",
                str(out),
                "--scope-out",
                str(scope),
            ],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        self.assertEqual(completed.returncode, expected_rc, completed.stdout)
        text = out.read_text()
        self.assertIn(f"PVS_BASE_DRC_CLASS={expected_class}\n", text)
        return text, scope, tmp

    def test_clean_base_drc_can_continue(self) -> None:
        text, scope, tmp = self.run_case([], "CLEAN", 0)
        self.addCleanup(tmp.cleanup)
        self.assertIn("DECISION=PASS_CONTINUE_LVS\n", text)
        self.assertIn("MANAGER_ANTENNA_EXCEPTION=NOT_NEEDED\n", scope.read_text())

    def test_exact_antenna_rule_set_can_continue_with_exception(self) -> None:
        rows = [("R1M2P1", 6, 6), ("R1M3P1", 68, 68), ("R2M2P1", 7, 7), ("R2M3P1", 55, 55)]
        text, scope, tmp = self.run_case(rows, "ANTENNA_ONLY_MANAGER_EXCEPTION", 0)
        self.addCleanup(tmp.cleanup)
        self.assertIn("ANTENNA_REPAIR_ATTEMPTED=NO\n", text)
        self.assertIn("MANAGER_ANTENNA_EXCEPTION=YES\n", scope.read_text())

    def test_non_antenna_rule_stops_for_reviewed_eco(self) -> None:
        rows = [("M1.MIN.AREA", 1, 1)]
        text, scope, tmp = self.run_case(rows, "NON_ANTENNA_DRC", 10)
        self.addCleanup(tmp.cleanup)
        self.assertIn("FAIL_STOP_ONE_ATTRIBUTED_ROUTING_ECO_ELIGIBLE", text)
        self.assertFalse(scope.exists())

    def test_hash_drift_is_invalid_evidence(self) -> None:
        text, scope, tmp = self.run_case([( "R1M2P1", 1, 1)], "INVALID_EVIDENCE", 8, corrupt_hash=True)
        self.addCleanup(tmp.cleanup)
        self.assertIn("rule inventory hash mismatch", text)
        self.assertFalse(scope.exists())


if __name__ == "__main__":
    unittest.main()
