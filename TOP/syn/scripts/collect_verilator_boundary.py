#!/usr/bin/env python3
"""Convert a Verilator XML top boundary into an immutable bit-level contract."""

from __future__ import annotations

import argparse
import csv
import hashlib
import xml.etree.ElementTree as ET
from pathlib import Path


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def dtype_bounds(element: ET.Element, types: dict[str, ET.Element]) -> tuple[int, int]:
    tag = element.tag
    if tag == "basicdtype":
        left = int(element.attrib.get("left", "0"))
        right = int(element.attrib.get("right", "0"))
        return left, right
    if tag == "packarraydtype":
        sub = types[element.attrib["sub_dtype_id"]]
        sub_left, sub_right = dtype_bounds(sub, types)
        ranges = element.findall("range")
        if len(ranges) != 1:
            raise ValueError(f"packed dtype {element.attrib['id']} has no unique range")
        consts = ranges[0].findall("const")
        if len(consts) != 2:
            raise ValueError(f"packed dtype {element.attrib['id']} has a non-constant range")
        left = int(consts[0].attrib["name"], 0)
        right = int(consts[1].attrib["name"], 0)
        sub_width = abs(sub_left - sub_right) + 1
        if sub_width != 1:
            raise ValueError("adjacent packed top dimensions are prohibited")
        return left, right
    if tag == "unpackarraydtype":
        raise ValueError("unpacked top-level dimensions are prohibited")
    if "sub_dtype_id" in element.attrib:
        return dtype_bounds(types[element.attrib["sub_dtype_id"]], types)
    raise ValueError(f"unsupported Verilator dtype at top boundary: {tag}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xml", required=True, type=Path)
    parser.add_argument("--top", required=True)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    root = ET.parse(args.xml).getroot()
    modules = root.findall("./netlist/module")
    matches = [module for module in modules if module.attrib.get("name") == args.top]
    if len(matches) != 1 or matches[0].attrib.get("topModule") != "1":
        raise SystemExit(f"top module count/status mismatch for {args.top}: {len(matches)}")

    types = {
        element.attrib["id"]: element
        for element in root.findall("./netlist/typetable/*")
        if "id" in element.attrib
    }
    rows: list[dict[str, object]] = []
    bits: list[dict[str, object]] = []
    ports = [var for var in matches[0].findall("var") if var.attrib.get("dir")]
    ports.sort(key=lambda item: int(item.attrib.get("pinIndex", "0")))
    for order, port in enumerate(ports, 1):
        left, right = dtype_bounds(types[port.attrib["dtype_id"]], types)
        width = abs(left - right) + 1
        name = port.attrib["name"]
        direction = port.attrib["dir"].lower()
        rows.append(
            {
                "order": order,
                "port": name,
                "direction": direction,
                "left": left,
                "right": right,
                "width": width,
                "dimension_count": 0 if width == 1 else 1,
            }
        )
        if width == 1:
            bits.append({"port": name, "bit_name": name, "direction": direction, "bit_index": "SCALAR"})
        else:
            step = -1 if left >= right else 1
            for bit in range(left, right + step, step):
                bits.append(
                    {
                        "port": name,
                        "bit_name": f"{name}[{bit}]",
                        "direction": direction,
                        "bit_index": bit,
                    }
                )

    names = [row["port"] for row in rows]
    if len(names) != len(set(names)):
        raise SystemExit("duplicate top-level port name in Verilator boundary")
    for supply in ("VDD", "VSS"):
        matching = [row for row in rows if row["port"] == supply]
        if len(matching) != 1 or matching[0]["direction"] != "inout" or matching[0]["width"] != 1:
            raise SystemExit(f"required scalar inout supply missing: {supply}")

    args.out.mkdir(parents=True, exist_ok=True)
    with (args.out / "rtl_boundary.tsv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, list(rows[0]), delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    with (args.out / "rtl_boundary_bits.tsv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, list(bits[0]), delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(bits)

    status = {
        "LABEL": "SPADMIC_DIGITAL_ASSEMBLY_RTL_BOUNDARY",
        "STATUS": "PASS",
        "TOP_MODULE": args.top,
        "BASE_PORT_COUNT": len(rows),
        "EXPANDED_BIT_PORT_COUNT": len(bits),
        "ADJACENT_DIMENSION_COUNT": 0,
        "VDD_BOUNDARY_STATUS": "PASS",
        "VSS_BOUNDARY_STATUS": "PASS",
        "VERILATOR_XML_SHA256": sha256(args.xml),
        "SIGNOFF_READY": "NO",
    }
    (args.out / "rtl_boundary_status.rpt").write_text(
        "".join(f"{key}={value}\n" for key, value in status.items()), encoding="utf-8"
    )
    print((args.out / "rtl_boundary_status.rpt").read_text(), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
