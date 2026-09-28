# P9-001 — Guarded native string equality in the current checked compiler

- Owner: staging/IR agent; independent reviewer and integration owner: root.
- Started/evidence cutoff: 2026-09-28, before implementation or new experiments.
- Initial timebox: 30 minutes for implementation and boundary controls, then a
  separately scheduled compiler comparison if those controls pass.
- Objective: shorten checking and the iteration loop without changing language
  semantics or claiming a new bootstrap/fixed point.
- Correctness: not yet tested on this upstream version.
- Measurement: not yet run; Phase8's current full-source checking result is the
  baseline context, not evidence for this candidate.
- Decision: investigate. Production/default installation is outside this task.
- Report: [implementation/phase9/native-equality.md](../../implementation/phase9/native-equality.md).

## Claim and cheapest disproof

**Hypothesis:** replacing the current generated `String.eq` call on two
well-formed primitive JavaScript strings with host equality avoids recursive
comparison, tuple allocation and reconstruction, reducing real compiler checking
cost. The unchanged source still calls `String.cmp`, so the opportunity is visible
in actual checked B1 bytes. A helper microbenchmark alone cannot establish a
compiler speedup.

**Invariant:** primitive, well-formed strings have equal Unicode scalar sequences
exactly when their JavaScript string values are equal. Both string type checks
and well-formedness checks precede the fast path. Every other input takes the
original helper body, preserving its demand and error behavior under standard,
unmodified JavaScript built-ins. Resource exhaustion and reflective/monkeypatched
host equivalence are outside this derivative's claim.

The new emitter's helper arguments, direct calls and public marshalling wrappers
differ from the old pin. In particular, current string decomposition no longer
calls `char_new`; do not import old malformed-UTF-16 error expectations. Keep the
old and new helper/runtime/upstream/recipe hashes separate, and preserve exact
historical transformation statistics and bytes for legacy release replay.

**Cheapest disproof:** compare original and transformed helpers over Unicode,
astral characters, combining sequences, lone surrogates, malformed suffixes,
non-string values and observable fallback objects. Any changed result, demanded
error, call order or public argument behavior blocks promotion. Any accepted
modified helper/runtime/body/provenance witness is also a failure.

**Stop conditions:** unreviewed emitted syntax, inability to preserve historical
replay, any semantic mismatch, or no meaningful real compiler gain in a controlled
comparison. An isolated successful transformation is not a promotion decision.

**Alternatives:** profile conversion/context lookup/allocation if this small
change fails to improve the checker. Generic evaluator/binder rewrites remain
unpromoted; no source rewrite or broad unchecked intrinsic is needed here.

## Controlled setup

- Baseline: genuine Phase8 checked B1, API SHA256
  `e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4`,
  upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`.
- Parent source SHA256:
  `0f5425ac8a2298f444b0907632088b406da61420407331e80708d9fea6a47822`.
- Canonical Base SHA256:
  `00c751b6cd045361a80f214c9c36bd4ec637e9ec86109b194e55cd57ca63ab94`.
- The candidate is a separately recorded derivative of that checked API. It must
  retain `newBootstrap:false` and must not fabricate bootstrap provenance.
- Maintained implementation: `selfhost/tools/development/equality.mjs` and its
  tests. Experiment controls and frozen recipes live under
  `selfhost/tools/performance/phase9/equality-*`; raw attempts use fresh numbered
  directories under `selfhost/build/phase9/`.
- Capture original/candidate API, bootstrap report, source, Base, host, runtime,
  transform, test harness and Node identities before and after runs. Pin all
  inputs before timing and preserve setup failures as separate attempts.
- Node 24.18.0 by absolute path. CPU2 for isolated correctness work; timed runs
  require a coordinated exclusive window. Keep stack/heap/deadline settings equal
  across variants and record process/request boundaries and peak RSS.
- Use serial fresh-process ABBA comparisons after boundary and compiler controls.
  Record all samples, including failures. Separate short workload results from
  full-source checking and from emitted-program execution; do not reuse the old
  full-compilation ratio as a new result.

## Gates planned before measurement

1. Exact runtime/body/dependency hashes, one insertion, unsupported syntax and
   rebinding/shadowing refusals; changed API/Base/source/recipe/provenance refusal.
2. Unicode and fallback observations, partial application, extra arguments,
   public marshalling behavior and input immutability where applicable.
3. Actual old-pin transformation replay and historical release verification.
4. Current genuine derivative creation and replay, retained failed attempts,
   representative accepted/rejected compiler inputs, exact verdict/phase/checked/
   diagnostic observations, and actual emitted JS execution.
5. Independent source review, then controlled compiler timing. A full current
   conformance vector and any release promotion are separate root-owned gates.

## Preservation and outcomes

This prospective plan is frozen before implementation. Outcomes, all raw attempt
identities, compiler controls, measurements, independent review and the final
promotion decision belong in the linked implementation report. Keep every
rejected guard/ABI/semantic attempt visible. Large artifacts must be archived
with their exact sources and prerequisites before the phase closes; an ignored
path or checksum by itself is not durable evidence.
