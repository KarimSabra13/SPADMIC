#!/usr/bin/env python3
"""Smoke test for the RO_tune4 LEF parser."""

from __future__ import annotations

from pathlib import Path

from parse_lef_macros import parse_lef_macros


REPO_ROOT = Path(__file__).resolve().parents[2]
LEF_DIR = REPO_ROOT / "results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef"


def check_lef(path: Path) -> None:
    macros = parse_lef_macros(path)
    names = [macro.name for macro in macros]
    assert names == ["RO_tune4"], f"{path}: expected only RO_tune4, got {names}"

    macro = macros[0]
    assert macro.size == (176.675, 67.17), f"{path}: unexpected SIZE {macro.size}"
    assert macro.has_obs, f"{path}: missing OBS block"

    pins = set(macro.pins)
    required = {"rstb", "VDD", "VSS", "vdd!"}
    required |= {f"S[{idx}]" for idx in range(8)}
    required |= {f"code[{idx}]" for idx in range(8)}
    missing = sorted(required - pins)
    assert not missing, f"{path}: missing pins {missing}"
    assert "CatenaDesignType" not in names, f"{path}: PROPERTYDEFINITIONS parsed as macro"


def main() -> int:
    source_lef = LEF_DIR / "RO_tune4_real_abstract.source.lef"
    output_lef = LEF_DIR / "RO_tune4_real_abstract.lef"
    assert source_lef.exists(), f"missing {source_lef}"
    assert output_lef.exists(), f"missing {output_lef}"

    check_lef(source_lef)
    check_lef(output_lef)
    print("PASS: RO_tune4 LEF parser ignores PROPERTYDEFINITIONS and finds real pins")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
