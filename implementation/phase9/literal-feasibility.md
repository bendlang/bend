# Literal feasibility and narrow descent repair

Initial evidence cutoff: 2026-09-28, Phase9 design commit `e7b2846`.
This section is read-only diagnosis. No speed measurement or compact-literal
implementation is credited. [Prospective experiment](../../experiments/phase9/P9-003-compact-literals.md).

## Three concrete causes

1. `src/check/quantity.bend:115` calls `descend` twice for a non-EQ field. Its
   `descend_ctr` then searches the same failed field again through `descend_sub`.
   Pinned `bend2/bend.ts:3207` stores that failed index and excludes it. Unary
   increasing arguments therefore revisit suffixes in the port, explaining the
   negative 64n→65n timeout. A String head is itself a 32-bit constructor tree;
   the same failed-field search can obstruct the tiny `"ab"`→`"b"` suffix case.
   This repair needs no literal IR or arithmetic shortcut.
2. `src/front/elaborate.bend:407` constructs Nat chains only through 256; larger
   values become `U32.to_nat` applications. `front/literals_arrays.bend:167`
   constructs all Nat patterns as chains. Structural descent does not normalize
   calls, so 299n as an application fails to match a subterm of the 300n pattern.
   This accounts for the two deep-Nat positive termination refusals.
3. `front/unicode.bend:59` expands each String scalar into SCon, Chr, U32 and
   32 Word bits before checking. `check/string_literal_long.bend` has 6000
   characters and overflows the stack. The current path cannot receive a
   constant-size literal checking rule because no compact node survives loading.

These are source-supported mechanisms. The Phase8 raw observations establish
the failures; a bounded Phase9 reproduction must establish the proposed repair.

## Upstream's actual Lit contract

The pinned upstream `bend2/bend.ts` uses numeric Lit nodes for Nat/U32/F32 and
text Lit nodes for Strings. `lit_step` at 1089 exposes one constructor layer;
Nat's tail remains Lit(n−1), a String's tail remains Lit(rest), and U32/F32 expose
their finite 32-bit tree. Plain weak-head evaluation does not eagerly expand Lit.
Its match continuation (2938), conversion against Ctr (3062), structural descent
against a constructor pattern (3213), and checking fallback (3557) demand a step.

The fast checking rule requires the normalized expected type to be the same ADT
family, with no removed constructors, and the actual book declaration marked as
Base/native. It returns no variable usage. Other expected types check the first
constructor step normally. Literal inference still requires an annotation;
an atomic representation must not invent a new inference rule.

`lit_of` at 1081 deliberately refuses to store surrogate/out-of-range escapes as
host String text. Those inputs stay explicit constructor chains and retain their
later scalar validation behavior. A host String-only parser shortcut would
silently alter this contract. Literal Nat syntax is bounded by U32 even though
the public runtime Nat ABI remains BigInt.

## Smallest useful boundaries

First repair structural descent alone in `check/quantity.bend`: evaluate a field
once, retain the failed index and skip exactly that child during subterm search.
Root authorized this after the read-only finding; kernel/normalize remain owned
by the independent checker agent. An isolated release07 snapshot will prevent
their ablations from entering this candidate.

The next coherent representation candidate starts with Nat, not all literals.
A new atomic node must survive parsing, generic transforms, checking and
annotation, while comparison/matching/termination expose it on demand. Actual
JS/native output support belongs in that same candidate before promotion. The
existing native `back/native/pattern.bend` already collects Nat matcher chains;
its behavior must be tested, not assumed to solve all new residual reconstruction.

Keep KTerm's six named fields if possible. **Do not store a numeric value in
`id`: `core/normalize.bend:289` takes the maximum id of every node, and max-U32
payload would wrap the fresh identity counter.** A family-specific literal tag,
zero id and payload in an otherwise unused field avoids that particular hazard.
This still changes the semantic IR contract and requires checking every tag and
quantity-field consumer. Generic empty-child traversal already helps substitution
and graph scanning, but unknown tags currently fail comparison/checking/emission.

The consumer audit must include both `norm_match` and graph machine matching,
`norm_cmp_heads/plain`, `check_node`, `ka_node/ka_type_node`, pretty/readback,
JS literal recognition and native typed erasure. Normalizing all literals at wnf
entry would erase the benefit and can change when errors/divergence are demanded.

## Relationship to previous attempts and expected cost

