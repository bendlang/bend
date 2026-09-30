# Phase 5 development workflow

For ordinary use and rebuilding the shipped compiler, start with the
[consolidated compiler guide](BEND-IN-BEND.md). `npm run build` composes this
workflow with checked B1 installation; `npm run
verify:release` checks the installed package. The commands below retain isolated
attempts for experiments without replacing the default.

Use a genuinely checked B1 for routine compiler edits. The maintained entry
freezes the source, runtime and host, builds the API, prepares its own validated
Base cache, and runs selected cases against pinned TypeScript. Compiler work
still executes the compiler written in Bend. The [design](../design/phase5/conformance_and_development.md)
defines the broader integration gates.

From `selfhost/`, create a small configuration, with paths relative to that file:

```json
{
  "upstream": ".bootstrap/upstream-phase23",
  "jobs": 1,
  "cpu": "3",
  "heapMb": 1024
}
```

Then run Node 24 with a new attempt directory:

```sh
node tools/development/workflow.mjs run development.json build/dev/attempt-01
```

The example limits each Node heap to 1 GiB and uses one worker. A heap limit
does not bound total process memory. For larger campaigns, run heavy jobs
serially and supervise the whole process tree. Phase32's
[bounded runner](../selfhost/tools/performance/phase32/bounded-run.py) records RSS,
checks available memory, enforces a deadline and stops tracked descendants.
Its [resource policy and limitations](../design/phase32/bounded-resumption.md)
and [executed stop controls](../implementation/phase32/supervisor-controls.md)
describe what it guarantees. Recent checked builds plus the focused gate took
about 40 seconds with the 1 GiB setting.

