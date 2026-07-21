#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import re
import struct
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
COLLECTOR = (
    REPO / "TOP" / "pnr" / "scripts" / "collect_position_pvs_gds_layer_applicability.py"
)
WRAPPER = (
    REPO / "TOP" / "ci" / "server_review_position_core_pvs_drc_gds_layer_applicability.sh"
)


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def record(record_type: int, data_type: int = 0, payload: bytes = b"") -> bytes:
    length = len(payload) + 4
    if length % 2:
        payload += b"\0"
        length += 1
    return struct.pack(">HBB", length, record_type, data_type) + payload


def gds_string(value: str) -> bytes:
    return value.encode("ascii")


def geometry(kind: int, purpose_record: int, layer: int, datatype: int) -> bytes:
    return b"".join(
        [
            record(kind),
            record(0x0D, 2, struct.pack(">h", layer)),
            record(purpose_record, 2, struct.pack(">h", datatype)),
            record(0x10, 3, struct.pack(">10l", 0, 0, 10, 0, 10, 10, 0, 10, 0, 0)),
            record(0x11),
        ]
    )


def structure(name: str, body: bytes) -> bytes:
    return b"".join(
        [
            record(0x05, 2, struct.pack(">12h", *([0] * 12))),
            record(0x06, 6, gds_string(name)),
            body,
            record(0x07),
        ]
    )


def reference(name: str) -> bytes:
    return b"".join(
        [
            record(0x0A),
            record(0x12, 6, gds_string(name)),
            record(0x10, 3, struct.pack(">2l", 0, 0)),
            record(0x11),
        ]
    )


def library(structures: list[bytes]) -> bytes:
    return b"".join(
        [
            record(0x00, 2, struct.pack(">h", 600)),
            record(0x01, 2, struct.pack(">12h", *([0] * 12))),
            record(0x02, 6, gds_string("fixture")),
            record(0x03, 5, b"\0" * 16),
            *structures,
            record(0x04),
        ]
    )


