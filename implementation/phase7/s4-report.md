# S4: declaration and frontend consolidation

Status: **validated bounded checkpoint installed**; the 50% milestone is **open**.
The current source is 14,667 physical / 12,505 nonblank lines and 470,062 bytes:
1,842 physical lines (11.16%), 1,298 nonblank lines (9.40%) and 39,875 bytes
(7.82%) below the original baseline. All functionality targets and known gaps
remain. S5–S7 have not started; there is no funded route to the required further
6,413-line deletion yet.
[The design](../../design/phase7/s4_frontend_book_consolidation.md) and both static
inventories were committed/pushed as `335737d` before implementation.

## Starting point and accounting

The starting S3 compiler was 15,687 physical / 13,093 nonblank Bend lines and
486,768 bytes across 59 modules. It has 1,450 definitions, 1,222 laws and 61
datatypes. The original baseline is 16,509 physical lines. Reaching the 8,254-line
milestone still requires 7,433 lines; audited local opportunities do not fund it.
Physical lines, nonblank lines, bytes, declaration coordination sites and any
new host/tool code are counted separately. Blank separators earn no conceptual
credit. No compiler logic moves into the host.

## A: redundant forward declarations

Planned trial: convert only the 425 fixed-order candidates already supported by
existing typed-definition syntax; preserve binder names/order/types/quantities,
return types, exact bodies and standalone unsafe markers. Keep all genuine
forward declarations and the assembler unchanged. The first pilot is the 34
eligible pairs in `core/term.bend`, checked before widening the edit.

Source candidates and tools are isolated under `selfhost/build/phase7/s4/`.
The S3 release stayed untouched during candidate validation. Failed attempts,
actual counts and the final integration decision are preserved below. Static
budgets and proposed tests are never counted as results.

## Remaining phase gates

The new source form needs actual Bend frontend/checker coverage and genuine
checked self-reproduction. A selected API that happens to remain byte-identical
can inherit the previous API's behavioral evidence, but cannot establish that
new source form's self-reproduction. Later loader/error/helper consolidation is
sequentially dependent on accepting or rejecting A. The 50% milestone additionally
retains the full source, backend, relocation and performance gates in the design.
No new whole-compiler TypeScript comparison is established here. Native smoke
and A's checked fixed point are recorded below; broad GPU execution remains outside
the available hardware evidence.

## First measured source-edit results

The audited one-off migration completed without changing the main source. The
34-pair pilot removes 69 physical / 35 nonblank lines and 597 bytes (34 separators).
The full 425-pair candidate is **14,853 physical / 12,666 nonblank lines and
474,549 bytes**: 834 / 427 / 12,219 removed, including 407 blank separators. It
retains 797 laws and has 2,308 compiler declaration events. The source-editor
tool costs a separate 179 lines / 9,109 bytes and is not part of any compiler build.
See the [pilot migration](s4-evidence/pilot-migration.json) and
[full migration](s4-evidence/candidate-migration.json).

The [core pilot](s4-evidence/core-pilot-result.json) passes pinned upstream checking
and both existing normalization and persistent-index suites for each source form.
The selected seven-export APIs are byte-identical. This is a four-module component
gate, not yet the full-candidate or self-reproduction gate.

## Rejected full candidate and bounded correction

The first full checked candidate (`attempt-a01`) passes all 21 focused cases,
with the same seven known exact diagnostic differences. It is nevertheless
**rejected**: artifact comparison found two missing exports, `j_layout_error` and
`annotate_selected`. The unchanged bootstrap host discovers those capabilities
by searching for their literal law headers. Converting the declarations silently
disabled those roots, so its smaller API is not a valid simplification. The
[failed identity comparison](s4-evidence/artifact-identity.json), candidate and
original migration-tool bytes are preserved. No release was installed.

