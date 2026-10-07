# bend-lint

bend-lint checks a Bend 2 file with bend's own checker, then runs your rules
on it. A rule reads the source text, the checker's result for each term
(type, scope, uses), or both, and returns findings with fixes. Bend itself
does not change. It needs Bun 1.2 or newer.

## Run

From the repo root:

```sh
bun tools/bend-lint/src/lint.ts file.bend [--rules rules.ts]... [--rules rule.bend]... [--fix]
```

Findings print in bend's error layout, with a severity, a code, and each fix
as a diff. `--fix` writes the `safe` fixes. Exit codes: 0 no error, 1 an
error (the file does not check, or a rule found an `error`), 2 bad usage or
a tool failure.

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
| `facts` | with `needsTypes`: per checked term, its type, scope, depth, def, quantity, uses, and span on disk |
| `prior` | the findings of earlier rules |
| `span(s)` | a bend span (e.g. `term.s`), moved to the file on disk |
| `walk`, `binder`, `show`, `same`, `normal`, `uses` | helpers over bend's terms |
| `diag({...})` | a finding; the default severity is `warning` |
| `Bend` | the bend module; use it, do not import `bend2/bend.ts` |

Severities: `error` (stops the run), `warning`, `information`, `hint`. Fix
levels: `safe` keeps behavior, `suggested` may change it, `dangerous` may
break code.

Rules run in order; none runs when the file does not check. Base's own defs
give no facts. A template body is checked as written and again per instance
(`generic~0`) at the same spans; `fact.inst` marks the instances. A file with
`import Base` reuses a Base checked once per process.

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

`input` holds the sources and, with `types()`, the facts. A rule asks about
a fact with effects (`Lint.view`, `type_of`, `binder`, `same`, `show`,
`normal`, `uses`, `text`) and may use Base's effects too. Offsets count
characters. bend-lint compiles a rule once; each run then takes about 10 ms.
`COMMA_BEND` and `TYPES_BEND` in `test/lint.test.ts` are complete examples.

## From code

```ts
import { applyFixes, bendRule, lint, render } from "./tools/bend-lint/src/lint.ts";

const res = await lint("file.bend", [...rules, await bendRule("rule.bend")]);
console.log(res.ok, res.diags.map(render));
const fixed = applyFixes(res.sources.find((s) => s.root)!.file, res.diags);
```

## How it works

- `src/lint.ts`: the library and the CLI.
- `src/patch.ts`: what bend-lint changes in bend2 as Bun loads it; the files
  on disk never change. bend.ts gets recording wrappers around `term_infer`
  and `term_check`, and an `fs` and `path` whose real paths use `/` (so
  imports resolve on Windows; on POSIX they act as node's). comp.ts exports
  `RUNTIME_MAIN` and `js_sat`, so a Bend rule is compiled once.
- `src/lint.bend`, `src/lint.js`: the contract for Bend rules, and its
  effects.

Each change needs one exact anchor, and a self-check runs at load.
`bend.pin` holds the git blob hashes of bend.ts and comp.ts. Any mismatch
stops bend-lint with a `DriftError`, never a wrong result. To bump:

```sh
BEND_LINT_UNPINNED=1 bun test tools/bend-lint
bun tools/bend-lint/src/lint.ts --pin
```

## Test

```sh
bun test tools/bend-lint
bunx tsc -p tools/bend-lint/tsconfig.json --noEmit
```

Bun does not check types, so run `tsc` too. It reports two errors in
bend2/bend.ts (lines 2040 and 3771), which are on main too; bend-lint has
none.
