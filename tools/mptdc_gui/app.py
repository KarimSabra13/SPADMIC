#!/usr/bin/env python3
"""Interface web locale française pour explorer l'architecture MPTDC."""

from __future__ import annotations

import argparse
import html
import json
import mimetypes
import socket
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse


TOOL_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOL_DIR.parents[1]
DB_PATH = TOOL_DIR / "architecture_db.json"
STEPS_PATH = TOOL_DIR / "presentation_steps.json"
ASSETS_DIR = TOOL_DIR / "assets"
EXPORTS_DIR = TOOL_DIR / "exports"
ANALYSIS_REPORT = TOOL_DIR / "ANALYSIS_REPORT.md"


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def ensure_generated(no_regenerate: bool = False) -> None:
    if no_regenerate and DB_PATH.exists():
        return
    sys.path.insert(0, str(TOOL_DIR))
    from diagram_generator import generate_all
    from rtl_parser import make_db

    db = make_db(REPO_ROOT)
    DB_PATH.write_text(json.dumps(db, indent=2), encoding="utf-8")
    generate_all(DB_PATH, ASSETS_DIR, EXPORTS_DIR)


def find_port(start: int) -> int:
    for port in range(start, start + 50):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                sock.bind(("127.0.0.1", port))
            except OSError:
                continue
            return port
    raise RuntimeError(f"Aucun port local libre entre {start} et {start + 49}")


def scoped_path(root: Path, relative_path: str) -> Path | None:
    root_resolved = root.resolve()
    candidate = (root_resolved / relative_path).resolve()
    try:
        candidate.relative_to(root_resolved)
    except ValueError:
        return None
    return candidate


