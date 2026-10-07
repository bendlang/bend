# bend-lint guide

This guide shows how to run bend-lint and how to write your own rules. The
README describes how the tool works inside.

## What bend-lint does

bend-lint checks a `.bend` file with bend's own checker, then runs rules on
it. A rule finds problems and can propose fixes. A rule can read:

- the source text (style, format), and
- the checker's results for each term: its type, its scope, how many times
  it is used.

bend itself does not change. You need Bun 1.2 or newer.

## 1. Run it

From the repo root:

```sh
bun tools/bend-lint/src/lint.ts my_file.bend
```

With no rules, bend-lint only checks the file, as `bend --check-only` does.
Give rules with `--rules`, once per module:

```sh
bun tools/bend-lint/src/lint.ts my_file.bend --rules my_rules.ts --rules my_rule.bend
bun tools/bend-lint/src/lint.ts my_file.bend --rules my_rules.ts --fix
```

`--fix` writes the `safe` fixes into your files.

A finding prints in bend's error layout, with its severity and code, and
each fix as a diff:

```
Warning [style/comma-space]:
- message  : Add a space after the comma.
Location:
...
Fix: Insert space [safe]
--- my_file.bend
+++ my_file.bend
@@ -27,1 +27,1 @@
-  generic(~N,a)
+  generic(~N, a)
```

Exit codes:

| Code | Meaning |
|---|---|
| 0 | no error |
| 1 | an error: the file does not check, or a rule found an `error` |
| 2 | bad usage, or a tool failure |

## 2. Write a rule in TypeScript

A rule module exports `rules`, an array of rules. Each rule has:

- `id`: `namespace/name`. This is also the code of its findings.
- `needsTypes` (optional): `true` gives the rule the checker's results.
- `run(cx, signal)`: returns a list of findings. It can be `async`.

### A rule that reads text

```ts
import type { LintRule } from "./tools/bend-lint/src/lint.ts";

export const rules: LintRule[] = [{
  id: "style/comma-space",
  run(cx) {
    return [...cx.root.text.matchAll(/,(?=\w)/g)].map((m) => {
      const spn = { file: cx.root.file, beg: m.index! + 1, end: m.index! + 1 };
      return cx.diag({
        message: "Add a space after the comma.",
        severity: "warning",
        spn,
        fixes: [{ title: "Insert space", applicability: "safe", edits: [{ spn, text: " " }] }],
      });
    });
  },
}];
```

### A rule that reads types

With `needsTypes: true`, `cx.facts` holds one fact per checked term: the
term, its type, its scope, its depth, its def, its uses, and its span in the
file on disk.

```ts
import type { LintRule } from "./tools/bend-lint/src/lint.ts";

export const rules: LintRule[] = [{
  id: "demo/var-types",
  needsTypes: true,
  run(cx) {
    return [...cx.facts!.values()]
      .filter((f) => !f.inst                         // skip copies from template instances
        && f.spn?.file === cx.root.file              // only the linted file
        && cx.Bend.term_strip(f.tm).$ === "Var")
      .map((f) => cx.diag({ message: "type: " + cx.show(f, f.ty), severity: "hint", spn: f.spn, fact: f }));
  },
}];
```

### What `cx` gives

| Field | What it is |
|---|---|
| `root`, `sources` | the linted file and its imports, as they are on disk |
| `facts` | the checker's results (only with `needsTypes`) |
| `prior` | the findings of the rules that ran before this one |
| `span(s)` | a span from bend (for example `term.s`), moved to the file on disk |
| `walk(tm)` | every sub-term of a checked term |
| `binder(fact, v)` | the binder a variable refers to, with its type |
| `show(fact, t)` | a type as text |
| `same(fact, a, b)` | whether the checker finds two types equal |
| `normal(fact, t)` | the normal form of a type |
| `uses(fact)` | the variables a term uses, and how many times |
| `diag({...})` | makes a finding; the default severity is `warning` |
| `Bend` | the whole bend module, for anything else |

Severities: `error` (stops the run; exit 1), `warning`, `information`,
`hint`.

Fix levels: `safe` keeps behavior (`--fix` applies these), `suggested` may
change behavior, `dangerous` may break code.

### Things to know

- Get bend from `cx.Bend`. Do not import `bend2/bend.ts` in a rule.
- Base's own defs give no facts. You see only your code and its imports.
- A template body is checked once as written and once per instance
  (`generic~0`), at the same spans. Use `fact.inst` to skip the instances.
- Rules run in the order you give them. When the file does not check, no
  rule runs.

## 3. Write a rule in Bend

A Bend rule imports `tools/bend-lint/src/lint.bend` by a relative path and
defines four things:

```python
import Base
import ../tools/bend-lint/src/lint.bend as Lint

def id() -> String:
  "demo/nothing"

def types() -> Bool:
  False{}

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  IO.pure(List<&2, Lint.Diag>, [])

def main() -> IO(Unit):
  Lint.serve(run)
```

- `types()` is `True{}` if the rule needs the checker's results.
- `input` holds the sources (path, text, root) and, with `types()`, the
  facts.
- Ask about a fact with these effects: `Lint.view`, `Lint.type_of`,
  `Lint.binder`, `Lint.same`, `Lint.show`, `Lint.normal`, `Lint.uses`,
  `Lint.text`. `src/lint.bend` lists them, and all types.
- Offsets in Bend count characters.
- A Bend rule can also use Base's effects (files, printing).
- bend-lint compiles a Bend rule once. Each run after that takes about
  10 ms.

For two complete rules, see `COMMA_BEND` (text) and `TYPES_BEND` (types)
in `test/lint.test.ts`.

## 4. Test your rule

Use the library in a `bun test`:

```ts
import { applyFixes, bendRule, lint, render } from "./tools/bend-lint/src/lint.ts";
import { rules } from "./my_rules.ts";

const res = await lint("example.bend", rules);          // or [await bendRule("my_rule.bend")]
console.log(res.ok, res.diags.map(render));
const root = res.sources.find((s) => s.root)!;
const fixed = applyFixes(root.file, res.diags);          // the text with the safe fixes
```

## 5. When bend changes

bend-lint is pinned to the `bend2/bend.ts` and `bend2/comp.ts` it was tested
with (`bend.pin`). When they change, bend-lint stops with a `DriftError`.
It does not give wrong results. To accept the new version:

```sh
BEND_LINT_UNPINNED=1 bun test tools/bend-lint
bun tools/bend-lint/src/lint.ts --pin
```

If a test fails, the error names the part of bend-lint to update.
