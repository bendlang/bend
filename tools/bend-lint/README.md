# bend-lint

`bend-lint` checks a Bend 2 file with bend's own checker, then runs your
rules on it. A rule reads the source text, the checker's types, or both,
and returns diagnostics with fixes. Bend itself does not change.

## Run

Bun 1.2 or newer is required, on Linux, macOS or WSL (bend resolves
imports with `/` paths, so native Windows cannot load relative imports).
From the repo root:

```sh
bun tools/bend-lint/src/cli.ts file.bend --rules my_rules.ts [--rules more.js] [--fix]
```

Exit codes: 0 no error, 1 an error was found (a failed check, or a rule
finding with severity `error`), 2 bad usage or a tool failure. `--fix`
writes the `safe` fixes to the files.

## Rules

A rule module default-exports an array of rules:

```ts
import type { LintRule } from "bend-lint"; // tools/bend-lint/src/index.ts

export default [{
  id: "style/comma-space",          // namespace/name; it is the diagnostic code
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
}] satisfies LintRule[];
```

Rules run in order, one at a time; `cx.prior` holds what earlier rules
found. A finding with severity `error` stops the run.

`cx` gives:

- `sources`, `root`: the files of the book as they are on disk.
- `facts` (with `needsTypes`): for each checked term, its type, context,
  depth and def. `fact.spn` is a span in the file on disk.
- `span(s)`: a span from bend.ts (for example `term.s`), mapped to the file
  on disk.
- `walk`, `binder`, `show`, `same`, `diag`: helpers over bend's terms.
- `Bend`: the bend.ts module, for anything else.

Get bend.ts from `cx.Bend`. Do not import `bend2/bend.ts` in a rule.

## How types are captured

bend.ts does not expose the checker's results. When bend-lint loads
bend.ts, it puts two recording wrappers around `term_infer` and
`term_check`. The file on disk does not change, and checking gives the same
results. The patch looks for the two exact signatures; if they changed, or a
self-check on a tiny program records no type, bend-lint stops with an
error. If bend.ts gets a `book.see` hook one day, bend-lint uses it and does
not patch.

## The bend.ts pin

`bend.pin` holds the git blob hash of the `bend2/bend.ts` this tool was
tested with. If bend.ts differs, bend-lint stops. To bump:

```sh
BEND_LINT_UNPINNED=1 bun test tools/bend-lint
bun tools/bend-lint/src/cli.ts --pin
```

## Test

```sh
bun test tools/bend-lint
```
