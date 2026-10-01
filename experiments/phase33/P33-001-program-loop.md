# P33-001 — Reuse prepared programs for bounded execution comparisons

- User objective: make the fast and slow generated-program loops easy to select,
  reproduce and reuse before further optimization.
- Owner: root; independent implementation and review: program_catalog,
  program_worker and program_review. Only root executes compiler/benchmark jobs.
- Scope: benchmark tooling. Installed Phase32 compiler and pinned target unchanged.
- [Design](../../design/phase33/program-execution-loop.md),
  [implementation and validation](../../implementation/phase33/README.md),
  [maintained commands](../../selfhost/tools/performance/programs/README.md).

## Claim and boundary

Preparing the existing fixed-input corpus once, then reusing emitted modules,
permits useful comparisons under 20 / 60 / 300 / 600-second wall ceilings without
repeating compiler acquisition or the historical long matrix. Inputs, oracles,
compiler identities and coverage must remain explicit. No budget may be met by
silently reducing a program input or dropping a failed observation.

This claim fails if the bundled reference depends on missing ignored builds,
wrong results pass, matched roles are omitted from ratios, prior output is
silently replaced, or resource/deadline failures lose their receipts. A portable
reference does not imply portability of arbitrary unused IO exports.

## Method

Freeze checked ordinary-library emissions from installed Phase32 and pinned
TypeScript. Exercise the checked-attempt acquisition path with the same compiler.
Use fresh serial processes, rotated roles, explicit warmup/calibration/timed
blocks, exact checks on every call and separate first/import times. Run both
synthetic failure controls and the actual preset selections. Test relocation
with Node filesystem permissions denying the original repository, including a
negative denial witness. Keep manual JavaScript experiments explicitly unchecked.

The implementation report retains observed coverage, wall time and resources.
Its timing protocol differs from earlier phase reports; all denominators come
from the same current run. Same-compiler differences characterize noise and
warming, not an optimization. Review follows the finite catalog scope, not a
claim about representative production applications or full backend conformance.

## Review and disposition

Independent review challenged incomplete pairing, interruption receipts, copied
module/worker/point identities, unsafe archive entries, signal/descendant cleanup,
source/verifier provenance and the cold-start cost of raytrace. Corrections are
recorded in the report. Polling is not a hard kernel memory ceiling, and one-second
warmup does not establish universal steady state. Raw observations and consumed
producers are retained in the Phase33 evidence capsule; the portable reference
also retains its complete checked acquisition evidence.
