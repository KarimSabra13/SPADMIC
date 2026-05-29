import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function MuxNode({ block, active, selected, onSelect }: NodeProps) {
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <polygon points="16,8 130,24 130,96 16,112 46,60" />
      <line className="control-pin" x1="74" y1="118" x2="74" y2="142" />
      <text className="pin-label" x={74} y={154} textAnchor="middle">
        input_sel_i
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
