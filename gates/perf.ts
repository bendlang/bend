#!/usr/bin/env bun
// Runs the benchmarks on the cluster: every runtime bench in each of its
// three modes on its own mini (48 cells), plus the five checker benches,
// and draws one fixed screen with each measure beside its ratio to the
// pin. A runtime cell runs `bend main.bend -o main` twice and times the
// second for the COMPILER column (the first build on a node after a
// pause pays the cold compiler service and module cache: 0.95 s against
// 0.62 for bfs), then asks for the C alone (`-o main.c`: a plain `-o`
// emits into a temp dir and drops it) and builds that with the cc line (the
// -O3 of bend -o: no -lm, no -fmodules, no -fno-slp-vectorize, so the
// gate grades the binary bend builds) and runs it with the flags the
// pins were measured with (PAR on the power of two under the core
// count, GPU over the bench's span), one warm run and one timed
// by a microsecond clock around /usr/bin/time -l, whose own 10 ms tick
// cannot grade a 50 ms GPU cell (its RSS is the space). A cell passes at
// 1.15x or under; --pin runs every
// cell three times and writes the medians as the new pins (a space in
// tenths of a megabyte, so a 2.5 MB program is not graded against "2M"),
// refusing to write while any cell is unmeasured; --gate prints only the
// verdict.

import * as child from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";

import * as lib from "./_lib";

// Types
// =====

type Cell = {
  bench: string;
  mode: number;
  secs: number | null;
  mem: number | null;
  comp: number | null;
  out: string;
  note: string;
};

type Chk = { bench: string; secs: number | null; note: string };

type Pin = { comp: number; secs: number[]; mems: number[]; out: string };

// Constants
// =========

const PIN = process.argv.includes("--pin");

const RUNTIME = path.join(lib.ROOT, "bench", "runtime");

const CHECKER = path.join(lib.ROOT, "bench", "checker");

const HW = "apple_m4";

export const MODES = ["SEQ-CPU", "PAR-CPU", "PAR-GPU"];

export const CC = "cc -std=c11 -O3";

export const BUILD = [CC + " main.c -lpthread", CC + " main.c -lpthread",
  CC + " -DBEND_METAL=1 -x objective-c -fobjc-arc main.c -lpthread"
  + " -framework Metal -framework Foundation"];

const THREADS = "nt=1; while [ $nt -lt $(getconf _NPROCESSORS_ONLN) ] &&"
  + " [ $nt -lt 256 ]; do nt=$((nt*2)); done;";

export const FLAGS = ["--threads 1 --gpu off", "--threads $nt --gpu off",
  "--gpu $gm"];

export const MEMORY: Record<string, string> = {
  "tree-bitonic": "768MB", gameoflife: "512MB", kmeans: "768MB",
  mandelbrot: "512MB", merkle: "768MB", nbody: "768MB",
  queens: "512MB", raytrace: "512MB", symreg: "512MB", terrain: "1GB",
};

const SLACK = 1.15;

const MARK = "@@B4";

const CLOCK = "perl -MTime::HiRes=time -e 'print time'";

const VIEW: string[] = [];

let drawn = 0;

// Fmt
// ===

function fmt_secs(x: number): string {
  return x < 10 ? x.toFixed(3) + "s" : x < 100 ? x.toFixed(2) + "s"
    : x < 1000 ? x.toFixed(1) + "s" : String(Math.round(x)).padStart(5) + "s";
}

function fmt_mem(mb: number): string {
  return mb < 100 ? mb.toFixed(1) + "M" : mb < 10000
    ? String(Math.round(mb)) + "M" : (mb / 1024).toFixed(2) + "G";
}

function fmt_ratio(got: number, pin: number | undefined): string {
  if (pin === undefined || pin === 0) {
    return "    -";
  }
  const x = got / pin;
  return (x < 10 ? x.toFixed(2) : x < 100 ? x.toFixed(1)
    : String(Math.round(x))).padStart(4) + "x";
}

function fmt_cell(got: number | null, pin: number | undefined,
  fmt: (x: number) => string, note: string): string {
  if (got === null) {
    return note === "" ? "" : "err";
  }
  return fmt(got).padStart(6) + "   " + fmt_ratio(got, pin);
}

// View
// ====

function view_rows(name: string, heads: string[], rows: string[][],
  spaced: boolean): string[] {
  const bar = "-".repeat(13);
  const cbar = "-".repeat(16);
  const line = spaced
    ? "| " + bar + " |" + heads.map(() => " " + cbar + " |").join("")
    : "|" + bar + "--|" + heads.map(() => cbar + "--|").join("");
  return ["| " + "bench".padEnd(13) + " |" + heads.map((h) =>
    " " + h.padEnd(16) + " |").join(""), line, ...rows.map((r) =>
    "| " + r[0].padEnd(13) + " |" + r.slice(1).map((c) =>
      " " + c.padEnd(16) + " |").join(""))];
}

