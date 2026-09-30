# Native U32 literal decisions: implementation boundary

This implements the first, restricted part of Phase25's numeric-pattern finding.
The checked source change is `selfhost/src/back/js/u32.bend`, selected from
`j_l_def` before deep matcher lifting. The old lowering remains the exact fallback
when recognition returns `None`. No runtime representation or calling ABI changes.
Build, correctness and measurement results belong in the phase report; this note
records the implementation reasoning and does not claim any tests have passed.

## Accepted checked programs

- The stripped global body begins with a `U32` matcher, and its normalized type is
  a live `U32 -> U32` function. Native U32 types have no arguments or removed U32
  constructor. Erased input and all other result types retain generic lowering.
- U32, Word.Nil, Word.Con and Bool are actual native ADTs in the book. Their named
  constructors must be native constructors found inside their owners. Word must
  be the native definition. Merely reusing the names does not qualify.
- The arm consists of ordered `WCon`/`WNil` and `True`/`False` matcher decisions,
  annotations and ignored lambdas. Every reachable leaf decodes as a closed U32
  literal using the existing literal recognizer. No calls, references, captured
  variables, rewriters or consumed residual Words are compiled by this worker.

`j_u32_word` tracks the current suffix length through a depth from 0 to 32.
Before depth 32, a Word has the native WCon shape; at depth 32 it has WNil shape.
`j_u32_bit` evaluates the ordered Boolean matcher for a known bit value. A failed
constructor decision follows its miss subtree without consuming the pending
argument, exactly as the generic matcher does. A successful constructor decision
advances to its fields. Impossible arms are not emitted.

An ignored Word binder can only return a closed literal. An ignored Bool binder
can continue the Word walk, which still admits no executable references to that
binder. It is skipped once before Boolean branch splitting. This avoids doubling
the suffix walk for each ignored bit. Both branches must succeed explicitly;
`Maybe` prevents an empty string from masquerading as successful code generation.
Equal literal/decision strings can share the single resulting expression.

The executable tree is first limited to 8192 visited nodes, counting repeated
edges separately and following only the body of annotations. The preflight itself
uses a work list and decreasing fuel. It runs only after the cheap matcher-head,
function-type and native-identity gates. Unsupported or oversized functions retain
the established lowering. The Word depth is separately bounded by 32.

## Emission and semantics

A success emits `fn(1,function(a){const u=a[0]>>>0;return ...;})`. Decisions are
unsigned low-bit tests; results are the existing unsigned literal spelling. The
`fn`, application, forcing, export and wrapper ABI remain unchanged. Selecting the
worker before `j_l_mark`/`j_l_walk` is necessary: replacing only `j_match` would
retain hundreds of now-unused lifted matcher functions.

Correctness is scoped to checked native U32 scalar inputs. The conversion executes
even when all branches collapse to one constant, preserving consumption of the
scrutinee. Raw JS callers can pass invalid host objects; the generic `word` loop
can invoke an object's coercion repeatedly while this worker invokes it once.
This phase must not claim preservation for such adversarial non-U32 inputs or
invent a stronger host-validation contract than the existing library provides.

## Relation to upstream and transfer limits

Pinned upstream `bend2/comp.ts` has broader `mat_lits`/`mat_rows` machinery: it
collects literal rows, preserves residual fields and sometimes chooses a dense
table. This first worker instead walks the existing decision tree, using no new
IR, substitution or residual-Word representation. It removes representation and
generic matcher allocation without adopting every upstream optimization.

The initial U32-return restriction deliberately excludes the actual compiler's
String/List-returning numeric helpers, including `j_escape_char_on`. Improvements
to table/wide numeric microkernels are emitted-program findings, not evidence of
faster self-compilation. Wider result expressions, argument raising, primitive
inlining and tail loops remain separate hypotheses with separate semantic gates.

Useful falsification controls include unsigned high-bit values and neighbors;
ordered defaults and ignored-bit/residual binders; same-name non-native ADTs;
missing or replaced native owners/constructors; captured and nonliteral results;
erased parameters; actual String-returning compiler helpers; and oversized trees.
The independent reviewer and parent integration run own these checks.
