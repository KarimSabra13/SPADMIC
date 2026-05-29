import type { ArchitectureDb, BlockDescriptor, VernierScenario } from "../types";
import MuxNode from "../nodes/MuxNode";
import FrontendNode from "../nodes/FrontendNode";
import RingOscillatorNode from "../nodes/RingOscillatorNode";
import GrayCounterNode from "../nodes/GrayCounterNode";
import PdMatrixNode from "../nodes/PdMatrixNode";
import CaptureBridgeNode from "../nodes/CaptureBridgeNode";
import FsmNode from "../nodes/FsmNode";
import ContextBankNode from "../nodes/ContextBankNode";
import FifoNode from "../nodes/FifoNode";
import SerializerNode from "../nodes/SerializerNode";
import SoftwareNode from "../nodes/SoftwareNode";

interface Props {
  db: ArchitectureDb;
  scenario: VernierScenario;
  currentStep: number;
  selectedModule: string;
  onSelectModule: (moduleName: string) => void;
  presentation?: boolean;
}

export const SCHEMATIC_BLOCKS: BlockDescriptor[] = [
  {
    id: "mux",
    module: "mptdc_input_mux",
    label: "MUX SPAD/CAL",
    subtitle: "sélection entrée",
    kind: "mux",
    x: 110,
    y: 285,
    tags: ["async"],
    inputs: ["start_spad_async_i", "cal_start_async_i"],
    outputs: ["start_async_o", "stop_async_o"]
  },
  {
    id: "frontend",
    module: "mptdc_async_frontend_v2",
    label: "Frontend async",
    subtitle: "START/STOP + ctx",
    kind: "frontend",
    x: 335,
    y: 285,
    tags: ["async"],
    inputs: ["start_async_i", "stop_async_i", "conv_arm_i"],
    outputs: ["osc_slow_en", "osc_fast_en", "pd_enable"]
  },
  {
    id: "slowOsc",
    module: "mptdc_osc_wrapper",
    label: "Osc. lent",
    subtitle: "slow ring",
    kind: "osc",
    x: 575,
    y: 145,
    tags: ["phase"],
    inputs: ["osc_slow_en"],
    outputs: ["slow_phase[7:0]"]
  },
  {
    id: "slowGray",
    module: "mptdc_gray_cnt_sync",
    label: "Compteur slow",
    subtitle: "Gray snapshot",
    kind: "gray",
    x: 795,
    y: 145,
    tags: ["phase", "snapshot"],
    inputs: ["slow_phase[0]"],
    outputs: ["nslow_snap"]
  },
  {
    id: "stopCapture",
    module: "mptdc_stop_capture_async",
    label: "Capture STOP",
    subtitle: "boundary",
    kind: "bridge",
    x: 795,
    y: 415,
    tags: ["async"],
    inputs: ["stop_async_i"],
    outputs: ["nfast_stop"]
  },
  {
    id: "fastOsc",
    module: "mptdc_osc_wrapper",
    label: "Osc. rapide",
    subtitle: "fast ring",
    kind: "osc",
    x: 1035,
    y: 415,
    tags: ["phase"],
    inputs: ["osc_fast_en"],
    outputs: ["fast_phase[7:0]"]
  },
  {
    id: "fastGray",
    module: "mptdc_gray_cnt_sync",
    label: "Compteur fast",
    subtitle: "Gray snapshot",
    kind: "gray",
    x: 1265,
    y: 415,
    tags: ["phase", "snapshot"],
    inputs: ["fast_phase[0]"],
    outputs: ["nfast_snap"]
  },
  {
    id: "pd",
    module: "mptdc_pd_cell",
    label: "Matrice PD 8x8",
    subtitle: "Vernier",
    kind: "pd",
    x: 1195,
    y: 135,
    tags: ["phase"],
    inputs: ["slow_phase[ns]", "fast_phase[nf]"],
    outputs: ["pd_hit_level", "pd_nfast_hit_packed"]
  },
  {
    id: "bridge",
    module: "mptdc_hit_capture_bridge",
    label: "Snapshot / bridge",
    subtitle: "image statique",
    kind: "bridge",
    x: 1440,
    y: 145,
    tags: ["snapshot"],
    inputs: ["pd_hit_level", "nslow", "nfast"],
    outputs: ["snapshot_i"]
  },
  {
    id: "meas",
    module: "mptdc_meas_ctrl",
    label: "FSM mesure",
    subtitle: "count + flags",
    kind: "fsm",
    x: 1665,
    y: 145,
    tags: ["readout"],
    inputs: ["snapshot", "max_hits"],
    outputs: ["capture_en", "hit_count"]
  },
  {
    id: "context",
    module: "mptdc_context_bank",
    label: "Context bank",
    subtitle: "double buffer",
    kind: "context",
    x: 1885,
    y: 145,
    tags: ["snapshot"],
    inputs: ["capture"],
    outputs: ["ctx_drain"]
  },
  {
    id: "drain",
    module: "mptdc_drain_ctrl",
    label: "FSM drain",
    subtitle: "META/HIT/EOC",
    kind: "fsm",
    x: 2105,
    y: 145,
    tags: ["readout"],
    inputs: ["ctx_drain"],
    outputs: ["fifo_wr_data"]
  },
  {
    id: "fifo",
    module: "mptdc_sync_fifo",
    label: "FIFO",
    subtitle: "records",
    kind: "fifo",
    x: 2325,
    y: 145,
    tags: ["readout"],
    inputs: ["wr_en", "rd_en"],
    outputs: ["valid", "empty"]
  },
  {
    id: "serializer",
    module: "mptdc_narrow16_tx_v2",
    label: "Serializer / shared",
    subtitle: "narrow16 ou acq_*",
    kind: "serializer",
    x: 2545,
    y: 145,
    tags: ["readout"],
    inputs: ["fifo_rd_data"],
    outputs: ["narrow16", "acq_*"]
  },
  {
    id: "software",
    module: "host_offchip_calibration",
    label: "Logiciel host",
    subtitle: "reco + LUT",
    kind: "software",
    x: 2785,
    y: 145,
    tags: ["logiciel"],
    inputs: ["packets"],
    outputs: ["valeur finale"]
  }
];

