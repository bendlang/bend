#!/usr/bin/env bun
// The numbers the landing page and the film quote, all from the record
// pins: this script measures NOTHING. Every figure comes from
// bench/*/_pin_/apple_m4_max.txt, which holds only what gen_pins.ts
// measured on this machine at the stamped commit. Repin first, then
// quote, then draw the README's gifs (gen_gifs.ts, on a mini):
//
//   bun bend2/docs/gen_pins.ts
//   bun bend2/docs/gen_charts.ts
//
// The site repo's front/site/index.html (beside this checkout, or at
// $SITE_REPO) has chart rows that keep their ids and titles and take
// their seconds from the pins; render.js's BENCH and CHECK take theirs
// the same way (render the film after) and its comment names the
// stamps. A checker timeout (>=300 s) is quoted as 300 and flagged
// over. gen_gifs.ts imports the pin readers below: they are the one
// source of every bar and figure.

import * as fs from "node:fs";
import * as path from "node:path";

// Constants
// =========

export const ROOT = path.join(import.meta.dirname, "..", "..");
export const RUNTIME_PIN = path.join(ROOT, "bench", "runtime", "_pin_",
  "apple_m4_max.txt");
export const CHECKER_PIN = path.join(ROOT, "bench", "checker", "_pin_",
  "apple_m4_max.txt");
export const CHECK_TIMEOUT = 300;

function say(text: string): void {
  process.stdout.write(text + "\n");
}

// Pins
// ====

export type RunRow = { bench: string; seq: number; par: number;
  gpu: number; c: number; ts: number; lean: number };

export type CheckRow = { family: string; n: number; lang: string;
  secs: number; over: boolean };

function pin_grid(file: string, heads: string[]): [string, string[]][] {
  const out: [string, string[]][] = [];
  for (const line of fs.readFileSync(file, "utf8").split("\n")) {
    const row = /^\| (\S+)\s*\|(.*)\|$/.exec(line);
    if (row === null) {
      continue;
    }
    const cells = row[2].split("|").map((c) => c.trim());
    if (row[1] === heads[0]) {
      if (cells.join(",") !== heads.slice(1).join(",")) {
        throw new Error(file + ": columns drifted from [" +
          heads.join(", ") + "] -- repin");
      }
      continue;
    }
    out.push([row[1], cells]);
  }
  if (out.length === 0) {
    throw new Error(file + ": no pin rows -- repin");
  }
  return out;
}

function pin_secs(cell: string): number {
  const got = /^(>?)([\d.]+)s/.exec(cell);
  if (got === null) {
    throw new Error("unreadable pin cell: " + cell);
  }
  return Number(got[2]);
}

export function pin_runtime(): RunRow[] {
  return pin_grid(RUNTIME_PIN, ["bench", "SEQ-CPU", "PAR-CPU",
    "PAR-GPU", "C", "TS", "Lean"]).map(([bench, c]) => ({
    bench, seq: pin_secs(c[0]), par: pin_secs(c[1]), gpu: pin_secs(c[2]),
    c: pin_secs(c[3]), ts: pin_secs(c[4]), lean: pin_secs(c[5]),
  }));
}

export function pin_checker(): CheckRow[] {
  const langs = ["isabelle", "agda", "lean", "rocq", "bend"];
  return pin_grid(CHECKER_PIN, ["bench", "Isabelle", "Agda", "Lean",
    "Rocq", "Bend"]).flatMap(([name, cells]) => {
    const cut = name.lastIndexOf("_");
    const family = name.slice(0, cut);
    const n = Number(name.slice(cut + 1));
    return langs.map((lang, i): CheckRow => ({
      family, n, lang, secs: pin_secs(cells[i]),
      over: cells[i].startsWith(">"),
    }));
  });
}

export function pin_stamp(file: string): string {
  const got = /^# (\d{4}-\d\d-\d\d) ([0-9a-f]+) /m
    .exec(fs.readFileSync(file, "utf8"));
  if (got === null) {
    throw new Error(file + ": no stamp line -- repin");
  }
  return "(" + got[1] + ", " + got[2] + ")";
}

