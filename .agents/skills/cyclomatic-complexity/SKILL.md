---
name: cyclomatic-complexity
description: Refactor code to reduce cyclomatic complexity so it stays readable, maintainable, and aligned with the long-term vision of the codebase, not just optimized for AI comprehension. Use whenever the user asks to refactor, simplify, clean up, or review code quality; mentions complexity, maintainability, readability, spaghetti code, deeply nested logic, or god functions; or asks to check AI-generated code before merging. Also use proactively after writing any nontrivial function with heavy branching.
---

# Cyclomatic Complexity

Purpose: AI-written code often works but branches like a jungle. This skill: measure complexity, refactor hotspots, keep code human-maintainable.

## Measure first

CC = decision points + 1. Decision points: `if`, `else if`, `case`, loops, `catch`, ternary, `&&`, `||` in conditions.

Project linter config wins. If eslintrc, radon config, sonar config, or similar sets a complexity threshold, use that. No config: use defaults below.

Thresholds:
- 1-5: fine, leave alone
- 6-10: watch, refactor if touching anyway
- 11-15: refactor now
- 15+: must split, no debate

Prefer real tools over eyeballing when environment allows:
- Python: `radon cc -s -a <path>`
- JS/TS: eslint `complexity` rule
- Go: `gocyclo`
- Polyglot: `lizard <path>`

No tool available: count manually, per function, show the count.

## Refactor tactics, in order of preference

1. **Guard clauses.** Invert conditions, return early, kill nesting.
2. **Extract function.** Each extracted piece gets a name that says what, not how. Names are documentation.
3. **Lookup table / map** instead of if-else or switch chains.
4. **Named predicates.** `if (isEligibleForRefund(order))` beats a 4-clause boolean soup.
5. **Polymorphism / strategy** for switch-on-type. Only when the switch appears in 2+ places.
6. **Flatten loops.** Extract loop body, use continue instead of nested if.

## Hard rules

- Preserve behavior. Run tests before and after. No tests: say so, suggest adding, refactor conservatively.
- Don't game the metric. A dense one-liner hiding 6 branches is worse than the honest if-chain it replaced. Complexity should move into well-named units, not disappear into cleverness.
- Don't break public APIs or exported signatures without asking.
- Small functions with clear names > few functions with comments explaining sections.
- One responsibility per function. If the name needs "and", split.

## Workflow

1. Measure all touched functions, rank by CC descending.
2. Report hotspots with numbers before touching anything.
3. Refactor worst first, one function at a time.
4. Re-measure. Show before/after table: function, CC before, CC after.
5. Verify: tests pass, behavior unchanged, diff reviewable.

## Output format

End every refactor with:

```
## Complexity report
| Function | Before | After |
|----------|--------|-------|
| parseOrder | 14 | 4 |

Extracted: validateHeader, resolveDiscount
Behavior verified: <how>
```

Keep prose minimal. Numbers and diffs do the talking.