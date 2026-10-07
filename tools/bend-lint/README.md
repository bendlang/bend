# bend-lint

bend-lint checks a Bend 2 file with bend's own checker, then runs your rules
on it. A rule reads the source text, the checker's result for each term
(type, scope, uses), or both, and returns findings with fixes. Bend itself
does not change. It needs Bun 1.2 or newer.

## Run

From the repo root:

```sh
bun tools/bend-lint/src/lint.ts file.bend [--rules rules.ts]... [--rules rule.bend]... [--config bend-lint.json] [--fix] [--json] [--bend <dir>]
```

Findings print in bend's error layout, with a severity, a code, and each fix
as a diff. `--fix` writes the `safe` fixes to the linted file only, never
to its imports (a BendHub package under `~/.bend/lib` is never edited). Equal
edits merge; a fix that clashes with an earlier one is skipped and counted,
and another `--fix` run applies it. Exit codes: 0 no error, 1 an error (the
file does not check, or a rule found an `error`), 2 bad usage or a tool
failure. "Does not check" means bend's checker rejects it: unlike
`bend --check-only`, bend-lint does not fail a file for relying on
`@unsafe` or foreign code.

`--json` prints only this, for other tools (ranges as in LSP: 0-based,
UTF-16):

```json
{ "ok": true, "findings": [{ "code": "style/comma-space", "severity": "warning", "message": "...",
  "def": "main", "path": "/abs/file.bend", "range": { "start": { "line": 25, "character": 13 }, "end": {...} },
  "fixes": [{ "title": "...", "applicability": "safe", "edits": [{ "path": "...", "range": {...}, "text": " " }] }] }] }
```

`--bend <dir>` (or `$BEND_DIR`) picks the bend to load: a bend checkout, or
its `bend2` folder. Inside the bend repo, its own bend is the default.

## Rules in TypeScript

A rule module exports `rules`. A rule has an `id` (`namespace/name`, also
the code of its findings), an optional `needsTypes`, and a `run` that may be
`async`:

```ts
import type { LintRule } from "./tools/bend-lint/src/lint.ts";

export const rules: LintRule[] = [{
  id: "style/comma-space",
  run: (cx) => [...cx.root.text.matchAll(/,(?=\w)/g)].map((m) => {
    const spn = { file: cx.root.file, beg: m.index! + 1, end: m.index! + 1 };
    return cx.diag({
      message: "Add a space after the comma.", severity: "warning", spn,
      fixes: [{ title: "Insert space", applicability: "safe", edits: [{ spn, text: " " }] }],
    });
  }),
}, {
  id: "demo/var-types",
  needsTypes: true,
  run: (cx) => [...cx.facts!.values()]
    .filter((f) => !f.inst && f.spn?.file === cx.root.file && cx.Bend.term_strip(f.tm).$ === "Var")
    .map((f) => cx.diag({ message: "type: " + cx.show(f, f.ty), severity: "hint", spn: f.spn, fact: f })),
}];
```

| `cx` | |
|---|---|
| `root`, `sources` | the linted file and its imports, as on disk |
| `facts` | with `needsTypes`: per checked term of the linted file, its type, scope, depth, def, quantity, uses, and span on disk |
| `prior` | the findings of earlier rules |
| `span(s)` | a bend span (e.g. `term.s`), moved to the file on disk |
| `walk`, `binder`, `show`, `same`, `normal`, `uses` | helpers over bend's terms |
| `diag({...})` | a finding; the default severity is `warning` |
| `Bend` | the bend module; use it, do not import `bend2/bend.ts` |

Severities: `error` (stops the run), `warning`, `information`, `hint`. Fix
levels: `safe` keeps behavior, `suggested` may change it, `dangerous` may
break code.

Rules run in order; none runs when the file does not check. Facts cover only
the linted file, so none come from Base or other imports. A template body is
checked as written and again per instance (`generic~0`) at the same spans;
`fact.inst` marks the instances. A file with a line exactly `import Base`
(as `bend --checkup` reads it) reuses a Base checked once per process. Every
checked term of the file gives a fact, so a very large file costs memory: a
rule with `needsTypes` on a 3,200-proof file holds about 1.3M facts.

