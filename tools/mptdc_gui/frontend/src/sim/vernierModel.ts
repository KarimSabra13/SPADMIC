import { extractMptdcConstants } from "../data/loadArchitecture";
import { buildAcqRecords, buildNarrowWords } from "./packetModel";
import { reconstructSoftware } from "./calibrationModel";
import type {
  ArchitectureDb,
  PdHit,
  PhaseSample,
  ScenarioConfig,
  StageId,
  TimelineEvent,
  VernierScenario
} from "../types";

const STAGE_LABELS: Array<{ stage: StageId; label: string; narrative: string; blocks: string[]; signals: string[] }> = [
  {
    stage: "armement",
    label: "Armement",
    narrative: "Le CSR arme la conversion; les contextes sont libres et les oscillateurs restent arrêtés.",
    blocks: ["csr", "frontend", "context"],
    signals: ["conv_arm_i"]
  },
  {
    stage: "selection",
    label: "Sélection source",
    narrative: "Le MUX choisit SPAD ou CAL puis transmet le couple START/STOP sélectionné au frontend.",
    blocks: ["mux", "frontend"],
    signals: ["input_sel_i", "start_async_i", "stop_async_i"]
  },
  {
    stage: "start",
    label: "START",
    narrative: "START arrive à t = 0 ns; le frontend verrouille START, réserve un contexte et démarre l’oscillateur lent.",
    blocks: ["frontend", "slowOsc", "slowGray"],
    signals: ["start_async_i", "osc_slow_en_async_o"]
  },
  {
    stage: "comptage_lent",
    label: "Comptage lent",
    narrative: "Les phases lentes avancent et le compteur Gray slow suit la phase de référence.",
    blocks: ["slowOsc", "slowGray"],
    signals: ["osc_slow_en_async_o", "slow_phase", "nslow_src_count"]
  },
  {
    stage: "stop",
    label: "STOP",
    narrative: "STOP arrive après le délai choisi; il est accepté après START, puis le fast ring démarre et la frontière STOP est capturée.",
    blocks: ["frontend", "stopCapture", "fastOsc", "fastGray"],
    signals: ["stop_async_i", "osc_fast_en_async_o", "nfast_stop_latched"]
  },
  {
    stage: "detection",
    label: "Détection Vernier",
    narrative: "La matrice PD 8x8 échantillonne slow_phase[ns] avec fast_phase[nf]; les cellules de crossing se verrouillent.",
    blocks: ["pd", "fastOsc", "fastGray"],
    signals: ["pd_enable_async_o", "pd_hit_level", "pd_nfast_hit_packed"]
  },
  {
    stage: "snapshot",
    label: "Snapshot",
    narrative: "Les compteurs et hits stabilisés sont capturés comme image statique puis transférés vers la logique système.",
    blocks: ["bridge", "slowGray", "fastGray", "pd"],
    signals: ["snapshot_en", "pd_hit_level", "pd_nfast_hit_packed"]
  },
  {
    stage: "evaluation",
    label: "Évaluation",
    narrative: "La FSM de mesure compte les hits, applique max_hits et prépare les flags de fermeture.",
    blocks: ["meas", "bridge"],
    signals: ["capture_en", "hit_count"]
  },
  {
    stage: "contexte",
    label: "Contexte",
    narrative: "Le contexte double-buffer reçoit le snapshot et devient disponible pour le drain.",
    blocks: ["context", "meas"],
    signals: ["ctx_drain_o", "capture_en"]
  },
  {
    stage: "drain",
    label: "Drain",
    narrative: "La FSM drain émet META puis les records HIT issus du scan de la matrice PD.",
    blocks: ["drain", "context"],
    signals: ["fifo_wr_en", "fifo_wr_data"]
  },
  {
    stage: "fifo",
    label: "FIFO",
    narrative: "Les records entrent dans la FIFO synchrone; le niveau FIFO reflète la pression readout.",
    blocks: ["fifo", "drain"],
    signals: ["fifo_wr_en", "fifo_rd_en"]
  },
  {
    stage: "sortie",
    label: "Sortie",
    narrative: "La sortie est sérialisée en narrow16 ou exposée comme records shared acq_* vers le TOP.",
    blocks: ["serializer", "shared"],
    signals: ["narrow_valid_o", "narrow_data_o", "acq_valid_o", "acq_data_o"]
  },
  {
    stage: "logiciel",
    label: "Logiciel",
    narrative: "Le host parse les packets, reconstruit les tuples bruts, applique la correction LUT/mean-correction et moyenne les hits.",
    blocks: ["software"],
    signals: ["raw_tuple", "lut_correction", "average"]
  }
];

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function makePhases(stopDelayNs: number, ne: number, slowStepPs: number, fastStepPs: number): PhaseSample[] {
  const samples: PhaseSample[] = [];
  const endNs = Math.max(28, stopDelayNs + 14);
  for (let t = 0; t <= endNs; t += 0.5) {
    const slowTap = Math.floor((t * 1000) / slowStepPs) % ne;
    const fastTap = t < stopDelayNs ? 0 : Math.floor(((t - stopDelayNs) * 1000) / fastStepPs) % ne;
    samples.push({ timeNs: Number(t.toFixed(2)), slowTap, fastTap });
  }
  return samples;
}

