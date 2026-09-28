# Phase13 independent branch-capture review

Status: the actual shared v5 implementation passes independent controls. The
first actual lifter has four retained semantic guard failures and one
unsupported-shape acceptance; the corrected helper passes 17 controls. Root's
separate measurement rejects plain lifting as a speed optimization. The smaller
selector pilot passes 30 paired observations and 23 refusal controls, and all
nine surviving real normalizer arrows are byte-identical to their originals.
The [prospective controls](../../experiments/phase13/P13-003-controls.md) precede
any execution. The implementation owner's proposed syntax is reviewed below;
these are bounded controls, not a general compiler-equivalence conclusion.

The current runtime matters: `run_tail(f, x)` constructs a unary jump, and
`run_loop` later invokes `f(...x)`. A literal arrow is therefore not necessarily
executed when its capture environment would be constructed by the rewrite.
Retaining that boundary avoids one source of recursive stack growth, but does
not establish identical stack behavior after V8 compiles a different function.
Phase12 demonstrated this even for a one-expression source cleanup.

## Required capture domain

Eligible captures should be initialized, unwritten lexical bindings. Copy their
values into the proposed packet; keep all calls, member reads and calculations
in the selected worker body. This preserves object identity and delays getters
and errors to the original branch demand point. An immutable binding may still
refer to a mutable object: capture the object reference, not its current fields.

Function parameters are writable JavaScript bindings. The generated SCC loop in
`$index_find$` rewrites `$0` through `$4`; its `const` aliases are distinct bindings
and may be eligible where direct state-parameter captures are not. Conversely,
`const` alone does not prove that initialization precedes capture construction.

Scope resolution must be binding-based, including nested arrows and block-local
declarations. A spelling-based free-name set is insufficient: a name can refer to
an outer parameter in one subtree and an inner parameter in another. Property
keys and `.field` names are not lexical references, while computed property
expressions are. Captures used only by a nested returned arrow are still free
requirements of the outer worker.

## Distinguishing examples

These examples were written before probes; the observed convention-control
results are recorded below. `Unit` means a newly constructed `{$: "Unit"}` and
`run_tail` has the current runtime's behavior.

A deferred closure can read a `const` after its initializer, even though the
initializer occurs after creation of the jump. Eager capture would read the
binding in its temporal dead zone:

```js
function delayedConst() {
  const jump = run_tail((unit) => x, {$: "Unit"});
  const x = 17;
  return jump;
}
```

A parameter can change before the branch is forced. Copying its value at jump
construction would return the earlier value:

```js
function delayedWrite(x) {
  const jump = run_tail((unit) => x, {$: "Unit"});
  x = 2;
  return jump;
}
```

A capture packet containing `record.value` would invoke the getter earlier than
the original branch. The safe candidate, if its other guards hold, captures only
`record` and leaves `.value` in the worker:

```js
function delayedField(record) {
  return run_tail((unit) => record.value, {$: "Unit"});
}
```

An inner binding cannot remove a sibling's free reference, and a returned arrow
keeps the worker's captured environment alive:

```js
function nested(x) {
  return run_tail((unit) => {
    const local = (x) => x;
    return (y) => local(y) + x;
  }, {$: "Unit"});
}
```

Reject writes through any captured binding, including destructuring, increments
and writes in a nested closure. A variable initialized by a destructuring getter
is safe to capture only after that original initialization has happened; moving
the initializer into a packet would be a separate transformation. Refuse unknown
syntax rather than guessing its scope or effect.

## Call, ABI and provenance requirements

The condition must run once before packet construction, and only the selected
branch packet should be constructed. Keep the original Unit value available to
its parameter, including when the body returns it or closes over it. Do not
replace any existing `run_loop` forcing point, currying wrapper, partial/public
application or error boundary. Worker functions stay private.

The implementation owner proposes using the existing multiargument jump format
directly, avoiding a new unary packet adapter:

```js
return condition
  ? {$: "$JMP", f: $workerYes$, x: [{$: "Unit"}, captureA, captureB]}
  : {$: "$JMP", f: $workerNo$, x: [{$: "Unit"}, captureC]};
```

