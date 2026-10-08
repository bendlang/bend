// What bend-lint changes in bend2 as Bun loads it; the files on disk never
// change. In bend.ts, term_infer and term_check are renamed and replaced by
// the wrappers below, which tell `hook.see` what they return; and fs and
// path come from this module, in bend.ts and main.ts: bend.ts builds paths
// with "/" (path.posix), so here real paths use "/" and a Windows drive
// letter is a root; on POSIX they behave as node's. comp.ts exports
// RUNTIME_MAIN and js_sat, so a rule written in Bend is compiled once and
// run many times. main.ts exports how `bend` reads a book (book_read) and
// words a failure (book_err, Check_Fail), so bend-lint checks a file
// exactly as bend does.
// Each text edit must match exactly once, and each name a tail exports must
// be declared once. The wrappers pass every argument through, so bend
// computes what it would without them; what they record is checked at load
// (see instrument in lint.ts).

import * as nodeFs from "node:fs";
import * as os from "node:os";
import * as nodePath from "node:path";
import * as url from "node:url";

import type { Book, Ctx, HTerm, LTerm, Name, Quant, Span, Uses } from "bend2/bend.ts";
import type * as BendModule from "bend2/bend.ts";

// Types
// =====

// A file's patch: exact edits, a tail appended to the file, and names it
// must declare once and export (the tail exports those it does not).
type Patch = { edits: Array<[string, string]>; tail: string; exports: string[] };

// What the checker reports for each checked term: what it was checked or
// inferred as, where, and how it was used.
export type See = (bok: Book, tm: LTerm, ty: HTerm, ctx: Ctx, dep: number, def: Name, spn: Span | undefined, qt: Quant, us: Uses) => void;

// An HTTP GET.
export type Get = (url: string) => Promise<Response>;

// How bendDir reaches the network, runs `bend`, where it caches, and where
// the bend repo would be; tests give their own. run gives a command's
// stdout, or undefined if it fails.
export type FindOptions = { get?: Get; run?: (cmd: string[]) => string | undefined; cache?: string; repo?: string };

// Constants
// =========

export class DriftError extends Error {
  override name = "DriftError";
}

const HERE = url.fileURLToPath(new URL(".", import.meta.url));
const DRIVE = /^[A-Za-z]:(?=\/)/;
const SHIM = JSON.stringify(url.pathToFileURL(nodePath.join(HERE, "patch.ts")).href);

export const MARK = "BEND_LINT_PATCH";

const GIT = "https://github.com/bendlang/bend.git/info/refs?service=git-upload-pack";
const RAW = "https://raw.githubusercontent.com/bendlang/bend/";
const RELEASE = /^v\d+\.\d+\.\d+$/;
const DAY = 24 * 60 * 60 * 1000;
const EFF = /^effs\/[\w.-]+$/;

// Downloaded bends, one folder per release.
const CACHE = nodePath.join(process.env.XDG_CACHE_HOME
  ?? (process.platform === "win32" ? process.env.LOCALAPPDATA ?? nodePath.join(os.homedir(), "AppData", "Local") : nodePath.join(os.homedir(), ".cache")),
  "bend-lint");

const SHIMMED: Array<[string, string]> = [
  ['import * as fs from "node:fs";', "import { fs } from " + SHIM + ";"],
  ['import * as path from "node:path";', "import { path } from " + SHIM + ";"],
];

const PATCHES: Record<string, Patch> = {
  "bend.ts": {
    edits: [
      ...SHIMMED,
      ["export function term_infer(", "function unseen_term_infer("],
      ["export function term_check(", "function unseen_term_check("],
    ],
    tail: "import { seeInfer, seeCheck } from " + SHIM + ";\n"
      + "export const term_infer = seeInfer(unseen_term_infer);\n"
      + "export const term_check = seeCheck(unseen_term_check);\n",
    exports: [],
  },
  "comp.ts": { edits: [], tail: "", exports: ["RUNTIME_MAIN", "js_sat"] },
  "main.ts": { edits: SHIMMED, tail: "", exports: ["book_read", "book_err", "Check_Fail"] },
};

// The bend2 files bend-lint patches and imports.
export const PATCHED = Object.keys(PATCHES);

// Where the wrappers report, set by lint.ts for one check at a time.
export const hook: { see?: See } = {};

// Text an editor holds unsaved, by real path, set by lint.ts for one check
// at a time. bend.ts reads it in place of the file on disk.
export const unsaved = new Map<string, string>();

// fs and path for bend.ts.
export const fs = {
  ...nodeFs,
  realpathSync: (p: nodeFs.PathLike): string => slash(nodeFs.realpathSync(p)),
  readFileSync: ((p: nodeFs.PathOrFileDescriptor, ...rest: unknown[]) =>
    held(p) ?? (nodeFs.readFileSync as (...a: unknown[]) => unknown)(p, ...rest)) as typeof nodeFs.readFileSync,
};

