#!/usr/bin/env python3
"""Generate the Phase-A SPADMIC digital assembly import collateral.

The generator treats the approved LEFs and the read-only SPADMIC2 audit as the
physical contract.  It intentionally refuses to produce runnable Innovus Tcl
when sizes, pin names, MY legality, or top-coordinate clearances drift.
"""

from __future__ import annotations

import argparse
import csv
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


TOP_MODULE = "spadmic_digital_assembly_v1"
PACKET_MACRO = "spadmic_tx_packet_core"
STRIP_MACRO = "spadmic_tx_ddr_strip"

DIE = (0.0, 0.0, 4116.031, 3740.792)
MATRIX = (25.915, 776.039, 2112.884, 2674.624)
PACKET_ORIGIN = (61.980, MATRIX[3] + 15.0)
STRIP_ORIGIN = (61.980, 3061.110)
MPTDC_HALO_UM = 20.0
EXPECTED_PACKET_SIZE = (2066.960, 366.800)
EXPECTED_STRIP_SIZE = (3522.960, 180.880)
MIN_STRIP_WIDTH_UM = 3413.515
SIZE_TOLERANCE_UM = 0.002
TX_PIN_CONTRACT = Path(__file__).resolve().parents[1] / "interfaces" / "tx_packet_strip_pin_contract.csv"


def load_tx_connections(path: Path = TX_PIN_CONTRACT) -> list[tuple[str, str, str]]:
    if not path.is_file():
        raise ValueError(f"TX pin contract missing: {path}")
    with path.open(newline="") as fh:
        rows = list(csv.DictReader(fh))
    if len(rows) != 19 or [int(row["order"]) for row in rows] != list(range(19)):
        raise ValueError(f"TX pin contract must contain ordered rows 0..18: {path}")
    for row in rows:
        packet_x = float(row["packet_local_x_um"])
        strip_x = float(row["strip_local_x_um"])
        assembly_x = float(row["assembly_x_um"])
        if abs(packet_x - strip_x) > 0.0005:
            raise ValueError(f"TX local X differs for {row['net']}: {path}")
        if abs(assembly_x - (PACKET_ORIGIN[0] + packet_x)) > 0.0005:
            raise ValueError(f"TX absolute X differs for {row['net']}: {path}")
    return [(row["net"], row["packet_pin"], row["strip_pin"]) for row in rows]


TX_CONNECTIONS = load_tx_connections()
SHARED_SIGNAL_PORTS = {"clk_sys", "rst_n"}
STRIP_ROUTED_INPUTS = {"clk_160m_i", "ddrs2_enable_i"}
PG_PINS = {"VDD", "VSS"}


@dataclass(frozen=True)
class Rect:
    layer: str
    llx: float
    lly: float
    urx: float
    ury: float

    @property
    def cx(self) -> float:
        return (self.llx + self.urx) / 2.0

    @property
    def cy(self) -> float:
        return (self.lly + self.ury) / 2.0


@dataclass
class Pin:
    name: str
    direction: str = "INOUT"
    use: str = "SIGNAL"
    rects: list[Rect] = field(default_factory=list)

    def primary_rect(self) -> Rect:
        if not self.rects:
            raise ValueError(f"pin has no RECT geometry: {self.name}")
        return self.rects[0]


@dataclass
class Macro:
    name: str
    width: float
    height: float
    symmetry: set[str]
    pins: dict[str, Pin]
    lef: Path


