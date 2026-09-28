# Phase11 long-string stack boundary

The 6000-character `check/string_literal_long.bend` fixture now checks at the
same 4 MiB Node stack limit. A fresh isolated replay reproduces the result twice
for the final compiler and twice for the choice-v4-only artifact. Phase10 fails
twice with the same stack-overflow diagnostic. The choice derivative alone is
sufficient for this particular resource-boundary improvement.

Root's full frontend comparison found this one changed observation among 2996:
the check lane now reports type acceptance and passed proof trust; the other
2995 observations are unchanged. This follow-up independently replays that
single check observation. It does not run interpretation, a proof kernel or a
new full conformance vector.

## Reproduction and identities

Prospective inputs and order are frozen in
`selfhost/build/phase11/checker-stack-02/plan.json`; the tool is
`selfhost/tools/performance/phase11/checker-stack.py`. The complete report is
`selfhost/build/phase11/checker-stack-02/report.json`, with
`complete:true` and `inputsVerified:true`.

Six serial fresh isolated workers ran on CPU2 in the order below. Every worker
used Node24.18.0, `--stack-size=4096`, `--max-old-space-size=4096`, the same pinned
fixture and Base, a 30-second fixture timeout, and byte-identical frozen
conformance driver/runtime helpers. Existing validated Base caches were used;
their exact identities were retained and checked after the run. All program
observations, errors, stack traces, commands and environment overrides are
retained in the corresponding numbered subdirectories.

| Order | Artifact | Result |
| --- | --- | --- |
| 0 | Phase10 | `Maximum call stack size exceeded` during check |
| 1 | Choice-v4 only | Type accepted; proof trust passed |
| 2 | Final Phase11 | Type accepted; proof trust passed |
| 3 | Final Phase11 | Type accepted; proof trust passed |
| 4 | Choice-v4 only | Type accepted; proof trust passed |
| 5 | Phase10 | `Maximum call stack size exceeded` during check |

Selected artifact SHA-256 identities:

- Phase10: `ff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9`.
- Choice-v4 only: `a9b79c2e1f7d25853bcc39de922903c8f952c1702227de369c10370530fedc29`.
- Final Phase11: `63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f`.

These are maintained derivatives of genuinely checked B1 artifacts, not
disposable generated-code patches. Their original bootstrap sidecars and attempt
identities are inputs. Every compiler module in the choice-only snapshot matches
Phase10 byte for byte. The earlier [independent review](call_review.md) records
the maintained derivative's verified replay and guard scope.

## Mechanism and limits

The retained failing trace enters `subst`, `subst_node` and `subst_terms`, with
recursive term-list traversal and nested `run_loop` calls. The fixture still
uses the existing expanded string representation. No compact-string syntax,
type-checking rule or substitution algorithm changed in the choice-only build.

The reviewed v4 transform replaces recognized literal choice calls and their
two `run_clo` wrappers with a selected literal arrow passed to the existing
`run_tail`. This changes the generated call/closure shape while retaining its
trampoline protocol. The isolated result attributes the observed threshold
improvement to that derivative. It does not identify exact V8 frame sizes or
prove which optimization inside V8 accounts for the changed threshold.
Recursive substitution remains; larger terms can still exceed the stack.

No execution time ratio is claimed from these checks. They establish a repeated
pass/fail boundary on one fixed fixture with identical resource limits. Proof
trust passed is the existing declaration-verdict result, with
`kernelChecked:false`; it is not a mathematical-validity theorem or general
semantic-equivalence proof.

## Retained wrapper failure

The first attempt, `checker-stack-01`, completed one genuine Phase10 check and
retained the same stack overflow. Its wrapper then asserted the conformance
report's `complete` field, which is false for the expected failed positive
fixture. That wrapper assertion was incorrect; it was not another compiler
failure. The original tool is frozen as `checker-stack-01/tool.py` beside the
full observation and logs. The corrected wrapper checks that exactly one
observation exists and that inputs are unchanged, then runs all six controls
in the fresh `checker-stack-02` directory. No old attempt was overwritten.

CPU2 was released immediately after the six checks. No source/helper changes,
compiler builds or further probes are pending.
