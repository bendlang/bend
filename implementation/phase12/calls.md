# Phase12 residual choices: independent A/B investigation

Native choice lowering A and the narrowed164-site leaf transform are retained
in the final no-seed candidate. The original broad transform fails long-string
checking even with the seed cleanup removed. Separately, matched-history
replays identify that seed cleanup as a source-level resource regression, so
root restores the original source. Final leaf API0975a4a8 passes both exact
53/60-request histories,22 focused cases,16 maintained groups and current plus
historical replay. Root owns the broad gates, controlled timing and release;
the earlier~9% leaf screen remains diagnostic.

The [prospective plan](../../experiments/phase12/P12-003-calls.md) was frozen
before probes. Baseline is Phase11 `f8244c9`, pinned upstream b2111cf, immutable
`selfhost/build/phase11/integrated-01`. Its selected API is
`63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f`.
Evidence paths below are relative to `selfhost/build/phase12/`.

## Static opportunity

`call-opportunities-01` preserves the plan, exact selected image, tokenizer,
maintained helper, pinned TypeScript emitter, and static census. The upstream
emitter already recognizes ordinary direct calls and direct tail cycles; only
closure application uses the trampoline. Ordinary uncurrying is not repeated.

The image has 1,532 generated functions. All229 remaining `nt_choose` calls have
two literal `run_clo` thunks: 458 wrapper sites remain after version4. Its exact
body matches the already reviewed `kc`/`f_choose` protocol. Separately, 1,012 of
the existing1,190 lowered choices occur directly after `return` and have the
restricted branch structure required by B. These are static syntax counts,
not operation or allocation measurements.

## A: finish literal-thunk lowering for native choices

`call-native-choice-01` applies the same verified body/runtime and protected-name
guards to `nt_choose`. It transforms all229 sites, with none skipped, producing
API `5c407dc3453daa7252c74fd6bbd74abe6b86dec373bbde339ec85dfe3d3ad9ab`.
The selected raw arrow still enters the original `run_tail` boundary. Runtime,
exports and public marshalling remain unchanged. This is an explicit derivative
of the verified baseline, not a new checked bootstrap.

`call-native-controls-01` passes29 boundary/public graph controls, including
raw truthiness, selected demand and exceptions, public partial/extra arguments,
returned functions and raw messages, nonliteral fallback, protected mutations,
100,000 self-tail iterations, and exact loaded graph/check/report observations
for4,16,64 definitions.

`call-native-counts-02` instruments actual native emission in the owning process:

| Fixture | Baseline wrapper calls | Candidate wrapper calls | Tail calls, both |
| --- | ---: | ---: | ---: |
| Bit main | 544,596 | 0 | 9,953,581 |
| Nat16 pattern | 632,914 | 0 | 2,234,393 |

The first row includes first Base preparation for each variant; the second uses
the resulting per-variant cache. These are not scaling samples or timings. Both
complete emission observations and C bytes match exactly. C hashes are
`c37637845619c1f567bbd4d5381e7dfeb8d0a773add578439be26c98c5c90772`
and `6826162ca00e9533752e0a8261aa6d436cc21c6fb0cec0f27e3126a379ae2cbb`.
No Clang or emitted-program execution is claimed by these operation probes.

## B: replace a returned branch closure with a scoped block

`call-tail-01` starts independently from the original Phase11 selected image,
without A. It transforms1,012 returned literal Unit choices and replaces1,010
terminal direct generated calls with existing-runtime messages. Its API is
`30c48835bd6539fba71819c472736f0e66a0acc694c965151ac47f70c46a17aa`.

The admitted branch body has zero or more simple `const` declarations followed
by one terminal `return`. The replacement evaluates the condition once, binds
the Unit parameter inside the selected block, and retains lexical captures.
Unknown branch statement forms remain unchanged. The module guard rejects
nested function declarations, protected binding changes, member callees, and
`this`, `arguments`, `new`, `super`, `eval`, `yield`, `await`, `try` and `finally`.

