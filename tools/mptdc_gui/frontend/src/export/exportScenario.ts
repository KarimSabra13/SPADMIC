import type { VernierScenario } from "../types";
import { downloadText } from "./exportSvg";

function csvEscape(value: string | number): string {
  const text = String(value);
  if (/[",\n;]/.test(text)) return `"${text.replace(/"/g, '""')}"`;
  return text;
}

export function scenarioToMarkdown(scenario: VernierScenario): string {
  const rows = scenario.hits
    .filter((hit) => hit.selected)
    .map((hit) => `| ${hit.recordIndex ?? ""} | ${hit.cell} | ${hit.ns} | ${hit.nf} | ${hit.nslow} | ${hit.nfast} | ${hit.rawTps} |`)
    .join("\n");
  return `# Scénario MPTDC Vernier

Généré localement depuis l'interface React.

- Source: \`${scenario.inputSource}\`
- Délai START→STOP: ${scenario.stopDelayNs.toFixed(2)} ns
- Hits sélectionnés: ${scenario.hits.filter((hit) => hit.selected).length}
- Mode sortie: \`${scenario.outputMode === "narrow16" ? "standalone narrow16" : "shared acq_*"}\`
- Valeur finale logicielle: ${scenario.software.finalValuePs.toFixed(2)} ps (${scenario.software.finalValueNs.toFixed(4)} ns)

> Calibration logicielle / off-chip - modèle de présentation.

| hit | cell | ns | nf | nslow | nfast | rawTps |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
${rows}

## Avertissements

${scenario.warnings.map((warning) => `- ${warning}`).join("\n")}
`;
}

export function scenarioHitsCsv(scenario: VernierScenario): string {
  const header = "hit;cell;ns;nf;nslow;nfast;rawTps;selected";
  const rows = scenario.hits.map((hit, index) =>
    [index, hit.cell, hit.ns, hit.nf, hit.nslow, hit.nfast, hit.rawTps, hit.selected ? 1 : 0].map(csvEscape).join(";")
  );
  return [header, ...rows].join("\n");
}

export function scenarioCalibrationCsv(scenario: VernierScenario): string {
  const header = "hit;cell;raw_ps;correction_ps;calibrated_ps";
  const rows = scenario.software.points.map((point) =>
    [point.hitIndex, point.cell, point.rawTps.toFixed(3), point.correctionPs.toFixed(3), point.calibratedTps.toFixed(3)]
      .map(csvEscape)
      .join(";")
  );
  return [header, ...rows].join("\n");
}

export function scenarioWaveDromJson(scenario: VernierScenario): string {
  const stopPos = Math.max(1, Math.round(scenario.stopDelayNs / 2));
  const pad = ".".repeat(stopPos);
  return JSON.stringify(
    {
      signal: [
        { name: "conv_arm_i", wave: "1".padEnd(stopPos + 9, ".") },
        { name: "start_async_i", wave: "p" + ".".repeat(stopPos + 8) },
        { name: "stop_async_i", wave: "." + pad + "p" + "......." },
        { name: "osc_slow_en_async_o", wave: "01".padEnd(stopPos + 8, ".") + "0" },
        { name: "osc_fast_en_async_o", wave: "." + pad + "01..0..." },
        { name: "pd_enable_async_o", wave: "." + pad + ".01.0.." },
        { name: "fifo_wr_en", wave: ".".repeat(stopPos + 5) + "010..." },
        { name: scenario.outputMode === "narrow16" ? "narrow_valid_o" : "acq_valid_o", wave: ".".repeat(stopPos + 7) + "01." }
      ],
      head: { text: `MPTDC START→STOP ${scenario.stopDelayNs.toFixed(2)} ns - modèle pédagogique` }
    },
    null,
    2
  );
}

export function exportScenarioBundle(scenario: VernierScenario): void {
  downloadText("scenario_mptdc_vernier.json", JSON.stringify(scenario, null, 2), "application/json;charset=utf-8");
  downloadText("scenario_mptdc_vernier.md", scenarioToMarkdown(scenario), "text/markdown;charset=utf-8");
  downloadText("scenario_hits.csv", scenarioHitsCsv(scenario), "text/csv;charset=utf-8");
  downloadText("scenario_calibration.csv", scenarioCalibrationCsv(scenario), "text/csv;charset=utf-8");
  downloadText("scenario_wavedrom.json", scenarioWaveDromJson(scenario), "application/json;charset=utf-8");
}

export function presentationHtml(scenario: VernierScenario): string {
  return `<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <title>Présentation MPTDC Vernier</title>
  <style>
    body { font-family: Inter, Arial, sans-serif; background:#f7f8fb; color:#1d2430; margin:40px; }
    h1 { font-size: 40px; }
    .value { font-size: 56px; color:#0f766e; font-weight:700; }
    .pill { display:inline-block; padding:8px 12px; border:1px solid #cbd5e1; border-radius:999px; margin:4px; }
  </style>
</head>
<body>
  <h1>MPTDC - scénario Vernier</h1>
  <p class="pill">Source ${scenario.inputSource}</p>
  <p class="pill">START→STOP ${scenario.stopDelayNs.toFixed(2)} ns</p>
  <p class="pill">${scenario.hits.length} hits</p>
  <p class="pill">${scenario.outputMode === "narrow16" ? "standalone narrow16" : "shared acq_*"}</p>
  <p class="value">${scenario.software.finalValuePs.toFixed(2)} ps</p>
  <p>Calibration logicielle / off-chip - modèle de présentation.</p>
</body>
</html>`;
}
