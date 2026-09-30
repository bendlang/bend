#!/usr/bin/env bun
// Runs the perf gate through the bastion's Ansible, for a machine without the
// `cluster` ssh aliases or a key the minis trust, and draws perf.ts's own
// screen: the same cells, graded against the same pins, in the same table,
// ending in the same PASS line.
//
// The fleet key stays on the bastion: perf_ansible.yml runs the cells there,
// as HigherOrderCompany. A runtime cell is perf.ts's cell_script with the
// pack read from a file, not stdin; a checker's script is chk_run's, copied.
// Jobs go to nodes 194-241 by default: the gate's four slots of 48 are nodes
// 2-193, so a gate run elsewhere never shares a mini with this one. There
// are more jobs (53) than live nodes (46), so the longest jobs, by their
// pins, get a node to themselves and the shortest share one. --times adds
// where the wall time went; --log shows the playbook's lines; --png draws
// the screen into perf.png at the repo's root (the same file every run),
// with every cell that failed in red.
//
//   bun gates/perf_ansible.ts [--nodes 194-217,219-229,231-241]
//     [--only bfs,queens] [--no-checker] [--times] [--log] [--png]

import * as child from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

import * as lib from "./_lib";
import * as perf from "./perf";

// Types
// =====

type Job = { name: string; pack: string; script: string; cost: number };

// Constants
// =========

const RUNTIME = path.join(lib.ROOT, "bench", "runtime");

const CHECKER = path.join(lib.ROOT, "bench", "checker");

const PLAYBOOK = path.join(import.meta.dirname, "perf_ansible.yml");

const AT = (process.env.BASTION_USER ?? "lorenzo") + "@52.67.125.18";

const SSH = ["-p", "22022", "-o", "BatchMode=yes", "-o", "ConnectTimeout=8",
  AT];

const STAGE = fs.mkdtempSync(path.join(os.tmpdir(), "bend-perf-"));

// 218 and 230 are dead (census 2026-09-14)
const NODES = "194-217,219-229,231-241";

const MARK = "@@B4";

const JOB = "@@JOB";

const CLOCK = "perl -MTime::HiRes=time -e 'print time'";

const PACKS = "$HOME/bend-perf-run";

const T0 = Date.now();

const STAMPS: [string, number][] = [];

const LOG = process.argv.includes("--log");

const PNG = path.join(lib.ROOT, "perf.png");

// Args
// ====

function arg(flag: string): string | undefined {
  const i = process.argv.indexOf(flag);
  return i < 0 ? undefined : process.argv[i + 1];
}

function nodes_parse(spec: string): number[] {
  return spec.split(",").flatMap((part) => {
    const [a, b] = part.split("-").map(Number);
    return Array.from({ length: (b ?? a) - a + 1 }, (_, i) => a + i);
  });
}

// The bastion's node list: index -> the inventory's hostname (its DNS name).
function nodes_dns(nodes: number[], tsv: string): string[] {
  const rows = new Map(tsv.split("\n").slice(1).map((l) => l.split("\t"))
    .map((c) => [Number(c[0]), c[3]]));
  return nodes.map((n) => {
    const dns = rows.get(n);
    if (dns === undefined) {
      throw new Error("node " + String(n) + " is not on the bastion's list");
    }
    return dns;
  });
}

// Jobs
// ====

// perf.ts cell_script, with the pack read from a file
function cell_script(bench: string, mode: number): string {
  return perf.cell_script({ bench, mode, secs: null, mem: null, comp: null,
    out: "", note: "" }).replace("tar -xzf -", "tar -xzf " + PACKS
    + "/runtime.tgz");
}

// perf.ts chk_run's script, with the pack read from a file
function chk_script(bench: string): string {
  return `d=$HOME/bend-perf/chk-${bench}; rm -rf $d; mkdir -p $d;`
    + ` cd $d; tar -xzf ${PACKS}/chk-${bench}.tgz; for i in 1 2 3; do`
    + ` t0=$(${CLOCK}); ${lib.BUN}`
    + ` bend2/main.ts ${bench}/main.bend > out.txt 2>&1; e=$?;`
    + ` t1=$(${CLOCK}); echo "${MARK} check $e $t0 $t1"; cat out.txt; done;`
    + ` cd; rm -rf $d`;
}

