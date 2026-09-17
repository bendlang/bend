#!/usr/bin/env bun
// Runs the four gates with --gate, side by side, and prints their verdicts.
//
// LAW: THE RUN HAS 30 SECONDS. When the gates are not all done at CAP, they
// are killed and the run FAILS with "the gates ran past the 30 s cap". The
// tests MUST NOT take longer than that, ever. Do NOT raise CAP, do NOT catch
// or skip the failure, do NOT move slow work out of a gate to dodge it: find
// the slow test, the slow build or the slow plumbing and make it cheap, or
// delete it. This law exists because in September 2026 two tests of arity
// 255 put the test gate at 284 s and nothing enforced the limit, so nobody
// noticed for days.

import * as child from "node:child_process";
import * as path from "node:path";

const CAP = 30_000;

const kids = ["repo", "test", "perf", "ping"].map((gate) => [gate, child.spawn(
  process.execPath, [path.join(import.meta.dirname, gate + ".ts"), "--gate"],
  { stdio: ["ignore", "pipe", "pipe"] })] as const);

// A gate that passes speaks in one line (its verdict); a gate that fails
// speaks in full, so a crash (a node pool run dry, an uncaught error) shows
// its message and not Bun's version banner, which is the last line it prints.
const runs = kids.map(([gate, kid]) => new Promise<boolean>((done) => {
  let out = "";
  let err = "";
  kid.stdout.on("data", (d: Buffer) => { out += d.toString(); });
  kid.stderr.on("data", (d: Buffer) => { err += d.toString(); });
  kid.on("close", (code) => {
    const last = out.trim().split("\n").pop() ?? "";
    console.log(gate.padEnd(5) + " " + (code === 0 ? last : (last + "\n" + err).trim()));
    done(code === 0);
  });
}));

const bomb = setTimeout(() => {
  console.log("FAIL: the gates ran past the " + String(CAP / 1000) + " s cap");
  for (const [, kid] of kids) {
    kid.kill("SIGKILL");
  }
  process.exit(1);
}, CAP);

const oks = await Promise.all(runs);
clearTimeout(bomb);
process.exit(oks.every((ok) => ok) ? 0 : 1);
