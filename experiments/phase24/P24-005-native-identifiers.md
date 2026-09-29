# P24-005 — Injective native function identifiers using the existing encoding

- Owner: backend agent; reviewer: coordinating agent.
- Frozen before source edits, 2026-09-29. Bound: two emitter expressions and focused controls.
- Correctness: counterexample on installed Phase23; candidate unchecked.
- Measurement: no performance claim. Decision: investigate.

The fresh native pilot rejects the valid upstream `import/js_names_apart.bend` because punctuation folding creates `FID_HAS_HYPHEN_LIB_TWO` twice; the pinned compiler executes it and prints 22. Full evidence is retained in `selfhost/build/phase24/backend-pilot-07`.

Replace only `nt_fid`'s uppercase punctuation folding with `FID_` plus the already-used `nc_ctor_codes` scalar sequence. Decimal scalars separated by underscores are injective, preserve case and Unicode, and cannot equal alphabetic reserved runtime FIDs. Reuse this encoding rather than add upstream's stateful suffix allocator. Update `MAIN_FID` to call the same helper; preserve fixed runtime FIDs and all constructor IDs. Foreign C symbolic `FID(name)` continues through the common mapper. Existing direct literal FID contracts will be inspected before editing.

Falsify with differing names receiving the same identifier, changed FID references/arity tables, runtime reserved-ID collisions, foreign FID translation failures, or changed execution. Retest the original import, dot/underscore/case and reserved-looking function names, plus the complete 81-row pilot. Preserve the old native unit fixture which incorrectly required this rejection, then replace it with a positive execution control. Unicode identifier parsing is tested only if the language accepts the source; the encoding itself is checked directly where exposed.

Use the same checked combined candidate/harness/resource/CPU policy as [P24-003](P24-003-effect-collision.md); no runtime or TypeScript edits. Every failure remains evidence. Source size/identifier length is reported as a tradeoff; there is no generated-code performance claim. Outcomes belong in [backend census](../../implementation/phase24/backend-census.md), not a rewritten prospective record.