function makeHits(config: ScenarioConfig, ne: number, slowHalfPs: number, nfastW: number, deltaStepPs: number): PdHit[] {
  const requested = clamp(Math.floor(config.maxHits), 0, 15);
  if (config.stopDelayNs >= 31.5 || requested === 0) return [];
  const delayPs = config.stopDelayNs * 1000;
  const baseCell = Math.floor((delayPs / Math.max(1, deltaStepPs)) % (ne * ne));
  const baseNslow = Math.floor(delayPs / slowHalfPs);
  const nfastModulo = 2 ** Math.min(12, nfastW);
  const hits: PdHit[] = [];

  for (let index = 0; index < requested; index += 1) {
    const cell = (baseCell + index * (ne + 1)) % (ne * ne);
    const ns = Math.floor(cell / ne);
    const nf = cell % ne;
    const spread = (index - (requested - 1) / 2) * deltaStepPs;
    const rawTps = Math.round(delayPs + spread + (ns - nf) * 0.8);
    hits.push({
      cell,
      ns,
      nf,
      nslow: baseNslow + ns,
      nfast: (Math.floor(delayPs / 50) + nf + index) % nfastModulo,
      rawTps,
      selected: true,
      recordIndex: index + 1
    });
  }
  return hits;
}

function stageTime(stage: StageId, stopDelayNs: number): number {
  const fixed: Record<StageId, number> = {
    armement: -2,
    selection: -1,
    start: 0,
    comptage_lent: Math.max(0.5, stopDelayNs * 0.45),
    stop: stopDelayNs,
    detection: stopDelayNs + 2,
    snapshot: stopDelayNs + 4,
    evaluation: stopDelayNs + 6,
    contexte: stopDelayNs + 8,
    drain: stopDelayNs + 10,
    fifo: stopDelayNs + 12,
    sortie: stopDelayNs + 14,
    logiciel: stopDelayNs + 17
  };
  return fixed[stage];
}

function signalValues(stage: StageId, outputMode: ScenarioConfig["outputMode"]): Record<string, 0 | 1 | string> {
  return {
    start_async_i: stage === "start" ? 1 : 0,
    stop_async_i: stage === "stop" ? 1 : 0,
    conv_arm_i: ["armement", "selection", "start", "comptage_lent", "stop"].includes(stage) ? 1 : 0,
    osc_slow_en_async_o: ["start", "comptage_lent", "stop", "detection"].includes(stage) ? 1 : 0,
    osc_fast_en_async_o: ["stop", "detection"].includes(stage) ? 1 : 0,
    pd_enable_async_o: stage === "detection" ? 1 : 0,
    pd_hit_level: ["detection", "snapshot", "evaluation"].includes(stage) ? "actif" : 0,
    pd_nfast_hit_packed: ["detection", "snapshot", "evaluation"].includes(stage) ? "actif" : 0,
    snapshot_en: stage === "snapshot" ? 1 : 0,
    capture_en: stage === "evaluation" ? 1 : 0,
    fifo_wr_en: ["drain", "fifo"].includes(stage) ? 1 : 0,
    fifo_rd_en: ["fifo", "sortie"].includes(stage) ? 1 : 0,
    narrow_valid_o: stage === "sortie" && outputMode === "narrow16" ? 1 : 0,
    narrow_data_o: stage === "sortie" && outputMode === "narrow16" ? "mots 16-bit" : 0,
    acq_valid_o: stage === "sortie" && outputMode === "shared" ? 1 : 0,
    acq_data_o: stage === "sortie" && outputMode === "shared" ? "records acq_*" : 0
  };
}

function buildTimeline(config: ScenarioConfig): TimelineEvent[] {
  return STAGE_LABELS.map((entry) => ({
    stage: entry.stage,
    label: entry.label,
    timeNs: stageTime(entry.stage, config.stopDelayNs),
    durationNs: entry.stage === "comptage_lent" ? Math.max(0.5, config.stopDelayNs - 0.2) : 1.4,
    narrative: entry.narrative,
    activeSignals: entry.signals,
    activeBlocks: entry.blocks,
    signalValues: signalValues(entry.stage, config.outputMode)
  }));
}

export function buildVernierScenario(db: ArchitectureDb, config: ScenarioConfig): VernierScenario {
  const constants = extractMptdcConstants(db);
  const ne = constants.values.NE;
  const maxHits = clamp(config.maxHits, 0, constants.values.MAX_HITS || 15);
  const normalized: ScenarioConfig = {
    ...config,
    stopDelayNs: clamp(config.stopDelayNs, 0, 32),
    maxHits
  };
  const phases = makePhases(
    normalized.stopDelayNs,
    ne,
    constants.values.OSC_TS_SLOW_PS,
    constants.values.OSC_TS_FAST_PS
  );
  const hits = makeHits(
    normalized,
    ne,
    constants.values.SLOW_HALF_PERIOD_PS,
    constants.values.NFAST_W,
    constants.values.DELTA_STEP
  );
  const rawRecords = buildAcqRecords(hits, normalized.outputMode);
  const narrowWords = buildNarrowWords(rawRecords);
  const software = reconstructSoftware(hits, normalized.stopDelayNs * 1000);
  const warnings = [
    "Modèle pédagogique aligné avec les constantes RTL; ce n’est pas une simulation transistor, STA ni une preuve silicon.",
    "La calibration LUT/mean-correction est logicielle/off-chip dans cette présentation.",
    ...constants.fallbacks.map((name) => `Constante ${name} en fallback local: vérifier architecture_db.json.`)
  ];
  if (normalized.stopDelayNs >= 31.5) {
    warnings.push("Cas timeout pédagogique: aucune cellule PD sélectionnée pour illustrer la fermeture sans hit.");
  }

  return {
    inputSource: normalized.inputSource,
    startTimeNs: 0,
    stopDelayNs: normalized.stopDelayNs,
    stopTimeNs: normalized.stopDelayNs,
    maxHits: normalized.maxHits,
    outputMode: normalized.outputMode,
    constants,
    phases,
    hits,
    rawRecords,
    narrowWords,
    software,
    timeline: buildTimeline(normalized),
    warnings
  };
}

export const STAGE_ORDER = STAGE_LABELS.map((entry) => entry.stage);
