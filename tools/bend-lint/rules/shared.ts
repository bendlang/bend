// Helpers for the rules in this folder that are written in TypeScript.

import type { SourceFile } from "../src/lint.ts";

// Types
// =====

// A line of a file: its text without the line break (nor a \r before it),
// and the offsets where that text begins and ends.
export type Line = { text: string; beg: number; end: number };

// Functions
// =========

export function lines(file: SourceFile): Line[] {
  return file.str.split("\n").reduce<{ at: number; out: Line[] }>(({ at, out }, raw) => {
    const text = raw.endsWith("\r") ? raw.slice(0, -1) : raw;
    return { at: at + raw.length + 1, out: [...out, { text, beg: at, end: at + text.length }] };
  }, { at: 0, out: [] }).out;
}
