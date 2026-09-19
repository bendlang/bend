import { parentPort } from "node:worker_threads";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { pathToFileURL } from "node:url";
import {
  book_load,
  book_nil,
  book_valid,
  err_show,
  term_lower,
  term_show,
  type Book,
  type Err,
} from "../../../bend2/bend.js";
import type { AnalysisDiagnostic, AnalysisRequest, AnalysisResult, Overlay } from "./protocol.js";

const nativeFetch = globalThis.fetch;
globalThis.fetch = (input, init = {}) => nativeFetch(input, { ...init, signal: init.signal ?? AbortSignal.timeout(10_000) });

const mirrorRoot = path.join(os.tmpdir(), `bend2-lsp-${process.pid}`);

function key(file: string): string {
  return path.resolve(file).replaceAll("\\", "/").toLowerCase();
}

function compilerPath(file: string): string {
  return file.replaceAll("\\", "/");
}

function mirrorPath(file: string, runRoot: string): string {
  const absolute = path.resolve(file);
  const root = path.parse(absolute).root;
  const volume = root.replace(/[^A-Za-z0-9]/g, "") || "root";
  return path.join(runRoot, volume, absolute.slice(root.length));
}

type Source = { original: string; staged: string; uri: string; text: string; namespace: string };

function imports(text: string): Array<{ relative: string; alias: string }> {
  const found: Array<{ relative: string; alias: string }> = [];
  for (const line of text.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const match = /^import\s+(\S+)\s+as\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:#.*)?$/.exec(trimmed);
    if (match) found.push({ relative: match[1], alias: match[2] });
    else if (trimmed !== "import Base") break;
  }
  return found;
}

function compilerSource(text: string): string {
  const lines = text.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line || line.startsWith("#")) continue;
    if (/^import(?:\s|$)/.test(line)) lines[i] = "";
    else break;
  }
  return lines.join("\n");
}

