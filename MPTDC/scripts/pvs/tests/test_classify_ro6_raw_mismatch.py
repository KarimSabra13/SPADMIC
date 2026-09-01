#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


class RawMismatchClassifierTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo = Path(__file__).resolve().parents[4]
        cls.classifier = cls.repo / "MPTDC/scripts/pvs/15_classify_ro6_raw_mismatch.py"
        cls.raw_cls = (
            cls.repo
            / "MPTDC/docs/server_snapshots/pvs"
            / "20260901_181712_mptdc_v13_pg15_compositional_pvs_04_lvs"
            / "pvs_lvs"
            / "mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script"
            / "mptdc_axis_core_lvs.sum.cls"
        )

    def run_classifier(self, raw_cls: Path, report: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(self.classifier), "--cls", str(raw_cls), "--out", str(report)],
            check=False,
            text=True,
            capture_output=True,
        )

    def test_exact_published_two_ro_mismatch_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            report = Path(temp_dir) / "classification.rpt"
            result = self.run_classifier(self.raw_cls, report)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            values = report.read_text(encoding="utf-8")
            self.assertIn("STATUS=PASS\n", values)
            self.assertIn("MISMATCH_ATTRIBUTION=EXACT_TWO_RO6_INTERNALS_ONLY\n", values)
            self.assertIn("DIRECT_MONOLITHIC_ELIGIBLE=YES\n", values)
            self.assertIn("HIERARCHICAL_COMPOSITION_ELIGIBLE=YES\n", values)
            self.assertIn("SOURCE_ONLY_INSTANCE_COUNT=2\n", values)
            self.assertIn("LAYOUT_ONLY_INSTANCE_COUNT=380\n", values)
            self.assertIn("RO_LAYOUT_ROOT_SIGNATURE=X0/X0:190,X3/X5127:190\n", values)
            self.assertIn("RO_LAYOUT_CLUSTER_COUNT=2\n", values)

    def test_device_signature_drift_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            mutated = temp / "mutated.cls"
            text = self.raw_cls.read_text(encoding="utf-8")
            mutated.write_text(
                text.replace("Layout Model: MP(PELI)", "Layout Model: MP(PEI)", 1),
                encoding="utf-8",
            )
            report = temp / "classification.rpt"
            result = self.run_classifier(mutated, report)
            self.assertEqual(result.returncode, 10)
            values = report.read_text(encoding="utf-8")
            self.assertIn("STATUS=FAIL\n", values)
            self.assertIn("MISMATCH_ATTRIBUTION=REJECTED\n", values)
            self.assertIn("DIRECT_MONOLITHIC_ELIGIBLE=NO\n", values)
            self.assertIn("HIERARCHICAL_COMPOSITION_ELIGIBLE=NO\n", values)


if __name__ == "__main__":
    unittest.main()
