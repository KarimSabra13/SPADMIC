#!/usr/bin/env python3
"""Generate French SVG/DOT/Markdown/HTML exports for the MPTDC GUI."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from schematic_symbols import (
    PALETTE,
    async_arrow,
    bit_field,
    cdc_sync_symbol,
    clock_arrow,
    control_arrow,
    data_arrow,
    domain_lane,
    esc,
    fifo_symbol,
    fsm_symbol,
    gray_counter_symbol,
    label,
    mux_symbol,
    packet_adapter_symbol,
    pd_matrix_symbol,
    port_pin,
    register_bank_symbol,
    reset_arrow,
    ring_oscillator_symbol,
    serializer_symbol,
    svg_footer,
    svg_header,
    warning_marker,
)


def evidence_text(refs: list[dict[str, Any]]) -> str:
    if not refs:
        return "preuve RTL/doc non renseignée"
    ref = refs[0]
    return f"{ref.get('file')}:{ref.get('line')}"


SEVERITY_FR = {"low": "faible", "medium": "moyen", "high": "élevé"}

UNCERTAINTY_FR = {
    "Expected top name absent": (
        "Nom de top attendu absent",
        "`mptdc_vernier_top_silicon` n'a pas été trouvé dans les fichiers du dépôt parcourus.",
    ),
    "Physical oscillator not signoff-ready in repo": (
        "Oscillateur physique non prêt pour la revue de signoff",
        "Le chemin synthèse utilise un bloc de remplacement tant que le contrat macro réel n'est pas disponible.",
    ),
    "Standard CDC/STA closure not proven": (
        "Fermeture CDC/STA standard non prouvée",
        "Les verrous asynchrones, la capture STOP, les snapshots Gray et les horloges locales PD exigent une méthodologie et des dérogations contrôlées.",
    ),
    "Committed VIP artifact appears stale or failed": (
        "Artefact VIP commité probablement ancien ou échoué",
        "`vip_summary.json` rapporte 4096 échecs, en contradiction avec les statuts README/docs courants.",
    ),
}

DATAFLOW_FR = {
    "SPAD/CAL async source select": (
        "Sélection source SPAD/CAL asynchrone",
        "`mptdc_input_mux` sélectionne START/STOP SPAD ou calibration comme signaux asynchrones combinatoires purs.",
    ),
    "START accepts and allocates a context": (
        "START accepté et contexte alloué",
        "Le frontend accepte START uniquement si la conversion est armée, non verrouillée et avec un contexte libre.",
    ),
    "STOP launches fast oscillator and PD eligibility": (
        "STOP lance l'oscillateur rapide et l'éligibilité PD",
        "STOP, ou le timeout synthétique, ne verrouille `stop_latched` qu'après START ; l'oscillateur rapide et `pd_enable` dérivent des verrous START/STOP.",
    ),
    "8 x 8 phase detector matrix": (
        "Matrice phase detector 8 x 8",
        "`mptdc_core` génère une cellule PD par paire phase lente/rapide et verrouille `nfast_hit` par cellule.",
    ),
    "Snapshot, context bank, drain": (
        "Snapshot, banque de contextes, drain",
        "La FSM `clk_sys` échantillonne l'image tenue, commit le contexte, puis `drain_ctrl` émet META/HIT.",
    ),
    "FIFO to local or shared readout": (
        "FIFO vers sortie locale ou readout partagé",
        "La FIFO acquisition est consommée par le serializer local `narrow16` ou par l'export partagé `acq_valid/acq_ready`.",
    ),
}


def uncertainty_fr(item: dict[str, Any]) -> tuple[str, str, str]:
    title, detail = UNCERTAINTY_FR.get(item.get("title"), (item.get("title", ""), item.get("detail", "")))
    severity = SEVERITY_FR.get(item.get("severity", ""), item.get("severity", ""))
    return severity, title, detail


def dataflow_fr(item: dict[str, Any]) -> tuple[str, str]:
    return DATAFLOW_FR.get(item.get("title"), (item.get("title", ""), item.get("claim", "")))


def generate_architecture_schematic(db: dict[str, Any]) -> str:
    svg = [svg_header(1780, 1120, "Schéma architectural MPTDC")]
    svg.append(label(42, 44, "Architecture RTL MPTDC - schéma microélectronique", "domain-label"))
    svg.append(label(42, 68, "Top actif repo-grounded : mptdc_top_asic ; contexte full-chip : spadmic_top_v1", "caption"))
    lanes = [
        (30, 90, 1720, 125, "Domaine asynchrone START/STOP", PALETTE["domain_async"]),
        (30, 230, 1720, 112, "Domaine oscillateur lent", PALETTE["domain_clock"]),
        (30, 355, 1720, 112, "Domaine oscillateur rapide", PALETTE["domain_clock"]),
        (30, 480, 1720, 140, "Domaine phase detector Vernier", PALETTE["domain_data"]),
        (30, 635, 1720, 155, "Domaine clk_sys", PALETTE["domain_control"]),
        (30, 805, 1720, 120, "Domaine readout / FIFO / stream", PALETTE["domain_data"]),
        (30, 940, 1720, 120, "Contexte TOP partagé spadmic_top_v1", PALETTE["domain_reset"]),
    ]
    for lane in lanes:
        svg.append(domain_lane(*lane))

    svg.append(mux_symbol(190, 125, 170, 74, "mptdc_input_mux", "MUX SPAD/CAL", ["start_spad_async_i", "stop_spad_async_i", "cal_start_async_i", "cal_stop_async_i"], ["start_async_o", "stop_async_o"], "input_sel"))
    svg.append(register_bank_symbol(110, 665, 205, 92, "mptdc_csr_minimal", "CSR / config", "arm, clear, status", ["csr_valid_i", "csr_write_i"], ["cfg", "conv_arm", "fifo_clr"]))
    svg.append(cdc_sync_symbol(385, 652, 170, 94, "mptdc_reset_sync", "Sync reset", 3))
    svg.append(register_bank_symbol(420, 125, 260, 82, "mptdc_async_frontend_v2", "Frontend async", "START/STOP + contexte", ["start_async_i", "stop_async_i", "conv_arm_i"], ["osc_slow_en", "osc_fast_en", "pd_enable", "ctx_drain"]))

    svg.append(ring_oscillator_symbol(730, 246, 215, 82, "mptdc_osc_wrapper", "Oscillateur lent", "slow_phase[7:0]", "lent"))
    svg.append(ring_oscillator_symbol(730, 371, 215, 82, "mptdc_osc_wrapper", "Oscillateur rapide", "fast_phase[7:0]", "rapide"))
    svg.append(gray_counter_symbol(1010, 252, 210, 88, "mptdc_gray_cnt_sync", "Compteur Gray slow"))
    svg.append(gray_counter_symbol(1010, 377, 210, 88, "mptdc_gray_cnt_sync", "Compteur Gray fast"))
    svg.append(cdc_sync_symbol(1040, 660, 190, 92, "mptdc_hit_capture_bridge", "Bridge capture", 2, warning=True))
    svg.append(register_bank_symbol(420, 370, 210, 74, "mptdc_stop_capture_async", "Capture STOP", "boundary bits", ["stop_async_i"], ["phase0_snap", "slow_boundary_inc"]))

    svg.append(pd_matrix_symbol(1280, 492, 330, 118, "mptdc_pd_cell", "Matrice PD 8x8", (3, 5)))
    svg.append(fsm_symbol(650, 660, 265, 96, "mptdc_meas_ctrl", "FSM mesure", ["IDLE", "MEAS", "SNAP", "COUNT", "EVAL"], ["stop_latched", "pd_hit_level"], ["capture_en", "clear"]))
    svg.append(register_bank_symbol(1280, 665, 250, 94, "mptdc_context_bank", "Banque contexte", "2 entrées", ["capture_en", "ctx_id"], ["ctx_valid", "ctx_drain"]))

    svg.append(fsm_symbol(520, 825, 250, 84, "mptdc_drain_ctrl", "FSM drain", ["IDLE", "SEL", "META", "HIT"], ["ctx_drain"], ["fifo_wr_en"]))
    svg.append(fifo_symbol(840, 820, 225, 92, "mptdc_sync_fifo", "FIFO acquisition"))
    svg.append(serializer_symbol(1140, 815, 255, 96, "mptdc_narrow16_tx_v2", "Serializer narrow16"))
    svg.append(packet_adapter_symbol(1140, 950, 255, 86, "mptdc_core", "Export partagé acq_*"))
    svg.append(packet_adapter_symbol(1450, 956, 245, 80, "spadmic_tdc_packet_adapter", "Adaptateur TOP / ARB / TX"))

    # External pins.
    for idx, pin in enumerate(["start_spad_async_i", "stop_spad_async_i", "cal_start_async_i", "cal_stop_async_i"]):
        svg.append(port_pin(92, 136 + idx * 17, pin, "left", PALETTE["async"]))
        svg.append(async_arrow(104, 136 + idx * 17, 190, 136 + min(idx, 3) * 17, "", signal_id=pin))
    for idx, pin in enumerate(["clk_sys", "rst_sys_n/async_rst_n", "conv_arm", "fifo_clr", "soft_rst"]):
        svg.append(label(98, 690 + idx * 18, pin, "pin", "end"))

    # Main flow.
    svg.extend(
        [
            async_arrow(360, 162, 420, 162, "START/STOP", signal_id="start_stop_selected"),
            control_arrow(315, 704, 420, 166, "cfg/arm", signal_id="conv_arm"),
            control_arrow(680, 166, 730, 287, "osc_slow_en", signal_id="osc_slow_en_async_o"),
            control_arrow(680, 178, 730, 412, "osc_fast_en", signal_id="osc_fast_en_async_o"),
            clock_arrow(945, 286, 1010, 286, "slow_phase[0]", signal_id="slow_phase"),
            clock_arrow(945, 412, 1010, 412, "fast_phase[0]", signal_id="fast_phase"),
            clock_arrow(945, 286, 1280, 525, "slow_phase[7:0]", signal_id="slow_phase_bus"),
            clock_arrow(945, 412, 1425, 492, "fast_phase[7:0]", signal_id="fast_phase_bus"),
            async_arrow(630, 407, 1280, 552, "boundary", signal_id="stop_boundary"),
            data_arrow(1610, 552, 1610, 705, "pd_hit_level", signal_id="pd_hit_level"),
            data_arrow(1220, 296, 1120, 660, "nslow", signal_id="nslow_snapshot"),
            data_arrow(1220, 421, 1160, 660, "nfast", signal_id="nfast_snapshot"),
            data_arrow(1230, 706, 1280, 706, "snapshot", signal_id="hit_capture_snapshot"),
            control_arrow(915, 708, 1040, 706, "snapshot_en", signal_id="snapshot_en_o"),
            control_arrow(1530, 710, 520, 866, "ctx_drain", signal_id="ctx_drain"),
            data_arrow(770, 866, 840, 866, "META/HIT", signal_id="drain_fifo_wr_data"),
            data_arrow(1065, 866, 1140, 866, "FIFO front", signal_id="fifo_rd_data"),
            data_arrow(1395, 866, 1510, 866, "narrow16", signal_id="narrow_data_o"),
            data_arrow(1395, 993, 1450, 993, "acq_*", signal_id="acq_data_o"),
            reset_arrow(555, 699, 650, 699, "rst/clk_sys", signal_id="rst_sys_n"),
        ]
    )
    svg.append(warning_marker(1668, 515, "STA/CDC + macro osc."))
    svg.append(label(1320, 1092, "Pointillé orange = async ; bleu = clock/phase ; vert = données ; violet = contrôle ; rouge = incertain/signoff", "caption"))
    svg.append(svg_footer())
    return "\n".join(svg)


def generate_dataflow_animation_svg(db: dict[str, Any]) -> str:
    svg = [svg_header(1500, 760, "Animation schématique du flux MPTDC")]
    svg.append(label(36, 42, "Animation du flux de données - acquisition Vernier", "domain-label"))
    svg.append(label(36, 66, "Les blocs et bus sont activés par l'interface web étape par étape.", "caption"))
    svg.append(domain_lane(28, 88, 1444, 96, "Asynchrone", PALETTE["domain_async"]))
    svg.append(domain_lane(28, 204, 1444, 112, "Oscillateurs / phases", PALETTE["domain_clock"]))
    svg.append(domain_lane(28, 336, 1444, 130, "Détection Vernier", PALETTE["domain_data"]))
    svg.append(domain_lane(28, 486, 1444, 110, "clk_sys / contrôle", PALETTE["domain_control"]))
    svg.append(domain_lane(28, 616, 1444, 90, "Readout", PALETTE["domain_data"]))
    svg.append(mux_symbol(70, 110, 150, 58, "mptdc_input_mux", "MUX", ["SPAD", "CAL"], ["start/stop"], "input_sel"))
    svg.append(register_bank_symbol(270, 110, 190, 58, "mptdc_async_frontend_v2", "Frontend", "verrous", ["START", "STOP"], ["slow_en", "fast_en"]))
    svg.append(ring_oscillator_symbol(520, 222, 190, 70, "mptdc_osc_wrapper", "Osc. lent", "slow_phase", "lent"))
    svg.append(ring_oscillator_symbol(760, 222, 190, 70, "mptdc_osc_wrapper", "Osc. rapide", "fast_phase", "rapide"))
    svg.append(gray_counter_symbol(1010, 220, 205, 74, "mptdc_gray_cnt_sync", "Compteurs Gray"))
    svg.append(pd_matrix_symbol(520, 354, 275, 102, "mptdc_pd_cell", "PD 8x8", (3, 5)))
    svg.append(cdc_sync_symbol(880, 358, 190, 88, "mptdc_hit_capture_bridge", "Pont CDC", 2, warning=True))
    svg.append(fsm_symbol(250, 506, 250, 78, "mptdc_meas_ctrl", "FSM mesure", ["IDLE", "SNAP", "EVAL", "CLEAR"], ["snapshot"], ["capture"]))
    svg.append(register_bank_symbol(570, 504, 210, 80, "mptdc_context_bank", "Banque contexte", "2 contextes", ["capture"], ["à drainer"]))
    svg.append(fsm_symbol(840, 506, 210, 78, "mptdc_drain_ctrl", "FSM drain", ["META", "HIT"], ["ctx"], ["fifo_wr"]))
    svg.append(fifo_symbol(1110, 500, 200, 86, "mptdc_sync_fifo", "FIFO"))
    svg.append(serializer_symbol(1040, 626, 220, 68, "mptdc_narrow16_tx_v2", "narrow16"))
    svg.append(packet_adapter_symbol(1280, 626, 170, 68, "spadmic_tdc_packet_adapter", "TX TOP"))
    svg.extend(
        [
            async_arrow(220, 139, 270, 139, "sélection", signal_id="start_stop_selected"),
            control_arrow(460, 139, 520, 256, "slow_en", signal_id="osc_slow_en_async_o"),
            control_arrow(460, 150, 760, 256, "fast_en", signal_id="osc_fast_en_async_o"),
            clock_arrow(710, 256, 1010, 256, "slow_phase", signal_id="slow_phase"),
            clock_arrow(950, 256, 1010, 256, "fast_phase", signal_id="fast_phase"),
            clock_arrow(710, 292, 600, 354, "", signal_id="slow_phase_bus"),
            clock_arrow(860, 292, 715, 354, "", signal_id="fast_phase_bus"),
            data_arrow(795, 405, 880, 405, "hits", signal_id="pd_hit_level"),
            data_arrow(1070, 405, 1120, 505, "snapshot", signal_id="hit_capture_snapshot"),
            control_arrow(500, 545, 570, 545, "capture", signal_id="capture_en_o"),
            data_arrow(780, 545, 840, 545, "ctx", signal_id="ctx_drain"),
            data_arrow(1050, 545, 1110, 545, "records", signal_id="drain_fifo_wr_data"),
            data_arrow(1210, 586, 1140, 626, "local", signal_id="fifo_rd_data"),
            data_arrow(1310, 545, 1360, 626, "shared", signal_id="acq_data_o"),
        ]
    )
    svg.append(svg_footer())
    return "\n".join(svg)


def generate_pd_matrix_svg(db: dict[str, Any]) -> str:
    svg = [svg_header(980, 720, "Matrice Vernier 8x8")]
    svg.append(label(36, 44, "Matrice Vernier 8x8", "domain-label"))
    svg.append(label(36, 68, "Chaque cellule : CELL = ns * NE + nf ; NE = 8 dans la cible active.", "caption"))
    svg.append(pd_matrix_symbol(90, 120, 560, 470, "mptdc_pd_cell", "Matrice PD 8x8", (3, 5)))
    svg.append(data_arrow(665, 265, 860, 265, "pd_hit_level[63:0]"))
    svg.append(data_arrow(665, 330, 860, 330, "pd_nfast_hit_packed"))
    svg.append(label(700, 385, "Exemple : ns=3, nf=5 -> CELL=29", "domain-label"))
    svg.append(label(700, 415, "La cellule allumée représente un croisement verrouillé.", "caption"))
    svg.append(label(700, 445, "Références : mptdc_core.sv:404-417 ; mptdc_pd_cell.sv:83-103", "caption"))
    svg.append(svg_footer())
    return "\n".join(svg)


def generate_cdc_timing_svg(db: dict[str, Any]) -> str:
    svg = [svg_header(1360, 760, "CDC et timing MPTDC")]
    svg.append(label(36, 44, "CDC / timing - domaines et crossings", "domain-label"))
    svg.append(domain_lane(40, 88, 1240, 105, "START/STOP asynchrones", PALETTE["domain_async"]))
    svg.append(domain_lane(40, 218, 1240, 105, "Oscillateurs slow/fast", PALETTE["domain_clock"]))
    svg.append(domain_lane(40, 348, 1240, 140, "Capture statique / snapshot", PALETTE["domain_data"]))
    svg.append(domain_lane(40, 518, 1240, 125, "clk_sys", PALETTE["domain_control"]))
    svg.append(cdc_sync_symbol(170, 535, 205, 84, "mptdc_reset_sync", "Reset synchronizers", 2))
    svg.append(cdc_sync_symbol(480, 360, 230, 92, "mptdc_hit_capture_bridge", "Bus snapshot tenu", 2, True))
    svg.append(gray_counter_symbol(770, 235, 230, 74, "mptdc_gray_cnt_sync", "Gray counter CDC"))
    svg.append(cdc_sync_symbol(1060, 535, 180, 84, "mptdc_pulse_sync", "Pulse sync support", 2, True))
    svg.extend(
        [
            async_arrow(170, 140, 480, 405, "START/STOP -> latch"),
            clock_arrow(620, 270, 770, 270, "phase[0]"),
            data_arrow(1000, 272, 920, 535, "gray snapshot"),
            data_arrow(710, 405, 790, 535, "held bus"),
            reset_arrow(375, 577, 480, 577, "rst_sys_n"),
        ]
    )
    svg.append(warning_marker(1030, 390, "waiver nécessaire"))
    svg.append(warning_marker(1170, 270, "macro oscillateur"))
    svg.append(label(76, 690, "Alertes : à valider STA/CDC ; dépend du contrat macro oscillateur ; pas une preuve silicium.", "caption"))
    svg.append(label(76, 715, "Références : docs/timing_closure/cdc_async_waiver_package.md ; oscillator_macro_contract.md ; MPTDC/docs/07_DESIGN_REVIEW.md", "caption"))
    svg.append(svg_footer())
    return "\n".join(svg)


def generate_event_format_svg(db: dict[str, Any]) -> str:
    svg = [svg_header(1180, 720, "Format événement MPTDC")]
    svg.append(label(36, 44, "Format événement / sortie", "domain-label"))
    svg.append(label(36, 68, "Mots 16-bit en mode standalone ; records META/HIT en mode readout partagé.", "caption"))
    x = 100
    y = 125
    w = 54
    rows = [
        ("HEADER", [("marqueur", "15:12", "#fee2e2"), ("ctx", "11", "#dbeafe"), ("hit_count", "10:7", "#dcfce7"), ("flags", "6:3", "#fef3c7"), ("slow_boundary_inc", "2", "#f5f3ff"), ("rsvd", "1:0", "#f8fafc")]),
        ("Mot HIT 0", [("marqueur", "15:12", "#fee2e2"), ("ns", "11:9", "#dbeafe"), ("nf", "8:6", "#dcfce7"), ("nfast", "5:0", "#ecfdf5")]),
        ("Mot HIT 1", [("marqueur", "15:12", "#fee2e2"), ("nslow", "11:3", "#ecfdf5"), ("stop_disc", "2:0", "#f5f3ff")]),
        ("EOC", [("marqueur", "15:14", "#fee2e2"), ("conv_count", "13:0", "#dbeafe")]),
    ]
    for ridx, (name, fields) in enumerate(rows):
        yy = y + ridx * 92
        svg.append(label(42, yy + 28, name, "domain-label"))
        xx = x
        for fname, bits, fill in fields:
            span = max(1, len(bits.split(":")) and (abs(int(bits.split(":")[0]) - int(bits.split(":")[-1])) + 1 if ":" in bits else 1))
            fw = max(w, span * 38)
            svg.append(bit_field(xx, yy, fw, 48, fname, bits, fill))
            xx += fw
    svg.append(packet_adapter_symbol(770, 120, 260, 85, "mptdc_drain_ctrl", "Records internes"))
    svg.append(data_arrow(900, 205, 900, 275, "META/HIT acquisition records"))
    svg.append(fifo_symbol(790, 285, 220, 86, "mptdc_sync_fifo", "FIFO"))
    svg.append(serializer_symbol(770, 405, 260, 80, "mptdc_narrow16_tx_v2", "Serializer v2.7 fixe"))
    svg.append(label(700, 555, "Standalone : narrow_valid_o / narrow_ready_i / narrow_data_o[15:0]", "caption"))
    svg.append(label(700, 580, "TOP partagé : acq_valid_o / acq_ready_i / acq_data_o vers spadmic_tdc_packet_adapter", "caption"))
    svg.append(label(700, 618, "Références : MPTDC/docs/02_OUTPUT_PROTOCOL.md ; mptdc_narrow16_tx_v2.sv:91-121 ; mptdc_drain_ctrl.sv:137-156", "caption"))
    svg.append(svg_footer())
    return "\n".join(svg)


def generate_calibration_pipeline_svg(db: dict[str, Any]) -> str:
    svg = [svg_header(1280, 560, "Pipeline calibration MPTDC")]
    svg.append(label(36, 44, "Calibration / caractérisation hors puce", "domain-label"))
    stages = [
        ("Tuple raw", "ns,nf,nslow,..."),
        ("Campagne CSV", "sweep delays"),
        ("Reco brute", "RAW_FEATURES"),
        ("LUT 6D", "correction moyenne"),
        ("Validation", "held-out"),
        ("Métriques", "RMSE / INL / DNL"),
    ]
    x = 72
    for idx, (name, sub) in enumerate(stages):
        svg.append(register_bank_symbol(x, 150, 150, 96, f"cal_stage_{idx}", name, sub))
        if idx < len(stages) - 1:
            svg.append(data_arrow(x + 150, 198, x + 190, 198, ""))
        x += 190
    cal = db.get("curated", {}).get("calibration", {})
    svg.append(label(82, 325, "Points établis par le dépôt :", "domain-label"))
    svg.append(label(82, 354, "Calibration hors puce ; le flux RTL courant n'intègre pas de LUT sur puce pour le fonctionnement normal.", "caption"))
    svg.append(label(82, 380, f"RMSE pré-calibration : {cal.get('pre_cal_rmse_ps', 'n/a')} ps ; post-calibration : {cal.get('post_cal_rmse_ps', 'n/a')} ps.", "caption"))
    svg.append(label(82, 406, f"Lignes de campagne : {cal.get('campaign_row_count', 'n/a')}. Méthode : {cal.get('method', 'n/a')}.", "caption"))
    svg.append(warning_marker(82, 466, "pré-silicium / modèle comportemental"))
    svg.append(label(120, 471, "Les résultats dépendent du modèle oscillateur/PD et nécessitent revue silicium.", "caption"))
    svg.append(svg_footer())
    return "\n".join(svg)


def generate_fsm_svg(name: str, states: list[str], title: str) -> str:
    width = max(840, 120 + len(states) * 126)
    svg = [svg_header(width, 300, title)]
    svg.append(label(32, 44, title, "domain-label"))
    x = 58
    y = 130
    for idx, state in enumerate(states):
        svg.append(f"<circle cx='{x}' cy='{y}' r='37' fill='#ffffff' stroke='{PALETTE['control']}' stroke-width='1.8' filter='url(#shadow)'/>")
        svg.append(label(x, y + 4, state.replace('ST_M_', '').replace('S_', '')[:10], "fieldlabel", "middle"))
        if idx < len(states) - 1:
            svg.append(control_arrow(x + 38, y, x + 88, y, ""))
        x += 126
    if states:
        svg.append(control_arrow(x - 95, y + 54, 58, y + 54, "retour/clear"))
    svg.append(svg_footer())
    return "\n".join(svg)


def generate_step_svg(step: dict[str, Any], index: int) -> str:
    svg = [svg_header(1280, 720, f"Étape {index} - {step['title']}")]
    svg.append(label(48, 54, f"Étape {index} - {step['title']}", "domain-label"))
    svg.append(label(48, 82, step.get("subtitle", ""), "caption"))
    svg.append(domain_lane(50, 120, 1180, 110, "Asynchrone", PALETTE["domain_async"]))
    svg.append(domain_lane(50, 260, 1180, 110, "Oscillateurs / PD", PALETTE["domain_clock"]))
    svg.append(domain_lane(50, 400, 1180, 110, "clk_sys", PALETTE["domain_control"]))
    svg.append(domain_lane(50, 540, 1180, 80, "Readout", PALETTE["domain_data"]))
    svg.append(mux_symbol(105, 148, 140, 54, "mptdc_input_mux", "MUX", ["SPAD", "CAL"], ["start/stop"], "sel"))
    svg.append(register_bank_symbol(300, 145, 175, 58, "mptdc_async_frontend_v2", "Frontend", "latch"))
    svg.append(ring_oscillator_symbol(540, 285, 170, 58, "mptdc_osc_wrapper", "Oscillateurs", "phase[7:0]", "rapide"))
    svg.append(pd_matrix_symbol(770, 276, 230, 80, "mptdc_pd_cell", "PD 8x8", (3, 5)))
    svg.append(fsm_symbol(210, 420, 220, 62, "mptdc_meas_ctrl", "FSM mesure", ["IDLE", "EVAL", "CLR"]))
    svg.append(register_bank_symbol(500, 420, 190, 62, "mptdc_context_bank", "Contexte", "2 contextes"))
    svg.append(fsm_symbol(760, 420, 190, 62, "mptdc_drain_ctrl", "Drain", ["META", "HIT"]))
    svg.append(fifo_symbol(500, 552, 180, 58, "mptdc_sync_fifo", "FIFO"))
    svg.append(serializer_symbol(760, 550, 210, 60, "mptdc_narrow16_tx_v2", "Sortie"))
    svg.extend(
        [
            async_arrow(245, 176, 300, 176, ""),
            control_arrow(475, 176, 540, 313, ""),
            clock_arrow(710, 313, 770, 313, ""),
            data_arrow(1000, 316, 1045, 450, ""),
            control_arrow(430, 451, 500, 451, ""),
            data_arrow(690, 451, 760, 451, ""),
            data_arrow(950, 451, 590, 552, ""),
            data_arrow(680, 581, 760, 581, ""),
        ]
    )
    active = ", ".join(step.get("active_modules", []))
    svg.append(label(64, 655, step.get("explanation", ""), "domain-label"))
    svg.append(label(64, 682, f"Blocs actifs : {active}", "caption"))
    svg.append(svg_footer())
    return "\n".join(svg)


def generate_dot(db: dict[str, Any]) -> str:
    modules = db.get("module_index", {})
    lines = ["digraph MPTDC {", "  rankdir=LR;", "  node [shape=box, style=rounded];"]
    seen: set[tuple[str, str, str]] = set()
    for mod_name, mod in modules.items():
        for inst in mod.get("instances", []):
            edge = (mod_name, inst["module"], inst["name"])
            if edge in seen:
                continue
            seen.add(edge)
            lines.append(f'  "{mod_name}" -> "{inst["module"]}" [label="{inst["name"]}"];')
    lines.append("}")
    return "\n".join(lines) + "\n"


def markdown_summary_fr(db: dict[str, Any]) -> str:
    curated = db["curated"]
    lines = [
        "# Résumé d'architecture MPTDC",
        "",
        f"- Top MPTDC actif : `{db.get('active_top')}`.",
        f"- Contexte full-chip : `{db.get('full_chip_top')}`.",
        "- Le nom attendu initialement `mptdc_vernier_top_silicon` n'apparaît pas dans cette copie de travail.",
        "- Le parser de ports ANSI est validé sur `mptdc_input_mux`, `mptdc_core`, `mptdc_top_asic` et `mptdc_narrow16_tx_v2`.",
        "",
        "## Flux principal",
        "",
    ]
    for item in curated["flows"]["dataflow"]:
        ref = evidence_text(item.get("evidence", []))
        title, claim = dataflow_fr(item)
        lines.append(f"- **{title}** : {claim} (`{ref}`).")
    lines.extend(["", "## Points incertains / revue manuelle", ""])
    for item in curated.get("uncertainties", []):
        severity, title, detail = uncertainty_fr(item)
        lines.append(f"- **{severity}** - {title} : {detail}")
    return "\n".join(lines) + "\n"


def html_report_fr(db: dict[str, Any]) -> str:
    uncertainties = "".join(
        f"<li><strong>{esc(uncertainty_fr(i)[0])}</strong> - {esc(uncertainty_fr(i)[1])} : {esc(uncertainty_fr(i)[2])}</li>"
        for i in db["curated"].get("uncertainties", [])
    )
    return f"""<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>Rapport architecture MPTDC</title>
  <style>
    body {{ font-family: Inter, Segoe UI, Arial, sans-serif; margin: 32px; color: #1d2430; background: #f7f8fb; }}
    h1, h2 {{ margin-bottom: .35rem; }}
    .panel {{ background: white; border: 1px solid #d8dee8; border-radius: 8px; padding: 18px; margin: 18px 0; }}
    code {{ background: #eef3f8; padding: 2px 5px; border-radius: 4px; }}
    img {{ max-width: 100%; border: 1px solid #d8dee8; border-radius: 8px; background: white; }}
  </style>
</head>
<body>
  <h1>Rapport architecture MPTDC</h1>
  <p>Top actif : <code>{esc(db.get("active_top"))}</code>. Contexte full-chip : <code>{esc(db.get("full_chip_top"))}</code>.</p>
  <div class="panel"><img src="../assets/architecture_schematique_mptdc.svg" alt="Schéma architecture MPTDC"></div>
  <div class="panel">
    <h2>Points incertains / revue manuelle</h2>
    <ul>{uncertainties}</ul>
  </div>
</body>
</html>
"""


def generate_all(db_path: Path, assets_dir: Path, exports_dir: Path) -> None:
    db = json.loads(db_path.read_text(encoding="utf-8"))
    assets_dir.mkdir(parents=True, exist_ok=True)
    exports_dir.mkdir(parents=True, exist_ok=True)

    architecture_svg = generate_architecture_schematic(db)
    dataflow_svg = generate_dataflow_animation_svg(db)
    (assets_dir / "architecture_schematique_mptdc.svg").write_text(architecture_svg, encoding="utf-8")
    (assets_dir / "dataflow_animation_schematique.svg").write_text(dataflow_svg, encoding="utf-8")
    (assets_dir / "architecture_overview.svg").write_text(architecture_svg, encoding="utf-8")
    (assets_dir / "dataflow_overview.svg").write_text(dataflow_svg, encoding="utf-8")
    (assets_dir / "pd_matrix_8x8.svg").write_text(generate_pd_matrix_svg(db), encoding="utf-8")
    (assets_dir / "cdc_timing_domains.svg").write_text(generate_cdc_timing_svg(db), encoding="utf-8")
    (assets_dir / "event_format_bitlayout.svg").write_text(generate_event_format_svg(db), encoding="utf-8")
    (assets_dir / "calibration_pipeline.svg").write_text(generate_calibration_pipeline_svg(db), encoding="utf-8")

    fsm_titles = {
        "measurement_fsm": "FSM de mesure",
        "drain_fsm": "FSM drain",
        "serializer_fsm": "FSM serializer narrow16",
    }
    for flow in db["curated"]["flows"]["control_flow"]:
        name = flow["name"]
        (assets_dir / f"{name}.svg").write_text(generate_fsm_svg(name, flow["states"], fsm_titles.get(name, name)), encoding="utf-8")

    steps_path = db_path.parent / "presentation_steps.json"
    if steps_path.exists():
        steps = json.loads(steps_path.read_text(encoding="utf-8"))
        for idx, step in enumerate(steps, start=1):
            safe_id = "".join(ch if ch.isalnum() or ch in "-_" else "_" for ch in step.get("id", f"step_{idx}"))
            (exports_dir / f"etape_{idx:02d}_{safe_id}.svg").write_text(generate_step_svg(step, idx), encoding="utf-8")

    (exports_dir / "mptdc_hierarchy.dot").write_text(generate_dot(db), encoding="utf-8")
    (exports_dir / "resume_architecture_fr.md").write_text(markdown_summary_fr(db), encoding="utf-8")
    (exports_dir / "rapport_architecture_fr.html").write_text(html_report_fr(db), encoding="utf-8")
    (exports_dir / "architecture_summary.md").write_text(markdown_summary_fr(db), encoding="utf-8")
    (exports_dir / "architecture_report.html").write_text(html_report_fr(db), encoding="utf-8")
    (exports_dir / "architecture_db_export.json").write_text(json.dumps(db, indent=2), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Génère les schémas et exports MPTDC.")
    parser.add_argument("--db", default="tools/mptdc_gui/architecture_db.json")
    parser.add_argument("--assets", default="tools/mptdc_gui/assets")
    parser.add_argument("--exports", default="tools/mptdc_gui/exports")
    args = parser.parse_args()
    generate_all(Path(args.db), Path(args.assets), Path(args.exports))
    print(f"Schémas écrits dans {args.assets} ; exports écrits dans {args.exports}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
