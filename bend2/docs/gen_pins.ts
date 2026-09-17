#!/usr/bin/env bun
// The record pins, measured on this machine: bench/runtime/_pin_/<hw>.txt and
// bench/checker/_pin_/<hw>.txt (hw from the CPU's brand string, so apple_m4_max
// on the MacBook), raw seconds that gen_charts.ts draws and the landing page
// and the film quote. The gate pins on the minis are gates/perf.ts --pin; this
// script writes nothing it did not measure in the same run, and every Bend run
// must print the output the gate pins hold. Every timed cell runs alone on a
// quiet machine; only the builds run pooled, one per performance core. A
// runtime row: the Bend binary built as the gate builds it (the cc lines of
// gates/perf.ts) in each of its three modes, one warm run then the timed one
// under /usr/bin/time -l (a fresh binary's first GPU run compiles its shader);
// then the twins, warm then timed: main.c under the same cc line (an f32 sum is
// not checked: -O3 fuses a*b+c), main.ts under bun and node (the faster),
// main.lean under lean -c and leanc -O3. A checker row: one cold check under
// Isabelle, Agda, Lean, Rocq and Bend, 300 s each, a timeout written as >300s.
// Run it whole or one file at a time; --keep <lang> carries a checker column
// forward from the file as it is, unmeasured (a prover this machine cannot run
// today), and the stamp says so:
//
//   bun bend2/docs/gen_pins.ts [runtime] [checker] [--keep <lang>]

import * as child from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { BUILD, CC, FLAGS, MEMORY, MODES } from "../../gates/perf.ts";

// Constants
// =========

const ROOT = path.join(import.meta.dirname, "..", "..");

const MAIN = path.join(ROOT, "bend2", "main.ts");

const RUNTIME = path.join(ROOT, "bench", "runtime");

const CHECKER = path.join(ROOT, "bench", "checker");

const HW = child.spawnSync("sysctl", ["-n", "machdep.cpu.brand_string"],
  { encoding: "utf8" }).stdout.trim().toLowerCase().replace(/\s+/g, "_");

const RUN_TIMEOUT = 600;

const CHECK_TIMEOUT = 300;

const LANGS = ["isabelle", "agda", "lean", "rocq", "bend"];

const POOL = ((): number => {
  const got = child.spawnSync("sysctl", ["-n", "hw.perflevel0.logicalcpu"],
    { encoding: "utf8" });
  const n = Number(got.stdout.trim());
  return Number.isInteger(n) && n > 0 ? n : os.cpus().length;
})();

// Exec
// ====

type Ran = { secs: number; out: string; over: boolean; rss: number };

function exec_run(cmd: string[], cwd: string, timeout: number,
  quiet = false): Promise<Ran> {
  return new Promise((ok, no) => {
    const at = performance.now();
    const kid = child.spawn(cmd[0], cmd.slice(1),
      { cwd, detached: true, stdio: ["ignore", "pipe", "pipe"] });
    let outs = "";
    let errs = "";
    let over = false;
    const timer = setTimeout(() => {
      over = true;
      try {
        process.kill(-(kid.pid as number), "SIGKILL");
      } catch {}
    }, timeout * 1000);
    kid.stdout.on("data", (d: Buffer) => {
      outs += d.toString();
    });
    kid.stderr.on("data", (d: Buffer) => {
      errs += d.toString();
    });
    kid.on("error", (e) => {
      clearTimeout(timer);
      no(e);
    });
    kid.on("close", (status) => {
      clearTimeout(timer);
      const secs = (performance.now() - at) / 1000;
      if (over) {
        return ok({ secs: timeout, out: "", over: true, rss: 0 });
      }
      if (status !== 0) {
        if (quiet) {
          return ok({ secs: -1, out: "", over: false, rss: 0 });
        }
        return no(new Error(cmd.join(" ") + " failed:\n"
          + outs.slice(-400) + errs.slice(-800)));
      }
      const mem = /(\d+)\s+maximum resident set size/.exec(errs);
      ok({ secs, out: outs.trim(), over: false,
        rss: mem === null ? 0 : Number(mem[1]) / (1 << 20) });
    });
  });
}

