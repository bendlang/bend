# Phase30 amendment: guard a closed scalar loop once

Status: prospective, frozen before prototype derivation, controls or timing.
Owner: Phase30 analysis agent. Generated-JavaScript experiment only.

## Claim

The per-call guarded leading-lambda experiment may spend more on reflection than
it saves on generic dispatch. The same metadata proof can be amortized at a
closed, synchronous execution region whose internal operations cannot mutate
those bindings. Mandelbrot's existing `mit` successor callback is a small such
region. Test it before designing a broader compiler representation.

The candidate starts from the exact Phase29 module with SHA256
`11977282d5c364224eb3ac540fe3885345531d5819a68e5facfc72b03a836033`.
Its existing loop, U32 arithmetic expressions, BigInt Nat state, step ordering,
public descriptors, constructor representations and exports remain in place.
A private copy of the loop uses direct positional scalar helpers. The existing
loop is the fallback for every rejected entry. This is a disposable prototype,
not emitted output from an optimized compiler.

## Region and invariants

Enter only after the public Nat matcher and successor callback have consumed all
seven arguments. Preserve the original seven `a[i]` reads, in order, into the
existing local state slots before any new checks. Do not inspect the argument
array's length, prototype or properties a second time. This preserves even an
externally invoked callback's indexed getter transcript. Check the captured
values: one BigInt predecessor within the native Nat range and six integer Number
values in the U32 range. Any host object, Symbol, invalid number or out-of-range
value takes the unchanged fallback; no coercion hook runs in a successful region.

The complete reachable source-helper closure is exactly:

- `mit` calls `asr8` three times, `sel` twice and `b2u` twice per iteration;
- `asr8` calls `sel`;
- `sel` calls `sel.go`;
- `sel.go` and `b2u` select scalar values using native Boolean cases.

Verify all four live `G` entries are unchanged own data bindings. Verify each
captured ordinary descriptor's own `arity`, `code`, `env`, `bound` data fields,
original empty bound vector, ordinary object prototype and the absence of
`io`/`typeName` overrides. Verify ordinary code function prototype, absence of an
own `.call`, and unchanged inherited intrinsic `.call`, as established by the
separate callable-guard follow-up. Inspect descriptors without triggering getters.
A changed binding, Proxy replacement, code accessor, bound/env/arity edit or
call-hook mutation forces the whole original loop. No repeated region checks
occur during the successful loop.

Within the accepted region every operation is scalar and synchronous. There is
no foreign call, higher-order parameter, callback, record, array, String/Chr
projection, constructor build, mutable state operation or unknown global call.
The only host operations are the original primitive arithmetic expressions,
Math.imul and Number conversion for native shifts. Standard host intrinsics and primitive/Object/Array prototype behavior are
assumed (in particular, no added request/bounce/build getters on primitive
prototypes and no changed Array copying hooks); source programs cannot execute a JavaScript hook that mutates G during a
successful region. Native Boolean identities are bound by the exact checked
input image. No unguarded public helper is replaced.

## Transformation boundaries

Copy the original `for(;;)` body unchanged, including its immutable per-iteration
aliases, next-state temporaries, BigInt decrement and Zero-arm handling. Replace
only the seven generic calls in that copy by the direct private helper closure.
Copy `asr8`'s exact arithmetic body and substitute its direct scalar `sel` call.
Implement `sel.go` and `b2u` with the corresponding native Boolean branches;
`sel` retains its original `t === 0` condition. Require exact source shapes and
static site counts at derivation, and hash all input/output/plan/tool bytes.

Argument demand before region entry remains public runtime behavior. Returning
from a successful region must produce the same U32 value. Fall back before
performing any original loop computation if admission fails. The prototype may
increase emitted code size because the old body is retained; report that cost.

## Controls and measurements

Before timing, run the previous three-output grid and benchmark controls,
50,000-iteration witness, public partial descriptors and every mutation/error
transcript, including the new code.call counterexamples. Add runtime non-scalar
inputs and indexed argument getter observations; ensure failing admissions take
the original loop with the same result/error/effect order. Add mutations of each
reachable helper, not only asr8. Check an independent repeated-zero result oracle
and original size2 benchmark checksum. Preserve every failed attempt.

Use separate instrumented copies for runtime dispatch/descriptor/copied-slot
counts and region admission counts. Record named-site reductions, not an assumed
fraction of total allocation. The clean screen uses original `bench(0,0)` with
expected 2747870681; retain original size2 as correctness and later transfer.
Freeze concrete screen/confirmation configurations before clean execution,
coordinate exclusive CPU3 timing with the lead, and keep startup, first call,
warmup drift, clean execution and instrumented counts separate.

Compare upstream, unchanged Phase29, repaired per-call guarded lambda02 and this
region. Confirm a material region improvement under longer warmup before a
compiler implementation. A successful result would support a general closed,
first-order scalar-region analysis; it does not justify speculative unguarded
rewrites of arbitrary match/record/foreign code.
