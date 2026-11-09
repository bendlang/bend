#!/usr/bin/env bun
// bend-cache: `bend <file.bend> --check-only` with a proof cache, outside
// bend. A def whose check read nothing that changed since a run it passed
// is skipped; the output is the CLI's, byte for byte.
//
// It loads bend2's own sources and patches them as Bun loads them (the
// way bend-lint does): each edit must match exactly once, or it stops
// with a drift error. Then it runs main.ts's book_read and cli_verdict.
//
// The cache holds traces. While a def is checked, proxies on book.tlds,
// book.ctrs and book.tmps (the only state the checker reads) record the
// first read of each name and what it found; the trace keeps a hash of
// each, and the names the def's elaborated body refers to. A later run
// skips the def at its own event when every read hashes the same, and
// hands the verdict the names it kept. The order of events (a law opaque
// before its fill, unfolding after) is part of what a read finds, so no
// rule about who sees which fill is needed.

import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import * as url from "node:url";

// Options
// =======

const USAGE = "usage: bend-cache <file.bend> [--cache <file.json>] [--bend <bend2 dir>] [--min-ms <ms>] [--stats]";

type Options = { file: string; cache: string; bend: string; min: number; stats: boolean };

function options(args: string[]): Options {
  const here = path.dirname(url.fileURLToPath(import.meta.url));
  const home = process.env.XDG_CACHE_HOME ?? path.join(os.homedir(), ".cache");
  const opts: Options = {
    file: "",
    cache: process.env.BEND_CACHE ?? path.join(home, "bend-cache", "traces.json"),
    bend: process.env.BEND_DIR ?? path.join(here, "..", "..", "..", "bend2"),
    min: 0.2,
    stats: false,
  };
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    const val = (): string => args[++i] ?? fail(a + " needs a value");
    if (a === "--cache") {
      opts.cache = path.resolve(val());
    } else if (a === "--bend") {
      opts.bend = path.resolve(val());
    } else if (a === "--min-ms") {
      opts.min = Number(val());
      if (!(opts.min >= 0)) {
        fail("--min-ms needs a number of ms");
      }
    } else if (a === "--stats") {
      opts.stats = true;
    } else if (a.startsWith("-") || opts.file !== "") {
      fail("unknown argument " + a);
    } else {
      opts.file = a;
    }
  }
  return opts.file === "" ? fail("no file") : opts;
}

function fail(msg: string, code = 1): never {
  process.stderr.write("bend-cache: " + msg + "\n" + (code === 1 ? USAGE + "\n" : ""));
  process.exit(code);
}

// Seam
// ====
// bend.ts: book_valid takes a predicate of the entries to skip, and counts
// the TODOs of skipped entries too (a def whose fill a later file dropped
// is a TODO at its law, which may be skipped).
// main.ts: book_read calls a replaceable validator; book_promises reads the names kept for skipped defs (it reads
// t.e, which a skipped check does not make); the CLI functions exported.

type Patch = { edits: Array<[string, string]>; tail: string };

const PATCHES: Record<string, Patch> = {
  "bend.ts": {
    edits: [
      [
        "export function book_valid(book: Book, done: number = 0): void {\n",
        "export function book_valid(book: Book, done: number | ((i: number) => boolean) = 0): void {\n"
          + "  const skip = typeof done === \"number\" ? (i: number) => i < done : done;\n",
      ],
      [
        "      if (i >= done) {\n        term_check(book, { t: Ref(k), n: 0, def: k, qs: [] }, tld.T",
        "      if (!skip(i)) {\n        term_check(book, { t: Ref(k), n: 0, def: k, qs: [] }, tld.T",
      ],
      [
        "    if (i >= done) {\n      if (fin && tld.v === null && tld.b !== true && !tld.i) {\n        book.hols += 1;\n      }\n",
        "    if (fin && tld.v === null && tld.b !== true && !tld.i) {\n      book.hols += 1;\n    }\n    if (!skip(i)) {\n",
      ],
    ],
    tail: "",
  },
  "main.ts": {
    edits: [
      [
        "    Bend.book_valid(book, base?.order.length ?? 0);\n",
        "    CACHE_HOOK.valid(book, base?.order.length ?? 0);\n",
      ],
      [
        "      if (t.$ === \"Def\" && t.e !== undefined) {\n        term_refs(t.e, rs);\n      }\n",
        "      if (t.$ === \"Def\" && t.e !== undefined) {\n        term_refs(t.e, rs);\n      }\n"
          + "      CACHE_HOOK.refs.get(t)?.forEach((r: string) => rs.add(r));\n",
      ],
    ],
    tail: "\nexport const CACHE_HOOK = {\n"
      + "  valid: (book: Bend.Book, done: number): void => Bend.book_valid(book, done),\n"
      + "  refs: new WeakMap<object, string[]>(),\n"
      + "};\n",
  },
};

