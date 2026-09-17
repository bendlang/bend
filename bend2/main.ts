#!/usr/bin/env bun
// Run, this file is the CLI. Imported, it is the loader that makes `import
// Game from "./x.bend"` work: a bun plugin (preload it in bunfig.toml, list
// it under [serve.static] plugins, or hand it to Bun.build) and a node hook
// (node --import). A .bend module exports every filled, non-base, non-IO
// def, wrapped so a JS caller passes the live arguments, in one call or
// curried, and gets a plain value back: a constructor is {$: "Name", field:
// value, ...}, a closure is a function, Nat is BigInt, Bool, String and U32
// are native. A page bundles through Bun.build with the loader on, since
// the bun build CLI takes no plugins.

import * as child from "node:child_process";
import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as mod from "node:module";
import * as os from "node:os";
import * as path from "node:path";
import * as url from "node:url";
import * as thr from "node:worker_threads";

import type { BunPlugin } from "bun";

import * as Bend from "./bend.ts";
import * as Comp from "./comp.ts";

// Main
// ====

// Constants
// =========

const VERSION = "2.0.4";

const HELP = `Bend ${VERSION}: check, run, build and publish Bend programs.

usage:
  bend <file.bend>            check the file, then run main
  bend <file.bend> -o <out>   build a binary; <out>.c emits C, <out>.js JS
  bend <file.bend> --checkup  check and run each import alone
  bend <file.bend> --publish  publish the file and its imports to the hub
  bend <page.html> -o <dir>   bundle a page that imports .bend files
  bend base [--types|<name>]  print Base, its types, or a name and its subnames
  bend guide                  print the Bend guide
  bend --version              print the version

Read the guide (\`bend guide\`) before writing Bend code.
`;


const BASE = fs.realpathSync(path.join(import.meta.dirname, "base.bend"));

const GUIDE = path.join(import.meta.dirname, "..", "guide", "GUIDE.md");

// A package's proof of work is a nonce whose sha256(hash + " " + nonce)
// opens (its top 53 bits) with a number under 2^53 / work, where work is
// POW hashes (two seconds of an M4 Max's sixteen cores) per 256 KiB of
// package, and no less. Every core mines; the hub checks it with one hash.
const POW = 140000000;

const POW_JS = `
const crypto = require("node:crypto");
const { parentPort, workerData: { pre, lim, from, step } }
  = require("node:worker_threads");
for (let n = from;; n += step) {
  const h = crypto.hash("sha256", pre + n, "buffer");
  if ((h[0] * 16777216 + (h[1] << 16) + (h[2] << 8) + h[3]) * 2097152
    + ((h[4] * 16777216 + (h[5] << 16) + (h[6] << 8) + h[7]) >>> 11) < lim) {
    parentPort.postMessage(n);
    break;
  }
}`;

const PLUGIN: BunPlugin = {
  name: "bend",
  setup(build) {
    build.onLoad({ filter: /\.bend$/ }, async (args) =>
      ({ contents: await load_js(args.path), loader: "js" }));
  },
};

// CLI
// ===

