// What bend-lint changes in bend2 as Bun loads it; the files on disk never
// change. In bend.ts, term_infer and term_check are renamed and replaced by
// the wrappers below, which tell a `book.see` hook what they return; and fs
// and path come from this module: bend.ts builds paths with "/"
// (path.posix), so here real paths use "/" and a Windows drive letter is a
// root; on POSIX they behave as node's. comp.ts exports RUNTIME_MAIN and
// js_sat, so a rule written in Bend is compiled once and run many times.
// Each text edit must match exactly once, and each name a tail exports must
// be declared once. The wrappers pass every argument through, so bend
// computes what it would without them; what they record is checked at load
// (see instrument in lint.ts).

import * as nodeFs from "node:fs";
import * as nodePath from "node:path";
import * as url from "node:url";

import type { Book, Ctx, HTerm, LTerm, Name, Quant, Span, Uses } from "bend2/bend.ts";
import type * as BendModule from "bend2/bend.ts";

// Types
// =====

// A file's patch: exact edits, then a tail appended to the file, which may
// export only names the file declares (`needs`).
type Patch = { edits: Array<[string, string]>; tail: string; needs: string[] };

// A book whose checker reports to `see`: for each checked term, what it was
// checked or inferred as, where, and how it was used.
export type Hooked = Book & {
  see?: (bok: Book, tm: LTerm, ty: HTerm, ctx: Ctx, dep: number, def: Name, spn: Span | undefined, qt: Quant, us: Uses) => void;
};

// Constants
// =========

export class DriftError extends Error {
  override name = "DriftError";
}

const HERE = url.fileURLToPath(new URL(".", import.meta.url));
const DRIVE = /^[A-Za-z]:(?=\/)/;
const SHIM = JSON.stringify(url.pathToFileURL(nodePath.join(HERE, "patch.ts")).href);

export const MARK = "BEND_LINT_PATCH";

const PATCHES: Record<string, Patch> = {
  "bend.ts": {
    edits: [
      ['import * as fs from "node:fs";', "import { fs } from " + SHIM + ";"],
      ['import * as path from "node:path";', "import { path } from " + SHIM + ";"],
      ["export function term_infer(", "function unseen_term_infer("],
      ["export function term_check(", "function unseen_term_check("],
    ],
    tail: "import { seeInfer, seeCheck } from " + SHIM + ";\n"
      + "export const term_infer = seeInfer(unseen_term_infer);\n"
      + "export const term_check = seeCheck(unseen_term_check);\n",
    needs: [],
  },
  "comp.ts": { edits: [], tail: "export { RUNTIME_MAIN, js_sat };\n", needs: ["RUNTIME_MAIN", "js_sat"] },
};

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

function slash(p: string): string {
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

// term_infer and term_check as bend.ts calls them: every argument passes
// through, and each result is also reported to book.see. tsc checks the
// names against bend.ts's signatures; a function that no longer takes the
// arguments read here stops loading.
export function seeInfer(f: typeof BendModule.term_infer): typeof BendModule.term_infer {
  arity(f, 6, "term_infer");
  return (...args) => {
    const r = f(...args);
    const [book, lhs, tm, qt, ctx, d] = args;
    (book as Hooked).see?.(book, r.tm, r.ty, ctx, d, lhs.def, tm.s, qt, r.us);
    return r;
  };
}

export function seeCheck(f: typeof BendModule.term_check): typeof BendModule.term_check {
  arity(f, 7, "term_check");
  return (...args) => {
    const r = f(...args);
    const [book, lhs, tm, qt, ty, ctx, d] = args;
    (book as Hooked).see?.(book, r.tm, ty, ctx, d, lhs.def, tm.s, qt, r.us);
    return r;
  };
}

// f.length counts the parameters before the first default.
function arity(f: (...args: never[]) => unknown, n: number, name: string): void {
  if (f.length !== n) {
    throw new DriftError(name + " takes " + f.length + " parameters, not " + n + "; update seeInfer and seeCheck in tools/bend-lint/src/patch.ts");
  }
}

// `file` is "bend.ts" or "comp.ts".
export function patch(file: string, src: string): string {
  const { edits, tail, needs } = PATCHES[file];
  const drift = (what: string, n: number): never => {
    throw new DriftError("cannot patch bend2/" + file + ": found " + n + " of " + what
      + ", expected 1. Update PATCHES in tools/bend-lint/src/patch.ts.");
  };
  const edited = edits.reduce((out, [at, to]) => {
    const n = out.split(at).length - 1;
    return n === 1 ? out.replace(at, () => to) : drift(JSON.stringify(at), n);
  }, src);
  for (const name of needs) {
    const n = edited.match(new RegExp("^(?:export )?(?:function|const|let) " + name + "\\b", "gm"))?.length ?? 0;
    if (n !== 1) drift("a declaration of " + name, n);
  }
  return edited + "\n" + tail + "export const " + MARK + " = 1;\n";
}

// The bend2 folder to load: `given` (from --bend), else $BEND_DIR, else
// the bend repo around tools/bend-lint, if there is one. A bend checkout
// works too, for its bend2 folder.
export function bendDir(given: string | undefined): string {
  const dir = path.resolve(given ?? process.env.BEND_DIR ?? path.join(HERE, "..", "..", "..", "bend2"));
  const found = [path.join(dir, "bend2"), dir].find((d) => nodeFs.existsSync(path.join(d, "bend.ts")));
  if (found === undefined) {
    throw new Error((given ?? process.env.BEND_DIR) === undefined
      ? "no bend found: give a bend checkout with --bend <dir> or BEND_DIR"
      : "no bend2 at " + dir + " (it needs bend.ts); give a bend checkout with --bend <dir> or BEND_DIR");
  }
  return fs.realpathSync(found);
}