The default selection is 36 frontend witnesses: the earlier 26 cases (including
four imported-law trust refusals and the 6,000-character string) plus six exact
upstream checks and four separate illegal-import-path controls from Phase15.
Those four custom fixtures explicitly require refusal during parsing; they retain
known wording differences and do not replace the original strict upstream cases.
The string runs first, preserving its fresh-worker comparison. Phase11 itself can
overflow at4MiB after the previous21-case history, and rejected Phase12 variants
fail separate stack controls; those failures are retained in the Phase12 report. This gate does not claim general
stack safety. It does not assert exact diagnostic agreement. Supply `"selection"`
to choose exact upstream probes or custom fixtures using the
[selected harness format](PHASE2_DEVELOPMENT.md#select-exact-upstream-probes).
Parse/check selections reuse persistent workers; a selection containing an
execution lane uses isolated workers. Emitter/runtime changes need applicable
compile-and-execute witnesses, not only frontend cases.

To test changed fixtures without rebuilding that compiler:

```sh
node tools/development/workflow.mjs validate build/dev/attempt-01 \
  my-selection.json build/dev/validation-02
```

Every validation directory must be new. This command verifies the original
checked API, source snapshot, runtime, helpers and bootstrap evidence before
reuse. It continues to test that frozen compiler even if the working source
has since changed; run a new build attempt to test compiler edits. It discovers
fresh fixture graphs and retains failed reproductions and replay histories.

`build.json` records the checked build phase. `attempt.json` identifies the
immutable compiler and its genuine `.bootstrap.json`. Each validation has its
own `report.json`, paired reference/candidate reports and command logs.
`complete` means that the requested observations finished with stable inputs;
`pass` describes their strict/explicit-oracle result. Exact diagnostic
differences are counted separately. Nonzero exit remains nonzero, including
known strict failures. These reports never imply full-language conformance.
The CLI summary includes `exactDifferences`; set `"strictExact": true` to also
require zero exact reference/candidate differences, even for custom acceptance
oracles. By default those oracles retain their declared acceptance/phase scope.

An interrupted bootstrap is not reusable: inspect its logs and choose a new
attempt. If `attempt.json` identifies a completed verified build but validation
was interrupted, use `validate` with a fresh destination. No partial worker
history is silently resumed or overwritten.

Set `"fullFrontend": true` for the full candidate parse/check inventory after
the focused paired gate passes. Use `"jobs": 4` and a mask of four available
physical cores, for example `"cpu": "0,1,2,3"`, only when those resources are
available. All workers share the mask. The full report preserves existing
conformance failures, so complete coverage can still exit nonzero. Live pinned
TypeScript is run for the focused selection; the optional full inventory is a
candidate gate, not a second paired full sweep.

Resource options are `timeoutMs` per probe (default 120,000, maximum 300,000),
`phaseTimeoutMs` for selected validation (default 900,000), `fullTimeoutMs`
(default 3,600,000), `heapMb` per process (default/maximum 4,096), and
`recycleAfter` (default 64). Bootstrap and Base preparation each have a
180-second outer deadline. The unchanged bootstrap currently gives its stage0
child a 120-second deadline and its existing Node resource policy; workflow
parent flags are not claimed to propagate to that nested child. Deadlines,
spawn failures and output overflow retain failed reports. Choose a smaller
selection before increasing a deadline.

The optional `"profile": "equality"` delegates to the separate checked-B1
equality derivation helper. It retains the untouched checked API and records a
distinct derived artifact. Unknown bodies or missing provenance are refused.
The development workflow defaults to `"checked"`; `npm run build` defaults to
`"equality"` after the [Phase9 current-pin validation](../implementation/phase9/checker_speed.md).
An explicit profile overrides either default.

The current pin is `018751270e800bc222a93dad7f257083ee53a5f7` (after
Bend 2.0.34). Prepare `.bootstrap/upstream-phase23` at that exact commit;
historical reference checkouts remain unchanged. Phase23's guarded version6
profile recognizes the new Base chain `String.eq → Cmp.is_eq → String.order →
Pair.snd/String.cmp`. It checks the full dependency bodies and retained runtime
contract before applying the existing equality/choice transformation. Versions
1–5 still replay their original bytes. An unknown body, runtime, or protected
binding is refused. See the [migration report](../implementation/phase23/upstream-graph-conversion.md)
for controlled costs, failed attempts and final validation.

In Phase12, `equality` remains the compatibility profile name. Its version5
includes native-choice helpers and replaces a restricted set of returned literal
branch closures with scoped blocks. Both branches must contain one return and
no nested call work; a terminal generated call may have only call-free arguments.
Other branches keep their closure boundary. The condition is evaluated once, the chosen Unit parameter
retains its binding, and terminal generated calls use the unchanged runtime's
tail-message format. Public forcing wrappers, runtime bytes, argument order and
bounded tail stack remain protected by the reviewed profile/export/binding guards.
Unsupported branch statements retain the prior path; unsupported lexical or
protected-binding changes are refused. Historical versions1/2/3/4 replay their
original bytes exactly. Private unforced message identity is not invariant.
The untouched checked B1 and explicit derivation record remain separate; this
is not a newly self-emitted fixed point or a change to emitted user-JS behavior.
See the [Phase12 report](../implementation/phase12/avoidable_work.md).

The [Phase11 report](../implementation/phase11/known_work.md) records the combined
source offload demand guard, shared constructor telescope and native open-Succ
compaction, their failed attempts, and final validation. Native compaction uses
private `NNatAdd`/`NNatSum` terms after constructor identity and erasure are known;
it evaluates the tail once and preserves the first checked increment before a
bounded residual addition. U32 run counts and the runtime's 48-bit Nat cap are
distinct bounds. The retained long-string fixture passes the final full frontend
run with a 4MiB stack; that result does not establish unbounded string support.

Historically, the focused workflow gate and a full 2,756-observation frontend
gate passed for this route. On the frozen Phase5 second integration, an
exclusive four-core ABBA comparison reduced mean full frontend wall from301.9
to229.8seconds (23.9%), retaining every known failure. This is an artifact-specific
workflow result, not a general compiler or generated-program speed claim; see
the [controlled comparison](../implementation/phase5/equality-frontend.md).
See the [workflow evidence](../implementation/phase5/development-workflow.md)
for the exact tested scope and retained diagnostic differences.

Persistent parse/check workers now privately reuse decoded Base data after
verifying the complete cache bytes and compiler/Base identities on each request.
A changed or invalid cache clears the entry before normal validation; the book
is immutable and source graphs remain per-request. This requires no user setting.
Public single-request compilation and program execution keep their existing
paths. A controlled full-inventory comparison on one frozen checked compiler
reduced mean wall from 292.6 to 242.6 seconds (17.1%), with every observation and
worker history unchanged. See [the cache policy and gates](../implementation/phase5/persistent-base-decoding.md).
The equality and Base-memo percentages come from separate comparisons and must
not be multiplied to claim an unmeasured combined gain.

On the final Phase 5 source, the [controlled complete-source comparison](../implementation/phase5/full-source-comparison.md)
measures mean process wall of 60.25 seconds for pinned TypeScript, 642.58 seconds
for checked B1 and 363.39 seconds for its maintained equality derivative. All six
compilations pass checking, output-byte and execution gates. Bend uses validated
disk Base caches while TypeScript reloads/checks Base, so the 6.03× derivative/TS
ratio describes these workflows. This is a long integration workload; use the
focused commands above for ordinary edits. It does not measure public self-emitted
H or establish faster runtime for generated user programs.