function view_draw(cells: Cell[], chks: Chk[], pins: Map<string, Pin>,
  cpins: Map<string, number>, notes: string[]): void {
  const heads = ["COMPILER TIME", ...MODES.flatMap((m) =>
    [m + " TIME", m + " SPACE"])];
  const benches = [...new Set(cells.map((c) => c.bench))];
  const rows = benches.map((b) => {
    const cs = MODES.map((_, m) => cells.find((c) =>
      c.bench === b && c.mode === m) as Cell);
    const comps = cs.map((c) => c.comp).filter((x) => x !== null);
    const comp = comps.length === 0 ? null
      : [...comps].sort((x, y) => x - y)[Math.floor(comps.length / 2)];
    const pin = pins.get(b);
    return [b, fmt_cell(comp, pin?.comp, fmt_secs, ""), ...cs.flatMap((c) =>
      [fmt_cell(c.secs, pin?.secs[c.mode], fmt_secs, c.note),
        fmt_cell(c.mem, pin?.mems[c.mode], fmt_mem, c.note)])];
  });
  const crow = chks.map((c) => [c.bench,
    fmt_cell(c.secs, cpins.get(c.bench), fmt_secs, c.note)]);
  const lines = [...view_rows("bench", heads, rows, false), "",
    ...view_rows("bench", ["CHECKER TIME"], crow, true), ...notes.length === 0
    ? [] : ["", ...notes]];
  VIEW.splice(0, VIEW.length, ...lines);
  if (process.stdout.isTTY === true && !lib.GATE) {
    const up = drawn > 0 ? "\x1b[" + String(drawn) + "A" : "";
    process.stdout.write(up + lines.map((l) => "\x1b[2K" + l + "\n").join(""));
    drawn = lines.length;
  }
}

// Pin
// ===

function pin_read(): [Map<string, Pin>, Map<string, number>] {
  const pins = new Map<string, Pin>();
  const cpins = new Map<string, number>();
  const rows = (file: string): [string, string[]][] => {
    try {
      return fs.readFileSync(file, "utf8").split("\n").flatMap((line) => {
        const row = /^\| (\S+)\s*\|(.*)\|$/.exec(line);
        return row === null || row[1] === "bench" || row[2].startsWith("-")
          ? [] : [[row[1], row[2].split("|").map((c) => c.trim())]];
      });
    } catch {
      return [];
    }
  };
  const num = (c: string): number => Number(/[\d.]+/.exec(c)?.[0] ?? 0);
  for (const [b, c] of rows(path.join(RUNTIME, "_pin_", HW + ".txt"))) {
    const cell = (i: number): number[] => c[i].split(/\s+/).map(num);
    pins.set(b, { comp: num(c[0]), secs: [1, 2, 3].map((i) => cell(i)[0]),
      mems: [1, 2, 3].map((i) => cell(i)[1]), out: c[4] });
  }
  for (const [b, c] of rows(path.join(CHECKER, "_pin_", HW + ".txt"))) {
    cpins.set(b, num(c[0]));
  }
  return [pins, cpins];
}

function pin_write(cells: Cell[], chks: Chk[]): void {
  const head = child.spawnSync("git", ["rev-parse", "--short", "HEAD"],
    { cwd: lib.ROOT, encoding: "utf8" }).stdout.trim();
  const stamp = "# " + new Date().toISOString().slice(0, 10) + " " + head
    + " bun gates/perf.ts --pin";
  const benches = [...new Set(cells.map((c) => c.bench))];
  const w = Math.max(10, ...benches.map((b) => b.length),
    ...chks.map((c) => c.bench.length));
  const bar = (n: number): string => "-".repeat(n + 2);
  const rows = benches.map((b) => {
    const cs = MODES.map((_, m) => cells.find((c) =>
      c.bench === b && c.mode === m) as Cell);
    const comps = cs.map((c) => c.comp ?? 0).sort((x, y) => x - y);
    return "| " + b.padEnd(w) + " | " + fmt_secs(comps[1]).padStart(8)
      + " |" + cs.map((c) => " " + fmt_secs(c.secs ?? 0).padStart(8) + " "
        + fmt_mem(c.mem ?? 0).padStart(7) + " |").join("") + " "
      + cs[0].out.padEnd(10) + " |";
  });
  fs.writeFileSync(path.join(RUNTIME, "_pin_", HW + ".txt"), [stamp,
    "| " + "bench".padEnd(w) + " | COMPILER |" + MODES.map((m) =>
      " " + m.padEnd(16) + " |").join("") + " OUTPUT     |",
    "|" + bar(w) + "|" + bar(8) + "|" + MODES.map(() => bar(16) + "|").join("")
      + bar(10) + "|", ...rows, ""].join("\n"));
  fs.writeFileSync(path.join(CHECKER, "_pin_", HW + ".txt"), [stamp,
    "| " + "bench".padEnd(w) + " | CHECKER  |", "|" + bar(w) + "|" + bar(8)
      + "|", ...chks.map((c) => "| " + c.bench.padEnd(w) + " | "
      + fmt_secs(c.secs ?? 0).padStart(8) + " |"), ""].join("\n"));
}

