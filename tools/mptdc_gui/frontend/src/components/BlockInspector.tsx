import { useMemo, useState } from "react";
import { getModule } from "../data/loadArchitecture";
import type { ArchitectureDb, ArchitecturePort, VernierScenario } from "../types";

interface Props {
  db: ArchitectureDb;
  moduleName: string;
  scenario: VernierScenario;
  currentStep: number;
}

const CATEGORY_LABELS: Array<[string, (port: ArchitecturePort) => boolean]> = [
  ["Clocks / resets", (port) => /clk|clock|rst|reset/i.test(port.name) || port.category === "reset" || port.category === "clock/timing"],
  ["Entrées async", (port) => port.direction === "input" && /async|start|stop/i.test(port.name)],
  ["Contrôle", (port) => /arm|clear|clr|enable|valid|ready|capture|ctx|sel|mode|busy|done/i.test(port.name)],
  ["Données", (port) => /data|hit|phase|nslow|nfast|snapshot|record|word|fifo/i.test(port.name)],
  ["Statut/debug", (port) => /status|err|flag|count|level|full|empty|debug/i.test(port.name)],
  ["Sorties", (port) => port.direction === "output"]
];

function groupPorts(ports: ArchitecturePort[]) {
  const used = new Set<string>();
  const groups = CATEGORY_LABELS.map(([label, predicate]) => {
    const selected = ports.filter((port) => !used.has(port.name) && predicate(port));
    selected.forEach((port) => used.add(port.name));
    return { label, ports: selected };
  }).filter((group) => group.ports.length > 0);
  const other = ports.filter((port) => !used.has(port.name));
  if (other.length > 0) groups.push({ label: "Autres ports", ports: other });
  return groups;
}

export default function BlockInspector({ db, moduleName, scenario, currentStep }: Props) {
  const [showAll, setShowAll] = useState(false);
  const mod = getModule(db, moduleName);
  const activeSignals = new Set(scenario.timeline[currentStep].activeSignals);
  const groups = useMemo(() => groupPorts(mod?.ports ?? []), [mod]);

  if (!mod && moduleName === "host_offchip_calibration") {
    return (
      <aside className="inspector">
        <h2>Détail du bloc</h2>
        <h3>Logiciel host</h3>
        <p>Bloc pédagogique hors RTL: parsing packets, reconstruction brute, LUT 6D / mean-correction, averaging et valeur finale.</p>
        <p className="warning-line">Calibration logicielle / off-chip - pas de LUT complète on-chip dans cette narration.</p>
        <span className="evidence-chip">MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md</span>
      </aside>
    );
  }

  if (!mod) {
    return (
      <aside className="inspector">
        <h2>Détail du bloc</h2>
        <p>Sélectionner un bloc du schéma.</p>
      </aside>
    );
  }

  const refs = [mod.file ? `${mod.file}${mod.line ? `:${mod.line}` : ""}` : "", ...(mod.direct_evidence ?? []).map((ref) => `${ref.file}${ref.line ? `:${ref.line}` : ""}`)]
    .filter(Boolean)
    .filter((value, index, array) => array.indexOf(value) === index);

  const copyRefs = () => {
    void navigator.clipboard?.writeText(refs.join("\n"));
  };

  return (
    <aside className="inspector">
      <div className="panel-title-row">
        <h2>Détail du bloc</h2>
        <button type="button" onClick={copyRefs}>
          Copier les références RTL
        </button>
      </div>
      <h3>{mod.name}</h3>
      <p>{mod.purpose || "Rôle inféré depuis le nom du module et la hiérarchie."}</p>
      <div className="inspector-meta">
        <span>{mod.file}</span>
        {mod.line ? <span>ligne {mod.line}</span> : null}
      </div>
      <h4>Signaux actifs dans le scénario</h4>
      <div className="chip-row">
        {(mod.ports ?? [])
          .map((port) => port.name)
          .filter((name) => activeSignals.has(name))
          .slice(0, 12)
          .map((name) => (
            <code key={name}>{name}</code>
          ))}
        {(mod.ports ?? []).every((port) => !activeSignals.has(port.name)) ? <span>aucun port direct actif à cette étape</span> : null}
      </div>
      <h4>Ports importants</h4>
      {groups.map((group) => {
        const ports = showAll ? group.ports : group.ports.slice(0, 6);
        return (
          <details key={group.label} open={group.label !== "Autres ports"}>
            <summary>{group.label}</summary>
            <ul className="port-list">
              {ports.map((port) => (
                <li key={`${group.label}-${port.name}`}>
                  <code>{port.name}</code>
                  <span>{port.direction}</span>
                  {port.width ? <em>{port.width}</em> : null}
                </li>
              ))}
            </ul>
          </details>
        );
      })}
      <button type="button" onClick={() => setShowAll((value) => !value)}>
        {showAll ? "Masquer les ports détaillés" : "Voir tous les ports"}
      </button>
      {mod.fsm_states && mod.fsm_states.length > 0 ? (
        <>
          <h4>États / registres clés</h4>
          <div className="chip-row">
            {mod.fsm_states.slice(0, 12).map((state) => (
              <code key={state}>{state}</code>
            ))}
          </div>
        </>
      ) : null}
      {mod.instances && mod.instances.length > 0 ? (
        <>
          <h4>Modules enfants</h4>
          <div className="chip-row">
            {mod.instances.slice(0, 10).map((inst, index) => (
              <code key={`${inst.module}-${index}`}>{inst.module ?? inst.name}</code>
            ))}
          </div>
        </>
      ) : null}
    </aside>
  );
}