// A job's cost is its pinned time: two compiles and an emit with cc for the
// build, a warm run and a timed one for a cell, three checks for a checker.
function jobs_make(benches: string[], chks: string[]): Job[] {
  const [pins, cpins] = perf.pin_read();
  return [...benches.flatMap((b) => perf.MODES.map((_, m) => {
    const pin = pins.get(b);
    return { name: b + ":" + String(m), pack: "runtime.tgz",
      script: cell_script(b, m), cost: pin === undefined ? 60
        : 3 * pin.comp + 1 + 2 * pin.secs[m] };
  })), ...chks.map((b) => ({ name: "chk:" + b, pack: "chk-" + b + ".tgz",
    script: chk_script(b), cost: 3 * (cpins.get(b) ?? 20) }))];
}

// Longest job first, each to the node with the least work so far.
function jobs_place(jobs: Job[], hosts: string[]): Map<string, Job[]> {
  const load = new Map(hosts.map((h) => [h, 0]));
  const mine = new Map<string, Job[]>();
  for (const j of [...jobs].sort((x, y) => y.cost - x.cost)) {
    const host = hosts.reduce((a, b) =>
      (load.get(b) as number) < (load.get(a) as number) ? b : a);
    load.set(host, (load.get(host) as number) + j.cost);
    mine.set(host, [...(mine.get(host) ?? []), j]);
  }
  return mine;
}

// Stage
// =====

function stamp(what: string): void {
  STAMPS.push([what, Date.now()]);
}

// What goes up to ~/bend-perf on the bastion: the playbook, jobs.json (the
// hosts), packs/ and jobs/<host>.sh (its jobs, one after another, each headed
// by its name and the node's clock) with jobs/<host>.packs (the packs they
// build from), which the bastion tars into nodes/<host>.tar.
function stage(jobs: Job[], hosts: string[]): void {
  for (const dir of ["packs", "jobs"]) {
    fs.mkdirSync(path.join(STAGE, dir));
  }
  fs.copyFileSync(PLAYBOOK, path.join(STAGE, "perf_ansible.yml"));
  fs.writeFileSync(path.join(STAGE, "packs", "runtime.tgz"),
    lib.pack(RUNTIME));
  for (const j of jobs.filter((j) => j.name.startsWith("chk:"))) {
    fs.writeFileSync(path.join(STAGE, "packs", j.pack),
      lib.pack(path.join(CHECKER, j.name.slice(4))));
  }
  const placed = jobs_place(jobs, hosts);
  for (const [host, js] of placed) {
    fs.writeFileSync(path.join(STAGE, "jobs", host + ".sh"), js.map((j) =>
      `echo "${JOB} ${j.name} $(${CLOCK})"; ${j.script}\n`).join("")
      + `echo "${JOB} end $(${CLOCK})"\n`);
    fs.writeFileSync(path.join(STAGE, "jobs", host + ".packs"),
      [...new Set(js.map((j) => j.pack))].join(" "));
  }
  fs.writeFileSync(path.join(STAGE, "jobs.json"),
    JSON.stringify({ jobs: [...placed.keys()] }));
}

function run(bin: string, args: string[]): string {
  const got = child.spawnSync(bin, args, { encoding: "utf8",
    maxBuffer: 1 << 26 });
  if (got.status !== 0) {
    throw new Error(bin + " " + args.join(" ") + ": exit "
      + String(got.status) + "\n" + got.stderr);
  }
  return got.stdout;
}

