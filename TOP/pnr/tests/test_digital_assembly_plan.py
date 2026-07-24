#!/usr/bin/env python3

from __future__ import annotations

import csv
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
GENERATOR = REPO / "TOP" / "pnr" / "scripts" / "gen_spadmic_digital_assembly_v1.py"
PROCESSOR = REPO / "TOP" / "pnr" / "scripts" / "process_spadmic2_assembly_audit.py"
PG_CLASSIFIER = (
    REPO / "TOP" / "pnr" / "scripts" / "classify_spadmic2_digital_pg_access.py"
)
CORRIDOR_CLASSIFIER = (
    REPO
    / "TOP"
    / "pnr"
    / "scripts"
    / "classify_spadmic2_selected_pg_corridor.py"
)
CONTRACT = REPO / "TOP" / "pnr" / "assembly" / "spadmic_digital_assembly_contract.json"
UNKNOWN_POLICY = REPO / "TOP" / "pnr" / "assembly" / "matrice5_unknown_family_policy.csv"
RTL = REPO / "TOP" / "pnr" / "assembly" / "spadmic_digital_assembly_v1.sv"
SPADMIC2_KEY_INSTANCES = (
    REPO
    / "TOP"
    / "docs"
    / "layout_audits"
    / "SPADMIC2_20260709_072331"
    / "reports"
    / "SPADMIC2_key_instances.csv"
)

OOC_MODULE_PATH = REPO / "TOP" / "pnr" / "scripts" / "gen_ooc_block_harden_plan.py"
OOC_SPEC = importlib.util.spec_from_file_location("ooc_harden_plan", OOC_MODULE_PATH)
assert OOC_SPEC and OOC_SPEC.loader
ooc = importlib.util.module_from_spec(OOC_SPEC)
sys.modules[OOC_SPEC.name] = ooc
OOC_SPEC.loader.exec_module(ooc)


