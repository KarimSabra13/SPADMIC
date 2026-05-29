export function downloadText(filename: string, text: string, mimeType = "text/plain;charset=utf-8"): void {
  const blob = new Blob([text], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

export function exportElementAsSvg(elementId: string, filename: string): void {
  const element = document.getElementById(elementId);
  if (!element) {
    throw new Error(`Élément introuvable: ${elementId}`);
  }
  const svg = element instanceof SVGElement ? element : element.querySelector("svg");
  if (!svg) {
    throw new Error(`Aucun SVG dans: ${elementId}`);
  }
  const clone = svg.cloneNode(true) as SVGElement;
  clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");
  const text = new XMLSerializer().serializeToString(clone);
  downloadText(filename, text, "image/svg+xml;charset=utf-8");
}

export async function exportElementAsPng(elementId: string, filename: string): Promise<void> {
  const element = document.getElementById(elementId);
  const svg = element instanceof SVGElement ? element : element?.querySelector("svg");
  if (!svg) {
    throw new Error(`Aucun SVG exportable dans: ${elementId}`);
  }
  const serialized = new XMLSerializer().serializeToString(svg);
  const blob = new Blob([serialized], { type: "image/svg+xml;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const image = new Image();
  await new Promise<void>((resolve, reject) => {
    image.onload = () => resolve();
    image.onerror = () => reject(new Error("Conversion PNG impossible dans ce navigateur."));
    image.src = url;
  });
  const canvas = document.createElement("canvas");
  const svgRoot = svg as SVGSVGElement;
  const viewBox = svgRoot.getAttribute("viewBox")?.split(/\s+/).map(Number) ?? [];
  canvas.width = Math.max(1, Math.ceil(viewBox[2] || svgRoot.clientWidth || 1600));
  canvas.height = Math.max(1, Math.ceil(viewBox[3] || svgRoot.clientHeight || 900));
  const context = canvas.getContext("2d");
  if (!context) throw new Error("Canvas non disponible.");
  context.fillStyle = "#f7f8fb";
  context.fillRect(0, 0, canvas.width, canvas.height);
  context.drawImage(image, 0, 0, canvas.width, canvas.height);
  URL.revokeObjectURL(url);
  const pngUrl = canvas.toDataURL("image/png");
  const link = document.createElement("a");
  link.href = pngUrl;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
