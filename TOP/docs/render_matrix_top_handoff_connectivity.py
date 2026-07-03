#!/usr/bin/env python3
"""Render human-readable views of the matrix-top handoff connectivity CSV."""

from __future__ import annotations

import csv
from collections import OrderedDict
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SOURCE_CSV = ROOT / "26_MATRIX_TOP_HANDOFF_CONNECTIVITY.csv"
MARKDOWN_OUT = ROOT / "26_MATRIX_TOP_HANDOFF_CONNECTIVITY_READABLE.md"
EXCEL_CSV_OUT = ROOT / "26_MATRIX_TOP_HANDOFF_CONNECTIVITY_EXCEL.csv"


SECTION_TITLES = {
    "metadata": "00 - Metadata and Source Context",
    "top_core_boundary": "01 - Digital Top Core Boundary",
    "pad_wrapper": "02 - Pads, PLL, Clock Wrapper, and Macro Boundary",
    "reset_glue": "03 - Reset Glue",
    "handoff_block": "04 - Genus Handoff Blocks",
    "glue_block": "05 - Glue RTL Detail",
    "mptdc_macro": "06 - MPTDC Macro Black-Box Contract",
}

DISPLAY_COLUMNS = [
    "row",
    "section_title",
    "section",
    "block",
    "instance",
    "module",
    "block_kind",
    "port",
    "direction",
    "width",
    "clock_domain",
    "reset_domain",
    "connection_class",
    "source_signal",
    "connects_to",
    "pad_or_macro",
    "voltage_domain",
    "top_wrapper_action",
    "notes",
    "source_file",
]


def clean(value: str | None) -> str:
    return (value or "").replace("\n", " ").strip()


def md(value: str | None) -> str:
    text = clean(value)
    if text == "":
        return "-"
    return text.replace("|", "\\|")


def target(row: dict[str, str]) -> str:
    parts = [
        clean(row.get("destination_block")),
        clean(row.get("destination_instance")),
        clean(row.get("destination_port")),
    ]
    parts = [part for part in parts if part and part != "-"]
    return ".".join(parts) if parts else "-"


def section_title(section: str) -> str:
    return SECTION_TITLES.get(section, f"99 - {section}")


def load_rows() -> list[dict[str, str]]:
    with SOURCE_CSV.open(newline="") as f:
        return list(csv.DictReader(f))


def ordered_groups(rows: list[dict[str, str]]) -> OrderedDict[str, OrderedDict[str, list[dict[str, str]]]]:
    raw_groups: OrderedDict[str, OrderedDict[str, list[dict[str, str]]]] = OrderedDict()
    for row in rows:
        section = clean(row.get("section"))
        block = clean(row.get("block"))
        raw_groups.setdefault(section, OrderedDict()).setdefault(block, []).append(row)

    groups: OrderedDict[str, OrderedDict[str, list[dict[str, str]]]] = OrderedDict()
    for section in sorted(raw_groups, key=lambda name: (section_title(name), name)):
        groups[section] = raw_groups[section]
    return groups


def render_block_index(rows: list[dict[str, str]]) -> list[str]:
    lines = [
        "## Quick Index",
        "",
        "| Section | Block | Module(s) | Kind(s) | Rows | Main Action |",
        "| --- | --- | --- | --- | ---: | --- |",
    ]
    for section, blocks in ordered_groups(rows).items():
        for block, block_rows in blocks.items():
            modules = sorted({clean(r.get("module")) for r in block_rows if clean(r.get("module")) not in {"", "-"}})
            kinds = sorted({clean(r.get("block_kind")) for r in block_rows if clean(r.get("block_kind")) not in {"", "-"}})
            actions = [
                clean(r.get("top_wrapper_action"))
                for r in block_rows
                if clean(r.get("top_wrapper_action")) not in {"", "-"}
            ]
            action = actions[0] if actions else "-"
            lines.append(
                f"| {md(section_title(section))} | {md(block)} | {md(', '.join(modules) or '-')} | "
                f"{md(', '.join(kinds) or '-')} | {len(block_rows)} | {md(action)} |"
            )
    lines.append("")
    return lines