INDEX_HTML = r"""<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Explorateur architecture MPTDC</title>
  <style>
    :root {
      --bg: #f7f8fb;
      --panel: #ffffff;
      --ink: #1d2430;
      --muted: #64748b;
      --line: #d8dee8;
      --line-strong: #a9b3c2;
      --async: #be5d00;
      --clock: #2563eb;
      --data: #0f766e;
      --control: #7c3aed;
      --reset: #64748b;
      --warning: #b91c1c;
      --soft: #eef3f8;
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      background: var(--bg);
      color: var(--ink);
      font-family: Inter, "Segoe UI", Arial, sans-serif;
      letter-spacing: 0;
    }

    button, input, select { font: inherit; }

    .app {
      display: grid;
      grid-template-columns: 270px 1fr;
      min-height: 100vh;
    }

    .sidebar {
      position: sticky;
      top: 0;
      height: 100vh;
      overflow: auto;
      padding: 18px 16px;
      border-right: 1px solid var(--line);
      background: #fbfcfe;
    }

    .brand { margin-bottom: 18px; }
    .brand strong { display: block; font-size: 18px; line-height: 1.2; }
    .brand span { display: block; color: var(--muted); font-size: 12px; line-height: 1.45; margin-top: 5px; }

    .tabs { display: flex; flex-direction: column; gap: 6px; }
    .tab-btn {
      border: 1px solid transparent;
      background: transparent;
      color: var(--ink);
      text-align: left;
      padding: 9px 10px;
      border-radius: 7px;
      cursor: pointer;
      min-height: 38px;
    }
    .tab-btn:hover { border-color: var(--line); background: var(--soft); }
    .tab-btn.active { background: #e8f0ff; border-color: #bdd0ff; color: #173b8f; font-weight: 700; }

    .main { padding: 22px 28px 44px; min-width: 0; }
    .topbar { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 18px; }
    .topbar h1 { margin: 0; font-size: 25px; line-height: 1.22; }
    .topbar p { margin: 4px 0 0; color: var(--muted); font-size: 13px; }
    .toolbar { display: flex; gap: 8px; flex-wrap: wrap; justify-content: flex-end; }

    .cmd {
      min-height: 36px;
      border: 1px solid var(--line);
      border-radius: 7px;
      background: var(--panel);
      color: var(--ink);
      padding: 8px 10px;
      cursor: pointer;
    }
    .cmd:hover { border-color: var(--line-strong); background: #fdfefe; }
    .cmd.primary { background: #173b8f; color: #fff; border-color: #173b8f; }

    .view { display: none; }
    .view.active { display: block; }

    .grid { display: grid; gap: 16px; }
    .grid.two { grid-template-columns: minmax(0, 1.5fr) minmax(320px, .8fr); }
    .grid.three { grid-template-columns: repeat(3, minmax(0, 1fr)); }

    .panel {
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 16px;
      min-width: 0;
    }
    .panel h2, .panel h3 { margin: 0 0 10px; line-height: 1.25; }
    .panel h2 { font-size: 18px; }
    .panel h3 { font-size: 15px; }
    .muted { color: var(--muted); }
    .small { font-size: 12px; line-height: 1.5; }
    .mono { font-family: "Cascadia Mono", Consolas, monospace; font-size: 12px; }
    code { background: var(--soft); padding: 2px 5px; border-radius: 4px; }

    .svg-frame {
      background: #ffffff;
      border: 1px solid var(--line);
      border-radius: 8px;
      overflow: auto;
      min-height: 420px;
    }
    .svg-frame svg { display: block; max-width: none; }
    .svg-frame.fit svg { width: 100%; height: auto; }

    .legend { display: flex; flex-wrap: wrap; gap: 10px; margin: 10px 0 0; }
    .legend span { display: inline-flex; align-items: center; gap: 6px; color: var(--muted); font-size: 12px; }
    .swatch { width: 24px; height: 3px; border-radius: 2px; background: var(--data); }
    .swatch.async { background: var(--async); border-top: 2px dashed var(--async); height: 0; }
    .swatch.clock { background: var(--clock); }
    .swatch.control { background: var(--control); }
    .swatch.reset { background: var(--reset); }
    .swatch.warning { background: var(--warning); }

    .detail-list { display: grid; gap: 10px; }
    .section-title { font-weight: 800; font-size: 12px; text-transform: uppercase; color: #475569; margin: 14px 0 7px; }
    .chips { display: flex; flex-wrap: wrap; gap: 6px; }
    .chip {
      border: 1px solid var(--line);
      background: #f8fafc;
      color: #334155;
      border-radius: 999px;
      padding: 4px 8px;
      font-size: 12px;
      font-family: "Cascadia Mono", Consolas, monospace;
    }

    .step-card { display: grid; gap: 10px; }
    .step-title { font-size: 22px; font-weight: 800; }
    .controls { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
    input[type="range"] { accent-color: var(--control); }

    .table-wrap { overflow: auto; max-height: 560px; border: 1px solid var(--line); border-radius: 8px; }
    table { width: 100%; border-collapse: collapse; background: #fff; }
    th, td { padding: 8px 10px; border-bottom: 1px solid var(--line); text-align: left; vertical-align: top; }
    th { position: sticky; top: 0; background: #f8fafc; z-index: 1; font-size: 12px; color: #475569; }
    td { font-size: 12px; }

    .warning-box {
      border-left: 4px solid var(--warning);
      background: #fff1f2;
      padding: 10px 12px;
      border-radius: 6px;
      margin: 8px 0;
    }

    .export-list { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 10px; }
    .export-link {
      display: block;
      text-decoration: none;
      color: var(--ink);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 12px;
      background: #fff;
    }
    .export-link:hover { border-color: var(--line-strong); background: #fdfefe; }

    body.presentation .app { display: block; }
    body.presentation .sidebar { display: none; }
    body.presentation .main { max-width: 1500px; margin: 0 auto; padding: 22px; }
    body.presentation .topbar p, body.presentation .secondary-panel { display: none; }
    body.presentation .grid.two { grid-template-columns: 1fr; }
    body.presentation .svg-frame { aspect-ratio: 16 / 9; min-height: 0; }
    body.presentation .svg-frame svg { width: 100%; height: 100%; }
    body.presentation .step-title { font-size: 32px; }
    body.presentation .panel { border: none; }

    @media (max-width: 1050px) {
      .app { grid-template-columns: 1fr; }
      .sidebar { position: static; height: auto; }
      .grid.two, .grid.three { grid-template-columns: 1fr; }
      .main { padding: 18px; }
    }
  </style>
</head>
<body>
  <div class="app">
    <aside class="sidebar">
      <div class="brand">
        <strong>Explorateur RTL MPTDC</strong>
        <span>Généré localement à partir du dépôt SPADMIC / MPTDC.</span>
      </div>
      <nav class="tabs" id="tabs"></nav>
    </aside>

    <main class="main">
      <div class="topbar">
        <div>
          <h1 id="viewTitle">Vue d'ensemble de l'architecture</h1>
          <p id="viewSubtitle">Schéma interactif repo-grounded du chemin MPTDC actif.</p>
        </div>
        <div class="toolbar">
          <button class="cmd" id="presentationBtn">Mode présentation 16:9</button>
          <button class="cmd" id="reloadBtn">Regénérer la vue</button>
        </div>
      </div>

      <section class="view active" id="view-architecture">
        <div class="grid two">
          <div>
            <div class="svg-frame fit" id="architectureSvg"></div>
            <div class="legend">
              <span><i class="swatch async"></i>orange pointillé = async</span>
              <span><i class="swatch clock"></i>bleu = clock / phase</span>
              <span><i class="swatch"></i>vert = données</span>
              <span><i class="swatch control"></i>violet = contrôle</span>
              <span><i class="swatch warning"></i>rouge = warning / incertain</span>
              <span><i class="swatch reset"></i>gris = reset / infrastructure</span>
            </div>
          </div>
          <div class="panel secondary-panel">
            <h2>Détail du bloc</h2>
            <div id="blockDetail" class="detail-list muted">Cliquez sur un symbole du schéma.</div>
          </div>
        </div>
      </section>

      <section class="view" id="view-animation">
        <div class="grid two">
          <div>
            <div class="svg-frame fit" id="dataflowSvg"></div>
            <div class="controls" style="margin-top:12px">
              <button class="cmd" id="prevStep">Précédent</button>
              <button class="cmd primary" id="playStep">Lecture</button>
              <button class="cmd" id="pauseStep">Pause</button>
              <button class="cmd" id="nextStep">Suivant</button>
              <button class="cmd" id="resetStep">Réinitialiser</button>
              <label class="small">Vitesse <input type="range" id="speedSlider" min="600" max="3000" step="200" value="1400"></label>
              <button class="cmd" id="exportStep">Exporter cette étape en SVG</button>
            </div>
          </div>
          <div class="panel">
            <div class="step-card">
              <div class="muted small" id="stepIndex"></div>
              <div class="step-title" id="stepTitle"></div>
              <div class="muted" id="stepSubtitle"></div>
              <p id="stepExplanation"></p>
              <div>
                <div class="section-title">Signaux actifs</div>
                <div class="chips" id="stepSignals"></div>
              </div>
              <div>
                <div class="section-title">Références RTL/doc</div>
                <div class="chips" id="stepEvidence"></div>
              </div>
              <a class="export-link" href="/exports" id="allStepsHint" style="display:none">Exports d'étapes disponibles dans le dossier exports.</a>
            </div>
          </div>
        </div>
      </section>

      <section class="view" id="view-control">
        <div class="grid three">
          <div class="panel"><h2>FSM de mesure</h2><div class="svg-frame fit" id="measurementFsmSvg"></div></div>
          <div class="panel"><h2>FSM drain</h2><div class="svg-frame fit" id="drainFsmSvg"></div></div>
          <div class="panel"><h2>FSM serializer</h2><div class="svg-frame fit" id="serializerFsmSvg"></div></div>
        </div>
        <div class="panel" style="margin-top:16px">
          <h2>Transitions et reset / clear</h2>
          <div id="controlEvidence"></div>
        </div>
      </section>

      <section class="view" id="view-signaux">
        <div class="panel">
          <h2>Explorateur de signaux</h2>
          <p class="muted small">Recherche par nom de signal, catégorie, producteur ou consommateur. Les relations restent statiques et inférées lorsque le parser ne peut pas prouver une connexion complète.</p>
          <input id="signalSearch" class="cmd" style="width:100%; margin:8px 0 12px" placeholder="Rechercher : clk_sys, pd_hit_level, acq_valid_o...">
          <div class="table-wrap"><table id="signalTable"></table></div>
        </div>
      </section>

      <section class="view" id="view-pd">
        <div class="grid two">
          <div class="svg-frame fit" id="pdSvg"></div>
          <div class="panel">
            <h2>Matrice Vernier 8x8</h2>
            <p>La matrice instancie 64 cellules PD. La relation indexée est <code>CELL = ns * NE + nf</code>, avec <code>NE = 8</code> dans la cible active.</p>
            <div class="section-title">Éléments affichés</div>
            <div class="chips">
              <span class="chip">slow_phase[7:0]</span>
              <span class="chip">fast_phase[7:0]</span>
              <span class="chip">pd_hit_level[63:0]</span>
              <span class="chip">pd_nfast_hit_packed</span>
              <span class="chip">nfast_hit</span>
            </div>
            <div class="section-title">Références</div>
            <div class="chips">
              <span class="chip">MPTDC/rtl/pd/mptdc_pd_cell.sv:83</span>
              <span class="chip">MPTDC/rtl/top/mptdc_core.sv:404</span>
            </div>
          </div>
        </div>
      </section>

      <section class="view" id="view-cdc">
        <div class="grid two">
          <div class="svg-frame fit" id="cdcSvg"></div>
          <div class="panel">
            <h2>Alertes CDC / timing</h2>
            <div class="warning-box"><strong>à valider STA/CDC</strong><br>Les franchissements documentés ont besoin de contraintes et dérogations contrôlées.</div>
            <div class="warning-box"><strong>waiver nécessaire</strong><br>Les bus snapshot tenus ne sont pas une synchronisation bit-à-bit classique.</div>
            <div class="warning-box"><strong>dépend du macro oscillateur</strong><br>Les hypothèses physiques slow/fast viennent du contrat macro, pas du seul RTL.</div>
            <div class="warning-box"><strong>pas une preuve silicium</strong><br>Les résultats de simulation et calibration restent pré-silicium.</div>
          </div>
        </div>
      </section>

      <section class="view" id="view-format">
        <div class="grid two">
          <div class="svg-frame fit" id="formatSvg"></div>
          <div class="panel">
            <h2>Format d'événement</h2>
            <p>Le mode standalone sort des mots <code>narrow_data_o[15:0]</code>. Le mode TOP partagé expose des records <code>acq_*</code> avant adaptation/arbitrage.</p>
            <div id="formatEvidence" class="chips"></div>
          </div>
        </div>
      </section>

      <section class="view" id="view-verification">
        <div class="grid two">
          <div class="panel">
            <h2>Vérification disponible</h2>
            <div id="verificationSummary"></div>
          </div>
          <div class="panel">
            <h2>Fichiers bancs de test / scripts</h2>
            <div id="verificationFiles" class="table-wrap"></div>
          </div>
        </div>
      </section>

      <section class="view" id="view-calibration">
        <div class="grid two">
          <div class="svg-frame fit" id="calibrationSvg"></div>
          <div class="panel">
            <h2>Calibration scientifique</h2>
            <div id="calibrationMetrics"></div>
            <p class="muted small">Calibration hors puce : le RTL de fonctionnement normal ne charge pas de LUT sur puce dans le chemin actif documenté.</p>
          </div>
        </div>
      </section>

      <section class="view" id="view-export">
        <div class="panel">
          <h2>Export</h2>
          <p class="muted small">Tous les fichiers sont générés localement. PDF : ouvrir le rapport HTML et utiliser l'impression du navigateur.</p>
          <div class="export-list" id="exportList"></div>
        </div>
      </section>
    </main>
  </div>

  <script>
    const tabs = [
      ["architecture", "Vue d'ensemble de l'architecture", "Schéma interactif repo-grounded du chemin MPTDC actif."],
      ["animation", "Animation du flux de données", "Acquisition START/STOP étape par étape."],
      ["control", "Flux de contrôle", "FSM, reset, clear et séquencement."],
      ["signaux", "Explorateur de signaux", "Recherche signal, producteurs, consommateurs et catégories."],
      ["pd", "Matrice Vernier 8x8", "Détail phase detector et packing des hits."],
      ["cdc", "Timing / CDC", "Domaines d'horloge, synchronizers et warnings."],
      ["format", "Format d'événement", "Bit layout narrow16 et records acq_*."],
      ["verification", "Vérification", "Bancs de test, assertions, scripts et manques."],
      ["calibration", "Calibration", "Pipeline hors puce et métriques pré-silicium."],
      ["export", "Export", "SVG, HTML, Markdown, JSON et DOT."]
    ];

    const state = { db: null, steps: [], step: 0, timer: null, selectedModule: null };
    const assetMap = {
      architectureSvg: "/assets/architecture_schematique_mptdc.svg",
      dataflowSvg: "/assets/dataflow_animation_schematique.svg",
      measurementFsmSvg: "/assets/measurement_fsm.svg",
      drainFsmSvg: "/assets/drain_fsm.svg",
      serializerFsmSvg: "/assets/serializer_fsm.svg",
      pdSvg: "/assets/pd_matrix_8x8.svg",
      cdcSvg: "/assets/cdc_timing_domains.svg",
      formatSvg: "/assets/event_format_bitlayout.svg",
      calibrationSvg: "/assets/calibration_pipeline.svg"
    };

    function el(id) { return document.getElementById(id); }
    function escapeHtml(s) {
      return String(s ?? "").replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
    }
    function chip(text) { return `<span class="chip">${escapeHtml(text)}</span>`; }
    function refText(ref) { return `${ref.file}:${ref.line}`; }

    function initTabs() {
      const nav = el("tabs");
      nav.innerHTML = tabs.map(([id, title]) => `<button class="tab-btn" data-tab="${id}">${title}</button>`).join("");
      nav.addEventListener("click", e => {
        const btn = e.target.closest("[data-tab]");
        if (btn) activateTab(btn.dataset.tab);
      });
      activateTab("architecture");
    }

    function activateTab(id) {
      document.querySelectorAll(".tab-btn").forEach(b => b.classList.toggle("active", b.dataset.tab === id));
      document.querySelectorAll(".view").forEach(v => v.classList.toggle("active", v.id === `view-${id}`));
      const meta = tabs.find(t => t[0] === id) || tabs[0];
      el("viewTitle").textContent = meta[1];
      el("viewSubtitle").textContent = meta[2];
      if (id === "animation") renderStep();
    }

    async function loadJson(path) {
      const res = await fetch(path);
      if (!res.ok) throw new Error(`chargement impossible : ${path}`);
      return await res.json();
    }

    async function loadSvg(targetId, path) {
      const res = await fetch(path);
      const text = await res.text();
      el(targetId).innerHTML = text;
      if (targetId === "architectureSvg") wireBlockClicks(el(targetId));
      if (targetId === "dataflowSvg") renderStep();
    }

    function wireBlockClicks(root) {
      root.querySelectorAll(".block[data-module]").forEach(node => {
        node.addEventListener("click", () => showModuleDetail(node.dataset.module));
      });
    }

    function groupPorts(ports) {
      const groups = { "Clocks / resets": [], "Entrées async": [], "Contrôle": [], "Données": [], "Statut/debug": [], "Sorties": [] };
      for (const p of ports || []) {
        const name = p.name || "";
        const cat = p.category || "";
        if (name.includes("clk") || name.includes("rst") || name.includes("reset")) groups["Clocks / resets"].push(p);
        else if (name.includes("async")) groups["Entrées async"].push(p);
        else if (cat.includes("control") || /valid|ready|enable|_en|arm|clr|clear|sel/.test(name)) groups["Contrôle"].push(p);
        else if (cat.includes("status") || /status|busy|done|full|empty|flag|error/.test(name)) groups["Statut/debug"].push(p);
        else if (p.direction === "output") groups["Sorties"].push(p);
        else groups["Données"].push(p);
      }
      return groups;
    }

    function showModuleDetail(moduleName, showAll=false) {
      state.selectedModule = moduleName;
      const mod = state.db.module_index[moduleName];
      const box = el("blockDetail");
      if (!mod) {
        box.innerHTML = `<div class="warning-box">Module non trouvé dans architecture_db.json : <code>${escapeHtml(moduleName)}</code></div>`;
        return;
      }
      const children = (mod.instances || []).slice(0, 12).map(i => chip(`${i.name}:${i.module}`)).join("");
      const refs = (mod.direct_evidence || []).map(r => chip(`${r.file}:${r.line}`)).join("") || chip(`${mod.file}:${mod.line}`);
      const groups = groupPorts(mod.ports || []);
      const portHtml = Object.entries(groups).map(([title, items]) => {
        const visible = showAll ? items : items.slice(0, 8);
        if (!visible.length) return "";
        return `<div class="section-title">${title}</div><div class="chips">${visible.map(p => chip(`${p.direction} ${p.width || ""} ${p.name}`.trim())).join("")}</div>`;
      }).join("");
      const fsm = (mod.fsm_states || []).slice(0, 12).map(chip).join("");
      const regs = (mod.key_registers || []).slice(0, 12).map(chip).join("");
      box.innerHTML = `
        <h3><code>${escapeHtml(mod.name)}</code></h3>
        <p>${escapeHtml(mod.purpose || "Rôle inféré depuis le nom, les ports et les instanciations.")}</p>
        <div class="section-title">Domaine probable</div>
        <div class="chips">${inferDomain(mod).map(chip).join("")}</div>
        ${portHtml}
        <div class="section-title">Registres / états clés</div>
        <div class="chips">${fsm || regs || chip("non détecté")}</div>
        <div class="section-title">Modules enfants</div>
        <div class="chips">${children || chip("aucun enfant RTL parsé")}</div>
        <div class="section-title">Références RTL</div>
        <div class="chips">${refs}</div>
        <div class="controls">
          <button class="cmd" onclick="showModuleDetail('${escapeHtml(moduleName)}', true)">Voir tous les ports</button>
          <button class="cmd" onclick="copyRefs('${escapeHtml(moduleName)}')">Copier les références RTL</button>
        </div>`;
    }

    function inferDomain(mod) {
      const names = (mod.ports || []).map(p => p.name).join(" ");
      const file = mod.file || "";
      const out = [];
      if (/async|start|stop/.test(names) || file.includes("/async/")) out.push("asynchrone");
      if (/phase|osc|gray/.test(names) || file.includes("/osc/")) out.push("clock/phase");
      if (/fifo|narrow|acq|data|hit/.test(names) || file.includes("/readout/")) out.push("données/readout");
      if (/state|ctrl|arm|clear|valid|ready/.test(names) || file.includes("/ctrl/")) out.push("contrôle");
      return out.length ? out : ["à confirmer"];
    }

    async function copyRefs(moduleName) {
      const mod = state.db.module_index[moduleName];
      const refs = [`${mod.file}:${mod.line}`].concat((mod.direct_evidence || []).map(refText));
      await navigator.clipboard.writeText([...new Set(refs)].join("\n"));
    }

    function renderStep() {
      if (!state.steps.length) return;
      const step = state.steps[state.step];
      el("stepIndex").textContent = `Étape ${state.step + 1} / ${state.steps.length}`;
      el("stepTitle").textContent = step.title;
      el("stepSubtitle").textContent = step.subtitle || "";
      el("stepExplanation").textContent = step.explanation || "";
      el("stepSignals").innerHTML = (step.active_signals || []).map(chip).join("");
      el("stepEvidence").innerHTML = (step.evidence || []).map(r => chip(refText(r))).join("");
      highlightDataflow(step);
    }

    function highlightDataflow(step) {
      const root = el("dataflowSvg");
      root.querySelectorAll(".block").forEach(n => n.classList.remove("active"));
      root.querySelectorAll(".signal-wire").forEach(n => n.classList.remove("active-signal"));
      root.querySelectorAll(".domain-lane").forEach(n => n.style.opacity = "0.55");
      for (const moduleName of step.active_modules || []) {
        root.querySelectorAll(`.block[data-module="${CSS.escape(moduleName)}"]`).forEach(n => n.classList.add("active"));
      }
      for (const sig of step.active_signals || []) {
        root.querySelectorAll(".signal-wire").forEach(n => {
          const id = n.dataset.signal || "";
          const bare = sig.replace(/\[.*\]/, "");
          if (id && (sig.includes(id) || id.includes(bare))) n.classList.add("active-signal");
        });
      }
      for (const domain of step.active_domains || []) {
        root.querySelectorAll(".domain-lane").forEach(n => {
          if ((n.dataset.domain || "").includes(domain)) n.style.opacity = "1";
        });
      }
    }

    function nextStep(delta=1) {
      state.step = (state.step + delta + state.steps.length) % state.steps.length;
      renderStep();
    }

    function play() {
      pause();
      state.timer = setInterval(() => nextStep(1), Number(el("speedSlider").value));
    }
    function pause() {
      if (state.timer) clearInterval(state.timer);
      state.timer = null;
    }

    function exportCurrentStep() {
      const svg = el("dataflowSvg").querySelector("svg");
      if (!svg) return;
      const step = state.steps[state.step];
      const blob = new Blob([svg.outerHTML], {type: "image/svg+xml"});
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = `mptdc_etape_${String(state.step + 1).padStart(2, "0")}_${step.id}.svg`;
      a.click();
      URL.revokeObjectURL(a.href);
    }

    function renderSignals() {
      const q = (el("signalSearch").value || "").toLowerCase();
      const rows = (state.db.signals || []).filter(s => {
        const hay = [s.name, s.category, ...(s.producers || []), ...(s.consumers || [])].join(" ").toLowerCase();
        return hay.includes(q);
      }).slice(0, 350);
      el("signalTable").innerHTML = `
        <thead><tr><th>Signal</th><th>Catégorie</th><th>Largeurs</th><th>Producteurs</th><th>Consommateurs</th><th>Occurrences</th></tr></thead>
        <tbody>${rows.map(s => `<tr>
          <td class="mono">${escapeHtml(s.name)}</td>
          <td>${escapeHtml(s.category || "")}</td>
          <td class="mono">${escapeHtml((s.widths || []).join(", "))}</td>
          <td class="mono">${escapeHtml((s.producers || []).slice(0, 5).join(", "))}</td>
          <td class="mono">${escapeHtml((s.consumers || []).slice(0, 5).join(", "))}</td>
          <td>${s.occurrences || 0}</td>
        </tr>`).join("")}</tbody>`;
    }

    function renderControl() {
      const flows = state.db.curated.flows.control_flow || [];
      el("controlEvidence").innerHTML = flows.map(f => `
        <div class="section-title">${escapeHtml(f.title || f.name)}</div>
        <p>${escapeHtml(f.claim || "")}</p>
        <div class="chips">${(f.states || []).map(chip).join("")}${(f.evidence || []).map(r => chip(refText(r))).join("")}</div>
      `).join("");
    }

    function renderFormatEvidence() {
      el("formatEvidence").innerHTML = [
        "MPTDC/docs/02_OUTPUT_PROTOCOL.md:9",
        "MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:91",
        "MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:137",
        "MPTDC/docs/10_SHARED_READOUT_EXPORT.md:37"
      ].map(chip).join("");
    }

    function renderVerification() {
      const v = state.db.curated.verification || {};
      const entrypoints = (v.entrypoints || []).map(chip).join("");
      const unit = (v.unit_benches || []).map(chip).join("");
      const integ = (v.integration_benches || []).map(chip).join("");
      const vip = v.vip_artifact_summary || {};
      el("verificationSummary").innerHTML = `
        <div class="section-title">Commandes de régression documentées</div><div class="chips">${entrypoints || chip("non renseigné")}</div>
        <div class="section-title">Bancs unitaires</div><div class="chips">${unit || chip("non renseigné")}</div>
        <div class="section-title">Bancs d'intégration</div><div class="chips">${integ || chip("non renseigné")}</div>
        <div class="warning-box"><strong>Artefact VIP commité</strong><br>
          total=${escapeHtml(vip.total ?? "n/a")}, réussites=${escapeHtml(vip.pass ?? "n/a")}, échecs=${escapeHtml(vip.fail ?? "n/a")}. À considérer ancien ou à relancer si contradictoire.
        </div>`;
      const files = [...(state.db.files.testbench || []), ...(state.db.files.scripts || [])].slice(0, 160);
      el("verificationFiles").innerHTML = `<table><thead><tr><th>Fichier</th></tr></thead><tbody>${files.map(f => `<tr><td class="mono">${escapeHtml(f)}</td></tr>`).join("")}</tbody></table>`;
    }

    function renderCalibration() {
      const c = state.db.curated.calibration || {};
      el("calibrationMetrics").innerHTML = `
        <div class="chips">
          ${chip(`méthode: ${c.method || "n/a"}`)}
          ${chip(`RMSE pré: ${c.pre_cal_rmse_ps || "n/a"} ps`)}
          ${chip(`RMSE post: ${c.post_cal_rmse_ps || "n/a"} ps`)}
          ${chip(`campagne: ${c.campaign_row_count || "n/a"} lignes`)}
        </div>
        <div class="section-title">Références</div>
        <div class="chips">${(c.evidence || []).map(r => chip(refText(r))).join("")}</div>
      `;
    }

    function renderExports() {
      const files = [
        ["/assets/architecture_schematique_mptdc.svg", "SVG architecture schématique"],
        ["/assets/dataflow_animation_schematique.svg", "SVG animation schématique"],
        ["/assets/pd_matrix_8x8.svg", "SVG matrice Vernier 8x8"],
        ["/assets/cdc_timing_domains.svg", "SVG CDC / timing"],
        ["/assets/event_format_bitlayout.svg", "SVG format événement"],
        ["/assets/calibration_pipeline.svg", "SVG pipeline calibration"],
        ["/exports/resume_architecture_fr.md", "Markdown français"],
        ["/exports/rapport_architecture_fr.html", "Rapport HTML français"],
        ["/exports/architecture_db_export.json", "Base architecture JSON"],
        ["/exports/mptdc_hierarchy.dot", "Hiérarchie DOT"]
      ];
      const stepLinks = state.steps.map((s, i) => [`/exports/etape_${String(i+1).padStart(2, "0")}_${s.id}.svg`, `SVG étape ${i+1} - ${s.title}`]);
      el("exportList").innerHTML = files.concat(stepLinks).map(([href, title]) => `<a class="export-link" href="${href}" download><strong>${escapeHtml(title)}</strong><br><span class="muted small mono">${escapeHtml(href)}</span></a>`).join("");
    }

    function togglePresentation() {
      document.body.classList.toggle("presentation");
      const on = document.body.classList.contains("presentation");
      const url = new URL(location.href);
      if (on) url.searchParams.set("presentation", "1"); else url.searchParams.delete("presentation");
      history.replaceState(null, "", url);
    }

    async function init() {
      initTabs();
      state.db = await loadJson("/api/db");
      state.steps = await loadJson("/api/steps");
      await Promise.all(Object.entries(assetMap).map(([id, path]) => loadSvg(id, path)));
      renderStep();
      renderSignals();
      renderControl();
      renderFormatEvidence();
      renderVerification();
      renderCalibration();
      renderExports();
      if (new URL(location.href).searchParams.get("presentation") === "1") document.body.classList.add("presentation");
      if (state.db.parser_validation && !state.db.parser_validation.passed) {
        el("blockDetail").innerHTML = "<div class='warning-box'>Validation du parser de ports en échec : revue manuelle requise.</div>";
      }
    }

    el("presentationBtn").addEventListener("click", togglePresentation);
    el("reloadBtn").addEventListener("click", () => location.reload());
    el("prevStep").addEventListener("click", () => nextStep(-1));
    el("nextStep").addEventListener("click", () => nextStep(1));
    el("playStep").addEventListener("click", play);
    el("pauseStep").addEventListener("click", pause);
    el("resetStep").addEventListener("click", () => { state.step = 0; pause(); renderStep(); });
    el("exportStep").addEventListener("click", exportCurrentStep);
    el("speedSlider").addEventListener("input", () => { if (state.timer) play(); });
    el("signalSearch").addEventListener("input", renderSignals);

    init().catch(err => {
      document.body.innerHTML = `<pre style="padding:24px;color:#b91c1c">${escapeHtml(err.stack || err)}</pre>`;
    });
  </script>
</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args: object) -> None:
        return

    def send_body(self, body: bytes, ctype: str, status: int = 200) -> None:
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def send_file(self, path: Path) -> None:
        if not path.exists() or not path.is_file():
            self.send_error(404, "Fichier introuvable")
            return
        ctype = mimetypes.guess_type(str(path))[0] or "application/octet-stream"
        self.send_body(path.read_bytes(), ctype)

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        path = unquote(parsed.path)
        if path in {"/", "/index.html"}:
            self.send_body(INDEX_HTML.encode("utf-8"), "text/html; charset=utf-8")
            return
        if path == "/api/db":
            self.send_file(DB_PATH)
            return
        if path == "/api/steps":
            self.send_file(STEPS_PATH)
            return
        if path == "/analysis":
            self.send_file(ANALYSIS_REPORT)
            return
        if path == "/exports":
            listing = "".join(
                f"<li><a href='/exports/{esc(p.name)}'>{esc(p.name)}</a></li>"
                for p in sorted(EXPORTS_DIR.glob("*"))
                if p.is_file()
            )
            self.send_body(f"<!doctype html><html lang='fr'><meta charset='utf-8'><body><h1>Exports MPTDC</h1><ul>{listing}</ul></body></html>".encode("utf-8"), "text/html; charset=utf-8")
            return
        if path.startswith("/assets/"):
            target = scoped_path(ASSETS_DIR, path.removeprefix("/assets/"))
            if target is None:
                self.send_error(403, "Accès interdit")
                return
            self.send_file(target)
            return
        if path.startswith("/exports/"):
            target = scoped_path(EXPORTS_DIR, path.removeprefix("/exports/"))
            if target is None:
                self.send_error(403, "Accès interdit")
                return
            self.send_file(target)
            return
        self.send_error(404, "Chemin inconnu")


def main() -> int:
    parser = argparse.ArgumentParser(description="Lance l'interface web locale MPTDC.")
    parser.add_argument("--port", type=int, default=8501, help="Premier port local à essayer")
    parser.add_argument("--no-regenerate", action="store_true", help="Ne pas regénérer JSON/SVG au démarrage")
    args = parser.parse_args()

    ensure_generated(args.no_regenerate)
    port = find_port(args.port)
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"Interface MPTDC prête : http://127.0.0.1:{port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nArrêt demandé.", flush=True)
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
