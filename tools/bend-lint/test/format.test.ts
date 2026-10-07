import { afterAll, expect, test } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import { Bend, applyFixes, lint } from "../src/index.ts";
import type { Book, Diag, SourceFile } from "../src/index.ts";
import { spacing, spacingEdits, tokens } from "./rules/format.ts";

const file = fileURLToPath(new URL("./fixtures/format.bend", import.meta.url));
const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-lint-format-"));
afterAll(() => fs.rmSync(dir, { recursive: true, force: true }));

function asDiags(file: SourceFile): Diag[] {
  return spacingEdits(file).map((edit) => ({
    code: spacing.id, severity: "hint", message: "", spn: edit.spn,
    fixes: [{ title: "Normalize spacing", applicability: "safe", edits: [edit] }],
  }));
}

function bodies(book: Book): Record<string, string> {
  const out: Record<string, string> = {};
  for (const name of book.order) {
    const tld = book.tlds[name];
    if (tld.$ === "Def" && tld.e !== undefined && !tld.b) out[name] = Bend.term_show(tld.e);
  }
  return out;
}

test("strings, characters, comments, operators and CRLF stay whole", () => {
  const source = 'a= "x,y=z#text\\"still,string" # comment,a=b\r\n'
    + "b= '='\r\nc= ','\r\nd= '#'\r\ne= '\\''\r\n"
    + "f(a,\r\n  b)\r\nx==y\r\nx=>y\r\nx!=y\r\nx<=y\r\nx>=y\r\nf(a,)\r\n";
  const sf: SourceFile = { str: source, ns: "", al: {}, path: "<lexical>" };
  const diags = asDiags(sf);
  const formatted = applyFixes(sf, diags);
  expect(formatted).toBe(source.replace(/^([abcde])=/gm, "$1 ="));
  expect(tokens(formatted).map((t) => t.text)).toEqual(tokens(source).map((t) => t.text));
  expect(() => applyFixes(sf, [diags[0], diags[0]])).toThrow(/overlap/);
});

test("one rule gives editor findings and formatter edits", async () => {
  const res = await lint(file, [spacing]);
  expect(res.ok).toBe(true);
  expect(res.facts).toBeUndefined();
  expect(res.diags.length).toBe(8);
  const root = res.sources.find((s) => s.root)!;
  const formatted = applyFixes(root.file, res.diags);
  expect(formatted).toContain("def choose(x: Sample, y: Sample)");
  expect(formatted).toContain("a : Sample = SampleValue{} # preserve,this=comment");
  expect(formatted).toContain("b : Sample = SampleValue{}");
  expect(formatted).toContain("f : Sample -> Sample = y=>y");
  expect(formatted).toContain("f(choose(a, b))");
  expect(tokens(formatted).map((t) => t.text)).toEqual(tokens(root.text).map((t) => t.text));

  const fixed = path.join(dir, "format.bend");
  fs.writeFileSync(fixed, formatted);
  const after = await lint(fixed, [spacing]);
  expect(after.diags).toEqual([]);
  expect(bodies(after.book)).toEqual(bodies(res.book));
  expect(fs.readFileSync(file, "utf8")).toBe(root.text);
});