// One session carries the stage up (stdin), the playbook's lines (stderr,
// each task stamped when Ansible names it) and out/ back (stdout, a tar).
function play(): Promise<void> {
  const dir = "$HOME/bend-perf";
  const script = `set -e; rm -rf ${dir}; mkdir -p ${dir}/nodes ${dir}/out;`
    + ` tar -xzf - -C ${dir}; cd ${dir}/jobs; for f in *.sh; do`
    + ` tar -cf ../nodes/\${f%.sh}.tar $f -C ../packs $(cat \${f%.sh}.packs);`
    + ` done; cd ~/ansible; sudo ANSIBLE_PIPELINING=1 ansible-playbook`
    + ` ${dir}/perf_ansible.yml -e @${dir}/jobs.json 1>&2 || s=$?;`
    + ` tar -cf - -C ${dir} out; exit \${s:-0}`;
  const up = child.spawnSync("tar", ["-czf", "-", "-C", STAGE, "."],
    { maxBuffer: 1 << 28 }).stdout;
  return new Promise((done, fail) => {
    const kid = child.spawn("ssh", [...SSH, script], { stdio: ["pipe",
      "pipe", "pipe"] });
    const outs: Buffer[] = [];
    const log: string[] = [];
    let rest = "";
    kid.stdout.on("data", (d: Buffer) => outs.push(d));
    kid.stderr.on("data", (d: Buffer) => {
      const lines = (rest + d.toString()).split("\n");
      rest = lines.pop() ?? "";
      for (const line of lines) {
        const task = /^TASK \[(.*)\]/.exec(line);
        if (task !== null) {
          stamp("ansible: " + task[1]);
        }
        log.push(line);
        if (LOG) {
          process.stderr.write(line + "\n");
        }
      }
    });
    kid.on("close", (code) => {
      stamp("download and grade");
      fs.writeFileSync(path.join(STAGE, "out.tar"), Buffer.concat(outs));
      run("tar", ["-xf", path.join(STAGE, "out.tar"), "-C", STAGE]);
      fs.writeFileSync(path.join(STAGE, "ansible.log"), log.join("\n"));
      code === 0 ? done() : fail(new Error("ansible-playbook: exit "
        + String(code) + "\n" + log.slice(-20).join("\n")));
    });
    kid.stdin.end(up);
  });
}

async function remote(jobs: Job[], hosts: number[]): Promise<void> {
  stamp("node list");
  const tsv = run("ssh", [...SSH, "cat /etc/hoc-ssh/nodes.tsv"]);
  stamp("pack and stage");
  stage(jobs, nodes_dns(hosts, tsv));
  stamp("upload and untar");
  await play();
}

// Grade
// =====

// Each job's output, and each node's [first job start, end] by its clock.
function outputs(): [Map<string, [string, string]>, [number, number][]] {
  const got = new Map<string, [string, string]>();
  const spans: [number, number][] = [];
  const all = JSON.parse(fs.readFileSync(path.join(STAGE, "out",
    "out.json"), "utf8")) as Record<string, string>;
  for (const [host, text] of Object.entries(all)) {
    const parts = text.split(new RegExp("^" + JOB + " ", "m")).slice(1);
    const clocks: number[] = [];
    for (const part of parts) {
      const nl = part.indexOf("\n");
      const [name, clock] = part.slice(0, nl === -1 ? undefined : nl)
        .split(" ");
      clocks.push(Number(clock));
      if (name !== "end") {
        got.set(name, [host, part.slice(nl + 1)]);
      }
    }
    if (clocks.length > 1) {
      spans.push([clocks[0], clocks[clocks.length - 1]]);
    }
  }
  return [got, spans];
}

// Where the wall time went: each phase from its stamp to the next, and
// inside the playbook, the window in which the nodes ran their jobs (the
// nodes' clocks agree within a second) and the longest node's run.
function times(spans: [number, number][]): void {
  console.log("\nWALL TIME " + ((Date.now() - T0) / 1000).toFixed(1) + "s");
  STAMPS.forEach(([what, at], i) => {
    const next = i + 1 < STAMPS.length ? STAMPS[i + 1][1] : Date.now();
    console.log("  " + ((next - at) / 1000).toFixed(1).padStart(5) + "s  "
      + what);
  });
  if (spans.length > 0) {
    const lo = Math.min(...spans.map((s) => s[0]));
    const hi = Math.max(...spans.map((s) => s[1]));
    const long = Math.max(...spans.map((s) => s[1] - s[0]));
    console.log("  the nodes ran their jobs in a " + (hi - lo).toFixed(1)
      + "s window; the busiest node ran for " + long.toFixed(1) + "s");
  }
}

