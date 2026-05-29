import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function ContextBankNode({ block, active, selected, onSelect }: NodeProps) {
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <rect x="10" y="10" width="150" height="112" rx="8" />
      <rect className="bank-cell" x="32" y="58" width="42" height="44" rx="4" />
      <rect className="bank-cell" x="94" y="58" width="42" height="44" rx="4" />
      <text className="tiny-label" x="53" y="84" textAnchor="middle">
        ctx0
      </text>
      <text className="tiny-label" x="115" y="84" textAnchor="middle">
        ctx1
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
