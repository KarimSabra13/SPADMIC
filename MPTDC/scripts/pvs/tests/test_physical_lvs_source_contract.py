#!/usr/bin/env python3
"""Focused tests for the physical PVS LVS source contract."""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "01_generate_lvs_source_pg_filtered.py"


PHYSICAL_NETLIST = r"""
// module COMMENTED_OUT (A); endmodule
/* module ALSO_COMMENTED_OUT (A);
   endmodule */
module BUJIHDX1 (A, Y, VDD, VSS);
  input A;
  output Y;
  inout VDD, VSS;
endmodule

module LOGIC1DJIHD (Y, VDD, VSS);
  output Y;
  inout VDD, VSS;
endmodule

module FEED1JIHD (VDD, VSS);
  inout VDD, VSS;
endmodule

module FEED2JIHD (VDD, VSS);
  inout VDD, VSS;
endmodule

module helper (A, Y);
  input A;
  output Y;
endmodule

module RO_tune6 (VDD, VSS, rstb, code, S);
  inout VDD, VSS, rstb;
  inout [7:0] code, S;
endmodule

module mptdc_axis_core;
  wire VDD, VSS, rstb, tie1;
  wire [7:0] code_fast, code_slow, phase_fast, phase_slow;
  LOGIC1DJIHD u_tie1 ( .Y(tie1), .VDD(VDD), .VSS(VSS) );
  FEED1JIHD MPTDC_FILL_0 ( .VDD(VDD), .VSS(VSS) );
  FEED1JIHD MPTDC_FILL_1 ( .VDD(VDD), .VSS(VSS) );
  FEED2JIHD MPTDC_FILL_2 ( .VDD(VDD), .VSS(VSS) );
  BUJIHDX1 u_buf ( .A(tie1), .Y(rstb), .VDD(VDD), .VSS(VSS) );
  helper u_helper ( .A(tie1), .Y() );
  RO_tune6 u_core_u_osc_fast_u_ro_tune4 (
    .VDD(VDD), .VSS(VSS), .rstb(rstb),
    .code(code_fast[7:0]), .S(phase_fast)
  );
  RO_tune6 u_core_u_osc_slow_u_ro_tune4 (
    .VDD(VDD), .VSS(VSS), .rstb(rstb),
    .code(code_slow),
    .S({phase_slow[7], phase_slow[6], phase_slow[5], phase_slow[4],
        phase_slow[3], phase_slow[2], phase_slow[1], phase_slow[0]})
  );
endmodule
"""