// perf.ts cell_run's reading of a cell's output
function cell_read(c: perf.Cell, host: string, out: string): void {
  const built = new RegExp("^" + MARK + " built (\\d+) ([\\d.]+) ([\\d.]+)$",
    "m").exec(out);
  const ran = new RegExp("^" + MARK + " ran (\\d+) ([\\d.]+) ([\\d.]+)$", "m")
    .exec(out);
  if (built === null) {
    c.note = c.bench + " " + perf.MODES[c.mode] + ": no output"
      + (host === "" ? " (its node never answered)" : " from " + host);
    return;
  }
  c.comp = Number(built[3]) - Number(built[2]);
  if (built[1] !== "0" || ran === null || ran[1] !== "0") {
    c.note = c.bench + " " + perf.MODES[c.mode] + ": " + (built[1] !== "0"
      ? "build: " : "exit " + String(ran?.[1] ?? "?") + ": ")
      + perf.cell_note(out);
    return;
  }
  const tail = out.split(new RegExp("^" + MARK + " ran .*\n", "m"))[1];
  const [body, time] = (tail ?? "").split(MARK + " time\n");
  const rss = /(\d+)\s+maximum resident set size/.exec(time ?? "");
  c.out = body.split("\n").map((l) => l.trim()).filter((l) => l !== "")
    .pop() ?? "";
  c.secs = Number(ran[3]) - Number(ran[2]);
  c.mem = rss === null ? null : Number(rss[1]) / (1 << 20);
  if (c.mem === null) {
    c.note = c.bench + " " + perf.MODES[c.mode] + ": unreadable time output";
  }
}

// perf.ts chk_run's reading of a checker's output
function chk_read(c: perf.Chk, out: string): void {
  const runs = [...out.matchAll(new RegExp("^" + MARK
    + " check (\\d+) ([\\d.]+) ([\\d.]+)$", "gm"))];
  if (runs.length === 0) {
    c.note = c.bench + ": no output";
  } else if (runs.some((r) => r[1] !== "0")
    || !out.includes("ALL PROOFS CHECK")) {
    c.note = c.bench + ": " + perf.cell_note(out);
  } else {
    c.secs = Math.min(...runs.map((r) => Number(r[3]) - Number(r[2])));
  }
}

// perf.ts main's grading, drawn with its view.
function grade(cells: perf.Cell[], chks: perf.Chk[]): never {
  const [pins, cpins] = perf.pin_read();
  const [got, spans] = outputs();
  for (const c of cells) {
    const [host, out] = got.get(c.bench + ":" + String(c.mode)) ?? ["", ""];
    cell_read(c, host, out);
  }
  for (const c of chks) {
    chk_read(c, got.get("chk:" + c.bench)?.[1] ?? "");
  }
  // a failed cell is "<bench> <column>", the column counted as in the view
  const fails = new Set<string>();
  const fits = (x: number | null, pin: number | undefined, bench: string,
    col: number): number => {
    const ok = x !== null && pin !== undefined && x <= pin * perf.SLACK;
    if (!ok) {
      fails.add(bench + " " + String(col));
    }
    return Number(ok);
  };
  let pass = 0;
  for (const c of cells) {
    const pin = pins.get(c.bench);
    if (pin !== undefined && c.out !== pin.out && c.secs !== null) {
      c.note = c.bench + " " + perf.MODES[c.mode] + ": output " + c.out
        + " differs from the pinned " + pin.out;
      c.secs = null;
    }
    pass += fits(c.secs, pin?.secs[c.mode], c.bench, 2 + 2 * c.mode)
      + fits(c.mem, pin?.mems[c.mode], c.bench, 3 + 2 * c.mode);
    if (c.mode === 0) {
      const comps = cells.filter((o) => o.bench === c.bench).map((o) => o.comp)
        .filter((x) => x !== null).sort((x, y) => x - y);
      pass += fits(comps[Math.floor(comps.length / 2)] ?? null, pin?.comp,
        c.bench, 1);
    }
  }
  for (const c of chks) {
    pass += fits(c.secs, cpins.get(c.bench), c.bench, 1);
  }
  const total = cells.length * 2 + new Set(cells.map((c) => c.bench)).size
    + chks.length;
  draw(cells, chks);
  if (process.stdout.isTTY !== true) {
    console.log(perf.VIEW.join("\n"));
  }
  if (process.argv.includes("--times")) {
    times(spans);
  }
  if (process.argv.includes("--png")) {
    png(fails, pass, total);
  }
  lib.verdict(pass, total);
}

function draw(cells: perf.Cell[], chks: perf.Chk[]): void {
  const [pins, cpins] = perf.pin_read();
  perf.view_draw(cells, chks, pins, cpins, [...cells, ...chks]
    .map((c) => c.note).filter((n) => n !== ""));
}