The corrected candidate retains both law/fill pairs. The independent audit found
one other law-header probe, `j_program_selected`, whose law was already retained.
It converts **423 pairs** and reaches **14,857 physical / 12,668 nonblank lines /
474,656 bytes**, removing **830 / 425 / 12,112** respectively. Of the physical
reduction, 405 lines are blank separators; 11,707 bytes remain after excluding
those newlines. Both nonblank and byte acceptance thresholds still hold.
The host and assembler remain unchanged; no new capability-detection rule is added.

The frozen genuine S3 compiler parses, loads and checks both four-module core
source forms successfully. All twelve tiny before/after declaration controls
also pass against pinned TypeScript and S3, covering trailing commas, dependent
erased binders, affine/unrestricted quantities, unsafe kind rules, recursion,
mutual forward laws and invalid syntax. Positive normalized signatures, quantities
and unsafe flags match. Raw declaration order is intentionally not an equality
claim. The first control-runner attempt stopped on sandbox `spawnSync` EPERM
before any compiler observations and is retained separately.

## Corrected candidate gate

`attempt-a02` passes the fresh checked build and all 21 focused observations,
with the same seven known exact diagnostic differences. Its checked API, optimized
API, runtime, driver, ABI and assembler are **byte-identical to S3**, and all
55 selected exports remain in the same order. See the
[corrected identity comparison](s4-evidence/artifact-identity-a02.json). The
[independent review](s4-evidence/a-independent-review.md) also extracted and
compared all 1,450 function bodies, unsafe markers and definition order.

These identities allow reuse of S3's component, full frontend and runtime evidence
for the generated compiler. They do not replace checking the new compiler source.
The genuine checked self-reproduction run **passed** on A02. Fresh checked B1
emitted H, and actual H compiled the same frozen source to a byte-identical
1,078,529-byte module, SHA256
`f322353996820096a07dd329efc41b4c25f1ceabd31e6467d5fcd5df49f455d8`.
Both stages checked the source and verified their inputs. Stage durations were
619.859 and 1,342.088 seconds; these are proof-run durations, not a controlled
TypeScript comparison. The unchanged maintained runner used CPU 0, 12 GiB heap,
4 MiB Node stack, 40-minute stage deadlines and a 55-minute outer deadline.
Neither the optimized API nor a previous H was substituted. See the
[launch and verification record](s4-evidence/self-reproduction-a02.json).

## B: shared frontend operations prepared in isolation

The [B design](../../design/phase7/s4b_shared_frontend_operations.md) was committed
and pushed as `86630a2` before its source edit. A's new source had passed complete
Bend checking; its fixed-point proof subsequently passed on immutable inputs.
B remained isolated until its own build, broad gates and controlled costs passed.

The actual edit removes 17 helpers and shares two algorithms. Restoring forward
laws for `fpe_term` and `fpe_defs` costs four physical lines; the disabled-seed
ordering comment costs one. After all replacements, B01 is **14,667 physical /
12,505 nonblank lines / 470,062 bytes**: **190 / 163 / 4,594** less than A02. It
has 1,433 definitions and 789 laws. The 48 new lexical dependency edges include
three forward references, all declared. The two bootstrap capability laws remain.
See the [patch](s4-evidence/b01-shared-frontend.patch) and
[counts](s4-evidence/b01-source-counts.json).

A new cross-version boundary test has passed its baseline-versus-itself setup
check with 58 rows / 626 counted comparisons. This initial run was a test-fixture validation,
**not a B01 correctness result**; the later cross-version gate is recorded below. It covers whole raw/parsed books and traces,
real versus unused/stale/disabled seeds, deliberate direct-API selection sentinels,
mismatched cached parse payloads, partial failures, namespace/cycle precedence,
law/fill name order, empty Error children and input immutability. Original test
bytes and both smoke attempts remain in the S4 build area.

## Architectural limits

