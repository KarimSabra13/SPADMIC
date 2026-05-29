import { NodeTitle, Ports, nodeClass, type NodeProps } from "./nodeTypes";

export default function RingOscillatorNode({ block, active, selected, onSelect }: NodeProps) {
  const taps = Array.from({ length: 8 }, (_, index) => {
    const angle = (Math.PI * 2 * index) / 8;
    return { x: 83 + Math.cos(angle) * 42, y: 68 + Math.sin(angle) * 28, index };
  });
  return (
    <g transform={`translate(${block.x} ${block.y})`} className={nodeClass(active, selected, block.kind)} onClick={() => onSelect(block.module)}>
      <ellipse cx="83" cy="68" rx="60" ry="40" />
      {taps.map((tap) => (
        <g key={tap.index}>
          <circle className="phase-tap" cx={tap.x} cy={tap.y} r="5" />
          <path className="inverter" d={`M${tap.x - 5} ${tap.y - 9} l10 9 l-10 9 z`} />
        </g>
      ))}
      <line className="control-pin" x1="18" y1="68" x2="-10" y2="68" />
      <line className="clock-pin" x1="143" y1="68" x2="174" y2="68" />
      <text className="tiny-label" x="83" y="104" textAnchor="middle">
        phase[7:0]
      </text>
      <NodeTitle block={block} />
      <Ports block={block} />
    </g>
  );
}
