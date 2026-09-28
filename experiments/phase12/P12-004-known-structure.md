# P12-004 — Reuse the JS constructor literal decision

Owner: known-structure investigator. Baseline Phase11 `f8244c9`, selected API
`63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f`, immutable
`selfhost/build/phase11/integrated-01`; upstream stays `b2111cf`.
This prospective record precedes probes. Initially static work only while root
profiles CPU0; root must release a CPU before any compiler experiment.
Outcome belongs in [known_structure.md](../../implementation/phase12/known_structure.md).

## Ranked hypotheses

1. `j_constructor_mode` runs `j_literal_typed` in an eager Boolean conjunction,
   then its non-build branch repeats that exact call through `j_constructor`.
   Share the first result with the existing `j_constructor_literal` helper.
   This is local immutable result reuse, not a new literal representation or
   an unchecked annotation shortcut. The initial recognition still precedes
   selecting either branch, preserving its demand and errors. The now-unused
   one-call wrapper may be removed if source/export inspection confirms it is
   private. Expected benefit: halve recognition at that call site for closed
   literals and non-tail constructors; no whole-compiler percentage predicted.
   Expected complexity: one binding and removing a private wrapper, no new tags,
   helper, cache, declaration certificate or public API.
2. P6-005's isolated five-line retention of already compacted `NWord` arguments
   removes wide-record native continuation growth. The archive has checked
   source and actual native gates, but it was never integrated. This is a known
   unpromoted candidate, not a new discovery or rejected semantic-value trial.
   Rebase only if root prioritizes that remaining workload; keep its attribution
   separate from JS recognition reuse.

## Archive and upstream constraints

Pinned `comp.ts` reads a constructor's ADT/scalar result once in `js_expr`.
Pinned `bend.ts` retains compact String/U32/F32 Lit nodes, while this port still
expands those trees. That larger representation difference is real but not yet
profile-justified for this bounded task. P6-012's annotation bypass needed a
273-line declaration certificate after forged-native metadata counterexamples;
do not revive its weaker predicate. P7's unconditional checked-output and
semantic-value work has unresolved demand/arity/reflexivity boundaries. None of
those prototypes may enter this candidate.

## Cheapest falsifier and gates

After CPU release, expose or count the actual checked helper on finite closed
U32/String literals, dynamic Nat/String tails and custom constructor ownership.
Use tail and non-tail modes. Record recognizer entries and exact emitted text;
the candidate is pointless if duplicate recognition is absent, and blocked if
text, evaluation demand, diagnostic phase or public export identity changes.

Use small 8/16/32/64-depth source families as justified, bounded subprocesses,
Node24.18.0, 4MiB stack/4GiB heap and an assigned CPU. An isolated checked B1 and
v4 derivative follow only a decisive operation result. Compare exact JS bytes
and actual execution for a focused set, retaining existing reference diagnostic
differences. Controls include closed word/F32 bits, empty/non-BMP/invalid-scalar
strings, computed tails, aliases, private user constructors, erased and live
failing fields, and dynamic-tail open-Array refusal. Native output should remain
byte-identical because this candidate edits only JS constructor emission.

Preserve every source/tool version, failing oracle and process outcome in fresh
directories. Instrumented/concurrent observations are not speed claims. Root owns
integration, full corpus, controlled timing and release; no production or dist
file is modified by this investigator.
