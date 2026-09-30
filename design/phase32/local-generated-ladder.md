# Saved-output local-data ladder

Start from the installed checked07 compiler at fork commit `5f3015d`. This is a
generated-JavaScript experiment, not a production compiler edit. Preserve the
exact checked07 pair and independent fold sources, emitted modules and receipts
from Phase31. Read the experiment workflow, ledger and steering before work.

## Hypotheses and order

1. Return-position private field-unpacking arrows can become ordered local
   declarations without a new data representation. The narrower control flow
   may improve generated-code optimization; V8 may already eliminate the arrow.
   Only this transformation changes in the first derivative.
2. A canonical native Array.get result passed immediately as the last argument
   to a completely unpacking private consumer need not allocate a two-slot
   result tuple. A private bridge can preserve earlier argument evaluations,
   evaluate the handle and index once, perform the read at the original producer
   point, then call a specialized consumer with the handle and captured scalar.
   This is a separate derivative of07; test their combination only afterward.
3. Record-state scalarization is deferred until the first two results identify
   remaining cost. It requires its own prospective proof and ablation; fewer
   objects in source alone does not justify it.

## Exact transformation boundaries

Use the Node24.18 embedded Acorn8.16 parser and retain its identity. Restrict
changes to compiler-generated private functions with `$R_` encoded names and
their lexically bound calls inside the existing private-root closures. Public
generic function bodies, root admission conditions, runtime helpers and exports
remain unchanged, except for the same existing benchmark wrapper.

Statement lowering selects a private ReturnStatement whose expression is an
immediate arrow call, with identifier parameters and consecutive indexed reads
from one known input's tuple or `.a` vector. Capture that input in an outer fresh
block; introduce ordered field bindings in a nested block before the arm. This
keeps original input names outside the new binding scope. Reject zero-rebinding
arrows, arbitrary argument expressions and nonexpression arms. Preserve each
original edit and demonstrate exact inverse reconstruction of the original
module. Unpack arrows nested only in expression positions remain unchanged.

Tuple fusion selects a private consumer whose entire body is one return of
canonical two-field unpacking of its final parameter, used only by those two
field reads. Retain the ordinary private consumer. Add a uniquely named private
clone with the two fields replacing that last parameter, and a bridge whose
arguments are the preceding ordinary arguments followed by native handle/index.
The bridge reads using the original `arraydata`, `Number(index)`, modulo and
indexed lookup semantics, preserving handle identity and read value before the
consumer can mutate any alias. Do not remove an unused read or delay it until
the scalar is used. Exact eligible call sites must contain the actual compiler's
canonical erased-null Array.get native wrapper and a fully saturated consumer.
Reject unknown producers/consumers and retain all public entry safety. Generated
names must be absent from the input. Record each site and its original bytes.

For these saved-output prototypes, canonical provenance comes from the fixed
checked07 typed output and exact native-wrapper shape. A production compiler
rule must additionally use checked Sigma/native identity and the typed local
region proof; JavaScript spelling is not a general compiler admission rule.

## Cheap falsification and independent controls

First inventory eligible sites and inverse diffs. Then run focused JavaScript
order witnesses: earlier argument mutation before the read, handle/index
evaluation once, consumer mutation before using the captured value, aliasing,
wraparound, unused result fields and repeated reads separated by a write. A
producer that defers its read until consumer use must fail a retained negative
witness. Unknown producer and noncanonical consumer shapes must stay unchanged.

Run the unchanged fold's 40 BigInt oracle points and its delayed-first-field
negative witnesses. Check n4096/seed17 separately. Run six complete pair values,
the full physical array oracle and the exact328,966 allocation/read/write event
schedule, plus public mutation/raw/forged/constructed/saved-partial controls.
Where fusion replaces `arrayget`, instrument the actual scalar lookup as one
logical read with the same handle/index/value; do not report zero reads. Keep
tuple allocations distinct from logical storage events. Root independently
reviews semantic scope before production implementation.

## Frozen measurement policy

No timed comparison without the root's exclusive CPU3 grant. Correctness
acquisitions may run in the assigned CPU slot; their duration is not throughput.
After controls pass, freeze identities for checked07, statement-only,
fusion-only, combined if admitted, and the pinned TypeScript reference. Use the
same full pair p0 and independent fold n4096/seed17. A short screen selects
surviving directions; five fresh rotating samples, three seconds of warmup and
a300ms target confirm material gains. Do not compare these medians to older
windows or infer an original-program or compiler-throughput gain.

A speed recommendation requires at least5% less time with disjoint sample
ranges on one fixture and no greater than3% disjoint slowdown on the other;
smaller/overlapping results are neutral unless a documented code simplification
has its own value. Inspect half-sample drift; unresolved warming requires a
declared longer confirmation rather than presenting steady-state claims.
Generated bytes and transformation/worker counts accompany runtime numbers.

Maintain tools under `selfhost/tools/performance/phase32/local-*`, raw attempts
under `selfhost/build/phase32/local-*`, and outcomes in
`implementation/phase32/local-*`. Preserve every failed preparation and all
Phase31 originals. Keep acquisition output bounded because disk space is tight.
Root owns production source, integration, commits and pushes; no PR comments.
