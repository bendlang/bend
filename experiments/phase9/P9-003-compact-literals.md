# P9-003 — Bounded literal descent, then compact literal demand

- Owner: conformance/literal agent; independent reviewer: root.
- Registered 2026-09-28 after root design commit `e7b2846`, before implementation.
- Objective: repair literal conformance and shorten validation without weakening
  termination or changing public value representations.
- Correctness: source inspection only at registration. Measurement: not run.
- Decision: investigate a narrow descent repair; compact-IR production changes
  require a separate root authorization after review.
- Findings: [literal feasibility](../../implementation/phase9/literal-feasibility.md).

## Claim and cheapest disproof

The existing structural descent traversal repeats each non-equal field result
and searches a failed field again as a possible proper subterm. Pinned upstream
records the first failing field and excludes it from that second search. A
faithful implementation should make increasing unary literal comparisons linear
in pattern depth and let short String suffix calls finish, preserving the exact
LT/EQ/GT and erased-column rules.

This is independent of compact IR. Current Nat values above 256 become calls to
U32.to_nat, while patterns become Succ chains; strings become constructor/bit
trees. Removing repeated descent does not claim to repair those representations.

Disproof: any changed structural order against upstream, acceptance of equal or
increasing self-calls, changed erased/lexicographic behavior, missing earlier
error, or failure of the checked build. Performance disproof is no useful growth
improvement on the bounded negative series. Preserve timeouts and failed builds.

## Stage A: smallest authorized repair

Only `selfhost/src/check/quantity.bend` and owned fixtures/tools. Return both the
field ordering and the first failed field index from the matching-constructor
walk, evaluate each child once, and skip exactly that index during the subsequent
proper-subterm search. Different constructor heads still search all fields.
Preserve declaration and field order; do not memoize terms or evaluate definitions.
Use the existing 0/1/2 = LT/EQ/GT convention and erased-column EQ behavior.

Freeze an isolated project from release07 and apply only this module change, so
concurrent kernel/normalizer ablations are absent. Build a genuine checked B1
through the maintained workflow on CPU3, 4 GiB heap/4 MiB stack, with finite
bootstrap and request deadlines. Keep the default distribution unchanged. A
successful selected gate permits root review, not automatic installation.

First gates:

1. Direct structural controls against upstream term_descend: equal Vars,
   different Vars, empty constructors, arity/head mismatches, a failed first or
   later field, proper-subterm successes outside that failed field, Ann/cell
   stripping, erased columns and lexicographic multi-argument order.
2. Actual checked fixtures: `check/string_literal_descends.bend` positive and
   `halt/literal_descent_linear.bend` negative, plus equal/increasing String and
   Nat recursion and a decreasing constructor control. Keep exact upstream
   fixture oracles; additional acceptance/phase controls are separate rows.
3. A finite negative Nat size series 4, 8, 12, 16, 32, 64 and 128. Stop baseline
   repetitions once a cap fires; never infer a completed duration from timeout.
   Candidate/reference must still reject each case for termination.
4. Recheck the other three known positive literal gaps with short finite caps;
   they are expected to remain and are not failure of the narrower claim.
5. After correctness, root schedules an uncontended frozen opposite-order
   comparison. Until then timings/counters are exploratory, not a speed claim.

Initial implementation/checkpoint budget: 45 minutes, followed by root review.
No broad corpus, full-source benchmark or self-emission without allocation.
An estimated 30–90 source lines and local linear-versus-exponential benefit are
hypotheses. No whole-compiler percentage is credited.

## Stage B: compact representation proposal, not yet authorized

The smallest coherent next representation is an atomic closed Nat literal,
followed by U32/F32 words and then valid scalar Strings. Match upstream demand:
ordinary weak-head normalization leaves Lit atomic; constructor comparison,
matching, checking fallback and structural descent expose exactly one layer.
Literal/literal comparison uses exact kind/payload. The checker accepts a literal
directly only against the actual native Base family with no removed constructors;
other expected types use its constructor step and the ordinary checker.

Do not hide numeric payloads in KTerm.id: norm_max_walk scans every id, so a
max-U32 literal could wrap the fresh-binder bound. A family-specific literal tag
with id=0 and numeric payload in an otherwise unused field can preserve the six
public KTerm fields, but every field/tag consumer must be audited. Strings need
a valid-scalar payload; invalid Unicode escapes keep an explicit constructor
chain so evaluation still raises the existing error at the same demand point.

An isolated prototype must cover parser/elaborator construction, generic graph
operations, ordinary and graph normalization, conversion, descent, checking,
annotation, pretty output, JS emission and native erasure together. A source-only
fast check that leaves downstream unknown tags is not a compiler candidate.
No reinterpretation of arbitrary U32.to_nat applications as literals: they are
ordinary source calls and can have different identity/demand semantics.

Prototype progression: Nat-only check/convert witness; checked Nat compiler and
actual JS/native fixture outputs; bounded U32/F32 extension; then String decoding
and scalar suffixes. Root reviews each boundary before expanding the scope.
Small native literal lowering can reuse existing scalar IR. Retain existing Nat
pattern-chain collection; verify large-pattern residual reconstruction by actual
C compilation/execution before claiming backend coverage.

## Falsifiers and impact accounting

- 0, 1, 255, 256, 257, 299, 300, 2^32−1 and rejected overflow; explicit
  Zero/Succ versus literal equations; computed/open tails and shadowed families.
- Wrong expected family, removed constructor, malformed/raw native metadata and
  mismatched constructor arity. Builtin spelling alone is not provenance.
- Equal/increasing recursion, multi-field descent and erased first arguments.
- Empty/6000-scalar Strings; embedded NUL, escapes, supplementary scalars;
  U+D7FF/U+D800/U+DFFF/U+E000/U+10FFFF/U+110000; malformed escape syntax.
- F32 signed zero, subnormals and explicit nonfinite bit constructors; source
  nonfinite numeric syntax retains its existing rejection.
- Substitution/freshening/quotation, shared literals, divergent unused neighbors,
  source diagnostics, reachable/unreachable branches and ordered runtime errors.
- Actual interpreter/JS/native value output and affine sharing/disposal; public
  BigInt Nat and named-field object/callback ABI must remain unchanged.

P6-012 skipped child annotation only after checking complete native word trees.
It added 273 lines and required a declaration certificate after forged-native
counterexamples. It did not compact parsing/checking or establish an integrated
speed result. Reusing it unchanged would not solve the current failures. A true
Lit representation is a separate semantic feature, with higher integration cost.

Estimate for review: Nat/word support is several hundred source lines across
multiple consumers, likely hours rather than a tiny local patch; String support
adds decoding and demand/error-order obligations. Compact nodes can eliminate
dozens of word-node checks or thousands of String descendants per literal, but
the fraction of current whole-source checking time remains unmeasured.

## Evidence and promotion

Freeze baseline/candidate source, checked API, runtime, canonical Base, host,
harness, commands, CPU/deadlines and all inputs in uniquely named phase9 runs.
Retain every failed attempt and the installed release07 as control. Store raw
rows and source patches durably before final consolidation. The findings report
records correctness, measurement and promotion separately; this prospective
record stays unchanged after execution.
