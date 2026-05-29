import { useEffect, useMemo, useState } from "react";
import { extractMptdcConstants, loadArchitecture, scenarioEvidence } from "../data/loadArchitecture";
import { exportScenarioBundle } from "../export/exportScenario";
import { buildVernierScenario } from "../sim/vernierModel";
import type { ArchitectureDb, ScenarioConfig } from "../types";
import BlockInspector from "./BlockInspector";
import ExportPanel from "./ExportPanel";
import InteractiveSchematic from "./InteractiveSchematic";
import PacketStreamView from "./PacketStreamView";
import PdMatrixView from "./PdMatrixView";
import PresentationMode from "./PresentationMode";
import ScenarioControls from "./ScenarioControls";
import SignalTimeline from "./SignalTimeline";
import SoftwareCalibrationView from "./SoftwareCalibrationView";
import WaveformView from "./WaveformView";

type TabId =
  | "simulation"
  | "architecture"
  | "controle"
  | "signaux"
  | "pd"
  | "cdc"
  | "format"
  | "verification"
  | "calibration"
  | "export";

const TABS: Array<{ id: TabId; label: string }> = [
  { id: "simulation", label: "Simulation interactive" },
  { id: "architecture", label: "Architecture" },
  { id: "controle", label: "Contrôle RTL" },
  { id: "signaux", label: "Explorateur de signaux" },
  { id: "pd", label: "Matrice Vernier 8x8" },
  { id: "cdc", label: "CDC / timing" },
  { id: "format", label: "Format événement" },
  { id: "verification", label: "Vérification" },
  { id: "calibration", label: "Calibration" },
  { id: "export", label: "Export" }
];

const DEFAULT_CONFIG: ScenarioConfig = {
  inputSource: "SPAD",
  stopDelayNs: 17.5,
  maxHits: 15,
  outputMode: "narrow16",
  speed: 1
};

function useDb(): ArchitectureDb {
  return useMemo(() => loadArchitecture(), []);
}

function isPresentationRoute(): boolean {
  return window.location.pathname.includes("presentation") || new URLSearchParams(window.location.search).get("presentation") === "1";
}

function ControlFlowView({ db }: { db: ArchitectureDb }) {
  const modules = ["mptdc_async_frontend_v2", "mptdc_meas_ctrl", "mptdc_drain_ctrl", "mptdc_narrow16_tx_v2"];
  return (
    <section className="panel">
      <h2>Contrôle RTL</h2>
      <p>FSM et séquenceurs extraits de `architecture_db.json`; les transitions détaillées restent à lire dans les fichiers RTL cités.</p>
      <div className="fsm-grid">
        {modules.map((name) => {
          const mod = db.modules.find((entry) => entry.name === name);
          return (
            <article key={name}>
              <h3>{name}</h3>
              <p>{mod?.purpose}</p>
              <div className="chip-row">
                {(mod?.fsm_states ?? ["séquence implicite / logique combinatoire"]).map((state) => (
                  <code key={state}>{state}</code>
                ))}
              </div>
              <span className="evidence-chip">
                {mod?.file}
                {mod?.line ? `:${mod.line}` : ""}
              </span>
            </article>
          );
        })}
      </div>
    </section>
  );
}