// Cell
// ====

// Every runtime cell gets the one pack of bench/runtime and builds its
// bench out of it.
function cell_script(c: Cell): string {
  const run = "./cell " + FLAGS[c.mode].replace("$gm", MEMORY[c.bench] ?? "on");
  const src = "runtime/" + c.bench + "/main.bend";
  return `d=$HOME/bend-perf/${c.bench}-${String(c.mode)}; rm -rf $d;`
    + ` mkdir -p $d; cd $d; tar -xzf -; ${THREADS} ${lib.BUN} bend2/main.ts`
    + ` ${src} -o main > /dev/null 2>&1; t0=$(${CLOCK}); ${lib.BUN}`
    + ` bend2/main.ts ${src} -o main > build.txt 2>&1; b=$?;`
    + ` t1=$(${CLOCK}); [ $b = 0 ] && { ${lib.BUN} bend2/main.ts ${src}`
    + ` -o main.c >> build.txt 2>&1 && ${BUILD[c.mode]} -o cell >> build.txt`
    + ` 2>&1; b=$?; }; echo "${MARK} built $b $t0 $t1"; cat build.txt;`
    + ` if [ $b = 0 ]; then ${run} > /dev/null 2>&1; t2=$(${CLOCK});`
    + ` /usr/bin/time -l ${run} > out.txt 2> time.txt; r=$?; t3=$(${CLOCK});`
    + ` echo "${MARK} ran $r $t2 $t3"; cat out.txt; echo "${MARK} time";`
    + ` cat time.txt; fi; cd; rm -rf $d`;
}

function cell_note(out: string): string {
  const line = out.trim().split("\n").filter((l) => !l.startsWith(MARK)
    && !/ real | maximum resident|^\s*\d+\s+\w/.test(l)).pop() ?? "";
  return line.slice(0, 100);
}

async function cell_run(c: Cell, node: number, pack: Buffer): Promise<void> {
  const got = await lib.ssh(node, cell_script(c), pack, 20 * 60 * 1000);
  const built = new RegExp("^" + MARK + " built (\\d+) ([\\d.]+) ([\\d.]+)$",
    "m")
    .exec(got.out);
  const ran = new RegExp("^" + MARK + " ran (\\d+) ([\\d.]+) ([\\d.]+)$", "m")
    .exec(got.out);
  if (built === null) {
    throw new Error("node", { cause: got.err });
  }
  c.comp = Number(built[3]) - Number(built[2]);
  if (built[1] !== "0" || ran === null || ran[1] !== "0") {
    c.note = c.bench + " " + MODES[c.mode] + ": " + (built[1] !== "0"
      ? "build: " : "exit " + String(ran?.[1] ?? "?") + ": ")
      + cell_note(got.out);
    return;
  }
  const tail = got.out.split(new RegExp("^" + MARK + " ran .*\n", "m"))[1];
  const [body, time] = (tail ?? "").split(MARK + " time\n");
  const rss = /(\d+)\s+maximum resident set size/.exec(time ?? "");
  c.out = body.split("\n").map((l) => l.trim()).filter((l) => l !== "")
    .pop() ?? "";
  c.secs = Number(ran[3]) - Number(ran[2]);
  c.mem = rss === null ? null : Number(rss[1]) / (1 << 20);
  if (c.mem === null) {
    c.note = c.bench + " " + MODES[c.mode] + ": unreadable time output";
  }
}

// Chk
// ===

