#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "12_classify_mptdc_density_delta.py"


class DensityDeltaClassifierTest(unittest.TestCase):
    def write_evidence(
        self, root: Path, variant: str, rows: list[tuple[str, int, int]], layout: str = "abc123"
    ) -> tuple[Path, Path]:
        rules = root / f"{variant.lower()}_rules.tsv"
        rules.write_text(
            "rule\tprimary\texpanded\n"
            + "".join(f"{name}\t{primary}\t{expanded}\n" for name, primary, expanded in rows)
        )
        status = root / f"{variant.lower()}_status.rpt"
        raw = "PASS" if not rows else "FAIL"
        status.write_text(
            f"STATUS={raw}\n"
            f"PVS_DRC_STATUS={raw}\n"
            f"PVS_DRC_VARIANT={variant}\n"
            "PVS_RC=0\n"
            f"DRC_TOTAL_PRIMARY={sum(row[1] for row in rows)}\n"
            f"DRC_TOTAL_EXPANDED={sum(row[2] for row in rows)}\n"
            f"NONZERO_RULE_COUNT={len(rows)}\n"
            f"NONZERO_RULE_REPORT={rules.resolve()}\n"
            f"NONZERO_RULE_REPORT_SHA256={hashlib.sha256(rules.read_bytes()).hexdigest()}\n"
            f"LAYOUT_INPUT_SHA256={layout}\n"
        )
        return status, rules

    def run_case(
        self,
        base_rows: list[tuple[str, int, int]],
        density_rows: list[tuple[str, int, int]],
        expected_rc: int,
        density_layout: str = "abc123",
    ) -> str:
        with tempfile.TemporaryDirectory(prefix="mptdc_density_delta_") as tmp:
            root = Path(tmp)
            base_status, base_rules = self.write_evidence(root, "BASE", base_rows)
            density_status, density_rules = self.write_evidence(
                root, "DENSITY", density_rows, density_layout
            )
            out = root / "classification.rpt"
            completed = subprocess.run(
                [
                    "python3",
                    str(SCRIPT),
                    "--base-status",
                    str(base_status),
                    "--base-rules",
                    str(base_rules),
                    "--density-status",
                    str(density_status),
                    "--density-rules",
                    str(density_rules),
                    "--out",
                    str(out),
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
            )
            self.assertEqual(completed.returncode, expected_rc, completed.stdout)
            return out.read_text()

    def test_antenna_only_density_is_non_antenna_clean(self) -> None:
        antenna = [("R1M2P1", 6, 6), ("R2M3P1", 55, 55)]
        text = self.run_case(antenna, antenna, 0)
        self.assertIn("PVS_DRC_DENSITY_NON_ANTENNA_STATUS=PASS\n", text)
        self.assertIn("DENSITY_NON_ANTENNA_RULE_COUNT=0\n", text)

    def test_density_debt_is_attributed(self) -> None:
        antenna = [("R1M2P1", 6, 6)]
        text = self.run_case(antenna, antenna + [("DENSITY.M1", 3, 3)], 10)
        self.assertIn("DENSITY_CLASSIFICATION_STATUS=FAIL\n", text)
        self.assertIn("DENSITY_NON_ANTENNA_RULE_SET=DENSITY.M1\n", text)

    def test_antenna_signature_drift_is_invalid(self) -> None:
        text = self.run_case([("R1M2P1", 6, 6)], [("R1M2P1", 7, 7)], 8)
        self.assertIn("density antenna signature drift", text)

    def test_layout_drift_is_invalid(self) -> None:
        antenna = [("R1M2P1", 6, 6)]
        text = self.run_case(antenna, antenna, 8, density_layout="different")
        self.assertIn("different layout hashes", text)


if __name__ == "__main__":
    unittest.main()