const EDGES = [
  ["mux", "frontend", "async"],
  ["frontend", "slowOsc", "control"],
  ["slowOsc", "slowGray", "phase"],
  ["frontend", "stopCapture", "async"],
  ["stopCapture", "fastOsc", "control"],
  ["fastOsc", "fastGray", "phase"],
  ["slowGray", "pd", "phase"],
  ["fastGray", "pd", "phase"],
  ["pd", "bridge", "data"],
  ["bridge", "meas", "data"],
  ["meas", "context", "control"],
  ["context", "drain", "data"],
  ["drain", "fifo", "data"],
  ["fifo", "serializer", "data"],
  ["serializer", "software", "data"]
] as const;

function center(block: BlockDescriptor) {
  return { x: block.x + 85, y: block.y + 66 };
}

function blockById(id: string) {
  return SCHEMATIC_BLOCKS.find((block) => block.id === id)!;
}

function edgePath(sourceId: string, targetId: string): string {
  const source = center(blockById(sourceId));
  const target = center(blockById(targetId));
  const sx = source.x + 82;
  const tx = target.x - 8;
  const mid = sx + (tx - sx) / 2;
  return `M ${sx} ${source.y} C ${mid} ${source.y}, ${mid} ${target.y}, ${tx} ${target.y}`;
}

function renderNode(block: BlockDescriptor, active: boolean, selected: boolean, onSelectModule: (moduleName: string) => void) {
  const props = { block, active, selected, onSelect: onSelectModule };
  if (block.kind === "mux") return <MuxNode key={block.id} {...props} />;
  if (block.kind === "frontend") return <FrontendNode key={block.id} {...props} />;
  if (block.kind === "osc") return <RingOscillatorNode key={block.id} {...props} />;
  if (block.kind === "gray") return <GrayCounterNode key={block.id} {...props} />;
  if (block.kind === "pd") return <PdMatrixNode key={block.id} {...props} />;
  if (block.kind === "bridge") return <CaptureBridgeNode key={block.id} {...props} />;
  if (block.kind === "fsm") return <FsmNode key={block.id} {...props} />;
  if (block.kind === "context") return <ContextBankNode key={block.id} {...props} />;
  if (block.kind === "fifo") return <FifoNode key={block.id} {...props} />;
  if (block.kind === "serializer") return <SerializerNode key={block.id} {...props} />;
  return <SoftwareNode key={block.id} {...props} />;
}

