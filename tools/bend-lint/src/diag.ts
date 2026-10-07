// Diagnostics: rendering, fixes and LSP positions.

import type { Err } from "../../../bend2/bend.ts";
import { Bend } from "./core.ts";
import { line, starts } from "./spans.ts";
import type { Applicability, Diag, Edit, Fix, Severity, SourceFile, Span } from "./types.ts";

const HEAD: Record<Severity, string> = {
  error: "Error", warning: "Warning", information: "Information", hint: "Hint",
};

export function isErr(e: unknown): e is Err {
  return typeof e === "object" && e !== null && (e as { $?: unknown }).$ === "Err";
}

// bend's own layout; only the head names the severity and the code.
export function render(d: Diag): string {
  const err = isErr(d.core) ? d.core
    : Bend.Err(d.bok ?? Bend.book_nil(), d.ctx ?? Bend.ctx_nil(), d.message, d.obs, d.spn, d.def, d.note);
  return Bend.err_show(err).replace(/^Error:/, HEAD[d.severity] + " [" + d.code + "]:")
    + d.fixes.map(fixShow).join("");
}

// A fix, as a unified diff per file.
export function fixShow(fix: Fix): string {
  let out = "\n\nFix: " + fix.title + " [" + fix.applicability + "]";
  const files = new Map<Span["file"], Edit[]>();
  for (const edit of fix.edits) {
    const edits = files.get(edit.spn.file) ?? [];
    edits.push(edit);
    files.set(edit.spn.file, edits);
  }
  for (const [file, edits] of files) {
    const str = [...edits].sort((a, b) => b.spn.beg - a.spn.beg).reduce(
      (s, { spn, text }) => s.slice(0, spn.beg) + text + s.slice(spn.end), file.str);
    const old = file.str.match(/[^\n]*\n|[^\n]+$/g) ?? [];
    const now = str.match(/[^\n]*\n|[^\n]+$/g) ?? [];
    let beg = 0;
    let end = old.length;
    let tip = now.length;
    while (beg < end && beg < tip && old[beg] === now[beg]) ++beg;
    while (end > beg && tip > beg && old[end - 1] === now[tip - 1]) { --end; --tip; }
    if (beg === end && beg === tip) continue;
    const name = (file as Partial<SourceFile>).path ?? (file.ns || "<input>");
    const range = (e: number) => (e === beg ? beg : beg + 1) + "," + (e - beg);
    const lines = (xs: string[], prefix: string) => xs.map((l) => prefix
      + l.replace(/\r?\n$/, "") + (l.endsWith("\n") ? "" : "\n\\ No newline at end of file"));
    out += "\n--- " + name + "\n+++ " + name + "\n@@ -" + range(end) + " +" + range(tip) + " @@\n"
      + lines(old.slice(beg, end), "-").concat(lines(now.slice(beg, tip), "+")).join("\n");
  }
  return out;
}

// The text of `file` with the fixes of the given levels applied. Edits
// must not overlap.
export function applyFixes(file: SourceFile, diags: Diag[], levels: Applicability[] = ["safe"]): string {
  const edits = diags.flatMap((d) => d.fixes)
    .filter((f) => levels.includes(f.applicability))
    .flatMap((f) => f.edits).filter((e) => e.spn.file === file)
    .sort((a, b) => b.spn.beg - a.spn.beg);
  let out = file.str;
  let wall = out.length + 1;
  for (const { spn, text } of edits) {
    if (spn.beg < 0 || spn.beg > spn.end || spn.end > file.str.length || spn.end > wall || spn.beg >= wall) {
      throw new Error("bend-lint: fixes are out of bounds or overlap");
    }
    out = out.slice(0, spn.beg) + text + out.slice(spn.end);
    wall = spn.beg;
  }
  return out;
}

export type Position = { line: number; character: number };

// LSP range of a span in a file on disk (0-based; UTF-16, as JS strings).
export function position(spn: Span): { start: Position; end: Position } {
  const ss = starts(spn.file.str);
  const at = (off: number): Position => {
    const i = line(ss, off);
    return { line: i, character: off - ss[i] };
  };
  return { start: at(spn.beg), end: at(spn.end) };
}