A terminal generated call `g(a,b)` becomes a message containing the stable
generated function and its arguments. The callee is evaluated before arguments,
which retain left-to-right evaluation. The unchanged `run_loop` invokes it later.
This preserves the terminal tail-call boundary. It does not preserve the
frame size during nested non-tail argument evaluation; the later broad gate
exposes that distinction. Generated functions cannot observe the method receiver introduced by
`r.f(...r.x)` because the lexical/control guard excludes that dependency.

Ordinary values, returned functions, raw `$JMP` values and existing nonliteral
tail applications keep their forcing behavior. Runtime and public export bytes
are unchanged; the verified parent supplies their checked marshalling/forcing
contract. Private unforced tail-message representation is deliberately not an
invariant. Synthetic controls compare complete forced observations, not the
identity of an internal continuation. Hostile prototype mutation and reflective
function/stack strings remain outside the standard runtime assumption.

`call-tail-controls-01` passes29 initial boundary/public graph controls.
`call-tail-boundaries-01` adds34 controls:100,000 mutual tail steps; Unit and
per-turn captured closures; partial/overapplication; condition, argument and
callee effects/errors; raw-message tag/function/argument getters, receiver and
throw order; undemanded raw values; nonliteral fallback; unsupported branch skip;
and eleven rejection mutations. `call-tail-selected-01` matches all21 complete
focused baseline observations exactly, excluding separately recorded host
provenance. This is stronger than acceptance-only comparison but is not broad
language conformance or historical derivation replay.

`call-tail-counts-01` counts both remaining `run_tail` messages and the newly
introduced direct generated-call messages. Instrumented API graph/check results
match exactly; no count disappears merely because its allocation moved.

| Definitions | Baseline messages | Candidate `run_tail` | Candidate direct messages | Candidate total |
| ---: | ---: | ---: | ---: | ---: |
| 16 | 12,124 | 777 | 3,936 | 4,713 |
| 64 | 61,484 | 2,937 | 24,154 | 27,091 |
| 256 | 451,276 | 11,733 | 224,418 | 236,151 |

Total messages fall48–61% on these valid loading/checking graphs. Wrapper calls
are already zero for both variants in this lane. This does not establish a V8
allocation count, memory saving, or speedup: indirect dispatch may have a cost,
and the representative controlled comparison remains necessary.

## Original maintained version5 handoff: subsequently rejected

After root reviewed B's restricted grammar and public forcing contract, the
isolated `call-maintained-01/project` combines A and B in the existing equality
derivation helper. Version5 is the current-pin default; explicit versions1–4
retain their original transformation paths, output bytes, and statistics. The
existing production tokenizer is reused, with no external helper dependency.

Independent review found no blocker within the finite generated/public-forced
domain. It confirmed an essential integration condition: version5 tail lowering
runs only after the existing `currentExport`, exact runtime and reviewed profile
guards in `transformEquality`. The standalone experiment validates only the
outer export shape and is not a trusted arbitrary-JavaScript optimizer. Raw
reflection, stack strings, hostile prototype mutation and private unforced
message representation are excluded; public forced observations remain required.

The genuine checked-B1 workflow in `call-maintained-01/attempt` passes all21
focused gates with12 retained exact TypeScript differences. The resulting
version5 API is
`e169b0b952cc2ade7ffd247d09258d03aaaa0cedc5e434aa501dcc86a739afcc`.
It lowers1,419 literal choices, then1,197 returned branches;1,166 terminal
generated calls retain a message boundary. These counts differ from independent
B because A exposes additional native choices before B runs.

`current-tests-01/report.json` passes all16 maintained groups, including nine
new generated-callee/lexical-control mutations and integrated effect-order,
Unit-capture,100,000-tail-step and arity controls. The pre-existing public zero-
arity/currying/extra-argument, malformed-string, demand and lineage controls also
run against the version5 image. `replay-01/report.json` verifies the completed
version5 attempt and authentic historical v1, v3 and v4 releases plus the v2
derivation. In particular, v4 replays exactly to the Phase11 API63c861e9.

