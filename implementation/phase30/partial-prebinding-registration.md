# Partial prebinding registration cost investigation

The isolated generic and fused matcher variants pass the semantic gates below.
A drifting initial screen favors generic application; confirmation is pending.
Neither variant is a maintained runtime change. The final14
original-program matrix raised a release blocker because several generic programs
regressed against Phase29; these tests do not yet attribute that regression.

The [design](../../design/phase30/partial-prebinding-registration-ablation.md)
separates two hypotheses. Generic delayed application removes matcher1p entry
registration and prebinding, returning the original literal-arm bounce. Fused
registration retains permission exactly, but exposes the unchanged matcher body
through a literal destructured-parameter IIFE inside the fresh public arrow.
It removes shared enterExact dispatch for this callback only. Neither changes
emitted definitions, ordinary apply, scalar workers or guards. The independent
ordinary invokeExact inlining and actual-method-read variants remain separate.

Partial arity is insufficient to skip permission safely. The old retained
`selfhost/build/phase30/review-prebind-entry-01/report.json` already uses two fields
and a three-argument arm: eager field copying moves a foreign slice before outer
copied-length effects and changes raw callback bounce shape. Generic application
therefore restores the complete original delayed application; it does not merely
return a prebound partial on every invocation.

`review-prebind-generic-derive.py` acquires checked actual14 emissions, verifies
the selected attempt/API/runtime/Base/driver/input and prospective design, saves
all three modules and cores, and proves exact inverse edits with an unchanged
generated suffix. Frozen outputs are:

- `selfhost/build/phase30/review-prebind-helper-01`
- `selfhost/build/phase30/review-prebind-editdist-01`
- `selfhost/build/phase30/review-prebind-mandel-01`
- `selfhost/build/phase30/review-prebind-row-01`

Each directory contains `baseline.mjs`, generic `candidate.mjs`, registered
`fused.mjs`, core copies and `derive.json`. The row uses the new checked14
`runtime-row-source-14/candidate.mjs` receipt and exactly the canonical owned-row
fixture used by all release-regression variants.

Independent semantic observations on CPU6, with no timing claim:

| Gate | Result | Raw evidence under selfhost/build/phase30 |
|---|---:|---|
| Original-reference, current, generic, fused runtime controls |97 pass; generic/current also identical |review-prebind-variants-02/report.json |
| Retained raw/exact/partial/oversaturation/slice/call-hook witnesses |7 per each of3 cores |review-prebind-{baseline,candidate,fused}-entry-01/report.json |
| Full helper ABI, metadata, coercion and primitive-prototype controls |146 per candidate, plus72 scalar observations |review-prebind-{candidate,fused}-scalar-01/report.json |
| Exact-entry reentrancy and restoration |9 per candidate |review-prebind-{candidate,fused}-token-01/report.json |
| Foreign record/tuple vectors, copies, errors and public descriptors |33 per candidate; live G replacement also agrees |review-prebind-{candidate,fused}-cell-01/report.json |
| Complete original editdist and Mandelbrot outputs |6 observations;2065873279 and887240761 |review-prebind-programs-01/report.json |

The initial new harness failed at `short/exact` because its returned observation
retained a live Proxy bound vector; deep comparison itself invoked its length
getter and mutated the stored event list. The complete failure and consumed
harness remain in `review-prebind-variants-01`. The corrected02 harness snapshots
that public bound vector before comparing, preserving all runtime actions. It
passes97 cases, including source fields whose custom slice returns zero, exact
arm arity or excess fields; malformed noniterable callback arguments; callable
kind; saved partial hooks; and iterator/slot/environment/slice reentry.

Ambient Object.prototype observations are recorded separately. The first24
cases are in `review-prebind-prototypes-01`; the prospectively extended36 cases
are in `review-prebind-prototypes-extra-01`, with their separate
[throw-threshold plan](../../design/phase30/partial-prebinding-prototype-throws.md).
Every generic trace equals the literal matcher1 reference, and every fused trace
equals current14. Generic/current differ on io and typeName hooks:

| Hook | Original/generic | Current14/fused |
|---|---:|---:|
| io, nonthrowing |6 observations, result31 |4 observations, result31 |
| io, throw on fifth observation |original sentinel error |result31 |
| typeName, nonthrowing |3 observations, result31 |2 observations, result31 |
| typeName, throw on third observation |original sentinel error |result31 |

The generic variant restores original delayed arm-application behavior here.
These differences are not a reason to preserve the earlier elision. Global
prototype mutation lies outside the frozen stable-intrinsic optimization scope,
so this is specific evidence of restored observations, not a claim that all
ambient intrinsic mutation is now supported. Request/bounce/build/code hook
observations agree in this minimal probe. All97 ordinary foreign-vector/ABI cases
also agree with current14, and neither variant has a supported-scope discrepancy
in these controls.

The prototype owner separately runs the full four-array row oracle and retained
alias/boundary harness across all isolated runtime variants. Phase29 participates
in numeric comparison while its earlier known scheduling defects stay explicit.
Timing and promotion remain parent-owned decisions; no runtime/compiler source
has been edited for these ablations.

The prototype owner's row gates now pass: `runtime-row-boundaries-abc-01` and
`runtime-row-boundaries-fused-01` each retain28 full-state oracles,16 alias checks
and257 ordered/public observations with no changed traces. The separate
seven-way numeric comparison passes196 observations. These are executions by
the prototype owner, not additional independent reviewer executions.

The first clean row screen at `runtime-row-screen-01` is encouraging for generic
B: current14 median0.870054 ms, generic0.685677, fused0.842583 and Phase29
0.674038. These are screen observations only. Opposing within-sample movement
is extreme (roughly−43–45% for29/generic and+46–50% for14/fused), so this window
cannot establish a settled gain. The lead has granted the separate seven-way
confirmation; it is pending here.

The conditional [source retirement proposal](../../design/phase30/retire-arm-prebinding.md)
would remove58 lines/eight compiler functions, one manifest entry and the small
runtime compatibility bridge after the runtime-only release repair. It covers
both ordinary arms and the shared scalar Nat/tree successor wrapper, keeping
actual worker exact-entry permission. It is unimplemented and conditional on
measured benefit, with structural emitted-AST equivalence planned separately.