// main.ts functions bend-cache calls: the tail exports those it does not
const EXPORTS = ["book_read", "book_err", "cli_verdict", "term_refs", "check"];

// the Book fields the checker reads: a new one would read state the
// traces do not see
const FIELDS = "tlds,ctrs,order,hols,tmps";

type Bend = typeof import("../../../bend2/bend.ts");
type Main = {
  book_read(file: string, base?: unknown, seen?: Map<string, string | null>): Promise<any>;
  book_err(e: unknown): string;
  cli_verdict(book: any, kernel: boolean): number;
  term_refs(t: object, out: Set<string>): void;
  check(): Promise<void>;
  CACHE_HOOK: { valid: (book: any, done: number) => void; refs: WeakMap<object, string[]> };
};

async function load(dir: string): Promise<{ B: Bend; M: Main; ver: string }> {
  const patched = new Map<string, string>();
  for (const [f, p] of Object.entries(PATCHES)) {
    const at = path.join(dir, f);
    if (!fs.existsSync(at)) {
      fail("no bend2 at " + dir + " (give --bend <dir> or BEND_DIR)");
    }
    let src = fs.readFileSync(at, "utf8");
    for (const [from, to] of p.edits) {
      if (src.split(from).length !== 2) {
        fail("drift: bend2/" + f + " changed where bend-cache patches it", 2);
      }
      src = src.split(from).join(to);
    }
    const missing = f !== "main.ts" ? [] : EXPORTS.filter((n) => {
      const decl = (pre: string) => new RegExp("^" + pre + "(?:async function|function|const|let) " + n + "\\b", "m");
      return decl("(?:export )?").test(src) ? !decl("export ").test(src) : fail("drift: bend2/main.ts has no " + n, 2);
    });
    const named = missing.length === 0 ? "" : "export { " + missing.join(", ") + " };\n";
    patched.set(fs.realpathSync(at), src + p.tail + named + "export const BEND_CACHE_PATCH = 1;\n");
  }
  // only this bend2's own files
  const real = fs.realpathSync(dir).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  Bun.plugin({
    name: "bend-cache",
    setup: (build) => {
      build.onLoad({ filter: new RegExp("^" + real + "[\\\\/](bend|main)\\.ts$") }, (args) => {
        const contents = patched.get(fs.realpathSync(args.path));
        return contents === undefined ? fail("drift: matched " + args.path + " but did not patch it", 2) : { contents, loader: "ts" };
      });
    },
  });
  const B: Bend = await import(url.pathToFileURL(path.join(fs.realpathSync(dir), "bend.ts")).href);
  const M: Main = await import(url.pathToFileURL(path.join(fs.realpathSync(dir), "main.ts")).href);
  if ((B as any).BEND_CACHE_PATCH !== 1 || (M as any).BEND_CACHE_PATCH !== 1) {
    fail("drift: bend2 was loaded before bend-cache could patch it", 2);
  }
  if (Object.keys(B.book_nil()).join(",") !== FIELDS) {
    fail("drift: bend2's Book changed (" + Object.keys(B.book_nil()).join(",") + ")", 2);
  }
  // what a trace depends on: the checker, Base, the verdict's refs, this tool
  const srcs = [path.join(dir, "bend.ts"), path.join(dir, "main.ts"), B.BASE_BEND, url.fileURLToPath(import.meta.url)];
  const ver = sha(srcs.map((f) => fs.readFileSync(f, "utf8")).join("\0"));
  return { B, M, ver };
}