After root integrated the source survivors and copied the maintained helper,
`final-derivation-tests-01` repeats all16 groups against the final genuine checked
parent and the live helper/tests, verified identical to the checked snapshot.
Its launcher exits0 with stable input identities. `final-replay-01` passes current
version5 verification and authentic v1/v2/v3/v4 replay again. The final integrated
selected API is `fcd23771a4e070fb4610d26ce0269e327e1a0d7029bd4f4f354a572219dae479`.
These derivation gates passed, but the later broad frontend rejects this
integrated image. They are retained evidence, not release approval.

The handoff files are under
`call-maintained-01/project/tools/development/`, also preserved in its checked
snapshot. Helper SHA-256 is
`dbfc09f0656e3d46fb0f1a4b56e264ba819e3022f4a224c25f65bd56ca7f66ca`;
test SHA-256 is
`06d06de39a51cf92fd8466d96f38d059dc0a04149adfff6feb53224a9a992de2`.
Before-images and exact patches are retained. Additional tests have their exact
fragment and edit record; the final snapshot is authoritative.

This adds23 physical helper lines (273→296) and5,526 helper bytes
(21,543→27,069), plus29 test lines (170→199) and2,841 test bytes. Dense formatting
does not mean the new recognition and forcing obligations are small. No Bend
source line changes. The selected compiler image grows22,272 bytes
(762,897→785,169); this is not a code-size improvement. Emitted user programs
and their runtime remain a separate axis from host compiler throughput.

## Failures, resources and decision

The first native-count attempt used a self-contained Bit program without
`import Base`. Type checking succeeded, but native compilation correctly refused
with `a build needs import Base`. `call-native-counts-01` and its consumed tool
are retained; fresh attempt02 adds the required import. One syntax-check shell
command used unavailable bare `node`; the retained launch note records exit127,
and the absolute Node24 command then passed. Neither is a successful compiler
gate under the failed setup.

Owned probes run onCPU3 with Node24.18.0,4MiB stack and4GiB heap, after root
released the profile slot. All dynamic probes above execute in the owning Node
process; none relies on a status-only child launcher. Actual inputs and consumed
tools are retained. No live Bend source, production helper, runtime, installed
artifact or pinned upstream checkout is changed by either candidate.

A and B have separate operation evidence, but B does not meet the resource
contract. The small A-only maintained alternative is owned by the normalizer
agent; its fresh checked workflow and final root gates must determine adoption.
The rejected version5 helper, tests, attempt and integrated image remain intact
for exact replay. Official historical versions1–4 remain unchanged. Root owns
controlled timing, integration and release; no candidate receives an unmeasured
share of a later combined speedup.


## Broad stack gate and causal ablation

Root's complete frontend gate on `integrated-01` finds exactly one regression:
`check/string_literal_long.bend` fails with `Maximum call stack size exceeded`.
The other2,995 observations remain unchanged. The ordinary focused selection
had omitted this existing test; root now adds it to the routine22-case gate.

`call-stack-01` derives v4, A-only, B-only and A+B from the same verified final
checked parent. Source, Base, runtime, ABI, hosts and4MiB/4GiB resource policy
are held fixed. The initial cold diagnostic wraps public checking to capture
raw stacks; all four fail under that altered setup, so it is not a valid
acceptance comparison. Its traces are retained: v4/A recurse in substitution,
while B/A+B recurse through `check`, constructor and telescope checking.

`call-stack-harness-01` removes the hook and uses the exact unchanged isolated
conformance worker with separately validated per-image Base caches. Its decisive
same-source results are v4 pass, A pass, B fail, A+B fail. Root independently
checks the normalizer seed source change with v4 in ABBA order; all four pass.
This isolates the observed resource regression to B, rather than the seed or A.

