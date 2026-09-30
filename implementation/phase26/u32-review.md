# Phase26: independent review of direct U32 decisions

**Source-review decision: no blocking semantic defect found for checked native U32 scalar inputs.** This is a bounded source review, not execution evidence or authorization to generalize to arbitrary host values. The reviewer did not implement the optimizer or run its checked-source correctness/timing campaign. The reviewer authored the separate exact compiler escape component and its upstream-only oracle pilot.

Reviewed [u32.bend](../../selfhost/src/back/js/u32.bend), the `j_l_def` integration in [emit.bend](../../selfhost/src/back/js/emit.bend), [literal decoding](../../selfhost/src/back/js/literals.bend), [runtime projection/application](../../selfhost/src/runtime.mjs), and the Phase26 source controls. The reviewed `j_u32_branches` failure rows are the explicit `None{} other` and `Some{x} None{}` forms. Compiler edits and promotion remain root-owned.

## Accepted domain and identity

`j_u32_worker` only recognizes a root `Mat("U32")`. `j_u32_worker_type` requires a live `All` argument, and both normalized argument and result types must be zero-argument `ADT("U32")` without U32 removed from its alternatives. This excludes leading captured arguments, multiple source columns, function-valued results and String-result helpers. It does not change the argument grouping rule or public function arity.

`j_u32_native_book` checks the native flag and definition kind of the U32 owner/constructor, Word.Nil/WNil, Word.Con/WCon, Bool/False/True, and the Word definition. Constructor lookup is inside each owning datatype's constructor list; spelling alone is insufficient. These checks rely on the existing checked-book provenance invariant: native flags identify authoritative Base declarations and constructors have passed ordinary declaration/layout validation. They are not a cryptographic proof against a caller fabricating arbitrary KDef objects with forged native flags. That lower-level adversarial raw-book interface is outside this review's compiler claim.

The source refusal controls cover user-defined/shadowed U32 at normal frontend boundaries. Because those programs can be refused before the optimizer executes, they do not independently demonstrate every native-flag guard. A cheap additional unit control would clear each required native flag in an otherwise eligible checked book and require `None`, without redefining the supported source semantics.

## Word interpretation and ordered branches

The runtime `word(n)` constructs a 32-bit little-endian logical word: its head is bit0 and its tail progresses toward bit31, ending in WNil. The new worker tests `((u >>> depth) & 1)` with the same index order.

At a word position, WCon is selected only below depth32; at depth32 it continues to that matcher's remainder. WNil selects its arm only at depth32 and otherwise continues to the remainder. At a Boolean position, `j_u32_bit_node` walks each ordered True/False matcher chain until the first matching arm and uses that arm's remaining word function. It does not sort rows or treat duplicate-looking cases as an unordered map. This preserves priority for the accepted tree grammar. Impossible native word shapes need not execute their arms.

The traversal rejects executable forms outside this grammar. In particular, an absurd/incomplete reachable arm, variable result, application, residual word reconstruction or generic function body cannot produce a successful recognized string. Both possible bit results must be `Some`; a failure on either reachable branch discards the entire replacement.

## Why ignored binders are safe in this restricted grammar

At a word-default `Lam`, the implementation accepts only `j_u32` decoding of its body. That decoder recognizes a closed compact U32 literal or a complete closed U32 constructor/Word/Bool literal tree. A Var, call, captured computation or literal tree containing a Var fails. Ignoring that default binder therefore cannot change the accepted result.

At a WCon arm whose next node is a `Lam`, the binder is the bit field. `j_u32_word_arm` skips it once and advances to the tail-word function. If its body subsequently needs the ignored bit in executable code, it introduces a form outside the accepted grammar or an open terminal literal, and recognition fails. A binder referenced only in erased annotation types does not contribute executable behavior.

This shortcut is also necessary for compilation cost: evaluating that same suffix once for false and once for true at every ignored bit could duplicate it exponentially before eventual string equality detects the duplicate. The direct Lam path avoids that duplication.

## Traversal and output bounds

`j_u32_bounded` walks at most8,192 executable term nodes before recognition, treating annotations as their value rather than traversing erased annotation types. It counts child occurrences; it is not graph memoization. Excess fuel fails closed. The decision walk descends input word positions at most32 times. For a real Boolean match, the false and true probes select disjoint arm outcomes or walk the ordered remainder; they do not both recurse into an ignored-bit Lam suffix because of the special path above. Sibling decisions remain limited by the accepted syntax tree.

These observations rule out the obvious ignored-bit exponential expansion in this implementation. They are not a general theorem that every part of checking/emission is bounded by8,192 operations: normalization, owner lookups, initial annotation stripping, strings and the fallback emitter have their own costs. A near-budget accepted tree and a just-over-budget refusal would be useful focused resource controls. No new large execution was requested for this review.

