import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import * as Bend from "../../bend2/bend.ts";
import { book_read } from "../../bend2/main.ts";

const file = fileURLToPath(new URL("./userland.bend", import.meta.url));
const spacing = {
  id: "style/comma-space",
  run: book => book.files.flatMap(file => [...file.str.matchAll(/,(?=\w)/g)].map(match => {
    const spn = { file, beg: match.index + 1, end: match.index + 1 };
    const fix = { title: "Insert space", applicability: "safe", edits: [{ spn, text: " " }] };
    return Bend.Diag(spacing.id, book, Bend.ctx_nil(), "Add a space after the comma.",
      undefined, spn, undefined, undefined, [fix], "warning");
  })),
};
const neverRun = {
  id: "test/never-run",
  run: () => assert.fail("This rule must not run."),
};


async function read(file, rules = [], signal, base) {
  return await book_read(file, base, undefined, signal, rules);
}

async function checkRules() {
  const source = fs.readFileSync(file, "utf8");
  const book = await read(file, [spacing]);
  assert.deepEqual(book.diags.map(d => d.code), [spacing.id]);
  const edit = book.diags[0].fixes[0].edits[0];
  assert.equal(edit.spn.file.str, source);
  assert.equal(edit.spn.beg, edit.spn.end);
  assert.ok(Bend.diag_show(book.diags[0]).includes("generic(~N, a)"));
  assert.equal(fs.readFileSync(file, "utf8"), source);

  const plain = await read(file, [spacing]);
  assert.equal(plain.checked, undefined, "source rules do not capture types");
  const original = await read(file);
  assert.equal(original.files, undefined);
  assert.equal(original.checked, undefined);
  assert.equal(Bend.term_show(original.tlds.main.e), Bend.term_show(book.tlds.main.e));

  const peel = [...Bend.term_walk(book.tlds.peel.e)];
  assert.ok(peel.some(tm => tm.$ === "Mat"));
}

async function checkFailures(dir) {
  const bad = path.join(dir, "bad.bend");
  fs.writeFileSync(bad, "type N is Data:\n  Z{}\ndef broken(\n# ,x\n");
  await assert.rejects(read(bad, [neverRun]), e => e.why?.$ === "Diag");

  fs.writeFileSync(bad, "type N is Data:\n  Z{}\ndef broken() -> N:\n  missing\n# ,x\n");
  await assert.rejects(read(bad, [neverRun]), e => e.why?.code === Bend.DIAG_CODES.UndefinedName);

  fs.writeFileSync(bad, "type N is Data:\n  Z{}\ndef broken() -> N:\n  ?TODO\n");
  await assert.rejects(read(bad, [neverRun]), e => String(e.why).includes("1 TODO found"));
}

async function checkCancellation() {
  const controller = new AbortController();
  const abort = {
    id: "test/abort",
    async run(book, signal) {
      await Promise.resolve();
      assert.equal(signal, controller.signal);
      controller.abort();
      return [];
    },
  };
  await assert.rejects(read(file, [abort, neverRun], controller.signal), e => e.why?.name === "AbortError");
  await assert.rejects(read(file, [], controller.signal), e => e.why?.name === "AbortError");
}

async function checkRuleResults() {
  const boom = {
    id: "test/boom",
    async run() { throw new Error("rule failed"); },
  };
  await assert.rejects(read(file, [boom]), e => e.why?.message === "rule failed");
  const stamp = {
    id: "test/stamp",
    run: book => [Bend.Diag("other/code", book, Bend.ctx_nil(), "stamped", undefined,
      undefined, undefined, undefined, [], "hint")],
  };
  assert.equal((await read(file, [stamp])).diags[0].code, stamp.id);
  const error = {
    id: "test/error",
    run: book => [Bend.Diag("other/error", book, Bend.ctx_nil(), "failed")],
  };
  await assert.rejects(read(file, [error, neverRun]), e => e.why?.code === error.id);
}

async function checkImports(dir) {
  const dep = path.join(dir, "dep.bend");
  const main = path.join(dir, "main.bend");
  fs.writeFileSync(dep, "type N is Data:\n  Z{}\ndef id(x: N) -> N:\n  x\n");
  fs.writeFileSync(main, "import ./dep.bend as D\n\ndef main() -> D.N:\n  D.id(D.Z{})\n");
  const book = await read(main, [{ id: "test/imports", run: () => [] }]);
  assert.deepEqual(book.diags, []);
  assert.equal(book.files.length, 2);
  const mainFile = book.files.find(f => f.path === main);
  assert.equal(book.tlds.main.v.s.file, mainFile);
  assert.ok(book.tlds.main.v.s.file.str.startsWith("import ./dep.bend"));
  assert.equal(book.files.find(f => f.path === dep).ns, "dep");
  const plain = await read(main);
  assert.equal(plain.tlds.main.v.s.file.str, mainFile.str);
}

async function checkIsolation() {
  let resume, entered;
  const waiting = new Promise(resolve => { resume = resolve; });
  const started = new Promise(resolve => { entered = resolve; });
  const paused = { id: "test/paused", async run(book) {
    assert.equal(book.checked, undefined);
    entered();
    await waiting;
    return [];
  } };
  const first = read(file, [paused]);
  await started;
  try {
    const second = await read(file, [spacing]);
    assert.equal(second.checked, undefined);
    assert.deepEqual(second.diags.map(d => d.code), [spacing.id]);
  } finally {
    resume();
    const book = await first;
    assert.equal(book.checked, undefined);
    assert.deepEqual(book.diags, [], "an in-flight read keeps its own rules");
  }
}

async function checkSeeds(dir) {
  const rules = [{ id: "test/seed", run: () => [] }];
  const untyped = await read(Bend.BASE_BEND);
  const base = await read(Bend.BASE_BEND, rules);
  const main = path.join(dir, "seeded.bend");
  fs.writeFileSync(main, "import Base\n" + fs.readFileSync(file, "utf8"));
  const seeded = await read(main, rules, undefined, base);
  assert.notEqual(seeded.files, base.files);
  assert.ok(seeded.files.includes(base.files[0]));
  const fresh = await read(main, rules, undefined, untyped);
  assert.equal(fresh.files.length, seeded.files.length);
  assert.equal(fresh.checked, undefined);
}

if (import.meta.main) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-lint-"));
  try {
    await checkRules();
    await checkFailures(dir);
    await checkCancellation();
    await checkRuleResults();
    await checkImports(dir);
    await checkIsolation();
    await checkSeeds(dir);
    console.log("PASS userland diagnostics: source edits, imports, isolation, seeds, async, cancellation");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}