class PositionPvsGdsLayerApplicabilityTest(unittest.TestCase):
    def build_fixture(
        self,
        root: Path,
        reachable_target: bool = False,
        unreachable_target: bool = False,
    ) -> dict[str, Path]:
        gds = root / "spadmic_position_core.gds"
        deck = root / "xh018_DRC.rul"
        stream_map = root / "pnr_streamout.map"

        child_body = geometry(0x08, 0x0E, 8, 0)
        if reachable_target:
            child_body += geometry(0x08, 0x0E, 221, 5)
        structures = [
            structure("position_leaf", child_body),
            structure("spadmic_position_core", reference("position_leaf")),
        ]
        if unreachable_target:
            structures.append(
                structure("unused_pad_library_cell", geometry(0x08, 0x0E, 221, 5))
            )
        gds.write_bytes(library(structures))

        deck.write_text(
            "layer_map 37 -datatype 0 50370\n"
            "layer_def pad 50370\n"
            "layer_map 221 -datatype 5 22150\n"
            "layer_def pimide 22150\n"
            "layer_map 222 -datatype 0 22200\n"
            "layer_def nopim 22200\n"
        )
        stream_map.write_text(
            "PAD drawing 37 0\n"
            "PIMIDE drawing 221 5\n"
            "NOPIM drawing 222 0\n"
        )
        return {"gds": gds, "deck": deck, "stream_map": stream_map}

    def command(self, paths: dict[str, Path], output: Path) -> list[str]:
        return [
            "python3",
            str(COLLECTOR),
            "--gds",
            str(paths["gds"]),
            "--stream-map",
            str(paths["stream_map"]),
            "--drc-rule",
            str(paths["deck"]),
            "--output-dir",
            str(output),
            "--expected-gds-sha",
            file_sha(paths["gds"]),
            "--expected-stream-map-sha",
            file_sha(paths["stream_map"]),
            "--expected-drc-sha",
            file_sha(paths["deck"]),
        ]

    def test_zero_reachable_target_geometry_is_ready_for_manual_authorization(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            paths = self.build_fixture(root)
            output = root / "output"
            before = {name: file_sha(path) for name, path in paths.items()}

            result = subprocess.run(
                self.command(paths, output), text=True, capture_output=True, check=False
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(before, {name: file_sha(path) for name, path in paths.items()})
            status = (output / "gds_layer_applicability_collector_status.rpt").read_text()
            self.assertIn("COLLECTOR_STATUS=PASS", status)
            self.assertIn("GDS_PARSE_STATUS=PASS", status)
            self.assertIn("GDS_HIERARCHY_STATUS=PASS", status)
            self.assertIn("PAD_GDS_LAYER=37", status)
            self.assertIn("PIMIDE_GDS_LAYER=221", status)
            self.assertIn("PIMIDE_GDS_DATATYPE=5", status)
            self.assertIn("PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT=0", status)
            self.assertIn("PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=0", status)
            self.assertIn(
                "PIMIDE_POSITION_APPLICABILITY_STATUS="
                "NOT_APPLICABLE_NO_REACHABLE_PAD_OR_PIMIDE_GEOMETRY",
                status,
            )
            self.assertIn(
                "STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=READY_FOR_MANUAL_AUTHORIZATION",
                status,
            )
            self.assertIn("STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO", status)
            self.assertIn("PVS_EXECUTED=NO", status)

    def test_reachable_pimide_geometry_holds_authorization_without_failing_collection(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            paths = self.build_fixture(root, reachable_target=True)
            output = root / "output"

            result = subprocess.run(
                self.command(paths, output), text=True, capture_output=True, check=False
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            status = (output / "gds_layer_applicability_collector_status.rpt").read_text()
            self.assertIn("COLLECTOR_STATUS=PASS", status)
            self.assertIn("PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=1", status)
            self.assertIn(
                "PIMIDE_POSITION_APPLICABILITY_STATUS="
                "REVIEW_REQUIRED_REACHABLE_PAD_OR_PIMIDE_GEOMETRY_PRESENT",
                status,
            )
            self.assertIn("STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=HOLD", status)

    def test_unreachable_library_geometry_does_not_count_as_position_geometry(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            paths = self.build_fixture(root, unreachable_target=True)
            output = root / "output"

            result = subprocess.run(
                self.command(paths, output), text=True, capture_output=True, check=False
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            status = (output / "gds_layer_applicability_collector_status.rpt").read_text()
            self.assertIn("PIMIDE_ALL_GEOMETRY_ELEMENT_COUNT=1", status)
            self.assertIn("PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=0", status)
            structures = (output / "gds_structure_inventory.tsv").read_text()
            self.assertRegex(structures, r"(?m)^unused_pad_library_cell\tNO\t")

    def test_event_subject_uses_event_labels_without_changing_analysis(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            paths = self.build_fixture(root)
            output = root / "output"
            command = self.command(paths, output)
            command.extend(
                [
                    "--subject-label",
                    "event",
                    "--top-structure",
                    "spadmic_position_core",
                ]
            )

            result = subprocess.run(
                command, text=True, capture_output=True, check=False
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            status = (output / "gds_layer_applicability_collector_status.rpt").read_text()
            policy = (output / "event_option_policy_contract.rpt").read_text()
            self.assertIn(
                "LABEL=SPADMIC_EVENT_PVS_DRC_GDS_LAYER_APPLICABILITY_COLLECTOR",
                status,
            )
            self.assertIn(
                "PIMIDE_EVENT_APPLICABILITY_STATUS="
                "NOT_APPLICABLE_NO_REACHABLE_PAD_OR_PIMIDE_GEOMETRY",
                status,
            )
            self.assertIn("LABEL=SPADMIC_EVENT_PVS_DRC_OPTION_POLICY_CONTRACT", policy)
            self.assertIn(
                "DUMMY_FILL_POLICY=NO_VIRTUAL_DUMMY_GENERATION_DURING_EVENT_OOC_DRC",
                policy,
            )

    def test_malformed_gds_fails_closed_and_keeps_pvs_unauthorized(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            paths = self.build_fixture(root)
            paths["gds"].write_bytes(paths["gds"].read_bytes()[:-4])
            output = root / "output"

            result = subprocess.run(
                self.command(paths, output), text=True, capture_output=True, check=False
            )

            self.assertNotEqual(result.returncode, 0)
            status = (output / "gds_layer_applicability_collector_status.rpt").read_text()
            self.assertIn("COLLECTOR_STATUS=FAIL", status)
            self.assertIn("GDS_PARSE_STATUS=FAIL", status)
            self.assertIn("STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO", status)
            self.assertIn("PVS_EXECUTED=NO", status)

    def test_pinned_hash_mismatch_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            paths = self.build_fixture(root)
            output = root / "output"
            command = self.command(paths, output)
            command[command.index("--expected-stream-map-sha") + 1] = "0" * 64

            result = subprocess.run(command, text=True, capture_output=True, check=False)

            self.assertNotEqual(result.returncode, 0)
            status = (output / "gds_layer_applicability_collector_status.rpt").read_text()
            self.assertIn("KNOWN_SOURCE_HASH_GATE_STATUS=FAIL", status)
            self.assertIn("PVS_EXECUTED=NO", status)

    def test_missing_required_deck_mapping_fails_with_numbered_context(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            paths = self.build_fixture(root)
            paths["deck"].write_text(
                "layer_def pad 50370\n"
                "layer_map 221 -datatype 5 22150\n"
                "layer_def pimide 22150\n"
            )
            output = root / "output"

            result = subprocess.run(
                self.command(paths, output), text=True, capture_output=True, check=False
            )

            self.assertNotEqual(result.returncode, 0)
            status = (output / "gds_layer_applicability_collector_status.rpt").read_text()
            self.assertIn("TARGET_LAYER_MAPPING_STATUS=FAIL", status)
            self.assertIn("PAD_MAPPING_STATUS=NOT_FOUND", status)
            context = (output / "pvs_target_layer_context.rpt").read_text()
            self.assertIn("1:layer_def pad 50370", context)
            self.assertIn("MAPPING_ERROR_COUNT=1", context)
            self.assertIn("PVS_EXECUTED=NO", status)

    def test_server_wrapper_is_interactive_safe_and_never_runs_pvs(self) -> None:
        text = WRAPPER.read_text()
        self.assertIn("set +e", text)
        self.assertNotRegex(text, re.compile(r"^\s*set\s+-e", re.MULTILINE))
        self.assertNotRegex(text, re.compile(r"^\s*exit(?:\s|$)", re.MULTILINE))
        self.assertNotIn("run_pvs_drc_handoff.sh", text)
        self.assertNotIn("replay_pvs_handoff_template.py", text)
        self.assertIn("collect_position_pvs_gds_layer_applicability.py", text)
        self.assertIn("9de7fc2c3be8631837256734128f336927987d089f9e23a5efff7a949542ebd5", text)
        self.assertIn("4d7b850f74ef193b6bc7b15b1e52fd38ba61cc4a6e1b283c4201343a20ad233d", text)
        self.assertIn('echo "PVS_EXECUTED=NO"', text)

    def test_server_wrapper_has_valid_bash_syntax(self) -> None:
        result = subprocess.run(
            ["bash", "-n", str(WRAPPER)], text=True, capture_output=True, check=False
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
