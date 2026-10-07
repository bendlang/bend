import { afterAll, expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

const cli = fileURLToPath(new URL("../src/cli.ts", import.meta.url));
const fixture = fileURLToPath(new URL("./fixtures/userland.bend", import.meta.url));
const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-lint-cli-"));
afterAll(() => fs.rmSync(dir, { recursive: true, force: true }));

const input = path.join(dir, "cli.bend");
fs.writeFileSync(input, fs.readFileSync(fixture, "utf8"));

function rule(name: string, body: string): string {
  const file = path.join(dir, name);
  fs.writeFileSync(file, "export default " + body + ";\n");
  return file;
}

const first = rule("first.js", `[{ id: "cli/first", needsTypes: true, run(cx) {
  if (!cx.facts?.size || !cx.sources.length) throw new Error("missing metadata");
  return [cx.diag({ message: "First rule", severity: "warning" })];
} }]`);
const second = rule("second.ts", `[{ id: "cli/second", run(cx) {
  if (cx.prior[0]?.code !== "cli/first") throw new Error("wrong rule order");
  return [cx.diag({ message: "Second rule", severity: "hint" })];
} }]`);
const blocking = rule("error.js", `[{ id: "cli/error", run(cx) {
  return [cx.diag({ message: "Blocked by rule", severity: "error" })];
} }]`);

function run(...args: string[]) {
  return spawnSync(process.execPath, [cli, ...args], { encoding: "utf8" });
}

test("rules run in order and print bend's layout", () => {
  const out = run(input, "--rules", first, "--rules", second);
  expect(out.status).toBe(0);
  expect(out.stdout).toMatch(/Warning \[cli\/first\]:[\s\S]*Hint \[cli\/second\]:/);
});

test("an error finding exits 1", () => {
  const out = run(input, "--rules", blocking);
  expect(out.status).toBe(1);
  expect(out.stdout).toContain("Error [cli/error]:");
});

test("a failed check exits 1", () => {
  const bad = path.join(dir, "bad.bend");
  fs.writeFileSync(bad, "def broken(\n");
  const out = run(bad);
  expect(out.status).toBe(1);
  expect(out.stdout).toContain("Error [bend/check]:");
});

test("bad usage and bad modules exit 2", () => {
  expect(run().status).toBe(2);
  expect(run(input, "--rules").status).toBe(2);
  expect(run(input, "--nope").status).toBe(2);
  expect(run(input, "--rules", path.join(dir, "missing.js")).status).toBe(2);
  expect(run(input, "--rules", rule("object.js", "{}")).stderr).toMatch(/must default-export an array/);
  expect(run(input, "--rules", rule("bad.js", `[{ id: "bad", run() { return []; } }]`)).stderr).toMatch(/invalid rule/);
  const bend = path.join(dir, "rule.bend");
  fs.writeFileSync(bend, "");
  expect(run(input, "--rules", bend).stderr).toMatch(/not supported yet/);
});

test("--fix applies safe fixes only", () => {
  const target = path.join(dir, "fix.bend");
  fs.writeFileSync(target, fs.readFileSync(fixture, "utf8"));
  const comma = rule("comma.js", `[{ id: "style/comma-space", run(cx) {
  return [...cx.root.text.matchAll(/,(?=\\w)/g)].map((m) => {
    const spn = { file: cx.root.file, beg: m.index + 1, end: m.index + 1 };
    return cx.diag({ message: "space", severity: "hint", spn,
      fixes: [{ title: "Insert space", applicability: "safe", edits: [{ spn, text: " " }] }] });
  });
} }]`);
  expect(run(target, "--rules", comma, "--fix").status).toBe(0);
  expect(fs.readFileSync(target, "utf8")).toContain("generic(~N, a)");
});
