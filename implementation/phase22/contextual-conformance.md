# Phase22: one contextual frontend

Status: installed and validated. The final compiler has zero exact differences
on the complete pinned frontend inventory and the acquired neighboring controls.
The final cost screen passes; preservation status is recorded separately in the
[Phase22 evidence index](context-evidence/README.md).

## Result and scope

The target stays `b2111cf43244e65f76ddc278ee695e669f720cbf` (Bend2 2.0.32 era).
The installed source is `context-source-17`, checked attempt `context-build-16`.
Its genuine upstream-checked B1 is `9cf01096f395817470ef0515e0ee98da85a53eb1b05823c88c9f2d5531e6072a`.
The retained guarded version5 equality derivative is
`ade8ef020e439b81ecb53057b33a473c34a3cbd993b98a044121ecc3c2b8c9c3`.
These are distinct artifacts. This work establishes neither a new self-hosted
fixed point nor independent proof-kernel validation.

| Evidence | Final result | Change from Phase21 |
|---|---|---|
| Full pinned frontend, 1,498 fixtures / 2,996 parse/check observations | 2,996 exact | Last two do-block diagnostic differences closed |
| Existing broader parser selection, 196 observations | 196 exact | 57 gained; zero lost |
| Independently acquired public controls, 154 +22 observations | 176 exact | Actual lexical scope, group completion, syntax priority, arrays, rewrite, do, eager/deferred materialization |
| Independent check/interpreter/JavaScript/native selection | 36 exact | Four previously different observations closed |
| Direct completion worker controls | 17/17 | Exact error demand, beta reduction and origin contracts |
| Maintained checked-build validation | 36 strict exact | Passes on final host and source |
| Actual `--checkup` comparisons | 4/4 exact | Import scanning and missing-file continuation match the pin |
| Integration selection | 198/198 exact | Complete results preserved |
| Original histories and fresh long strings | 226 paired +2 fresh | One prospectively pinned diagnostic correction; all other fields exact |
| Standalone frontend | 26 modules, checked component passes | Retained ordinary/traced/seeded text-source routes without checker dependencies |
| Installed and relocated CLI | 42/42 | Integrity, check, interpreter, JS and native execution |

These selections overlap. Counts are acquired observations, not a sum of unique
programs. Full frontend agreement is a finite tested result, not a claim that
all language features, platforms or arbitrary programs conform.

The raw main runner retains **1,494 check passes /4 failures**. The four fixtures
expect later-emission errors, and both frontends accept them at this earlier
stage. Its parse lane retains **1,001 passes /497 observed negatives**. The
separate196 runner retains its original `pass:false` aggregate with195 passes
and one observed negative. Exact result comparison is separately successful;
no expected output, raw verdict or comparison axis was weakened to manufacture
that result.

## Why the architectural change mattered

The old frontend parsed a mostly context-free representation, then reconstructed
scope, aliases and patterns later. Its grammar sometimes needed those answers
before parsing the following token. Fixing diagnostic locations alone could not
make an earlier semantic failure occur before a later syntax failure, and a
simple comma guard could reject a valid completed nested group.

The production parser now carries its real lexical environment, alias frame,
namespace and fresh counter. It validates patterns at the same checkpoints as
the pin, resolves simultaneous RHS expressions before opening their binders,
and retains the distinction between a completed body and syntax that can still
participate in tuple parsing. Source origins stay on their actual producers.
No empty-environment scoping pass or range-based completion guess remains.

One materializer implements the pin's two demand stages. The higher stage
handles eager ordinary children and beta reduction, while lambda bodies,
dependent codomains and let tails remain deferred. The lower stage forces those
children at the required boundary. Headers and bodies have different forcing
checkpoints; a later declaration must not hide an earlier completed-body error.
This is observable behavior, including which error appears first.

The same authority handles do-block monad lookup, rewrite motives, array size
and namespace rules, index desugaring, and computed-pattern diagnostics. A name
retains both its written-variable shape and resolved value where syntax needs
one and semantic completion needs the other. Absent beta-argument locations
inherit the bound occurrence's origin; real argument locations retain their own.
A nested App guard avoids inspecting an irrelevant deferred child's tag.

## Simplicity and host boundary

The old raw parsing/loading entry points, duplicate scope/alias replay, per-term
completion wrappers and98 unreachable frontend workers were removed. Those
workers occupied977 definition/law block lines; this is gross removal, not net
whole-compiler reduction. The loader accepts the completed-source ABI2 and
retains imported-law filling, declaration qualification and foreign-path work.
Its completed result is a trusted internal handoff, not authentication of an
arbitrary hostile IR graph.