export const path = {
  ...nodePath,
  join: (...ps: string[]): string => slash(nodePath.join(...ps)),
  resolve: (...ps: string[]): string => slash(nodePath.resolve(...ps)),
  posix: { ...nodePath.posix, resolve: (...ps: string[]): string => resolve(process.cwd(), ...ps), relative },
};

// Functions
// =========

function held(p: nodeFs.PathOrFileDescriptor): string | undefined {
  return typeof p === "string" && unsaved.size > 0 && nodeFs.existsSync(p) ? unsaved.get(slash(nodeFs.realpathSync(p))) : undefined;
}

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
// through, and each result is also reported to hook.see. tsc checks the
// names against bend.ts's signatures; a function that no longer takes the
// arguments read here stops loading.
export function seeInfer(f: typeof BendModule.term_infer): typeof BendModule.term_infer {
  arity(f, 6, "term_infer");
  return (...args) => {
    const r = f(...args);
    const [book, lhs, tm, qt, ctx, d] = args;
    hook.see?.(book, r.tm, r.ty, ctx, d, lhs.def, tm.s, qt, r.us);
    return r;
  };
}

export function seeCheck(f: typeof BendModule.term_check): typeof BendModule.term_check {
  arity(f, 7, "term_check");
  return (...args) => {
    const r = f(...args);
    const [book, lhs, tm, qt, ty, ctx, d] = args;
    hook.see?.(book, r.tm, ty, ctx, d, lhs.def, tm.s, qt, r.us);
    return r;
  };
}

// f.length counts the parameters before the first default.
function arity(f: (...args: never[]) => unknown, n: number, name: string): void {
  if (f.length !== n) {
    throw new DriftError(name + " takes " + f.length + " parameters, not " + n + "; update seeInfer and seeCheck in tools/bend-lint/src/patch.ts");
  }
}

// `file` is one of PATCHED.
export function patch(file: string, src: string): string {
  const { edits, tail, exports } = PATCHES[file];
  const drift = (what: string, n: number): never => {
    throw new DriftError("cannot patch bend2/" + file + ": found " + n + " of " + what
      + ", expected 1. Update PATCHES in tools/bend-lint/src/patch.ts.");
  };
  const edited = edits.reduce((out, [at, to]) => {
    const n = out.split(at).length - 1;
    return n === 1 ? out.replace(at, () => to) : drift(JSON.stringify(at), n);
  }, src);
  const missing = exports.filter((name) => {
    const n = edited.match(new RegExp("^(?:export )?(?:async function|function|class|const|let) " + name + "\\b", "gm"))?.length ?? 0;
    return n === 1 ? !new RegExp("^export (?:async function|function|class|const|let) " + name + "\\b", "m").test(edited) : drift("a declaration of " + name, n);
  });
  return edited + "\n" + tail + (missing.length === 0 ? "" : "export { " + missing.join(", ") + " };\n")
    + "export const " + MARK + " = 1;\n";
}

// The bend2 folder to load: `given` (from --bend), else $BEND_DIR, else
// the bend repo around tools/bend-lint, if there is one, else a release
// from GitHub: the installed bend's version, or the newest. A bend
// checkout works too, for its bend2 folder.
export async function bendDir(given: string | undefined, { get = download, run = spawn, cache = CACHE, repo }: FindOptions = {}): Promise<string> {
  const chosen = given ?? process.env.BEND_DIR;
  const dir = path.resolve(chosen ?? repo ?? path.join(HERE, "..", "..", "..", "bend2"));
  const found = [path.join(dir, "bend2"), dir].find((d) => nodeFs.existsSync(path.join(d, "bend.ts")));
  if (found !== undefined) {
    return fs.realpathSync(found);
  }
  if (chosen !== undefined) {
    throw new Error("no bend2 at " + dir + " (it needs bend.ts); give a bend checkout with --bend <dir> or BEND_DIR");
  }
  const tag = installedTag(run) ?? await latestTag(cache, get);
  const fresh = !nodeFs.existsSync(nodePath.join(cache, tag, "bend2"));
  const got = await fetchBend(tag, cache, get).catch((e: unknown) => {
    throw new Error("could not download bend " + tag + " (" + (e instanceof Error ? e.message : String(e))
      + "); give a bend checkout with --bend <dir> or BEND_DIR");
  });
  if (fresh) {
    console.error("bend-lint: downloaded bend " + tag + " to " + got);
  }
  return fs.realpathSync(got);
}

// fetch, given up after 30 seconds.
function download(url: string): Promise<Response> {
  return fetch(url, { signal: AbortSignal.timeout(30_000) });
}