class DigitalAssemblyPlanTest(unittest.TestCase):
    @staticmethod
    def _write_tsv(path: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
        with path.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames, delimiter="\t", lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)

    @staticmethod
    def _read_kv(path: Path) -> dict[str, str]:
        return dict(
            line.split("=", 1)
            for line in path.read_text(encoding="utf-8").splitlines()
            if "=" in line
        )

    def _make_audit(self, root: Path) -> Path:
        audit = root / "audit"
        audit.mkdir()
        (audit / "assembly_audit_status.rpt").write_text(
            "STATUS=PASS\n"
            "P00_P02_IMPLEMENTATION_AUTHORIZED=YES\n"
            "P03_IMPLEMENTATION_AUTHORIZED=YES\n"
            "SPADMIC2_DIE_BBOX_UM=0.000 0.000 400.000 400.000\n",
            encoding="utf-8",
        )
        self._write_tsv(
            audit / "fixed_obstacles.tsv",
            ["instance", "llx", "lly", "urx", "ury"],
            [{"instance": "analog_fixed", "llx": "300", "lly": "0", "urx": "400", "ury": "400"}],
        )
        groups = [
            "tx_packet", "tx_ddr_strip", "position", "event", "matrix_or",
            "matrix_snapshot_reset", "matrix_cfg",
        ]
        self._write_tsv(
            audit / "soft_group_guides.tsv",
            ["group", "llx", "lly", "urx", "ury"],
            [
                {"group": group, "llx": str(index * 10), "lly": "10", "urx": str(index * 10 + 8), "ury": "80"}
                for index, group in enumerate(groups)
            ],
        )
        self._write_tsv(
            audit / "pg_overlap_anchors.tsv",
            ["net", "layer", "llx", "lly", "urx", "ury"],
            [
                {"net": "VDD", "layer": "METTP", "llx": "20", "lly": "0", "urx": "24", "ury": "400"},
                {"net": "VSS", "layer": "METTP", "llx": "40", "lly": "0", "urx": "44", "ury": "400"},
            ],
        )
        self._write_tsv(
            audit / "matrice5_proxy_pin_access.tsv",
            ["terminal", "family", "index", "direction", "layer", "purpose", "llx", "lly", "urx", "ury"],
            [
                {"terminal": "R<0>", "family": "R", "index": "0", "direction": "OUTPUT", "layer": "MET3", "purpose": "drawing", "llx": "1", "lly": "2", "urx": "3", "ury": "4"},
                {"terminal": "Din<0>", "family": "Din", "index": "0", "direction": "INPUT", "layer": "MET2", "purpose": "drawing", "llx": "5", "lly": "6", "urx": "7", "ury": "8"},
            ],
        )
        return audit

    def _make_processor_audit(self, root: Path, include_exact_pg: bool) -> Path:
        contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        audit = root / "raw_audit"
        audit.mkdir()
        self._write_tsv(
            audit / "source_identity.tsv",
            ["role", "library", "cell", "view", "filesystem_path", "open_status", "bbox"],
            [
                {
                    "role": "spadmic2",
                    "library": "SPADMIC",
                    "cell": "SPADMIC2",
                    "view": "layout",
                    "filesystem_path": contract["source_layouts"]["spadmic2"]["filesystem_path"],
                    "open_status": "PASS",
                    "bbox": "0 0 100 100",
                },
                {
                    "role": "matrice5",
                    "library": "SPADMIC",
                    "cell": "matrice5",
                    "view": "layout",
                    "filesystem_path": contract["source_layouts"]["matrice5"]["filesystem_path"],
                    "open_status": "PASS",
                    "bbox": "-10 -20 10 20",
                },
            ],
        )
        self._write_tsv(
            audit / "spadmic2_instances.tsv",
            [
                "instance", "master_library", "master_cell", "master_view",
                "orient", "llx", "lly", "urx", "ury",
            ],
            [
                {
                    "instance": "M182",
                    "master_library": "SPADMIC",
                    "master_cell": "matrice5",
                    "master_view": "layout",
                    "orient": "ABSENT",
                    "llx": "30",
                    "lly": "40",
                    "urx": "50",
                    "ury": "80",
                }
            ],
        )

        terminal_fields = [
            "terminal", "direction", "net", "layer", "purpose",
            "llx", "lly", "urx", "ury",
        ]
        terminal_rows: list[dict[str, str]] = []
        ordinal = 0
        for family, expected in contract["matrix_terminal_families"].items():
            for index in range(int(expected["width"])):
                x = -9.0 + float(ordinal % 18)
                y = -19.0 + float((ordinal // 18) % 38)
                terminal_rows.append(
                    {
                        "terminal": f"{family}<{index}>",
                        "direction": "inputOutput",
                        "net": "ABSENT",
                        "layer": "MET2",
                        "purpose": "pin",
                        "llx": f"{x:.3f}",
                        "lly": f"{y:.3f}",
                        "urx": f"{x + 0.1:.3f}",
                        "ury": f"{y + 0.1:.3f}",
                    }
                )
                ordinal += 1
        for terminal, layer, purpose in (
            ("AVDD", "MET3", "drawing"),
            ("DVDD", "MET3", "drawing"),
            ("VSS", "MET3", "drawing"),
            ("SUB", "MET2", "drawing"),
            ("VTUNE", "MET3", "drawing"),
            ("STI<0>", "PHODEF", "VERIFICATION"),
            ("STI<1>", "PHODEF", "VERIFICATION"),
        ):
            terminal_rows.append(
                {
                    "terminal": terminal,
                    "direction": "inputOutput",
                    "net": "ABSENT",
                    "layer": layer,
                    "purpose": purpose,
                    "llx": "-1",
                    "lly": "-1",
                    "urx": "1",
                    "ury": "1",
                }
            )
        self._write_tsv(
            audit / "matrice5_top_terminals.tsv",
            terminal_fields,
            terminal_rows,
        )
        self._write_tsv(
            audit / "spadmic2_instance_pins.tsv",
            [
                "instance", "terminal", "direction", "net", "layer",
                "purpose", "llx", "lly", "urx", "ury",
            ],
            [],
        )

        top_shapes = [
            {
                "shape_type": "rect",
                "net": "DVDD",
                "layer": "METTPL",
                "purpose": "pin",
                "llx": "12",
                "lly": "10",
                "urx": "18",
                "ury": "12",
            },
        ]
        if include_exact_pg:
            top_shapes.extend(
                [
                    {
                        "shape_type": "pathSeg",
                        "net": "VDD",
                        "layer": "METTP",
                        "purpose": "drawing",
                        "llx": "2",
                        "lly": "0",
                        "urx": "4",
                        "ury": "100",
                    },
                    {
                        "shape_type": "pathSeg",
                        "net": "VSS",
                        "layer": "METTP",
                        "purpose": "drawing",
                        "llx": "6",
                        "lly": "0",
                        "urx": "8",
                        "ury": "100",
                    },
                ]
            )
        else:
            top_shapes.insert(
                0,
                {
                    "shape_type": "pathSeg",
                    "net": "ABSENT",
                    "layer": "METTP",
                    "purpose": "drawing",
                    "llx": "10",
                    "lly": "10",
                    "urx": "20",
                    "ury": "12",
                },
            )
        self._write_tsv(
            audit / "spadmic2_top_shapes.tsv",
            [
                "shape_type", "net", "layer", "purpose",
                "llx", "lly", "urx", "ury",
            ],
            top_shapes,
        )
        return audit

    def _make_pg_probe(self, root: Path, include_direct_top: bool) -> tuple[Path, Path]:
        probe = root / "pg_probe"
        probe.mkdir()
        source = root / "sealed_source"
        (source / "processed_contract").mkdir(parents=True)
        (source / "raw_oa_export").mkdir()
        contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        self._write_tsv(
            probe / "source_identity.tsv",
            [
                "role",
                "library",
                "cell",
                "view",
                "filesystem_path",
                "open_status",
                "bbox",
            ],
            [
                {
                    "role": "spadmic2",
                    "library": contract["source_layouts"]["spadmic2"]["library"],
                    "cell": contract["source_layouts"]["spadmic2"]["cell"],
                    "view": contract["source_layouts"]["spadmic2"]["view"],
                    "filesystem_path": contract["source_layouts"]["spadmic2"][
                        "filesystem_path"
                    ],
                    "open_status": "PASS",
                    "bbox": "-500 -500 1100 1100",
                }
            ],
        )
        self._write_tsv(
            source / "raw_oa_export/spadmic2_instances.tsv",
            [
                "instance",
                "master_library",
                "master_cell",
                "master_view",
                "orient",
                "llx",
                "lly",
                "urx",
                "ury",
            ],
            [
                {
                    "instance": "I5",
                    "master_library": "SPADMIC",
                    "master_cell": "BOX_RING2",
                    "master_view": "layout",
                    "orient": "R0",
                    "llx": "-0.240",
                    "lly": "-287.715",
                    "urx": "999.760",
                    "ury": "712.285",
                },
                {
                    "instance": "M1",
                    "master_library": "SPADMIC",
                    "master_cell": "DDRs2",
                    "master_view": "layout",
                    "orient": "R0",
                    "llx": "0",
                    "lly": "80",
                    "urx": "20",
                    "ury": "180",
                },
            ],
        )
        (probe / "virtuoso_export_status.rpt").write_text(
            "LABEL=SPADMIC2_DIGITAL_PG_ACCESS_VIRTUOSO_EXPORT\n"
            "SOURCE_MUTATION_AUTHORIZED=NO\n"
            "OA_EDIT_AUTHORIZED=NO\n"
            "INSTANCE_TERMINAL_ENUMERATION_POLICY="
            "MASTER_TERMINALS_WITH_OPTIONAL_INSTTERM_CONNECTIVITY_AND_"
            "TRANSFORM_PROVENANCE_V2\n"
            "INSTANCE_TRANSFORM_POLICY="
            "DB_TRANSFORM_OR_BBOX_VERIFIED_XY_ORIENT_UNIT_MAG_STANDARD_INSTANCE\n"
            "UNAVAILABLE_TRANSFORM_POLICY="
            "MASTER_LOCAL_ONLY_NOT_A_CANDIDATE\n"
            "STATUS=PASS\n",
            encoding="utf-8",
        )
        self._write_tsv(
            source / "processed_contract/verified_digital_whitespace.tsv",
            ["rank", "llx", "lly", "urx", "ury", "area_um2", "status"],
            [
                {
                    "rank": "1",
                    "llx": "-100",
                    "lly": "0",
                    "urx": "0",
                    "ury": "200",
                    "area_um2": "20000",
                    "status": "VERIFIED_EMPTY",
                }
            ],
        )
        common_shape_fields = [
            "shape_type",
            "net",
            "layer",
            "purpose",
            "llx",
            "lly",
            "urx",
            "ury",
        ]
        direct_rows = [
            {
                "shape_type": "pathSeg",
                "net": "ABSENT",
                "layer": "METTP",
                "purpose": "drawing",
                "llx": "10",
                "lly": "40",
                "urx": "12",
                "ury": "80",
            }
        ]
        self._write_tsv(
            probe / "direct_mettp_shapes.tsv",
            common_shape_fields,
            direct_rows,
        )
        top_supply_rows: list[dict[str, str]] = []
        if include_direct_top:
            top_supply_rows = [
                {
                    "shape_type": "rect",
                    "net": "DVDD",
                    "layer": "METTP",
                    "purpose": "drawing",
                    "llx": "-20",
                    "lly": "10",
                    "urx": "-18",
                    "ury": "190",
                },
                {
                    "shape_type": "rect",
                    "net": "DVSS",
                    "layer": "METTP",
                    "purpose": "drawing",
                    "llx": "-30",
                    "lly": "10",
                    "urx": "-28",
                    "ury": "190",
                },
            ]
        self._write_tsv(
            probe / "supply_top_shapes.tsv",
            common_shape_fields,
            top_supply_rows,
        )
        self._write_tsv(
            probe / "supply_top_terminals.tsv",
            [
                "terminal",
                "direction",
                "net",
                "layer",
                "purpose",
                "llx",
                "lly",
                "urx",
                "ury",
            ],
            [],
        )
        self._write_tsv(
            probe / "supply_instance_pins.tsv",
            [
                "instance",
                "instance_object_type",
                "master_library",
                "master_cell",
                "master_view",
                "orient",
                "terminal",
                "direction",
                "net",
                "layer",
                "purpose",
                "transform_status",
                "coordinate_space",
                "master_llx",
                "master_lly",
                "master_urx",
                "master_ury",
                "llx",
                "lly",
                "urx",
                "ury",
            ],
            [
                {
                    "instance": "M1",
                    "instance_object_type": "inst",
                    "master_library": "SPADMIC",
                    "master_cell": "DDRs2",
                    "master_view": "layout",
                    "orient": "R0",
                    "terminal": "DVDD",
                    "direction": "inputOutput",
                    "net": "ABSENT",
                    "layer": "METTP",
                    "purpose": "pin",
                    "transform_status": (
                        "RECONSTRUCTED_XY_ORIENT_UNIT_MAG_BBOX_VERIFIED"
                    ),
                    "coordinate_space": "TOP_CELLVIEW",
                    "master_llx": "5",
                    "master_lly": "100",
                    "master_urx": "7",
                    "master_ury": "130",
                    "llx": "5",
                    "lly": "100",
                    "urx": "7",
                    "ury": "130",
                },
                {
                    "instance": "M1",
                    "instance_object_type": "inst",
                    "master_library": "SPADMIC",
                    "master_cell": "DDRs2",
                    "master_view": "layout",
                    "orient": "R0",
                    "terminal": "DVSS",
                    "direction": "inputOutput",
                    "net": "DVSS",
                    "layer": "METTP",
                    "purpose": "pin",
                    "transform_status": "DB_INSTANCE_TRANSFORM",
                    "coordinate_space": "TOP_CELLVIEW",
                    "master_llx": "5",
                    "master_lly": "140",
                    "master_urx": "7",
                    "master_ury": "170",
                    "llx": "5",
                    "lly": "140",
                    "urx": "7",
                    "ury": "170",
                },
                {
                    "instance": "I_LOCAL",
                    "instance_object_type": "inst",
                    "master_library": "D_CELLS_JIHD",
                    "master_cell": "ON22JIHDX1",
                    "master_view": "layout",
                    "orient": "R0",
                    "terminal": "VDD",
                    "direction": "inputOutput",
                    "net": "VDD",
                    "layer": "METTP",
                    "purpose": "pin",
                    "transform_status": "DB_INSTANCE_TRANSFORM",
                    "coordinate_space": "TOP_CELLVIEW",
                    "master_llx": "-90",
                    "master_lly": "20",
                    "master_urx": "-88",
                    "master_ury": "40",
                    "llx": "-90",
                    "lly": "20",
                    "urx": "-88",
                    "ury": "40",
                },
            ],
        )
        return probe, source

    def test_contract_defines_exact_cumulative_soft_phase_order(self) -> None:
        contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        self.assertEqual(contract["schema"], "spadmic.digital_assembly.contract.v2")
        self.assertEqual(list(contract["phases"]), ["p00_tx", "p01_position", "p02_event_control", "p03_matrix_interface"])
        self.assertEqual(
            [contract["phases"][phase]["top"] for phase in contract["phases"]],
            [
                "spadmic_digital_assembly_v1_p00_tx",
                "spadmic_digital_assembly_v1_p01_position",
                "spadmic_digital_assembly_v1_p02_event_control",
                "spadmic_digital_assembly_v1_p03_matrix_interface",
            ],
        )
        self.assertEqual(contract["physical_policy"]["implementation"], "CUMULATIVE_SOFT_LOGIC")
        self.assertEqual(contract["physical_policy"]["ordinary_signal_layers"], ["MET1", "MET2", "MET3"])
        self.assertEqual(contract["physical_policy"]["target_utilization"], 0.60)
        self.assertEqual(contract["physical_policy"]["max_local_density"], 0.70)
        self.assertEqual(
            contract["physical_policy"]["digital_to_chip_power_net_map"],
            {"VDD": "DVDD", "VSS": "DVSS"},
        )
        self.assertEqual(
            contract["assembly_floorplan"]["boundary_instance"],
            {
                "instance": "I5",
                "master_library": "SPADMIC",
                "master_cell": "BOX_RING2",
                "master_view": "layout",
                "orient": "R0",
            },
        )
        self.assertEqual(
            contract["assembly_floorplan"]["boundary_policy"],
            "HOLLOW_PAD_RING_REFERENCE",
        )
        self.assertEqual(
            contract["assembly_floorplan"]["coordinate_policy"],
            "NORMALIZE_TO_BOUNDARY_INSTANCE_LOWER_LEFT",
        )
        self.assertEqual(
            contract["assembly_floorplan"]["core_keepout_um"],
            164.0,
        )
        self.assertEqual(
            contract["selected_pg_corridor_probe"]["target_instance"],
            {
                "instance": "I6",
                "master_library": "SPADMIC",
                "master_cell": "TXRX4TDC2_HV",
                "master_view": "layout",
                "orient": "R0",
            },
        )
        self.assertEqual(
            contract["selected_pg_corridor_probe"]["target_pins"]["VDD"],
            {
                "chip_net": "DVDD",
                "layer": "METTP",
                "purpose": "pin",
                "source_bbox_um": [3515.96, 2241.71, 3550.96, 2243.845],
            },
        )
        self.assertEqual(
            contract["selected_pg_corridor_probe"]["target_pins"]["VSS"],
            {
                "chip_net": "DVSS",
                "layer": "METTP",
                "purpose": "pin",
                "source_bbox_um": [3555.96, 2241.985, 3590.96, 2243.845],
            },
        )
        self.assertEqual(
            contract["selected_pg_corridor_probe"]["hierarchy_depth"],
            [0, 32],
        )
        self.assertTrue(
            contract["selected_pg_corridor_probe"][
                "include_mosaic_rows_and_columns"
            ]
        )
        self.assertEqual(
            contract["selected_pg_corridor_probe"]["candidate_policy"],
            "REVIEW_ONLY_NO_GEOMETRY_CREATION",
        )
        self.assertEqual(contract["phases"]["p03_matrix_interface"]["allowed_density_rules"], ["R1M1", "R1M2", "R1M3", "R1MT"])
        self.assertEqual(contract["source_layouts"]["matrice5"]["library"], "SPADMIC")
        self.assertEqual(
            contract["source_layouts"]["matrice5"]["filesystem_path"],
            "/group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL/matrice5",
        )
        for phase in ("p00_tx", "p01_position", "p02_event_control"):
            self.assertEqual(contract["phases"][phase]["density_gate"], "NOT_RUN")
        self.assertIn("BLOCKED", contract["deferred"]["p04_mptdc_frontend"])
        self.assertEqual(contract["deferred"]["p05_csr_i2c"], "DEFERRED")

    def test_pg_access_classifier_keeps_instance_pin_candidates_review_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            probe, source = self._make_pg_probe(root, include_direct_top=False)
            output = root / "classified"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PG_CLASSIFIER),
                    "--probe-root",
                    str(probe),
                    "--source-audit-root",
                    str(source),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = self._read_kv(output / "digital_pg_access_status.rpt")
            self.assertEqual(status["STATUS"], "PASS")
            self.assertEqual(status["LOCAL_VDD_NET"], "VDD")
            self.assertEqual(status["CHIP_VDD_NET"], "DVDD")
            self.assertEqual(status["LOCAL_VSS_NET"], "VSS")
            self.assertEqual(status["CHIP_VSS_NET"], "DVSS")
            self.assertEqual(
                status["DIRECT_TOP_CHIP_PG_METTP_ACCESS_STATUS"],
                "FAIL",
            )
            self.assertEqual(
                status["INSTANCE_PIN_CHIP_PG_METTP_CANDIDATE_STATUS"],
                "PASS",
            )
            self.assertEqual(status["REVIEW_CANDIDATE_PAIR_STATUS"], "PASS")
            self.assertEqual(
                status["INSTANCE_TERMINAL_ENUMERATION_POLICY"],
                "MASTER_TERMINALS_WITH_OPTIONAL_INSTTERM_CONNECTIVITY_AND_"
                "TRANSFORM_PROVENANCE_V2",
            )
            self.assertEqual(status["INSTANCE_TRANSFORM_COVERAGE_STATUS"], "PASS")
            self.assertEqual(
                status[
                    "INSTANCE_CHIP_PG_TRANSFORM_ELIGIBLE_MASTER_TERMINAL_COUNT"
                ],
                "2",
            )
            self.assertEqual(
                status[
                    "INSTANCE_CHIP_PG_TRANSFORM_UNAVAILABLE_MASTER_TERMINAL_COUNT"
                ],
                "0",
            )
            self.assertEqual(
                status["INSTANCE_CHIP_PG_MASTER_TERMINAL_COUNT"],
                "2",
            )
            self.assertEqual(
                status["INSTANCE_CHIP_PG_DISCONNECTED_MASTER_TERMINAL_COUNT"],
                "1",
            )
            self.assertEqual(status["INSTANCE_PIN_VDD_ALL_LAYER_SHAPE_COUNT"], "1")
            self.assertEqual(status["INSTANCE_PIN_VSS_ALL_LAYER_SHAPE_COUNT"], "1")
            self.assertEqual(
                status["NEXT_GATE"],
                "RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE",
            )
            self.assertEqual(status["ASSEMBLY_FLOORPLAN_MODEL_STATUS"], "PASS")
            self.assertEqual(status["ASSEMBLY_BOUNDARY_INSTANCE"], "I5")
            self.assertEqual(
                status["ASSEMBLY_NORMALIZED_DIE_BBOX_UM"],
                "0.000000 0.000000 1000.000000 1000.000000",
            )
            self.assertEqual(
                status["SOURCE_TO_ASSEMBLY_TRANSLATION_UM"],
                "0.240000 287.715000",
            )
            self.assertEqual(
                status["COMPLETE_SAME_INSTANCE_PG_PAIR_STATUS"],
                "PASS",
            )
            self.assertEqual(status["REVIEW_CANDIDATE_PAIR_INSTANCE"], "M1")
            self.assertEqual(
                status["TARGET_INSTANCE_METTP_CONTEXT_STATUS"],
                "NOT_PROBED",
            )
            self.assertEqual(
                status["BRIDGE_GEOMETRY_STATUS"],
                "NOT_AUTHORIZED",
            )
            self.assertEqual(status["P00_P02_IMPLEMENTATION_AUTHORIZED"], "NO")

            with (output / "digital_pg_review_pair.tsv").open(
                newline="",
                encoding="utf-8",
            ) as handle:
                pair = list(csv.DictReader(handle, delimiter="\t"))
            self.assertEqual({row["local_net"] for row in pair}, {"VDD", "VSS"})
            self.assertTrue(all(row["instance"] == "M1" for row in pair))
            vdd = next(row for row in pair if row["local_net"] == "VDD")
            vss = next(row for row in pair if row["local_net"] == "VSS")
            self.assertEqual(
                vdd["evidence_class"],
                "INSTANCE_PIN_EXACT_TERMINAL_NAME",
            )
            self.assertEqual(
                vdd["transform_status"],
                "RECONSTRUCTED_XY_ORIENT_UNIT_MAG_BBOX_VERIFIED",
            )
            self.assertEqual(
                vss["evidence_class"],
                "INSTANCE_PIN_EXACT_CONNECTED_NET",
            )
            self.assertTrue(
                all(
                    row["authorization"]
                    == "REVIEW_ONLY_NOT_AN_ASSEMBLY_ANCHOR"
                    for row in pair
                )
            )
            context = (
                output / "mettp_to_supply_access_context.tsv"
            ).read_text(encoding="utf-8")
            self.assertIn("M1\tinst\tDDRs2\tDVDD", context)
            all_layers = (
                output / "digital_pg_access_all_layers.tsv"
            ).read_text(encoding="utf-8")
            self.assertIn(
                "INSTANCE_MASTER_TERMINAL_PIN\t"
                "INSTANCE_PIN_EXACT_TERMINAL_NAME",
                all_layers,
            )
            self.assertIn("NO_INSTTERM_CONNECTIVITY", all_layers)
            layer_summary = (
                output / "digital_pg_access_layer_summary.tsv"
            ).read_text(encoding="utf-8")
            self.assertIn("POSITIVE_AREA_METTP", layer_summary)
            self.assertTrue(
                (output / "assembly_floorplan_boundary.tsv").is_file()
            )
            self.assertTrue(
                (output / "assembly_fixed_obstacles_normalized.tsv").is_file()
            )
            self.assertTrue(
                (output / "assembly_verified_whitespace_normalized.tsv").is_file()
            )
            self.assertTrue((output / "digital_pg_pair_ranking.tsv").is_file())
            manifest = subprocess.run(
                ["sha256sum", "-c", "SHA256SUMS"],
                cwd=output,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(manifest.returncode, 0, manifest.stdout)

    def test_pg_access_classifier_ranks_complete_pair_against_corrected_interior(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            probe, source = self._make_pg_probe(root, include_direct_top=False)

            instance_path = source / "raw_oa_export/spadmic2_instances.tsv"
            with instance_path.open(newline="", encoding="utf-8") as handle:
                instances = list(csv.DictReader(handle, delimiter="\t"))
            instances.append(
                {
                    "instance": "I6",
                    "master_library": "SPADMIC",
                    "master_cell": "TXRX4TDC2_HV",
                    "master_view": "layout",
                    "orient": "R0",
                    "llx": "700",
                    "lly": "200",
                    "urx": "800",
                    "ury": "500",
                }
            )
            self._write_tsv(instance_path, list(instances[0]), instances)

            pin_path = probe / "supply_instance_pins.tsv"
            with pin_path.open(newline="", encoding="utf-8") as handle:
                pins = list(csv.DictReader(handle, delimiter="\t"))
            for row in pins:
                if row["instance"] == "M1":
                    row["net"] = "ABSENT"
            for terminal, lly, ury in (
                ("DVDD", "300", "310"),
                ("DVSS", "320", "330"),
            ):
                pins.append(
                    {
                        "instance": "I6",
                        "instance_object_type": "inst",
                        "master_library": "SPADMIC",
                        "master_cell": "TXRX4TDC2_HV",
                        "master_view": "layout",
                        "orient": "R0",
                        "terminal": terminal,
                        "direction": "inputOutput",
                        "net": "ABSENT",
                        "layer": "METTP",
                        "purpose": "pin",
                        "transform_status": "DB_INSTANCE_TRANSFORM",
                        "coordinate_space": "TOP_CELLVIEW",
                        "master_llx": "0",
                        "master_lly": lly,
                        "master_urx": "20",
                        "master_ury": ury,
                        "llx": "700",
                        "lly": lly,
                        "urx": "720",
                        "ury": ury,
                    }
                )
            self._write_tsv(pin_path, list(pins[0]), pins)

            output = root / "classified"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PG_CLASSIFIER),
                    "--probe-root",
                    str(probe),
                    "--source-audit-root",
                    str(source),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = self._read_kv(output / "digital_pg_access_status.rpt")
            self.assertEqual(status["REVIEW_CANDIDATE_PAIR_INSTANCE"], "I6")
            self.assertEqual(
                status["ASSEMBLY_PRIMARY_WHITESPACE_NORMALIZED_BBOX_UM"],
                "164.000000 164.000000 700.240000 836.000000",
            )
            self.assertEqual(
                status["NEXT_GATE"],
                "RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE",
            )
            with (output / "digital_pg_pair_ranking.tsv").open(
                newline="",
                encoding="utf-8",
            ) as handle:
                ranking = list(csv.DictReader(handle, delimiter="\t"))
            self.assertEqual(ranking[0]["instance"], "I6")
            self.assertEqual(ranking[1]["instance"], "M1")
            self.assertEqual(
                ranking[0]["authorization"],
                "REVIEW_ONLY_NOT_AN_ASSEMBLY_ANCHOR",
            )

    def test_pg_floorplan_replay_matches_historical_key_instance_geometry(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            probe, source = self._make_pg_probe(root, include_direct_top=False)

            identity_path = probe / "source_identity.tsv"
            with identity_path.open(newline="", encoding="utf-8") as handle:
                identity = list(csv.DictReader(handle, delimiter="\t"))
            identity[0]["bbox"] = (
                "-451.632000 -287.715000 4115.791000 3453.077000"
            )
            self._write_tsv(identity_path, list(identity[0]), identity)

            with SPADMIC2_KEY_INSTANCES.open(
                newline="",
                encoding="utf-8",
            ) as handle:
                historical = list(csv.reader(handle))
            source_instances = [
                {
                    "instance": row[0],
                    "master_library": row[1],
                    "master_cell": (
                        "matrice5" if row[0] == "M182" else row[2]
                    ),
                    "master_view": row[3],
                    "orient": row[4] or "ABSENT",
                    "llx": row[5],
                    "lly": row[6],
                    "urx": row[7],
                    "ury": row[8],
                }
                for row in historical
            ]
            self.assertEqual(len(source_instances), 11)
            instance_path = source / "raw_oa_export/spadmic2_instances.tsv"
            self._write_tsv(
                instance_path,
                list(source_instances[0]),
                source_instances,
            )

            pin_fields = [
                "instance",
                "instance_object_type",
                "master_library",
                "master_cell",
                "master_view",
                "orient",
                "terminal",
                "direction",
                "net",
                "layer",
                "purpose",
                "transform_status",
                "coordinate_space",
                "master_llx",
                "master_lly",
                "master_urx",
                "master_ury",
                "llx",
                "lly",
                "urx",
                "ury",
            ]
            pin_rows = []
            for (
                instance,
                master_cell,
                terminal,
                master_bbox,
                placed_bbox,
            ) in (
                (
                    "I5",
                    "BOX_RING2",
                    "DVDD",
                    ("1608.600000", "49.245000", "1661.600000", "115.260000"),
                    ("1391.500000", "49.245000", "1444.500000", "115.260000"),
                ),
                (
                    "I5",
                    "BOX_RING2",
                    "DVSS",
                    ("1420.600000", "49.245000", "1473.600000", "115.260000"),
                    ("1203.500000", "49.245000", "1256.500000", "115.260000"),
                ),
                (
                    "I6",
                    "TXRX4TDC2_HV",
                    "DVDD",
                    ("30.795000", "1405.555000", "65.795000", "1407.690000"),
                    ("3515.960000", "2241.710000", "3550.960000", "2243.845000"),
                ),
                (
                    "I6",
                    "TXRX4TDC2_HV",
                    "DVSS",
                    ("70.795000", "1405.830000", "105.795000", "1407.690000"),
                    ("3555.960000", "2241.985000", "3590.960000", "2243.845000"),
                ),
            ):
                pin_rows.append(
                    {
                        "instance": instance,
                        "instance_object_type": "inst",
                        "master_library": "SPADMIC",
                        "master_cell": master_cell,
                        "master_view": "layout",
                        "orient": "R0",
                        "terminal": terminal,
                        "direction": "inputOutput",
                        "net": "ABSENT",
                        "layer": "METTP",
                        "purpose": "pin",
                        "transform_status": "DB_INSTANCE_TRANSFORM",
                        "coordinate_space": "TOP_CELLVIEW",
                        "master_llx": master_bbox[0],
                        "master_lly": master_bbox[1],
                        "master_urx": master_bbox[2],
                        "master_ury": master_bbox[3],
                        "llx": placed_bbox[0],
                        "lly": placed_bbox[1],
                        "urx": placed_bbox[2],
                        "ury": placed_bbox[3],
                    }
                )
            self._write_tsv(
                probe / "supply_instance_pins.tsv",
                pin_fields,
                pin_rows,
            )

            output = root / "classified"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PG_CLASSIFIER),
                    "--probe-root",
                    str(probe),
                    "--source-audit-root",
                    str(source),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = self._read_kv(output / "digital_pg_access_status.rpt")
            self.assertEqual(
                status["ASSEMBLY_NORMALIZED_DIE_BBOX_UM"],
                "0.000000 0.000000 4116.031000 3740.792000",
            )
            self.assertEqual(
                status["ASSEMBLY_FIXED_OBSTACLE_COUNT"],
                "10",
            )
            self.assertEqual(
                status["ASSEMBLY_VERIFIED_INTERIOR_WHITESPACE_RECT_COUNT"],
                "42",
            )
            self.assertEqual(
                status["ASSEMBLY_PRIMARY_WHITESPACE_SOURCE_BBOX_UM"],
                "3638.670000 -123.715000 3951.791000 3289.077000",
            )
            self.assertEqual(
                status["ASSEMBLY_PRIMARY_WHITESPACE_NORMALIZED_BBOX_UM"],
                "3638.910000 164.000000 3952.031000 3576.792000",
            )
            self.assertEqual(status["REVIEW_CANDIDATE_PAIR_INSTANCE"], "I6")
            with (output / "digital_pg_pair_ranking.tsv").open(
                newline="",
                encoding="utf-8",
            ) as handle:
                ranking = list(csv.DictReader(handle, delimiter="\t"))
            self.assertEqual([row["instance"] for row in ranking], ["I6", "I5"])
            self.assertEqual(
                ranking[0]["vdd_primary_whitespace_distance_um"],
                "87.710000",
            )
            self.assertEqual(
                ranking[0]["vss_primary_whitespace_distance_um"],
                "47.710000",
            )
            manifest = subprocess.run(
                ["sha256sum", "-c", "SHA256SUMS"],
                cwd=output,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(manifest.returncode, 0, manifest.stdout)

    def test_pg_access_classifier_distinguishes_direct_top_alias_access(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            probe, source = self._make_pg_probe(root, include_direct_top=True)
            output = root / "classified"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PG_CLASSIFIER),
                    "--probe-root",
                    str(probe),
                    "--source-audit-root",
                    str(source),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = self._read_kv(output / "digital_pg_access_status.rpt")
            self.assertEqual(
                status["DIRECT_TOP_CHIP_PG_METTP_ACCESS_STATUS"],
                "PASS",
            )
            self.assertEqual(
                status["NEXT_GATE"],
                "REVIEW_DIRECT_CHIP_PG_ACCESS_AND_DEFINE_LOCAL_RAILS",
            )
            self.assertEqual(status["OA_EDIT_AUTHORIZED"], "NO")
            self.assertEqual(status["INNOVUS_AUTHORIZED"], "NO")

    def test_pg_access_classifier_separates_non_mettp_master_pins(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            probe, source = self._make_pg_probe(root, include_direct_top=False)
            pin_path = probe / "supply_instance_pins.tsv"
            with pin_path.open(newline="", encoding="utf-8") as handle:
                rows = list(csv.DictReader(handle, delimiter="\t"))
            for row in rows:
                if row["terminal"] in {"DVDD", "DVSS"}:
                    row["layer"] = "MET3"
            self._write_tsv(pin_path, list(rows[0]), rows)
            output = root / "classified"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PG_CLASSIFIER),
                    "--probe-root",
                    str(probe),
                    "--source-audit-root",
                    str(source),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = self._read_kv(output / "digital_pg_access_status.rpt")
            self.assertEqual(
                status["INSTANCE_PIN_CHIP_PG_METTP_CANDIDATE_STATUS"],
                "FAIL",
            )
            self.assertEqual(status["INSTANCE_PIN_VDD_ALL_LAYER_SHAPE_COUNT"], "1")
            self.assertEqual(status["INSTANCE_PIN_VSS_ALL_LAYER_SHAPE_COUNT"], "1")
            self.assertEqual(
                status["NEXT_GATE"],
                "REVIEW_NON_METTP_CHIP_PG_PINS_AND_REQUEST_ROUTABLE_ACCESS",
            )

    def test_pg_access_classifier_rejects_unresolved_mosaic_coordinates(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            probe, source = self._make_pg_probe(root, include_direct_top=False)
            pin_path = probe / "supply_instance_pins.tsv"
            with pin_path.open(newline="", encoding="utf-8") as handle:
                rows = list(csv.DictReader(handle, delimiter="\t"))
            for row in rows:
                if row["terminal"] in {"DVDD", "DVSS"}:
                    row["instance_object_type"] = "mosaic"
                    row["transform_status"] = "UNAVAILABLE_MOSAIC_TRANSFORM"
                    row["coordinate_space"] = "MASTER_LOCAL_ONLY"
                    for field in ("llx", "lly", "urx", "ury"):
                        row[field] = "UNKNOWN"
            self._write_tsv(pin_path, list(rows[0]), rows)
            output = root / "classified"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PG_CLASSIFIER),
                    "--probe-root",
                    str(probe),
                    "--source-audit-root",
                    str(source),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = self._read_kv(output / "digital_pg_access_status.rpt")
            self.assertEqual(status["INSTANCE_TRANSFORM_COVERAGE_STATUS"], "UNAVAILABLE")
            self.assertEqual(
                status[
                    "INSTANCE_CHIP_PG_TRANSFORM_UNAVAILABLE_MASTER_TERMINAL_COUNT"
                ],
                "2",
            )
            self.assertEqual(
                status[
                    "INSTANCE_CHIP_PG_NONSTANDARD_UNAVAILABLE_MASTER_TERMINAL_COUNT"
                ],
                "2",
            )
            self.assertEqual(status["REVIEW_CANDIDATE_COUNT"], "0")
            self.assertEqual(
                status["NEXT_GATE"],
                "STOP_AND_RESOLVE_UNAVAILABLE_INSTANCE_TRANSFORMS",
            )
            all_layers = (
                output / "digital_pg_access_all_layers.tsv"
            ).read_text(encoding="utf-8")
            self.assertIn("UNAVAILABLE_MOSAIC_TRANSFORM", all_layers)
            self.assertIn("MASTER_LOCAL_ONLY", all_layers)
            self.assertIn("REJECT_UNPROVEN_TOP_COORDINATES", all_layers)

    def test_pg_access_classifier_rejects_instterm_only_probe_policy(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            probe, source = self._make_pg_probe(root, include_direct_top=False)
            (probe / "virtuoso_export_status.rpt").write_text(
                "STATUS=PASS\n"
                "INSTANCE_TERMINAL_ENUMERATION_POLICY=INSTTERMS_ONLY\n",
                encoding="utf-8",
            )
            output = root / "classified"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PG_CLASSIFIER),
                    "--probe-root",
                    str(probe),
                    "--source-audit-root",
                    str(source),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 2, result.stdout)
            status = self._read_kv(output / "digital_pg_access_status.rpt")
            self.assertIn(
                "master-terminal enumeration independent of instTerm",
                status["ERROR"],
            )

    def test_pg_access_probe_is_one_read_only_cadence_action(self) -> None:
        skill = (
            REPO / "TOP" / "pnr" / "scripts" / "probe_spadmic2_digital_pg_access.il"
        ).read_text()
        wrapper_path = (
            REPO / "TOP" / "ci" / "server_probe_spadmic2_digital_pg_access.sh"
        )
        wrapper = wrapper_path.read_text()
        syntax = subprocess.run(
            ["bash", "-n", str(wrapper_path)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        self.assertEqual(syntax.returncode, 0, syntax.stdout)
        self.assertTrue(os.access(wrapper_path, os.X_OK))
        self.assertEqual(wrapper.count('"$VIRTUOSO_BIN" -nograph'), 1)
        self.assertIn('dbOpenCellViewByType(libName cellName viewName "" "r")', skill)
        self.assertIn("spadmicPgWriteSupplyInstancePins", skill)
        self.assertNotIn("dbTransformBBox(fig~>bBox inst~>transform)", skill)
        self.assertIn("spadmicPgInstanceTransformRecord", skill)
        self.assertIn("dbTransformBBox(fig~>bBox transform)", skill)
        self.assertIn('inst~>objType == "inst"', skill)
        self.assertIn('inst~>objType == "mosaic"', skill)
        self.assertIn(
            "RECONSTRUCTED_XY_ORIENT_UNIT_MAG_BBOX_VERIFIED",
            skill,
        )
        self.assertIn("UNAVAILABLE_MOSAIC_TRANSFORM", skill)
        self.assertIn("MASTER_LOCAL_ONLY", skill)
        instance_writer = skill.split(
            "procedure(spadmicPgWriteSupplyInstancePins",
            1,
        )[1].split("procedure(spadmicPgWriteDirectMettpShapes", 1)[0]
        self.assertIn("foreach(term master~>terminals", instance_writer)
        self.assertNotIn("foreach(instTerm inst~>instTerms", instance_writer)
        self.assertIn(
            "MASTER_TERMINALS_WITH_OPTIONAL_INSTTERM_CONNECTIVITY_AND_"
            "TRANSFORM_PROVENANCE_V2",
            skill,
        )
        self.assertIn(
            "MASTER_TERMINALS_WITH_OPTIONAL_INSTTERM_CONNECTIVITY_AND_"
            "TRANSFORM_PROVENANCE_V2",
            wrapper,
        )
        self.assertIn(
            "UNAVAILABLE_TRANSFORM_POLICY=MASTER_LOCAL_ONLY_NOT_A_CANDIDATE",
            wrapper,
        )
        self.assertIn("SPADMIC_PG_CHIP_VDD", skill)
        self.assertIn("SPADMIC_PG_CHIP_VSS", skill)
        self.assertNotIn("dbSave", skill)
        self.assertNotIn("dbCreate", skill)
        self.assertNotIn("dbDelete", skill)
        self.assertIn('inventory_tree "$TOP_OA_PATH"', wrapper)
        self.assertIn('"$CHMOD_BIN" -R a-w "$RAW_ROOT"', wrapper)
        self.assertIn('"$CHMOD_BIN" -R a-w "$PROCESSED_ROOT"', wrapper)
        self.assertIn('"$CHMOD_BIN" -R a-w "$DIAGNOSTIC_ROOT"', wrapper)
        self.assertIn("SPADMIC_SHA256_SELFTEST_V1", wrapper)
        self.assertIn("evidence_payload.tar.gz.sha256", wrapper)
        self.assertIn("RECOVERY_ARCHIVE_HASH_VERIFY_RC", wrapper)
        self.assertIn("digital_pg_access_layer_summary.tsv", wrapper)
        self.assertIn("digital_pg_access_all_layers.tsv", wrapper)
        self.assertIn("assembly_floorplan_boundary.tsv", wrapper)
        self.assertIn("assembly_fixed_obstacles_normalized.tsv", wrapper)
        self.assertIn("assembly_verified_whitespace_normalized.tsv", wrapper)
        self.assertIn("digital_pg_pair_ranking.tsv", wrapper)
        self.assertIn("REVIEW_CANDIDATE_PAIR_INSTANCE=I6", wrapper)
        self.assertIn(
            "RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE",
            wrapper,
        )
        self.assertIn(
            'echo "RAW_MANIFEST_POST_ARCHIVE_RC=$RAW_MANIFEST_POST_ARCHIVE_RC"',
            wrapper,
        )
        self.assertIn(
            'echo "PROCESSED_MANIFEST_POST_ARCHIVE_RC='
            '$PROCESSED_MANIFEST_POST_ARCHIVE_RC"',
            wrapper,
        )
        self.assertIn("DO_NOT_START_GENUS_INNOVUS_OR_EDIT_OA", wrapper)
        self.assertNotIn("\ngenus ", wrapper)
        self.assertNotIn("\ninnovus ", wrapper)
        self.assertNotIn("\nrm ", wrapper)

    def test_pg_floorplan_replay_is_processor_only_and_fail_closed(self) -> None:
        wrapper_path = (
            REPO
            / "TOP"
            / "ci"
            / "server_replay_spadmic2_digital_pg_floorplan.sh"
        )
        wrapper = wrapper_path.read_text(encoding="utf-8")
        syntax = subprocess.run(
            ["bash", "-n", str(wrapper_path)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        self.assertEqual(syntax.returncode, 0, syntax.stdout)
        self.assertTrue(os.access(wrapper_path, os.X_OK))
        self.assertIn("set +e", wrapper)
        self.assertIn("--probe-root \"$PG_RAW\"", wrapper)
        self.assertIn("--source-audit-root \"$SOURCE_ROOT\"", wrapper)
        self.assertIn("ASSEMBLY_BOUNDARY_INSTANCE=I5", wrapper)
        self.assertIn(
            "SOURCE_INSTANCES_SHA256="
            "9dc5e18abadd3b3d38fb43347ff11486ec8c1b13f194bf070dd6ac5957709360",
            wrapper,
        )
        self.assertIn("ASSEMBLY_FIXED_OBSTACLE_COUNT=13", wrapper)
        self.assertIn(
            "ASSEMBLY_VERIFIED_INTERIOR_WHITESPACE_RECT_COUNT=62",
            wrapper,
        )
        self.assertIn(
            "ASSEMBLY_PRIMARY_WHITESPACE_NORMALIZED_BBOX_UM="
            "3662.775000 164.000000 3952.031000 3576.792000",
            wrapper,
        )
        self.assertNotIn("ASSEMBLY_FIXED_OBSTACLE_COUNT=10", wrapper)
        self.assertIn("REVIEW_CANDIDATE_PAIR_INSTANCE=I6", wrapper)
        self.assertIn(
            "TARGET_INSTANCE_METTP_CONTEXT_STATUS=NOT_PROBED",
            wrapper,
        )
        self.assertIn("BRIDGE_GEOMETRY_STATUS=NOT_AUTHORIZED", wrapper)
        self.assertIn(
            "RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE",
            wrapper,
        )
        self.assertIn('"$CHMOD_BIN" -R a-w "$REPLAY_ROOT"', wrapper)
        self.assertIn("DO_NOT_START_CADENCE_GENUS_INNOVUS_OR_EDIT_OA", wrapper)
        self.assertNotIn('"$VIRTUOSO_BIN"', wrapper)
        self.assertNotIn("-nograph", wrapper)
        self.assertNotIn("\ngenus ", wrapper)
        self.assertNotIn("\ninnovus ", wrapper)
        self.assertNotIn("\nrm ", wrapper)
        self.assertNotIn("\nexit ", wrapper)
        self.assertNotIn("set -e", wrapper)

    def test_selected_i6_corridor_classifier_is_evidence_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            probe = root / "raw_corridor"
            floorplan = root / "floorplan"
            output = root / "classified"
            probe.mkdir()
            floorplan.mkdir()
            contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
            source = contract["source_layouts"]["spadmic2"]

            (probe / "virtuoso_export_status.rpt").write_text(
                "LABEL=SPADMIC2_SELECTED_I6_METTP_CORRIDOR_VIRTUOSO_EXPORT\n"
                "SOURCE_MUTATION_AUTHORIZED=NO\n"
                "OA_EDIT_AUTHORIZED=NO\n"
                "HIERARCHICAL_QUERY_POLICY="
                "DB_GET_TRUE_OVERLAPS_DEPTH_0_32_WITH_ROW_COLUMN_ENUMERATION\n"
                "HIERARCHICAL_TRANSFORM_POLICY=DB_GET_HIER_PATH_TRANSFORM\n"
                "CORRIDOR_AUTHORIZATION=REVIEW_ONLY_NO_GEOMETRY_CREATION\n"
                "STATUS=PASS\n",
                encoding="utf-8",
            )
            (probe / "corridor_query_status.rpt").write_text(
                "LABEL=SPADMIC2_SELECTED_I6_METTP_CORRIDOR_QUERY\n"
                "STATUS=PASS\n"
                "TARGET_INSTANCE=I6\n"
                "TARGET_MASTER=SPADMIC/TXRX4TDC2_HV/layout\n"
                "TARGET_ORIENT=R0\n"
                "TARGET_PG_PIN_SHAPE_COUNT=2\n"
                "QUERY_WINDOW_UM="
                "3415.960000 2141.710000 3762.535000 2343.845000\n"
                "DB_GET_TRUE_OVERLAPS_RESULT_COUNT=4\n"
                "HIERARCHICAL_SHAPE_ROW_COUNT=4\n"
                "HIERARCHICAL_TRANSFORM_FAILURE_COUNT=0\n"
                "HIERARCHY_DEPTH=0:32\n"
                "MOSAIC_ROW_COLUMN_ENUMERATION=YES\n"
                "CORRIDOR_AUTHORIZATION=REVIEW_ONLY_NO_GEOMETRY_CREATION\n",
                encoding="utf-8",
            )
            self._write_tsv(
                probe / "source_identity.tsv",
                [
                    "role",
                    "library",
                    "cell",
                    "view",
                    "filesystem_path",
                    "open_status",
                    "bbox",
                ],
                [
                    {
                        "role": "spadmic2",
                        "library": source["library"],
                        "cell": source["cell"],
                        "view": source["view"],
                        "filesystem_path": source["filesystem_path"],
                        "open_status": "PASS",
                        "bbox": (
                            "-451.632000 -287.715000 "
                            "4115.791000 3453.077000"
                        ),
                    }
                ],
            )
            self._write_tsv(
                probe / "target_instance.tsv",
                [
                    "instance",
                    "instance_object_type",
                    "master_library",
                    "master_cell",
                    "master_view",
                    "orient",
                    "transform",
                    "llx",
                    "lly",
                    "urx",
                    "ury",
                ],
                [
                    {
                        "instance": "I6",
                        "instance_object_type": "inst",
                        "master_library": "SPADMIC",
                        "master_cell": "TXRX4TDC2_HV",
                        "master_view": "layout",
                        "orient": "R0",
                        "transform": "((3485.165 836.155) R0 1.0)",
                        "llx": "3485.165",
                        "lly": "836.155",
                        "urx": "4115.790",
                        "ury": "2824.170",
                    }
                ],
            )
            pin_fields = [
                "instance",
                "terminal",
                "direction",
                "net",
                "shape_type",
                "layer",
                "purpose",
                "master_llx",
                "master_lly",
                "master_urx",
                "master_ury",
                "llx",
                "lly",
                "urx",
                "ury",
                "transform_status",
            ]
            pin_rows = [
                {
                    "instance": "I6",
                    "terminal": "DVDD",
                    "direction": "inputOutput",
                    "net": "ABSENT",
                    "shape_type": "rect",
                    "layer": "METTP",
                    "purpose": "pin",
                    "master_llx": "30.795",
                    "master_lly": "1405.555",
                    "master_urx": "65.795",
                    "master_ury": "1407.690",
                    "llx": "3515.960",
                    "lly": "2241.710",
                    "urx": "3550.960",
                    "ury": "2243.845",
                    "transform_status": "DB_INSTANCE_TRANSFORM",
                },
                {
                    "instance": "I6",
                    "terminal": "DVSS",
                    "direction": "inputOutput",
                    "net": "ABSENT",
                    "shape_type": "rect",
                    "layer": "METTP",
                    "purpose": "pin",
                    "master_llx": "70.795",
                    "master_lly": "1405.830",
                    "master_urx": "105.795",
                    "master_ury": "1407.690",
                    "llx": "3555.960",
                    "lly": "2241.985",
                    "urx": "3590.960",
                    "ury": "2243.845",
                    "transform_status": "DB_INSTANCE_TRANSFORM",
                },
            ]
            self._write_tsv(probe / "target_pg_pins.tsv", pin_fields, pin_rows)

            shape_fields = [
                "query_index",
                "hierarchy_depth",
                "top_instance",
                "hierarchy_path",
                "shape_type",
                "net",
                "layer",
                "purpose",
                "transform_status",
                "master_llx",
                "master_lly",
                "master_urx",
                "master_ury",
                "llx",
                "lly",
                "urx",
                "ury",
            ]
            shape_rows = [
                {
                    "query_index": "1",
                    "hierarchy_depth": "1",
                    "top_instance": "I6",
                    "hierarchy_path": "(I6 DVDD)",
                    "shape_type": "rect",
                    "net": "DVDD",
                    "layer": "METTP",
                    "purpose": "pin",
                    "transform_status": "DB_GET_HIER_PATH_TRANSFORM",
                    "master_llx": "30.795",
                    "master_lly": "1405.555",
                    "master_urx": "65.795",
                    "master_ury": "1407.690",
                    "llx": "3515.960",
                    "lly": "2241.710",
                    "urx": "3550.960",
                    "ury": "2243.845",
                },
                {
                    "query_index": "2",
                    "hierarchy_depth": "1",
                    "top_instance": "I6",
                    "hierarchy_path": "(I6 DVSS)",
                    "shape_type": "rect",
                    "net": "DVSS",
                    "layer": "METTP",
                    "purpose": "pin",
                    "transform_status": "DB_GET_HIER_PATH_TRANSFORM",
                    "master_llx": "70.795",
                    "master_lly": "1405.830",
                    "master_urx": "105.795",
                    "master_ury": "1407.690",
                    "llx": "3555.960",
                    "lly": "2241.985",
                    "urx": "3590.960",
                    "ury": "2243.845",
                },
                {
                    "query_index": "3",
                    "hierarchy_depth": "2",
                    "top_instance": "I6",
                    "hierarchy_path": "(I6 I3 obstruction)",
                    "shape_type": "pathSeg",
                    "net": "ABSENT",
                    "layer": "METTP",
                    "purpose": "drawing",
                    "transform_status": "DB_GET_HIER_PATH_TRANSFORM",
                    "master_llx": "114.835",
                    "master_lly": "1438.845",
                    "master_urx": "134.835",
                    "master_ury": "1448.845",
                    "llx": "3600.000",
                    "lly": "2275.000",
                    "urx": "3620.000",
                    "ury": "2285.000",
                },
                {
                    "query_index": "4",
                    "hierarchy_depth": "0",
                    "top_instance": "TOP",
                    "hierarchy_path": "topShape",
                    "shape_type": "rect",
                    "net": "SIGNAL",
                    "layer": "MET4",
                    "purpose": "drawing",
                    "transform_status": "TOP_CELLVIEW_IDENTITY",
                    "master_llx": "3610.000",
                    "master_lly": "2242.000",
                    "master_urx": "3620.000",
                    "master_ury": "2243.000",
                    "llx": "3610.000",
                    "lly": "2242.000",
                    "urx": "3620.000",
                    "ury": "2243.000",
                },
            ]
            self._write_tsv(
                probe / "corridor_hierarchical_shapes.tsv",
                shape_fields,
                shape_rows,
            )

            (floorplan / "digital_pg_access_status.rpt").write_text(
                "STATUS=PASS\n"
                "ASSEMBLY_FLOORPLAN_MODEL_STATUS=PASS\n"
                "ASSEMBLY_PRIMARY_WHITESPACE_SOURCE_BBOX_UM="
                "3662.535000 -123.715000 3951.791000 3289.077000\n"
                "REVIEW_CANDIDATE_PAIR_INSTANCE=I6\n"
                "REVIEW_CANDIDATE_PAIR_OWNER_SCOPE=INSTANCE\n"
                "TARGET_INSTANCE_METTP_CONTEXT_STATUS=NOT_PROBED\n"
                "BRIDGE_GEOMETRY_STATUS=NOT_AUTHORIZED\n"
                "NEXT_GATE=RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE\n",
                encoding="utf-8",
            )
            self._write_tsv(
                floorplan / "digital_pg_review_pair.tsv",
                [
                    "local_net",
                    "chip_net",
                    "instance",
                    "layer",
                    "purpose",
                    "llx",
                    "lly",
                    "urx",
                    "ury",
                ],
                [
                    {
                        "local_net": "VDD",
                        "chip_net": "DVDD",
                        "instance": "I6",
                        "layer": "METTP",
                        "purpose": "pin",
                        "llx": "3515.960",
                        "lly": "2241.710",
                        "urx": "3550.960",
                        "ury": "2243.845",
                    },
                    {
                        "local_net": "VSS",
                        "chip_net": "DVSS",
                        "instance": "I6",
                        "layer": "METTP",
                        "purpose": "pin",
                        "llx": "3555.960",
                        "lly": "2241.985",
                        "urx": "3590.960",
                        "ury": "2243.845",
                    },
                ],
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(CORRIDOR_CLASSIFIER),
                    "--probe-root",
                    str(probe),
                    "--floorplan-root",
                    str(floorplan),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = self._read_kv(output / "selected_i6_corridor_status.rpt")
            self.assertEqual(status["STATUS"], "PASS")
            self.assertEqual(status["TARGET_INSTANCE"], "I6")
            self.assertEqual(status["TARGET_PIN_PAIR_STATUS"], "PASS")
            self.assertEqual(
                status["TARGET_PIN_HIERARCHICAL_COVERAGE_STATUS"],
                "PASS",
            )
            self.assertEqual(
                status["DVDD_DIRECT_EAST_TO_WHITESPACE_STATUS"],
                "REJECT_TARGET_DVSS_INTERSECTION",
            )
            self.assertEqual(
                status["DVDD_DIRECT_DVSS_INTERSECTION_BBOX_UM"],
                "3555.960000 2241.985000 3590.960000 2243.845000",
            )
            self.assertEqual(status["BRIDGE_GEOMETRY_STATUS"], "NOT_AUTHORIZED")
            self.assertEqual(status["GENUS_AUTHORIZED"], "NO")
            self.assertEqual(status["INNOVUS_AUTHORIZED"], "NO")
            self.assertEqual(
                status["NEXT_GATE"],
                "RETURN_I6_CORRIDOR_EVIDENCE_FOR_BRIDGE_CANDIDATE_DEFINITION",
            )
            with (output / "corridor_search_regions.tsv").open(
                newline="",
                encoding="utf-8",
            ) as handle:
                regions = list(csv.DictReader(handle, delimiter="\t"))
            self.assertEqual(len(regions), 5)
            north = next(
                row
                for row in regions
                if row["region"] == "DVDD_NORTH_ESCAPE_SEARCH"
            )
            self.assertEqual(north["non_target_mettp_contact_count"], "1")
            manifest = subprocess.run(
                ["sha256sum", "-c", "SHA256SUMS"],
                cwd=output,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(manifest.returncode, 0, manifest.stdout)

            self._write_tsv(
                probe / "corridor_hierarchical_shapes.tsv",
                shape_fields,
                [shape_rows[0], shape_rows[2], shape_rows[3]],
            )
            query_status_path = probe / "corridor_query_status.rpt"
            query_status_path.write_text(
                query_status_path.read_text(encoding="utf-8").replace(
                    "HIERARCHICAL_SHAPE_ROW_COUNT=4",
                    "HIERARCHICAL_SHAPE_ROW_COUNT=3",
                ),
                encoding="utf-8",
            )
            rejected = root / "rejected_missing_vss"
            rejected_result = subprocess.run(
                [
                    sys.executable,
                    str(CORRIDOR_CLASSIFIER),
                    "--probe-root",
                    str(probe),
                    "--floorplan-root",
                    str(floorplan),
                    "--out",
                    str(rejected),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(rejected_result.returncode, 2)
            rejected_status = self._read_kv(
                rejected / "selected_i6_corridor_status.rpt"
            )
            self.assertEqual(rejected_status["STATUS"], "FAIL")
            self.assertIn(
                "did not recover exact VSS pin",
                rejected_status["ERROR"],
            )

    def test_selected_i6_corridor_probe_is_read_only_and_fail_closed(self) -> None:
        skill_path = (
            REPO
            / "TOP"
            / "pnr"
            / "scripts"
            / "probe_spadmic2_selected_pg_corridor.il"
        )
        wrapper_path = (
            REPO
            / "TOP"
            / "ci"
            / "server_probe_spadmic2_selected_pg_corridor.sh"
        )
        skill = skill_path.read_text(encoding="utf-8")
        wrapper = wrapper_path.read_text(encoding="utf-8")
        syntax = subprocess.run(
            ["bash", "-n", str(wrapper_path)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        self.assertEqual(syntax.returncode, 0, syntax.stdout)
        self.assertTrue(os.access(wrapper_path, os.X_OK))
        self.assertTrue(os.access(CORRIDOR_CLASSIFIER, os.X_OK))
        self.assertEqual(wrapper.count('"$VIRTUOSO_BIN" -nograph'), 1)
        self.assertIn(
            'dbOpenCellViewByType(libName cellName viewName "" "r")',
            skill,
        )
        self.assertIn("dbGetTrueOverlaps(cv queryBox t 0:32 t)", skill)
        self.assertIn("dbGetHierPathTransform(overlap)", skill)
        self.assertIn("dbTransformBBox(leaf~>bBox transform)", skill)
        self.assertIn("spadmicCorridorTopInstance(overlap)", skill)
        self.assertNotIn("dbSave", skill)
        self.assertNotIn("dbCreate", skill)
        self.assertNotIn("dbDelete", skill)
        self.assertIn("set +e", wrapper)
        self.assertIn("FLOORPLAN_MANIFEST_PRE_RC", wrapper)
        self.assertIn("SOURCE_STABILITY_RC", wrapper)
        self.assertIn('"$CHMOD_BIN" -R a-w "$RAW_ROOT"', wrapper)
        self.assertIn('"$CHMOD_BIN" -R a-w "$PROCESSED_ROOT"', wrapper)
        self.assertIn('"$CHMOD_BIN" -R a-w "$DIAGNOSTIC_ROOT"', wrapper)
        self.assertIn(
            "DVDD_DIRECT_EAST_TO_WHITESPACE_STATUS="
            "REJECT_TARGET_DVSS_INTERSECTION",
            wrapper,
        )
        self.assertIn("BRIDGE_GEOMETRY_STATUS=NOT_AUTHORIZED", wrapper)
        self.assertIn(
            "RETURN_I6_CORRIDOR_EVIDENCE_FOR_BRIDGE_CANDIDATE_DEFINITION",
            wrapper,
        )
        self.assertIn("DO_NOT_START_GENUS_INNOVUS_OR_EDIT_OA", wrapper)
        self.assertNotIn("\ngenus ", wrapper)
        self.assertNotIn("\ninnovus ", wrapper)
        self.assertNotIn("\nrm ", wrapper)
        self.assertNotIn("\nexit ", wrapper)
        self.assertNotIn("set -e", wrapper)

    def test_oa_processor_reconciles_physical_inputoutput_and_isolated_matrix_pins(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            audit = self._make_processor_audit(root, include_exact_pg=False)
            output = root / "processed"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PROCESSOR),
                    "--audit-root",
                    str(audit),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 2, result.stdout)
            status = self._read_kv(output / "assembly_audit_status.rpt")
            self.assertEqual(status["SOURCE_IDENTITY_GATE_STATUS"], "PASS")
            self.assertEqual(status["EXACT_MATRICE5_INSTANCE_GATE_STATUS"], "PASS")
            self.assertEqual(status["MATRIX_TERMINAL_PARITY_STATUS"], "PASS")
            self.assertEqual(status["UNKNOWN_FAMILY_GATE_STATUS"], "PASS")
            self.assertEqual(status["MATRIX_PROXY_PIN_ACCESS_STATUS"], "PASS")
            self.assertEqual(status["MATRIX_PROXY_PIN_SHAPE_COUNT"], "560")
            self.assertEqual(status["P03_INTERFACE_CONTRACT_STATUS"], "PASS")
            self.assertEqual(
                status["MATRIX_PROXY_COORDINATE_SOURCE"],
                "MATRICE5_TOP_TERMINALS_PLUS_R0_BBOX_TRANSLATION",
            )
            self.assertEqual(status["MATRIX_PROXY_TRANSFORM_STATUS"], "PASS")
            self.assertEqual(status["MATRIX_PROXY_TRANSLATION_UM"], "40.000000 60.000000")
            self.assertEqual(status["MATRICE5_INSTANCE_ORIENT"], "ABSENT")
            self.assertEqual(
                status["AUDIT_SCOPE"],
                "P00_P02_ENTRY_GATE_WITH_P03_PRECLASSIFICATION",
            )
            self.assertEqual(status["PG_ANCHOR_GATE_STATUS"], "FAIL")
            self.assertEqual(status["DIRECT_METTP_ATTRIBUTION_STATUS"], "FAIL")
            self.assertEqual(status["METTP_CONTEXT_REPORT_STATUS"], "PASS")
            self.assertEqual(
                status["METTP_CONTEXT_AUTHORIZATION"],
                "REVIEW_ONLY_NOT_A_PG_ANCHOR",
            )
            self.assertEqual(
                status["METTP_NETTED_AREA_OVERLAP_CANDIDATE_COUNT"],
                "1",
            )
            self.assertEqual(
                status["METTP_SAME_LAYER_EXACT_PG_CONTACT_CANDIDATE_COUNT"],
                "0",
            )
            self.assertEqual(status["P00_P02_IMPLEMENTATION_AUTHORIZED"], "NO")
            self.assertEqual(status["P03_IMPLEMENTATION_AUTHORIZED"], "NO")
            self.assertEqual(status["NEXT_GATE"], "STOP_AND_RECONCILE_PG_ANCHORS")

            with (output / "matrice5_terminal_family_contract.tsv").open(
                newline="",
                encoding="utf-8",
            ) as handle:
                family_rows = list(csv.DictReader(handle, delimiter="\t"))
            self.assertTrue(all(row["index_status"] == "PASS" for row in family_rows))
            self.assertTrue(all(row["direction_status"] == "PASS" for row in family_rows))
            self.assertTrue(all(row["physical_pin_status"] == "PASS" for row in family_rows))
            self.assertEqual(
                {row["direction_evidence"] for row in family_rows},
                {"OA_INPUTOUTPUT_WITH_CONTRACT_LOGICAL_DIRECTION"},
            )

            with (output / "matrice5_proxy_pin_access.tsv").open(
                newline="",
                encoding="utf-8",
            ) as handle:
                proxy_rows = list(csv.DictReader(handle, delimiter="\t"))
            r_zero = next(row for row in proxy_rows if row["terminal"] == "R<0>")
            self.assertEqual(r_zero["direction"], "OUTPUT")
            self.assertEqual(r_zero["oa_direction"], "inputOutput")
            self.assertEqual(
                (r_zero["llx"], r_zero["lly"], r_zero["urx"], r_zero["ury"]),
                ("31.000000", "41.000000", "31.100000", "41.100000"),
            )

            with (output / "matrice5_unknown_families.tsv").open(
                newline="",
                encoding="utf-8",
            ) as handle:
                unknown_rows = list(csv.DictReader(handle, delimiter="\t"))
            self.assertTrue(all(row["p03_status"] == "PASS" for row in unknown_rows))
            sti = next(row for row in unknown_rows if row["terminal"] == "STI<0>")
            self.assertEqual(sti["family"], "STI")
            self.assertEqual(sti["layers"], "PHODEF")
            self.assertEqual(sti["purposes"], "VERIFICATION")

            overlap_text = (output / "mettp_overlap_candidates.tsv").read_text(
                encoding="utf-8"
            )
            self.assertIn("DVDD\tMETTPL\tpin", overlap_text)
            self.assertIn("REVIEW_ONLY_NOT_A_PG_ANCHOR", overlap_text)
            with (output / "mettp_anchor_context_summary.tsv").open(
                newline="",
                encoding="utf-8",
            ) as handle:
                context_summary = list(csv.DictReader(handle, delimiter="\t"))
            self.assertEqual(len(context_summary), 1)
            self.assertEqual(context_summary[0]["orientation"], "HORIZONTAL")
            self.assertEqual(
                context_summary[0]["nearest_supply_like_net"],
                "DVDD",
            )
            self.assertEqual(
                context_summary[0]["context_status"],
                "REVIEW_ONLY_NOT_A_PG_ANCHOR",
            )
            manifest = subprocess.run(
                ["sha256sum", "-c", "SHA256SUMS"],
                cwd=output,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(manifest.returncode, 0, manifest.stdout)

    def test_oa_processor_requires_exact_pg_even_when_p03_interface_is_clean(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            audit = self._make_processor_audit(root, include_exact_pg=True)
            output = root / "processed"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PROCESSOR),
                    "--audit-root",
                    str(audit),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = self._read_kv(output / "assembly_audit_status.rpt")
            self.assertEqual(status["PG_ANCHOR_GATE_STATUS"], "PASS")
            self.assertEqual(status["P00_P02_IMPLEMENTATION_AUTHORIZED"], "YES")
            self.assertEqual(status["P03_INTERFACE_CONTRACT_STATUS"], "PASS")
            self.assertEqual(status["P03_IMPLEMENTATION_AUTHORIZED"], "YES")
            self.assertEqual(status["UNATTRIBUTED_METTP_SHAPE_COUNT"], "0")
            self.assertEqual(status["DIRECT_METTP_ATTRIBUTION_STATUS"], "PASS")
            self.assertEqual(
                status["METTP_NETTED_BOUNDARY_CONTACT_CANDIDATE_COUNT"],
                "0",
            )

    def test_oa_processor_reports_same_layer_touch_without_authorizing_pg(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            audit = self._make_processor_audit(root, include_exact_pg=False)
            with (audit / "spadmic2_top_shapes.tsv").open(
                "a",
                encoding="utf-8",
            ) as handle:
                handle.write(
                    "pathSeg\tVDD\tMETTP\tdrawing\t20\t10\t22\t12\n"
                )
            output = root / "processed"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PROCESSOR),
                    "--audit-root",
                    str(audit),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 2, result.stdout)
            status = self._read_kv(output / "assembly_audit_status.rpt")
            self.assertEqual(status["PG_ANCHOR_GATE_STATUS"], "FAIL")
            self.assertEqual(status["P00_P02_IMPLEMENTATION_AUTHORIZED"], "NO")
            self.assertEqual(
                status["METTP_NETTED_BOUNDARY_CONTACT_CANDIDATE_COUNT"],
                "1",
            )
            self.assertEqual(
                status["METTP_SAME_LAYER_EXACT_PG_CONTACT_CANDIDATE_COUNT"],
                "1",
            )
            with (output / "mettp_netted_shape_context.tsv").open(
                newline="",
                encoding="utf-8",
            ) as handle:
                context_rows = list(csv.DictReader(handle, delimiter="\t"))
            exact_touch = next(
                row
                for row in context_rows
                if row["selection_scope"] == "SAME_LAYER_NETTED_NEAREST"
                and row["candidate_net"] == "VDD"
            )
            self.assertEqual(exact_touch["candidate_net_class"], "EXACT_DIGITAL_PG")
            self.assertEqual(exact_touch["geometry_relation"], "BOUNDARY_TOUCH")
            self.assertEqual(
                exact_touch["authorization"],
                "REVIEW_ONLY_NOT_A_PG_ANCHOR",
            )

    def test_oa_processor_does_not_accept_mettp_labels_as_pg_geometry(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            audit = self._make_processor_audit(root, include_exact_pg=False)
            with (audit / "spadmic2_top_shapes.tsv").open(
                "a",
                encoding="utf-8",
            ) as handle:
                handle.write("label\tVDD\tMETTP\tpin\t2\t0\t4\t100\n")
                handle.write("label\tVSS\tMETTP\tpin\t6\t0\t8\t100\n")
            output = root / "processed"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PROCESSOR),
                    "--audit-root",
                    str(audit),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 2, result.stdout)
            status = self._read_kv(output / "assembly_audit_status.rpt")
            self.assertEqual(status["VDD_METTP_ANCHOR_COUNT"], "0")
            self.assertEqual(status["VSS_METTP_ANCHOR_COUNT"], "0")
            self.assertEqual(status["METTP_TOP_SHAPE_COUNT"], "1")
            self.assertEqual(status["PG_ANCHOR_GATE_STATUS"], "FAIL")

    def test_oa_processor_refuses_populated_output_without_mutation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            audit = self._make_processor_audit(root, include_exact_pg=False)
            output = root / "processed"
            output.mkdir()
            sentinel = output / "sentinel.txt"
            sentinel.write_text("preserve\n", encoding="utf-8")
            result = subprocess.run(
                [
                    sys.executable,
                    str(PROCESSOR),
                    "--audit-root",
                    str(audit),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 2, result.stdout)
            self.assertIn(
                "ERROR=immutable processor output already populated:",
                result.stdout,
            )
            self.assertEqual(sentinel.read_text(encoding="utf-8"), "preserve\n")
            self.assertEqual([path.name for path in output.iterdir()], ["sentinel.txt"])

    def test_oa_processor_rejects_unattributed_mettp_even_with_exact_pg(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            audit = self._make_processor_audit(root, include_exact_pg=True)
            with (audit / "spadmic2_top_shapes.tsv").open(
                "a",
                encoding="utf-8",
            ) as handle:
                handle.write(
                    "pathSeg\tABSENT\tMETTP\tdrawing\t10\t10\t20\t12\n"
                )
            output = root / "processed"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PROCESSOR),
                    "--audit-root",
                    str(audit),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 2, result.stdout)
            status = self._read_kv(output / "assembly_audit_status.rpt")
            self.assertEqual(status["VDD_METTP_ANCHOR_COUNT"], "1")
            self.assertEqual(status["VSS_METTP_ANCHOR_COUNT"], "1")
            self.assertEqual(status["UNATTRIBUTED_METTP_SHAPE_COUNT"], "1")
            self.assertEqual(status["PG_ANCHOR_GATE_STATUS"], "FAIL")

    def test_oa_processor_rejects_non_translation_matrix_transform(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            audit = self._make_processor_audit(root, include_exact_pg=True)
            instance_path = audit / "spadmic2_instances.tsv"
            instance_text = instance_path.read_text(encoding="utf-8")
            instance_path.write_text(
                instance_text.replace("\tABSENT\t30\t40\t", "\tR90\t30\t40\t"),
                encoding="utf-8",
            )
            output = root / "processed"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PROCESSOR),
                    "--audit-root",
                    str(audit),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = self._read_kv(output / "assembly_audit_status.rpt")
            self.assertEqual(status["P00_P02_IMPLEMENTATION_AUTHORIZED"], "YES")
            self.assertEqual(status["MATRIX_PROXY_PIN_ACCESS_STATUS"], "FAIL")
            self.assertEqual(status["MATRIX_PROXY_COORDINATE_SOURCE"], "UNAVAILABLE")
            self.assertEqual(status["MATRIX_PROXY_TRANSFORM_STATUS"], "FAIL")
            self.assertEqual(status["P03_INTERFACE_CONTRACT_STATUS"], "FAIL")
            self.assertEqual(status["P03_IMPLEMENTATION_AUTHORIZED"], "NO")

    def test_oa_processor_rejects_unknown_family_outside_reviewed_geometry(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            audit = self._make_processor_audit(root, include_exact_pg=True)
            terminal_path = audit / "matrice5_top_terminals.tsv"
            terminal_text = terminal_path.read_text(encoding="utf-8")
            terminal_path.write_text(
                terminal_text.replace(
                    "STI<0>\tinputOutput\tABSENT\tPHODEF\tVERIFICATION",
                    "STI<0>\tinputOutput\tABSENT\tMET3\tpin",
                ),
                encoding="utf-8",
            )
            output = root / "processed"
            result = subprocess.run(
                [
                    sys.executable,
                    str(PROCESSOR),
                    "--audit-root",
                    str(audit),
                    "--out",
                    str(output),
                ],
                cwd=REPO,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = self._read_kv(output / "assembly_audit_status.rpt")
            self.assertEqual(status["P00_P02_IMPLEMENTATION_AUTHORIZED"], "YES")
            self.assertEqual(status["UNKNOWN_FAMILY_GATE_STATUS"], "FAIL")
            self.assertEqual(status["P03_INTERFACE_CONTRACT_STATUS"], "FAIL")
            self.assertEqual(status["P03_IMPLEMENTATION_AUTHORIZED"], "NO")
            with (output / "matrice5_unknown_families.tsv").open(
                newline="",
                encoding="utf-8",
            ) as handle:
                unknown_rows = list(csv.DictReader(handle, delimiter="\t"))
            sti = next(row for row in unknown_rows if row["terminal"] == "STI<0>")
            self.assertEqual(sti["policy_evidence_status"], "FAIL")
            self.assertEqual(sti["p03_status"], "BLOCK")

    def test_matrice5_unknown_policy_matches_normalized_oa_families(self) -> None:
        with UNKNOWN_POLICY.open(newline="", encoding="utf-8") as handle:
            policy = {
                row["family"]: (
                    row["disposition"],
                    row["allowed_directions"],
                    row["allowed_layers"],
                    row["allowed_purposes"],
                )
                for row in csv.DictReader(handle)
            }
        self.assertEqual(
            policy,
            {
                "SUPPLY": (
                    "IGNORE_NON_DIGITAL",
                    "INPUTOUTPUT",
                    "MET2;MET3",
                    "DRAWING",
                ),
                "SUB": (
                    "IGNORE_NON_DIGITAL",
                    "INPUTOUTPUT",
                    "MET2;MET3",
                    "DRAWING",
                ),
                "VTUNE": (
                    "IGNORE_NON_DIGITAL",
                    "INPUTOUTPUT",
                    "MET2;MET3",
                    "DRAWING",
                ),
                "STI": (
                    "IGNORE_NON_DIGITAL",
                    "INPUTOUTPUT",
                    "PHODEF",
                    "VERIFICATION",
                ),
            },
        )

    def test_rtl_contains_exact_cumulative_tops_and_matrix_boundary(self) -> None:
        rtl = RTL.read_text(encoding="utf-8")
        for top in json.loads(CONTRACT.read_text(encoding="utf-8"))["phases"].values():
            self.assertEqual(rtl.count(f"module {top['top']} ("), 1)
        self.assertIn("spadmic_digital_assembly_v1_p01_position u_phase_p01", rtl)
        self.assertIn("spadmic_digital_assembly_v1_p02_event_control u_phase_p02", rtl)
        self.assertIn("spadmic_matrix_or_tree u_matrix_or_r", rtl)
        self.assertIn("spadmic_matrix_snapshot_frontend u_matrix_snapshot", rtl)
        self.assertIn("spadmic_matrix_reset_ctrl u_matrix_reset", rtl)
        self.assertIn("spadmic_matrix_cfg_ctrl u_matrix_cfg", rtl)
        self.assertIn("input  logic [2:0]                                  mptdc_ready_i", rtl)
        self.assertIn("input  logic                                        matrix_cfg_cmd_start_i", rtl)
        self.assertNotIn("spadmic_digital_assembly_v1_sequencer", rtl)

    def test_phase_generator_is_audit_bound_and_has_no_child_macros(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            audit = self._make_audit(root)
            for phase, expected_proxy_rows in (("p00_tx", 0), ("p03_matrix_interface", 2)):
                output = root / phase
                result = subprocess.run(
                    [sys.executable, str(GENERATOR), "--phase", phase, "--audit-root", str(audit), "--out", str(output)],
                    cwd=REPO,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stdout)
                status = (output / "assembly_phase_contract_status.rpt").read_text()
                config = (output / "assembly_phase_config.tcl").read_text()
                self.assertIn("IMPLEMENTATION=CUMULATIVE_SOFT_LOGIC", status)
                self.assertIn("HARD_MACRO_COUNT=0", status)
                self.assertIn("CHILD_GDS_MERGE_COUNT=0", status)
                self.assertIn("SIGNAL_ROUTE_LAYERS=MET1-MET3", status)
                self.assertIn("CHIP_POWER_NET_MAP=VDD:DVDD,VSS:DVSS", status)
                self.assertIn("variable hard_macro_count 0", config)
                self.assertIn("variable child_gds_merge_count 0", config)
                self.assertIn("set chip_power_net_map(VDD) {DVDD}", config)
                self.assertIn("set chip_power_net_map(VSS) {DVSS}", config)
                self.assertIn("set pg_anchors(VDD)", config)
                self.assertIn("set pg_anchors(VSS)", config)
                with (output / "matrix_proxy_pin_plan.tsv").open(newline="") as handle:
                    proxy_rows = list(csv.DictReader(handle, delimiter="\t"))
                self.assertEqual(len(proxy_rows), expected_proxy_rows)
                manifest = subprocess.run(
                    ["sha256sum", "-c", "SHA256SUMS"], cwd=output, text=True,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
                )
                self.assertEqual(manifest.returncode, 0, manifest.stdout)
            p03_proxy = (root / "p03_matrix_interface" / "matrix_proxy_pin_plan.tsv").read_text()
            self.assertIn("R_i[0]\tR<0>", p03_proxy)
            self.assertIn("matrix_din_o[0]\tDin<0>", p03_proxy)

    def test_server_flow_keeps_one_eda_action_per_review_gate(self) -> None:
        genus = (REPO / "TOP" / "ci" / "server_run_digital_assembly_phase_genus.sh").read_text()
        innovus = (REPO / "TOP" / "pnr" / "scripts" / "run_innovus_digital_assembly.sh").read_text()
        pvs = (REPO / "TOP" / "ci" / "server_run_digital_assembly_phase_pvs.sh").read_text()
        self.assertEqual(genus.count("genus -files TOP/syn/scripts/run_genus_matrix_block.tcl"), 1)
        self.assertEqual(innovus.count("innovus -nowin -init"), 1)
        self.assertEqual(pvs.count("bash TOP/pnr/scripts/run_pvs_drc_handoff.sh"), 1)
        self.assertEqual(pvs.count("bash TOP/pnr/scripts/run_pvs_lvs_handoff.sh"), 1)
        self.assertIn("density is authorized only for p03_matrix_interface", pvs)
        self.assertIn("DO_NOT_START_NEXT_PVS_MODE_UNTIL_REVIEWED", pvs)

    def test_oa_audit_avoids_unneeded_matrice5_internal_traversal(self) -> None:
        audit = (REPO / "TOP" / "pnr" / "scripts" / "audit_spadmic2_assembly_contract.il").read_text()
        self.assertIn(
            "procedure(spadmicAuditWriteInstancePins(cv path targetLib targetCell targetView)",
            audit,
        )
        self.assertIn("master~>libName == targetLib", audit)
        self.assertIn("master~>cellName == targetCell", audit)
        self.assertIn('if(role == "spadmic2" then', audit)
        self.assertIn("SPADMIC_OA_AUDIT_PROGRESS=WRITE_SPADMIC2_TOP_CONTRACT", audit)
        self.assertIn("SPADMIC_OA_AUDIT_PROGRESS=WRITE_MATRICE5_TOP_TERMINALS", audit)

    def test_oa_audit_uses_xfab_project_launch_context_and_completion_gate(self) -> None:
        wrapper = (
            REPO / "TOP" / "ci" / "server_audit_spadmic2_assembly_contract.sh"
        ).read_text()
        audit = (
            REPO / "TOP" / "pnr" / "scripts" / "audit_spadmic2_assembly_contract.il"
        ).read_text()
        self.assertIn(
            "SPADMIC_CADENCE_LAUNCH_DIR:-/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0",
            wrapper,
        )
        self.assertIn('ENTRY_HEAD="$(git rev-parse HEAD 2>/dev/null)"', wrapper)
        self.assertIn('[ "$ENTRY_HEAD" != "$ACTUAL_HEAD" ]', wrapper)
        self.assertIn("export SPADMIC_AUDIT_REEXECUTED=1", wrapper)
        self.assertIn(
            'exec bash "$REPO/TOP/ci/server_audit_spadmic2_assembly_contract.sh"',
            wrapper,
        )
        self.assertIn('CADENCE_CDS_LIB="$CADENCE_LAUNCH_DIR/cds.lib"', wrapper)
        self.assertIn(
            'SPADMIC2_SESSION_CDS_LIB="$DIAGNOSTIC_ROOT/spadmic2_session.cds.lib"',
            wrapper,
        )
        self.assertIn(
            'MATRICE5_SESSION_CDS_LIB="$DIAGNOSTIC_ROOT/matrice5_session.cds.lib"',
            wrapper,
        )
        self.assertIn('echo "INCLUDE $CADENCE_CDS_LIB"', wrapper)
        self.assertIn('echo "UNDEFINE SPADMIC"', wrapper)
        self.assertIn('echo "DEFINE SPADMIC $MATRIX_OA_LIBRARY_PATH"', wrapper)
        self.assertIn('cd "$CADENCE_LAUNCH_DIR"', wrapper)
        self.assertIn('-cdslib "$session_cds_lib"', wrapper)
        self.assertIn('SPADMIC_OA_AUDIT_ROLE="$role"', wrapper)
        self.assertIn(
            'run_oa_role \\\n        matrice5 \\\n        "$MATRICE5_SESSION_CDS_LIB"',
            wrapper,
        )
        self.assertIn(
            'run_oa_role \\\n        spadmic2 \\\n        "$SPADMIC2_SESSION_CDS_LIB"',
            wrapper,
        )
        self.assertIn(
            '-restore "$REPO/TOP/pnr/scripts/audit_spadmic2_assembly_contract.il"',
            wrapper,
        )
        self.assertIn("</dev/null", wrapper)
        self.assertIn(
            "EXPECTED_XFAB_COMMAND=xfab -p Prj_xh018 -t xh018 -m 1131 -y 2023 -v",
            wrapper,
        )
        self.assertIn('"$RAW_ROOT/virtuoso_export_status.rpt"', wrapper)
        self.assertIn('"$RAW_ROOT/matrice5_virtuoso_export_status.rpt"', wrapper)
        self.assertIn('"$RAW_ROOT/spadmic2_virtuoso_export_status.rpt"', wrapper)
        self.assertIn('export SPADMIC_OA_MATRIX_LIBRARY=SPADMIC', wrapper)
        self.assertIn("OA_EXTRACTION_PROCESS_COUNT=2", wrapper)
        self.assertIn("OA_EXTRACTION_PROCESS_ORDER=matrice5,spadmic2", wrapper)
        self.assertIn("SOURCE_IDENTITY_COMBINE_RC", wrapper)
        self.assertIn("grep -Fxq 'STATUS=PASS'", wrapper)
        self.assertIn(
            "CADENCE_SESSION_CDS_LIB_MODE=PROCESS_ISOLATED_SOURCE_BINDINGS",
            wrapper,
        )
        self.assertIn("SOURCE_CDS_LIB_MUTATION_AUTHORIZED=NO", wrapper)
        self.assertIn('role = getShellEnvVar("SPADMIC_OA_AUDIT_ROLE")', audit)
        self.assertIn(
            'unless(role == "spadmic2" || role == "matrice5"',
            audit,
        )
        self.assertIn(
            'identityPath = strcat(outRoot "/" role "_source_identity.tsv")',
            audit,
        )
        self.assertNotIn('identityPath = strcat(outRoot "/source_identity.tsv")', audit)
        self.assertIn("runResult = errset(spadmicAuditAssemblyMain() t)", audit)
        self.assertIn('fprintf(statusFp "STATUS=FAIL\\n")', audit)
        self.assertIn("SPADMIC_OA_AUDIT_COMPLETION_STATUS=PASS", audit)
        self.assertNotIn("dbSave(", audit)
        self.assertNotIn("dbCreate", audit)
        self.assertNotIn("dbDelete", audit)

    def test_oa_skill_text_sanitizers_use_ic23_rex_contract(self) -> None:
        for relative_path in (
            "audit_spadmic2_assembly_contract.il",
            "insert_digital_assembly_p03_into_spadmic2.il",
        ):
            skill = (REPO / "TOP" / "pnr" / "scripts" / relative_path).read_text()
            self.assertIn('rexCompile("[\\t\\n\\r]")', skill)
            self.assertIn('rexReplace(text " " 0)', skill)
            self.assertNotIn('rexReplace(text "[\\t\\n\\r]" " " 0)', skill)

    def test_oa_audit_preserves_exact_source_stability_deltas(self) -> None:
        wrapper = (
            REPO / "TOP" / "ci" / "server_audit_spadmic2_assembly_contract.sh"
        ).read_text()
        self.assertIn("! -name '.nfs*'", wrapper)
        self.assertIn("! -name '*.cdslck'", wrapper)
        self.assertIn("! -name '*.cdslck.*'", wrapper)
        self.assertIn("! -name '*.oa.*.oacache'", wrapper)
        self.assertNotIn("! -name '*.oacache'", wrapper)
        self.assertIn("POLICY=CANONICAL_OA_CONTENT_V2", wrapper)
        self.assertIn(
            'echo "EXCLUDED_BASENAME_PATTERN=*.oa.*.oacache"',
            wrapper,
        )
        self.assertIn('source_inventory_policy.rpt"', wrapper)
        self.assertIn('> "$DIAGNOSTIC_ROOT/spadmic2_source_delta.rpt"', wrapper)
        self.assertIn('> "$DIAGNOSTIC_ROOT/matrice5_source_delta.rpt"', wrapper)
        self.assertIn("SPADMIC2_SOURCE_DELTA_REPORT=", wrapper)
        self.assertIn("MATRICE5_SOURCE_DELTA_REPORT=", wrapper)

    def test_oa_audit_pins_and_self_tests_checksum_executable(self) -> None:
        wrapper_path = (
            REPO / "TOP" / "ci" / "server_audit_spadmic2_assembly_contract.sh"
        )
        wrapper = wrapper_path.read_text()
        syntax = subprocess.run(
            ["bash", "-n", str(wrapper_path)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        self.assertEqual(syntax.returncode, 0, syntax.stdout)
        self.assertIn('SHA256SUM_BIN="$(type -P sha256sum 2>/dev/null)"', wrapper)
        self.assertIn("SPADMIC_SHA256_SELFTEST_V1", wrapper)
        self.assertIn(
            "8f07d5176d42a4f11c17a591edc7e38026d0b4e4a31366b9e5a807b5e70cecd5",
            wrapper,
        )
        self.assertIn('"$SHA256SUM_BIN" -c SHA256SUMS', wrapper)
        self.assertIn("PAYLOAD_MUTATION_AUTHORIZED=NO", wrapper)
        self.assertNotIn("xargs -0 -r sha256sum", wrapper)

    def test_oa_audit_archives_and_read_only_seals_verified_payloads(self) -> None:
        wrapper = (
            REPO / "TOP" / "ci" / "server_audit_spadmic2_assembly_contract.sh"
        ).read_text()
        raw_manifest = wrapper.index('create_directory_manifest "$RAW_ROOT"')
        processor = wrapper.index(
            'python3 "$REPO/TOP/pnr/scripts/process_spadmic2_assembly_audit.py"'
        )
        raw_read_only_seal = wrapper.index(
            '"$CHMOD_BIN" -R a-w "$RAW_ROOT"'
        )
        post_processor = wrapper.index(
            'RAW_MANIFEST_POST_PROCESS_RC=$?', processor
        )
        processed_read_only_seal = wrapper.index(
            '"$CHMOD_BIN" -R a-w "$PROCESSED_ROOT"'
        )
        archive = wrapper.index(
            '"$TAR_BIN" -czf evidence_payload.tar.gz'
        )
        post_archive = wrapper.index(
            'RAW_MANIFEST_POST_ARCHIVE_RC=$?', archive
        )
        outer_manifest = wrapper.index(
            'create_outer_manifest "$DIAGNOSTIC_ROOT"'
        )
        read_only_seal = wrapper.index(
            '"$CHMOD_BIN" -R a-w "$DIAGNOSTIC_ROOT"'
        )
        post_seal = wrapper.index(
            'POST_SEAL_MANIFEST_RC=$?', read_only_seal
        )
        self.assertLess(raw_manifest, processor)
        self.assertLess(raw_manifest, raw_read_only_seal)
        self.assertLess(raw_read_only_seal, processor)
        self.assertLess(processor, post_processor)
        self.assertLess(post_processor, processed_read_only_seal)
        self.assertLess(processed_read_only_seal, archive)
        self.assertLess(post_processor, archive)
        self.assertLess(archive, post_archive)
        self.assertLess(post_archive, outer_manifest)
        self.assertLess(outer_manifest, read_only_seal)
        self.assertLess(read_only_seal, post_seal)
        self.assertIn("evidence_payload.tar.gz.sha256", wrapper)
        self.assertIn("RECOVERY_ARCHIVE_TAR_VERIFY_RC", wrapper)
        self.assertIn("PROCESSED_MANIFEST_POST_ARCHIVE_RC", wrapper)
        self.assertIn('RUN_ID="${TIMESTAMP}_pid$$"', wrapper)
        self.assertIn('mkdir "$DIAGNOSTIC_ROOT"', wrapper)
        self.assertNotIn('mkdir -p "$RAW_ROOT" "$PROCESSED_ROOT"', wrapper)
        self.assertIn(
            '[ "$DIAGNOSTIC_ROOT_CREATE_RC" = "0" ] && \\\n'
            '   [ -d "$DIAGNOSTIC_ROOT" ]',
            wrapper,
        )
        self.assertIn("! -path './SHA256SUMS'", wrapper)
        self.assertIn("READ_ONLY_MODE_GATE_RC", wrapper)
        self.assertIn("SPADMIC2_MATRICE5_EVIDENCE_PRESERVATION_STATUS=PASS", wrapper)
        self.assertIn("EVIDENCE_ROOT_REUSE_AUTHORIZED=NO", wrapper)
        self.assertIn(
            '[ "$RUN_OK" = "1" ] && [ "$EVIDENCE_PRESERVATION_RC" = "0" ]',
            wrapper,
        )

    def test_mettp_context_replay_is_processor_only_and_source_immutable(self) -> None:
        wrapper_path = (
            REPO
            / "TOP"
            / "ci"
            / "server_replay_spadmic2_mettp_context.sh"
        )
        wrapper = wrapper_path.read_text()
        syntax = subprocess.run(
            ["bash", "-n", str(wrapper_path)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        self.assertEqual(syntax.returncode, 0, syntax.stdout)
        self.assertTrue(os.access(wrapper_path, os.X_OK))
        self.assertIn('verify_manifest "$SOURCE_ROOT"', wrapper)
        self.assertIn('verify_manifest "$RAW_ROOT"', wrapper)
        self.assertIn('mkdir "$REPLAY_ROOT"', wrapper)
        self.assertNotIn('mkdir -p "$REPLAY_ROOT"', wrapper)
        self.assertIn('python3 "$PROCESSOR"', wrapper)
        self.assertIn('[ "$PROCESS_RC" = "2" ]', wrapper)
        self.assertIn('"$CHMOD_BIN" -R a-w "$REPLAY_ROOT"', wrapper)
        self.assertNotIn('"$CHMOD_BIN" -R a-w "$SOURCE_ROOT"', wrapper)
        self.assertIn("SOURCE_MANIFEST_POST_RC", wrapper)
        self.assertIn("RAW_MANIFEST_POST_RC", wrapper)
        self.assertIn(
            "PROCESSOR_ONLY_METTP_CONTEXT_STATUS=$REPLAY_STATUS",
            wrapper,
        )
        self.assertIn("PASS_EVIDENCE_READY", wrapper)
        self.assertIn("DO_NOT_START_CADENCE_GENUS_OR_EDIT_OA", wrapper)
        self.assertNotIn("virtuoso ", wrapper)
        self.assertNotIn("genus ", wrapper)
        self.assertNotIn("innovus ", wrapper)
        self.assertNotIn("\nrm ", wrapper)

    def test_innovus_flow_rejects_child_macro_implementation(self) -> None:
        tcl = (REPO / "TOP" / "pnr" / "scripts" / "run_innovus_digital_assembly.tcl").read_text()
        wrapper = (REPO / "TOP" / "pnr" / "scripts" / "run_innovus_digital_assembly.sh").read_text()
        self.assertIn("SPADMIC_DA_HARD_MACRO_GATE_FAILED", tcl)
        self.assertIn("HARD_MACRO_COUNT", tcl)
        self.assertIn("CHILD_GDS_MERGE_COUNT=0", wrapper)
        self.assertIn("setNanoRouteMode -routeBottomRoutingLayer 1", tcl)
        self.assertIn("setNanoRouteMode -routeTopRoutingLayer 3", tcl)
        self.assertIn("METTP_POLICY PG_AND_BOUNDED_PIN_ACCESS_ONLY", tcl)

    def test_clean_ooc_pg_uses_exact_geometry_before_signal_route(self) -> None:
        tcl = (REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_harden_block.tcl").read_text()
        wrapper = (REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_harden_block.sh").read_text()
        self.assertIn("$vdd_cx - $core_margin - $strap_width / 2.0", tcl)
        self.assertIn("$vss_cx - $core_margin - $strap_width / 2.0", tcl)
        self.assertIn("add_shape -net $net -layer $layer -shape STRIPE", tcl)
        self.assertIn("-corePinCheckStdcellGeoms", tcl)
        self.assertIn("SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS", tcl)
        self.assertIn("SPADMIC_OOC_PG_DIRECT_VIA_AREAS", tcl)
        self.assertIn("-via_rows 1 -via_columns 1", tcl)
        self.assertIn("setViaGenMode -area_only 0", tcl)
        self.assertIn("PG_DIRECT_VIA_PRE_CTS_CONNECTIVITY_STATUS", tcl)
        self.assertIn("PG_DIRECT_VIA_PRE_CTS_DRC_STATUS", tcl)
        self.assertIn("SPADMIC_OOC_PRE_CTS_EXPECTED_DANGLING_COUNT", tcl)
        self.assertIn("SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH", tcl)
        self.assertIn("EXPECTED_DANGLING_ONLY", tcl)
        self.assertIn("SROUTE_PG_POST_FILLER", tcl)
        self.assertIn("PG_POST_FILLER_CONNECTIVITY_STATUS", tcl)
        self.assertIn("PG_POST_FILLER_DRC_STATUS", tcl)
        self.assertLess(
            tcl.index("        spadmic_ooc_route_pg\n"),
            tcl.index("    spadmic_ooc_cts_design\n"),
        )
        self.assertLess(
            tcl.index("    spadmic_ooc_route_pg\n"),
            tcl.index("    spadmic_ooc_route_design\n"),
        )
        self.assertLess(
            tcl.index("    spadmic_ooc_add_fillers\n"),
            tcl.index("        spadmic_ooc_post_filler_pg_restitch\n"),
        )
        self.assertLess(
            tcl.index("        spadmic_ooc_post_filler_pg_restitch\n"),
            tcl.index("    spadmic_ooc_route_design\n"),
        )
        self.assertIn("--required-merge \"$SPADMIC_STDCELL_GDS\"", wrapper)
        self.assertIn('[[ "$gds_audit_rc" -eq 0 ]]', wrapper)
        self.assertIn("</dev/null", wrapper)
        self.assertIn('summary_route_profile="$(status_value ROUTE_PROFILE)"', wrapper)
        self.assertIn('summary_signal_route_layers="$(status_value SIGNAL_ROUTE_LAYERS)"', wrapper)
        self.assertIn('summary_pg_local_route_mode="$(status_value PG_LOCAL_ROUTE_MODE)"', wrapper)
        self.assertIn('summary_pg_route_strategy="$(status_value PG_ROUTE_STRATEGY)"', wrapper)
        self.assertIn('echo "- OOC route profile: \\`$summary_route_profile\\`"', wrapper)
        self.assertIn('echo "- Local PG route mode: \\`$summary_pg_local_route_mode\\`"', wrapper)
        self.assertNotIn('echo "- OOC route profile: \\`${SPADMIC_OOC_ROUTE_PROFILE:-default}\\`"', wrapper)

    def test_pg_geometry_fix_preserves_signal_implementation(self) -> None:
        script = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.tcl"
        ).read_text()
        self.assertIn("add_shape -net VDD -layer METTP -shape STRIPE", script)
        self.assertIn("add_shape -net VSS -layer METTP -shape STRIPE", script)
        self.assertIn("sroute -connect {corePin}", script)
        self.assertNotIn("blockPin", script)
        for forbidden in ("routeDesign", "placeDesign", "ccopt_design", "clockDesign"):
            self.assertNotIn(forbidden, script)

    def test_pg_geometry_fix_uses_marker_derived_extents(self) -> None:
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        ).read_text()
        self.assertIn("SPADMIC_PG_FIX_VDD_X_FALLBACK_UM:-858.480", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VSS_X_FALLBACK_UM:-2574.880", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VDD_Y0_UM:-10.080", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VSS_Y0_UM:-14.560", wrapper)
        self.assertIn("SPADMIC_PG_FIX_Y1_UM:-180.880", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VDD_HELPER_Y0_UM:-126.560", wrapper)
        self.assertIn("SPADMIC_PG_FIX_VDD_HELPER_Y1_UM:-153.440", wrapper)

    def test_pg_helper_candidates_use_fresh_innovus_processes(self) -> None:
        script = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.tcl"
        ).read_text()
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        ).read_text()
        self.assertEqual(script.count("restoreDesign"), 1)
        self.assertNotIn("restore_db_stop_at_design_in_memory", script + wrapper)
        self.assertIn("for CANDIDATE_X in", wrapper)
        self.assertIn("SPADMIC_PG_FIX_TRIAL_MODE=1", wrapper)
        self.assertIn("SPADMIC_PG_FIX_TRIAL_MODE=0", wrapper)
        self.assertIn("ACCEPT_FOR_CANONICAL_REPLAY", wrapper)
        self.assertIn("ONE_INNOVUS_PROCESS_PER_CANDIDATE", script)

    def test_pg_helper_candidates_are_fail_closed(self) -> None:
        script = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.tcl"
        ).read_text()
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        ).read_text()
        self.assertIn("PG_HELPER_CANDIDATE_REJECTED", script)
        self.assertIn("NOT_RUN_CANDIDATE_TRIAL", script)
        self.assertIn('status(PG_CONNECTIVITY_STATUS) ne "PASS"', script)
        self.assertIn('status(PG_MARKER_COUNT) != 0', script)
        self.assertIn('status(REGULAR_CONNECTIVITY_STATUS) ne "PASS"', script)
        self.assertIn('status(INNOVUS_DRC_STATUS) ne "PASS"', script)
        self.assertIn('TRIAL_PG" == "0"', wrapper)
        self.assertIn('TRIAL_MARKERS" == "0"', wrapper)
        self.assertIn('TRIAL_REGULAR" == "0"', wrapper)
        self.assertIn('TRIAL_DRC" == "0"', wrapper)
        self.assertIn("FAIL_NO_CLEAN_CANDIDATE", wrapper)

    def test_pg_wrapper_replays_clean_trial_in_fresh_process(self) -> None:
        wrapper = REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_geometry_fix.sh"
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            checkpoint = root / "source" / "checkpoints" / "05_postroute_export.enc.dat"
            checkpoint.mkdir(parents=True)
            stream_map = root / "stream.map"
            stdcell_gds = root / "stdcells.gds"
            stream_map.write_text("map\n")
            stdcell_gds.write_text("gds\n")

            calls = root / "innovus_calls.tsv"
            fake_bin = root / "bin"
            fake_bin.mkdir()
            fake_innovus = fake_bin / "innovus"
            fake_innovus.write_text(
                "#!/usr/bin/env bash\n"
                "set -u\n"
                "printf '%s\\t%s\\n' \"$SPADMIC_PG_FIX_TRIAL_MODE\" "
                "\"$SPADMIC_PG_FIX_RUN_ROOT\" >>\"$FAKE_INNOVUS_CALLS\"\n"
                "mkdir -p \"$SPADMIC_PG_FIX_RUN_ROOT/reports\"\n"
                "if [[ \"$SPADMIC_PG_FIX_TRIAL_MODE\" == 1 ]]; then\n"
                "  {\n"
                "    echo STATUS=PASS\n"
                "    echo RESULT=PG_HELPER_CANDIDATE_CLEAN\n"
                "    echo PG_CONNECTIVITY_VIOLATION_COUNT=0\n"
                "    echo PG_MARKER_COUNT=0\n"
                "    echo REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
                "    echo DRC_MARKER_TOTAL=0\n"
                "  } >\"$SPADMIC_PG_FIX_RUN_ROOT/reports/pg_geometry_fix_status.rpt\"\n"
                "  exit 0\n"
                "fi\n"
                "{\n"
                "  echo STATUS=FAIL\n"
                "  echo RESULT=CANONICAL_REPLAY_TEST_STOP\n"
                "} >\"$SPADMIC_PG_FIX_RUN_ROOT/reports/pg_geometry_fix_status.rpt\"\n"
                "exit 8\n"
            )
            fake_innovus.chmod(0o755)

            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{fake_bin}:{env.get('PATH', '')}",
                    "FAKE_INNOVUS_CALLS": str(calls),
                    "SPADMIC_WORK_ROOT": str(root / "work"),
                    "SPADMIC_STREAMOUT_MAP_FILE": str(stream_map),
                    "SPADMIC_STDCELL_GDS": str(stdcell_gds),
                    "SPADMIC_PG_FIX_VDD_HELPER_CANDIDATES_UM": "970.480 746.480",
                }
            )
            result = subprocess.run(
                [str(wrapper), str(root / "source"), "tx_ddr_strip", "pg_process_test"],
                cwd=REPO,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )

            self.assertEqual(result.returncode, 8, result.stdout)
            invocation_rows = [line.split("\t") for line in calls.read_text().splitlines()]
            self.assertEqual([row[0] for row in invocation_rows], ["1", "0"])
            self.assertNotEqual(invocation_rows[0][1], invocation_rows[1][1])
            self.assertIn("/trials/trial_01_x_970p480", invocation_rows[0][1])
            self.assertTrue(invocation_rows[1][1].endswith("/innovus/pg_process_test"))

            run_root = root / "work" / "innovus" / "pg_process_test"
            candidate_summary = (run_root / "reports" / "vdd_helper_candidate_summary.tsv").read_text()
            self.assertIn("ACCEPT_FOR_CANONICAL_REPLAY", candidate_summary)
            self.assertEqual(list((run_root / "trials" / "trial_01_x_970p480" / "outputs").iterdir()), [])
            wrapper_status = (run_root / "reports" / "pg_geometry_fix_wrapper_status.rpt").read_text()
            self.assertIn("CANONICAL_REPLAY=RUN", wrapper_status)
            self.assertIn("CANONICAL_INNOVUS_RC=8", wrapper_status)


if __name__ == "__main__":
    unittest.main()
