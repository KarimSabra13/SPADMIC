import type { ScenarioConfig } from "../types";

interface Props {
  config: ScenarioConfig;
  playing: boolean;
  currentStep: number;
  totalSteps: number;
  onConfigChange: (config: ScenarioConfig) => void;
  onRun: () => void;
  onPause: () => void;
  onNext: () => void;
  onPrev: () => void;
  onReset: () => void;
  onPresentation: () => void;
  onExport: () => void;
}

const speedValues: ScenarioConfig["speed"][] = [0.25, 0.5, 1, 2];

export default function ScenarioControls({
  config,
  playing,
  currentStep,
  totalSteps,
  onConfigChange,
  onRun,
  onPause,
  onNext,
  onPrev,
  onReset,
  onPresentation,
  onExport
}: Props) {
  const update = <K extends keyof ScenarioConfig>(key: K, value: ScenarioConfig[K]) => {
    onConfigChange({ ...config, [key]: value });
  };

  return (
    <section className="control-surface">
      <div className="control-group">
        <label>Source</label>
        <div className="segmented">
          {(["SPAD", "CAL"] as const).map((source) => (
            <button
              key={source}
              className={config.inputSource === source ? "is-selected" : ""}
              onClick={() => update("inputSource", source)}
              type="button"
            >
              {source}
            </button>
          ))}
        </div>
      </div>

      <div className="control-group wide">
        <label>Délai START→STOP: {config.stopDelayNs.toFixed(2)} ns</label>
        <input
          type="range"
          min="0"
          max="32"
          step="0.1"
          value={config.stopDelayNs}
          onChange={(event) => update("stopDelayNs", Number(event.target.value))}
        />
        <div className="preset-row">
          <button type="button" onClick={() => update("stopDelayNs", 15)}>
            15 ns
          </button>
          <button type="button" onClick={() => update("stopDelayNs", 17.5)}>
            17.5 ns
          </button>
          <button type="button" onClick={() => update("stopDelayNs", 20)}>
            20 ns
          </button>
          <button type="button" onClick={() => update("stopDelayNs", 2.5)}>
            cas court
          </button>
          <button type="button" onClick={() => update("stopDelayNs", 28)}>
            cas long
          </button>
          <button type="button" onClick={() => update("stopDelayNs", 32)}>
            cas timeout
          </button>
        </div>
      </div>

      <div className="control-group">
        <label>Sortie</label>
        <div className="segmented">
          <button
            className={config.outputMode === "narrow16" ? "is-selected" : ""}
            onClick={() => update("outputMode", "narrow16")}
            type="button"
          >
            standalone `narrow16`
          </button>
          <button
            className={config.outputMode === "shared" ? "is-selected" : ""}
            onClick={() => update("outputMode", "shared")}
            type="button"
          >
            shared `acq_*`
          </button>
        </div>
      </div>

      <div className="control-group compact">
        <label>`max_hits`</label>
        <input
          type="number"
          min="0"
          max="15"
          value={config.maxHits}
          onChange={(event) => update("maxHits", Number(event.target.value))}
        />
      </div>

      <div className="control-group">
        <label>Vitesse</label>
        <div className="segmented">
          {speedValues.map((speed) => (
            <button
              key={speed}
              className={config.speed === speed ? "is-selected" : ""}
              onClick={() => update("speed", speed)}
              type="button"
            >
              {speed}x
            </button>
          ))}
        </div>
      </div>

      <div className="transport-row">
        <button className="primary" type="button" onClick={onRun}>
          Lancer
        </button>
        <button type="button" onClick={onPause}>
          {playing ? "Pause" : "Pause"}
        </button>
        <button type="button" onClick={onPrev}>
          Pas précédent
        </button>
        <button type="button" onClick={onNext}>
          Pas suivant
        </button>
        <button type="button" onClick={onReset}>
          Réinitialiser
        </button>
        <button type="button" onClick={onPresentation}>
          Mode soutenance
        </button>
        <button type="button" onClick={onExport}>
          Exporter le scénario
        </button>
        <span className="step-indicator">
          étape {currentStep + 1}/{totalSteps}
        </span>
      </div>
    </section>
  );
}