// A checker bench is megabytes of source, so each ships in its own pack.
async function chk_run(c: Chk, node: number): Promise<void> {
  const script = `d=$HOME/bend-perf/chk-${c.bench}; rm -rf $d; mkdir -p $d;`
    + ` cd $d; tar -xzf -; for i in 1 2 3; do t0=$(${CLOCK}); ${lib.BUN}`
    + ` bend2/main.ts ${c.bench}/main.bend > out.txt 2>&1; e=$?;`
    + ` t1=$(${CLOCK}); echo "${MARK} check $e $t0 $t1"; cat out.txt; done;`
    + ` cd; rm -rf $d`;
  const got = await lib.ssh(node, script,
    lib.pack(path.join(CHECKER, c.bench)), 20 * 60 * 1000);
  const runs = [...got.out.matchAll(new RegExp("^" + MARK
    + " check (\\d+) ([\\d.]+) ([\\d.]+)$", "gm"))];
  if (runs.length === 0) {
    throw new Error("node", { cause: got.err });
  }
  if (runs.some((r) => r[1] !== "0") || !got.out.includes("All terms check.")) {
    c.note = c.bench + ": " + cell_note(got.out);
    return;
  }
  c.secs = Math.min(...runs.map((r) => Number(r[3]) - Number(r[2])));
}

// Main
// ====

if (import.meta.main) {
  const benches = fs.readdirSync(RUNTIME).filter((f) => !f.startsWith("_"))
    .sort();
  const reps = PIN ? 3 : 1;
  let cells: Cell[] = benches.flatMap((bench) => MODES.flatMap((_, mode) =>
    Array.from({ length: reps }, () => ({ bench, mode, secs: null,
      mem: null, comp: null, out: "", note: "" }))));
  const chks: Chk[] = fs.readdirSync(CHECKER).filter((f) => !f.startsWith("_"))
    .sort().map((bench) => ({ bench, secs: null, note: "" }));
  const [pins, cpins] = PIN
    ? [new Map<string, Pin>(), new Map<string, number>()]
    : pin_read();
  const notes = (): string[] => [...cells, ...chks].map((c) => c.note)
    .filter((n) => n !== "");
  const draw = (): void => view_draw(cells, chks, pins, cpins, notes());
  draw();
  const nodes = await lib.node_lock();
  const pack = lib.pack(RUNTIME);
  await lib.node_pool(nodes, [...cells.map((c) => async (node: number) => {
    await cell_run(c, node, pack);
    draw();
  }), ...chks.map((c) => async (node: number) => {
    await chk_run(c, node);
    draw();
  })]);
  if (PIN) {
    const mid = (xs: (number | null)[]): number | null => {
      const ys = xs.filter((x) => x !== null).sort((x, y) => x - y);
      return ys.length === xs.length ? ys[Math.floor(ys.length / 2)] : null;
    };
    cells = benches.flatMap((bench) => MODES.map((_, mode) => {
      const cs = cells.filter((c) => c.bench === bench && c.mode === mode);
      return { bench, mode, secs: mid(cs.map((c) => c.secs)),
        mem: mid(cs.map((c) => c.mem)), comp: mid(cs.map((c) => c.comp)),
        out: cs[0].out, note: cs.map((c) => c.note).find((n) => n !== "")
          ?? (cs.every((c) => c.out === cs[0].out) ? "" : bench + " "
          + MODES[mode] + ": the runs printed different outputs") };
    }));
    if (notes().length > 0) {
      console.log(notes().join("\n"));
      lib.verdict(0, 1);
    }
    pin_write(cells, chks);
  }
  const fits = (got: number | null, pin: number | undefined): boolean =>
    got !== null && (PIN || pin !== undefined && got <= pin * SLACK);
  let pass = 0;
  for (const c of cells) {
    const pin = pins.get(c.bench);
    if (!PIN && pin !== undefined && c.out !== pin.out && c.secs !== null) {
      c.note = c.bench + " " + MODES[c.mode] + ": output " + c.out
        + " differs from the pinned " + pin.out;
      c.secs = null;
    }
    pass += Number(fits(c.secs, pin?.secs[c.mode]))
      + Number(fits(c.mem, pin?.mems[c.mode]));
    if (c.mode === 0) {
      const comps = cells.filter((o) => o.bench === c.bench).map((o) => o.comp)
        .filter((x) => x !== null).sort((x, y) => x - y);
      pass += Number(fits(comps[Math.floor(comps.length / 2)] ?? null,
        pin?.comp));
    }
  }
  for (const c of chks) {
    pass += Number(fits(c.secs, cpins.get(c.bench)));
  }
  draw();
  if (!lib.GATE && process.stdout.isTTY !== true) {
    console.log(VIEW.join("\n"));
  }
  lib.verdict(pass, cells.length * 2 + benches.length + chks.length);
}
