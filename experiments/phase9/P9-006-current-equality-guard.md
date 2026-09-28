# P9-006 — Remove redundant current-emitter string validation

- Owner: staging/IR agent; independent reviewer and integration owner: root.
- Prospective record: 2026-09-28, before isolated implementation or controls.
- Trigger: completed residual-profile-02 assigns 14.28% of sampled exclusive
  time to the current guarded String.eq helper. Sampling does not identify how
  much belongs to its two isWellFormed calls or establish a speedup.
- Correctness: source hypothesis only; differential controls pending.
- Measurement: no new full-source timing or profile authorized by this task.
- Decision: investigate in an isolated helper; production changes require root
  review. No release installation is part of this experiment.
- Report: [current-equality-guard.md](../../implementation/phase9/current-equality-guard.md).

## Hypothesis, invariant and falsifier

For the exact current b2111cf generated runtime and 11 protected dependency
bodies, String.eq on any two primitive JavaScript strings is equivalent to `===`,
including malformed UTF-16. If true, the current derivative can avoid scanning
both strings with isWellFormed before comparing them. Legacy 6018e28 semantics
validate malformed character codes and must retain the existing guarded fallback.

The proposed invariant is injective decomposition: codePointAt plus the emitted
one- or two-code-unit slicing partitions every UTF-16 string into tokens. A valid
surrogate pair has a unique scalar value above 65535; each unpaired code unit has
its own value at or below 65535. Equal token sequences therefore imply equal
original code-unit sequences, and vice versa. Inspect the actual dependency
bodies and failure/demand behavior before treating this as established.

The claim assumes standard unmodified JavaScript built-ins, matching the prior
derivative. Non-string inputs must retain the unchanged fallback body, including
observable object access/error order. Resource exhaustion and reflective or
monkeypatched-host equivalence remain outside the claim.

Any differing Boolean, error, object observation, public API behavior, legacy
byte replay or accepted invalid provenance blocks promotion. A helper timing
alone cannot establish a whole-compiler benefit. If the proof fails, keep the
current guarded helper and retain the counterexample.

## Isolated implementation and checks

Preserve integrated-02's genuine checked API, current guarded derived API,
bootstrap/derivation reports and helper snapshot by exact identities. Keep
legacy transformation version 1 and existing current version 2 replay intact;
use a distinct version 3 for changed current replacement bytes. Runtime,
protected bodies, source/Base/bootstrap recipes, exact public exports and pin
cross-binding remain guarded. Do not change the upstream compiler or generated
user-program behavior.

1. Write the inspected dependency slice and source proof to the report.
2. Build an isolated helper candidate with the smallest versioned replacement.
3. Run the existing 12 current and 11 applicable legacy boundary groups.
4. Differentially compare genuine current helper, version 2 and version 3 over
   all single UTF-16 code units, all valid surrogate pairs, representative short
   string pairs and deterministic seeded arbitrary-UTF-16 fuzz cases. Include
   lone surrogates, mixed paired/unpaired boundaries, long common prefixes,
   non-string inputs and observable fallback objects. Bound this additional
   differential process to 20 seconds; preserve a deadline failure if reached.
5. Verify exact old version-2 derivation replay as well as version 1. Preserve
   source snapshots, inputs, commands, seeds, counts, failures and output hashes
   under fresh directories in selfhost/build/phase9/current-equality-guard/.
6. Send root the proof, scope and controls before any production edit. Root owns
   independent review, integrated compiler gates and controlled timing.

CPU2 is assigned for these isolated checks. No compiler rebuild, full-source
check, profile rerun, archive capture or release install is included. This plan
is frozen; results belong in the linked implementation report.
