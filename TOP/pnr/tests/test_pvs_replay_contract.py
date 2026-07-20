#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
REPLAY = REPO / "TOP" / "pnr" / "scripts" / "replay_pvs_handoff_template.py"


class PvsReplayContractTest(unittest.TestCase):
    def make_template(
        self,
        root: Path,
        mode: str,
        *,
        executable_cdl: bool = True,
        svdb_directory: bool = True,
        stale_same_basename_metadata_cdl: bool = False,
        unrelated_missing_metadata_cdl: bool = False,
        layout_top: str = "old_layout_top",
        historical_run_name: str = "historical_gui_run",
    ) -> tuple[Path, dict[str, str]]:
        template = root / "template"
        template.mkdir()
        old = {
            "gds": str(template / "old.gds"),
            "source": str(template / "old.pg.v"),
            "cdl": str(template / "old.cdl"),
            "layout_top": layout_top,
            "source_top": "old_source_top",
        }
        historical_run = root / historical_run_name
        historical_run.mkdir()
        (historical_run / "cell_tree.txt").write_text(f"{layout_top}\n")
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
            )
            if svdb_directory:
                control_text += (
                    f'mask_svdb_dir "{historical_run / "svdb"}";\n'
                )
            control_text += f'schematic_path "{old["source"]}" verilog;\n'
            if executable_cdl:
                control_text += f'schematic_path "{old["cdl"]}" spice;\n'
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
        metadata_cdl = old["cdl"]
        if stale_same_basename_metadata_cdl:
            metadata_cdl = str(
                root
                / "blocks"
                / old["source_top"]
                / "tx_packet_pvs_waiver"
                / "pdk"
                / "xh018_D_CELLS_JIHD.cdl"
            )
        preset_text = f'SchematicDFIIiCDLfile "{metadata_cdl}"\n'
        if unrelated_missing_metadata_cdl:
            preset_text += (
                f'UnrelatedCDL "{root / "missing" / "custom_analog.cdl"}"\n'
            )
        (template / ".preset.autosave").write_text(preset_text)
        return template, old

    def run_replay(
        self,
        root: Path,
        mode: str,
        *,
        executable_cdl: bool = True,
        svdb_directory: bool = True,
        stale_same_basename_metadata_cdl: bool = False,
        unrelated_missing_metadata_cdl: bool = False,
        omit_cdl_replacement: bool = False,
        density: bool = False,
        colliding_execution_root: bool = False,
    ):
        layout_top = "old_layout_top"
        template, old = self.make_template(
            root,
            mode,
            executable_cdl=executable_cdl,
            svdb_directory=svdb_directory,
            stale_same_basename_metadata_cdl=(
                stale_same_basename_metadata_cdl
            ),
            unrelated_missing_metadata_cdl=unrelated_missing_metadata_cdl,
            layout_top=layout_top,
            historical_run_name=(
                layout_top if colliding_execution_root else "historical_gui_run"
            ),
        )
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

    def test_lvs_replay_adds_missing_executable_cdl_input(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result, run_dir = self.run_replay(
                Path(tmp),
                "lvs",
                executable_cdl=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            control = (run_dir / "pvslvsctl").read_text()
            self.assertEqual(control.count("xh018_D_CELLS_JIHD.cdl"), 1)
            isolation = (run_dir / "output_isolation.rpt").read_text()
            self.assertIn("SCHEMATIC_CDL_ACTION=ADDED_MISSING", isolation)

    def test_lvs_replay_normalizes_same_basename_auxiliary_cdl_reference(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            result, run_dir = self.run_replay(
                root,
                "lvs",
                executable_cdl=False,
                stale_same_basename_metadata_cdl=True,
                omit_cdl_replacement=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            canonical_cdl = root / "xh018_D_CELLS_JIHD.cdl"
            preset = (run_dir / ".preset.autosave").read_text()
            self.assertIn(str(canonical_cdl), preset)
            self.assertNotIn("tx_packet_pvs_waiver", preset)
            references = (run_dir / "external_references.rpt").read_text()
            self.assertIn(f"FILE={canonical_cdl}|", references)
            self.assertNotIn("tx_packet_pvs_waiver", references)
            replacements = (run_dir / "template_replacements.rpt").read_text()
            self.assertIn("INFERRED_AUXILIARY_CDL_REFERENCE=", replacements)
            self.assertIn(f"NEW={canonical_cdl}|OCCURRENCES=1", replacements)

    def test_lvs_replay_keeps_unrelated_missing_cdl_reference_visible(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            unrelated = root / "missing" / "custom_analog.cdl"
            result, run_dir = self.run_replay(
                root,
                "lvs",
                unrelated_missing_metadata_cdl=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            references = (run_dir / "external_references.rpt").read_text()
            self.assertIn(f"MISSING={unrelated}", references)

    def test_lvs_replay_adds_missing_run_local_svdb_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result, run_dir = self.run_replay(
                Path(tmp),
                "lvs",
                svdb_directory=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            control = (run_dir / "pvslvsctl").read_text()
            self.assertEqual(control.count("mask_svdb_dir"), 1)
            self.assertIn(f'mask_svdb_dir "{run_dir / "svdb"}";', control)
            isolation = (run_dir / "output_isolation.rpt").read_text()
            self.assertIn(f"SVDB_DIRECTORY={run_dir / 'svdb'}", isolation)
            self.assertIn("SVDB_ACTION=ADDED_MISSING", isolation)
            self.assertIn("SVDB_REWRITE_COUNT=0", isolation)

    def test_lvs_replay_rejects_multiple_svdb_directories(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            template, old = self.make_template(root, "lvs")
            with (template / "pvslvsctl").open("a") as handle:
                handle.write(f'mask_svdb_dir "{root / "second_svdb"}";\n')
            new_gds = root / "canonical.gds"
            new_source = root / "canonical.lvs.pg.v"
            new_cdl = root / "xh018_D_CELLS_JIHD.cdl"
            for path in (new_gds, new_source, new_cdl):
                path.write_text(path.name + "\n")
            result = subprocess.run(
                [
                    "python3", str(REPLAY), "--mode", "lvs",
                    "--template", str(template), "--run-dir", str(root / "run"),
                    "--cadence-pvs", "/cadence/bin/pvs",
                    "--replace", f"{old['gds']}={new_gds}",
                    "--replace", f"{old['source']}={new_source}",
                    "--replace", f"{old['cdl']}={new_cdl}",
                    "--replace", f"{old['layout_top']}=canonical_top",
                    "--replace", f"{old['source_top']}=canonical_top",
                    "--expected-layout-top", "canonical_top",
                    "--expected-source-top", "canonical_top",
                    "--expected-gds", str(new_gds),
                    "--expected-source", str(new_source),
                    "--expected-cdl", str(new_cdl),
                    "--preprocessor-undefine", "DENSITY",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn(
                "multiple mask_svdb_dir directives",
                result.stdout + result.stderr,
            )

    def test_lvs_replay_rejects_multiple_executable_cdl_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            template, old = self.make_template(root, "lvs")
            with (template / "pvslvsctl").open("a") as handle:
                handle.write(f'schematic_path "{old["cdl"]}" spice;\n')
            new_gds = root / "canonical.gds"
            new_source = root / "canonical.lvs.pg.v"
            new_cdl = root / "xh018_D_CELLS_JIHD.cdl"
            for path in (new_gds, new_source, new_cdl):
                path.write_text(path.name + "\n")
            result = subprocess.run(
                [
                    "python3", str(REPLAY), "--mode", "lvs",
                    "--template", str(template), "--run-dir", str(root / "run"),
                    "--cadence-pvs", "/cadence/bin/pvs",
                    "--replace", f"{old['gds']}={new_gds}",
                    "--replace", f"{old['source']}={new_source}",
                    "--replace", f"{old['cdl']}={new_cdl}",
                    "--replace", f"{old['layout_top']}=canonical_top",
                    "--replace", f"{old['source_top']}=canonical_top",
                    "--expected-layout-top", "canonical_top",
                    "--expected-source-top", "canonical_top",
                    "--expected-gds", str(new_gds),
                    "--expected-source", str(new_source),
                    "--expected-cdl", str(new_cdl),
                    "--preprocessor-undefine", "DENSITY",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn(
                "multiple executable schematic_path spice",
                result.stdout + result.stderr,
            )

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

    def test_top_name_inside_execution_root_is_relocated_before_scalar_rewrite(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            result, run_dir = self.run_replay(
                root,
                "drc",
                colliding_execution_root=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            false_root = str(root / "canonical_top")
            old_root = str(root / "old_layout_top")
            for name in ("run.pvs", "pvsdrcctl", "pipo1.setup"):
                text = (run_dir / name).read_text()
                self.assertNotIn(false_root, text)
                self.assertNotIn(old_root, text)
            pipo = (run_dir / "pipo1.setup").read_text()
            self.assertIn(f'runDir\t"{run_dir}"', pipo)
            self.assertIn(f'logFile\t"{run_dir / "PIPO1.LOG"}"', pipo)
            references = (run_dir / "external_references.rpt").read_text()
            self.assertNotIn(false_root, references)
            self.assertNotIn(old_root, references)

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
