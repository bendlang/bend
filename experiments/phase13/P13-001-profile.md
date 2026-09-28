# P13-001 — Profile the actual released Phase12 compiler

Prospective,2026-09-28. Root owns this diagnostic. Baseline isPhase12integrated-03,
selected API0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697.
No source/host/runtime change. Verify installed integrity first; profile complete
final source using unchanged phase9/profile-check.mjs, CPU0,10000us,Node24.18.0,
4MiBstack/4GiBheap. Other investigators initially read/prepare only. A launch,
semantic or input-identity failure invalidates attribution. Keep raw profile and
lexical/inclusive boundaries distinct; runtime/GC share is not a guessed gain.
Output `selfhost/build/phase13/current-profile-01`; no timing-ratio claim.
The [design](../../design/phase13/structured_rewriter.md) defines progression;
outcomes go in the [report](../../implementation/phase13/structured_rewriter.md).
