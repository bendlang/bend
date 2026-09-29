# P16-002D — one allocation for generated-node range attachment

Status: prospective; no measured speed claim.

The populated-range integration03 pilot costs 10.17% more process time than
Phase15. Root profile attributes about 15% to frontend work and reports GC near
15%, versus 13.9% before. Those shares motivate a bounded allocation experiment;
they do not establish that this one helper causes the full regression.

Baseline is immutable `spans-integration-source-04/project`, checked by
`spans-integration-build-04`, optimized API
`9a5294d51db35fc5317ae94bc8439bb62f586b4ea7b8314366cb4ff4473a4c11`.
Change only `f_span_created` in parser.bend. Pattern-match KTerm once, retain the
same zero/existing-origin guard, traverse the same children once, and construct
one final record. This replaces the current child-rebuild record followed by a
second range-replacement record; it also removes the kb/ks projections there.
It adds no new function, pass, representation or host rule.

For valid immutable KTerms, all eight fields, child order, boundary behavior and
parser error priority must be identical. Existing located children must remain
unchanged; legacy zero-start parsing must remain zero/zero. The comparison uses
both complete serialized-book digests and explicit term/range counts, never a
large object assertion that could allocate a full mismatch dump.

Require genuine checked B1 and unchanged v5 derivation, 36 focused controls,
complete raw/indexed Base and compiler-source parses, supplied-source cold/seeded
loader/provenance equality, and all seven recent malformed-parser controls.
Retain every failure. Do not claim speed from allocation counting or concurrent
correctness runs; root decides the serial controlled timing window afterward.