function sha(s: string): string {
  return crypto.createHash("sha256").update(s).digest("base64url");
}

// Traces
// ======

// a trace: the hash of each first read ("o" the entry's own declaration,
// "t" a def as the check found it, "c" a constructor, "m" an instance
// memo), and the names the def's elaborated body refers to
type Trace = { d: Array<[string, string]>; r: string[] };
type Store = { ver: string; traces: Record<string, Trace> };

type Stats = { checked: number; skipped: number; kept: number };

function trace_valid(B: Bend, M: Main, opts: Options, ver: string, book: any, st: Stats, made: Array<[string, Trace]>): void {
  const db = read_store(opts.cache, ver).traces;
  // a def's hash: Base's by name (no file redeclares one), the rest lowered
  // without spans; an instance carries no b, so it hashes by its content
  const memo = new WeakMap<object, string>();
  const low = (t: unknown): string => JSON.stringify(t && B.term_lower(t as never), (k, v) => (k === "s" ? undefined : v));
  const hash = (k: string, t: any): string => {
    if (t === undefined) {
      return "-";
    }
    if (t instanceof Map) {
      return sha(JSON.stringify([...t]));
    }
    let h = memo.get(t);
    if (h === undefined) {
      h = t.b === true ? k + ":" + String(t.v === null)
        : sha(JSON.stringify({ ...t, T: low(t.T), v: low(t.v), e: 0, c: t.c?.map((c: any) => [c.k, c.n, low(c.T)]) }));
      memo.set(t, h);
    }
    return h;
  };
  // the tables, and proxies that record what each name held at its first
  // access (a read, or a write: an instance the check mints was absent)
  const tabs: Record<string, any> = { o: book.tlds, t: undefined, c: book.ctrs, m: book.tmps };
  let seen: Map<string, unknown> | null = null;
  const note = (tag: string, o: any, k: string | symbol) => {
    if (seen !== null && typeof k === "string" && !seen.has(tag + k)) {
      seen.set(tag + k, o[k] instanceof Map ? new Map(o[k]) : o[k]);
    }
  };
  const spy = (tag: string, tab: any) => new Proxy(tab, {
    get: (o, k, r) => (note(tag, o, k), Reflect.get(o, k, r)),
    set: (o, k, v, r) => (note(tag, o, k), Reflect.set(o, k, v, r)),
  });
  let live = spy("o", book.tlds);
  Object.defineProperty(book, "tlds", {
    configurable: true,
    get: () => live,
    set: (v) => (live = spy("t", tabs.t = v)),
  });
  book.ctrs = spy("c", book.ctrs);
  book.tmps = spy("m", book.tmps);
  // an entry's key: its name, which of its events, and whether it is the last
  const order: string[] = book.order;
  const occ = new Map<string, number>();
  const fin = new Map(order.map((k, i) => [k, i]));
  const keys = order.map((k, i) => {
    occ.set(k, (occ.get(k) ?? -1) + 1);
    return k + "#" + String(occ.get(k)) + (fin.get(k) === i ? "f" : "");
  });
  // the names a checked def's body refers to, through the instances it
  // minted (an instance of an @unsafe template names the template: it
  // carries the mark)
  const refs = (t: any, out: Set<string>): Set<string> => {
    const rs = new Set<string>();
    M.term_refs(t?.e ?? {}, rs);
    for (const r of rs) {
      if (!out.has(r)) {
        out.add(r);
        if (r.includes("~")) {
          const inst = tabs.t[r];
          refs(inst, inst?.u === true ? out.add(r.slice(0, r.lastIndexOf("~"))) : out);
        }
      }
    }
    return out;
  };
  // only a check slower than --min-ms keeps a trace: a cheap one checks
  // again faster than its trace hashes
  let at = -1;
  let t0 = 0;
  const close = () => {
    if (seen !== null && performance.now() - t0 >= opts.min) {
      const d = [...seen].map(([k, v]): [string, string] => [k, hash(k.slice(1), v)]);
      // an instance's name is the order it was minted in, which a skip
      // changes: keep what it refers to (the walk above), not its name
      const r = [...refs(tabs.o[order[at]], new Set())].filter((x) => !x.includes("~"));
      made.push([keys[at], { d, r }]);
    }
    seen = null;
  };
  // the patched book_valid takes a predicate (its type here is the
  // unpatched one) and asks it once per entry: each ask closes the entry
  // before, minus book_valid's own read of this entry's declaration
  const valid = B.book_valid as (book: unknown, done: number | ((i: number) => boolean)) => void;
  try {
    valid(book, (i: number) => {
      if (at >= 0 && order[at] !== order[i]) {
        seen?.delete("o" + order[i]);
      }
      close();
      const tr = db[keys[i]];
      if (tr !== undefined && tr.d.every(([k, h]) => hash(k.slice(1), tabs[k[0]][k.slice(1)]) === h)) {
        M.CACHE_HOOK.refs.set(tabs.o[order[i]], tr.r);
        st.skipped += 1;
        return true;
      }
      st.checked += 1;
      at = i;
      seen = new Map([["o" + order[i], tabs.o[order[i]]]]);
      t0 = performance.now();
      return false;
    });
    close();
  } finally {
    // a failing def keeps no trace: it is still open
    Object.defineProperty(book, "tlds", { value: tabs.t ?? tabs.o, writable: true, configurable: true, enumerable: true });
    Object.assign(book, { ctrs: tabs.c, tmps: tabs.m });
    st.kept = made.length;
  }
}