function exec_need(bins: string[]): void {
  const missing = bins.filter((b) =>
    child.spawnSync("which", [b], { encoding: "utf8" }).status !== 0);
  if (missing.length > 0) {
    throw new Error("missing toolchains: " + missing.join(", ")
      + " -- every pin must be measured, install them or do not repin");
  }
}

function tmp_dir(tag: string): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), "bend-pins-" + tag + "-"));
}

async function pool_run(jobs: (() => Promise<void>)[]): Promise<void> {
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(POOL, jobs.length) },
    async () => {
      while (next < jobs.length) {
        const job = jobs[next];
        next += 1;
        await job();
      }
    }));
}

function say(text: string): void {
  process.stdout.write(text + "\n");
}

// Table
// =====

function fmt_secs(x: number): string {
  return x.toFixed(3).padStart(7) + "s";
}

function fmt_mem(mb: number): string {
  return mb < 100 ? mb.toFixed(1) + "M" : String(Math.round(mb)) + "M";
}

function fmt_meas(r: Ran): string {
  return fmt_secs(r.secs) + " " + fmt_mem(r.rss).padStart(6);
}

function pin_table(heads: string[], rows: string[][]): string[] {
  const wide = heads.map((h, i) =>
    Math.max(h.length, ...rows.map((r) => r[i].length)));
  const line = (cells: string[]): string =>
    "| " + cells.map((c, i) => c.padEnd(wide[i])).join(" | ") + " |";
  return [line(heads),
    "|" + wide.map((w) => "-".repeat(w + 2)).join("|") + "|",
    ...rows.map(line)];
}

function pin_write(file: string, name: string, target: string,
  lines: string[], kept = ""): void {
  const head = child.spawnSync("git", ["rev-parse", "--short", "HEAD"],
    { cwd: ROOT, encoding: "utf8" }).stdout.trim();
  fs.writeFileSync(file, "# " + name + "\n# "
    + new Date().toISOString().slice(0, 10) + " " + head
    + " bun bend2/docs/gen_pins.ts " + target + kept + "\n\n"
    + lines.join("\n") + "\n");
  say("wrote " + file);
}

// The rows of a pin file as it is, by bench, with its stamp.
function pin_rows(file: string): [string, Map<string, string[]>] {
  const rows = new Map<string, string[]>();
  let stamp = "";
  for (const line of fs.readFileSync(file, "utf8").split("\n")) {
    const row = /^\| (\S+)\s*\|(.*)\|$/.exec(line);
    if (row !== null && row[1] !== "bench" && !row[2].startsWith("-")) {
      rows.set(row[1], row[2].split("|").map((c) => c.trim()));
    } else if (/^# \d{4}-/.test(line)) {
      stamp = /^# (\S+ \S+)/.exec(line)?.[1] ?? "";
    }
  }
  return [stamp, rows];
}

// Outputs
// =======

// The gate pins' OUTPUT column: what every Bend run here must print.
function pin_outs(): Map<string, string> {
  const rows = pin_rows(path.join(RUNTIME, "_pin_", "apple_m4.txt"))[1];
  return new Map([...rows].map(([b, c]) => [b, c[c.length - 1]]));
}

// Runtime
// =======

type Built = { bench: string; want: string; f32: boolean; cpu: string;
  gpu: string; cbin: string; lbin: string };

