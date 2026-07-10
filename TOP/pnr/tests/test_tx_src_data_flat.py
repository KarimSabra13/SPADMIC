#!/usr/bin/env python3
from __future__ import annotations

import csv
import re
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "TOP/rtl/interfaces/tx_src_data_flat.csv"
GENERATOR = ROOT / "TOP/scripts/generate_tx_src_data_flat.py"
ACTIVE_MODULES = {
    ROOT / "TOP/rtl/spadmic_event_bundle_tx.sv": "spadmic_event_bundle_tx",
    ROOT / "TOP/rtl/spadmic_tx_egress_core.sv": "spadmic_tx_egress_core",
    ROOT / "TOP/rtl/spadmic_tx_egress_cluster.sv": "spadmic_tx_egress_cluster",
    ROOT / "TOP/rtl/spadmic_tx_packet_core.sv": "spadmic_tx_packet_core",
    ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_v1.sv": "spadmic_digital_assembly_v1",
}


class TxSourceDataFlatTest(unittest.TestCase):
    def manifest_rows(self) -> list[dict[str, str]]:
        with MANIFEST.open(newline="", encoding="utf-8") as handle:
            return list(csv.DictReader(handle))

    def test_manifest_is_complete_unique_and_source_major(self) -> None:
        rows = self.manifest_rows()
        actual = [
            (int(row["source"]), int(row["bit"]), row["name"])
            for row in rows
        ]
        expected = [
            (source, bit, f"src_data_i_s{source}_b{bit}")
            for source in range(4)
            for bit in range(16)
        ]
        self.assertEqual(actual, expected)
        self.assertEqual(len({name for _, _, name in actual}), 64)

    def test_generated_regions_are_current(self) -> None:
        completed = subprocess.run(
            ["python3", str(GENERATOR), "--repo-root", str(ROOT), "--check"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)
        self.assertIn("TX_SRC_DATA_PIN_COUNT=64", completed.stdout)

    def test_active_module_boundaries_are_scalar(self) -> None:
        expected_names = {
            f"src_data_i_s{source}_b{bit}"
            for source in range(4)
            for bit in range(16)
        }
        two_dimensional_port = re.compile(
            r"(?m)^\s*(?:input|output|inout)\b[^;\n]*\bsrc_data_i\s*\["
        )
        for path, module in ACTIVE_MODULES.items():
            text = path.read_text(encoding="utf-8")
            header_match = re.search(
                rf"\bmodule\s+{module}\b.*?\n\);", text, flags=re.DOTALL
            )
            self.assertIsNotNone(header_match, path)
            header = header_match.group(0)
            self.assertIsNone(two_dimensional_port.search(header), path)
            actual_names = set(re.findall(r"\bsrc_data_i_s\d+_b\d+\b", header))
            self.assertEqual(actual_names, expected_names, path)

    def test_legacy_arbiter_contract_is_not_rewritten(self) -> None:
        legacy = ROOT / "arb/rtl/spadmic_packet_arbiter4.sv"
        text = legacy.read_text(encoding="utf-8")
        self.assertIn("src_data_i [spadmic_pkg::SPADMIC_SRC_COUNT]", text)
        self.assertNotIn("SPADMIC_TX_SRC_DATA_GENERATED_BEGIN", text)


if __name__ == "__main__":
    unittest.main()
