import type { VernierScenario } from "../types";

interface Props {
  scenario: VernierScenario;
  currentStep: number;
}

const SIGNALS = [
  "conv_arm_i",
  "start_async_i",
  "stop_async_i",
  "osc_slow_en_async_o",
  "osc_fast_en_async_o",
  "pd_enable_async_o",
  "pd_hit_level",
  "pd_nfast_hit_packed",
  "snapshot_en",
  "capture_en",
  "fifo_wr_en",
  "fifo_rd_en",
  "narrow_valid_o",
  "acq_valid_o"
];

function highWindow(signal: string, scenario: VernierScenario): Array<[number, number]> {
  const d = scenario.stopDelayNs;
  const end = d + 20;
  const map: Record<string, Array<[number, number]>> = {
    conv_arm_i: [[-2, d + 7]],
    start_async_i: [[0, 0.45]],
    stop_async_i: [[d, d + 0.45]],
    osc_slow_en_async_o: [[0, d + 4]],
    osc_fast_en_async_o: [[d, d + 3.5]],
    pd_enable_async_o: [[d + 1.3, d + 3.4]],
    pd_hit_level: [[d + 1.7, d + 6]],
    pd_nfast_hit_packed: [[d + 1.7, d + 6]],
    snapshot_en: [[d + 4, d + 4.8]],
    capture_en: [[d + 6, d + 6.8]],
    fifo_wr_en: [[d + 9, d + 12.5]],
    fifo_rd_en: [[d + 12, d + 15]],
    narrow_valid_o: scenario.outputMode === "narrow16" ? [[d + 14, end]] : [],
    acq_valid_o: scenario.outputMode === "shared" ? [[d + 14, end]] : []
  };
  return map[signal] ?? [];
}

export default function SignalTimeline({ scenario, currentStep }: Props) {
  const minT = -2.5;
  const maxT = Math.max(34, scenario.stopDelayNs + 20);
  const width = 1240;
  const rowH = 24;
  const height = 74 + SIGNALS.length * rowH;
  const toX = (time: number) => 150 + ((time - minT) / (maxT - minT)) * (width - 190);
  const currentTime = scenario.timeline[currentStep].timeNs;

  return (
    <section className="panel">
      <div className="panel-title-row">
        <h2>Chronogramme du scénario</h2>
        <span className="evidence-chip">axe en ns · modèle pédagogique</span>
      </div>
      <svg className="timeline-svg" viewBox={`0 0 ${width} ${height}`} role="img" aria-label="Timeline des signaux MPTDC">
        <rect x="0" y="0" width={width} height={height} rx="12" fill="#ffffff" />
        <line x1={toX(minT)} y1="42" x2={toX(maxT)} y2="42" className="axis" />
        {Array.from({ length: Math.floor((maxT - minT) / 5) + 1 }, (_, index) => minT + index * 5).map((tick) => (
          <g key={tick}>
            <line x1={toX(tick)} y1="36" x2={toX(tick)} y2={height - 14} className="grid-line" />
            <text x={toX(tick)} y="28" textAnchor="middle" className="tick-label">
              {tick.toFixed(0)}
            </text>
          </g>
        ))}
        <rect x={toX(0)} y="46" width={Math.max(3, toX(scenario.stopDelayNs) - toX(0))} height="18" className="zone zone-measure" />
        <rect x={toX(scenario.stopDelayNs + 8)} y="46" width={toX(scenario.stopDelayNs + 13) - toX(scenario.stopDelayNs + 8)} height="18" className="zone zone-encode" />
        <rect x={toX(scenario.stopDelayNs + 13)} y="46" width={toX(scenario.stopDelayNs + 17) - toX(scenario.stopDelayNs + 13)} height="18" className="zone zone-out" />
        <rect x={toX(scenario.stopDelayNs + 17)} y="46" width={toX(maxT) - toX(scenario.stopDelayNs + 17)} height="18" className="zone zone-soft" />
        <text x={toX(0)} y="70" className="marker-label" textAnchor="middle">
          START
        </text>
        <text x={toX(scenario.stopDelayNs)} y="70" className="marker-label" textAnchor="middle">
          STOP
        </text>
        <line x1={toX(0)} y1="34" x2={toX(0)} y2={height - 10} className="start-marker" />
        <line x1={toX(scenario.stopDelayNs)} y1="34" x2={toX(scenario.stopDelayNs)} y2={height - 10} className="stop-marker" />

        {SIGNALS.map((signal, row) => {
          const y = 92 + row * rowH;
          return (
            <g key={signal}>
              <text x="18" y={y + 5} className="signal-name">
                {signal}
              </text>
              <line x1="150" y1={y} x2={width - 40} y2={y} className="wave-base" />
              {highWindow(signal, scenario).map(([start, end], index) => (
                <rect
                  key={`${signal}-${index}`}
                  x={toX(start)}
                  y={y - 9}
                  width={Math.max(2, toX(end) - toX(start))}
                  height="14"
                  className={`wave-high ${scenario.timeline[currentStep].activeSignals.includes(signal) ? "is-current" : ""}`}
                />
              ))}
            </g>
          );
        })}
        <line x1={toX(currentTime)} y1="30" x2={toX(currentTime)} y2={height - 8} className="current-time" />
        <text x={toX(currentTime) + 8} y={height - 16} className="current-label">
          {scenario.timeline[currentStep].label}
        </text>
      </svg>
    </section>
  );
}
