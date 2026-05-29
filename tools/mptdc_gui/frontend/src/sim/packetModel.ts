import type { AcqRecord, ArchitectureReference, NarrowWord, OutputMode, PdHit } from "../types";

const DRAIN_REF: ArchitectureReference = { file: "MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv", line: 26 };
const NARROW_REF: ArchitectureReference = { file: "MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv", line: 24 };
const PKG_REF: ArchitectureReference = { file: "MPTDC/rtl/pkg/mptdc_pkg.sv", line: 190 };

function hex(value: number, width = 4): string {
  return `0x${Math.max(0, value).toString(16).toUpperCase().padStart(width, "0")}`;
}

export function buildAcqRecords(hits: PdHit[], outputMode: OutputMode): AcqRecord[] {
  const selectedHits = hits.filter((hit) => hit.selected);
  const meta: AcqRecord = {
    index: 0,
    kind: "META",
    label: "META",
    valueHex: hex(0xa000 | Math.min(15, selectedHits.length)),
    rtlRefs: [DRAIN_REF, PKG_REF],
    fields: [
      { name: "type", bits: "record.kind", value: "META", source: "mptdc_acq_rec_t" },
      { name: "hit_count", bits: "MAX_HITS_W", value: selectedHits.length, source: "snapshot.hit_count" },
      { name: "mode_sortie", value: outputMode === "narrow16" ? "standalone narrow16" : "shared acq_*" }
    ]
  };

  const hitRecords = selectedHits.map<AcqRecord>((hit, index) => ({
    index: index + 1,
    kind: "HIT",
    label: `HIT ${index}`,
    valueHex: hex(0xb000 | ((hit.cell & 0x3f) << 4) | (hit.nfast & 0xf)),
    rtlRefs: [DRAIN_REF, PKG_REF],
    fields: [
      { name: "cell", bits: "PD_W", value: hit.cell, source: "CELL = ns * NE + nf" },
      { name: "ns", bits: "PH_W", value: hit.ns, source: "slow_phase[ns]" },
      { name: "nf", bits: "PH_W", value: hit.nf, source: "fast_phase[nf]" },
      { name: "nslow", bits: "NSLOW_W", value: hit.nslow, source: "snapshot.nslow_snap" },
      { name: "nfast", bits: "NFAST_W", value: hit.nfast, source: "pd_nfast_hit_packed" }
    ]
  }));

  const eoc: AcqRecord = {
    index: hitRecords.length + 1,
    kind: "EOC",
    label: "EOC",
    valueHex: hex(0xe000 | Math.min(15, selectedHits.length)),
    rtlRefs: [DRAIN_REF, PKG_REF],
    fields: [
      { name: "type", bits: "record.kind", value: "EOC" },
      { name: "done", value: 1 },
      { name: "flags", value: "closed_by_maxhits / normal selon scénario" }
    ]
  };

  return [meta, ...hitRecords, eoc];
}

export function buildNarrowWords(records: AcqRecord[]): NarrowWord[] {
  const words: NarrowWord[] = [];
  const hitRecords = records.filter((record) => record.kind === "HIT");
  words.push({
    index: words.length,
    kind: "HEADER",
    label: "HEADER",
    valueHex: hex(0xd000 | Math.min(15, hitRecords.length)),
    fields: [
      { name: "signature", bits: "15:12", value: "D" },
      { name: "hit_count", bits: "3:0", value: hitRecords.length, source: "mptdc_narrow16_tx_v2" }
    ]
  });

  hitRecords.forEach((record, hitIndex) => {
    const cell = Number(record.fields.find((field) => field.name === "cell")?.value ?? 0);
    const nfast = Number(record.fields.find((field) => field.name === "nfast")?.value ?? 0);
    const nslow = Number(record.fields.find((field) => field.name === "nslow")?.value ?? 0);
    words.push({
      index: words.length,
      kind: "HIT_W0",
      label: `HIT ${hitIndex} W0`,
      valueHex: hex(0x8000 | ((cell & 0x3f) << 4) | (nfast & 0xf)),
      fields: [
        { name: "cell", bits: "9:4", value: cell },
        { name: "nfast_lsb", bits: "3:0", value: nfast & 0xf }
      ]
    });
    words.push({
      index: words.length,
      kind: "HIT_W1",
      label: `HIT ${hitIndex} W1`,
      valueHex: hex(0x9000 | ((nslow & 0x7f) << 4) | ((nfast >> 4) & 0xf)),
      fields: [
        { name: "nslow", bits: "10:4", value: nslow },
        { name: "nfast_msb", bits: "3:0", value: (nfast >> 4) & 0xf }
      ]
    });
  });

  words.push({
    index: words.length,
    kind: "EOC",
    label: "EOC",
    valueHex: hex(0xf000 | Math.min(15, hitRecords.length)),
    fields: [
      { name: "signature", bits: "15:12", value: "F" },
      { name: "fin_conversion", value: 1, source: NARROW_REF.file }
    ]
  });
  return words;
}
