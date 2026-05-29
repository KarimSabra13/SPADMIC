import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function FrontendNode({ block, active, selected, onSelect }: NodeProps) {
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <rect x="8" y="8" width="150" height="112" rx="10" />
      <path className="node-detail" d="M32 88 h26 v-34 h28 v34 h30 v-44 h24" />
      <circle className="state-dot" cx="42" cy="64" r="7" />
      <circle className="state-dot" cx="84" cy="64" r="7" />
      <circle className="state-dot" cx="126" cy="64" r="7" />
      <text className="tiny-label" x="84" y="100" textAnchor="middle">
        latch START/STOP + ctx
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
