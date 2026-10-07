import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
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
const semantic = {
  id: "example/identity",
  needsTypes: true,
  run: async (book, signal) => {
    await Promise.resolve();
    signal.throwIfAborted();
    const body = checkedTerms(book, "id").find(e => e.dep === 1 && e.tm.x?.$ === "Var");
    assert.ok(body, "the checked body is reachable from its definition");
    const ann = Bend.pmap_get(body.ctx, body.tm.x.i);
    assert.equal(ann.k, "x");
    assert.equal(Bend.term_wnf(body.bok, body.ty).k, "N");
    assert.ok(Bend.term_compare("EQ", body.bok, body.ty, ann.T, body.dep));
    return [Bend.Diag(semantic.id, body.bok, body.ctx, "This function returns its parameter.",
      undefined, body.spn, body.def, undefined, [], "information")];
  },
};
const neverRun = {
  id: "test/never-run",
  needsTypes: true,
  run: () => assert.fail("This rule must not run."),
};

function checkedTerms(book, name) {
  return [...Bend.term_walk(book.tlds[name].e)]
    .map(tm => book.checked.get(tm)).filter(e => e !== undefined);
}

async function read(file, rules = [], signal, base) {
  return await book_read(file, base, undefined, signal, rules);
}

async function checkRules() {
  const source = fs.readFileSync(file, "utf8");
  const book = await read(file, [spacing, semantic]);
  assert.deepEqual(book.diags.map(d => d.code), [spacing.id, semantic.id]);
  const edit = book.diags[0].fixes[0].edits[0];
  assert.equal(edit.spn.file.str, source);
  assert.equal(edit.spn.beg, edit.spn.end);
  assert.ok(Bend.diag_show(book.diags[0]).includes("generic(~N, a)"));
  assert.ok(Bend.diag_show(book.diags[1]).includes("Context:"));
  assert.equal(fs.readFileSync(file, "utf8"), source);

  const plain = await read(file, [spacing]);
  assert.equal(plain.checked, undefined, "source rules do not capture types");
  const original = await read(file);
  assert.equal(original.files, undefined);
  assert.equal(original.checked, undefined);
  assert.equal(Bend.term_show(original.tlds.main.e), Bend.term_show(book.tlds.main.e));

  const genericBody = checkedTerms(book, "generic").find(e => e.tm.x?.$ === "Var" && e.tm.x.k === "x");
  assert.ok(genericBody.bok.tlds["generic~T"], "generic types retain their opaque parameter declarations");
  const proof = checkedTerms(book, "proof").find(e => e.tm.x?.$ === "Rfl");
  assert.equal(proof.ty.$, "Eql");
  assert.equal(proof.dep, 1);
  assert.ok(Bend.term_compare("EQ", proof.bok, proof.ty.a, proof.ty.b, proof.dep));
  const peel = [...Bend.term_walk(book.tlds.peel.e)];
  assert.ok(peel.some(tm => tm.$ === "Mat"));
  assert.ok(peel.some(tm => tm.$ === "Ann" && tm.x.$ === "Efq" && !book.checked.has(tm)),
    "generated unreachable fallbacks have no captured checking event");
  const field = checkedTerms(book, "peel").find(e => e.tm.x?.$ === "Var" && e.tm.x.k === "p");
  assert.equal(Bend.pmap_get(field.ctx, field.tm.x.i).k, "p");
  assert.equal(Bend.term_wnf(field.bok, field.ty).k, "N");
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
  const book = await read(main, [{ id: "test/imports", needsTypes: true, run: () => [] }]);
  assert.deepEqual(book.diags, []);
  assert.equal(book.files.length, 2);
  const mainFile = book.files.find(f => f.path === main);
  const root = book.checked.get(book.tlds.main.e);
  assert.equal(root.spn.file, mainFile);
  assert.ok(root.spn.file.str.startsWith("import ./dep.bend"));
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
    const second = await read(file, [semantic]);
    assert.ok(second.checked.size > 0);
    assert.deepEqual(second.diags.map(d => d.code), [semantic.id]);
  } finally {
    resume();
    const book = await first;
    assert.equal(book.checked, undefined);
    assert.deepEqual(book.diags, [], "an in-flight read keeps its own rules");
  }
}

async function checkSeeds(dir) {
  const rules = [{ id: "test/seed", needsTypes: true, run: () => [] }];
  const untyped = await read(Bend.BASE_BEND);
  const base = await read(Bend.BASE_BEND, rules);
  const main = path.join(dir, "seeded.bend");
  fs.writeFileSync(main, "import Base\n" + fs.readFileSync(file, "utf8"));
  const seeded = await read(main, rules, undefined, base);
  assert.notEqual(seeded.files, base.files);
  assert.notEqual(seeded.checked, base.checked);
  assert.ok(seeded.files.includes(base.files[0]));
  for (const [tm, fact] of base.checked) assert.equal(seeded.checked.get(tm), fact);
  assert.ok(seeded.checked.size > base.checked.size);
  const fresh = await read(main, rules, undefined, untyped);
  assert.equal(fresh.files.length, seeded.files.length);
  assert.equal(fresh.checked.size, seeded.checked.size,
    "a seed lacking requested metadata is loaded and checked again");
}

