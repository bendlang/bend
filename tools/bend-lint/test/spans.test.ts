import { expect, test } from "bun:test";

import { SpanError, Spans } from "../src/spans.ts";
import type { Source } from "../src/types.ts";

function source(path: string, ns: string, text: string): Source {
  return { path, ns, text, root: true, base: false, file: { str: text, ns, al: Object.create(null), path } };
}

for (const eol of ["\n", "\r\n"]) {
  const text = ["import Base", "import ./a.bend as A", "", "def f() -> N:", "  x", ""].join(eol);
  const lines = text.split("\n");
  const blank = lines.map((l) => l.startsWith("import") ? "" : l).join("\n");
  const space = lines.map((l) => l.startsWith("import") ? " ".repeat(l.length) : l).join("\n");
  for (const [name, masked] of [["empty", blank], ["spaces", space]] as const) {
    test("maps a span past " + name + " import lines (" + JSON.stringify(eol) + ")", () => {
      const src = source("/p/m.bend", "", text);
      const spans = new Spans([src]);
      const parse = { str: masked, ns: "", dir: "/p/", al: { A: "a" } };
      const beg = masked.indexOf("x");
      const got = spans.map({ file: parse, beg, end: beg + 1 })!;
      expect(got.file).toBe(src.file);
      expect(text.slice(got.beg, got.end)).toBe("x");
      expect(src.file.al.A).toBe("a");
    });
  }
}

test("a span already on disk passes through", () => {
  const src = source("/p/m.bend", "", "def f() -> N:\n  x\n");
  const spn = { file: src.file, beg: 2, end: 3 };
  expect(new Spans([src]).map(spn)).toBe(spn);
});

test("a copy that does not match the file fails loudly", () => {
  const src = source("/p/m.bend", "", "import Base\ndef f() -> N:\n  x\n");
  const spans = new Spans([src]);
  expect(() => spans.map({ file: { str: "\ndef g() -> N:\n  x\n", ns: "", al: {} }, beg: 0, end: 0 }))
    .toThrow(SpanError);
  expect(() => spans.map({ file: { str: "def f() -> N:\n  x\n", ns: "", al: {} }, beg: 0, end: 0 }))
    .toThrow(SpanError);
});

test("the directory and the namespace pick the file", () => {
  const a = source("/a/m.bend", "", "import Base\nx\n");
  const b = source("/b/m.bend", "m", "import Base\nx\n");
  const spans = new Spans([a, b]);
  expect(spans.map({ file: { str: "\nx\n", ns: "m", dir: "/b/", al: {} }, beg: 1, end: 2 })!.file).toBe(b.file);
  expect(spans.map({ file: { str: "\nx\n", ns: "", dir: "/a/", al: {} }, beg: 1, end: 2 })!.file).toBe(a.file);
});