async function runtime_build(bench: string, want: string,
  dir: string): Promise<Built> {
  const home = path.join(RUNTIME, bench);
  const at = path.join(dir, bench);
  fs.mkdirSync(at);
  fs.copyFileSync(path.join(home, "main.lean"), path.join(at, "main.lean"));
  await exec_run([process.execPath, MAIN, path.join(home, "main.bend"),
    "-o", "main.c"], at, RUN_TIMEOUT);
  await exec_run(["sh", "-c", BUILD[0] + " -o cpu"], at, RUN_TIMEOUT);
  await exec_run(["sh", "-c", BUILD[2] + " -o gpu"], at, RUN_TIMEOUT);
  await exec_run(["sh", "-c", CC + " " + path.join(home, "main.c")
    + " -o twin_c"], at, RUN_TIMEOUT);
  await exec_run(["lean", "main.lean", "-c", "lean.c"], at, RUN_TIMEOUT);
  await exec_run(["leanc", "-O3", "-DNDEBUG", "lean.c", "-o", "twin_lean"],
    at, RUN_TIMEOUT);
  const f32 = fs.readFileSync(path.join(home, "main.bend"), "utf8")
    .includes("F32");
  return { bench, want, f32, cpu: path.join(at, "cpu"),
    gpu: path.join(at, "gpu"), cbin: path.join(at, "twin_c"),
    lbin: path.join(at, "twin_lean") };
}

function runtime_check(b: Built, what: string, got: Ran): Ran {
  if (got.out.split("\n").pop()?.trim() !== b.want) {
    throw new Error(b.bench + " " + what + ": output " + got.out.slice(-60)
      + " != the pinned " + b.want);
  }
  return got;
}

// A Bend binary runs in its build directory: the Metal one reads its
// shader from main.c through __FILE__.
async function runtime_cell(b: Built, mode: number): Promise<Ran> {
  const bin = mode === 2 ? b.gpu : b.cpu;
  const dir = path.dirname(bin);
  let nt = 1;
  while (nt * 2 <= os.cpus().length && nt < 256) {
    nt *= 2;
  }
  const args = FLAGS[mode].replace("$nt", String(nt))
    .replace("$gm", MEMORY[b.bench] ?? "on").split(" ");
  await exec_run([bin, ...args], dir, RUN_TIMEOUT);
  return runtime_check(b, MODES[mode],
    await exec_run(["/usr/bin/time", "-l", bin, ...args], dir, RUN_TIMEOUT));
}

async function runtime_ts(b: Built, dir: string): Promise<number> {
  const file = path.join(RUNTIME, b.bench, "main.ts");
  await exec_run([process.execPath, file], dir, RUN_TIMEOUT);
  const bun = runtime_check(b, "main.ts under bun",
    await exec_run([process.execPath, file], dir, RUN_TIMEOUT));
  await exec_run(["node", file], dir, RUN_TIMEOUT, true);
  const node = await exec_run(["node", file], dir, RUN_TIMEOUT, true);
  return node.secs >= 0 && node.out.trim().endsWith(b.want)
    ? Math.min(bun.secs, node.secs) : bun.secs;
}

async function runtime_rows(): Promise<string[][]> {
  exec_need(["cc", "lean", "leanc", "node"]);
  const outs = pin_outs();
  const dir = tmp_dir("runtime");
  const benches = fs.readdirSync(RUNTIME).filter((f) => !f.startsWith("_"))
    .sort();
  const built: Built[] = [];
  await pool_run(benches.map((bench, i) => async () => {
    const want = outs.get(bench);
    if (want === undefined) {
      throw new Error(bench + ": no OUTPUT in the gate pins to check");
    }
    built[i] = await runtime_build(bench, want, dir);
  }));
  const rows: string[][] = [];
  for (const b of built) {
    const runs = [];
    for (let mode = 0; mode < 3; mode += 1) {
      runs.push(await runtime_cell(b, mode));
    }
    await exec_run([b.cbin], dir, RUN_TIMEOUT);
    const c = await exec_run([b.cbin], dir, RUN_TIMEOUT);
    if (!b.f32) {
      runtime_check(b, "main.c", c);
    }
    const ts = await runtime_ts(b, dir);
    await exec_run([b.lbin], dir, RUN_TIMEOUT);
    const lean = runtime_check(b, "main.lean", await exec_run([b.lbin], dir,
      RUN_TIMEOUT));
    rows.push([b.bench, ...runs.map(fmt_meas), fmt_secs(c.secs),
      fmt_secs(ts), fmt_secs(lean.secs)]);
    say("runtime " + rows[rows.length - 1].join(" "));
  }
  fs.rmSync(dir, { recursive: true, force: true });
  return rows;
}

