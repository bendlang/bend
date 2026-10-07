#!/usr/bin/env bun
// bend-lint: checks a Bend file with bend's checker, then runs rules on it.
// Exit: 0 ok, 1 an error was found, 2 bad usage or a tool failure.

import * as fs from "node:fs";

import { pin } from "./instrument.ts";

const USAGE = [
  "usage: bun tools/bend-lint/src/cli.ts <file.bend> --rules <module> [--rules <module>...] [--fix]",
  "       bun tools/bend-lint/src/cli.ts --pin   (pin the current bend2/bend.ts)",
].join("\n");

function usage(msg: string): number {
  console.error("bend-lint: " + msg + "\n" + USAGE);
  return 2;
}

async function main(argv: string[]): Promise<number> {
  let file: string | undefined;
  const mods: string[] = [];
  let fix = false;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--pin") {
      console.log("bend-lint: pinned bend2/bend.ts " + pin());
      return 0;
    } else if (a === "--rules") {
      const m = argv[++i];
      if (m === undefined || m.startsWith("-")) return usage("--rules needs a module");
      mods.push(m);
    } else if (a === "--fix") {
      fix = true;
    } else if (a === "-h" || a === "--help") {
      console.log(USAGE);
      return 0;
    } else if (a.startsWith("-")) {
      return usage("unknown option " + a);
    } else if (file === undefined) {
      file = a;
    } else {
      return usage("one file at a time");
    }
  }
  if (file === undefined) return usage("no file");
  // loaded here, after --pin, so a pin mismatch does not block --pin
  const { lint } = await import("./lint.ts");
  const { render, applyFixes } = await import("./diag.ts");
  const { loadRules } = await import("./rules.ts");
  const res = await lint(file, await loadRules(mods));
  for (const d of res.diags) {
    console.log(render(d) + "\n");
  }
  if (fix && res.ok) {
    for (const src of res.sources) {
      if (src.base) continue;
      const out = applyFixes(src.file, res.diags);
      if (out !== src.text) {
        fs.writeFileSync(src.path, out);
        console.error("bend-lint: fixed " + src.path);
      }
    }
  }
  console.log(res.ok ? "bend-lint: " + res.diags.length + " finding(s)" : "bend-lint: FAIL");
  return res.ok ? 0 : 1;
}

try {
  process.exit(await main(process.argv.slice(2)));
} catch (e) {
  console.error("bend-lint: " + (e instanceof Error ? e.message : String(e)));
  process.exit(2);
}
