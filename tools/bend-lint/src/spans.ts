// bend.ts parses a copy of each file with its import lines blanked. The
// lines stay in place, so a span maps to the file on disk by line and
// column. Before a file is mapped, the copy is compared with the file;
// if they do not agree, the tool stops.

import type { Source, Span } from "./types.ts";

export class SpanError extends Error {
  override name = "SpanError";
}

type Loose = { str: string; ns?: string; dir?: string; al?: Record<string, string> };
type Hit = { src: Source; conv(off: number): number };

export function starts(text: string): number[] {
  const out = [0];
  for (let i = 0; i < text.length; i++) {
    if (text.charCodeAt(i) === 10) {
      out.push(i + 1);
    }
  }
  return out;
}

export function line(starts: number[], off: number): number {
  let lo = 0;
  let hi = starts.length - 1;
  while (lo < hi) {
    const mid = (lo + hi + 1) >> 1;
    if (starts[mid] <= off) lo = mid; else hi = mid - 1;
  }
  return lo;
}

export function compatible(masked: string, text: string): boolean {
  if (masked === text) {
    return true;
  }
  const ml = masked.split("\n");
  const ol = text.split("\n");
  return ml.length === ol.length && ml.every((l, i) =>
    l === ol[i] || l.trim() === "" && /^\s*import(\s|$)/.test(ol[i]));
}

export function dirOf(p: string): string {
  return p.slice(0, p.lastIndexOf("/") + 1);
}

export class Spans {
  private hits = new WeakMap<object, Hit>();
  private own = new Set<object>();

  constructor(readonly sources: Source[]) {
    for (const s of sources) {
      this.own.add(s.file);
    }
  }

  map(s: Span | undefined): Span | undefined {
    if (s === undefined) {
      return undefined;
    }
    if (this.own.has(s.file)) {
      return s;
    }
    const hit = this.find(s.file as Loose);
    return { file: hit.src.file, beg: hit.conv(s.beg), end: hit.conv(s.end) };
  }

  private find(f: Loose): Hit {
    const old = this.hits.get(f);
    if (old !== undefined) {
      return old;
    }
    const found = this.sources.filter((src) =>
      (f.ns === undefined || src.ns === undefined || f.ns === src.ns)
      && (f.dir === undefined || f.dir === dirOf(src.path))
      && compatible(f.str, src.text));
    if (found.length !== 1) {
      throw new SpanError("cannot map a bend.ts span to a file on disk (" + found.length
        + " candidates). bend.ts may mask imports another way now; update tools/bend-lint/src/spans.ts.");
    }
    const src = found[0];
    if (f.al !== undefined) {
      Object.assign(src.file.al, f.al);
    }
    const ms = starts(f.str);
    const os = starts(src.text);
    const same = f.str === src.text;
    const hit: Hit = {
      src,
      conv: (off) => {
        if (same) return off;
        const i = line(ms, off);
        return os[i] + (off - ms[i]);
      },
    };
    this.hits.set(f, hit);
    return hit;
  }
}
