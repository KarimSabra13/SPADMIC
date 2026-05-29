import type { VernierScenario } from "../types";
import { scenarioWaveDromJson } from "../export/exportScenario";

interface Props {
  scenario: VernierScenario;
}

export default function WaveformView({ scenario }: Props) {
  return (
    <section className="panel">
      <div className="panel-title-row">
        <h2>Chronogrammes numériques</h2>
        <span className="evidence-chip">WaveDrom JSON exportable</span>
      </div>
      <pre className="code-block">{scenarioWaveDromJson(scenario)}</pre>
    </section>
  );
}