[P6-012](../phase6/closed-word-readback.md) retained full literal trees and only
skipped child annotations for selected JS emission. Its first name/native-flag
certificate accepted malformed native declarations; the strengthened certificate
cost 273 Bend lines. Focused graph correctness and smaller Ann counts were
recorded, but no integrated promotion or current-target speed benefit follows.
It cannot repair literal loading, checking depth or termination recognition.

The descent repair is expected to cost tens of lines and offers a specific
linear-versus-repeated-search benefit. A compact Nat/word representation is a
multi-module change of several hundred lines; String support adds Unicode,
stack-depth and demand-order work. These are implementation estimates, not
measured savings. Local literal checking should lose most per-constructor work;
the whole-source share of that work must still be measured. The Phase8 73.20×
checking deficit is not attributable entirely to literals from current evidence.

No public runtime value representation should change: native words remain native
words, public Nat remains BigInt in JS, and named-field foreign objects/callbacks
keep their ABI. Compiler graph caches must be tied to the changed source/API;
old parsed Base caches cannot be silently reused under the new literal contract.

## Required next observations

The experiment specifies exact positive/negative fixtures, growth series,
provenance, Unicode/word/Nat boundaries, direct structural falsifiers and actual
backend outputs. Root must review the checked narrow repair before authorizing
compact production changes. Outcomes and failed attempts will be appended here
without changing the prospective plan.

## Descent-only outcome and compact Nat preregistration

The checked descent candidate adds 19 net Bend lines, preserving upstream's failed
field index and avoiding duplicate child comparisons. All 353 direct valid graph
controls agree with upstream after correcting a harness mistake that represented
an upstream variable cell as a function. Both the failed first vector and corrected
vector are retained. At increasing Nat 8, observed recursive calls fall from 9,841
to 9; at Nat 128 the repaired traversal uses 129 calls while the baseline hits the
explicit 200,000-call observation cap. These are mechanism counts, not a controlled
wall-time speedup claim.

The 21-row source gate agrees semantically with TypeScript throughout, including
actual interpreter and JS execution of string_literal_descends. Its sole strict
oracle failure is the known missing caret on literal_descent_linear, which now
terminates with the correct check rejection. The three remaining representation
cases are not repaired: two Nat 300 cases still reject; long String reaches the new
10-second cap (the Phase8 30-second observation reached stack overflow). Resource
limits differ, so the String observation is not evidence of a new regression.

Before the next source change, root authorizes an isolated compact-Nat prototype.
It starts from the frozen descent candidate, not concurrent kernel experiments.
The representation is tag LitNat, empty name, id zero, quant carrying the exact
U32-bounded source numeral, and no children. This does not add arbitrary precision
or alter public BigInt Nat values. Ordinary wnf leaves it atomic; constructor
comparison, matching (including graph evaluation), checking fallback, and structural
descent expose one layer. Parsing n+ must preserve folding and overflow behavior;
patterns keep their demand shape. Annotation must expand custom/non-native Nat
fallbacks rather than silently using native layouts. Pretty, JS literal lowering,
and native immediate-word lowering are part of this same prototype.

Before integration, require checked compiler construction, Nat 0/256/257/300 and
max-U32 boundaries, dynamic n+ and overflow controls, freshness unaffected by
payload, malformed direct graph controls, custom Nat fallback, graph strong
normalization, and actual interpreter/JS/native result parity. The initial bound
is a narrow prototype and selected gates; there is no permission to substitute a
checker-only result for a complete compiler or to run broad timing/corpus jobs.
Any unmet consumer obligation will be stated explicitly with the candidate patch.

## Compact Nat findings

The isolated candidate uses 41 net additional Bend lines across 12 modules,
relative to the descent repair. The six-field KTerm layout and public runtime
values are unchanged; the internal tag contract changes. Nat source literals
are exact U32-bounded payloads. Computed JS/native Nat values may exceed U32;
they must not be folded through the U32 payload slot.

Five named build attempts are retained. Attempt01 failed bootstrap parsing due
to a misplaced wrapper parenthesis across a following law. Attempt02 built and
passed the default 21 controls, but direct host-forged payload observations
exposed missing defensive validation. Attempt03 added that guard and exposed a
native constant-folding bug: Succ{4294967295n} wrapped to zero. Attempt04 retained
that Succ dynamically and passed actual native boundary execution. Its printer
still folded that term to 4294967296n, whereas upstream readback deliberately
prints 1n+4294967295n because source numeral syntax is U32-bounded. Attempt05 adds
that readback bound. All failed observations remain separate; the test oracle
was not weakened to make the candidate pass.

