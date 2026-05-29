import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function GrayCounterNode({ block, active, selected, onSelect }: NodeProps) {
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <rect x="12" y="12" width="142" height="104" rx="8" />
      {[0, 1, 2, 3, 4, 5, 6].map((bit) => (
        <rect key={bit} className="bit-cell" x={28 + bit * 16} y="64" width="12" height="28" rx="2" />
      ))}
      <path className="node-detail" d="M28 52 h96 m-12 -8 l12 8 l-12 8" />
      <text className="tiny-label" x="84" y="104" textAnchor="middle">
        Gray + snapshot CDC
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