export default function InteractiveSchematic({ scenario, currentStep, selectedModule, onSelectModule, presentation }: Props) {
  const stage = scenario.timeline[currentStep];
  const activeBlocks = new Set(stage.activeBlocks);
  const activeEdges = new Set(
    EDGES.filter(([source, target]) => activeBlocks.has(source) || activeBlocks.has(target) || (activeBlocks.has("shared") && target === "software")).map(
      ([source, target]) => `${source}-${target}`
    )
  );

  return (
    <div className={`schematic-shell${presentation ? " presentation-schematic" : ""}`} id="schematic-export-root">
      <svg id="mptdc-main-schematic" viewBox="0 0 3030 700" role="img" aria-label="Schéma interactif MPTDC">
        <defs>
          <marker id="arrow-data" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto">
            <path d="M0,0 L0,6 L9,3 z" fill="#0f766e" />
          </marker>
          <marker id="arrow-control" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto">
            <path d="M0,0 L0,6 L9,3 z" fill="#7c3aed" />
          </marker>
          <marker id="arrow-phase" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto">
            <path d="M0,0 L0,6 L9,3 z" fill="#2563eb" />
          </marker>
          <marker id="arrow-async" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto">
            <path d="M0,0 L0,6 L9,3 z" fill="#be5d00" />
          </marker>
        </defs>

        <rect className="schematic-bg" x="0" y="0" width="3030" height="700" />
        <g transform="translate(24 312)" className="input-source">
          <path d="M0 0 h72 l24 38 l-24 38 H0 z" />
          <text x="42" y="30" textAnchor="middle">
            START
          </text>
          <text x="42" y="52" textAnchor="middle">
            STOP
          </text>
        </g>
        <path id="edge-source-mux" className="edge edge-async is-active" d="M120 350 C140 350, 150 350, 165 350" markerEnd="url(#arrow-async)" />

        {EDGES.map(([source, target, kind], index) => {
          const id = `${source}-${target}`;
          const active = activeEdges.has(id);
          return (
            <g key={id}>
              <path
                id={`edge-${index}`}
                className={`edge edge-${kind}${active ? " is-active" : ""}`}
                d={edgePath(source, target)}
                markerEnd={`url(#arrow-${kind})`}
              />
              {active && (
                <circle className={`edge-particle particle-${kind}`} r="6">
                  <animateMotion dur="1.8s" repeatCount="indefinite">
                    <mpath href={`#edge-${index}`} />
                  </animateMotion>
                </circle>
              )}
            </g>
          );
        })}

        {SCHEMATIC_BLOCKS.map((block) =>
          renderNode(
            block,
            activeBlocks.has(block.id) || (activeBlocks.has("shared") && block.id === "serializer"),
            selectedModule === block.module,
            onSelectModule
          )
        )}

        <g className="legend-inline" transform="translate(70 32)">
          <text x="0" y="0">
            Parcours de mesure sans découpage par domaines d’horloge
          </text>
          <text x="0" y="24">
            Tags discrets: async · phase · snapshot · readout · logiciel
          </text>
        </g>
        <g className="stage-badge" transform="translate(2370 36)">
          <rect x="0" y="0" width="560" height="82" rx="16" />
          <text x="24" y="32">
            {stage.label}
          </text>
          <text x="24" y="58">
            STOP = {scenario.stopDelayNs.toFixed(2)} ns · {scenario.hits.length} hits ·{" "}
            {scenario.outputMode === "narrow16" ? "narrow16" : "shared acq_*"}
          </text>
        </g>
      </svg>
    </div>
  );
}
