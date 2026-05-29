import type { VernierScenario } from "../types";

interface Props {
  scenario: VernierScenario;
  currentStep: number;
  presentation?: boolean;
}

function visiblePacketCount(scenario: VernierScenario, currentStep: number): number {
  const stage = scenario.timeline[currentStep].stage;
  if (["armement", "selection", "start", "comptage_lent", "stop", "detection", "snapshot", "evaluation", "contexte"].includes(stage)) {
    return 0;
  }
  if (stage === "drain") return Math.min(1 + scenario.hits.length, scenario.rawRecords.length);
  if (stage === "fifo") return scenario.rawRecords.length;
  return scenario.outputMode === "narrow16" ? scenario.narrowWords.length : scenario.rawRecords.length;
}

export default function PacketStreamView({ scenario, currentStep, presentation }: Props) {
  const visibleCount = visiblePacketCount(scenario, currentStep);
  const records = scenario.outputMode === "narrow16" ? scenario.narrowWords : scenario.rawRecords;
  const title = scenario.outputMode === "narrow16" ? "Flux standalone `narrow16`" : "Flux shared `acq_*`";
  return (
    <section className="panel">
      <div className="panel-title-row">
        <h2>{title}</h2>
        <span className="evidence-chip">META/HIT/EOC depuis drain + serializer</span>
      </div>
      <div className={`packet-strip${presentation ? " presentation-packets" : ""}`}>
        {records.map((record, index) => {
          const active = index < visibleCount;
          const fields = record.fields.map((field) => `${field.name}${field.bits ? ` [${field.bits}]` : ""}=${field.value}`).join("\n");
          return (
            <div key={`${record.label}-${index}`} className={`packet-word ${active ? "is-visible" : ""} packet-${record.kind.toLowerCase()}`} title={fields}>
              <span>{record.label}</span>
              <strong>{record.valueHex}</strong>
            </div>
          );
        })}
      </div>
      {!presentation && (
        <div className="packet-detail-grid">
          {scenario.rawRecords.map((record) => (
            <details key={record.index}>
              <summary>
                {record.label} · {record.valueHex}
              </summary>
              <ul>
                {record.fields.map((field) => (
                  <li key={`${record.index}-${field.name}`}>
                    <code>{field.name}</code> {field.bits ? `[${field.bits}]` : ""} = <code>{field.value}</code>
                    {field.source ? <span> · {field.source}</span> : null}
                  </li>
                ))}
              </ul>
            </details>
          ))}
        </div>
      )}
    </section>
  );
}