Root's `stack-frames-01` bytecode diagnostic adds supporting evidence: the
unoptimized `check_node` frame grows40→248 bytes; `tele_check_static`48→136;
`tele_check_after_head`64→120; `check_ctr_found`104→128. This is not proof of
optimized V8 frame sizes. The source-level mechanism is nevertheless concrete:
B evaluates nested arguments of a deferred terminal call in the enclosing
function, so non-tail checker recursion can carry a larger frame even though
the eventual terminal call still uses a trampoline message.

Three prospective structural counterfactuals in `call-stack-variants-01` do not
fix the regression. Requiring lone-return branches with no `const` retains887
sites; omitting unused Unit bindings retains1,197; combining both retains887.
After explicit cache validation, `call-stack-harness-03` fails all three. A prior
primer syntax error (`pass` used as a keyword argument) caused an unintended
unprimed run in `call-stack-harness-02`; that failed setup, consumed bad tool and
all observations are retained separately. It is not the primed comparison.

The narrower `call-stack-leaf-01` instead preserves the original closure around
all branches containing nonterminal calls. Each admitted branch is one return
with no declarations, and has no call except a single terminal generated call
with call-free arguments. It retains164 of1,197 sites, defers161 generated calls,
and introduces no function-name or fixture exceptions. API is
`b132e10300274616b118dcd7daec5d856fa4759e73d7235239f28772129316e4`.
After explicit private Base preparation, `call-stack-harness-04` passes the exact
long-string worker at the unchanged4MiB stack. This establishes a useful
counterfactual, not broad correctness or a maintained-candidate promotion.

`call-leaf-diagnostic-01` is the prospective bounded same-source A-versus-leaf
checking screen. It verifies actual checking/trust results and source/API/cache
identities, uses CPU3 and the established worker, and adds reverse order only
when the initial ratio is within10%. Team jobs may run concurrently, so its
measurements are diagnostic and cannot substitute for root's final serial
comparison. All four A–leaf–leaf–A rows pass checking/trust and agree on unsafe
definitions, with stable identities. Request means are28.710s for A and25.975s
for leaf (9.53% reduction); process means are29.759s and27.020s (9.20%). No
broad conformance, full behavior suite or historical maintained-helper replay
has been run for leaf. Its copied tool still carries the original broad-B
report-kind/scope string; the prospective plan and explicit grammar above
identify the actual restricted experiment.

The initial owner recommendation was A-only for simplicity, preserved in
`call-stack-decision-01`. Root instead authorized one final maintained leaf
candidate because the repeated~9% diagnostic benefit warrants a complete gate.
The broad transform remains rejected, and A-only remains the fallback if the
narrow candidate fails broad conformance or the controlled benefit disappears.
The new attempt must verify the exact restricted grammar, public boundaries,
long-string resource behavior and full frontend before promotion. The lesson is that
removing a closure can save allocations while enlarging the live recursive
frame; terminal tail messages alone do not protect nested non-tail work.


## Maintained leaf-only version5 candidate

`call-leaf-maintained-01` is a fresh unpublished version5 revision; no earlier
attempt or helper snapshot is overwritten. It uses the exact `integrated-01`
source and host, plus the current22-case selection. The helper keeps the
profile, complete export, runtime/body and protected-binding gates before leaf
lowering, and reuses the existing tokenizer. Obsolete const-body handling is
removed. The new call scan also rejects optional calls (`f?.(...)`) inside
branches or terminal arguments, closing a hole identified by root's review.
Calls in the condition remain allowed in their original evaluation position.
The new report kind and scope explicitly describe the leaf-only grammar.

The helper produces exactly the previously screened API
`b132e10300274616b118dcd7daec5d856fa4759e73d7235239f28772129316e4`:
164 transformed sites,1,033 skipped,161 terminal generated-call messages.
`prebuild-tests-01` passes all16 maintained groups against the same verified
checked parent. New controls explicitly prove nested, nonterminal and optional
calls stay behind the original boundary; lone-return/call-free recursion is
transformed; Unit values and returned closures retain captures; effects,
exceptions, public arity and100,000 tail steps agree. `replay-01` passes current
version5 derivation verification and authentic versions1–4 again.

