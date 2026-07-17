#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
COLLECTOR = REPO / "TOP" / "pnr" / "scripts" / "collect_position_pvs_rule_semantics.py"
WRAPPER = REPO / "TOP" / "ci" / "server_review_position_core_pvs_drc_rule_semantics.sh"


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class PositionPvsRuleSemanticsReviewTest(unittest.TestCase):
    def build_fixture(self, root: Path) -> dict[str, Path]:
        project_rules = root / "project" / ".pvsSetup" / "PVS" / "techRuleSets"
        pdk_root = root / "pdk" / "PVS"
        pdk_rules = pdk_root / "XH018_1131" / "techRuleSets"
        metalswitch = pdk_root / "XH018_1131" / "xh018_1131"
        revision = pdk_root / "PVS.revision"
        drc_rule = pdk_root / "xh018_DRC.rul"
        pvs_config = pdk_root / "pvs.cfg"
        dummy_config = pdk_root / "dummy.cfg"
        dummy_output = pdk_root / "dummy_out.pvl"
        density_selector = pdk_root / "density.pvl"

        project_rules.parent.mkdir(parents=True)
        pdk_rules.parent.mkdir(parents=True)
        project_rules.write_text(
            '(RuleSet "default"\n'
            '  (DrcRules "metalswitch.pvl" "../xh018_DRC.rul")\n'
            '  (LvsRules "metalswitch.pvl" "../xh018_LVS.rul"))\n'
        )
        pdk_rules.write_text(
            '(RuleSet "default"\n'
            '  (DrcRules "metalswitch.pvl" "../xh018_DRC.rul"))\n'
            '(RuleSet "dummy"\n'
            '  (DrcRules "metalswitch.pvl" "../xh018_DRC.rul" "../dummy_out.pvl"))\n'
        )
        metalswitch.write_text("#DEFINE METAL_STACK_1131\n")
        revision.write_text("PVS_VERSION=fixture\n")
        drc_rule.write_text(
            "#IFDEF DUMMY_FILL\n"
            "copy bulk -outputlayer dummy_fill_area\n"
            "#ENDIF\n"
            "#IFNDEF DUMMY_FILL\n"
            "copy empty -outputlayer dummy_output\n"
            "#ENDIF\n"
            "#IFDEF PIMIDE\n"
            'rule "B1PAPM" {\n'
            'caption "PAD without PIMIDE marker is not allowed"\n'
            "}\n"
            "#ELSE\n"
            "copy empty -outputlayer pad_nopimide\n"
            "#ENDIF\n"
            "#IFDEF POPPING\n"
            '// IMD Popping Checks\n'
            'rule "POPPING1" {\n'
            'caption "Popping check"\n'
            "}\n"
            "#ENDIF\n"
            "#IFDEF VAR_ANT_RATIO\n"
            'VARIABLE VAR_R2P1 "200"\n'
            'rule "R2P1_VAR" {\n'
            'caption "Variable ratio antenna"\n'
            "}\n"
            "#ENDIF\n"
            "#IFDEF DENSITY\n"
            'rule "R1M1" {\n'
            'caption "Minimum density"\n'
            "}\n"
            "#ENDIF\n"
        )
        pvs_config.write_text(
            "\n".join(
                f'configoption -option {symbol} -default "0"'
                for symbol in ("DENSITY", "POPPING", "PIMIDE", "DUMMY_FILL", "VAR_ANT_RATIO")
            )
            + "\n"
        )
        dummy_config.write_text('configoption -option DUMMY_FILL -default "1"\n')
        dummy_output.write_text("#ifdef DUMMY_FILL\noutput -drc dummy\n#endif\n")
        density_selector.write_text("#DEFINE DENSITY\n")

        return {
            "project_rules": project_rules,
            "pdk_rules": pdk_rules,
            "metalswitch": metalswitch,
            "revision": revision,
            "drc_rule": drc_rule,
            "pvs_config": pvs_config,
            "dummy_config": dummy_config,
            "dummy_output": dummy_output,
            "density_selector": density_selector,
            "user_guide": pdk_root / "doc" / "UserGuide.pdf",
        }

    def command(self, paths: dict[str, Path], output: Path) -> list[str]:
        return [
            "python3",
            str(COLLECTOR),
            "--project-techrulesets",
            str(paths["project_rules"]),
            "--pdk-techrulesets",
            str(paths["pdk_rules"]),
            "--metalswitch",
            str(paths["metalswitch"]),
            "--revision",
            str(paths["revision"]),
            "--drc-rule",
            str(paths["drc_rule"]),
            "--pvs-config",
            str(paths["pvs_config"]),
            "--dummy-config",
            str(paths["dummy_config"]),
            "--dummy-output",
            str(paths["dummy_output"]),
            "--density-selector",
            str(paths["density_selector"]),
            "--user-guide",
            str(paths["user_guide"]),
            "--output-dir",
            str(output),
            "--expected-drc-sha",
            file_sha(paths["drc_rule"]),
            "--expected-pvs-config-sha",
            file_sha(paths["pvs_config"]),
            "--expected-dummy-config-sha",
            file_sha(paths["dummy_config"]),
            "--expected-dummy-output-sha",
            file_sha(paths["dummy_output"]),
            "--expected-density-selector-sha",
            file_sha(paths["density_selector"]),
        ]

    def test_collector_records_complete_structured_evidence_without_source_changes(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            paths = self.build_fixture(root)
            output = root / "output"
            before = {name: file_sha(path) for name, path in paths.items() if path.is_file()}

            result = subprocess.run(
                self.command(paths, output),
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            after = {name: file_sha(path) for name, path in paths.items() if path.is_file()}
            self.assertEqual(before, after)

            status = (output / "rule_semantics_collector_status.rpt").read_text()
            self.assertIn("COLLECTOR_STATUS=PASS", status)
            self.assertIn("DEFAULT_RULE_SET_EVIDENCE_STATUS=PASS", status)
            self.assertIn("PVS_CONFIG_OPTION_DEFAULT_GATE_STATUS=PASS", status)
            self.assertIn("DIRECTIVE_CONDITIONAL_BLOCK_GATE_STATUS=PASS", status)
            self.assertIn("STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO", status)
            self.assertIn("PVS_EXECUTED=NO", status)

            named = (output / "named_rule_sets_numbered.rpt").read_text()
            self.assertIn('RuleSet "default"', named)
            self.assertIn("DrcRules", named)

            summary = (output / "directive_conditional_block_summary.tsv").read_text()
            for symbol in ("DENSITY", "POPPING", "PIMIDE", "DUMMY_FILL", "VAR_ANT_RATIO"):
                self.assertRegex(summary, rf"(?m)^{symbol}\t")
            context = (output / "directive_conditional_block_context.rpt").read_text()
            self.assertIn('caption "PAD without PIMIDE marker is not allowed"', context)
            self.assertIn('caption "Variable ratio antenna"', context)

            guide = (output / "user_guide_semantic_scan.rpt").read_text()
            self.assertIn("USER_GUIDE_TEXT_STATUS=NOT_PRESENT", guide)

    def test_collector_fails_closed_on_pinned_deck_hash_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            paths = self.build_fixture(root)
            output = root / "output"
            command = self.command(paths, output)
            index = command.index("--expected-drc-sha") + 1
            command[index] = "0" * 64

            result = subprocess.run(
                command,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertNotEqual(result.returncode, 0)
            status = (output / "rule_semantics_collector_status.rpt").read_text()
            self.assertIn("COLLECTOR_STATUS=FAIL", status)
            self.assertIn("KNOWN_SOURCE_HASH_GATE_STATUS=FAIL", status)
            self.assertIn("PVS_EXECUTED=NO", status)

    def test_server_wrapper_is_interactive_safe_and_never_runs_pvs(self) -> None:
        text = WRAPPER.read_text()
        self.assertIn("set +e", text)
        self.assertNotRegex(text, re.compile(r"^\s*set\s+-e", re.MULTILINE))
        self.assertNotRegex(text, re.compile(r"^\s*exit(?:\s|$)", re.MULTILINE))
        self.assertNotIn("run_pvs_drc_handoff.sh", text)
        self.assertNotIn("replay_pvs_handoff_template.py", text)
        self.assertIn("collect_position_pvs_rule_semantics.py", text)
        self.assertIn("b54eb78f97839ddfc0b782576e04ecc64d2f327a4cd0c7c43764d8d1a6b95f04", text)
        self.assertIn("0b1ce563da515dd50d17a5e16baa2a2addc10354aa06ab5e1a111b01ed039cb6", text)
        self.assertIn('echo "PVS_EXECUTED=NO"', text)

    def test_server_wrapper_has_valid_bash_syntax(self) -> None:
        result = subprocess.run(
            ["bash", "-n", str(WRAPPER)],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