// A command's stdout, or undefined if it does not run or fails.
function spawn(cmd: string[]): string | undefined {
  try {
    const r = Bun.spawnSync(cmd, { stdout: "pipe", stderr: "ignore" });
    return r.exitCode === 0 ? r.stdout.toString() : undefined;
  } catch {
    return undefined;
  }
}

// The installed bend's release ("v2.0.36"), or undefined if `bend version`
// does not run.
export function installedTag(run: (cmd: string[]) => string | undefined = spawn): string | undefined {
  const version = run(["bend", "version"])?.match(/^bend (\d+\.\d+\.\d+)\b/)?.[1];
  return version === undefined ? undefined : "v" + version;
}

// The newest release, from git's list of refs (GitHub's API limits calls).
// It asks at most once a day; offline, it takes the newest one cached.
export async function latestTag(cache: string = CACHE, get: Get = download): Promise<string> {
  const note = nodePath.join(cache, "latest.json");
  let known: { tag?: unknown; at?: unknown } | undefined;
  try {
    known = JSON.parse(nodeFs.readFileSync(note, "utf8"));
  } catch {
    known = undefined; // no note yet, or a damaged one
  }
  if (typeof known?.tag === "string" && RELEASE.test(known.tag) && typeof known.at === "number" && Date.now() - known.at < DAY) {
    return known.tag;
  }
  const newest = (tags: string[]): string | undefined => tags.filter((t) => RELEASE.test(t))
    .map((t) => t.slice(1).split(".").map(Number)).sort((a, b) => b[0] - a[0] || b[1] - a[1] || b[2] - a[2])
    .map((v) => "v" + v.join("."))[0];
  const listed = await get(GIT).then((res) => res.ok ? res.text() : Promise.reject(new Error("GitHub answered " + res.status)))
    .then((refs) => newest([...refs.matchAll(/refs\/tags\/(v[\d.]+)$/gm)].map((m) => m[1])), (e: unknown) => {
      const cached = newest(nodeFs.existsSync(cache) ? nodeFs.readdirSync(cache) : []);
      return cached ?? Promise.reject(new Error("cannot list bend's releases (" + (e instanceof Error ? e.message : String(e))
        + "); give a bend checkout with --bend <dir> or BEND_DIR"));
    });
  if (listed === undefined) {
    throw new Error("bend has no release tags; give a bend checkout with --bend <dir> or BEND_DIR");
  }
  nodeFs.mkdirSync(cache, { recursive: true });
  nodeFs.writeFileSync(note, JSON.stringify({ tag: listed, at: Date.now() }));
  return listed;
}

// bend2 at a release: the PATCHED files, safe.ts (main.ts imports it),
// base.bend, and the effs/ files base.bend imports, kept in
// <cache>/<tag>/bend2. A download goes to a temporary folder first, so the
// cache never holds a partial one; a cached folder without main.ts (from an
// older bend-lint) is downloaded again.
export async function fetchBend(tag: string, cache: string = CACHE, get: Get = download): Promise<string> {
  if (!RELEASE.test(tag)) {
    throw new Error("not a bend release: " + tag);
  }
  const dir = nodePath.join(cache, tag, "bend2");
  const whole = (): boolean => [...PATCHED, "safe.ts", "base.bend"].every((f) => nodeFs.existsSync(nodePath.join(dir, f)));
  if (whole()) {
    return dir;
  }
  const text = (file: string): Promise<[string, string]> => get(RAW + tag + "/bend2/" + file)
    .then((res) => res.ok ? res.text() : Promise.reject(new Error("GitHub answered " + res.status + " for bend2/" + file)))
    .then((body) => [file, body]);
  const base = await text("base.bend");
  const effs = [...new Set([...base[1].matchAll(/^\s*import "\.\/(effs\/[^"]+)"/gm)].map((m) => m[1]))];
  const odd = effs.find((f) => !EFF.test(f));
  if (odd !== undefined) {
    throw new Error("base.bend imports " + odd + ", which is not a plain file in effs/");
  }
  const files = [base, ...await Promise.all([...PATCHED, "safe.ts", ...effs].map(text))];
  nodeFs.mkdirSync(nodePath.join(cache, tag), { recursive: true });
  const part = nodeFs.mkdtempSync(nodePath.join(cache, tag, ".part-"));
  files.forEach(([file, body]) => {
    nodeFs.mkdirSync(nodePath.dirname(nodePath.join(part, file)), { recursive: true });
    nodeFs.writeFileSync(nodePath.join(part, file), body);
  });
  try {
    nodeFs.rmSync(dir, { recursive: true, force: true });
    nodeFs.renameSync(part, dir);
  } catch (e) {
    nodeFs.rmSync(part, { recursive: true, force: true });
    if (!whole()) {
      throw e;
    }
  }
  return dir;
}
