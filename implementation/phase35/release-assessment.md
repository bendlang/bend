# Independent assessment of the selected Phase35 release

**Accept checked09 for this phase, with the compiler-time and code-size costs
reported explicitly.** The installed API is the same checked image used by the
completed correctness, owner, generated-program and compilation-cost gates:
`467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82`.
This assessment uses root's completed executions and independent read-only
identity/statistic checks; it does not introduce additional performance runs.

The [review receipt](release-review.json) rehashes all 225 original/frozen source
pairs, the installed API, final gate reports, 18 reports across 15 owner groups,
release launch outputs and the ordinary/relocated CLI receipt. The selected
manifest adds only `jpure.bend` and `fold.bend` at the previously frozen positions;
original module order, upstream pin and other manifest fields are retained.

## Correctness and installed usability

The completed successor preinstall audit accepts all 14 groups. The postinstall
audit accepts all **15/15**, including successful installation/verification and
**42 ordinary and relocated CLI checks** against the selected API. The broad
gates retain 3,026 main and 196 broader exact frontend outcomes, 36 focused and
15 upstream probes, 56,205 primitive scalar checks, 3,759 worker checks, 144 nested
checks, 1,129 primitive refusal guards, 23 generated libraries/127 points,
40 worker refusals/two execution witnesses, 22 component observations and the
complete 42-byte HVM demonstration output. These counts overlap and should not
be summed into a novel test-total claim.

Exact agreement is distinct from all fixtures succeeding. Main frontend outcomes
still include 497 observed cases and four shared failures; the broader set has
one observed case. Backend coverage is the selected **81 exact observations**:
69 passes, eight not applicable and four shared check failures. The phase does
not convert those failures to passes or establish comprehensive backend/GPU
conformance. The release manifest reports `newBootstrap: false`; installing this
checked image does not establish a new self-host fixed point.

Owner controls establish execution of the intended private paths and preserve
public argument/demand/mutation behavior. The new recursive-fold subset includes
675 independently modeled small result comparisons, 57 paired public boundaries,
24 recognizer cases and local depth 50,000 without native-stack failure. It remains
a deliberately narrow typed subset with generic fallback, not general arbitrary
tree or recursive-graph lowering.

## Performance judgement

The complete 600-second-budget confirmation finished all 15 selected generated
points in 518.338 seconds. The principal combined gains are **1.32× pair, 2.36×
fold, 6.87× symreg and 5.47× ray tracing**. They remain respectively 3.06×, 3.50×,
14.02× and 54.78× the TypeScript execution time. These are genuine selected
workload improvements, not a claim that all Bend programs now run faster than
TypeScript. [Performance admission](performance-admission.md) retains the complete
corpus, overlaps and null results; [profiles](profile-findings.md) separate clean
timing from sampled mechanisms.

The normal checked compiler costs matter to the user's iteration-loop objective.
All 36 fresh-process cost samples passed exact output checks, but request medians
rose by **0.72% pair** (overlapping ranges), **8.17% Mandelbrot**, **30.09% symreg**
and **34.40% ray** (the latter three disjoint). Ray's baseline also drifted 26.80%
from first to last sample, limiting precision. Complete modules grew 3.31–27.46%
on these normal request outputs. The [cost report](compiler-cost.md) preserves
imports, whole harness process time, RSS, raw samples and exact baseline-path
provenance; it does not hide those costs inside a runtime speedup.

This is an acceptable phase tradeoff because the two largest affected complete
workloads now save substantial execution time, and correctness gates closed on
the exact installed image. It is **not uniformly better for compile-once/run-once
workflows**. On fixed warmed symreg inputs, six complete calls would cover the
additional request time; one fixed ray call would cover its additional request
time. These are arithmetic illustrations across separate measurements, not
end-to-end observations. Mandelbrot has no established runtime benefit to offset
its slower compilation. Faster normal compilation should remain a measured
follow-up target, not be dismissed as negligible.

## Failed evidence and audit repair remain visible

The original owner launcher stopped when a TypeScript acquisition hit sandbox
`spawnSync git EPERM`. Its successor retained the failure and the first nine
successful commands, then reran only failed/downstream work. The complete owner
aggregate therefore has a documented retry lineage, not an erased failure.

The original preinstall audit also failed while traversing the immutable portable
baseline declaration: an acquisition-era canonical runtime path now refers to
the changed compiler. The successor recognizes only the exact hard-pinned
reference manifest, verifies its archive/producers/preparation receipts and the
historical Phase32 snapshot, then resolves those historical API/runtime/Base/
driver declarations to their frozen bytes. Candidate edges remain strict.
Independent static review found no blanket path/hash exception or weakened
semantic assertion. The executed successor closes before and after installation;
the initial failed audit remains preserved.

## Closure and next work

Correctness, selected performance admission and installed usability are closed
for this image. Evidence archiving and commit/push are separate root-owned final
steps; this review does not claim that ignored build files are already durable.
The [capsule receipts](evidence/README.md) record completed capture and verification.

The next experiments should target the changed bottlenecks: symreg's generic
producer consumes 64.33% of candidate CPU sample ancestry, and repeated ray
guards consume 47.24%. Carry one proved private boundary farther through those
graphs while keeping public mutation fallback. Investigate cheap proof-result
caching and pruning of unreferenced private helper bodies alongside these
changes, so execution gains do not keep increasing compile time and output size.