The final candidate05 has genuine checked B1 lineage and passes the maintained
21 controls with their unchanged 12 exact differences. Its 120 direct graph
controls pass: atomic weak/strong normalization; one-step comparison in both
directions; graph matching; 0/1/255/256/257/300/max-U32 boundaries; maximum-id and
capture checks; native/custom Nat annotation; removed constructors; malformed
metadata and numeric payloads; native overflow fallback; and readback bounds.
These helper exports are disposable views of the checked image, not a release
artifact or proof of a self-hosting fixed point.

The final selected source gate has 40 rows: TypeScript passes all 40; candidate05
passes 35 strict oracles and correctly rejects the five remaining negative rows
with the same known diagnostic differences as the installed baseline. All 40
paired semantic observations agree, and no input identities changed. The target
harness truthfully retains selectedComplete:false. Actual interpreter and JS
execution pass for nat_literal_unfolds, including max-U32 output. Four boundary
programs also pass actual Clang16/native execution. Separate readback fixtures
preserve upstream's different interpreter and compiled output above U32.
The no-Base custom Nat case passes check/interpreter and direct annotation
expansion; the maintained harness excludes its compiled lanes.

### Deep-pattern backend gap retained

The two former Nat-300 type-check rejections are repaired. This does **not**
mean both programs now compile efficiently. nat_pattern_deep checks and interprets
correctly, but JS compilation reached a 70-second outer bound and native reached
its 30-second row bound. Traces place about 22 seconds in the shared runtime-layout
validation pass before emission. No full compiled success is claimed for that case.

A separate equivalent source writes every 299/300 value as explicit Succ/Zero
constructors and runs on the descent-only baseline. TypeScript passes all four
lanes; Bend checks and interprets it, then both JS/native also hit 30-second
bounds, with about 21 seconds in that same validation pass. This establishes
that the deep-pattern backend scaling problem exists without compact Nat nodes.
It remains a separate follow-up; it was not concealed by raising resource limits.
The native sandbox initially returned EPERM for Clang; those vectors are retained,
followed by actual executions under the authorized local toolchain configuration.

The long String literal gap is unchanged and needs a separate coherent literal
representation across parsing, Unicode, checking, normalization, annotation and
both emitters. This Nat prototype does not solve it by changing an arbitrary
expansion threshold. No speed estimate for the whole compiler is credited from
these conformance or exploratory phase-trace observations.

### Review and integration boundary

Only the reviewed descent repair has been copied to production by this owner.
The Nat prototype remains isolated. The current-root patch preserves the other
agent's kernel/normalize edits and records exact preimage hashes. A fresh full
assembled-source ordinary-check/trust preflight completed under 285-second child
and 300-second outer limits; its result and the integration recommendation are
recorded below. Broad corpus, combined-source validation and controlled timing
remain root-owned gates. No full-language pass count or speed ratio is inferred
from the selected 40-row gate.

The exact integration diff is
[compact-nat-current-root.patch](../../selfhost/build/phase9/literals/compact-nat-current-root.patch),
bound to [current source preimages](../../selfhost/build/phase9/literals/integration-current-inputs.json).
It adds 41 net lines and preserves the separate checker optimizations. The
[40-row selection](../../selfhost/build/phase9/literals/nat-final-selection.json)
is API-independent so the final integrated compiler can rerun the same actual
controls. Its raw [paired vector](../../selfhost/build/phase9/literals/nat-final-05/paired.json)
retains strict failures separately from semantic agreement. The failed deep
backend controls are [literal native](../../selfhost/build/phase9/literals/nat-native-04/paired.json)
and [explicit baseline](../../selfhost/build/phase9/literals/nat-expanded-baseline/paired.json).
The unified Phase9 collector owns durable retention of these inputs and outcomes.

### Final owner gate and recommendation

The [complete-source preflight](../../selfhost/build/phase9/literals/nat-full-source-05/report.json)
passes. Candidate05 accepts its complete assembled compiler source's types and
returns the expected unsafe-declaration trust refusal. Pinned TypeScript agrees
on the exact unsafe-definition set; all bound input identities remain unchanged.
Candidate process/request observations are 199.83s/198.74s, versus 2.77s/1.81s for
TypeScript. This was a concurrent correctness preflight, not a controlled timing
window, and measures ordinary checking/trust reporting rather than emission.
It is neither a new fixed-point claim nor a performance promotion result.

