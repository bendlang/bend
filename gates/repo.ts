#!/usr/bin/env bun
// The shape of the repo: every tracked file must match one allow line,
// and a textual file must stay under its ttok cap (a binary under its
// byte cap). Anything else in the tree is a failure. evals/ is not
// counted: it is the models' arena, not the repo's shape.

import * as child from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";

import * as lib from "./_lib";

// Types
// =====

type Rule = { at: RegExp; cap: number; bytes: boolean };

// Constants
// =========

const RULES: Rule[] = [];

// Allow
// =====

function allow(at: string | RegExp, cap: number, bytes = false): void {
  RULES.push({ at: typeof at === "string" ? new RegExp("^" + at
    .replace(/[.]/g, "\\.") + "$") : at, cap, bytes });
}

allow(/^\.github\/ISSUE_TEMPLATE\/(bug|config)\.yml$/, 600);
allow(".gitattributes", 200);
allow(".gitignore", 100);
allow("AGENTS.md", 2000);
allow("README.md", 3000);
allow("LICENSE", 4000);
allow("bend2/base.bend", 24000);
allow("bend2/bend.lean", 400000);
allow("bend2/bend.ts", 41000);
allow("bend2/comp.ts", 61000);
allow("bend2/main.ts", 10000);
allow(/^bend2\/effs\/[a-z_]+\.(c|js)$/, 4000);
allow(/^bend2\/pack\/(\.gitignore|package\.json|tsconfig\.json|bun\.lock)$/, 1000);
allow(/^bend2\/docs\/(BendRT|BendTT)\/(main\.typ|refs\.bib)$/, 60000);
allow("bend2/docs/bend.sublime-syntax", 1000);
allow("bend2/docs/gen_anim.ts", 7500);
allow("bend2/docs/gen_charts.ts", 4000);
allow("bend2/docs/gen_gifs.ts", 4000);
allow("bend2/docs/gen_pins.ts", 4100);
allow(/^bend2\/docs\/intro\/[a-z.]+$/, 20000);
allow(/^bench\/checker\/[a-z]+_[0-9]+\/main\.(bend|agda|lean|thy|v)$/, 3000000);
allow(/^bench\/checker\/_pin_\/[a-z0-9_]+\.txt$/, 2000);
allow(/^bench\/runtime\/[a-z-]+\/main\.(bend|c|lean|ts)$/, 8000);
allow(/^bench\/runtime\/_pin_\/[a-z0-9_]+\.txt$/, 2000);
allow(/^demos\/[a-z0-9_]+\/[A-Za-z0-9_]+\.bend$/, 64000);
allow(/^demos\/[a-z0-9_]+\/[A-Za-z_]+\.(c|sh|md)$/, 4000);
allow(/^demos\/[a-z0-9_]+\/web\/(index\.html|main\.js|bunfig\.toml)$/, 4000);
allow("guide/GUIDE.md", 12000);
allow(/^paper\/(BendRT|BendTT)\.pdf$/, 400000, true);
allow(/^media\/intro\.(gif|mp4)$/, 25000000, true);
allow(/^media\/(runtime|checker|parallel)\.gif$/, 6000000, true);
allow(/^media\/hero(_dark)?\.gif$/, 200000, true);
allow(/^media\/logo_(bend|hoc)\.png$/, 100000, true);
allow(/^media\/game_[a-z_]+\.gif$/, 2000000, true);
allow(/^media\/slash_boss_3d\/[a-z_]+\.wav$/, 400000, true);
allow(/^gates\/(_lib|_run|perf|ping|repo|test)\.ts$/, 6000);
allow(/^tests\/[a-z]+\/[a-z0-9_]+\.bend$/, 16000);
allow(/^tests\/[a-z]+\/[a-z0-9_]+\.(c|js)$/, 8000);

// Gate
// ====

function ttok(file: string): number {
  const got = child.spawnSync("ttok", [], { input: fs.readFileSync(file) });
  return Number(got.stdout.toString().trim());
}

function gate(): string[] {
  const fails: string[] = [];
  const files = child.execFileSync("git", ["ls-files"], { cwd: lib.ROOT,
    encoding: "utf8" }).trim().split("\n");
  for (const file of files) {
    if (file.startsWith("evals/")) continue;
    const rule = RULES.find((r) => r.at.test(file));
    if (rule === undefined) {
      fails.push(file + ": not in the allow list");
      continue;
    }
    const full = path.join(lib.ROOT, file);
    const size = fs.statSync(full).size;
    const n = rule.bytes || size <= rule.cap ? size : ttok(full);
    if (n > rule.cap) {
      fails.push(file + ": " + String(n) + " > " + String(rule.cap)
        + (rule.bytes ? " bytes" : " ttok"));
    }
  }
  return fails;
}

// Main
// ====

if (import.meta.main) {
  const fails = gate();
  if (!lib.GATE) {
    for (const f of fails) {
      console.log("FAIL " + f);
    }
  }
  lib.verdict(RULES.length - Math.min(RULES.length, fails.length),
    RULES.length);
}
