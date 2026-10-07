import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import * as Bend from "../../bend2/bend.ts";

const file = fileURLToPath(new URL("./userland.bend", import.meta.url));

async function read(file) {
  const book = Bend.book_nil();
  await Bend.book_load(book, file, "", new Map());
  Bend.book_valid(book);
  return book;
}

async function checkImports(dir) {
  const dep = path.join(dir, "dep.bend");
  const main = path.join(dir, "main.bend");
  fs.writeFileSync(dep, "type N is Data:\n  Z{}\ndef id(x: N) -> N:\n  x\n");
  fs.writeFileSync(main, "import ./dep.bend as D\n\ndef main() -> D.N:\n  D.id(D.Z{})\n");
  const book = await read(main);
  assert.deepEqual(book.diags, []);
  const mainFile = { str: fs.readFileSync(main, "utf8") };
  assert.equal(book.tlds.main.v.s.file.str, mainFile.str);
  assert.ok(book.tlds.main.v.s.file.str.startsWith("import ./dep.bend"));
  const plain = await read(main);
  assert.equal(plain.tlds.main.v.s.file.str, mainFile.str);
}

function checkRuleResults() {
  const book = Bend.book_nil();
  const diag = Bend.Diag("test/stamp", book, Bend.ctx_nil(), "stamped");
  assert.equal(diag.code, "test/stamp");
}

async function checkRules() {
  const book = await read(file);
  const peel = [...Bend.term_walk(book.tlds.peel.e)];
  assert.ok(peel.some(tm => tm.$ === "Mat"));
  assert.equal(peel[0], book.tlds.peel.e);
}

if (import.meta.main) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-lint-"));
  try {
    await checkImports(dir);
    await checkRuleResults();
    await checkRules();
    console.log("PASS userland diagnostics: source spans, external codes, traversal");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}
