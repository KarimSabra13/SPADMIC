import type { CalibrationPoint, PdHit, SoftwareReconstruction } from "../types";

function average(values: number[]): number {
  if (values.length === 0) return 0;
  return values.reduce((acc, value) => acc + value, 0) / values.length;
}

function standardDeviation(values: number[]): number {
  if (values.length < 2) return 0;
  const mean = average(values);
  const variance = average(values.map((value) => (value - mean) ** 2));
  return Math.sqrt(variance);
}

function pedagogicalMeanCorrection(cell: number, hitIndex: number): number {
  const cellTerm = ((cell % 8) - 3.5) * 1.4;
  const rowTerm = (Math.floor(cell / 8) - 3.5) * 0.9;
  const repeatabilityTerm = Math.sin((hitIndex + 1) * 1.7) * 1.2;
  return -(cellTerm + rowTerm + repeatabilityTerm);
}

export function reconstructSoftware(hits: PdHit[], requestedDelayPs: number): SoftwareReconstruction {
  const selectedHits = hits.filter((hit) => hit.selected);
  const points: CalibrationPoint[] = selectedHits.map((hit, index) => {
    const correctionPs = pedagogicalMeanCorrection(hit.cell, index);
    const calibratedTps = hit.rawTps + correctionPs;
    return {
      hitIndex: index,
      cell: hit.cell,
      rawTps: hit.rawTps,
      correctionPs,
      calibratedTps
    };
  });

  const rawAveragePs = average(points.map((point) => point.rawTps));
  const calibratedAveragePs = average(points.map((point) => point.calibratedTps));
  const finalValuePs = calibratedAveragePs || requestedDelayPs;

  return {
    modelLabel: "Calibration logicielle / off-chip - modèle de présentation",
    rawAveragePs,
    calibratedAveragePs,
    standardDeviationPs: standardDeviation(points.map((point) => point.calibratedTps)),
    finalValuePs,
    finalValueNs: finalValuePs / 1000,
    points,
    notes: [
      "Le RTL produit les packets et features brutes; la correction LUT 6D / mean-correction est présentée côté host.",
      "Les corrections affichées sont pédagogiques et servent à visualiser le pipeline off-chip.",
      "Les métriques pré-silicon du dépôt restent la référence documentaire pour RMSE/INL/DNL."
    ]
  };
}
