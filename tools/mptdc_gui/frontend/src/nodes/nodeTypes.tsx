import type { BlockDescriptor } from "../types";

export interface NodeProps {
  block: BlockDescriptor;
  active: boolean;
  selected: boolean;
  onSelect: (moduleName: string) => void;
}

export function nodeClass(active: boolean, selected: boolean, kind: string): string {
  return `mptdc-node node-${kind}${active ? " is-active" : ""}${selected ? " is-selected" : ""}`;
}

export function Ports({ block }: { block: BlockDescriptor }) {
  return (
    <>
      {block.inputs.slice(0, 3).map((name, index) => (
        <text key={`in-${name}`} className="port-label port-in" x={-8} y={30 + index * 16} textAnchor="end">
          {name}
        </text>
      ))}
      {block.outputs.slice(0, 3).map((name, index) => (
        <text key={`out-${name}`} className="port-label port-out" x={158} y={30 + index * 16}>
          {name}
        </text>
      ))}
    </>
  );
}

export function NodeTitle({ block }: { block: BlockDescriptor }) {
  return (
    <>
      <text className="node-title" x={75} y={30} textAnchor="middle">
        {block.label}
      </text>
      <text className="node-subtitle" x={75} y={48} textAnchor="middle">
        {block.subtitle}
      </text>
    </>
  );
}
