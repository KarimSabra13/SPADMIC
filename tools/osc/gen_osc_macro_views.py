#!/usr/bin/env python3
"""Generate provisional oscillator LEF/Liberty shells for O0 planning.

The generated views are intentionally blackbox-style integration collateral:
they define macro size, pins, simple capacitance limits, and obstructions.  They
do not model oscillator startup, jitter, phase order, or internal timing arcs.
"""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any


DEFAULTS: dict[str, Any] = {
    "defaults": {
        "width_um": 300.0,
        "height_um": 100.0,
        "phase_pin_width_um": 8.0,
        "phase_pin_height_um": 4.0,
        "ctrl_pin_width_um": 8.0,
        "ctrl_pin_height_um": 4.0,
        "enable_pin_width_um": 4.0,
        "enable_pin_height_um": 8.0,
        "pg_pin_height_um": 4.0,
        "signal_layer": "MET3",
        "enable_layer": "MET2",
        "power_layer": "METTP",
        "max_phase_cap_pf": 0.050,
        "input_cap_pf": 0.001,
        "area_um2": 30000.0,
        "symmetry": "X Y",
    },
    "macros": {
        "slow": {
            "name": "MPTDC_OSC_SLOW_PROVISIONAL",
            "output_file_prefix": "mptdc_osc_slow_provisional",
            "enable_pin": "start_i",
            "phase_side": "bottom",
            "ctrl_side": "top",
            "phase_bus": "phase_o",
            "ctrl_bus": "ctrl_i",
            "pg_power_pin": "VDDA",
            "pg_ground_pin": "VSSA",
            "notes": "PROVISIONAL - NOT ANALOG VERIFIED",
        },
        "fast": {
            "name": "MPTDC_OSC_FAST_PROVISIONAL",
            "output_file_prefix": "mptdc_osc_fast_provisional",
            "enable_pin": "stop_i",
            "phase_side": "top",
            "ctrl_side": "bottom",
            "phase_bus": "phase_o",
            "ctrl_bus": "ctrl_i",
            "pg_power_pin": "VDDA",
            "pg_ground_pin": "VSSA",
            "notes": "PROVISIONAL - NOT ANALOG VERIFIED",
        },
    },
}


def load_config(path: Path) -> dict[str, Any]:
    try:
        import yaml  # type: ignore
    except Exception:
        return DEFAULTS
    with path.open() as fh:
        data = yaml.safe_load(fh)
    if not data:
        return DEFAULTS
    merged = DEFAULTS.copy()
    merged["defaults"] = {**DEFAULTS["defaults"], **data.get("defaults", {})}
    macros = DEFAULTS["macros"].copy()
    for family, macro in (data.get("macros", {}) or {}).items():
        if family in macros:
            macros[family] = {**macros[family], **(macro or {})}
    merged["macros"] = macros
    return merged


def pin_rect(side: str, idx: int, count: int, width: float, height: float, macro_w: float, macro_h: float) -> tuple[float, float, float, float]:
    pitch = macro_w / (count + 1)
    x0 = pitch * (idx + 1) - width / 2.0
    x1 = x0 + width
    if side == "bottom":
        return x0, 0.0, x1, height
    if side == "top":
        return x0, macro_h - height, x1, macro_h
    if side == "left":
        pitch_y = macro_h / (count + 1)
        y0 = pitch_y * (idx + 1) - height / 2.0
        return 0.0, y0, width, y0 + height
    raise ValueError(f"unsupported side {side}")


def lef_pin(name: str, direction: str, use: str, layer: str, rect: tuple[float, float, float, float]) -> str:
    x0, y0, x1, y1 = rect
    return f"""  PIN {name}
    DIRECTION {direction} ;
    USE {use} ;
    PORT
      LAYER {layer} ;
        RECT {x0:.3f} {y0:.3f} {x1:.3f} {y1:.3f} ;
    END
  END {name}
"""


