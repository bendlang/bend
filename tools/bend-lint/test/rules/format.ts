// One space after a comma and on each side of an assignment. Quoted
// literals, comments and compound operators stay whole; only gaps change.

import type { Edit, LintRule, SourceFile } from "../../src/index.ts";

type Token = { text: string; beg: number; end: number };

export function tokens(source: string): Token[] {
  const pattern = /#[^\r\n]*|"(?:\\[\s\S]|[^"\\])*"|'(?:\\[\s\S]|[^'\\])*'|==|=>|!=|<=|>=|[^\s]/g;
  return [...source.matchAll(pattern)].map((m) => ({ text: m[0], beg: m.index!, end: m.index! + m[0].length }));
}

function gapEdit(file: SourceFile, left?: Token, right?: Token): Edit | undefined {
  if (left === undefined || right === undefined || right.text.startsWith("#")) return;
  const gap = file.str.slice(left.end, right.beg);
  if (!/^[ \t]*$/.test(gap) || gap === " ") return;
  return { spn: { file, beg: left.end, end: right.beg }, text: " " };
}

export function spacingEdits(file: SourceFile): Edit[] {
  const stream = tokens(file.str);
  const edits: Array<Edit | undefined> = [];
  for (let i = 0; i < stream.length; i++) {
    const token = stream[i];
    if (token.text === "=") edits.push(gapEdit(file, stream[i - 1], token));
    if (token.text === "=" || token.text === ",") {
      const next = stream[i + 1];
      if (next !== undefined && !["}", ")", "]"].includes(next.text)) edits.push(gapEdit(file, token, next));
    }
  }
  return edits.filter((e): e is Edit => e !== undefined);
}

// Formats the file that was linted; imports are formatted when linted
// themselves.
export const spacing: LintRule = {
  id: "format/spacing",
  run(cx, signal) {
    signal.throwIfAborted();
    return spacingEdits(cx.root.file).map((edit) => cx.diag({
      message: "Use one space after a comma and on each side of an assignment.",
      severity: "hint",
      spn: edit.spn,
      fixes: [{ title: "Normalize spacing", applicability: "safe", edits: [edit] }],
    }));
  },
};

export default [spacing];
