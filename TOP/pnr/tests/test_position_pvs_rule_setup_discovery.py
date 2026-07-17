#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
COLLECTOR = REPO / "TOP" / "pnr" / "scripts" / "collect_position_pvs_rule_setup.py"
WRAPPER = REPO / "TOP" / "ci" / "server_discover_position_core_pvs_rule_setup.sh"
PREPROCESSOR_WRAPPER = (
    REPO / "TOP" / "ci" / "server_review_position_core_pvs_drc_preprocessor.sh"
)


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class PositionPvsRuleSetupDiscoveryTest(unittest.TestCase):
    def build_fixture(self, root: Path, mapping: str = ".pvsSetup/PVS") -> tuple[Path, Path]:
        project = root / "cds_V0"
        setup = project / ".pvsSetup" / "PVS"
        pdk = project / ".xkit" / "setup" / "xh018" / "cadence" / "pvs" / "PVS"
        setup.mkdir(parents=True)
        pdk.mkdir(parents=True)

        techlib = project / "pvtech.lib"
        techlib.write_text(
            f"UNDEFINE XH018_1131\nDEFINE XH018_1131 {mapping}\n"
        )
        (setup / "default.rul").write_text(
            "INCLUDE ../../.xkit/setup/xh018/cadence/pvs/PVS/xh018_DRC.rul\n"
        )
        (pdk / "xh018_DRC.rul").write_text(
            "#IFDEF POPPING\n"
            "#IFDEF PIMIDE\n"
            "#IFDEF DUMMY_FILL\n"
            "#IFDEF VAR_ANT_RATIO\n"
            "#IFDEF DENSITY\n"
        )

        matrix = root / "candidate_directive_matrix.tsv"
        lines = [
            "candidate\tDENSITY\tPOPPING\tPIMIDE\tDUMMY_FILL\tVAR_ANT_RATIO"
        ]
        for index in range(114):
            var_state = "DEFINED" if index < 3 else "UNDEFINED"
            lines.append(
                f"candidate_{index:03d}\tUNDEFINED\tUNDEFINED\tUNDEFINED\t"
                f"UNDEFINED\t{var_state}"
            )
        matrix.write_text("\n".join(lines) + "\n")
        return techlib, matrix

    def test_collector_resolves_relative_mapping_and_preserves_sources(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            techlib, matrix = self.build_fixture(root)
            output = root / "output"
            before = (file_sha(techlib), file_sha(matrix))

            result = subprocess.run(
                [
                    "python3",
                    str(COLLECTOR),
                    "--techlib",
                    str(techlib),
                    "--candidate-matrix",
                    str(matrix),
                    "--output-dir",
                    str(output),
                ],
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(before, (file_sha(techlib), file_sha(matrix)))
            mapping = (output / "pvtech_mapping_resolution.rpt").read_text()
            self.assertIn("MAPPING_RAW=.pvsSetup/PVS", mapping)
            self.assertIn(f"MAPPING_LEXICAL={techlib.parent / '.pvsSetup/PVS'}", mapping)
            self.assertNotIn("MAPPING_RAW=/PVS", mapping)

            status = (output / "rule_setup_collector_status.rpt").read_text()
            self.assertIn("COLLECTOR_STATUS=PASS", status)
            self.assertIn("MATRIX_CANDIDATE_COUNT=114", status)
            self.assertIn("VAR_ANT_DEFINED_CANDIDATE_COUNT=3", status)
            self.assertIn("PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED", status)
            self.assertIn("PVS_EXECUTED=NO", status)

            candidates = (output / "var_ant_defined_candidates.tsv").read_text()
            self.assertEqual(candidates.count("\n"), 4)
            context = (output / "directive_context_excerpt.rpt").read_text()
            for symbol in ("DENSITY", "POPPING", "PIMIDE", "DUMMY_FILL", "VAR_ANT_RATIO"):
                self.assertIn(symbol, context)

    def test_collector_fails_closed_on_unexpected_mapping(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            techlib, matrix = self.build_fixture(root, mapping="unexpected/PVS")
            output = root / "output"
            result = subprocess.run(
                [
                    "python3",
                    str(COLLECTOR),
                    "--techlib",
                    str(techlib),
                    "--candidate-matrix",
                    str(matrix),
                    "--output-dir",
                    str(output),
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            status = (output / "rule_setup_collector_status.rpt").read_text()
            self.assertIn("COLLECTOR_STATUS=FAIL", status)
            self.assertIn("MAPPING_GATE_STATUS=FAIL", status)
            self.assertIn("STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO", status)

    def test_server_wrapper_is_interactive_safe_and_never_runs_pvs(self) -> None:
        text = WRAPPER.read_text()
        self.assertIn("set +e", text)
        self.assertNotRegex(text, re.compile(r"^\s*set\s+-e", re.MULTILINE))
        self.assertNotRegex(text, re.compile(r"^\s*exit(?:\s|$)", re.MULTILINE))
        self.assertNotIn("run_pvs_drc_handoff.sh", text)
        self.assertNotIn("replay_pvs_handoff_template.py", text)
        self.assertIn("collect_position_pvs_rule_setup.py", text)
        self.assertIn("ba8d72355f691f0877a26d28b91de7c18c6a7f3c95c4a75bec76cd23430823c7", text)
        self.assertIn('echo "PVS_EXECUTED=NO"', text)

    def test_shell_wrappers_have_valid_bash_syntax(self) -> None:
        for script in (WRAPPER, PREPROCESSOR_WRAPPER):
            result = subprocess.run(
                ["bash", "-n", str(script)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_preprocessor_reference_parser_preserves_relative_token(self) -> None:
        text = PREPROCESSOR_WRAPPER.read_text()
        self.assertIn('print "REFERENCE_RAW=" $3', text)
        self.assertIn("grep -Ec '^REFERENCE_RAW='", text)
        self.assertNotIn("grep -Eo '/[^\"[:space:];]+'", text)


if __name__ == "__main__":
    unittest.main()
