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

import * as lib from "./_lib";

const CAP = 30_000;

const kids = ["repo", "test", "perf", "ping"].map((gate) => [gate, child.spawn(
  process.execPath, [path.join(import.meta.dirname, gate + ".ts"), "--gate"],
  { stdio: ["ignore", "pipe", "pipe"] })] as const);

// A gate that passes speaks in one line (its verdict); a gate that fails
// speaks in full, so a crash (a node pool run dry, an uncaught error) shows
// its message and not Bun's version banner, which is the last line it prints.
// A gate that could not run leaves with lib.SKIP: it is reported as such and
// never counted as a pass, so a partial run cannot read as a green one.
const runs = kids.map(([gate, kid]) => new Promise<number>((done) => {
  let out = "";
  let err = "";
  kid.stdout.on("data", (d: Buffer) => { out += d.toString(); });
  kid.stderr.on("data", (d: Buffer) => { err += d.toString(); });
  kid.on("close", (code) => {
    const last = out.trim().split("\n").pop() ?? "";
    // A skip is a claim, and a claim needs evidence. The exit code alone is not
    // proof: any crash that happens to leave 2 would look like one, and
    // BEND_ALLOW_SKIP would then absorb it. So a skip must leave 2 AND say
    // "SKIP:" as its last word AND have written nothing to stderr -- verdict_skip
    // does exactly that and nothing else. A gate that skipped but also
    // complained fails closed, which is the safe direction. Anything stronger
    // wants a verdict channel of its own rather than the output stream.
    const state = code === 0 ? 0
      : code === lib.SKIP && err.trim() === "" && last.startsWith("SKIP:")
        ? lib.SKIP : 1;
    console.log(gate.padEnd(5) + " " + (state === 0 ? last : (last + "\n" + err).trim()));
    done(state);
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
const skipped = kids.filter((_, i) => oks[i] === lib.SKIP).map(([g]) => g);
if (skipped.length > 0) {
  // An affirmative value only: BEND_ALLOW_SKIP=0, =false or = (empty) must mean
  // off, so a caller cannot opt in by accident while meaning to opt out.
  const allow = /^(1|true|yes)$/i.test(process.env.BEND_ALLOW_SKIP ?? "");
  console.log((allow ? "SKIPPED: " : "FAIL: ") + skipped.join(", ")
    + " did not run" + (allow ? " (BEND_ALLOW_SKIP is set)"
      : "; set BEND_ALLOW_SKIP=1 to accept a partial run"));
  process.exit(allow && oks.every((s) => s !== 1) ? 0 : 1);
}
process.exit(oks.every((ok) => ok === 0) ? 0 : 1);