function SignalExplorer({ db }: { db: ArchitectureDb }) {
  const [query, setQuery] = useState("");
  const filtered = db.signals
    .filter((signal) => signal.name.toLowerCase().includes(query.toLowerCase()))
    .slice(0, 80);
  return (
    <section className="panel">
      <div className="panel-title-row">
        <h2>Explorateur de signaux</h2>
        <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Rechercher un signal" />
      </div>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>signal</th>
              <th>catégorie</th>
              <th>largeur</th>
              <th>producteurs</th>
              <th>consommateurs</th>
              <th>référence</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((signal) => (
              <tr key={signal.name}>
                <td>
                  <code>{signal.name}</code>
                </td>
                <td>{signal.category}</td>
                <td>{signal.widths?.join(", ")}</td>
                <td>{signal.producers?.join(", ")}</td>
                <td>{signal.consumers?.join(", ")}</td>
                <td>{signal.appearances?.[0] ? `${signal.appearances[0].file}:${signal.appearances[0].line ?? ""}` : ""}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function CdcTimingView({ db }: { db: ArchitectureDb }) {
  const cdcModules = db.modules.filter((mod) => /cdc|sync|gray|reset|pulse|bridge/i.test(mod.name));
  return (
    <section className="panel">
      <h2>CDC / timing</h2>
      <p>Vue technique séparée: synchronisation reset, pulse/toggle, compteurs Gray, snapshots statiques et points à valider STA/CDC.</p>
      <div className="cdc-map">
        {cdcModules.slice(0, 10).map((mod) => (
          <article key={mod.name}>
            <h3>{mod.name}</h3>
            <p>{mod.purpose}</p>
            <span className="evidence-chip">
              {mod.file}
              {mod.line ? `:${mod.line}` : ""}
            </span>
          </article>
        ))}
      </div>
      <div className="warning-box">
        <strong>À valider STA/CDC</strong>
        <p>Les latches async, la capture STOP, les snapshots Gray et le macro oscillateur nécessitent méthodologie, contraintes et waivers. Cette vue n’est pas une preuve silicon.</p>
      </div>
    </section>
  );
}

function ArchitectureView({ db }: { db: ArchitectureDb }) {
  const constants = extractMptdcConstants(db);
  return (
    <section className="panel">
      <h2>Architecture repo-grounded</h2>
      <div className="metric-grid">
        <span>Top actif: `{db.active_top}`</span>
        <span>Contexte full-chip: `{db.full_chip_top}`</span>
        <span>Modules parsés: {db.modules.length}</span>
        <span>Signaux indexés: {db.signals.length}</span>
      </div>
      <h3>Constantes MPTDC utilisées par le modèle pédagogique</h3>
      <div className="constant-grid">
        {Object.entries(constants.values)
          .filter(([name]) => ["NE", "OSC_TS_SLOW_PS", "OSC_TS_FAST_PS", "DELTA_STEP", "MAX_HITS", "NSLOW_W", "NFAST_W", "FIFO_DEPTH"].includes(name))
          .map(([name, value]) => (
            <div key={name}>
              <strong>{name}</strong>
              <span>{value}</span>
              <small>
                {constants.sources[name]?.file}
                {constants.sources[name]?.line ? `:${constants.sources[name].line}` : ""}
              </small>
            </div>
          ))}
      </div>
      <h3>Références principales</h3>
      <div className="chip-row">
        {scenarioEvidence().map((item) => (
          <span className="evidence-chip" key={item.ref}>
            {item.label}: {item.ref}
          </span>
        ))}
      </div>
    </section>
  );
}

function VerificationView({ db }: { db: ArchitectureDb }) {
  const verification = db.curated?.verification as
    | {
        entrypoints?: string[];
        unit_benches?: string[];
        integration_benches?: string[];
        vip_artifact_summary?: string;
      }
    | undefined;
  return (
    <section className="panel">
      <h2>Vérification</h2>
      <div className="verification-grid">
        <article>
          <h3>Entrypoints</h3>
          {(verification?.entrypoints ?? []).map((item) => (
            <p key={item}>
              <code>{item}</code>
            </p>
          ))}
        </article>
        <article>
          <h3>Benches unitaires</h3>
          {(verification?.unit_benches ?? []).map((item) => (
            <p key={item}>
              <code>{item}</code>
            </p>
          ))}
        </article>
        <article>
          <h3>Benches intégration</h3>
          {(verification?.integration_benches ?? []).map((item) => (
            <p key={item}>
              <code>{item}</code>
            </p>
          ))}
        </article>
      </div>
      <div className="warning-box">
        <strong>Gaps et artefacts</strong>
        <p>{verification?.vip_artifact_summary ?? "Les gaps restent à confirmer dans les rapports de vérification du dépôt."}</p>
      </div>
    </section>
  );
}

export default function MptdcExplorer() {
  const db = useDb();
  const [config, setConfig] = useState<ScenarioConfig>(DEFAULT_CONFIG);
  const scenario = useMemo(() => buildVernierScenario(db, config), [db, config]);
  const [currentStep, setCurrentStep] = useState(0);
  const [playing, setPlaying] = useState(false);
  const [tab, setTab] = useState<TabId>("simulation");
  const [selectedModule, setSelectedModule] = useState("mptdc_async_frontend_v2");
  const [presentation, setPresentation] = useState(isPresentationRoute());
  const totalSteps = scenario.timeline.length;

  useEffect(() => {
    if (!playing) return;
    const delay = 1500 / config.speed;
    const timer = window.setInterval(() => {
      setCurrentStep((step) => {
        if (step >= totalSteps - 1) {
          window.clearInterval(timer);
          setPlaying(false);
          return step;
        }
        return step + 1;
      });
    }, delay);
    return () => window.clearInterval(timer);
  }, [playing, config.speed, totalSteps]);

  const next = () => setCurrentStep((step) => Math.min(totalSteps - 1, step + 1));
  const prev = () => setCurrentStep((step) => Math.max(0, step - 1));
  const reset = () => {
    setPlaying(false);
    setCurrentStep(0);
  };
  const run = () => {
    setCurrentStep(0);
    setPlaying(true);
  };

  if (presentation) {
    return (
      <PresentationMode
        db={db}
        scenario={scenario}
        currentStep={currentStep}
        selectedModule={selectedModule}
        onSelectModule={setSelectedModule}
        onExit={() => setPresentation(false)}
      />
    );
  }

  return (
    <main className="app-shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">Généré localement · modèle pédagogique repo-grounded</p>
          <h1>Simulation interactive de mesure Vernier MPTDC</h1>
        </div>
        <div className="topbar-status">
          <span>{db.active_top}</span>
          <span>{scenario.stopDelayNs.toFixed(2)} ns</span>
          <span>{scenario.hits.length} hits</span>
        </div>
      </header>

      <ScenarioControls
        config={config}
        playing={playing}
        currentStep={currentStep}
        totalSteps={totalSteps}
        onConfigChange={(nextConfig) => {
          setConfig(nextConfig);
          setCurrentStep(0);
        }}
        onRun={run}
        onPause={() => setPlaying(false)}
        onNext={next}
        onPrev={prev}
        onReset={reset}
        onPresentation={() => setPresentation(true)}
        onExport={() => exportScenarioBundle(scenario)}
      />

      <nav className="tabs">
        {TABS.map((entry) => (
          <button key={entry.id} className={tab === entry.id ? "is-selected" : ""} onClick={() => setTab(entry.id)} type="button">
            {entry.label}
          </button>
        ))}
      </nav>

      {tab === "simulation" ? (
        <div className="main-grid">
          <section className="main-column">
            <InteractiveSchematic db={db} scenario={scenario} currentStep={currentStep} selectedModule={selectedModule} onSelectModule={setSelectedModule} />
            <div className="stage-card">
              <h2>{scenario.timeline[currentStep].label}</h2>
              <p>{scenario.timeline[currentStep].narrative}</p>
              <div className="chip-row">
                {scenario.timeline[currentStep].activeSignals.map((signal) => (
                  <code key={signal}>{signal}</code>
                ))}
              </div>
            </div>
            <SignalTimeline scenario={scenario} currentStep={currentStep} />
            <div className="split-panels">
              <PdMatrixView scenario={scenario} currentStep={currentStep} />
              <PacketStreamView scenario={scenario} currentStep={currentStep} />
            </div>
            <SoftwareCalibrationView scenario={scenario} />
          </section>
          <BlockInspector db={db} moduleName={selectedModule} scenario={scenario} currentStep={currentStep} />
        </div>
      ) : null}

      {tab === "architecture" ? <ArchitectureView db={db} /> : null}
      {tab === "controle" ? <ControlFlowView db={db} /> : null}
      {tab === "signaux" ? <SignalExplorer db={db} /> : null}
      {tab === "pd" ? <PdMatrixView scenario={scenario} currentStep={currentStep} /> : null}
      {tab === "cdc" ? <CdcTimingView db={db} /> : null}
      {tab === "format" ? <PacketStreamView scenario={scenario} currentStep={currentStep} /> : null}
      {tab === "verification" ? <VerificationView db={db} /> : null}
      {tab === "calibration" ? <SoftwareCalibrationView scenario={scenario} /> : null}
      {tab === "export" ? (
        <>
          <ExportPanel scenario={scenario} />
          <WaveformView scenario={scenario} />
        </>
      ) : null}

      <section className="warning-box">
        <strong>Incertitudes / revue manuelle</strong>
        <ul>
          {scenario.warnings.map((warning) => (
            <li key={warning}>{warning}</li>
          ))}
          {(db.curated?.uncertainties ?? []).map((item) => (
            <li key={item.title}>
              {item.title}: {item.detail}
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}
