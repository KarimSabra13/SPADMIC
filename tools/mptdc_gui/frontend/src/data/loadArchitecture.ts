import rawDb from "../../../architecture_db.json";
import type { ArchitectureDb, ArchitectureModule, MptdcConstants } from "../types";

const FALLBACKS: Record<string, number> = {
  NE: 8,
  OSC_TS_SLOW_PS: 55,
  OSC_TS_FAST_PS: 50,
  DELTA_STEP: 5,
  DELTA_LSB: 10,
  K_VERNIER: 11,
  NSLOW_W: 7,
  NFAST_W: 7,
  MAX_HITS: 15,
  FIFO_DEPTH: 64,
  N_CTX: 2
};

export function loadArchitecture(): ArchitectureDb {
  return rawDb as ArchitectureDb;
}

export function moduleIndex(db: ArchitectureDb): Map<string, ArchitectureModule> {
  return new Map(db.modules.map((mod) => [mod.name, mod]));
}

export function getModule(db: ArchitectureDb, moduleName: string): ArchitectureModule | undefined {
  return moduleIndex(db).get(moduleName);
}

function parsePlainNumber(value: string | undefined): number | undefined {
  if (!value) return undefined;
  const cleaned = value.replace(/_/g, "").trim();
  if (/^\d+$/.test(cleaned)) return Number(cleaned);
  if (/^64'd\d+$/.test(cleaned)) return Number(cleaned.split("d")[1]);
  return undefined;
}

function sourceForParam(pkg: ArchitectureModule | undefined, name: string) {
  const param = pkg?.parameters?.find((entry) => entry.name === name);
  return {
    value: param?.value ?? String(FALLBACKS[name] ?? ""),
    file: pkg?.file ?? "MPTDC/rtl/pkg/mptdc_pkg.sv",
    line: param?.line,
    fallback: !param
  };
}

export function extractMptdcConstants(db: ArchitectureDb): MptdcConstants {
  const pkg = db.modules.find((mod) => mod.name === "mptdc_pkg");
  const raw = new Map((pkg?.parameters ?? []).map((entry) => [entry.name, entry.value]));
  const values: Record<string, number> = {};
  const sources: MptdcConstants["sources"] = {};
  const fallbacks: string[] = [];

  for (const name of Object.keys(FALLBACKS)) {
    const parsed = parsePlainNumber(raw.get(name));
    values[name] = parsed ?? FALLBACKS[name];
    sources[name] = sourceForParam(pkg, name);
    if (parsed === undefined) {
      sources[name].fallback = true;
      fallbacks.push(name);
    }
  }

  values.PD_N = values.NE * values.NE;
  sources.PD_N = sourceForParam(pkg, "PD_N");
  if (sources.PD_N.fallback) fallbacks.push("PD_N");

  values.DELTA_STEP = Math.max(1, values.OSC_TS_SLOW_PS - values.OSC_TS_FAST_PS);
  sources.DELTA_STEP = sourceForParam(pkg, "DELTA_STEP");
  values.DELTA_LSB = 2 * values.DELTA_STEP;
  sources.DELTA_LSB = sourceForParam(pkg, "DELTA_LSB");
  values.K_VERNIER = Math.max(1, Math.floor(values.OSC_TS_SLOW_PS / values.DELTA_STEP));
  sources.K_VERNIER = sourceForParam(pkg, "K_VERNIER");
  values.SLOW_HALF_PERIOD_PS = values.NE * values.OSC_TS_SLOW_PS;
  sources.SLOW_HALF_PERIOD_PS = sourceForParam(pkg, "SLOW_HALF_PERIOD_PS");
  values.FAST_HALF_PERIOD_PS = values.NE * values.OSC_TS_FAST_PS;
  sources.FAST_HALF_PERIOD_PS = sourceForParam(pkg, "FAST_HALF_PERIOD_PS");

  return { values, sources, fallbacks: Array.from(new Set(fallbacks)) };
}

export function portNames(db: ArchitectureDb, moduleName: string, direction?: "input" | "output"): string[] {
  const mod = getModule(db, moduleName);
  return (mod?.ports ?? [])
    .filter((port) => !direction || port.direction === direction)
    .map((port) => port.name);
}

export function rtlReference(db: ArchitectureDb, moduleName: string): string {
  const mod = getModule(db, moduleName);
  if (!mod) return "Référence RTL non trouvée";
  const line = mod.line ? `:${mod.line}` : "";
  return `${mod.file}${line}`;
}

export function scenarioEvidence(): Array<{ label: string; ref: string }> {
  return [
    { label: "Top actif", ref: "MPTDC/rtl/top/mptdc_top_asic.sv:24" },
    { label: "Core mesure/readout", ref: "MPTDC/rtl/top/mptdc_core.sv:32" },
    { label: "Matrice PD 8x8", ref: "MPTDC/rtl/top/mptdc_core.sv:406" },
    { label: "Cellule PD", ref: "MPTDC/rtl/pd/mptdc_pd_cell.sv:39" },
    { label: "Serializer narrow16", ref: "MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:24" },
    { label: "Calibration off-chip", ref: "MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md" }
  ];
}
