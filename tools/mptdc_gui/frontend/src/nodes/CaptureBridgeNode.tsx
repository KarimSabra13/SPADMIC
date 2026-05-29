import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function CaptureBridgeNode({ block, active, selected, onSelect }: NodeProps) {
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <rect x="10" y="10" width="150" height="112" rx="8" />
      {[0, 1, 2].map((stage) => (
        <g key={stage} transform={`translate(${38 + stage * 34} 62)`}>
          <rect className="flop" x="-10" y="-18" width="20" height="36" rx="2" />
          <path className="node-detail" d="M-7 10 l7 -7 l7 7" />
        </g>
      ))}
      <path className="node-detail" d="M20 62 h116 m-10 -8 l12 8 l-12 8" />
      <text className="tiny-label" x="86" y="103" textAnchor="middle">
        snapshot statique
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