async function cli(): Promise<void> {
  const args = process.argv.slice(2);
  if (args[0] === "--version" && args.length === 1) {
    return cli_say(1, "bend " + VERSION + "\n");
  }
  if (args[0] === "guide" && args.length === 1) {
    return cli_say(1, fs.readFileSync(GUIDE, "utf8"));
  }
  if (args[0] === "base" && args.length <= 2) {
    return cli_base(args[1]);
  }
  const outs: string[] = [];
  let file: string | undefined;
  let checkup = false;
  let publish = false;
  for (let i = 0; i < args.length; i += 1) {
    const a = args[i];
    if (a === "--help" || a === "-h") {
      cli_say(1, HELP);
      process.exit(0);
    } else if (a === "--checkup") {
      checkup = true;
    } else if (a === "--publish") {
      publish = true;
    } else if (a === "-o") {
      i += 1;
      outs.push(args[i] ?? cli_fail("-o needs an output file"));
    } else if (a.startsWith("-") || file !== undefined) {
      cli_fail(a.startsWith("-") ? "unknown option " + a
        : "too many arguments");
    } else {
      file = a;
    }
  }
  if (file === undefined) {
    cli_say(1, HELP);
    process.exit(1);
  }
  if (file.endsWith(".html")) {
    if (outs.length !== 1 || checkup || publish) {
      cli_fail("a page bundles with -o <dir>");
    }
    return cli_bundle(file, outs[0]);
  }
  if (publish && (outs.length !== 0 || checkup)) {
    cli_fail("--publish takes no other option");
  }
  if (checkup && outs.length !== 0) {
    cli_fail("--checkup takes no -o: a binary holds one main, so build each"
      + " import alone");
  }
  try {
    if (publish) {
      return await cli_publish(file);
    }
    if (checkup) {
      return await cli_checkup(file);
    }
    const seen = new Map<string, string | null>();
    const book = await book_read(file, undefined, seen);
    if (outs.length === 0) {
      process.exit(book_run(book));
    }
    const ins = new Set([...seen.keys(), ...Object.values(book.tlds).flatMap((t) =>
      t.$ === "Def" && t.i !== undefined ? t.i.map(path_real) : [])]);
    for (const out of outs) {
      const at = path_real(out);
      if (ins.has(at) || (fs.existsSync(at) && fs.statSync(at).isDirectory())) {
        cli_fail("-o " + out + " is a file the program reads, or a directory");
      }
      cli_emit(book, out);
    }
  } catch (e) {
    cli_say(2, book_err(e) + "\n");
    process.exit(1);
  }
}

// cli_checkup checks and runs each import of the file alone (Base read
// once, seeded into every module that imports it); one that fails fails it.
async function cli_checkup(file: string): Promise<void> {
  const base = await book_read(BASE);
  let bad = false;
  for (const raw of fs.readFileSync(file, "utf8").split("\n")) {
    const m = /^import\s+(\S+)\s+as\s+[A-Za-z_][A-Za-z0-9_]*\s*$/
      .exec(raw.trim());
    if (m === null) {
      continue;
    }
    const at = path.join(path.dirname(file), m[1]);
    cli_say(1, "--- " + m[1] + " ---\n");
    let code = 1;
    try {
      const own = /^import Base$/m.test(fs.readFileSync(at, "utf8"));
      code = book_run(await book_read(at, own ? base : undefined));
    } catch (e) {
      cli_say(2, book_err(e) + "\n");
    }
    if (code !== 0) {
      cli_say(1, "exit " + String(code) + "\n");
      bad = true;
    }
  }
  if (bad) {
    process.exit(1);
  }
}

function path_real(p: string): string {
  return fs.existsSync(p) ? fs.realpathSync(p) : path.resolve(p);
}

