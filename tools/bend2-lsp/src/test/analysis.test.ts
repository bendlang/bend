import assert from "node:assert/strict";
import * as os from "node:os";
import * as path from "node:path";
import { pathToFileURL } from "node:url";
import test from "node:test";
import { Analyzer } from "../analysis.js";
import { lexicalDiagnostics, staticHover } from "../lexical.js";

test("reports lexical errors and documents syntax", () => {
  const diagnostics = lexicalDiagnostics('def main() -> String:\n  "unfinished\n  ?TODO');
  assert.deepEqual(diagnostics.map((item) => item.code), ["parsing", "holes"]);
  assert.match(staticHover("!") ?? "", /GPU/);
  assert.equal(staticHover("unknown"), null);
});

test("uses the compiler for diagnostics and hover", async () => {
  const analyzer = new Analyzer();
  const file = path.join(os.tmpdir(), `bend2-lsp-test-${process.pid}.bend`);
  const uri = pathToFileURL(file).href;
  const text = "import Base\n\ndef main() -> U32:\n  0";
  const result = await analyzer.analyze({ type: "analyze", uri, path: file, version: 1, text, overlays: [{ uri, path: file, version: 1, text }] });
  await analyzer.close();
  assert.deepEqual(result.diagnostics, []);
  assert.match(result.hovers.main, /main :/);
});

test("resolves an imported unsaved overlay", async () => {
  const analyzer = new Analyzer();
  const dir = path.join(os.tmpdir(), `bend2-lsp-overlay-${process.pid}`);
  const main = path.join(dir, "main.bend");
  const dep = path.join(dir, "dep.bend");
  const mainUri = pathToFileURL(main).href;
  const depUri = pathToFileURL(dep).href;
  const mainText = "import ./dep.bend as Dep\n\ndef main() -> U32:\n  Dep.answer";
  const depText = "import Base\n\ndef answer() -> U32:\n  42";
  const overlays = [{ uri: mainUri, path: main, version: 1, text: mainText }, { uri: depUri, path: dep, version: 2, text: depText }];
  const result = await analyzer.analyze({ type: "analyze", uri: mainUri, path: main, version: 1, text: mainText, overlays });
  await analyzer.close();
  assert.deepEqual(result.diagnostics, []);
  assert.match(result.hovers["Dep.answer"], /answer/);
});

test("categorizes compiler failures with source offsets", async () => {
  const analyzer = new Analyzer();
  const dir = path.join(os.tmpdir(), `bend2-lsp-errors-${process.pid}`);
  const cases = [
    { name: "parse", text: "import Base\n\ndef main() -> U32:\n  )", code: "parsing", at: ")" },
    { name: "type", text: 'import Base\n\ndef main() -> U32:\n  "no"', code: "checking", at: '"no"' },
    { name: "import", text: "import ./missing.bend as Missing\n\ndef main() -> U32:\n  0", code: "imports", at: "./missing.bend" },
    { name: "hole", text: "import Base\n\ndef main() -> U32:\n  ?TODO", code: "holes", at: "?TODO" },
    { name: "law", text: "import Base\n\nlaw unfinished:\n  {0 == 0 : U32}", code: "incomplete-law", at: "unfinished" },
  ] as const;
  try {
    for (const item of cases) {
      const file = path.join(dir, `${item.name}.bend`);
      const uri = pathToFileURL(file).href;
      const result = await analyzer.analyze({ type: "analyze", uri, path: file, version: 1, text: item.text, overlays: [{ uri, path: file, version: 1, text: item.text }] });
      assert.equal(result.diagnostics[0]?.code, item.code, `${item.name}: ${JSON.stringify(result.diagnostics)}`);
      assert.equal(result.diagnostics[0]?.range.start, item.text.lastIndexOf(item.at), item.name);
    }
  } finally {
    await analyzer.close();
  }
});