def parse_lef(path: Path) -> Macro:
    if not path.is_file():
        raise ValueError(f"LEF missing: {path}")

    macro_name = ""
    width = height = None
    symmetry: set[str] = set()
    pins: dict[str, Pin] = {}
    current_pin: Pin | None = None
    current_layer = ""

    for raw in path.read_text(errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        match = re.match(r"MACRO\s+(\S+)", line)
        if match and not macro_name:
            macro_name = match.group(1)
            continue
        match = re.match(r"SIZE\s+([-+0-9.eE]+)\s+BY\s+([-+0-9.eE]+)", line)
        if match and width is None:
            width, height = float(match.group(1)), float(match.group(2))
            continue
        match = re.match(r"SYMMETRY\s+(.+?)\s*;?$", line)
        if match and current_pin is None:
            symmetry.update(token.rstrip(";") for token in match.group(1).split())
            continue
        match = re.match(r"PIN\s+(\S+)", line)
        if match:
            name = match.group(1)
            current_pin = Pin(name=name)
            pins[name] = current_pin
            current_layer = ""
            continue
        if current_pin is None:
            continue
        match = re.match(r"DIRECTION\s+(\S+)", line)
        if match:
            current_pin.direction = match.group(1).rstrip(";").upper()
            continue
        match = re.match(r"USE\s+(\S+)", line)
        if match:
            current_pin.use = match.group(1).rstrip(";").upper()
            continue
        match = re.match(r"LAYER\s+(\S+)", line)
        if match:
            current_layer = match.group(1).rstrip(";")
            continue
        match = re.match(
            r"RECT\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+"
            r"([-+0-9.eE]+)\s+([-+0-9.eE]+)",
            line,
        )
        if match:
            current_pin.rects.append(
                Rect(current_layer, *(float(match.group(i)) for i in range(1, 5)))
            )
            continue
        if re.match(rf"END\s+{re.escape(current_pin.name)}$", line):
            current_pin = None
            current_layer = ""

    if not macro_name or width is None or height is None:
        raise ValueError(f"LEF macro header incomplete: {path}")
    return Macro(macro_name, width, height, symmetry, pins, path.resolve())


def close(a: float, b: float, tolerance: float = SIZE_TOLERANCE_UM) -> bool:
    return abs(a - b) <= tolerance


def validate_macro(macro: Macro, expected_name: str, expected_size: tuple[float, float]) -> None:
    errors: list[str] = []
    if macro.name != expected_name:
        errors.append(f"macro name {macro.name!r} != {expected_name!r}")
    if not close(macro.width, expected_size[0]) or not close(macro.height, expected_size[1]):
        errors.append(
            f"macro size {macro.width:.6f}x{macro.height:.6f} != "
            f"{expected_size[0]:.6f}x{expected_size[1]:.6f}"
        )
    if errors:
        raise ValueError(f"{macro.lef}: " + "; ".join(errors))


def validate_strip_macro(macro: Macro) -> None:
    errors: list[str] = []
    if macro.name != STRIP_MACRO:
        errors.append(f"macro name {macro.name!r} != {STRIP_MACRO!r}")
    if not close(macro.height, EXPECTED_STRIP_SIZE[1]):
        errors.append(
            f"macro height {macro.height:.6f} != {EXPECTED_STRIP_SIZE[1]:.6f}"
        )
    if macro.width < MIN_STRIP_WIDTH_UM - SIZE_TOLERANCE_UM:
        errors.append(
            f"macro width {macro.width:.6f} is below DDR pin-guide minimum {MIN_STRIP_WIDTH_UM:.6f}"
        )
    if macro.width > EXPECTED_STRIP_SIZE[0] + SIZE_TOLERANCE_UM:
        errors.append(
            f"macro width {macro.width:.6f} exceeds original approved maximum {EXPECTED_STRIP_SIZE[0]:.6f}"
        )
    if errors:
        raise ValueError(f"{macro.lef}: " + "; ".join(errors))


def transform_rect(rect: Rect, macro: Macro, origin: tuple[float, float], orient: str) -> Rect:
    ox, oy = origin
    if orient == "R0":
        return Rect(rect.layer, ox + rect.llx, oy + rect.lly, ox + rect.urx, oy + rect.ury)
    if orient == "MY":
        return Rect(
            rect.layer,
            ox + macro.width - rect.urx,
            oy + rect.lly,
            ox + macro.width - rect.llx,
            oy + rect.ury,
        )
    raise ValueError(f"unsupported orientation: {orient}")


def tx_orientation_score(
    packet: Macro,
    strip: Macro,
    packet_orient: str,
    strip_orient: str = "R0",
) -> tuple[int, float, float]:
    rows: list[tuple[float, float]] = []
    for _, packet_pin_name, strip_pin_name in TX_CONNECTIONS:
        packet_rect = transform_rect(
            packet.pins[packet_pin_name].primary_rect(), packet, PACKET_ORIGIN, packet_orient
        )
        strip_rect = transform_rect(
            strip.pins[strip_pin_name].primary_rect(), strip, STRIP_ORIGIN, strip_orient
        )
        rows.append((packet_rect.cx, strip_rect.cx))
    ordered = sorted(rows)
    strip_x = [strip_value for _, strip_value in ordered]
    inversions = sum(
        1
        for left in range(len(strip_x))
        for right in range(left + 1, len(strip_x))
        if strip_x[left] >= strip_x[right]
    )
    deltas = [abs(strip_x_um - packet_x_um) for packet_x_um, strip_x_um in rows]
    return inversions, max(deltas, default=0.0), sum(deltas)


def choose_tx_orientations(packet: Macro, strip: Macro) -> tuple[str, str, tuple[int, float, float]]:
    strip_orient = "R0"
    candidates = ["R0"]
    if "Y" in packet.symmetry:
        candidates.append("MY")
    scored = [
        (tx_orientation_score(packet, strip, orient, strip_orient), orient)
        for orient in candidates
    ]
    score, packet_orient = min(
        scored,
        key=lambda item: (*item[0], 0 if item[1] == "R0" else 1),
    )
    return packet_orient, strip_orient, score


def macro_bbox(macro: Macro, origin: tuple[float, float]) -> tuple[float, float, float, float]:
    return origin[0], origin[1], origin[0] + macro.width, origin[1] + macro.height


def intersects(a: tuple[float, float, float, float], b: tuple[float, float, float, float]) -> bool:
    return a[0] < b[2] and a[2] > b[0] and a[1] < b[3] and a[3] > b[1]


def intersection_box(
    a: tuple[float, float, float, float], b: tuple[float, float, float, float]
) -> tuple[float, float, float, float] | None:
    if not intersects(a, b):
        return None
    return max(a[0], b[0]), max(a[1], b[1]), min(a[2], b[2]), min(a[3], b[3])


def inside(inner: tuple[float, float, float, float], outer: tuple[float, float, float, float]) -> bool:
    return inner[0] >= outer[0] and inner[1] >= outer[1] and inner[2] <= outer[2] and inner[3] <= outer[3]


def require_pins(macro: Macro, names: Iterable[str]) -> None:
    missing = [name for name in names if name not in macro.pins]
    no_geometry = [name for name in names if name in macro.pins and not macro.pins[name].rects]
    if missing or no_geometry:
        raise ValueError(
            f"{macro.name}: missing pins={missing or 'none'} pins_without_rect={no_geometry or 'none'}"
        )


def verilog_ident(name: str) -> str:
    if re.match(r"^[A-Za-z_][A-Za-z0-9_$]*$", name):
        return name
    return f"\\{name} "


def external_pin_map(packet: Macro, strip: Macro) -> dict[str, tuple[str, Pin]]:
    result: dict[str, tuple[str, Pin]] = {}
    internal_packet = {packet_pin for _, packet_pin, _ in TX_CONNECTIONS}
    internal_strip = {strip_pin for _, _, strip_pin in TX_CONNECTIONS}

    for owner, macro, internal in [
        ("packet", packet, internal_packet),
        ("strip", strip, internal_strip),
    ]:
        for name, pin in macro.pins.items():
            if name in PG_PINS or pin.use in {"POWER", "GROUND"} or name in internal:
                continue
            if name in result:
                old_owner, old_pin = result[name]
                if old_pin.direction != pin.direction:
                    raise ValueError(
                        f"shared port direction mismatch for {name}: "
                        f"{old_owner}={old_pin.direction} {owner}={pin.direction}"
                    )
                continue
            result[name] = (owner, pin)
    return result


def pin_net(name: str, owner: str, internal_maps: dict[tuple[str, str], str]) -> str:
    return internal_maps.get((owner, name), verilog_ident(name))


def write_flat_verilog(path: Path, packet: Macro, strip: Macro) -> None:
    external = external_pin_map(packet, strip)
    ports = ["VDD", "VSS", *external.keys()]
    internal_maps: dict[tuple[str, str], str] = {}
    for net, packet_pin, strip_pin in TX_CONNECTIONS:
        internal_maps[("packet", packet_pin)] = net
        internal_maps[("strip", strip_pin)] = net

    with path.open("w") as fh:
        fh.write("// Auto-generated LEF-terminal assembly netlist.\n")
        fh.write("// Physical Phase A only; PG hookup is completed in the OA PG overlay.\n\n")
        fh.write(f"module {TOP_MODULE} (\n")
        for idx, name in enumerate(ports):
            comma = "," if idx + 1 < len(ports) else ""
            fh.write(f"  {verilog_ident(name)}{comma}\n")
        fh.write(");\n")
        fh.write("  inout VDD;\n  inout VSS;\n")
        for name, (_, pin) in external.items():
            direction = {"INPUT": "input", "OUTPUT": "output", "INOUT": "inout"}.get(
                pin.direction, "inout"
            )
            fh.write(f"  {direction} {verilog_ident(name)};\n")
        fh.write("\n")
        for net, _, _ in TX_CONNECTIONS:
            fh.write(f"  wire {net};\n")
        fh.write("\n")

        for owner, macro, instance in [
            ("packet", packet, "u_tx_packet_core"),
            ("strip", strip, "u_tx_ddr_strip"),
        ]:
            physical_pins = list(macro.pins.values())
            fh.write(f"  {verilog_ident(macro.name)} {instance} (\n")
            for idx, pin in enumerate(physical_pins):
                comma = "," if idx + 1 < len(physical_pins) else ""
                net = pin.name if pin.name in PG_PINS else pin_net(pin.name, owner, internal_maps)
                fh.write(f"    .{verilog_ident(pin.name)}({net}){comma}\n")
            fh.write("  );\n\n")
        fh.write("endmodule\n\n")

        for macro in [packet, strip]:
            physical_pins = list(macro.pins.values())
            fh.write(f"(* black_box *) module {verilog_ident(macro.name)} (\n")
            for idx, pin in enumerate(physical_pins):
                comma = "," if idx + 1 < len(physical_pins) else ""
                fh.write(f"  {verilog_ident(pin.name)}{comma}\n")
            fh.write(");\n")
            for pin in physical_pins:
                direction = {"INPUT": "input", "OUTPUT": "output", "INOUT": "inout"}.get(
                    pin.direction, "inout"
                )
                fh.write(f"  {direction} {verilog_ident(pin.name)};\n")
            fh.write("endmodule\n\n")


def tcl_atom(value: str) -> str:
    return "{" + value.replace("}", "\\}") + "}"


def load_obstacles(layout_audit_dir: Path) -> list[tuple[str, str, tuple[float, float, float, float], list[str]]]:
    instances_path = layout_audit_dir / "csv" / "SPADMIC2_instances_enriched.csv"
    shapes_path = layout_audit_dir / "csv" / "SPADMIC2_top_shapes.csv"
    if not instances_path.is_file() or not shapes_path.is_file():
        raise ValueError(f"layout audit CSVs missing under {layout_audit_dir}")

    obstacles: list[tuple[str, str, tuple[float, float, float, float], list[str]]] = []
    with instances_path.open(newline="") as fh:
        for row in csv.DictReader(fh):
            cell = row["cell"].strip()
            klass = row["class"].strip()
            if cell == "BOX_RING2":
                continue
            box = tuple(float(row[key]) for key in ("norm_llx", "norm_lly", "norm_urx", "norm_ury"))
            if klass == "MPTDC":
                box = (
                    max(DIE[0], box[0] - MPTDC_HALO_UM),
                    max(DIE[1], box[1] - MPTDC_HALO_UM),
                    min(DIE[2], box[2] + MPTDC_HALO_UM),
                    min(DIE[3], box[3] + MPTDC_HALO_UM),
                )
            obstacles.append((f"inst_{row['inst']}_{cell}", "MACRO", box, ["MET1", "MET2", "MET3", "METTP"]))

    allowed_layers = {"MET1", "MET2", "MET3", "METTP"}
    with shapes_path.open(newline="") as fh:
        for idx, row in enumerate(csv.DictReader(fh)):
            layer = row["layer"].strip()
            purpose = row["purpose"].strip().lower()
            if layer not in allowed_layers or purpose != "drawing":
                continue
            box = tuple(float(row[key]) for key in ("llx", "lly", "urx", "ury"))
            if box[2] <= DIE[0] or box[3] <= DIE[1] or box[0] >= DIE[2] or box[1] >= DIE[3]:
                continue
            box = (
                max(DIE[0], box[0]),
                max(DIE[1], box[1]),
                min(DIE[2], box[2]),
                min(DIE[3], box[3]),
            )
            obstacles.append((f"topshape_{idx}_{layer}", "TOP_SHAPE", box, [layer]))
    return obstacles


def build_proxy_pins(
    packet: Macro,
    strip: Macro,
    packet_orient: str,
    strip_orient: str,
) -> list[tuple[str, float, float, str, float, float, str]]:
    external = external_pin_map(packet, strip)
    proxies = []
    for name, (owner, pin) in external.items():
        macro = packet if owner == "packet" else strip
        origin = PACKET_ORIGIN if owner == "packet" else STRIP_ORIGIN
        orient = packet_orient if owner == "packet" else strip_orient
        rect = transform_rect(pin.primary_rect(), macro, origin, orient)
        proxies.append(
            (name, rect.cx, rect.cy, rect.layer, rect.urx - rect.llx, rect.ury - rect.lly, owner)
        )
    return proxies


def write_config_tcl(
    path: Path,
    packet: Macro,
    strip: Macro,
    obstacles: list[tuple[str, str, tuple[float, float, float, float], list[str]]],
    proxies: list[tuple[str, float, float, str, float, float, str]],
    packet_orient: str,
    strip_orient: str,
) -> None:
    selected_nets = [net for net, _, _ in TX_CONNECTIONS] + [
        "clk_sys",
        "rst_n",
        "clk_160m_i",
        "ddrs2_enable_i",
    ]
    with path.open("w") as fh:
        fh.write("# Auto-generated Phase-A top-coordinate assembly configuration.\n")
        fh.write(f"set SPADMIC_DA_TOP_MODULE {tcl_atom(TOP_MODULE)}\n")
        fh.write("set SPADMIC_DA_DIE {%.3f %.3f %.3f %.3f}\n" % DIE)
        fh.write("set SPADMIC_DA_INSTANCES [list \\\n")
        fh.write(
            "  [list {u_tx_packet_core} {%s} %.3f %.3f {%s}] \\\n"
            % (packet.name, PACKET_ORIGIN[0], PACKET_ORIGIN[1], packet_orient)
        )
        fh.write(
            "  [list {u_tx_ddr_strip} {%s} %.3f %.3f {%s}] \\\n"
            % (strip.name, STRIP_ORIGIN[0], STRIP_ORIGIN[1], strip_orient)
        )
        fh.write("]\n")
        fh.write("set SPADMIC_DA_ROUTE_NETS [list")
        for net in selected_nets:
            fh.write(f" {tcl_atom(net)}")
        fh.write("]\n")
        fh.write("set SPADMIC_DA_OBSTACLES [list \\\n")
        for name, kind, box, layers in obstacles:
            fh.write(
                "  [list %s %s {%.3f %.3f %.3f %.3f} {%s}] \\\n"
                % (tcl_atom(name), tcl_atom(kind), *box, " ".join(layers))
            )
        fh.write("]\n")
        fh.write("set SPADMIC_DA_PROXY_PINS [list \\\n")
        for name, x, y, layer, width, depth, owner in proxies:
            fh.write(
                "  [list %s %.3f %.3f %s %.3f %.3f %s] \\\n"
                % (tcl_atom(name), x, y, tcl_atom(layer), width, depth, tcl_atom(owner))
            )
        fh.write("]\n")


def write_connections_csv(
    path: Path,
    packet: Macro,
    strip: Macro,
    packet_orient: str,
    strip_orient: str,
) -> tuple[int, float, float]:
    rows = []
    for net, packet_pin_name, strip_pin_name in TX_CONNECTIONS:
        packet_rect = transform_rect(
            packet.pins[packet_pin_name].primary_rect(), packet, PACKET_ORIGIN, packet_orient
        )
        strip_rect = transform_rect(
            strip.pins[strip_pin_name].primary_rect(), strip, STRIP_ORIGIN, strip_orient
        )
        rows.append(
            {
                "net": net,
                "packet_pin": packet_pin_name,
                "packet_x_um": f"{packet_rect.cx:.3f}",
                "packet_y_um": f"{packet_rect.cy:.3f}",
                "strip_pin": strip_pin_name,
                "strip_x_um": f"{strip_rect.cx:.3f}",
                "strip_y_um": f"{strip_rect.cy:.3f}",
                "delta_x_um": f"{strip_rect.cx - packet_rect.cx:.3f}",
                "delta_y_um": f"{strip_rect.cy - packet_rect.cy:.3f}",
            }
        )

    ordered = sorted(rows, key=lambda row: float(row["packet_x_um"]))
    strip_x = [float(row["strip_x_um"]) for row in ordered]
    inversions = sum(
        1
        for left in range(len(strip_x))
        for right in range(left + 1, len(strip_x))
        if strip_x[left] >= strip_x[right]
    )

    with path.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    deltas = [abs(float(row["delta_x_um"])) for row in rows]
    return inversions, max(deltas, default=0.0), sum(deltas)


def write_macro_manifest(
    path: Path,
    packet: Macro,
    strip: Macro,
    packet_orient: str,
    strip_orient: str,
) -> None:
    with path.open("w", newline="") as fh:
        writer = csv.writer(fh, lineterminator="\n")
        writer.writerow(
            ["role", "macro", "lef", "width_um", "height_um", "origin_x_um", "origin_y_um", "orient", "pin_count", "symmetry"]
        )
        for role, macro, origin, orient in [
            ("packet", packet, PACKET_ORIGIN, packet_orient),
            ("strip", strip, STRIP_ORIGIN, strip_orient),
        ]:
            writer.writerow(
                [
                    role,
                    macro.name,
                    macro.lef,
                    f"{macro.width:.3f}",
                    f"{macro.height:.3f}",
                    f"{origin[0]:.3f}",
                    f"{origin[1]:.3f}",
                    orient,
                    len(macro.pins),
                    " ".join(sorted(macro.symmetry)),
                ]
            )


def write_geometry_conflicts(
    path: Path,
    packet_box: tuple[float, float, float, float],
    strip_box: tuple[float, float, float, float],
    obstacles: list[tuple[str, str, tuple[float, float, float, float], list[str]]],
) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for digital_name, digital_box in [
        ("u_tx_packet_core", packet_box),
        ("u_tx_ddr_strip", strip_box),
    ]:
        for obstacle_name, kind, obstacle_box, layers in obstacles:
            overlap = intersection_box(digital_box, obstacle_box)
            if overlap is None:
                continue
            rows.append(
                {
                    "digital_instance": digital_name,
                    "digital_bbox_um": " ".join(f"{value:.3f}" for value in digital_box),
                    "obstacle": obstacle_name,
                    "obstacle_kind": kind,
                    "obstacle_bbox_um": " ".join(f"{value:.3f}" for value in obstacle_box),
                    "overlap_bbox_um": " ".join(f"{value:.3f}" for value in overlap),
                    "overlap_width_um": f"{overlap[2] - overlap[0]:.3f}",
                    "overlap_height_um": f"{overlap[3] - overlap[1]:.3f}",
                    "blocked_layers": " ".join(layers),
                }
            )

    fieldnames = [
        "digital_instance",
        "digital_bbox_um",
        "obstacle",
        "obstacle_kind",
        "obstacle_bbox_um",
        "overlap_bbox_um",
        "overlap_width_um",
        "overlap_height_um",
        "blocked_layers",
    ]
    with path.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    return rows


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--packet-lef", required=True, type=Path)
    parser.add_argument("--strip-lef", required=True, type=Path)
    parser.add_argument("--layout-audit-dir", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    args = parser.parse_args()

    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    status_path = out_dir / "assembly_plan_status.rpt"

    try:
        packet = parse_lef(args.packet_lef.resolve())
        strip = parse_lef(args.strip_lef.resolve())
        validate_macro(packet, PACKET_MACRO, EXPECTED_PACKET_SIZE)
        validate_strip_macro(strip)
        packet_required = ["VDD", "VSS", "clk_sys", "rst_n"] + [item[1] for item in TX_CONNECTIONS]
        strip_required = ["VDD", "VSS", "clk_sys", "clk_160m_i", "rst_n", "ddrs2_enable_i"] + [
            item[2] for item in TX_CONNECTIONS
        ]
        require_pins(packet, packet_required)
        require_pins(strip, strip_required)
        packet_orient, strip_orient, orientation_score = choose_tx_orientations(packet, strip)

        packet_box = macro_bbox(packet, PACKET_ORIGIN)
        strip_box = macro_bbox(strip, STRIP_ORIGIN)
        matrix_keepout = (MATRIX[0], MATRIX[1], MATRIX[2], MATRIX[3] + 15.0)
        if not inside(packet_box, DIE) or not inside(strip_box, DIE):
            raise ValueError(f"macro outside die: packet={packet_box} strip={strip_box}")
        if intersects(packet_box, strip_box):
            raise ValueError(f"packet/strip overlap: packet={packet_box} strip={strip_box}")
        if intersects(packet_box, matrix_keepout):
            raise ValueError(f"packet violates 15um matrix keepout: {packet_box}")
        if packet_box[2] >= 2132.884:
            raise ValueError(f"packet enters matrix-to-MPTDC corridor: urx={packet_box[2]:.3f}")

        channel_um = strip_box[1] - packet_box[3]
        if channel_um <= 0:
            raise ValueError(f"non-positive TX channel: {channel_um:.3f}um")

        obstacles = load_obstacles(args.layout_audit_dir.resolve())
        geometry_conflicts = write_geometry_conflicts(
            out_dir / "assembly_geometry_conflicts.csv", packet_box, strip_box, obstacles
        )
        if geometry_conflicts:
            first = geometry_conflicts[0]
            raise ValueError(
                "digital macro overlaps a protected top object: "
                f"{first['digital_instance']} vs {first['obstacle']} "
                f"overlap={first['overlap_bbox_um']}um; "
                "see assembly_geometry_conflicts.csv"
            )

        proxies = build_proxy_pins(packet, strip, packet_orient, strip_orient)
        write_flat_verilog(out_dir / "spadmic_digital_assembly_v1_p00_tx.v", packet, strip)
        write_config_tcl(
            out_dir / "assembly_config.tcl",
            packet,
            strip,
            obstacles,
            proxies,
            packet_orient,
            strip_orient,
        )
        inversions, max_delta_x, total_delta_x = write_connections_csv(
            out_dir / "assembly_connections.csv",
            packet,
            strip,
            packet_orient,
            strip_orient,
        )
        write_macro_manifest(
            out_dir / "assembly_macro_manifest.csv",
            packet,
            strip,
            packet_orient,
            strip_orient,
        )
        (out_dir / "assembly_no_timing.sdc").write_text(
            "# Phase A intentionally has no timing-closure gate.\n"
            "# DRC and selected-net connectivity are the acceptance checks.\n"
        )
        if inversions != 0:
            raise ValueError(
                f"TX pin order crosses after orientation selection: "
                f"packet={packet_orient} strip={strip_orient} inversions={inversions}"
            )

        status_path.write_text(
            "LABEL=SPADMIC_DIGITAL_ASSEMBLY_V1_PLAN\n"
            "STATUS=PASS\n"
            "RESULT=PHASE_A_GEOMETRY_READY_FOR_INNOVUS\n"
            f"TOP_MODULE={TOP_MODULE}\n"
            f"PACKET_MACRO={packet.name}\n"
            f"PACKET_ORIENT={packet_orient}\n"
            f"PACKET_BBOX_UM={' '.join(f'{v:.3f}' for v in packet_box)}\n"
            f"STRIP_MACRO={strip.name}\n"
            f"STRIP_ORIENT={strip_orient}\n"
            f"STRIP_BBOX_UM={' '.join(f'{v:.3f}' for v in strip_box)}\n"
            f"TX_CHANNEL_HEIGHT_UM={channel_um:.3f}\n"
            f"TX_CONNECTION_COUNT={len(TX_CONNECTIONS)}\n"
            f"TX_PIN_ORDER_INVERSIONS={inversions}\n"
            f"TX_PIN_MAX_DELTA_X_UM={max_delta_x:.3f}\n"
            f"TX_PIN_TOTAL_DELTA_X_UM={total_delta_x:.3f}\n"
            f"TX_ORIENTATION_SCORE={orientation_score[0]},{orientation_score[1]:.3f},{orientation_score[2]:.3f}\n"
            f"TX_PIN_CONTRACT={TX_PIN_CONTRACT.resolve()}\n"
            "PRIMARY_ROUTE_LAYERS=MET2-MET3\n"
            "MET1_FALLBACK=SELECTED_NETS_ONLY\n"
            "TIMING_STATUS=DEFERRED_BY_PLAN\n"
            "PG_STATUS=DEFERRED_TO_OA_OVERLAY\n"
            "SIGNOFF_READY=NO\n"
        )
    except Exception as exc:
        status_path.write_text(
            "LABEL=SPADMIC_DIGITAL_ASSEMBLY_V1_PLAN\n"
            "STATUS=FAIL\n"
            "RESULT=STOPPED_BEFORE_INNOVUS\n"
            f"ERROR={str(exc).replace(chr(10), ' ')}\n"
            "SIGNOFF_READY=NO\n"
        )
        raise SystemExit(str(exc)) from exc

    print(f"ASSEMBLY_PLAN_OUT_DIR={out_dir}")
    print(f"ASSEMBLY_PLAN_STATUS={status_path}")
    print("ASSEMBLY_PLAN_RESULT=PASS")


if __name__ == "__main__":
    main()