## Demand, ABI and fallback

The emitted replacement is still `fn(1, function(a) { ... })`. Zero, partial and overapplication stay under the existing generic runtime. The optimizer does not move later source argument expressions ahead of a matcher, evaluate unused branches, change tail cycles, inline arithmetic primitives or replace constructor forcing.

All accepted leaves are closed literal results, so there is no selected branch effect/call whose evaluation can be moved or dropped. Computing only the selected JS conditional arm has the same returned literal. Equal branch strings can collapse because neither branch contains work beyond numeric tests/literals; the input is still normalized before returning a collapsed constant.

On failure, `j_u32_global` preserves the prior deep-lifting versus ordinary-global decision. Recognition occurs before lifting, which allows a successful replacement to omit factories for the discarded tree. The successful global still goes through `j_l_global_worker`, retaining the registration path and any outer native-definition guard from `j_def`. The runtime itself is unchanged.

## Explicit host-domain limitation

The old runtime computes32 bitwise shifts on its input while constructing Word; the new worker coerces the input once with `a[0] >>> 0`. For actual JavaScript numeric U32 values this preserves the word bits. It also shares JavaScript unsigned coercion on ordinary primitive numeric out-of-range values, but that is not the primary language contract being established.

An arbitrary host object with effectful `valueOf`/`Symbol.toPrimitive` can distinguish one coercion from32, potentially even supplying inconsistent bits to the original runtime. Eliminating those repeated coercions is observably different for that adversarial input. Exported-library callers must supply valid native values for the advertised U32 parameter; this review does **not** claim arbitrary host object/proxy equivalence. If that broader contract is required, a `typeof`-guarded generic fallback would be necessary and would need its own cost/correctness test. The current design already limits the optimization to native scalar semantics.

## What this review does not establish

The correctness campaign must still show execution reaches optimized workers, compare dense/sparse/full-width/ordered cases against independent outputs, and retain fallback controls for used binders, captures, higher-order use and structural views. Static guard inspection cannot replace those observations. Full H speed, C/GPU behavior and a broad upstream runtime-conformance theorem remain outside this experiment.

The source census found no current actual compiler U32-result helper with this numeric-case shape. `j_escape_char_on` and `sk_char` return String; `nb_regs` and `nb_fork_close` return string lists. The extracted [compiler escape component](../../selfhost/tools/performance/phase26/compiler-escape.bend) is therefore a useful unsupported-result fallback witness, not evidence that this initial restriction speeds the complete compiler. Successful U32 microkernel timing should be reported as generated-program execution with its remaining loop/dispatch cost, never converted directly into a whole-compiler gain.

## Completed direct guard controls

After the source review, root authorized direct recognizer tests. [test-u32.mjs](../../selfhost/src/back/js/test-u32.mjs) passed **56 guard/recognition observations and780 scalar executions** on CPU6, Node24.18.0, 4MiB stack/1GiB heap. The report is `selfhost/build/phase26/guards-02/report.json`. The tested API is the Phase26 attempt01 equality derivative, SHA256 `4c67ac041c41d1e9ba5984ea29985a46ff7ee90963cb8eb820a7c82d91e7f664`.

The retained `guards-01` failure discovered that the ordinary library export surface does not expose `j_u32_worker`/`j_u32_bounded`. Attempt02 still loads the candidate through its snapshot `typed-driver`/`loadApi`, then uses an exact API copy with two append-only diagnostic exports wrapping the existing generated bodies through `run_loop`. Prefix equality and parent/copy hashes are asserted; no generated function body, compiler source or installed API is changed. These are recognizer-unit observations on the candidate's actual functions, not a new production export or checked-source acquisition.

The successful suite separately clears, removes or changes the kind of each required owner/constructor and of Word, requiring fallback. It also covers non-function/erased/wrong-domain/parameterized/removed input types; String, function and removed-U32 results; a wrong root, leading capture, variable/effectful/structural/non-U32 result; accepted annotation stripping and ignored bit/tail binders; rejection of an open reachable Boolean arm; and ordered duplicate Boolean arms choosing the first match.

Resource controls accept exactly8,192 independent nodes at fuel8,192 and reject8,193; zero-fuel boundary behavior is explicit. A 7,165-node decision-tree shape below the budget recognizes successfully, while the next deeper 14,333-node tree exceeds the budget and falls back. These synthetic terms exercise the recognizer's own guard; they are not claims that fabricated KDefs passed the frontend. Three produced workers run on all256 byte values plus four full-width boundaries: the constant result, low-byte extraction and first-arm priority match independent expected numbers on every point. Returned worker arity1 and an empty bound vector are asserted.

This closes the native-guard and budget unit-coverage suggestions above within the tested domain. The separate root-owned checked-source differential campaign supplies the normal compiler-pipeline evidence; the two forms of evidence should not be conflated.
