# Phase 23 backend migration and shared arrays

The final checked compiler implements the upstream 0187512 backend fixes and
closes the shared-array execution gaps exposed by its new tests. It keeps the
existing one 64-bit slot per element native array representation, the existing
RFC ownership machinery and ordinary checked Base bodies for Array.fork/join.
There is no packed-array rewrite or new compiler IR/state type.

The final candidate is `selfhost/build/phase23/combined-build-03`: genuine checked
API `5f539f81bace8e5783a7cdd8c82606e106fe85813638d7725bff84a943d57c8a`,
guarded v6 derivative `5596f914fd245a5085a614b81099360aeaf601ed61f16357fc491c85106c1102`.
The checked source and derivative remain distinct artifacts. Build 01 preserves
the initial migration before shared-array support; build 02 preserves the first
atomic implementation and the clone-order failure.

## Observable changes

- Native U32.to_nat casts to u64 before surrounding Nat arithmetic, so a maximum
  word followed by a Nat successor or addition does not wrap at 2^32.
- The shared Bend foreign-source scanner ignores CID/FID spellings in complete
  comments and quoted strings. Both emitters use the same scanner. Its behavior
  deliberately matches upstream's regex, including opaque template interpolation,
  escaped-LF line comments and fallback scanning of unterminated quoted regions.
- TCP.recv, recv_bytes and poll reject a zero maximum length with EINVAL before waiting, reading or
  allocating. Native recv no longer registers a preread wait that could prevent
  the handler from rejecting an idle socket. Positive reads and EOF keep their
  prior behavior.
- Native CPU distribution grows to at least one row per worker. This changes work
  availability without changing the runtime ABI.
- All nine Array.atomic operations now exist in JS/native: add, min, max, and,
  or, xor, exch, cas and fadd. Native operations use the existing 32-bit atomic CAS
  primitive on each uniform slot's U32/F32 payload, return the previous value,
  wrap indices and retain the array handle. JS updates synchronously within its
  sequential runtime; it does not claim native worker parallelism.
- Native array reads and updates follow existing RFC redirects. Splitting,
  matching or rebuilding a shared block retains copied elements, while dropping
  a shared block decrements its RFC. Unshared blocks retain their move/free path.
  Clone keeps the original handle first and an independent copy second.

The last point exposed an inherited bug: native clone previously returned the
copy first. Ordinary value comparisons could not distinguish the pair. A second
alias made it visible: the scoped witness expected 119, but native returned 199
while upstream and JS returned 119. The original failing output is preserved;
changing the pair order fixes it. The existing upstream array_fork_unshare test
also passes after the correction.

## Validation and exact scope

| Gate | Result |
| --- | --- |
| Shared scanner versus exact target emitter regex | 4,116/4,116 exact |
| Direct JS TCP effect contracts | 16/16 pass |
| Eight new upstream backend fixtures, JS/native | 16/16 candidate fixture verdicts pass; 15 exact pairs |
| Four scoped atomic/ownership/socket/scheduler fixtures, JS/native | 8/8 candidate fixture verdicts pass; 7 exact pairs |
| Nine retained upstream array/closure/fork fixtures, JS/native | 18/18 exact and pass |
| Five saved native programs, 5 repetitions at each of 1/2/3/4 workers | 100/100 pass on cores 3–6 |

The two nonexact pairs are the new TCP fixture and the stronger idle-socket
variant on JS. Upstream's emitted JS requires bun:ffi, unavailable in the Node 24
reference environment. Our JS runtime passes their exact expected output. These
are explicit reference-environment limitations; their original paired strict
reports remain false. They are not counted as exact conformance.

The scoped atomic fixture checks all nine operations, previous-value results,
U32 overflow, wrapping indices, successful and failed CAS, and F32 rounding and
cancellation. Ownership controls cover shared boxed leaves and halves, rebuilding
a node from two handles to the same block, join followed by destruction, and
clone independence from a surviving alias. Retained upstream tests additionally
cover floating atomic forks, structural mutation, boxed gets, split/join, closure
arrays and values held across a fork. The 100 repeated executions reuse unchanged
emitted binaries; they are semantic stress observations, not speed measurements.

Independent [ownership review](native-ownership-review.json) checks field
retention, RFC decrement order, redirect reads and the clone correction. It does
not establish safety for arbitrary concurrent non-atomic structural reads and
atomic writes to the same cell. GPU hardware is untested.

ThreadSanitizer could not run in this environment. The first bounded attempt used
GCC 10, which cannot parse the emitted Clang musttail statement attribute. The
second compiled both unchanged reference/candidate sources with Clang 16
instrumentation, but linking against installed GCC 10 libtsan failed because that
runtime lacks __tsan_memcpy/__tsan_memset; the linker also reported unsupported
DWARF forms. Neither attempt is a runtime race result or a sanitizer pass. No
source adaptation or suppressed instrumentation was used to manufacture a pass.

## Evidence and failed attempts

The [evidence index](backend/README.md) lists every consumed attempt. All scripts,
fixtures and selectors live in `selfhost/tests/phase23-backend/`. The frozen
[P23-002 plan](../../experiments/phase23/P23-002-uniform-array-atomics.md) precedes
the atomic implementation and remains a prospective historical input.

