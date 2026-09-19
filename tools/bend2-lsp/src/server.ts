#!/usr/bin/env node
import { fileURLToPath } from "node:url";
import {
  createConnection, DiagnosticSeverity, MarkupKind, ProposedFeatures, TextDocuments, TextDocumentSyncKind,
  type Diagnostic, type Hover, type InitializeResult, type TextEdit,
} from "vscode-languageserver/node.js";
import { TextDocument } from "vscode-languageserver-textdocument";
import { Analyzer } from "./analysis.js";
import { formatBend } from "./formatter.js";
import { lexicalDiagnostics, staticHover } from "./lexical.js";
import type { AnalysisDiagnostic, AnalysisResult, Overlay } from "./protocol.js";

const connection = createConnection(ProposedFeatures.all);
const documents = new TextDocuments(TextDocument);
const analyzer = new Analyzer();
const timers = new Map<string, NodeJS.Timeout>();
const results = new Map<string, AnalysisResult>();
const imports = new Map<string, Set<string>>();

function supported(document: TextDocument): boolean {
  return document.languageId === "bend" || document.languageId === "bend2";
}

function filePath(uri: string): string | null {
  try { return uri.startsWith("file:") ? fileURLToPath(uri) : null; } catch { return null; }
}

function importUris(document: TextDocument): Set<string> {
  const found = new Set<string>();
  if (!filePath(document.uri)) return found;
  for (const line of document.getText().split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const match = /^import\s+(\S+)\s+as\s+[A-Za-z_][A-Za-z0-9_]*\s*(?:#.*)?$/.exec(trimmed);
    if (match && !/^0x[0-9a-f]+\//.test(match[1])) found.add(new URL(match[1], document.uri).href);
    else if (trimmed !== "import Base") break;
  }
  return found;
}

function dependentsOf(uri: string): Set<string> {
  const result = new Set([uri]);
  let changed = true;
  while (changed) {
    changed = false;
    for (const [candidate, deps] of imports) {
      if (![...deps].some((dep) => result.has(dep)) || result.has(candidate)) continue;
      result.add(candidate);
      changed = true;
    }
  }
  return result;
}

function overlays(): Overlay[] {
  return documents.all().flatMap((document) => {
    const path = filePath(document.uri);
    return path ? [{ uri: document.uri, path, version: document.version, text: document.getText() }] : [];
  });
}

function diagnostic(document: TextDocument, item: Omit<AnalysisDiagnostic, "uri">): Diagnostic {
  return {
    range: { start: document.positionAt(item.range.start), end: document.positionAt(item.range.end) },
    message: item.message, severity: DiagnosticSeverity.Error, source: "bend2", code: item.code,
  };
}

function lexical(document: TextDocument): Diagnostic[] {
  return lexicalDiagnostics(document.getText()).map((item) => diagnostic(document, item));
}

async function analyze(uri: string): Promise<void> {
  const document = documents.get(uri);
  if (!document || !supported(document)) return;
  const version = document.version;
  const path = filePath(uri);
  if (!path) {
    connection.sendDiagnostics({ uri, version, diagnostics: lexical(document) });
    return;
  }
  const result = await analyzer.analyze({ type: "analyze", uri, path, version, text: document.getText(), overlays: overlays() });
  const current = documents.get(uri);
  if (!current || current.version !== result.version) return;
  results.set(uri, result);
  const grouped = new Map<string, AnalysisDiagnostic[]>();
  for (const item of result.diagnostics) grouped.set(item.uri, [...(grouped.get(item.uri) ?? []), item]);
  const targets = new Set([uri, ...grouped.keys()]);
  for (const target of targets) {
    const targetDocument = documents.get(target);
    if (!targetDocument) continue;
    if (result.versions[target] !== undefined && targetDocument.version !== result.versions[target]) continue;
    const compiler = (grouped.get(target) ?? []).map((item) => diagnostic(targetDocument, item));
    const lex = lexical(targetDocument);
    const seen = new Set(lex.map((item) => `${item.code}:${item.range.start.line}:${item.range.start.character}`));
    connection.sendDiagnostics({
      uri: target, version: targetDocument.version,
      diagnostics: [...lex, ...compiler.filter((item) => !seen.has(`${item.code}:${item.range.start.line}:${item.range.start.character}`))],
    });
  }
}

function schedule(uri: string, delay = 250): void {
  const old = timers.get(uri);
  if (old) clearTimeout(old);
  timers.set(uri, setTimeout(() => {
    timers.delete(uri);
    void analyze(uri).catch((error) => connection.console.error(error instanceof Error ? error.stack ?? error.message : String(error)));
  }, delay));
}

connection.onInitialize((): InitializeResult => ({
  capabilities: { textDocumentSync: TextDocumentSyncKind.Full, documentFormattingProvider: true, hoverProvider: true },
  serverInfo: { name: "bend2-lsp", version: "0.1.0" },
}));

connection.onDocumentFormatting((params): TextEdit[] => {
  const document = documents.get(params.textDocument.uri);
  if (!document || !supported(document)) return [];
  const source = document.getText();
  const formatted = formatBend(source, params.options);
  if (formatted === source) return [];
  return [{ range: { start: { line: 0, character: 0 }, end: document.positionAt(source.length) }, newText: formatted }];
});

function tokenAt(document: TextDocument, offset: number): string {
  const source = document.getText();
  for (const token of ["{==}", "<&>", "->", "=>", "==", "!=", "&0", "&1", "&2"]) {
    const start = source.lastIndexOf(token, offset);
    if (start >= 0 && start <= offset && offset <= start + token.length) return token;
  }
  if (source[offset] === "%" || source[offset] === "!") return source[offset];
  let start = offset;
  let end = offset;
  while (start > 0 && /[A-Za-z0-9_./]/.test(source[start - 1])) start--;
  while (end < source.length && /[A-Za-z0-9_./]/.test(source[end])) end++;
  if (start === end && /[%!]/.test(source[offset] ?? source[offset - 1] ?? "")) return source[offset] ?? source[offset - 1];
  return source.slice(start, end);
}

connection.onHover((params): Hover | null => {
  const document = documents.get(params.textDocument.uri);
  if (!document || !supported(document)) return null;
  const token = tokenAt(document, document.offsetAt(params.position));
  const value = staticHover(token) ?? results.get(document.uri)?.hovers[token];
  return value ? { contents: { kind: MarkupKind.Markdown, value } } : null;
});

documents.onDidOpen(({ document }) => {
  if (!supported(document)) return;
  imports.set(document.uri, importUris(document));
  schedule(document.uri, 0);
});
documents.onDidChangeContent(({ document }) => {
  if (!supported(document)) return;
  imports.set(document.uri, importUris(document));
  results.delete(document.uri);
  for (const uri of dependentsOf(document.uri)) schedule(uri);
});
documents.onDidClose(({ document }) => {
  const timer = timers.get(document.uri);
  if (timer) clearTimeout(timer);
  timers.delete(document.uri);
  imports.delete(document.uri);
  results.delete(document.uri);
  connection.sendDiagnostics({ uri: document.uri, diagnostics: [] });
  for (const uri of dependentsOf(document.uri)) if (uri !== document.uri) schedule(uri);
});

connection.onShutdown(async () => { await analyzer.close(); });
documents.listen(connection);
connection.listen();