| Canonical Bend modules | Phase21 | Phase22 | Delta |
|---|---:|---:|---:|
| Physical lines | 15,900 | 15,600 | −300 (1.89%) |
| Nonblank lines | 13,546 | 13,305 | −241 (1.78%) |
| Bytes | 577,159 | 580,464 | +3,305 (0.57%) |
| Definitions | 1,660 | 1,691 | +31 |
| Laws | 719 | 638 | −81 |
| Types | 67 | 68 | +1 |
| Modules | 59 | 60 | +1 |

The reduction is primarily architectural: one frontend authority replaces two
routes. Added contextual state and helpers mean this is not a decrease on every
numeric metric, nor achievement of the historical50%/75% reduction targets.
The [source census](context-source-census-cost17.json) preserves exact membership
and the retired worker list. The complete changed snapshot, including the host,
is293 lines shorter. This counts compiler source, not the experiment archive.

The host requires ABI2 and the complete entry-point set, without the old raw
fallback. It scans imports for `--checkup` in pinned textual order, prepares Base
once, checks each imported module independently and continues after failures.
Opening a missing import now produces the pinned filesystem diagnostic before
any module inspection. Ordinary compilation still runs Bend-generated code;
it has no TypeScript fallback.

## Cost and iteration speed

The first isolated change replaced per-element index-removal closures with a
named state worker. All51 direct order/duplicate/demand controls passed. Its own
exclusive comparison improved11.2124→10.4665 seconds, a6.65% process reduction,
with TypeScript at3.4425 seconds. That measurement belongs to the isolated
candidate and must not be substituted for the final combined cost.

The final comparison uses the same frozen Phase21 compiler source, pin, Base,
runtime, CPU0 and4MiB stack/4GiB heap limits. Fresh processes run in the order
TypeScript/baseline/candidate/candidate/baseline/TypeScript. Bend uses separately
validated Base caches; TypeScript checks Base. Request time includes lazy API
loading; process time also includes startup, hashing and output capture. The
host review proves exactly one of35 host files differs, so the attribution is
the complete usable compiler bundle, not isolated Bend code. Complete program
observations agree; only independently verified host identity is excluded.
Two samples per image are a controlled cost screen, not a statistical bound,
full-compilation benchmark or generated-program speed claim.

The first usable contextual bundle failed this gate. Its32.8% slowdown led to a
fresh CPU profile: recursive constructor lookup alone used11.26% of sampled
exclusive time, and repeated declaration checks added4.29%. The failed screens
remain separate, immutable observations:

| Bundle screen | Phase21 seconds | Candidate seconds | TypeScript seconds | Candidate process change |
|---|---:|---:|---:|---:|
| Initial contextual frontend | 11.1282 | 14.7744 | 3.3953 | +32.77% |
| Header guards + empty-constructor worker | 11.0924 | 11.8107 | 3.3821 | +6.48% |
| Constructor Bool worker + template arity index | 11.0060 | 11.5986 | 3.4180 | +5.38% |
| Constructor index in parser scope | 11.0168 | 10.6991 | 3.3833 | −2.88% |

The corrections skip unnecessary declaration scans, preserve direct recursive
constructor workers, and reuse the existing declaration index only for a proved
arity projection. Whole-definition index lookup has different duplicate ordering,
so that substitution is deliberately limited to the validated count result.

Source17 additionally carries a constructor index in the existing parser scope.
It uses the existing index data structure with three small wrappers, exactly
preserves the recursive lookup's first depth-first winner, ignores ordinary
same-name definitions, and publishes datatype constructors at the original
completion boundary. It does not traverse constructor term payloads or introduce
a second checker. Independent42 direct controls and24 public observations pass.
The [source review](constructor-index-source-review.md) and
[controls](context-controls-constructor-index.md) bind these contracts.

The final screen passes both process and request gates: **10.6991 seconds**
versus Phase21's11.0168 and TypeScript's3.3833, a **3.1623×** TypeScript gap.
Request time is9.5968 versus9.9165 seconds (−3.22%). Peak RSS is674,148 versus
657,568KiB (+2.52%). This modest two-sample improvement should not be presented
as a precise statistical speedup. All six complete ordinary program results
agree. It recovers the measured conformance cost without claiming faster
emission or generated execution.
The [final cost report](constructor-index-cost.md) binds the complete six-row
measurement and separately reviews the host change.

