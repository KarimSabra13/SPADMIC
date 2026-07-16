#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
SCRIPT = REPO / "TOP" / "pnr" / "scripts" / "open_pvs_lvs_gui_review.sh"


class OpenPvsLvsGuiReviewTest(unittest.TestCase):
    def make_run(self, root: Path, *, status: str = "MATCH") -> Path:
        run = root / "immutable_lvs_run"
        (run / "svdb").mkdir(parents=True)
        (run / "pvs_lvs_status.rpt").write_text(
            "LABEL=SPADMIC_PVS_HANDOFF_RESULT\n"
            "MODE=LVS\n"
            "PVS_RC=0\n"
            f"PVS_LVS_STATUS={status}\n"
            f"EVIDENCE={run / 'svdb' / 'matched'}\n"
            "LVS_NEGATIVE_MATCH_COUNT=0\n"
            "LVS_POSITIVE_MATCH_COUNT=3\n"
        )
        (run / "replay_contract_status.rpt").write_text(
            "LABEL=SPADMIC_PVS_REPLAY_CONTRACT\n"
            "STATUS=PASS\n"
            "MODE=LVS\n"
        )
        (run / "output_isolation.rpt").write_text(
            "LABEL=SPADMIC_PVS_OUTPUT_ISOLATION\n"
            "STATUS=PASS\n"
            f"RUN_DIR={run}\n"
        )
        (run / "external_references.rpt").write_text(
            "LABEL=SPADMIC_PVS_EXTERNAL_REFERENCES\n"
            f"FILE={run / 'pvslvsctl'}|1|hash\n"
        )
        (run / "pvs_result_evidence_inventory.rpt").write_text(
            "LABEL=SPADMIC_PVS_RESULT_EVIDENCE_INVENTORY\n"
            f"RUN_DIR={run}\n"
            "SCANNED_TEXT_FILE_COUNT=3\n"
        )
        (run / "pvs_file.index").write_text(
            f'"Run Directory" internal none {run}\n'
            f'"Mask SVDB Directory" internal none {run / "svdb"}\n'
        )
        (run / ".preset.autosave").write_text(f'RunDir "{run}"\n')
        (run / "pvslvsctl").write_text(f'mask_svdb_dir "{run / "svdb"}";\n')
        (run / "svdb" / "matched").write_text("Circuits match\n")
        return run

    def test_prepare_only_creates_relocated_disposable_copy(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run = self.make_run(root)
            review_root = root / "reviews"
            result = subprocess.run(
                [
                    "bash",
                    str(SCRIPT),
                    "--run-dir",
                    str(run),
                    "--review-root",
                    str(review_root),
                    "--view",
                    "results",
                    "--prepare-only",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            review_line = next(
                line for line in result.stdout.splitlines()
                if line.startswith("GUI_REVIEW_DIR=")
            )
            review = Path(review_line.split("=", 1)[1])
            self.assertTrue(review.is_dir())
            self.assertIn(str(review), (review / "pvs_file.index").read_text())
            self.assertNotIn(str(run), (review / "pvs_file.index").read_text())
            self.assertIn(
                "SOURCE_RUN_MUTATION_AUTHORIZED=NO",
                (review / "gui_review_origin.rpt").read_text(),
            )
            self.assertIn(str(run), (run / "pvs_file.index").read_text())

    def test_nonmatch_is_rejected_before_copy(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run = self.make_run(root, status="MISMATCH")
            review_root = root / "reviews"
            result = subprocess.run(
                [
                    "bash",
                    str(SCRIPT),
                    "--run-dir",
                    str(run),
                    "--review-root",
                    str(review_root),
                    "--prepare-only",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("PVS LVS status is not MATCH", result.stderr)
            self.assertFalse(review_root.exists())


if __name__ == "__main__":
    unittest.main()
