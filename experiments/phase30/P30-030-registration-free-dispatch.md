# P30-030 — Dispatch before any private registration

Owner: phase30_analysis. Status: prospective design only; no derived candidate,
control execution or timing yet. Root requested this discriminator after the
complete final16 RLE point remained10.30% slower than Phase29 with disjoint ranges.

**Hypothesis.** The module has no private-worker registration, yet every generic
exact application consults an empty private WeakSet. Removing only that predicate
may account for some of the residual cost. Retired selected-arm prebinding and
owned non-tail vectors are separate mechanisms; do not combine them here.

**Invariant.** Keep exact descriptor/code/method/environment read order, current
public matcher scheduling, callback shape, reentry and permission restoration.
The standard-intrinsic boundary is explicit. No public descriptor immutability
or first-use snapshot assumption is introduced.

**Variants.** The [frozen design](../../design/phase30/registration-free-exact-dispatch.md)
specifies unchanged16, a module-proved registration-free direct generic helper,
and a general monotone flag that bypasses WeakSet.has only before the first
successful registration. Registered helper and Mandelbrot modules are required
negative controls for the general rule; the direct generic diagnostic cannot be
used on them. Source/AST audit, inverse derivation and mutation/reentry/transition
controls precede any timing grant.

**Reference evidence.** The [static report](../../implementation/phase30/rle-runtime-regression.md)
identifies exact source/emission receipts, the single definition-time bu snapshot,
absence of emitted guards/registrations, and five algorithm arm sites plus one
untimed U32.show site changed by the earlier retirement. These are static findings,
not dynamic counts or causal attribution. All final16 measurements stay intact.

**Decision.** Pending bounded correctness acquisition and separately granted clean
timing. No production integration, baseline rewriting, eager-arm restoration or
runtime combination is authorized by this record.
