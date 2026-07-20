#!/usr/bin/env python3
"""Tests for the read-only PVS LVS control-scaffold audit."""

from __future__ import annotations

import hashlib
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
AUDIT = REPO / "TOP" / "pnr" / "scripts" / "audit_pvs_lvs_control_scaffold.py"
PVS_BIN = "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs"


class PvsLvsControlScaffoldAuditTests(unittest.TestCase):
    def make_template(
        self,
        root: Path,
        *,
        executable_cdl: bool = False,
        svdb_directory: bool = True,
    ) -> Path:
        template = root / "template"
        template.mkdir()
        old_run = root / "historical_gui_run"
        old_gds = root / "historical.gds"
        old_source = root / "historical.pg.v"
        old_cdl = root / "historical.cdl"
        (template / ".config.rul").write_text("")
        (template / ".preset.autosave").write_text(
            f'SchematicDFIIiCDLfile "{old_cdl}"\n'
        )
        (template / ".technology.rul").write_text('technology "XH018_1131";\n')
        (template / "pipo1.setup").write_text(f'runDir\t"{old_run}"\n')
        (template / "run.pvs").write_text(
            "#!/bin/sh -f\n"
            "pwd_d=`pwd`\n"
            f"cd {old_run} ;\\\n"
            f"{PVS_BIN} \\\n"
            "  -lvs \\\n"
            "  -top_cell historical_layout \\\n"
            "  -source_top_cell historical_source \\\n"
            f"  -spice {old_run / 'historical_layout.spi'} \\\n"
            f"  -control {old_run / 'pvslvsctl'} \\\n"
            f"  {old_run / '.config.rul'} \\\n"
            f"  {old_run / '.technology.rul'}\n"
            "cd $pwd_d\n"
        )
        control = (
            "text_depth -primary;\n"
            "lvs_ignore_ports no;\n"
            "lvs_expand_cell_on_error no;\n"
            'lvs_report_file "historical_lvs.sum";\n'
            "lvs_run_erc_checks yes;\n"
            'report_summary -erc "historical_erc.sum" -replace;\n'
            f'results_db -erc "{old_run / "historical_lvs.err"}" -ascii;\n'
        )
        if svdb_directory:
            control += f'mask_svdb_dir "{old_run / "svdb"}";\n'
        control += f'schematic_path "{old_source}" verilog;\n'
        if executable_cdl:
            control += f'schematic_path "{old_cdl}" spice;\n'
        control += (
            "abort_on_layout_error yes;\n"
            "layout_format gdsii;\n"
            f'layout_path "{old_gds}";\n'
            "#UNDEFINE DUMMY_FILL\n"
        )
        (template / "pvslvsctl").write_text(control)
        return template

    def run_audit(self, root: Path, template: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                "python3",
                str(AUDIT),
                "--template",
                str(template),
                "--output",
                str(root / "audit.rpt"),
                "--expected-pvs-bin",
                PVS_BIN,
            ],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_valid_historical_scaffold_passes_without_executable_cdl(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            template = self.make_template(root)
            before = {
                path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                for path in template.iterdir()
            }
            result = self.run_audit(root, template)
            report = (root / "audit.rpt").read_text()
            after = {
                path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                for path in template.iterdir()
            }

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(before, after)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("SOURCE_MUTATION_AUTHORIZED=NO", report)
            self.assertIn("TEMPLATE_LAYOUT_TOP=historical_layout", report)
            self.assertIn("TEMPLATE_SOURCE_TOP=historical_source", report)
            self.assertIn(f"TEMPLATE_GDS={root / 'historical.gds'}", report)
            self.assertIn(f"TEMPLATE_SOURCE={root / 'historical.pg.v'}", report)
            self.assertIn("TEMPLATE_EXECUTABLE_CDL=NONE", report)
            self.assertIn("ERROR_COUNT=0", report)

    def test_one_existing_executable_cdl_is_allowed(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            template = self.make_template(root, executable_cdl=True)
            result = self.run_audit(root, template)
            report = (root / "audit.rpt").read_text()

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn(f"TEMPLATE_EXECUTABLE_CDL={root / 'historical.cdl'}", report)
            self.assertIn("SCHEMATIC_SPICE_COUNT=1", report)

    def test_missing_svdb_directory_is_valid_input_for_replay_normalization(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            template = self.make_template(root, svdb_directory=False)
            result = self.run_audit(root, template)
            report = (root / "audit.rpt").read_text()

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("SVDB_DIRECTORY_COUNT=0", report)

    def test_duplicate_svdb_directories_fail(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            template = self.make_template(root)
            with (template / "pvslvsctl").open("a") as handle:
                handle.write(f'mask_svdb_dir "{root / "second_svdb"}";\n')
            result = self.run_audit(root, template)
            report = (root / "audit.rpt").read_text()

            self.assertEqual(result.returncode, 1)
            self.assertIn("ERROR=svdb_directory_count=2", report)

    def test_duplicate_verilog_source_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            template = self.make_template(root)
            with (template / "pvslvsctl").open("a") as handle:
                handle.write(f'schematic_path "{root / "second.v"}" verilog;\n')
            result = self.run_audit(root, template)
            report = (root / "audit.rpt").read_text()

            self.assertEqual(result.returncode, 1)
            self.assertIn("STATUS=FAIL", report)
            self.assertIn("ERROR=schematic_verilog_count=2", report)

    def test_unsafe_port_policy_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            template = self.make_template(root)
            control = template / "pvslvsctl"
            control.write_text(control.read_text().replace(
                "lvs_ignore_ports no;",
                "lvs_ignore_ports yes;",
            ))
            result = self.run_audit(root, template)
            report = (root / "audit.rpt").read_text()

            self.assertEqual(result.returncode, 1)
            self.assertIn("ERROR=lvs_ignore_ports_no_count=0", report)

    def test_drc_mode_in_lvs_launcher_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            template = self.make_template(root)
            run_file = template / "run.pvs"
            run_file.write_text(run_file.read_text().replace("  -lvs", "  -drc"))
            result = self.run_audit(root, template)
            report = (root / "audit.rpt").read_text()

            self.assertEqual(result.returncode, 1)
            self.assertIn("ERROR=lvs_mode_count=0", report)
            self.assertIn("ERROR=drc_mode_count=1", report)


if __name__ == "__main__":
    unittest.main()
