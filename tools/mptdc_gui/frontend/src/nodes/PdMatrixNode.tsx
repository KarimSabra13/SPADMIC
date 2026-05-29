import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function PdMatrixNode({ block, active, selected, onSelect }: NodeProps) {
  const cells = Array.from({ length: 64 }, (_, cell) => ({ ns: Math.floor(cell / 8), nf: cell % 8, cell }));
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <rect x="4" y="4" width="174" height="150" rx="10" />
      <text className="node-title" x="88" y="24" textAnchor="middle">
        {block.label}
      </text>
      <text className="node-subtitle" x="88" y="40" textAnchor="middle">
        64 cellules PD
      </text>
      <g transform="translate(32 52)">
        {cells.map((entry) => (
          <rect
            key={entry.cell}
            className={`pd-mini-cell ${(entry.ns + entry.nf) % 5 === 0 ? "pd-diagonal" : ""}`}
            x={entry.nf * 13}
            y={entry.ns * 10}
            width="10"
            height="8"
            rx="1"
          />
        ))}
      </g>
      <text className="tiny-label" x="88" y="142" textAnchor="middle">
        CELL = ns * NE + nf
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
