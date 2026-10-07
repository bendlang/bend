import { afterAll, expect, test } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import { Bend, lint, render } from "../src/index.ts";
import type { Fact, LintRule, RuleContext } from "../src/index.ts";

const file = fileURLToPath(new URL("./fixtures/userland.bend", import.meta.url));
const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-lint-"));
afterAll(() => fs.rmSync(dir, { recursive: true, force: true }));

type Loose = Fact & { tm: { x?: { $: string; k?: string; i?: number } } };

function facts(cx: { facts?: Map<unknown, Fact>; book: RuleContext["book"]; walk: RuleContext["walk"] }, name: string): Loose[] {
  const tld = cx.book.tlds[name];
  if (tld.$ !== "Def" || tld.e === undefined) return [];
  return [...cx.walk(tld.e)].map((tm) => cx.facts!.get(tm)).filter((f): f is Loose => f !== undefined);
}

const commaSpace: LintRule = {
  id: "style/comma-space",
  run: (cx) => [...cx.root.text.matchAll(/,(?=\w)/g)].map((m) => {
    const spn = { file: cx.root.file, beg: m.index! + 1, end: m.index! + 1 };
    return cx.diag({
      message: "Add a space after the comma.", severity: "warning", spn,
      fixes: [{ title: "Insert space", applicability: "safe", edits: [{ spn, text: " " }] }],
    });
  }),
};

const identity: LintRule = {
  id: "example/identity",
  needsTypes: true,
  run: async (cx, signal) => {
    await Promise.resolve();
    signal.throwIfAborted();
    const body = facts(cx, "id").find((f) => f.dep === 1 && f.tm.x?.$ === "Var")!;
    expect(body).toBeDefined();
    const ann = cx.Bend.pmap_get(body.ctx, body.tm.x!.i!)!;
    expect(ann.k).toBe("x");
    expect((cx.Bend.term_wnf(body.bok, body.ty) as { k?: string }).k).toBe("N");
    expect(cx.same(body, body.ty, ann.T)).toBe(true);
    return [cx.diag({ message: "This function returns its parameter.", severity: "information", spn: body.spn, fact: body })];
  },
};

const neverRun: LintRule = {
  id: "test/never-run",
  needsTypes: true,
  run: () => { throw new Error("this rule must not run"); },
};

test("source and typed rules report in order, with fixes on the file on disk", async () => {
  const text = fs.readFileSync(file, "utf8");
  const res = await lint(file, [commaSpace, identity]);
  expect(res.ok).toBe(true);
  expect(res.diags.map((d) => d.code)).toEqual([commaSpace.id, identity.id]);
  const edit = res.diags[0].fixes[0].edits[0];
  expect(edit.spn.file.str).toBe(text);
  expect(render(res.diags[0])).toStartWith("Warning [style/comma-space]:");
  expect(render(res.diags[0])).toContain("generic(~N, a)");
  expect(render(res.diags[1])).toContain("Context:");
  expect(fs.readFileSync(file, "utf8")).toBe(text);
});

test("only rules with needsTypes get facts", async () => {
  let seen: unknown = "unset";
  const look: LintRule = { id: "test/look", run: (cx) => { seen = cx.facts; return []; } };
  await lint(file, [look, identity]);
  expect(seen).toBeUndefined();
  const plain = await lint(file, [commaSpace]);
  expect(plain.facts).toBeUndefined();
});

test("facts cover templates, proofs, matches and fields", async () => {
  const probe: LintRule = {
    id: "test/probe",
    needsTypes: true,
    run: (cx) => {
      const generic = facts(cx, "generic").find((f) => f.tm.x?.$ === "Var" && f.tm.x.k === "x")!;
      expect(generic.bok.tlds["generic~T"]).toBeDefined();
      const proof = facts(cx, "proof").find((f) => f.tm.x?.$ === "Rfl")!;
      expect(proof.ty.$).toBe("Eql");
      expect(proof.dep).toBe(1);
      const peel = [...cx.walk((cx.book.tlds.peel as { e: Parameters<RuleContext["walk"]>[0] }).e)];
      expect(peel.some((tm) => tm.$ === "Mat")).toBe(true);
      expect(peel.some((tm) => tm.$ === "Ann" && tm.x.$ === "Efq" && !cx.facts!.has(tm))).toBe(true);
      const field = facts(cx, "peel").find((f) => f.tm.x?.$ === "Var" && f.tm.x.k === "p")!;
      expect(cx.Bend.pmap_get(field.ctx, field.tm.x!.i!)!.k).toBe("p");
      return [];
    },
  };
  expect((await lint(file, [probe])).ok).toBe(true);
});

test("a failed check is one bend/check error, and no rule runs", async () => {
  const bad = path.join(dir, "bad.bend");
  fs.writeFileSync(bad, "type N is Data:\n  Z{}\ndef broken(\n");
  let res = await lint(bad, [neverRun]);
  expect(res.ok).toBe(false);
  expect(res.diags.map((d) => d.code)).toEqual(["bend/check"]);
  expect(render(res.diags[0])).toStartWith("Error [bend/check]:");
  fs.writeFileSync(bad, "type N is Data:\n  Z{}\ndef broken() -> N:\n  missing\n");
  res = await lint(bad, [neverRun]);
  expect(res.ok).toBe(false);
  fs.writeFileSync(bad, "type N is Data:\n  Z{}\ndef broken() -> N:\n  ?TODO\n");
  res = await lint(bad, [neverRun]);
  expect(res.diags[0].message).toContain("1 TODO found");
  res = await lint(path.join(dir, "missing.bend"), [neverRun]);
  expect(res.ok).toBe(false);
});

