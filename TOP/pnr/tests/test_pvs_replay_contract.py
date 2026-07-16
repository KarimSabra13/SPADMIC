#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
REPLAY = REPO / "TOP" / "pnr" / "scripts" / "replay_pvs_handoff_template.py"


class PvsReplayContractTest(unittest.TestCase):
    def make_template(self, root: Path, mode: str) -> tuple[Path, dict[str, str]]:
        template = root / "template"
        template.mkdir()
        old = {
            "gds": str(template / "old.gds"),
            "source": str(template / "old.pg.v"),
            "cdl": str(template / "old.cdl"),
            "layout_top": "old_layout_top",
            "source_top": "old_source_top",
        }
        historical_run = root / "historical_gui_run"
        historical_run.mkdir()
        (historical_run / "cell_tree.txt").write_text("old_layout_top\n")
        if mode == "lvs":
            run_mode = "-lvs"
            source_option = f" -source_top_cell {old['source_top']}"
            output_option = f" -spice {historical_run / 'old_layout.spi'}"
            control = "pvslvsctl"
        else:
            run_mode = "-drc"
            source_option = ""
            output_option = ""
            control = "pvsdrcctl"
        (template / "run.pvs").write_text(
            "#!/bin/sh\n"
            "pwd_d=`pwd`\n"
            f"cd {historical_run} ;\\\n"
            "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs "
            f"{run_mode} -top_cell {old['layout_top']}{source_option} "
            f"{output_option} "
            f"-control {historical_run / control} "
            f"-cell_tree {historical_run / 'cell_tree.txt'} "
            f"{historical_run / '.config.rul'} "
            f"{historical_run / '.technology.rul'}\n"
            "cd $pwd_d\n"
        )
        control_text = (
            f'layout_path "{old["gds"]}";\n'
            "#UNDEFINE DENSITY\n"
        )
        if mode == "lvs":
            control_text += (
                'lvs_report_file "old_layout_lvs.sum";\n'
                'report_summary -erc "old_layout_erc.sum" -replace;\n'
                f'results_db -erc "{historical_run / "old_layout_lvs.err"}" -ascii;\n'
                f'mask_svdb_dir "{historical_run / "svdb"}";\n'
                f'schematic_path "{old["source"]}" verilog;\n'
                f'schematic_path "{old["cdl"]}" spice;\n'
            )
        else:
            control_text += (
                'report_summary -drc "old_layout_drc.sum" -replace;\n'
                f'results_db -drc "{historical_run / "old_layout_drc.err"}" -ascii;\n'
            )
        (template / control).write_text(control_text)
        (template / "pipo1.setup").write_text(
            f'runDir\t"{historical_run}"\n'
            f'logFile\t"{historical_run / "PIPO1.LOG"}"\n'
            f'strmFile\t"{old["gds"]}"\n'
        )
        (template / ".config.rul").write_text("// config\n")
        (template / ".technology.rul").write_text(
            'technology "XH018_1131";\n'
            "//============================================================\n"
            "// Historical reference: /missing/comment-only/reference\n"
            "/* Retired reference: /missing/block-comment/reference */\n"
        )
        return template, old

    def run_replay(self, root: Path, mode: str, *, omit_cdl_replacement: bool = False, density: bool = False):
        template, old = self.make_template(root, mode)
        run_dir = root / "run"
        new_gds = root / "canonical.gds"
        new_source = root / "canonical.lvs.pg.v"
        new_cdl = root / "xh018_D_CELLS_JIHD.cdl"
        for path in (new_gds, new_source, new_cdl):
            path.write_text(path.name + "\n")
        command = [
            "python3", str(REPLAY), "--mode", mode,
            "--template", str(template), "--run-dir", str(run_dir),
            "--cadence-pvs", "/cadence/bin/pvs",
            "--replace", f"{old['gds']}={new_gds}",
            "--replace", f"{old['layout_top']}=canonical_top",
            "--expected-layout-top", "canonical_top",
            "--expected-gds", str(new_gds),
        ]
        if mode == "lvs":
            command.extend([
                "--replace", f"{old['source']}={new_source}",
                "--replace", f"{old['source_top']}=canonical_top",
                "--expected-source-top", "canonical_top",
                "--expected-source", str(new_source),
                "--expected-cdl", str(new_cdl),
            ])
            if not omit_cdl_replacement:
                command.extend(["--replace", f"{old['cdl']}={new_cdl}"])
        command.extend([
            "--preprocessor-define" if density else "--preprocessor-undefine",
            "DENSITY",
        ])
        result = subprocess.run(command, text=True, capture_output=True, check=False)
        return result, run_dir

    def test_lvs_replay_requires_and_records_all_canonical_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result, run_dir = self.run_replay(Path(tmp), "lvs")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("STATUS=PASS", (run_dir / "replay_contract_status.rpt").read_text())
            self.assertIn("canonical_top", (run_dir / "run.pvs").read_text())
            self.assertIn("canonical.lvs.pg.v", (run_dir / "pvslvsctl").read_text())
            self.assertIn("xh018_D_CELLS_JIHD.cdl", (run_dir / "pvslvsctl").read_text())
            self.assertIn("#UNDEFINE DENSITY", (run_dir / "pvslvsctl").read_text())

    def test_lvs_replay_fails_when_cdl_was_not_replaced(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result, _ = self.run_replay(Path(tmp), "lvs", omit_cdl_replacement=True)
            self.assertEqual(result.returncode, 1)
            self.assertIn("cdl_not_in_replay", result.stdout + result.stderr)

    def test_guessed_old_value_with_zero_occurrences_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            template, old = self.make_template(root, "drc")
            new_gds = root / "canonical.gds"
            new_gds.write_text("gds\n")
            result = subprocess.run(
                [
                    "python3", str(REPLAY), "--mode", "drc",
                    "--template", str(template), "--run-dir", str(root / "run"),
                    "--cadence-pvs", "/cadence/bin/pvs",
                    "--replace", f"{template / 'guessed.gds'}={new_gds}",
                    "--replace", f"{old['layout_top']}=canonical_top",
                    "--expected-layout-top", "canonical_top",
                    "--expected-gds", str(new_gds),
                    "--preprocessor-undefine", "DENSITY",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("REPLACEMENT_SOURCE_NOT_FOUND", result.stdout + result.stderr)

    def test_density_replay_defines_density_explicitly(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result, run_dir = self.run_replay(Path(tmp), "drc", density=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("#DEFINE DENSITY", (run_dir / "pvsdrcctl").read_text())
            self.assertIn("DEFINE=DENSITY|OCCURRENCES=1", (run_dir / "preprocessor_defines.rpt").read_text())

    def test_comment_separators_are_not_external_path_references(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result, run_dir = self.run_replay(Path(tmp), "drc")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            references = (run_dir / "external_references.rpt").read_text()
            self.assertNotIn("MISSING=//", references)
            self.assertNotIn("/missing/comment-only/reference", references)
            self.assertNotIn("/missing/block-comment/reference", references)
            self.assertIn(str(Path(tmp) / "canonical.gds"), references)

    def test_gui_execution_and_output_paths_are_relocated(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            result, run_dir = self.run_replay(root, "drc")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            historical = str(root / "historical_gui_run")
            run_text = (run_dir / "run.pvs").read_text()
            control_text = (run_dir / "pvsdrcctl").read_text()
            self.assertIn(f"cd {run_dir}", run_text)
            self.assertIn(f"-control {run_dir / 'pvsdrcctl'}", run_text)
            self.assertIn(str(run_dir / ".config.rul"), run_text)
            self.assertIn(str(run_dir / ".technology.rul"), run_text)
            self.assertIn(str(run_dir / "canonical_top_drc.sum"), control_text)
            self.assertIn(str(run_dir / "canonical_top_drc.err"), control_text)
            self.assertNotIn(historical, run_text)
            self.assertNotIn(historical, control_text)
            self.assertNotIn(
                historical,
                (run_dir / "external_references.rpt").read_text(),
            )
            isolation = (run_dir / "output_isolation.rpt").read_text()
            self.assertIn("STATUS=PASS", isolation)
            self.assertIn("DRC_SUMMARY_REWRITE_COUNT=1", isolation)
            replacements = (run_dir / "template_replacements.rpt").read_text()
            self.assertIn("COPIED_EXTERNAL_CELL_TREE=", replacements)

    def test_lvs_outputs_are_relocated_for_report_level_classification(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result, run_dir = self.run_replay(Path(tmp), "lvs")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            run_text = (run_dir / "run.pvs").read_text()
            control_text = (run_dir / "pvslvsctl").read_text()
            self.assertIn(str(run_dir / "canonical_top.spi"), run_text)
            for output in (
                run_dir / "canonical_top_lvs.sum",
                run_dir / "canonical_top_erc.sum",
                run_dir / "canonical_top_lvs.err",
                run_dir / "svdb",
            ):
                self.assertIn(str(output), control_text)


if __name__ == "__main__":
    unittest.main()
