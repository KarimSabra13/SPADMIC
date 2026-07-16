#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
BUILD = REPO / "TOP" / "pnr" / "scripts" / "build_innovus_handoff_gate.py"
PROMOTE = REPO / "TOP" / "pnr" / "scripts" / "promote_innovus_handoff.py"
WAIVER_PATH = REPO / "TOP" / "pnr" / "scripts" / "validate_formal_drc_waiver.py"
WAIVER_SPEC = importlib.util.spec_from_file_location("formal_waiver_test", WAIVER_PATH)
assert WAIVER_SPEC and WAIVER_SPEC.loader
waiver = importlib.util.module_from_spec(WAIVER_SPEC)
sys.modules[WAIVER_SPEC.name] = waiver
WAIVER_SPEC.loader.exec_module(waiver)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class InnovusHandoffPromotionTest(unittest.TestCase):
    def make_package(self, root: Path) -> tuple[Path, Path, dict[str, Path]]:
        package = root / "blocks" / "spadmic_position_core" / "v1"
        for directory in ("gds", "manifests", "status", "reports", "netlist"):
            (package / directory).mkdir(parents=True, exist_ok=True)
        gds = package / "gds" / "spadmic_position_core.gds"
        gds.write_bytes(b"exact-position-gds")
        lvs_source = package / "netlist" / "spadmic_position_core.lvs.pg.v"
        lvs_source.write_text("module spadmic_position_core; endmodule\n")
        (package / "manifests" / "package.json").write_text(
            json.dumps(
                {
                    "name": "spadmic_position_core",
                    "layout_top": "spadmic_position_core",
                    "source_top": "spadmic_position_core",
                }
            )
        )
        (package / "status" / "qualification.rpt").write_text(
            "CANONICAL_NAME_STATUS=PASS\n"
        )
        (package / "status" / "handoff_audit.rpt").write_text("STATUS=PASS\n")
        evidence = {
            name: package / "reports" / name
            for name in (
                "base.rpt",
                "density.rpt",
                "lvs.rpt",
                "pg.rpt",
                "contract.rpt",
                "layer.rpt",
                "timing.rpt",
            )
        }
        binding = f"PACKAGE={package}\nGDS={gds}\nGDS_SHA256={sha(gds)}\n"
        evidence["base.rpt"].write_text(
            "PVS_DRC_STATUS=PASS\nPVS_DRC_VARIANT=BASE\n" + binding
        )
        evidence["density.rpt"].write_text(
            "PVS_DRC_STATUS=PASS\nPVS_DRC_VARIANT=DENSITY\n" + binding
        )
        evidence["lvs.rpt"].write_text(
            "PVS_LVS_STATUS=MATCH\n"
            + binding
            + f"LVS_SOURCE={lvs_source}\nLVS_SOURCE_SHA256={sha(lvs_source)}\n"
        )
        evidence["pg.rpt"].write_text("INTERNAL_PG_STATUS=PASS\n")
        evidence["contract.rpt"].write_text(
            "BBOX_PARITY_STATUS=PASS\nPIN_PARITY_STATUS=PASS\n"
        )
        evidence["layer.rpt"].write_text(
            "GDS_LAYER_MAP_STATUS=PASS\n"
            "GDS_MERGE_STATUS=PASS\n"
            f"GDS={gds}\n"
            f"GDS_SHA256={sha(gds)}\n"
        )
        evidence["timing.rpt"].write_text("TC_TIMING_STATUS=PASS\n")
        return package, gds, evidence

    def build_command(
        self,
        package: Path,
        evidence: dict[str, Path],
        run_id: str,
        waiver_manifest: Path | None = None,
    ) -> list[str]:
        command = [
            "python3",
            str(BUILD),
            "--package",
            str(package),
            "--base-drc-status",
            str(evidence["base.rpt"]),
            "--density-drc-status",
            str(evidence["density.rpt"]),
            "--lvs-status",
            str(evidence["lvs.rpt"]),
            "--pg-status",
            str(evidence["pg.rpt"]),
            "--contract-status",
            str(evidence["contract.rpt"]),
            "--layer-status",
            str(evidence["layer.rpt"]),
            "--timing-status",
            str(evidence["timing.rpt"]),
            "--run-id",
            run_id,
        ]
        if waiver_manifest:
            command.extend(["--formal-waiver-manifest", str(waiver_manifest)])
        return command

    def test_clean_evidence_builds_gate_and_promotes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            package, _, evidence = self.make_package(Path(tmp))
            built = subprocess.run(
                self.build_command(package, evidence, "clean_gate"),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(built.returncode, 0, built.stdout + built.stderr)
            gate = package / "status" / "clean_gate.rpt"
            self.assertIn("PROMOTION_BASIS=CLEAN_ZERO_DRC", gate.read_text())
            promoted = subprocess.run(
                ["python3", str(PROMOTE), str(package), "--gate-status", str(gate)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(promoted.returncode, 0, promoted.stdout + promoted.stderr)
            self.assertTrue((package.parent / "current").is_symlink())

    def test_wrong_gds_hash_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            package, _, evidence = self.make_package(Path(tmp))
            evidence["density.rpt"].write_text(
                evidence["density.rpt"].read_text().replace(
                    "GDS_SHA256=", "GDS_SHA256=stale-"
                )
            )
            built = subprocess.run(
                self.build_command(package, evidence, "stale_gate"),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(built.returncode, 8)
            self.assertIn("density_drc_gds_sha256", built.stdout)

    def test_evidence_outside_package_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            package, _, evidence = self.make_package(root)
            external_timing = root / "external_timing.rpt"
            external_timing.write_text("TC_TIMING_STATUS=PASS\n")
            evidence["timing.rpt"] = external_timing
            built = subprocess.run(
                self.build_command(package, evidence, "external_gate"),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(built.returncode, 8)
            self.assertIn("timing_evidence_outside_package", built.stdout)

    def test_stale_lvs_source_hash_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            package, _, evidence = self.make_package(Path(tmp))
            evidence["lvs.rpt"].write_text(
                evidence["lvs.rpt"].read_text().replace(
                    "LVS_SOURCE_SHA256=", "LVS_SOURCE_SHA256=stale-"
                )
            )
            built = subprocess.run(
                self.build_command(package, evidence, "stale_source_gate"),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(built.returncode, 8)
            self.assertIn("lvs_source_sha256", built.stdout)

    def test_promotion_rejects_missing_gate_gds_without_traceback(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            package, _, evidence = self.make_package(Path(tmp))
            built = subprocess.run(
                self.build_command(package, evidence, "missing_gds_gate"),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(built.returncode, 0, built.stdout + built.stderr)
            gate = package / "status" / "missing_gds_gate.rpt"
            gate.write_text(
                "\n".join(
                    line for line in gate.read_text().splitlines() if not line.startswith("GDS=")
                )
                + "\n"
            )
            promoted = subprocess.run(
                ["python3", str(PROMOTE), str(package), "--gate-status", str(gate)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(promoted.returncode, 0)
            self.assertIn("GDS=MISSING expected_existing_file", promoted.stderr)
            self.assertNotIn("Traceback", promoted.stderr)

    def test_hash_bound_formal_waiver_can_cover_both_drc_variants(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            package, gds, evidence = self.make_package(Path(tmp))
            for name in ("base.rpt", "density.rpt"):
                evidence[name].write_text(
                    evidence[name].read_text().replace(
                        "PVS_DRC_STATUS=PASS", "PVS_DRC_STATUS=FAIL"
                    )
                )
            manifest = package / "reports" / "formal_waiver.json"
            document = {
                "schema": waiver.SCHEMA,
                "status": "APPROVED",
                "block": "spadmic_position_core",
                "gds_sha256": sha(gds),
                "approver": "physical-signoff-owner",
                "approval_reference": "review-42",
                "approved_utc": "2026-07-16T12:00:00Z",
                "scope": "exact reviewed base and density findings",
                "justification": "approved project disposition",
                "review_condition": "any GDS or rule-deck change",
                "coverage": {
                    variant: {
                        "status": "APPROVED_WAIVER",
                        "result_count": 1,
                        "rule_ids": [f"{variant.upper()}_RULE"],
                        "disposition": "accepted for this exact block GDS",
                    }
                    for variant in ("base", "density")
                },
                "signature": {
                    "algorithm": waiver.ALGORITHM,
                    "signer": "physical-signoff-owner",
                    "payload_sha256": "",
                },
            }
            document["signature"]["payload_sha256"] = waiver.payload_digest(document)
            manifest.write_text(json.dumps(document, indent=2) + "\n")
            built = subprocess.run(
                self.build_command(package, evidence, "waived_gate", manifest),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(built.returncode, 0, built.stdout + built.stderr)
            gate = (package / "status" / "waived_gate.rpt").read_text()
            self.assertIn("PVS_BASE_DRC_STATUS=FORMALLY_WAIVED", gate)
            self.assertIn("PVS_DENSITY_DRC_STATUS=FORMALLY_WAIVED", gate)
            self.assertIn("PROMOTION_BASIS=FORMAL_DRC_WAIVER", gate)
            result, errors = waiver.validate_manifest(
                manifest,
                gds,
                expected_block="spadmic_position_core",
            )
            self.assertEqual(errors, [])
            self.assertEqual(
                result["ATTESTATION_SECURITY"],
                "INTEGRITY_ONLY_NOT_CRYPTOGRAPHIC_IDENTITY",
            )

            original_base = evidence["base.rpt"].read_text()
            evidence["base.rpt"].write_text(
                original_base.replace("PVS_DRC_STATUS=FAIL", "PVS_DRC_STATUS=NOT_RUN")
            )
            not_run = subprocess.run(
                self.build_command(package, evidence, "not_run_waiver_gate", manifest),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(not_run.returncode, 8)
            self.assertIn("PVS_BASE_DRC_STATUS=NOT_RUN", not_run.stdout)
            evidence["base.rpt"].write_text(original_base)

            document["justification"] = "tampered after approval"
            manifest.write_text(json.dumps(document, indent=2) + "\n")
            promoted = subprocess.run(
                [
                    "python3",
                    str(PROMOTE),
                    str(package),
                    "--gate-status",
                    str(package / "status" / "waived_gate.rpt"),
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(promoted.returncode, 0)
            self.assertIn("PROMOTION_EVIDENCE_HASH_FAIL", promoted.stderr)


if __name__ == "__main__":
    unittest.main()
