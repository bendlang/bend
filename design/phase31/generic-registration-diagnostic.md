# Unused exact-call registration and generic-row cost

This bounded diagnostic follows the completed checked07 confirmation. The
complete generic row is 5.04% slower than installed17, with disjoint fresh
sample ranges. It does not enter a local scalar-result region. Installed17's
module contains no exact-call registration; checked07 registers `pair` and
`batch`, neither of which the diagnostic row calls. The common runtime changes
its `invokeExact` branch after any registration: `hasExactCodes` becomes true,
so generic exact-arity calls also execute `exactCodes.has(code)`.

The single hypothesis is that enabling that existing global registration flag
accounts for most of the generic-row regression. No production source or actual
checked07 module will change, and no entry-safety check will be disabled.

## Frozen change and controls

Read the exact three module identities from
`selfhost/build/phase31/canary07-plan/confirm.json`, selecting only
`complete-generic-row32`. Derive one module from its installed17 input by
appending exactly `\nexactCode(()=>null);\n`. The returned registered wrapper is
never stored or invoked; it is not reachable from any public Bend definition.
Removing exactly that suffix must recover every byte and SHA256 of installed17.
The existing `exactCode` helper is unchanged. Assert that original installed17
has only its helper definition, while checked07 has that definition and two
actual registrations. Preserve all original modules and the previous canary.

Reuse the unchanged `review-local-data.mjs` against installed17, the diagnostic
and checked07. It checks 99 complete four-array oracle points, 12 native event
schedules, fresh and aliased storage, public fallback and ordered hostile
boundaries, plus delayed-write and omitted-zero-swap negative witnesses. Its
inputs, consumed tool and result become part of the timing plan. This validates
the new derivative without changing the existing oracle or measured wrapper.
Pinned TypeScript remains the same absolute reference, with its frozen complete
row output checked by the timing harness as before.

## Prospective comparison and interpretation

After those controls pass, freeze four roles: original installed17, installed17
plus one unused registration, unchanged checked07 and pinned TypeScript. Reuse
the exact n32/seed17 complete-row point and its expected serialization. Use the
existing confirmation protocol: five fresh rotating serial samples on CPU3,
at least 100 calls and three seconds of warmup, then a 300ms measurement target.
Only the root-granted exclusive window may run timings. Controls acquire on
CPU6; they are not throughput evidence.

Report all medians, ranges and half-sample drift. The hypothesis is supported
as a substantial explanation if the diagnostic is slower than installed17 with
disjoint ranges, explains at least 75% of checked07's same-window excess time,
and is within 2% of checked07 or has overlapping sample ranges. If not, report
the residual instead of assigning it to registration. Regardless of the result,
this diagnostic does not establish a safe runtime fix or erase the original
regression. The separate scalar zero-work cost and existing private-region
speedups retain their original measurements.

Raw output prefixes are `selfhost/build/phase31/generic-registration-*`;
the maintained deriver/plan tool is
`selfhost/tools/performance/phase31/generic-registration-diagnostic.py`.
All failed derivations, controls and timings remain preserved under fresh names.
