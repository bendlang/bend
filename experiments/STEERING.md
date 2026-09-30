# Current compiler experiment strategy

Phase31 is consolidated on2026-09-30. User authorization covers compiler
research, experiments, implementation, design/report and commit/push to
`rom1504/bend`, branch `selfhost/bootstrap`. No PR comments without an explicit
request. Phase30's seven-hour minimum is historical and complete.

## Installed Phase31 compiler

[Campaign design](../design/phase31/local-data-and-compiler-throughput.md),
[implementation](../implementation/phase31/closed-local-regions.md),
[release](../implementation/phase31/release-07.md),
[independent review](../implementation/phase31/independent-release-review.md).
Target remains upstream0187512, after Bend2.0.34. Selected07 is installed and
passes release verification and all42 ordinary/relocated CLI checks.
API `d8f609c9…`, genuine parent `da90b033…`, source `f253683f…`,
runtime `4121f338…`, Base `c742fae9…`; maintained guarded derivative version6.
The previous33545640… default is preserved in release history.

One bounded private graph now admits internally allocated Array<U32>,
nonrecursive records and canonical Sigma. Private returns complete at their
proved demand point; calls need no extra force; matches read known fields
directly. Public roots retain scalar boundaries and the inert terminal-record
exception. Public descriptors, storage and unsupported fallback remain unchanged.
No new ownership system, IR pipeline or datatype declaration is introduced.

## Measurements and accepted costs

Same-window original four-pair edit distance:17 1900.375ms,07 70.817ms,
TypeScript4.95995ms. **26.83× faster than17; still14.28×TS.** Original Mandelbrot
takes0.203686ms (4.48×TS); RLE0.045167ms (75.73×TS). Other seven original
programs have no fresh Phase31 timing. Keep first-call and half-drift limits.

Actual checked04→05→06→07 ablations on a full pair and a distinct fold isolate
closed calls, eager private returns, redundant-force removal and direct fields.
Final07 improves29.09×/17.67× over17. Force removal has overlapping incremental
ranges: retain its simpler invariant, not an independently proven speedup.
Direct fields save62.50%/49.46% over06. Fold still warms about9% between halves.

The original no-material-regression condition **failed**. Long confirmation
finds scalar-zero +4.01% (~0.18µs) and generic-row +5.04%. A separate unused
worker-registration experiment explains96.97% of same-window row excess.
The [admission amendment](../design/phase31/admission-tradeoff.md) explicitly
accepts these costs; unsafe guard/descriptor shortcuts are not promoted.
Normal edit-distance compilation also adds107.77ms (+6.90%, disjoint ranges);
Mandelbrot +0.73% overlaps. No compiler-throughput improvement is claimed.

Canonical source:17,014 physical /14,529 nonblank Bend lines;1,878 definitions,
640 laws,70 types,66 modules. Net236 lines (+1.41%),34 definitions and one module
over17. Runtime core245 lines (+11). Experiment/docs/generated artifacts excluded.

## Correctness and preservation

Fresh3026 main +196 broader frontend observations agree exactly. Raw main
2525 pass /497 observed /4 shared failures; broader195 pass /1 observed.
The explicit60→65→66 module migration preserves old ordering/non-module metadata.

Backend81 agrees with history:69 pass /8 N/A /4 shared failures. Its original
restricted run retains17 paired Clang EPERM failures. A separate approved-context
21-row retry combines with60 unaffected original rows; the failed campaign is
not relabeled. Selected upstream15,23 libraries/127 points, inherited primitive/
worker/nested/refusal suites,worker40+2,component22 and full HVM output pass.
Independent local-array/record/boundary/negative controls pass. Counts overlap.

No new H image, fixed point, GPU or proof-kernel claim. Optional811 further JS
rows remain deferred. H17 attribution/profile are diagnostic:about97% of traced
request time is generated invocation, not host encoding; checker samples point
to application/forcing/matching. Zig primary-source research is complete.

All producers are closed. Preserve103 unrelated starting files byte-for-byte
and unstaged. The [Phase31 capsule](../implementation/phase31/evidence/README.md)
and prior capsules retain failed attempts, consumed tools and raw receipts.
01–03 guard/embedded-runtime failures,07's observer correction, the H profile's
raw-size overrun and native-context failures remain explicit.

## Next decisions

1. Start from the [next-transformations design](../design/phase31/next-local-transformations.md):
   first return-position JUnpack statements with fresh lexical scopes; then
   proved Array.get producer/consumer tuple fusion. Neither has a measured gain.
   Preserve producer-time reads, alias ordering and initial-zero rebinding.
2. The complete pair still allocates262,401 read-result tuples and66,049 record
   shells. These are opportunities, not CPU-share or speedup estimates. Test one
   change on saved output before another checked build.
3. Include a mixed generic/specialized module in runtime screens: registering
   an optimized root activates lookup costs for unrelated generic calls. Do not
   weaken exact-entry or Array-free Sigma guards to make a canary look faster.
4. Treat actual H throughput separately. Do not multiply old5.002×H/parent,
   current14.28×program/TS and normal-request ratios. H17's reference is its
   TS-produced Bend parent, not the handwritten TypeScript compiler.
5. Keep the loop short: saved-output controls/screens, about38-second checked
   builds plus36 focused observations, then selected transfer. Broad frontend,
   backend, CLI and archive work belongs at integration, outside each hypothesis.
6. Any compiler analysis cache or compact private IR needs a measured producer
   cost and a book/type identity proof. Zig's historical gains are not predictions
   for Bend. Avoid a large rewrite without a discriminating experiment.

## Earlier release

[Phase30](../implementation/phase30/release-17.md) introduced scalar lexical
regions/loops/trees, retired constructor-arm prebinding and avoided registry
lookup before the first worker. Its original Mandelbrot gained100.47× over29,
while edit distance still took391.54×TS. These are historical windows; current
Phase31 uses freshly paired17 references. All prior capsules and baselines remain.