def make_lef(macro: dict[str, Any], defaults: dict[str, Any]) -> str:
    name = macro["name"]
    w = float(defaults["width_um"])
    h = float(defaults["height_um"])
    sig_layer = defaults["signal_layer"]
    enable_layer = defaults["enable_layer"]
    power_layer = defaults["power_layer"]
    symmetry = defaults.get("symmetry", "X Y")
    phase_side = macro["phase_side"]
    ctrl_side = macro["ctrl_side"]
    phase_bus = macro["phase_bus"]
    ctrl_bus = macro["ctrl_bus"]
    pg_h = float(defaults["pg_pin_height_um"])

    lines = [
        'VERSION 5.8 ;',
        'BUSBITCHARS "[]" ;',
        'DIVIDERCHAR "/" ;',
        '',
        f'MACRO {name}',
        '  CLASS BLOCK ;',
        f'  FOREIGN {name} 0.000 0.000 ;',
        '  ORIGIN 0.000 0.000 ;',
        f'  SIZE {w:.3f} BY {h:.3f} ;',
        f'  SYMMETRY {symmetry} ;',
        '',
    ]

    lines.append(lef_pin(macro["enable_pin"], "INPUT", "SIGNAL", enable_layer, (0.0, h / 2.0 - 4.0, 4.0, h / 2.0 + 4.0)))
    lines.append(lef_pin("rst_n", "INPUT", "SIGNAL", enable_layer, (0.0, h / 2.0 + 10.0, 4.0, h / 2.0 + 18.0)))
    lines.append(lef_pin("test_i", "INPUT", "SIGNAL", enable_layer, (0.0, h / 2.0 - 18.0, 4.0, h / 2.0 - 10.0)))

    for idx in range(8):
        rect = pin_rect(ctrl_side, idx, 8, float(defaults["ctrl_pin_width_um"]), float(defaults["ctrl_pin_height_um"]), w, h)
        lines.append(lef_pin(f"{ctrl_bus}[{idx}]", "INPUT", "SIGNAL", sig_layer, rect))
    for idx in range(8):
        rect = pin_rect(phase_side, idx, 8, float(defaults["phase_pin_width_um"]), float(defaults["phase_pin_height_um"]), w, h)
        lines.append(lef_pin(f"{phase_bus}[{idx}]", "OUTPUT", "SIGNAL", sig_layer, rect))

    lines.append(lef_pin(macro["pg_power_pin"], "INOUT", "POWER", power_layer, (0.0, h - 2.0 * pg_h, w, h - pg_h)))
    lines.append(lef_pin(macro["pg_ground_pin"], "INOUT", "GROUND", power_layer, (0.0, pg_h, w, 2.0 * pg_h)))
    lines.append(f"""  OBS
    LAYER MET1 ;
      RECT 0.000 0.000 {w:.3f} {h:.3f} ;
    LAYER MET2 ;
      RECT 4.000 0.000 {w:.3f} {h:.3f} ;
    LAYER MET3 ;
      RECT 0.000 {2.0 * pg_h:.3f} {w:.3f} {h - 2.0 * pg_h:.3f} ;
    LAYER METTP ;
      RECT 0.000 {2.0 * pg_h:.3f} {w:.3f} {h - 2.0 * pg_h:.3f} ;
  END
END {name}
""")
    return "\n".join(lines)


def make_lib(macro: dict[str, Any], defaults: dict[str, Any]) -> str:
    name = macro["name"]
    cap = float(defaults["input_cap_pf"])
    max_phase_cap = float(defaults["max_phase_cap_pf"])
    area = float(defaults["area_um2"])
    power_pin = macro["pg_power_pin"]
    ground_pin = macro["pg_ground_pin"]
    phase_bus = macro["phase_bus"]
    ctrl_bus = macro["ctrl_bus"]
    pins = [macro["enable_pin"], "rst_n", "test_i"]

    lines = [
        f'/* {macro.get("notes", "PROVISIONAL - NOT ANALOG VERIFIED")} */',
        f'library ({name.lower()}_lib) {{',
        '  delay_model : table_lookup;',
        '  time_unit : "1ns";',
        '  voltage_unit : "1V";',
        '  current_unit : "1mA";',
        '  capacitive_load_unit (1, pf);',
        '  nom_process : 1.0;',
        '  nom_temperature : 25.0;',
        '  nom_voltage : 1.8;',
        '',
        '  type (mptdc_osc_ctrl_bus) {',
        '    base_type : array;',
        '    data_type : bit;',
        '    bit_width : 8;',
        '    bit_from : 7;',
        '    bit_to : 0;',
        '    downto : true;',
        '  }',
        '',
        '  type (mptdc_osc_phase_bus) {',
        '    base_type : array;',
        '    data_type : bit;',
        '    bit_width : 8;',
        '    bit_from : 7;',
        '    bit_to : 0;',
        '    downto : true;',
        '  }',
        '',
        f'  cell ({name}) {{',
        f'    area : {area:.3f};',
        '    cell_leakage_power : 0.0;',
        f'    pg_pin ({power_pin}) {{ pg_type : primary_power; voltage_name : "{power_pin}"; }}',
        f'    pg_pin ({ground_pin}) {{ pg_type : primary_ground; voltage_name : "{ground_pin}"; }}',
    ]
    for pin in pins:
        lines.extend([
            f'    pin ("{pin}") {{',
            '      direction : input;',
            f'      capacitance : {cap:.6f};',
            f'      related_power_pin : "{power_pin}";',
            f'      related_ground_pin : "{ground_pin}";',
            '    }',
        ])
    lines.extend([
        f'    bus ({ctrl_bus}) {{',
        '      bus_type : mptdc_osc_ctrl_bus;',
        '      direction : input;',
        f'      capacitance : {cap:.6f};',
        f'      related_power_pin : "{power_pin}";',
        f'      related_ground_pin : "{ground_pin}";',
        '    }',
        '',
        f'    bus ({phase_bus}) {{',
        '      bus_type : mptdc_osc_phase_bus;',
        '      direction : output;',
        f'      max_capacitance : {max_phase_cap:.6f};',
        f'      related_power_pin : "{power_pin}";',
        f'      related_ground_pin : "{ground_pin}";',
        '    }',
    ])
    lines.extend(['  }', '}'])
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", type=Path, default=Path("tools/osc/oscillator_macro_template.yaml"))
    parser.add_argument("--out-dir", type=Path, default=Path("MPTDC/syn/macros"))
    args = parser.parse_args()

    cfg = load_config(args.template)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    for family, macro in cfg["macros"].items():
        prefix = macro["output_file_prefix"]
        lef_path = args.out_dir / f"{prefix}.lef"
        lib_path = args.out_dir / f"{prefix}.lib"
        lef_path.write_text(make_lef(macro, cfg["defaults"]))
        lib_path.write_text(make_lib(macro, cfg["defaults"]))
        print(f"wrote {family}: {lef_path} {lib_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
