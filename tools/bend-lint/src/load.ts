// Loads and checks a book as bend2/main.ts book_read does, and records
// the checker's results when asked.

import * as fs from "node:fs";
import * as path from "node:path";

import { Bend } from "./core.ts";
import { isErr } from "./diag.ts";
import type { Hooked } from "./instrument.ts";
import { Spans } from "./spans.ts";
import type { Book, Diag, Fact, LTerm, Source, Span } from "./types.ts";

export type Loaded = {
  book: Book;
  sources: Source[];
  spans: Spans;
  facts?: Map<LTerm, Fact>;
  failed: boolean;
  failure?: unknown;
};

export async function loadBook(file: string, capture: boolean, signal: AbortSignal): Promise<Loaded> {
  const book = Bend.book_nil() as Hooked;
  const seen = new Map<string, string | null>();
  const facts = capture ? new Map<LTerm, Fact>() : undefined;
  let spans: Spans | undefined;
  if (facts !== undefined) {
    book.see = (bok, tm, ty, ctx, dep, def, raw) => {
      let memo: Span | undefined | null = null;
      facts.set(tm, {
        tm, ty, bok, ctx, dep, def, raw,
        get spn() {
          if (memo === null) memo = spans!.map(raw);
          return memo;
        },
      });
    };
  }
  let failed = false;
  let failure: unknown;
  try {
    signal.throwIfAborted();
    await Bend.book_load(book, file, "", seen);
    signal.throwIfAborted();
    const laws = path.join(path.dirname(file), "LAWS.bend");
    if (path.basename(file) === "PROOF.bend" && fs.existsSync(laws)
      && !seen.has(fs.realpathSync(laws))) {
      throw "Error: PROOF.bend must import ./LAWS.bend";
    }
    Bend.book_valid(book, 0);
    if (book.hols > 0) {
      throw "Error: " + String(book.hols) + " TODO" + (book.hols === 1 ? "" : "s")
        + " found.\nThe code is incomplete, and not a valid proof yet.";
    }
  } catch (e) {
    if (signal.aborted) {
      throw signal.reason;
    }
    failed = true;
    failure = e;
  }
  const root = seen.keys().next().value;
  const sources: Source[] = [];
  for (const [real, ns] of seen) {
    let text: string;
    try {
      text = fs.readFileSync(real, "utf8");
    } catch {
      continue;
    }
    sources.push({
      path: real, ns: ns ?? undefined, text, root: real === root, base: real === Bend.BASE_BEND,
      file: { str: text, ns: ns ?? "", al: Object.create(null), path: real },
    });
  }
  spans = new Spans(sources);
  return { book, sources, spans, facts, failed, failure };
}

// bend's own failure, as a diagnostic.
export function coreDiag(e: unknown, spans: Spans): Diag {
  if (isErr(e)) {
    let spn: Span | undefined;
    try {
      spn = spans.map(e.spn);
    } catch {
      spn = undefined;
    }
    const message = typeof e.exp === "string" ? e.exp : Bend.expr_show(e.bok, e.exp);
    return { code: "bend/check", severity: "error", message, spn, def: e.def, fixes: [], core: e };
  }
  const message = e instanceof RangeError
    ? "the machine stack overflowed (a deep recursion, or a literal too large to expand)"
    : String(e).replace(/^Error:\s*/, "");
  return { code: "bend/check", severity: "error", message, fixes: [] };
}
