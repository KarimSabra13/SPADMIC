import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function SoftwareNode({ block, active, selected, onSelect }: NodeProps) {
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <rect x="8" y="10" width="178" height="118" rx="12" />
      <path className="node-detail" d="M40 70 h30 l14 -18 l18 36 l16 -18 h34" />
      <rect className="software-core" x="36" y="44" width="32" height="32" rx="4" />
      <rect className="software-core" x="118" y="44" width="32" height="32" rx="4" />
      <text className="tiny-label" x="96" y="107" textAnchor="middle">
        reconstruction + LUT + moyenne
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
