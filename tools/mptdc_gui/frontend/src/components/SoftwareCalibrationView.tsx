import type { VernierScenario } from "../types";

interface Props {
  scenario: VernierScenario;
  compact?: boolean;
}

export default function SoftwareCalibrationView({ scenario, compact }: Props) {
  const points = scenario.software.points;
  const maxRaw = Math.max(...points.map((point) => point.rawTps), scenario.stopDelayNs * 1000 + 1);
  const minRaw = Math.min(...points.map((point) => point.rawTps), scenario.stopDelayNs * 1000 - 1);
  const span = Math.max(1, maxRaw - minRaw);

  return (
    <section className="panel software-panel">
      <div className="panel-title-row">
        <div>
          <h2>Calibration logicielle / off-chip</h2>
          <p>Le RTL produit packets et features brutes; le logiciel reconstruit, calibre, moyenne, puis donne la valeur finale.</p>
        </div>
        <div className="final-value">
          <span>valeur finale</span>
          <strong>{scenario.software.finalValuePs.toFixed(2)} ps</strong>
          <em>{scenario.software.finalValueNs.toFixed(4)} ns</em>
        </div>
      </div>
      <div className="software-pipeline">
        {["Packets RTL", "parsing", "tuples bruts", "reconstruction brute", "LUT 6D / mean correction", "averaging", "valeur finale"].map((item) => (
          <span key={item}>{item}</span>
        ))}
      </div>
      <div className="calibration-plot" role="img" aria-label="Raw versus calibrated">
        {points.map((point) => {
          const left = ((point.rawTps - minRaw) / span) * 92 + 4;
          const corrected = ((point.calibratedTps - minRaw) / span) * 92 + 4;
          return (
            <div key={point.hitIndex} className="calibration-row">
              <span>H{point.hitIndex}</span>
              <div className="calibration-bar">
                <i className="raw-dot" style={{ left: `${left}%` }} title={`raw ${point.rawTps.toFixed(2)} ps`} />
                <i className="cal-dot" style={{ left: `${corrected}%` }} title={`cal ${point.calibratedTps.toFixed(2)} ps`} />
              </div>
            </div>
          );
        })}
      </div>
      {!compact && (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>hit</th>
                <th>cell</th>
                <th>raw ps</th>
                <th>correction ps</th>
                <th>calibré ps</th>
              </tr>
            </thead>
            <tbody>
              {points.map((point) => (
                <tr key={point.hitIndex}>
                  <td>{point.hitIndex}</td>
                  <td>{point.cell}</td>
                  <td>{point.rawTps.toFixed(2)}</td>
                  <td>{point.correctionPs.toFixed(2)}</td>
                  <td>{point.calibratedTps.toFixed(2)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="metric-grid">
            <span>moyenne brute {scenario.software.rawAveragePs.toFixed(2)} ps</span>
            <span>moyenne calibrée {scenario.software.calibratedAveragePs.toFixed(2)} ps</span>
            <span>écart-type {scenario.software.standardDeviationPs.toFixed(2)} ps</span>
          </div>
        </div>
      )}
    </section>
  );
}
