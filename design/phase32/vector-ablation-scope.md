# Actual checked03 vector ablation scope

Scope clarification recorded2026-09-30 before interpreting the controlled actual
compiler screen. The frozen [saved-output record experiment](local-record-vectors.md)
and existing hashed controls remain unchanged. The production implementation uses
a narrower ordinary-record rule and also bypasses canonical Sigma constructor
dispatch, so its ablation must be named and interpreted precisely.

## What02 to03 changes

Checked02 includes scoped return-position unpacking and typed Array.get bridges.
Checked03 additionally emits JVector for every constructed type selected by
`j_region_local_vector`, after the existing successful local-type proof:

- Canonical Sigma retains its existing two-field JavaScript array representation,
  but constructs the array directly instead of calling `ctor("Tuple", fields)`.
- An eligible ordinary record rejected by the public flat-terminal-record rule
  uses its field array directly. Constructor and both unpack forms use the same
  normalized predicate. PairBox and aliases to it remain boxed; Nest/Dp can be
  private vectors under the established public boundary.

There is no second AST patcher, new04 compiler or unmeasured representation variant.
The frozen role name `record_vectors` denotes this complete checked03 change.
It must not be described as ordinary-record-only or as leaving the fold bytes
unchanged. Runtime, public constructor/fallback paths, array storage and native
read/write semantics remain unchanged.

## Exact static changes in the affected fixtures

The independent fold loses three private `ctor("Tuple", ...)` wrappers, each14
bytes:77,475 bytes in02 becomes77,433 in03, a42-byte reduction. Its public/generic
Tuple constructor site remains. Any measured fold increment may come from this
constructor-dispatch removal or generated-code/JIT consequences; it does not
establish the cost of ordinary record shells, because this fixture has none.

The full-pair module loses14 private Dp constructor wrappers and10 `.a` accesses,
reducing raw emitted bytes99,823 to99,649 (174 bytes). It has no Tuple constructor
sites, so its02→03 comparison isolates the changed Dp layout within this exact
implementation, subject to normal generated-code/JIT interactions.

The alias/nested-record fixture loses two private Nest wrappers and two `.a`
accesses,77,233 to77,203 bytes (30 fewer), while both PairBox constructor sites
remain. The public terminal-record gate checks boxed output explicitly. The scope
fixture remains byte-for-byte identical between02 and03.

[Static counts and identities](../../implementation/phase32/local-complexity.json)
retain exact modules and receipts. [Independent review](../../implementation/phase32/review-vector03.md)
explains the proof. All six focused actual-output/predicate gate groups passed
before timing. The combined iteration ladder should report01,02 and03 separately;
no speed improvement is established by these byte counts or by this clarification.
