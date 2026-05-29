import InteractiveSchematic from "./InteractiveSchematic";
import PacketStreamView from "./PacketStreamView";
import SoftwareCalibrationView from "./SoftwareCalibrationView";
import type { ArchitectureDb, VernierScenario } from "../types";

interface Props {
  db: ArchitectureDb;
  scenario: VernierScenario;
  currentStep: number;
  selectedModule: string;
  onSelectModule: (moduleName: string) => void;
  onExit: () => void;
}

export default function PresentationMode({ db, scenario, currentStep, selectedModule, onSelectModule, onExit }: Props) {
  const stage = scenario.timeline[currentStep];
  return (
    <main className="presentation-mode">
      <header>
        <div>
          <p>Mode soutenance</p>
          <h1>{stage.label}</h1>
        </div>
        <div className="presentation-stats">
          <span>STOP {scenario.stopDelayNs.toFixed(2)} ns</span>
          <span>{scenario.hits.length} hits</span>
          <span>{scenario.software.finalValuePs.toFixed(1)} ps</span>
        </div>
        <button type="button" onClick={onExit}>
          Quitter
        </button>
      </header>
      <p className="presentation-narrative">{stage.narrative}</p>
      <InteractiveSchematic
        db={db}
        scenario={scenario}
        currentStep={currentStep}
        selectedModule={selectedModule}
        onSelectModule={onSelectModule}
        presentation
      />
      <div className="presentation-bottom">
        <PacketStreamView scenario={scenario} currentStep={currentStep} presentation />
        <SoftwareCalibrationView scenario={scenario} compact />
      </div>
    </main>
  );
}