async function checkAPI() {
  const server = Bun.serve({
    port: 0,
    async fetch(request) {
      assert.equal((await request.json()).type, "N");
      return new Response("API advice");
    },
  });
  const remote = {
    id: "test/api",
    needsTypes: true,
    async run(book, signal) {
      const fact = book.checked.get(book.tlds.id.e);
      const type = Bend.term_wnf(fact.bok, fact.ty);
      const response = await fetch(server.url, {
        method: "POST",
        body: JSON.stringify({ type: Bend.term_wnf(fact.bok, type.A).k }),
        signal,
      });
      const advice = await response.text();
      return [Bend.Diag(remote.id, book, Bend.ctx_nil(), advice, undefined,
        undefined, undefined, undefined, [], "hint")];
    },
  };
  const next = {
    id: "test/after-api",
    run(book) {
      assert.equal(book.diags[0].exp, "API advice");
      return [];
    },
  };
  try {
    await read(file, [remote, next]);
  } finally {
    server.stop(true);
  }
}

function checkCLI(dir) {
  const cli = fileURLToPath(new URL("../../bend2/main.ts", import.meta.url));
  const bend = new URL("../../bend2/bend.ts", import.meta.url).href;
  const input = path.join(dir, "cli.bend");
  fs.writeFileSync(input, "import Base\n" + fs.readFileSync(file, "utf8"));
  const first = path.join(dir, "first.js");
  const second = path.join(dir, "second.ts");
  const invalid = path.join(dir, "invalid.js");
  const error = path.join(dir, "error.js");
  fs.writeFileSync(first, `import * as Bend from ${JSON.stringify(bend)};
export default [{ id: "cli/first", needsTypes: true, async run(book) {
  if (!book.checked?.size || !book.files?.length) throw new Error("Missing metadata");
  return [Bend.Diag("cli/first", book, Bend.ctx_nil(), "First rule", undefined,
    undefined, undefined, undefined, [], "warning")];
} }];`);
  fs.writeFileSync(second, `import * as Bend from ${JSON.stringify(bend)};
export default [{ id: "cli/second", run(book) {
  if (book.diags[0]?.code !== "cli/first") throw new Error("Wrong rule order");
  return [Bend.Diag("cli/second", book, Bend.ctx_nil(), "Second rule", undefined,
    undefined, undefined, undefined, [], "hint")];
} }];`);
  fs.writeFileSync(error, `import * as Bend from ${JSON.stringify(bend)};
export default [{ id: "cli/error", run(book) {
  return [Bend.Diag("cli/error", book, Bend.ctx_nil(), "Blocked by rule")];
} }];`);
  const run = (...args) => spawnSync(process.execPath, [cli, input, ...args], {
    encoding: "utf8", env: { ...process.env, BEND_NO_TELEMETRY: "1" },
  });
  const checked = run("--check-only", "--lint", first, "--lint", second);
  assert.equal(checked.status, 0, checked.stderr);
  assert.match(checked.stdout, /ALL PROOFS CHECK/);
  assert.match(checked.stderr, /Warning \[cli\/first\]:[\s\S]*Hint \[cli\/second\]:/);
  const executed = run("--lint", first);
  assert.equal(executed.status, 0, executed.stderr);
  assert.equal(executed.stdout.trim(), "S{Z{}}");
  const blocked = run("--lint", error);
  assert.equal(blocked.status, 1);
  assert.equal(blocked.stdout, "");
  assert.match(blocked.stderr, /Error \[cli\/error\]:/);
  assert.equal(run("--lint").status, 1);
  assert.equal(run("--lint", "--check-only").status, 1);
  assert.equal(run("--lint", path.join(dir, "missing.js")).status, 1);
  fs.writeFileSync(invalid, "export default {};");
  assert.match(run("--lint", invalid).stderr, /must default-export an array/);
  fs.writeFileSync(invalid, 'export default [{ id: "bad", run() { return []; } }];');
  assert.match(run("--lint", invalid).stderr, /invalid diagnostic rule/);
  const built = path.join(dir, "built.js");
  const emitted = run("--lint", first, "-o", built);
  assert.equal(emitted.status, 0, emitted.stderr);
  assert.ok(fs.existsSync(built));
  const source = fs.readFileSync(first, "utf8");
  assert.equal(run("--lint", first, "-o", first).status, 1);
  assert.equal(fs.readFileSync(first, "utf8"), source);
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
    await checkAPI();
    checkCLI(dir);
    console.log("PASS userland diagnostics: source edits, types, scopes, imports, isolation, seeds, async, cancellation, CLI");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}
