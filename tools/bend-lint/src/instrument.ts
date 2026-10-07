// Loads bend2/bend.ts for bend-lint. bend.ts on disk never changes: when
// Bun loads it, two recording wrappers go around term_infer and
// term_check, so typed rules can see what the checker found. If bend.ts
// changes, the tool stops with a clear error instead of giving wrong data.

import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as url from "node:url";

import type * as BendNS from "../../../bend2/bend.ts";
import type { Book, Ctx, HTerm, LTerm, Name, Span } from "../../../bend2/bend.ts";

export type Bend = typeof BendNS;
export type See = (bok: Book, tm: LTerm, ty: HTerm, ctx: Ctx, dep: number, def: Name, spn?: Span) => void;
export type Hooked = Book & { see?: See };

export class PatchError extends Error {
  override name = "PatchError";
}

export const BEND_TS = fs.realpathSync(url.fileURLToPath(new URL("../../../bend2/bend.ts", import.meta.url)));
export const PIN_FILE = url.fileURLToPath(new URL("../bend.pin", import.meta.url));
export const UNPINNED = process.env.BEND_LINT_UNPINNED === "1";

// The hook, `book.see`. If bend.ts ships it one day, the tool uses it and
// does not patch.
const HOOK  = /\bbook\.see\?\.\(/;
const INFER = /^export function term_infer\(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ctx: Ctx, d: number, sp: HTerm\[\] = \[\]\): Infer \{/m;
const CHECK = /^export function term_check\(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ty: HTerm, ctx: Ctx, d: number\): Check \{/m;
const MARK  = "BEND_LINT_PATCH";

const INFER_WRAP = [
  "export function term_infer(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ctx: Ctx, d: number, sp: HTerm[] = []): Infer {",
  "  const inf = lint_infer(book, lhs, tm, qt, ctx, d, sp);",
  "  (book as any).see?.(book, inf.tm, inf.ty, ctx, d, lhs.def, tm.s);",
  "  return inf;",
  "}",
  "function lint_infer(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ctx: Ctx, d: number, sp: HTerm[]): Infer {",
].join("\n");

const CHECK_WRAP = [
  "export function term_check(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ty: HTerm, ctx: Ctx, d: number): Check {",
  "  const chk = lint_check(book, lhs, tm, qt, ty, ctx, d);",
  "  (book as any).see?.(book, chk.tm, ty, ctx, d, lhs.def, tm.s);",
  "  return chk;",
  "}",
  "function lint_check(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ty: HTerm, ctx: Ctx, d: number): Check {",
].join("\n");

// The git blob hash of a text file, as `git rev-parse HEAD:<file>` prints
// it (CRLF read as LF, as git stores it with core.autocrlf).
export function blob(text: string): string {
  const buf = Buffer.from(text.replace(/\r\n/g, "\n"), "utf8");
  return crypto.createHash("sha1").update("blob " + buf.length + "\0").update(buf).digest("hex");
}

export function pinned(): string {
  return fs.readFileSync(PIN_FILE, "utf8").trim();
}

export function current(): string {
  return blob(fs.readFileSync(BEND_TS, "utf8"));
}

export function pin(): string {
  const hash = current();
  fs.writeFileSync(PIN_FILE, hash + "\n");
  return hash;
}

export function checkPin(): void {
  const now = current();
  const want = pinned();
  if (now !== want && !UNPINNED) {
    throw new PatchError("bend2/bend.ts is " + now + ", but bend-lint is pinned to " + want + ".\n"
      + "To bump: BEND_LINT_UNPINNED=1 bun test tools/bend-lint, then bun tools/bend-lint/src/cli.ts --pin");
  }
}

export function patch(src: string): string {
  for (const [re, name] of [[INFER, "term_infer"], [CHECK, "term_check"]] as const) {
    const n = src.match(new RegExp(re.source, "gm"))?.length ?? 0;
    if (n !== 1) {
      throw new PatchError("cannot instrument bend2/bend.ts: found " + n + " " + name
        + " signatures, expected 1. bend.ts changed; update tools/bend-lint/src/instrument.ts.");
    }
  }
  if (/\b(lint_infer|lint_check|BEND_LINT_PATCH)\b/.test(src)) {
    throw new PatchError("cannot instrument bend2/bend.ts: it already defines a bend-lint name.");
  }
  return src.replace(INFER, () => INFER_WRAP).replace(CHECK, () => CHECK_WRAP)
    + "\nexport const " + MARK + " = 1;\n";
}

let loaded: Promise<Bend> | undefined;

export function loadBend(): Promise<Bend> {
  return loaded ??= load();
}

async function load(): Promise<Bend> {
  checkPin();
  const src = fs.readFileSync(BEND_TS, "utf8");
  const upstream = HOOK.test(src);
  if (!upstream) {
    if (typeof Bun === "undefined") {
      throw new PatchError("bend-lint runs on Bun: bun tools/bend-lint/src/cli.ts");
    }
    const out = patch(src);
    Bun.plugin({
      name: "bend-lint",
      setup(build) {
        build.onLoad({ filter: /[\\/]bend2[\\/]bend\.ts$/ }, () => ({ contents: out, loader: "ts" }));
      },
    });
  }
  const mod = await import(url.pathToFileURL(BEND_TS).href) as Bend & { [MARK]?: number };
  if (!upstream && mod[MARK] !== 1) {
    throw new PatchError("bend2/bend.ts was loaded before bend-lint could instrument it. "
      + "Import bend-lint before any module that imports bend.ts.");
  }
  return mod;
}

const SAMPLE = "type N is Data:\n  Z{}\n\ndef id(x: N) -> N:\n  x\n";
let checked = false;

// Checks a tiny program and requires the type of `x` in `id` to be N.
export function selfCheck(B: Bend): void {
  if (checked) {
    return;
  }
  const book = B.book_nil() as Hooked;
  const seen: Array<{ bok: Book; tm: LTerm; ty: HTerm; def: Name }> = [];
  book.see = (bok, tm, ty, _ctx, _dep, def) => { seen.push({ bok, tm, ty, def }); };
  B.parse_book(book, "/", SAMPLE, "", Object.create(null));
  B.book_valid(book);
  const ok = seen.some((f) => f.def === "id" && B.term_strip(f.tm).$ === "Var"
    && (B.term_wnf(f.bok, f.ty) as { k?: string }).k === "N");
  if (!ok) {
    throw new PatchError("self-check failed: bend.ts was instrumented but recorded no type for `id`. "
      + "The checker changed; update tools/bend-lint/src/instrument.ts.");
  }
  checked = true;
}
