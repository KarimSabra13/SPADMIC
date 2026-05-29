import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function FsmNode({ block, active, selected, onSelect }: NodeProps) {
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <rect x="10" y="10" width="150" height="112" rx="8" />
      <circle className="state-bubble" cx="48" cy="70" r="15" />
      <circle className="state-bubble" cx="88" cy="52" r="15" />
      <circle className="state-bubble" cx="118" cy="86" r="15" />
      <path className="node-detail" d="M62 64 C70 56 72 54 74 52 M98 62 C106 70 108 74 110 78 M103 91 C82 94 70 88 62 80" />
      <text className="tiny-label" x="84" y="108" textAnchor="middle">
        FSM RTL
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