// Front
// =====

export const SITE = process.env.SITE_REPO ?? path.join(ROOT, "..", "bend-lang.com");
export const FRONT = path.join(SITE, "front", "site", "index.html");

// The landing page's chart rows: `["id", "title", secs...],`; the title
// of every bench and checker family lives there, and only there.
export function front_titles(): Record<string, string> {
  const out: Record<string, string> = {};
  for (const line of fs.readFileSync(FRONT, "utf8").split("\n")) {
    const row = /^\s*\["([a-z0-9_-]+)", "([^"]*)",/.exec(line);
    if (row !== null) {
      out[row[1]] = row[2];
    }
  }
  return out;
}

// Quote
// =====

function quote_secs(r: { secs: number; over: boolean }): string {
  return r.over ? String(CHECK_TIMEOUT) : r.secs.toFixed(3);
}

function quote_front(runs: RunRow[], checks: CheckRow[]): void {
  fs.writeFileSync(FRONT, fs.readFileSync(FRONT, "utf8").split("\n")
    .map((line) => {
      const row = /^(\s*\["([a-z0-9_-]+)", "[^"]*",) [^\]]*\],$/.exec(line);
      if (row === null) {
        return line;
      }
      const run = runs.find((r) => r.bench === row[2]);
      const cells = run !== undefined
        ? [run.ts, run.lean, run.c, run.seq, run.par, run.gpu]
          .map((x) => x.toFixed(3))
        : checks.filter((c) => c.family + "_" + String(c.n) === row[2])
          .map(quote_secs);
      if (cells.length === 0) {
        throw new Error(FRONT + ": " + row[2] + " has no pin");
      }
      return row[1] + " " + cells.join(", ") + "],";
    }).join("\n"));
  say("wrote " + FRONT);
}

function quote_film(runs: RunRow[], checks: CheckRow[]): void {
  const file = path.join(ROOT, "bend2", "docs", "intro", "render.js");
  const text = fs.readFileSync(file, "utf8");
  const bench = /^const BENCH = \{\n  ([a-z]+):/m.exec(text)?.[1];
  const run = runs.find((r) => r.bench === bench);
  const family = /^\/\/ CHECK: (\S+)$/m.exec(text)?.[1];
  const check = checks.filter((c) => c.family + "_" + String(c.n) === family);
  if (run === undefined || check.length !== 5) {
    throw new Error(file + ": BENCH " + String(bench) + " or CHECK "
      + String(family) + " has no pin");
  }
  const names = ["Isabelle", "Agda", "Lean", "Rocq", "Bend"];
  const stamps = [pin_stamp(RUNTIME_PIN), pin_stamp(CHECKER_PIN)];
  fs.writeFileSync(file, text
    .replace(/rivals: \[[^\n]*\],/, `rivals: [["TypeScript", ${
      run.ts.toFixed(3)}], ["Lean", ${run.lean.toFixed(3)}], ["C", ${
      run.c.toFixed(3)}]],`)
    .replace(/seq: [\d.]+, par: [\d.]+, gpu: [\d.]+/, `seq: ${
      run.seq.toFixed(3)}, par: ${run.par.toFixed(3)}, gpu: ${
      run.gpu.toFixed(3)}`)
    .replace(/^const CHECK = \[[^;]*\];$/m, "const CHECK = [" + check.map(
      (c, i) => `["${names[i]}", ${quote_secs(c)}${c.over ? ", true" : ""}]`)
      .join(", ") + "];")
    .replace(/\(\d{4}-\d\d-\d\d, [0-9a-f]+\)/g, () => stamps.shift() ?? ""));
  say("wrote " + file);
}

// Main
// ====

if (import.meta.main) {
  const runs = pin_runtime();
  const checks = pin_checker();
  quote_front(runs, checks);
  quote_film(runs, checks);
}
