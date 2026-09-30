# Phase25 generated-program corpus

Preservation note: the original `corpus/pilot-evidence/` paths below are retained
locally and durably stored in [corpus-pilots.tar.gz](evidence/corpus-pilots.tar.gz),
with [per-file recovery verification](evidence/corpus-pilots-receipt.json). Extract
that archive into `selfhost/tools/performance/phase25/corpus/` to restore them.

The frozen corpus contains **23 small programs**: 20 compiler-mechanism witnesses,
one deliberately trivial generated-ABI control, and two unchanged pinned fixture
prefixes with appended runtime-input wrappers. Every entry exports
`bench(size: U32, seed: U32) -> U32`. The machine index is
[`corpus.mjs`](../../selfhost/tools/performance/phase25/corpus.mjs); running it prints
the JSON array with absolute paths and source hashes.

Inputs arrive at the generated-library ABI. Each call includes its documented
input construction, kernel work and complete scalar checksum; the selected bench
function performs no I/O. The runner must time emitted execution separately from
building these libraries. The host-boundary control returns its seed and ignores
size intentionally; its separately sampled latency must not simply be subtracted
from other timings.

## Represented mechanisms and boundaries

| Family | Witnesses | Evidence scope |
|---|---|---|
| Scalar / Boolean | Arithmetic; thunk-choice and Boolean-worker recurrences | Dynamic U32 arithmetic and alternate source shapes for identical recurrence |
| Membership | Choice and worker variants | Renamed `has_name` recurrence, early hit and complete miss |
| Lists / calls | Reverse; map/fold; matcher with remaining arguments; explicit partial application; capture | First-order reconstruction, arity boundaries and capture; static census determines whether each emitter retains the intended shape |
| Strings | FNV hash; codepoint classification; equality | Renamed exact `index_hash` recurrence, lexer-like traversal and name equality; not the full tokenizer |
| Trees | Full fold and repeated shared use | Adapted local tree fixture and pinned shared-tree mechanism, fixed depth 5 with dynamic seed and traversal count |
| Terms | Substitution; field shifting; simple normalization | Four-constructor toy terms, not the production dependent checker or graph-conversion engine |
| Index | Association-list lookup | Immutable numeric bindings and first-hit/miss behavior; not the production persistent trie |
| Literals | Nat reconstruction; pinned dense and wide U32 matches | Runtime conversions plus preserved upstream match/table fixtures |

Most programs are **mechanism analogues**, not extracted full compiler modules.
The membership worker and FNV hash preserve their named current helper recurrences.
The list-map and shared-tree adaptations retain explicit origins in the metadata.
Term substitution has a simplified shadowing rule on its toy domain; term field
shifting is not capture-avoiding semantic freshening. The normalization witness is
a first-order evaluator over identity/addition nodes with repeated sharing, not
full dependent normalization or a graph memoization benchmark.

Two source files begin with byte-identical pinned upstream fixture contents at
`018751270e800bc222a93dad7f257083ee53a5f7`:
`tests/compile/u32_table_popcount.bend` and
`tests/compile/u32_literal_word.bend`. Metadata records each exact prefix's hash
and byte length. Appended wrappers supply dynamic values. The original fixture
`main` functions and I/O expectations remain present but are not invoked by the
benchmark. These are faithful fixture mechanisms, not untouched workload timings.

Recursive helpers are explicitly `@unsafe` where appropriate. Ordinary upstream
checking and ownership still run; this does **not** establish termination proofs.
The shared quantities apply only to Data. Runtime inputs prevent the entire
workload from becoming one compile-time constant, but individual lowering rules
may still remove source constructs. The structural census must record that fact.

## Independent scalar expectations and size policy

[`oracles.mjs`](../../selfhost/tools/performance/phase25/corpus/oracles.mjs) gives
independent JavaScript scalar specifications, never used inside timed execution.
They use explicit unsigned 32-bit wrapping, codepoint iteration for hashing and
scanning, closed arithmetic formulas for tree/term checksums, and direct finite
lookup rules for the pinned fixtures. Expectations are serialized in metadata;
they were not copied from generated-program outputs.

There are **127 unique correctness points** across the 23 programs, including
all **45 benchmark points**. Most inputs cover zero, one, a small middle input,
and a larger one. Membership includes both hit and miss; pinned integer cases
include the maximum U32 value and table default arm. Benchmark inputs use sizes
32/256 for recursive construction or non-tail traversals and 256/1024 for tail,
string and fixed-depth tree loops. The host control has one benchmark point.
`correctness` deduplicates the union of `inputs` and `benchmarkInputs`.

## Fixture-development attempts, all retained

No corpus-owner run is a performance measurement. Serial correctness work used
CPU3 and Node 24.18.0 with 4 MiB stack / 4 GiB heap.

| Attempt | Result | Interpretation |
|---|---|---|
| `pilot-evidence/attempt-01` | 7/20 upstream validity passes | Thirteen source-construction failures: affine duplication without explicit sharing and a constructor named `App` colliding with Base. Every attempted source and error is retained. |
| `pilot-evidence/attempt-02` | 20/21 passes | Added the host control. One substitution variable still needed explicit sharing across condition and branch; original failure retained. |
| `pilot-evidence/attempt-03` | 23/23 passes | Corrected capture and added the two pinned fixtures. Uses complete ordinary library-root emission, matching the root acquisition policy. |
| `pilot-evidence/oracles-01` | 127/127 exact | Actual upstream-generated `bench` outputs match every independent scalar expectation, including all proposed benchmark inputs. |

Attempts 01/02 initially selected only the `bench` library root; their results
remain scoped that way. Attempt 03 uses `C.js_lib(book, true)` after full ordinary
checking, and retains the actual emitted modules. Each source attempt is copied
into its own evidence directory. The exact unchanged pilot helper used for
attempts 01/02 was copied after those runs, before its root-policy change; that
preservation timing is not relabeled contemporaneous. Attempt 03 and the oracle
acquisition capture their helper and metadata before execution.

Root-owned paired emission, generated execution, static analysis and controlled
measurement remain separate gates. In particular, upstream-only fixture validity
does not certify our emitter, and equality on these points is not universal
compiler or backend conformance. No production compiler code was changed by this
corpus work, and no full self-emitted compiler was built.
