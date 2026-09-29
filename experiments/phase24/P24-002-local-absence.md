# P24-002: prove local misses with the existing contextual index

Prospective, 2026-09-29; owner root, independent review phase23_equality.
CPU profile02: source completion5.019s, check3.343s in diagnostic request9.857s;
f_find owns623.8ms exclusive samples. Parent stacks point primarily at local
header lookup, signature selection and publication. Existing prior index cannot
replace first-event lookup: its construction picks the last prior duplicate.

Hypothesis: a miss in the existing scope index proves a miss in the local emitted
book. Every published local declaration also publishes a header with its alias/
namespace mapping (f_context_header). Temporary self/type headers can add hits,
which must fall back to the original local scan. On a hit retain original order,
full definition and Missing sentinel behavior; use no cached definition directly.
One helper centralizes this proof and replaces local scans only where FParseScope
and the matching book travel together. Leave prior and constructor scans alone.
No new index, cache, datatype or frontend. A public fixture mismatch, header/book
invariant counterexample or cost regression rejects promotion. Test local laws,
fills, imports/aliases, nested names, shadowing, malformed declarations and exact
first diagnostics before broad frontend. Use same frozen ordinary workload for
controlled baseline/candidate/TypeScript comparison; profiling is not timing.