The [remaining architecture review](s4-evidence/remaining-architecture.md) and
[global continuation census](s4-evidence/continuation-global-audit.md) find useful
further bounded work, but no funded route to 50%. Deleting entire required
passes with no replacement would still miss the target; their real replacements
are substantial. Typed tag dispatch is a worthwhile conceptual/byte hypothesis,
but replacing existing densely written branches with ordinary matches does not
automatically save physical lines. These are research limits, not proof that a
better compiler is impossible. S5–S7 remain gated by the actual milestone.

## C: continuation fusion rejected before source changes

The [C design](../../design/phase7/s4c_continuation_fusion.md) was committed and
pushed as `1187708` before its independent syntax review. That review invalidates
its assumed replacement: Bend does not allow matching a local binder or a computed
expression, including computed constructor destructuring. Fourteen of the
seventeen selected helpers therefore cannot be fused as proposed. The remaining
three offer only 23 estimated nonblank lines, below the planned 100-line gate.
All seventeen remain. No parser change, replacement framework or percentage
credit is introduced. B01 is the final bounded S4 candidate for validation.

## B01 correctness integration

The frozen B01 checked build and all 21 focused observations pass, preserving
the seven known exact differences and the ordered 55-export interface. A
conservative generated-function comparison finds 47 public dependency closures
unchanged and eight requiring the fresh frontend gates. The new whole-result
loader/error test passes all 58 rows / 626 comparisons across A02 and B01.

All 19 maintained component groups and 52 host/harness tests pass. The first
isolated component run stopped at the seeded-loader fixture because no installed
`dist/base.bend` existed in that temporary project; it is retained. A fresh run
with explicit pinned `BEND_BASE` passes. Fresh genuine eight-root API builds
pass the 530 provenance comparisons; the end-to-end diagnostic test passes its
204 assertions. Neither focused API is presented as a new full bootstrap.

The frozen candidate host also passes check, interpreter, JavaScript and native
CPU execution of the maintained Base/U32 smoke fixture, with exact expected
output. Native execution uses the independently verified local Clang 19.1.7
toolchain documented in [the toolchain evidence](s4-evidence/clang/). This is
a native smoke, not new broad backend or GPU conformance. Full frontend and
controlled host and graph-cost results follow.

## Exact frontend preservation and host cost

The full B01 frontend run produced all 2,756 observations with healthy workers
and no observation differences from S3. It includes 919 positive and 459 negative
check fixtures; the **318 existing strict failures remain**. Its exit code is
therefore 1, as required by the strict conformance runner. The separate
[preservation comparison](s4-evidence/frontend-comparison.json) passes without
diagnostic normalization or trading regressions against improvements.

The serial A02/B01 host comparison ran after correctness jobs stopped, using the
same frozen host, real 60,909-byte core source, canonical Base, runtime, equality
profile, CPU 0 and separately validated API-specific caches. Every generated
output and rejection matched. All six opposite-order pairs pass the 5% time and
10% memory guards: accepted request overhead 0.21–1.04%, early rejection
1.07–1.53%, late rejection 0.54–0.98%; maximum paired peak-RSS increase 0.71%.
The selected API is 1,023,803 bytes versus 1,030,277 (0.63% smaller). This is a
small simplification cost, **not a speedup**. See [raw host samples](s4-evidence/host-performance.json)
and [explicit guards](s4-evidence/host-performance-guards.json). No new full-source
TypeScript ratio is inferred.

The separate ordinary-loader experiment also passes: two serial ABBA blocks
per raw/parsed mode, 16 fresh workers, three warmups and five measured requests
each, fixed CPU 0. Entire graph and trace outputs match before timing. Median
raw load overhead is 1.94%; parsed load overhead is 2.63%. Median peak RSS grows
0.37% and 0.29%, respectively, within the 5%/10% guards. Every sample, including
a slower parsed candidate sample, is retained in the [graph report](s4-evidence/graph-performance.json).
Only small documentation/review activity occurred alongside controlled samples;
no other intentional compiler/benchmark job ran. The design commit during the
graph run printed Git's automatic housekeeping notice; no claim of an otherwise
idle machine or statistical significance is made.