// Checker
// =======

function checker_cell(lang: string, home: string, dir: string): Promise<Ran> {
  const t = CHECK_TIMEOUT;
  if (lang === "bend") {
    return exec_run([process.execPath, MAIN, path.join(home, "main.bend")],
      dir, t);
  }
  const ext: Record<string, string> = { lean: "lean", agda: "agda",
    rocq: "v", isabelle: "thy" };
  fs.copyFileSync(path.join(home, "main." + ext[lang]),
    path.join(dir, "main." + ext[lang]));
  if (lang === "lean" || lang === "agda") {
    return exec_run([lang, "main." + ext[lang]], dir, t);
  }
  if (lang === "rocq") {
    return exec_run(["rocq", "compile", "main.v"], dir, t);
  }
  fs.writeFileSync(path.join(dir, "ROOT"),
    "session bench = HOL +\n  theories\n    main\n");
  return exec_run(["isabelle", "build", "-c", "-D", "."], dir, t);
}

async function checker_rows(keep: string[]): Promise<string[][]> {
  exec_need(LANGS.filter((l) => l !== "bend" && !keep.includes(l)));
  const [, was] = pin_rows(path.join(CHECKER, "_pin_", HW + ".txt"));
  const rows: string[][] = [];
  const names = fs.readdirSync(CHECKER).filter((f) => !f.startsWith("_"))
    .sort().filter((n) => fs.existsSync(path.join(CHECKER, n, "main.lean")));
  for (const name of names) {
    const row = [name];
    for (const lang of LANGS) {
      if (keep.includes(lang)) {
        const cell = was.get(name)?.[LANGS.indexOf(lang)] ?? "-";
        row.push(/^[\d.]+s$/.test(cell) ? fmt_secs(Number(cell.slice(0, -1)))
          : cell);
        continue;
      }
      const dir = tmp_dir(lang);
      const ran = await checker_cell(lang, path.join(CHECKER, name), dir)
        .finally(() => fs.rmSync(dir, { recursive: true, force: true }));
      if (lang === "bend" && !ran.out.includes("All terms check.")) {
        throw new Error(name + ": Bend did not check: " + ran.out.slice(-200));
      }
      row.push(ran.over ? ">" + String(CHECK_TIMEOUT) + "s"
        : fmt_secs(ran.secs));
      say("checker " + name + " " + lang + " " + row[row.length - 1].trim());
    }
    rows.push(row);
  }
  return rows;
}

// Main
// ====

const args = process.argv.slice(2);
const keep = args.flatMap((a, i) => args[i - 1] === "--keep" ? [a] : []);
const known = ["runtime", "checker"];
if (args.some((a, i) => !known.includes(a) && a !== "--keep"
  && args[i - 1] !== "--keep")) {
  process.stderr.write("usage: bun bend2/docs/gen_pins.ts [runtime]"
    + " [checker] [--keep <lang>]\n");
  process.exit(1);
}
say("pins for " + HW);
const targets = known.filter((k) => args.includes(k));
for (const target of targets.length === 0 ? known : targets) {
  if (target === "runtime") {
    pin_write(path.join(RUNTIME, "_pin_", HW + ".txt"), "Runtime", target,
      pin_table(["bench", ...MODES, "C", "TS", "Lean"], await runtime_rows()));
  } else {
    const file = path.join(CHECKER, "_pin_", HW + ".txt");
    const kept = keep.length === 0 ? "" : "; " + keep.join(", ")
      + " kept from " + pin_rows(file)[0] + ", not measured";
    pin_write(file, "Checker", target, pin_table(["bench", "Isabelle",
      "Agda", "Lean", "Rocq", "Bend"], await checker_rows(keep)), kept);
  }
}