def render_metadata_table(rows: list[dict[str, str]]) -> list[str]:
    lines = [
        "| Block | Module | Source / Signal | Target / Location | Action | Notes | Source File |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in rows:
        lines.append(
            f"| {md(row.get('block'))} | {md(row.get('module'))} | {md(row.get('source_signal'))} | "
            f"{md(row.get('pad_or_macro'))} | {md(row.get('top_wrapper_action'))} | "
            f"{md(row.get('notes'))} | {md(row.get('source_file'))} |"
        )
    lines.append("")
    return lines


def render_port_table(rows: list[dict[str, str]]) -> list[str]:
    lines = [
        "| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in rows:
        lines.append(
            f"| {md(row.get('port'))} | {md(row.get('direction'))} | {md(row.get('width'))} | "
            f"{md(row.get('clock_domain'))} | {md(row.get('reset_domain'))} | "
            f"{md(row.get('source_signal'))} | {md(target(row))} | {md(row.get('pad_or_macro'))} | "
            f"{md(row.get('top_wrapper_action'))} | {md(row.get('notes'))} |"
        )
    lines.append("")
    return lines


def render_markdown(rows: list[dict[str, str]]) -> None:
    groups = ordered_groups(rows)
    lines = [
        "# Matrix TOP Handoff Connectivity - Readable View",
        "",
        "This file is generated from `26_MATRIX_TOP_HANDOFF_CONNECTIVITY.csv`.",
        "Use the CSV as the machine-readable source of truth and this Markdown file",
        "for review in a text editor, GitHub, or an email attachment.",
        "",
        "Regenerate with:",
        "",
        "```bash",
        "python3 TOP/docs/render_matrix_top_handoff_connectivity.py",
        "```",
        "",
    ]
    lines.extend(render_block_index(rows))

    for section, blocks in groups.items():
        lines.extend([f"## {md(section_title(section))}", ""])
        for block, block_rows in blocks.items():
            module_names = sorted(
                {clean(r.get("module")) for r in block_rows if clean(r.get("module")) not in {"", "-"}}
            )
            kind_names = sorted(
                {clean(r.get("block_kind")) for r in block_rows if clean(r.get("block_kind")) not in {"", "-"}}
            )
            suffix = []
            if module_names:
                suffix.append(f"module: `{', '.join(module_names)}`")
            if kind_names:
                suffix.append(f"kind: `{', '.join(kind_names)}`")
            suffix_text = f" ({'; '.join(suffix)})" if suffix else ""
            lines.extend([f"### {md(block)}{suffix_text}", ""])
            if section == "metadata":
                lines.extend(render_metadata_table(block_rows))
            else:
                lines.extend(render_port_table(block_rows))

    while lines and lines[-1] == "":
        lines.pop()
    MARKDOWN_OUT.write_text("\n".join(lines) + "\n")


def render_excel_csv(rows: list[dict[str, str]]) -> None:
    with EXCEL_CSV_OUT.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=DISPLAY_COLUMNS, lineterminator="\n")
        writer.writeheader()
        for idx, row in enumerate(rows, start=1):
            section = clean(row.get("section"))
            writer.writerow(
                {
                    "row": idx,
                    "section_title": section_title(section),
                    "section": section,
                    "block": clean(row.get("block")),
                    "instance": clean(row.get("instance")),
                    "module": clean(row.get("module")),
                    "block_kind": clean(row.get("block_kind")),
                    "port": clean(row.get("port")),
                    "direction": clean(row.get("direction")),
                    "width": clean(row.get("width")),
                    "clock_domain": clean(row.get("clock_domain")),
                    "reset_domain": clean(row.get("reset_domain")),
                    "connection_class": clean(row.get("connection_class")),
                    "source_signal": clean(row.get("source_signal")),
                    "connects_to": target(row),
                    "pad_or_macro": clean(row.get("pad_or_macro")),
                    "voltage_domain": clean(row.get("voltage_domain")),
                    "top_wrapper_action": clean(row.get("top_wrapper_action")),
                    "notes": clean(row.get("notes")),
                    "source_file": clean(row.get("source_file")),
                }
            )


def main() -> None:
    rows = load_rows()
    render_markdown(rows)
    render_excel_csv(rows)
    print(f"Wrote {MARKDOWN_OUT}")
    print(f"Wrote {EXCEL_CSV_OUT}")


if __name__ == "__main__":
    main()