## Options

A rule may declare options with their defaults (`options: { tabWidth: 2,
breakLines: false }`) and read them from `cx.options`. A `bend-lint.json` in
the file's folder or above it (or the one `--config` gives) sets them, and
can also turn a rule off or change its severity:

```json
{ "rules": {
  "format/indent": { "tabWidth": 4, "breakLines": true },
  "style/comma-space": "off",
  "demo/var-types": { "severity": "hint" }
} }
```

An unknown option, or a value whose type differs from its default, stops
bend-lint with an error. From code: `lint(file, rules, { config })`.

## Rules in Bend

A `.bend` rule imports `src/lint.bend`, which lists the contract:

```python
import Base
import ../tools/bend-lint/src/lint.bend as Lint

def id() -> String:
  "demo/nothing"

def types() -> Bool:           # True{} to get facts
  False{}

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  IO.pure(List<&2, Lint.Diag>, [])

def main() -> IO(Unit):
  Lint.serve(run)
```

`input` holds the sources, the rule's options and, with `types()`, the
facts. Read an option with `Lint.option_number`, `option_flag` or
`option_text`, each with a default; numbers are whole (U32). A rule asks about
a fact with effects (`Lint.view`, `type_of`, `binder`, `same`, `show`,
`normal`, `uses`, `text`) and may use Base's effects too. Offsets count
characters. bend-lint compiles a rule once; each run then takes about 10 ms.
A rule runs on bend's JS runtime, where only tail calls run as loops: walk
a long text or list with a tail call, or the stack overflows.
`COMMA_BEND` and `TYPES_BEND` in `test/lint.test.ts` are complete examples.

## From code

```ts
import { applyFixes, bendRule, lint, render } from "./tools/bend-lint/src/lint.ts";

const res = await lint("file.bend", [...rules, await bendRule("rule.bend")]);
console.log(res.ok, res.diags.map(render));
const { text, skipped } = applyFixes(res.sources.find((s) => s.root)!.file, res.diags);
```

A library picks its bend with `$BEND_DIR`, set before it imports bend-lint.
`position(span)` gives the LSP range of a span.

## How it works

- `src/lint.ts`: the library and the CLI.
- `src/patch.ts`: what bend-lint changes in bend2 as Bun loads it; the files
  on disk never change. bend.ts's `term_infer` and `term_check` are renamed
  and wrapped by typed functions in `patch.ts` that record what they
  return, and bend.ts gets an `fs` and `path` whose real paths use `/` (so
  imports resolve on Windows; on POSIX they act as node's). comp.ts exports
  `RUNTIME_MAIN` and `js_sat`, so a Bend rule is compiled once.
- `src/lint.bend`, `src/lint.js`: the contract for Bend rules, and its
  effects.

bend-lint is not pinned to a bend version; it checks what it depends on
instead. Each text edit must match exactly once, and comp.ts must declare
what it exports. The wrappers pass every argument through, so bend computes
what it would without them; `tsc` checks them against bend's signatures,
and at load they must take the expected number of arguments. A self-check
then checks every field recorded for `x` in `def id(x: N) -> N: x`. Any
mismatch stops bend-lint with a `DriftError`, never a wrong result. The
tests catch subtler changes.

## Outside the bend repo

bend-lint needs a bend checkout, because it loads bend's source. Give it
with `--bend <dir>` or `$BEND_DIR`; with neither, it stops with a clear
error. For `tsc`, run `bun install` (for `@types/bun`) and point the
`bend2/*` path in `tsconfig.json` at that checkout's `bend2/`. The drift
tests read the checkout's own `tests/`.

## Test

```sh
bun test tools/bend-lint
bunx tsc -p tools/bend-lint/tsconfig.json --noEmit
```

Bun does not check types, so run `tsc` too. It reports two errors in
bend2/bend.ts (lines 2040 and 3771), which are on main too; bend-lint has
none.
