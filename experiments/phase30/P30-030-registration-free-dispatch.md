# P30-030 — Dispatch before any private registration

Owner: phase30_analysis. Status: scoped correctness and all prospective timing
criteria pass; selected for checked17 integration, release gates pending. Root requested this discriminator after the
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

**Observed correctness.** RLE and generated H have zero actual registration sites
under the Acorn use audit; H's two quoted emitter strings are excluded. Helper
and original Mandelbrot have3/5 registrations and receive only the general flag.
Exact inverse/suffix checks pass. RLE passes33 complete-state and22 host cases;
independent gates pass22 transitions,146 ABI+72 scalar and nine entry cases.
The manually derived H-flag also genuinely checks Base under its own API hash and
reproduces original H's small positive/negative observations and emitted bytes.
The [implementation report](../../implementation/phase30/registration-dispatch.md)
records identities, scope and all gate paths. No timing is inferred from them.

**Decision.** Clean five-sample RLE confirmation reduces16 time from.0485082
to.0458081ms (5.566%, disjoint ranges). The registered helper and15-second-warmup
original Mandelbrot controls have overlapping ranges, with−.003% and−.60%
median changes; the complete-state row improves5.378% with disjoint ranges.
All prospective thresholds pass. The direct-only diagnostic saves3.91% and is
not selected. RLE flag remains3.45% slower thanPhase29 in the same window.
Root selected only the three general-flag runtime edits for checked17. Actual
emission/gates/release remain separately required. The drifting short screen,
two metadata-plan failures,16 baseline and all raw observations remain retained;
no eager-arm restoration or runtime combination is selected. Full ranges, drift,
paths and decision scope are in the linked implementation report.