## D: shared-helper ownership

Independent review found that B01's parser context pulled in the whole normalizer
solely for generic concatenation. The [D design](../../design/phase7/s4d_shared_helper_ownership.md)
was committed and pushed as `f94591c` before its source edit, which began after
controlled measurements finished. B02 moves the unchanged two helpers and one
existing law into `core/term.bend`, beside `KTerm`/`KDef`. Exactly 24 physical /
21 nonblank lines / 396 bytes move; all production totals stay unchanged.
This removes the parser-to-normalizer dependency and earns zero deletion credit.
The fresh checked build and all 21 focused controls pass. Checked API, optimized
API, runtime, Base, all five host helpers and the ordered 55-export interface are
**byte-identical to B01**; the [identity gate](s4-evidence/b02-artifact-identity.json)
passes. B01's observations and cost measurements therefore apply to the exact
installed compiler bytes. B02 retains its own source/bootstrap/derivation records.

## Final release and complexity accounting

The installed B02 release verifies and passes all eleven integrity/ordinary-use
observations, including check, interpretation, JavaScript and CPU-native execution
from a manifest-driven relocated package **without an upstream checkout**. See
[release smoke](s4-evidence/release-smoke.json). The maintained release verifier
checks exact source, runtime, host, checked-parent and transformation identities.

| Installed identity | SHA256 |
| --- | --- |
| Assembled B02 source | `75a2de1e9fd7ff995d164eb51594c826091bce92430b09fcd0db9732675880cb` |
| Genuine checked B1 | `f201bdea7ea4041483b40704f622703945858e981c404a4d7e50979b74370110` |
| Default equality-derived API | `9826ac8f2cb2ad17ab07d7a1f3fcefc701c64cd44d3c50333b3410d761d98b7f` |
| Unchanged runtime | `26f5eee2f54b194b64f768df6ff505c67bf7a5df2159aa06caf53ecba54e910b` |

S4 removes 1,020 physical / 588 nonblank lines / 16,706 bytes from S3. Of the
physical saving, 432 lines are blank separators and earn no concept credit.
The current compiler has 1,433 definitions, 789 laws and 61 datatypes in the same
59 modules. The large language responsibilities and public representations remain.
A removes 423 redundant two-site declaration obligations. B retires two duplicate
algorithms, eight duplicate utilities and one unused checker projection, totaling
17 private helper interfaces. The new disabled-seed invariant and graph/seed and
frontend/error ownership dependencies are explicitly charged; these are modest
mechanism reductions, not a claim of 17 fewer language concepts. D removes the
unnecessary parser-to-normalizer ownership dependency without moving any compiler
logic into the host. Independent [B review](s4-evidence/b-production-review.md)
and [D review](s4-evidence/d-ownership-review.md) record the reasoning and limits.

The original-context recount retains every original task file and charges moved
owners. B01's parser source-owner context grew; D reduces that source-owner set
to 5,418 physical / 4,693 nonblank lines / 196,578 bytes versus original
5,716 / 4,851 / 198,816. With the new shared-operation control included, it is
5,560 / 4,834 / 209,145: **bytes grow**. Adding the new provenance integration
control gives 5,687 / 4,958 / 218,720, with only 29 fewer physical lines and more
nonblank lines/bytes. The task sets overlap, are whole-file proxies and must not
be summed. There is no uniform reduction in review context or measured cognitive
complexity. Original [B01 counts](s4-evidence/context-counts.md) remain immutable;
the [separate D recount](s4-evidence/d-context-counts.md) records ownership and
validation supplements.

New validation material is charged separately: the maintained shared-operation
test plus top-level one-off migration/validation programs add 827 physical /
801 nonblank lines / 62,670 bytes at the recorded cutoff. The test itself is
142 lines / 12,567 bytes; historical tools and generated evidence are separate.
See [exact auxiliary membership](s4-evidence/auxiliary-source-counts.json). Thus
the repository's total line count is not claimed to decrease. None of these
one-off programs is part of ordinary compiler operation.

