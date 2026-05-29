import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function FifoNode({ block, active, selected, onSelect }: NodeProps) {
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <rect x="12" y="10" width="148" height="118" rx="8" />
      {[0, 1, 2, 3, 4].map((slot) => (
        <rect key={slot} className="fifo-slot" x="34" y={48 + slot * 13} width="96" height="9" rx="1" />
      ))}
      <text className="tiny-label" x="84" y="118" textAnchor="middle">
        wr_en / rd_en / full / empty
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
