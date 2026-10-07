import { afterAll, expect, test } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import { Bend, applyFixes, lint } from "../src/index.ts";
import type { Book } from "../src/index.ts";
import { redundantAnnotation } from "./rules/erasure.ts";

const file = fileURLToPath(new URL("./fixtures/erasure.bend", import.meta.url));
const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-lint-erasure-"));
afterAll(() => fs.rmSync(dir, { recursive: true, force: true }));

function bodies(book: Book): Record<string, string> {
  const out: Record<string, string> = {};
  for (const name of book.order) {
    const tld = book.tlds[name];
    if (tld.$ === "Def" && tld.e !== undefined) out[name] = Bend.term_show(tld.e);
  }
  return out;
}

test("finds the four redundant annotations, and the fix keeps every body", async () => {
  const source = fs.readFileSync(file, "utf8");
  const res = await lint(file, [redundantAnnotation]);
  expect(res.ok).toBe(true);
  expect(res.diags.map((d) => d.def).sort()).toEqual(["alias", "dependent", "direct", "generic"]);
  expect(res.diags.every((d) => d.fixes.length === 1)).toBe(true);
  const root = res.sources.find((s) => s.root)!;
  const cleaned = applyFixes(root.file, res.diags, ["suggested"]);
  expect(cleaned).toContain("f : N -> N = y => y");
  expect(cleaned).toContain("value : N = Z{}");

  const fixed = path.join(dir, "erasure.bend");
  fs.writeFileSync(fixed, cleaned);
  const after = await lint(fixed, [redundantAnnotation]);
  expect(after.ok).toBe(true);
  expect(after.diags).toEqual([]);
  expect(bodies(after.book)).toEqual(bodies(res.book));
  expect(fs.readFileSync(file, "utf8")).toBe(source);
});

test("the annotations it keeps are needed", async () => {
  const res = await lint(file, [redundantAnnotation]);
  const cleaned = applyFixes(res.sources.find((s) => s.root)!.file, res.diags, ["suggested"]);
  const fixed = path.join(dir, "needed.bend");
  for (const [annotation, binding] of [["f : N -> N =", "f ="], ["value : N =", "value ="]]) {
    fs.writeFileSync(fixed, cleaned.replace(annotation, binding));
    const broken = await lint(fixed, []);
    expect(broken.ok).toBe(false);
    expect(broken.diags[0].code).toBe("bend/check");
  }
});