test("an error finding stops later rules; the code is always the rule's id", async () => {
  const stamp: LintRule = { id: "test/stamp", run: (cx) => [{ ...cx.diag({ message: "stamped", severity: "hint" }), code: "other/code" }] };
  expect((await lint(file, [stamp])).diags[0].code).toBe(stamp.id);
  const stop: LintRule = { id: "test/error", run: (cx) => [cx.diag({ message: "failed", severity: "error" })] };
  const res = await lint(file, [stop, neverRun]);
  expect(res.ok).toBe(false);
  expect(res.diags.map((d) => d.code)).toEqual([stop.id]);
});

test("a rule that throws, and an abort, reach the caller", async () => {
  const boom: LintRule = { id: "test/boom", run: async () => { throw new Error("rule failed"); } };
  await expect(lint(file, [boom])).rejects.toThrow("rule failed");
  const controller = new AbortController();
  const abort: LintRule = {
    id: "test/abort",
    run: async (_cx, signal) => { expect(signal).toBe(controller.signal); controller.abort(); return []; },
  };
  await expect(lint(file, [abort, neverRun], { signal: controller.signal })).rejects.toThrow();
  await expect(lint(file, [], { signal: controller.signal })).rejects.toThrow();
});

// bend resolves relative imports with "/" paths, and bend does not run on
// native Windows ("No Windows (WSL works)"), so this test does not either.
test.skipIf(process.platform === "win32")("spans after import lines point at the right text on disk", async () => {
  const dep = path.join(dir, "dep.bend");
  const main = path.join(dir, "main.bend");
  fs.writeFileSync(dep, "type N is Data:\n  Z{}\ndef id(x: N) -> N:\n  x\n");
  fs.writeFileSync(main, "import ./dep.bend as D\n\ndef main() -> D.N:\n  D.id(D.Z{})\n");
  const look: LintRule = {
    id: "test/imports",
    needsTypes: true,
    run: (cx) => {
      const mine = cx.sources.find((s) => s.path === fs.realpathSync(main))!;
      expect(mine.root).toBe(true);
      expect(cx.sources.find((s) => s.path === fs.realpathSync(dep))!.ns).toBe("dep");
      const spanned = [...cx.facts!.values()].filter((f) => f.def === "main" && f.spn !== undefined);
      expect(spanned.length).toBeGreaterThan(0);
      for (const f of spanned) {
        expect(f.spn!.file).toBe(mine.file);
        const text = mine.text.slice(f.spn!.beg, f.spn!.end);
        expect(text.length).toBeGreaterThan(0);
        expect(mine.text.slice(f.spn!.beg).startsWith(text)).toBe(true);
      }
      const call = spanned.map((f) => mine.text.slice(f.spn!.beg, f.spn!.end));
      expect(call.some((t) => t.startsWith("D.id") || t.startsWith("D.Z"))).toBe(true);
      return [];
    },
  };
  const res = await lint(main, [look]);
  expect(res.diags.map(render)).toEqual([]);
  expect(res.ok).toBe(true);
  expect(res.sources.length).toBe(2);
});

test("lints in flight keep their own rules and facts", async () => {
  let resume!: () => void;
  let entered!: () => void;
  const waiting = new Promise<void>((r) => { resume = r; });
  const started = new Promise<void>((r) => { entered = r; });
  const paused: LintRule = {
    id: "test/paused",
    run: async (cx) => { expect(cx.facts).toBeUndefined(); entered(); await waiting; return []; },
  };
  const first = lint(file, [paused]);
  await started;
  try {
    const second = await lint(file, [identity]);
    expect(second.facts!.size).toBeGreaterThan(0);
    expect(second.diags.map((d) => d.code)).toEqual([identity.id]);
  } finally {
    resume();
  }
  const res = await first;
  expect(res.facts).toBeUndefined();
  expect(res.diags).toEqual([]);
});

test("a rule may await I/O, and later rules see earlier findings", async () => {
  const server = Bun.serve({ port: 0, fetch: async (req) => new Response("advice for " + (await req.json()).type) });
  try {
    const remote: LintRule = {
      id: "test/api",
      needsTypes: true,
      run: async (cx, signal) => {
        const fact = cx.facts!.get((cx.book.tlds.id as { e: Parameters<RuleContext["walk"]>[0] }).e)!;
        const type = cx.Bend.term_wnf(fact.bok, fact.ty) as { $: string; A: Parameters<typeof Bend.term_wnf>[1] };
        const arg = cx.Bend.term_wnf(fact.bok, type.A) as { k?: string };
        const res = await fetch(server.url, { method: "POST", body: JSON.stringify({ type: arg.k }), signal });
        return [cx.diag({ message: await res.text(), severity: "hint" })];
      },
    };
    const next: LintRule = { id: "test/after-api", run: (cx) => { expect(cx.prior[0].message).toBe("advice for N"); return []; } };
    expect((await lint(file, [remote, next])).ok).toBe(true);
  } finally {
    server.stop(true);
  }
});