Earlier source11/12 checked-build plus36-control loops completed in roughly
33–35 seconds under their recorded conditions. Those are observed development
loops, not this exclusive cost workload. Routine changes should keep that
focused workflow; the full integration suites belong at release checkpoints.

## Validation, rejected attempts and transfer

Source09/build08 acquired the first successful full2996, broader196, public176,
execution36 and direct17 results. Source10/build09 changes only the checkup
handler; all215 frozen source members were compared, the other214 are identical,
and the compiled API is byte-identical. Source10 maintained36, actualcheckup4
and request histories validate the changed host. Source17 adds cost changes and
has fresh final acquisitions; those gates are not transferred by API name. The
[bundle host review](bundle-host-review-v2.json) records this narrow transfer;
earlier gate files retain their original host identities.

Source17/build16 now reruns the complete main corpus: **2,996 exact matches**,
the last two diagnostic differences closed and zero lost matches. Its final
broader196 and marked114 subset audit also close every recorded difference.
Public176, execution36, integration198, completion17 and checkup4 have fresh
successful acquisitions on that same final API. The final histories preserve226
paired observations and two fresh long strings. Exactly one predeclared do-block
diagnostic changes to the frozen pinned result; the earlier zero-exception run
remains failed. The unchanged standalone test builds a distinct genuinely checked
26-module component, not a new full-compiler fixed point. The independent
[release controls](context-controls-release.md) bind all these scopes.

The frontend comparator has one explicit old-to-new module-layout descriptor
because the new contextual module changes manifest membership. It still checks
all non-layout fields, paths, source identities, complete result objects and
frozen pinned oracles. Its25 independent visibility/negative controls pass.
Neither this descriptor nor host identity is a blanket normalization policy.

Failed source/build attempts remain immutable. They include upstream affine
checking failure, missing imported-law support, a first production candidate
with30 new main-suite regressions, lost synthetic origins, premature header
forcing, computed-pattern pretty-print order and an extra deferred-child tag
read. The loader deletion script's first multiline-boundary error was caught
before compilation and retained alongside its corrected successor.

Direct completion controls first matched15/17, then16/17, before17/17. The first
actual-checkup oracle launch failed under Node's strip-only TypeScript mode;
the next launcher explicitly enabled type transformation and retained the same
pinned function bodies and fixtures. It exposed a real missing-import mismatch,
fixed only in source10. Earlier wrong fixture expectations and raw failed
aggregates remain unchanged. See the owner reports for exact bindings:

- [Final contextual parser and scope](contextual-parser-final.md), with the [earlier implementation history](contextual-parser.md).
- [Final independent release controls](context-controls-release.md), including public, execution, history and component gates.
- [Direct completion controls](completion-beta-final.md).
- [ABI2 host controls](loader-host-abi2.md) and [loader retirement review](loader-retirement-review.md).
- [Frontend layout comparator](frontend-layout-audit.md).
- [Index-removal worker](index-remove-worker.md) and [installed profile](installed-profile.md).

## Installation, preservation and remaining limits

The independently reviewed promotion copies exactly21 source/host members from
`context-build-16`, including one new module. Installed release integrity, lineage
and source verification pass, followed by all42 installed/relocated CLI checks.
The [promotion inputs](context-promotion-inputs.json) and
[independent manifest review](context-promotion-manifest-review.json) bind the
exact gates. Generated artifacts retain their genuine checked parent and guarded
version5 derivation; no TypeScript fallback is introduced.

The75 unrelated Phase6 paths remain protected by hash and Git status and are
excluded from this work. Space-constrained preservation coalesces only reviewed
byte-identical closed scratch files while keeping every logical path, byte and
mode. Capsule/recovery decisions and receipts live in the separate evidence
index; compiler acceptance does not imply preservation or publication succeeded.
Commits are local while the previously recorded automatic approval block on
remote publication remains unresolved.

The active pin is unchanged. Independent proof-kernel validation/`--verdict`,
GPU execution, hub/package fetching, interactive devices and broader platform
coverage remain outside the demonstrated result. Native Process depends on a
libc symbol unavailable on this host, also affecting upstream. Source Nat
payloads retain the U32-size restriction. Earlier backend and fixed-point
results retain their recorded artifact identities; they are not silently
relabelled as Phase22 validation.

The next justified optimization should follow the fresh profile and preserve
these error-demand boundaries. Generated execution speed needs its own workload
and measurement. A language-wide conformance proof or much larger source
reduction remains separate work.
