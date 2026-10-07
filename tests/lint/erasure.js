import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import * as Bend from "../../bend2/bend.ts";
import { book_read } from "../../bend2/main.ts";

// The compiler supplies local types and contexts; the cleanup policy lives here.
// Only local variable values: their types are available without an annotation.
// Constructors and lambdas may need an expected type even after checking succeeds.
export const redundantAnnotation = {
  id: "erasure/redundant-local-annotation",
  needsTypes: true,
  run(book, signal) {
    const findings = new Map();
    for (const fact of book.checked.values()) {
      signal.throwIfAborted();
      const finding = redundantBinding(fact);
      if (!finding) continue;
      const span = finding.spn;
      const key = JSON.stringify([span.file.path, span.beg, span.end]);
      if (!findings.has(key)) findings.set(key, finding);
    }
    return [...findings.values()];
  },
};

function redundantBinding(fact) {
  const term = Bend.term_strip(fact.tm);
  if (term.$ !== "Var" || !fact.spn || !term.s) return;
  const variable = Bend.pmap_get(fact.ctx, term.i);
  if (!variable) return;
  if (!Bend.term_compare("EQ", fact.bok, variable.T, fact.ty, fact.dep)) return;
  const edit = annotationEdit(fact.spn, term.s);
  if (!edit) return;
  const type = Bend.term_show(Bend.term_lower(variable.T, fact.dep));
  return Bend.Diag(redundantAnnotation.id, fact.bok, fact.ctx,
    `Remove the redundant annotation: ${variable.k} already has type ${type}.`,
    undefined, edit.spn, fact.def, undefined,
    [{ title: "Remove redundant local type annotation", applicability: "suggested", edits: [edit] }],
    "hint");
}

function annotationEdit(binding, value) {
  if (binding.file !== value.file || binding.beg >= value.beg) return;
  const prefix = binding.file.str.slice(binding.beg, value.beg);
  if (prefix.includes("#")) return;
  const name = prefix.match(/^([A-Za-z_][A-Za-z_0-9]*)\s*:/);
  if (!name || !prefix.trimEnd().endsWith("=")) return;
  const beg = binding.beg + name[1].length;
  const end = binding.beg + prefix.lastIndexOf("=");
  return { spn: { file: binding.file, beg, end }, text: " " };
}

export default [redundantAnnotation];

async function demonstrate() {
  const file = fileURLToPath(new URL("./erasure.bend", import.meta.url));
  const original = await book_read(file);
  const checked = await book_read(file, undefined, undefined, undefined, [redundantAnnotation]);
  const findings = checked.diags;
  assert.deepEqual(findings.map(d => d.def).sort(), ["alias", "dependent", "direct", "generic"]);
  assert.ok(findings.every(d => d.fixes.length === 1));
  assert.ok(findings.every(d => d.ctx !== null));
  assert.equal(original.checked, undefined);

  const source = fs.readFileSync(file, "utf8");
  const edits = findings.flatMap(d => d.fixes[0].edits).sort((a, b) => b.spn.beg - a.spn.beg);
  let cleaned = source;
  for (const edit of edits) {
    assert.equal(edit.spn.file.path, file);
    cleaned = cleaned.slice(0, edit.spn.beg) + edit.text + cleaned.slice(edit.spn.end);
  }
  assert.ok(cleaned.includes("f : N -> N = y => y"));
  assert.ok(cleaned.includes("value : N = Z{}"));
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-lint-erasure-"));
  try {
    const fixed = path.join(dir, "erasure.bend");
    fs.writeFileSync(fixed, cleaned);
    const after = await book_read(fixed, undefined, undefined, undefined, [redundantAnnotation]);
    assert.deepEqual(after.diags, [], "cleanup is idempotent");
    for (const name of original.order) {
      const before = original.tlds[name];
      if (before.$ !== "Def" || !before.e) continue;
      assert.equal(Bend.term_show(after.tlds[name].e), Bend.term_show(before.e), name);
    }
    for (const [annotation, binding] of [
      ["f : N -> N =", "f ="],
      ["value : N =", "value ="],
    ]) {
      fs.writeFileSync(fixed, cleaned.replace(annotation, binding));
      await assert.rejects(book_read(fixed),
        error => error.why?.code === Bend.DIAG_CODES.CannotInfer,
        `${annotation} is necessary for bidirectional checking`);
    }
    assert.equal(fs.readFileSync(file, "utf8"), source);
    console.log("PASS: four annotations removed; aliases, generic and dependent types resolved");
    console.log("PASS: removing constructor or lambda annotations fails; all cleaned bodies unchanged");
    console.log("PASS: edited source checks again and produces no further findings");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

if (import.meta.main) await demonstrate();
