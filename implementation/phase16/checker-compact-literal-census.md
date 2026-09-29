# Literal expansion is the dominant term-growth mechanism

The bounded census passes on the identical frozen compiler source and reproduces
all2,171,037 raw KTerms from the earlier whole-source proof. No compiler body was
changed. It uses an identity-bound instrumentation-only API, CPU1,4MiB stack and
4GiB heap, verifies inputs before/after, and retains compact aggregate results.

| Structural group | Raw KTerms | Share |
| --- | ---: | ---: |
| String-shaped | 1,868,327 | 86.06% |
| U32-shaped | 170,690 | 7.86% |
| Char-shaped | 6,075 | 0.28% |
| F32-shaped | 166 | <0.01% |
| Compact Nat | 76 | <0.01% |
| Other word shapes | 180 | <0.01% |
| Other | 125,523 | 5.78% |

The main parsed AST contains94,044 terms and5,813 literal tokens:3,559 strings,
2,153 U32s,90 chars and11 Nats. No float literal occurs in that main source; the
small F32-shaped total mostly comes from Base or explicit constructors.

Actual builder entries independently identify the cause. The3,559 strings decode
27,244 characters. Those characters,90 standalone chars and2,153 U32 literals
invoke f_u32 exactly29,487 times. The word worker runs973,071 times, exactly33
per U32. Each word expands to65 terms plus its U32 wrapper. String construction
alone therefore creates1,856,151 KTerms before subsequent copying; the literal
builders together construct2,004,290 terms. These construction totals precede
later copying/discarding and are not an assertion about unique retained nodes.
Structural groups also contain explicitly written constructor-shaped expressions.

Pinned TypeScript already keeps number/string values in explicit Lit nodes and
unfolds them at head-demand boundaries. Its checker can accept a literal at the
matching trusted Base datatype without checking per-unit constructor trees.
Our compact Nat path demonstrates the same pattern locally; generalizing it is
a stronger direction than a Base-prefix cache optimization, which removed only
1.3244% of freshening entries.

The next representation and correctness plan is
[checker-compact-literals.md](../../design/phase16/checker-compact-literals.md).
The exact aggregates, builders and artifact hashes are in
[checker-compact-literal-census.json](checker-compact-literal-census.json).
The census makes no elapsed-speed claim and authorizes no production promotion.