Each named worker receives Unit followed by its captures, and contains the
original branch body with its original terminal and nonterminal calls. This
matches the unchanged runtime's existing `f(...x)` dispatch; current v5 already
uses that format for other deferred generated calls. There is no requirement to
call the unary `run_tail` with multiple arguments or to add a runtime protocol.
Condition evaluation precedes the selected array, with Unit first and captured
identifier reads afterward. This shape has no static blocker under the capture
domain above; correct binding analysis and emitted bytes remain to be reviewed.

Bypassing `run_tail` also bypasses its `f.j` inspection. Here that is justified
only for the original fresh literal arrows and the existing unmodified-host
contract. New named workers must not escape to `run_clo`, acquire `.j` mutations,
or collide with any source binding/reference. Their additional formal parameters
can change frame size and V8 behavior even when the trampoline remains intact.

Named worker sharing changes function identity and the private jump payload.
The current v5 scope already does not promise private unforced tail-message
representation, but that is not permission to expose changed raw messages through
public compiler results. Required controls cover forced observations and raw
jumps flowing through the original trampoline. Monkeypatched built-ins and
arbitrary reflective hosts remain outside the existing derivative contract.

New worker names must be reserved against every relevant binding, not just the
top-level function list. Reject lexical `this`, `arguments`, `new.target`,
`super`, dynamic evaluation and unsupported control forms; ordinary top-level
functions do not inherit the lexical environment of an arrow. Preserve the exact
runtime and public export/marshalling guards. If a maintained v6 is later adopted,
explicit versions 1–5 must reproduce their original bytes and metadata.

## Phase12 evidence required by this review

The normalizer seed cleanup is rejected, and broad returned-branch inlining also
fails after restoring the original seed. The released leaf derivative passes
the exact 53- and 60-request histories. The independent controls must use those
same histories with exact predecessor digests and a 4 MiB stack; a fresh-process
long-string pass alone is insufficient. A history where both baseline and
candidate fail cannot excuse a different history where baseline succeeds.

The new profile may rank the opportunity, but sample shares do not prove a count
of closure allocations or an attainable speedup. This review makes no speed,
allocation, conformance or universal-equivalence claim. The proposed worker shape
has been reviewed statically; next is inspecting the actual capture analysis and
running the frozen controls after root releases a CPU slot. The earlier static
report and prospective bytes are preserved in
`selfhost/build/phase13/control-static-01/`.

## Independent convention controls

`selfhost/build/phase13/control-packets-01/report.json` passes 23 positive
comparisons using handwritten original/worker bodies and the exact runtime
prefix from the verified Phase12 API. The original body is an arrow passed to
the existing trampoline; the counterpart uses the proposed named worker and
capture argument vector. This validates selected aspects of that calling
convention, **not the implementation owner's parser or rewriting algorithm**.
The harness is not a compiler bootstrap or production source change.

Controls cover condition truthiness and effects, selected exceptions, a condition
exception, partial/extra public arguments, returned functions and raw jumps,
getters left in the demanded body, same-object aliases, nested shadowing and
escaped closures, fresh Unit values, zero/multiple captures and 100,000 tail
steps. Each original/transformed observation compares directly; identities and
complete generated toy modules are retained. Explicit encoding preserves
`undefined` in the saved reports. No compiler throughput or allocation count was
measured.

Five deliberately unsafe rewrites exhibit the planned counterexamples:

| Unsupported shape | Original result | Eager explicit-capture result |
| --- | --- | --- |
| Captured `const` initialized after jump creation | `17` | TDZ `ReferenceError` |
| Captured parameter changed before demand | `2` | `7` |
| Captured parameter changed by nested closure | `2` | `7` |
| Lexical `this` in an arrow | `9` | `undefined` |
| Lexical `arguments` in an arrow | `7` | Unit object |

The required disposition is refusal or leaving those sites unchanged. These
negative results are successful witnesses, not implementation-owner regressions.
The tool and per-run plan were frozen before execution. The CPU2 launch used
4 MiB stack / 4 GiB heap, exited successfully and verified its inputs; the exact
command/logs are retained alongside the run. No child remains active. Next is
reviewing the actual rewriter interface and testing its guards against these
witnesses and nested-scope mutations.

## Actual shared-v5 review and controls

