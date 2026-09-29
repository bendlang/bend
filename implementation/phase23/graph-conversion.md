# Phase23 graph conversion: component findings

The first checked component now compares shared terms without expanding their
logical trees. This is a component checkpoint; the main Phase23 report records
full compiler integration, conformance and controlled speed before promotion.

The change reuses `GHeap`, `GState` and `g_wnf` from strong normalization. The
existing comparison worklist now carries that state. A `KNormShare` continuation
copies the forced left cell value into the right cell only after every equality
obligation succeeds. Repeated edges then reach the same child cell identifiers.
Directional `LE` comparisons never install this symmetric equality. A failed
branch discards its unfinished sharing continuations; completed proofs and
normalization results remain valid for the next alternative.

Conversion first runs with an empty definition book, matching upstream's rigid
comparison, then retries with the actual book only on failure. The passes have
separate heaps. Initial exact comparison still precedes the fresh-identifier
scan. Conversion now shares the graph evaluator with strong normalization and keeps
the existing comparison worklist, with no new global cache or alternate checker.
The ordinary weak-head evaluator remains in use by other checker queries. Telescope domains now share through the existing graph heap;
the deferred codomain remains outside that cell so opening its binder still
substitutes the body.

## Component evidence

`equality-component-02` genuinely checks the four modules `term`, `index`,
`normalize` and `graph` against pinned upstream
`018751270e800bc222a93dad7f257083ee53a5f7`. Its API hash is
`6e394261d5dc39b5497a3a1085a338055555980300bd28432ef7062c663187ac`.
Independent reproduction from its assembled source produced identical API bytes.
This is an upstream-checked test component, not a full compiler bootstrap or a
self-hosted fixed point.

The existing `selfhost/tests/normalize.mjs` passed all31 checks with this API,
including5000-deep constructor equality, strong normalization, binder freshness,
kind alternatives with later failure, and shared recursive/match/field reduction.
The invocation used Node24.18.0, CPU2,4MiB stack and1GiB heap with
`BEND_NORMALIZE_API` pointing to the component API.

The new [paired controls](../../selfhost/tools/performance/phase23/equality-controls.mjs)
passed26/26 against upstream's own term constructors and conversion operation.
They cover:

- Equal and unequal shared binary graphs at depths0,8,16,32 and64.
- A successful shared prefix followed by a distinct later field.
- Alpha-equivalent shared lambdas, capture mismatches and high free identifiers.
- Sharing introduced after a binder opens.
- A directional `LE` domain fit followed by an `EQ` codomain mismatch on the same
  cells. This specifically detects an unsound union after subtyping.
- Kind alternatives, real-book retry after rigid failure, extensional bare
  definitions and nominal stuck heads.

The depth32 and64 equal cases took about15.6ms and19.1ms in this single component
run. These interleaved request observations only establish bounded completion of
the witnesses; they are not a throughput claim. The process's224,328KiB peak RSS
includes upstream, component imports, fixture construction and all26 cases.
Public upstream depth32 regressions require a separate full compiler gate.

## Rejected attempt and preservation

Component01 failed parsing because a `match` cannot scrutinize a computed value.
The component retains that source and its reproduced error. Four ordinary
parameter workers now sequence left/right graph results and kind normalization;
one worker shares telescope domains. No failed API is promoted. An initial shell
attempt also found `node` absent from PATH; subsequent commands use the explicit
Node24 executable.

The [evidence manifest](equality-evidence/manifest.json) and
[archive receipt](equality-evidence/archive.json) preserve both assembled sources,
the successful API and its byte-identical reproduction, exact commands and
upstream hashes, the26 inputs/results, and the control tool. All14 archive members
were independently extracted in memory and hashed against the manifest. Restore
instructions are in the receipt; the compressed archive is32,424bytes.

This first implementation adds102 physical lines across the two maintained
modules: six definitions, one law and one worklist constructor; no new module or
semantic representation. Ordinary checker cost remains an integration question.
