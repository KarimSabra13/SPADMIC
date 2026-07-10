#!/usr/bin/env python3
"""Clone the executable part of a GUI PVS run and patch explicit values."""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
from pathlib import Path


CORE_FILES = {
    "run.pvs",
    ".config.rul",
    ".technology.rul",
    ".preset.autosave",
    "pvsdrcctl",
    "pvslvsctl",
    "cell_tree.txt",
    "pipo1.setup",
    "pipo2.setup",
    "var_streamOutKeys.virtuoso",
    "var_cdlOutKeys.virtuoso",
}


def is_text(path: Path) -> bool:
    try:
        path.read_text()
        return True
    except (UnicodeDecodeError, OSError):
        return False


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--template", required=True, type=Path)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--mode", choices=["drc", "lvs"], required=True)
    parser.add_argument("--cadence-pvs", required=True)
    parser.add_argument("--replace", action="append", default=[])
    args = parser.parse_args()

    template = args.template.resolve()
    run_dir = args.run_dir.resolve()
    if not template.is_dir():
        raise SystemExit(f"template missing: {template}")
    if run_dir.exists():
        raise SystemExit(f"immutable PVS run already exists: {run_dir}")
    required_control = "pvsdrcctl" if args.mode == "drc" else "pvslvsctl"
    for name in ["run.pvs", ".config.rul", ".technology.rul", required_control]:
        if not (template / name).is_file():
            raise SystemExit(f"template file missing: {template / name}")

    run_dir.mkdir(parents=True)
    copied = []
    for source in template.iterdir():
        if not source.is_file():
            continue
        if source.name in CORE_FILES or source.suffix in {".lmap", ".rul"}:
            destination = run_dir / source.name
            shutil.copy2(source, destination)
            copied.append(destination)

    replacements: list[tuple[str, str]] = [(str(template), str(run_dir))]
    for item in args.replace:
        if "=" not in item:
            raise SystemExit(f"replacement must be OLD=NEW: {item}")
        old, new = item.split("=", 1)
        if not old:
            raise SystemExit(f"empty OLD replacement: {item}")
        if old != new:
            replacements.append((old, new))

    for path in copied:
        if not is_text(path):
            continue
        text = path.read_text()
        for old, new in replacements:
            text = text.replace(old, new)
        # The copied run is pinned to the selected Cadence binary regardless of PATH.
        for known in [
            "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs",
            "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/tools/bin/pvs",
        ]:
            text = text.replace(known, args.cadence_pvs)
        path.write_text(text)

    run_file = run_dir / "run.pvs"
    text = run_file.read_text()
    if args.cadence_pvs not in text:
        raise SystemExit("PVS_BINARY_GATE_FAIL: patched run.pvs does not name the selected Cadence binary")
    stale = [old for old, _ in replacements if old and old in "\n".join(p.read_text(errors="ignore") for p in copied)]
    if stale:
        raise SystemExit(f"STALE_TEMPLATE_PATHS: {stale}")
    run_file.chmod(0o755)
    external_paths = set()
    for path in copied:
        if not is_text(path):
            continue
        for value in re.findall(r"(?:\"|\{|\s)(/[^\s\"'{};]+)", path.read_text(errors="ignore")):
            candidate = Path(value)
            if run_dir not in candidate.parents and candidate != run_dir:
                external_paths.add(candidate)
    reference_lines = ["LABEL=SPADMIC_PVS_EXTERNAL_REFERENCES"]
    for candidate in sorted(external_paths):
        if candidate.is_file():
            reference_lines.append(
                f"FILE={candidate}|{candidate.stat().st_size}|{digest(candidate)}"
            )
        elif candidate.is_dir():
            reference_lines.append(f"DIRECTORY={candidate}")
        else:
            reference_lines.append(f"MISSING={candidate}")
    (run_dir / "external_references.rpt").write_text("\n".join(reference_lines) + "\n")
    print(f"PVS_REPLAY_RUN_DIR={run_dir}")
    print("PVS_REPLAY_PATCH_STATUS=PASS")


if __name__ == "__main__":
    main()