The implementation owner's `rewriter-structure.mjs` factors delimiter/token
ranges, argument splitting, arrow/returned-choice recognition, leaf recognition,
rendering and protected-binding checks. `rewriter-v5.mjs` reuses the frozen
maintained scalar-equality guard and these views. Static review finds no mismatch
in the choice/leaf predicates or exclusive endpoint conversion. The owner's
`rewriter-stage1-01` checks output bytes and exact JSON statistics against authentic
versions 1–5, not merely two fresh implementations' expectations.

Independent `control-stage1-01` freezes the actual helper files in their relative
module layout before testing. It passes 30 mutations: 12 accepted inputs have
exact old/new output bytes and statistics, and 18 refusal inputs agree in
acceptance status. Refusal diagnostic wording is retained but not required to be
identical. Nested choices, arrow parentheses, declarations that prevent leaf
lowering, dynamic thunks, quoted delimiters, nested scopes, zero-arity calls and
nested commas exercise range handling. Mutations of protected parameters,
destructuring, writes, member calls, runtime/body identities and unsupported
syntax exercise guards. Four structural groups check unchanged rendering,
top-level source spans, unknown option keys and invalid versions.

The shared view is **not a full JavaScript parser or lexical scope analysis**.
Its existing protected-name guard cannot establish initialization and capture
safety for a new transformation. Historical output replay does not discharge
those new obligations.

## First actual lifter: retained counterexamples

`control-lift-01` freezes and tests the implementation owner's actual
`rewriter-lift.mjs` (SHA256
`3941690594f80f811819e6905f8cbb4242d85665483ebf3ae80ea5c6552864cb`).
It first reproduces the proposed compiler image exactly:
`d74ecdbd243bb1bafe4ed726b1b697ccb3b942ca39a0b7a8dfe27e5ff5581554`,
with seven choices, 14 named workers and 63 static capture arguments. These
counts are not runtime allocations or a performance measurement.

The initial owner domain is deliberately smaller than the prospective maximum:
parameters and nested single-parameter block arrows only; all declarations and
writes should be refused. Four actual-transform positive cases pass: readonly
parameters, transitive nested captures, shadowed block-arrow parameters and
computed-property captures. Ordinary assignment and later `const` are refused
by the lifter; lexical `arguments` is refused by its prerequisite v5 guard.

However, the complete 12-case control report is **failed**. Four accepted inputs
have different behavior after the actual transformation:

| Accepted input | v5 baseline | Lifted result | Cause visible in the resolver |
| --- | --- | --- | --- |
| Parameter named `undefined` | `17` | `undefined` | Keyword filtering precedes lexical binding resolution |
| Captured `x <<= 1` after saving an arrow reading `x` | Return 14; saved arrow reads 14 | Return 14; saved arrow reads 7 | Shift assignment bypasses write guard; worker mutates a copied binding |
| Captured `x >>= 1` | Return 4; saved arrow reads 4 | Return 4; saved arrow reads 8 | Same missed compound write |
| Captured `x >>>= 1` | Return 2147483647; saved arrow reads 2147483647 | Return 2147483647; saved arrow reads -1 | Same missed compound write |

An unparenthesized nested arrow is also accepted despite the stated syntax
boundary. That witness returns the same value; it demonstrates a domain/analysis
gap, not an observed value mismatch. All inputs, original/transformed modules,
capture lists, helper copies and nonzero launch status remain in the failed run.
These mutations do not occur in the selected current `norm_eval_node` body, so
they do not by themselves demonstrate a bad result in image `d74ecdbd…`; they do
block a claim that the general admitted-owner guard is sound.

The first helper, candidate and failed observations remain unchanged. The
corrected helper is tested separately below.

## Corrected lifter and decision

`control-lift-02/report.json` passes all 17 controls using the actual fresh
`rewriter-lift-v2.mjs`, SHA256
`5d88b4e22cc7e65174c66ad58b3d3f4af62fa5841eb49b5bf41d99e5ce40720e`.
The original 12 cases are repeated; `undefined` now resolves to its lexical
parameter and the three shift writes and unsupported bare arrow are refused.
Five additional cases cover member names, quoted object keys, generated tag
keys and protected runtime/generated-function parameter shadows. The latter
shadows are rejected by the v5 prerequisite rather than by capture lowering.
The existing seven-site compiler candidate is reproduced exactly as `d74ecdbd…`.