Its genuine checked workflow builds successfully, but `validation-001` finds
21/22 passes: the newly appended long-string test fails after the preceding21
cases in the persistent worker. Root then runs the identical22-case history on
the frozen Phase11 version4 baseline; it also fails21/22. The independently
maintained A-only candidate has the identical failure, although it passes twice
in fresh isolated workers. This is an existing history-sensitive4MiB resource
limit, distinct from broad B's proven fresh-worker regression. All failures and
consumed selections are retained. Root preserves the appended and reordered
selections plus rationale in `focused-stack-order-01`. The corrected selection
runs long-string first, then the original21 cases. Fresh `validation-002` of the
same unchanged checked leaf attempt passes22/22, with the same12 known exact
TypeScript differences. No stack increase or history-fix claim is made here.
This catches broad B's independently demonstrated fresh-worker failure while
keeping the existing persistent-history limit explicit.

Frozen handoff helper SHA-256 is
`84a065f61b9c6c6c1ebd8cdfe10dca1a8017f40d19302a84515e1c3a2cc356d9`;
tests SHA-256 is
`bec05fd9da87ebd2bc3640bb4292b70ed5fd32bef94222ad2ab820375b03c615`.
Against Phase11 this adds23 helper lines (273→296) and5,802 bytes
(21,543→27,345); tests add37 lines (170→207) and4,368 bytes. The narrow grammar
reduces semantic scope, but the extra call-recognition obligation still has a
maintenance cost. The report's original bounded-gate and simplicity-decision
versions are preserved before each update.


The final leaf handoff is ready for root integration: exact checked API b132e103,
22/22 focused observations,16 maintained groups and five current/historical
replay checks pass. The first22-case validation failure remains alongside the
fresh passing validation. Root still owns the unchanged broad frontend and
backend gates, controlled comparison, and final release decision. There are no
further owned compiler jobs or changes to the frozen helper/tests.


## Final integrated leaf derivation gates and guard review

Root copies the exact frozen leaf helper/tests into production and builds
`integrated-02`. Its focused gate passes22/22. `final-derivation-tests-02`
then runs all16 groups against the final genuine checked parent and live files,
asserting the live helper/test identities equal the checked snapshot. Every
group passes; `final-replay-02` passes current version5 and authentic versions
1–4 replay again. The final selected API remains b132e103. The root baseline
also passes the same regression-first22-case history in `baseline-focus22-first-01`.

`final-derivation-tests-02/guard-review.json` records a fresh post-integration
coverage review by this implementation owner, distinct from root and earlier
separate-agent reviews. No blocking finding remains in the admitted finite
generated/public-forced domain. The review checks that exact profile/runtime,
body and public export validation precede lowering; protected names cannot be
rebound; nested/nonterminal/optional calls keep their closure boundary; Unit
bindings, captures, effects, demand and public arity are covered; and historical
lineage remains exact. It explicitly retains the persistent-history stack
limit and excludes arbitrary JavaScript, reflection/hostile prototypes, and
private unforced message identity. Sixteen groups do not replace root's broad
frontend/backend gate or controlled measurements.

All owned compiler and replay jobs are closed after these passing final gates.


## Broad integrated02 failure: matched history blocks promotion

The broad `frontend-02` gate rejects integrated02: only long-string checking
changes, while the other2,995 observations remain exact. Root requires matched
history attribution rather than weakening or relabeling the gate.

`call-prefix-replay-01` verifies the retained original request/session prefix
integrity, Node identity and all original input identities, then replays the
same53 requests through long-string at index52 for Phase11 baseline, current
leaf and A-only. It uses the unchanged persistent worker, byte-identical
adapters/hosts, identical4MiB stack/4GiB heap and per-image validated Base caches
in private projects. Only the compiler/cache/project/output identities are
substituted and recorded. Any crash, timeout, unexpected worker recycle, input
drift or pre-target result difference aborts attribution.

