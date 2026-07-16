#!/usr/bin/env python3
"""Validate an approved DRC waiver bound to one immutable GDS hash."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


SCHEMA = "spadmic.formal_drc_waiver.v1"
ALGORITHM = "SHA256_CANONICAL_JSON"


def file_digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def payload_document(document: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in document.items() if key != "signature"}


def payload_digest(document: dict[str, Any]) -> str:
    encoded = json.dumps(
        payload_document(document),
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=True,
    ).encode()
    return hashlib.sha256(encoded).hexdigest()


def validate_manifest(
    manifest_path: Path,
    gds_path: Path,
    *,
    expected_block: str = "",
) -> tuple[dict[str, str], list[str]]:
    errors: list[str] = []
    try:
        document = json.loads(manifest_path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        return {}, [f"manifest_read={error}"]

    if document.get("schema") != SCHEMA:
        errors.append(f"schema={document.get('schema', 'MISSING')} expected={SCHEMA}")
    if document.get("status") != "APPROVED":
        errors.append(f"status={document.get('status', 'MISSING')} expected=APPROVED")
    for key in (
        "block",
        "approver",
        "approval_reference",
        "approved_utc",
        "scope",
        "justification",
        "review_condition",
    ):
        if not str(document.get(key, "")).strip():
            errors.append(f"missing_{key}")
    if expected_block and document.get("block") != expected_block:
        errors.append(
            f"block={document.get('block', 'MISSING')} expected={expected_block}"
        )

    try:
        expected_gds_hash = file_digest(gds_path)
    except OSError as error:
        errors.append(f"gds_read={error}")
        expected_gds_hash = "MISSING"
    if document.get("gds_sha256") != expected_gds_hash:
        errors.append(
            f"gds_sha256={document.get('gds_sha256', 'MISSING')} expected={expected_gds_hash}"
        )

    signature = document.get("signature")
    if not isinstance(signature, dict):
        errors.append("signature_missing")
        signature = {}
    if signature.get("algorithm") != ALGORITHM:
        errors.append(
            f"signature_algorithm={signature.get('algorithm', 'MISSING')} expected={ALGORITHM}"
        )
    signer = str(signature.get("signer", "")).strip()
    if not signer:
        errors.append("signature_signer_missing")
    if signer and signer != str(document.get("approver", "")).strip():
        errors.append("signature_signer_does_not_match_approver")
    actual_payload_hash = payload_digest(document)
    if signature.get("payload_sha256") != actual_payload_hash:
        errors.append(
            "signature_payload_sha256="
            f"{signature.get('payload_sha256', 'MISSING')} expected={actual_payload_hash}"
        )

    coverage = document.get("coverage")
    if not isinstance(coverage, dict):
        errors.append("coverage_missing")
        coverage = {}
    covered: dict[str, str] = {}
    for variant in ("base", "density"):
        entry = coverage.get(variant)
        if entry is None:
            covered[variant] = "NO"
            continue
        if not isinstance(entry, dict):
            errors.append(f"coverage_{variant}_invalid")
            covered[variant] = "NO"
            continue
        if entry.get("status") != "APPROVED_WAIVER":
            errors.append(
                f"coverage_{variant}_status={entry.get('status', 'MISSING')}"
            )
        if not str(entry.get("disposition", "")).strip():
            errors.append(f"coverage_{variant}_disposition_missing")
        result_count = entry.get("result_count")
        if not isinstance(result_count, int) or result_count <= 0:
            errors.append(f"coverage_{variant}_result_count_invalid")
        rule_ids = entry.get("rule_ids")
        if not isinstance(rule_ids, list) or not rule_ids:
            errors.append(f"coverage_{variant}_rule_ids_missing")
        covered[variant] = "YES"

    result = {
        "STATUS": "PASS" if not errors else "FAIL",
        "BLOCK": str(document.get("block", "MISSING")),
        "GDS_SHA256": expected_gds_hash,
        "BASE_COVERED": covered.get("base", "NO"),
        "DENSITY_COVERED": covered.get("density", "NO"),
        "APPROVER": str(document.get("approver", "MISSING")),
        "APPROVAL_REFERENCE": str(document.get("approval_reference", "MISSING")),
        "PAYLOAD_SHA256": actual_payload_hash,
        "ATTESTATION_SECURITY": "INTEGRITY_ONLY_NOT_CRYPTOGRAPHIC_IDENTITY",
    }
    return result, errors


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--gds", required=True, type=Path)
    parser.add_argument("--block", default="")
    parser.add_argument("--status", type=Path)
    parser.add_argument("--calculate-payload-sha", action="store_true")
    args = parser.parse_args()

    if args.calculate_payload_sha:
        document = json.loads(args.manifest.read_text())
        print(payload_digest(document))
        return

    result, errors = validate_manifest(
        args.manifest.resolve(),
        args.gds.resolve(),
        expected_block=args.block,
    )
    text = (
        "LABEL=SPADMIC_FORMAL_DRC_WAIVER\n"
        + "".join(f"{key}={value}\n" for key, value in result.items())
        + "".join(f"ERROR={error}\n" for error in errors)
    )
    if args.status:
        args.status.resolve().write_text(text)
    print(text, end="")
    if errors:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
