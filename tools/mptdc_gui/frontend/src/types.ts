export type InputSource = "SPAD" | "CAL";
export type OutputMode = "narrow16" | "shared";
export type StageId =
  | "armement"
  | "selection"
  | "start"
  | "comptage_lent"
  | "stop"
  | "detection"
  | "snapshot"
  | "evaluation"
  | "contexte"
  | "drain"
  | "fifo"
  | "sortie"
  | "logiciel";

export type SignalClass = "async" | "phase" | "data" | "control" | "reset" | "warning" | "software";

export interface ArchitecturePort {
  name: string;
  direction: "input" | "output" | "inout" | "";
  sv_type?: string;
  width?: string;
  line?: number;
  category?: string;
}

export interface ArchitectureReference {
  file: string;
  line?: number;
  kind?: string;
}

export interface ArchitectureModule {
  name: string;
  kind: string;
  file: string;
  line?: number;
  purpose?: string;
  ports?: ArchitecturePort[];
  parameters?: { name: string; value: string; line?: number }[];
  instances?: { module?: string; instance?: string; name?: string }[];
  signals?: { name: string; kind?: string; width?: string; line?: number; category?: string }[];
  fsm_states?: string[];
  key_registers?: string[];
  direct_evidence?: ArchitectureReference[];
}

export interface ArchitectureDb {
  schema_version: number;
  active_top: string;
  full_chip_top: string;
  modules: ArchitectureModule[];
  signals: Array<{
    name: string;
    category?: string;
    widths?: string[];
    directions?: string[];
    producers?: string[];
    consumers?: string[];
    appearances?: Array<{ file: string; line?: number; context?: string }>;
  }>;
  curated?: {
    flows?: Record<string, unknown>;
    event_format?: Record<string, unknown>;
    verification?: Record<string, unknown>;
    calibration?: Record<string, unknown>;
    uncertainties?: Array<{ title: string; detail: string; severity?: string; evidence?: ArchitectureReference[] }>;
  };
  parser_validation?: {
    passed: boolean;
    checks: Array<{ module: string; passed: boolean; missing: string[]; bad_short_names: string[]; parsed: string[] }>;
  };
}

export interface ConstantSource {
  value: string;
  file: string;
  line?: number;
  fallback: boolean;
}

export interface MptdcConstants {
  values: Record<string, number>;
  sources: Record<string, ConstantSource>;
  fallbacks: string[];
}

export interface ScenarioConfig {
  inputSource: InputSource;
  stopDelayNs: number;
  maxHits: number;
  outputMode: OutputMode;
  speed: 0.25 | 0.5 | 1 | 2;
}

export interface PhaseSample {
  timeNs: number;
  slowTap: number;
  fastTap: number;
}

export interface PdHit {
  cell: number;
  ns: number;
  nf: number;
  nslow: number;
  nfast: number;
  rawTps: number;
  selected: boolean;
  recordIndex?: number;
}

export interface AcqRecord {
  index: number;
  kind: "META" | "HIT" | "EOC";
  label: string;
  fields: Array<{ name: string; bits?: string; value: string | number; source?: string }>;
  valueHex: string;
  rtlRefs: ArchitectureReference[];
}

export interface NarrowWord {
  index: number;
  kind: "HEADER" | "HIT_W0" | "HIT_W1" | "EOC";
  valueHex: string;
  label: string;
  fields: Array<{ name: string; bits?: string; value: string | number; source?: string }>;
}

export interface CalibrationPoint {
  hitIndex: number;
  cell: number;
  rawTps: number;
  correctionPs: number;
  calibratedTps: number;
}

export interface SoftwareReconstruction {
  modelLabel: string;
  rawAveragePs: number;
  calibratedAveragePs: number;
  standardDeviationPs: number;
  finalValuePs: number;
  finalValueNs: number;
  points: CalibrationPoint[];
  notes: string[];
}

export interface TimelineEvent {
  stage: StageId;
  label: string;
  timeNs: number;
  durationNs: number;
  narrative: string;
  activeSignals: string[];
  activeBlocks: string[];
  signalValues: Record<string, 0 | 1 | string>;
}

export interface VernierScenario {
  inputSource: InputSource;
  startTimeNs: number;
  stopDelayNs: number;
  stopTimeNs: number;
  maxHits: number;
  outputMode: OutputMode;
  constants: MptdcConstants;
  phases: PhaseSample[];
  hits: PdHit[];
  rawRecords: AcqRecord[];
  narrowWords: NarrowWord[];
  software: SoftwareReconstruction;
  timeline: TimelineEvent[];
  warnings: string[];
}

export interface BlockDescriptor {
  id: string;
  module: string;
  label: string;
  subtitle: string;
  kind:
    | "mux"
    | "frontend"
    | "osc"
    | "gray"
    | "pd"
    | "bridge"
    | "fsm"
    | "context"
    | "fifo"
    | "serializer"
    | "software";
  x: number;
  y: number;
  tags: string[];
  inputs: string[];
  outputs: string[];
}