// Png
// ===

function xml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// The view's lines as an svg, one span per cell: a failed cell in red, the
// heads in blue, the rules and bars dim; then rsvg-convert makes the png
// (headless Chrome when it is missing).
function png(fails: Set<string>, pass: number, total: number): void {
  const head = child.spawnSync("git", ["rev-parse", "--short", "HEAD"],
    { cwd: lib.ROOT, encoding: "utf8" }).stdout.trim();
  const hosts = nodes_parse(arg("--nodes") ?? NODES).length;
  const lines = [
    [["bend2-core perf  ·  " + head + "  ·  " + new Date().toISOString()
      .slice(0, 10) + "  ·  " + String(hosts) + " minis  ·  pass at "
      + String(perf.SLACK) + "x of the apple_m4 pins or under", "t"]],
    [["red: failed", "d"]], [],
    ...perf.VIEW.map((line) => {
      if (/^\| bench /.test(line)) {
        return [[line, "h"]];
      }
      if (/^\|[-| ]+\|$/.test(line) || !line.startsWith("|")) {
        return [[line, line.startsWith("|") ? "d" : "r"]];
      }
      const parts = line.split("|");
      const bench = parts[1].trim();
      return parts.flatMap((part, i) => [...i === 0 ? [] : [["|", "d"]],
        [part, fails.has(bench + " " + String(i - 1)) ? "r" : ""]]);
    }), [],
    [["PASS: " + String(pass) + " / " + String(total), pass === total
      ? "g" : "r"]]] as [string, string][][];
  const size = 22;
  const cw = size * 0.602;
  const lh = 32;
  const pad = 36;
  const w = Math.ceil(pad * 2 + cw * Math.max(...lines.map((l) =>
    l.reduce((n, [t]) => n + t.length, 0))));
  const h = pad * 2 + lh * lines.length;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${String(w)}"`
    + ` height="${String(h)}"><style>text{font:${String(size)}px Menlo,`
    + ` Consolas, monospace;white-space:pre;fill:#1f2328}.t,.h,.r,.g`
    + `{font-weight:bold}.h{fill:#0550ae}.d{fill:#8c959f}.r{fill:#cf222e}`
    + `.g{fill:#1a7f37}</style><rect width="100%" height="100%"`
    + ` fill="#ffffff"/>` + lines.map((l, i) => `<text x="${String(pad)}"`
    + ` y="${String(pad + lh * (i + 0.7))}" xml:space="preserve">`
    + l.map(([t, k]) => `<tspan${k === "" ? "" : ` class="${k}"`}>`
      + xml(t) + "</tspan>").join("") + "</text>").join("") + "</svg>";
  const src = path.join(STAGE, "perf.svg");
  fs.writeFileSync(src, svg);
  const rsvg = child.spawnSync("rsvg-convert", ["-o", PNG, src]);
  if (rsvg.status === 0) {
    console.log("wrote " + PNG);
    return;
  }
  const chrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
  const shot = child.spawnSync(chrome, ["--headless", "--hide-scrollbars",
    "--screenshot=" + PNG, "--window-size=" + String(w) + "," + String(h),
    "file://" + src], { encoding: "utf8" });
  console.log(shot.status === 0 ? "wrote " + PNG : "no png: install"
    + " rsvg-convert (brew install librsvg) or Google Chrome; the svg is "
    + src);
}

// Main
// ====

const only = arg("--only")?.split(",");
const benches = fs.readdirSync(RUNTIME).filter((f) => !f.startsWith("_")
  && (only === undefined || only.includes(f))).sort();
const cells: perf.Cell[] = benches.flatMap((bench) => perf.MODES.map((_,
  mode) => ({ bench, mode, secs: null, mem: null, comp: null, out: "",
  note: "" })));
const chks: perf.Chk[] = process.argv.includes("--no-checker") ? []
  : fs.readdirSync(CHECKER).filter((f) => !f.startsWith("_")
    && (only === undefined || only.includes(f))).sort()
    .map((bench) => ({ bench, secs: null, note: "" }));
draw(cells, chks);
await remote(jobs_make(benches, chks.map((c) => c.bench)),
  nodes_parse(arg("--nodes") ?? NODES));
grade(cells, chks);
