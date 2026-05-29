import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function SerializerNode({ block, active, selected, onSelect }: NodeProps) {
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <rect x="10" y="10" width="160" height="112" rx="8" />
      {[0, 1, 2, 3, 4, 5, 6, 7].map((bit) => (
        <rect key={bit} className="shift-cell" x={24 + bit * 15} y="64" width="12" height="26" rx="2" />
      ))}
      <path className="node-detail" d="M26 52 h116 m-10 -8 l12 8 l-12 8" />
      <text className="tiny-label" x="90" y="105" textAnchor="middle">
        sortie 16-bit / acq_*
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