// one JSON file per cache; another bend2 version starts it over
function read_store(file: string, ver: string): Store {
  try {
    const s = JSON.parse(fs.readFileSync(file, "utf8")) as Store;
    return s.ver === ver ? s : { ver, traces: {} };
  } catch {
    return { ver, traces: {} };
  }
}

// the traces made, merged into the store as it is now (another run may
// have written since)
function write_store(file: string, ver: string, made: Array<[string, Trace]>): void {
  const store = read_store(file, ver);
  for (const [k, tr] of made) {
    store.traces[k] = tr;
  }
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const tmp = file + "." + String(process.pid);
  fs.writeFileSync(tmp, JSON.stringify(store));
  fs.renameSync(tmp, file);
}

// Main
// ====

async function main(): Promise<void> {
  const opts = options(process.argv.slice(2));
  const { B, M, ver } = await load(opts.bend);
  const st: Stats = { checked: 0, skipped: 0, kept: 0 };
  const made: Array<[string, Trace]> = [];
  M.CACHE_HOOK.valid = (book) => trace_valid(B, M, opts, ver, book, st, made);
  try {
    process.exitCode = M.cli_verdict(await M.book_read(opts.file), false);
  } catch (e) {
    process.stderr.write(M.book_err(e) + "\n");
    process.exitCode = 1;
  }
  // a cache it cannot write costs the next run its skips, not this verdict
  try {
    if (made.length > 0) {
      write_store(opts.cache, ver, made);
    }
  } catch (e) {
    process.stderr.write("bend-cache: cannot write " + opts.cache + ": " + (e instanceof Error ? e.message : String(e)) + "\n");
  }
  await M.check().catch(() => {});
  if (opts.stats) {
    process.stderr.write("bend-cache: checked " + String(st.checked) + ", skipped " + String(st.skipped)
      + ", traces kept " + String(st.kept) + "\n");
  }
}

if (import.meta.main) {
  await main();
}
