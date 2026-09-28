# Update upstream, improve conformance, retain useful simplifications

Date: 2026-09-28. User authorization: update to upstream, improve conformance,
and use the best simplification results. This changes the priority from Phase7's
percentage reduction campaign. Its achieved reductions remain; its 50%/75%
milestones are not claimed complete or prerequisites for useful work.

## Immutable comparison points

Starting fork commit: `69947fc`. Installed S4 B02 has 59 Bend modules, 14,667
physical / 12,505 nonblank lines and 470,062 bytes. Release integrity passes.
The old reference is `6018e28ecc67cf1fffc0c20c64b11023474c2df8` (2.0.21).
The migration target, verified against upstream main on this date, is
`b2111cf43244e65f76ddc278ee695e669f720cbf` (after the 2.0.32 release entry).
Freeze this revision; do not chase moving main during the migration.

Retain the old pinned checkout and source/API/runtime/release identities. A
separate read-only target checkout is `selfhost/.bootstrap/upstream-phase8`.
Upstream source enters the fork by merging its commit, not by editing the
human-written TypeScript language implementation. The explicit update request
authorizes changing the active pin; historical evidence keeps its original pin.
Existing unrelated Phase6 worktree changes remain untouched.

The recorded old frontend gate has 919 positive and 459 negative fixtures,
318 strict failures and 444 exact parse/check observation differences. Its check
acceptance decisions match the old reference. Most differences concern selected
errors or phase/text; they are not automatically cosmetic. The new reference
changes tests and diagnostics, so counts on the two inventories are separate.

## Success criteria

Deliver one usable release built from Bend source against the new upstream pin,
with updated Base/runtime/host contracts, explicit new conformance measurements,
and no silent TypeScript fallback. Preserve the successful provenance, structured
failure, graph-loading and list-operation simplifications. Integrate additional
changes only when their new-target controls pass. Record remaining gaps honestly;
an upstream update is not a claim of complete language or backend equivalence.

Keep three metrics separate: compiler execution, edit/build/test latency, and
emitted program execution. The old 6.03x full-source ratio is historical. The
about-35-second selected edit loop includes about21 seconds of upstream build;
faster self-host execution cannot be credited with speeding all of that work.

## U0: audit and preserve before changing compiler code

1. Preserve the installed source/API and verify release identity. Inspect actual
   upstream diffs and new tests, not only release claims.
2. Audit changed language rules: upfront definition/datatype declarations, unsafe
   definition sugar, literal handling, binder/error rules, canonical module
   identity, namespace clashes and changed CLI verdicts.
3. Audit bootstrap and emitted-code boundaries. New upstream removes public
   `book_owned`, removes `Book.open`, and changes `js_lib(book, roots, outs)` to
   `js_lib(book, mod)`. Its internal Nat becomes Number but its host boundary
   still marshals Nat as BigInt; do not apply a blanket ABI conversion.
4. Rank retained Phase6 candidates against the new target. Old focused passes
   are evidence to revisit, not promotion authority for changed source.

This design and experiment records are committed before migration implementation.

## U1: update upstream and establish a genuine checked compiler

Merge the target upstream commit while preserving fork documentation and compiler
source. Bind current bootstrap/conformance tools to the new pin from one
authoritative manifest where practical. Keep historical legacy/replay pins intact.
Use an isolated build path until the candidate is ready for release installation.

The stage0 helper must check the complete source book and reject unresolved
holes/laws. Adapt only the changed bootstrap API: no omitted checking, parsed
body substitution, or post-hoc fake bootstrap sidecar. Selected library exports
must retain the full checked definition/constructor context. A checked book
view with selected `order` is permissible only after validating export eligibility
and proving that private dependencies still compile correctly.

Build unchanged compiler semantics with the new emitter first where possible.
Test the actual host boundary on terms, lists, nested Nat, callbacks, partial
applications and relevant deep recursion. Freeze old/new artifacts before a
small serial ABBA comparison on identical compiler requests. Upstream's reported
2.3x JS gain is a hypothesis for this workload, not our result.

The old equality derivation is body-sensitive. Reuse it only if its invariants
are re-established for the new emitter; otherwise ship the genuine checked API
and retire the now-redundant maintained transform route if evidence supports it.
No stale transform may run just to preserve an old profile name.

## U2: language and conformance migration

Use small differential selections to implement changes required by the new Base
and target language. Preserve the one-authoritative-error design and immutable
graph context. Change declaration visibility according to the new checker,
including distinctions between safe and unsafe forward calls; do not equate
upfront declaration with unrestricted accepted recursion.

Prioritize acceptance and error-selection differences, then source/phase
classification, then exact presentation. Revisit existing prefix/erased,
import-phase, lexer and parser candidates against current source. Each combined
candidate needs fresh checking and relevant positive/negative controls. Retain
all initial failures and later superseding results.

Create a fresh upstream fixture inventory and run both reference and candidate.
Report positive passes, negative rejections, wrong acceptance/rejection, phase
differences and exact-text differences independently. Track new tests separately
from the old common fixture subset. Do not rewrite expected outputs to manufacture
agreement or normalize away diagnostics.

## U3: runtime/backends and useful simplification

Update Base and effects needed by the chosen upstream. Native runtime source is
an explicit upstream dependency: do not mix a new generated calling convention
with an old runtime accidentally. Run emitted JavaScript and CPU-native programs
for changed primitives/effects and representative constructor/layout boundaries.
Reassess the preserved wide-constructor/native scalar candidate, which had a
concrete execution benefit, before attempting broader layout architecture.

Prefer upstream's concrete simpler mechanisms (shared operator descriptions,
literal representation and reduced duplicate backend bookkeeping) where a scoped
replacement earns its cost. Preserve existing source counts and separately count
new host/runtime/test infrastructure. No percentage deletion quota justifies
weakening correctness or hiding implementation in host code.

The Phase7 runtime generic binder walker and general semantic-value prototype
remain rejected. Checked-output ownership is a later bounded option if current
profiling still identifies annotation replay; do not ship the unconditional
prototype with its check-only regression. A small proven change takes priority
over constructing another parallel implementation.

The new upstream `--verdict`/Lean translation supplies independent future
validation for its supported fragment. This migration must document whether the
port supports that new CLI path; do not silently route ordinary checking through
TypeScript or claim Lean proves the port because upstream ships a kernel.

## U4: release, measure and consolidate

Run maintained harness/runtime/ABI checks, a fresh full paired frontend inventory,
targeted interpreter/JS/native execution, and release integrity/relocation smoke.
Use full self-reproduction when the final bootstrap/emitter boundary needs it;
record that proof separately from conformance. Preserve a usable installed
artifact and reproducible rebuild command for the selected pin.

Measure a bounded serial old/new operation comparison before broader timings.
If warranted, measure final compiler versus new TypeScript on identical frozen
source with explicit Base-cache/startup policy. Retain every sample, failure,
memory observation and consumed artifact identity. Do not mix correctness runs
with performance samples or compare different accepted programs as throughput.

Write implementation reports under `implementation/phase8/`, a file per
hypothesis under `experiments/phase8/`, and update compiler docs/README/current
steering. Commit and push concrete checkpoints to `selfhost/bootstrap`. Default
release promotion requires the relevant gates, not elapsed effort or an
attractive microbenchmark.

## Coordination

Root owns integration, upstream merge/pin, core/checker, release and serial
measurement. Independent agents audit and then own explicitly assigned frontend
or bootstrap helper files. No concurrent edits to the same files. Correctness
workers may use available cores; any controlled benchmark gets exclusive compiler
CPU use. This request does not renew a historical multi-hour deadline.