## Decision and remaining phase boundary

Promote A+B+D as one usable checked release; preserve rejected A01 and C evidence.
Do not claim a new whole-source TypeScript ratio, a B02 H fixed point, fewer
conformance failures, broad new backend coverage, or the 50%/75% milestones.
A02's successful fixed point is specifically the declaration-source proof.
The final-source fixed point and the larger milestone gates remain required if
a future candidate actually reaches that milestone.

The audited local work is exhausted at this checkpoint. The remaining whole-pass
budgets do not fund another 6,413 net lines, and the proposed helper fusion fails
the current language's syntax. Advancing to S5 merely to satisfy the schedule
would violate the approved milestone gate. The next S4 work needs a concrete
architectural replacement with its own cheaper falsifier and net deletion budget;
formatting, hidden host code, removal of language functionality and relaxed tests
are not substitutes. The overall simplification program is **not complete**.

## E: controlled development-loop confirmation

The [final loop plan](../../design/phase7/s4e_iteration_cost_gate.md) was committed
and pushed as `f29c56c`, with its measurement setup correction as `999c9e7`, before
the successful run. The first launcher could not find `/usr/bin/time` and stopped
before compiling. Its exact script, command and incomplete result are retained.
The corrected method uses one fresh Python worker per process tree and Linux
child-process resource accounting; it does not modify the compiler. The reported
RSS is the largest waited-for process high-water mark, not the simultaneous sum
of the process tree. Independent review also found that the one-off wrapper's
kill-group timeout branch cannot guarantee cleanup of the workflow's detached
child groups. No timeout occurred: all four attempts finished normally within
the intended limits. Preserve that limitation; this archived runner is not a
reusable maintained supervisor.

Four completely fresh maintained checked/equality/focused attempts run serially
on CPU 0 in S3 / S4 / S4 / S3 order. Each checks the expected compiler identities,
55 exports and all 21 focused observations with the same seven exact differences.
Whole-loop times are about **35 seconds** for each version. Opposite-order paired
S4/S3 wall ratios are 0.99289 and 1.00723 (−0.71% and +0.72%); peak-RSS ratios
are 1.01934 and 1.03298. Both 5% runtime and 10% memory guards pass. This supports
**unchanged iteration speed**, not an improvement inferred from earlier unpaired
timestamps. No other intentional compiler, archive-compression or Git operation
overlaps the four measured attempts. Full source-versus-TypeScript timing and H
self-reproduction remain different workloads. See the [complete loop report](s4-loop-evidence/report.json) and
[independent review](s4-loop-evidence/loop-review.md).

The additional measurement and preservation programs are separately inventoried
in [loop source counts](s4-loop-evidence/source-counts.json); they are one-off
evidence tools, not runtime dependencies.

## Evidence preservation

The original [raw capsule](s4-evidence/raw.tar.gz) is 31,014,381 bytes, containing
10,268 files / 403,460,958 uncompressed bytes. Every member was read back and
verified by SHA256 against the [manifest](s4-evidence/manifest.json). It includes
the rejected 425-law candidate, exact tool versions, successful proof outputs,
source snapshots, full frontend vector, fixtures, performance workers/samples,
release/relocation inputs and setup failures. Archive SHA256:
`571e68d28cf21aacfc4dc98713c2e0e73299bdeccd5d91fddec8c5ace586ae55`.

The final loop's failed setup and four fresh measured attempts have a separate
[capsule](s4-loop-evidence/raw.tar.gz) and [read-back manifest](s4-loop-evidence/manifest.json).
The original capsule is unchanged. Pinned upstream and Node are identified by
revision/content hash; local Clang package metadata and its reproducible install
recipe are [preserved separately](s4-evidence/clang/). Historical performance and
conformance claims remain attached to their recorded artifact identities.
