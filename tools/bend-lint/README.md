# bend-lint

`bend-lint` checks a Bend 2 file with bend's own checker, then runs your
rules on it. A rule reads the source text, the checker's types, or both,
and returns diagnostics with fixes. Bend itself does not change.

- `src/lint.ts`: the library and the CLI.
- `src/patch.ts`: the two changes made to `bend2/bend.ts` as Bun loads it,
  and the pin.
- `src/lint.bend`, `src/lint.js`: the contract for rules written in Bend,
  and its effects.

## Run

Bun 1.2 or newer is required. From the repo root:

```sh
bun tools/bend-lint/src/lint.ts file.bend --rules my_rules.ts [--rules more.js] [--fix]
```

Exit codes: 0 no error, 1 an error was found (a failed check, or a rule
finding with severity `error`), 2 bad usage or a tool failure. `--fix`
writes the `safe` fixes to the files.

## Rules

A rule module exports `rules`, an array of rules:

```ts
import type { LintRule } from "./tools/bend-lint/src/lint.ts";

export const rules: LintRule[] = [{
  id: "style/comma-space",          // namespace/name; the code of its findings
  needsTypes: false,                // true gives the rule cx.facts
  run(cx, signal) {
    return [...cx.root.text.matchAll(/,(?=\w)/g)].map((m) => {
      const spn = { file: cx.root.file, beg: m.index + 1, end: m.index + 1 };
      return cx.diag({
        message: "Add a space after the comma.", severity: "warning", spn,
        fixes: [{ title: "Insert space", applicability: "safe", edits: [{ spn, text: " " }] }],
      });
    });
  },
}];
```

A file with its own `import Base` starts from a copy of Base, checked once
per process (again only if base.bend changes), and facts of Base's own defs
are not recorded.

Rules run in order, one at a time; `cx.prior` holds what earlier rules
found. A finding with severity `error` stops the run.

`cx` gives:

- `sources`, `root`: the files of the book as they are on disk.
- `facts` (with `needsTypes`): for each checked term, its type, context,
  depth, def, quantity, uses, and span in the file on disk. A template body
  is checked as written and again per instance (`generic~0`), at the same
  spans; `fact.inst` marks the facts of an instance.
- `span(s)`: a span from bend.ts (for example `term.s`), in the file on
  disk.
- `walk`, `binder`, `show`, `same`, `diag`: helpers over bend's terms.
- `Bend`: the bend.ts module, for anything else.

Get bend.ts from `cx.Bend`. Do not import `bend2/bend.ts` in a rule.

## Rules written in Bend

A `.bend` rule imports `src/lint.bend` (by a relative path) and defines
`id()`, `types()`, `run(input)` and a `main` that hands `run` to
`Lint.serve`; `src/lint.bend` lists the contract. `run` gets the sources
and, with `types()` true, the facts (as indexes, `Lint.Fact`); it asks about them
through effects (`Lint.view`, `Lint.type_of`, `Lint.binder`, `Lint.same`,
`Lint.show`) and answers a list of `Lint.Diag`. Offsets count characters.

```sh
bun tools/bend-lint/src/lint.ts file.bend --rules my_rule.bend
```

bend-lint checks the rule once; each run compiles it and runs its `main`
with bend's own IO runtime (`comp.ts` `io_run`), so a rule may also use
Base's effects. Effects run synchronously.

## The patch

bend.ts does not expose the checker's results, and builds file paths with
`/`. As Bun loads bend.ts, `patch.ts` changes two things; the file on disk
does not change:

1. `term_infer` and `term_check` get wrappers that record what they return.
   Checking gives the same results.
2. bend.ts gets `fs` and `path` from `patch.ts`, where real paths use `/`
   and a drive letter is a root, so imports resolve on Windows too. On
   POSIX these behave as node's.

Each change looks for one exact anchor in bend.ts. If an anchor is not
found exactly once, or a self-check on a tiny program records no type,
bend-lint stops with a `DriftError`.

## The pin

`bend.pin` holds the git blob hashes of the `bend2/bend.ts` and
`bend2/comp.ts` this tool was tested with (`git rev-parse HEAD:<file>`).
If either differs, bend-lint stops. To bump:

```sh
BEND_LINT_UNPINNED=1 bun test tools/bend-lint
bun tools/bend-lint/src/lint.ts --pin
```

## Test

```sh
bun test tools/bend-lint
```