class PhysicalLvsSourceContractTest(unittest.TestCase):
    def run_contract(
        self,
        source: str = PHYSICAL_NETLIST,
        filler_count: int = 3,
        row_fillers: str = "FEED1JIHD FEED2JIHD",
    ) -> tuple[subprocess.CompletedProcess[str], Path, Path, Path, tempfile.TemporaryDirectory[str]]:
        temp = tempfile.TemporaryDirectory(prefix="mptdc_lvs_source_contract.")
        root = Path(temp.name)
        input_path = root / "mptdc_axis_core_pnr_lvs_phys_with_pg.v"
        output_path = root / "source.v"
        hcell_path = root / "pvs_hcell_ro6.txt"
        report_path = root / "source_contract.rpt"
        cdl_path = root / "cells.cdl"
        filler_report = root / "filler_status.rpt"
        row_infra_report = root / "row_infra_insertion.rpt"
        input_path.write_text(source)
        cdl_path.write_text(
            ".SUBCKT BUJIHDX1 A Y VDD VSS\n.ENDS BUJIHDX1\n"
            ".SUBCKT LOGIC1DJIHD Y VDD VSS\n.ENDS LOGIC1DJIHD\n"
            ".SUBCKT FEED1JIHD VDD VSS\n.ENDS FEED1JIHD\n"
            ".SUBCKT FEED2JIHD VDD VSS\n.ENDS FEED2JIHD\n"
        )
        filler_report.write_text(
            "FILLER_CANDIDATES=FEED1JIHD FEED2JIHD\n"
            f"FILLER_COUNT={filler_count}\n"
            "FILLER_INSERTION_STATUS=PASS\n"
            "POST_FILLER_ROUTE_COMMAND_PHASE=PRE_SROUTE\n"
            "POST_FILLER_ROUTE_COMMAND_PHASE=POST_SROUTE\n"
        )
        row_infra_report.write_text(
            f"FILLER_CANDIDATES={row_fillers}\n"
            "TIE_HIGH_CANDIDATES=LOGIC1DJIHD\n"
            "TIE_LOW_CANDIDATES=LOGIC0DJIHD\n"
        )
        result = subprocess.run(
            [
                str(SCRIPT),
                "--input", str(input_path),
                "--output", str(output_path),
                "--hcell", str(hcell_path),
                "--report", str(report_path),
                "--cdl", str(cdl_path),
                "--filler-report", str(filler_report),
                "--row-infra-report", str(row_infra_report),
                "--expected-ro-instance", "u_core_u_osc_fast_u_ro_tune4",
                "--expected-ro-instance", "u_core_u_osc_slow_u_ro_tune4",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return result, output_path, hcell_path, report_path, temp

    def test_exact_cdl_filter_and_scalar_ro_contract(self) -> None:
        result, output_path, hcell_path, report_path, temp = self.run_contract()
        self.addCleanup(temp.cleanup)
        self.assertEqual(result.returncode, 0, result.stdout)
        output = output_path.read_text()
        report = report_path.read_text()

        self.assertNotIn("module BUJIHDX1", output)
        self.assertNotIn("module TIE1JIHDX1", output)
        self.assertIn("module helper", output)
        self.assertIn("LOGIC1DJIHD u_tie1", output)
        self.assertNotIn("MPTDC_FILL_0", output)
        self.assertNotIn("MPTDC_FILL_1", output)
        self.assertNotIn("MPTDC_FILL_2", output)
        self.assertEqual(output.count("RO_tune6 u_"), 2)
        self.assertIn(r".\code<0> (code_fast[0])", output)
        self.assertIn(r".\S<7> (phase_slow[7])", output)
        self.assertIn(r"module RO_tune6 (VDD, VSS, rstb, \code<0> ", output)
        self.assertNotIn("inout [7:0] code", output)
        self.assertEqual(hcell_path.read_text(), "RO_tune6 RO_tune6\n")
        self.assertIn("LVS_SOURCE_CONTRACT_STATUS=PASS", report)
        self.assertIn("MODULE_REMOVAL_POLICY=EXACT_CANONICAL_CDL_MEMBERSHIP", report)
        self.assertIn(
            "PHYSICAL_ONLY_INSTANCE_REMOVAL_POLICY=EXACT_TRACKED_FILLER_REPORT_MASTER_SET",
            report,
        )
        self.assertIn("PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_EXPECTED=3", report)
        self.assertIn("PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_INPUT=3", report)
        self.assertIn("PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_REMOVED=3", report)
        self.assertIn("PHYSICAL_ONLY_FILLER_REMOVAL_STATUS=PASS", report)
        self.assertIn("RO6_PIN_NORMALIZATION=EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS", report)
        self.assertIn("PHYSICAL_TIE_INSTANCE_COUNT=1", report)
        self.assertIn("PHYSICAL_TIE_MASTER=LOGIC1DJIHD:1", report)
        self.assertIn("PHYSICAL_TIE_PRESERVATION_STATUS=PASS", report)
        self.assertIn("UNRESOLVED_ACTIVE_MASTER_COUNT=0", report)

    def test_unresolved_master_fails_closed(self) -> None:
        source = PHYSICAL_NETLIST.replace(
            "helper u_helper ( .A(tie1), .Y() );",
            "UNKNOWN_PHYSICAL_CELL u_unknown ( .A(tie1), .Y() );",
        )
        result, output_path, _hcell_path, report_path, temp = self.run_contract(source)
        self.addCleanup(temp.cleanup)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(output_path.exists())
        self.assertIn("LVS_SOURCE_CONTRACT_STATUS=FAIL", report_path.read_text())
        self.assertIn("UNKNOWN_PHYSICAL_CELL", report_path.read_text())

    def test_positional_ro_instance_fails_closed(self) -> None:
        source = PHYSICAL_NETLIST.replace(
            "RO_tune6 u_core_u_osc_fast_u_ro_tune4 (\n    .VDD(VDD), .VSS(VSS), .rstb(rstb),\n    .code(code_fast[7:0]), .S(phase_fast)\n  );",
            "RO_tune6 u_core_u_osc_fast_u_ro_tune4 (VDD, VSS, rstb, code_fast, phase_fast);",
        )
        result, output_path, _hcell_path, report_path, temp = self.run_contract(source)
        self.addCleanup(temp.cleanup)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(output_path.exists())
        self.assertIn("positional connections are not accepted", report_path.read_text())

    def test_wrong_ro_instance_name_fails_closed(self) -> None:
        source = PHYSICAL_NETLIST.replace(
            "RO_tune6 u_core_u_osc_fast_u_ro_tune4", "RO_tune6 u_other"
        )
        result, output_path, _hcell_path, report_path, temp = self.run_contract(source)
        self.addCleanup(temp.cleanup)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(output_path.exists())
        self.assertIn("instance-name contract mismatch", report_path.read_text())

    def test_tracked_filler_count_mismatch_fails_closed(self) -> None:
        result, output_path, _hcell_path, report_path, temp = self.run_contract(
            filler_count=4
        )
        self.addCleanup(temp.cleanup)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(output_path.exists())
        self.assertIn("filler count does not match tracked report", report_path.read_text())

    def test_row_and_filler_master_sets_must_match(self) -> None:
        result, output_path, _hcell_path, report_path, temp = self.run_contract(
            row_fillers="FEED2JIHD FEED1JIHD"
        )
        self.addCleanup(temp.cleanup)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(output_path.exists())
        self.assertIn("candidate contract differs", report_path.read_text())

    def test_zero_observed_tie_instances_is_an_explicit_valid_count(self) -> None:
        source = PHYSICAL_NETLIST.replace(
            "  LOGIC1DJIHD u_tie1 ( .Y(tie1), .VDD(VDD), .VSS(VSS) );\n",
            "",
        )
        result, output_path, _hcell_path, report_path, temp = self.run_contract(
            source=source
        )
        self.addCleanup(temp.cleanup)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue(output_path.exists())
        report = report_path.read_text()
        self.assertIn("PHYSICAL_TIE_MASTER_COUNT=0", report)
        self.assertIn("PHYSICAL_TIE_INSTANCE_COUNT=0", report)
        self.assertIn("PHYSICAL_TIE_PRESERVATION_STATUS=PASS", report)


if __name__ == "__main__":
    unittest.main()
