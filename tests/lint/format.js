import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import * as Bend from "../../bend2/bend.ts";
import { book_read } from "../../bend2/main.ts";

// Quoted literals, comments and compound operators stay whole. Only gaps change.
function tokens(source) {
  const pattern = /#[^\r\n]*|"(?:\\[\s\S]|[^"\\])*"|'(?:\\[\s\S]|[^'\\])*'|==|=>|!=|<=|>=|[^\s]/g;
  return [...source.matchAll(pattern)].map(match => ({
    text: match[0], beg: match.index, end: match.index + match[0].length,
  }));
}

function gapEdit(file, left, right) {
  if (!left || !right || right.text.startsWith("#")) return;
  const gap = file.str.slice(left.end, right.beg);
  if (!/^[ \t]*$/.test(gap) || gap === " ") return;
  return { spn: { file, beg: left.end, end: right.beg }, text: " " };
}

function spacingEdits(file) {
  const stream = tokens(file.str);
  const edits = [];
  for (let i = 0; i < stream.length; i++) {
    const token = stream[i];
    if (token.text === "=") edits.push(gapEdit(file, stream[i - 1], token));
    if (token.text === "=" || token.text === ",") {
      const next = stream[i + 1];
      if (next && !["}", ")", "]"].includes(next.text)) edits.push(gapEdit(file, token, next));
    }
  }
  return edits.filter(Boolean);
}

export const spacing = {
  id: "format/spacing",
  run(book, signal) {
    // Format the active file; imported modules are formatted when opened themselves.
    const files = book.files.filter(file => file.ns === "");
    return files.flatMap(file => {
      signal.throwIfAborted();
      return spacingEdits(file).map(edit => Bend.Diag(spacing.id, book, Bend.ctx_nil(),
        "Use one space after a comma and on each side of an assignment.",
        undefined, edit.spn, undefined, undefined,
        [{ title: "Normalize spacing", applicability: "safe", edits: [edit] }], "hint"));
    });
  },
};

export default [spacing];

// A formatter consumes the same fixes an editor offers individually.
export function formatSource(file, diagnostics) {
  const edits = diagnostics.flatMap(diag => diag.fixes)
    .filter(fix => fix.applicability === "safe")
    .flatMap(fix => fix.edits).filter(edit => edit.spn.file === file)
    .sort((a, b) => b.spn.beg - a.spn.beg);
  let output = file.str;
  let boundary = output.length + 1;
  for (const { spn, text } of edits) {
    assert.ok(spn.beg >= 0 && spn.beg <= spn.end && spn.end <= file.str.length
      && spn.end <= boundary && spn.beg < boundary,
      "edits must be in bounds and must not overlap");
    output = output.slice(0, spn.beg) + text + output.slice(spn.end);
    boundary = spn.beg;
  }
  return output;
}

function checkLexicalCases() {
  const source = 'a= "x,y=z#text\\\"still,string" # comment,a=b\r\n'
    + "b= '='\r\nc= ','\r\nd= '#'\r\ne= '\\\''\r\n"
    + "f(a,\r\n  b)\r\nx==y\r\nx=>y\r\nx!=y\r\nx<=y\r\nx>=y\r\nf(a,)\r\n";
  const file = { str: source, ns: "" };
  const book = Bend.book_nil([spacing]);
  book.files.push(file);
  const diagnostics = spacing.run(book, new AbortController().signal);
  const formatted = formatSource(file, diagnostics);
  assert.equal(formatted, source.replace(/^([abcde])=/gm, "$1 ="));
  assert.deepEqual(tokens(formatted).map(t => t.text), tokens(source).map(t => t.text));
  assert.equal(book.checked, undefined, "formatting does not request type metadata");
  assert.throws(() => formatSource(file, [diagnostics[0], diagnostics[0]]), /overlap/);
}

async function demonstrate() {
  checkLexicalCases();
  const file = fileURLToPath(new URL("./format.bend", import.meta.url));
  const book = await book_read(file, undefined, undefined, undefined, [spacing]);
  const active = book.files.find(source => source.path === file);
  assert.equal(book.checked, undefined);
  assert.equal(book.diags.length, 8);
  const formatted = formatSource(active, book.diags);
  assert.ok(formatted.includes("def choose(x: Sample, y: Sample)"));
  assert.ok(formatted.includes("a : Sample = SampleValue{} # preserve,this=comment"));
  assert.ok(formatted.includes("b : Sample = SampleValue{}"));
  assert.ok(formatted.includes("f : Sample -> Sample = y=>y"));
  assert.ok(formatted.includes("f(choose(a, b))"));
  assert.deepEqual(tokens(formatted).map(t => t.text), tokens(active.str).map(t => t.text));
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-lint-format-"));
  try {
    const fixed = path.join(dir, "format.bend");
    fs.writeFileSync(fixed, formatted);
    const after = await book_read(fixed, undefined, undefined, undefined, [spacing]);
    assert.deepEqual(after.diags, [], "formatting is idempotent");
    for (const name of book.order) {
      const before = book.tlds[name];
      if (before.$ !== "Def" || !before.e) continue;
      assert.equal(Bend.term_show(after.tlds[name].e), Bend.term_show(before.e), name);
    }
    assert.equal(fs.readFileSync(file, "utf8"), active.str);
    console.log("Formatted source:\n" + formatted);
    console.log("PASS: one external rule supplies editor diagnostics and formatter edits");
    console.log("PASS: strings, characters, comments, operators and line breaks preserved");
    console.log("PASS: formatted source checks, elaborated bodies match, second run has no edits");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

if (import.meta.main) await demonstrate();
