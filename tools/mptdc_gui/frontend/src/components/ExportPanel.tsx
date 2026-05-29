import { exportElementAsPng, exportElementAsSvg, downloadText } from "../export/exportSvg";
import {
  presentationHtml,
  scenarioCalibrationCsv,
  scenarioHitsCsv,
  scenarioToMarkdown,
  scenarioWaveDromJson
} from "../export/exportScenario";
import type { VernierScenario } from "../types";

interface Props {
  scenario: VernierScenario;
}

export default function ExportPanel({ scenario }: Props) {
  const safeExport = async (action: () => void | Promise<void>) => {
    try {
      await action();
    } catch (error) {
      window.alert(error instanceof Error ? error.message : String(error));
    }
  };

  return (
    <section className="panel export-panel">
      <h2>Export</h2>
      <p>Exports générés localement dans le navigateur; aucun accès internet requis.</p>
      <div className="export-grid">
        <button type="button" onClick={() => safeExport(() => exportElementAsSvg("schematic-export-root", "schema_mptdc_scenario.svg"))}>
          Export SVG du schéma courant
        </button>
        <button type="button" onClick={() => safeExport(() => exportElementAsPng("schematic-export-root", "schema_mptdc_scenario.png"))}>
          Export PNG du schéma courant
        </button>
        <button type="button" onClick={() => downloadText("scenario_mptdc_vernier.json", JSON.stringify(scenario, null, 2), "application/json;charset=utf-8")}>
          Export JSON du scénario
        </button>
        <button type="button" onClick={() => downloadText("scenario_mptdc_vernier.md", scenarioToMarkdown(scenario), "text/markdown;charset=utf-8")}>
          Export Markdown français
        </button>
        <button type="button" onClick={() => downloadText("presentation_mptdc.html", presentationHtml(scenario), "text/html;charset=utf-8")}>
          Export HTML présentation
        </button>
        <button type="button" onClick={() => downloadText("scenario_hits.csv", scenarioHitsCsv(scenario), "text/csv;charset=utf-8")}>
          Export CSV hits
        </button>
        <button type="button" onClick={() => downloadText("scenario_calibration.csv", scenarioCalibrationCsv(scenario), "text/csv;charset=utf-8")}>
          Export CSV raw/calibrated
        </button>
        <button type="button" onClick={() => downloadText("scenario_wavedrom.json", scenarioWaveDromJson(scenario), "application/json;charset=utf-8")}>
          Export WaveDrom JSON
        </button>
      </div>
    </section>
  );
}
