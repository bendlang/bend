// The two changes bend-lint makes to bend2/bend.ts as Bun loads it; the
// file on disk never changes. One wraps term_infer and term_check so a
// `book.see` hook records what they return. The other gives bend.ts this
// module's fs and path: bend.ts builds paths with "/" (path.posix), so here
// real paths use "/" and a Windows drive letter counts as a root. On POSIX
// they behave as node's. bend.pin holds the bend.ts these were tested on.

import * as crypto from "node:crypto";
import * as nodeFs from "node:fs";
import * as nodePath from "node:path";
import * as url from "node:url";

// Constants
// =========

export class DriftError extends Error {
  override name = "DriftError";
}

const HERE = url.fileURLToPath(new URL(".", import.meta.url));
const DRIVE = /^[A-Za-z]:(?=\/)/;
const SHIM = JSON.stringify(url.pathToFileURL(nodePath.join(HERE, "patch.ts")).href);

export const MARK = "BEND_LINT_PATCH";
export const PIN_FILE = nodePath.join(HERE, "..", "bend.pin");

const PATCHES = [
  {
    name: "the node:fs import",
    at: /^import \* as fs from "node:fs";/m,
    to: "import { fs } from " + SHIM + ";",
  },
  {
    name: "the node:path import",
    at: /^import \* as path from "node:path";/m,
    to: "import { path } from " + SHIM + ";",
  },
  {
    name: "term_infer",
    at: /^export function term_infer\(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ctx: Ctx, d: number, sp: HTerm\[\] = \[\]\): Infer \{/m,
    to: [
      "export function term_infer(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ctx: Ctx, d: number, sp: HTerm[] = []): Infer {",
      "  const inf = lint_infer(book, lhs, tm, qt, ctx, d, sp);",
      "  (book as any).see?.(book, inf.tm, inf.ty, ctx, d, lhs.def, tm.s);",
      "  return inf;",
      "}",
      "function lint_infer(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ctx: Ctx, d: number, sp: HTerm[]): Infer {",
    ].join("\n"),
  },
  {
    name: "term_check",
    at: /^export function term_check\(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ty: HTerm, ctx: Ctx, d: number\): Check \{/m,
    to: [
      "export function term_check(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ty: HTerm, ctx: Ctx, d: number): Check {",
      "  const chk = lint_check(book, lhs, tm, qt, ty, ctx, d);",
      "  (book as any).see?.(book, chk.tm, ty, ctx, d, lhs.def, tm.s);",
      "  return chk;",
      "}",
      "function lint_check(book: Book, lhs: LHS, tm: HTerm, qt: Quant, ty: HTerm, ctx: Ctx, d: number): Check {",
    ].join("\n"),
  },
];

// fs and path for bend.ts.
export const fs = { ...nodeFs, realpathSync: (p: nodeFs.PathLike): string => slash(nodeFs.realpathSync(p)) };

export const path = {
  ...nodePath,
  join: (...ps: string[]): string => slash(nodePath.join(...ps)),
  resolve: (...ps: string[]): string => slash(nodePath.resolve(...ps)),
  posix: { ...nodePath.posix, resolve: (...ps: string[]): string => resolve(process.cwd(), ...ps), relative },
};

// Functions
// =========

export function slash(p: string): string {
  return p.split(nodePath.sep).join("/");
}

// path.posix.resolve from `cwd`, where a drive letter is a root.
export function resolve(cwd: string, ...ps: string[]): string {
  const all = [cwd, ...ps].map(slash);
  const drive = all.filter((p) => DRIVE.test(p)).at(-1)?.slice(0, 2) ?? "";
  return drive + nodePath.posix.resolve(...all.map((p) => p.replace(DRIVE, "")));
}

export function relative(from: string, to: string): string {
  return nodePath.posix.relative(slash(from).replace(DRIVE, ""), slash(to).replace(DRIVE, ""));
}

export function patch(src: string): string {
  return PATCHES.reduce((out, { name, at, to }) => {
    const n = out.match(new RegExp(at.source, "gm"))?.length ?? 0;
    if (n !== 1) {
      throw new DriftError("cannot patch bend2/bend.ts: found " + n + " of " + name
        + ", expected 1. Update PATCHES in tools/bend-lint/src/patch.ts.");
    }
    return out.replace(at, () => to);
  }, src) + "\nexport const " + MARK + " = 1;\n";
}

// The git blob hash of a text, as `git rev-parse HEAD:<file>` prints it
// (CRLF counts as LF, as git stores it).
export function blob(text: string): string {
  const buf = Buffer.from(text.replace(/\r\n/g, "\n"), "utf8");
  return crypto.createHash("sha1").update("blob " + buf.length + "\0").update(buf).digest("hex");
}

export function pinned(): string {
  return nodeFs.readFileSync(PIN_FILE, "utf8").trim();
}

export function current(): string {
  return blob(nodeFs.readFileSync(BEND_TS, "utf8"));
}

// Side effects
// ============

export const BEND_TS = fs.realpathSync(path.join(HERE, "..", "..", "..", "bend2", "bend.ts"));