The initial new 16 gate genuinely failed four atomic observations (both new
shared-array fixtures, both backends). Scanner build 01 failed sandbox child
spawning; build 02 found an invalid computed match in the proposed scanner;
build 03 found omitted dependencies in the small build harness. Corrected build 04
is checked and passes the differential corpus. Initial JS TCP harness attempts
collided with an existing binding and overapplied a receive operation; corrected
attempt 03 passes 16 controls.

Scoped control 01 contained invalid negative-literal and computed-destructuring
syntax. Control 02 fixes those and reveals the real native clone-order defect.
Its float expected-output comments also incorrectly included .0 for integer
F32.show results, although actual reference/candidate values matched. The final
atomic_operations_v3 fixture corrects those comments; older fixtures and reports
remain unchanged. Only final healthy executions count in the results above.

This work adds 96 physical source lines across 11 changed files, including the
regenerated JS runtime; this is the net diff relative to Phase 22 for the owned
backend/scanner files. It introduces no new data representation/type. The shared
scanner and shared ownership helpers provide one behavior per responsibility.
The phase-wide measured compiler speed and canonical source census belong to the
[main migration report](upstream-graph-conversion.md); these execution gates do
not claim a generated-program speedup.

## Maintained harness after installation

The installed combined-build-03 compiler passes all 114 maintained harness tests
across 18 files. The complete TAP output, command, input hashes and unchanged-input
check are in `selfhost/build/phase23/harness-final-01/`; exit status is 0 and elapsed
time is 31.53 seconds on CPU 3. This is a correctness gate, not a timing comparison.

The first sandbox invocation reported six failing test files; its available
summary is retained in `maintained-checks-01/initial-sandbox-results.json`. It ran
before the new release installation and does not have a complete TAP transcript.
We did not infer that all six failures came from the same cause. Before changing
tests, their original bytes and hashes were saved in `harness-originals-01/`.
Current-default corpus tests now use the exact Phase 23 checkout and its observed
1,513 runnable fixtures, 1,524 Bend sources and 11 support files. The explicitly
historical Phase 8 oracle test still checks the original 1,498-fixture corpus.

The checker capability mock was also stale: it lacked the mandatory contextual
loader ABI 2 contract. It now supplies that contract and separately verifies
legacy, structured and program checker ownership of rejection. Unknown numeric
and string capability values remain explicit refusals before checker execution.
Only test defaults and mocks changed; no runtime change was needed for this gate.
The final invocation uses Node 24 with a 4 MiB stack, 4 GiB heap, one test worker
and local child-process permission, with ambient Bend overrides cleared.

## Current component verification

The advertised `npm run verify` command passes all 18 component steps after
bounded test maintenance. The final invocation is retained in
`selfhost/build/phase23/component-invocation-03/`, with the complete step report,
snapshotted Bend modules and genuine checked 36-export component API in
`component-verify-03/`. It exits 0, reports no changed inputs, and takes 37.74 seconds
on CPU 1. This component API is a separate test artifact, not the installed release
image. The package command supplies a 4 MiB stack and 4 GiB heap; the existing
resource-argument helper forwards those limits to child processes. A fresh
`BEND_COMPONENT_DIR` preserves each invocation, and the default reference checkout
is now the Phase 23 pin.

The maintenance keeps the tests aligned with contracts already established before
this migration. No Bend module, runtime or public API changed during this work:

- Retired raw-parser exports and the retired main-module-only reporting step leave
  the runner. Their historical fixture files remain unchanged. Eight completion
  controls instead compare actual contextually completed sources with ordinary
  graph loading, including dependency aliases, beta reduction, errors, cycles,
  repeated imports, parallel bindings and seed fallback. Current whole-closure
  verdict behavior is independently covered by the full conformance and CLI gates.
- Low-level checker fixtures now construct the existing KWorld/KEnv records, and
  freshening fixtures include the current origin fields and KLambda representation.
  Their deep allocation/order/scope assertions remain intact.
- Diagnostic fixtures now use existing source intervals rather than the removed
  per-term DOrigin lookup protocol. They retain exact token and UTF-16 positions,
  preserve semantic graph equality, and enforce the established overlap and
  changed-alias refusals. Formatting assertions now require the existing caret
  underlines. All eight source diagnostics match the pinned upstream exactly;
  two older tests previously discarded available source locations.
- Specialization tests use the existing result accessors. The 64-level guard must
  now reject through both checker and specialization entry points, reflecting
  existing immediate instance validation. Open template arguments retain exact
  rejection checks using the current underlying unbound-variable diagnostic.

The final gate includes 43 checker assertions, 22 diagnostic assertions, eight
exact upstream diagnostic comparisons, 31 normalization checks, the existing deep
freshening cases, runtime contracts and host safeguards. The separate complete
maintained harness still supplies the broader 114-test result above.

Every intermediate attempt is retained. Component invocation 01 found another
retired export; invocation 02 checked the complete source then exposed the old
KEnv fixture shape. Focused attempts 01–10 reused that same checked component API
rather than rebuilding on every fixture edit. Their failures record the old
open-template message, missing caret underlines, removed DOrigin records, obsolete
span-stripping expectations, old namespace/token forms, incomplete KTerm/KLambda
fixtures, direct access to a changed specialization record, an accessor-edit typo,
and the old delayed depth-guard expectation. The typo was corrected without
changing compiler code. Final invocation 03 reruns the complete maintained
component command and passes. Original and consumed fixture bytes are preserved in
`component-originals-01/`, `component-fixture-originals-01/02/03/`, each focused
attempt, and the three invocation directories.
