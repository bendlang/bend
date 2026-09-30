# Phase32: remove temporary representation and repeated compiler work

User authorization: implement the recommended generated-code, checker, semantic
reuse and compact-representation investigations, preserve correctness and
simplicity, document experiments and results, commit and push. No PR comment.
Baseline is commit `5f3015d`, installed Phase31 checked07; upstream remains
`018751270e800bc222a93dad7f257083ee53a5f7`. Its measured tradeoffs remain part of
the baseline. No new gain is established by this design.

## Separate questions and owners

1. **Local values:** root owns Bend emitter changes. The local-data investigator
   owns saved-JavaScript ablations and independent array-fold/full-pair controls.
   First replace return-position unpacking IIFEs with scoped declarations.
   Then fuse a canonical Array.get producer with a completely unpacking private
   consumer. Only after this separate result investigate loop-state records.
2. **Structured compiler helpers:** a separate investigator prototypes one hot
   H17 lookup/checker helper. Keep its representation and demand points first;
   compare complete observations before changing further matching machinery.
   A second structural helper must test transfer. H17 is an older generated
   compiler, not the installed B1 derivative or handwritten upstream TypeScript.
3. **Semantic reuse:** measure repeated work over a fixed edit sequence, then
   test one dependency-complete cache against fresh checking. Existing Base
   caches/persistent workers are the starting point. Body reduction, errors,
   specialization, fresh identities and event order belong to the cache key or
   dependency proof; a validated flag alone is insufficient.
4. **Compact analysis:** instrument repeated local-type/normalization/helper
   analysis before proposing an indexed per-function plan. Reuse an existing
   representation when possible. A new IR must retire duplicated machinery and
   demonstrate a benefit; a negative result is a useful completed investigation.

## Local semantic boundary

Follow [the Phase31 proof obligations](../phase31/next-local-transformations.md).
Private input types, complete field telescopes, stable native provenance and
root guards remain required. Fresh scopes preserve simultaneous let bindings.
Initial-zero argument rebinding is not ordinary unpacking and stays unchanged.
Tuple fusion captures the scalar at the original read point, before consumer
writes, even when the field is unused. Evaluate each earlier argument, handle
and index once in source order. Native conversions, wraparound, bounds, physical
array identity and logical read/write order remain observable. Unknown/escaping
consumers and unsupported patterns retain the ordinary representation.

Public descriptors, mutable metadata and hostile/prototype entry behavior must
continue through the existing guarded boundary. No new global unboxing promise
or unchecked recursive-type admission is authorized by the local-data proof.

## Fast experiment and integration gates

Each hypothesis gets a pre-execution file, exact artifact/tool identities,
retained attempts and a separate correctness/measurement/promotion decision.
Use saved-output derivatives first, then genuinely checked Bend-source builds
with the maintained workflow. Derivatives are experiments, not shipped compiler
implementations. Root serializes timing windows; correctness may use separate
cores, but clean confirmation has no competing campaign CPU work.

Minimum local controls include nested scopes, argument prefixes, name collisions,
parallel lets, zero and loop-to-zero, read/write aliases, unused fields, two
producer shapes, canonical-name refusal and hostile guards. Compare the full
pair state and ordered native events plus the independent fold. Count removed
tuples separately from unchanged logical reads. Require actual checked output
to exhibit the intended change before measuring its transfer.

Freeze process/node/affinity, priming, input, runtime and API boundaries. Rotate
variants, retain all observations and half-run drift. Report import/first-call,
warmed program execution, ordinary compiler request and edit-loop costs as
separate metrics. Include mixed generic/specialized, scalar and unrelated-program
canaries, compiler emission cost, source lines/concepts and memory where relevant.
Operation counts are opportunities, not CPU shares or speed forecasts.

Only surviving changes proceed to appropriate inherited frontend, backend,
primitive/worker/library, component and CLI gates. No broad gate or complete
self-emission is part of every inner iteration. Preserve the installed baseline
until a selected candidate has reproducible provenance and release verification.

## Preservation and completion

Snapshot the 103 unrelated starting files and leave them unchanged/unstaged.
Disk pressure may be relieved only by verifying redundant local artifacts
byte-for-byte against already committed archives before deletion, with a
recovery receipt. Preserve all failures, rejected hypotheses and used tools.
Update the compiler guide and current experiment frontier, then commit/push the
selected compiler and comprehensive report. Complete all four investigations;
integrate only evidence-backed transformations. No particular estimated gain
is an admission criterion or a promised result.
