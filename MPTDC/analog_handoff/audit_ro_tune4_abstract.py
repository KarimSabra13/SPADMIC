#!/usr/bin/env python3
"""Audit the real RO macro RTL/Liberty/LEF interface used by MPTDC flows.

The LEF parser intentionally ignores PROPERTYDEFINITIONS.  Some exported LEFs
contain entries such as ``MACRO CatenaDesignType STRING ;`` in that section;
those are property declarations, not physical macro declarations.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MPTDC_ROOT = REPO_ROOT / "MPTDC"
TOOLS_TIMING = REPO_ROOT / "tools" / "timing"
sys.path.insert(0, str(TOOLS_TIMING))

from parse_lef_macros import LefMacro, parse_lef_macros  # noqa: E402


ENV_FILE = MPTDC_ROOT / "analog_handoff" / "real_ro_tune6_layout.env"
DEFAULT_COPIED_LEF = Path("/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef")
DEFAULT_LIBERTY = MPTDC_ROOT / "syn" / "macros" / "RO_tune6_real_layout_shell.lib"
DEFAULT_RTL = MPTDC_ROOT / "rtl" / "osc" / "mptdc_osc_wrapper.sv"
DEFAULT_REPORT = Path("reports") / "ro_tune6_lef_audit.rpt"

REQUIRED_INPUTS = ["rstb"] + [f"code[{idx}]" for idx in range(8)]
REQUIRED_OUTPUTS = [f"S[{idx}]" for idx in range(8)]
REQUIRED_SUPPLIES = ["VDD", "VSS", "vdd!"]
REQUIRED_PINS = REQUIRED_INPUTS + REQUIRED_OUTPUTS + REQUIRED_SUPPLIES


def yesno(value: bool) -> str:
    return "YES" if value else "NO"


def shell_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[len("export ") :].strip()
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key:
            values[key] = os.path.expandvars(value)
    return values


def resolve_optional_path(path_text: str | None) -> Path | None:
    if not path_text:
        return None
    expanded = os.path.expanduser(os.path.expandvars(path_text))
    path = Path(expanded)
    if not path.is_absolute():
        path = REPO_ROOT / path
    return path


def normalize_pin(name: str) -> str:
    token = name.strip().strip('"')
    match = re.fullmatch(r"([A-Za-z_][A-Za-z0-9_!$]*)[<\[]([0-9]+)[>\]]", token)
    if match:
        return f"{match.group(1)}[{int(match.group(2))}]"
    return token


def scan_property_macro_entries(path: Path) -> list[str]:
    entries: list[str] = []
    in_property = False
    for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        upper = line.upper()
        if upper.startswith("PROPERTYDEFINITIONS"):
            in_property = True
            continue
        if in_property and upper.startswith("END PROPERTYDEFINITIONS"):
            in_property = False
            continue
        if not in_property:
            continue
        tokens = line.split()
        if len(tokens) >= 2 and tokens[0].upper() == "MACRO":
            entries.append(tokens[1].rstrip(";"))
    return entries


def select_ro_macro(macros: list[LefMacro], expected_macro: str) -> LefMacro | None:
    for macro in macros:
        if macro.name == expected_macro:
            return macro
    return None


def audit_lef(path: Path | None, expected_macro: str) -> dict[str, object]:
    result: dict[str, object] = {
        "path": str(path) if path else "unset",
        "found": False,
        "macros": [],
        "macro_name": "missing",
        "property_entries": [],
        "required_found": False,
        "missing": REQUIRED_PINS[:],
        "extra": [],
        "pin_geometry_present": False,
        "pins": [],
    }
    if path is None or not path.is_file():
        return result

    macros = parse_lef_macros(path)
    macro_names = [macro.name for macro in macros]
    macro = select_ro_macro(macros, expected_macro)
    result["found"] = True
    result["macros"] = macro_names
    result["property_entries"] = scan_property_macro_entries(path)
    if macro is None:
        result["macro_name"] = macro_names[0] if macro_names else "missing"
        return result

    normalized_to_actual = {normalize_pin(pin_name): pin_name for pin_name in macro.pins}
    normalized_pins = set(normalized_to_actual)
    required = set(REQUIRED_PINS)
    missing = sorted(required - normalized_pins)
    extra = sorted(normalized_to_actual[name] for name in normalized_pins - required)
    geometry_ok = True
    for required_pin in REQUIRED_PINS:
        actual = normalized_to_actual.get(required_pin)
        if actual is None or not macro.pins[actual].rects:
            geometry_ok = False
            break

    result["macro_name"] = macro.name
    result["required_found"] = not missing
    result["missing"] = missing
    result["extra"] = extra
    result["pin_geometry_present"] = geometry_ok
    result["pins"] = sorted(macro.pins)
    return result


def expand_bus(bits_name: str) -> set[str]:
    return {f"{bits_name}[{idx}]" for idx in range(8)}


def audit_liberty(path: Path, expected_macro: str) -> dict[str, object]:
    result: dict[str, object] = {
        "path": str(path),
        "found": path.is_file(),
        "cell_found": False,
        "required_found": False,
        "missing": REQUIRED_PINS[:],
        "pins": [],
    }
    if not path.is_file():
        return result

    text = path.read_text(encoding="utf-8", errors="replace")
    result["cell_found"] = bool(
        re.search(rf"\bcell\s*\(\s*\"?{re.escape(expected_macro)}\"?\s*\)", text)
    )
    pins: set[str] = set()
    pins.update(match.strip('"') for match in re.findall(r"\bpin\s*\(\s*([^)]+?)\s*\)", text))
    pins.update(match.strip('"') for match in re.findall(r"\bpg_pin\s*\(\s*([^)]+?)\s*\)", text))
    buses = {match.strip('"') for match in re.findall(r"\bbus\s*\(\s*([^)]+?)\s*\)", text)}
    if "code" in buses:
        pins.update(expand_bus("code"))
    if "S" in buses:
        pins.update(expand_bus("S"))

    normalized = {normalize_pin(pin) for pin in pins}
    missing = sorted(set(REQUIRED_PINS) - normalized)
    result["pins"] = sorted(pins)
    result["missing"] = missing
    result["required_found"] = bool(result["cell_found"]) and not missing
    return result


def audit_rtl(path: Path, expected_macro: str) -> dict[str, object]:
    result: dict[str, object] = {
        "path": str(path),
        "found": path.is_file(),
        "module_found": False,
        "logical_pins_found": False,
        "explicit_supply_pins": False,
        "pins": [],
    }
    if not path.is_file():
        return result

    text = path.read_text(encoding="utf-8", errors="replace")
    match = re.search(
        rf"\bmodule\s+{re.escape(expected_macro)}\s*\((.*?)\);\s*endmodule",
        text,
        re.S,
    )
    if not match:
        return result

    block = match.group(1)
    result["module_found"] = True
    pins = set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_!]*)\b(?=\s*(?:,|\)))", block))
    result["pins"] = sorted(pins)
    has_rstb = re.search(r"\binput\s+wire\s+rstb\b", block) is not None
    has_code = re.search(r"\binput\s+wire\s+\[[^\]]*7\s*:\s*0[^\]]*\]\s+code\b", block) is not None
    has_s = re.search(r"\boutput\s+wire\s+\[[^\]]*7\s*:\s*0[^\]]*\]\s+S\b", block) is not None
    result["logical_pins_found"] = has_rstb and has_code and has_s
    result["explicit_supply_pins"] = {"VDD", "VSS", "vdd!"}.issubset(pins)
    return result


def join_list(values: object) -> str:
    if not isinstance(values, list) or not values:
        return "none"
    return ",".join(str(value) for value in values)


def write_report(
    report: Path,
    expected_macro: str,
    source: dict[str, object],
    copied: dict[str, object],
    liberty: dict[str, object],
    rtl: dict[str, object],
) -> bool:
    property_ignored = (
        "CatenaDesignType" not in source.get("macros", [])
        and "CatenaDesignType" not in copied.get("macros", [])
    )
    required_found = bool(source["required_found"]) and bool(copied["required_found"])
    geometry_present = bool(source["pin_geometry_present"]) and bool(copied["pin_geometry_present"])
    pass_status = all(
        [
            source["found"],
            copied["found"],
            source["macro_name"] == expected_macro,
            copied["macro_name"] == expected_macro,
            property_ignored,
            required_found,
            geometry_present,
            liberty["required_found"],
            rtl["logical_pins_found"],
        ]
    )

    missing_sections: list[str] = []
    if source.get("missing"):
        missing_sections.append(f"source:{join_list(source['missing'])}")
    if copied.get("missing"):
        missing_sections.append(f"copied:{join_list(copied['missing'])}")
    if liberty.get("missing"):
        missing_sections.append(f"liberty:{join_list(liberty['missing'])}")

    report.parent.mkdir(parents=True, exist_ok=True)
    with report.open("w", encoding="utf-8") as fh:
        fh.write(f"# {expected_macro} LEF/Liberty/RTL Interface Audit\n\n")
        fh.write(f"EXPECTED_MACRO={expected_macro}\n")
        fh.write(f"SOURCE_LEF={source['path']}\n")
        fh.write(f"COPIED_LEF={copied['path']}\n")
        fh.write(f"LIBERTY_FILE={liberty['path']}\n")
        fh.write(f"RTL_FILE={rtl['path']}\n")
        fh.write(f"SOURCE_LEF_FOUND={yesno(bool(source['found']))}\n")
        fh.write(f"COPIED_LEF_FOUND={yesno(bool(copied['found']))}\n")
        fh.write(f"SOURCE_MACRO_NAME={source['macro_name']}\n")
        fh.write(f"COPIED_MACRO_NAME={copied['macro_name']}\n")
        fh.write(f"SOURCE_REAL_MACROS={join_list(source['macros'])}\n")
        fh.write(f"COPIED_REAL_MACROS={join_list(copied['macros'])}\n")
        fh.write(
            "SOURCE_PROPERTYDEFINITIONS_MACRO_ENTRIES="
            f"{join_list(source['property_entries'])}\n"
        )
        fh.write(
            "COPIED_PROPERTYDEFINITIONS_MACRO_ENTRIES="
            f"{join_list(copied['property_entries'])}\n"
        )
        fh.write(
            "PROPERTYDEFINITIONS_MACRO_ENTRIES_IGNORED="
            f"{yesno(property_ignored)}\n"
        )
        fh.write(f"REQUIRED_PINS_FOUND={yesno(required_found)}\n")
        fh.write(
            "MISSING_PINS="
            f"{';'.join(missing_sections) if missing_sections else 'none'}\n"
        )
        fh.write(f"EXTRA_PINS_SOURCE={join_list(source['extra'])}\n")
        fh.write(f"EXTRA_PINS_COPIED={join_list(copied['extra'])}\n")
        fh.write(f"PIN_GEOMETRY_PRESENT={yesno(geometry_present)}\n")
        fh.write(f"SOURCE_PIN_NAMES={join_list(source['pins'])}\n")
        fh.write(f"COPIED_PIN_NAMES={join_list(copied['pins'])}\n")
        fh.write(f"LIBERTY_CELL_{expected_macro.upper()}_FOUND={yesno(bool(liberty['cell_found']))}\n")
        fh.write(f"LIBERTY_REQUIRED_PINS_FOUND={yesno(bool(liberty['required_found']))}\n")
        fh.write(f"RTL_MODULE_{expected_macro.upper()}_FOUND={yesno(bool(rtl['module_found']))}\n")
        fh.write(f"RTL_LOGICAL_PINS_FOUND={yesno(bool(rtl['logical_pins_found']))}\n")
        fh.write(f"RTL_SUPPLY_PINS_EXPLICIT={yesno(bool(rtl['explicit_supply_pins']))}\n")
        fh.write("RTL_SUPPLY_PIN_POLICY=LIBERTY_PG_AND_LEF_PHYSICAL_PINS\n")
        fh.write(f"AUDIT_STATUS={'PASS' if pass_status else 'FAIL'}\n")
    return pass_status


def main() -> int:
    env_file = resolve_optional_path(os.environ.get("MPTDC_RO_HANDOFF_ENV")) or ENV_FILE
    env_values = shell_env(env_file)
    expected_macro = (
        os.environ.get("O1_RO_CELL_NAME")
        or env_values.get("O1_RO_CELL_NAME")
        or "RO_tune6"
    )
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--macro", default=expected_macro)
    parser.add_argument("--source-lef", default=os.environ.get("O1_RO_SOURCE_LEF_PATH") or env_values.get("O1_RO_SOURCE_LEF_PATH"))
    parser.add_argument("--copied-lef", default=os.environ.get("O1_RO_LEF_PATH") or env_values.get("O1_RO_LEF_PATH") or str(DEFAULT_COPIED_LEF))
    parser.add_argument("--liberty", default=os.environ.get("O1_RO_LIBERTY_PATH") or str(DEFAULT_LIBERTY))
    parser.add_argument("--rtl", default=str(DEFAULT_RTL))
    parser.add_argument("--report", default=str(DEFAULT_REPORT))
    args = parser.parse_args()
    expected_macro = args.macro

    source_path = resolve_optional_path(args.source_lef)
    copied_path = resolve_optional_path(args.copied_lef)
    liberty_path = resolve_optional_path(args.liberty)
    rtl_path = resolve_optional_path(args.rtl)
    report_path = resolve_optional_path(args.report) or DEFAULT_REPORT

    source = audit_lef(source_path, expected_macro)
    copied = audit_lef(copied_path, expected_macro)
    liberty = audit_liberty(liberty_path or DEFAULT_LIBERTY, expected_macro)
    rtl = audit_rtl(rtl_path or DEFAULT_RTL, expected_macro)
    passed = write_report(report_path, expected_macro, source, copied, liberty, rtl)
    print(f"RO_MACRO_AUDIT_REPORT={report_path}")
    print(f"AUDIT_STATUS={'PASS' if passed else 'FAIL'}")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