Root's subsequent controlled ABBA screen found plain lifting approximately
1.01% slower. That is root-owned timing evidence, not a result of these controls.
The appropriate decision is to retain the structural/counterexample evidence
and reject plain lifting as a speed optimization. Correcting its guard does not
make its extra workers and capture arrays worthwhile.

## Actual selector pilot

The separate [selector plan](../../experiments/phase13/P13-005-selector-fusion.md)
removes false-branch arrows whose only work is another returned choice. It
requires an unused discarded Unit binding and an admitted nested parameter tag
test. It preserves the selected body arrow and existing runtime boundary,
introduces no workers or capture protocol, and does not revive the rejected
normalizer seed change.

Independent static review verifies the selected-owner restrictions: parameters
and single-parameter block arrows, no declarations, writes or owner-parameter
shadowing; exact tag/equality helper bodies and protected dependencies; exact
runtime and public exports. Conditions still execute left to right. Their
execution moves from a later trampoline iteration into the current producer
frame. A tag getter or represented-string fallback can throw, so this is not a
claim that all raw-host tag tests are total or that stack behavior is identical.

Root's first selector preparation failed before emitting a candidate because a
redundant post-v5 global guard rejected legitimate existing leaf jump function
references. Root retained that failure in `selector-norm-eval-01`; this reviewer
did not independently reproduce it. The corrected selector02 relies on v5's
original-binding validation and guards the actual selector dependencies after
that transform.

`control-selector-01/report.json` freezes and tests actual selector helper
SHA256 `010de17cc7be6391dc9c5df12e61e8b7f7a934cc0e57f264b569e94abb7d1287`.
It first rederives the actual selector02 API exactly:
`5a1a9449ec9a190e1bee0b695d211fd83e5672a6e1fc87623c3e3826268d4441`,
with five removed intermediate selectors. It then inserts a synthetic generated
owner into the genuine checked source and compares actual v5 versus actual
selector transformations. Private test exports are appended only afterward;
this is not an additional checked B1 artifact.

All **30 paired observations** match, including native and boxed tag strings,
empty strings, getters with stable/changing values, getter failures at each
condition, malformed raw tags and fallback failure, selected body errors,
returned functions and jumps, fresh Unit identity and partial/extra public
arguments. Malformed/raw host probes are explicit boundary evidence rather than
an expansion of the ordinary compiler-term domain. Exact saved observations
include both effects and error name/message; `undefined` has an explicit JSON
encoding. Four synthetic selected bodies remain byte-identical while two
intermediate arrows disappear.

All **23 guard controls** refuse the requested rewrite. Eighteen reach the
selector after passing v5; five fail the prerequisite. They include direct and
nested uses of the discarded Unit, owner shadowing, declarations, assignment,
all three shift assignments, increment, non-tag/non-parameter/projected/forced
conditions, a bare arrow, helper/runtime mutations, protected names, unknown
owners, duplicate owners and unknown options. This establishes refusal of the
tested witnesses, not a complete JavaScript scope proof.

## Actual branch-byte supplement and its setup failure

The first supplementary check, `control-selector-bodies-01`, is retained as
**failed**. It mistakenly selected the parent's raw checked `api.mjs` instead of
the released v5 `equality/api.mjs`. It therefore detected a preexisting v5
rewrite inside the Rwt body. That is a harness baseline error, not evidence of a
new selector body change. Its consumed script, observations and exit status 1
remain intact.

The new tool and run `control-selector-bodies-02` select and verify the exact
`baselineApi` and `api` identities from selector02's frozen manifest. The
released baseline has 14 block arrows in `norm_eval_node`; selector02 has nine.
**Every surviving complete arrow source string is byte-identical to a distinct
original range.** Five intermediate selectors are removed. The report records
all ranges, hashes and full arrow text; the inner Rfl branch bodies and the Rwt
body containing them are preserved relative to the correct v5 baseline.

These synthetic/static controls ran on CPU2, without an explicit Node stack
flag. They do not substitute for the separate fresh/53/60-request compiler
history gates at 4 MiB, nor measure throughput or allocation counts. All owned
jobs are closed. Root owns those history gates, any controlled performance
comparison and the eventual promotion decision. No live compiler source,
maintained helper, runtime, upstream snapshot or installed artifact was changed
by this reviewer. The frozen prospective P13-003 plan remains unchanged; all
failed and corrected attempts are retained separately.