All52 earlier results are byte-exact for all three variants. The Phase11
baseline passes the target; leaf and A-only both fail with stack overflow.
Thus this is an observed release regression under matched request history,
not a failure that can be waived as an inherited history-sensitive boundary.
The earlier first-case22 gate and final16/replay tests remain true but were
insufficient to establish the full resource contract. Promotion stays blocked.

Root also requests the original passing Phase11 worker prefix:60 requests with
long-string at index59. Its passing request directory was pruned, so
`call-prefix-input-01` reconstructs the request from the integrity-bound session
entry plus its recorded prefix digest. This reconstruction is explicit and must
pass the unchanged replay validator before `call-prefix-replay-02` runs.


The original passing Phase11 prefix gives the same decisive result in
`call-prefix-replay-02`: baseline passes; leaf and A-only fail. All59 preceding
observations are byte-exact for each image. This independently reproduces the
regression using both the current failing and historical passing histories.

`call-prefix-current-v4-01` then uses the final Bend source with explicit
version4 lowering only. Its image is checked byte-for-byte against the version4
transformation of integrated02's genuine checked parent before replay. It also
fails the same53-request current prefix, while all52 preceding observations
remain exact. Thus call lowering is not required for this warm-history failure:
the Bend source changes, or their effect on generated-code resource behavior,
already suffice. Root/normalizer-owner seed-only and JS-only controls will
separate those source changes. This attribution is distinct from broad B's
separately established cold/fresh-worker regression.


The normalizer owner's `normalizer-prefix-replay-01` completes that isolation:
seed-only version4 fails the same target; JS-only version4 passes. Both replay
all52 preceding observations exactly. The seed cleanup alone is sufficient for
the warm-history regression and should be removed before reconsidering leaf.
This does not erase the broad-B fresh-worker ablation: under its fixed final
source parent, v4/A pass while B fails. That was a conditional resource result,
not a claim that broad B fails under every possible source. No broader B retry
is proposed; root can validate the already narrowed leaf with the seed removed.


## Final no-seed choice and independent broad rejection

Root restores the original normalizer source while retaining the JS source
improvement and narrowed leaf helper. Genuine `integrated-03` has checked parent
`a8453133f37a0965b7291795af2e06c7c65e3ee7c97a8ff4b14b98cfba2e5568`
and selected API
`0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697`.
Its22 focused cases pass. `call-leaf-noseed-prefix-01` passes the exact current
53-request history and `call-leaf-noseed-prefix-02` passes the original60-request
history. All52/59 pre-target observations are byte-exact, with the same4MiB
stack,4GiB heap and separately validated caches. The two historical60-request
reports retain a copied53-request scope label from the first tool; their attached
`scope-note.json` files correct that label using the actual full request arrays
and target index59. No requests are omitted or original evidence rewritten.

One bounded confound check tests the original broad transform without the seed.
`call-broad-noseed-01` uses the original frozen helperdbfc09f0, verified by hash,
to derive from the genuine JS-only checked parent; original bootstrap lineage
and exact derivation replay pass. Resulting API is
`cf9ec225e2e0fa1026152c21d11e13b7b66abc303068869621de97f3fd39dc53`,
with1,197 returned branches. After explicit private Base preparation,
`call-broad-noseed-fresh-01` fails fresh long-string checking with stack overflow.
`call-broad-noseed-prefix-01` independently fails the same53-request history,
with all52 predecessors exact. Broad inlining therefore remains rejected even
without the seed. The original live leaf helper is not changed during this
confound, and no broader optimization or timing is attempted.

`final-derivation-tests-03` passes all16 maintained groups against integrated03's
actual checked parent and the live helper/tests, whose identities equal its
snapshot. `final-replay-03` passes current version5 and authentic versions1–4
replay. The final guard-coverage conclusion remains limited to the finite
reviewed generated/public-forced domain; root's full frontend/backend and
controlled comparison remain required. All owned compiler, replay and report
producers are closed after these final passing gates.
