# Phase31 selected compiler and release closure

Status: checked07 is installed. All final scoped correctness gates, release
verification and all42 ordinary/relocated CLI checks pass.
The [implementation report](closed-local-regions.md) separates program execution,
normal compilation cost, source complexity and the known entry/fallback costs.
The [independent review](independent-release-review.md) checks evidence and scope.

## Artifact identity

| Item | SHA256 |
| --- | --- |
| Selected API | `d8f609c99b3acef932f90040d0c6152c96605493bef926e46f25559ac125029b` |
| Genuine checked parent | `da90b03328759dd699b8343789e206474b14eb1a027f722054391cf8da0deb8d` |
| Assembled Bend source | `f253683ff97c55e553b70b18cf463b35dc9924261f91012d0da0034437a3f702` |
| Embedded runtime | `4121f338a7e4e115bae557343cd3d194a26ed26589bc47d82094969284181e10` |
| Base | `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661` |

The upstream pin remains `018751270e800bc222a93dad7f257083ee53a5f7`
(after Bend2.0.34). This is the maintained guarded version6 derivative of a
genuine TypeScript-produced checked parent from the same Bend source. Ordinary
compilation runs that Bend implementation without a TypeScript fallback. It is
not a new H self-emission or a compiler fixed point.

## Performance decision

Original four-pair edit distance improves26.83× over17 and remains14.28×
TypeScript time. A separate full-pair ablation and one-array fold improve29.09×
and17.67×. Mandelbrot and RLE retain their prior performance in the measured
window; they still trail TypeScript4.48× and75.73× respectively.

The original no-material-regression performance condition failed: zero-entry
+4.01% and generic mixed-module row +5.04%. The controlled registration
experiment explains96.97% of same-window row excess. Selection explicitly accepts
these costs under the [admission amendment](../../design/phase31/admission-tradeoff.md).
Edit-distance compilation adds108ms (+6.90% request time), also accepted;
Mandelbrot request ranges overlap. No compiler-throughput speedup is claimed.

All clean timing windows closed before rendering, compression, broad correctness
work or installation. First calls, every fresh sample, full ranges, within-sample
drift, commands, output identities and peak RSS are retained.

## Final correctness and installation

Fresh main3026 and broader196 candidate observations agree exactly with the
attested pinned TypeScript references. Main raw outcomes remain2525 pass /497
observed /4 shared failures; broader195 pass /1 observed. The exact audited
60→65→66 module migration adds only `local.bend` relative to17.

The backend pilot initially retained17 paired Clang EPERM failures in restricted
execution. The unchanged21-row native subset then ran in the approved execution
context and reproduced17 passes /4 not-applicable outcomes. Combining the60
other original rows with those21 retries preserves all81 historical observations:
69 passes /8 not applicable /4 shared failures. Both raw campaigns remain
visible; the failed81-row admission is not rewritten as a successful run.

Fresh final07 inherited gates pass15 selected upstream JS cases,56,205 primitive
executions,3,759 worker executions,144 nested cases,1,129 primitive refusal
controls and23 libraries/127 points. Added worker admission40+2,22 compiler
component observations and the complete42-byte HVM output also pass. The
[conformance report](final-conformance.md) and [summary](conformance-summary.json)
bind each gate. Counts overlap and are not a sum of unique tests.

Local-data controls cover full arrays and328,966 ordered native
events,88 structural-fixture values,52 ordered boundary observations,35 private
functions/51 return nodes and30 bounded type/provenance controls. The55-case
runtime support acquisition is reused only under byte-exact final-runtime
identity. Counterexamples for weakened guards and delayed-write reorderings
remain effective. The independent report describes its proof and test limits.

The maintained release tool installs the exact07 attempt and verifies the
selected API, original checked parent, source, Base, runtime and host lineage.
The previous33545640… default is preserved in a new release-history directory;
none of the four unrelated protected history directories is modified.
Install/verification receipts are `release-install-07` and `release-verify-07`
beneath the raw capture root.

All **42 ordinary/relocated CLI checks** pass in41.900 seconds, including
version, checking, interpreter, JS emission/execution, CPU emission/build/run
and integrity before/after. The [complete receipt](release-cli.json) is copied
byte-for-byte from `final-plan-07/release-smoke/checks/report.json`; its outer
receipt is `release-smoke-07-outer`. The native smoke uses the same approved
Clang16 context as the successful subset retry. Relocation supplies no upstream
checkout; historical absolute provenance paths remain data, not an OS isolation
claim. No source change follows selection07.

The optional811 further JS cases remain deferred. No new H self-emission,
fixed point, GPU or independent proof-kernel coverage is inferred.

## Complexity and preservation

The final manifest has17,014 physical /14,529 nonblank Bend lines,1,878 definitions,
640 laws,70 types and66 modules. This is236 physical lines (+1.41%),34 definitions
and one module above17. Maintained runtime core245 lines,11 more than17.
Generated artifacts, documentation and experiment tools are counted separately.

The verified [evidence capsule](evidence/README.md) retains22,095 files /
251,864,074 logical bytes in a49,396,387-byte archive. Capture compares every
member's exact name, size, SHA256 and mode against the stable live inventory.
Failed attempts, old consumed tools, default-context native failures, exact
profiles and event streams are preserved alongside passing acquisitions.
All103 unrelated starting files remain protected under the start/final hash audit.
No PR comment is authorized or posted.
