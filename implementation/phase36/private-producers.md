# Private producer investigation

Status: source inspection and saved-output discriminator prepared; no execution
or production changes by the owner. Root owns all bounded execution.

The generated symreg private cand root still calls generic gen. Public gen has a
Nat matcher, nested fn callbacks, two recursively curried calls and generic node
and gen.leaf calls. Existing eval/esize private folds have already removed their
matching dispatch. The pinned source has depth-dependent output rather than
observable effects; gen's two child computations occur in left-to-right nested
lets and the node opcode uses the parent seed after both complete.

The saved-output producer reads only checked09 module SHA256
`dd400df33dc3acbf50c781778a85eb8960bdd065d40a5bf6cffde0009bb3ad26`.
It leaves the full benchmark and public generic definitions unchanged. Its first
variant removes gen recursion and PRNG generic calls but retains node/gen.leaf;
its second additionally lowers those finite choices. The explicit frame loop is
unbounded in implementation depth and retains exact BigInt counters. Feasible
complete outputs at depths0–8 exercise the diagnostic entry; the design explains
why deep binary output is not an appropriate stack test.

The derivation creates inherited Phase35 sum controls with provenance labels and
variant labels updated. Additional assertions check complete diagnostic trees,
actual cand producer admission and refusal after gen descriptor mutation. It
writes a distinct output directory and never updates closed Phase35 evidence.

[Design](../../design/phase36/private-producers.md) and
[experiment](../../experiments/phase36/P36-002-private-producers.md).

The proposed real compiler change is
[producer-source.patch](producer-source.patch), with the complete new module in
[producer-proposed.bend](producer-proposed.bend). It adds107 Bend lines and hooks
the existing private helper selection/declaration/host-guard paths. It performs
an independent `JPure` graph proof before lowering; failed proof/planning rolls
back to the original ordinary helper path. No runtime changes are proposed.
The first source subset deliberately matches the generator-only discriminator.

[producer-fixtures.bend](../../selfhost/tools/performance/phase36/producer-fixtures.bend)
provides a general second program: different arithmetic/constructor order,
parallel and sequential two-child producers, parent-dependent combination,
shared child aliases and negative dependent-RHS/unary cases. The original fixture later failed its ownership check; corrected v2 sources
and their checked03 results are recorded below. The source proposal is not promoted merely because its
fixture compiles; emitted admission, independent results and unchanged original
symreg timing remain required.

Independent review also identified a separate scoped-guard issue: runtime
`bad` calls the mutable global `Error`. Nat overflow can therefore call host code
before a scoped proof's `finally` runs. The accepted guard implementation suspends the proof through Error
construction, with an actual overflow/mutation/reentry control. An identity-only
guard would miss mutable properties on the original Error constructor. The producer proposal
itself does not install a proof token.

## First actual saved-output controls

Root executed `selfhost/build/phase36/producer-controls01`: **106 oracle rows and
121 boundary observations pass**, complete=true. The controls include the
unchanged full symreg result, complete Sel fields, public producer outputs,
private producer depths0–8, generic-dispatch mutation/demand boundaries and
positive/negative cand admission counters. These observations establish the
saved-output discriminator's named scope; they do not validate the proposed
compiler recognizer or establish a speed gain. The raw acquisition remains under
Phase36 for root's final preservation.

## Clean mechanism screen and full-selector successor

Root's `producer-screen01` completes in10.75s with disjoint sample ranges:
baseline15.8691ms, generator-only10.9321ms, full producer4.19892ms, TS1.16612ms.
Thus full production is3.78× the Phase35 baseline speed and2.60× generator-only
on the original unchanged symreg point. These are saved-output mechanism values,
not an installed compiler release. `producer-clean01` excludes entry counters
from timing while preserving the instrumented correctness artifacts separately.

This justified the small [selector extension](producer-selectors.patch):10 net
Bend lines beyond the frozen107-line producer proposal. It threads remaining
arity through the existing finite-Nat plan and selects original closed-sum
constructors only inside a whole-JPure-proved private producer context. Bool
already supports trailing arguments. The [design](../../design/phase36/producer-selectors.md)
records grammar proof for the reserved marker, helper-cache replacement and
unchanged depth/fuel/member budgets. No new IR, runtime or cache is introduced.

Root's first general fixture acquisition failed in baseline checking because
`p.share` duplicated an affine binder. The original source and failed acquisition
remain. `producer-fixtures-v2.bend` marks shared/reused locals unrestricted;
`producer-selectors-v2.bend` similarly marks the duplicate child formal and the
reused scalar formal. Both are explicit successors; this is fixture correction,
not a relaxation of checking or optimizer admission.

The actual selector controls now capture the emitted private worker and retain
raw candidate identity. They require six actual direct helper bodies, entry and
mutation-refusal counters,243 complete/hash oracle rows including depth12,
shared-child identity and explicit context/field-admission refusals. Root's
checked03 build and final acquisition/controls determine real implementation
correctness; source inspection and the earlier mechanism are separate evidence.

## Actual checked03 results

Actual checked03 API
`93e55ad7ee456eebb5fa3dd9606c2cf262ea386c6f66bfd891ffe187d8f50a75`
passes the general and full-selector controls. The
[hashed evidence index](producer-checked03-evidence.json) records every raw report,
actual input identity and diagnostic-parent binding:

| Gate | Passed scope | Raw report SHA256 |
|---|---|---|
| producer-fixture03 |175 oracles,5 admission/refusal checks|`a3961b43e2f104c4337f641dcc9e21b9173c700fc0518f56fec5523093dd89c5`|
| producer-reviewed03 |108 complete trees,36 alias checks,9 actual entries,27 mutation boundaries,3 iterative structures|`3b2b9d2dcb1365abb5ae316910fa1d455a9b142a703c398b489e462f20495115`|
| producer-selector03 |243 oracles,10 admissions/refusals,6 active mutation boundaries|`8edf3110073619fc52c3db3ce726cc6a0118ffd1e96b7e7c7aecf19808781d6d`|

This includes actual direct node/leaf helpers, full tagged values, shared-child
identity, feasible depth12, first/final Nat selectors with observed remainders,
Bool argument positions, context/primitive-field refusal and positive entry
counters. Diagnostic copies expose the actual emitted helpers; they do not insert
a replacement algorithm. No diagnostic artifact is used for timing.

These results belong specifically to checked03. A later selected image needs
fresh owner binding and inherited integration; this checkpoint is not an implicit
final-release claim. Source review of the final owner closer is retained in
[producer-owner-close-review.json](producer-owner-close-review.json).
