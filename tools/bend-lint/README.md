# bend-lint

bend-lint checks a Bend 2 file with bend's own checker, then runs your rules
on it. A rule reads the source text, the checker's result for each term
(type, scope, uses), or both, and returns findings with fixes. Bend itself
does not change. It needs Bun 1.2 or newer.

Tools will eventually live in their own repos, so bend-lint is maintained
separately at [github.com/MattCozendey/bend-lint](https://github.com/MattCozendey/bend-lint).

## Run

From the repo root:

```sh
bun tools/bend-lint/src/lint.ts file.bend [--rules rules.ts]... [--rules rule.bend]... [--config bend-lint.json] [--fix | --fix-suggested | --fix-dangerously] [--json] [--bend <dir>]
```

Findings print in bend's error layout, with a severity, a code, and each fix
as a diff. `--fix` writes the `safe` fixes to the linted file only, never
to its imports (a BendHub package under `~/.bend/lib` is never edited). Equal
edits merge; a fix that clashes with an earlier one is skipped and counted,
and another run applies it. `--fix-suggested` also writes the `suggested`
fixes, which may change behavior; `--fix-dangerously` writes every fix, even
one that may break code. Exit codes: 0 no error, 1 an error (the
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
Elsewhere, bend-lint downloads bend's source (see
[Outside the bend repo](#outside-the-bend-repo)).

## Rules in TypeScript

A rule module exports `rules`. A rule has an `id` (`namespace/name`, also
the code of its findings), an optional `facts` (see [Facts](#facts)), and a
`run` that may be `async`:

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
  facts: { kinds: ["Var"] },
  run: (cx) => [...cx.facts!.values()]
    .filter((f) => !f.inst)
    .map((f) => cx.diag({ message: "type: " + cx.show(f, f.ty), severity: "hint", spn: f.spn, fact: f })),
}];
```

| `cx` | |
|---|---|
| `root`, `sources` | the linted file and its imports, as on disk |
| `facts` | the facts the rule asked for: per checked term, its type, scope, depth, def, quantity, uses, and span on disk |
| `prior` | the findings of earlier rules |
| `span(s)` | a bend span (e.g. `term.s`), moved to the file on disk |
| `walk`, `binder`, `show`, `same`, `normal`, `uses` | helpers over bend's terms |
| `diag({...})` | a finding; the default severity is `warning` |
| `Bend` | the bend module; use it, do not import `bend2/bend.ts` |

Severities: `error` (stops the run), `warning`, `information`, `hint`. Fix
levels: `safe` keeps behavior, `suggested` may change it, `dangerous` may
break code.

Rules run in order; none runs when the file does not check. A file with a
line exactly `import Base` (as `bend --checkup` reads it) reuses a Base
checked once per process.

## Facts

A fact is what the checker found for one term. A rule gets facts only if it
asks with `facts`: `true` for all of the linted file's, or a filter. A fact
must match each list given; an absent or empty list matches all:

```ts
facts: {
  scope: "file",     // "file" (default): the linted file; "program": its imports too, never Base
  kinds: ["Var"],    // the term's kind, annotations stripped: Var, Ref, App, Lam, Lit, ...
  defs: ["main"],    // the def whose body holds the term; a template's instances count as it
  names: ["foo"],    // the name a Var or Ref points to
}
```

bend-lint keeps a fact only if some rule asks for it, and drops the rest as
the checker gives them, so a narrow filter costs little. Each rule gets only
its own. On a 3,200-proof file (1.27M facts) peak memory was 0.77 GB with no
facts, 2.6 GB with all, 1.5 GB with `kinds: ["Var"]`. A template body is
checked as written and again per instance (`generic~0`) at the same spans;
`fact.inst` marks the instances.

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

def facts() -> Lint.Want:      # Lint.NoFacts{}, or Lint.Want{scope, kinds, defs, names}
  Lint.NoFacts{}

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  IO.pure(List<&2, Lint.Diag>, [])

def main() -> IO(Unit):
  Lint.serve(run)
```

`input` holds the sources and the rule's options. A rule that wants facts
returns a filter, as in [Facts](#facts), with empty lists for "all":
`Lint.Want{Lint.File{}, ["Var"], [], []}`. It then reads them one at a time,
so a big file never becomes one big list:

```python
def step(found: List<&2, Lint.Diag>, +f: Lint.Fact) -> IO(List<&2, Lint.Diag>):
  ...

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  Lint.fold_facts(~List<&2, Lint.Diag>, ~step, [])
```

`fold_facts` takes `step` as a template (`~step`), and `step` takes its fact
as `+f`. Read an option with `Lint.option_number`, `option_flag` or
`option_text`, each with a default; numbers are whole (U32). A rule asks about
a fact with effects (`Lint.view`, `type_of`, `binder`, `same`, `show`,
`normal`, `uses`, `text`) and may use Base's effects too. Offsets count
characters. bend-lint compiles a rule once; each run then takes about 10 ms.
A rule runs on bend's JS runtime, where only tail calls run as loops: walk
a long text or list with a tail call, or the stack overflows.
`COMMA_BEND`, `TYPES_BEND` and `COUNT_BEND` in `test/lint.test.ts` are
complete examples.

## Rules shipped here

`rules/` holds ready rules, one per file. None runs unless you pass it with
`--rules`, and `bend-lint.json` can turn one `"off"`:

| File | Rule | What | Fix |
| --- | --- | --- | --- |
| `trailing_whitespace.ts` | `style/trailing-whitespace` | spaces or tabs at the end of a line | safe: delete them |
| `line_length.bend` | `style/line-length` | a line longer than `max` characters (default 100) | none |

```sh
bun tools/bend-lint/src/lint.ts file.bend --rules tools/bend-lint/rules/trailing_whitespace.ts --rules tools/bend-lint/rules/line_length.bend
```

To add a rule, add one file: a `.ts` file that exports `rules`, or a `.bend`
file as above. Helpers used by more than one rule go in `rules/shared.ts`
or `rules/shared.bend`.

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

bend-lint loads bend's source, not the `bend` program. With no `--bend`
or `$BEND_DIR`, and no bend repo around it, it downloads the source of one
bend release from GitHub: the version of the `bend` on your PATH (`bend
version`), else the newest release (asked once a day). It takes only
`bend2/bend.ts`, `comp.ts`, `base.bend` and the `effs/` files Base imports
(about 0.6 MB), and keeps them in `~/.cache/bend-lint/<version>/`
(`$XDG_CACHE_HOME`, or `%LOCALAPPDATA%` on Windows). Later runs use the
cache, with no network; offline, it uses the newest release cached. If a
release changes what `src/patch.ts` edits, bend-lint stops with a
DriftError, as it does for a checkout. For `tsc`, run `bun install` (for `@types/bun`) and point the
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
