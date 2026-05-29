import { useState } from "react";
import type { VernierScenario } from "../types";

interface Props {
  scenario: VernierScenario;
  currentStep: number;
}

export default function PdMatrixView({ scenario, currentStep }: Props) {
  const [hitsOnly, setHitsOnly] = useState(false);
  const stageIndex = currentStep;
  const detectionStarted = stageIndex >= scenario.timeline.findIndex((event) => event.stage === "detection");
  const hitCells = new Map(scenario.hits.map((hit) => [hit.cell, hit]));
  const cells = Array.from({ length: 64 }, (_, cell) => ({ ns: Math.floor(cell / 8), nf: cell % 8, cell }));

  return (
    <section className="panel">
      <div className="panel-title-row">
        <div>
          <h2>Matrice Vernier 8x8</h2>
          <p>64 cellules `mptdc_pd_cell` · `CELL = ns * NE + nf` · packing vers `pd_nfast_hit_packed`.</p>
        </div>
        <div className="segmented">
          <button className={!hitsOnly ? "is-selected" : ""} type="button" onClick={() => setHitsOnly(false)}>
            Voir toutes les cellules
          </button>
          <button className={hitsOnly ? "is-selected" : ""} type="button" onClick={() => setHitsOnly(true)}>
            Voir uniquement les hits
          </button>
        </div>
      </div>
      <div className="pd-layout">
        <div className="pd-axis-col">
          <span />
          {Array.from({ length: 8 }, (_, ns) => (
            <span key={ns}>slow_phase[{ns}]</span>
          ))}
        </div>
        <div className="pd-grid-wrap">
          <div className="pd-axis-row">
            {Array.from({ length: 8 }, (_, nf) => (
              <span key={nf}>fast_phase[{nf}]</span>
            ))}
          </div>
          <div className="pd-grid">
            {cells.map(({ ns, nf, cell }) => {
              const hit = hitCells.get(cell);
              const visible = !hitsOnly || Boolean(hit);
              const animated = detectionStarted && Boolean(hit);
              return (
                <button
                  key={cell}
                  className={`pd-cell${hit ? " has-hit" : ""}${animated ? " is-lit" : ""}${visible ? "" : " is-muted"}`}
                  type="button"
                  title={
                    hit
                      ? `ns=${ns}, nf=${nf}, cell=${cell}, nslow=${hit.nslow}, nfast=${hit.nfast}, rawTps=${hit.rawTps}`
                      : `ns=${ns}, nf=${nf}, cell=${cell}`
                  }
                >
                  <span>{cell}</span>
                </button>
              );
            })}
          </div>
        </div>
        <aside className="pd-side">
          <strong>{scenario.hits.length} hits sélectionnés</strong>
          <p>`nfast_hit` est capturé par cellule; `pd_hit_level[63:0]` indique les cellules verrouillées.</p>
          <p className="evidence-chip">MPTDC/rtl/top/mptdc_core.sv:406</p>
          <p className="evidence-chip">MPTDC/rtl/pd/mptdc_pd_cell.sv:39</p>
        </aside>
      </div>
    </section>
  );
}