function stageGraph(root: string, overlays: Overlay[], runRoot: string): { entry: string; sources: Source[]; aliases: Map<string, string> } {
  const overlay = new Map(overlays.map((item) => [key(item.path), item]));
  const sources: Source[] = [];
  const aliases = new Map<string, string>();
  const seen = new Set<string>();
  function stage(file: string, namespace: string, rootAliases: boolean): void {
    const id = key(file);
    if (seen.has(id)) return;
    seen.add(id);
    const open = overlay.get(id);
    if (!open && !fs.existsSync(file)) return;
    const text = open?.text ?? fs.readFileSync(file, "utf8");
    const staged = mirrorPath(file, runRoot);
    fs.mkdirSync(path.dirname(staged), { recursive: true });
    fs.writeFileSync(staged, text);
    sources.push({ original: file, staged, uri: open?.uri ?? pathToFileURL(file).href, text, namespace });
    for (const imported of imports(text)) {
      if (/^0x[0-9a-f]+\//.test(imported.relative) || path.isAbsolute(imported.relative)) continue;
      const child = path.resolve(path.dirname(file), imported.relative);
      const childNs = path.posix.join(path.posix.dirname(namespace), imported.relative.replaceAll("\\", "/")).replace(/\.bend$/, "");
      if (rootAliases) aliases.set(imported.alias, childNs);
      stage(child, childNs, false);
    }
  }
  stage(root, "", true);
  return { entry: mirrorPath(root, runRoot), sources, aliases };
}

function offsetRange(source: string, beg: number, end: number): { start: number; end: number } {
  const start = Math.max(0, Math.min(source.length, beg));
  return { start, end: Math.max(start, Math.min(source.length, end)) };
}

function errorCode(error: Err, checking: boolean): AnalysisDiagnostic["code"] {
  const expected = typeof error.exp === "string" ? error.exp : "";
  if (/import|file|hash|namespace|cycle|BEND_HUB/i.test(expected)) return "imports";
  return checking ? "checking" : "parsing";
}

function errorMessage(error: Err): string {
  const shown = err_show(error);
  return shown.replace(/\nLocation:[\s\S]*$/, "").trim();
}

function sourceForSpan(sources: Source[], spanSource: string | undefined, fallback: Source): Source {
  return sources.find((source) => source.text === spanSource || compilerSource(source.text) === spanSource) ?? fallback;
}

function originalOffset(source: Source, spanSource: string | undefined, offset: number): number {
  if (spanSource === undefined || spanSource === source.text) return offset;
  const before = spanSource.slice(0, offset);
  const line = before.split("\n").length - 1;
  const column = offset - before.lastIndexOf("\n") - 1;
  const lines = source.text.split("\n");
  let result = 0;
  for (let i = 0; i < line; i++) result += (lines[i]?.length ?? 0) + 1;
  return result + column;
}

function declarationKinds(sources: Source[]): Map<string, string> {
  const kinds = new Map<string, string>();
  for (const source of sources) {
    for (const match of source.text.matchAll(/^\s*(def|law|type)\s+([A-Za-z_][A-Za-z0-9_.]*)/gm)) {
      kinds.set(source.namespace ? `${source.namespace}.${match[2]}` : match[2], match[1]);
    }
  }
  return kinds;
}

function renderHovers(book: Book, sources: Source[], aliases: Map<string, string>): Record<string, string> {
  const result: Record<string, string> = Object.create(null) as Record<string, string>;
  const kinds = declarationKinds(sources);
  for (const [name, tld] of Object.entries(book.tlds)) {
    const kind = tld.$ === "ADT" ? "type" : (kinds.get(name) ?? "def");
    const signature = term_show(term_lower(tld.T));
    const hover = `**${kind} ${name}**\n\n\`\`\`bend\n${name} : ${signature}\n\`\`\``;
    result[name] = hover;
    const leaf = name.split(/[/.]/).at(-1)!;
    if (!(leaf in result)) result[leaf] = hover;
    for (const [alias, namespace] of aliases) {
      if (name.startsWith(namespace + ".")) result[`${alias}.${name.slice(namespace.length + 1)}`] = hover;
    }
  }
  for (const [name, constructor] of Object.entries(book.ctrs)) {
    const signature = term_show(term_lower(constructor.T));
    const hover = `**constructor ${name}**\n\n\`\`\`bend\n${name} : ${signature}\n\`\`\``;
    result[name] = hover;
    for (const [alias, namespace] of aliases) {
      if (name.startsWith(namespace + ".")) result[`${alias}.${name.slice(namespace.length + 1)}`] = hover;
    }
  }
  return result;
}

function firstMarker(book: Book, sources: Source[]): AnalysisDiagnostic | null {
  if (book.hols > 0) {
    for (const source of sources) {
      const match = /\?[A-Za-z_][A-Za-z0-9_]*/.exec(source.text);
      if (match) return { uri: source.uri, range: { start: match.index, end: match.index + match[0].length }, message: `Unresolved hole '${match[0]}'.`, code: "holes" };
    }
  }
  if (book.open > 0) {
    for (const source of sources) {
      const match = /^\s*law\s+([A-Za-z_][A-Za-z0-9_.]*)/m.exec(source.text);
      if (match) {
        const start = match.index + match[0].lastIndexOf(match[1]);
        return { uri: source.uri, range: { start, end: start + match[1].length }, message: `Law '${match[1]}' has no proof.`, code: "incomplete-law" };
      }
    }
  }
  return null;
}

async function analyze(request: AnalysisRequest): Promise<AnalysisResult> {
  const runRoot = path.join(mirrorRoot, String(request.id));
  const staged = stageGraph(request.path, request.overlays, runRoot);
  const root = staged.sources.find((source) => key(source.original) === key(request.path))!;
  const book = book_nil();
  let checking = false;
  let diagnostics: AnalysisDiagnostic[] = [];
  try {
    const done = await book_load(book, compilerPath(staged.entry), "", new Map());
    checking = true;
    book_valid(book, done);
    const marker = firstMarker(book, staged.sources);
    if (marker) diagnostics = [marker];
  } catch (caught) {
    const error = caught as Partial<Err>;
    if (error.$ === "Err" && error.bok && error.ctx && error.exp !== undefined) {
      const typed = error as Err;
      const source = sourceForSpan(staged.sources, typed.spn?.src, root);
      const beg = originalOffset(source, typed.spn?.src, typed.spn?.beg ?? 0);
      const end = originalOffset(source, typed.spn?.src, typed.spn?.end ?? 0);
      diagnostics = [{
        uri: source.uri,
        range: offsetRange(source.text, beg, end),
        message: errorMessage(typed),
        code: errorCode(typed, checking),
      }];
    } else {
      diagnostics = [{ uri: request.uri, range: { start: 0, end: 0 }, message: caught instanceof Error ? caught.message : String(caught), code: checking ? "checking" : "imports" }];
    }
  }
  const versions = Object.fromEntries(request.overlays.map((overlay) => [overlay.uri, overlay.version]));
  const result = { id: request.id, uri: request.uri, version: request.version, versions, diagnostics, hovers: renderHovers(book, staged.sources, staged.aliases) };
  fs.rmSync(runRoot, { recursive: true, force: true });
  return result;
}

parentPort?.on("message", (request: AnalysisRequest) => {
  if (request.type === "analyze") void analyze(request).then((result) => parentPort?.postMessage(result));
});