function cli_emit(book: Bend.Book, out: string): void {
  if (out.endsWith(".js")) {
    fs.writeFileSync(out, Comp.js_book(book));
  } else if (out.endsWith(".c")) {
    fs.writeFileSync(out, Comp.compile_book(book));
  } else {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-"));
    const c   = path.join(dir, path.basename(out) + ".c");
    fs.writeFileSync(c, Comp.compile_book(book));
    try {
      cli_build(out, c);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  }
}

// cc_find is $CC when set, else the first of clang and every clang-NN on
// PATH (newest first), that is new enough: clang 14 for a CPU build, and
// for a GPU build clang 19 (Apple clang 17, which ships LLVM 19), whose
// #embed carries the device program.
function cc_find(gpu: boolean): string {
  function dir_list(dir: string): string[] {
    try {
      return fs.readdirSync(dir);
    } catch {
      return [];
    }
  }
  const dirs = (process.env.PATH ?? "").split(path.delimiter);
  const nums = [...new Set(dirs.flatMap(dir_list).filter((f) =>
    /^clang-\d+$/.test(f)))].sort((a, b) => Number(b.slice(6)) - Number(a.slice(6)));
  const olds: string[] = [];
  const ccs  = process.env.CC === undefined ? ["clang", ...nums] : [process.env.CC];
  for (const cc of ccs) {
    const out = child.spawnSync(cc, ["--version"], { encoding: "utf8" }).stdout ?? "";
    const m   = /^(Apple )?(?:\w+ )?clang version (\d+)/m.exec(out);
    const need = gpu ? (m?.[1] === undefined ? 19 : 17) : 14;
    if (m !== null && Number(m[2]) >= need) {
      return cc;
    }
    olds.push(m === null ? "no " + cc : "clang " + m[2] + " as " + cc);
  }
  throw "Error: bend needs clang " + (gpu ? "19 (Apple clang 17)" : "14")
    + " or newer to build " + (gpu ? "a GPU program" : "binaries") + " (found "
    + olds.join(", ") + "); on Debian/Ubuntu: curl -fsSL"
    + " https://apt.llvm.org/llvm.sh | sudo bash -s 19; on macOS: xcode-select"
    + " --install";
}

// cli_build builds the C file at `file` into the binary `bin`. A `!` program
// builds with the GPU lane and writes its GPU program too (on Linux only with
// CUDA at $CUDA_HOME, else at /usr/local/cuda, its libraries in lib64 or, as
// nix lays them, lib; else the ! runs on the cores). On macOS a program with
// a framework (#import: a window, audio) builds as Objective-C; on Linux it
// links the X11 and ALSA libraries it includes.
function cli_build(bin: string, file: string): void {
  const c     = fs.readFileSync(file, "utf8");
  const mac   = process.platform === "darwin";
  const cuda  = process.env.CUDA_HOME || "/usr/local/cuda";
  const bangs = !/^#define BANGS\s+0$/m.test(c)
    && (mac || fs.existsSync(cuda + "/include/nvrtc.h"));
  const cc    = cc_find(bangs);
  const objc  = mac && (bangs || /^#import /m.test(c))
    ? ["-x", "objective-c", "-fobjc-arc", "-fmodules"] : [];
  const libs  = [["X11", "X11"], ["alsa", "asound"]].flatMap(([h, l]) =>
    !mac && c.includes("#include <" + h + "/") ? ["-l" + l] : []);
  const cpu = [...objc, "-std=c11", "-O3", file, "-lpthread", "-lm",
    ...libs, "-o", path.resolve(bin)];
  const gpu = mac ? ["-DBEND_METAL=1", ...cpu]
    : ["-DBEND_CUDA=1", "-I" + cuda + "/include", "-L" + cuda + "/lib64",
      "-L" + cuda + "/lib", ...cpu, "-lcuda", "-lnvrtc"];
  const steps: [string, string[]][] = bangs
    ? [[cc, gpu], [path.resolve(bin), ["--gpu-build"]]] : [[cc, cpu]];
  for (const [cmd, args] of steps) {
    if (child.spawnSync(cmd, args, { stdio: "inherit" }).status !== 0) {
      throw "Error: " + path.basename(cmd) + " failed to build " + bin;
    }
  }
}

// cli_base prints the base library; with --types, its type declarations
// (every `type`, and every law whose result is a kind); with a name, the
// blocks declaring it or a name under it (its law, its def, its @unsafe).
function cli_base(what?: string): void {
  const src = fs.readFileSync(BASE, "utf8");
  if (what === undefined) {
    return cli_say(1, src);
  }
  const want: string[] = [];
  for (const text of src.split(/\n(?=type |law |def |@)/)) {
    const m = /^(type|law|def) ([^\s(<:]+)/m.exec(text);
    if (m === null) {
      continue;
    }
    const s = text.replace(/(\n(#[^\n]*)?)+$/, "");
    const last = s.slice(s.lastIndexOf("\n") + 1);
    const ok = what === "--types"
      ? m[1] === "type" || (m[1] === "law" && /^ *(Type|Data|Kind\(.*\))$/.test(last))
      : m[2] === what || m[2].startsWith(what + ".");
    if (ok) {
      want.push(s);
    }
  }
  if (want.length === 0) {
    cli_fail("Base has no " + what);
  }
  cli_say(1, want.join("\n\n") + "\n");
}

async function cli_bundle(page: string, dir: string): Promise<void> {
  const out = await Bun.build({
    entrypoints: [page],
    outdir: dir,
    target: "browser",
    minify: true,
    plugins: [PLUGIN],
  });
  for (const a of out.outputs) {
    cli_say(1, a.path + " (" + (a.size / 1024).toFixed(1) + "kb)\n");
  }
}

// Publish
// =======

// cli_publish checks the file, then posts what the loader read (no TODO
// left) to the hub with its proof of work, and prints the import line.
async function cli_publish(file: string): Promise<void> {
  const seen = new Map<string, string | null>();
  const book = await book_read(file, undefined, seen);
  const files = pkg_files(file, book, seen);
  const paths = Object.keys(files).sort();
  const bytes = paths.reduce((n, p) => n + Buffer.byteLength(files[p]), 0);
  const hash  = "0x" + sha256(paths.map((p) => sha256(files[p]) + " " + p
    + "\n").join("")).slice(0, 32);
  cli_say(2, "publishing " + String(paths.length) + " files, "
    + String(bytes) + " bytes, as " + hash + " (mining its proof of work)\n");
  const nonce = await pow_mine(hash, bytes);
  const res = await fetch(Bend.BEND_HUB, { method: "POST",
    body: JSON.stringify({ files, nonce }) });
  const got = (await res.text()).trim();
  if (!res.ok || got !== hash) {
    throw "Error: " + Bend.BEND_HUB + " answered: " + got;
  }
  const entry = Object.keys(files)[0];
  const name  = path.basename(entry, ".bend");
  cli_say(1, hash + "\nimport " + hash + "/" + entry + " as "
    + name[0].toUpperCase() + name.slice(1) + "\n");
}

// pkg_files is the package the loader read for this file, the entry first:
// every .bend file at its namespace (the entry at its name), every foreign
// .c or .js file at its path from the entry's directory; base and the
// store's packages stay out. A path that climbs above the entry's directory
// takes the entry's ancestor directories along, as many as the deepest climb.
function pkg_files(file: string, book: Bend.Book,
  seen: Map<string, string | null>): Record<string, string> {
  const dir  = file.slice(0, file.lastIndexOf("/") + 1);
  const raws = [...[...seen].flatMap(([real, ns]): [string, string][] =>
    real === BASE || ns === null || ns.startsWith("0x") ? []
      : [[ns === "" ? path.basename(file) : ns + ".bend", real]]),
  ...Object.entries(book.tlds).flatMap(([k, tld]): [string, string][] =>
    tld.$ !== "Def" || tld.i === undefined || tld.b === true
      || k.startsWith("0x") ? [] : tld.i.map((f) =>
      [f.startsWith(dir) ? f.slice(dir.length) : f, f]))];
  const ups = raws.map(([p]) => path.posix.normalize(p).split("/")
    .filter((s) => s === "..").length);
  const anc = fs.realpathSync(path.dirname(file)).split("/")
    .slice(-Math.max(0, ...ups) || Infinity);
  const files: Record<string, string> = {};
  for (const [raw, real] of raws) {
    const p = path.posix.join(...anc, raw);
    if (p.startsWith("/") || p.startsWith("..")) {
      throw "Error: " + real + " cannot be published (an absolute import,"
        + " or a climb above the file system)";
    }
    files[p] = fs.readFileSync(real, "utf8");
  }
  return files;
}

function sha256(text: string): string {
  return crypto.createHash("sha256").update(text).digest("hex");
}

async function pow_mine(hash: string, bytes: number): Promise<number> {
  const step = os.availableParallelism();
  const lim  = 2 ** 53 / (POW * Math.max(1, bytes / 262144));
  const ws   = Array.from({ length: step }, (_, k) => new thr.Worker(POW_JS,
    { eval: true, workerData: { pre: hash + " ", lim, from: k, step } }));
  const n = await new Promise<number>((res) =>
    ws.forEach((w) => w.on("message", res)));
  ws.forEach((w) => w.terminate());
  return n;
}

// Report
// ======

function cli_report(book: Bend.Book): void {
  const uns  = Object.values(book.tlds).filter((t) =>
    t.$ === "Def" && t.u === true).length;
  cli_say(1, uns > 0 ? `${uns} term${uns === 1 ? "" : "s"}`
    + " annotated as unsafe.\nThe code is well-typed, but may contain logical"
    + " paradoxes.\n" : "All terms check.\n");
}

function cli_say(fd: number, text: string): void {
  try {
    fs.writeSync(fd, text);
  } catch (e) {
    if ((e as NodeJS.ErrnoException).code !== "EPIPE") {
      throw e;
    }
    process.exit(0);
  }
}

function cli_fail(msg: string): never {
  cli_say(2, "bend: " + msg + " (see bend --help)\n");
  process.exit(1);
}

// Book
// ====

async function book_read(file: string, base?: Bend.Book,
  seen = new Map<string, string | null>()): Promise<Bend.Book> {
  const book = base === undefined ? Bend.book_nil() : book_seed(base);
  if (base !== undefined) {
    seen.set(BASE, "");
  }
  await Bend.book_load(book, file, "", seen);
  Bend.book_valid(book, base?.order.length ?? 0);
  const hols = book.hols + book.open;
  if (hols > 0) {
    throw "Error: " + String(hols) + " TODO" + (hols === 1 ? "" : "s")
      + " found.\nThe code is incomplete, and not a valid proof yet.";
  }
  return book;
}

function book_seed(base: Bend.Book): Bend.Book {
  const book = Bend.book_nil();
  for (const k of Object.keys(base.tlds)) {
    book.tlds[k] = { ...base.tlds[k] };
  }
  Object.assign(book.ctrs, base.ctrs);
  for (const k of Object.keys(base.tmps)) {
    book.tmps[k] = { ...base.tmps[k], p: { ...base.tmps[k].p, book },
      is: { ...base.tmps[k].is } };
  }
  book.order.push(...base.order);
  return book;
}

function book_run(book: Bend.Book): number {
  const main = book.tlds["main"];
  if (main === undefined || main.$ !== "Def"
    || (main.v === null && main.i === undefined)) {
    cli_report(book);
    return 0;
  }
  if (Comp.io_type(book) !== null) {
    return Comp.io_run(book);
  }
  const snf = Bend.term_snf(book, main.v as Bend.HTerm);
  cli_say(1, Bend.term_show(Bend.term_lower(snf)) + "\n");
  return 0;
}

function book_err(e: unknown): string {
  const err = e as Bend.Err;
  if (e instanceof RangeError) {
    return "Error: the machine stack overflowed (a deep recursion, or a"
      + " literal too large to expand)";
  }
  return err?.$ === "Err" ? Bend.err_show(err) : String(e);
}

// Load
// ====

async function load_js(path: string): Promise<string> {
  let book: Bend.Book;
  try {
    book = await book_read(path);
  } catch (e) {
    throw new Error(book_err(e));
  }
  const outs = [...new Set(book.order)].filter((k) => {
    const tld = book.tlds[k];
    return tld.$ === "Def" && tld.v !== null && tld.b !== true
      && tld.i === undefined && Comp.io_base(book, tld.T) === null;
  });
  return Comp.js_lib(book, outs, outs);
}

export async function load(u: string, context: unknown,
  next: (u: string, context: unknown) => unknown): Promise<unknown> {
  return u.endsWith(".bend")
    ? { format: "module", shortCircuit: true,
      source: await load_js(url.fileURLToPath(u)) }
    : next(u, context);
}

export default PLUGIN;

if (import.meta.main) {
  await cli();
} else if (typeof Bun !== "undefined") {
  Bun.plugin(PLUGIN);
} else if (thr.isMainThread) {
  mod.register(import.meta.url);
}
