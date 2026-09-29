# Phase15: paired integration histories and backend validation

Final conformance-only and combined checked compilers pass the fresh-string
and exact saved53/60-request histories. The combined compiler passes all
**41paired backend rows**, retaining the same three exact diagnostic differences.
There are no lost exact backend matches. All owned producer jobs are closed.
These are scoped correctness results, separate from root's full frontend,
release checks and controlled final TypeScript comparison.

## Exact checked candidates

| Attempt | Equality-v5 API SHA256 |
| --- | --- |
| `conformance-02` | `c4c90831259f87e2ae5339da7b9365a56c8df2797ea1c221a211644e2cc8be64` |
| `combined-02` | `b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d` |

Both attempts under `selfhost/build/phase15/` genuinely check with unchanged
upstreamb2111cf, then pass36maintained focused cases with11retained exact
diagnostic differences. Their checked B1 parents are respectively
`06065e057e95224c5ecc4e88b2a96f78f3448d21fe9e9e19d44390b95a3aea6a` and
`32ec77a35982f29d5e6f405a74236fdbff72810b8960459f1e26f4e3c126c1c9`.
The additional difference in the combined compiler is the reviewed two-worker
lookup optimization. Current hosts/runtime/Base are identical between them.

## Paired resource histories

`selfhost/build/phase15/integration-history-binding-01.json` supplies the two
exact attempts to the unchanged Phase14 generic paired-history runner.
`integration-history-01/report.json` completes at00:25:55UTC on2026-09-29.
Both fresh6,000-character string checks pass. The original53and60-request
histories then pass all**226paired complete observations**, including every
predecessor, with4MiBstack/4GiBheap, original30-second request deadlines,
CPU3 and no hidden recycling. Worker generation/index, launch health, captured
inputs and compiler identities pass their original checks.

All113historical requests per variant have the expected current hostProvenance
change from Phase12. Six observations in the53-request history and nine in the
60-request history also change diagnostics. No other result fields differ from
the retained Phase12 successful vectors. The full raw comparison remains in
the history report; `integration-audit-02.json` classifies fields without
normalizing or removing anything from the actual current paired comparison.
These finite histories do not prove stack safety for arbitrary workloads.

## Paired backends and actual native execution

The unchanged maintained development validator runs the existing Phase14
`backend-inputs-01/selection.json` against combined-02. Its CPU3 config controls
the actual child affinity. `backend-environment-01.json` freezes the command,
Node/Clang identities and explicit CC/include/library paths before execution.
Clang is the retained16toolchain under `selfhost/build/phase1/clang/root/`.
The validation runs00:26:15→00:27:41UTC and finishes cleanly with all process,
complete-observation and input-identity gates passing.

`backend-validation-01/report.json` passes41paired rows. Three known exact
diagnostic mismatches remain, all in the check lane:

- `p11/nat_literal_own_nat`
- `p11/nat_literal_own_succ`
- `p11/nat_literal_pattern_arity`

All previously exact rows remain exact. The imported dependent-law fill retains
exact check/interpreter/JavaScript/native results; execution returns5n. Across
the selection,10programs actually compile and execute natively for each
adapter,20executions total. Every candidate native result records Clang16 and
clean runtime output/exit; the reference reports executionMode:native through
its unchanged adapter. Negative compile/refusal rows are not counted as
successful native executions. These concurrent correctness runs are not speed
measurements.

## Retained setup failures and independent review

The earlier conformance-01/combined-01 attempts genuinely build but their
expanded focused selection fails4of36rows. Read-only inspection finds that
existing upstream selections retain their #| exact oracle; adding accept or
rejectPhase metadata does not override it. The four invalid-path cases reach
the correct parser refusal but still print a different observed token. Root's
replacement selection copies those four source fixtures with only #| lines
blanked, gives them distinct local IDs and explicit acceptance/phase oracles,
and preserves their line positions. The original strict failures, full-corpus
oracles and all paired diagnostic differences remain unchanged. No harness
semantics were edited or failed raw result relabeled.

The independent source03 cycle review finds no blocker: active traversal keys
and the private signal carry real canonical paths; the closest closing-edge
catch preserves caller source/token context and tags phase once. Completed
physical aliases are not active cycles. Missing entry/non-ENOENT behavior and
historical API fallback remain separate. Only canonical IO traversal lives in
the host; Bend still formats diagnostics. The behavior owner's checked/control
reports establish their finite tested scope; this review launches no new probes.

`integration-audit.py` initially assumes both native result schemas contain
nativeBuild. The reference instead uses executionMode:native. This postprocessing
failure is retained as `integration-audit-01-failure.json` with the original
tool. `integration-audit-v2.py` checks each actual schema explicitly and passes
over the unchanged completed vectors in `integration-audit-02.json`; no compiler
probe is rerun or failure erased.

All integration history/backend workers and supervisors are closed. Root owns
final full frontend/timing/release decisions and durable evidence publication.