Recommendation: integrate the reviewed current-root compact-Nat patch for its two
established type-checking repairs, then run the root-owned combined build, the
same 40-row actual execution selection, broader frontend conformance and controlled
performance comparison. The explicit baseline establishes that deep-pattern
backend scaling remains independently unresolved. Long String remains outside
this Nat-only representation. Final owner output is frozen in
[final-status.json](../../selfhost/build/phase9/literals/final-status.json); CPU3
compiler work is paused. Only the earlier reviewed descent repair has been applied
to production by this owner.

### Integrated audit and inference diagnostic repair

The complete integrated02 frontend vector contains 2,996 observations and exactly
five changed baseline rows, all in the check lane. Three positive cases improve:
string_literal_descends moves from timeout to acceptance, and nat_pattern_deep
and nat_literal_unfolds move from false termination refusal to acceptance.
The negative literal_descent_linear moves from timeout to the correct termination
refusal, retaining its missing-caret exact difference.

The fifth change is a real diagnostic regression: nat_literal_import still
refuses at check time, but says “an annotated term (cannot infer)” where upstream
and the pre-compact baseline say “a declared constructor”. The original selected
suite did not include this inference-only case. Its full integrated02 vector is
preserved as the regression witness. Pinned upstream's inference fallback inspects
a literal's first constructor step before deciding whether that constructor is
undeclared. Root authorized a one-line repair to the final infer_node fallback:
for a valid compact Nat, infer its first step; otherwise retain the old error.
The ordinary inference branches and all existing checker edits are preserved.

The exact patch and preimage hash are retained under
[selfhost/build/phase9/literals/inference-repair](../../selfhost/build/phase9/literals/inference-repair/).
Six source controls require the declared-constructor versus annotation category
and then compare the entire diagnostic/phase/trust record against the frozen
descent-only baseline: pinned 2n without Base, undeclared 0n/1n, custom Nat 0n/1n
with both constructors, and a custom Nat missing Succ. The
[inference control runner](../../selfhost/tests/phase9-literals/inference-controls.mjs)
and [case list](../../selfhost/build/phase9/literals/inference-repair/cases.json)
are ready for root's integrated03 build. No pass for that repair is claimed until
those actual observations complete.

Before this diagnostic repair, integrated02 accepts 1,000/1,001 positive fixtures
and refuses all 482 validation negatives, with no unexpected type acceptance or
remaining timeout. Long String is the one positive stack-overflow failure.
Strict checks are 1,005 pass / 493 fail; exact reference differences are 533 check
and 198 parse rows. These units include diagnostics and differ from semantic
acceptance/refusal counts. The integrated 40-row literal gate agrees semantically
on every row and matches candidate05's observations exactly: five pinned strict
negative failures plus six diagnostic differences in acceptance-oracle controls
produce 11 exact differences in total. None is a compiler-path or metadata delta.

### Final integrated03 outcome

Root's [integrated03 inference controls](../../selfhost/build/phase9/literals/inference-repair/integrated-03.json)
complete successfully: all twelve observations across six paired sources preserve
the precise error category and the complete baseline diagnostic/status/trust
record. The fresh [frontend03 comparison](../../selfhost/build/phase9/frontend-03/baseline-comparison.json)
contains exactly the four justified semantic improvements listed above; the
nat_literal_import diagnostic regression is restored to baseline. No other
baseline frontend observation changes. Positive acceptance is 1,000/1,001;
all 482 validation negatives refuse, with no unexpected type acceptance or timeout.
Strict checking remains 1,005 pass /493 fail, including the known exact-output gaps.

The final [40-row literal comparison](../../selfhost/build/phase9/integrated-literals-03/previous-comparison.json)
is identical to integrated02 and candidate05: every semantic observation agrees,
with 35 strict passes, five existing strict failures and 11 exact reference
text differences. The deep-pattern backend and long-String limitations remain
unchanged. This closes the literal owner's integration correctness recommendation;
controlled performance measurement, final release and evidence preservation stay
root-owned. No new compiler, test or archive jobs were run during the final timing
window for this read-only review.
